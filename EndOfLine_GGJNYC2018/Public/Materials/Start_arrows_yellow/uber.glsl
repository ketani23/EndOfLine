//-----------------------------------------------------------------------
// Copyright (c) 2017 Snap Inc.
//-----------------------------------------------------------------------

#define STD_ENABLE_VERTEX_COLOR // TODO: remove this hack once bitmoji shader can be transitioned to use the vertex color defined in std_vs.glsl.
#define SC_USE_USER_DEFINED_VS_MAIN

#include <std.glsl>
#include <std_vs.glsl>
#include <std_fs.glsl>
#include "includes/utils.glsl"
#include "includes/blend_modes.glsl"
#include "includes/fizzle.glsl"

//-----------------------------------------------------------------------
// Feature defines - add these to the "Defines" field of Studio material to enable features you need. Ex: ENABLE_LIGHTING, ENABLE_SPECULAR_LIGHTING, ENABLE_NORMALMAP will give you a normal mapped PBR material.
//-----------------------------------------------------------------------
//#define ENABLE_UV2					// Enables a UV trasform that can take an existing UV set and scale and translate it, for example to tile a detail map over an existing UV set.
//#define ENABLE_UV2_ANIMATION			// This enables UV scrolling. The speed of the scroll will be uv2Offset units per second.
//#define ENABLE_UV3					// Enables a UV trasform that can take an existing UV set and scale and translate it, for example to tile a detail map over an existing UV set.
//#define ENABLE_UV3_ANIMATION			// This enables UV scrolling. The speed of the scroll will be uv2Offset units per second.
//#define ENABLE_BASE_TEX               // Most materials use a base texture, but disabling it means the base texture will be considered white.
//#define ENABLE_VERTEX_COLOR_BASE		// Multiplies the base color by vertex color rgba.
//#define ENABLE_OPACITY_TEX            // Normally, the baseTex texture's alpha is taken as opacity. Enabling this allows you to define a separate greyscale opacity texture. The opacityTex value will be bultiplied with the baseTex texture's alpha (which is 1 for textures without alpha) to get the final opacity.
//#define ENABLE_NORMALMAP              // Enables the normal map texture and normal mapping.
//#define ENABLE_EMISSIVE               // Enables the emissive texture.
//#define ENABLE_VERTEX_COLOR_EMISSIVE  // Enables emissive color from vertex color rgb, and adds it on top of any other emissive source.
//#define ENABLE_LIGHTING               // Enables direct and indirect (ambient) lighting. Disabling this creates an unlit (flat) shader.
//#define ENABLE_DIFFUSE_LIGHTING       // Enables direct and indirect diffuse lighting. Can be disabled as an optimization on pure metals.
//#define ENABLE_SPECULAR_LIGHTING      // Enables direct and indirect specular lighting (specular highlights and reflections). Disabling this creates a shader that's only lit diffusely.
//#define ENABLE_DIRECT_LIGHTS          // Enables direct analytical lights (directional lights, point lights, etc.). Disabling this means objects will only be lit by the environment map (indirect light), and rendering will be faster.
//#define ENABLE_VERTEX_COLOR_AO		// Multiplies AO by vertex color rgb.
//#define ENABLE_ENVMAP                 // Use an environment map for indirect diffuse and indirect specular lighting. Disabling this will use the ambient light instead as set in Studio.
//#define ENABLE_ENVMAP_FROM_CAMERA     // Use the live camera feed as the source of the environment map. This replaces the usual user specified environment map.
//#define ENABLE_ENVMAP_FROM_CAMERA_ROUGHNESS     // Enable blurring of camera envmap based on roughness.
//#define ENABLE_SPECULAR_AO            // Allow AO to influence indirect specular lighting (reflections).
//#define ENABLE_SIMPLE_REFLECTION      // Replaces the default PBR environment mapping with a simple lookup from a regular texture (no hdr, no roughness, no fresnel, etc.). The reflection lookup technically assumes a spherical environment map, which is a circular shaped texture as obtained by photographing a mirror ball. However, as a hack, it is sometimes used with simple, flat photos, and manually bent mesh normals. This is an example of a mirror ball env map http://www.orbolt.com/media/blog_files/LightProbe.jpg . Note: this spherical mapping is technically different from the "angular" envmap format that looks similar (represented here: http://www.pauldebevec.com/Probes/ ).
//#define ENABLE_RIM_HIGHLIGHT          // "Rim highlight", aka. "fake Fresnel effect".
//#define ENABLE_RIM_COLOR_TEX          // Allows the use of a texture (rimColorTex) to modulate the rim highlight color.
//#define ENABLE_TRANSLUCENCY_THIN      // [not implemented] Translucency through thin objects like leaves, flags, etc. Light penetrates to back side, because even if the substance might be quite opaque, the distance light has to travel is short.
//#define ENABLE_TRANSLUCENCY_BROAD     // [not implemented] Broad translucency as seen in highly translucent materials with thick volume, like grapes or jade. Light penetrates to back side, because even though it has to travel far, the substance is not very opaque.
//#define ENABLE_TRANSLUCENCY_SHORT     // [not implemented] Short range diffusion on the front sides of highly opaque materials, like facial skin or marble. Light does not penetrate to back side, because the opaque substance extinguishes it quickly, and the object is thick.
//#define ENABLE_TONE_MAPPING           // Normally all lit and unlit materials are rendered with HDR tone mapping enabled, so that they fit into the 3D scene correctly. However, for some uses, like UI elements or unlit materials withh multiplicative blending, you might want to turn tone mapping off.
//#define ENABLE_FIZZLE                 // Allows the material to fizzle in or out of existence according to a noise function, driven by the "transition" parameter (0 is fully visible and 1 is fully invisible).
//#define RENDER_CONSTANT_COLOR         // Ignores all other shader operations and just renders a solid color (baseColor). This is the cheapest possible shader, useful for occluders and such.

