#version 330 core
//in vec3  fragColor;
in vec2 frag_uv;
in vec3 frag_position;
in vec3 frag_normal;

uniform sampler2D fragTexture;
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
//AntiAliasingSamples (AntiAlias)not working


float iSphere(in vec3 ro, in vec3 rd, in vec4 sph){
    //so, a spherer centered at the orign has the equation |xyz| = r
    //meaning. |xyz|^2 = r^2, means <xyz,xyz> = r^2
    // now, xyz = ro + t*rd, therefore }ro|^2 + t^2 + 2<ro,rd>t-r^2 = 0
    // which is a quadratiq equation, so
    //float b = 2.0*dot(ro,rd);
    //float r = 1.0;
    //float c = dot(ro,ro) - r*r;
    vec3 oc = ro - sph.xyz;
    float b = 2.0*dot(oc,rd);
    float c = dot(oc,oc) - sph.w*sph.w;
    float h = b*b - 4.0*c;
    if(h<0.0) return -1.0;
    float t = (-b - sqrt(h))/2.0;
    return t;
}
vec3 nSphere(in vec3 pos, in vec4 sph){
    return (pos-sph.xyz)/sph.w;
}
float iPlane(in vec3 ro, in vec3 rd){
    //equation of a plane, y=0 = ro.y + t*rd.y
    return -ro.y/rd.y;
}
vec3 nPlane(in vec3 pos){
    return vec3(0.0,1.0,0.0);
}
vec4 sph1 = vec4(0.0,0.0,0.0,1.0);//sphere transform
float intersect(in vec3 ro, in vec3 rd, out float resT){
    resT = 1000.0;
    float id = -1.0;
    float tsph = iSphere(ro,rd, sph1);//intersect with a sphere
    float tpla = iPlane(ro,rd);//intersect with a plane
    if(tsph>0.0){
        id = 1.0;
        resT = tsph;
    }
    if(tpla>0.0 && tpla<resT){
        id = 2.0;
        resT = tpla;
    }
    return id;
}

//simple ray trace
vec3 renderBasic(vec2 uv,vec2 p){
    vec3 col;
    vec2 q = p - vec2(0.5,0.5);//distance from pixel to point

    if(iTime%60==0){//step 1 get object mat from distance function
        //we draw black, by default
        col = vec3(0.0);//BGColor
        //we generate a ray with origin ro and direction rd
        vec3 ro = vec3(0.0, 1.0, 4.0);
        //vec3 ro = vec3(0.0, 0.5, 3.0);
        vec3 rd = normalize(vec3((-1.0+2.0*uv), -1.0));
        //we intersect the ray with the 3d scene
        float t;
        float id = intersect(ro,rd,t);

        //if(t>0.0){
        if(id>0.5 && id <1.5){
            //if we hit sphere
            col = vec3(0.3,0.6,0.7);
        }
        else if(id>1.5 && id <2.5){
            //if we hit the plane
            col = vec3(0.6,0.3,0.1);
        }

    }
    else if(iTime%60>=1){//step 2 get object normals
        //we draw black, by default
        col = vec3(0.6);//BGColor
        //move the sphere
        sph1 = vec4(0.0,1.0,0.0,1.0);//sphere transform
        sph1.x = (0.5+cos(time));
        sph1.z = (0.5+sin(time));
        vec3 light = normalize(vec3(0.5703));
        //we generate a ray with origin ro and direction rd
        //vec3 ro = vec3(0.0, 1.0, 4.0);
        vec3 ro = vec3(0.0, 0.5, 5.0);
        vec3 rd = normalize(vec3((-1.0+2.0*uv), -1.0));
        //we intersect the ray with the 3d scene
        float t;
        float id = intersect(ro,rd,t);
        //for lighting we need normals
        if(id>0.5 && id<1.5){
            //if we hit sphere
            vec3 pos = ro + t*rd;
            vec3 nor = nSphere(pos, sph1);
            float dif = clamp(dot(nor,light),0.0,1.0);
            float ao = 0.5 + 0.5*nor.y;
            col = vec3(0.9,0.8,0.6)*dif*ao + ao*vec3(0.1,0.2,0.4);
        }
        else if(id>1.5 && id <2.5){
            //if we hit the plane
            vec3 pos = ro + t*rd;
            vec3 nor = nPlane(pos);
            float dif = clamp(dot(nor,light),0.0,1.0);
            float amb = smoothstep(0.0, sph1.w, length(pos.xz-sph1.xz));
            col = vec3(amb+0.7);
        }

    }
    return col;
}

//----------------------------------------------------------------------------------------------------
float sdPlane( vec3 p )
{
    return p.y;
}
float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}
float sdSphere( in vec3 p, in vec4 s )
{
    return length(p-s.xyz) - s.w;//length(p)-s;
}
float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}
float udRoundBox( vec3 p, vec3 b, float r )
{
    return length(max(abs(p)-b,0.0))-r;
}
float sdHexPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
#if 0
    return max(q.z-h.y,max((q.x*0.866025+q.y*0.5),q.y)-h.x);
#else
    float d1 = q.z-h.y;
    float d2 = max((q.x*0.866025+q.y*0.5),q.y)-h.x;
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
#endif
}
float sdEquilateralTriangle(  in vec2 p )
{
    const float k = sqrt(3.0);
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0/k;
    if( p.x + k*p.y > 0.0 ) p = vec2( p.x - k*p.y, -k*p.x - p.y )/2.0;
    p.x += 2.0 - 2.0*clamp( (p.x+2.0)/2.0, 0.0, 1.0 );
    return -length(p)*sign(p.y);
}
float sdTriPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
    float d1 = q.z-h.y;
#if 1
    // distance bound
    float d2 = max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5;
#else
    // correct distance
    h.x *= 0.866025;
    float d2 = sdEquilateralTriangle(p.xy/h.x)*h.x;
