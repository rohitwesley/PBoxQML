/****************************************************************************
** Contact: https://wes.tecrt.co
** Developer: Rohit Wesley Thomas
**
** Draw a B-Spline Give 3 points in space
**
** For the Sample lines of code I decide to show one of the features of my
** Personal Art Tool.
** Code Repository : https://github.com/rohitwesley/PBoxQML.git
** Code Explanation: http://wes.tecrt.co/page_project.html
**
** Bézier curve using Parabolic Arcs: https://www.khanacademy.org/partner-content/pixar/environment-modeling-2/animating-parabolas-ver2/v/environment-modeling3
** De Casteljau's algorithm to interpolate : https://www.khanacademy.org/partner-content/pixar/animate/parametric-curves/v/animation7
**
****************************************************************************/
#version 330 core
//in vec3  fragColor;
in vec2 frag_uv;
in vec3 frag_position;
in vec3 frag_normal;

uniform sampler2D fragTexture;
uniform sampler2D fragFBOTexture;
uniform float opacity;
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

#define STEPS  20.0
#define STEPSSPEED  2.5
// HSV to RGB conversion
// [iq: https://www.shadertoy.com/view/MsS3Wc]
vec3 hsv2rgb_smooth(float x, float y, float z) {
    vec3 rgb = clamp( abs(mod(x*6.+vec3(0.,4.,2.),6.)-3.)-1., 0., 1.);
    rgb = rgb*rgb*(3.-2.*rgb); // cubic smoothing
    return z * mix( vec3(1), rgb, y);
}
vec3  hash3( float n ) { return fract(sin(vec3(n,n+7.3,n+13.7))*1313.54531); }
vec3 noise33( in float x )
{
    float p = floor(x);
    float f = fract(x);
    f = f*f*(3.0-2.0*f);
    return mix( hash3(p+0.0), hash3(p+1.0), f );
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
//=============Height map to normal map	=============
float getHeight(vec2 uv) {
    return texture(iChannel0, uv).r;
}
vec4 bumpFromDepth(vec2 uv, vec2 resolution, float scale) {
    vec2 step = 1. / resolution;

    float height = getHeight(uv);

    vec2 dxy = height - vec2(
                getHeight(uv + vec2(step.x, 0.)),
                getHeight(uv + vec2(0., step.y))
                );

    return vec4(normalize(vec3(dxy * scale / step, 1.)), height);
}

//=============Interpolate along a segment=============
// use De Casteljau's algorithm
vec4 interpolate1dg(vec4 a, vec4 b, float p)
{
    vec4 v0 = mix(a, b, p);
    return v0;
}
vec4 interpolate2dg(vec4 a, vec4 b, vec4 c, float p)
{
    vec4 v0 = mix(a, b, p);
    vec4 v1 = mix(b, c, p);

    vec4 v2 = mix(v0, v1, p);
    return v2;
}
vec4 interpolate3dg(vec4 a, vec4 b, vec4 c,  vec4 d, float p)
{
    vec4 v0 = mix(a, b, p);
    vec4 v1 = mix(b, c, p);
    vec4 v2 = mix(c, d, p);

    vec4 v3 = mix(v0, v1, p);
    vec4 v4 = mix(v1, v2, p);

    vec4 v5 = mix(v3, v4, p);
    return v5;
}
vec4 interpolate4dg(vec4 a, vec4 b, vec4 c,  vec4 d, vec4 e, float p)
{
    vec4 v0 = mix(a, b, p);
    vec4 v1 = mix(b, c, p);
    vec4 v2 = mix(c, d, p);
    vec4 v3 = mix(d, e, p);

    vec4 v4 = mix(v0, v1, p);
    vec4 v5 = mix(v1, v2, p);
    vec4 v6 = mix(v2, v3, p);

    vec4 v7 = mix(v4, v5, p);
    vec4 v8 = mix(v5, v6, p);

    vec4 v9 = mix(v7, v8, p);
    return v9;
}

//============= Domain functions=============
//domain deformations
vec3 opTwist( vec3 p )
{
    float c = cos(20.0*p.y);
    float s = sin(20.0*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xz,p.y);
    return q;
}
vec3 opTwist( vec3 p, float k )
{
    float cx = -0.1;
    p.x -= cx;
    float  c = cos(k);
    float  s = sin(k);
    mat2   m = mat2(c,-s,s,c);
    vec2   q = m*p.xz;
    return vec3(q.x+cx,p.y,q.y);
}
vec3 opCheapBend( vec3 p )
{
    float c = cos(20.0*p.y);
    float s = sin(20.0*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xy,p.z);
    return q;
}
vec3 opRepetition( vec3 p, vec3 c )
{
    vec3 q = mod(p,c)-0.5*c;
    return q;
}
//domain operations
//2d coordinates (z=0.0,w=0.0)
vec4 rotateCCW(vec4 p, float a)
{
    mat2 m = mat2(cos(a), sin(a), -sin(a), cos(a));
    return vec4((p.xy * m),p.z,p.w);
}
vec4 rotateCW(vec4 p, float a)
{
    mat2 m = mat2(cos(a), -sin(a), sin(a), cos(a));
    return vec4((p.xy * m),p.z,p.w);
}
vec4 translate(vec4 p, vec4 t)
{
    return p - t;
}
//3d coordinates (w=0.0)
//vec3 opTx( vec3 p, mat4 m )
//{
//    vec3 q = invert(m)*p;
//    return q;
//}
vec3 opScale( vec3 p, float s )
{
    //return primitive(p/s)*s;
    return p/s;
}
//============= Signed Distance field functions=============
//============= Utilities=============
// polynomial smooth min (k = 0.1);
float smin( float a, float b, float k )
{
    float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}
vec2 smin( vec2 a, vec2 b, float k )
{
    float h = clamp( 0.5 + 0.5*(b.x-a.x)/k, 0.0, 1.0 );
    return vec2( mix( b.x, a.x, h ) - k*h*(1.0-h), mix( b.y, a.y, h ) );
}
vec4 smin( vec4 a, vec4 b, float k )
{
    float h = clamp( 0.5 + 0.5*(b.x-a.x)/k, 0.0, 1.0 );
    return vec4( mix( b.x, a.x, h ) - k*h*(1.0-h), mix( b.yzw, a.yzw, h ) );
}
float smax( float a, float b, float k )
{
    float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
    return mix( a, b, h ) + k*h*(1.0-h);
}
vec3 smax( vec3 a, vec3 b, float k )
{
    vec3 h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
    return mix( a, b, h ) + k*h*(1.0-h);
}

//=============Deformation and Combination distance field functions=============
//distance deformations
float opBlend(float d1, float d2)
{
    float k = 1.0;
    return smin(d1, d2, k);
}
float opDisplace( vec3 p ,float primitive)
{
    float displacement = sin(20*p.x)*sin(20*p.y)*sin(20*p.z);
    return primitive+displacement;
}
//distance operations
float opUnion( float d1, float d2 )
{
    return min(d1,d2);
}
vec2 opUnion( vec2 d1, vec2 d2 )
{
    return (d1.x<d2.x) ? d1 : d2;
}
float opSubstraction( float d1, float d2 )
{
    return max(-d1,d2);
}
float opIntersection( float d1, float d2 )
{
    return max(d1,d2);
}
//=============BasicShapes=============
float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}
float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}
//=============Bezier, Quadratic=============
//Draw Points on Bézier curve using Parabolic Arcs
float drawPoint0dg(vec4 sampleUVPixel, vec4 a, float scale) {
    return sdSphere(translate(sampleUVPixel, a).xyz, scale);
}
float drawPoint1dg(vec4 sampleUVPixel, vec4 a, vec4 b, float width, float stepID) {

    vec4 p = interpolate1dg(a, b, mod(stepID * 2., STEPSSPEED) / STEPSSPEED);
    return drawPoint0dg(sampleUVPixel, p, width);
}
float drawPoint2dg(vec4 sampleUVPixel, vec4 a, vec4 b, vec4 c, float width, float stepID) {
    vec4 p = interpolate2dg(a, b, c, mod(stepID * 2., STEPSSPEED) / STEPSSPEED);
    return drawPoint0dg(sampleUVPixel, p, width);
}
float drawPoint3dg(vec4 sampleUVPixel, vec4 a, vec4 b, vec4 c, vec4 d, float width, float stepID)  {
    vec4 p = interpolate3dg(a, b, c, d, mod(stepID * 2., STEPSSPEED) / STEPSSPEED);
    return drawPoint0dg(sampleUVPixel, p, width);
}

