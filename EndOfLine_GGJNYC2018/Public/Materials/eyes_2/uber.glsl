//-----------------------------------------------------------------------
// Copyright (c) 2017 Snap Inc.
//-----------------------------------------------------------------------

#define STD_ENABLE_VERTEX_COLOR // TODO: remove this hack once bitmoji shader can be transitioned to use the vertex color defined in std_vs.glsl.
#define SC_USE_USER_DEFINED_VS_MAIN

#include <std.glsl>
#include <std_vs.glsl>
#include <std_fs.glsl>
//-----------------------------------------------------------------------
// Copyright (c) 2017 Snap Inc.
//-----------------------------------------------------------------------

#ifndef UTILS_GLSL
#define UTILS_GLSL

#ifndef PI
#define PI 3.141592653589793238462643383279
#endif

#ifndef MAYA
float saturate(float value) {
    return clamp(value, 0.0, 1.0);
}

vec3 saturate(vec3 value) {
    return clamp(value, 0.0, 1.0);
}
#endif

float dot_sat(vec3 a, vec3 b) {
    return saturate(dot(a, b)); // dp3_sat
}

#if defined(MAYA) || defined(SUBSTANCE)
float srgbToLinear(float x) {
    return x <= 0.04045 ? x * 0.0773993808 : pow((x + 0.055) / 1.055, 2.4);
}

float linearToSrgb(float x) {
    return x <= 0.0031308 ? 12.92 * x : 1.055 * pow(x, 0.41666) - 0.055;
}
#else
float srgbToLinear(float x) {
    return pow(x, 2.2);
}

float linearToSrgb(float x) {
    return pow(x, 1.0 / 2.2);
}
#endif

vec3 srgbToLinear(vec3 color) {
    return vec3(srgbToLinear(color.r), srgbToLinear(color.g), srgbToLinear(color.b));
}

vec3 linearToSrgb(vec3 color) {
    return vec3(linearToSrgb(color.r), linearToSrgb(color.g), linearToSrgb(color.b));
}

#endif // UTILS_GLSL
//-----------------------------------------------------------------------
// Copyright (c) 2017 Snap Inc.
//-----------------------------------------------------------------------


#ifndef BLEND_MODES_GLSL
#define BLEND_MODES_GLSL

#ifdef FRAGMENT_SHADER
#ifdef sc_BlendMode_Custom

#include <std_fs.glsl>
//-----------------------------------------------------------------------
// Copyright (c) 2017 Snap Inc.
//-----------------------------------------------------------------------

#ifndef BLEND_MODES_EYECOLOR_GLSL
#define BLEND_MODES_EYECOLOR_GLSL


#ifdef BLEND_MODE_REALISTIC
#define COLOR_MODE 0
#endif

#ifdef BLEND_MODE_DIVISION
#define COLOR_MODE 1
#endif

#ifdef BLEND_MODE_BRIGHT
#define COLOR_MODE 2
#endif

#ifdef BLEND_MODE_FORGRAY
#define COLOR_MODE 3
#endif

#ifdef BLEND_MODE_NOTBRIGHT
#define COLOR_MODE 4
#endif

#ifdef BLEND_MODE_INTENSE
#define COLOR_MODE 5
#endif



#ifdef COLOR_MODE

uniform float     correctedIntensity;
uniform sampler2D intensityTexture;


#if COLOR_MODE == 0 || COLOR_MODE == 3 || COLOR_MODE == 4

float transformSingleColor(float original, float intMap, float target) {
    return original / pow((1.0 - target), intMap);
}

#endif
#if COLOR_MODE == 1

float transformSingleColor(float original, float intMap, float target) {
    return original / (1.0 - target);
}

#endif
#if COLOR_MODE == 2

float transformSingleColor(float original, float intMap, float target) {
    return original / pow((1.0 - target), 2.0 - 2.0 * original);
}

#endif

#if COLOR_MODE != 5

vec3 transformColor(float yValue, vec3 original, vec3 target, float weight, float intMap) {
    vec3 tmpColor;
    tmpColor.r = transformSingleColor(yValue, intMap, target.r);
    tmpColor.g = transformSingleColor(yValue, intMap, target.g);
    tmpColor.b = transformSingleColor(yValue, intMap, target.b);
    tmpColor = clamp(tmpColor, 0.0, 1.0);
    vec3 resColor = mix(original, tmpColor, weight);
    return resColor;
}

#endif

#if COLOR_MODE == 5

#ifndef RGBHSL_GLSL
#define RGBHSL_GLSL

vec3 RGBtoHCV(vec3 rgb)
{
    vec4 p = (rgb.g < rgb.b) ? vec4(rgb.bg, -1.0, 2.0/3.0) : vec4(rgb.gb, 0.0, -1.0/3.0);
    vec4 q = (rgb.r < p.x) ? vec4(p.xyw, rgb.r) : vec4(rgb.r, p.yzx);
    
    float c = q.x - min(q.w, q.y);
    float h = abs((q.w - q.y) / (6.0*c + 1e-7) + q.z);
    float v = q.x;
    
    return vec3(h, c, v);
}

vec3 RGBToHSL(vec3 rgb)
{
    vec3 hcv = RGBtoHCV(rgb);
    
    float lum = hcv.z - hcv.y * 0.5;
    float sat = hcv.y / (1.0 - abs(2.0*lum - 1.0) + 1e-7);
    
    return vec3(hcv.x, sat, lum);
}

vec3 HUEtoRGB(float hue)
{
    float r = abs(6.0*hue - 3.0) - 1.0;
    float g = 2.0 - abs(6.0*hue - 2.0);
    float b = 2.0 - abs(6.0*hue - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0);
}

vec3 HSLToRGB(vec3 hsl)
{
    vec3 rgb = HUEtoRGB(hsl.x);
    float c = (1.0 - abs(2.0 * hsl.z - 1.0)) * hsl.y;
    rgb = (rgb - 0.5) * c + hsl.z;
    return rgb;
}

#endif //RGBHSL_GLSL

vec3 transformColor(float yValue, vec3 original, vec3 target, float weight, float intMap) {
    vec3 hslOrig = RGBToHSL(original);
    vec3 res;
    res.r = target.r; //hue
    res.g = target.g; //sat
    res.b = hslOrig.b; //light
    res = HSLToRGB(res);
    vec3 resColor = mix(original, res, weight);
    return resColor;
}

#endif

float unpack1(float inp, float mul) {
    return inp * mul;
}

float unpack2(vec2 inp, float mul) {
    return (inp[0] * 256.0 + inp[1]) / 257.0 * mul;
}

float unpack3(vec3 inp, float mul) {
    //    return (inp[0] * 256.0 * 256.0 * 255.0 + inp[1] * 256.0 * 255.0 + inp[2] * 255.0) / (256.0 * 256.0 * 256.0 - 1);
    //    256^3 - 1 == 255*(256 * 256 + 256 + 1)
    //    return (inp[0] * 256.0 * 256.0 + inp[1] * 256.0 + inp[2]) / (256.0 * 256.0 + 256.0 + 1);
    //    256.0^2 can be too big, let's divide num and denom by 256
    return (inp[0] * 256.0 + inp[1] + inp[2] / 256.0) / (256.0 + 1.0 + 1.0 / 256.0) * mul;
}

float getYValue(vec3 rgb) {
    return 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b;
}

vec3 eyeColorBlend(vec3 texColor, vec3 resColor)
{
    float newYValue = getYValue(texColor);

    float weight = 1.0;
    float fragmentCorrectedIntensity = pow(newYValue, 1.0 / correctedIntensity);
    vec3 intenseMapCompressed = texture2D(intensityTexture, vec2(fragmentCorrectedIntensity, 0.5)).rgb;
    float intenseMapValue = unpack3(intenseMapCompressed, 16.0);

#if COLOR_MODE == 3
    intenseMapValue = max(intenseMapValue, 1.0);
#endif
#if COLOR_MODE == 4
    intenseMapValue = min(intenseMapValue, 1.0);
#endif

    vec3 newColor = transformColor(newYValue, texColor, resColor, weight, intenseMapValue);
    return newColor;
}