#endif
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}
float sdCylinder( vec3 p, vec2 h )
{
    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
float sdCone( in vec3 p, in vec3 c )
{
    vec2 q = vec2( length(p.xz), p.y );
    float d1 = -q.y-c.z;
    float d2 = max( dot(q,c.xy), q.y);
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}
float sdConeSection( in vec3 p, in float h, in float r1, in float r2 )
{
    float d1 = -p.y - h;
    float q = p.y - h;
    float si = 0.5*(r1-r2)/h;
    float d2 = max( sqrt( dot(p.xz,p.xz)*(1.0-si*si)) + q*si - r2, q );
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}
float sdPryamid4(vec3 p, vec3 h ) // h = { cos a, sin a, height }
{
    // Tetrahedron = Octahedron - Cube
    float box = sdBox( p - vec3(0,-2.0*h.z,0), vec3(2.0*h.z) );

    float d = 0.0;
    d = max( d, abs( dot(p, vec3( -h.x, h.y, 0 )) ));
    d = max( d, abs( dot(p, vec3(  h.x, h.y, 0 )) ));
    d = max( d, abs( dot(p, vec3(  0, h.y, h.x )) ));
    d = max( d, abs( dot(p, vec3(  0, h.y,-h.x )) ));
    float octa = d - h.z;
    return max(-box,octa); // Subtraction
}
float length2( vec2 p )
{
    return sqrt( p.x*p.x + p.y*p.y );
}
float length6( vec2 p )
{
    p = p*p*p; p = p*p;
    return pow( p.x + p.y, 1.0/6.0 );
}
float length8( vec2 p )
{
    p = p*p; p = p*p; p = p*p;
    return pow( p.x + p.y, 1.0/8.0 );
}
float sdTorus82( vec3 p, vec2 t )
{
    vec2 q = vec2(length2(p.xz)-t.x,p.y);
    return length8(q)-t.y;
}
float sdTorus88( vec3 p, vec2 t )
{
    vec2 q = vec2(length8(p.xz)-t.x,p.y);
    return length8(q)-t.y;
}
float sdCylinder6( vec3 p, vec2 h )
{
    return max( length6(p.xz)-h.x, abs(p.y)-h.y );
}
float sdEllipsoid( in vec3 p, in vec3 r )
{
    return (length( p/r ) - 1.0) * min(min(r.x,r.y),r.z);
}
float sdEllipsoid( in vec3 p, in vec3 c, in vec3 r )
{
    return (length( (p-c)/r ) - 1.0) * min(min(r.x,r.y),r.z);//(length( p/r ) - 1.0) * min(min(r.x,r.y),r.z);
}
float sdEllipsoid( in vec2 p, in vec2 c, in vec2 r )
{
    return (length( (p-c)/r ) - 1.0) * min(r.x,r.y);
}
float sdTorus( vec3 p, vec2 t )
{
    return length( vec2(length(p.xz)-t.x,p.y) )-t.y;
}
float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}
//----------------------------------------------------------------------------------------------------

vec2 udSegment( vec3 p, vec3 a, vec3 b )
{
    vec3 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return vec2( length( pa - ba*h ), h );
}

// http://research.microsoft.com/en-us/um/people/hoppe/ravg.pdf
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

vec4 sdBezier( vec3 a, vec3 b, vec3 c, vec3 p )
{
    vec3 w = normalize( cross( c-b, a-b ) );
    vec3 u = normalize( c-b );
    vec3 v = normalize( cross( w, u ) );

    vec2 a2 = vec2( dot(a-b,u), dot(a-b,v) );
    vec2 b2 = vec2( 0.0 );
    vec2 c2 = vec2( dot(c-b,u), dot(c-b,v) );
    vec3 p3 = vec3( dot(p-b,u), dot(p-b,v), dot(p-b,w) );

    vec3 cp = getClosest( a2-p3.xy, b2-p3.xy, c2-p3.xy );

    return vec4( sqrt(dot(cp.xy,cp.xy)+p3.z*p3.z), cp.z, length(cp.xy), p3.z );
}

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

//---------------------------------------------------------------------------

float hash1( float n )
{
    return fract(sin(n)*43758.5453123);
}

vec3 hash3( float n )
{
    return fract(sin(n+vec3(0.0,13.1,31.3))*158.5453123);
}

vec3 forwardSF( float i, float n)
{
    const float PI  = 3.141592653589793238;
    const float PHI = 1.618033988749894848;
    float phi = 2.0*PI*fract(i/PHI);
    float zi = 1.0 - (2.0*i+1.0)/n;
    float sinTheta = sqrt( 1.0 - zi*zi);
    return vec3( cos(phi)*sinTheta, sin(phi)*sinTheta, zi);
}

//------------------------------------------------------------------

float opS( float d1, float d2 )
{
    return max(-d2,d1);
}

vec2 opU( vec2 d1, vec2 d2 )
{
    return (d1.x<d2.x) ? d1 : d2;
}

vec3 opRep( vec3 p, vec3 c )
{
    return mod(p,c)-0.5*c;
}

