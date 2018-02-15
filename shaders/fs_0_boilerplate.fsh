/*
Sample Lines Of Code

For the Sample lines of code I decide to show the main code
of my Art Tool that is used to draw. As it is compacted
into an OpenGL Fragment Shader, the main article with
details of the software are in this <link> if needed.
The code exceeds 400 lines due to all the functions.
So If you could just look at the "main()" function, all
the variables and just the 2 functions it calles you can get
an idea of what is this program about.

*/
#version 330 core
//in vec3  fragColor;
in vec2 frag_uv;
in vec3 frag_position;
in vec3 frag_normal;

uniform sampler2D fragTexture;
uniform sampler2D fragFBOTexture;
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

const int mode = 1;
//const vec3 lightPos = vec3(0.0,0.0,-50.0);
const vec3 ambientColor = vec3(0.0015, 0.0015, 0.0015);
const vec3 diffuseColor = vec3(0.015, 0.015, 0.015);
//const vec3 specColor = vec3(1.0, 0.0, 0.0);
const float shininess = 4096.0;//16.0;
const float screenGamma = 2.2; // Assume the monitor is calibrated to the sRGB color space

uniform vec4        iMode;                  // mode values
uniform vec4        iColor;                 // color values
uniform vec3        iResolution;            // viewport resolution (in pixels)
uniform int         iTime;                  // shader playback time (in seconds)
uniform float       iTimeDelta;             // render time (in seconds)
uniform int         iFrame;                 // shader playback frame
uniform float       iChannelTime[4];        // channel playback time (in seconds)
uniform vec3        iChannelResolution[4];  // channel resolution (in pixels)
uniform vec4        iMouse;                 // mouse pixel coords. xy: current (if MLB down), zw: click
uniform vec4        iPosition;              // object pixel coords. xy: current (if MLB down), zw: click
uniform vec4        iDate;                  // (year, month, day, time in seconds)
// input channel. XX = 2D/Cube
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;

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
            vec2  r = g - f + (0.5+0.5*sin(iTime+6.2831*o));
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

