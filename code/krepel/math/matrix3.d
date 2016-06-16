module krepel.math.matrix3;

import krepel.math.vector3;
import krepel.math.quaternion;
import krepel.math.math;

@safe:

Matrix3 GetTransposed(Matrix3 Mat)
{
  Matrix3 Transposed = void;

  Transposed.M[0][0] = Mat.M[0][0];
  Transposed.M[0][1] = Mat.M[1][0];
  Transposed.M[0][2] = Mat.M[2][0];

  Transposed.M[1][0] = Mat.M[0][1];
  Transposed.M[1][1] = Mat.M[1][1];
  Transposed.M[1][2] = Mat.M[2][1];

  Transposed.M[2][0] = Mat.M[0][2];
  Transposed.M[2][1] = Mat.M[1][2];
  Transposed.M[2][2] = Mat.M[2][2];

  return Transposed;
}

/// Calculcates the Determinant of the 3x3 Matrix
float GetDeterminant(Matrix3 Mat)
{
  /*
  _      _
  |a, b, c|
  |d, e, f|
  |g, h, i|
  _      _
  */

  /*
          |e, f|
  DetA = a|h, i|
  */
  float DetA = Mat.M[0][0] * (
    Mat.M[1][1] * Mat.M[2][2] - Mat.M[1][2] * Mat.M[2][1]
  );

  /*
          |d, f|
  DetB = b|g, i|
  */
  float DetB = Mat.M[0][1] * (
    Mat.M[1][0] * Mat.M[2][2] - Mat.M[1][2] * Mat.M[2][0]
  );

  /*
          |d, e|
  DetC = c|g, h|
  */
  float DetC = Mat.M[0][2] * (
    Mat.M[1][0] * Mat.M[2][1] - Mat.M[1][1] * Mat.M[2][0]
  );

  return DetA - DetB + DetC;
}

Quaternion ToQuaternion(Matrix3 M)
{
  Quaternion Result;
  if (M.GetScaledAxis(EAxisType.X).IsNearlyZero() || M.GetScaledAxis(EAxisType.Y).IsNearlyZero() || M.GetScaledAxis(EAxisType.Z).IsNearlyZero())
  {
    Result = Quaternion.Identity;
    return Result;
  }

  //const MeReal *const t = (MeReal *) tm;
  float  HalfInvSqrt;

  // Check diagonal (trace)
  const float Trace = M.M[0][0] + M.M[1][1] + M.M[2][2];

  if (Trace > 0.0f)
  {
    float InvS = InvSqrt(Trace + 1.0f);
    Result.W = 0.5f * (1.0f / InvS);
    HalfInvSqrt = 0.5f * InvS;

    Result.X = (M.M[1][2] - M.M[2][1]) * HalfInvSqrt;
    Result.Y = (M.M[2][0] - M.M[0][2]) * HalfInvSqrt;
    Result.Z = (M.M[0][1] - M.M[1][0]) * HalfInvSqrt;
  }
  else
  {
    // diagonal is negative
    int Index = 0;

    if (M.M[1][1] > M.M[0][0])
      Index = 1;

    if (M.M[2][2] > M.M[Index][Index])
      Index = 2;

    const int[3] Next = [ 1, 2, 0 ];
    const int j = Next[Index];
    const int k = Next[j];

    HalfInvSqrt = M.M[Index][Index] - M.M[j][j] - M.M[k][k] + 1.0f;

    float InvS = InvSqrt(HalfInvSqrt);

    Result.Data[Index] = 0.5f * (1.0f / InvS);

    HalfInvSqrt = 0.5f * InvS;

    Result.Data[3] = (M.M[j][k] - M.M[k][j]) * HalfInvSqrt;
    Result.Data[j] = (M.M[Index][j] + M.M[j][Index]) * HalfInvSqrt;
    Result.Data[k] = (M.M[Index][k] + M.M[k][Index]) * HalfInvSqrt;
  }

  Result.SafeNormalize();
  return Result;
}