vec3 opTwist( vec3 p )
{
    float  c = cos(10.0*p.y+10.0);
    float  s = sin(10.0*p.y+10.0);
    mat2   m = mat2(c,-s,s,c);
    return vec3(m*p.xz,p.y);
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

//---------------------------------------------------------------------------

const float pi = 3.1415927;

float mapShell( in vec3 p, out vec4 matInfo )
{

    const float sc = 1.0/1.0;
    p -= vec3(0.05,0.12,-0.09);

    p *= sc;

    vec3 q = mat3(-0.6333234236, -0.7332753384, 0.2474039592,
                  0.7738444477, -0.6034162289, 0.1924931824,
                  0.0081370606,  0.3133626215, 0.9495986813) * p;

    const float b = 0.1759;

    float r = length( q.xy );
    float t = atan( q.y, q.x );

    // https://swiftcoder.wordpress.com/2010/06/21/logarithmic-spiral-distance-field/
    float n = (log(r)/b - t)/(2.0*pi);

    const float th = 0.11;
    float nm = (log(th)/b-t)/(2.0*pi);

    n = min(n,nm);

    float ni = floor( n );

    float r1 = exp( b * (t + 2.0*pi*ni));
    float r2 = r1 * 3.019863;

    //-------

    float h1 = q.z + 1.5*r1 - 0.5;
    float d1 = sqrt( (r1-r)*(r1-r) + h1*h1) - r1;
    float h2 = q.z + 1.5*r2 - 0.5;
    float d2 = sqrt( (r2-r)*(r2-r) + h2*h2) - r2;

    float d, dx, dy;
    if( d1<d2 ) { d = d1; dx=r1-r; dy=h1; }
    else        { d = d2; dx=r2-r; dy=h2; }


    float di = textureLod( fragTexture, vec2(t+r,0.5), 0. ).x;//textureLod( iChannel2, vec2(t+r,0.5), 0. ).x;
    d += 0.002*di;

    matInfo = vec4(dx,dy,r/0.4,t/3.14159);

    vec3 s = q;
    q = q - vec3(0.34,-0.1,0.03);
    q.xy = mat2(0.8,0.6,-0.6,0.8)*q.xy;
    d = smin( d, sdTorus( q, vec2(0.28,0.05) ), 0.06);
    d = smax( d, -sdEllipsoid(q,vec3(0.0,0.0,0.0),vec3(0.24,0.36,0.24) ), 0.03 );

    d = smax( d, -sdEllipsoid(s,vec3(0.52,-0.0,0.0),vec3(0.42,0.23,0.5) ), 0.05 );

    return d/sc;
}
vec2 mapSnail( vec3 p, out vec4 matInfo )
{
    vec3 head = vec3(-0.76,0.6,-0.3);

    vec3 q = p - head;

    // body
#if 1
    vec4 b1 = sdBezier( vec3(-0.13,-0.65,0.0), vec3(0.24,0.9+0.1,0.0), head+vec3(0.04,0.01,0.0), p );
    float d1 = b1.x;
    d1 -= smoothstep(0.0,0.2,b1.y)*(0.16 - 0.07*smoothstep(0.5,1.0,b1.y));
    b1 = sdBezier( vec3(-0.085,0.0,0.0), vec3(-0.1,0.9-0.05,0.0), head+vec3(0.06,-0.08,0.0), p );
    float d2 = b1.x;
    d2 -= 0.1 - 0.06*b1.y;
    d1 = smin( d1, d2, 0.03 );
    matInfo.xyz = b1.yzw;
#else
    vec4 b1 = sdBezier( vec3(-0.13,-0.65,0.0), vec3(0.24,0.9+0.11,0.0), head+vec3(0.05,0.01-0.02,0.0), p );
    float d1 = b1.x;
    d1 -= smoothstep(0.0,0.2,b1.y)*(0.16 - 0.75*0.07*smoothstep(0.5,1.0,b1.y));
    matInfo.xyz = b1.yzw;
    float d2;
#endif
    d2 = sdSphere( q, vec4(0.0,-0.06,0.0,0.085) );
    d1 = smin( d1, d2, 0.03 );

    d1 = smin( d1, sdSphere(p,vec4(0.05,0.52,0.0,0.13)), 0.07 );

    q.xz = mat2(0.8,0.6,-0.6,0.8)*q.xz;

    vec3 sq = vec3( q.xy, abs(q.z) );

    // top antenas
    vec3 af = 0.05*sin(0.5*time+vec3(0.0,1.0,3.0) + vec3(2.0,1.0,0.0)*sign(q.z) );
    vec4 b2 = sdBezier( vec3(0.0), vec3(-0.1,0.2,0.2), vec3(-0.3,0.2,0.3)+af, sq );
    float d3 = b2.x;
    d3 -= 0.03 - 0.025*b2.y;
    d1 = smin( d1, d3, 0.04 );
    d3 = sdSphere( sq, vec4(-0.3,0.2,0.3,0.016) + vec4(af,0.0) );
    d1 = smin( d1, d3, 0.01 );

    // bottom antenas
    vec3 bf = 0.02*sin(0.3*time+vec3(4.0,1.0,2.0) + vec3(3.0,0.0,1.0)*sign(q.z) );
    vec2 b3 = udSegment( sq, vec3(0.06,-0.05,0.0), vec3(-0.04,-0.2,0.18)+bf );
    d3 = b3.x;
    d3 -= 0.025 - 0.02*b3.y;
    d1 = smin( d1, d3, 0.06 );
    d3 = sdSphere( sq, vec4(-0.04,-0.2,0.18,0.008)+vec4(bf,0.0) );
    d1 = smin( d1, d3, 0.02 );

    // bottom
    vec3 pp = p-vec3(-0.17,0.15,0.0);
    float co = 0.988771078;
    float si = 0.149438132;
    pp.xy = mat2(co,-si,si,co)*pp.xy;
    d1 = smin( d1, sdEllipsoid( pp, vec3(0.0,0.0,0.0), vec3(0.084,0.3,0.15) ), 0.05 );
    d1 = smax( d1, -sdEllipsoid( pp, vec3(-0.08,-0.0,0.0), vec3(0.06,0.55,0.1) ), 0.02 );

    // disp
    float dis = textureLod( fragTexture, 5.0*p.xy, 0. ).x;//textureLod( iChannel1, 5.0*p.xy, 0. ).x;
    float dx = 0.5 + 0.5*(1.0-smoothstep(0.5,1.0,b1.y));
    d1 -= 0.005*dis*dx*0.5;

    return vec2(d1,1.0);
}
float mapDrop( in vec3 p )
{
    p -= vec3(-0.26,0.25,-0.02);
    p.x -= 2.5*p.y*p.y;
    return sdCapsule( p, vec3(0.0,-0.06,0.0), vec3(0.014,0.06,0.0), 0.037 );
}
float mapLeaf( in vec3 p )
{
    p -= vec3(-1.8,0.6,-0.75);

    p = mat3(0.671212, 0.366685, -0.644218,
             -0.479426, 0.877583,  0.000000,
             0.565354, 0.308854,  0.764842)*p;

    p.y += 0.2*exp(-abs(2.0*p.z) );


    float ph = 0.25*50.0*p.x - 0.25*75.0*abs(p.z);// + 1.0*sin(5.0*p.x)*sin(5.0*p.z);
    float rr = sin( ph );
    rr = rr*rr;
    rr = rr*rr;
    p.y += 0.005*rr;

    float r = clamp((p.x+2.0)/4.0,0.0,1.0);
    r = 0.0001 + r*(1.0-r)*(1.0-r)*6.0;

    rr = sin( ph*2.0 );
    rr = rr*rr;
    rr *= 0.5+0.5*sin( p.x*12.0 );

    float ri = 0.035*rr;

    float d = sdEllipsoid( p, vec3(0.0), vec3(2.0,0.25*r,r+ri) );

    float d2 = p.y-0.02;
    d = smax( d, -d2, 0.02 );

    return d;
}
vec2 mapOpaque( vec3 p, out vec4 matInfo )
{
    matInfo = vec4(0.0);

    //--------------
    vec2 res = mapSnail( p, matInfo );

    //---------------
    vec4 tmpMatInfo;
    float d4 = mapShell( p, tmpMatInfo );
    if( d4<res.x  ) { res = vec2(d4,2.0); matInfo = tmpMatInfo; }

    //---------------

    // plant
    vec4 b3 = sdBezier( vec3(-0.15,-1.5,0.0), vec3(-0.1,0.5,0.0), vec3(-0.6,1.5,0.0), p );
    d4 = b3.x;
    d4 -= 0.04 - 0.02*b3.y;
    if( d4<res.x  ) { res = vec2(d4,3.0); }

    //----------------------------

    float d5 = mapLeaf( p );
    if( d5<res.x ) res = vec2(d5,4.0);

    return res;
}
vec2 mapObjects( in vec3 pos )
{
    vec2 res = opU( vec2( sdPlane(     pos), 1.0 ),
                    vec2( sdSphere(    pos-vec3( 0.0,0.25, 0.0), 0.25 ), 46.9 ) );
    res = opU( res, vec2( sdBox(       pos-vec3( 1.0,0.25, 0.0), vec3(0.25) ), 3.0 ) );
    res = opU( res, vec2( udRoundBox(  pos-vec3( 1.0,0.25, 1.0), vec3(0.15), 0.1 ), 41.0 ) );
    res = opU( res, vec2( sdTorus(     pos-vec3( 0.0,0.25, 1.0), vec2(0.20,0.05) ), 25.0 ) );
    res = opU( res, vec2( sdCapsule(   pos,vec3(-1.3,0.10,-0.1), vec3(-0.8,0.50,0.2), 0.1  ), 31.9 ) );
    res = opU( res, vec2( sdTriPrism(  pos-vec3(-1.0,0.25,-1.0), vec2(0.25,0.05) ),43.5 ) );
    res = opU( res, vec2( sdCylinder(  pos-vec3( 1.0,0.30,-1.0), vec2(0.1,0.2) ), 8.0 ) );
    res = opU( res, vec2( sdCone(      pos-vec3( 0.0,0.50,-1.0), vec3(0.8,0.6,0.3) ), 55.0 ) );
    res = opU( res, vec2( sdTorus82(   pos-vec3( 0.0,0.25, 2.0), vec2(0.20,0.05) ),50.0 ) );
    res = opU( res, vec2( sdTorus88(   pos-vec3(-1.0,0.25, 2.0), vec2(0.20,0.05) ),43.0 ) );
    res = opU( res, vec2( sdCylinder6( pos-vec3( 1.0,0.30, 2.0), vec2(0.1,0.2) ), 12.0 ) );
    res = opU( res, vec2( sdHexPrism(  pos-vec3(-1.0,0.20, 1.0), vec2(0.25,0.05) ),17.0 ) );
    res = opU( res, vec2( sdPryamid4(  pos-vec3(-1.0,0.15,-2.0), vec3(0.8,0.6,0.25) ),37.0 ) );
    res = opU( res, vec2( opS( udRoundBox(  pos-vec3(-2.0,0.2, 1.0), vec3(0.15),0.05),
                               sdSphere(    pos-vec3(-2.0,0.2, 1.0), 0.25)), 13.0 ) );
    res = opU( res, vec2( opS( sdTorus82(  pos-vec3(-2.0,0.2, 0.0), vec2(0.20,0.1)),
                               sdCylinder(  opRep( vec3(atan(pos.x+2.0,pos.z)/6.2831, pos.y, 0.02+0.5*length(pos-vec3(-2.0,0.2, 0.0))), vec3(0.05,1.0,0.05)), vec2(0.02,0.6))), 51.0 ) );
    res = opU( res, vec2( 0.5*sdSphere(    pos-vec3(-2.0,0.25,-1.0), 0.2 ) + 0.03*sin(50.0*pos.x)*sin(50.0*pos.y)*sin(50.0*pos.z), 65.0 ) );
    res = opU( res, vec2( 0.5*sdTorus( opTwist(pos-vec3(-2.0,0.25, 2.0)),vec2(0.20,0.05)), 46.7 ) );
    res = opU( res, vec2( sdConeSection( pos-vec3( 0.0,0.35,-2.0), 0.15, 0.2, 0.1 ), 13.67 ) );
    res = opU( res, vec2( sdEllipsoid( pos-vec3( 1.0,0.35,-2.0), vec3(0.15, 0.2, 0.05) ), 43.17 ) );

    return res;
}
vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*mapObjects( pos + e.xyy ).x +
                      e.yyx*mapObjects( pos + e.yyx ).x +
                      e.yxy*mapObjects( pos + e.yxy ).x +
                      e.xxx*mapObjects( pos + e.xxx ).x );
    /*
        vec3 eps = vec3( 0.0005, 0.0, 0.0 );
        vec3 nor = vec3(
            mapObjects(pos+eps.xyy).x - mapObjects(pos-eps.xyy).x,
            mapObjects(pos+eps.yxy).x - mapObjects(pos-eps.yxy).x,
            mapObjects(pos+eps.yyx).x - mapObjects(pos-eps.yyx).x );
        return normalize(nor);
        */
}
vec3 calcNormalOpaque( in vec3 pos, in float eps )
{
    vec4 kk;
    vec2 e = vec2(1.0,-1.0)*0.5773*eps;
    return normalize( e.xyy*mapOpaque( pos + e.xyy, kk ).x +
                      e.yyx*mapOpaque( pos + e.yyx, kk ).x +
                      e.yxy*mapOpaque( pos + e.yxy, kk ).x +
                      e.xxx*mapOpaque( pos + e.xxx, kk ).x );
}

