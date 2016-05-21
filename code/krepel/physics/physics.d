module krepel.physics.system;

import krepel;
import krepel.engine;
import krepel.game_framework;
import krepel.physics.rigid_body;
import krepel.physics.collision_detection;
import krepel.input;

class PhysicsSystem : Subsystem
{
  Array!RigidBody RigidBodies;
  IAllocator Allocator;
  Engine ParentEngine;

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

  override void Tick(TickData Tick)
  {
    if (ParentEngine.InputContexts[0]["Resolve"].ButtonIsDown)
    {
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
              Body1.Owner.MoveWorld(ResolvanceVector * Body1ResolvanceFactor);
              Body2.Owner.MoveWorld(-ResolvanceVector * Body2ResolvanceFactor);
            }
          }
        }
      }
    }
  }
}
