Shader "Hidden/Playable RP/StencilDeferred"
{
    SubShader
    {
        // Cull Off ZWrite On ZTest Always
        HLSLINCLUDE
        #include "../../ShaderLibrary/Common.hlsl"
        #include "../../ShaderLibrary/Surface.hlsl"
        #include "../../ShaderLibrary/Shadows.hlsl"
        #include "../../ShaderLibrary/Light.hlsl"
        #include "../../ShaderLibrary/BRDF.hlsl"
        #include "../../ShaderLibrary/GI.hlsl"
        #include "../../ShaderLibrary/Lighting.hlsl"
        #include "../../ShaderLibrary/UnityGBuffer.hlsl"
        ENDHLSL

        Name "GBuffer Decode"
        Pass
        {
            HLSLPROGRAM
            #pragma target 3.5
            #pragma shader_feature _CLIPPING
            #pragma shader_feature _RECEIVE_SHADOWS
            #pragma shader_feature _PREMULTIPLY_ALPHA
            #pragma multi_compile _ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7
            #pragma multi_compile _ _CASCADE_BLEND_SOFT _CASCADE_BLEND_DITHER
            #pragma multi_compile_instancing
            #pragma vertex vert
            #pragma fragment frag

            #define MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT 4
            #define MAX_CASCADE_COUNT 4
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                return o;
            }

            half4 frag(v2f i, out float depth : SV_DEPTH) : SV_Target
            {
                Surface surface = SurfaceFromGbuffer(i.uv);
                depth = surface.depth;
                #if defined(_PREMULTIPLY_ALPHA)
                    BRDF brdf = GetBRDF(surface, true);
                #else
                    BRDF brdf = GetBRDF(surface);
                #endif

                GI gi = GetIBL(i.uv, surface);
                float3 color = GetLighting(surface, brdf, gi);
                color += surface.emission;
                return float4(color, surface.alpha);
            }
            ENDHLSL
        }
    }
}

