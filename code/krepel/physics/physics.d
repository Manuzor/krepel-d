module krepel.physics.system;

import krepel;
import krepel.engine;
import krepel.game_framework;
import krepel.physics;
import krepel.input;

class PhysicsSystem : Subsystem
{
  Array!RigidBody RigidBodies;
  IAllocator Allocator;
  Engine ParentEngine;
  Vector3 Gravity = Vector3(0,0,-9.81f);

  this(IAllocator Allocator)
  {
    this.Allocator = Allocator;
    RigidBodies.Allocator = Allocator;
  }

  void RegisterRigidBody(RigidBody Body)
  {
    RigidBodies ~= Body;
  }

  void UnregisterRigidBody(RigidBody Body)
  {
    auto Position = RigidBodies[].CountUntil(Body);
    if (Position >= 0)
    {
      RigidBodies.RemoveAtSwap(Position);
    }
  }

  override void Initialize(Engine ParentEngine)
  {
    this.ParentEngine = ParentEngine;
    ParentEngine.InputContexts[0].RegisterInputSlot(InputType.Button, "Resolve");
    ParentEngine.InputContexts[0].AddSlotMapping(Keyboard.Space, "Resolve");
  }

  override void Destroy()
  {

  }
  bool WasUp = false;

  Quaternion MakeQuaternionFromAngularVelocity(Vector3 AngularVelocity)
  {
    return Matrix3([
      [1, -AngularVelocity.Z, AngularVelocity.Y],
      [AngularVelocity.Z, 1, -AngularVelocity.X],
      [-AngularVelocity.Y, AngularVelocity.X, 1]]).ToQuaternion;
  }

  Quaternion ApplyAngularVelocity(Matrix3 RotationMatrix, Quaternion AngularVelocity)
  {
    return Matrix3(AngularVelocity.TransformDirection(RotationMatrix.GetScaledAxis(EAxisType.X)),
    AngularVelocity.TransformDirection(RotationMatrix.GetScaledAxis(EAxisType.Y)),
    AngularVelocity.TransformDirection(RotationMatrix.GetScaledAxis(EAxisType.Z))
    ).ToQuaternion;
  }