#define definedBlend eyeColorBlend

#endif //COLOR_MODE

#endif //BLEND_MODES_EYECOLOR_GLSL
#ifndef RGBHSL_GLSL
#define RGBHSL_GLSL

vec3 RGBtoHCV(vec3 rgb)
{
    vec4 p = (rgb.g < rgb.b) ? vec4(rgb.bg, -1.0, 2.0/3.0) : vec4(rgb.gb, 0.0, -1.0/3.0);
    vec4 q = (rgb.r < p.x) ? vec4(p.xyw, rgb.r) : vec4(rgb.r, p.yzx);
    
    float c = q.x - min(q.w, q.y);
    float h = abs((q.w - q.y) / (6.0*c + 1e-7) + q.z);
    float v = q.x;
    
    return vec3(h, c, v);
}

vec3 RGBToHSL(vec3 rgb)
{
    vec3 hcv = RGBtoHCV(rgb);
    
    float lum = hcv.z - hcv.y * 0.5;
    float sat = hcv.y / (1.0 - abs(2.0*lum - 1.0) + 1e-7);
    
    return vec3(hcv.x, sat, lum);
}

vec3 HUEtoRGB(float hue)
{
    float r = abs(6.0*hue - 3.0) - 1.0;
    float g = 2.0 - abs(6.0*hue - 2.0);
    float b = 2.0 - abs(6.0*hue - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0);
}

vec3 HSLToRGB(vec3 hsl)
{
    vec3 rgb = HUEtoRGB(hsl.x);
    float c = (1.0 - abs(2.0 * hsl.z - 1.0)) * hsl.y;
    rgb = (rgb - 0.5) * c + hsl.z;
    return rgb;
}

#endif //RGBHSL_GLSL

/*
 ** Contrast, saturation, brightness
 ** Code of this function is from TGM's shader pack
 ** http://irrlicht.sourceforge.net/phpBB2/viewtopic.php?t=21057
 */

// For all settings: 1.0 = 100% 0.5=50% 1.5 = 150%
vec3 ContrastSaturationBrightness(vec3 color, float brt, float sat, float con)
{
    // Increase or decrease theese values to adjust r, g and b color channels seperately
    const float AvgLumR = 0.5;
    const float AvgLumG = 0.5;
    const float AvgLumB = 0.5;

    const vec3 LumCoeff = vec3(0.2125, 0.7154, 0.0721);

    vec3 AvgLumin = vec3(AvgLumR, AvgLumG, AvgLumB);
    vec3 brtColor = color * brt;
    vec3 intensity = vec3(dot(brtColor, LumCoeff));
    vec3 satColor = mix(intensity, brtColor, sat);
    vec3 conColor = mix(AvgLumin, satColor, con);
    return conColor;
}


/*
 ** Float blending modes
 ** Adapted from here: http://www.nathanm.com/photoshop-blending-math/
 ** But I modified the HardMix (wrong condition), Overlay, SoftLight, ColorDodge, ColorBurn, VividLight, PinLight (inverted layers) ones to have correct results
 */

float BlendAddf(float base, float blend) {
    return min(base + blend, 1.0);
}
float BlendSubtractf(float base, float blend) {
    return max(base + blend - 1.0, 0.0);
}
float BlendLinearDodgef(float base, float blend) {
    return min(base + blend, 1.0);
}
float BlendLinearBurnf(float base, float blend) {
    return max(base + blend - 1.0, 0.0);
}
float BlendLightenf(float base, float blend) {
    return max(blend, base);
}
float BlendDarkenf(float base, float blend) {
    return min(blend, base);
}
float BlendScreenf(float base, float blend) {
    return (1.0 - ((1.0 - (base)) * (1.0 - (blend))));
}
float BlendOverlayf(float base, float blend) {
    return (base < 0.5 ? (2.0 * (base) * (blend)) : (1.0 - 2.0 * (1.0 - (base)) * (1.0 - (blend))));
}
float BlendSoftLightf(float base, float blend) {
    return ((1.0 - 2.0 * (blend))*(base)*(base) + 2.0 * (base) * (blend));
}
float BlendColorDodgef(float base, float blend) {
    return ((blend == 1.0) ? blend : min((base) / (1.0 - (blend)), 1.0));
}
float BlendColorBurnf(float base, float blend) {
    return ((blend == 0.0) ? blend : max((1.0 - ((1.0 - (base)) / (blend))), 0.0));
}
float BlendLinearLightf(float base, float blend) {
    if(blend < 0.5) {
        return BlendLinearBurnf(base, 2.0 * blend);
    }
    else {
        return BlendLinearDodgef(base, 2.0 * (blend - 0.5));
    }
}
float BlendVividLightf(float base, float blend) {
    if(blend < 0.5) {
        return BlendColorBurnf(base, 2.0 * blend);
    }
    else {
        return BlendColorDodgef(base, 2.0 * (blend - 0.5));
    }
}
float BlendPinLightf(float base, float blend) {
    if(blend < 0.5) {
        return BlendDarkenf(base, 2.0 * blend);
    }
    else {
        return BlendLightenf(base, 2.0 * (blend - 0.5));
    }
}
float BlendHardMixf(float base, float blend) {
    if(BlendVividLightf(base, blend) < 0.5) {
        return 0.0;
    }
    else {
        return 1.0;
    }
}
float BlendReflectf(float base, float blend) {
    return ((blend == 1.0) ? blend : min((base) * (base) / (1.0 - (blend)), 1.0));
}

//#define BlendLinearDodgef 			    BlendAddf
//#define BlendLinearBurnf 			        BlendSubtractf
//#define BlendAddf(base, blend) 		    min(base + blend, 1.0)
//#define BlendSubtractf(base, blend) 	    max(base + blend - 1.0, 0.0)
//#define BlendLightenf(base, blend) 		max(blend, base)
//#define BlendDarkenf(base, blend) 		min(blend, base)
//#define BlendLinearLightf(base, blend) 	(blend < 0.5 ? BlendLinearBurnf(base, (2.0 * (blend))) : BlendLinearDodgef(base, (2.0 * ((blend) - 0.5))))
//#define BlendScreenf(base, blend) 		(1.0 - ((1.0 - (base)) * (1.0 - (blend))))
//#define BlendOverlayf(base, blend) 	    (base < 0.5 ? (2.0 * (base) * (blend)) : (1.0 - 2.0 * (1.0 - (base)) * (1.0 - (blend))))
//#define BlendSoftLightf(base, blend) 	    ((1.0 - 2.0 * (blend))*(base)*(base) + 2.0 * (base) * (blend))
//#define BlendColorDodgef(base, blend) 	((blend == 1.0) ? blend : min((base) / (1.0 - (blend)), 1.0))
//#define BlendColorBurnf(base, blend) 	    ((blend == 0.0) ? blend : max((1.0 - ((1.0 - (base)) / (blend))), 0.0))
//#define BlendVividLightf(base, blend) 	((blend < 0.5) ? BlendColorBurnf(base, (2.0 * (blend))) : BlendColorDodgef(base, (2.0 * ((blend) - 0.5))))
//#define BlendPinLightf(base, blend) 	    ((blend < 0.5) ? BlendDarkenf(base, (2.0 * (blend))) : BlendLightenf(base, (2.0 *((blend) - 0.5))))
//#define BlendHardMixf(base, blend) 	    ((BlendVividLightf(base, blend) < 0.5) ? 0.0 : 1.0)
//#define BlendReflectf(base, blend) 		((blend == 1.0) ? blend : min((base) * (base) / (1.0 - (blend)), 1.0))

