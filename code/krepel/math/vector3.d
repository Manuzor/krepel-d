module krepel.math.vector3;

import krepel.math.math;
import krepel.algorithm.comparison;
import krepel.math.vector2;
import krepel.math.vector4;
import std.conv;

@nogc:
@safe:
nothrow:

/// Calculates the Dot Product of the two vectors
/// Input vectors will not be modified
float Dot(Vector3 lhs, Vector3 rhs)
{
  float result = lhs | rhs;
  return result;
}

/// Multiplies two vectors per component returning a new vector containing
/// (lhs.X * rhs.X, lhs.Y * rhs.Y, lhs.Z * rhs.Z)
/// Input vectors will not be modified
Vector3 Mul(Vector3 lhs, Vector3 rhs)
{
  return lhs * rhs;
}

/// Calculates the cross Product (lhs x rhs) and returns the result
/// Input vectors will not be modified
Vector3 Cross(Vector3 lhs, Vector3 rhs)
{
  return lhs ^ rhs;
}

/// Calculates the squared length  of the given vector, which is the same as the dot product with the same vector
/// Input vector will not be modified
float LengthSquared(Vector3 vec)
{
  return vec | vec;
}

/// Calculates the squared length of the X and Y components, ignoring the Z component
/// Input vector will not be modified
float LengthSquared2D(Vector3 vec)
{
  return vec.X * vec.X + vec.Y * vec.Y;
}

/// Calculates the 2D length of the Vector using the square root of the LengthSquared2D
/// Input vector will not be modified
float Length2D(Vector3 vec)
{
  return Sqrt(vec.LengthSquared2D());
}

/// Calculates the 2D length of the Vector using the square root of the LengthSquared
/// Input vector will not be modified
float Length(Vector3 vec)
{
  return Sqrt(vec.LengthSquared());
}

/// Creates a copy of the vector, which is normalized in its length (has a length of 1.0)
Vector3 NormalizedCopy(Vector3 vec)
{
  Vector3 copy = vec;
  copy.Normalize();
  return copy;
}

/// Projects a given vector onto a normal (normal needs to be normalized)
/// Returns the projected vector, which will be a scaled version of the vector
/// Input vectors will not be modified
Vector3 ProjectOntoNormal(Vector3 vec, Vector3 normal)
{
  return normal * (vec | normal);
}

/// Projects a given vector on a plane, which has the given normal (normal needs to be normalized)
/// Returns vector which resides on the plane spanned by the normal
/// Input vector will not be modified
Vector3 ProjectOntoPlane(Vector3 vec, Vector3 normal)
{
  return vec - vec.ProjectOntoNormal(normal);
}

/// Reflects a vector around a normal (normal needs to be normalized)
/// Returns the reflected vector
/// Input vectors will not be modified
Vector3 ReflectVector(Vector3 vec, Vector3 normal)
{
  return vec - (2 * (vec | normal) * normal);
}

/// Checks if any component inside the vector is NaN.
/// Input vector will not be modified
bool ContainsNaN(Vector3 vec)
{
  return IsNaN(vec.X) || IsNaN(vec.Y) || IsNaN(vec.Z);
}

/// Checks if two vectors are nearly equal (are equal with respect to a scaled epsilon)
/// Input vectors will not be modified
bool NearlyEquals(Vector3 a, Vector3 b, float epsilon = 1e-4f)
{
  return krepel.math.NearlyEquals(a.X, b.X, epsilon) &&
         krepel.math.NearlyEquals(a.Y, b.Y, epsilon) &&
         krepel.math.NearlyEquals(a.Z, b.Z, epsilon);
}

/// Returns a clamped copy of the given vector
/// The retuned vector will be of size <= MaxSize
/// Input vector will not be modified
Vector3 ClampSize(Vector3 vec, float MaxSize)
{
  Vector3 normal = vec.NormalizedCopy();
  return normal * Min(vec.Length(), MaxSize);
}

