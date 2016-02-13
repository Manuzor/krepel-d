module krepel.math.vector2;

import krepel.math.math;
import krepel.algorithm.comparison;
import krepel.math.vector3;
import krepel.math.vector4;
import std.conv;

@nogc:
@safe:
nothrow:

/// Calculates the Dot Product of the two vectors
/// Input vectors will not be modified
float Dot(Vector2 lhs, Vector2 rhs)
{
  float result = lhs | rhs;
  return result;
}

/// Multiplies two vectors per component returning a new vector containing
/// (lhs.X * rhs.X, lhs.Y * rhs.Y, lhs.Z * rhs.Z)
/// Input vectors will not be modified
Vector2 Mul(Vector2 lhs, Vector2 rhs)
{
  return lhs * rhs;
}

/// Calculates the squared length  of the given vector, which is the same as the dot product with the same vector
/// Input vector will not be modified
float LengthSquared(Vector2 vec)
{
  return vec | vec;
}

/// Calculates the 2D length of the Vector using the square root of the LengthSquared
/// Input vector will not be modified
float Length(Vector2 vec)
{
  return Sqrt(vec.LengthSquared());
}

/// Creates a copy of the vector, which is normalized in its length (has a length of 1.0)
Vector2 NormalizedCopy(Vector2 vec)
{
  Vector2 copy = vec;
  copy.Normalize();
  return copy;
}

/// Projects a given vector onto a normal (normal needs to be normalized)
/// Returns the projected vector, which will be a scaled version of the vector
/// Input vectors will not be modified
Vector2 ProjectOntoNormal(Vector2 vec, Vector2 normal)
{
  return normal * (vec | normal);
}

/// Projects a given vector on a plane, which has the given normal (normal needs to be normalized)
/// Returns vector which resides on the plane spanned by the normal
/// Input vector will not be modified
Vector2 ProjectOntoPlane(Vector2 vec, Vector2 normal)
{
  return vec - vec.ProjectOntoNormal(normal);
}

/// Reflects a vector around a normal (normal needs to be normalized)
/// Returns the reflected vector
/// Input vectors will not be modified
Vector2 ReflectVector(Vector2 vec, Vector2 normal)
{
  return vec - (2 * (vec | normal) * normal);
}

/// Checks if any component inside the vector is NaN.
/// Input vector will not be modified
bool ContainsNaN(Vector2 vec)
{
  return IsNaN(vec.X) || IsNaN(vec.Y);
}

/// Checks if two vectors are nearly equal (are equal with respect to a scaled epsilon)
/// Input vectors will not be modified
bool NearlyEquals(Vector2 a, Vector2 b, float epsilon = 1e-4f)
{
  return krepel.math.NearlyEquals(a.X, b.X, epsilon) &&
         krepel.math.NearlyEquals(a.Y, b.Y, epsilon);
}

/// Returns a clamped copy of the given vector
/// The retuned vector will be of size <= MaxSize
/// Input vector will not be modified
Vector2 ClampSize(Vector2 vec, float MaxSize)
{
  Vector2 normal = vec.NormalizedCopy();
  return normal * Min(vec.Length(), MaxSize);
}

struct Vector2
{
  @safe:
  @nogc:
  nothrow:

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

  /// Normalizes the vector (vector will have a length of 1.0)
  void Normalize()
  {
    // Don't return result to avoid confusion with NormalizedCopy
    // and stress that this operation modifies the vector on which it is called
    float length = this.Length();
    this /= length;
  }

  // Dot product
  float opBinary(string op:"|")(Vector2 rhs)
  {
    return
      X * rhs.X +
      Y * rhs.Y;
  }

  Vector2 opOpAssign(string op)(float rhs)
  {
    static if(op == "*" || op == "/")
    {
      auto result = mixin("Vector2("~
        "X" ~ op ~ "rhs,"
        "Y" ~ op ~ "rhs)");
      Data = result.Data;
      return this;
    }
    else
    {
      static assert(false, "Operator " ~ op ~ " not implemented.");
    }
  }

  //const (char)[] ToString() const
  //{
  //  // TODO: More memory friendly (no GC) implementation?
  //  return "{X:"~text(X)~", Y:"~text(Y)~", Z:"~text(Z)~"}";
  //}

  Vector2 opBinary(string op)(Vector2 rhs) inout
  {
    // Addition, subtraction, component wise multiplication
    static if(op == "+" || op == "-" || op == "*")
    {
      return mixin("Vector2("~
        "X" ~ op ~ "rhs.X,"
        "Y" ~ op ~ "rhs.Y)");
    }
    else
    {
      static assert(false, "Operator " ~ op ~ " not implemented.");
    }
  }

  Vector2 opBinary(string op)(float rhs) inout
  {
    // Vector scaling
    static if(op == "/" || op == "*")
    {
      return mixin("Vector2("~
        "X" ~ op ~ "rhs,"
        "Y" ~ op ~ "rhs)");
    }
    else
    {
      static assert(false, "Operator " ~ op ~ " not implemented.");
    }
  }

  Vector2 opBinaryRight(string op)(float rhs) inout
  {
    // Vector scaling
    static if(op == "*")
    {
      return mixin("Vector2("~
        "X" ~ op ~ "rhs,"
        "Y" ~ op ~ "rhs)");
    }
    else
    {
      static assert(false, "Operator " ~ op ~ " not implemented.");
    }
  }

