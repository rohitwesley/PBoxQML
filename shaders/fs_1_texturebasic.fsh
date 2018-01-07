#version 330 core
//in vec3  fragColor;
in vec2 frag_uv;
in vec3 frag_position;
in vec3 frag_normal;

uniform sampler2D fragTexture;
uniform sampler2D fboTexture;
uniform float opacity;


struct Material {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float shininess;
};

struct Light {
    vec3 position;
    vec3 ambient;
};
// array of lights
#define MAX_LIGHTS 10
uniform int numLights;
uniform Material material;
uniform Light light[10];
uniform bool has_texture;
uniform bool has_texturebuffer;

const int mode = 1;
//const vec3 lightPos = vec3(0.0,0.0,-50.0);
const vec3 ambientColor = vec3(0.0015, 0.0015, 0.0015);
const vec3 diffuseColor = vec3(0.015, 0.015, 0.015);
//const vec3 specColor = vec3(1.0, 0.0, 0.0);
const float shininess = 4096.0;//16.0;
const float screenGamma = 2.2; // Assume the monitor is calibrated to the sRGB color space

uniform bool        selected;               // object active
uniform vec3        iResolution;            // viewport resolution (in pixels)
uniform int         iTime;                  // shader playback time (in seconds)
uniform float       iTimeDelta;             // render time (in seconds)
uniform int         iFrame;                 // shader playback frame
uniform float       iChannelTime[4];        // channel playback time (in seconds)
uniform vec3        iChannelResolution[4];  // channel resolution (in pixels)
uniform vec4        iMouse;                 // mouse pixel coords. xy: current (if MLB down), zw: click
uniform vec4        iDate;                  // (year, month, day, time in seconds)
// input channel. XX = 2D/Cube
//uniform sampler2D iChannel0;
//uniform sampler2D iChannel1;
//uniform sampler2D iChannel2;
//uniform sampler2D iChannel3;
#define time iFrame * 0.01 + iMouse.x*5.0
#define AntiAliasingSamples 1



/////////////////////
// MoCap functions //
/////////////////////

#define _in(T) const in T
#define _inout(T) inout T
#define _out(T) out T
#define _begin(type) type (
#define _end )
#define mul(a, b) (a) * (b)
// Shadertoy specific uniforms
#define u_res iResolution
#define u_time iFrame * 0.001 + iMouse.x*0.01
#define u_mouse iMouse
#define PI 3.14159265359

/////////////////////
// Mocap functions //
/////////////////////
//=============Sky Mocap=============
struct ray_t {
        vec3 origin;
        vec3 direction;
};
#define BIAS 1e-4 // small offset to avoid self-intersections

struct sphere_t {
        vec3 origin;
        float radius;
        int material;
};

struct plane_t {
        vec3 direction;
        float distance;
        int material;
};

mat3 rotate_around_x(_in(float) angle_degrees)
{
        float angle = radians(angle_degrees);
        float _sin = sin(angle);
        float _cos = cos(angle);
        return mat3(1, 0, 0, 0, _cos, -_sin, 0, _sin, _cos);
}


ray_t get_primary_ray(
        _in(vec3) cam_local_point,
        _inout(vec3) cam_origin,
        _inout(vec3) cam_look_at
){
        vec3 fwd = normalize(cam_look_at - cam_origin);
        vec3 up = vec3(0, 1, 0);
        vec3 right = cross(up, fwd);
        up = cross(fwd, right);

        ray_t r = _begin(ray_t)
                cam_origin,
                normalize(fwd + up * cam_local_point.y + right * cam_local_point.x)
                _end;
        return r;
}

bool isect_sphere(_in(ray_t) ray, _in(sphere_t) sphere, _inout(float) t0, _inout(float) t1)
{
        vec3 rc = sphere.origin - ray.origin;
        float radius2 = sphere.radius * sphere.radius;
        float tca = dot(rc, ray.direction);
        float d2 = dot(rc, rc) - tca * tca;
        if (d2 > radius2) return false;
        float thc = sqrt(radius2 - d2);
        t0 = tca - thc;
        t1 = tca + thc;

        return true;
}