vec3 procedural2dsceen(vec2 uv,vec2 p,int mode){
    vec3 col;
    vec2 q = p - uv;//distance from pixel to point

    if(mode%15==1){//step 1
        col = vec3(1.0,0.4,0.1);
        col *= length(q);//circuler region around point
    }
    else if(mode%15==2){//step 2
        col = vec3(1.0,0.4,0.1);
        float r = 0.2;
        col *= smoothstep(r,r+0.01,length(q));//circle of r radious from point
    }
    else if(mode%15==3){//step 3
        col = vec3(1.0,0.4,0.1);
        float freq = 10.0;//no. of spikes/wave
        float ampl = 0.10;//size. of spikes/wave
        float r = 0.2 + ampl*cos(atan(q.y,q.x)*freq) ;//cos() waves around point
        col *= smoothstep(r,r+0.01,length(q));
    }
    else if(mode%15==4){//step 4
        col = vec3(1.0,0.4,0.1);
        float freq = 10.0;//no. of spikes/wave
        float ampl = 0.10;//size. of spikes/wave
        float warpCircle = 20.0*q.x + 1.0;//warp waves on circle and rotate them
        float r = 0.2 + ampl*cos(atan(q.y,q.x)*freq + warpCircle) ;//cos() waves around point
        col *= smoothstep(r,r+0.01,length(q));
    }
    else if(mode%15==5){//step 5
        col = vec3(1.0,0.4,0.1);
        float freq = 10.0;//no. of spikes/wave
        float ampl = 0.10;//size. of spikes/wave
        float warpCircle = 20.0*q.x + 1.0;//warp waves on circle and rotate them
        float r = 0.2 + ampl*cos(atan(q.y,q.x)*freq + warpCircle) ;//cos() waves around point
        col *= smoothstep(r,r+0.01,length(q));
        r = 0.015;//draw a line parallel to y axis with thickness r
        col *= smoothstep(r,r+0.002,abs(q.x));
    }
    else if(mode%15==6){//step 6
        col = vec3(1.0,0.4,0.1);
        float freq = 10.0;//no. of spikes/wave
        float ampl = 0.10;//size. of spikes/wave
        float warpCircle = 20.0*q.x + 1.0;//warp waves on circle and rotate them
        float r = 0.2 + ampl*cos(atan(q.y,q.x)*freq + warpCircle) ;//cos() waves around point
        col *= smoothstep(r,r+0.01,length(q));
        r = 0.015;//draw a line parallel to y axis with thickness r
        float erase = (1.0 -smoothstep(0.0,0.1,q.y));//erase line by gradient
        col *= 1.0 - (1.0 -smoothstep(r,r+0.002,abs(q.x)))*erase;
    }
    else if(mode%15==7){//step 7
        q = q - vec2(0.3,0.7);//position object on screen
        col = vec3(1.0,0.4,0.1);
        float freq = 10.0;//no. of spikes/wave
        float ampl = 0.10;//size. of spikes/wave
        float warpCircle = 20.0*q.x + 1.0;//warp waves on circle and rotate them
        float r = 0.2 + ampl*cos(atan(q.y,q.x)*freq + warpCircle) ;//cos() waves around point
        col *= smoothstep(r,r+0.01,length(q));
        r = 0.015;//draw a line parallel to y axis with thickness r
        float erase = (1.0 -smoothstep(0.0,0.1,q.y));//erase line by gradient
        col *= 1.0 - (1.0 -smoothstep(r,r+0.002,abs(q.x)))*erase;
    }
    else if(mode%15==8){//step 8
        q = q - vec2(0.3,0.7);//position object on screen
        col = vec3(1.0,0.4,0.1);
        float freq = 10.0;//no. of spikes/wave
        float ampl = 0.10;//size. of spikes/wave
        float warpCircle = 20.0*q.x + 1.0;//warp waves on circle and rotate them
        float r = 0.2 + ampl*cos(atan(q.y,q.x)*freq + warpCircle) ;//cos() waves around point
        col *= smoothstep(r,r+0.01,length(q));
        r = 0.015;//draw a line parallel to y axis with thickness r
        float erase = (1.0 -smoothstep(0.0,0.1,q.y));//erase line by gradient
        float warpLine = -0.25*sin(2.0*q.y);//warp main wave on line to create main curve
        col *= 1.0 - (1.0 -smoothstep(r,r+0.002,abs(q.x + warpLine)))*erase;
    }
    else if(mode%15==9){//step 9
        q = q - vec2(0.3,0.7);//position object on screen
        col = vec3(1.0,0.4,0.1);
        float freq = 10.0;//no. of spikes/wave
        float ampl = 0.10;//size. of spikes/wave
        float warpCircle = 20.0*q.x + 1.0;//warp waves on circle and rotate them
        float r = 0.2 + ampl*cos(atan(q.y,q.x)*freq + warpCircle) ;//cos() waves around point
        col *= smoothstep(r,r+0.01,length(q));
        r = 0.015;//draw a line parallel to y axis with thickness r
        r += 0.002*cos(120.0*q.y);//warp small wave on line
        float erase = (1.0 -smoothstep(0.0,0.1,q.y));//erase line by gradient
        float warpLine = -0.25*sin(2.0*q.y);//warp main wave on line to create main curve
        col *= 1.0 - (1.0 -smoothstep(r,r+0.002,abs(q.x + warpLine)))*erase;
    }
    else if(mode%15==10){//step 10
        q = q - vec2(0.3,0.7);//position object on screen
        col = vec3(1.0,0.4,0.1);
        float freq = 10.0;//no. of spikes/wave
        float ampl = 0.10;//size. of spikes/wave
        float warpCircle = 20.0*q.x + 1.0;//warp waves on circle and rotate them
        float r = 0.2 + ampl*cos(atan(q.y,q.x)*freq + warpCircle) ;//cos() waves around point
        col *= smoothstep(r,r+0.01,length(q));
        r = 0.015;//draw a line parallel to y axis with thickness r
        r += 0.002*cos(120.0*q.y);//warp small wave on line
        r += exp(-40.0*p.y);// add exponential curve for hill
        float erase = (1.0 -smoothstep(0.0,0.1,q.y));//erase line by gradient
        float warpLine = -0.25*sin(2.0*q.y);//warp main wave on line to create main curve
        col *= 1.0 - (1.0 -smoothstep(r,r+0.002,abs(q.x + warpLine)))*erase;
    }
    else if(mode%15>=11){//step 11
        q = q - vec2(0.3,0.7);//position object on screen
        col = mix(vec3(1.0,0.4,0.1),vec3(1.0,0.8,0.3),p.y);//make gradient bg
        float freq = 10.0;//no. of spikes/wave
        float ampl = 0.10;//size. of spikes/wave
        float warpCircle = 20.0*q.x + 1.0;//warp waves on circle and rotate them
        float r = 0.2 + ampl*cos(atan(q.y,q.x)*freq + warpCircle) ;//cos() waves around point
        col *= smoothstep(r,r+0.01,length(q));
        r = 0.015;//draw a line parallel to y axis with thickness r
        r += 0.002*cos(120.0*q.y);//warp small wave on line
        r += exp(-40.0*p.y);// add exponential curve for hill
        float erase = (1.0 -smoothstep(0.0,0.1,q.y));//erase line by gradient
        float warpLine = -0.25*sin(2.0*q.y);//warp main wave on line to create main curve
        col *= 1.0 - (1.0 -smoothstep(r,r+0.002,abs(q.x + warpLine)))*erase;
    }
    else{//default
        col = vec3(uv,0.0);
    }
    return col;
}

