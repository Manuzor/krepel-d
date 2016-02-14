module krepel.math.vector3;

import krepel.math.math;
import krepel.algorithm.comparison;
import krepel.math.vector2;
import krepel.math.vector4;
import std.conv;

@nogc:
@safe:
nothrow:

/// Calculates the Dot Product of the two Vectors
/// Input Vectors will not be modified
float Dot(Vector3 Lhs, Vector3 Rhs)
{
  float Result = Lhs | Rhs;
  return Result;
}

/// Multiplies two Vectors per component returning a new Vector containing
/// (Lhs.X * Rhs.X, Lhs.Y * Rhs.Y, Lhs.Z * Rhs.Z)
/// Input Vectors will not be modified
Vector3 Mul(Vector3 Lhs, Vector3 Rhs)
{
  return Lhs * Rhs;
}

/// Calculates the cross Product (Lhs x Rhs) and returns the result
/// Input Vectors will not be modified
Vector3 Cross(Vector3 Lhs, Vector3 Rhs)
{
  return Lhs ^ Rhs;
}

/// Calculates the squared length  of the given Vector, which is the same as the dot product with the same Vector
/// Input Vector will not be modified
float LengthSquared(Vector3 Vec)
{
  return Vec | Vec;
}

/// Calculates the squared length of the X and Y components, ignoring the Z component
/// Input Vector will not be modified
float LengthSquared2D(Vector3 Vec)
{
  return Vec.X * Vec.X + Vec.Y * Vec.Y;
}

/// Calculates the 2D length of the Vector using the square root of the LengthSquared2D
/// Input Vector will not be modified
float Length2D(Vector3 Vec)
{
  return Sqrt(Vec.LengthSquared2D());
}

/// Calculates the 2D length of the Vector using the square root of the LengthSquared
/// Input Vector will not be modified
float Length(Vector3 Vec)
{
  return Sqrt(Vec.LengthSquared());
}

/// Creates a copy of the Vector, which is Normalized in its length (has a length of 1.0)
Vector3 NormalizedCopy(Vector3 Vec)
{
  Vector3 Copy = Vec;
  Copy.Normalize();
  return Copy;
}

/// Projects a given Vector onto a Normal (Normal needs to be Normalized)
/// Returns the projected Vector, which will be a scaled version of the Vector
/// Input Vectors will not be modified
Vector3 ProjectOntoNormal(Vector3 Vec, Vector3 Normal)
{
  return Normal * (Vec | Normal);
}

/// Projects a given Vector on a plane, which has the given Normal (Normal needs to be Normalized)
/// Returns Vector which resides on the plane spanned by the Normal
/// Input Vector will not be modified
Vector3 ProjectOntoPlane(Vector3 Vec, Vector3 Normal)
{
  return Vec - Vec.ProjectOntoNormal(Normal);
}

/// Reflects a Vector around a Normal (Normal needs to be Normalized)
/// Returns the reflected Vector
/// Input Vectors will not be modified
Vector3 ReflectVector(Vector3 Vec, Vector3 Normal)
{
  return Vec - (2 * (Vec | Normal) * Normal);
}

/// Checks if any component inside the Vector is NaN.
/// Input Vector will not be modified
bool ContainsNaN(Vector3 Vec)
{
  return IsNaN(Vec.X) || IsNaN(Vec.Y) || IsNaN(Vec.Z);
}

/// Checks if two Vectors are nearly equal (are equal with respect to a scaled epsilon)
/// Input Vectors will not be modified
bool NearlyEquals(Vector3 A, Vector3 B, float Epsilon = 1e-4f)
{
  return krepel.math.NearlyEquals(A.X, B.X, Epsilon) &&
         krepel.math.NearlyEquals(A.Y, B.Y, Epsilon) &&
         krepel.math.NearlyEquals(A.Z, B.Z, Epsilon);
}

