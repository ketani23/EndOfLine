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
