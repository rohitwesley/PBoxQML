#version 330 core
in vec3 position;
in vec3 color;
in vec2 uv;
in vec3 normal;

out vec2 frag_uv;
out vec3 frag_position;
out vec3 frag_normal;
out vec3 geom_normal;
uniform mat4 modelviewprojectionMatrix;

void main(void)
{
    gl_Position   =  modelviewprojectionMatrix * vec4(position.xyz, 1.0);
    frag_uv       = vec2(uv.x,1.0-uv.y);//TODO check if this is required
    frag_position = position;
    frag_normal   = normal;
    geom_normal   = normal;
}
