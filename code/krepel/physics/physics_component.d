module krepel.physics.physics_component;

import krepel;
import krepel.scene;

class PhysicsComponent : SceneComponent
{
  this(IAllocator Allocator, UString Name, GameObject Owner)
  {
    super(Allocator, Name, Owner);
  }
}
