using UnityEngine;
using UnityEngine.Rendering;

public class Gbuffer
{
    public RenderTexture gdepth;
    public RenderTexture[] gbuffers = new RenderTexture[4];
    public RenderTargetIdentifier[] gbufferId = new RenderTargetIdentifier[4];

    public Gbuffer()
    {
        gdepth = new RenderTexture(Screen.width, Screen.height, 24, RenderTextureFormat.Depth, RenderTextureReadWrite.Linear);
        gbuffers[0] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear); // albedo
        gbuffers[1] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB2101010, RenderTextureReadWrite.Linear); // world normal
        gbuffers[2] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB64, RenderTextureReadWrite.Linear); // motion vector, roughness, metallic
        gbuffers[3] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear); // emission, occlusion

        for (int i = 0; i < 4; i++)
        {
            gbufferId[i] = gbuffers[i];
        }
    }
}