//Draw Bézier curve using Parabolic Arcs
float drawCurve1dg(vec4 sampleUVPixel, vec4 a, vec4 b, float width) {
    return sdCapsule(sampleUVPixel.xyz,a.xyz,b.xyz, width);
}
float drawCurve2dg(vec4 sampleUVPixel, vec4 a, vec4 b, vec4 c, float width) {
    float e = 1.;
    for (float i = 0.; i < STEPS; ++i)
    {
        vec4  p0 = interpolate2dg(a, b, c, (i   ) / STEPS);
        vec4  p1 = interpolate2dg(a, b, c, (i+1.) / STEPS);
        float l = drawCurve1dg(sampleUVPixel,p0,p1, width);
        e = opBlend(e,l);
    }
    return e;
}
float drawCurve3dg(vec4 sampleUVPixel, vec4 a, vec4 b, vec4 c, vec4 d, float width) {
    float e = 1.;
    for (float i = 0.; i < STEPS; ++i)
    {
        vec4  p0 = interpolate3dg(a, b, c, d,(i   ) / STEPS);
        vec4  p1 = interpolate3dg(a, b, c, d,(i+1.) / STEPS);
        float l = drawCurve1dg(sampleUVPixel,p0,p1, width);
        e = opBlend(e,l);
    }
    return e;

}

//-----------------------------------------------------------------------------------

// undefine this for animation
#define ANIMATE
// undefine to compare to linear segments
//#define USELINEAR
#define SHOW_BOUNDINGBOX   1
#define SHOW_CONTROLPOINTS 1

#define CP00 sin(iFrame*0.30) * 0.5 + 0.5
#define CP01 sin(iFrame*0.10) * 0.5 + 0.5
#define CP02 sin(iFrame*0.70) * 0.5 + 0.5
#define CP03 sin(iFrame*0.52) * 0.5 + 0.5

#define CP10 sin(iFrame*0.20) * 0.5 + 0.5
#define CP11 sin(iFrame*0.40) * 0.5 + 0.5
#define CP12 sin(iFrame*0.80) * 0.5 + 0.5
#define CP13 sin(iFrame*0.61) * 0.5 + 0.5

#define CP20 sin(iFrame*0.50) * 0.5 + 0.5
#define CP21 sin(iFrame*0.90) * 0.5 + 0.5
#define CP22 sin(iFrame*0.60) * 0.5 + 0.5
#define CP23 sin(iFrame*0.32) * 0.5 + 0.5

#define CP30 sin(iFrame*0.27) * 0.5 + 0.5
#define CP31 sin(iFrame*0.64) * 0.5 + 0.5
#define CP32 sin(iFrame*0.18) * 0.5 + 0.5
#define CP33 sin(iFrame*0.95) * 0.5 + 0.5

#define CPMin (min(CP00,min(CP01,min(CP02,min(CP03, min(CP10,min(CP11,min(CP12,min(CP13, min(CP20,min(CP21,min(CP22,min(CP23, min(CP30,min(CP31,min(CP32,CP33)))))))))))))))-0.005)

#define CPMax (max(CP00,max(CP01,max(CP02,max(CP03, max(CP10,max(CP11,max(CP12,max(CP13, max(CP20,max(CP21,max(CP22,max(CP23, max(CP30,max(CP31,max(CP32,CP33)))))))))))))))+0.005)

#define FLT_MAX 3.402823466e+38