/*
 ** Vector3 blending modes
 */

// Component wise blending

#define BlendNormal(base, blend) 		(blend)
#define BlendLighten(base, blend)		(vec3(BlendLightenf(base.r, blend.r),BlendLightenf(base.g, blend.g),BlendLightenf(base.b, blend.b)))
#define BlendDarken(base, blend)		(vec3(BlendDarkenf(base.r, blend.r),BlendDarkenf(base.g, blend.g),BlendDarkenf(base.b, blend.b)))
#define BlendMultiply(base, blend) 		((base) * (blend))
#define BlendDivide(base, blend) 		((blend) / (base))
#define BlendAverage(base, blend) 		((base + blend) / 2.0)
#define BlendAdd(base, blend) 		    min(base + blend, vec3(1.0))
#define BlendSubtract(base, blend) 	    max(base + blend - vec3(1.0), vec3(0.0))
#define BlendDifference(base, blend) 	abs(base - (blend))
#define BlendNegation(base, blend) 	    (vec3(1.0) - abs(vec3(1.0) - (base) - (blend)))
#define BlendExclusion(base, blend) 	(base + blend - 2.0 * (base) * (blend))
#define BlendScreen(base, blend) 		vec3(BlendScreenf(base.r, blend.r), BlendScreenf(base.g, blend.g), BlendScreenf(base.b, blend.b))

#define BlendOverlay(base, blend) 		vec3(BlendOverlayf(base.r, blend.r), BlendOverlayf(base.g, blend.g), BlendOverlayf(base.b, blend.b))
#define BlendSoftLight(base, blend) 	vec3(BlendSoftLightf(base.r, blend.r),BlendSoftLightf(base.g, blend.g),BlendSoftLightf(base.b, blend.b))
#define BlendHardLight(base, blend) 	BlendOverlay(blend, base)
#define BlendColorDodge(base, blend) 	vec3(BlendColorDodgef(base.r, blend.r), BlendColorDodgef(base.g, blend.g), BlendColorDodgef(base.b, blend.b))
#define BlendColorBurn(base, blend) 	vec3(BlendColorBurnf(base.r, blend.r), BlendColorBurnf(base.g, blend.g), BlendColorBurnf(base.b, blend.b))
#define BlendLinearDodge(base, blend)	BlendAdd(base, blend)
#define BlendLinearBurn(base, blend)	BlendSubtract(base, blend)
// Linear Light is another contrast-increasing mode
// If the blend color is darker than midgray, Linear Light darkens the image by decreasing the brightness. If the blend color is lighter than midgray, the result is a brighter image due to increased brightness.
#define BlendLinearLight(base, blend) 	vec3(BlendLinearLightf(base.r, blend.r), BlendLinearLightf(base.g, blend.g), BlendLinearLightf(base.b, blend.b))
#define BlendVividLight(base, blend) 	vec3(BlendVividLightf(base.r, blend.r), BlendVividLightf(base.g, blend.g), BlendVividLightf(base.b, blend.b))
#define BlendPinLight(base, blend) 		vec3(BlendPinLightf(base.r, blend.r), BlendPinLightf(base.g, blend.g), BlendPinLightf(base.b, blend.b))
#define BlendHardMix(base, blend) 		vec3(BlendHardMixf(base.r, blend.r), BlendHardMixf(base.g, blend.g), BlendHardMixf(base.b, blend.b))
#define BlendReflect(base, blend) 		vec3(BlendReflectf(base.r, blend.r), BlendReflectf(base.g, blend.g), BlendReflectf(base.b, blend.b))
#define BlendGlow(base, blend) 		    BlendReflect(blend, base)
#define BlendPhoenix(base, blend) 		(min(base, blend) - max(base, blend) + vec3(1.0))
#define BlendOpacity(base, blend, F, O) 	(F(base, blend) * O + (blend) * (1.0 - O))


// Hue Blend mode creates the result color by combining the luminance and saturation of the base color with the hue of the blend color.
vec3 BlendHue(vec3 base, vec3 blend)
{
    vec3 baseHSL = RGBToHSL(base);
    return HSLToRGB(vec3(RGBToHSL(blend).r, baseHSL.g, baseHSL.b));
}

// Saturation Blend mode creates the result color by combining the luminance and hue of the base color with the saturation of the blend color.
vec3 BlendSaturation(vec3 base, vec3 blend)
{
    vec3 baseHSL = RGBToHSL(base);
    return HSLToRGB(vec3(baseHSL.r, RGBToHSL(blend).g, baseHSL.b));
}

// Color Mode keeps the brightness of the base color and applies both the hue and saturation of the blend color.
vec3 BlendColor(vec3 base, vec3 blend)
{
    vec3 blendHSL = RGBToHSL(blend);
    return HSLToRGB(vec3(blendHSL.r, blendHSL.g, RGBToHSL(base).b));
}

// Luminosity Blend mode creates the result color by combining the hue and saturation of the base color with the luminance of the blend color.
vec3 BlendLuminosity(vec3 base, vec3 blend)
{
    vec3 baseHSL = RGBToHSL(base);
    return HSLToRGB(vec3(baseHSL.r, baseHSL.g, RGBToHSL(blend).b));
}


/*
 ** Gamma correction
 ** Details: http://blog.mouaif.org/2009/01/22/photoshop-gamma-correction-shader/
 */

#define GammaCorrection(color, gamma)								pow(color, 1.0 / gamma)

/*
 ** Levels control (input (+gamma), output)
 ** Details: http://blog.mouaif.org/2009/01/28/levels-control-shader/
 */

#define LevelsControlInputRange(color, minInput, maxInput)				min(max(color - vec3(minInput), vec3(0.0)) / (vec3(maxInput) - vec3(minInput)), vec3(1.0))
#define LevelsControlInput(color, minInput, gamma, maxInput)				GammaCorrection(LevelsControlInputRange(color, minInput, maxInput), gamma)
#define LevelsControlOutputRange(color, minOutput, maxOutput) 			mix(vec3(minOutput), vec3(maxOutput), color)
#define LevelsControl(color, minInput, gamma, maxInput, minOutput, maxOutput) 	LevelsControlOutputRange(LevelsControlInput(color, minInput, gamma, maxInput), minOutput, maxOutput)



#if   defined BLEND_MODE_NORMAL
#define definedBlend(a,b) BlendNormal(a,b)

#elif defined BLEND_MODE_LIGHTEN
#define definedBlend(a,b) BlendLighten(a,b)

#elif defined BLEND_MODE_DARKEN
#define definedBlend(a,b) BlendDarken(a,b)

#elif defined BLEND_MODE_MULTIPLY
#define definedBlend(a,b) BlendMultiply(a,b)

#elif defined BLEND_MODE_DIVIDE
#define definedBlend(a,b) BlendDivide(a,b)

#elif defined BLEND_MODE_AVERAGE
#define definedBlend(a,b) BlendAverage(a,b)

#elif defined BLEND_MODE_ADD
#define definedBlend(a,b) BlendAdd(a,b)

#elif defined BLEND_MODE_SUBTRACT
#define definedBlend(a,b) BlendSubtract(a,b)

#elif defined BLEND_MODE_DIFFERENCE
#define definedBlend(a,b) BlendDifference(a,b)

#elif defined BLEND_MODE_NEGATION
#define definedBlend(a,b) BlendNegation(a,b)

#elif defined BLEND_MODE_EXCLUSION
#define definedBlend(a,b) BlendExclusion(a,b)

#elif defined BLEND_MODE_SCREEN
#define definedBlend(a,b) BlendScreen(a,b)

