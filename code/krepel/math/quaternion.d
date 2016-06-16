module krepel.math.quaternion;

import krepel.math.vector3;
import krepel.math.vector4;
import krepel.math.math;
import krepel.math.matrix3;

@safe:

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

Quaternion FindBetweenNormals(Vector3 Normal1, Vector3 Normal2)
{
  float W = 1.0f + Dot(Normal1, Normal2);
  Quaternion Result;

  if (W >= 1e-4f)
  {
    auto Axis = Normal1 ^ Normal2;
    Result = Quaternion(Axis.X, Axis.Y, Axis.Z, W);
  }
  else
  {
    // Normal1 and Normal2 point in opposite directions
    W = 0.0f;
    Result = Abs(Normal1.X) > Abs(Normal1.Y)
        ? Quaternion(-Normal1.Z, 0.0f, Normal1.X, W)
        : Quaternion(0.0f, -Normal1.Z, Normal1.Y, W);
  }

  Result.SafeNormalize();
  return Result;
}

float LengthSquared(Quaternion Quat)
{
  return Quat.X * Quat.X + Quat.Y * Quat.Y + Quat.Z * Quat.Z + Quat.W * Quat.W;
}

float Length(Quaternion Quat)
{
  return Sqrt(LengthSquared(Quat));
}

Matrix3 ToRotationMatrix(Quaternion Quat)
{
  const float X2 = Quat.X + Quat.X;
  const float Y2 = Quat.Y + Quat.Y;
  const float Z2 = Quat.Z + Quat.Z;

  const float XX = Quat.X * X2;
  const float XY = Quat.X * Y2;
  const float XZ = Quat.X * Z2;

  const float YY = Quat.Y * Y2;
  const float YZ = Quat.Y * Z2;
  const float ZZ = Quat.Z * Z2;

  const float WX = Quat.W * X2;
  const float WY = Quat.W * Y2;
  const float WZ = Quat.W * Z2;

  return Matrix3([
    [1.0f - (YY + ZZ), XY + WZ, XZ - WY],
    [XY - WZ, 1.0f - (XX + ZZ), YZ + WX],
    [XZ + WY, YZ - WX, 1.0f - (XX + YY)]
  ]);
}

Vector3 TransformDirection(Quaternion Quat, Vector3 Direction)
{
  const Q = Vector3(Quat.X, Quat.Y, Quat.Z);
  const T = 2.0f * Q.Cross(Direction);
  return Direction + (Quat.W * T) + Q.Cross(T);
}

/// Rotation of the Vector
/// The W component of the vector will be unchanged
Vector4 TransformDirection(Quaternion Quat, Vector4 Direction)
{
  const Q = Vector3(Quat.X, Quat.Y, Quat.Z);
  const T = 2.0f * Q.Cross(Direction.XYZ);
  return Vector4(Direction.XYZ + (Quat.W * T) + Q.Cross(T), Direction.W);
}

/// Inverse Rotation of the Vector, using the Inverse Quaternion of the given one.
/// E.g. if the Quaternion will rotate your Vector on the Z Axis in Clockwise direction, this operation will rotate
/// the given Vector in Counter-Clockwise Direction
Vector3 InverseTransformDirection(Quaternion Quat, Vector3 Direction)
{
  const Q = Vector3(-Quat.X, -Quat.Y, -Quat.Z);
  const T = 2.0f * Q.Cross(Direction);
  return Direction + (Quat.W * T) + Q.Cross(T);
}

/// Inverse Rotation of the Vector, using the Inverse Quaternion of the given one.
/// E.g. if the Quaternion will rotate your Vector on the Z Axis in Clockwise direction, this operation will rotate
/// the given Vector in Counter-Clockwise Direction
/// The W component of the vector will be unchanged
Vector4 InverseTransformDirection(Quaternion Quat, Vector4 Direction)
{
  const Q = Vector3(-Quat.X, -Quat.Y, -Quat.Z);
  const T = 2.0f * Q.Cross(Direction.XYZ);
  return Vector4(Direction.XYZ + (Quat.W * T) + Q.Cross(T), Direction.W);
}

Quaternion SafeNormalizedCopy(Quaternion Quat, float Epsilon = 1e-4f)
{
  Quat.SafeNormalize(Epsilon);
  return Quat;
}

Quaternion UnsafeNormalizedCopy(Quaternion Quat)
{
  Quat.UnsafeNormalize();
  return Quat;
}

bool IsNormalized(Quaternion Quat)
{
  return krepel.math.math.NearlyEquals(LengthSquared(Quat),1);
}

float Angle(Quaternion Quat)
{
  return ACos(Quat.W) * 2;
}

Vector3 Axis(Quaternion Quat)
{
  const float Scale = Sin(Angle(Quat) * 0.5f);
  return Vector3(Quat.Data[0..3]) / Scale;
}

bool NearlyEquals(Quaternion Quat1, Quaternion Quat2, float Epsilon = 1e-4f)
{
  return
    krepel.math.math.NearlyEquals(Quat1.X, Quat2.X, Epsilon) &&
    krepel.math.math.NearlyEquals(Quat1.Y, Quat2.Y, Epsilon) &&
    krepel.math.math.NearlyEquals(Quat1.Z, Quat2.Z, Epsilon) &&
    krepel.math.math.NearlyEquals(Quat1.W, Quat2.W, Epsilon);
}

/// Checks if any of the components of the quaternion is QNaN
bool ContainsNaN(Quaternion Quat)
{
  return
    krepel.math.math.IsNaN(Quat.X) ||
    krepel.math.math.IsNaN(Quat.Y) ||
    krepel.math.math.IsNaN(Quat.Z) ||
    krepel.math.math.IsNaN(Quat.W);
}

