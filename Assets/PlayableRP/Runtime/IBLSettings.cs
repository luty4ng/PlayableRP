using UnityEngine;
using UnityEngine.Rendering;

[System.Serializable]
public class IBLSettings
{
    public Cubemap diffuseIBL;
    public Cubemap specularIBL;
    public Texture brdfLut;
}
