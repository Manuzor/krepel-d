module krepel.math.vector3;

import krepel.math.math;

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

float Length(Vector3 vec)
{
  return Sqrt(vec.LengthSquared());
}


struct Vector3
{
  union
  {
    struct{
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

  Vector3 opBinary(string op)(Vector3 rhs)
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

  Vector3 opBinary(string op)(float rhs)
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

  Vector3 opBinaryRight(string op)(float rhs)
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

  static Vector3 Forward = Vector3(1,0,0);
  static Vector3 Right = Vector3(0,1,0);
  static Vector3 Up = Vector3(0,0,1);

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
    auto vec = Vector3.Up ^ Vector3.Forward;
    assert(vec == Vector3.Right);
    // Function
    assert(Cross(Vector3.Up, Vector3.Forward) == Vector3.Right);
    Vector3 vec1 = Vector3.Up;
    Vector3 vec2 = Vector3.Forward;
    // UFCS
    Vector3 vec3 = vec1.Cross(vec2);
    assert(vec3 == Vector3.Right);
  }
}
