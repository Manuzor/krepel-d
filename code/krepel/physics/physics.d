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
  bool StepMode = false;
  bool DebugDrawPolyShapes = false;
  bool DoCollisionResponse = true;
  bool DoPenetrationResolve = true;
  bool DoApplyFriction = true;
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
    import krepel.system; // Platform interaction
    auto ConfigFile = OpenFile(ParentEngine.EngineAllocator, WString("../data/config/physics.sdl", ParentEngine.EngineAllocator));
    scope(exit) CloseFile(ParentEngine.EngineAllocator, ConfigFile);
    import krepel.serialization.sdlang;
    auto Context = SDLParsingContext("Physics Config", .Log);
    auto Document = ParentEngine.EngineAllocator.New!SDLDocument(ParentEngine.EngineAllocator);

    scope(exit) ParentEngine.EngineAllocator.Delete(Document);
    auto SourceString = ParentEngine.EngineAllocator.NewArray!char(ConfigFile.Size);
    scope(exit) ParentEngine.EngineAllocator.Delete(SourceString);
    auto BytesRead = ConfigFile.Read(SourceString);
    Document.ParseDocumentFromString(cast(string)SourceString, Context);

    auto RootNode = Document.Root;
    auto GravityNode = RootNode.Nodes["Gravity"][0];
    Gravity = Vector3(cast(float)GravityNode.Values[0],cast(float)GravityNode.Values[1],cast(float)GravityNode.Values[2]);
    Log.Info("Gravity is %f %f %f", Gravity.X, Gravity.Y, Gravity.Z);
    StepMode = cast(bool)RootNode.Nodes["StepMode"][0].Values[0];
    DebugDrawPolyShapes = cast(bool)RootNode.Nodes["DebugDrawPolyShapes"][0].Values[0];
    DoCollisionResponse = cast(bool)RootNode.Nodes["DoCollisionResponse"][0].Values[0];
    DoPenetrationResolve = cast(bool)RootNode.Nodes["DoPenetrationResolve"][0].Values[0];
    DoApplyFriction = cast(bool)RootNode.Nodes["DoApplyFriction"][0].Values[0];

  }

  override void Destroy()
  {

  }

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
    bool DoStep = true;

    debug
    {
      DoStep = (ParentEngine.InputContexts[0]["Resolve"].ButtonIsDown);
    }
    if (DoStep || !StepMode)
    {
      ParentEngine.DebugHelper.DataToRender.Clear();
      ParentEngine.DebugHelper.Lines.Mesh.Vertices.Clear();
      Vector3 DeltaGravity = Gravity * Tick.ElapsedTime;
      foreach(Body; RigidBodies)
      {
        if (Body.BodyMovability == Movability.Dynamic)
        {
          Transform BodyWorldTransform = Body.Owner.GetWorldTransform;
          auto WorldRotationMatrix = BodyWorldTransform.Rotation.ToRotationMatrix();
          Matrix3 InverseWorldInertiaTensor = WorldRotationMatrix * Body.InertiaTensor.SafeInvert * WorldRotationMatrix.GetTransposed;
          Body.Velocity += DeltaGravity;
          Body.Velocity += Body.PendingAcceleration * Tick.ElapsedTime;
          Body.AngularVelocity += BodyWorldTransform.TransformDirection(Body.Torque) * Tick.ElapsedTime;
          Body.Owner.MoveWorld(Body.Velocity * Tick.ElapsedTime);
          Body.Owner.SetRotation(ApplyAngularVelocity(WorldRotationMatrix, MakeQuaternionFromAngularVelocity(Body.AngularVelocity * Tick.ElapsedTime)).SafeNormalizedCopy);
          Body.Torque = Vector3.ZeroVector;
          Body.PendingAcceleration = Vector3.ZeroVector;
          Body.Velocity *= Body.Damping;
          Body.AngularVelocity *= Body.Damping;
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
              float CollisionResponseFactor = 0.0f;
              float CollisionEpsilon = -(1+CollisionResponseFactor);
              Vector3 Center1ToCollisionPoint = Vector3.ZeroVector;
              if(Body1.Movable)
              {
                Center1ToCollisionPoint = CollisionResult.CollisionPoint - Body1.Owner.GetWorldTransform.Translation;
              }
              Vector3 Center2ToCollisionPoint = Vector3.ZeroVector;
              if(Body2.Movable)
              {
                Center2ToCollisionPoint = CollisionResult.CollisionPoint - Body2.Owner.GetWorldTransform.Translation;
              }
              Vector3 Body1Tangent = Vector3.ZeroVector;
              if (Body1.Movable)
              {
                Body1Tangent = Center1ToCollisionPoint ^ CollisionNormal;

              }
              Vector3 Body2Tangent = Vector3.ZeroVector;
              if (Body2.Movable)
              {
                  Body2Tangent = Center2ToCollisionPoint ^ CollisionNormal;
              }

              Vector3 DeltaVelocity =(Body1.Velocity - Body2.Velocity);
              float DeltaVelocityToCollisionNormal = Dot(DeltaVelocity,CollisionNormal);


              float AngularVelocity1ToTanget = 0.0f;
              if(Body1.Movable)
              {
                Dot(Body1.AngularVelocity, Body1Tangent);
              }
              float AngularVelocity2ToTanget = 0.0f;
              if (Body2.Movable)
              {
                AngularVelocity2ToTanget = Dot(Body2.AngularVelocity, Body2Tangent);
              }

              float Nominator = CollisionEpsilon * DeltaVelocityToCollisionNormal + AngularVelocity1ToTanget - AngularVelocity2ToTanget;
              Matrix3 InverseInertiaTensor1 = Body1.InertiaTensor.SafeInvert();
              Matrix3 InverseInertiaTensor2 = Body2.InertiaTensor.SafeInvert();
              Vector3 TangentToIntertia1 = InverseInertiaTensor1.TransformDirection(Body1Tangent) ^ Center1ToCollisionPoint;
              Vector3 TangentToIntertia2 = InverseInertiaTensor2.TransformDirection(Body2Tangent) ^ Center2ToCollisionPoint;
              float Denominator = 0;
              if (Body1.Movable)
              {
                Denominator += 1/Body1.Mass;
              }
              if (Body2.Movable)
              {
                Denominator += 1/Body2.Mass;
              }
              Denominator += Dot((TangentToIntertia1 + TangentToIntertia2), CollisionNormal);

              float CollisionResultImpulseFactor = Nominator / Denominator;
              if (DoCollisionResponse)
              {
                Body1.Velocity += (CollisionResultImpulseFactor / Body1.Mass) * CollisionNormal;
                Body2.Velocity -= (CollisionResultImpulseFactor / Body2.Mass) * CollisionNormal;
                Body1.AngularVelocity += InverseInertiaTensor1.TransformDirection((CollisionResultImpulseFactor * CollisionNormal) ^ Center1ToCollisionPoint);
                Body2.AngularVelocity += InverseInertiaTensor2.TransformDirection((-CollisionResultImpulseFactor * CollisionNormal) ^ Center2ToCollisionPoint);
              }
              //Body1.ApplyForceWorld(CollisionResult.CollisionNormal * Sign(CollisionResult.PenetrationDepth) * Body1ResolvanceFactor, CollisionResult.CollisionPoint);
              //Body2.ApplyForceWorld(-CollisionResult.CollisionNormal * Sign(CollisionResult.PenetrationDepth) * Body2ResolvanceFactor, CollisionResult.CollisionPoint);
              //assert((Body1ResolvanceFactor + Body2ResolvanceFactor).NearlyEquals(1.0f));
              if (DoPenetrationResolve)
              {
                if (Body1.Movable)
                {
                  Body1.Owner.MoveWorld(ResolvanceVector * Body2ResolvanceFactor);
                }
                if (Body2.Movable)
                {
                  Body2.Owner.MoveWorld(-ResolvanceVector * Body2ResolvanceFactor);
                }
              }

              Vector3 Tangent = DeltaVelocity - (CollisionNormal * DeltaVelocityToCollisionNormal);
              Tangent.SafeNormalize();
              float FrictionImpulseFactor = 0.0f;
              Denominator = 0.0f;
              if (Body1.Movable)
              {
                Denominator += 1/Body1.Mass;
                Denominator += Dot(Center1ToCollisionPoint ^ InverseInertiaTensor1.TransformDirection(Tangent ^ Center1ToCollisionPoint), Tangent);
              }
              if (Body2.Movable)
              {
                Denominator += 1/Body2.Mass;
                Denominator += Dot(Center2ToCollisionPoint ^ InverseInertiaTensor2.TransformDirection(Tangent ^ Center2ToCollisionPoint), Tangent);
              }
              FrictionImpulseFactor = Dot(DeltaVelocity, Tangent) / Denominator;
              float DynamicFriction = (Body1.DynamicFriction + Body2.DynamicFriction) / 2;
              if (DoApplyFriction)
              {
                GlobalEngine.DebugHelper.AddLine(CollisionResult.CollisionPoint,Tangent, Colors.Red);
                if (FrictionImpulseFactor <= (DynamicFriction*CollisionResultImpulseFactor))
                {
                  Body1.Velocity -= (Abs(FrictionImpulseFactor) / Body1.Mass) * Tangent;
                  Body2.Velocity += (Abs(FrictionImpulseFactor) / Body2.Mass) * Tangent;
                  Body1.AngularVelocity += InverseInertiaTensor1.TransformDirection((-Abs(FrictionImpulseFactor) * Tangent) ^ Center1ToCollisionPoint);
                  Body2.AngularVelocity += InverseInertiaTensor2.TransformDirection((Abs(FrictionImpulseFactor) * Tangent) ^ Center2ToCollisionPoint);
                }
                else
                {
                  Body1.Velocity -= (DynamicFriction* FrictionImpulseFactor / Body1.Mass) * Tangent;
                  Body2.Velocity += (DynamicFriction* FrictionImpulseFactor / Body2.Mass) * Tangent;
                  Body1.AngularVelocity += InverseInertiaTensor1.TransformDirection((DynamicFriction* -FrictionImpulseFactor * Tangent) ^ Center1ToCollisionPoint);
                  Body2.AngularVelocity += InverseInertiaTensor2.TransformDirection((DynamicFriction* FrictionImpulseFactor * Tangent) ^ Center2ToCollisionPoint);
                }
              }
            }
            if(DebugDrawPolyShapes)
            {
              ColorLinear[1] DebugColor = [CollisionResult.DoesCollide ? Colors.Red : Colors.Lime];
              if (Body1.Shape.Type == ShapeType.Poly && Body2.Shape.Type == ShapeType.Poly && CollisionResult.DoesCollide)
              {

                GlobalEngine.DebugHelper.AddPolyShape(Body1.Owner.GetWorldTransform, Body1.Shape.Poly, DebugColor);
                GlobalEngine.DebugHelper.AddPolyShape(Body2.Owner.GetWorldTransform, Body2.Shape.Poly, DebugColor );
              }
            }
          }
        }
      }
    }
  }
}