vec3 light = normalize(vec3(-0.2,0.6,0.9));
// use to define bezier type
int bezierType=2;
// undefine this for animation
#define ANIMATE
// undefine to compare to linear segments
//#define USELINEAR
#define METHOD 1
// method 0 : approximate http://research.microsoft.com/en-us/um/people/hoppe/ravg.pdf
// method 1 : exact       https://www.shadertoy.com/view/ltXSDB
#if METHOD==0
float det( vec2 a, vec2 b ) { return a.x*b.y-b.x*a.y; }
vec3 getClosest( vec2 b0, vec2 b1, vec2 b2 )
{

    float a =     det(b0,b2);
    float b = 2.0*det(b1,b0);
    float d = 2.0*det(b2,b1);
    float f = b*d - a*a;
    vec2  d21 = b2-b1;
    vec2  d10 = b1-b0;
    vec2  d20 = b2-b0;
    vec2  gf = 2.0*(b*d21+d*d10+a*d20); gf = vec2(gf.y,-gf.x);
    vec2  pp = -f*gf/dot(gf,gf);
    vec2  d0p = b0-pp;
    float ap = det(d0p,d20);
    float bp = 2.0*det(d10,d0p);
    float t = clamp( (ap+bp)/(2.0*a+b+d), 0.0 ,1.0 );
    return vec3( mix(mix(b0,b1,t), mix(b1,b2,t),t), t );
}
vec2 sdBezier( vec3 a, vec3 b, vec3 c, vec3 p )
{
    vec3 w = normalize( cross( c-b, a-b ) );
    vec3 u = normalize( c-b );
    vec3 v = normalize( cross( w, u ) );

    vec2 a2 = vec2( dot(a-b,u), dot(a-b,v) );
    vec2 b2 = vec2( 0.0 );
    vec2 c2 = vec2( dot(c-b,u), dot(c-b,v) );
    vec3 p3 = vec3( dot(p-b,u), dot(p-b,v), dot(p-b,w) );

    vec3 cp = getClosest( a2-p3.xy, b2-p3.xy, c2-p3.xy );

    return vec2( sqrt(dot(cp.xy,cp.xy)+p3.z*p3.z), cp.z );
}
#endif
#if METHOD==1
vec2 sdBezier(vec3 A, vec3 B, vec3 C, vec3 pos)
{
    vec3 a = B - A;
    vec3 b = A - 2.0*B + C;
    vec3 c = a * 2.0;
    vec3 d = A - pos;

    float kk = 1.0 / dot(b,b);
    float kx = kk * dot(a,b);
    float ky = kk * (2.0*dot(a,a)+dot(d,b)) / 3.0;
    float kz = kk * dot(d,a);

    vec2 res;

    float p = ky - kx*kx;
    float p3 = p*p*p;
    float q = kx*(2.0*kx*kx - 3.0*ky) + kz;
    float h = q*q + 4.0*p3;

    if(h >= 0.0)
    {
        h = sqrt(h);
        vec2 x = (vec2(h, -h) - q) / 2.0;
        vec2 sampleUVPixel = sign(x)*pow(abs(x), vec2(1.0/3.0));
        float t = sampleUVPixel.x + sampleUVPixel.y - kx;
        t = clamp( t, 0.0, 1.0 );

        // 1 root
        vec3 qos = d + (c + b*t)*t;
        res = vec2( length(qos),t);
    }
    else
    {
        float z = sqrt(-p);
        float v = acos( q/(p*z*2.0) ) / 3.0;
        float m = cos(v);
        float n = sin(v)*1.732050808;
        vec3 t = vec3(m + m, -n - m, n - m) * z - kx;
        t = clamp( t, 0.0, 1.0 );

        // 3 roots
        vec3 qos = d + (c + b*t.x)*t.x;
        float dis = dot(qos,qos);

        res = vec2(dis,t.x);

        qos = d + (c + b*t.y)*t.y;
        dis = dot(qos,qos);
        if( dis<res.x ) res = vec2(dis,t.y );

        qos = d + (c + b*t.z)*t.z;
        dis = dot(qos,qos);
        if( dis<res.x ) res = vec2(dis,t.z );

        res.x = sqrt( res.x );
    }

    return res;
}
#define U(a,b) (a.x*b.y-b.x*a.y)
// Distance to Bezier
// inspired by [iq:https://www.shadertoy.com/view/ldj3Wh]
// calculate distance to 2D bezier curve on xy but without forgeting the z component of p
// total distance is corrected using pytagore just before return
vec2 sdBezier(vec2 m, vec2 n, vec2 o, vec3 p) {
    vec2 q = p.xy;
    m-= q; n-= q; o-= q;
    float x = U(m, o), y = 2. * U(n, m), z = 2. * U(o, n);
    vec2 i = o - m, j = o - n, k = n - m,
            s = 2. * (x * i + y * j + z * k),
            r = m + (y * z - x * x) * vec2(s.y, -s.x) / dot(s, s);
    float t = clamp((U(r, i) + 2. * U(k, r)) / (x + x + y + z), 0.,1.); // parametric position on curve
    r = m + t * (k + k + t * (j - k)); // distance on 2D xy space
    return vec2(sqrt(dot(r, r) + p.z * p.z), t); // distance on 3D space
}
#endif
#if METHOD==2
// Test if point p crosses line (a, b), returns sign of result
float testCross(vec2 a, vec2 b, vec2 p) {
    return sign((b.y-a.y) * (p.x-a.x) - (b.x-a.x) * (p.y-a.y));
}
// Determine which side we're on (using barycentric parameterization)
float signBezier(vec2 A, vec2 B, vec2 C, vec2 p)
{
    vec2 a = C - A, b = B - A, c = p - A;
    vec2 bary = vec2(c.x*b.y-b.x*c.y,a.x*c.y-c.x*a.y) / (a.x*b.y-b.x*a.y);
    vec2 d = vec2(bary.y * 0.5, 0.0) + 1.0 - bary.x - bary.y;
    return mix(sign(d.x * d.x - d.y), mix(-1.0, 1.0,
                                          step(testCross(A, B, p) * testCross(B, C, p), 0.0)),
               step((d.x - d.y), 0.0)) * testCross(A, C, B);
}
// Solve cubic equation for roots
vec3 solveCubic(float a, float b, float c)
{
    float p = b - a*a / 3.0, p3 = p*p*p;
    float q = a * (2.0*a*a - 9.0*b) / 27.0 + c;
    float d = q*q + 4.0*p3 / 27.0;
    float offset = -a / 3.0;
    if(d >= 0.0) {
        float z = sqrt(d);
        vec2 x = (vec2(z, -z) - q) / 2.0;
        vec2 sampleUVPixel = sign(x)*pow(abs(x), vec2(1.0/3.0));
        return vec3(offset + sampleUVPixel.x + sampleUVPixel.y);
    }
    float v = acos(-sqrt(-27.0 / p3) * q / 2.0) / 3.0;
    float m = cos(v), n = sin(v)*1.732050808;
    return vec3(m + m, -n - m, n - m) * sqrt(-p / 3.0) + offset;
}
// Find the signed distance from a point to a bezier curve
float sdBezier(vec2 A, vec2 B, vec2 C, vec2 p)
{
    B = mix(B + vec2(1e-4), B, abs(sign(B * 2.0 - A - C)));
    vec2 a = B - A, b = A - B * 2.0 + C, c = a * 2.0, d = A - p;
    vec3 k = vec3(3.*dot(a,b),2.*dot(a,a)+dot(d,b),dot(d,a)) / dot(b,b);
    vec3 t = clamp(solveCubic(k.x, k.y, k.z), 0.0, 1.0);
    vec2 pos = A + (c + b*t.x)*t.x;
    float dis = length(pos - p);
    pos = A + (c + b*t.y)*t.y;
    dis = min(dis, length(pos - p));
    pos = A + (c + b*t.z)*t.z;
    dis = min(dis, length(pos - p));
    return dis;    // * signBezier(A, B, C, p);  //No need for this sign
}
#endif
#if METHOD==3
// Find the signed distance from a point to a bezier curve
float sdBezier(vec2 a, vec2 b, vec2 c, vec2 p)
{
    // Compute vectors
    vec2 v0 = c.xy - a.xy;
    vec2 v1 = b.xy - a.xy;
    vec2 v2 = p.xy - a.xy;

    // Compute dot products
    float dot00 = dot(v0, v0);
    float dot01 = dot(v0, v1);
    float dot02 = dot(v0, v2);
    float dot11 = dot(v1, v1);
    float dot12 = dot(v1, v2);

    // Compute barycentric coordinates
    float invDenom = 1.0 / (dot00 * dot11 - dot01 * dot01);
    float u = (dot11 * dot02 - dot01 * dot12) * invDenom;
    float v = (dot00 * dot12 - dot01 * dot02) * invDenom;

    // use the blinn and loop method
    float w = (1.0 - u - v);
    vec2 textureCoord = u * vec2(0.0,0.0) + v * vec2(0.5,0.0) + w * vec2(1.0,1.0);
    float surface = textureCoord.x * textureCoord.x - textureCoord.y;
    // use the sign of the result to decide between grey or black
    float insideOutside = sign(textureCoord.x * textureCoord.x - textureCoord.y);
    insideOutside = insideOutside < 0.0 ? 1.0 : 0.5;
    surface = -insideOutside;
    // if it's outside the triangle, lighten it a bit
    surface *= ((u >= 0.0) && (v >= 0.0) && (u + v < 1.0)) ? 1.0 : 0.75;
    return surface;
}
#endif
vec2 sdSegment( vec3 a, vec3 b, vec3 p )
{
    vec3 pa = p - a;
    vec3 ba = b - a;
    float t = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return vec2( length( pa - ba*t ), t );
}

//Draw Bézier Surfaces using Parabolic Arcs and a Center Of Gravity Point
float drawCurveSurface1dg(vec4 sampleUVPixel, vec4 a, vec4 b, vec4 c, float width) {
    float e = 0.;
    vec2 textureCoord;
    float surface;

#if METHOD==0
    textureCoord = sdBezier(a.xyz,b.xyz,c.xyz,sampleUVPixel.xyz);
    surface = textureCoord.x * textureCoord.x - textureCoord.y;
#endif
#if METHOD==1
    textureCoord = sdBezier(a.xyz,b.xyz,c.xyz,sampleUVPixel.xyz);
    surface = textureCoord.x * textureCoord.x - textureCoord.y;
#endif
#if METHOD==2
    // Define the control points of our curve
    vec2 p = sampleUVPixel.xy;//(2.0*sampleUVPixel.xy-iResolution.xy)/iResolution.y;
    vec2 A = 2*a.xy/iResolution.y;
    vec2 B = 2*b.xy/iResolution.y;
    vec2 C = 2*c.xy/iResolution.y;
    // Render the control points
    float d = min(distance(p, A),(min(distance(p, B),distance(p, C))));
    //if (d < 0.04) { fragColor = vec4(1.0 - smoothstep(0.025, 0.034, d)); return; }
    // Get the signed distance to bezier curve
    d = sdBezier(A, B, C, p);

    surface = d;
    //surface = sdBezier(a.xy,b.xy,c.xy,sampleUVPixel.xy);
#endif
#if METHOD==3
    surface = sdBezier(a.xy,b.xy,c.xy,sampleUVPixel.xy);
#endif

    e = surface;
    return e;
}
float drawCurveSurface2dg(vec4 sampleUVPixel, vec4 a, vec4 b, vec4 c, vec4 d, float width) {
    float e = 0.;
    e = opUnion(drawCurveSurface1dg(sampleUVPixel,a,b,c,width), drawCurveSurface1dg(sampleUVPixel,c,d,a,width));
    return e;
}
float drawCurveSurface3dg(vec4 sampleUVPixel, vec4 p0, vec4 p1, vec4 p2, vec4 p3, vec4 p4,  vec4 p5, float width) {
    float e = 0.;
    e = opUnion(drawCurveSurface1dg(sampleUVPixel,p0,p1,p2,width), drawCurveSurface1dg(sampleUVPixel,p2,p3,p4,width));
    e = opUnion(e, drawCurveSurface1dg(sampleUVPixel,p4,p5,p0,width));
    return e;
}
float drawCurveSurface4dg(vec4 sampleUVPixel, vec4 p0, vec4 p1, vec4 p2, vec4 p3, vec4 p4,  vec4 p5,  vec4 p6, vec4 p7, float width) {
    float e = 0.;
    e = opUnion(drawCurveSurface1dg(sampleUVPixel,p0,p1,p2,width), drawCurveSurface1dg(sampleUVPixel,p2,p3,p4,width));
    e = opUnion(e, drawCurveSurface1dg(sampleUVPixel,p4,p5,p6,width));
    e = opUnion(e, drawCurveSurface1dg(sampleUVPixel,p6,p7,p0,width));
    return e;
}

