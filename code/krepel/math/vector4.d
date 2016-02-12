module krepel.math.vector4;

import krepel.math.math;
import krepel.algorithm.comparison;
import krepel.math.vector3;
import std.conv;

@nogc:
@safe:

/// Calculates the Dot Product of the two vectors
/// Input vectors will not be modified
float Dot(Vector4 lhs, Vector4 rhs)
{
  float result = lhs | rhs;
  return result;
}

/// Multiplies two vectors per component returning a new vector containing
/// (lhs.X * rhs.X, lhs.Y * rhs.Y, lhs.Z * rhs.Z)
/// Input vectors will not be modified
Vector4 Mul(Vector4 lhs, Vector4 rhs)
{
  return lhs * rhs;
}

/// Calculates the squared length  of the given vector, which is the same as the dot product with the same vector
/// Input vector will not be modified
float LengthSquared(Vector4 vec)
{
  return vec | vec;
}

/// Calculates the squared length of the X and Y components, ignoring the Z component
/// Input vector will not be modified
float LengthSquared2D(Vector4 vec)
{
  return vec.X * vec.X + vec.Y * vec.Y;
}

/// Calculates the 2D length of the Vector using the square root of the LengthSquared2D
/// Input vector will not be modified
float Length2D(Vector4 vec)
{
  return Sqrt(vec.LengthSquared2D());
}

/// Calculates the 2D length of the Vector using the square root of the LengthSquared
/// Input vector will not be modified
float Length(Vector4 vec)
{
  return Sqrt(vec.LengthSquared());
}

/// Creates a copy of the vector, which is normalized in its length (has a length of 1.0)
Vector4 NormalizedCopy(Vector4 vec)
{
  Vector4 copy = vec;
  copy.Normalize();
  return copy;
}

/// Projects a given vector onto a normal (normal needs to be normalized)
/// Returns the projected vector, which will be a scaled version of the vector
/// Input vectors will not be modified
Vector4 ProjectOntoNormal(Vector4 vec, Vector4 normal)
{
  return normal * (vec | normal);
}

/// Projects a given vector on a plane, which has the given normal (normal needs to be normalized)
/// Returns vector which resides on the plane spanned by the normal
/// Input vector will not be modified
Vector4 ProjectOntoPlane(Vector4 vec, Vector4 normal)
{
  return vec - vec.ProjectOntoNormal(normal);
}

/// Reflects a vector around a normal (normal needs to be normalized)
/// Returns the reflected vector
/// Input vectors will not be modified
Vector4 ReflectVector(Vector4 vec, Vector4 normal)
{
  return vec - (2 * (vec | normal) * normal);
}

/// Checks if any component inside the vector is NaN.
/// Input vector will not be modified
bool ContainsNaN(Vector4 vec)
{
  return IsNaN(vec.X) || IsNaN(vec.Y) || IsNaN(vec.Z);
}

/// Checks if two vectors are nearly equal (are equal with respect to a scaled epsilon)
/// Input vectors will not be modified
bool NearlyEquals(Vector4 a, Vector4 b, float epsilon = 1e-4f)
{
  return krepel.math.NearlyEquals(a.X, b.X, epsilon) &&
         krepel.math.NearlyEquals(a.Y, b.Y, epsilon) &&
         krepel.math.NearlyEquals(a.Z, b.Z, epsilon) &&
         krepel.math.NearlyEquals(a.W, b.W, epsilon);
}

/// Returns a clamped copy of the given vector
/// The retuned vector will be of size <= MaxSize
/// Input vector will not be modified
Vector4 ClampSize(Vector4 vec, float MaxSize)
{
  Vector4 normal = vec.NormalizedCopy();
  return normal * Min(vec.Length(), MaxSize);
}

/// Returns a clamped copy of the X and Y component of the Vector, the Z compnent will be untouched
/// The length of the X and Y component will be <= MaxSize
/// Input vector will not be modified
Vector4 ClampSize2D(Vector4 vec, float MaxSize)
{
  Vector4 clamped = vec;
  clamped.Z = 0;
  clamped.W = 0;
  clamped.Normalize();
  clamped *= Min(vec.Length2D(), MaxSize);
  clamped.Z = vec.Z;
  clamped.W = vec.W;
  return clamped;
}

struct Vector4
{
  @safe:
  @nogc:
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

  this(Vector3 vec, float W)
  {
    this.Data[0..3] = vec.Data[];
    this.W = W;
  }

