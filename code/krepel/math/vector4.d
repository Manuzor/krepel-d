module krepel.math.vector4;

import krepel.math.math;
import krepel.algorithm.comparison;
import krepel.math.vector3;
import krepel.math.vector2;
import std.conv;

@nogc:
@safe:
nothrow:

/// Calculates the Dot Product of the two Vectors
/// Input Vectors will not be modified
float Dot(Vector4 Lhs, Vector4 Rhs)
{
  float Result = Lhs | Rhs;
  return Result;
}

/// Multiplies two Vectors per component returning a new Vector containing
/// (Lhs.X * Rhs.X, Lhs.Y * Rhs.Y, Lhs.Z * Rhs.Z)
/// Input Vectors will not be modified
Vector4 Mul(Vector4 Lhs, Vector4 Rhs)
{
  return Lhs * Rhs;
}

/// Calculates the squared length  of the given Vector, which is the same as the dot product with the same Vector
/// Input Vector will not be modified
float LengthSquared(Vector4 Vec)
{
  return Vec | Vec;
}

/// Calculates the squared length of the X and Y components, ignoring the Z component
/// Input Vector will not be modified
float LengthSquared2D(Vector4 Vec)
{
  return Vec.X * Vec.X + Vec.Y * Vec.Y;
}

/// Calculates the 2D length of the Vector using the square root of the LengthSquared2D
/// Input Vector will not be modified
float Length2D(Vector4 Vec)
{
  return Sqrt(Vec.LengthSquared2D());
}

/// Calculates the 2D length of the Vector using the square root of the LengthSquared
/// Input Vector will not be modified
float Length(Vector4 Vec)
{
  return Sqrt(Vec.LengthSquared());
}

/// Creates a copy of the Vector, which is Normalized in its length (has a length of 1.0)
Vector4 NormalizedCopy(Vector4 Vec)
{
  Vector4 copy = Vec;
  copy.Normalize();
  return copy;
}

/// Projects a given Vector onto a Normal (Normal needs to be Normalized)
/// Returns the Projected Vector, which will be a scaled version of the Vector
/// Input Vectors will not be modified
Vector4 ProjectOntoNormal(Vector4 Vec, Vector4 Normal)
{
  return Normal * (Vec | Normal);
}

/// Projects a given Vector on a plane, which has the given Normal (Normal needs to be Normalized)
/// Returns Vector which resides on the plane spanned by the Normal
/// Input Vector will not be modified
Vector4 ProjectOntoPlane(Vector4 Vec, Vector4 Normal)
{
  return Vec - Vec.ProjectOntoNormal(Normal);
}

/// Reflects a Vector around a Normal (Normal needs to be Normalized)
/// Returns the reflected Vector
/// Input Vectors will not be modified
Vector4 ReflectVector(Vector4 Vec, Vector4 Normal)
{
  return Vec - (2 * (Vec | Normal) * Normal);
}

/// Checks if any component inside the Vector is NaN.
/// Input Vector will not be modified
bool ContainsNaN(Vector4 Vec)
{
  return IsNaN(Vec.X) || IsNaN(Vec.Y) || IsNaN(Vec.Z);
}

/// Checks if two Vectors are nearly equal (are equal with respect to a scaled epsilon)
/// Input Vectors will not be modified
bool NearlyEquals(Vector4 A, Vector4 B, float Epsilon = 1e-4f)
{
  return krepel.math.math.NearlyEquals(A.X, B.X, Epsilon) &&
         krepel.math.math.NearlyEquals(A.Y, B.Y, Epsilon) &&
         krepel.math.math.NearlyEquals(A.Z, B.Z, Epsilon) &&
         krepel.math.math.NearlyEquals(A.W, B.W, Epsilon);
}

/// Returns a Clamped copy of the given Vector
/// The retuned Vector will be of size <= MaxSize
/// Input Vector will not be modified
Vector4 ClampSize(Vector4 Vec, float MaxSize)
{
  Vector4 Normal = Vec.NormalizedCopy();
  return Normal * Min(Vec.Length(), MaxSize);
}

/// Returns a Clamped copy of the X and Y component of the Vector, the Z compnent will be untouched
/// The length of the X and Y component will be <= MaxSize
/// Input Vector will not be modified
Vector4 ClampSize2D(Vector4 Vec, float MaxSize)
{
  Vector4 Clamped = Vec;
  Clamped.Z = 0;
  Clamped.W = 0;
  Clamped.Normalize();
  Clamped *= Min(Vec.Length2D(), MaxSize);
  Clamped.Z = Vec.Z;
  Clamped.W = Vec.W;
  return Clamped;
}

