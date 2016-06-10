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
  PhysicsShape Shape;
  float Mass = 1.0f;
  PhysicsComponent Owner;
  Movability BodyMovability = Movability.Dynamic;
  IAllocator Allocator;

  @property bool Movable() const
  {
    return BodyMovability == Movability.Dynamic;
  }
  Vector3 Velocity = Vector3.ZeroVector;
  float Restitution = 1.0f;

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
