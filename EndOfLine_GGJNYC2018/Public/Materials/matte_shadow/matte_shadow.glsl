//-----------------------------------------------------------------------
// Copyright (c) 2017 Snap Inc.
//-----------------------------------------------------------------------

#define SC_USE_USER_DEFINED_VS_MAIN

#include <std.glsl>
#include <std_vs.glsl>
#include <std_fs.glsl>

uniform float shadowDensity;

#ifdef VERTEX_SHADER

void main(void) {
    sc_Vertex_t v = sc_LoadVertexAttributes();
    sc_ProcessVertex(v);
}

#endif // #ifdef VERTEX_SHADER

#ifdef FRAGMENT_SHADER

void main(void) {
#ifdef sc_ProjectiveShadowsReceiver
    float s = mix(1.0, getShadowSample(), shadowDensity);
#else
    float s = shadowDensity;
#endif
    
    gl_FragColor = vec4(s, s, s, 1.0);
}

#endif //FRAGMENT SHADER