struct Vector4
{
  @safe:
  @nogc:
  nothrow:

  union
  {
    struct
    {
      float X, Y, Z, W;
    }
    float[4] Data;
  }
  this(float Value)
  {
    X = Value;
    Y = Value;
    Z = Value;
    W = Value;
  }

  this(Vector2 Vec, float Z, float W)
  {
    this.Data[0..2] = Vec.Data[];
    this.Z = Z;
    this.W = W;
  }

  this(float X, Vector2 Vec, float W)
  {
    this.Data[1..3] = Vec.Data[];
    this.X = X;
    this.W = W;
  }

  this(float X, float Y, Vector2 Vec)
  {
    this.Data[2..4] = Vec.Data[];
    this.X = X;
    this.Y = Y;
  }

  this(Vector2 Vec1, Vector2 Vec2)
  {
    this.Data[0..2] = Vec1.Data[];
    this.Data[2..4] = Vec2.Data[];
  }

  this(Vector3 Vec, float W)
  {
    this.Data[0..3] = Vec.Data[];
    this.W = W;
  }

  this(float X, Vector3 Vec)
  {
    this.Data[1..4] = Vec.Data[];
    this.X = X;
  }

  this(float X, float Y, float Z, float W)
  {
    this.X = X;
    this.Y = Y;
    this.Z = Z;
    this.W = W;
  }

  /// Normalizes the Vector (Vector will have a length of 1.0)
  void Normalize()
  {
    // Don't return Result to avoid confusion with NormalizedCopy
    // and stress that this operation modifies the Vector on which it is called
    float Length = this.Length();
    this /= Length;
  }

  // Dot product
  float opBinary(string Operator:"|")(Vector4 Rhs)
  {
    return
      X * Rhs.X +
      Y * Rhs.Y +
      Z * Rhs.Z +
      W * Rhs.W;
  }

  Vector4 opOpAssign(string Operator)(float Rhs)
  {
    static if(Operator == "*" || Operator == "/")
    {
      auto Result = mixin("Vector4("~
        "X" ~ Operator ~ "Rhs,"
        "Y" ~ Operator ~ "Rhs,"
        "Z" ~ Operator ~ "Rhs,"
        "W" ~ Operator ~ "Rhs)");
      Data = Result.Data;
      return this;
    }
    else
    {
      static assert(false, "Operator " ~ Operator ~ " not implemented.");
    }
  }

  //const (char)[] ToString() const
  //{
  //  // TODO: More memory friendly (no GC) implementation?
  //  return "{X:"~text(X)~", Y:"~text(Y)~", Z:"~text(Z)~"}";
  //}

  Vector4 opBinary(string Operator)(Vector4 Rhs) inout
  {
    // Addition, subtraction, component wise multiplication
    static if(Operator == "+" || Operator == "-" || Operator == "*")
    {
      return mixin("Vector4("~
        "X" ~ Operator ~ "Rhs.X,"
        "Y" ~ Operator ~ "Rhs.Y,"
        "Z" ~ Operator ~ "Rhs.Z,"
        "W" ~ Operator ~ "Rhs.W)");
    }
    else
    {
      static assert(false, "Operator " ~ Operator ~ " not implemented.");
    }
  }

  Vector4 opBinary(string Operator)(float Rhs) inout
  {
    // Vector scaling
    static if(Operator == "/" || Operator == "*")
    {
      return mixin("Vector4("~
        "X" ~ Operator ~ "Rhs,"
        "Y" ~ Operator ~ "Rhs,"
        "Z" ~ Operator ~ "Rhs,"
        "W" ~ Operator ~ "Rhs)");
    }
    else
    {
      static assert(false, "Operator " ~ Operator ~ " not implemented.");
    }
  }

  Vector4 opBinaryRight(string Operator)(float Rhs) inout
  {
    // Vector scaling
    static if(Operator == "*")
    {
      return mixin("Vector4("~
        "X" ~ Operator ~ "Rhs,"
        "Y" ~ Operator ~ "Rhs,"
        "Z" ~ Operator ~ "Rhs,"
        "W" ~ Operator ~ "Rhs)");
    }
    else
    {
      static assert(false, "Operator " ~ Operator ~ " not implemented.");
    }
  }