float drawObject(vec4 sampleUVPixel, vec4 a, vec4 b, vec4 c, vec4 d, vec4 cg, float width, float stepID) {

    float scale = width;
    float object = 1.0;
    vec2 A = vec2(0.0, -0.6), C = vec2(0.0, +0.6), B = cg.xy;
    object = min(distance(sampleUVPixel.xy, A),(min(distance(sampleUVPixel.xy, B),distance(sampleUVPixel.xy, C))));
    vec4 aa = vec4(a.xy*iResolution.xy/2,0.0,0.0);
    vec4 bb = vec4(b.xy*iResolution.xy/2,0.0,0.0);
    vec4 cc = vec4(c.xy*iResolution.xy/2,0.0,0.0);
    vec4 dd = vec4(d.xy*iResolution.xy/2,0.0,0.0);
    vec4 cg4 = vec4(cg.xy*iResolution.xy/2,0.0,0.0);
    //draw Bezier Surface
    scale = 2*width/5;
    object = opUnion(object, drawCurveSurface1dg(sampleUVPixel,aa,cg4,bb,scale));
    vec4 p0 = interpolate1dg(aa, bb, mod(stepID * 2., STEPSSPEED) / STEPSSPEED);
    object = opUnion(object, drawCurveSurface2dg(sampleUVPixel,aa,p0,cc,cg4,scale));
    vec4 p1 = interpolate1dg(bb, cc, mod(stepID * 2., STEPSSPEED) / STEPSSPEED);
    object = opUnion(object, drawCurveSurface3dg(sampleUVPixel,aa,p0,bb,p1,cc,cg4,scale));
    vec4 p2 = interpolate1dg(cc, dd, mod(stepID * 2., STEPSSPEED) / STEPSSPEED);
    object = opUnion(object, drawCurveSurface4dg(sampleUVPixel,aa,p0,bb,p1,cc,p2,dd,cg4,scale));

    vec2 sampleUVPixel3d = sampleUVPixel.xy*iResolution.xy/2;
    vec4 sampleUVPixel4 = vec4(sampleUVPixel3d.x,sampleUVPixel3d.y,0.0,0.0);
    // object = sdSphere(translate(sampleUVPixel4, cg4).xyz, scale);
    scale = width/4;
    // //object = opBlend(object, sdCapsule(sampleUVPixel4.xyz,vec3(0.0),a.xyz, scale));
    //draw a Point
    scale = 2*width/3;
    object = opBlend(object, drawPoint0dg(sampleUVPixel4,aa,scale));
    object = opBlend(object, drawPoint0dg(sampleUVPixel4,bb,scale));
    object = opBlend(object, drawPoint0dg(sampleUVPixel4,cc,scale));
    object = opBlend(object, drawPoint0dg(sampleUVPixel4,dd,scale));
    scale = 3*width;
    object = opBlend(object, drawPoint1dg(sampleUVPixel4,aa,dd,scale,stepID));
    object = opBlend(object, drawPoint2dg(sampleUVPixel4,aa,bb,dd,scale,stepID));
    object = opBlend(object, drawPoint3dg(sampleUVPixel4,aa,bb,cc,dd,scale,stepID));
    //draw Bezier Curve
    scale = 3*width/5;
    object = opBlend(object, drawCurve1dg(sampleUVPixel4,aa,dd,scale));
    object = opBlend(object, drawCurve2dg(sampleUVPixel4,aa,bb,dd,scale));
    object = opBlend(object, drawCurve3dg(sampleUVPixel4,aa,bb,cc,dd,scale));

    return object;
}

//=======================================================================================
float LinearBezier (float A, float B, float t)
{
    return A * (1.0-t) + B * t;
}
//=======================================================================================
float QuadraticBezier (float A, float B, float C, float t)
{
    float s = 1.0 - t;
    float s2 = s * s;
    float t2 = t * t;

    return A*s2 + B*2.0*s*t + C*t2;
}
//=======================================================================================
float CubicBezier (float A, float B, float C, float D, float t)
{
    float s = 1.0 - t;
    float s2 = s * s;
    float s3 = s * s * s;
    float t2 = t * t;
    float t3 = t * t * t;

    return A*s3 + B*3.0*s2*t + C*3.0*s*t2 + D*t3;
}
//=======================================================================================
vec3 Gradient (vec2 p)
{
    if(bezierType<=1) {
        float CP0_ = QuadraticBezier(CP00, CP01, CP02, p.x);
        float CP1_ = QuadraticBezier(CP10, CP11, CP12, p.x);
        float CP2_ = QuadraticBezier(CP20, CP21, CP22, p.x);
        float FY1 = CP1_ - CP0_;
        float FY2 = CP2_ - CP1_;
        float valueY = 2.0 * LinearBezier(FY1, FY2, p.y);

        float CP_0 = QuadraticBezier(CP00, CP10, CP20, p.y);
        float CP_1 = QuadraticBezier(CP01, CP11, CP21, p.y);
        float CP_2 = QuadraticBezier(CP02, CP12, CP22, p.y);
        float FX1 = CP_1 - CP_0;
        float FX2 = CP_2 - CP_1;
        float valueX = 2.0 * LinearBezier(FX1, FX2, p.x);

        return vec3(valueX,-1.0,valueY)*-1.0;
    }
    else if(bezierType==2) {
        float CP0_ = CubicBezier(CP00, CP01, CP02, CP03, p.x);
        float CP1_ = CubicBezier(CP10, CP11, CP12, CP13, p.x);
        float CP2_ = CubicBezier(CP20, CP21, CP22, CP23, p.x);
        float CP3_ = CubicBezier(CP30, CP31, CP32, CP33, p.x);
        float FY1 = CP1_ - CP0_;
        float FY2 = CP2_ - CP1_;
        float FY3 = CP3_ - CP2_;
        float valueY = 3.0 * QuadraticBezier(FY1, FY2, FY3,  p.y);

        float CP_0 = CubicBezier(CP00, CP10, CP20, CP30, p.y);
        float CP_1 = CubicBezier(CP01, CP11, CP21, CP31, p.y);
        float CP_2 = CubicBezier(CP02, CP12, CP22, CP32, p.y);
        float CP_3 = CubicBezier(CP03, CP13, CP23, CP33, p.y);
        float FX1 = CP_1 - CP_0;
        float FX2 = CP_2 - CP_1;
        float FX3 = CP_3 - CP_2;
        float valueX = 3.0 * QuadraticBezier(FX1, FX2, FX3,  p.x);

        return vec3(valueX,-1.0,valueY)*-1.0;
    }

}
//=======================================================================================
bool RayIntersectAABox (vec3 boxMin, vec3 boxMax, in vec3 rayPos, in vec3 rayDir, out vec2 time)
{
    vec3 roo = rayPos - (boxMin+boxMax)*0.5;
    vec3 rad = (boxMax - boxMin)*0.5;

    vec3 m = 1.0/rayDir;
    vec3 n = m*roo;
    vec3 k = abs(m)*rad;

    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

    time = vec2( max( max( t1.x, t1.y ), t1.z ),
                 min( min( t2.x, t2.y ), t2.z ) );

    return time.y>time.x && time.y>0.0;
}
//=======================================================================================
float RayIntersectSphere (vec4 sphere, in vec3 rayPos, in vec3 rayDir)
{
    //get the vector from the center of this circle to where the ray begins.
    vec3 m = rayPos - sphere.xyz;

    //get the dot product of the above vector and the ray's vector
    float b = dot(m, rayDir);

    float c = dot(m, m) - sphere.w * sphere.w;

    //exit if r's origin outside s (c > 0) and r pointing away from s (b > 0)
    if(c > 0.0 && b > 0.0)
        return -1.0;

    //calculate discriminant
    float discr = b * b - c;

    //a negative discriminant corresponds to ray missing sphere
    if(discr < 0.0)
        return -1.0;

    //ray now found to intersect sphere, compute smallest t value of intersection
    float collisionTime = -b - sqrt(discr);

    //if t is negative, ray started inside sphere so clamp t to zero and remember that we hit from the inside
    if(collisionTime < 0.0)
        collisionTime = -b + sqrt(discr);

    return collisionTime;
}