/////////////////////////
// 2D Vector functions //
/////////////////////////

//=============IK Solver=============
vec2 solveIKJoint( vec2 p, float l1, float l2 )
{
    vec2 q = p*( 0.5 + 0.5*(l1*l1-l2*l2)/dot(p,p) );

    float s = l1*l1/dot(q,q) - 1.0;

    if( s<0.0 ) return vec2(-100.0);

    return q + q.yx*vec2(-1.0,1.0)*sqrt( s );
}
//=============Interpolate along a segment=============
// use De Casteljau's algorithm
vec2 interpolate(vec2 a, vec2 b, vec2 c, float p)
{
    vec2 v0 = mix(a, b, p);
    vec2 v1 = mix(b, c, p);
    return mix(v0, v1, p);
}
//=============Combine distance field functions=============
float smoothMerge(float d1, float d2, float k)
{
    float h = clamp(0.5 + 0.5*(d2 - d1)/k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0-h);
}
float merge(float d1, float d2)
{
    return min(d1, d2);
}
float mergeExclude(float d1, float d2)
{
    return min(max(-d1, d2), max(-d2, d1));
}
float substract(float d1, float d2)
{
    return max(-d1, d2);
}
float intersect(float d1, float d2)
{
    return max(d1, d2);
}
//=============Rotation and translation=============
vec2 rotateCCW(vec2 p, float a)
{
    mat2 m = mat2(cos(a), sin(a), -sin(a), cos(a));
    return p * m;
}
vec2 rotateCW(vec2 p, float a)
{
    mat2 m = mat2(cos(a), -sin(a), sin(a), cos(a));
    return p * m;
}
vec2 translate(vec2 p, vec2 t)
{
    return p - t;
}
//============= 2D Signed Distance field functions=============
float pie(vec2 p, float angle)
{
    angle = radians(angle) / 2.0;
    vec2 n = vec2(cos(angle), sin(angle));
    return abs(p).x * n.x + p.y*n.y;
}
float circleDist(vec2 p, float radius)
{
    return length(p) - radius;
}
float triangleDist(vec2 p, float radius)
{
    return max(	abs(p).x * 0.866025 +
                p.y * 0.5, -p.y)
            -radius * 0.5;
}
float triangleDist(vec2 p, float width, float height)
{
    vec2 n = normalize(vec2(height, width / 2.0));
    return max(	abs(p).x*n.x + p.y*n.y - (height*n.y), -p.y);
}
float semiCircleDist(vec2 p, float radius, float angle, float width)
{
    width /= 2.0;
    radius -= width;
    return substract(pie(p, angle),
                     abs(circleDist(p, radius)) - width);
}
float boxDist(vec2 p, vec2 size, float radius)
{
    size -= vec2(radius);
    vec2 d = abs(p) - size;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - radius;
}
float lineDist(vec2 p, vec2 start, vec2 end, float width)
{
    vec2 dir = start - end;
    float lngth = length(dir);
    dir /= lngth;
    vec2 proj = max(0.0, min(lngth, dot((start - p), dir))) * dir;
    return length( (start - p) - proj ) - (width / 2.0);
}
//============= 3D Signed Distance field functions=============
float sphereDist( vec3 p, float s )
{
    return length(p)-s;
}
//=============Masks for drawing=============
float fillMask(float dist)
{
    return clamp(-dist, 0.0, 1.0);
}
float innerBorderMask(float dist, float width)
{
    //dist += 1.0;
    float alpha1 = clamp(dist + width, 0.0, 1.0);
    float alpha2 = clamp(dist, 0.0, 1.0);
    return alpha1 - alpha2;
}
float outerBorderMask(float dist, float width)
{
    //dist += 1.0;
    float alpha1 = clamp(dist, 0.0, 1.0);
    float alpha2 = clamp(dist - width, 0.0, 1.0);
    return alpha1 - alpha2;
}
//=============Bezier, Quadratic=============
#define ANIMATED
#define SHOW_CONTROL_POINTS
#define SHOW_SEGMENT_POINTS
#define STEPS  10.0
#define STROKE 0.2
#define SKELETON 3.0
#define EPS    0.01
float ip_control(vec2 uv, vec2 a, vec2 b, vec2 c, float width)
{
    float l0 = lineDist(uv, a, b, width);//sharpen(sdSegment(uv, a, b), EPS * .6);
    float l1 = lineDist(uv, b, c, width);//sharpen(sdSegment(uv, b, c), EPS * .6);

    return merge(l0,l1);
}

