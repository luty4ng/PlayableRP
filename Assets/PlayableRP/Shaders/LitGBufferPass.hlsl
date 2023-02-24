#ifndef CUSTOM_LIT_GBUFFER_PASS_INCLUDED
#define CUSTOM_LIT_GBUFFER_PASS_INCLUDED

#include "../ShaderLibrary/Surface.hlsl"
#include "../ShaderLibrary/Shadows.hlsl"
#include "../ShaderLibrary/Light.hlsl"
#include "../ShaderLibrary/BRDF.hlsl"
#include "../ShaderLibrary/GI.hlsl"
#include "../ShaderLibrary/Lighting.hlsl"
#include "../ShaderLibrary/UnityGBuffer.hlsl"

struct a2v
{
    float3 positionOS : POSITION;
    float2 uv : TEXCOORD0;
    float3 normalOS : NORMAL;
    // GI_ATTRIBUTE_DATA
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    float4 positionCS : SV_POSITION;
    float3 positionWS : VAR_POSITION;
    float2 uv : VAR_BASE_UV;
    float3 normalWS : VAR_NORMAL;
    // GI_VARYINGS_DATA
    UNITY_VERTEX_INPUT_INSTANCE_ID
};


v2f LitGBufferPassVertex(a2v input)
{
    v2f output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    // TRANSFER_GI_DATA(input, output);

    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    output.positionWS = TransformObjectToWorld(input.positionOS);
    output.positionCS = TransformWorldToHClip(output.positionWS);
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.uv = TransformBaseUV(input.uv);
    return output;
}

GBufferOutput LitGBufferPassFragment(v2f input)
{
    UNITY_SETUP_INSTANCE_ID(input);
    float4 base = GetBase(input.uv);
    Surface surface;
    surface.position = input.positionWS;
    surface.normal = normalize(input.normalWS);
    surface.viewDirection = normalize(_WorldSpaceCameraPos - input.positionWS);
    surface.depth = -TransformWorldToView(input.positionWS).z;
    surface.color = base.rgb;
    surface.alpha = base.a;
    surface.metallic = GetMetallic(input.uv);
    surface.smoothness = GetSmoothness(input.uv);
    surface.occlusion = GetOcclusion(input.uv);
    surface.emission = GetEmission(input.uv);
    surface.dither = InterleavedGradientNoise(input.positionCS.xy, 0);
    return SurfaceToGbuffer(surface);
}

#endif