#elif defined BLEND_MODE_OVERLAY
#define definedBlend(a,b) BlendOverlay(a,b)

#elif defined BLEND_MODE_SOFT_LIGHT
#define definedBlend(a,b) BlendSoftLight(a,b)

#elif defined BLEND_MODE_HARD_LIGHT
#define definedBlend(a,b) BlendHardLight(a,b)

#elif defined BLEND_MODE_COLOR_DODGE
#define definedBlend(a,b) BlendColorDodge(a,b)

#elif defined BLEND_MODE_COLOR_BURN
#define definedBlend(a,b) BlendColorBurn(a,b)

#elif defined BLEND_MODE_LINEAR_LIGHT
#define definedBlend(a,b) BlendLinearLight(a,b)

#elif defined BLEND_MODE_VIVID_LIGHT
#define definedBlend(a,b) BlendVividLight(a,b)

#elif defined BLEND_MODE_PIN_LIGHT
#define definedBlend(a,b) BlendPinLight(a,b)

#elif defined BLEND_MODE_HARD_MIX
#define definedBlend(a,b) BlendHardMix(a,b)

#elif defined BLEND_MODE_HARD_REFLECT
#define definedBlend(a,b) BlendReflect(a,b)

#elif defined BLEND_MODE_HARD_GLOW
#define definedBlend(a,b) BlendGlow(a,b)

#elif defined BLEND_MODE_HARD_PHOENIX
#define definedBlend(a,b) BlendPhoenix(a,b)

#elif defined BLEND_MODE_HUE
#define definedBlend(a,b) BlendHue(a,b)

#elif defined BLEND_MODE_SATURATION
#define definedBlend(a,b) BlendSaturation(a,b)

#elif defined BLEND_MODE_COLOR
#define definedBlend(a,b) BlendColor(a,b)

#elif defined BLEND_MODE_LUMINOSITY
#define definedBlend(a,b) BlendLuminosity(a,b)

#endif

#ifndef definedBlend
#error If you define sc_BlendMode_Custom, you must also define a BLEND_MODE_*!
#endif

vec4 applyCustomBlend(vec4 color) {
    vec4 result;
    vec3 framebuffer = getFramebufferColor().rgb;
    result.rgb = definedBlend(framebuffer, color.rgb);
    result.rgb = mix(framebuffer, result.rgb, color.a);
    result.a = 1.0;
    return result;
}

#endif // sc_BlendMode_Custom
#endif // FRAGMENT_SHADER

#endif //BLEND_MODES_GLSL
//-----------------------------------------------------------------------
// Copyright (c) 2017 Snap Inc.
//-----------------------------------------------------------------------

#ifndef FIZZLE_GLSL
#define FIZZLE_GLSL

#ifdef FRAGMENT_SHADER

uniform float transition;

float map( float value, float inputMin, float inputMax, float outputMin, float outputMax ) { return ((value - inputMin) / (inputMax - inputMin) * (outputMax - outputMin) + outputMin); }
float linearStep( float _edge0, float _edge1, float _t ) { return clamp( (_t - _edge0)/(_edge1 - _edge0), 0.0, 1.0); }

// hash and snoise licensed under MIT via: https://www.shadertoy.com/view/4sfGzS
// The MIT License
// Copyright 2013 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the Software), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

float hash(vec3 p)
{
    p  = fract( p*0.3183099+.1 );
    p *= 17.0;
    return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}

float snoise( vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    return mix(mix(mix( hash(p+vec3(0.0,0.0,0.0)),
                       hash(p+vec3(1.0,0.0,0.0)),f.x),
                   mix( hash(p+vec3(0.0,1.0,0.0)),
                       hash(p+vec3(1.0,1.0,0.0)),f.x),f.y),
               mix(mix( hash(p+vec3(0.0,0.0,1.0)),
                       hash(p+vec3(1.0,0.0,1.0)),f.x),
                   mix( hash(p+vec3(0.0,1.0,1.0)),
                       hash(p+vec3(1.0,1.0,1.0)),f.x),f.y),f.z);
}

vec4 fizzle(vec4 col)
{
    vec4 result = col;
    if( transition >= 1.0 )
    {
        discard;
    }
    else if( transition > 0.0 )
    {
        vec3 burnPassOutColor = vec3(1.0, 1.0, 1.0);
        
        vec3 origColor = result.xyz;  // surface color could be anything
        vec3 origColorInverted = vec3(1.0 - result.xyz);
        vec3 burnEdgeColor = vec3(1.0, 1.0, 1.0);
        
        vec3 burnAwayNoisePosFrequency = vec3(0.3, 0.03, 0.3);
        
        vec3 p = vec3( varPos.xyz * burnAwayNoisePosFrequency );
        
        float amountToMoveUpwards = 6.0;
        p.xyz += vec3(0.0, map( smoothstep( 0.0, 0.8, transition), 0.0, 1.0, 0.0, amountToMoveUpwards), 0.0); // make it move
        
        float noiseVal = (snoise(p) + 1.0) * 0.5;
        noiseVal -= smoothstep( 0.0, 1.0, transition);
        noiseVal = smoothstep( 0.05, 0.95, noiseVal ); // let's keep it at 0 and 1 a little bit longer, also gives it a bit of easing
        if (noiseVal <= 0.0) discard;
        
        float burnAmount = 1.0 - linearStep( 0.0, 0.1, noiseVal ); // we have a value from 0..1, let's map it so the first X% ramps up to 1 and holds there
        float burnColorMix = linearStep( 0.9, 1.0, burnAmount );
        burnColorMix = linearStep( 0.2, 0.8, burnColorMix ); // Stay at 0 and 1.0 longer
        vec3 burnColor = mix( origColorInverted, burnEdgeColor, burnColorMix );
        
        float surfaceOrBurn = 1.0 - step( 0.0075, noiseVal );
        burnPassOutColor = mix( origColor, burnColor, surfaceOrBurn );
        
        result.xyz = burnPassOutColor;
    }
    return result;
}

#endif // #ifdef FRAGMENT_SHADER
#endif // FIZZLE_GLSL

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
//-----------------------------------------------------------------------
// Copyright (c) 2017 Snap Inc.
//-----------------------------------------------------------------------

#ifndef ENVMAP_GLSL
#define ENVMAP_GLSL


//-----------------------------------------------------------------------
// Copyright (c) 2017 Snap Inc.
//-----------------------------------------------------------------------

#ifndef UTILS_GLSL
#define UTILS_GLSL

#ifndef PI
#define PI 3.141592653589793238462643383279
#endif

#ifndef MAYA
float saturate(float value) {
    return clamp(value, 0.0, 1.0);
}

vec3 saturate(vec3 value) {
    return clamp(value, 0.0, 1.0);
}
#endif

float dot_sat(vec3 a, vec3 b) {
    return saturate(dot(a, b)); // dp3_sat
}

#if defined(MAYA) || defined(SUBSTANCE)
float srgbToLinear(float x) {
    return x <= 0.04045 ? x * 0.0773993808 : pow((x + 0.055) / 1.055, 2.4);
}

float linearToSrgb(float x) {
    return x <= 0.0031308 ? 12.92 * x : 1.055 * pow(x, 0.41666) - 0.055;
}
#else
float srgbToLinear(float x) {
    return pow(x, 2.2);
}

float linearToSrgb(float x) {
    return pow(x, 1.0 / 2.2);
}
#endif

vec3 srgbToLinear(vec3 color) {
    return vec3(srgbToLinear(color.r), srgbToLinear(color.g), srgbToLinear(color.b));
}

vec3 linearToSrgb(vec3 color) {
    return vec3(linearToSrgb(color.r), linearToSrgb(color.g), linearToSrgb(color.b));
}

#endif // UTILS_GLSL


