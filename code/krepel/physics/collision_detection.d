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
  float MinDistance;
  byte FaceIndex;
  byte MinFaceIndex;
}

struct EdgeQueryResult
{
  float Distance;
  float MinDistance;
  Vector3 MinNormal;
  byte EdgeIndexBody1;
  byte EdgeIndexBody2;
  byte MinEdgeIndexBody1;
  byte MinEdgeIndexBody2;
}

struct EdgeProjectResult
{
  float Distance;
  Vector3 Normal;
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
    Transform WorldPolyTransform = Poly.Owner.GetWorldTransform;
    Vector4 PlaneVector = Plane.Shape.Plane.Plane;
    Vector3 PlaneNormal = PlaneVector.XYZ.SafeNormalizedCopy;
    Vector3 Support1 = WorldPolyTransform.TransformPosition(Poly.Shape.Poly.GetSupport(WorldPolyTransform.InverseTransformDirection(PlaneNormal)));
    Vector3 Support2 = WorldPolyTransform.TransformPosition(Poly.Shape.Poly.GetSupport(WorldPolyTransform.InverseTransformDirection(-PlaneNormal)));
    float Distance1 = PlaneVector.DistancePlaneToPoint(Support1);
    float Distance2 = PlaneVector.DistancePlaneToPoint(Support2);
    CollisionResult Result = CollisionResult.EmptyResult;
    if (Distance1 <= 0 && Distance2 >= 0 || Distance1 >= 0 && Distance2 <= 0)
    {
      Result.DoesCollide = true;
      Result.CollisionNormal = PlaneNormal;
      if (Abs(Distance1) < Abs(Distance2))
      {
        Result.PenetrationDepth = -Distance1;
      }
      else
      {
        Result.PenetrationDepth = -Distance2;
      }
    }

