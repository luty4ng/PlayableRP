#ifndef CUSTOM_BRDF_INCLUDED
#define CUSTOM_BRDF_INCLUDED

struct BRDF
{
    float3 diffuse;
    float3 specular;
    float roughness;
};

#define MIN_REFLECTIVITY 0.04

float OneMinusReflectivity(float metallic)
{
    float range = 1.0 - MIN_REFLECTIVITY;
    return range - metallic * range;
}

BRDF GetBRDF(Surface surface, bool applyAlphaToDiffuse = false)
{
    BRDF brdf;
    brdf.specular = lerp(MIN_REFLECTIVITY, surface.color, surface.metallic);
    float oneMinusReflectivity = OneMinusReflectivity(surface.metallic);
    brdf.diffuse = surface.color * oneMinusReflectivity;
    // brdf.diffuse = float3(surface.metallic, surface.metallic, surface.metallic);
    if (applyAlphaToDiffuse)
    {
        brdf.diffuse *= surface.alpha;
    }
    
    float perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(surface.smoothness);
    brdf.roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
    return brdf;
}

float3 FresnelSchlickRoughness(float NoV, float3 f0, float roughness)
{
    float r1 = 1.0f - roughness;
    return f0 + (max(float3(r1, r1, r1), f0) - f0) * pow(1 - NoV, 5.0f);
}

// D
float D_GGX(float NoH, float a)
{
    float a2 = a * a;
    float NoH2 = NoH * NoH;

    float nom = a2;
    float denom = (NoH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return nom / denom;
}

// F
float3 F_Schlick(float Hov, float3 F0)
{
    float m = clamp(1 - Hov, 0, 1);
    float m2 = m * m;
    float m5 = m2 * m2 * m; // pow(m,5)
    return F0 + (1.0 - F0) * m5;
}

// G
float G_Schlick(float NoV, float k)
{
    float nom = NoV;
    float denom = NoV * (1.0 - k) + k;

    return nom / denom;
}

float3 CookTorranceDirectBRDF(Surface surface, BRDF brdf, Light light)
{
    float3 L = light.direction;
    float3 V = surface.viewDirection;
    float3 N = surface.normal;
    float3 H = normalize(L + V);
    float NoL = max(dot(N, L), 0);
    float NoV = max(dot(N, V), 0);
    float NoH = max(dot(N, H), 0);
    float LoH = max(dot(L, H), 0);
    float Hov = max(dot(H, V), 0);

    float alpha = brdf.roughness;
    float k = pow(alpha + 1, 2) / 8;
    float3 f0 = lerp(MIN_REFLECTIVITY, surface.color, surface.metallic);

    // distribution
    float D = D_GGX(NoH, alpha);
    // fresnel
    float F = F_Schlick(Hov, f0);
    // geometry
    float G = G_Schlick(NoV, alpha);

    float3 f_specular = (D * F * G) / (4.0 * NoV * NoL + 0.0001) * PI;
    float3 color = f_specular * brdf.specular + brdf.diffuse;
    return color;
}

// float SpecularStrength(Surface surface, BRDF brdf, Light light)
// {
//     float3 h = SafeNormalize(light.direction + surface.viewDirection);
//     float nh2 = Square(saturate(dot(surface.normal, h)));
//     float lh2 = Square(saturate(dot(light.direction, h)));
//     float r2 = Square(brdf.roughness);
//     float d2 = Square(nh2 * (r2 - 1.0) + 1.00001);
//     float normalization = brdf.roughness * 4.0 + 2.0;
//     return r2 / (d2 * max(0.1, lh2) * normalization);
// }

// float3 DirectBRDF(Surface surface, BRDF brdf, Light light)
// {
//     return SpecularStrength(surface, brdf, light) * brdf.specular + brdf.diffuse;
// }


#endif