// scattering coefficients at sea level (m)
const vec3 betaR = vec3(5.5e-6, 13.0e-6, 22.4e-6); // Rayleigh
const vec3 betaM = vec3(21e-6); // Mie

// scale height (m)
// thickness of the atmosphere if its density were uniform
const float hR = 7994.0; // Rayleigh
const float hM = 1200.0; // Mie

float rayleigh_phase_func(float mu)
{
        return
                        3. * (1. + mu*mu)
        / //------------------------
                                (16. * PI);
}

// Henyey-Greenstein phase function factor [-1, 1]
// represents the average cosine of the scattered directions
// 0 is isotropic scattering
// > 1 is forward scattering, < 1 is backwards
const float g = 0.76;
float henyey_greenstein_phase_func(float mu)
{
        return
                                                (1. - g*g)
        / //---------------------------------------------
                ((4. + PI) * pow(1. + g*g - 2.*g*mu, 1.5));
}

// Schlick Phase Function factor
// Pharr and  Humphreys [2004] equivalence to g above
const float k = 1.55*g - 0.55 * (g*g*g);
float schlick_phase_func(float mu)
{
        return
                                        (1. - k*k)
        / //-------------------------------------------
                (4. * PI * (1. + k*mu) * (1. + k*mu));
}

const float earth_radius = 6360e3; // (m)
const float atmosphere_radius = 6420e3; // (m)

vec3 sun_dir = vec3(0, 1, 0);
const float sun_power = 20.0;

const sphere_t atmosphere = _begin(sphere_t)
        vec3(0, 0, 0), atmosphere_radius, 0
_end;

const int num_samples = 16;
const int num_samples_light = 8;

bool get_sun_light(
        _in(ray_t) ray,
        _inout(float) optical_depthR,
        _inout(float) optical_depthM
){
        float t0, t1;
        isect_sphere(ray, atmosphere, t0, t1);

        float march_pos = 0.;
        float march_step = t1 / float(num_samples_light);

        for (int i = 0; i < num_samples_light; i++) {
                vec3 s =
                        ray.origin +
                        ray.direction * (march_pos + 0.5 * march_step);
                float height = length(s) - earth_radius;
                if (height < 0.)
                        return false;

                optical_depthR += exp(-height / hR) * march_step;
                optical_depthM += exp(-height / hM) * march_step;

                march_pos += march_step;
        }

        return true;
}

vec3 get_incident_light(_in(ray_t) ray)
{
        // "pierce" the atmosphere with the viewing ray
        float t0, t1;
        if (!isect_sphere(
                ray, atmosphere, t0, t1)) {
                return vec3(0);
        }

        float march_step = t1 / float(num_samples);

        // cosine of angle between view and light directions
        float mu = dot(ray.direction, sun_dir);

        // Rayleigh and Mie phase functions
        // A black box indicating how light is interacting with the material
        // Similar to BRDF except
        // * it usually considers a single angle
        //   (the phase angle between 2 directions)
        // * integrates to 1 over the entire sphere of directions
        float phaseR = rayleigh_phase_func(mu);
        float phaseM =
#if 1
                henyey_greenstein_phase_func(mu);
#else
                schlick_phase_func(mu);
#endif

        // optical depth (or "average density")
        // represents the accumulated extinction coefficients
        // along the path, multiplied by the length of that path
        float optical_depthR = 0.;
        float optical_depthM = 0.;

        vec3 sumR = vec3(0);
        vec3 sumM = vec3(0);
        float march_pos = 0.;

        for (int i = 0; i < num_samples; i++) {
                vec3 s =
                        ray.origin +
                        ray.direction * (march_pos + 0.5 * march_step);
                float height = length(s) - earth_radius;

                // integrate the height scale
                float hr = exp(-height / hR) * march_step;
                float hm = exp(-height / hM) * march_step;
                optical_depthR += hr;
                optical_depthM += hm;

                // gather the sunlight
                ray_t light_ray = _begin(ray_t)
                        s,
                        sun_dir
                _end;
                float optical_depth_lightR = 0.;
                float optical_depth_lightM = 0.;
                bool overground = get_sun_light(
                        light_ray,
                        optical_depth_lightR,
                        optical_depth_lightM);

                if (overground) {
                        vec3 tau =
                                betaR * (optical_depthR + optical_depth_lightR) +
                                betaM * 1.1 * (optical_depthM + optical_depth_lightM);
                        vec3 attenuation = exp(-tau);

                        sumR += hr * attenuation;
                        sumM += hm * attenuation;
                }

                march_pos += march_step;
        }

        return
                sun_power *
                (sumR * phaseR * betaR +
                sumM * phaseM * betaM);
}