//=========================================================================

float mapLeafWaterDrops( in vec3 p )
{
    p -= vec3(-1.8,0.6,-0.75);
    vec3 s = p;
    p = mat3(0.671212, 0.366685, -0.644218,
             -0.479426, 0.877583,  0.000000,
             0.565354, 0.308854,  0.764842)*p;

    vec3 q = p;
    p.y += 0.2*exp(-abs(2.0*p.z) );

    //---------------

    float r = clamp((p.x+2.0)/4.0,0.0,1.0);
    r = r*(1.0-r)*(1.0-r)*6.0;
    float d0 = sdEllipsoid( p, vec3(0.0), vec3(2.0,0.25*r,r) );
    float d1 = sdEllipsoid( q, vec3(0.5,0.0,0.2), 1.0*vec3(0.15,0.13,0.15) );
    float d2 = sdEllipsoid( q, vec3(0.8,-0.07,-0.15), 0.5*vec3(0.15,0.13,0.15) );
    float d3 = sdEllipsoid( s, vec3(0.76,-0.8,0.6), 0.5*vec3(0.15,0.2,0.15) );
    float d4 = sdEllipsoid( q, vec3(-0.5,0.09,-0.2), vec3(0.04,0.03,0.04) );

    d3 = max( d3, p.y-0.01);

    float d = min( min(d1,d4), min(d2,d3) );

    return d;
}

