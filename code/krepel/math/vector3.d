module krepel.math.vector3;

import krepel.math.math;
import krepel.algorithm.comparison;
import std.conv;

@nogc:
@safe:

float Dot(Vector3 lhs, Vector3 rhs)
{
  float result = lhs | rhs;
  return result;
}

Vector3 Mul(Vector3 lhs, Vector3 rhs)
{
  return lhs * rhs;
}

Vector3 Cross(Vector3 lhs, Vector3 rhs)
{
  return lhs ^ rhs;
}

float LengthSquared(Vector3 vec)
{
  return vec | vec;
}

float LengthSquared2D(Vector3 vec)
{
  return vec.X * vec.X + vec.Y * vec.Y;
}

float Length2D(Vector3 vec)
{
  return Sqrt(vec.LengthSquared2D());
}

float Length(Vector3 vec)
{
  return Sqrt(vec.LengthSquared());
}

Vector3 NormalizedCopy(Vector3 vec)
{
  Vector3 copy = vec;
  copy.Normalize();
  return copy;
}

Vector3 ProjectOntoNormal(Vector3 vec, Vector3 normal)
{
  return normal * (vec | normal);
}

Vector3 ProjectOntoPlane(Vector3 vec, Vector3 normal)
{
  return vec - vec.ProjectOntoNormal(normal);
}

Vector3 ReflectVector(Vector3 vec, Vector3 normal)
{
  return vec - (2 * (vec | normal) * normal);
}

bool ContainsNaN(Vector3 vec)
{
  return IsNaN(vec.X) || IsNaN(vec.Y) || IsNaN(vec.Z);
}

bool NearlyEquals(Vector3 a, Vector3 b, float epsilon = 1e-4f)
{
  return krepel.math.NearlyEquals(a.X, b.X, epsilon) &&
         krepel.math.NearlyEquals(a.Y, b.Y, epsilon) &&
         krepel.math.NearlyEquals(a.Z, b.Z, epsilon);
}

Vector3 ClampSize(Vector3 vec, float MaxSize)
{
  Vector3 normal = vec.NormalizedCopy();
  return normal * Min(vec.Length(), MaxSize);
}

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

  // Don't return result to avoid confusion with NormalizedCopy
  // and stress that this operation modifies the vector on which it is called
  void Normalize()
  {
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
      assert(false, "Operator " ~ op ~ " not implemented.");
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
      assert(false, "Operator " ~ op ~ " not implemented.");
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
      assert(false, "Operator " ~ op ~ " not implemented.");
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
      assert(false, "Operator " ~ op ~ " not implemented.");
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
}
