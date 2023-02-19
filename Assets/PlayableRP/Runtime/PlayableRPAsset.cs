using UnityEngine;
using UnityEngine.Rendering;

public enum RenderingMode
{
    Forward,
    Deferred
};
[CreateAssetMenu(menuName = "Rendering/Playable RP")]
public class PlayableRPAsset : RenderPipelineAsset
{
    [SerializeField] bool useDynamicBatching = true, useGPUInstancing = true, useSRPBatcher = true;
    [SerializeField] RenderingMode renderingMode = RenderingMode.Forward;
    [SerializeField] ShadowSettings shadowSettings = default;
    [SerializeField] IBLSettings iBLSettings = default;
    protected override RenderPipeline CreatePipeline()
    {
        return new PlayableRP(useDynamicBatching, useGPUInstancing, useSRPBatcher, renderingMode, shadowSettings, iBLSettings);
    }
}