float ip_point(vec2 uv, vec2 a, vec2 b, vec2 c, float width, float stepID)
{
    vec2 p = interpolate(a, b, c, mod(stepID * 2., STEPS) / 10.);

    return circleDist(translate(uv, p), width);
    //return fillMask(circleDist(translate(uv, p), 25.0025));
    //return sharpen(sdCircleOutline(uv, p, .0025), EPS * 1.);
}

float ip_curve(vec2 uv, vec2 a, vec2 b, vec2 c, float width)
{
    float e = 0.;
    for (float i = 0.; i < STEPS; ++i)
    {
        vec2  p0 = interpolate(a, b, c, (i   ) / STEPS);
        vec2  p1 = interpolate(a, b, c, (i+1.) / STEPS);
        float l = lineDist(uv, p0,  p1, width);//sharpen(sdSegment(uv, p0, p1), EPS * STROKE);
        //e += max(e, l);
        e = merge(e,l);
    }

    return e;
}

float ip_curveThick(vec2 uv, vec2 a, vec2 b, vec2 c, float width)
{
    float e = 0.;
    for (float i = 0.; i < STEPS; ++i)
    {
        vec2  p0 = interpolate(a, b, c, (i   ) / STEPS);
        vec2  p1 = interpolate(a, b, c, (i+1.) / STEPS);
        float segGradient  = (STEPS-i)/STEPS;
        float l = lineDist(uv, p0,  p1, width*segGradient);//sharpen(sdSegment(uv, p0, p1), EPS * SKELETON * segGradient);
        //e += max(e, l);
        e = merge(e,l);
    }

    return e;
}