/// Returns a clamped copy of the given Vector
/// The retuned Vector will be of size <= MaxSize
/// Input Vector will not be modified
Vector3 ClampSize(Vector3 Vec, float MaxSize)
{
  Vector3 Normal = Vec.NormalizedCopy();
  return Normal * Min(Vec.Length(), MaxSize);
}

/// Returns a clamped copy of the X and Y component of the Vector, the Z compnent will be untouched
/// The length of the X and Y component will be <= MaxSize
/// Input Vector will not be modified
Vector3 ClampSize2D(Vector3 Vec, float MaxSize)
{
  Vector3 Clamped = Vec;
  Clamped.Z = 0;
  Clamped.Normalize();
  Clamped *= Min(Vec.Length2D(), MaxSize);
  Clamped.Z = Vec.Z;
  return Clamped;
}

struct Vector3
{
  @safe:
  @nogc:
  nothrow:
  union
  {
    struct
    {
      float X, Y, Z;
    }
    float[3] Data;
  }
  this(float Value)
  {
    X = Value;
    Y = Value;
    Z = Value;
  }

  this(float X, float Y, float Z)
  {
    this.X = X;
    this.Y = Y;
    this.Z = Z;
  }

  this(Vector2 Vec, float Z)
  {
    this.Data[0..2] = Vec.Data[];
    this.Z = Z;
  }

  this(float X, Vector2 Vec)
  {
    this.X = X;
    this.Data[1..3] = Vec.Data[];
  }

  /// Normalizes the Vector (Vector will have a length of 1.0)
  void Normalize()
  {
    // Don't return result to avoid confusion with NormalizedCopy
    // and stress that this operation modifies the Vector on which it is called
    float Length = this.Length();
    this /= Length;
  }

  // Dot product
  float opBinary(string Op:"|")(Vector3 Rhs)
  {
    return
      X * Rhs.X +
      Y * Rhs.Y +
      Z * Rhs.Z;
  }

