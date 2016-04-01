module krepel.math.vector2;

import krepel.math.math;
import krepel.algorithm.comparison;
import krepel.math.vector3;
import krepel.math.vector4;
import std.conv;

@safe:

/// Calculates the Dot Product of the two Vectors
/// Input Vectors will not be modified
float Dot(Vector2 Lhs, Vector2 Rhs)
{
  float Result = Lhs | Rhs;
  return Result;
}

/// Multiplies two Vectors per component returning a new Vector containing
/// (Lhs.X * Rhs.X, Lhs.Y * Rhs.Y, Lhs.Z * Rhs.Z)
/// Input Vectors will not be modified
Vector2 Mul(Vector2 Lhs, Vector2 Rhs)
{
  return Lhs * Rhs;
}

/// Calculates the squared length  of the given Vector, which is the same as the dot product with the same Vector
/// Input Vector will not be modified
float LengthSquared(Vector2 Vec)
{
  return Vec | Vec;
}

/// Calculates the 2D length of the Vector using the square root of the LengthSquared
/// Input Vector will not be modified
float Length(Vector2 Vec)
{
  return Sqrt(Vec.LengthSquared());
}

/// Creates a copy of the Vector, which is Normalized in its length (has a length of 1.0)
Vector2 NormalizedCopy(Vector2 Vec)
{
  Vector2 Copy = Vec;
  Copy.Normalize();
  return Copy;
}

/// Projects a given Vector onto a Normal (Normal needs to be Normalized)
/// Returns the Projected Vector, which will be a scaled version of the Vector
/// Input Vectors will not be modified
Vector2 ProjectOntoNormal(Vector2 Vec, Vector2 Normal)
{
  return Normal * (Vec | Normal);
}

/// Projects a given Vector on a plane, which has the given Normal (Normal needs to be Normalized)
/// Returns Vector which resides on the plane spanned by the Normal
/// Input Vector will not be modified
Vector2 ProjectOntoPlane(Vector2 Vec, Vector2 Normal)
{
  return Vec - Vec.ProjectOntoNormal(Normal);
}

/// Reflects a Vector around a Normal (Normal needs to be Normalized)
/// Returns the reflected Vector
/// Input Vectors will not be modified
Vector2 ReflectVector(Vector2 Vec, Vector2 Normal)
{
  return Vec - (2 * (Vec | Normal) * Normal);
}

/// Checks if any component inside the Vector is NaN.
/// Input Vector will not be modified
bool ContainsNaN(Vector2 Vec)
{
  return IsNaN(Vec.X) || IsNaN(Vec.Y);
}

/// Checks if two Vectors are nearly equal (are equal with respect to a scaled epsilon)
/// Input Vectors will not be modified
bool NearlyEquals(Vector2 A, Vector2 B, float Epsilon = 1e-4f)
{
  return krepel.math.math.NearlyEquals(A.X, B.X, Epsilon) &&
         krepel.math.math.NearlyEquals(A.Y, B.Y, Epsilon);
}

/// Returns a clamped copy of the given Vector
/// The retuned Vector will be of size <= MaxSize
/// Input Vector will not be modified
Vector2 ClampSize(Vector2 Vec, float MaxSize)
{
  Vector2 Normal = Vec.NormalizedCopy();
  return Normal * Min(Vec.Length(), MaxSize);
}

struct Vector2
{
  @safe:

  union
  {
    struct
    {
      float X, Y;
    }
    float[2] Data;
  }
  this(float Value)
  {
    X = Value;
    Y = Value;
  }

