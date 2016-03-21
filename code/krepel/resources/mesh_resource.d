module krepel.resources.resource_mesh;

import krepel.resources;
import krepel.container;
import krepel.math;
import krepel.memory;

struct Vertex
{
  Vector3 Position;
  Vector2 TextureCoordinate;
  Vector3 Normal;
  Vector4 Tangent;
  Vector3 Binormal;
}

struct SubMesh
{
  Array!Vertex Vertices;
  Array!int Indices;
}

class MeshResource : IResource
{
  Array!SubMesh Meshes;

  this(IAllocator Allocator)
  {
    Meshes = Array!SubMesh(Allocator);
  }
}
