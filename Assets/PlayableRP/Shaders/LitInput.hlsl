#ifndef CUSTOM_LIT_INPUT_INCLUDED
#define CUSTOM_LIT_INPUT_INCLUDED

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

float _Use_Normal_Map;
float _Use_Metal_Map;

TEXTURE2D(_MetallicGlossMap);
TEXTURE2D(_EmissionMap);
TEXTURE2D(_OcclusionMap);
TEXTURE2D(_BumpMap);

SAMPLER(sampler_MetallicGlossMap);
SAMPLER(sampler_EmissionMap);
SAMPLER(sampler_OcclusionMap);
SAMPLER(sampler_BumpMap);

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionColor)
UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

float2 TransformBaseUV(float2 uv)
{
    float4 baseST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
    return uv * baseST.xy + baseST.zw;
}

float4 GetBase(float2 uv)
{
    float4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
    float4 color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
    return map * color;
}

float GetCutoff(float2 uv)
{
    return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff);
}

float GetMetallic(float2 uv)
{
    if (_Use_Metal_Map)
    {
        float4 metal = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv);
        return metal.r;
    }
    return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Metallic);
}

float GetSmoothness(float2 uv)
{
    if (_Use_Metal_Map)
    {
        float4 metal = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv);
        return metal.a;
    }
    return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Smoothness);
}

float3 GetEmission(float2 uv)
{
    float4 map = SAMPLE_TEXTURE2D(_EmissionMap, sampler_BaseMap, uv);
    float4 color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _EmissionColor);
    return map.rgb * color.rgb;
}

float GetOcclusion(float2 uv)
{
    float ao = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).a;
    return ao;
}

float3 GetBumpMap(float2 uv)
{
    float3 normal = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv);
    return normal;
}
#endif