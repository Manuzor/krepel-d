module krepel.math.quaternion;

import krepel.math.vector3;
import krepel.math.math;
import krepel.math.matrix4;

@nogc:
@safe:
nothrow:

Quaternion ConcatenateQuaternion(Quaternion Quat1, Quaternion Quat2)
{
  return Quaternion(
    ((Quat1.W * Quat2.X) + (Quat1.X * Quat2.W) + (Quat1.Y * Quat2.Z) - (Quat1.Z * Quat2.Y)),
    ((Quat1.W * Quat2.Y) + (Quat1.Y * Quat2.W) + (Quat1.Z * Quat2.X) - (Quat1.X * Quat2.Z)),
    ((Quat1.W * Quat2.Z) + (Quat1.Z * Quat2.W) + (Quat1.X * Quat2.Y) - (Quat1.Y * Quat2.X)),
    ((Quat1.W * Quat2.W) - (Quat1.X * Quat2.X) - (Quat1.Y * Quat2.Y) - (Quat1.Z * Quat2.Z))
  );
}

Quaternion ComponentWiseAddition(Quaternion Quat1, Quaternion Quat2)
{
  return Quaternion(
    Quat1.X + Quat2.X,
    Quat1.Y + Quat2.Y,
    Quat1.Z + Quat2.Z,
    Quat1.W + Quat2.W
  );
}

Quaternion ComponentWiseSubtraction(Quaternion Quat1, Quaternion Quat2)
{
  return Quaternion(
    Quat1.X - Quat2.X,
    Quat1.Y - Quat2.Y,
    Quat1.Z - Quat2.Z,
    Quat1.W - Quat2.W
  );
}

Matrix4 ToRotationMatrix(Quaternion Quat)
{
  float XX = Quat.X * Quat.X;
  float YY = Quat.Y * Quat.Y;
  float ZZ = Quat.Z * Quat.Z;
  float WW = Quat.W * Quat.W;
  float XY = 2 * Quat.X * Quat.Y;
  float XZ = 2 * Quat.X * Quat.Z;
  float XW = 2 * Quat.X * Quat.W;
  float YZ = 2 * Quat.Y * Quat.Z;
  float YW = 2 * Quat.Y * Quat.W;
  float ZW = 2 * Quat.Z * Quat.W;

  return Matrix4([
    [WW + XX - YY - ZZ, XY + ZW, XZ - YW, 0.0f],
    [XY - ZW, WW - XX + YY - ZZ, YZ + XW, 0.0f],
    [XZ + YW, YZ - XW, WW - XX - YY + ZZ, 0.0f],
    [0.0f, 0.0f, 0.0f, 1.0f]
  ]);
}

float GetAngle(Quaternion Quat)
{
  return ACos(Quat.W) * 2;
}

Vector3 GetAxis(Quaternion Quat)
{
  float Scale = Sin(GetAngle(Quat) * 0.5f);
  return Vector3(Quat.Data[0..3]) / Scale;
}

struct Quaternion
{
  @nogc:
  @safe:
  nothrow:

  union
  {
    struct{
      float X = 0;
      float Y = 0;
      float Z = 0;
      float W = 1;
    }
    float[4] Data;
  }

  this(float[4] Data)
  {
    this.Data[] = Data[];
  }

  this(float X, float Y, float Z, float W)
  {
    this.X = X;
    this.Y = Y;
    this.Z = Z;
    this.W = W;
  }

  /// Creates a rotation around the given Axis with the given Angle
  // @param Axis The Vector which we rotate around, needs NOT be normalized
  this(Vector3 Axis, float Angle)
  {
    Axis.SafeNormalize();
    W = Cos(Angle * 0.5f);
    float Sinus = Sin(Angle * 0.5f);
    X = Sinus * Axis.X;
    Y = Sinus * Axis.Y;
    Z = Sinus * Axis.Z;
  }

  Quaternion opBinary(string Operator)(Quaternion Quat)
  {
    static if(Operator == "*")
    {
      return ConcatenateQuaternion(this, Quat);
    }
    else static if(Operator == "+")
    {
      return ComponentWiseAddition(this, Quat);
    }
    else static if(Operator == "-")
    {
      return ComponentWiseSubtraction(this, Quat);
    }
  }
}

/// Default Initialization
unittest
{
  Quaternion TestQuat;
  assert(TestQuat.X == 0);
  assert(TestQuat.Y == 0);
  assert(TestQuat.Z == 0);
  assert(TestQuat.W == 1);
}

/// Constructors
unittest
{
  Quaternion TestQuat = Quaternion(1,2,3,4);
  assert(TestQuat.X == 1);
  assert(TestQuat.Y == 2);
  assert(TestQuat.Z == 3);
  assert(TestQuat.W == 4);

  TestQuat = Quaternion([1,2,3,4]);
  assert(TestQuat.X == 1);
  assert(TestQuat.Y == 2);
  assert(TestQuat.Z == 3);
  assert(TestQuat.W == 4);
}

/// From Axis Angle Creation and Rotation Matrix Conversion
unittest
{
  Quaternion RotateCCW = Quaternion(Vector3.UpVector, -3.141529f/2);
  Vector3 Result = RotateCCW.ToRotationMatrix().TransformVector(Vector3(1,0,0));

  assert(Result.NearlyEquals(Vector3(0,-1,0)));
}

/// Quaternion concatenation
unittest
{
  // TODO(Marvin): Unit test quaternion concatenation
}

unittest
{
  Quaternion Quat = Quaternion(Vector3(1,2,3), 2);
  assert(Quat.GetAngle().NearlyEquals(2));
  assert(Quat.GetAxis().NearlyEquals(Vector3(1,2,3).SafeNormalizedCopy()));
}
