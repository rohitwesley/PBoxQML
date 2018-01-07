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
#define time iFrame * 0.001
#define AntiAliasingSamples 1

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

/////////////////////
// 2D Vector functions //
/////////////////////
//=============Signed Distance Functions=============
float sdSegment( vec2 p, vec2 a, vec2 b )
{
        vec2 pa = p - a;
        vec2 ba = b - a;
        float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );

        return length( pa - ba*h );
}
float sdCircleOutline(vec2 p, vec2 c, float r)
{
    return abs(r - length(p - c));
}
float sdCircle(vec2 p, vec2 c, float r)
{
    return length(p - c) - r;
}
//=============Sharpen edges=============
float sharpen(in float d, in float w)
{
    float e = 1. / min(iResolution.y , iResolution.x);
    return 1. - smoothstep(-e, e, d - w);
}
#define ANIMATED
#define SHOW_CONTROL_POINTS
#define SHOW_SEGMENT_POINTS
#define STEPS  5.
#define STROKE .2
#define SKELETON 3.0
#define EPS    .01

//=============IK Solver=============
vec2 solveIKJoint( vec2 p, float l1, float l2 )
{
        vec2 q = p*( 0.5 + 0.5*(l1*l1-l2*l2)/dot(p,p) );

        float s = l1*l1/dot(q,q) - 1.0;

        if( s<0.0 ) return vec2(-100.0);

    return q + q.yx*vec2(-1.0,1.0)*sqrt( s );
}
//=============Interpolate along a segment=============
// use de Casteljau's algorithm
vec2 interpolate(vec2 a, vec2 b, vec2 c, float p)
{
    vec2 v0 = mix(a, b, p);
    vec2 v1 = mix(b, c, p);
    return mix(v0, v1, p);
}

//=============Bezier, Quadratic=============
float ip_control(vec2 uv, vec2 a, vec2 b, vec2 c)
{
    float cp = 0.;

#ifdef SHOW_CONTROL_POINTS
    float c0 = sharpen(sdCircleOutline(uv, a, .002), EPS * .75);
    float c1 = sharpen(sdCircleOutline(uv, b, .002), EPS * .75);
    float c2 = sharpen(sdCircleOutline(uv, c, .002), EPS * .75);

    float l0 = sharpen(sdSegment(uv, a, b), EPS * .6);
    float l1 = sharpen(sdSegment(uv, b, c), EPS * .6);

    cp = max(max(max(c0, c1), c2),
                 max(l0, l1));
#endif

    return cp;
}

float ip_point(vec2 uv, vec2 a, vec2 b, vec2 c,float stepID)
{
    vec2 p = interpolate(a, b, c, mod(stepID * 2., 10.) / 10.);
    return sharpen(sdCircleOutline(uv, p, .0025), EPS * 1.);
}

float ip_curve(vec2 uv, vec2 a, vec2 b, vec2 c)
{
    float e = 0.;
    for (float i = 0.; i < STEPS; ++i)
    {
        vec2  p0 = interpolate(a, b, c, (i   ) / STEPS);
        vec2  p1 = interpolate(a, b, c, (i+1.) / STEPS);
#ifdef SHOW_SEGMENT_POINTS
        float m = sharpen(sdCircleOutline(uv, p0, .001), EPS * .5);
        float n = sharpen(sdCircleOutline(uv, p1, .001), EPS * .5);
        e = max(e, max(m, n));
#endif
        float l = sharpen(sdSegment(uv, p0, p1), EPS * STROKE);
        e = max(e, l);
    }

    return e;
}

