module krepel.physics.shape;

import krepel;

enum ShapeType
{
  Sphere,
  Poly,
  Plane
}

struct HalfEdge
{
  byte NextIndex; //Next Edge Index
  byte TwinIndex; //The Index of the Edge Twin
  byte OriginIndex; // The Vertex Index it belongs to
  byte FaceIndex; // The face Index the Edge belongs to
}

struct PolyShapeData
{
  Array!Vector3 Vertices;
  Array!byte Faces; // Faces as Index of one of the surrounding Edges
  Array!HalfEdge Edges;
  Array!Vector4 Planes; // Planes of the Faces

  void Initialize(IAllocator Allocator)
  {
    Vertices.Allocator = Allocator;
    Faces.Allocator = Allocator;
    Edges.Allocator = Allocator;
    Planes.Allocator = Allocator;
  }
}

struct SphereShapeData
{
  float Radius;
}

struct PlaneShapeData
{
  Vector4 Plane;
}

struct Polygon
{
  Array!Vector3 Vertices; // CCW List of Vertices surrounding the polygon
}

PolyShapeData CreatePolyShapeFromBox(IAllocator Allocator, Vector3 HalfDimensions)
{
  Array!Polygon Polygons;
  Polygons.Allocator = Allocator;

  Polygon CurrentPoly;
  CurrentPoly.Vertices.Allocator = Allocator;

  CurrentPoly.Vertices ~= Vector3(-HalfDimensions.X, -HalfDimensions.Y, -HalfDimensions.Z);
  CurrentPoly.Vertices ~= Vector3(HalfDimensions.X, -HalfDimensions.Y, -HalfDimensions.Z);
  CurrentPoly.Vertices ~= Vector3(HalfDimensions.X, -HalfDimensions.Y, HalfDimensions.Z);
  CurrentPoly.Vertices ~= Vector3(-HalfDimensions.X, -HalfDimensions.Y, HalfDimensions.Z);
  CurrentPoly.Vertices ~= CurrentPoly.Vertices[0];
  Polygons ~= CurrentPoly;
  CurrentPoly.Vertices.Clear();

  CurrentPoly.Vertices ~= Vector3(-HalfDimensions.X, -HalfDimensions.Y, -HalfDimensions.Z);
  CurrentPoly.Vertices ~= Vector3(-HalfDimensions.X, -HalfDimensions.Y, HalfDimensions.Z);
  CurrentPoly.Vertices ~= Vector3(-HalfDimensions.X, HalfDimensions.Y, HalfDimensions.Z);
  CurrentPoly.Vertices ~= Vector3(-HalfDimensions.X, HalfDimensions.Y, -HalfDimensions.Z);
  CurrentPoly.Vertices ~= CurrentPoly.Vertices[0];

  Polygons ~= CurrentPoly;
  CurrentPoly.Vertices.Clear();

  CurrentPoly.Vertices ~= Vector3(-HalfDimensions.X, -HalfDimensions.Y, -HalfDimensions.Z);
  CurrentPoly.Vertices ~= Vector3(-HalfDimensions.X, HalfDimensions.Y, -HalfDimensions.Z);
  CurrentPoly.Vertices ~= Vector3(HalfDimensions.X, HalfDimensions.Y, -HalfDimensions.Z);
  CurrentPoly.Vertices ~= Vector3(HalfDimensions.X, -HalfDimensions.Y, -HalfDimensions.Z);
  CurrentPoly.Vertices ~= CurrentPoly.Vertices[0];

  Polygons ~= CurrentPoly;
  CurrentPoly.Vertices.Clear();

  CurrentPoly.Vertices ~= Vector3(-HalfDimensions.X, HalfDimensions.Y, -HalfDimensions.Z);
  CurrentPoly.Vertices ~= Vector3(-HalfDimensions.X, HalfDimensions.Y, HalfDimensions.Z);
  CurrentPoly.Vertices ~= Vector3(HalfDimensions.X, HalfDimensions.Y, HalfDimensions.Z);
  CurrentPoly.Vertices ~= Vector3(HalfDimensions.X, HalfDimensions.Y, -HalfDimensions.Z);
  CurrentPoly.Vertices ~= CurrentPoly.Vertices[0];

  Polygons ~= CurrentPoly;
  CurrentPoly.Vertices.Clear();

  CurrentPoly.Vertices ~= Vector3(HalfDimensions.X, -HalfDimensions.Y, -HalfDimensions.Z);
  CurrentPoly.Vertices ~= Vector3(HalfDimensions.X, HalfDimensions.Y, -HalfDimensions.Z);
  CurrentPoly.Vertices ~= Vector3(HalfDimensions.X, HalfDimensions.Y, HalfDimensions.Z);
  CurrentPoly.Vertices ~= Vector3(HalfDimensions.X, -HalfDimensions.Y, HalfDimensions.Z);
  CurrentPoly.Vertices ~= CurrentPoly.Vertices[0];

  Polygons ~= CurrentPoly;
  CurrentPoly.Vertices.Clear();

  CurrentPoly.Vertices ~= Vector3(-HalfDimensions.X, -HalfDimensions.Y, HalfDimensions.Z);
  CurrentPoly.Vertices ~= Vector3(HalfDimensions.X, -HalfDimensions.Y, HalfDimensions.Z);
  CurrentPoly.Vertices ~= Vector3(HalfDimensions.X, HalfDimensions.Y, HalfDimensions.Z);
  CurrentPoly.Vertices ~= Vector3(-HalfDimensions.X, HalfDimensions.Y, HalfDimensions.Z);
  CurrentPoly.Vertices ~= CurrentPoly.Vertices[0];

  Polygons ~= CurrentPoly;
  CurrentPoly.Vertices.Clear();
  return CreatePolyShapeFromPolygons(Allocator, Polygons[]);
}