  private static bool IsValidSwizzleChar(const char Char)
  {
    return Char == 'X' || Char == 'Y' || Char == 'Z' || Char == 'W' || Char == '0' || Char == '1';
  }

  private static bool IsValidSwizzleString(string String)
  {
    foreach(const char Char; String)
    {
      if(!IsValidSwizzleChar(Char))
      {
        return false;
      }
    }
    return true;
  }

  Vector2 opDispatch(string SwizzleString)() inout
    if(SwizzleString.length == 2 || (SwizzleString.length == 3 && SwizzleString[0] == '_'))
  {
    // Special case for setting X to 0 (_0YZ)
    static if(SwizzleString.length == 3 && SwizzleString[0] == '_' && IsValidSwizzleString(SwizzleString[1..3]))
    {
      return mixin(
        "typeof(return)(" ~ SwizzleString[1] ~","~
        SwizzleString[2] ~")");
    }
    else static if(SwizzleString.length == 2 && IsValidSwizzleString(SwizzleString))
    {
      return mixin(
        "typeof(return)(" ~ SwizzleString[0] ~","~
        SwizzleString[1] ~")");
    }
  }

  Vector3 opDispatch(string SwizzleString)() inout
    if((SwizzleString.length == 3 && SwizzleString[0] != '_') || (SwizzleString.length == 4 && SwizzleString[0] == '_'))
  {
    // Special case for setting X to 0 (_0YZ)
    static if(SwizzleString.length == 4 && SwizzleString[0] == '_' && IsValidSwizzleString(SwizzleString[1..4]))
    {
      return mixin(
        "typeof(return)(" ~ SwizzleString[1] ~","~
        SwizzleString[2] ~","~
        SwizzleString[3] ~")");
    }
    else static if(SwizzleString.length == 3 && IsValidSwizzleString(SwizzleString))
    {
      return mixin(
        "typeof(return)(" ~ SwizzleString[0] ~","~
        SwizzleString[1] ~","~
        SwizzleString[2] ~")");
    }
  }

  Vector4 opDispatch(string SwizzleString)() inout
    if((SwizzleString.length == 4 && SwizzleString[0] != '_') || (SwizzleString.length == 5 && SwizzleString[0] == '_'))
  {
    // Special case for setting X to 0 (_0YZ)
    static if(SwizzleString.length == 5 && SwizzleString[0] == '_' && IsValidSwizzleString(SwizzleString[1..5]))
    {
      return mixin(
        "typeof(return)(" ~ SwizzleString[1] ~","~
        SwizzleString[2] ~","~
        SwizzleString[3] ~","~
        SwizzleString[4] ~")");
    }
    else static if(SwizzleString.length == 4 && IsValidSwizzleString(SwizzleString))
    {
      return mixin(
        "typeof(return)(" ~ SwizzleString[0] ~","~
        SwizzleString[1] ~","~
        SwizzleString[2] ~","~
        SwizzleString[3] ~")");
    }
  }

  Vector4 opUnary(string Operator : "-")() inout
  {
    return typeof(return)(-X, -Y, -Z, -W);
  }

  __gshared immutable ForwardVector   = Vector4(1,0,0,0);
  __gshared immutable RightVector     = Vector4(0,1,0,0);
  __gshared immutable UpVector        = Vector4(0,0,1,0);
  __gshared immutable WeightVector    = Vector4(0,0,0,1);
  __gshared immutable UnitScaleVector = Vector4(1,1,1,1);
  __gshared immutable ZeroVector      = Vector4(0,0,0,0);

  // Initialization test
  unittest
  {
    Vector4 V3 = Vector4(1,2,3,4);
    assert(V3.X == 1);
    assert(V3.Y == 2);
    assert(V3.Z == 3);
    assert(V3.W == 4);
    assert(V3.Data[0] == 1);
    assert(V3.Data[1] == 2);
    assert(V3.Data[2] == 3);
    assert(V3.Data[3] == 4);

    V3 = Vector4(5);
    assert(V3.X == 5);
    assert(V3.Y == 5);
    assert(V3.Z == 5);
    assert(V3.W == 5);
  }

  // Addition test
  unittest
  {
    Vector4 V1 = Vector4(1,2,3,4);
    Vector4 V2 = Vector4(10,11,12,13);
    auto V3 = V1 + V2;
    assert(V3.X == 11);
    assert(V3.Y == 13);
    assert(V3.Z == 15);
    assert(V3.W == 17);
  }

