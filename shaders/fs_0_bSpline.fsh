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

/////////////////////////
// 2D Vector functions //
/////////////////////////
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
//Bézier curve using Parabolic Arcs
#define ANIMATED
#define SHOW_CONTROL_POINTS
#define SHOW_SEGMENT_POINTS
#define STEPS  10.0
#define STROKE 0.2
#define SKELETON 3.0
#define EPS    0.01
float ip_control(vec2 uv, vec2 a, vec2 b, vec2 c)
{
    float l0 = lineDist(uv, a, b, 10.0);//sharpen(sdSegment(uv, a, b), EPS * .6);
    float l1 = lineDist(uv, b, c, 10.0);//sharpen(sdSegment(uv, b, c), EPS * .6);

    return merge(l0,l1);
}

float ip_point(vec2 uv, vec2 a, vec2 b, vec2 c,float stepID)
{
    vec2 p = interpolate(a, b, c, mod(stepID * 2., STEPS) / 10.);

    return circleDist(translate(uv, p), 10.0);
    //return fillMask(circleDist(translate(uv, p), 25.0025));
    //return sharpen(sdCircleOutline(uv, p, .0025), EPS * 1.);
}

float ip_curve(vec2 uv, vec2 a, vec2 b, vec2 c)
{
    float e = 0.;
    for (float i = 0.; i < STEPS; ++i)
    {
        vec2  p0 = interpolate(a, b, c, (i   ) / STEPS);
        vec2  p1 = interpolate(a, b, c, (i+1.) / STEPS);
        float l = lineDist(uv, p0,  p1, 10.0);//sharpen(sdSegment(uv, p0, p1), EPS * STROKE);
        //e += max(e, l);
        e = merge(e,l);
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
        float segGradient  = (STEPS-i)/STEPS;
        float l = lineDist(uv, p0,  p1, 10.0*segGradient);//sharpen(sdSegment(uv, p0, p1), EPS * SKELETON * segGradient);
        //e += max(e, l);
        e = merge(e,l);
    }

    return e;
}
//=============Scene=============

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

    //Draw A Bezier Curve Given three points a,b,c (Parabolic Arc)
    //control points and line segments
    float d0 = ip_control(uv2d, a, b, c);
    float point = 0.0;
    //#ifdef ANIMATED
    // active segment point
    point = ip_point(uv2d, a, b, c, iFrame * 0.01);
    //#endif
    //Bezier curve
    float d1 = ip_curve(uv2d, a, b, c);
    //Bezier curve with Thickness
    float d2 = ip_curveThick(uv2d, a, b, c);

    //---2D Curve Scene---
    // shape fill
    col = mix(col, vec4(1.0, 0.4, 0.0, 1.0), fillMask(point1));
    col = mix(col, vec4(0.4, 0.6, 0.0, 1.0), fillMask(point2));
    col = mix(col, vec4(1.0, 0.0, 0.4, 1.0), fillMask(point3));
    col = mix(col, vec4(0.2, 0.35, 0.55, 1.0), fillMask(d0));
    col = mix(col, vec4(0.9, 0.43, 0.34, 1.0), fillMask(point));
    col = mix(col, vec4(1.0, 0.4, 1.0, 1.0), fillMask(d1));
    col = mix(col, vec4(0.2, 0.4, 0.0, 1.0), fillMask(d2));
    // shape outline
    col = mix(col, vec4(0.1, 0.1, 0.1, 1.0), innerBorderMask(point, 02.50));
    // shape outline
    col = mix(col, vec4(0.9, 0.9, 0.9, 1.0), outerBorderMask(point, 02.50));

    col = clamp(col, 0.0, 1.0);
    return col;
}

vec4 draw2DScene(vec2 uv,vec4 p, vec3 colBase){
    vec4 col;

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
    vec2 a = vec2(0.0,0.0);
    vec2 b = p0;//mo1;
    vec2 c = p1;//mo2;

    return scene2DCurve(uv2d-a,uv2d-b,uv2d-c);
}

out vec4 color;
void main(void)
{

    vec4 computedcolor;
    if (iMode.x==-1.0) {
        //TODO render to texture
        computedcolor = texture(fragFBOTexture, frag_uv);
    }
    else {

        vec2 uv = frag_uv.xy ;//uv range is from 0.0 to 0.999
        vec2 p = iMouse.xy;//vec2(0.999)//vec2(0.5)//iMouse.xy//adjust point error
        int mode = iTime;
        vec3 col;
        //select base color
        if (iMode.x==0.0) computedcolor = vec4(1.0,1.0,1.0,1.0);
        if (iMode.x==1.0) computedcolor = vec4(frag_uv,0.0,1.0);
        if (iMode.x==2.0) computedcolor = vec4(vec3(uv,0.5+0.5*sin((float(iTime)/10)+(float(iFrame)/100))),1.0);
        if (iMode.x==3.0) computedcolor = iColor;
        if (iMode.x==4.0) computedcolor = texture(fragTexture, frag_uv);
        if (iMode.x==5.0) computedcolor = texture(iChannel0, frag_uv);
        if (iMode.x==6.0) {
            //grid texture
            float scale = 100.0;//number of squares
            vec2 center = p;//grid center
            computedcolor = vec4(grid( uv,center,scale ),1.0);
        }

        //Draw 2D Scene
        if (iMode.z==1.0) {
            //mouse point
            computedcolor = draw2DScene(uv,iPosition,computedcolor.xyz);
        }

        //add opacity
        computedcolor = vec4(computedcolor.xyz,computedcolor.w*opacity);
    }

    color = computedcolor;

}
