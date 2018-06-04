#include <std.glsl>
#include <std_vs.glsl>
#include <std_fs.glsl>

uniform vec4        mainColor;

uniform float       uvScale;

uniform sampler2D mainTexture;
uniform sampler2D maskTexture;

#ifdef VERTEX_SHADER

void sc_VSMain(inout sc_Vertex_t v) {
    v.texture1 = v.texture0;
    float scale = uvScale / 100.0;
    vec3 worldPos = (sc_ModelMatrix * v.position).xyz;
    v.texture0 = vec2(-1.0*scale, 1.0*scale)*worldPos.xz;
}

#endif


#ifdef FRAGMENT_SHADER

void main(void) {
    vec4 albedo = texture2D(mainTexture, varTex0) * mainColor;
    float mask = texture2D(maskTexture, varTex1).r;
    mask = mask*mask;
    mask = mask*mask;
    mask = mask*mask;
    gl_FragColor = vec4(albedo.rgb*vec3(mask), albedo.a*mask);
}

#endif //FRAGMENT SHADER