  // Subtraction test
  unittest
  {
    Vector4 V1 = Vector4(1,2,3,4);
    Vector4 V2 = Vector4(10,11,12,13);
    auto V3 = V1 - V2;
    assert(V3.X == -9);
    assert(V3.Y == -9);
    assert(V3.Z == -9);
    assert(V3.W == -9);
  }

  // Float multiplication test
  unittest
  {
    Vector4 V1 = Vector4(1,2,3,4) * 5;
    Vector4 V2 = Vector4(1,2,3,4) * 5.0f;
    assert(V1 == Vector4(5,10,15,20));
    assert(V2 == Vector4(5,10,15,20));

    V1 = 5 * Vector4(1,2,3,4);
    V2 = 5.0f * Vector4(1,2,3,4);
    assert(V1 == Vector4(5,10,15,20));
    assert(V2 == Vector4(5,10,15,20));
  }

  // Float division test
  unittest
  {
    Vector4 V1 = Vector4(5,10,15,20) / 5;
    Vector4 V2 = Vector4(5,10,15,20) / 5.0f;
    assert(V1 == Vector4(1,2,3,4));
    assert(V2 == Vector4(1,2,3,4));

    V1 = Vector4(5,10,15,20);
    V2 = Vector4(5,10,15,20);
    V1 /= 5;
    V2 /= 5.0f;
    assert(V1 == Vector4(1,2,3,4));
    assert(V2 == Vector4(1,2,3,4));
  }

  /// Dot product test
  unittest
  {
    Vector4 V1 = Vector4(1,2,3,4);
    Vector4 V2 = Vector4(10,11,12,13);
    auto V3 = V1 | V2;
    assert(V3 == 10 + 22 + 36 + 52);
    assert(V3 == V1.Dot(V2));
  }

  /// Component wise multiplication test
  unittest
  {
    Vector4 V1 = Vector4(1,2,3,4);
    Vector4 V2 = Vector4(10,11,12,13);
    auto V3 = V1 * V2;
    assert(V3.X == 10);
    assert(V3.Y == 22);
    assert(V3.Z == 36);
    assert(V3.W == 52);
    assert(V3 == V1.Mul(V2));
  }

  /// Normalization
  unittest
  {
    Vector4 Vec = Vector4(1,1,1,1);
    Vec.Normalize();
    float Expected = 1.0f/Sqrt(4);
    assert(Vec == Vector4(Expected, Expected, Expected, Expected));

    Vec = Vector4(1,1,1,1);
    auto Normalized = Vec.NormalizedCopy();
    auto NormalizedUFCS = NormalizedCopy(Vec);
    assert(Vec == Vector4(1,1,1,1));
    assert(Normalized == Vector4(Expected, Expected, Expected, Expected));
    assert(NormalizedUFCS == Vector4(Expected, Expected, Expected, Expected));
  }

  /// Project Onto Normal
  unittest
  {
    Vector4 Normal = Vector4.UpVector;
    Vector4 ToProject = Vector4(1,1,0.5f,0);

    Vector4 Projected = ToProject.ProjectOntoNormal(Normal);

    assert(Projected == Vector4(0,0,0.5f,0));
  }

  /// Project Onto PLane
  unittest
  {
    Vector4 Normal = Vector4.UpVector;
    Vector4 ToProject = Vector4(1,1,0.5f,0);

    Vector4 Projected = ToProject.ProjectOntoPlane(Normal);

    assert(Projected == Vector4(1,1,0,0));
  }

  /// Reflect Vector
  unittest
  {
    Vector4 Normal = Vector4(1,0,0,0);
    Vector4 Reflection = Vector4(-1,0,-1,0);

    Vector4 Reflected = Reflection.ReflectVector(Normal);

    assert(Reflected == Vector4(1,0,-1,0));
  }

  /// NearlyEquals
  unittest
  {
    Vector4 A = Vector4(1,1,0,1);
    Vector4 B = Vector4(1+1e-5f,1,-1e-6f,1);
    Vector4 C = Vector4(1,1,1,10);
    assert(NearlyEquals(A,B));
    assert(!NearlyEquals(A,C));
  }

  /// Clamp Vector4
  unittest
  {
    Vector4 Vec = Vector4(0,0,0,100);
    Vector4 Clamped = Vec.ClampSize(1);
    assert(Vec == Vector4(0,0,0,100));
    assert(Clamped == Vector4(0,0,0,1));
  }