//=======================================================================================
vec3 HandleControlPoints (in vec3 rayPos, in vec3 rayDir, in vec3 pixelColor, inout float hitTime, float width)
{
#if SHOW_CONTROLPOINTS
    float cpHitTime = RayIntersectSphere(vec4(0.0, CP00, 0.0, width), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(1.0,0.0,0.0);
    }
    cpHitTime = RayIntersectSphere(vec4(1.0/3.0, CP01, 0.0, width), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(1.0,0.0,0.0);
    }
    cpHitTime = RayIntersectSphere(vec4(2.0/3.0, CP02, 0.0, width), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(1.0,0.0,0.0);
    }
    cpHitTime = RayIntersectSphere(vec4(1.0, CP03, 0.0, width), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(1.0,0.0,0.0);
    }


    cpHitTime = RayIntersectSphere(vec4(0.0, CP10, 1.0/3.0, width), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(0.0,1.0,0.0);
    }
    cpHitTime = RayIntersectSphere(vec4(1.0/3.0, CP11, 1.0/3.0, width), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(0.0,1.0,0.0);
    }
    cpHitTime = RayIntersectSphere(vec4(2.0/3.0, CP12, 1.0/3.0, width), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(0.0,1.0,0.0);
    }
    cpHitTime = RayIntersectSphere(vec4(1.0, CP13, 1.0/3.0, width), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(0.0,1.0,0.0);
    }


    cpHitTime = RayIntersectSphere(vec4(0.0, CP20, 2.0 / 3.0, width), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(0.0,0.0,1.0);
    }
    cpHitTime = RayIntersectSphere(vec4(1.0/3.0, CP21, 2.0 / 3.0, width), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(0.0,0.0,1.0);
    }
    cpHitTime = RayIntersectSphere(vec4(2.0/3.0, CP22, 2.0 / 3.0, width), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(0.0,0.0,1.0);
    }
    cpHitTime = RayIntersectSphere(vec4(1.0, CP23, 2.0 / 3.0, width), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(0.0,0.0,1.0);
    }


    cpHitTime = RayIntersectSphere(vec4(0.0, CP30, 1.0, width), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(1.0,1.0,0.0);
    }
    cpHitTime = RayIntersectSphere(vec4(1.0/3.0, CP31, 1.0, width), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(1.0,1.0,0.0);
    }
    cpHitTime = RayIntersectSphere(vec4(2.0/3.0, CP32, 1.0, width), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(1.0,1.0,0.0);
    }
    cpHitTime = RayIntersectSphere(vec4(1.0, CP33, 1.0, width), rayPos, rayDir);
    if (cpHitTime > 0.0 && cpHitTime < hitTime)
    {
        hitTime = cpHitTime;
        pixelColor = vec3(1.0,1.0,0.0);
    }
#endif

    return pixelColor;
}
//=======================================================================================

float mapHeightAtPos(vec2 P)
{
    if(bezierType==0) {
        float ut = P.x;
        float ut2 = ut * ut;
        float us = 1.0 - ut;
        float us2 = us * us;

        float vt = P.y;
        float vt2 = vt * vt;
        float vs = 1.0 - vt;
        float vs2 = vs * vs;

        float u0 = us2;
        float u1 = 2.0*us*ut;
        float u2 = ut2;

        float v0 = vs2;
        float v1 = 2.0*vs*vt;
        float v2 = vt2;

        return
                CP00*u0*v0 + CP01*u1*v0 + CP02*u2*v0 +
                CP10*u0*v1 + CP11*u1*v1 + CP12*u2*v1 +
                CP20*u0*v2 + CP21*u1*v2 + CP22*u2*v2
                ;
    }
    else if(bezierType==1) {
        float CP0X = QuadraticBezier(CP00, CP01, CP02, P.x);
        float CP1X = QuadraticBezier(CP10, CP11, CP12, P.x);
        float CP2X = QuadraticBezier(CP20, CP21, CP22, P.x);

        return QuadraticBezier(CP0X, CP1X,CP2X, P.y);
    }
    else if(bezierType==2) {
        float CP0X = CubicBezier(CP00, CP01, CP02, CP03, P.x);
        float CP1X = CubicBezier(CP10, CP11, CP12, CP13, P.x);
        float CP2X = CubicBezier(CP20, CP21, CP22, CP23, P.x);
        float CP3X = CubicBezier(CP30, CP31, CP32, CP33, P.x);

        return CubicBezier(CP0X, CP1X, CP2X, CP3X, P.y);
    }

}
#define U(a,b) (a.x*b.y-b.x*a.y)

vec2 A[15];
vec2 T1[5];
vec2 T2[5];
const vec3 L = normalize(vec3(1,.72, 1)), Y = vec3(0,1,0), E = Y*.01;
float tMorph;
mat2 mat2Rot;
float mapTeaPot(vec3 p){
    // Distance to Teapot ---------------------------------------------------
    // precalcul first part of teapot spout
    vec2 h = sdBezier(T1[2],T1[3],T1[4], p);
    float a = 99.,
            // distance to teapot handle (-.06 => make the thickness)
            b = min(min(sdBezier(T2[0],T2[1],T2[2], p).x, sdBezier(T2[2],T2[3],T2[4], p).x) - .06,
            // max p.y-.9 => cut the end of the spout
            max(p.y - .9,
                // distance to second part of teapot spout (abs(dist,r1)-dr) => enable to make the spout hole
                min(abs(sdBezier(T1[0],T1[1],T1[2], p).x - .07) - .01,
            // distance to first part of teapot spout (tickness incrase with pos on curve)
            h.x * (1. - .75 * h.y) - .08)));

    // distance to teapot body => use rotation symetry to simplify calculation to a distance to 2D bezier curve
    vec3 qq= vec3(sqrt(dot(p,p)-p.y*p.y), p.y, 0);
    // the substraction of .015 enable to generate a small thickness arround bezier to help convergance
    // the .8 factor help convergance
    for(int i=0;i<13;i+=2)
        a = min(a, (sdBezier(A[i], A[i + 1], A[i + 2], qq).x - .015) * .7);
    // smooth minimum to improve quality at junction of handle and spout to the body
    float dTeapot = smin(a,b,.02);

    // Distance to other shapes ---------------------------------------------
    float dShape;
    int idMorph = int(mod(floor(.5+(iFrame)/(2.*3.141592658)),3.));

    if (idMorph == 1) {
        p.xz *= mat2Rot;
        vec3 d = abs(p-vec3(.0,.5,0)) - vec3(.8,.7,.8);
        dShape = min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
    } else if (idMorph == 2) {
        p -= vec3(0,.55,0);
        vec3 d1 = abs(p) - vec3(.67,.67,.67*1.618);
        vec3 d3 = abs(p) - vec3(.67*1.618,.67,.67);
        dShape = min(max(d1.x,max(d1.y,d1.z)),0.) + length(max(d1,0.));
        dShape = min(dShape,min(max(d3.x,max(d3.y,d3.z)),0.) + length(max(d3,0.)));
    } else {
        dShape = length(p-vec3(0,.45,0))-1.1;
    }

    // !!! The morphing is here !!!
    return mix(dTeapot, dShape, abs(tMorph));
}