/// Calculcates the inversion of the matrix, if possible, otherwise return the identity matrix.
/// Additionally checks for Zero scale matrix and returns an Identity Matrix in this case as well.
Matrix3 SafeInvert(Matrix3 Mat)
{
  if (!Mat.IsInvertible() || (
      Mat.GetScaledAxis(EAxisType.X).IsNearlyZero &&
      Mat.GetScaledAxis(EAxisType.Y).IsNearlyZero &&
      Mat.GetScaledAxis(EAxisType.Z).IsNearlyZero
    ))
  {
    return Matrix3.Identity;
  }
  else
  {
    return UnsafeInvert(Mat);
  }
}

/// Runs a Matrix inversion
/// Checks in debug build if it can be inverted and raises an assert if matrix cannot be inverted.
/// No checks in release build.
Matrix3 UnsafeInvert(Matrix3 Mat)
{
  Matrix3 Inverted = void;
  const float InvDet = 1/Mat.GetDeterminant();

  debug
  {
    assert((!Mat.IsInvertible() || (
        Mat.GetScaledAxis(EAxisType.X).IsNearlyZero &&
        Mat.GetScaledAxis(EAxisType.Y).IsNearlyZero &&
        Mat.GetScaledAxis(EAxisType.Z).IsNearlyZero)
      ) == false, "Matrix can not be inverted, you should use SafeInvert or no Inversion at all.");
  }

  Inverted.M[0][0] = InvDet * (
    Mat.M[1][1] * Mat.M[2][2] - Mat.M[1][2] * Mat.M[2][1] );
  Inverted.M[0][1] = InvDet * (
    Mat.M[0][2] * Mat.M[2][1] - Mat.M[0][1] * Mat.M[2][2] );
  Inverted.M[0][2] = InvDet * (
    Mat.M[0][1] * Mat.M[1][2] - Mat.M[0][2] * Mat.M[1][1] );
  Inverted.M[1][0] = InvDet * (
    Mat.M[1][2] * Mat.M[2][0] - Mat.M[1][0] * Mat.M[2][2] );
  Inverted.M[1][1] = InvDet * (
    Mat.M[0][0] * Mat.M[2][2] - Mat.M[0][2] * Mat.M[2][0] );
  Inverted.M[1][2] = InvDet * (
    Mat.M[0][2] * Mat.M[1][0] - Mat.M[0][0] * Mat.M[1][2] );
  Inverted.M[2][0] = InvDet * (
    Mat.M[1][0] * Mat.M[2][1] - Mat.M[1][1] * Mat.M[2][0] );
  Inverted.M[2][1] = InvDet * (
    Mat.M[0][1] * Mat.M[2][0] - Mat.M[0][0] * Mat.M[2][1] );
  Inverted.M[2][2] = InvDet * (
    Mat.M[0][0] * Mat.M[1][1] - Mat.M[0][1] * Mat.M[1][0] );

  return Inverted;
}

/// Checks if the matrix can be inverted (if the Determinant is non zero)
bool IsInvertible(Matrix3 Mat)
{
  return !NearlyEquals(Mat.GetDeterminant(),0);
}

/// Homogenous transform of a 3 dimensional Vector
/// @return Result = Vector*Mat
Vector3 TransformDirection(Matrix3 Mat, Vector3 Vector)
{
  Vector3 Result = void;

  Result.Data[0] = Mat.M[0][0] * Vector.Data[0] + Mat.M[1][0] * Vector.Data[1] + Mat.M[2][0] * Vector.Data[2];
  Result.Data[1] = Mat.M[0][1] * Vector.Data[0] + Mat.M[1][1] * Vector.Data[1] + Mat.M[2][1] * Vector.Data[2];
  Result.Data[2] = Mat.M[0][2] * Vector.Data[0] + Mat.M[1][2] * Vector.Data[1] + Mat.M[2][2] * Vector.Data[2];

  return Result;
}

/// Homogenous inverse transform of a 3 dimensional Vector
/// @return Result = Vector*Mat^-1
Vector3 InverseTransformDirection(Matrix3 Mat, Vector3 Vector)
{
  Vector3 Result = void;

  Matrix3 Inverted = Mat.SafeInvert();

  Result.Data[0] = Inverted.M[0][0] * Vector.Data[0] + Inverted.M[1][0] * Vector.Data[1] + Inverted.M[2][0] * Vector.Data[2];
  Result.Data[1] = Inverted.M[0][1] * Vector.Data[0] + Inverted.M[1][1] * Vector.Data[1] + Inverted.M[2][1] * Vector.Data[2];
  Result.Data[2] = Inverted.M[0][2] * Vector.Data[0] + Inverted.M[1][2] * Vector.Data[1] + Inverted.M[2][2] * Vector.Data[2];

  return Result;
}