//-----------------------------------------------------------------------
// Global defines
//-----------------------------------------------------------------------
//#define DEBUG
#define SCENARIUM

#ifdef GL_ES
#define MOBILE
#endif

#if SC_DEVICE_CLASS >= SC_DEVICE_CLASS_C && (!defined(MOBILE) || defined(GL_FRAGMENT_PRECISION_HIGH))
#define DEVICE_IS_FAST
#endif

#ifdef DEVICE_IS_FAST
#define DEFAULT_MIP_BIAS 0.0
#else
#define DEFAULT_MIP_BIAS 1.0
#endif

#if defined(ENABLE_UV3)
#define NUM_UVS 4
#elif defined(ENABLE_UV2)
#define NUM_UVS 3
#else
#define NUM_UVS 2
#endif

#ifndef baseTexUV
#define baseTexUV 0
#endif


//-----------------------------------------------------------------------
// Uniforms
//-----------------------------------------------------------------------
uniform sampler2D baseTex;
uniform sampler2D opacityTex;
uniform sampler2D normalTex;
uniform sampler2D materialParamsTex;
uniform sampler2D emissiveTex;
uniform sampler2D rimColorTex;

uniform sampler2D diffuseEnvmapTex;
uniform sampler2D specularEnvmapTex;
uniform sampler2D reflectionTex;

uniform mat3 baseTexTransform;

uniform vec2 uv2Scale;
uniform vec2 uv2Offset;
uniform vec2 uv3Scale;
uniform vec2 uv3Offset;

uniform vec4 baseColor;
uniform float alphaTestThreshold;
uniform vec3 emissiveColor;
uniform float emissiveIntensity;
uniform float reflectionIntensity;
uniform vec3 rimColor;
uniform float rimIntensity;
uniform float rimExponent;
uniform float envmapExposure;
uniform float envmapRotation;
uniform float specularAoIntensity;
uniform float specularAoDarkening;
uniform float reflBlurWidth;
uniform float reflBlurMinRough;
uniform float reflBlurMaxRough;

#ifdef DEBUG
uniform int DebugAlbedo;
uniform int DebugSpecColor;
uniform int DebugRoughness;
uniform int DebugNormal;
uniform int DebugAo;
uniform float DebugDirectDiffuse;
uniform float DebugDirectSpecular;
uniform float DebugIndirectDiffuse;
uniform float DebugIndirectSpecular;
uniform float DebugRoughnessOffset;
uniform float DebugRoughnessScale;
uniform float DebugNormalIntensity;
uniform int DebugEnvBRDFApprox;
uniform int DebugEnvBentNormal;
uniform float DebugEnvMip;
uniform int DebugFringelessMetallic;
uniform int DebugAcesToneMapping;
uniform int DebugLinearToneMapping;
#endif  // #ifdef DEBUG

