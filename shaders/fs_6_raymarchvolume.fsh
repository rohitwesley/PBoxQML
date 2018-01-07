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
#define v_index vec3(1.0,1.0,0.0)
#define time iFrame * 0.001 + iMouse.x*0.01

out vec4 color;

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);

#if 1
    vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
    vec2 rg = textureLod( fragTexture, (uv+ 0.5)/256.0, 0. ).yx;
#else
    ivec3 q = ivec3(p);
    ivec2 uv = q.xy + ivec2(37,17)*q.z;

    vec2 rg = mix( mix( texelFetch( fragTexture, (uv           )&255, 0 ),
                        texelFetch( fragTexture, (uv+ivec2(1,0))&255, 0 ), f.x ),
                   mix( texelFetch( fragTexture, (uv+ivec2(0,1))&255, 0 ),
                        texelFetch( fragTexture, (uv+ivec2(1,1))&255, 0 ), f.x ), f.y ).yx;//iChannel0
#endif

    return -1.0+2.0*mix( rg.x, rg.y, f.z );
}

float map5( in vec3 p )
{
    vec3 q = p - vec3(0.0,0.1,1.0)*time;
    float f;
    f  = 0.50000*noise( q ); q = q*2.02;
    f += 0.25000*noise( q ); q = q*2.03;
    f += 0.12500*noise( q ); q = q*2.01;
    f += 0.06250*noise( q ); q = q*2.02;
    f += 0.03125*noise( q );
    return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
}

float map4( in vec3 p )
{
    vec3 q = p - vec3(0.0,0.1,1.0)*time;
    float f;
    f  = 0.50000*noise( q ); q = q*2.02;
    f += 0.25000*noise( q ); q = q*2.03;
    f += 0.12500*noise( q ); q = q*2.01;
    f += 0.06250*noise( q );
    return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
}

float map3( in vec3 p )
{
    vec3 q = p - vec3(0.0,0.1,1.0)*time;
    float f;
    f  = 0.50000*noise( q ); q = q*2.02;
    f += 0.25000*noise( q ); q = q*2.03;
    f += 0.12500*noise( q );
    return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
}

float map2( in vec3 p )
{
    vec3 q = p - vec3(0.0,0.1,1.0)*time;
    float f;
    f  = 0.50000*noise( q ); q = q*2.02;
    f += 0.25000*noise( q );;
    return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
}

vec3 sundir = normalize( vec3(-1.0,0.0,-1.0) );

vec4 integrate( in vec4 sum, in float dif, in float den, in vec3 bgcol, in float t )
{
    // lighting
    vec3 lin = vec3(0.65,0.7,0.75)*1.4 + vec3(1.0, 0.6, 0.3)*dif;
    vec4 col = vec4( mix( vec3(1.0,0.95,0.8), vec3(0.25,0.3,0.35), den ), den );
    col.xyz *= lin;
    col.xyz = mix( col.xyz, bgcol, 1.0-exp(-0.003*t*t) );
    // front to back blending
    col.a *= 0.4;
    col.rgb *= col.a;
    return sum + col*(1.0-sum.a);
}

#define MARCH(STEPS,MAPLOD) for(int i=0; i<STEPS; i++) { vec3  pos = ro + t*rd; if( pos.y<-3.0 || pos.y>2.0 || sum.a > 0.99 ) break; float den = MAPLOD( pos ); if( den>0.01 ) { float dif =  clamp((den - MAPLOD(pos+0.3*sundir))/0.6, 0.0, 1.0 ); sum = integrate( sum, dif, den, bgcol, t ); } t += max(0.05,0.02*t); }

vec4 raymarch( in vec3 ro, in vec3 rd, in vec3 bgcol, in ivec2 px )
{
    vec4 sum = vec4(0.0);

    float t = 0.0;//0.05*texelFetch( fragTexture, px&255, 0 ).x;//iChannel0

    MARCH(30,map5);
    MARCH(30,map4);
    MARCH(30,map3);
    MARCH(30,map2);

    return clamp( sum, 0.0, 1.0 );
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

vec4 render( in vec3 ro, in vec3 rd, in ivec2 px )
{
    // background sky
    float sun = clamp( dot(sundir,rd), 0.0, 1.0 );
    vec3 col = vec3(0.6,0.71,0.75) - rd.y*0.2*vec3(1.0,0.5,1.0) + 0.15*0.5;
    col += 0.2*vec3(1.0,.6,0.1)*pow( sun, 8.0 );

    // clouds
    vec4 res = raymarch( ro, rd, col, px );
    col = col*(1.0-res.w) + res.xyz;

    // sun glare
    col += 0.2*vec3(1.0,0.4,0.2)*pow( sun, 3.0 );

    return vec4( col, 1.0 );
}


void main()
{
    //object selected
    if (selected) {
        if(has_texture&&iTime%2==0)
            color = texture(fragTexture, frag_uv);
        else if(has_texturebuffer&&iTime%1==1)
            color = texture(fboTexture, frag_uv);
        else {
            color = vec4(frag_uv,0.0,opacity);
        }
    }
    else {
        vec2 uv = frag_uv.xy;
        //vec2 p = ((vec2(1.5)*normalize(frag_position).xy) - vec2(-0.5)) / iResolution.xy;//adjust point error
        vec2 p = (-iResolution.xy + 2.0*(frag_uv.xy*iResolution.xy))/ iResolution.y;

        vec2 m = iMouse.xy/iResolution.xy;

        // camera
        vec3 ro = 4.0*normalize(vec3(sin(3.0*m.x), 0.4*m.y, cos(3.0*m.x)));
        vec3 ta = vec3(0.0, -1.0, 0.0);
        mat3 ca = setCamera( ro, ta, 0.0 );
        // ray
        vec3 rd = ca * normalize( vec3(p.xy,1.5));

        color = render( ro, rd, ivec2(frag_uv-0.5) );// * texture(fragTexture, uvIndexText);

        // pix selected
        if((uv.x <= iMouse.x+0.05 && uv.x >= iMouse.x-0.05) &&
                (uv.y <= iMouse.y+0.05 && uv.y >= iMouse.y-0.05)){
            // Set fragment color from texture
            color = vec4(1.0,0.0,0.0,1.0);
        }
    }

    //color = vec4(1.0,1.0,0.0,1.0);

}