vec4 encodeRGBD(vec3 rgb) {
    float maxRGB = max(1.0, (max(rgb.x, max(rgb.g, rgb.b))));
    float D = 1.0 / maxRGB;
    return vec4(rgb.rgb * D, D);
}

vec3 decodeRGBD(vec4 rgbd) {
    return rgbd.rgb * (1.0 / rgbd.a);
}

vec3 decodeRGBE(vec4 rgbe) {
    float f1 = exp2(rgbe.w * 255.0 - 128.0);
    return rgbe.xyz * vec3(f1);
}

vec2 calcSeamlessPanoramicUvsForConvolution(vec2 uv, vec2 topMipRes, float lod) {
    // Maps a range of (halftex, res-halftex) to (0, res).
    vec2 thisMipRes = max(vec2(1.0), topMipRes / vec2(exp2(lod)));
    return (uv * thisMipRes - 0.5) / (thisMipRes - 1.0);
}

vec2 calcSeamlessPanoramicUvsForSampling(vec2 uv, vec2 topMipRes, float lod) {
#ifdef DEVICE_IS_FAST
    // Maps a range of (0, res) to (halftex, res-halftex), ie: one texel narrower.
    // This makes sure that we only sample to the center of the border texels, as intended by the convolution.
    vec2 thisMipRes = max(vec2(1.0), topMipRes / vec2(exp2(lod)));
    return uv * (thisMipRes - 1.0) / thisMipRes + 0.5 / thisMipRes;
#else
    return uv;
#endif
}

float _atan2(float x, float y) {
    // This version of atan2 is faster on low-end devices like Galaxy S3.
    return sign(x) * acos(y/length(vec2(x,y)));
}

vec2 calcPanoramicTexCoordsFromDir(vec3 reflDir, float rotationDegrees) {
    vec2 uv;
    uv.x = _atan2(reflDir.x, -reflDir.z) - PI/2.0; // Need to mirror the lookup, and rotate to match Substance.
    uv.y = acos(reflDir.y);
    uv = uv / vec2(2.0 * PI, PI);
    uv.y = 1.0 - uv.y;
    
    // Rotate the environment around the Y axis
    uv.x += rotationDegrees / 360.0;
    uv.x = fract(uv.x + floor(uv.x) + 1.0); // wrap the result to be between 0 and 1, otherwise the seamless uv lookup fails

    return uv;
}

vec3 calcDirFromPanoramicTexCoords(vec2 uv) {
    float a = 2.0 * PI * (uv.x);
    float b = PI * uv.y;
    
    float x = sin(a) * sin(b);
    float y = cos(b);
    float z = cos(a) * sin(b);
    
    return vec3(z, y, x);
}

vec2 calcSphericalTexCoordsFromDir(vec3 reflDir) {
    float m = 2.0 * sqrt(reflDir.x * reflDir.x + reflDir.y * reflDir.y + (reflDir.z + 1.0) * (reflDir.z + 1.0));
    vec2 reflTexCoord = reflDir.xy / m + 0.5;
    return reflTexCoord;
}

vec2 calcAngularTexCoordsFromDir(vec3 V) {
    V = vec3(-V.z, V.y, -V.x);  // Rotate to match Lys panoramics.
    float r = 0.159154943*acos(V.z)/sqrt(V.x*V.x + V.y*V.y);
    float u = 0.5 + V.x * r;
    float v = 0.5 + V.y * r;
    return vec2(u, 1.0 - v);
}

vec2 calculateEnvmapScreenToCube(vec3 V)
{
    // Similar to cubemap lookup code, but modified to unwrap the half-cube to the screen, and mirror the half-cube in Z.
    V.z = abs(V.z);
    vec3 vAbs = abs(V);
    vec2 uv;
    if(vAbs.z >= vAbs.x && vAbs.z >= vAbs.y)
    {
        float ma = 0.5 / vAbs.z;
        uv = vec2(V.x, V.y) * ma;
        uv = uv * 0.5 + vec2(0.5);
    }
    else if(vAbs.y >= vAbs.x)
    {
        float ma = 0.5 / vAbs.y;
        uv = vec2(V.x, -V.z) * ma;
        uv.x = uv.x * mix(0.5, 1.0, 1.0 - abs(uv.y) * 2.0); // map the sides to trapezoids instead of 0.25x0.5 recrangles, to make sure that the edges match and there are no texture seams.
        uv.x += 0.5;
        uv.y *= 0.5;
        uv.y = abs(uv.y);
        if (V.y > 0.0) {
            uv.y = 1.0 - uv.y;
        }
    }
    else
    {
        float ma = 0.5 / vAbs.x;
        uv = vec2(V.x < 0.0 ? V.z : -V.z, V.y) * ma;
        uv.y = uv.y * mix(0.5, 1.0, 1.0 - abs(uv.x) * 2.0); // map the sides to trapezoids instead of 0.25x0.5 recrangles, to make sure that the edges match and there are no texture seams.
        uv.y += 0.5;
        uv.x *= 0.5;
        uv.x = abs(uv.x);
        if (V.x > 0.0) {
            uv.x = 1.0 - uv.x;
        }
    }
    return uv;
}

#endif // ENVMAP_GLSL

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

//-----------------------------------------------------------------------
// Copyright (c) 2017 Snap Inc.
//-----------------------------------------------------------------------

#ifndef PBR_GLSL
#define PBR_GLSL

// Requirements:
//
// Depending on platform, some or all of the below functions must be defined by the client shader before this file is included (a form of callback):
//
// vec3 sampleSpecularEnvmapLod(vec3 R, float lod);
// vec3 sampleRadiance(vec3 R);
// vec3 calculateDiffuseIrradiance(vec3 N);


//-----------------------------------------------------------------------
// Copyright (c) 2017 Snap Inc.
//-----------------------------------------------------------------------

#ifndef UTILS_GLSL
#define UTILS_GLSL

#ifndef PI
#define PI 3.141592653589793238462643383279
#endif

#ifndef MAYA
float saturate(float value) {
    return clamp(value, 0.0, 1.0);
}

vec3 saturate(vec3 value) {
    return clamp(value, 0.0, 1.0);
}
#endif

float dot_sat(vec3 a, vec3 b) {
    return saturate(dot(a, b)); // dp3_sat
}

#if defined(MAYA) || defined(SUBSTANCE)
float srgbToLinear(float x) {
    return x <= 0.04045 ? x * 0.0773993808 : pow((x + 0.055) / 1.055, 2.4);
}

float linearToSrgb(float x) {
    return x <= 0.0031308 ? 12.92 * x : 1.055 * pow(x, 0.41666) - 0.055;
}
#else
float srgbToLinear(float x) {
    return pow(x, 2.2);
}

float linearToSrgb(float x) {
    return pow(x, 1.0 / 2.2);
}
#endif

vec3 srgbToLinear(vec3 color) {
    return vec3(srgbToLinear(color.r), srgbToLinear(color.g), srgbToLinear(color.b));
}

vec3 linearToSrgb(vec3 color) {
    return vec3(linearToSrgb(color.r), linearToSrgb(color.g), linearToSrgb(color.b));
}

#endif // UTILS_GLSL


struct SurfaceProperties {
    vec3 albedo;
    float opacity;
    vec3 normal;
    float metallic;
    float roughness;
    vec3 emissive;
    vec3 ao;
    vec3 specularAo;
    
    // Derived surface properties
    vec3 specColor;
};

struct LightingComponents {
    vec3 directDiffuse;
    vec3 directSpecular;
    vec3 indirectDiffuse;
    vec3 indirectSpecular;
    vec3 emitted;
    vec3 transmitted;
};

struct LightProperties {
    vec3 direction;
    vec3 color;
    float attenuation;
};