  override void Tick(TickData Tick)
  {
    if ((ParentEngine.InputContexts[0]["Resolve"].ButtonIsDown && WasUp) || true)
    {
      WasUp = false;
      Vector3 DeltaGravity = Gravity * Tick.ElapsedTime;
      foreach(Body; RigidBodies)
      {
        if (Body.BodyMovability == Movability.Dynamic)
        {
          Transform BodyWorldTransform = Body.Owner.GetWorldTransform;
          auto WorldRotationMatrix = BodyWorldTransform.Rotation.ToRotationMatrix();
          Matrix3 InverseWorldInertiaTensor = WorldRotationMatrix * Body.InertiaTensor.SafeInvert * WorldRotationMatrix.GetTransposed;
          //Body.Velocity += DeltaGravity;
          Body.Velocity += Body.PendingAcceleration * Tick.ElapsedTime;
          Body.AngularVelocity += BodyWorldTransform.TransformDirection(Body.Torque) * Tick.ElapsedTime;
          Body.Owner.MoveWorld(Body.Velocity * Tick.ElapsedTime);
          Body.Owner.SetRotation(ApplyAngularVelocity(WorldRotationMatrix, MakeQuaternionFromAngularVelocity(Body.AngularVelocity * Tick.ElapsedTime)).SafeNormalizedCopy);
          Body.Torque = Vector3.ZeroVector;
          Body.PendingAcceleration = Vector3.ZeroVector;
        }
      }
      foreach(Index1, Body1; RigidBodies)
      {
        foreach(Index2, Body2; RigidBodies[Index1+1..$])
        {
          if (Body1.BodyMovability == Movability.Dynamic || Body2.BodyMovability == Movability.Dynamic )
          {
            auto CollisionResult = CollisionDetection.CheckCollision(Body1, Body2);
            if (CollisionResult.DoesCollide)
            {
              Vector3 ResolvanceVector = CollisionResult.PenetrationDepth * CollisionResult.CollisionNormal;
              float Body1ResolvanceFactor = 1.0f;
              float Body2ResolvanceFactor = 0.0f;
              GlobalEngine.DebugHelper.AddLine(CollisionResult.CollisionPoint,CollisionResult.CollisionNormal * CollisionResult.PenetrationDepth, Colors.Blue);
              GlobalEngine.DebugHelper.AddBox(Transform(CollisionResult.CollisionPoint),Vector3.UnitScaleVector * 0.05f, Colors.Blue);
              Log.Info("CollisionPoint: %f %f %f", CollisionResult.CollisionPoint.X,CollisionResult.CollisionPoint.Y,CollisionResult.CollisionPoint.Z);
              if (Body1.BodyMovability == Movability.Dynamic && Body2.BodyMovability.Dynamic)
              {
                Body1ResolvanceFactor = Body1.Mass / (Body1.Mass + Body2.Mass);
                Body2ResolvanceFactor = 1.0f - Body1ResolvanceFactor;
              }
              else if(Body1.BodyMovability == Movability.Static)
              {
                Body1ResolvanceFactor = 0.0f;
                Body2ResolvanceFactor = 1.0f;
              }
              //Body1ResolvanceFactor *= 1.1f;
              //Body2ResolvanceFactor *= 1.1f;
              //Body1.Velocity = Body1.Velocity.ReflectVector(ResolvanceVector.SafeNormalizedCopy) * //Body1.Restitution;
              //Body2.Velocity = Body2.Velocity.ReflectVector(ResolvanceVector.SafeNormalizedCopy) * //Body2.Restitution;
              Vector3 CollisionNormal = CollisionResult.CollisionNormal * Sign(CollisionResult.PenetrationDepth);
              float CollisionResponseFactor = 1.0f;
              float CollisionEpsilon = -(1+CollisionResponseFactor);
              Vector3 Center1ToCollisionPoint = CollisionResult.CollisionPoint - Body1.Owner.GetWorldTransform.Translation;
              Vector3 Center2ToCollisionPoint = CollisionResult.CollisionPoint - Body2.Owner.GetWorldTransform.Translation;
              Vector3 Body1Tangent = Center1ToCollisionPoint ^ CollisionNormal;
              Vector3 Body2Tangent = Center2ToCollisionPoint ^ CollisionNormal;

              float DeltaVelocityToCollisionNormal = Dot((Body1.Velocity - Body2.Velocity),CollisionNormal);
              float AngularVelocity1ToTanget = Dot(Body1.AngularVelocity, Body1Tangent);
              float AngularVelocity2ToTanget = Dot(Body2.AngularVelocity, Body2Tangent);

              float Nominator = CollisionEpsilon * DeltaVelocityToCollisionNormal + AngularVelocity1ToTanget - AngularVelocity2ToTanget;
              Matrix3 InverseInertiaTensor1 = Body1.InertiaTensor.SafeInvert();
              Matrix3 InverseInertiaTensor2 = Body2.InertiaTensor.SafeInvert();
              Vector3 TangentToIntertia1 = InverseInertiaTensor1.TransformDirection(Body1Tangent) ^ Center1ToCollisionPoint;
              Vector3 TangentToIntertia2 = InverseInertiaTensor2.TransformDirection(Body2Tangent) ^ Center2ToCollisionPoint;
              float Denominator = 1/Body1.Mass + 1/Body2.Mass + Dot((TangentToIntertia1 + TangentToIntertia2), CollisionNormal);

              float CollisionResultImpulseFactor = Nominator / Denominator;

              Body1.Velocity += (CollisionResultImpulseFactor / Body1.Mass) * CollisionNormal;
              Body2.Velocity -= (CollisionResultImpulseFactor / Body2.Mass) * CollisionNormal;
              Body1.AngularVelocity += InverseInertiaTensor1.TransformDirection((CollisionResultImpulseFactor * CollisionNormal) ^ Center1ToCollisionPoint);
              Body2.AngularVelocity += InverseInertiaTensor2.TransformDirection((-CollisionResultImpulseFactor * CollisionNormal) ^ Center2ToCollisionPoint);

              //Body1.ApplyForceWorld(CollisionResult.CollisionNormal * Sign(CollisionResult.PenetrationDepth) * Body1ResolvanceFactor, CollisionResult.CollisionPoint);
              //Body2.ApplyForceWorld(-CollisionResult.CollisionNormal * Sign(CollisionResult.PenetrationDepth) * Body2ResolvanceFactor, CollisionResult.CollisionPoint);
              //assert((Body1ResolvanceFactor + Body2ResolvanceFactor).NearlyEquals(1.0f));
              if (Body1.Movable)
              {
                Body1.Owner.MoveWorld(ResolvanceVector * Body2ResolvanceFactor);
              }
              if (Body2.Movable)
              {
                Body2.Owner.MoveWorld(-ResolvanceVector * Body2ResolvanceFactor);
              }
            }
            ColorLinear[1] DebugColor = [CollisionResult.DoesCollide ? Colors.Red : Colors.Lime];

            //if (Body1.Shape.Type == ShapeType.Poly)
            //{
            //  GlobalEngine.DebugHelper.AddPolyShape(Body1.Owner.GetWorldTransform, Body1.Shape.Poly, DebugColor);
            //}
            //if (Body2.Shape.Type == ShapeType.Poly)
            //{
            //  GlobalEngine.DebugHelper.AddPolyShape(Body2.Owner.GetWorldTransform, Body2.Shape.Poly, DebugColor );
            //}

          }
        }
      }
    }
    else if(!ParentEngine.InputContexts[0]["Resolve"].ButtonIsDown)
    {
      WasUp = true;
    }
  }
}
