module krepel.resources.material_resource;

import krepel;
import krepel.resources;

enum ShaderType
{
  VertexShader,
  PixelShader,
  ComputeShader,
  TesselationShader,
  GeometryShader
}

enum ConstantBufferValueType
{
  Matrix4,
  Float1,
  Float2,
  Float3,
  Float4
}

struct ConstantBufferDescription
{
  union
  {
    Matrix4 Matrix;
    float Float1;
    Vector2 Float2;
    Vector3 Float3;
    Vector4 Float4;
  }
  UString RawValue;
  ConstantBufferValueType Type;
}

struct ShaderDefinition
{
  UString ShaderFile;
  UString EntryPoint;
  ShaderType Type;
  ConstantBufferDescription ConstantDescription;
}


class SubMaterial
{
  Array!ShaderDefinition ShaderDefinitions;
  this(IAllocator Allocator)
  {
    ShaderDefinitions.Allocator = Allocator;
  }
}

class MaterialResource : Resource
{
  Array!SubMaterial Materials;

  this(IAllocator Allocator, IResourceLoader Loader, WString FileName)
  {
    super(Loader, FileName);
    Materials = Array!SubMaterial(Allocator);
  }
}
