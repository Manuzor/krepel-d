module krepel.physics.collision_detection;

import krepel;
import krepel.physics.rigid_body;
import krepel.physics.shape;

struct CollisionResult
{
  bool DoesCollide;
  Vector3 CollisionPoint = Vector3.ZeroVector;
  Vector3 CollisionNormal = Vector3.ZeroVector; //Resolvance Vector can be determined by Scaling this vector by PenetrationDepth
  float PenetrationDepth = 0.0f;
  Vector3 SurfaceNormal = Vector3.ZeroVector; // Surface Normal of the other body

  __gshared immutable EmptyResult = CollisionResult();
}

class CollisionDetection
{
  static CollisionResult CheckCollision(RigidBody Body1, RigidBody Body2)
  {
    final switch(Body1.Shape.Type)
    {
      case ShapeType.Sphere:
        return CheckCollisionSphereAny(Body1, Body2);
      case ShapeType.Poly:
        return CheckCollisionPolyAny(Body1, Body2);
      case ShapeType.Plane:
        return CheckCollisionPlaneAny(Body1, Body2);
    }
  }

  static CollisionResult CheckCollisionSphereAny(RigidBody Sphere, RigidBody Body2)
  {
    final switch(Body2.Shape.Type)
    {
      case ShapeType.Sphere:
        return CheckCollisionSphereSphere(Sphere, Body2);
      case ShapeType.Poly:
        return CheckCollisionSpherePoly(Sphere, Body2);
      case ShapeType.Plane:
        return CheckCollisionSpherePlane(Sphere, Body2);
    }
  }

  static CollisionResult CheckCollisionPolyAny(RigidBody Poly, RigidBody Body2)
  {
    final switch(Body2.Shape.Type)
    {
      case ShapeType.Sphere:
        auto Result = CheckCollisionSpherePoly(Body2, Poly);
        FixupCollisionDirection(Result);
        return Result;
      case ShapeType.Poly:
        return CheckCollisionPolyPoly(Poly, Body2);
      case ShapeType.Plane:
        return CheckCollisionPolyPlane(Poly, Body2);
    }
  }

  static CollisionResult CheckCollisionPlaneAny(RigidBody Plane, RigidBody Body2)
  {
    final switch(Body2.Shape.Type)
    {
      case ShapeType.Sphere:
        auto Result = CheckCollisionSpherePlane(Body2, Plane);
        FixupCollisionDirection(Result);
        return Result;
      case ShapeType.Poly:
        auto Result = CheckCollisionPolyPlane(Body2, Plane);
        FixupCollisionDirection(Result);
        return Result;
      case ShapeType.Plane:
        return CheckCollisionPlanePlane(Plane, Body2);
    }
  }

  static CollisionResult CheckCollisionSpherePoly(RigidBody Sphere, RigidBody Poly)
  {
    return CollisionResult.EmptyResult;
  }

  static CollisionResult CheckCollisionSpherePlane(RigidBody Sphere, RigidBody Plane)
  {
    Vector3 SphereWorldPosition = Sphere.Owner.GetWorldTransform.Translation;
    Vector3 PlaneNormal = Plane.Shape.Plane.Plane.XYZ;
    const float Distance = Abs(((SphereWorldPosition | PlaneNormal) + Plane.Shape.Plane.Plane.W))/PlaneNormal.Length;
    CollisionResult Result;
    Result.DoesCollide = Distance < Sphere.Shape.Sphere.Radius;
    if (Result.DoesCollide)
    {
      Result.PenetrationDepth = Sphere.Shape.Sphere.Radius - Distance;
      Result.CollisionNormal = PlaneNormal;
      Result.SurfaceNormal = PlaneNormal;
    }
    return Result;
  }

  static CollisionResult CheckCollisionSphereSphere(RigidBody Sphere1, RigidBody Sphere2)
  {
    float DistanceSquared = (Sphere1.Owner.GetWorldTransform().Translation -
      Sphere2.Owner.GetWorldTransform().Translation).LengthSquared;
    float AddedRadi = Sphere1.Shape.Sphere.Radius + Sphere2.Shape.Sphere.Radius;
    if (DistanceSquared < AddedRadi * AddedRadi)
    {
      CollisionResult Result;
      Result.DoesCollide = true;
      Result.SurfaceNormal = (Sphere2.Owner.GetWorldTransform().Translation -
        Sphere1.Owner.GetWorldTransform().Translation).SafeNormalizedCopy();
      Result.PenetrationDepth = AddedRadi - Sqrt(DistanceSquared);
      Result.CollisionNormal = -Result.SurfaceNormal;
      return Result;
    }
    return CollisionResult.EmptyResult;
  }

  static CollisionResult CheckCollisionPolyPlane(RigidBody Poly, RigidBody Plane)
  {
    return CollisionResult.EmptyResult;
  }

  static CollisionResult CheckCollisionPolyPoly(RigidBody Poly1, RigidBody Poly2)
  {
    return CollisionResult.EmptyResult;
  }

  static CollisionResult CheckCollisionPlanePlane(RigidBody Plane1, RigidBody Plane2)
  {
    return CollisionResult.EmptyResult;
  }

  static void FixupCollisionDirection(ref CollisionResult Result)
  {
    if (Result.DoesCollide)
    {
      Result.CollisionNormal = -Result.CollisionNormal;
    }
  }
}