struct DebugOptions {
    bool enableMetallic;
    bool envBRDFApprox;
    bool envBentNormal;
    float envMip;
    bool envSampling;
    bool envSamplingGroundTruth;
    int envSamples;
    int envRandMod;
    int envRandSeed;
    bool fringelessMetallic;
    bool acesToneMapping;
    bool linearToneMapping;
    bool albedo;
    bool specColor;
    bool roughness;
    bool normal;
    bool ao;
    float directDiffuse;
    float directSpecular;
    float indirectDiffuse;
    float indirectSpecular;
};

SurfaceProperties defaultSurfaceProperties() {
    SurfaceProperties surfaceProperties;
    
    surfaceProperties.albedo = vec3(0.0);
    surfaceProperties.opacity = 1.0;
    surfaceProperties.normal = vec3(0.0);
    surfaceProperties.metallic = 0.0;
    surfaceProperties.roughness = 0.0;
    surfaceProperties.emissive = vec3(0.0);
    surfaceProperties.ao = vec3(1.0);
    surfaceProperties.specularAo = vec3(1.0);
    
    return surfaceProperties;
}

LightingComponents defaultLightingComponents() {
    LightingComponents lighting;
    
    lighting.directDiffuse = vec3(0.0);
    lighting.directSpecular = vec3(0.0);
    lighting.indirectDiffuse = vec3(1.0);
    lighting.indirectSpecular = vec3(0.0);
    lighting.emitted = vec3(0.0);
    lighting.transmitted = vec3(0.0);
    
    return lighting;
}

DebugOptions defaultDebugOptions() {
    DebugOptions debug;
    
    debug.enableMetallic = true;
    debug.envBRDFApprox = true;
    debug.envBentNormal = true;
    debug.envMip = -1.0;
    debug.envSampling = false;
    debug.envSamplingGroundTruth = false;
#ifndef MOBILE
    debug.envSamples = 500;
    debug.envRandMod = 333;
    debug.envRandSeed = -1;
#endif
    debug.fringelessMetallic = true;
    debug.acesToneMapping = false;
    debug.linearToneMapping = false;
    debug.albedo = false;
    debug.specColor = false;
    debug.roughness = false;
    debug.normal = false;
    debug.directDiffuse = 1.0;
    debug.indirectDiffuse = 1.0;
    debug.directSpecular = 1.0;
    debug.indirectSpecular = 1.0;
    
    return debug;
}

vec3 fresnelSchlickSub(float cosTheta, vec3 F0, vec3 fresnelMax) {
    float b = 1.0 - cosTheta;
    float b2 = b * b;
    float b5 = b2 * b2 * b;  // b5 = pow(1-cosTheta, 5);
    return F0 + (fresnelMax - F0) * b5;
}

vec3 fresnelSchlick(float cosTheta, vec3 F0) {
    return fresnelSchlickSub(cosTheta, F0, vec3(1.0));
}

float Dggx(float NdotH, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH2 = NdotH * NdotH;
    float b = NdotH2 * (a2 - 1.0) + 1.0;
    float b2 = b * b;
    return a2 / b2;
}

float Gggx1(float NdotV, float roughness) {
    float k = roughness + 1.0;
    k = k * k * 0.125;
    return NdotV * (1.0 - k) + k;  // The NdotV and NdotL from the numerator of G cancel with the NdotV and NdotL in the denominator of the Cook Torrance BRDF. We take the reciprocal together in G.
}

float Gggx(float NdotL, float NdotV, float roughness) {
    // Schlick approximation of Smith G for GGX.
    return 1.0 / (Gggx1(NdotL, roughness) * Gggx1(NdotV, roughness));
}

vec3 calculateDirectDiffuse(SurfaceProperties surfaceProperties, vec3 L) {
    return vec3(saturate(dot(surfaceProperties.normal, L)));
}

vec3 calculateDirectSpecular(SurfaceProperties surfaceProperties, vec3 L, vec3 V) {
    float r = max(surfaceProperties.roughness, 0.03); // Make sure the tightest highlight is not infinitely small
    vec3 F0 = surfaceProperties.specColor;
    vec3 N = surfaceProperties.normal;
    vec3 H = normalize(L + V);
    float NdotL = saturate(dot(N, L));
    float NdotV = saturate(dot(N, V));
    float NdotH = saturate(dot(N, H));
    float VdotH = saturate(dot(V, H));
    
#if defined(DEVICE_IS_FAST)
    // Cook torrance Specular with GGX NDF. Note: the NdotL and NdotV from the denominator of Cook Torrance cancels with the numerator of G.
    // The pi disappears and the NdotL appears the same way it does in the diffuse lighting function (BRDF is modulated by NdotL to get actual lighting).
    return Dggx(NdotH, r) * Gggx(NdotL, NdotV, r) * 0.25 * NdotL * fresnelSchlick(VdotH, F0);
#else
    // Normalized Blinn-Phong
    float specPower = exp2(11.0 - 10.0 * r);  // Simplified based on: gloss = 1 - r
    return (specPower * 0.125 + 0.25) * pow(NdotH, specPower) * NdotL * fresnelSchlick(VdotH, F0);
#endif
}

LightingComponents accumulateLight(LightingComponents lighting, LightProperties light, SurfaceProperties surfaceProperties, vec3 V) {
    lighting.directDiffuse += calculateDirectDiffuse(surfaceProperties, light.direction) * light.color * light.attenuation;
    lighting.directSpecular += calculateDirectSpecular(surfaceProperties, light.direction, V) * light.color * light.attenuation;
    return lighting;
}

#ifndef SUBSTANCE

vec3 calculateIndirectDiffuse(SurfaceProperties surfaceProperties) {
    return calculateDiffuseIrradiance(surfaceProperties.normal);
}

// Calculate the appropriate env map mip based on the roughness.
// The curve is controlled by the exponent, to allocate the most appropriate amount of detail to each mip.
// If the resulution is too low for a given convolution, it will look bad.
// If the resolution is too high, you're not getting as many useful mip grades.
// The maxRoughnessMip specifies which mip level contains the roughest convolution. This is usually not the last mip, as a single pixel can't represent the necessary variation in lighting.
float calculateEnvMipFromRoughness(float roughness, float roughnessExponentInv, float maxRoughnessMip)
{
    return saturate(pow(roughness, roughnessExponentInv)) * maxRoughnessMip;
}

float calculateEnvMipFromRoughness(float roughness, DebugOptions debug) {
#ifdef SCENARIUM
    // In Scenarium we use an importance sampling convolver to render our env maps in lat-long format.
    // The tools that generate mips must match this roughnessExponentInv and maxRoughnessMip at bake time.
    // NOTE: in practice we hack the exponent (doesn't quite match the exponent used at bake time) to match the importance sampled reference better. It seems that due to the low-ish number of mips, a sharper mip often gets mixed in, and that effectively makes the roughness look sharper. This hack compensates a bit. Bottom of this page might also offer a clue to investigate: https://docs.knaldtech.com/doku.php?id=specular_lys
    const float roughnessExponentInv = 1.0/1.5;
    const float maxRoughnessMip = 5.0;
    float mip = calculateEnvMipFromRoughness(roughness, roughnessExponentInv, maxRoughnessMip);
#else
    // In Maya we use cubemaps convolved by Lys.
    // maxRoughnessMip must match the roughest mip as set in Lys.
    float gloss = 1.0 - roughness;
    float lysRoughness = 1.0 - gloss*gloss;  // Match the env map roughnes curve of Lys to proper GGX (not sure why Lys expects roughness to be the inverse of gloss squared, but this is the closest match I can get).
    const float maxRoughnessMip = 7.0;
    float mip = lysRoughness * maxRoughnessMip;
#endif
    
#ifdef DEBUG
    if (debug.envMip >= 0.0) {
        mip = debug.envMip;
    }
#endif
    
    return mip;
}