vec4 mocap(vec2 uv,vec2 p)
{
        vec2 aspect_ratio = vec2(u_res.x / u_res.y, 1);
        float fov = tan(radians(45.0));
        vec2 point_ndc = uv.xy;// / u_res.xy;
        vec3 point_cam = vec3((2.0 * point_ndc - 1.0) * aspect_ratio * fov, -1.0);

        vec3 col = vec3(0);

        // sun
        mat3 rot = rotate_around_x(-abs(sin(u_time / 2.)) * 90.);
        sun_dir *= rot;

    //if (u_mouse.z < 0.1) {
    if(selected) {
        // sky dome angles
        vec3 p = point_cam;
        float z2 = p.x * p.x + p.y * p.y;
        float phi = atan(p.y, p.x);
        float theta = acos(1.0 - z2);
        vec3 dir = vec3(
            sin(theta) * cos(phi),
            cos(theta),
            sin(theta) * sin(phi));

        ray_t ray = _begin(ray_t)
            vec3(0, earth_radius + 1., 0),
            dir
        _end;

        col = get_incident_light(ray);

        //get light ray
        //get noise
//        vec2 q = vec2(2.0)*(uv+vec2(-0.5));//offset uv to center
//        vec2 r=(456.789*sin(789.123*q.xy));
//        vec3 noisetx = vec4(fract(r.x*r.y*(1.+q.x)));


    } else {
        vec3 eye = vec3 (0, earth_radius + 1., 0);
        vec3 look_at = vec3 (0, earth_radius + 1.5, -1);

        ray_t ray = get_primary_ray(point_cam, eye, look_at);

        if (dot(ray.direction, vec3(0, 1, 0)) > .0) {
            col = get_incident_light(ray);
        } else {
            col = vec3 (0.333);
        }
    }

        return vec4(col, 1);
}

/////////////////////
// Noise functions //
/////////////////////
//=============Random Number=============
float rand(vec2 p) {
    p+=.2127+p.x*.3713*p.y;
    vec2 r=4.789*sin(489.123*(p));
    return fract(r.x*r.y);
}
//=============pick a hue=============
vec3 h2r(vec3 hsv) {
    vec3 t=clamp(abs(mod(hsv.r*6.+ vec3(0.,2.,4.),6.)-3.)-1.,0.,1.);
    return hsv.b*hsv.g*t+hsv.b-hsv.b*hsv.r;
}
//=============Basic Noise=============
float sn(vec2 p) {
    vec2 i=floor(p-.5);
    vec2 f=fract(p-.5);
    float rt=mix(rand(i),rand(i+vec2(1.,0.)),f.x);
    float rb=mix(rand(i+vec2(0.,1.)),rand(i+vec2(1.,1.)),f.x);
    return mix(rt,rb,f.y);
}
//=============Basic Smooth=============
float snSmooth(vec2 p) {
    vec2 i=floor(p-.5);
    vec2 f=fract(p-.5);
    f = f*f*f*(f*(f*6.0-15.0)+10.0);
    float rt=mix(rand(i),rand(i+vec2(1.,0.)),f.x);
    float rb=mix(rand(i+vec2(0.,1.)),rand(i+vec2(1.,1.)),f.x);
    return mix(rt,rb,f.y);
}
//=============Noise Cloud=============
float bm(vec2 p) {
    return .5*snSmooth(p)
    +.25*snSmooth(2.*p)
    +.125*snSmooth(4.*p)
    +.0625*snSmooth(8.*p)
    +.03125*snSmooth(16.*p)+
    .0156*snSmooth(32.*p);
 }
