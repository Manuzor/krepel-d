module krepel.physics.system;

import krepel;
import krepel.engine;
import krepel.game_framework;
import krepel.physics.rigid_body;
import krepel.physics.collision_detection;

class PhysicsSystem : Subsystem
{
  Array!RigidBody RigidBodies;
  IAllocator Allocator;

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

  override void Tick(TickData Tick)
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

          }
        }
      }
    }
  }
}
