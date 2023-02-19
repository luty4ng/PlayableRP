﻿using UnityEngine;
using UnityEngine.Rendering;

public class PlayableRP : RenderPipeline {

	ForwardRenderer renderer = new ForwardRenderer();

	bool useDynamicBatching, useGPUInstancing;

	ShadowSettings shadowSettings;

	public PlayableRP (
		bool useDynamicBatching, bool useGPUInstancing, bool useSRPBatcher,
		ShadowSettings shadowSettings
	) {
		this.shadowSettings = shadowSettings;
		this.useDynamicBatching = useDynamicBatching;
		this.useGPUInstancing = useGPUInstancing;
		GraphicsSettings.useScriptableRenderPipelineBatching = useSRPBatcher;
		GraphicsSettings.lightsUseLinearIntensity = true;
	}

	protected override void Render (
		ScriptableRenderContext context, Camera[] cameras
	) {
		foreach (Camera camera in cameras) {
			renderer.Render(
				context, camera, useDynamicBatching, useGPUInstancing,
				shadowSettings
			);
		}
	}
}