  this(float X, float Y, float Z, float W)
  {
    this.X = X;
    this.Y = Y;
    this.Z = Z;
    this.W = W;
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
  float opBinary(string op:"|")(Vector4 rhs)
  {
    return
      X * rhs.X +
      Y * rhs.Y +
      Z * rhs.Z +
      W * rhs.W;
  }

  Vector4 opOpAssign(string op)(float rhs)
  {
    static if(op == "*" || op == "/")
    {
      auto result = mixin("Vector4("~
        "X" ~ op ~ "rhs,"
        "Y" ~ op ~ "rhs,"
        "Z" ~ op ~ "rhs,"
        "W" ~ op ~ "rhs)");
      Data = result.Data;
      return this;
    }
    else
    {
      assert(false, "Operator " ~ op ~ " not implemented.");
    }
  }

  //const (char)[] ToString() const
  //{
  //  // TODO: More memory friendly (no GC) implementation?
  //  return "{X:"~text(X)~", Y:"~text(Y)~", Z:"~text(Z)~"}";
  //}

  Vector4 opBinary(string op)(Vector4 rhs) inout
  {
    // Addition, subtraction, component wise multiplication
    static if(op == "+" || op == "-" || op == "*")
    {
      return mixin("Vector4("~
        "X" ~ op ~ "rhs.X,"
        "Y" ~ op ~ "rhs.Y,"
        "Z" ~ op ~ "rhs.Z,"
        "W" ~ op ~ "rhs.W)");
    }
    else
    {
      assert(false, "Operator " ~ op ~ " not implemented.");
    }
  }

  Vector4 opBinary(string op)(float rhs) inout
  {
    // Vector scaling
    static if(op == "/" || op == "*")
    {
      return mixin("Vector4("~
        "X" ~ op ~ "rhs,"
        "Y" ~ op ~ "rhs,"
        "Z" ~ op ~ "rhs,"
        "W" ~ op ~ "rhs)");
    }
    else
    {
      assert(false, "Operator " ~ op ~ " not implemented.");
    }
  }

  Vector4 opBinaryRight(string op)(float rhs) inout
  {
    // Vector scaling
    static if(op == "*")
    {
      return mixin("Vector4("~
        "X" ~ op ~ "rhs,"
        "Y" ~ op ~ "rhs,"
        "Z" ~ op ~ "rhs,"
        "W" ~ op ~ "rhs)");
    }
    else
    {
      assert(false, "Operator " ~ op ~ " not implemented.");
    }
  }

  Vector4 opDispatch(string s)() const
  {
    // Special case for setting X to 0 (_0YZ)
    static if(s.length == 5 && s[0] == '_')
    {
      return mixin(
        "Vector4(" ~ s[1] ~","~
        s[2] ~","~
        s[3] ~","~
        s[4] ~")");
    }
    else static if(s.length == 4 && s[0] != '_')
    {
      return mixin(
        "Vector4(" ~ s[0] ~","~
        s[1] ~","~
        s[2] ~","~
        s[3] ~")");
    }
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
    Vector4 v3 = Vector4(1,2,3,4);
    assert(v3.X == 1);
    assert(v3.Y == 2);
    assert(v3.Z == 3);
    assert(v3.W == 4);
    assert(v3.Data[0] == 1);
    assert(v3.Data[1] == 2);
    assert(v3.Data[2] == 3);
    assert(v3.Data[3] == 4);

    v3 = Vector4(5);
    assert(v3.X == 5);
    assert(v3.Y == 5);
    assert(v3.Z == 5);
    assert(v3.W == 5);
  }

  // Addition test
  unittest
  {
    Vector4 v1 = Vector4(1,2,3,4);
    Vector4 v2 = Vector4(10,11,12,13);
    auto v3 = v1 + v2;
    assert(v3.X == 11);
    assert(v3.Y == 13);
    assert(v3.Z == 15);
    assert(v3.W == 17);
  }

  // Subtraction test
  unittest
  {
    Vector4 v1 = Vector4(1,2,3,4);
    Vector4 v2 = Vector4(10,11,12,13);
    auto v3 = v1 - v2;
    assert(v3.X == -9);
    assert(v3.Y == -9);
    assert(v3.Z == -9);
    assert(v3.W == -9);
  }

  // Float multiplication test
  unittest
  {
    Vector4 v1 = Vector4(1,2,3,4) * 5;
    Vector4 v2 = Vector4(1,2,3,4) * 5.0f;
    assert(v1 == Vector4(5,10,15,20));
    assert(v2 == Vector4(5,10,15,20));

    v1 = 5 * Vector4(1,2,3,4);
    v2 = 5.0f * Vector4(1,2,3,4);
    assert(v1 == Vector4(5,10,15,20));
    assert(v2 == Vector4(5,10,15,20));
  }

  // Float division test
  unittest
  {
    Vector4 v1 = Vector4(5,10,15,20) / 5;
    Vector4 v2 = Vector4(5,10,15,20) / 5.0f;
    assert(v1 == Vector4(1,2,3,4));
    assert(v2 == Vector4(1,2,3,4));

    v1 = Vector4(5,10,15,20);
    v2 = Vector4(5,10,15,20);
    v1 /= 5;
    v2 /= 5.0f;
    assert(v1 == Vector4(1,2,3,4));
    assert(v2 == Vector4(1,2,3,4));
  }

  /// Dot product test
  unittest
  {
    Vector4 v1 = Vector4(1,2,3,4);
    Vector4 v2 = Vector4(10,11,12,13);
    auto v3 = v1 | v2;
    assert(v3 == 10 + 22 + 36 + 52);
    assert(v3 == v1.Dot(v2));
  }

  /// Component wise multiplication test
  unittest
  {
    Vector4 v1 = Vector4(1,2,3,4);
    Vector4 v2 = Vector4(10,11,12,13);
    auto v3 = v1 * v2;
    assert(v3.X == 10);
    assert(v3.Y == 22);
    assert(v3.Z == 36);
    assert(v3.W == 52);
    assert(v3 == v1.Mul(v2));
  }

  /// Normalization
  unittest
  {
    Vector4 vec = Vector4(1,1,1,1);
    vec.Normalize();
    float expected = 1.0f/Sqrt(4);
    assert(vec == Vector4(expected, expected, expected, expected));

    vec = Vector4(1,1,1,1);
    auto normalized = vec.NormalizedCopy();
    auto normalizedUFCS = NormalizedCopy(vec);
    assert(vec == Vector4(1,1,1,1));
    assert(normalized == Vector4(expected, expected, expected, expected));
    assert(normalizedUFCS == Vector4(expected, expected, expected, expected));
  }

  /// Project Onto Normal
  unittest
  {
    Vector4 normal = Vector4.UpVector;
    Vector4 toProject = Vector4(1,1,0.5f,0);

    Vector4 projected = toProject.ProjectOntoNormal(normal);

    assert(projected == Vector4(0,0,0.5f,0));
  }

  /// Project Onto PLane
  unittest
  {
    Vector4 normal = Vector4.UpVector;
    Vector4 toProject = Vector4(1,1,0.5f,0);

    Vector4 projected = toProject.ProjectOntoPlane(normal);

    assert(projected == Vector4(1,1,0,0));
  }

  /// Reflect Vector
  unittest
  {
    Vector4 normal = Vector4(1,0,0,0);
    Vector4 reflection = Vector4(-1,0,-1,0);

    Vector4 reflected = reflection.ReflectVector(normal);

    assert(reflected == Vector4(1,0,-1,0));
  }

  /// NearlyEquals
  unittest
  {
    Vector4 a = Vector4(1,1,0,1);
    Vector4 b = Vector4(1+1e-5f,1,-1e-6f,1);
    Vector4 c = Vector4(1,1,1,10);
    assert(NearlyEquals(a,b));
    assert(!NearlyEquals(a,c));
  }

  /// Clamp Vector4
  unittest
  {
    Vector4 vec = Vector4(0,0,0,100);
    Vector4 clamped = vec.ClampSize(1);
    assert(vec == Vector4(0,0,0,100));
    assert(clamped == Vector4(0,0,0,1));
  }

  /// Clamp2D Vector4
  unittest
  {
    Vector4 vec = Vector4(100,0,1000,2000);
    Vector4 clamped = vec.ClampSize2D(1);
    assert(vec == Vector4(100,0,1000,2000));
    assert(clamped == Vector4(1,0,1000,2000));
  }

  /// 2D Length
  unittest
  {
    Vector4 vec = Vector4(0,1,1032094,34857);
    assert(vec.Length2D() == 1);
    assert(vec.LengthSquared2D() == 1);
  }

  unittest
  {
    Vector4 vec = Vector4(1,2,3,4);

    Vector4 swizzled = vec.Z0YW;

    assert(swizzled == Vector4(3,0,2,4));
  }
}
