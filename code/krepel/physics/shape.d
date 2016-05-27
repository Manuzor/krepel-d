module krepel.physics.shape;

import krepel;

enum ShapeType
{
  Sphere,
  Box,
  Plane
}

struct BoxShapeData
{
  Vector3 HalfDimensions;
}

struct SphereShapeData
{
  float Radius;
}

struct PlaneShapeData
{
  Vector4 Plane;
}


void SetBox(PhysicsShape Shape, BoxShapeData Data)
{
  Shape.Type = ShapeType.Box;
  Shape.Box = Data;
}

void SetSphere(PhysicsShape Shape, SphereShapeData Data)
{
  Shape.Type = ShapeType.Sphere;
  Shape.Sphere = Data;
}

void SetPlane(PhysicsShape Shape, PlaneShapeData Data)
{
  Shape.Type = ShapeType.Plane;

  Shape.Plane = Data;
}

class PhysicsShape
{
  ShapeType Type;
  union
  {
    BoxShapeData Box;
    SphereShapeData Sphere;
    PlaneShapeData Plane;
  }

}