//=============Voronian cells=============
vec2 voronoihash( vec2 p ) { p=vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))); return fract(sin(p)*18.5453); }
// return distance, and cell id
vec2 voronoi( in vec2 x )
{
    vec2 n = floor( x );
    vec2 f = fract( x );

        vec3 m = vec3( 8.0 );
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec2  g = vec2( float(i), float(j) );
        vec2  o = voronoihash( n + g );
      //vec2  r = g - f + o;
            vec2  r = g - f + (0.5+0.5*sin(time+6.2831*o));
                float d = dot( r, r );
        if( d<m.x )
            m = vec3( d, o );
    }

    return vec2( sqrt(m.x), m.y+m.z );
}
//=============Grid Map=============
vec2 gridmap( vec2 pixel,vec2 center,float scale )
{
    return center + scale*(-0.5+pixel / 1.0);
}
vec3 grid(vec2 uv,vec2 center,float scale ) {
    vec3 col = vec3(1.0,1.0,0.0);
    vec2 q = gridmap( uv,center,scale );
    col = vec3(0.35);
    col *= 1.0 + 0.1*mod( floor(q.x) + floor(q.y), 2.0 );
    if( (q.y>0.0 && q.x>0.0) ) col.xy *= vec2(1.4,1.3);
    if( !(q.y*q.x>0.0 ) ) col.yz *= 1.3;
    if( (q.y<0.0 && q.x<0.0) ) col *= vec3(1.1,1.4,1.2);
    return col;

}
/////////////
// Filters //
/////////////
//=============Binary Filter=============
vec3 binarygates(vec2 uv){
    float c = 0.0;

    float r = floor(uv.y*4.0 )*4.0 + floor(uv.x*4.0 );

    float a = fract(uv.x*4.0);
    float b = fract(uv.y*4.0);
#if 1
    /* 0011 = A         */
    /* 0101 = B         */
    /* ----   --------- */
    if( r< 0.5 ) /* 0000 = RESET     */ c = 0.0;
    else if( r< 1.5 ) /* 0001 = A AND B   */ c = a*b;
    else if( r< 2.5 ) /* 0010 = A AND !B  */ c = a - a*b;
    else if( r< 3.5 ) /* 0011 = A         */ c = a;
    else if( r< 4.5 ) /* 0100 = !A AND B  */ c = b - a*b;
    else if( r< 5.5 ) /* 0101 = B         */ c = b;
    else if( r< 6.5 ) /* 0110 = A XOR B   */ c = a + b - 2.0*a*b;
    else if( r< 7.5 ) /* 0111 = A OR B    */ c = a + b - a*b;
    else if( r< 8.5 ) /* 1000 = A NOR B   */ c = 1.0 - a - b + a*b;
    else if( r< 9.5 ) /* 1001 = A XNOR B  */ c = 1.0 - b - a + 2.0*a*b;
    else if( r<10.5 ) /* 1010 = !B        */ c = 1.0 - b;
    else if( r<11.5 ) /* 1011 = !A NAND B */ c = 1.0 - b + a*b;
    else if( r<12.5 ) /* 1100 = !A        */ c = 1.0 - a;
    else if( r<13.5 ) /* 1101 = A NAND !B */ c = 1.0 - a + a*b;
    else if( r<14.5 ) /* 1110 = A NAND B  */ c = 1.0 - a*b;
    else if( r<15.5 ) /* 1111 = SET       */ c = 1.0;
#else
    /* 0011 = A         */
    /* 0101 = B         */
    /* ----   --------- */
    if( r< 0.5 ) /* 0000 = RESET     */ c = bilin( a, b, 0.,0.,0.,0. );
    else if( r< 1.5 ) /* 0001 = A AND B   */ c = bilin( a, b, 0.,0.,0.,1. );
    else if( r< 2.5 ) /* 0010 = A AND !B  */ c = bilin( a, b, 0.,0.,1.,0. );
    else if( r< 3.5 ) /* 0011 = A         */ c = bilin( a, b, 0.,0.,1.,1. );
    else if( r< 4.5 ) /* 0100 = !A AND B  */ c = bilin( a, b, 0.,1.,0.,0. );
    else if( r< 5.5 ) /* 0101 = B         */ c = bilin( a, b, 0.,1.,0.,1. );
    else if( r< 6.5 ) /* 0110 = A XOR B   */ c = bilin( a, b, 0.,1.,1.,0. );
    else if( r< 7.5 ) /* 0111 = A OR B    */ c = bilin( a, b, 0.,1.,1.,1. );
    else if( r< 8.5 ) /* 1000 = A NOR B   */ c = bilin( a, b, 1.,0.,0.,0. );
    else if( r< 9.5 ) /* 1001 = A XNOR B  */ c = bilin( a, b, 1.,0.,0.,1. );
    else if( r<10.5 ) /* 1010 = !B        */ c = bilin( a, b, 1.,0.,1.,0. );
    else if( r<11.5 ) /* 1011 = !A NAND B */ c = bilin( a, b, 1.,0.,1.,1. );
    else if( r<12.5 ) /* 1100 = !A        */ c = bilin( a, b, 1.,1.,0.,0. );
    else if( r<13.5 ) /* 1101 = A NAND !B */ c = bilin( a, b, 1.,1.,0.,1. );
    else if( r<14.5 ) /* 1110 = A NAND B  */ c = bilin( a, b, 1.,1.,1.,0. );
    else if( r<15.5 ) /* 1111 = SET       */ c = bilin( a, b, 1.,1.,1.,1. );
#endif

    vec3 col = vec3(c);

    col = mix( col, vec3(0.9,0.5,0.3), smoothstep( 0.490, 0.495, abs(a-0.5) ) );
    col = mix( col, vec3(0.9,0.5,0.3), smoothstep( 0.485, 0.490, abs(b-0.5) ) );
    return col;
}