//=============Scene=============
vec4 scene2DDist(vec2 p){

    float scaleW = 20.0;
    float scaleH = 20.0;
    vec4 col = vec4(0.0, 0.0, 0.0, 0.0);
    float c = circleDist(translate(p, vec2(100, 250)), scaleW);
    float b1 =  boxDist(translate(p, vec2(200, 250)), vec2(scaleW, scaleH), 0.0);
    float b2 =  boxDist(translate(p, vec2(300, 250)), vec2(scaleW, scaleH), 10.0);
    float l = lineDist(p, vec2(370, 220),  vec2(430, 280), 10.0);
    float t1 = triangleDist( translate(p, vec2(500, 210)), scaleW*2.0, scaleH*2.0);
    float t2 = triangleDist( rotateCW(translate(p, vec2(600, 250)), iTime), scaleW);

    float m = c;
    m = merge(m, b1);
    m = merge(m, b2);
    m = merge(m, l);
    m = merge(m, t1);
    m = merge(m, t2);

    int timeCycle = iFrame/30;
    float b3 = boxDist(	translate(p, vec2(100, sin(timeCycle * 3.0 + 1.0) * scaleW + 100.0)),
                                vec2(scaleW, scaleH/3.0), 	0.0);
    float c2 = circleDist( translate(p, vec2(100, 100)), scaleW);
    float s = substract(b3, c2);

    float b4 = boxDist( translate(p, vec2(200, sin(timeCycle * 3.0 + 2.0) * scaleW + 100.0)),
                                vec2(scaleW, scaleH/3.0), 	0.0);
    float c3 = circleDist( translate(p, vec2(200, 100)), scaleW);
    float i = intersect(b4, c3);

    float b5 = boxDist( translate(p, vec2(300, sin(timeCycle * 3.0 + 3.0) * scaleW + 100.0)),
                                vec2(scaleW, scaleH/3.0), 0.0);
    float c4 = circleDist( translate(p, vec2(300, 100)), scaleW);
    float a = merge(b5, c4);

    float b6 = boxDist(	translate(p, vec2(400, 100)), vec2(scaleW, scaleH/3.0), 0.0);
    float c5 = circleDist( translate(p, vec2(400, 100)), scaleW);
    float sm = smoothMerge(b6, c5, 10.0);

    float sc = semiCircleDist(translate(p, vec2(500,100)), scaleW, 90.0, 10.0);

    float b7 = boxDist(	translate(p, vec2(600, sin(timeCycle * 3.0 + 3.0) * scaleW + 100.0)),
                                vec2(scaleW, 15), 	0.0);
    float c6 = circleDist( translate(p, vec2(600, 100)), scaleW);
    float e = mergeExclude(b7, c6);

    m = merge(m, s);
    m = merge(m, i);
    m = merge(m, a);
    m = merge(m, sm);
    m = merge(m, sc);
    m = merge(m, e);

    //---2D Object Scene---
    // shape distancemap
    //col = mix(col, vec4(0.0, 0.0, 0.4, 1.0), m);
    // shape fill
    col = mix(col, vec4(1.0, 0.4, 0.0, 1.0), fillMask(m));
    // shape outline
    col = mix(col, vec4(0.1, 0.1, 0.1, 1.0), innerBorderMask(m, 05.0));
    // shape outline
    col = mix(col, vec4(0.9, 0.9, 0.9, 1.0), outerBorderMask(m, 05.0));

    return col;
}

vec4 scene2DCurve(vec2 a,vec2 b,vec2 c){
    float scaleW = 10.0;
    float scaleH = 10.0;
    vec2 uv2d = vec2(0.0,0.0);
    vec4 col = vec4(0.0, 0.0, 0.0, 0.0);

    //Draw three points a,b,c
    float point1 = circleDist(a, scaleW);
    float point2 = circleDist(b, scaleW);
    float point3 = circleDist(c, scaleW);
    float m = 0.0;
    m = merge(m, point1);
    m = merge(m, point2);
    m = merge(m, point3);

    //Draw A IKBones Given two points a,c
//    float l1 = 0.5;
//    float l2 = 0.4;
//    vec2 ikJoint = solveIKJoint( b, l1, l2 );
//    float line1 = lineDist(uv2d, a,  c, scaleW/2);
//    float line2 = lineDist(uv2d, c,  ikJoint, scaleW/2);
//    float ikJointPoint = circleDist(ikJoint, scaleW);
//    m = merge(m, line1);
//    m = merge(m, line2);
//    m = merge(m, ikJointPoint);

    //Draw A Bezier Curve Given three points a,b,c (Parabolic Arc)
    //control points and line segments
    float d0 = ip_control(uv2d, a, b, c, 2.5);
    float point = 0.0;
    //#ifdef ANIMATED
    // active segment point
    point = ip_point(uv2d, a, b, c, 5.0, iFrame * 0.01);
    //#endif
    //Bezier curve
    float d1 = ip_curve(uv2d, a, b, c, 10.0);
    //Bezier curve with Thickness
    float d2 = ip_curveThick(uv2d, a, b, c, 10.0);
    float l3 = lineDist(uv2d, a, c, 5.0);
//    m = merge(m, d0);
//    m = merge(m, point);
//    m = merge(m, d1);
//    m = merge(m, d2);

    //---2D Curve Scene---
    // shape distancemap
    //col = mix(col, vec4(0.0, 0.0, 0.4, 1.0), scene2DCurve(uv2d-a,uv2d-b,uv2d-c));
    // shape fill
    col = mix(col, vec4(1.0, 0.4, 0.0, 1.0), fillMask(point1));
    col = mix(col, vec4(0.4, 0.6, 0.0, 1.0), fillMask(point2));
    col = mix(col, vec4(1.0, 0.0, 0.4, 1.0), fillMask(point3));
    col = mix(col, vec4(0.2, 0.4, 0.0, 1.0), fillMask(l3));
    col = mix(col, vec4(0.2, 0.35, 0.55, 1.0), fillMask(d0));
    col = mix(col, vec4(0.9, 0.43, 0.34, 1.0), fillMask(point));
    col = mix(col, vec4(1.0, 0.4, 1.0, 1.0), fillMask(d1));
    col = mix(col, vec4(0.2, 0.4, 0.0, 1.0), fillMask(d2));
    // shape inline
    col = mix(col, vec4(0.1, 0.1, 0.1, 1.0), innerBorderMask(point, 02.50));
    // shape outline
    col = mix(col, vec4(0.9, 0.9, 0.9, 1.0), outerBorderMask(point, 02.50));

    col = clamp(col, 0.0, 1.0);

    float opc = 0.0;
    if((col.x+col.y+col.z)>0.01){
        opc = 1.0;
    }
    col = vec4(col.xyz,opc);

    return col;
}

