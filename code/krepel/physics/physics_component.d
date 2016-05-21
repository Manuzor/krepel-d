module krepel.physics.physics_component;

import krepel;
import krepel.scene;
import krepel.physics.rigid_body;
import krepel.physics.shape;

class PhysicsComponent : SceneComponent
{
  this(IAllocator Allocator, UString Name, GameObject Owner)
  {
    super(Allocator, Name, Owner);
    ComponentBody = Allocator.New!RigidBody(Allocator, this);
  }

  ~this()
  {
    Allocator.Delete(ComponentBody);
  }

  RigidBody ComponentBody;

}
