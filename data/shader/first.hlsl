cbuffer Camera
{
  matrix MVP;
};

struct VSOut
{
  float4 Pos : SV_POSITION;
  float2 UV : UV;
};
//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
VSOut VSMain( float3 Pos : POSITION, float2 UV : UV )
{
  VSOut Output;
  Output.Pos = mul(float4(Pos, 1.0f), MVP);
  Output.UV = UV;
  return Output;
}


//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
float4 PSMain( VSOut Input ) : SV_Target
{
    return float4( Input.UV, 0.0f, 1.0f );
}