//-----------------------------------------------------------------------
#ifdef VERTEX_SHADER
//-----------------------------------------------------------------------
void main(void) {
    sc_Vertex_t v = sc_LoadVertexAttributes();
    v.texture0 = vec2(baseTexTransform * vec3(v.texture0, 1.0));
    sc_ProcessVertex(v);
}
#endif // #ifdef VERTEX_SHADER

//-----------------------------------------------------------------------
#ifdef FRAGMENT_SHADER
//-----------------------------------------------------------------------
#include "includes/envmap.glsl"

#ifdef ENABLE_STIPPLE_PATTERN_TEST
bool stipplePatternTest(highp float alpha) {
    vec2 localCoord = floor(mod(gl_FragCoord.xy, vec2(4.0)));
    float threshold = (mod(dot(localCoord, vec2(4.0, 1.0)) * 9.0, 16.0) + 1.0) / 17.0;

    return alpha >= threshold;
}
#endif // ENABLE_STIPPLE_PATTERN_TEST

vec2 uniTopMipRes = vec2(512.0, 256.0);

vec4 emulateTexture2DLod(sampler2D sampler, vec2 uv, float lod) {
#if (__VERSION__ == 120)
    return texture2DLod(sampler, uv, lod);
#elif defined(GL_EXT_shader_texture_lod)
    return texture2DLodEXT(sampler, uv, lod);
#elif defined(GL_OES_standard_derivatives)
    vec2 texels = uv * uniTopMipRes;
    float dudx = dFdx(texels.x);
    float dvdx = dFdx(texels.y);
    float dudy = dFdy(texels.x);
    float dvdy = dFdy(texels.y);
    float rho = max(length(vec2(dudx, dvdx)), length(vec2(dudy, dvdy))); // OpenGL reference calculation
    float mu = max(abs(dudx), abs(dudy));
    float mv = max(abs(dvdx), abs(dvdy));
    float rho2 = max(mu, mv); // The allowed alternative OpoenGL reference calculation that seems to match the main reference best.
    float mip = log2(rho2);
    float bias = lod - mip;
    return texture2D(sampler, uv, bias);
#else
    return texture2D(sampler, uv, -13.0);  // Note: can't sample an lod in old GLSL - you're on your own.
#endif
}

vec4 sampleEnvTextureLod(vec2 uv, float lod) {
#if (__VERSION__ == 120) || defined(GL_EXT_shader_texture_lod) || defined(GL_OES_standard_derivatives)
    return emulateTexture2DLod(specularEnvmapTex, uv, lod);
#else
    vec4 radiance0 = texture2D(specularEnvmapTex, uv, -13.0);
    vec4 radiance1 = texture2D(diffuseEnvmapTex, uv, -13.0);
    return mix(radiance0, radiance1, lod / 5.0);
#endif
}

vec3 sampleScreenTexture(vec2 uv, float lod)
{
#if defined(ENABLE_ENVMAP_FROM_CAMERA_ROUGHNESS) && defined(DEVICE_IS_FAST)
    const float maxRoughnessMipInv = 1.0/5.0;
    float r = lod * maxRoughnessMipInv;
    float reflectionRoughness = saturate((r - reflBlurMinRough) / (reflBlurMaxRough-reflBlurMinRough));
    vec2 pixelSize = vec2(1.0/720.0, 1.0/1280.0);
    vec3 blurred = vec3(0.0);
    const int NUM_SAMPLES = 5;
    vec2 offset = pixelSize * reflBlurWidth / float(NUM_SAMPLES) * reflectionRoughness;
    vec2 rnd = fract(uv * 1331711.0) - 0.5;
    //    uv += offset * rnd;
    uv -= offset * float(NUM_SAMPLES-1) * 0.5;
    for (int i = 0; i < NUM_SAMPLES; ++i) {
        for (int j = 0; j < NUM_SAMPLES; ++j) {
            blurred += texture2D(sc_ScreenTexture, uv + offset * vec2(i, j)).rgb;
        }
    }
    blurred *= 1.0 / float(NUM_SAMPLES * NUM_SAMPLES);
    return blurred;
#else // #if defined(ENABLE_ENVMAP_FROM_CAMERA_ROUGHNESS) && defined(DEVICE_IS_FAST)
    return texture2D(sc_ScreenTexture, uv).rgb;
#endif //#else // #if defined(ENABLE_ENVMAP_FROM_CAMERA_ROUGHNESS) && defined(DEVICE_IS_FAST)
}

