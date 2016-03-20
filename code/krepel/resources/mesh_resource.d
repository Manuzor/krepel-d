module krepel.resources.resource_mesh;

import krepel.resources;
import krepel.container;
import krepel.math;
import krepel.memory;

class MeshResource : IResource
{
  Array!Vector3 Vertices;
  Array!Vector3 Normals;
  Array!Vector2 TextureCoordinates;
  Array!WaveFrontFaceDefinition Faces;
  this(IAllocator Allocator)
  {
    Vertices = Array!Vector3(Allocator);
    Normals = Array!Vector3(Allocator);
    TextureCoordinates = Array!Vector2(Allocator);
    Faces = Array!WaveFrontFaceDefinition(Allocator);
  }
}
