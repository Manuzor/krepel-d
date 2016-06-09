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

struct FaceQueryResult
{
  float Distance;
  byte FaceIndex;
}

struct EdgeQueryResult
{
  float Distance;
  byte EdgeIndexBody1;
  byte EdgeIndexBody2;
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

  static void FaceQuery(ref FaceQueryResult Result, RigidBody Poly1, RigidBody Poly2)
  {
    // We perform all computations in local space of the second RigidBody
    Transform Transformation = Poly2.Owner.GetWorldTransform * Poly1.Owner.GetWorldTransform;

    int MaxIndex = -1;
    float MaxSeparation = -float.infinity;
    Matrix4 TransformMatrix = Transformation.ToMatrix();
    for ( int Index = 0; Index < Poly1.Shape.Poly.Faces.Count; Index++ )
    {
      Vector4 Plane = TransformMatrix.TransformDirection(Poly1.Shape.Poly.Planes[Index]);

      float Separation = ProjectRigidBodyOntoPlane( Plane, Poly2.Shape.Poly );
      if ( Separation > MaxSeparation )
      {
        MaxIndex = Index;
        MaxSeparation = Separation;
      }
    }

    Result.Distance = MaxSeparation;
    Result.FaceIndex = cast(byte)MaxIndex;
  }

  static float ProjectRigidBodyOntoPlane( ref const(Vector4) Plane, ref const(PolyShapeData) RigidBody )
  {
    Vector3 Support = RigidBody.GetSupport( -Plane.XYZ );
    return Plane.DistancePlaneToPoint(Support);
  }

  static bool IsMinkowskiFace( Vector3 A, Vector3 B, Vector3 B_x_A, Vector3 C, Vector3 D, Vector3 D_x_C )
  {
    // Test if arcs AB and CD intersect on the unit sphere
    float CBA = Dot( C, B_x_A );
    float DBA = Dot( D, B_x_A );
    float ADC = Dot( A, D_x_C );
    float BDC = Dot( B, D_x_C );

    return CBA * DBA < 0.0f && ADC * BDC < 0.0f && CBA * BDC > 0.0f;
  }

  static void QueryEdgeDirections( ref EdgeQueryResult Out, ref const(Transform) Transform1, ref const (RigidBody) RigidBody1, ref const (Transform) Transform2, ref const (RigidBody) RigidBody2 )
  {
    // We perform all computations in local space of the second RigidBody
    Transform Transformation = RigidBody1.Owner.GetWorldTransform * RigidBody2.Owner.GetWorldTransform;

    // Find axis of minimum penetration
    int MaxIndex1 = -1;
    int MaxIndex2 = -1;
    float MaxSeparation = -float.infinity;

    for ( int Index1 = 0; Index1 < RigidBody1.Shape.Poly.Edges.Count; Index1++ )
    {
      const HalfEdge Edge1 = RigidBody1.Shape.Poly.Edges[ Index1 ];
      const HalfEdge Twin1 = RigidBody1.Shape.Poly.Edges[ Edge1.TwinIndex ];

      Vector3 P1 = Transformation.TransformPosition(RigidBody1.Shape.Poly.Vertices[ Edge1.OriginIndex ]);
      Vector3 Q1 = Transformation.TransformPosition(RigidBody1.Shape.Poly.Vertices[ Twin1.OriginIndex ]);
      Vector3 E1 = Q1 - P1;

      Vector3 U1 = Transformation.Rotation * RigidBody1.Shape.Poly.Planes[ Edge1.FaceIndex ].XYZ;
      Vector3 V1 = Transformation.Rotation * RigidBody1.Shape.Poly.Planes[ Twin1.FaceIndex ].XYZ;

      for ( int Index2 = 0; Index2 < RigidBody2.Shape.Poly.Edges.Count; Index2++ )
      {
        const HalfEdge Edge2 = RigidBody2.Shape.Poly.Edges[ Index2 ];
        const HalfEdge Twin2 = RigidBody2.Shape.Poly.Edges[ Edge2.TwinIndex ];

        Vector3 P2 = RigidBody2.Shape.Poly.Vertices[ Edge2.OriginIndex ];
        Vector3 Q2 = RigidBody2.Shape.Poly.Vertices[ Twin2.OriginIndex ];
        Vector3 E2 = Q2 - P2;

        Vector3 U2 = RigidBody2.Shape.Poly.Planes[ Edge2.FaceIndex ].XYZ;
        Vector3 V2 = RigidBody2.Shape.Poly.Planes[ Twin2.FaceIndex ].XYZ;

        if ( IsMinkowskiFace( U1, V1, -E1, -U2, -V2, -E2 ) )
        {
          float Separation = Project( P1, E1, P2, E2, Vector3.ZeroVector );
          if ( Separation > MaxSeparation )
          {
            MaxIndex1 = Index1;
            MaxIndex2 = Index2;
            MaxSeparation = Separation;
          }
        }
      }
    }

    Out.EdgeIndexBody1 = cast(byte)MaxIndex1;
    Out.EdgeIndexBody2 = cast(byte)MaxIndex2;
    Out.Distance = MaxSeparation;
  }


  //--------------------------------------------------------------------------------------------------
  static float Project( Vector3 P1, Vector3 E1, Vector3 P2, Vector3 E2, Vector3 C1 )
  {
    // Build search direction
    Vector3 E1_x_E2 = Cross( E1, E2 );

    // Skip near parallel edges: |e1 x e2| = sin(alpha) * |e1| * |e2|
    const float Tolerance = 0.005f;

    float L = Length( E1_x_E2 );
    if ( L < Tolerance * Sqrt( E1.LengthSquared * E2.LengthSquared ) )
    {
      return -float.infinity;
    }

    // Assure consistent normal orientation (here: RigidBody1 . RigidBody2)
    Vector3 N = E1_x_E2 / L;
    if ( Dot ( N, P1 - C1 ) < 0.0f )
    {
      N = -N;
    }

    // s = Dot(n, p2) - d = Dot(n, p2) - Dot(n, p1) = Dot(n, p2 - p1)
    return Dot( N, P2 - P1 );
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