vec3 sampleSpecularEnvmapLod(vec3 R, float lod) {
#ifdef ENABLE_ENVMAP_FROM_CAMERA
    
    R = (sc_ViewMatrix * vec4(R, 0.0)).xyz;
    vec2 uv = calculateEnvmapScreenToCube(R);
    return srgbToLinear(sampleScreenTexture(uv, lod));
    
#else // #ifdef ENABLE_ENVMAP_FROM_CAMERA
    
    vec2 uv = calcPanoramicTexCoordsFromDir(R, envmapRotation);
    
#if defined(DEVICE_IS_FAST)
    float lodFloor = floor(lod);
    float lodCeil = ceil(lod);
    float lodFrac = lod - lodFloor;
    
    vec2 uvFloor = calcSeamlessPanoramicUvsForSampling(uv, uniTopMipRes, lodFloor);
    vec4 texFloor = sampleEnvTextureLod(uvFloor, lodFloor);
    
    vec2 uvCeil = calcSeamlessPanoramicUvsForSampling(uv, uniTopMipRes, lodCeil);
    vec4 texCeil = sampleEnvTextureLod(uvCeil, lodCeil);
    
    vec4 tex = mix(texFloor, texCeil, lodFrac);
#else // ##if defined(DEVICE_IS_FAST)
    vec4 tex = sampleEnvTextureLod(uv, lod);
#endif // #else // ##if defined(DEVICE_IS_FAST)
    
    return decodeRGBD(tex) * envmapExposure;
    
#endif // #else // #ifdef ENABLE_ENVMAP_FROM_CAMERA
}

vec2 uniDiffuseEnvmapRes = vec2(64.0, 32.0); // Must match the actual size of the texture.

vec3 calculateDiffuseIrradiance(vec3 N) {
    vec2 uv = calcPanoramicTexCoordsFromDir(N, envmapRotation);
    uv = calcSeamlessPanoramicUvsForSampling(uv, uniDiffuseEnvmapRes, 0.0);
    vec4 tex = emulateTexture2DLod(diffuseEnvmapTex, uv, 0.0);  // Must load the top mip, otherwise there will be a seam where the u coordinate wraps around from 1 to 0 in the panoramic mapping, because the derivatives get screwed up.
    return decodeRGBD(tex) * envmapExposure;
}

vec3 sampleRadiance(vec3 R) {
    return sampleSpecularEnvmapLod(R, 0.0);
}

#include "includes/pbr.glsl"  // Requires sampleSpecularEnvmapLod and calculateDiffuseIrradiance to be defined by the client shader (above).