  private static bool IsValidSwizzleChar(const char Char)
  {
    return Char == 'X' || Char == 'Y' || Char == '0';
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
    if(SwizzleString.length == 3 || (SwizzleString.length == 4 && SwizzleString[0] == '_'))
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
    if(SwizzleString.length == 4 || (SwizzleString.length == 5 && SwizzleString[0] == '_'))
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

  __gshared immutable UnitX           = Vector2(1,0);
  __gshared immutable UnitY           = Vector2(0,1);
  __gshared immutable UnitScaleVector = Vector2(1,1);
  __gshared immutable ZeroVector      = Vector2(0,0);

  // Initialization test
  unittest
  {
    Vector2 v3 = Vector2(1,2);
    assert(v3.X == 1);
    assert(v3.Y == 2);
    assert(v3.Data[0] == 1);
    assert(v3.Data[1] == 2);

    v3 = Vector2(5);
    assert(v3.X == 5);
    assert(v3.Y == 5);
  }

  // Addition test
  unittest
  {
    Vector2 v1 = Vector2(1,2);
    Vector2 v2 = Vector2(10,11);
    auto v3 = v1 + v2;
    assert(v3.X == 11);
    assert(v3.Y == 13);
  }

  // Subtraction test
  unittest
  {
    Vector2 v1 = Vector2(1,2);
    Vector2 v2 = Vector2(10,11);
    auto v3 = v1 - v2;
    assert(v3.X == -9);
    assert(v3.Y == -9);
  }

  // Float multiplication test
  unittest
  {
    Vector2 v1 = Vector2(1,2) * 5;
    Vector2 v2 = Vector2(1,2) * 5.0f;
    assert(v1 == Vector2(5,10));
    assert(v2 == Vector2(5,10));

    v1 = 5 * Vector2(1,2);
    v2 = 5.0f * Vector2(1,2);
    assert(v1 == Vector2(5,10));
    assert(v2 == Vector2(5,10));
  }

  // Float division test
  unittest
  {
    Vector2 v1 = Vector2(5,10) / 5;
    Vector2 v2 = Vector2(5,10) / 5.0f;
    assert(v1 == Vector2(1,2));
    assert(v2 == Vector2(1,2));

    v1 = Vector2(5,10);
    v2 = Vector2(5,10);
    v1 /= 5;
    v2 /= 5.0f;
    assert(v1 == Vector2(1,2));
    assert(v2 == Vector2(1,2));
  }

  /// Dot product test
  unittest
  {
    Vector2 v1 = Vector2(1,2);
    Vector2 v2 = Vector2(10,11);
    auto v3 = v1 | v2;
    assert(v3 == 10 + 22);
    assert(v3 == v1.Dot(v2));
  }

  /// Component wise multiplication test
  unittest
  {
    Vector2 v1 = Vector2(1,2);
    Vector2 v2 = Vector2(10,11);
    auto v3 = v1 * v2;
    assert(v3.X == 10);
    assert(v3.Y == 22);
    assert(v3 == v1.Mul(v2));
  }

  /// Normalization
  unittest
  {
    Vector2 vec = Vector2(1,1);
    vec.Normalize();
    float expected = 1.0f/Sqrt(2);
    assert(vec == Vector2(expected, expected));

    vec = Vector2(1,1);
    auto normalized = vec.NormalizedCopy();
    auto normalizedUFCS = NormalizedCopy(vec);
    assert(vec == Vector2(1,1));
    assert(normalized == Vector2(expected, expected));
    assert(normalizedUFCS == Vector2(expected, expected));
  }

  /// Project Onto Normal
  unittest
  {
    Vector2 normal = Vector2.UnitY;
    Vector2 toProject = Vector2(1,1);

    Vector2 projected = toProject.ProjectOntoNormal(normal);

    assert(projected == Vector2(0,1));
  }

  /// Project Onto PLane
  unittest
  {
    Vector2 normal = Vector2.UnitY;
    Vector2 toProject = Vector2(1,1);

    Vector2 projected = toProject.ProjectOntoPlane(normal);

    assert(projected == Vector2(1,0));
  }

  /// Reflect Vector
  unittest
  {
    Vector2 normal = Vector2(1,0);
    Vector2 reflection = Vector2(-1,0);

    Vector2 reflected = reflection.ReflectVector(normal);

    assert(reflected == Vector2(1,0));
  }

  /// NearlyEquals
  unittest
  {
    Vector2 a = Vector2(1,0);
    Vector2 b = Vector2(1+1e-5f,-1e-6f);
    Vector2 c = Vector2(1,10);
    assert(NearlyEquals(a,b));
    assert(!NearlyEquals(a,c));
  }

  /// Clamp Vector2
  unittest
  {
    Vector2 vec = Vector2(100,0);
    Vector2 clamped = vec.ClampSize(1);
    assert(vec == Vector2(100,0));
    assert(clamped == Vector2(1,0));
  }

  /// Dispatch test
  unittest
  {
    Vector2 vec = Vector2(1,2);

    Vector2 swizzled = vec.Y0;

    assert(swizzled == Vector2(2,0));
  }

  // Vector2
  unittest
  {
    assert(Vector2(1, 2).X == 1);
    assert(Vector2(1, 2).Y == 2);

    assert(Vector2(1, 2).YX   == Vector2(2, 1));
    assert(Vector2(1, 2).XYX  == Vector3(1, 2, 1));
    assert(Vector2(1, 2).XYXY == Vector4(1, 2, 1, 2));

    static assert(!__traits(compiles, Vector2(1, 2).Foo), "Swizzling is only supposed to work with value members of " ~ Vector2.stringof ~ ".");
    static assert(!__traits(compiles, Vector2(1, 2).XXXXX), "Swizzling output dimension is limited to 4.");
  }
}
