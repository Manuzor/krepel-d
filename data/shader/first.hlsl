cbuffer SceneData
{
  matrix Model;
  matrix MVP;
  float4 LightDir;
  float4 Color;
  float4 AmbientColor;
};

struct VSOut
{
  float4 Pos : SV_POSITION;
  float2 UV : UV;
  float3 Normal : NORMAL;
  float4 LightDir : LIGHT_DIRECTION;
  float4 ObjectColor : OBJ_COLOR;
  float4 AmbientColor : AMBIENT_COLOR;
};
//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
VSOut VSMain( float3 Pos : POSITION, float2 UV : UV, float3 Normal : NORMAL )
{
  VSOut Output;
  Output.Pos = mul(float4(Pos, 1.0f), MVP);
  Output.UV = UV;
  Output.Normal = mul(float4(Normal, 0.0f), Model);
  Output.LightDir = LightDir;
  Output.ObjectColor = Color;
  Output.AmbientColor = AmbientColor;
  return Output;
}


//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
float4 PSMain( VSOut Input ) : SV_Target
{
  float3 ReflectionVector = normalize(-reflect(Input.LightDir,Input.Normal));

  float3 Diffuse = clamp(Input.ObjectColor * max(dot(Input.Normal, Input.LightDir),0) * 0.3f, 0.0f, 1.0f);
  float3 Specular = clamp(Input.ObjectColor.xyz * pow(max(dot(ReflectionVector, Input.Normal),0),0.7f), 0.0f, 1.0f);
  return float4(pow(Diffuse + Specular + Input.AmbientColor.xyz, 1/2.2f), 1.0f);
}