vec2 mapBezierSegment( vec3 p )
{
    float dm = 100.0;

    vec3 a = vec3(0.0,-1.0,0.0);
    vec3 b = vec3(0.0, 1.0,0.0);
    vec3 c = vec3(0.0, 0.5,-0.5);
    float th = 0.0;
    float hm = 0.0;
    float id = 0.0;
    for( int i=0; i<8; i++ )
    {
#ifndef USELINEAR
        vec2 h = sdBezier( a, b, c, p );
#else
        vec2 h = sdSegment( a, c, p );
#endif
        float kh = (th + h.y)/8.0;

        float ra = 0.3 - 0.28*kh + 0.3*exp(-15.0*kh);

        float d = h.x - ra;

        //dm = min( dm, d );
        if( d<dm ) { dm=d; hm=kh; }

        vec3 na = c;
        vec3 nb = c + (c-b);
        vec3 nc = nb;
#ifndef ANIMATE
        vec3 dir = normalize(-1.0+2.0*hash3( id+13.0 ));
        nc = nb + 1.0*dir*sign(-dot(c-b,dir));
#else
        nc = nb + 0.8*normalize(-1.0+2.0*noise33(id+sin(iFrame*0.030) * 0.5));
        nc.y = max( nc.y, -0.9 );
#endif

        id += 3.71;
        a = na;
        b = nb;
        c = nc;
        th += 1.0;
    }
    return vec2( 0.5*dm, hm );
}

float map2( in vec3 pos )
{
    return min( pos.y+1.0, mapBezierSegment(pos).x );
}

vec3 calcNormal( in vec3 pos, in int mapID )
{
    //int mapID = 0;
    vec3 eps = vec3(0.002,0.0,0.0);
    if(mapID==0) {
        return normalize( vec3(
                              mapBezierSegment(pos+eps.xyy).x - mapBezierSegment(pos-eps.xyy).x,
                              mapBezierSegment(pos+eps.yxy).x - mapBezierSegment(pos-eps.yxy).x,
                              mapBezierSegment(pos+eps.yyx).x - mapBezierSegment(pos-eps.yyx).x ) );
    }
    if(mapID==1) {
#if 1
        return normalize(Gradient(pos.xy));
#else
        vec3 n = vec3( mapHeightAtPos(vec2(pos.x-eps.x,pos.y)) - mapHeightAtPos(vec2(pos.x+eps.x,pos.y)),
                       2.0*eps.x,
                       mapHeightAtPos(vec2(pos.x,pos.y-eps.x)) - mapHeightAtPos(vec2(pos.x,pos.y+eps.x)));
        return normalize( n );
#endif
    }
}
float calcAO( in vec3 pos, in vec3 nor )
{
    float ao = 0.0;
    for( int i=0; i<8; i++ )
    {
        float h = 0.02 + 0.5*float(i)/7.0;
        float d = map2( pos + h*nor );
        ao += -(d-h);
    }
    return clamp( 1.5 - ao*0.6, 0.0, 1.0 );
}
float softshadow( in vec3 ro, in vec3 rd, float mint, float k )
{
    float res = 1.0;
    float t = mint;
    float h = 1.0;
    for( int i=0; i<32; i++ )
    {
        h = mapBezierSegment(ro + rd*t).x;
        res = min( res, k*h/t );
        t += clamp( h, 0.02, 2.0 );
        if( res<0.0001 ) break;
    }
    return clamp(res,0.0,1.0);
}
//=======================================================================================
vec3 DiffuseColor (in vec3 pos)
{
    // checkerboard pattern
    return vec3(mod(floor(pos.x * 10.0) + floor(pos.z * 10.0), 2.0) < 1.0 ? 1.0 : 0.4);
}
const float EPSILON = 0.01;//0.0001;
/**
 * Using the gradient of the SDF, estimate the normal on the surface at point p.
 */