vec2 mapTransparent( vec3 p, out vec4 matInfo )
{
    matInfo = vec4(0.0);

    float d5 = mapDrop( p );
    vec2  res = vec2(d5,4.0);

    float d6 = mapLeafWaterDrops( p );
    res.x = min( res.x, d6 );

    return res;
}

vec3 calcNormalTransparent( in vec3 pos, in float eps )
{
    vec4 kk;
    vec2 e = vec2(1.0,-1.0)*0.5773*eps;
    return normalize( e.xyy*mapTransparent( pos + e.xyy, kk ).x +
                      e.yyx*mapTransparent( pos + e.yyx, kk ).x +
                      e.yxy*mapTransparent( pos + e.yxy, kk ).x +
                      e.xxx*mapTransparent( pos + e.xxx, kk ).x );
}

//=========================================================================
float calcAO5( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = mapObjects( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );
}
float calcAO32( in vec3 pos, in vec3 nor )
{
    vec4 kk;
    float ao = 0.0;
    for( int i=0; i<32; i++ )
    {
        vec3 ap = forwardSF( float(i), 32.0 );
        float h = hash1(float(i));
        ap *= sign( dot(ap,nor) ) * h*0.1;
        ao += clamp( mapOpaque( pos + nor*0.01 + ap, kk ).x*3.0, 0.0, 1.0 );
    }
    ao /= 32.0;

    return clamp( ao*6.0, 0.0, 1.0 );
}
float calcSSS( in vec3 pos, in vec3 nor )
{
    vec4 kk;
    float occ = 0.0;
    for( int i=0; i<8; i++ )
    {
        float h = 0.002 + 0.11*float(i)/7.0;
        vec3 dir = normalize( sin( float(i)*13.0 + vec3(0.0,2.1,4.2) ) );
        dir *= sign(dot(dir,nor));
        occ += (h-mapOpaque(pos-h*dir, kk).x);
    }
    occ = clamp( 1.0 - 11.0*occ/8.0, 0.0, 1.0 );
    return occ*occ;
}
float calcSoftShadow( in vec3 ro, in vec3 rd, float k )
{
    vec4 kk;
    float res = 1.0;
    float t = 0.01;
    for( int i=0; i<32; i++ )
    {
        float h = mapOpaque(ro + rd*t, kk ).x;
        res = min( res, smoothstep(0.0,1.0,k*h/t) );
        t += clamp( h, 0.04, 0.1 );
        if( res<0.01 ) break;
    }
    return clamp(res,0.0,1.0);
}
float softshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<16; i++ )
    {
        float h = mapObjects( ro + rd*t ).x;
        res = min( res, 8.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}
vec3 sunDir = normalize( vec3(0.2,0.1,0.02) );
vec3 shadeOpaque( in vec3 ro, in vec3 rd, in float t, in float m, in vec4 matInfo )
{
    float eps = 0.002;

    vec3 pos = ro + t*rd;
    vec3 nor = calcNormalOpaque( pos, eps );

    vec3 mateD = vec3(0.0);
    vec3 mateS = vec3(0.0);
    vec2 mateK = vec2(0.0);
    vec3 mateE = vec3(0.0);

    float focc = 1.0;
    float fsha = 1.0;

    if( m<1.5 ) // snail body
    {
        float dis = texture( fragTexture, 5.0*pos.xy ).x;//texture( iChannel1, 5.0*pos.xy ).x;

        float be = sdEllipsoid( pos, vec3(-0.3,-0.5,-0.1), vec3(0.2,1.0,0.5) );
        be = 1.0-smoothstep( -0.01, 0.01, be );

        float ff = abs(matInfo.x-0.20);

        mateS = 6.0*mix( 0.7*vec3(2.0,1.2,0.2), vec3(2.5,1.8,0.9), ff );
        mateS += 2.0*dis;
        mateS *= 1.5;
        mateS *= 1.0 + 0.5*ff*ff;
        mateS *= 1.0-0.5*be;

        mateD = vec3(1.0,0.8,0.4);
        mateD *= dis;
        mateD *= 0.015;
        mateD += vec3(0.8,0.4,0.3)*0.15*be;

        mateK = vec2( 60.0, 0.7 + 2.0*dis );

        float f = clamp( dot( -rd, nor ), 0.0, 1.0 );
        f = 1.0-pow( f, 8.0 );
        f = 1.0 - (1.0-f)*(1.0-texture( fragTexture, 0.3*pos.xy ).x);//1.0 - (1.0-f)*(1.0-texture( iChannel2, 0.3*pos.xy ).x);
        mateS *= vec3(0.5,0.1,0.0) + f*vec3(0.5,0.9,1.0);

        float b = 1.0-smoothstep( 0.25,0.55,abs(pos.y));
        focc = 0.2 + 0.8*smoothstep( 0.0, 0.15, sdSphere(pos,vec4(0.05,0.52,0.0,0.13)) );
    }
    else if( m<2.5 ) // shell
    {
        mateK = vec2(0.0);

        float tip = 1.0-smoothstep(0.05,0.4, length(pos-vec3(0.17,0.2,0.35)) );
        mateD = mix( 0.7*vec3(0.2,0.21,0.22), 0.2*vec3(0.15,0.1,0.0), tip );

        vec2 uv = vec2( .5*atan(matInfo.x,matInfo.y)/3.1416, 1.5*matInfo.w );

        vec3 ral = texture( fragTexture, vec2(2.0*matInfo.w+matInfo.z*0.5,0.5) ).xxx;//texture( iChannel1, vec2(2.0*matInfo.w+matInfo.z*0.5,0.5) ).xxx;
        mateD *= 0.25 + 0.75*ral;

        float pa = smoothstep(-0.2,0.2, 0.3+sin(2.0+40.0*uv.x + 3.0*sin(11.0*uv.x)) );
        float bar = mix(pa,1.0,smoothstep(0.7,1.0,tip));
        bar *= (matInfo.z<0.6) ? 1.0 : smoothstep( 0.17, 0.21, abs(matInfo.w)  );
        mateD *= vec3(0.06,0.03,0.0)+vec3(0.94,0.97,1.0)*bar;

        mateK = vec2( 64.0, 0.2 );
        mateS = 1.5*vec3(1.0,0.65,0.6) * (1.0-tip);//*0.5;
    }
    else if( m<3.5 ) // plant
    {
        mateD = vec3(0.05,0.1,0.0)*0.2;
        mateS = vec3(0.1,0.2,0.02)*25.0;
        mateK = vec2(5.0,1.0);

        float fre = clamp(1.0+dot(nor,rd), 0.0, 1.0 );
        mateD += 0.2*fre*vec3(1.0,0.5,0.1);

        vec3 te = texture( fragTexture, pos.xy*0.2 ).xyz;//texture( iChannel2, pos.xy*0.2 ).xyz;
        mateS *= 0.5 + 1.5*te;
        mateE = 0.5*vec3(0.1,0.1,0.03)*(0.2+0.8*te.x);
    }
    else //if( m<4.5 ) // leave
    {
        vec3 p = pos - vec3(-1.8,0.6,-0.75);
        vec3 s = p;
        p = mat3(0.671212, 0.366685, -0.644218,
                 -0.479426, 0.877583,  0.000000,
                 0.565354, 0.308854,  0.764842)*p;

        vec3 q = p;
        p.y += 0.2*exp(-abs(2.0*p.z) );

        float v = smoothstep( 0.01, 0.02, abs(p.z));

        float rr = sin( 4.0*0.25*50.0*p.x - 4.0*0.25*75.0*abs(p.z) );

        vec3 te = texture( fragTexture, p.xz*0.35 ).xyz;//texture( iChannel2, p.xz*0.35 ).xyz;

        float r = clamp((p.x+2.0)/4.0,0.0,1.0);
        r = r*(1.0-r)*(1.0-r)*6.0;
        float ff = length(p.xz/vec2(2.0,r));

        mateD = mix( vec3(0.07,0.1,0.0), vec3(0.05,0.2,0.01)*0.25, v );
        mateD = mix( mateD, vec3(0.16,0.2,0.01)*0.25, ff );
        mateD *= 1.0 + 0.25*te;
        mateD *= 0.8;

        mateS = vec3(0.15,0.2,0.02)*0.8;
        mateS *= 1.0 + 0.2*rr;
        mateS *= 0.8;

        mateK = vec2(64.0,0.25);

        //---------------------

        nor.xz += v*0.15*(-1.0+2.0*texture( fragTexture, 1.0*p.xz ).xy);//v*0.15*(-1.0+2.0*texture( iChannel3, 1.0*p.xz ).xy);
        nor = normalize( nor );

        float d1 = sdEllipsoid( q, vec3( 0.5-0.07, 0.0,  0.20), 1.0*vec3(1.4*0.15,0.13,0.15) );
        float d2 = sdEllipsoid( q, vec3( 0.8-0.05,-0.07,-0.15), 0.5*vec3(1.3*0.15,0.13,0.15) );
        float d4 = sdEllipsoid( q, vec3(-0.5-0.07, 0.09,-0.20), 1.0*vec3(1.4*0.04,0.03,0.04) );
        float dd = min(d1,min(d2,d4));
        fsha = 0.05 + 0.95*smoothstep(0.0,0.05,dd);

        d1 = sdEllipsoid( q.xz, vec2( 0.5, 0.20), 1.0*vec2(0.15,0.15) );
        d2 = sdEllipsoid( q.xz, vec2( 0.8,-0.15), 0.5*vec2(0.15,0.15) );
        d4 = sdEllipsoid( q.xz, vec2(-0.5,-0.20), 1.0*vec2(0.04,0.04) );
        d1 = abs(d1);
        d2 = abs(d2);
        d4 = abs(d4);
        dd = min(d1,min(d2,d4));
        focc *= 0.55 + 0.45*smoothstep(0.0,0.08,dd);

        d1 = distance( q.xz, vec2( 0.5-0.07, 0.20) );
        d2 = distance( q.xz, vec2( 0.8-0.03,-0.15) );
        fsha += (1.0-smoothstep(0.0,0.10,d1))*1.5;
        fsha += (1.0-smoothstep(0.0,0.05,d2))*1.5;
    }


    vec3 hal = normalize( sunDir-rd );
    float fre = clamp(1.0+dot(nor,rd), 0.0, 1.0 );
    float occ = calcAO32( pos, nor )*focc;
    float sss = calcSSS( pos, nor );
    sss = sss*occ + fre*occ + (0.5+0.5*fre)*pow(abs(matInfo.x-0.2),1.0)*occ;

    float dif1 = clamp( dot(nor,sunDir), 0.0, 1.0 );
    float sha = calcSoftShadow( pos, sunDir, 20.0 );
    dif1 *= sha*fsha;
    float spe1 = clamp( dot(nor,hal), 0.0, 1.0 );

    float bou = clamp( 0.3-0.7*nor.y, 0.0, 1.0 );

    // illumination

    vec3 col = vec3(0.0);
    col += 7.0*vec3(1.7,1.2,0.6)*dif1*2.0;           // sun
    col += 4.0*vec3(0.2,1.2,1.6)*occ*(0.5+0.5*nor.y);    // sky
    col += 1.8*vec3(0.1,2.0,0.1)*bou*occ;                // bounce

    col *= mateD;

    col += .4*sss*(vec3(0.15,0.1,0.05)+vec3(0.85,0.9,0.95)*dif1)*(0.05+0.95*occ)*mateS; // sss
    col = pow(col,vec3(0.6,0.8,1.0));

    col += vec3(1.0,1.0,1.0)*0.2*pow( spe1, 1.0+mateK.x )*dif1*(0.04+0.96*pow(fre,4.0))*mateK.x*mateK.y;   // sun lobe1
    col += vec3(1.0,1.0,1.0)*0.1*pow( spe1, 1.0+mateK.x/3.0 )*dif1*(0.1+0.9*pow(fre,4.0))*mateK.x*mateK.y; // sun lobe2
    col += 0.1*vec3(1.0,max(1.5-0.7*col.y,0.0),2.0)*occ*occ*smoothstep( 0.0, 0.3, reflect( rd, nor ).y )*mateK.x*mateK.y*(0.04+0.96*pow(fre,5.0)); // sky

    col += mateE;

    return col;
}
vec3 shadeTransparent( in vec3 ro, in vec3 rd, in float t, in float m, in vec4 matInfo, in vec3 col, in float depth )
{
    vec3 oriCol = col;

    float dz = depth - t;
    float ao = clamp(dz*50.0,0.0,1.0);
    vec3  pos = ro + t*rd;
    vec3  nor = calcNormalTransparent( pos, 0.002 );
    float fre = clamp( 1.0 + dot( rd, nor ), 0.0, 1.0 );
    vec3  hal = normalize( sunDir-rd );
    vec3  ref = reflect( -rd, nor );
    float spe1 = clamp( dot(nor,hal), 0.0, 1.0 );
    float spe2 = clamp( dot(ref,sunDir), 0.0, 1.0 );


    float ds = 1.6 - col.y;

    col *= mix( vec3(0.0,0.0,0.0), vec3(0.4,0.6,0.4), ao );

    col += ds*1.5*vec3(1.0,0.9,0.8)*pow( spe1, 80.0 );
    col += ds*0.2*vec3(0.9,1.0,1.0)*smoothstep(0.4,0.8,fre);
    col += ds*0.9*vec3(0.6,0.7,1.0)*smoothstep( -0.5, 0.5, -reflect( rd, nor ).y )*smoothstep(0.2,0.4,fre);
    col += ds*0.5*vec3(1.0,0.9,0.8)*pow( spe2, 80.0 );
    col += ds*0.5*vec3(1.0,0.9,0.8)*pow( spe2, 16.0 );
    col += vec3(0.8,1.0,0.8)*0.5*smoothstep(0.3,0.6,texture( fragTexture, 0.8*nor.xy ).x)*(0.1+0.9*fre*fre);//vec3(0.8,1.0,0.8)*0.5*smoothstep(0.3,0.6,texture( iChannel1, 0.8*nor.xy ).x)*(0.1+0.9*fre*fre);

    // hide aliasing a bit
    col = mix( col, oriCol, smoothstep(0.6,1.0,fre) );

    return col;
}

//--------------------------------------------

vec2 intersectOpaque( in vec3 ro, in vec3 rd, const float mindist, const float maxdist, out vec4 matInfo )
{
    vec2 res = vec2(-1.0);

    float t = mindist;
    for( int i=0; i<64; i++ )
    {
        vec3 p = ro + t*rd;
        vec2 h = mapOpaque( p, matInfo );
        res = vec2(t,h.y);

        if( h.x<(0.001*t) ||  t>maxdist ) break;

        t += h.x*0.9;
    }
    return res;
}
vec2 intersectTransparent( in vec3 ro, in vec3 rd, const float mindist, const float maxdist, out vec4 matInfo )
{
    vec2 res = vec2(-1.0);

    float t = mindist;
    for( int i=0; i<64; i++ )
    {
        vec3 p = ro + t*rd;
        vec2 h = mapTransparent( p, matInfo );
        res = vec2(t,h.y);

        if( h.x<(0.001*t) ||  t>maxdist ) break;

        t += h.x;
    }
    return res;
}
vec2 castRay( in vec3 ro, in vec3 rd )
{
    float tmin = 1.0;
    float tmax = 20.0;

#if 1
    // bounding volume
    float tp1 = (0.0-ro.y)/rd.y; if( tp1>0.0 ) tmax = min( tmax, tp1 );
    float tp2 = (1.6-ro.y)/rd.y; if( tp2>0.0 ) { if( ro.y>1.6 ) tmin = max( tmin, tp2 );
        else           tmax = min( tmax, tp2 ); }
#endif

    float t = tmin;
    float m = -1.0;
    for( int i=0; i<64; i++ )
    {
        float precis = 0.0005*t;
        vec2 res = mapObjects( ro+rd*t );
        if( res.x<precis || t>tmax ) break;
        t += res.x;
        m = res.y;
    }

    if( t>tmax ) m=-1.0;
    return vec2( t, m );
}

//--------------------------------------------

vec3 background( in vec3 d )
{
    // cheap cubemap
    vec3 n = abs(d);
    vec2 uv = (n.x>n.y && n.x>n.z) ? d.yz/d.x:
                                     (n.y>n.x && n.y>n.z) ? d.zx/d.y:
                                                            d.xy/d.z;

    // fancy blur
    vec3  col = vec3( 0.0 );
    for( int i=0; i<200; i++ )
    {
        float h = float(i)/200.0;
        float an = 31.0*6.2831*h;
        vec2  of = vec2( cos(an), sin(an) ) * h;

        vec3 tmp = texture( fragTexture, uv*0.25 + 0.0075*of, 4.0 ).yxz;//texture( iChannel2, uv*0.25 + 0.0075*of, 4.0 ).yxz;
        col = smax( col, tmp, 0.5 );
    }

    return pow(col,vec3(3.5,3.0,6.0))*0.2;
}

vec3 renderSnale( in vec3 ro, in vec3 rd, in vec2 q )
{
    //-----------------------------

    vec3 col = background( rd );

    //-----------------------------

    float mindist = 1.0;
    float maxdist = 4.0;

    vec4 matInfo;
    vec2 tm = intersectOpaque( ro, rd, mindist, maxdist, matInfo );
    if( tm.y>-0.5 && tm.x < maxdist )
    {
        col = shadeOpaque( ro, rd, tm.x, tm.y, matInfo );
        maxdist = tm.x;
    }

    //-----------------------------

    tm = intersectTransparent( ro, rd, mindist, maxdist, matInfo );
    if( tm.y>-0.5 && tm.x < maxdist )
    {
        col = shadeTransparent( ro, rd, tm.x, tm.y, matInfo, col, maxdist );
    }

    //-----------------------------

    float sun = clamp(dot(rd,sunDir),0.0,1.0);
    col += 1.0*vec3(1.5,0.8,0.7)*pow(sun,4.0);

    //-----------------------------

    col = pow( col, vec3(0.45) );

    col = 1.05*col + vec3(0.0,0.0,0.04);

    col *= 0.3 + 0.7*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.1);

    return clamp( col, 0.0, 1.0 );
}

