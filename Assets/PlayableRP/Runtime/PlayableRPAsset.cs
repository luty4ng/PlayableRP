using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "Rendering/Playable RP")]
public class PlayableRPAsset : RenderPipelineAsset {

	[SerializeField]
	bool useDynamicBatching = true, useGPUInstancing = true, useSRPBatcher = true;

	[SerializeField]
	ShadowSettings shadows = default;

	protected override RenderPipeline CreatePipeline () {
		return new PlayableRP(
			useDynamicBatching, useGPUInstancing, useSRPBatcher, shadows
		);
	}
}