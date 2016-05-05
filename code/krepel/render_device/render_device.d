module krepel.render_device.render_device;

import krepel.string;

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

}