/// Returns transposed multiplication of the two matrices
Matrix3 MatrixMultiply(const ref Matrix3 Mat1, const ref Matrix3 Mat2)
{
  Matrix3 Result = void;

  Result.M[0][0] = Mat1.M[0][0] * Mat2.M[0][0] + Mat1.M[0][1] * Mat2.M[1][0] + Mat1.M[0][2] * Mat2.M[2][0];
  Result.M[0][1] = Mat1.M[0][0] * Mat2.M[0][1] + Mat1.M[0][1] * Mat2.M[1][1] + Mat1.M[0][2] * Mat2.M[2][1];
  Result.M[0][2] = Mat1.M[0][0] * Mat2.M[0][2] + Mat1.M[0][1] * Mat2.M[1][2] + Mat1.M[0][2] * Mat2.M[2][2];

  Result.M[1][0] = Mat1.M[1][0] * Mat2.M[0][0] + Mat1.M[1][1] * Mat2.M[1][0] + Mat1.M[1][2] * Mat2.M[2][0];
  Result.M[1][1] = Mat1.M[1][0] * Mat2.M[0][1] + Mat1.M[1][1] * Mat2.M[1][1] + Mat1.M[1][2] * Mat2.M[2][1];
  Result.M[1][2] = Mat1.M[1][0] * Mat2.M[0][2] + Mat1.M[1][1] * Mat2.M[1][2] + Mat1.M[1][2] * Mat2.M[2][2];

  Result.M[2][0] = Mat1.M[2][0] * Mat2.M[0][0] + Mat1.M[2][1] * Mat2.M[1][0] + Mat1.M[2][2] * Mat2.M[2][0];
  Result.M[2][1] = Mat1.M[2][0] * Mat2.M[0][1] + Mat1.M[2][1] * Mat2.M[1][1] + Mat1.M[2][2] * Mat2.M[2][1];
  Result.M[2][2] = Mat1.M[2][0] * Mat2.M[0][2] + Mat1.M[2][1] * Mat2.M[1][2] + Mat1.M[2][2] * Mat2.M[2][2];

  return Result;
}

enum EAxisType
{
  X,
  Y,
  Z
}

Vector3 GetScaledAxis(Matrix3 Mat, EAxisType Type)
{
  return Vector3(Mat.M[Type][0..3]);
}

Vector3 GetUnitAxis(Matrix3 Mat, EAxisType Type)
{
  return GetScaledAxis(Mat, Type).SafeNormalizedCopy();
}

Matrix3 CreateLookDirMatrix(Vector3 Direction, Vector3 Up = Vector3.UpVector)
{
  Direction = Direction.SafeNormalizedCopy;
  Vector3 Right = Direction ^ Up.SafeNormalizedCopy;
  Up = Right ^ Direction;
  return Matrix3(
    Direction,
    Right,
    Up
  );
}

Matrix3 CreateMatrixFromScaleRotate(Quaternion Rotation, Vector3 Scale = Vector3.UnitScaleVector)
{
  Matrix3 Result;

  const float X2 = Rotation.X + Rotation.X;
  const float Y2 = Rotation.Y + Rotation.Y;
  const float Z2 = Rotation.Z + Rotation.Z;

  const float XX2 = Rotation.X * X2;
  const float YY2 = Rotation.Y * Y2;
  const float ZZ2 = Rotation.Z * Z2;
  const float XY2 = Rotation.X * Y2;
  const float WZ2 = Rotation.W * Z2;
  const float YZ2 = Rotation.Y * Z2;
  const float WX2 = Rotation.W * X2;
  const float XZ2 = Rotation.X * Z2;
  const float WY2 = Rotation.W * Y2;

  Result[0][0] = (1.0f - (YY2 + ZZ2)) * Scale.X;
  Result[0][1] = (XY2 + WZ2) * Scale.X;
  Result[0][2] = (XZ2 - WY2) * Scale.X;
  Result[1][0] = (XY2 - WZ2) * Scale.Y;
  Result[1][1] = (1.0f - (XX2 + ZZ2)) * Scale.Y;
  Result[1][2] = (YZ2 + WX2) * Scale.Y;
  Result[2][0] = (XZ2 + WY2) * Scale.Z;
  Result[2][1] = (YZ2 - WX2) * Scale.Z;
  Result[2][2] = (1.0f - (XX2 + YY2)) * Scale.Z;

  return Result;
}