vec4 procedural2dnoise(vec2 uv,vec2 p){
    vec4 col;
    vec2 q = vec2(2.0)*(uv+vec2(-0.5));//offset uv to center

    if(iTime%25==0){//step 1 quantaisation to 4 blocks using step function
        vec2 s=step(0.0,q);
        col = vec4(s.x,s.y,0.0,1.0);
    }
    else if(iTime%25==1){//step 2 efficient quantaisation to 3x3 grid using floor
        //quantaisation to 9 blocks using step function (spliting 0-1.0 by 1/3rd)
        //vec2 s=0.5*(step(-0.333,q.xy)+step(0.333,q.xy));
        //floor is a better aulternative allowing for any number of quantisations
        vec2 s=floor(3.*(q.xy*.5+.5))/2.;//0.5*(step(-0.333,q.xy)+step(0.333,q.xy));
        col = vec4(s.x,s.y,0.0,1.0);
    }
    else if(iTime%25==2){//step 3 efficient quantaisation to 5x10 grid using floor
        vec2 s=floor(vec2(5.,10.)*(q.xy*.5+.5));
        col = vec4(0.02*(s.x+5.*s.y));
    }
    else if(iTime%25==3){//step 4 50 shapes
        vec2 r=vec2(5.,10.)*(q.xy*.5+.5);
        vec2 i=floor(r);
        vec2 c=(fract(r)-.5)*vec2(4.,2.)*.6;
        float s=3.+i.x+5.*i.y;
        float a=atan(c.x,c.y);
        float b=6.28319/s;
        float w=floor(.5+a/b);
        float g=smoothstep(.55,.5,cos(w*b-a)*length(c.xy));
        col = vec4(vec3(1.-g*((60.-s)/50.)),g);
    }
    else if(iTime%25==4){//step 5 50 shapes and using a count to pick a hue
        vec2 r=vec2(5.,10.)*(q.xy*.5+.5);
        vec2 i=floor(r);
        vec2 c=(fract(r)-.5)*vec2(4.,2.)*.6;
        float s=3.+i.x+5.*i.y;
        float a=atan(c.x,c.y);
        float b=6.28319/s;
        float w=floor(.5+a/b);
        float g=smoothstep(.55,.5,cos(w*b-a)*length(c.xy));
        float v=1.-1.2*length(c.xy);
        float sa=1.-abs(w/s);
        float h=s/50.;
        vec3 rgb=v*sa*clamp(abs(mod(h*6.+vec3(0.,2.,4.),6.)-3.)-1.,0.,1.)+(v-v*sa);
        col = vec4(1.-g*rgb,g);
    }
    else if(iTime%25==5){//step 6 Low Frequency Repeating sin Function
        float r=0.5+0.5*sin(10.0*q.x);
        col = vec4(r);
    }
    else if(iTime%25==6){//step 7 High Frequency Repeating sin Function showing aliasing
        float r=0.5+0.5*sin(789.123*q.x);
        col = vec4(r);
    }
    else if(iTime%25==7){//step 8 Use fract to create noise in the 1D patern
        float r=fract(sin(789.123*q.x));
        col = vec4(r);
    }
    else if(iTime%25==8){//step 9 Use high frequency fract to create more noise in the 1D patern
        float r=fract(456.789*sin(789.123*q.x));
        col = vec4(r);
    }
    else if(iTime%25==9){//step 10 Use high frequency fract to create more noise in a 2D patern
        vec2 r=fract(456.789*sin(789.123*q.xy));
        col = vec4(r.x*r.y);
    }
    else if(iTime%25==10){//step 11 Apply the fract to r insted and we get noise with some repetition
        vec2 r=(456.789*sin(789.123*q.xy));
        col = vec4(fract(r.x*r.y));
    }
    else if(iTime%25==11){//step 12 Add a cheap value to the fract and we get  pure white noise
        vec2 r=(456.789*sin(789.123*q.xy));
        col = vec4(fract(r.x*r.y*(1.+q.x)));
    }
    else if(iTime%25==12){//step 13 Random number generator to generate value from 0 - 1.0
        col = vec4(rand(floor(vec2(4.,2.)*q.xy)));
    }
    else if(iTime%25==13){//step 14 Random number generator to generate 32 random hue squircles
        q = q.xy*vec2(4.,2.);
        float s=smoothstep(.1,.2,1.-length(pow(2.*fract(q)-1.,vec2(2.))));
        vec3 t=h2r(vec3(rand(floor(q)),.75,.6));
        col = vec4(t,s);
    }
    else if(iTime%25==14){//step 15 generate simple smooth noise
        col = vec4(vec3(sn(vec2(4.,2.)*q.xy)),1.);
    }
    else if(iTime%25==15){//step 16 generate smooth noise
        col = vec4(vec3(snSmooth(vec2(4.,2.)*q.xy)),1.);
    }
    else if(iTime%25==16){//step 17 Fractional Brownian Motion (FBM) cloudy pattern noise using different frequency octaves.
        q=q.xy*vec2(4.,2.);
        col = vec4(vec3(
            .5*snSmooth(q)
            +.25*snSmooth(2.*q)
            +.125*snSmooth(4.*q)
            +.0625*snSmooth(8.*q)
            +.03125*snSmooth(16.*q)+
            .015*snSmooth(32.*q)),1.);
    }
    else if(iTime%25==17){//step 18 world map from FBM
        float h=bm(q.xy*4.);
        col = vec4(
                    mix(
                        mix(
                            vec4(0.,0.,.7,1.),
                            vec4(0.,.7,0.,1.),
                            smoothstep(.6,.63,h)),
                        vec4(1.),
                        smoothstep(.7,.95,h)));
    }
    else if(iTime%25==18){//step 19 grid texture
        float scale = 100.0;//number of squares
        vec2 center = vec2(0.0);//grid center
        col = vec4(grid( uv,center,scale ),1.0);
    }
    else if(iTime%25==19){//step 20 voronoin texture
        // computer voronoi patterm
        vec2 c = voronoi( (14.0+6.0*sin(0.2*time))*uv );
        // colorize
        vec3 vorncell;
        vorncell = 0.5 + 0.5*cos( c.y*6.2831 + vec3(0.0,1.0,2.0) );
        vorncell *= clamp(1.0 - 0.4*c.x*c.x,0.0,1.0);
        vorncell -= (1.0-smoothstep( 0.08, 0.09, c.x));
        col = vec4(vorncell,1.0);
    }
    else if(iTime%25>=20){//step 21 binary filters
        col = vec4(binarygates(uv),1.0);
    }
    else{//default
        col = vec4(uv,0.0,1.0);
    }
    return col;
}

