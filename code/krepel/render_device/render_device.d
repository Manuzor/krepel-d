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

interface IRenderInputLayoutDescription
{

}

interface IRenderInputLayout
{

}

interface IConstantBuffer
{
  
}

interface IRenderDevice
{

}