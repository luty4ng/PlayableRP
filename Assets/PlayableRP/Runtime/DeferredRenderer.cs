using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public partial class DeferredRenderer
{
    static ShaderTagId
        unlitShaderTagId = new ShaderTagId("SRPDefaultUnlit"),
        litShaderTagId = new ShaderTagId("CustomLit"),
        shadowCasterTagId = new ShaderTagId("ShadowCaster");

    ScriptableRenderContext context;
    Camera camera;
    CullingResults cullingResults;
    Gbuffer gbuffer = new Gbuffer();
    Cubemap diffuseIBL;
    Cubemap specularIBL;
    Texture brdfLut;

    Lighting lighting = new Lighting();

    public void SetIBL(Cubemap diffuse, Cubemap specular, Texture lut)
    {
        diffuseIBL = diffuse;
        specularIBL = specular;
        brdfLut = lut;
    }

    public void Render(ScriptableRenderContext context, Camera camera, bool useDynamicBatching, bool useGPUInstancing, ShadowSettings shadowSettings)
    {
        this.context = context;
        this.camera = camera;
        PrepareForSceneWindow();

        Shader.SetGlobalTexture("_gdepth", gbuffer.gdepth);
        for (int i = 0; i < 4; i++)
            Shader.SetGlobalTexture("_GT" + i, gbuffer.gbuffers[i]);

        // rws matrix
        Matrix4x4 viewMatrix = camera.worldToCameraMatrix;
        Matrix4x4 projMatrix = GL.GetGPUProjectionMatrix(camera.projectionMatrix, false);
        Matrix4x4 vpMatrix = projMatrix * viewMatrix;
        Matrix4x4 vpMatrixInv = vpMatrix.inverse;
        Shader.SetGlobalMatrix("_vpMatrix", vpMatrix);
        Shader.SetGlobalMatrix("_vpMatrixInv", vpMatrixInv);

        // ibl maps
        Shader.SetGlobalTexture("_diffuseIBL", diffuseIBL);
        Shader.SetGlobalTexture("_specularIBL", specularIBL);
        Shader.SetGlobalTexture("_brdfLut", brdfLut);

        if (!Cull(shadowSettings.maxDistance))
        {
            return;
        }

        context.SetupCameraProperties(camera);
        CommandBuffer cmd = new CommandBuffer();
        cmd.name = "GBuffer";

        // set render target and global texture
        cmd.SetRenderTarget(gbuffer.gbufferId, gbuffer.gdepth);
        cmd.ClearRenderTarget(true, true, Color.clear);

        cmd.BeginSample("GBuffer Draw");
        ExecuteBuffer(cmd);

        ShaderTagId shaderTagId = new ShaderTagId("GBuffer");
        SortingSettings sortingSettings = new SortingSettings(camera);
        var drawingSettings = new DrawingSettings(shaderTagId, new SortingSettings(camera))
        {
            enableDynamicBatching = useDynamicBatching,
            enableInstancing = useGPUInstancing,
        };

        FilteringSettings filteringSettings = FilteringSettings.defaultValue;
        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);

        cmd.EndSample("GBuffer Draw");
        ExecuteBuffer(cmd);

        lighting.Setup(context, cullingResults, shadowSettings);

        DrawFromGBuffer(context, camera);


        context.SetupCameraProperties(camera);
        context.DrawSkybox(camera);
        
        DrawUnsupportedShaders();
        DrawGizmos();
        lighting.Cleanup();
        context.Submit();
    }

    void DrawFromGBuffer(ScriptableRenderContext context, Camera camera)
    {
        CommandBuffer cmd = new CommandBuffer();
        cmd.name = "GBuffer Decode";
        Material mat = new Material(Shader.Find("Hidden/Playable RP/StencilDeferred"));
        cmd.Blit(gbuffer.gbufferId[0], BuiltinRenderTextureType.CameraTarget, mat);
        context.ExecuteCommandBuffer(cmd);
        context.Submit();
    }

    void ShadowPass(ScriptableRenderContext context, Camera camera)
    {
        var sortingSettings = new SortingSettings(camera)
        {
            criteria = SortingCriteria.CommonOpaque
        };
        var drawingSettings = new DrawingSettings(shadowCasterTagId, sortingSettings);
        var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);
        context.DrawRenderers(
            cullingResults, ref drawingSettings, ref filteringSettings
        );
    }

    void ExecuteBuffer(CommandBuffer buffer)
    {
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }

    bool Cull(float maxShadowDistance)
    {
        if (camera.TryGetCullingParameters(out ScriptableCullingParameters p))
        {
            p.shadowDistance = Mathf.Min(maxShadowDistance, camera.farClipPlane);
            cullingResults = context.Cull(ref p);
            return true;
        }
        return false;
    }

}
