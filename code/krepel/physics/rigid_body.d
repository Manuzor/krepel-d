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
  Vector3 Velocity = Vector3.ZeroVector;
  float Restitution = 1.0f;
  float Damping = 0.999f;
  Vector3 AngularVelocity;
  Vector3 PendingAcceleration;
  Vector3 Torque;
  Matrix3 InertiaTensor = Matrix3.Identity;

  @property bool Movable() const
  {
    return BodyMovability == Movability.Dynamic;
  }

  this(IAllocator Allocator, PhysicsComponent Owner)
  {
    this.Owner = Owner;
    Shape = Allocator.New!PhysicsShape();
  }

  void SetBoxInertiaTensor(Vector3 BoxHalfDimension)
  {
    BoxHalfDimension *= 2.0f; //Full Dimensions
    InertiaTensor = Matrix3([
      [BoxHalfDimension.Z * BoxHalfDimension.Z + BoxHalfDimension.Y * BoxHalfDimension.Y,0,0],
      [0,BoxHalfDimension.X * BoxHalfDimension.X + BoxHalfDimension.Y * BoxHalfDimension.Y,0],
      [0,0,BoxHalfDimension.X * BoxHalfDimension.X + BoxHalfDimension.Z * BoxHalfDimension.Z]]) * ((1.0f/12.0f)*Mass);
  }

  void ApplyForceWorld(Vector3 Force, Vector3 Position)
  {
    //PendingAcceleration += Force / Mass;
    Torque += (Force ^ (Position - Owner.GetWorldTransform.Translation));
  }

  void ApplyForceCenter(Vector3 Force)
  {
    PendingAcceleration += Force / Mass;
  }

  ~this()
  {
    Allocator.Delete(Shape);
  }


}
