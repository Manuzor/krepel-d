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
          //Body.Velocity += DeltaGravity;
          //Body.Owner.MoveWorld(Body.Velocity * Tick.ElapsedTime);
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
              Vector3 ResolvanceVector = CollisionResult.PenetrationDepth * CollisionResult.CollisionNormal.SafeNormalizedCopy;
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
              Body1ResolvanceFactor *= 1.1f;
              Body2ResolvanceFactor *= 1.1f;
              //Body1.Velocity = Body1.Velocity.ReflectVector(ResolvanceVector.SafeNormalizedCopy) * //Body1.Restitution;
              //Body2.Velocity = Body2.Velocity.ReflectVector(ResolvanceVector.SafeNormalizedCopy) * //Body2.Restitution;
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

            if (Body1.Shape.Type == ShapeType.Poly)
            {
              GlobalEngine.DebugHelper.AddPolyShape(Body1.Owner.GetWorldTransform, Body1.Shape.Poly, DebugColor);
            }
            if (Body2.Shape.Type == ShapeType.Poly)
            {
              GlobalEngine.DebugHelper.AddPolyShape(Body2.Owner.GetWorldTransform, Body2.Shape.Poly, DebugColor );
            }

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
