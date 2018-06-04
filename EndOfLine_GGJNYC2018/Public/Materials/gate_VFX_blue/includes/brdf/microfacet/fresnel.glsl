vec3 fresnelSchlick(vec3 f0, float cosTheta) {
    return f0 + (vec3(1.0) - f0) * pow(1.0 - cosTheta, 5.0);
}