    return Result;
  }

  static CollisionResult CheckCollisionPolyPoly(const(RigidBody) Poly1, const(RigidBody) Poly2)
  {
    FaceQueryResult FaceResult1;
    FaceQuery(FaceResult1, Poly1, Poly2);
    if (FaceResult1.Distance > 0.0f)
    {
      return CollisionResult.EmptyResult;
    }
    FaceQueryResult FaceResult2;
    FaceQuery(FaceResult2, Poly2, Poly1);
    if (FaceResult2.Distance > 0.0f)
    {
      return CollisionResult.EmptyResult;
    }
    EdgeQueryResult EdgeResult;
    QueryEdgeDirections(EdgeResult, Poly1, Poly2);
    if(EdgeResult.Distance > 0.0f)
    {
      return CollisionResult.EmptyResult;
    }
    CollisionResult Collision;
    with(Collision)
    {
      DoesCollide = true;
      auto Poly1Transform = Poly1.Owner.GetWorldTransform();
      auto Poly2Transform = Poly2.Owner.GetWorldTransform();
      if (FaceResult1.MinDistance > FaceResult2.MinDistance && FaceResult1.MinDistance > EdgeResult.MinDistance)
      {
        CollisionNormal = Poly1Transform.ToMatrix.TransformPlane(
          Poly1.Shape.Poly.Planes[FaceResult1.MinFaceIndex]).XYZ;
          CollisionNormal.SafeNormalize();
        PenetrationDepth = FaceResult1.MinDistance;

      }
      else if(FaceResult2.MinDistance > EdgeResult.MinDistance)
      {
        CollisionNormal = Poly2Transform.ToMatrix.TransformPlane(
          Poly2.Shape.Poly.Planes[FaceResult2.MinFaceIndex]).XYZ;
          CollisionNormal.SafeNormalize();
        PenetrationDepth = -FaceResult2.MinDistance;
      }
      else
      {
        CollisionNormal = Poly2Transform.TransformDirection(EdgeResult.MinNormal);
        PenetrationDepth = EdgeResult.MinDistance;
        Vector3 Edge1Start = Poly1Transform.TransformPosition(Poly1.Shape.Poly.GetEdgeOrigin(EdgeResult.MinEdgeIndexBody1));
        Vector3 Edge1End = Poly1Transform.TransformPosition(Poly1.Shape.Poly.GetEdgeEnd(EdgeResult.MinEdgeIndexBody1));
        Vector3 Edge2Start = Poly2Transform.TransformPosition(Poly1.Shape.Poly.GetEdgeOrigin(EdgeResult.MinEdgeIndexBody2));
        Vector3 Edge2End = Poly2Transform.TransformPosition(Poly1.Shape.Poly.GetEdgeEnd(EdgeResult.MinEdgeIndexBody2));
        CollisionPoint = ClosestPointBetweenTwoLines(Edge1Start, Edge1End, Edge2Start, Edge2End);
      }
  }

    return Collision;
  }

  static void FaceQuery(ref FaceQueryResult Result, const(RigidBody) Poly1, const(RigidBody) Poly2)
  {
    // We perform all computations in local space of the second RigidBody
    Transform Transformation = Poly1.Owner.GetWorldTransform * Poly2.Owner.GetWorldTransform.InversedCopy;

    int MaxIndex = -1;
    float MaxSeparation = -float.infinity;
    float MinSeperation = -float.infinity;
    int MinIndex = -1;
    Matrix4 TransformMatrix = Transformation.ToMatrix();
    for ( int Index = 0; Index < Poly1.Shape.Poly.Faces.Count; Index++ )
    {
      Vector4 Plane = TransformMatrix.TransformPlane(Poly1.Shape.Poly.Planes[Index]);

      float Separation = ProjectRigidBodyOntoPlane( Plane, Poly2.Shape.Poly );
      if ( Separation > MaxSeparation )
      {
        MaxIndex = Index;
        MaxSeparation = Separation;
      }
      if(Separation <= 0 && Separation > MinSeperation)
      {
        MinSeperation = Separation;
        MinIndex = Index;
      }
    }

    Result.Distance = MaxSeparation;
    Result.FaceIndex = cast(byte)MaxIndex;
    Result.MinFaceIndex = cast(byte)MinIndex;
    Result.MinDistance = MinSeperation;
  }

  static float ProjectRigidBodyOntoPlane( ref const(Vector4) Plane, ref const(PolyShapeData) RigidBody )
  {
    Vector3 Support = RigidBody.GetSupport( -Plane.XYZ.SafeNormalizedCopy );
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

  static void QueryEdgeDirections( ref EdgeQueryResult Out, ref const (RigidBody) RigidBody1, ref const (RigidBody) RigidBody2 )
  {
    // We perform all computations in local space of the second RigidBody
    Transform Transformation = RigidBody1.Owner.GetWorldTransform * RigidBody2.Owner.GetWorldTransform.InversedCopy;

    // Find axis of minimum penetration
    int MaxIndex1 = -1;
    int MaxIndex2 = -1;
    float MaxSeparation = -float.infinity;
    int MinIndex1 = -1;
    int MinIndex2 = -1;
    float MinSeparation = -float.infinity;

    Vector3 C1 = Transformation.TransformPosition(Vector3.ZeroVector);

    for ( int Index1 = 0; Index1 < RigidBody1.Shape.Poly.Edges.Count; Index1++ )
    {
      const HalfEdge Edge1 = RigidBody1.Shape.Poly.Edges[ Index1 ];
      assert(Edge1.TwinIndex >= 0);
      const HalfEdge Twin1 = RigidBody1.Shape.Poly.Edges[ Edge1.TwinIndex ];

      Vector3 P1 = Transformation.TransformPosition(RigidBody1.Shape.Poly.Vertices[ Edge1.OriginIndex ]);
      Vector3 Q1 = Transformation.TransformPosition(RigidBody1.Shape.Poly.Vertices[ Twin1.OriginIndex ]);
      Vector3 E1 = Q1 - P1;

      Vector3 U1 = Transformation.Rotation * RigidBody1.Shape.Poly.Planes[ Edge1.FaceIndex ].XYZ;
      Vector3 V1 = Transformation.Rotation * RigidBody1.Shape.Poly.Planes[ Twin1.FaceIndex ].XYZ;

      for ( int Index2 = 0; Index2 < RigidBody2.Shape.Poly.Edges.Count; Index2++ )
      {
        const HalfEdge Edge2 = RigidBody2.Shape.Poly.Edges[ Index2 ];
        assert(Edge2.TwinIndex >= 0);

        const HalfEdge Twin2 = RigidBody2.Shape.Poly.Edges[ Edge2.TwinIndex ];

        Vector3 P2 = RigidBody2.Shape.Poly.Vertices[ Edge2.OriginIndex ];
        Vector3 Q2 = RigidBody2.Shape.Poly.Vertices[ Twin2.OriginIndex ];
        Vector3 E2 = Q2 - P2;

        Vector3 U2 = RigidBody2.Shape.Poly.Planes[ Edge2.FaceIndex ].XYZ;
        Vector3 V2 = RigidBody2.Shape.Poly.Planes[ Twin2.FaceIndex ].XYZ;

        if ( IsMinkowskiFace( U1, V1, -E1, -U2, -V2, -E2 ) )
        {
          auto ProjectResult = Project( P1, E1, P2, E2, C1 );
          if ( ProjectResult.Distance > MaxSeparation )
          {
            MaxIndex1 = Index1;
            MaxIndex2 = Index2;
            MaxSeparation = ProjectResult.Distance;
          }
          if(ProjectResult.Distance <= 0 && ProjectResult.Distance > MinSeparation)
          {
            MinSeparation = ProjectResult.Distance;
            MinIndex1 = Index1;
            MinIndex2 = Index2;
            Out.MinNormal = ProjectResult.Normal;
          }
        }
      }
    }

    Out.EdgeIndexBody1 = cast(byte)MaxIndex1;
    Out.EdgeIndexBody2 = cast(byte)MaxIndex2;
    Out.Distance = MaxSeparation;
    Out.MinDistance = MinSeparation;
    Out.MinEdgeIndexBody1 = cast(byte)MinIndex1;
    Out.MinEdgeIndexBody2 = cast(byte)MinIndex2;
    Out.MinNormal = RigidBody2.Owner.GetWorldTransform.TransformDirection(Out.MinNormal).SafeNormalizedCopy;
  }


  //--------------------------------------------------------------------------------------------------
  static EdgeProjectResult Project( Vector3 P1, Vector3 E1, Vector3 P2, Vector3 E2, Vector3 C1 )
  {
    EdgeProjectResult Result;
    // Build search direction
    Vector3 E1_x_E2 = Cross( E1, E2 );

    // Skip near parallel edges: |e1 x e2| = sin(alpha) * |e1| * |e2|
    const float Tolerance = 0.005f;

    float L = Length( E1_x_E2 );
    if ( L < Tolerance * Sqrt( E1.LengthSquared * E2.LengthSquared ) )
    {
      Result.Distance = -float.infinity;
      return Result;
    }

    // Assure consistent normal orientation (here: RigidBody1 . RigidBody2)
    Vector3 N = E1_x_E2 / L;
    if ( Dot ( N, P1 - C1 ) < 0.0f )
    {
      N = -N;
    }
    Result.Normal = N;

    // s = Dot(n, p2) - d = Dot(n, p2) - Dot(n, p1) = Dot(n, p2 - p1)
    Result.Distance = Dot( N, P2 - P1 );
    return Result;
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