float ip_curveThick(vec2 uv, vec2 a, vec2 b, vec2 c)
{
    float e = 0.;
    for (float i = 0.; i < STEPS; ++i)
    {
        vec2  p0 = interpolate(a, b, c, (i   ) / STEPS);
        vec2  p1 = interpolate(a, b, c, (i+1.) / STEPS);
#ifdef SHOW_SEGMENT_POINTS
        float m = sharpen(sdCircleOutline(uv, p0, .001), EPS * .5);
        float n = sharpen(sdCircleOutline(uv, p1, .001), EPS * .5);
        e = max(e, max(m, n));
#endif
        float segGradient  = (STEPS-i)/STEPS;
        float l = sharpen(sdSegment(uv, p0, p1), EPS * SKELETON * segGradient);
        e = max(e, l);
    }

    return e;
}


vec4 ik2dbone(vec2 uv,vec2 p){
    vec4 col;
    vec2 q = vec2(2.0)*(uv+vec2(-0.5));//offset uv to center

//    if(iTime%25==0){//step 1 grid texture
//        float scale = 100.0;//number of squares
//        vec2 center = vec2(0.0);//grid center
//        col = vec4(grid( uv,center,scale ),1.0);
//    }
//    else if(iTime%25==1){//step 2 voronoin texture
//        // computer voronoi patterm
//        vec2 c = voronoi( (14.0+6.0*sin(0.2*time))*uv );
//        // colorize
//        vec3 vorncell;
//        vorncell = 0.5 + 0.5*cos( c.y*6.2831 + vec3(0.0,1.0,2.0) );
//        vorncell *= clamp(1.0 - 0.4*c.x*c.x,0.0,1.0);
//        vorncell -= (1.0-smoothstep( 0.08, 0.09, c.x));
//        col = vec4(vorncell,1.0);
//    }
//    else if(iTime%25==2){//step 3 Fractional Brownian Motion (FBM) cloudy pattern noise using different frequency octaves.
//        q=q.xy*vec2(4.,2.);
//        col = vec4(vec3(
//            .5*snSmooth(q)
//            +.25*snSmooth(2.*q)
//            +.125*snSmooth(4.*q)
//            +.0625*snSmooth(8.*q)
//            +.03125*snSmooth(16.*q)+
//            .015*snSmooth(32.*q)),1.);
//    }

    if(iTime%25<=5){//step 1 IK Solver
        vec2 uv2d = -1.0 + 2.0*uv;//-1.0 + 2.0*frag_uv.xy / iResolution.xy;
        vec2 mo = -1.0 + 2.0*iMouse.xy/iResolution.xy;
        uv2d.x *= iResolution.x/iResolution.y;
        mo.x *= iResolution.x/iResolution.y;

        if( iMouse.z<=0.0001 ) {
            mo = vec2(1.0+0.2*sin(time),0.2+0.3*sin(time*3.3));
        }

        float l1 = 0.5;
        float l2 = 0.4;
        vec2 a = vec2(0.0,0.0);
        vec2 c = mo;
        vec2 b = solveIKJoint( c, l1, l2 );

        // grid texture
        float scale = 100.0;//number of squares
        vec2 center = vec2(0.0);//grid center
        vec3 colIK = grid( uv,center,scale );

        float f=0.0;
        // center range outline
        colIK = mix( colIK, vec3(0.2,0.2,0.2), smoothstep( 0.0, 0.01, sharpen(sdCircleOutline(uv2d,a,l1), EPS * .75) ) );
        // mouse range outline
        colIK = mix( colIK, vec3(0.2,0.2,0.2), smoothstep( 0.0, 0.01, sharpen(sdCircleOutline(uv2d,c,l2), EPS * .75) ) );
        if( b.x>-99.0 )
        {
            //Draw A Bezier Curve Given three points a,b,c (Parabolic Arc)
            //control points and line segments
            float d0 = ip_control(uv2d, a, b, c);
            float point = 0.;
    #ifdef ANIMATED
            // active segment point
            point = ip_point(uv2d, a, b, c, iFrame * 0.01);
    #endif
            //Bezier curve
            float d1 = ip_curve(uv2d, a, b, c);
            float rs = max(d0, d1);
            colIK += (point < .5) ? rs * (d0 > d1 ? vec3(.2, .35, .55) : vec3(.9, .43, .34)) : point * vec3(1.);

            //joint point
            colIK = mix( colIK, vec3(1.0,0.0,0.0), smoothstep( 0.02, 0.03, sharpen(sdCircle(uv2d,b,0.001), EPS * .75)  ) );

            //draw a line segment joining a,c
            f = sharpen(sdSegment( uv2d, a, c ), EPS * STROKE);
            colIK = mix( colIK, vec3(0.0,1.0,0.0), smoothstep( 0.00, 0.01, f ) );
        }
        //center point
        colIK = mix( colIK, vec3(1.0,1.0,1.0), smoothstep( 0.02, 0.03, sharpen(sdCircle(uv2d,a,0.01), EPS * .75)  ) );
        //mouse point
        colIK = mix( colIK, vec3(1.0,1.0,0.0), smoothstep( 0.02, 0.03, sharpen(sdCircle(uv2d,c,0.001), EPS * .75)  ) );

        col = vec4(colIK,1.0);
    }
    else if(iTime%25>=5){//step 2 Shapes
        vec2 uv2d = -1.0 + 2.0*uv;//-1.0 + 2.0*frag_uv.xy / iResolution.xy;
        vec2 mo = -1.0 + 2.0*iMouse.xy/iResolution.xy;
        uv2d.x *= iResolution.x/iResolution.y;
        mo.x *= iResolution.x/iResolution.y;

        if( iMouse.z<=0.0001 ) { mo = vec2(1.0+0.2*sin(time),0.2+0.3*sin(time*3.3)); }

        float l1 = 0.5;
        float l2 = 0.4;
        vec2 a = vec2(-0.9,-0.9);
        vec2 c = mo;
        vec2 b = solveIKJoint( c, l1, l2 );

        // grid texture
        float scale = 100.0;//number of squares
        vec2 center = vec2(40.0,40.0);//grid center
        vec3 colIK = grid( uv,center,scale );

        if( b.x>-99.0 )
        {
            float grass = sharpen(ip_curveThick(uv2d, a, b, c), EPS * .75);
            colIK = mix( colIK, vec3(0.1,0.5,0.1), 1-smoothstep( 0.0, 0.01, grass ) );
            //Bezier curve
            float d1 = sharpen(ip_curve(uv2d, a, b, c), EPS * .75);
            colIK = mix( colIK, vec3(.9, .43, .34), 1-smoothstep( 0.0, 0.01, d1 ) );
            //control points and line segments
            float d0 = sharpen(ip_control(uv2d, a, b, c), EPS * .75);
            colIK = mix( colIK, vec3(.9, .43, .34), 1-smoothstep( 0.0, 0.01, d0 ) );
            // active segment point
            float point = sharpen(ip_point(uv2d, a, b, c, iFrame * 0.01), EPS * .75);
            colIK = mix( colIK, vec3(1.), 1-smoothstep( 0.0, 0.01, point ) );
            //joint point
            colIK = mix( colIK, vec3(1.0,0.0,0.0), smoothstep( 0.02, 0.03, sharpen(sdCircle(uv2d,b,0.001), EPS * .75)  ) );
        }
        //center point
        colIK = mix( colIK, vec3(1.0,1.0,1.0), smoothstep( 0.02, 0.03, sharpen(sdCircle(uv2d,a,0.01), EPS * .75)  ) );
        //mouse point
        colIK = mix( colIK, vec3(1.0,1.0,0.0), smoothstep( 0.02, 0.03, sharpen(sdCircle(uv2d,c,0.001), EPS * .75)  ) );

        col = vec4(colIK,1.0);
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
            col = ik2dbone(uv,p);
        }
        else if(iTime%60<40){//sceen2
            col = ik2dbone(uv,p);
        }
        else{//default
            col = vec4(uv,0.5+0.5*sin((float(iTime)/10)+(float(iFrame)/100)),1.0);
        }

        color = col;

//    }

}
