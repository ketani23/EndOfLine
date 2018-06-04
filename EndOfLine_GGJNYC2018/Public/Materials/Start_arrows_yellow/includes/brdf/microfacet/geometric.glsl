#include "~/includes/utils.glsl"

#if defined(G_IMPLICIT)

float geometric(vec3 n, vec3 h, vec3 v, vec3 l, float roughness) {
    return dot_sat(n, l) * dot_sat(n, v);
}

#elif defined(G_COOK_TORRANCE)

float geometric(vec3 n, vec3 h, vec3 v, vec3 l, float roughness) {
    float ndl = dot_sat(n, l);
    float ndv = dot_sat(n, v);
    float ndh = dot_sat(n, h);
    float vdh = max(abs(dot(v, h)), 1.0e-4); // avoid division by zero
    float g = 2.0 * ndh / vdh;
    return min(min(ndv, ndl) * g, 1.0);
}

#elif defined(G_SCHLICK)

float geometric(vec3 n, vec3 h, vec3 v, vec3 l, float roughness) {
    float ndl = dot_sat(n, l);
    float ndv = dot_sat(n, v);
    float k = roughness * sqrt(2.0);
    float _1_min_k = 1.0 - k;
    return (ndl / (ndl * _1_min_k + k)) * (ndv / (ndv * _1_min_k + k));
}

#elif defined(G_WALTER)

float geometric(vec3 n, vec3 h, vec3 v, vec3 l, float roughness) {
    float ndv = dot_sat(n, v);
    float ndl = dot_sat(n, l);
    float hdv = dot_sat(h, v);
    float hdl = dot_sat(h, l);
    float a = 1.0 / (roughness * tan(acos(ndv)));
    float a_sq = a * a;
    float a_term = 1.0;
    if (a < 1.6) {
        a_term = (3.535 * a + 2.181 * a_sq) / (1.0 + 2.276 * a + 2.577 * a_sq);
    }
    return (step(0.0, hdl / ndl) * a_term) *
    (step(0.0, hdv / ndv) * a_term);
}

#else
#error Geometric term not defined, define G_IMPLICIT, G_COOK_TORRANCE, G_SCHLICK or G_WALTER
#endif