PolyShapeData CreatePolyShapeFromPolygons(IAllocator Allocator, Polygon[] Polys)
{
  PolyShapeData Data;
  Data.Initialize(Allocator);
  assert(Polys.length >= 4); // Simplest Possible Volume is a Tetrahedon
  with(Data)
  {
    foreach(Polygon; Polys)
    {
      Vector3 LastVertex = Polygon.Vertices[0];
      byte LastIndex = cast(byte)Vertices[].CountUntil(LastVertex);
      if (LastIndex < 0)
      {
        LastIndex = cast(byte)Vertices.Count;
        Vertices ~= LastVertex;
      }
      byte FaceIndex = cast(byte)(Faces.Count);
      Faces ~= cast(byte)Edges.Count;
      Vector3 Normal = (Polygon.Vertices[2] - Polygon.Vertices[1]) ^ (Polygon.Vertices[0] - Polygon.Vertices[1]);
      Planes ~= CreatePlaneFromNormalAndPoint(Normal, Polygon.Vertices[0]);
      auto FirstEdgeIndex = cast(byte)Edges.Count;
      foreach(Index, Vertex; Polygon.Vertices[1..$])
      {
        byte CurIndex = cast(byte)Vertices[].CountUntil(Vertex);
        if (CurIndex < 0)
        {
          Vertices ~= Vertex;
          CurIndex = cast(byte)(Vertices.Count - 1);
        }
        HalfEdge NewEdge = void;
        NewEdge.OriginIndex = LastIndex;
        NewEdge.FaceIndex = FaceIndex;
        NewEdge.TwinIndex = -1;
        if(Index > 0)
        {
          Edges[-1].NextIndex = cast(byte)Edges.Count;
        }
        Edges ~= NewEdge;
        LastIndex = CurIndex;
      }
      Edges[-1].NextIndex = FirstEdgeIndex;
    }

    // Find twins
    foreach(Index, Edge; Edges)
    {
      Vector3 FirstDirection = Vertices[Edges[Edge.NextIndex].OriginIndex] - Vertices[Edge.OriginIndex];
      if(Edge.TwinIndex != -1)
      {
        auto TwinIndex = Edges[Index+1..$].CountUntil!( (ref HalfEdge TwinEdge)
          {
            Vector3 SecondDirection = Vertices[TwinEdge.OriginIndex] - Vertices[Edges[Edge.NextIndex].OriginIndex];
            return NearlyEquals(FirstDirection, SecondDirection);
          });
        assert(TwinIndex >= 0);
        Edge.TwinIndex = cast(byte)TwinIndex;
        Edges[TwinIndex].TwinIndex = cast(byte)Index;
      }
    }
  }
  return Data;
}

void SetPoly(PhysicsShape Shape, ref PolyShapeData Data)
{
  Shape.Type = ShapeType.Poly;
  Shape.Poly = Data;
}

void SetSphere(PhysicsShape Shape, ref SphereShapeData Data)
{
  Shape.Type = ShapeType.Sphere;
  Shape.Sphere = Data;
}

void SetPlane(PhysicsShape Shape, ref PlaneShapeData Data)
{
  Shape.Type = ShapeType.Plane;

  Shape.Plane = Data;
}

class PhysicsShape
{
  ShapeType Type;
  union
  {
    SphereShapeData Sphere;
    PlaneShapeData Plane;
  }
  PolyShapeData Poly;

}