//float sceneSmooth(vec2 p, float r)
//{
//    float accum = scene2DDist(p);
//    accum += scene2DDist(p + vec2(0.0, r));
//    accum += scene2DDist(p + vec2(0.0, -r));
//    accum += scene2DDist(p + vec2(r, 0.0));
//    accum += scene2DDist(p + vec2(-r, 0.0));
//    return accum / 5.0;
//}

vec4 draw2DScene(vec2 uv,vec4 p, vec3 colBase){
    vec4 col;
    //vec2 q = vec2(2.0)*(uv+vec2(-0.5));//offset uv to center

    //transpose coordinates from (0.0,0.0)-(1.0,1.0) to (-1.0,-1.0)-(1.0,1.0)
    //and divide it into viewport pixels
    vec2 uv2d = -1.0 + 2.0*uv;
    uv2d = uv2d*iResolution.xy/2;
    vec2 mo1 = -1.0 + 2.0*iMouse.xy;
    mo1 = mo1*iResolution.xy/2;
    vec2 mo2 = (-1.0 + 2.0*iMouse.zw);
    mo2 = mo2*iResolution.xy/2;
    vec2 p0 = -1.0 + 2.0*p.xy;
    p0 = p0*iResolution.xy/2;
    vec2 p1 = -1.0 + 2.0*p.zw;
    p1 = p1*iResolution.xy/2;
    vec2 sinAnim = vec2(1.0+0.2*sin(iTime),0.2+0.3*sin(iTime*3.3));

    float l1 = 0.5;
    float l2 = 0.4;
    vec2 a = p0;//mo1;
    vec2 c = p1;//mo2;
    float stepID = iFrame * 0.01;
    float t = mod(stepID * 2., STEPS) / 10.;
    vec2 b =  vec2(0.0,0.0);//mix(a, c, t);//vec2(0.0,0.0);

    //Get Base Texture
    vec3 colIK = colBase;
    col = vec4(0.0, 0.0, 0.0, 0.0);

    vec2 pointOnCanves = uv2d-mo2;//distance between pixel and spriteCenter

    //float radious = 025.0;
    //float borderWidth = 05.0;
    //float feather = 02.50;
    //float distObject = scene2DDist(pointOnCanves);
    //float distBorder = scene2DDist(pointOnCanves)-distObject;
    //    distObject = smoothstep(radious,
    //                            radious-feather,
    //                            circleDist(pointOnCanves, radious));
    //    distBorder = smoothstep(radious+borderWidth,
    //                            radious+borderWidth-feather,
    //                            circleDist(pointOnCanves, radious+borderWidth))-distObject;
    //col = mix(col, vec4(1.0, 0.4, 0.0, 1.0), distObject);
    //col = mix(col, vec4(0.1, 0.1, 0.1, 1.0), distBorder);

    //---2D Object Scene---
    // shape distancemap
    //col = mix(col, vec4(0.0, 0.0, 0.4, 1.0), scene2DDist(pointOnCanves));
    // shape fill
    //col = mix(col, vec4(1.0, 0.4, 0.0, 1.0), fillMask(scene2DDist(pointOnCanves)));
    // shape outline
    //col = mix(col, vec4(0.1, 0.1, 0.1, 1.0), innerBorderMask(scene2DDist(pointOnCanves), 05.0));
    // shape outline
    //col = mix(col, vec4(0.9, 0.9, 0.9, 1.0), outerBorderMask(scene2DDist(pointOnCanves), 05.0));

    //---2D Curve Scene---
    // shape distancemap
    //col = mix(col, vec4(0.0, 0.0, 0.4, 1.0), scene2DCurve(uv2d-a,uv2d-b,uv2d-c));
    // shape fill
//    col = mix(col, vec4(1.0, 0.4, 0.0, 1.0), fillMask(scene2DCurve(uv2d-a,uv2d-b,uv2d-c)));
    // shape outline
//    col = mix(col, vec4(0.1, 0.1, 0.1, 1.0), innerBorderMask(scene2DCurve(uv2d-a,uv2d-b,uv2d-c), 05.0));
    // shape outline
//    col = mix(col, vec4(0.9, 0.9, 0.9, 1.0), outerBorderMask(scene2DCurve(uv2d-a,uv2d-b,uv2d-c), 05.0));

//    col = clamp(col, 0.0, 1.0);

    //return scene2DDist(pointOnCanves);
    return scene2DCurve(uv2d-a,uv2d-b,uv2d-c);
}

