module krepel.render_device.render_device;

import krepel;
import krepel.string;
import krepel.resources;


interface IShader
{

}

interface IRenderMesh
{
  uint GetIndexCount();
}

interface IRenderDeviceBuffer
{

}

enum InputDescriptionDataType
{
  Float,
  Int
}

struct RenderInputLayoutDescription
{
  UString SemanticName;
  uint SemanticIndex;
  InputDescriptionDataType DataType;
  uint NumberOfElements;
  bool PerVertexData;
}

enum RenderCullMode
{
  None,
  Back,
  Front
}

enum RenderWindingOrder
{
  ClockWise,
  CounterClockWise
}

enum RenderRasterizationMethod
{
  Solid,
  Wireframe
}

struct RenderRasterizerDescription
{
  RenderCullMode CullMode = RenderCullMode.Back;
  RenderWindingOrder WindingOrder = RenderWindingOrder.CounterClockWise;
  bool EnableDepthCulling = true;
  RenderRasterizationMethod RasterizationMethod = RenderRasterizationMethod.Solid;
}

enum RenderDepthCompareMethod
{
  Never,
  Less,
  Equal,
  LessEqual,
  Greater,
  NotEqual,
  GreaterEqual,
  Always
}

struct RenderDepthStencilDescription
{
  bool EnableDepthTest;
  RenderDepthCompareMethod DepthCompareFunc;
  bool EnableStencil;
}

struct RenderDeviceCreationDescription
{
  RenderDepthStencilDescription DepthStencilDescription;
}

interface IRenderDepthStencilBuffer
{

}

interface IRenderRasterizerState
{

}

interface IRenderInputLayoutDescription
{

}

interface IRenderInputLayout
{

}

interface IRenderConstantBuffer
{

}

interface IRenderDevice
{
  bool InitDevice(RenderDeviceCreationDescription Description);

  IShader LoadVertexShader(WString FileName, UString EntryPoint, UString Profile);
  void SetVertexShader(IShader Shader);
  void ReleaseVertexShader(IShader Shader);

  IRenderInputLayoutDescription CreateInputLayoutDescription(RenderInputLayoutDescription[] Descriptions);
  void DestroyInputLayoutDescription(IRenderInputLayoutDescription Description);
  IRenderInputLayout CreateVertexShaderInputLayoutFromDescription(IShader Shader, IRenderInputLayoutDescription Description);
  void SetInputLayout(IRenderInputLayout Layout);
  void DestroyInputLayout(IRenderInputLayout Layout);

  IRenderDepthStencilBuffer CreateDepthStencilBuffer(RenderDepthStencilDescription Description);
  void ReleaseDepthStencilBuffer(IRenderDepthStencilBuffer Buffer);

  IRenderRasterizerState CreateRasterizerState(RenderRasterizerDescription Description);
  void SetRasterizerState(IRenderRasterizerState State);
  void ReleaseRasterizerState(IRenderRasterizerState State);

  IShader LoadPixelShader(WString FileName, UString EntryPoint, UString Profile);
  void SetPixelShader(IShader Shader);
  void ReleasePixelShader(IShader Shader);

  IRenderConstantBuffer CreateConstantBuffer(void[] Data);
  void SetVertexShaderConstantBuffer(IRenderConstantBuffer Buffer, uint Index);
  void ReleaseConstantBuffer(IRenderConstantBuffer Buffer);

  IRenderMesh CreateRenderMesh(SubMesh Mesh);
  void SetMesh(IRenderMesh Mesh);
  void ReleaseRenderMesh(IRenderMesh Mesh);

  void ClearRenderTarget(Vector4 Color);
  void Draw(uint VertexCount, uint Offset = 0);
  void DrawIndexed(uint VertexCount, uint IndexOffset = 0, uint VertexOffset = 0);
  void Present();
}
