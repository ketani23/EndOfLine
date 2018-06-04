#include "~/includes/utils.glsl"

#if defined(D_BECKMANN)

float distribution(vec3 n, vec3 h, float roughness) {
    float ndh = dot_sat(n, h);
    float ndh_sq = ndh * ndh;
    float m_sq = roughness * roughness;
    float ndh_sq_m_sq = ndh_sq * m_sq;
    float e = exp((ndh_sq - 1.0) / ndh_sq_m_sq);
    return e / (ndh_sq_m_sq * ndh_sq);
}

#elif defined(D_BLINN)

float distribution(vec3 n, vec3 h, float roughness) {
    float ndh = dot_sat(n, h);
    float m = 2.0 / (roughness * roughness) - 2.0;
    return (m + 2.0) * pow(ndh, m) / (2.0);
}

#else
#error Distribution term not defined, define D_BECKMANN or D_BLINN
#endif
