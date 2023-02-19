using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

public class PlayableRP : RenderPipeline
{
    bool useDynamicBatching, useGPUInstancing;
    ShadowSettings shadowSettings;
    IBLSettings iBLSettings;
    ForwardRenderer renderer = new ForwardRenderer();
    DeferredRenderer deferredRenderer = new DeferredRenderer();
    RenderingMode renderingMode = RenderingMode.Forward;
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        foreach (Camera camera in cameras)
        {
            if (renderingMode == RenderingMode.Forward)
                renderer.Render(context, camera, useDynamicBatching, useGPUInstancing, shadowSettings);
            else if (renderingMode == RenderingMode.Deferred)
                deferredRenderer.Render(context, camera, useDynamicBatching, useGPUInstancing, shadowSettings);
        }
    }

    public PlayableRP(bool useDynamicBatching, bool useGPUInstancing, bool useSRPBatcher, RenderingMode renderingMode, ShadowSettings shadowSettings, IBLSettings iBLSettings)
    {
        this.useDynamicBatching = useDynamicBatching;
        this.useGPUInstancing = useGPUInstancing;
        this.shadowSettings = shadowSettings;
        this.renderingMode = renderingMode;
        this.iBLSettings = iBLSettings;
        GraphicsSettings.useScriptableRenderPipelineBatching = useSRPBatcher;
        GraphicsSettings.lightsUseLinearIntensity = true;
        deferredRenderer.SetIBL(this.iBLSettings.diffuseIBL, this.iBLSettings.specularIBL, this.iBLSettings.brdfLut);
    }
}
