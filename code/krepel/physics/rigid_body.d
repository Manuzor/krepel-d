module krepel.physics.rigid_body;

import krepel;
import krepel.physics.shape;
import krepel.physics.physics_component;

enum Movability
{
  Static,
  Dynamic
}

class RigidBody
{
  Transform Transformation;
  PhysicsShape Shape;
  float Mass = 1.0f;
  PhysicsComponent Owner;
  Movability BodyMovability = Movability.Dynamic;
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
