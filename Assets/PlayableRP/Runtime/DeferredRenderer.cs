using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public partial class DeferredRenderer
{
    static ShaderTagId
    unlitShaderTagId = new ShaderTagId("SRPDefaultUnlit"),
    litShaderTagId = new ShaderTagId("CustomLit");

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




        context.SetupCameraProperties(camera);
        CommandBuffer cmd = new CommandBuffer();
        cmd.name = "Gbuffer";

        // set render target and global texture
        cmd.SetRenderTarget(gbuffer.gbufferId, gbuffer.gdepth);
        cmd.ClearRenderTarget(true, true, Color.clear);

        cmd.SetGlobalTexture("_gdepth", gbuffer.gdepth);
        for (int i = 0; i < 4; i++)
            cmd.SetGlobalTexture("_GT" + i, gbuffer.gbuffers[i]);

        // rws matrix
        Matrix4x4 viewMatrix = camera.worldToCameraMatrix;
        Matrix4x4 projMatrix = GL.GetGPUProjectionMatrix(camera.projectionMatrix, false);
        Matrix4x4 vpMatrix = projMatrix * viewMatrix;
        Matrix4x4 vpMatrixInv = vpMatrix.inverse;
        cmd.SetGlobalMatrix("_vpMatrix", vpMatrix);
        cmd.SetGlobalMatrix("_vpMatrixInv", vpMatrixInv);

        // ibl maps
        cmd.SetGlobalTexture("_diffuseIBL", diffuseIBL);
        cmd.SetGlobalTexture("_specularIBL", specularIBL);
        cmd.SetGlobalTexture("_brdfLut", brdfLut);

        context.ExecuteCommandBuffer(cmd);
        camera.TryGetCullingParameters(out var cullingParameters);
        cullingResults = context.Cull(ref cullingParameters);

        // config
        ShaderTagId shaderTagId = new ShaderTagId("GBuffer");
        SortingSettings sortingSettings = new SortingSettings(camera);
        var drawingSettings = new DrawingSettings(shaderTagId, new SortingSettings(camera))
        {
            enableDynamicBatching = useDynamicBatching,
            enableInstancing = useGPUInstancing,
        };
        FilteringSettings filteringSettings = FilteringSettings.defaultValue;
        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);

        // cull

        // setup lighting data
        lighting.Setup(context, cullingResults, shadowSettings);
        GBufferPass(context, camera);
        // Setup(cmd);

        context.DrawSkybox(camera);
        DrawUnsupportedShaders();
        DrawGizmos();
        lighting.Cleanup();
        context.Submit();
    }

    void GBufferPass(ScriptableRenderContext context, Camera camera)
    {
        CommandBuffer cmd = new CommandBuffer();
        cmd.name = "GBuffer";
        Material mat = new Material(Shader.Find("Hidden/Playable RP/StencilDeferred"));
        cmd.Blit(gbuffer.gbufferId[0], BuiltinRenderTextureType.CameraTarget, mat);
        context.ExecuteCommandBuffer(cmd);
        context.Submit();
    }

    void ExecuteBuffer(CommandBuffer buffer)
    {
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }

}