out vec4 color;
void main(void)
{

    vec3 result = vec3(0.0);
    for(int i = 0; i < numLights; ++i){
        //vec3 lightPos = vec3(0.0,0.0,-50.0);
        vec3 lightPos = light[i].position;
        //vec3 specColor = vec3(1.0, 0.0, 0.0);
        vec3 specColor = light[i].ambient;
        vec3 normal = normalize(frag_normal);
        vec3 lightDir = normalize(lightPos - frag_position);

        float lambertian = max(dot(lightDir,normal), 0.0);
        float specular = 0.0;

        if(lambertian > 0.0) {

            vec3 viewDir = normalize(-frag_position);

            // this is blinn phong
            vec3 halfDir = normalize(lightDir + viewDir);
            float specAngle = max(dot(halfDir, normal), 0.0);
            specular = pow(specAngle, shininess);

            // this is phong (for comparison)
            if(mode == 2) {
                vec3 reflectDir = reflect(-lightDir, normal);
                specAngle = max(dot(reflectDir, viewDir), 0.0);
                // note that the exponent is different here
                specular = pow(specAngle, shininess/4.0);
            }
        }
        vec3 colorLinear = ambientColor + lambertian * diffuseColor + specular * specColor;
        // apply gamma correction (assume ambientColor, diffuseColor and specColor
        // have been linearized, i.e. have no gamma correction in them)
        vec3 colorGammaCorrected = pow(colorLinear, vec3(1.0/screenGamma));
        // use the gamma corrected color in the fragment
        result += colorGammaCorrected;
    }

//    if (selected) {
//        if(has_texture&&iTime%2==0)
//            color = vec4(result,opacity) * texture(fragTexture, frag_uv);
//        else if(has_texturebuffer&&iTime%1==1)
//            color = vec4(result,opacity) * texture(fboTexture, frag_uv);
//        else {
//            color = vec4(result,opacity);
//        }
//    }
//    else {

        vec2 uv = frag_uv.xy;
        vec2 p = ((vec2(1.5)*normalize(frag_position).xy) - vec2(-0.5));//adjust point error
        vec4 col;
        if(iTime%60<25){//sceen1
            col = procedural2dnoise(uv,p);
        }
        else if(iTime%60<40){//sceen2
            col = mocap(uv,p);
        }
        else{//default
            col = vec4(uv,0.5+0.5*sin((float(iTime)/10)+(float(iFrame)/100)),1.0);
        }

        color = col;

//    }

}