// Makes cubemap reflections behave closer to the reference, taking into account view vector dependence.
// Ie: correct for the fact that the env map is preconvolved assuming V == N, which does not hold in general.
// The idea came from Frostbite, but our version is much simplified and has less artifacts (ours doesn't warp reflections on smooth surfaces).
vec3 getSpecularDominantDir(vec3 N, vec3 R, float roughness, DebugOptions debug) {
#ifdef DEVICE_IS_FAST
#ifdef DEBUG
    if (debug.envBentNormal)
#endif
    {
        float lerpFactor = roughness * roughness * roughness;
        return normalize(mix(R, N, lerpFactor));
    }
#else // #ifdef DEVICE_IS_FAST
    return R;
#endif // #else // #ifdef DEVICE_IS_FAST
}

// Approximates the effects of fresnel and G for environment maps.
vec3 envBRDFApprox(SurfaceProperties surfaceProperties, float NdotV, DebugOptions debug) {
#ifdef DEVICE_IS_FAST
#ifdef DEBUG
    bool useBRDFApprox = debug.envBRDFApprox;
#else
    bool useBRDFApprox = true;
#endif
#else // #ifdef DEVICE_IS_FAST
    bool useBRDFApprox = false;
#endif // #else // #ifdef DEVICE_IS_FAST
        
    if (useBRDFApprox) {
        const vec4 c0 = vec4(-1.0, -0.0275, -0.572, 0.022);
        const vec4 c1 = vec4(1.0, 0.0425, 1.04, -0.04);
        vec4 r = surfaceProperties.roughness * c0 + c1;
        float a004 = min(r.x * r.x, exp2(-9.28 * NdotV)) * r.x + r.y;
        vec2 AB = vec2(-1.04, 1.04) * a004 + r.zw;
        return surfaceProperties.specColor * AB.x + AB.y;
    }
    else {
        // Do fresnel (F), but drive down the brightness at the edge as the roughness gets higher (G). Without this you get glowing edges on rough materials.
        vec3 fresnelMax = max(vec3(1.0 - surfaceProperties.roughness), surfaceProperties.specColor);
        return fresnelSchlickSub(NdotV, surfaceProperties.specColor, fresnelMax);
    }
}

#ifndef MOBILE
//-----------------------------------------------------------------------
// Copyright (c) 2017 Snap Inc.
//-----------------------------------------------------------------------

#ifndef IMPORTANCE_SAMPLING_GLSL
#define IMPORTANCE_SAMPLING_GLSL

// Requirements:
//
// Depending on platform, some or all of the below functions must be defined by the client shader before this file is included (a form of callback):
//
// vec3 sampleRadiance(vec3 R);

// Environment map filtering with importance sampling.
// Used for pre-convolving environment maps on the tool side.
// NOTE: importance sampling is not viable at runtime in production, but can be used as a ground truth debug aid.

//float radicalInverse_VdC(int bits) {
//    bits = (bits << 16) | (bits >> 16);
//    bits = ((bits & 0x55555555) << 1) | ((bits & 0xAAAAAAAA) >> 1);
//    bits = ((bits & 0x33333333) << 2) | ((bits & 0xCCCCCCCC) >> 2);
//    bits = ((bits & 0x0F0F0F0F) << 4) | ((bits & 0xF0F0F0F0) >> 4);
//    bits = ((bits & 0x00FF00FF) << 8) | ((bits & 0xFF00FF00) >> 8);
//    return float(bits) * 2.3283064365386963e-10; // / 0x100000000
//}

float radicalInverse(int n) {
    float val = 0.0;
    float invBase = 0.5;
    float invBi = invBase;
    while (n > 0) {
        int d_i = n - ((n / 2) * 2);
        val += d_i * invBi;
        n /= 2;
        invBi *= 0.5;
    }
    return val;
}

vec2 hammersley(int i, int N) {
    return vec2(float(i)/float(N), radicalInverse(i));
}

vec3 importanceSampleGGX(vec2 Xi, float roughness, vec3 N) {
    float a = roughness * roughness;
    float Phi = 2 * PI * Xi.x;
    float CosTheta = sqrt((1 - Xi.y) / (1 + (a*a - 1) * Xi.y));
    float SinTheta = sqrt(1 - CosTheta * CosTheta);
    vec3 H;
    H.x = SinTheta * cos(Phi);
    H.y = SinTheta * sin(Phi);
    H.z = CosTheta;
    vec3 UpVector = abs(N.z) < 0.999 ? vec3(0,0,1) : vec3(1,0,0);
    vec3 TangentX = normalize(cross(UpVector, N));
    vec3 TangentY = cross(N, TangentX);
    // Tangent to world space
    return TangentX * H.x + TangentY * H.y + N * H.z;
}

// Samples the environment map using the GGX disrtibution, but ignores G and F.
vec3 prefilterEnvmap(float roughness, vec3 R, DebugOptions debug) {
    vec3 N = R;
    vec3 V = R;
    vec3 totalColor = vec3(0.0);
    float totalWeight = 0.0;
    
    int randMod = debug.envRandMod; 
    int randSeed = debug.envRandSeed; // envRandSeed in combination with envRandMod can be used to split up a long random sequence of samples into multiple passes. emvRandMod would be the number of passes, and envRandSeed the pass index. This way we evenly cover the range of envNumSamples*envRandMod random samples in the Hammersley sequence.
    if (randSeed < 0) {
        // Randomize the Hammersley sequence per pixel.
        // We get a hash based on the reflection vector.
        // We then mod this and use it to select between randMod number of skip sequences
        randSeed = int((abs(R.x) + abs(R.y) + abs(R.z)) * 12345711.0);
        randSeed = int(mod(float(randSeed), float(randMod)));
    }
    
    int numSamples = int(debug.envSamples);
    for(int i = 0; i < numSamples; i++) {
        vec2 Xi = hammersley(i*randMod + randSeed, numSamples*randMod);
        vec3 H = importanceSampleGGX(Xi, roughness, N);
        vec3 L = 2 * dot(V, H) * H - V;
        
        float NoL = saturate(dot(N, L));
        
        if(NoL > 0) {
            vec3 IncidentLight = sampleRadiance(L) * NoL;
            totalColor += IncidentLight;
            totalWeight += NoL;
        }
    }
    return totalColor / totalWeight;
}

float gEnv1(vec3 N, vec3 V, float roughness) {
    // This version of G is different from our usual G.
    // UE4 remaps roughness to alpha = ((roughness+1)/2)^2 only for their G function to "reduce hotness" on analytical lights, so their version of G is not the true Schlick G.
    // This makes reflections too dark at glancing angles for image based lighting.
    // Below is the "true" Schlick G1.
    float alpha = roughness * roughness;
    float k = alpha * 0.5;
    float NdotV = saturate(dot(N, V));
    return NdotV * (1.0 - k) + k;  // The NdotV and NdotL from the numerator of G cancel with the NdotV and NdotL in the denominator of the Cook Torrance BRDF. We take the reciprocal together in G.
}

float gEnv(vec3 N, vec3 L, vec3 V, float roughness) {
    return 1.0 / (gEnv1(N, L, roughness) * gEnv1(N, V, roughness));
}