// This function evaluates all lighting for a surface based on its surface properties and all the existing lighting in the environment (multiple lights, ambient, reflections, etc).
LightingComponents evaluateLighting(SurfaceProperties surfaceProperties, DebugOptions debug) {
    LightingComponents lighting = defaultLightingComponents();

    vec3 N = surfaceProperties.normal;
    vec3 V = normalize(sc_Camera.position - varPos);
    
#ifdef ENABLE_LIGHTING
    
#ifdef ENABLE_DIRECT_LIGHTS
#ifdef sc_DirectionalLightsCount
    // Directional lights
    for(int i = 0; i < sc_DirectionalLightsCount; ++i) {
        sc_DirectionalLight_t light = sc_DirectionalLights[i];
        LightProperties lightProperties;
        lightProperties.direction = light.direction;
        lightProperties.color = light.color.rgb;
        lightProperties.attenuation = light.color.a;
        lighting = accumulateLight(lighting, lightProperties, surfaceProperties, V);
        
#ifdef sc_ProjectiveShadowsReceiver
        lighting.directDiffuse *= getShadowSample();
#endif // sc_ProjectiveShadowsReceiver
    }
#endif // #ifdef sc_DirectionalLightsCount
    
#ifdef sc_PointLightsCount
    // Pint lights
    for(int i = 0; i < sc_PointLightsCount; ++i) {
        sc_PointLight_t light = sc_PointLights[i];
        LightProperties lightProperties;
        lightProperties.direction = normalize(light.position - varPos);
        lightProperties.color = light.color.rgb;
        lightProperties.attenuation = light.color.a;
        lighting = accumulateLight(lighting, lightProperties, surfaceProperties, V);
        
#ifdef sc_ProjectiveShadowsReceiver
        lighting.directDiffuse *= getShadowSample();
#endif // sc_ProjectiveShadowsReceiver
    }
#endif // #ifdef sc_PointLightsCount
    
#ifndef ENABLE_SPECULAR_LIGHTING
    lighting.directSpecular = vec3(0.0);
#endif // #ifndef ENABLE_SPECULAR_LIGHTING
    
#endif // #ifdef ENABLE_DIRECT_LIGHTS
    
    // Indirect diffuse
#ifdef ENABLE_ENVMAP
    lighting.indirectDiffuse = calculateIndirectDiffuse(surfaceProperties);
#else
    lighting.indirectDiffuse = sc_AmbientLight.color;
#endif
    
#ifndef ENABLE_DIFFUSE_LIGHTING
    lighting.directDiffuse = vec3(0.0);
    lighting.indirectDiffuse = vec3(0.0);
#endif
    
#if defined(ENABLE_ENVMAP) && defined(ENABLE_SPECULAR_LIGHTING) && !defined(ENABLE_SIMPLE_REFLECTION)
    // Indirect specular
    lighting.indirectSpecular = calculateIndirectSpecular(surfaceProperties, V, debug);
#endif
    
    // Translucency
#ifdef ENABLE_TRANSLUCENCY_BROAD
#endif
    
#endif // #ifdef ENABLE_LIGHTING
    
#ifdef DEBUG
    // Debug sliders
    lighting.directDiffuse *= debug.directDiffuse;
    lighting.directSpecular *= debug.directSpecular;
    lighting.indirectDiffuse *= debug.indirectDiffuse;
    lighting.indirectSpecular *= debug.indirectSpecular;
#endif
    
    return lighting;
}

vec3 fragNormal(vec2 uvs[NUM_UVS]) {
#ifdef ENABLE_NORMALMAP
    vec3 N = normalize(varNormal); // FIXME avoid normalizing
    vec3 T = normalize(varTangent);
    vec3 B = normalize(cross(N, T) * varBitangentSign);
    mat3 TBN = mat3(T, B, N);
    vec3 nm = (texture2D(normalTex, uvs[normalTexUV], DEFAULT_MIP_BIAS).xyz - 0.5/255.0) * 2.0 - 1.0; // Offset by 0.5/255 to make sure that a pixel value of 128 actually maps to 0. The midpoint of 255 is 127.5, so we need to map 128 to 127.5 in this way.
#ifdef DEBUG
    nm.xy *= vec2(DebugNormalIntensity);
#endif
    return normalize(TBN * normalize(nm));
#else // #ifdef ENABLE_NORMALMAP
    return normalize(varNormal);
#endif // #else // #ifdef ENABLE_NORMALMAP
}

void calculateUVs(out vec2 uvs[NUM_UVS]) {
	uvs[0] = varTex0;
	uvs[1] = varTex1;

#ifdef ENABLE_UV2
	vec2 uv2OffsetLocal = uv2Offset;
#ifdef ENABLE_UV2_ANIMATION
	uv2OffsetLocal *= sc_TimeElapsed;
#endif
	uvs[2] = uvs[uv2] * uv2Scale + uv2OffsetLocal;
#endif

#ifdef ENABLE_UV3
	vec2 uv3OffsetLocal = uv3Offset;
#ifdef ENABLE_UV3_ANIMATION
	uv3OffsetLocal *= sc_TimeElapsed;
#endif
	uvs[3] = uvs[uv3] * uv3Scale + uv3OffsetLocal;
#endif
}

