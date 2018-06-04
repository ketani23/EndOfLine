#ifndef BRDF_MICROFACET_GLSL
#define BRDF_MICROFACET_GLSL

#include "geometric.glsl"
#include "distribution.glsl"
#include "fresnel.glsl"

vec3 diffuseEnergyRatio(vec3 f0) {
    return vec3(1.0) - f0;
}

// Microfacet BRDF:
//          D * F * G
// ---------------------------
//  4 * (N dot V) * (N dot L)
vec3 brdf(vec3 n, vec3 l, vec3 v, float roughness,
          vec3 diffuse, vec3 specular, vec3 lighting)
{
    float eps = 1.0e-4; // avoid division by zero
    vec3 h = normalize(l + v);
    // compute dot products
    float ndl = dot_sat(n, l);
    float ndv = dot_sat(n, v);
    float vdh = dot_sat(v, h);
    // geometric term
    float G = geometric(n, h, v, l, roughness);
    // normal distribution
    float D = distribution(n, h, roughness);
    // diffuse and specular Fresnel term
    vec3 F_diff = fresnelSchlick(specular, ndl);
    vec3 F_spec = fresnelSchlick(specular, vdh);
    // lambertian BRDF
    vec3 brdf_diff = diffuse * diffuseEnergyRatio(F_diff);
    // specular BRDF
    vec3 brdf_spec = F_spec * G * D / (4.0 * ndl * ndv + eps);
    // final combine
    return ndl * lighting * (brdf_diff + brdf_spec);
}

#endif // BRDF_MICROFACET_GLSL
