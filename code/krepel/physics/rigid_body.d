module krepel.physics.rigid_body;

import krepel;
import krepel.physics.shape;
import krepel.physics.physics_component;

class RigidBody
{
  Transform Transformation;
  PhysicsShape Shape;
  float Mass = 0.0f;
  PhysicsComponent Owner;
  IAllocator Allocator;

  this(IAllocator Allocator, PhysicsComponent Owner)
  {
    this.Owner = Owner;
    Shape = Allocator.New!PhysicsShape();

  }

  ~this()
  {
    Allocator.Delete(Shape);
  }


}
