#ifndef CUSTOM_GI_INCLUDED
#define CUSTOM_GI_INCLUDED

#include "BRDF.hlsl"

struct GI
{
    float3 diffuse;
    float3 specular;
};

TEXTURECUBE(_diffuseIBL);
TEXTURECUBE(_specularIBL);
TEXTURE2D(_brdfLut);
SAMPLER(sampler_diffuseIBL);
SAMPLER(sampler_specularIBL);
SAMPLER(sampler_brdfLut);

GI GetIBL(float2 uv, Surface surface)
{
    GI gi;
    float3 N = surface.normal;
    float3 V = surface.viewDirection;
    float3 albedo = surface.color;
    float roughness = 1 - surface.smoothness;
    float metallic = surface.metallic;

    roughness = min(roughness, 0.99);
    float3 H = normalize(N);
    float NoV = max(dot(N, V), 0);
    float HoV = max(dot(H, V), 0);
    float3 R = normalize(reflect(-V, N));

    float3 F0 = lerp(float3(0.04, 0.04, 0.04), albedo, metallic);
    float3 F = FresnelSchlickRoughness(HoV, F0, roughness);
    float3 k_s = F;
    float3 k_d = (1.0 - k_s) * (1.0 - metallic);

    // diffuse
    float3 IBLd = SAMPLE_TEXTURECUBE(_diffuseIBL, sampler_diffuseIBL, N);
    gi.diffuse = k_d * albedo * IBLd;

    // specular
    float rgh = roughness * (1.7 - 0.7 * roughness);
    float lod = 6.0 * rgh;
    float3 IBLs = SAMPLE_TEXTURECUBE_LOD(_specularIBL, sampler_specularIBL, R, lod).rgb;
    float2 brdf = SAMPLE_TEXTURE2D(_brdfLut, sampler_brdfLut, float2(NoV, roughness)).rg;
    gi.specular = IBLs * (F0 * brdf.x + brdf.y);
    return gi;
}

#endif