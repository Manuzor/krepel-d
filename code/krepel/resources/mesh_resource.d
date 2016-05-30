module krepel.resources.resource_mesh;

import krepel;
import krepel.resources;
import krepel.color;

struct Vertex
{
  Vector3 Position;
  Vector2 TextureCoordinate;
  Vector3 Normal;
  Vector4 Tangent;
  Vector3 Binormal;
  ColorLinear VertexColor;
}

class SubMesh
{
  Array!Vertex Vertices;
  Array!uint Indices;
  UString Name;

  this(IAllocator Allocator)
  {
    Vertices = Array!Vertex(Allocator);
    Indices = Array!uint(Allocator);
  }
}

class MeshResource : Resource
{
  Array!SubMesh Meshes;

  this(IAllocator Allocator, IResourceLoader Loader, WString FileName)
  {
    super(Loader, FileName);
    Meshes = Array!SubMesh(Allocator);
  }
}
