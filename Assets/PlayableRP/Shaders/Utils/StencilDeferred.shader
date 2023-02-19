Shader "Hidden/Playable RP/StencilDeferred"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
    }
    SubShader
    {
        Cull Off ZWrite On ZTest Always

        Name "GBuffer Decode"
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "../../ShaderLibrary/Common.hlsl"
            #include "../../ShaderLibrary/Surface.hlsl"
            #include "../../ShaderLibrary/Shadows.hlsl"
            #include "../../ShaderLibrary/Light.hlsl"
            #include "../../ShaderLibrary/BRDF.hlsl"
            // #include "../../ShaderLibrary/GI.hlsl"
            #include "../../ShaderLibrary/Lighting.hlsl"
            #include "../../ShaderLibrary/UnityGBuffer.hlsl"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
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

                // GI gi = GetIBL(i.uv, surface);
                // // GI gi = GetGI(GI_FRAGMENT_DATA(i), surface);
                // return float4(brdf.diffuse, 1);
                float3 color = GetLighting(surface, brdf);
                // float3 color = float3(0, 1, 0);
                color += surface.emission;
                return float4(color, surface.alpha);
            }
            ENDHLSL
        }
    }
}