/// 3x3 Matrix accessed first by row, then by column
struct Matrix3
{
  @safe:

  float[3][3] M;

  this(float[3][3] Data)
  {
    M[] = Data[];
  }

  this(Vector3 XAxis, Vector3 YAxis, Vector3 ZAxis)
  {
    M = [XAxis.Data,
         YAxis.Data,
         ZAxis.Data
         ];
  }

  Matrix3 opBinary(string Operator)(Matrix3 Mat) const
    if(Operator == "*")
  {
    return MatrixMultiply(this, Mat);
  }

  auto ref opIndex(int Index) inout
  {
    return M[Index];
  }

  auto ref opIndex(int Row, int Column) inout
  {
    return M[Row][Column];
  }

  __gshared immutable Identity = Matrix3([
    [1, 0, 0],
    [0, 1, 0],
    [0, 0, 1]
  ]);
}

unittest
{
    Matrix3 Mat = Matrix3([
      [ 1, 2, 3],
      [ 5, 6, 7],
      [ 9,10,11]]);
    assert(Mat.M[0][0] == 1);
    assert(Mat.M[0][1] == 2);
    assert(Mat.M[0][2] == 3);

    assert(Mat.M[1][0] == 5);
    assert(Mat.M[1][1] == 6);
    assert(Mat.M[1][2] == 7);

    assert(Mat.M[2][0] == 9);
    assert(Mat.M[2][1] == 10);
    assert(Mat.M[2][2] == 11);
}

unittest
{
  Matrix3 Original = Matrix3([
    [ 1, 2, 3],
    [ 5, 6, 7],
    [ 9,10,11]]);
  Matrix3 ExpectedTranspose = Matrix3([
    [ 1, 5, 9],
    [ 2, 6,10],
    [ 3, 7,11]]);
  Matrix3 Transposed = Original.GetTransposed();
  assert(ExpectedTranspose == Transposed);
}

/// GetScaledAxis Value
unittest
{
  Matrix3 Mat = Matrix3([
    [ 1, 2, 3],
    [ 5, 6, 7],
    [ 9,10,11]]);
  assert(Mat.GetScaledAxis(EAxisType.X) == Vector3(1,2,3));
  assert(Mat.GetScaledAxis(EAxisType.Y) == Vector3(5,6,7));
  assert(Mat.GetScaledAxis(EAxisType.Z) == Vector3(9,10,11));
}

/// GetUnitAxis Value
unittest
{
  Matrix3 Mat = Matrix3([
    [ 5, 0, 0],
    [ 0, 6, 0],
    [ 0, 0,11]]);
  assert(Mat.GetUnitAxis(EAxisType.X) == Vector3(1,0,0));
  assert(Mat.GetUnitAxis(EAxisType.Y) == Vector3(0,1,0));
  assert(Mat.GetUnitAxis(EAxisType.Z) == Vector3(0,0,1));
}

/// Axis creation
unittest
{
  Matrix3 Mat = Matrix3(Vector3(1,0,0), Vector3(0,1,0), Vector3(0,0,1));
  Matrix3 Expected = Matrix3([
    [1,0,0],
    [0,1,0],
    [0,0,1]]);
    assert(Expected.M[0][0] == Mat.M[0][0]);
    assert(Expected.M[0][1] == Mat.M[0][1]);
    assert(Expected.M[0][2] == Mat.M[0][2]);

    assert(Expected.M[1][0] == Mat.M[1][0]);
    assert(Expected.M[1][1] == Mat.M[1][1]);
    assert(Expected.M[1][2] == Mat.M[1][2]);

    assert(Expected.M[2][0] == Mat.M[2][0]);
    assert(Expected.M[2][1] == Mat.M[2][1]);
    assert(Expected.M[2][2] == Mat.M[2][2]);
}