/// Creates an inversed Copy of the Quaternion, which will rotate in the opposite direction.
Quaternion InversedCopy(Quaternion Quat)
{
  Quat.Invert();
  return Quat;
}

struct Quaternion
{
  @safe:

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
  /// Params:
  /// Axis = The Vector which we rotate around, needs NOT be normalized
  /// Angle = The amount of rotation in radians
  this(Vector3 Axis, float Angle)
  {
    Axis.SafeNormalize();
    W = Cos(Angle * 0.5f);
    const float Sinus = Sin(Angle * 0.5f);
    X = Sinus * Axis.X;
    Y = Sinus * Axis.Y;
    Z = Sinus * Axis.Z;
  }

  void SafeNormalize(float Epsilon = 1e-4f)
  {
    const float Length = this.Length;
    if (Length > Epsilon)
    {
      X /= Length;
      Y /= Length;
      Z /= Length;
      W /= Length;
    }
    else
    {
      this = this.init;
    }
  }

  void UnsafeNormalize()
  {
    const float Length = this.Length;
    X /= Length;
    Y /= Length;
    Z /= Length;
    W /= Length;
  }

  /// Inverts the quaternion, meaning that it rotates in the opposite direction (using the negative Axis)
  /// This will change the direction of the Axis and not the Angle
  void Invert()
  {
    X *= -1;
    Y *= -1;
    Z *= -1;
  }

  void opOpAssign(string Operator)(Quaternion Quat)
  {
    this.Data[] = this.opBinary!(Operator)(Quat).Data[];
  }

  Quaternion opBinary(string Operator)(Quaternion Quat) const
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
    else
    {
      static assert(false, "No operator " ~ Operator ~ " defined");
    }
  }

  Vector3 opBinary(string Operator : "*")(Vector3 Vec) const
  {
    return TransformDirection(this, Vec);
  }

  __gshared immutable Identity = Quaternion();
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
  Quaternion RotateCCW = Quaternion(Vector3.UpVector, -PI/2);
  Vector3 Result = krepel.math.matrix3.TransformDirection(RotateCCW.ToRotationMatrix(),Vector3(1,0,0));

  assert(krepel.math.vector3.NearlyEquals(Result,Vector3(0,-1,0)));
}

/// Quaternion concatenation
unittest
{
  Quaternion RotateCCW = Quaternion(Vector3.UpVector, -PI/2);

  RotateCCW *= RotateCCW;
  Vector3 Result = krepel.math.matrix3.TransformDirection(RotateCCW.ToRotationMatrix(),Vector3(1,0,0));
  Vector3 Result2 = RotateCCW.TransformDirection(Vector3(1,0,0));
  Vector3 Result3 = RotateCCW * Vector3(1,0,0);

  assert(krepel.math.vector3.NearlyEquals(Result,Vector3(-1,0,0)));
  assert(krepel.math.vector3.NearlyEquals(Result,Result2));
  assert(krepel.math.vector3.NearlyEquals(Result,Result3));
}

/// Inversion
unittest
{
  Quaternion RotateCCW = Quaternion(Vector3.UpVector, -PI/2);
  Quaternion RotateCW = RotateCCW.InversedCopy();
  Vector3 Result = RotateCCW.TransformDirection(Vector3(1,0,0));
  assert(krepel.math.vector3.NearlyEquals(Result, Vector3(0,-1,0)));
  Vector3 Result2 = RotateCW.TransformDirection(Result);
  Vector3 Result3 = RotateCCW.InverseTransformDirection(Result);
  assert(krepel.math.vector3.NearlyEquals(Result2, Vector3(1,0,0)));
  assert(krepel.math.vector3.NearlyEquals(Result2, Result3));
}

/// Inversion Vec4
unittest
{
  Quaternion RotateCCW = Quaternion(Vector3.UpVector, -PI/2);
  Quaternion RotateCW = RotateCCW.InversedCopy();
  Vector4 Result = RotateCCW.TransformDirection(Vector4(1,0,0,5));
  assert(krepel.math.vector4.NearlyEquals(Result, Vector4(0,-1,0,5)));
  Vector4 Result2 = RotateCW.TransformDirection(Result);
  Vector4 Result3 = RotateCCW.InverseTransformDirection(Result);
  assert(krepel.math.vector4.NearlyEquals(Result2, Vector4(1,0,0,5)));
  assert(krepel.math.vector4.NearlyEquals(Result2, Result3));
}

/// Axis angle Creation and Getters
unittest
{
  Quaternion Quat = Quaternion(Vector3(1,2,3), 2);
  assert(krepel.math.math.NearlyEquals(Quat.Angle(),2));
  assert(krepel.math.vector3.NearlyEquals(
    Quat.Axis(),
    krepel.math.vector3.SafeNormalizedCopy(Vector3(1,2,3))));
}

/// Safe Normalization
unittest
{
  Quaternion Quat = Quaternion(1,2,3,4);

  assert(!Quat.IsNormalized);
  Quat.SafeNormalize();
  assert(Quat.IsNormalized);

  Quat = Quaternion(0,0,0,0);
  assert(!Quat.IsNormalized);
  Quat.SafeNormalize();
  assert(Quat.IsNormalized);
  assert(Quat == Quat.Identity);
}

/// Unsafe Normalization NaN Check
unittest
{
  Quaternion Quat = Quaternion(1,2,3,4);

  assert(!Quat.IsNormalized);
  Quat.UnsafeNormalize();
  assert(Quat.IsNormalized);

  Quat = Quaternion(0,0,0,0);
  assert(!Quat.ContainsNaN());
  assert(!Quat.IsNormalized);
  Quat.UnsafeNormalize();
  assert(!Quat.IsNormalized);
  assert(Quat != Quat.Identity);
  assert(Quat.ContainsNaN);
}