/// Returns a clamped copy of the X and Y component of the Vector, the Z compnent will be untouched
/// The length of the X and Y component will be <= MaxSize
/// Input vector will not be modified
Vector3 ClampSize2D(Vector3 vec, float MaxSize)
{
  Vector3 clamped = vec;
  clamped.Z = 0;
  clamped.Normalize();
  clamped *= Min(vec.Length2D(), MaxSize);
  clamped.Z = vec.Z;
  return clamped;
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

  this(Vector2 vec, float Z)
  {
    this.Data[0..2] = vec.Data[];
    this.Z = Z;
  }

  this(float X, Vector2 vec)
  {
    this.X = X;
    this.Data[1..3] = vec.Data[];
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
  float opBinary(string op:"|")(Vector3 rhs)
  {
    return
      X * rhs.X +
      Y * rhs.Y +
      Z * rhs.Z;
  }

  Vector3 opOpAssign(string op)(float rhs)
  {
    static if(op == "*" || op == "/")
    {
      auto result = mixin("Vector3("~
        "X" ~ op ~ "rhs,"
        "Y" ~ op ~ "rhs,"
        "Z" ~ op ~ "rhs)");
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

  Vector3 opBinary(string op)(Vector3 rhs) inout
  {
    // Addition, subtraction, component wise multiplication
    static if(op == "+" || op == "-" || op == "*")
    {
      return mixin("Vector3("~
        "X" ~ op ~ "rhs.X,"
        "Y" ~ op ~ "rhs.Y,"
        "Z" ~ op ~ "rhs.Z)");
    }
    // Cross Product
    else if(op == "^")
    {
      return Vector3(
        (Y * rhs.Z) - (Z * rhs.Y),
        (Z * rhs.X) - (X * rhs.Z),
        (X * rhs.Y) - (Y * rhs.X)
      );
    }
    else
    {
      static assert(false, "Operator " ~ op ~ " not implemented.");
    }
  }

  Vector3 opBinary(string op)(float rhs) inout
  {
    // Vector scaling
    static if(op == "/" || op == "*")
    {
      return mixin("Vector3("~
        "X" ~ op ~ "rhs,"
        "Y" ~ op ~ "rhs,"
        "Z" ~ op ~ "rhs)");
    }
    else
    {
      static assert(false, "Operator " ~ op ~ " not implemented.");
    }
  }

  Vector3 opBinaryRight(string op)(float rhs) inout
  {
    // Vector scaling
    static if(op == "*")
    {
      return mixin("Vector3("~
        "X" ~ op ~ "rhs,"
        "Y" ~ op ~ "rhs,"
        "Z" ~ op ~ "rhs)");
    }
    else
    {
      static assert(false, "Operator " ~ op ~ " not implemented.");
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

  __gshared immutable ForwardVector   = Vector3(1,0,0);
  __gshared immutable RightVector     = Vector3(0,1,0);
  __gshared immutable UpVector        = Vector3(0,0,1);
  __gshared immutable UnitScaleVector = Vector3(1,1,1);
  __gshared immutable ZeroVector      = Vector3(0,0,0);

  // Initialization test
  unittest
  {
    Vector3 v3 = Vector3(1,2,3);
    assert(v3.X == 1);
    assert(v3.Y == 2);
    assert(v3.Z == 3);
    assert(v3.Data[0] == 1);
    assert(v3.Data[1] == 2);
    assert(v3.Data[2] == 3);

    v3 = Vector3(5);
    assert(v3.X == 5);
    assert(v3.Y == 5);
    assert(v3.Z == 5);
  }

  // Addition test
  unittest
  {
    Vector3 v1 = Vector3(1,2,3);
    Vector3 v2 = Vector3(10,11,12);
    auto v3 = v1 + v2;
    assert(v3.X == 11);
    assert(v3.Y == 13);
    assert(v3.Z == 15);
  }

  // Subtraction test
  unittest
  {
    Vector3 v1 = Vector3(1,2,3);
    Vector3 v2 = Vector3(10,11,12);
    auto v3 = v1 - v2;
    assert(v3.X == -9);
    assert(v3.Y == -9);
    assert(v3.Z == -9);
  }

  // Float multiplication test
  unittest
  {
    Vector3 v1 = Vector3(1,2,3) * 5;
    Vector3 v2 = Vector3(1,2,3) * 5.0f;
    assert(v1 == Vector3(5,10,15));
    assert(v2 == Vector3(5,10,15));

    v1 = 5 * Vector3(1,2,3);
    v2 = 5.0f * Vector3(1,2,3);
    assert(v1 == Vector3(5,10,15));
    assert(v2 == Vector3(5,10,15));
  }

  // Float division test
  unittest
  {
    Vector3 v1 = Vector3(5,10,15) / 5;
    Vector3 v2 = Vector3(5,10,15) / 5.0f;
    assert(v1 == Vector3(1,2,3));
    assert(v2 == Vector3(1,2,3));

    v1 = Vector3(5,10,15);
    v2 = Vector3(5,10,15);
    v1 /= 5;
    v2 /= 5.0f;
    assert(v1 == Vector3(1,2,3));
    assert(v2 == Vector3(1,2,3));
  }

  /// Dot product test
  unittest
  {
    Vector3 v1 = Vector3(1,2,3);
    Vector3 v2 = Vector3(10,11,12);
    auto v3 = v1 | v2;
    assert(v3 == 10 + 22 + 36);
    assert(v3 == v1.Dot(v2));
  }

  /// Component wise multiplication test
  unittest
  {
    Vector3 v1 = Vector3(1,2,3);
    Vector3 v2 = Vector3(10,11,12);
    auto v3 = v1 * v2;
    assert(v3.X == 10);
    assert(v3.Y == 22);
    assert(v3.Z == 36);
    assert(v3 == v1.Mul(v2));
  }

  /// Cross Product
  unittest
  {
    // Operator
    auto vec = Vector3.UpVector ^ Vector3.ForwardVector;
    assert(vec == Vector3.RightVector);
    // Function
    assert(Cross(Vector3.UpVector, Vector3.ForwardVector) == Vector3.RightVector);
    Vector3 vec1 = Vector3.UpVector;
    Vector3 vec2 = Vector3.ForwardVector;
    // UFCS
    Vector3 vec3 = vec1.Cross(vec2);
    assert(vec3 == Vector3.RightVector);
  }

  /// Normalization
  unittest
  {
    Vector3 vec = Vector3(1,1,1);
    vec.Normalize();
    float expected = 1.0f/Sqrt(3);
    assert(vec == Vector3(expected, expected, expected));

    vec = Vector3(1,1,1);
    auto normalized = vec.NormalizedCopy();
    auto normalizedUFCS = NormalizedCopy(vec);
    assert(vec == Vector3(1,1,1));
    assert(normalized == Vector3(expected, expected, expected));
    assert(normalizedUFCS == Vector3(expected, expected, expected));
  }

  /// Project Onto Normal
  unittest
  {
    Vector3 normal = Vector3.UpVector;
    Vector3 toProject = Vector3(1,1,0.5f);

    Vector3 projected = toProject.ProjectOntoNormal(normal);

    assert(projected == Vector3(0,0,0.5f));
  }

  /// Project Onto PLane
  unittest
  {
    Vector3 normal = Vector3.UpVector;
    Vector3 toProject = Vector3(1,1,0.5f);

    Vector3 projected = toProject.ProjectOntoPlane(normal);

    assert(projected == Vector3(1,1,0));
  }

  /// Reflect Vector
  unittest
  {
    Vector3 normal = Vector3(1,0,0);
    Vector3 reflection = Vector3(-1,0,-1);

    Vector3 reflected = reflection.ReflectVector(normal);

    assert(reflected == Vector3(1,0,-1));
  }

  /// NearlyEquals
  unittest
  {
    Vector3 a = Vector3(1,1,0);
    Vector3 b = Vector3(1+1e-5f,1,-1e-6f);
    Vector3 c = Vector3(1,1,10);
    assert(NearlyEquals(a,b));
    assert(!NearlyEquals(a,c));
  }

  /// Clamp Vector3
  unittest
  {
    Vector3 vec = Vector3(100,0,0);
    Vector3 clamped = vec.ClampSize(1);
    assert(vec == Vector3(100,0,0));
    assert(clamped == Vector3(1,0,0));
  }

  /// Clamp2D Vector3
  unittest
  {
    Vector3 vec = Vector3(100,0,1000);
    Vector3 clamped = vec.ClampSize2D(1);
    assert(vec == Vector3(100,0,1000));
    assert(clamped == Vector3(1,0,1000));
  }

  /// 2D Length
  unittest
  {
    Vector3 vec = Vector3(0,1,1032094);
    assert(vec.Length2D() == 1);
    assert(vec.LengthSquared2D() == 1);
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

    static assert(!__traits(compiles, Vector3(1, 2, 3).Foo), "Swizzling is only supposed to work with value members of " ~ Vector3.stringof ~ ".");
    static assert(!__traits(compiles, Vector3(1, 2, 3).XXXXX), "Swizzling output dimension is limited to 4.");
  }
}