  this(float X, float Y)
  {
    this.X = X;
    this.Y = Y;
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
  float opBinary(string Operator:"|")(Vector2 Rhs)
  {
    return
      X * Rhs.X +
      Y * Rhs.Y;
  }

  Vector2 opOpAssign(string Operator)(float Rhs)
  {
    static if(Operator == "*" || Operator == "/")
    {
      auto Result = mixin("Vector2("~
        "X" ~ Operator ~ "Rhs,"
        "Y" ~ Operator ~ "Rhs)");
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

  Vector2 opBinary(string Operator)(Vector2 Rhs) inout
  {
    // Addition, subtraction, component wise multiplication
    static if(Operator == "+" || Operator == "-" || Operator == "*")
    {
      return mixin("Vector2("~
        "X" ~ Operator ~ "Rhs.X,"
        "Y" ~ Operator ~ "Rhs.Y)");
    }
    else
    {
      static assert(false, "Operator " ~ Operator ~ " not implemented.");
    }
  }

  Vector2 opBinary(string Operator)(float Rhs) inout
  {
    // Vector scaling
    static if(Operator == "/" || Operator == "*")
    {
      return mixin("Vector2("~
        "X" ~ Operator ~ "Rhs,"
        "Y" ~ Operator ~ "Rhs)");
    }
    else
    {
      static assert(false, "Operator " ~ Operator ~ " not implemented.");
    }
  }

  Vector2 opBinaryRight(string Operator)(float Rhs) inout
  {
    // Vector scaling
    static if(Operator == "*")
    {
      return mixin("Vector2("~
        "X" ~ Operator ~ "Rhs,"
        "Y" ~ Operator ~ "Rhs)");
    }
    else
    {
      static assert(false, "Operator " ~ Operator ~ " not implemented.");
    }
  }

  private static bool IsValidSwizzleChar(const char Char)
  {
    return Char == 'X' || Char == 'Y' || Char == '0' || Char == '1';
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

  Vector2 opUnary(string Operator : "-")() inout
  {
    return typeof(return)(-X, -Y);
  }

  __gshared immutable UnitX           = Vector2(1,0);
  __gshared immutable UnitY           = Vector2(0,1);
  __gshared immutable UnitScaleVector = Vector2(1,1);
  __gshared immutable ZeroVector      = Vector2(0,0);

  // Initialization test
  unittest
  {
    Vector2 V3 = Vector2(1,2);
    assert(V3.X == 1);
    assert(V3.Y == 2);
    assert(V3.Data[0] == 1);
    assert(V3.Data[1] == 2);

    V3 = Vector2(5);
    assert(V3.X == 5);
    assert(V3.Y == 5);
  }

  // Addition test
  unittest
  {
    Vector2 V1 = Vector2(1,2);
    Vector2 V2 = Vector2(10,11);
    auto V3 = V1 + V2;
    assert(V3.X == 11);
    assert(V3.Y == 13);
  }

  // Subtraction test
  unittest
  {
    Vector2 V1 = Vector2(1,2);
    Vector2 V2 = Vector2(10,11);
    auto V3 = V1 - V2;
    assert(V3.X == -9);
    assert(V3.Y == -9);
  }

  // Float multiplication test
  unittest
  {
    Vector2 V1 = Vector2(1,2) * 5;
    Vector2 V2 = Vector2(1,2) * 5.0f;
    assert(V1 == Vector2(5,10));
    assert(V2 == Vector2(5,10));

    V1 = 5 * Vector2(1,2);
    V2 = 5.0f * Vector2(1,2);
    assert(V1 == Vector2(5,10));
    assert(V2 == Vector2(5,10));
  }

  // Float division test
  unittest
  {
    Vector2 V1 = Vector2(5,10) / 5;
    Vector2 V2 = Vector2(5,10) / 5.0f;
    assert(V1 == Vector2(1,2));
    assert(V2 == Vector2(1,2));

    V1 = Vector2(5,10);
    V2 = Vector2(5,10);
    V1 /= 5;
    V2 /= 5.0f;
    assert(V1 == Vector2(1,2));
    assert(V2 == Vector2(1,2));
  }

  /// Dot product test
  unittest
  {
    Vector2 V1 = Vector2(1,2);
    Vector2 V2 = Vector2(10,11);
    auto V3 = V1 | V2;
    assert(V3 == 10 + 22);
    assert(V3 == V1.Dot(V2));
  }

  /// Component wise multiplication test
  unittest
  {
    Vector2 V1 = Vector2(1,2);
    Vector2 V2 = Vector2(10,11);
    auto V3 = V1 * V2;
    assert(V3.X == 10);
    assert(V3.Y == 22);
    assert(V3 == V1.Mul(V2));
  }

  /// Normalization
  unittest
  {
    Vector2 Vec = Vector2(1,1);
    Vec.Normalize();
    float Expected = 1.0f/Sqrt(2);
    assert(Vec == Vector2(Expected, Expected));

    Vec = Vector2(1,1);
    auto Normalized = Vec.NormalizedCopy();
    auto NormalizedUFCS = NormalizedCopy(Vec);
    assert(Vec == Vector2(1,1));
    assert(Normalized == Vector2(Expected, Expected));
    assert(NormalizedUFCS == Vector2(Expected, Expected));
  }

  /// Project Onto Normal
  unittest
  {
    Vector2 Normal = Vector2.UnitY;
    Vector2 ToProject = Vector2(1,1);

    Vector2 Projected = ToProject.ProjectOntoNormal(Normal);

    assert(Projected == Vector2(0,1));
  }

  /// Project Onto PLane
  unittest
  {
    Vector2 Normal = Vector2.UnitY;
    Vector2 ToProject = Vector2(1,1);

    Vector2 Projected = ToProject.ProjectOntoPlane(Normal);

    assert(Projected == Vector2(1,0));
  }

  /// Reflect Vector
  unittest
  {
    Vector2 Normal = Vector2(1,0);
    Vector2 Reflection = Vector2(-1,0);

    Vector2 Reflected = Reflection.ReflectVector(Normal);

    assert(Reflected == Vector2(1,0));
  }

  /// NearlyEquals
  unittest
  {
    Vector2 A = Vector2(1,0);
    Vector2 B = Vector2(1+1e-5f,-1e-6f);
    Vector2 C = Vector2(1,10);
    assert(NearlyEquals(A,B));
    assert(!NearlyEquals(A,C));
  }

  /// Clamp Vector2
  unittest
  {
    Vector2 Vec = Vector2(100,0);
    Vector2 Clamped = Vec.ClampSize(1);
    assert(Vec == Vector2(100,0));
    assert(Clamped == Vector2(1,0));
  }

  /// Dispatch test
  unittest
  {
    Vector2 Vec = Vector2(1,2);

    Vector2 Swizzled = Vec.Y0;

    assert(Swizzled == Vector2(2,0));
  }

  // Vector2
  unittest
  {
    assert(Vector2(1, 2).X == 1);
    assert(Vector2(1, 2).Y == 2);

    assert(Vector2(1, 2).YX   == Vector2(2, 1));
    assert(Vector2(1, 2).XYX  == Vector3(1, 2, 1));
    assert(Vector2(1, 2).XYXY == Vector4(1, 2, 1, 2));
    assert(Vector2(1, 2)._YX == Vector2(2, 1));
    assert(Vector2(1, 2)._0X == Vector2(0, 1));

    static assert(!__traits(compiles, Vector2(1, 2).Foo), "Swizzling is only supposed to work with value members of " ~ Vector2.stringof ~ ".");
    static assert(!__traits(compiles, Vector2(1, 2).XXXXX), "Swizzling output dimension is limited to 4.");
  }
}
