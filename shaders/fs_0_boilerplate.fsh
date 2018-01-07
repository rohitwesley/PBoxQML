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


vec3 procedural2dsceen(vec2 uv,vec2 p){
    vec3 col;
    vec2 q = p - vec2(0.5,0.5);//distance from pixel to point

    if(iTime%15==0){//step 1
        col = vec3(1.0,0.4,0.1);
        col *= length(q);//circuler region around point
    }
    else if(iTime%15==1){//step 2
        col = vec3(1.0,0.4,0.1);
        float r = 0.2;
        col *= smoothstep(r,r+0.01,length(q));//circle of r radious from point
    }
    else if(iTime%15==2){//step 3
        col = vec3(1.0,0.4,0.1);
        float freq = 10.0;//no. of spikes/wave
        float ampl = 0.10;//size. of spikes/wave
        float r = 0.2 + ampl*cos(atan(q.y,q.x)*freq) ;//cos() waves around point
        col *= smoothstep(r,r+0.01,length(q));
    }
    else if(iTime%15==3){//step 4
        col = vec3(1.0,0.4,0.1);
        float freq = 10.0;//no. of spikes/wave
        float ampl = 0.10;//size. of spikes/wave
        float warpCircle = 20.0*q.x + 1.0;//warp waves on circle and rotate them
        float r = 0.2 + ampl*cos(atan(q.y,q.x)*freq + warpCircle) ;//cos() waves around point
        col *= smoothstep(r,r+0.01,length(q));
    }
    else if(iTime%15==4){//step 5
        col = vec3(1.0,0.4,0.1);
        float freq = 10.0;//no. of spikes/wave
        float ampl = 0.10;//size. of spikes/wave
        float warpCircle = 20.0*q.x + 1.0;//warp waves on circle and rotate them
        float r = 0.2 + ampl*cos(atan(q.y,q.x)*freq + warpCircle) ;//cos() waves around point
        col *= smoothstep(r,r+0.01,length(q));
        r = 0.015;//draw a line parallel to y axis with thickness r
        col *= smoothstep(r,r+0.002,abs(q.x));
    }
    else if(iTime%15==5){//step 6
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
    else if(iTime%15==6){//step 7
        q = p - vec2(0.3,0.7);//position object on screen
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
    else if(iTime%15==7){//step 8
        q = p - vec2(0.3,0.7);//position object on screen
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
    else if(iTime%15==8){//step 9
        q = p - vec2(0.3,0.7);//position object on screen
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
    else if(iTime%15==9){//step 10
        q = p - vec2(0.3,0.7);//position object on screen
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
    else if(iTime%15==10){//step 11
        q = p - vec2(0.3,0.7);//position object on screen
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
    else if(iTime%15==10){//step 11
        q = p - vec2(0.3,0.7);//position object on screen
        col = mix(vec3(1.0,0.4,0.1),vec3(1.0,0.8,0.3),sqrt(p.y));//make gradient bg with better spread using sqr
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

    if (selected){
        if (has_texture)
        color = vec4(result,opacity) *  texture(fragTexture, frag_uv);
    else
        color = vec4(result,opacity);
    }
    else {
        color = vec4(1.0,1.0,0.0,1.0);
        vec2 uv = frag_uv.xy ;
        vec2 p = ((vec2(1.5)*normalize(frag_position).xy) - vec2(-0.5)) ;//adjust point error
        vec3 col;
        if(iTime%20<15){//sceen1
            if(iTime%2==0) col = procedural2dsceen(uv,p);
            else col = procedural2dsceen(uv,uv);
        }
        else{//default
            col = vec3(uv,0.5+0.5*sin((float(iTime)/10)+(float(iFrame)/100)));
        }

        color = vec4(col,1.0);
    }

}