vec3 estimateNormal(vec4 sampleUVPixel, vec4 a, vec4 b, vec4 c, vec4 d, vec4 cg, float width, float stepID) {
    return normalize(vec3(
                         drawObject(vec4(sampleUVPixel.x + EPSILON, sampleUVPixel.y, sampleUVPixel.z, sampleUVPixel.w),
                                    a,b,c,d,cg,width,stepID)
                         - drawObject(vec4(sampleUVPixel.x - EPSILON, sampleUVPixel.y, sampleUVPixel.z, sampleUVPixel.w),
                                      a,b,c,d,cg,width,stepID),
                         drawObject(vec4(sampleUVPixel.x, sampleUVPixel.y + EPSILON, sampleUVPixel.z, sampleUVPixel.w),
                                    a,b,c,d,cg,width,stepID)
                         - drawObject(vec4(sampleUVPixel.x, sampleUVPixel.y - EPSILON, sampleUVPixel.z, sampleUVPixel.w),
                                      a,b,c,d,cg,width,stepID),
                         drawObject(vec4(sampleUVPixel.x, sampleUVPixel.y, sampleUVPixel.z  + EPSILON, sampleUVPixel.w),
                                    a,b,c,d,cg,width,stepID)
                         - drawObject(vec4(sampleUVPixel.x, sampleUVPixel.y, sampleUVPixel.z - EPSILON, sampleUVPixel.w),
                                      a,b,c,d,cg,width,stepID)
                         ));
}
vec3 intersect( in vec3 rayPos, in vec3 rayDir, in vec3 pixelColor, out float hitTime, out int mapID, out bool fromUnderneath )
{
    float time = 0.0;
    float height;
    float lastHeight = 0.0;
    float maxd = 12.0;
    vec2 timeMinMax = vec2(0.0);
    time = timeMinMax.x;

    pixelColor = vec3( -1.0 );

    float tp = (-1.0-rayPos.y)/rayDir.y;
    if( tp>0.0 )
    {
        // plane
        vec3 pos = rayPos + rayDir*tp;
        pixelColor = vec3( tp, 0.025*length(pos.xz)*1.0 + 0.01*atan(pos.z,pos.x), 0.0 );
        maxd = tp;
    }

    const int c_numIters = 100;//80;
    vec3 pos = rayPos + rayDir * time;
    const float precis = 0.001;
    for( int index=0; index<c_numIters; index++ )
    {
        // tentacle
        pos = rayPos + rayDir * time;
        vec2 h = mapBezierSegment(pos);
        if( h.x<precis || time>maxd ) break;
        time += h.x;
        lastHeight = h.y;
    }
    if( time<maxd ) {
        pixelColor = vec3( time, lastHeight, 1.0 );
    }
    mapID = 0;

    time = timeMinMax.x;
    height = 0.0;
    pos = rayPos + rayDir * time;
    for(int i=0;i<48;i++) {
        // Teapot
        pos = rayPos + rayDir * time;
        height = mapTeaPot(pos);
        if (height<.0001 || time>4.7) break;
        time += height;
    }
    if (height < .001) {
        pixelColor = vec3( time, lastHeight, 1.0 );
    }

    if (!RayIntersectAABox(vec3(0.0,CPMin,0.0), vec3(1.0,CPMax,1.0), rayPos, rayDir, timeMinMax))
        return pixelColor;
    time = timeMinMax.x;
    float deltaT = (timeMinMax.y - timeMinMax.x) / float(c_numIters);
    pos = rayPos + rayDir * time;
    float lastY = 0.0;
    height = 0.0;
    float firstSign = sign(pos.y - mapHeightAtPos(pos.xz));
    fromUnderneath = false;
    bool hitFound = false;

    for (int index = 0; index < c_numIters; ++index)
    {
        // Bezier Curves
        pos = rayPos + rayDir * time;
        height = mapHeightAtPos(pos.xz);
        if (sign(pos.y - height) * firstSign < 0.0)
        {
            fromUnderneath = firstSign < 0.0;
            hitFound = true;
            break;
        }
        time += deltaT;
        lastHeight = height;
        lastY = pos.y;
    }
    if (hitFound) {
        time = time - deltaT + deltaT*(lastHeight-lastY)/(pos.y-lastY-height+lastHeight);
        pos = rayPos + rayDir * time;
        pixelColor = vec3( time, lastHeight, lastY );
        hitTime = time;
        mapID = 1;
    }
    else
    {
#if SHOW_BOUNDINGBOX
        pixelColor += vec3(0.2);
        mapID = 2;
#endif
    }

    return pixelColor;
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
    if (iMode.x==2.0) computedcolor = iColor;
    if (iMode.x==3.0) computedcolor = vec4(frag_uv,0.0,1.0);
    if (iMode.x==4.0) computedcolor = vec4(vec3(uv,0.5+0.5*sin((float(iTime)/10)+(float(iFrame)/100))),1.0);
    if (iMode.x==5.0) {
        //grid texture
        float scale = 100.0;//number of squares
        vec2 center = p;//grid center
        computedcolor = vec4(grid( uv,center,scale ),1.0);
    }
    if (iMode.x==6.0) computedcolor = texture(fragTexture, frag_uv);

    if (iMode.w==0.25) computedcolor = mix(computedcolor, texture(fragFBOTexture, frag_uv), 0.5);
    if (iMode.w==0.5) computedcolor = mix(computedcolor, texture(iChannel0, frag_uv), 0.5);
    if (iMode.w==1.0) computedcolor = mix(computedcolor, texture(iChannel1, frag_uv), 0.5);
    if (iMode.w==2.0) computedcolor = mix(computedcolor, texture(iChannel2, frag_uv), 0.5);
    if (iMode.w==3.0) computedcolor = mix(computedcolor, texture(iChannel3, frag_uv), 0.5);

    //transpose uv screen position from (0.0,0.0)-(1.0,1.0) to (-1.0,-1.0)-(1.0,1.0)
    float zoom = 5.0;
    vec2 uv3d =  -zoom*0.5 + zoom*uv;//-1.0 + 2.0*uv;
    uv3d.y = -uv3d.y;//flip y to adjust for error
    vec2 mo1 = -zoom*0.5 + zoom*iMouse.xy;//-1.0 + 2.0*iMouse.xy;
    mo1.y = -mo1.y;//flip y to adjust for error
    vec2 mo2 = -zoom*0.5 + zoom*iMouse.zw;//(-1.0 + 2.0*iMouse.zw);
    mo2.y = -mo2.y;//flip y to adjust for error
    vec2 p0 = -zoom*0.5 + zoom*iPosition.xy;//-1.0 + 2.0*iPosition.xy;
    p0.y = -p0.y;//flip y to adjust for error
    vec2 p1 = -zoom*0.5 + zoom*iPosition.zw;//-1.0 + 2.0*iPosition.zw;
    p1.y = -p1.y;//flip y to adjust for error

    //Convert to 4 Dimensions
    vec2 pSta = vec2(0.7);
    vec4 uv4 = vec4(uv3d.x,uv3d.y,0.0,0.0);
    vec4 a = vec4(-pSta.x,-pSta.y,0.0,0.0);//vec4(mo1.x,mo1.y,0.0,0.0);
    vec4 b = vec4(-pSta.x,pSta.y,0.0,0.0);//vec4(mo2.x,mo2.y,0.0,0.0);
    vec4 c = vec4(pSta.x,pSta.y,0.0,0.0);//vec4(p0.x,p0.y,0.0,0.0);
    vec4 d = vec4(pSta.x,-pSta.y,0.0,0.0);//vec4(p1.x,p1.y,0.0,0.0);
    vec4 cg = vec4(0.0,0.0,0.0,0.0);//vec4(p1.x,p1.y,0.0,0.0);
    cg = vec4(p1.x,p1.y,0.0,0.0);
    //cg = vec4(mo1.x,mo1.y,0.0,0.0);
    //Set Properties
    float fillwidth = 30.00;
    float outWidth = 10.0;
    float inWidth = 10.0;
    float stepID = iFrame * 0.01;
    //cg = mix(cg,vec4(cos(iFrame * 1.2) * 0.8,0.0,0.0,0.0), step(stepID, 0.0));
    //Compute Object
    float object = 0.0;
    float inobject = 0.0;
    float surfobject = 0.0;
    float outobject = 0.0;


    //draw a Object
    fillwidth = 20.00;
    inWidth = 5.0;
    outWidth = 5.0;

    if (iMode.z==1.0) {
        //draw a Object
        object = drawObject(uv4,a,b,c,d,cg,fillwidth,stepID);
        vec4 objcolor = mix(vec4(0.0), vec4(1.0), object);
        objcolor = (sign(object)< 1.0) ? vec4(1.0,0.4,0.7,1.0) : vec4(0.4, 0.0, 0.7, 1.0);
        objcolor *= (1.0 - exp(-4.0*abs(object))) * (0.8 + 0.2*cos(140.*object));
        objcolor = mix(objcolor, vec4(1.0), 1.0-smoothstep(0.0,0.02,abs(object)) );
        computedcolor = objcolor;
    }
    else if (iMode.z==2.0) {

        //object = drawObject(uv4,a,b,c,d,cg,fillwidth,stepID);
        //inobject = drawObject(uv4,a,b,c,d,cg,fillwidth-inWidth,stepID);
        //surfobject = -object*drawObject(uv4,a,b,c,d,cg,inWidth,stepID);
        //outobject = -object*drawObject(uv4,a,b,c,d,cg,fillwidth+outWidth,stepID);


        object = 1.0;//0.0125;
        cg = vec4(p1.x,p1.y,0.0,0.0);
        object = drawObject(uv4,a,b,c,d,cg,fillwidth,stepID);
        //inobject = drawObject(samplePoint,uv4,a,b,c,d,cg,fillwidth-inWidth,stepID);
        //surfobject = mix(object, 1.0, inobject);
        //outobject = drawObject(samplePoint,uv4,a,b,c,d,cg,fillwidth+outWidth,stepID);
        //outobject = mix(object, 1.0, outobject);

        // shape fill
        vec4 objcolor = mix(vec4(0.0), vec4(1.0), object);
        //computedcolor += clamp(objcolor,0.0,1.0)*vec4(0.4, 0.0, 0.7, 1.0);
        // Visualize the distance field using iq's orange/blue scheme
        //objcolor = vec4(1.0) - sign(object)*vec4(1.0,0.4,0.7,1.0);
        objcolor = (sign(object)< 1.0) ? vec4(1.0,0.4,0.7,1.0) : vec4(0.4, 0.0, 0.7, 1.0);
        objcolor *= (1.0 - exp(-4.0*abs(object))) * (0.8 + 0.2*cos(140.*object));
        objcolor = mix(objcolor, vec4(1.0), 1.0-smoothstep(0.0,0.02,abs(object)) );
        computedcolor = objcolor;

        vec4 incolor = mix(vec4(0.0), vec4(1.0), inobject);
        //computedcolor += clamp(incolor,0.0,1.0)*vec4(0.4, 0.0, 0.7, 1.0);
        vec4 surfcolor = mix(vec4(0.0), vec4(1.0), surfobject);
        //computedcolor += clamp(surfobject,0.0,1.0)*vec4(0.4, 0.4, 0.7, 1.0);
        vec4 outcolor = mix(vec4(0.0), vec4(1.0), objcolor);
        //computedcolor += clamp(outcolor,0.0,1.0)*vec4(0.4, 0.4, 0.7, 1.0);

        vec3 normals = estimateNormal(uv4,a,b,c,d,cg,fillwidth,stepID);
        vec4 normalcolor = vec4(normals,clamp(sign(-object),0.0,1.0));
        //computedcolor += normalcolor*0.5;

        //computedcolor += clamp(incolor,0.0,1.0)*normalcolor;
        //computedcolor += clamp(surfobject,0.0,1.0)*normalcolor;
        //computedcolor += clamp(outcolor,0.0,1.0)*normalcolor;


        vec2 q = frag_uv.xy / iResolution.xy;
        vec2 p = -1.0 + 2.0 * q;
        p.x *= iResolution.x/iResolution.y;
        vec2 m = vec2(0.5);
        if( iMouse.x>0.0 ) m = iMouse.xy/iResolution.xy;
        q=uv;
        p=uv3d;
        m=mo1;


        //-----------------------------------------------------
        // animate
        //-----------------------------------------------------

        float ctime = stepID*STEPSSPEED;


        //-----------------------------------------------------
        // camera
        //-----------------------------------------------------

        float angleX = 2.0 + 0.3*ctime - 12.0*(m.x-0.5);
        //float angleX = iMouse.z > 0.0 ? 6.28 * m.x : 3.14 + ctime * 0.25;
        float angleY = (m.y * 6.28) - 0.4;
        //float angleY = iMouse.z > 0.0 ? (m.y * 6.28) - 0.4 : 0.5;

        vec3 cameraPos = vec3(7.0*sin(angleX),0.0,7.0*cos(angleX));
        cameraPos	= (vec3(sin(angleX)*cos(angleY), sin(angleY), cos(angleX)*cos(angleY))) * 3.0;
        cameraPos += vec3(0.5,0.5,0.5);
        vec3 cameraAt = vec3(0.0,0.0,0.0);

        // camera matrix
        vec3 cameraFwd = normalize( cameraAt - cameraPos );
        vec3 cameraLeft = normalize( cross(cameraFwd,vec3(0.0,1.0,0.0) ) );
        vec3 cameraUp = normalize( cross(cameraLeft,cameraFwd));

        // create view ray
        // vec3 rayTarget = (cameraFwd * vec3(cameraDistance,cameraDistance,cameraDistance))
        // 		   - (cameraLeft * percent.x * cameraViewWidth)
        //            + (cameraUp * percent.y * cameraViewHeight);
        vec3 rayDir = normalize( p.x*cameraLeft + p.y*cameraUp + 2.5*cameraFwd );

        //-----------------------------------------------------
        // render
        //-----------------------------------------------------

        vec3 pixelColor = clamp( vec3(0.95,0.95,1.0) - 0.75*rayDir.y, 0.0, 1.0 );
        float sun = pow( clamp( dot(rayDir,light), 0.0, 1.0 ), 8.0 );
        pixelColor += 0.7*vec3(1.0,0.9,0.8)*pow(sun,4.0);
        vec3 bcol = pixelColor;
        float hitTime = FLT_MAX;
        int mapID = 1;
        bool fromUnderneath;

        float aa=3.14159/4.;
        mat2Rot = mat2(cos(aa),sin(aa),-sin(aa),cos(aa));
        // Morphing step
        tMorph = cos(iFrame*.5);
        tMorph*=tMorph*tMorph*tMorph*tMorph;
        // Teapot body profil (8 quadratic curves)
        A[0]=vec2(0,0);A[1]=vec2(.64,0);A[2]=vec2(.64,.03);A[3]=vec2(.8,.12);A[4]=vec2(.8,.3);A[5]=vec2(.8,.48);A[6]=vec2(.64,.9);A[7]=vec2(.6,.93);
        A[8]=vec2(.56,.9);A[9]=vec2(.56,.96);A[10]=vec2(.12,1.02);A[11]=vec2(0,1.05);A[12]=vec2(.16,1.14);A[13]=vec2(.2,1.2);A[14]=vec2(0,1.2);
        // Teapot spout (2 quadratic curves)
        T1[0]=vec2(1.16, .96);T1[1]=vec2(1.04, .9);T1[2]=vec2(1,.72);T1[3]=vec2(.92, .48);T1[4]=vec2(.72, .42);
        // Teapot handle (2 quadratic curves)
        T2[0]=vec2(-.6, .78);T2[1]=vec2(-1.16, .84);T2[2]=vec2(-1.16,.63);T2[3]=vec2(-1.2, .42);;T2[4]=vec2(-.72, .24);



        // raymarch
        vec3 tmat = intersect(cameraPos, rayDir, pixelColor, hitTime, mapID, fromUnderneath);
        pixelColor = tmat;
        if( tmat.z>-0.5 )
        {
            // geometry
            vec3 pos = cameraPos + tmat.x*rayDir;
            vec3 normal = calcNormal(pos,mapID);
            normal *= fromUnderneath ? -1.0 : 1.0;

            if( tmat.z<0.5 )
                normal = vec3(0.0,1.0,0.0);
            vec3 reflection = reflect( rayDir, normal );

            // materials
            vec3 mate = vec3(0.5);
            if(iFrame%50<=10) mate = tmat;
            else if(iFrame%50<=20) mate = normalize(normal);
            else if(iFrame%50<=30) mate = hsv2rgb_smooth(.9+iTime*.02, 1.,1.);//color rotation in HSV color space
            else if(iFrame%50<=40) mate = bumpFromDepth(uv, iResolution.xy, .1).rgb * .5 + .5;//texture hightmap to normalmap
            else {
                if(mapID==0) mate *= smoothstep( -0.75, 0.75, cos( 200.0*tmat.y ) );
                if(mapID==1) mate *= DiffuseColor(pos);
            }
            if(fromUnderneath) mate *= vec3(1.0,0.0,0.0);

            float occ = calcAO( pos, normal );

            // lighting
            float sky = clamp(normal.y,0.0,1.0);
            float bou = clamp(-normal.y,0.0,1.0);
            float dif = max(dot(normal,light),0.0);
            float bac = max(0.3 + 0.7*dot(normal,-light),0.0);
            float sha = 0.0; if( dif>0.001 ) sha=softshadow( pos+0.01*normal, light, 0.0005, 32.0 );
            float fre = pow( clamp( 1.0 + dot(normal,rayDir), 0.0, 1.0 ), 5.0 );
            float spe = max( 0.0, pow( clamp( dot(light,reflection), 0.0, 1.0), 8.0 ) );

            // lights
            vec3 brdf = vec3(0.0);
            brdf += 2.0*dif*vec3(1.20,1.0,0.60)*sha;
            brdf += 1.5*sky*vec3(0.10,0.15,0.35)*occ;
            brdf += 1.0*bou*vec3(0.30,0.30,0.30)*occ;
            brdf += 1.0*bac*vec3(0.30,0.25,0.20)*occ;
            brdf += 1.0*fre*vec3(1.00,1.00,1.00)*occ*dif;

            // surface-light interacion
            pixelColor = mate.xyz* brdf;
            pixelColor += (1.0-mate.xyz)*1.0*spe*vec3(1.0,0.95,0.9)*sha*2.0*(0.2+0.8*fre)*occ;


            // fog
            pixelColor = mix( pixelColor, bcol, smoothstep(10.0,20.0,tmat.x) );
        }

        pixelColor += 0.4*vec3(1.0,0.8,0.7)*sun;

        // pixelColor = tmat;
        // gamma
        pixelColor = pow( clamp(pixelColor,0.0,1.0), vec3(0.45) );
        pixelColor = clamp(pixelColor,0.0,1.0);
        computedcolor = vec4(pixelColor,1.0);

        // Controlers
        vec3 controlPointColor = vec3(1.0);//texture(fragTexture, frag_uv).rgb;
        controlPointColor = HandleControlPoints(cameraPos, rayDir, pixelColor, hitTime,fillwidth*0.0051);
        controlPointColor = clamp(controlPointColor,0.0,1.0);
        computedcolor *= vec4(controlPointColor,1.0);


    }

    //border
    //if(uv.x<=0.001||uv.y<=0.001||uv.x>=0.999||uv.y>=0.999||uv.y==0.5)
    //computedcolor += vec4(1.0,0.0,0.0,1.0);

    //add opacity
    computedcolor.w *= opacity;

    color = computedcolor;



}
