//-----------------------------------------------------------------------
// Copyright (c) 2017 Snap Inc.
//-----------------------------------------------------------------------

#ifndef PROJECT_ENVMAP_GLSL
#define PROJECT_ENVMAP_GLSL

vec2 projectLatLong(vec3 r) {
    const float Pi = 3.141592;
    float latitude = atan(r.x, r.z);
    float longitude = asin(r.y);
    float u = (latitude + Pi) / (2.0 * Pi);
    float v = (longitude + Pi / 2.0) / Pi;
    return vec2(u, v);
}

#endif // PROJECT_ENVMAP_GLSL