/// (Inverse)Transform Position/Vector
unittest
{
  // Rotate 90 Degrees CCW around the Z Axis
  Matrix3 Mat = Matrix3(-Vector3.RightVector, Vector3.ForwardVector, Vector3.UpVector);
  Vector3 Pos = Vector3(1,0,0);

  auto Transformed = Mat.TransformDirection(Vector3.ForwardVector);
  assert(Transformed == -Vector3.RightVector);
  Transformed = Mat.InverseTransformDirection(Transformed);
  assert(Transformed == Vector3.ForwardVector);

  Mat = Matrix3(Vector3.ForwardVector, Vector3.RightVector, Vector3.UpVector);

  Transformed = Mat.TransformDirection(Vector3.ForwardVector);
  assert(Transformed == Vector3.ForwardVector);
  Transformed = Mat.InverseTransformDirection(Vector3.ForwardVector);
  assert(Transformed == Vector3.ForwardVector);

}
/// Determinant
unittest
{
  assert(Matrix3.Identity.GetDeterminant() == 1);
  assert(Matrix3.Identity.IsInvertible());

  Matrix3 Mat = Matrix3([
    [ 1, 2, 3],
    [ 5, 6, 7],
    [ 9,10,11]]);

  assert(Mat.GetDeterminant() == 0);
  assert(!Mat.IsInvertible());

  Mat = Matrix3(Vector3.ForwardVector, Vector3.RightVector, Vector3.UpVector);
  assert(Mat.GetDeterminant() == 1);
  assert(Mat.IsInvertible());
}

/// Matrix multiplication
unittest
{
  assert(Matrix3.Identity * Matrix3.Identity == Matrix3.Identity);

  Matrix3 Mat = Matrix3([
    [ 1, 2, 3],
    [ 5, 6, 7],
    [ 9,10,11]]);

  assert(Matrix3.Identity * Mat == Mat);

  Matrix3 Mat2 = Matrix3([
    [16,15,14],
    [12,11,10],
    [ 8, 7, 6]
    ]);

  Matrix3 Expected = Matrix3([
    [64, 58, 52 ],
    [208, 190, 172],
    [352, 322, 292]
    ]);

  assert(Mat * Mat2 == Expected);
}

/// Matrix Inversion
unittest
{
  assert(Matrix3.Identity.SafeInvert() == Matrix3.Identity);

  Matrix3 Matrix = Matrix3([
    [ 1, 2, 3],
    [ 5, 6, 7],
    [ 9,10,11]]);

  assert(Matrix.SafeInvert() == Matrix3.Identity);

  Matrix = Matrix3(Vector3.ForwardVector, Vector3.RightVector, Vector3.UpVector);
  assert(Matrix.IsInvertible);
  assert(Matrix * Matrix.SafeInvert() == Matrix3.Identity);
}

// Transform Matrix
unittest
{
  const Transform = CreateMatrixFromScaleRotate(Quaternion.Identity, Vector3(2,2,2));
  const Input = Vector3(10,20,30);
  const ResultVector = Transform.TransformDirection(Input);
  assert(ResultVector == Vector3(20,40,60));
}

// opIndex
unittest
{
  Matrix3 Mat = Matrix3.Identity;

  assert(Mat[0][0] == 1);
  assert(Mat[0][1] == 0);
  assert(Mat[0][2] == 0);

  Mat[0][1] = 10;
  assert(Mat[0][1] == 10);


  assert(Mat[1, 0] == 0);
  assert(Mat[1, 1] == 1);
  assert(Mat[1, 2] == 0);

  Mat[1, 1] = 10;
  assert(Mat[1, 1] == 10);

}

unittest
{
  auto RotationMatrix = Quaternion.Identity.ToRotationMatrix;
  auto NewQuat = RotationMatrix.ToQuaternion;
  assert(krepel.math.quaternion.NearlyEquals(NewQuat, Quaternion.Identity));
}