vec3 renderObjects( in vec3 ro, in vec3 rd )
{
    vec3 col = vec3(0.7, 0.9, 1.0) +rd.y*0.8;
    vec2 res = castRay(ro,rd);
    float t = res.x;
    float m = res.y;
    if( m>-0.5 )
    {
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal( pos );
        vec3 ref = reflect( rd, nor );

        // material
        col = 0.45 + 0.35*sin( vec3(0.05,0.08,0.10)*(m-1.0) );
        if( m<1.5 )
        {

            float f = mod( floor(5.0*pos.z) + floor(5.0*pos.x), 2.0);
            col = 0.3 + 0.1*f*vec3(1.0);
        }

        // lighitng
        float occ = calcAO5( pos, nor );
        vec3  lig = normalize( vec3(-0.4, 0.7, -0.6) );
        float amb = clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
        float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        float bac = clamp( dot( nor, normalize(vec3(-lig.x,0.0,-lig.z))), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);
        float dom = smoothstep( -0.1, 0.1, ref.y );
        float fre = pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );
        float spe = pow(clamp( dot( ref, lig ), 0.0, 1.0 ),16.0);

        dif *= softshadow( pos, lig, 0.02, 2.5 );
        dom *= softshadow( pos, ref, 0.02, 2.5 );

        vec3 lin = vec3(0.0);
        lin += 1.30*dif*vec3(1.00,0.80,0.55);
        lin += 2.00*spe*vec3(1.00,0.90,0.70)*dif;
        lin += 0.40*amb*vec3(0.40,0.60,1.00)*occ;
        lin += 0.50*dom*vec3(0.40,0.60,1.00)*occ;
        lin += 0.50*bac*vec3(0.25,0.25,0.25)*occ;
        lin += 0.25*fre*vec3(1.00,1.00,1.00)*occ;
        col = col*lin;

        col = mix( col, vec3(0.8,0.9,1.0), 1.0-exp( -0.0002*t*t*t ) );
    }

    return vec3( clamp(col,0.0,1.0) );
}