  /// Clamp2D Vector4
  unittest
  {
    Vector4 Vec = Vector4(100,0,1000,2000);
    Vector4 Clamped = Vec.ClampSize2D(1);
    assert(Vec == Vector4(100,0,1000,2000));
    assert(Clamped == Vector4(1,0,1000,2000));
  }

  /// 2D Length
  unittest
  {
    Vector4 Vec = Vector4(0,1,1032094,34857);
    assert(Vec.Length2D() == 1);
    assert(Vec.LengthSquared2D() == 1);
  }

  unittest
  {
    Vector4 Vec = Vector4(1,2,3,4);

    Vector4 Swizzled = Vec.Z0YW;

    assert(Swizzled == Vector4(3,0,2,4));
  }

  unittest
  {
    Vector4 Vec = Vector4(1,2,3,4);

    Vector3 Swizzled = Vec.Z0Y;

    assert(Swizzled == Vector3(3,0,2));
  }

  unittest
  {
    Vector4 Vec = Vector4(1,2,3,4);

    Vector2 Swizzled = Vec.ZY;

    assert(Swizzled == Vector2(3,2));
  }

  // Vector4
  unittest
  {
    assert(Vector4(1, 2, 3, 4).X == 1);
    assert(Vector4(1, 2, 3, 4).Y == 2);
    assert(Vector4(1, 2, 3, 4).Z == 3);
    assert(Vector4(1, 2, 3, 4).W == 4);

    assert(Vector4(Vector2(1, 2), 3, 4).X == 1);
    assert(Vector4(Vector2(1, 2), 3, 4).Y == 2);
    assert(Vector4(Vector2(1, 2), 3, 4).Z == 3);
    assert(Vector4(Vector2(1, 2), 3, 4).W == 4);

    assert(Vector4(1, Vector2(2, 3), 4).X == 1);
    assert(Vector4(1, Vector2(2, 3), 4).Y == 2);
    assert(Vector4(1, Vector2(2, 3), 4).Z == 3);
    assert(Vector4(1, Vector2(2, 3), 4).W == 4);

    assert(Vector4(1, 2, Vector2(3, 4)).X == 1);
    assert(Vector4(1, 2, Vector2(3, 4)).Y == 2);
    assert(Vector4(1, 2, Vector2(3, 4)).Z == 3);
    assert(Vector4(1, 2, Vector2(3, 4)).W == 4);

    assert(Vector4(Vector2(1, 2), Vector2(3, 4)).X == 1);
    assert(Vector4(Vector2(1, 2), Vector2(3, 4)).Y == 2);
    assert(Vector4(Vector2(1, 2), Vector2(3, 4)).Z == 3);
    assert(Vector4(Vector2(1, 2), Vector2(3, 4)).W == 4);

    assert(Vector4(Vector3(1, 2, 3), 4).X == 1);
    assert(Vector4(Vector3(1, 2, 3), 4).Y == 2);
    assert(Vector4(Vector3(1, 2, 3), 4).Z == 3);
    assert(Vector4(Vector3(1, 2, 3), 4).W == 4);

    assert(Vector4(1, Vector3(2, 3, 4)).X == 1);
    assert(Vector4(1, Vector3(2, 3, 4)).Y == 2);
    assert(Vector4(1, Vector3(2, 3, 4)).Z == 3);
    assert(Vector4(1, Vector3(2, 3, 4)).W == 4);
  }

  // Vector4 Swizzle
  unittest
  {
    assert(Vector4(1, 2, 3, 4).ZX   == Vector2(3, 1));
    assert(Vector4(1, 2, 3, 4).XZX  == Vector3(1, 3, 1));
    assert(Vector4(1, 2, 3, 4).WZYX == Vector4(4, 3, 2, 1));
    assert(Vector4(1, 2, 3, 4)._WZYX == Vector4(4, 3, 2, 1));
    assert(Vector4(1, 2, 3, 4)._0ZYX == Vector4(0, 3, 2, 1));

    static assert(!__traits(compiles, Vector4(1, 2, 3, 4).Foo), "Swizzling is only supposed to work with value members of " ~ Vector4.stringof ~ ".");
    static assert(!__traits(compiles, Vector4(1, 2, 3, 4).XXXXX), "Swizzling output dimension is limited to 4.");
  }
}
