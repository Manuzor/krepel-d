module krepel.resources.resource_mesh;

import krepel.resources;
import krepel.container;
import krepel.math;
import krepel.memory;
import krepel.string;

struct Vertex
{
  Vector3 Position;
  Vector2 TextureCoordinate;
  Vector3 Normal;
  Vector4 Tangent;
  Vector3 Binormal;
}

class SubMesh
{
  Array!Vertex Vertices;
  Array!int Indices;
  UString Name;

  this(IAllocator Allocator)
  {
    Vertices = Array!Vertex(Allocator);
    Indices = Array!int(Allocator);
  }
}

class MeshResource : IResource
{
  Array!SubMesh Meshes;

  this(IAllocator Allocator)
  {
    Meshes = Array!SubMesh(Allocator);
  }
}
