#ifndef UNIVERSAL_GBUFFERUTIL_INCLUDED
#define UNIVERSAL_GBUFFERUTIL_INCLUDED


#include "Surface.hlsl"
#include "Lighting.hlsl"

struct GBufferOutput
{
    float4 GT0 : SV_Target0;
    float4 GT1 : SV_Target1;
    float4 GT2 : SV_Target2;
    float4 GT3 : SV_Target3;
};

TEXTURE2D(_GT0);
TEXTURE2D(_GT1);
TEXTURE2D(_GT2);
TEXTURE2D(_GT3);
TEXTURE2D(_gdepth);
SAMPLER(sampler_gdepth);
SAMPLER(sampler_GT0);
SAMPLER(sampler_GT1);
SAMPLER(sampler_GT2);
SAMPLER(sampler_GT3);

float4x4 _vpMatrix;
float4x4 _vpMatrixInv;

GBufferOutput SurfaceToGbuffer(Surface surfaceData)
{
    GBufferOutput output;
    float3 color = surfaceData.color;
    float3 emission = surfaceData.emission;
    float3 normal = surfaceData.normal;
    float metallic = surfaceData.metallic;
    float roughness = surfaceData.smoothness;
    float ao = surfaceData.occlusion;
    output.GT0 = float4(color, 1);
    output.GT1 = float4(normal * 0.5 + 0.5, 0);
    output.GT2 = float4(0, 0, roughness, metallic);
    output.GT3 = float4(emission, ao);
    return output;
}

Surface SurfaceFromGbuffer(float2 uv)
{
    float4 GT2 = SAMPLE_TEXTURE2D(_GT2, sampler_GT2, uv);
    float4 GT3 = SAMPLE_TEXTURE2D(_GT3, sampler_GT3, uv);

    float3 albedo = SAMPLE_TEXTURE2D(_GT0, sampler_GT0, uv).rgb;
    float3 normal = SAMPLE_TEXTURE2D(_GT1, sampler_GT1, uv).rgb * 2 - 1;
    float2 motionVec = GT2.rg;
    float roughness = GT2.b;
    float metallic = GT2.a;
    float3 emission = GT3.rgb;
    float occlusion = GT3.a;
    
    float d = SAMPLE_DEPTH_TEXTURE(_gdepth, sampler_gdepth, uv);
    float linearDepth = Linear01Depth(d, _ZBufferParams);

    float4 ndcPos = float4(uv * 2 - 1, d, 1);
    float4 worldPos = mul(_vpMatrixInv, ndcPos);
    worldPos /= worldPos.w;

    Surface surface;
    surface.position = worldPos;
    surface.normal = normalize(normal);
    surface.viewDirection = normalize(_WorldSpaceCameraPos.xyz - worldPos.xyz);
    surface.emission = emission;
    surface.occlusion = occlusion;
    surface.depth = d;
    surface.color = albedo;
    surface.alpha = 1;
    surface.metallic = metallic;
    surface.smoothness = roughness;
    surface.dither = 0;
    return surface;
}

#endif