// Calculates a full importance sampled ground truth representation of environment mapping, taking into account the full BRDF, including F and G.
vec3 calculateIndirectSpecularGroundTruth(SurfaceProperties surfaceProperties, vec3 V, DebugOptions debug) {
    float roughness = surfaceProperties.roughness;
    vec3 N = surfaceProperties.normal;
    
#ifdef MAYA
    N = vec3(-N.z, N.y, -N.x);  // Orient the envmap like Substance.
    V = vec3(-V.z, V.y, -V.x);  // Orient the envmap like Substance.
#endif
    
    // Randomize the Hammersley sequence per pixel. Without this, there are coherent, splotchy artifacts. We prefer to replace this with incoherent noise to get a more unbiased ground truth approximation with less samples.
    // We get a hash based on the reflection vector. We then mod this and use it to select between randMod number of skip sequences (our full sequence length is numSamples * randMod and we select the skip sequence like this: i * randMod + rand).
    vec3 R = reflect(-V, N);
    int randMod = int(debug.envRandMod);
    int rand = int((abs(R.x) + abs(R.y) + abs(R.z)) * 12345711.0);
    rand = int(mod(float(rand), float(randMod)));
    
    vec3 totalColor = vec3(0.0);
    int numSamples = int(debug.envSamples);
    for(int i = 0; i < numSamples; i++) {
        vec2 Xi = hammersley(i * randMod + rand, numSamples * randMod);
        vec3 H = importanceSampleGGX(Xi, roughness, N);
        vec3 L = 2 * dot(V, H) * H - V;
        
        float NoL = saturate(dot(N, L));
        float NoH = saturate(dot(N, H));
        float VoH = saturate(dot(V, H));
        
        if(NoL > 0) {
            vec3 IncidentLight = sampleRadiance(L) * NoL;
            
            // Incident light = SampleColor * NoL
            // Microfacet specular = D*G*F / (4*NoL*NoV)
            // pdf = D * NoH / (4 * VoH)
            // (IncidentLight * D*G*F / 4)           / (D * NoH / (4 * VoH)) = IncidentLight * F * G * VoH / NoH        -- Is our version because our NoL NoV in G is already cancelled out with Cook Torrance (see calculateDirectSpecular()).
            totalColor += IncidentLight * gEnv(N, L, V, roughness) * VoH * (1.0 / NoH) * fresnelSchlick(VoH, surfaceProperties.specColor);
        }
    }
    return totalColor / numSamples;
}

#endif // IMPORTANCE_SAMPLING_GLSL
#endif

// Calculates environment reflections
vec3 calculateIndirectSpecular(SurfaceProperties surfaceProperties, vec3 V, DebugOptions debug) {
#ifdef MAYA
    if (debug.envSamplingGroundTruth) {
        return calculateIndirectSpecularGroundTruth(surfaceProperties, V, debug);  // Allow to compare the results of environment mapping calculated below, versus the realtime importance sampled evaluation of the full BRDF.
    }
#endif
    
    vec3 N = surfaceProperties.normal;
    
#ifdef MAYA
    // Orient the envmap like Substance and Scenarium.
    N = vec3(-N.z, N.y, -N.x);
    V = vec3(-V.z, V.y, -V.x);
#endif
    
    vec3 R = reflect(-V, N);
    
    R = getSpecularDominantDir(N, R, surfaceProperties.roughness, debug);
    
    float mip = calculateEnvMipFromRoughness(surfaceProperties.roughness, debug);

    vec3 envmap = sampleSpecularEnvmapLod(R, mip);
    
#ifdef MAYA
    if (debug.envSampling) {
        envmap = prefilterEnvmap(surfaceProperties.roughness, R, debug);  // Allow to compare the results of the envmap sampled above, versus the realtime importance sampled reference.
    }
#endif
    
    return envmap * envBRDFApprox(surfaceProperties, abs(dot(N, V)), debug); // We use abs instead of saturate here to avoid over-brightening the back sides of normal map bumps, which would not be visible in real life. Saturate just clamps the brightness of fresnel on the back sides of bumps to full bright, whereas abs peaks and trails off, making the artifact slightly less offensive.
}
#endif // #ifndef SUBSTANCE

void deriveAlbedoAndSpecColorFromSurfaceProperties(in SurfaceProperties surfaceProperties, out vec3 albedo, out vec3 specColor, DebugOptions debug) {
#ifdef DEBUG
    if (debug.enableMetallic) {
        if (debug.fringelessMetallic) {
#endif
            // The classic way of blending between metals and dielectrics causes bright fringes at the transition.
            // This same blend in the specular model does not cause such finging, and we observe that the shading result is darker in the middle of the blend range in the specular model than in the metallic model.
            // Ie: the sum of the diffuse and specular lighting with the classic metallic blend is brighter than it should be in the middle of the blend range.
            // Knowing that the undesirable fringe is brighter than the reference, we ramp down the brightness of diffuse albedo and specular color faster by multiplying in an extra metallic term.
            // The result of this is quite close to the reference, though it's impossible to do "correct" material blending in the metallic model since diffuse and specular colors are confounded.
            specColor = mix(vec3(0.04), surfaceProperties.albedo*surfaceProperties.metallic, surfaceProperties.metallic);
            albedo = mix(surfaceProperties.albedo*(1.0-surfaceProperties.metallic), vec3(0.0), surfaceProperties.metallic);
#ifdef DEBUG
        } else {
            specColor = mix(vec3(0.04), surfaceProperties.albedo, surfaceProperties.metallic);
            albedo = mix(surfaceProperties.albedo, vec3(0.0), surfaceProperties.metallic);
        }
    } else {
        // If we're not in metallic mode but colored spec, there's nothing to derive. Pass through.
        specColor = surfaceProperties.specColor;
        albedo = surfaceProperties.albedo;
    }
#endif
}

// This function derives surface properties that were not in the input material data (ex: in a metallic material model, spec color, ie: F0, is derived from albedo and the matallic parameter).
SurfaceProperties calculateDerivedSurfaceProperties(SurfaceProperties surfaceProperties, DebugOptions debug) {
    deriveAlbedoAndSpecColorFromSurfaceProperties(surfaceProperties, surfaceProperties.albedo, surfaceProperties.specColor, debug);
    return surfaceProperties;
}

// This function does the final logical combination of surface properties and lighting.
vec3 combineSurfacePropertiesWithLighting(SurfaceProperties surfaceProperties, LightingComponents lighting, bool enablePremultipliedAlpha) {
    vec3 diffuse = surfaceProperties.albedo * (lighting.directDiffuse + lighting.indirectDiffuse * surfaceProperties.ao);
    vec3 specular = lighting.directSpecular + lighting.indirectSpecular * surfaceProperties.specularAo;
    vec3 emitted = surfaceProperties.emissive;
    vec3 transmitted = lighting.transmitted;
    
    if (enablePremultipliedAlpha) {
        diffuse *= srgbToLinear(surfaceProperties.opacity);
    }
    
    vec3 result = diffuse + specular + emitted + transmitted;
    
    return result;
}

vec4 debugOutput(vec4 regularOutput, SurfaceProperties surfaceProperties, LightingComponents lighting, DebugOptions debug) {
    vec4 result = regularOutput;
    result.a = 1.0;
    
    if (debug.albedo) {
        result.xyz = surfaceProperties.albedo;
    } else if (debug.specColor) {
        result.xyz = surfaceProperties.specColor;
    } else if (debug.roughness) {
        result.xyz = vec3(srgbToLinear(surfaceProperties.roughness));
    } else if (debug.normal) {
        result.xyz = srgbToLinear(surfaceProperties.normal * 0.5 + 0.5);
    } else if (debug.ao) {
        result.xyz = surfaceProperties.ao;
    } else {
        result = regularOutput;
    }
    
    return result;
}

vec3 linearToneMapping(vec3 x) {
    // A curve that is mostly linear, but trails off in the shoulder region, so it avoids abrupt highlight clipping.
    float a = 1.8;  // Mid
    float b = 1.4;  // Toe
    float c = 0.5;  // Shoulder
    float d = 1.5;  // Mid
    
    return (x * (a * x + b)) / (x * (a * x + c) + d);
}

vec3 acesToneMapping(vec3 x) {
    // Approximated ACES RRT + ODT curve.
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return (x * (a * x + b)) / (x * (c * x + d) + e);
}

#endif // PBR_GLSL

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