DebugOptions setupDebugOptions() {
    DebugOptions debug = defaultDebugOptions();
    
#ifdef DEBUG
    debug.envMip = DebugEnvMip;
    debug.envBRDFApprox = bool(DebugEnvBRDFApprox);
    debug.envBentNormal = bool(DebugEnvBentNormal);
    debug.fringelessMetallic = bool(DebugFringelessMetallic);
    debug.acesToneMapping = bool(DebugAcesToneMapping);
    debug.linearToneMapping = bool(DebugLinearToneMapping);
    debug.albedo = bool(DebugAlbedo);
    debug.specColor = bool(DebugSpecColor);
    debug.roughness = bool(DebugRoughness);
    debug.normal = bool(DebugNormal);
    debug.ao = bool(DebugAo);
    debug.directDiffuse = DebugDirectDiffuse;
    debug.directSpecular = DebugDirectSpecular;
    debug.indirectDiffuse = DebugIndirectDiffuse;
    debug.indirectSpecular = DebugIndirectSpecular;
#endif  // #ifdef DEBUG
    
    return debug;
}


void main(void) {
    
#ifdef RENDER_CONSTANT_COLOR
    gl_FragColor = baseColor;
#elif defined(sc_ProjectiveShadowsCaster)
    gl_FragColor = getShadowColor(1.0);
#else
    
    DebugOptions debug = setupDebugOptions();
    
    vec2 uvs[NUM_UVS];
    calculateUVs(uvs);
    
    vec3 V = normalize(sc_Camera.position - varPos);
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Set up surface properties
    
    SurfaceProperties surfaceProperties = defaultSurfaceProperties();
    
    // Albedo
    vec4 albedo = baseColor;
#ifdef ENABLE_BASE_TEX
    albedo *= texture2D(baseTex, uvs[baseTexUV], DEFAULT_MIP_BIAS);
#endif
#ifdef ENABLE_VERTEX_COLOR_BASE
    albedo *= varColor;
#endif
    surfaceProperties.albedo = srgbToLinear(albedo.rgb);
    
    // Opacity
    surfaceProperties.opacity = albedo.a;
#if defined(ENABLE_OPACITY_TEX) && !defined(sc_BlendMode_Disabled)
    surfaceProperties.opacity *= texture2D(opacityTex, uvs[opacityTexUV], DEFAULT_MIP_BIAS).r;
#endif
#ifdef sc_BlendMode_Disabled
    surfaceProperties.opacity = 1.0; // Only necessary because on some hardware when alpha==0.0 we get a pure black result.
#endif
    
    // Alpha Test
#ifdef sc_BlendMode_AlphaTest
    if (surfaceProperties.opacity < alphaTestThreshold) {
        discard;
    }
#endif // #ifdef sc_BlendMode_AlphaTest
#ifdef ENABLE_STIPPLE_PATTERN_TEST
    if (stipplePatternTest(surfaceProperties.opacity) == false) {
        discard;
    }
#endif // ENABLE_STIPPLE_PATTERN_TEST

    // Normal
    surfaceProperties.normal = fragNormal(uvs);

    // Emissive
#ifdef ENABLE_EMISSIVE
    surfaceProperties.emissive += texture2D(emissiveTex, uvs[emissiveTexUV], DEFAULT_MIP_BIAS).rgb;
#endif
#ifdef ENABLE_VERTEX_COLOR_EMISSIVE
    surfaceProperties.emissive += varColor.rgb;
#endif
#if defined(ENABLE_EMISSIVE) || defined(ENABLE_VERTEX_COLOR_EMISSIVE)
    surfaceProperties.emissive *= emissiveColor * emissiveIntensity;
    surfaceProperties.emissive = srgbToLinear(surfaceProperties.emissive);
#endif
    
    // Rim highlight (fake Fresnel)
#ifdef ENABLE_RIM_HIGHLIGHT
    vec3 rimCol = rimColor * rimIntensity;
#ifdef ENABLE_RIM_COLOR_TEX
    rimCol *= texture2D(rimColorTex, uvs[rimColorTexUV], DEFAULT_MIP_BIAS).rgb;
#endif // #ifdef ENABLE_RIM_COLOR_TEX
    surfaceProperties.emissive += pow(1.0 - abs(dot(surfaceProperties.normal, V)), rimExponent) * srgbToLinear(rimCol);
#endif // #ifdef ENABLE_RIM_HIGHLIGHT

    // Simple reflection
#ifdef ENABLE_SIMPLE_REFLECTION
    vec3 R = reflect(V, surfaceProperties.normal);
    R.z = -R.z;
    vec2 uv = vec2(1.0) - calcSphericalTexCoordsFromDir(R);
    surfaceProperties.emissive += srgbToLinear(texture2D(reflectionTex, uv).rgb) * reflectionIntensity;
#endif
    
    // Lighting related surface properties
#ifdef ENABLE_LIGHTING
#ifdef ENABLE_SPECULAR_LIGHTING
    vec3 materialParams = texture2D(materialParamsTex, uvs[materialParamsTexUV], DEFAULT_MIP_BIAS).rgb; // R - metalness, G - roughness, B - ambient occlusion
#else
    vec3 materialParams = vec3(0.0, 0.0, 1.0);
#endif
    
    // Metallic
    surfaceProperties.metallic = materialParams.r;
    
    // Roughness
    surfaceProperties.roughness = materialParams.g;
#ifdef DEBUG
    surfaceProperties.roughness += DebugRoughnessOffset;
    surfaceProperties.roughness *= DebugRoughnessScale;
#endif

    // AO
    surfaceProperties.ao = vec3(materialParams.b);
#ifdef ENABLE_VERTEX_COLOR_AO
    surfaceProperties.ao *= varColor.rgb;
#endif
#ifdef ENABLE_SPECULAR_AO
    vec3 dummyAlbedo;
    vec3 dummySpecColor;
    deriveAlbedoAndSpecColorFromSurfaceProperties(surfaceProperties, dummyAlbedo, dummySpecColor, debug); // Kind of hacky, but necessary to keep separation between material setup and lighting. Gets optimized away in practice, since calculateDerivedSurfaceProperties() does the same calculation below.
    vec3 specularAoColor = mix(dummySpecColor * dummySpecColor * (1.0 - specularAoDarkening), vec3(1.0), surfaceProperties.ao); // When specularAoDarkening is 0, we just saturate towards the specular color, rather than blending to black, which is a more natural representation of interreflections.
    surfaceProperties.specularAo = mix(vec3(1.0), specularAoColor, specularAoIntensity);
#endif
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Evaluate lighting
    
    surfaceProperties = calculateDerivedSurfaceProperties(surfaceProperties, debug);
    
    LightingComponents lighting = evaluateLighting(surfaceProperties, debug);
#else // #ifdef ENABLE_LIGHTING
    LightingComponents lighting = defaultLightingComponents();
#endif // #else // #ifdef ENABLE_LIGHTING
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Output
    
#ifdef sc_BlendMode_ColoredGlass
    // Colored glass implies that the surface does not diffusely reflect light, instead it transmits light.
    // The transmitted light is the background multiplied by the color of the glass, taking opacity as strength.
    lighting.directDiffuse = vec3(0.0);
    lighting.indirectDiffuse = vec3(0.0);
    vec3 framebuffer = srgbToLinear(getFramebufferColor().rgb);
    lighting.transmitted = framebuffer * mix(vec3(1.0), surfaceProperties.albedo, surfaceProperties.opacity);
    
    // Since colored glass does its own multiplicative blending (above), forbid any other blending.
    surfaceProperties.opacity = 1.0;
#endif
    
#if defined(sc_BlendMode_PremultipliedAlpha)
    const bool enablePremultipliedAlpha = true;
#else
    const bool enablePremultipliedAlpha = false;
#endif
    
    // This is where the lighting and the surface finally come together.
    vec4 result = vec4(combineSurfacePropertiesWithLighting(surfaceProperties, lighting, enablePremultipliedAlpha), surfaceProperties.opacity);
    
    // Tone mapping
#if defined(ENABLE_TONE_MAPPING) && !defined(sc_BlendMode_Multiply)
#ifdef DEBUG
    if (debug.acesToneMapping)
        result.rgb = acesToneMapping(result.rgb);
    else if (debug.linearToneMapping)
#endif // #ifdef DEBUG
        result.rgb = linearToneMapping(result.rgb);
#endif // #ifndef DISABLE_TONE_MAPPING
    
    // sRGB output
    result.rgb = linearToSrgb(result.rgb);
    
    // Debug
#ifdef DEBUG
    result = debugOutput(result, surfaceProperties, lighting, debug);
#endif

    // Blending
#ifdef sc_BlendMode_Custom
    result = applyCustomBlend(result);
#endif
    
#ifdef ENABLE_FIZZLE
    result = fizzle(result);
#endif
    
    gl_FragColor = result;
    
#endif // #ifdef RENDER_CONSTANT_COLOR
}
#endif // #ifdef FRAGMENT_SHADER