mat3 setCamera( in vec3 ro, in vec3 rt, in float cr )
{
    vec3 cw = normalize(rt-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, -cw );
}

out vec4 color;
void main(void)
{

    vec3 result = vec3(0.0);
    //Phoong-Blinn Ray Trace
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

    if (selected){
        if (has_texture)
            color = vec4(result,opacity) *  texture(fragTexture, frag_uv);
        else
            color = vec4(result,opacity);
    }
    else {
        color = vec4(1.0,1.0,0.0,1.0);
        //uv are the pixel coordinates, from 0 to 1
        vec2 uv = frag_uv.xy;//frag_uv.xy / vec2(1.78,1.0);//frag_uv.xy / vec2(1.0,1.0);
        vec2 p = ((vec2(1.5)*normalize(frag_position).xy) - vec2(-0.5));//adjust point error
        vec3 col;
        if(iTime%180<5){//sceen1 Basic Ray Trace
            //if(iTime%2==0) col = render(uv,uv);
            //else
            col = renderBasic(uv,p);
        }
        else if(iTime%180<10){//sceen2 Snale Ray March
#if AntiAliasingSamples<2

            p = (-iResolution.xy+2.0*(frag_uv.xy*iResolution.xy))/iResolution.y;
            vec2  q = frag_uv.xy;
            float an = 1.87 - 0.04*(1.0-cos(0.5*time));

            vec3  ro = vec3(-0.4,0.2,0.0) + 2.2*vec3(cos(an),0.0,sin(an));
            vec3  ta = vec3(-0.6,0.2,0.0);
            mat3  ca = setCamera( ro, ta, 0.0 );
            vec3  rd = normalize( ca * vec3(p,-2.8) );

            col = renderSnale( ro, rd, q );

#else

            col = vec3(0.0);
            for( int m=0; m<AntiAliasingSamples; m++ )
                for( int n=0; n<AntiAliasingSamples; n++ )
                {
                    vec2 rr = vec2( float(m), float(n) ) / float(AntiAliasingSamples);

                    p = (-iResolution.xy+2.0*((frag_uv.xy*iResolution.xy)+rr))/iResolution.y;
                    float an = 1.87 - 0.04*(1.0-cos(0.5*time));
                    vec2 q = (frag_uv.xy+rr)/iResolution.xy;

                    vec3 ro = vec3(-0.4,0.2,0.0) + 2.2*vec3(cos(an),0.0,sin(an));
                    vec3 ta = vec3(-0.6,0.2,0.0);
                    mat3 ca = setCamera( ro, ta, 0.0 );
                    vec3 rd = normalize( ca * vec3(p,-2.8) );

                    col += renderSnale( ro, rd, q );
                }
            col /= float(AntiAliasingSamples*AntiAliasingSamples);
#endif

        }
        else if(iTime%180>0){//sceen2 Basic Ray March Objects
            col = vec3(0.0);
            vec2 mo = iMouse.xy/iResolution.xy;
            //time = 15.0 + iFrame;
#if AntiAliasingSamples>1
            for( int m=0; m<AntiAliasingSamples; m++ )
                for( int n=0; n<AntiAliasingSamples; n++ )
                {
                    // pixel coordinates
                    vec2 o = vec2(float(m),float(n)) / float(AntiAliasingSamples) - 0.5;
                    p = (-iResolution.xy + 2.0*((frag_uv.xy*iResolution.xy)+o))/iResolution.y;

                    // camera
                    float an = 1.87 - 0.04*(1.0-cos(0.5*time));
                    vec3 ro = vec3( -0.5+3.5*cos(0.1*time + 6.0*mo.x), 1.0 + 2.0*mo.y, 0.5 + 4.0*sin(0.1*time + 6.0*mo.x) );
                    vec3 ta = vec3( -0.5, -0.4, 0.5 );
                    // camera-to-world transformation
                    mat3 ca = setCamera( ro, ta, 0.0 );
                    // ray direction
                    vec3 rd = ca * normalize( vec3(p.xy,-2.0) );

                    // render
                    col = renderObjects( ro, rd );

                    // gamma
                    col = pow( col, vec3(0.4545) );

                    //col += col;
                }

            col /= float(AntiAliasingSamples*AntiAliasingSamples);
#else
            p = (-iResolution.xy + 2.0*(frag_uv.xy*iResolution.xy))/iResolution.y;

            // camera
            float an = 1.87 - 0.04*(1.0-cos(0.5*time));
            vec3 ro = vec3( -0.5+3.5*cos(0.1*time + 6.0*mo.x), 1.0 + 2.0*mo.y, 0.5 + 4.0*sin(0.1*time + 6.0*mo.x) );
            vec3 ta = vec3( -0.5, -0.4, 0.5 );
            // camera-to-world transformation
            mat3 ca = setCamera( ro, ta, 0.0 );
            // ray direction
            vec3 rd = ca * normalize( vec3(p.xy,2.0) );

            // render
            col = renderObjects( ro, rd );

            // gamma
            col = pow( col, vec3(0.4545) );

            //col += col;
#endif
        }
        else{//default
            col = vec3(uv,0.5+0.5*sin((float(iTime)/10)+(float(iFrame)/100)));
        }

        color = vec4(col,1.0);
    }

}