  Vector3 opOpAssign(string Operator)(float Rhs)
  {
    static if(Operator == "*" || Operator == "/")
    {
      auto Result = mixin("Vector3("~
        "X" ~ Operator ~ "Rhs,"
        "Y" ~ Operator ~ "Rhs,"
        "Z" ~ Operator ~ "Rhs)");
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

  Vector3 opBinary(string Operator)(Vector3 Rhs) const
  {
    // Addition, subtraction, component wise multiplication
    static if(Operator == "+" || Operator == "-" || Operator == "*")
    {
      return mixin("Vector3("~
        "X" ~ Operator ~ "Rhs.X,"
        "Y" ~ Operator ~ "Rhs.Y,"
        "Z" ~ Operator ~ "Rhs.Z)");
    }
    // Cross Product
    else static if(Operator == "^")
    {
      return Vector3(
        (Y * Rhs.Z) - (Z * Rhs.Y),
        (Z * Rhs.X) - (X * Rhs.Z),
        (X * Rhs.Y) - (Y * Rhs.X)
      );
    }
    else
    {
      static assert(false, "Operator " ~ Operator ~ " not implemented.");
    }
  }

  Vector3 opBinary(string Operator)(float Rhs) const
  {
    // Vector scaling
    static if(Operator == "/" || Operator == "*")
    {
      return mixin("Vector3("~
        "X" ~ Operator ~ "Rhs,"
        "Y" ~ Operator ~ "Rhs,"
        "Z" ~ Operator ~ "Rhs)");
    }
    else
    {
      static assert(false, "Operator " ~ Operator ~ " not implemented.");
    }
  }

  Vector3 opBinaryRight(string Operator)(float Rhs) inout
  {
    // Vector scaling
    static if(Operator == "*")
    {
      return mixin("Vector3("~
        "X" ~ Operator ~ "Rhs,"
        "Y" ~ Operator ~ "Rhs,"
        "Z" ~ Operator ~ "Rhs)");
    }
    else
    {
      static assert(false, "Operator " ~ Operator ~ " not implemented.");
    }
  }

  private static bool IsValidSwizzleChar(const char Char)
  {
    return Char == 'X' || Char == 'Y' || Char == 'Z' || Char == '0';
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

  __gshared immutable ForwardVector   = Vector3(1,0,0);
  __gshared immutable RightVector     = Vector3(0,1,0);
  __gshared immutable UpVector        = Vector3(0,0,1);
  __gshared immutable UnitScaleVector = Vector3(1,1,1);
  __gshared immutable ZeroVector      = Vector3(0,0,0);

  // Initialization test
  unittest
  {
    Vector3 V3 = Vector3(1,2,3);
    assert(V3.X == 1);
    assert(V3.Y == 2);
    assert(V3.Z == 3);
    assert(V3.Data[0] == 1);
    assert(V3.Data[1] == 2);
    assert(V3.Data[2] == 3);

    V3 = Vector3(5);
    assert(V3.X == 5);
    assert(V3.Y == 5);
    assert(V3.Z == 5);
  }

  // Addition test
  unittest
  {
    Vector3 V1 = Vector3(1,2,3);
    Vector3 V2 = Vector3(10,11,12);
    auto V3 = V1 + V2;
    assert(V3.X == 11);
    assert(V3.Y == 13);
    assert(V3.Z == 15);
  }

  // Subtraction test
  unittest
  {
    Vector3 V1 = Vector3(1,2,3);
    Vector3 V2 = Vector3(10,11,12);
    auto V3 = V1 - V2;
    assert(V3.X == -9);
    assert(V3.Y == -9);
    assert(V3.Z == -9);
  }

  // Float multiplication test
  unittest
  {
    Vector3 V1 = Vector3(1,2,3) * 5;
    Vector3 V2 = Vector3(1,2,3) * 5.0f;
    assert(V1 == Vector3(5,10,15));
    assert(V2 == Vector3(5,10,15));

    V1 = 5 * Vector3(1,2,3);
    V2 = 5.0f * Vector3(1,2,3);
    assert(V1 == Vector3(5,10,15));
    assert(V2 == Vector3(5,10,15));
  }

  // Float division test
  unittest
  {
    Vector3 V1 = Vector3(5,10,15) / 5;
    Vector3 V2 = Vector3(5,10,15) / 5.0f;
    assert(V1 == Vector3(1,2,3));
    assert(V2 == Vector3(1,2,3));

    V1 = Vector3(5,10,15);
    V2 = Vector3(5,10,15);
    V1 /= 5;
    V2 /= 5.0f;
    assert(V1 == Vector3(1,2,3));
    assert(V2 == Vector3(1,2,3));
  }

  /// Dot product test
  unittest
  {
    Vector3 V1 = Vector3(1,2,3);
    Vector3 V2 = Vector3(10,11,12);
    auto V3 = V1 | V2;
    assert(V3 == 10 + 22 + 36);
    assert(V3 == V1.Dot(V2));
  }

  /// Component wise multiplication test
  unittest
  {
    Vector3 V1 = Vector3(1,2,3);
    Vector3 V2 = Vector3(10,11,12);
    auto V3 = V1 * V2;
    assert(V3.X == 10);
    assert(V3.Y == 22);
    assert(V3.Z == 36);
    assert(V3 == V1.Mul(V2));
  }

  /// Cross Product
  unittest
  {
    // Operator
    auto Vec = Vector3.UpVector ^ Vector3.ForwardVector;
    assert(Vec == Vector3.RightVector);
    // Function
    assert(Cross(Vector3.UpVector, Vector3.ForwardVector) == Vector3.RightVector);
    Vector3 Vec1 = Vector3.UpVector;
    Vector3 Vec2 = Vector3.ForwardVector;
    // UFCS
    Vector3 Vec3 = Vec1.Cross(Vec2);
    assert(Vec3 == Vector3.RightVector);
  }

  /// Normalization
  unittest
  {
    Vector3 Vec = Vector3(1,1,1);
    Vec.Normalize();
    float Expected = 1.0f/Sqrt(3);
    assert(Vec == Vector3(Expected, Expected, Expected));

    Vec = Vector3(1,1,1);
    auto Normalized = Vec.NormalizedCopy();
    auto NormalizedUFCS = NormalizedCopy(Vec);
    assert(Vec == Vector3(1,1,1));
    assert(Normalized == Vector3(Expected, Expected, Expected));
    assert(NormalizedUFCS == Vector3(Expected, Expected, Expected));
  }

  /// Project Onto Normal
  unittest
  {
    Vector3 Normal = Vector3.UpVector;
    Vector3 ToProject = Vector3(1,1,0.5f);

    Vector3 Projected = ToProject.ProjectOntoNormal(Normal);

    assert(Projected == Vector3(0,0,0.5f));
  }

  /// Project Onto PLane
  unittest
  {
    Vector3 Normal = Vector3.UpVector;
    Vector3 ToProject = Vector3(1,1,0.5f);

    Vector3 Projected = ToProject.ProjectOntoPlane(Normal);

    assert(Projected == Vector3(1,1,0));
  }

  /// Reflect Vector
  unittest
  {
    Vector3 Normal = Vector3(1,0,0);
    Vector3 Reflection = Vector3(-1,0,-1);

    Vector3 Reflected = Reflection.ReflectVector(Normal);

    assert(Reflected == Vector3(1,0,-1));
  }

  /// NearlyEquals
  unittest
  {
    Vector3 A = Vector3(1,1,0);
    Vector3 B = Vector3(1+1e-5f,1,-1e-6f);
    Vector3 C = Vector3(1,1,10);
    assert(NearlyEquals(A,B));
    assert(!NearlyEquals(A,C));
  }

  /// Clamp Vector3
  unittest
  {
    Vector3 Vec = Vector3(100,0,0);
    Vector3 Clamped = Vec.ClampSize(1);
    assert(Vec == Vector3(100,0,0));
    assert(Clamped == Vector3(1,0,0));
  }

  /// Clamp2D Vector3
  unittest
  {
    Vector3 Vec = Vector3(100,0,1000);
    Vector3 Clamped = Vec.ClampSize2D(1);
    assert(Vec == Vector3(100,0,1000));
    assert(Clamped == Vector3(1,0,1000));
  }

  /// 2D Length
  unittest
  {
    Vector3 Vec = Vector3(0,1,1032094);
    assert(Vec.Length2D() == 1);
    assert(Vec.LengthSquared2D() == 1);
  }

  // Vector3
  unittest
  {
    assert(Vector3(Vector2(1, 2), 3).X == 1);
    assert(Vector3(Vector2(1, 2), 3).Y == 2);
    assert(Vector3(Vector2(1, 2), 3).Z == 3);

    assert(Vector3(1, Vector2(2, 3)).X == 1);
    assert(Vector3(1, Vector2(2, 3)).Y == 2);
    assert(Vector3(1, Vector2(2, 3)).Z == 3);
  }

  // Vector3 Swizzle
  unittest
  {
    assert(Vector3(1, 2, 3).ZX   == Vector2(3, 1));
    assert(Vector3(1, 2, 3).XZX  == Vector3(1, 3, 1));
    assert(Vector3(1, 2, 3).XYXY == Vector4(1, 2, 1, 2));
    assert(Vector3(1, 2, 3)._ZYX == Vector3(3, 2, 1));
    assert(Vector3(1, 2, 3)._0YX == Vector3(0, 2, 1));

    static assert(!__traits(compiles, Vector3(1, 2, 3).Foo), "Swizzling is only supposed to work with value members of " ~ Vector3.stringof ~ ".");
    static assert(!__traits(compiles, Vector3(1, 2, 3).XXXXX), "Swizzling output dimension is limited to 4.");
  }
}