layout(location = 0) out vec4 color;
void main(void)
{

    vec4 computedcolor;
    vec2 uv = frag_uv.xy ;//uv range is from 0.0 to 0.999
    vec2 p = iMouse.xy;//vec2(0.999)//vec2(0.5)//iMouse.xy//adjust point error
    int mode = iTime;
    vec3 col;

    //select base color
    if (iMode.x==0.0) computedcolor = vec4(0.0,0.0,0.0,0.0);
    if (iMode.x==1.0) computedcolor = vec4(1.0,1.0,1.0,1.0);
    if (iMode.x==2.0) computedcolor = vec4(frag_uv,0.0,1.0);
    if (iMode.x==3.0) computedcolor = vec4(vec3(uv,0.5+0.5*sin((float(iTime)/10)+(float(iFrame)/100))),1.0);
    if (iMode.x==4.0) computedcolor = iColor;
    if (iMode.x==5.0) {
        //grid texture
        float scale = 100.0;//number of squares
        vec2 center = p;//grid center
        computedcolor = vec4(grid( uv,center,scale ),1.0);
    }
    if (iMode.x==6.0) computedcolor = texture(fragTexture, frag_uv);

    if (iMode.w==0.25) computedcolor *= texture(fragFBOTexture, frag_uv);
    if (iMode.w==0.5) computedcolor *= texture(iChannel0, frag_uv);
    if (iMode.w==1.0) computedcolor *= texture(iChannel1, frag_uv);
    if (iMode.w==2.0) computedcolor *= texture(iChannel2, frag_uv);
    if (iMode.w==3.0) computedcolor *= texture(iChannel3, frag_uv);

    //add computation
    if (iMode.z==1.0) {
        // draw sample scene
        computedcolor *= vec4(procedural2dsceen(uv,iMouse.xy,mode),1.0);
    }
    if (iMode.z==2.0) {
        //draw Bezier Curve
        computedcolor *= draw2DScene(uv,iPosition,computedcolor.xyz);
    }

    //border
    //if(uv.x<=0.001||uv.y<=0.001||uv.x>=0.999||uv.y>=0.999||uv.y==0.5)
    //computedcolor += vec4(1.0,0.0,0.0,1.0);

    //add opacity
    computedcolor = vec4(computedcolor.xyz,computedcolor.w*opacity);

    color = computedcolor;



}
