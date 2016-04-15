module krepel.scnene.primitive_render_component;

import krepel.scene.scene_component;
import krepel.resources;
import krepel.memory;
import krepel.string;
import krepel.scene.game_object;

class PrimitiveRenderComponent : SceneComponent
{

  this(IAllocator Allocator, UString Name, GameObject Owner)
  {
    super(Allocator, Name, Owner);
  }

  void SetMesh(MeshResource Mesh)
  {
    this.Mesh = Mesh;
  }

  MeshResource GetMesh()
  {
    return Mesh;
  }

private:
  MeshResource Mesh;
}
