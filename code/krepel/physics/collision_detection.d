module krepel.physics.collision_detection;

import krepel;
import krepel.physics.rigid_body;
import krepel.physics.shape;

class CollisionDetection
{
  static bool DoesCollide(RigidBody Body1, RigidBody Body2)
  {
    final switch(Body1.Shape.Type)
    {
      case ShapeType.Sphere:
        return DoesCollideSphereAny(Body1, Body2);
      case ShapeType.Box:
        return DoesCollideBoxAny(Body1, Body2);
      case ShapeType.Plane:
        return DoesCollidePlaneAny(Body1, Body2);
    }
  }

  static bool DoesCollideSphereAny(RigidBody Sphere, RigidBody Body2)
  {
    final switch(Body2.Shape.Type)
    {
      case ShapeType.Sphere:
        return DoesCollideSphereSphere(Sphere, Body2);
      case ShapeType.Box:
        return DoesCollideSphereBox(Sphere, Body2);
      case ShapeType.Plane:
        return DoesCollideSpherePlane(Sphere, Body2);
    }
  }

  static bool DoesCollideBoxAny(RigidBody Box, RigidBody Body2)
  {
    final switch(Body2.Shape.Type)
    {
      case ShapeType.Sphere:
        return DoesCollideSphereBox(Body2, Box);
      case ShapeType.Box:
        return DoesCollideBoxBox(Box, Body2);
      case ShapeType.Plane:
        return DoesCollideBoxPlane(Box, Body2);
    }
  }

  static bool DoesCollidePlaneAny(RigidBody Plane, RigidBody Body2)
  {
    final switch(Body2.Shape.Type)
    {
      case ShapeType.Sphere:
        return DoesCollideSpherePlane(Body2, Plane);
      case ShapeType.Box:
        return DoesCollideBoxPlane(Body2, Plane);
      case ShapeType.Plane:
        return DoesCollidePlanePlane(Plane, Body2);
    }
  }

  static bool DoesCollideSphereBox(RigidBody Sphere, RigidBody Box)
  {
    return false;
  }

  static bool DoesCollideSpherePlane(RigidBody Sphere, RigidBody Plane)
  {
    Vector3 SphereWorldPosition = Sphere.Owner.GetWorldTransform.Translation;
    const float Distance = Abs((SphereWorldPosition | Plane.Shape.Plane.Plane.XYZ) + Plane.Shape.Plane.Plane.W)/Plane.Shape.Plane.Plane.XYZ.Length;
    return Distance < Sphere.Shape.Sphere.Radius;
  }

  static bool DoesCollideSphereSphere(RigidBody Sphere, RigidBody Plane)
  {
    return false;
  }

  static bool DoesCollideBoxPlane(RigidBody Sphere, RigidBody Plane)
  {
    return false;
  }

  static bool DoesCollideBoxBox(RigidBody Sphere, RigidBody Plane)
  {
    return false;
  }

  static bool DoesCollidePlanePlane(RigidBody Sphere, RigidBody Plane)
  {
    return false;
  }
}
