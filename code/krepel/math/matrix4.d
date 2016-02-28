module krepel.math.matrix4;

import krepel.math.vector3;
import krepel.math.vector4;
import krepel.math.math;

@nogc:
@safe:
nothrow:

Matrix4 GetTransposed(Matrix4 Mat)
{
  Matrix4 Transposed = void;

  Transposed.M[0][0] = Mat.M[0][0];
  Transposed.M[0][1] = Mat.M[1][0];
  Transposed.M[0][2] = Mat.M[2][0];
  Transposed.M[0][3] = Mat.M[3][0];

  Transposed.M[1][0] = Mat.M[0][1];
  Transposed.M[1][1] = Mat.M[1][1];
  Transposed.M[1][2] = Mat.M[2][1];
  Transposed.M[1][3] = Mat.M[3][1];

  Transposed.M[2][0] = Mat.M[0][2];
  Transposed.M[2][1] = Mat.M[1][2];
  Transposed.M[2][2] = Mat.M[2][2];
  Transposed.M[2][3] = Mat.M[3][2];

  Transposed.M[3][0] = Mat.M[0][3];
  Transposed.M[3][1] = Mat.M[1][3];
  Transposed.M[3][2] = Mat.M[2][3];
  Transposed.M[3][3] = Mat.M[3][3];

  return Transposed;
}

/// Calculcates the Determinant of the 4x4 Matrix
float GetDeterminant(Matrix4 Mat)
{
  /*
  _         _
  |a, b, c, d|
  |e, f, g, h|
  |i, j, k, l|
  |m, n, o ,p|
  _         _
  */

  /*
          |f, g, h|
  DetA = a|j, k, l|
          |n, o ,p|
  */
  float DetA = Mat.M[0][0] * (
    (Mat.M[1][1] * (Mat.M[2][2] * Mat.M[3][3] - Mat.M[2][3] * Mat.M[3][2])) -
    (Mat.M[1][2] * (Mat.M[2][1] * Mat.M[3][3] - Mat.M[2][3] * Mat.M[3][1])) +
    (Mat.M[1][3] * (Mat.M[2][1] * Mat.M[3][2] - Mat.M[2][2] * Mat.M[3][1]))
  );

  /*
          |e, g, h|
  DetB = b|i, k, l|
          |m, o ,p|
  */
  float DetB = Mat.M[0][1] * (
    (Mat.M[1][0] * (Mat.M[2][2] * Mat.M[3][3] - Mat.M[2][3] * Mat.M[3][2])) -
    (Mat.M[1][2] * (Mat.M[2][0] * Mat.M[3][3] - Mat.M[2][3] * Mat.M[3][0])) +
    (Mat.M[1][3] * (Mat.M[2][0] * Mat.M[3][2] - Mat.M[2][2] * Mat.M[3][0]))
  );

  /*
          |e, f, h|
  DetC = c|i, j, l|
          |m, n ,p|
  */
  float DetC = Mat.M[0][2] * (
    (Mat.M[1][0] * (Mat.M[2][1] * Mat.M[3][3] - Mat.M[2][3] * Mat.M[3][1])) -
    (Mat.M[1][1] * (Mat.M[2][0] * Mat.M[3][3] - Mat.M[2][3] * Mat.M[3][0])) +
    (Mat.M[1][3] * (Mat.M[2][0] * Mat.M[3][1] - Mat.M[2][1] * Mat.M[3][0]))
  );

  /*
          |e, f, g|
  DetD = d|i, j, k|
          |m, n ,o|
  */
  float DetD = Mat.M[0][3] * (
    (Mat.M[1][0] * (Mat.M[2][1] * Mat.M[3][2] - Mat.M[2][2] * Mat.M[3][1])) -
    (Mat.M[1][1] * (Mat.M[2][0] * Mat.M[3][2] - Mat.M[2][2] * Mat.M[3][0])) +
    (Mat.M[1][2] * (Mat.M[2][0] * Mat.M[3][1] - Mat.M[2][1] * Mat.M[3][0]))
  );

  return DetA - DetB + DetC - DetD;
}

/// Calculcates the inversion of the matrix, if possible, otherwise return the identity matrix.
/// Additionally checks for Zero scale matrix and returns an Identity Matrix in this case as well.
Matrix4 SafeInvert(Matrix4 Mat)
{
  if (!Mat.IsInvertible() || (
      Mat.GetScaledAxis(EAxisType.X).IsNearlyZero &&
      Mat.GetScaledAxis(EAxisType.Y).IsNearlyZero &&
      Mat.GetScaledAxis(EAxisType.Z).IsNearlyZero
    ))
  {
    return Matrix4.Identity;
  }
  else
  {
    return UnsafeInvert(Mat);
  }
}

/// Runs a Matrix inversion
/// Checks in debug build if it can be inverted and raises an assert if matrix cannot be inverted.
/// No checks in release build.
Matrix4 UnsafeInvert(Matrix4 Mat)
{
  Matrix4 Inverted = void;
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
    Mat.M[1][2] * Mat.M[2][3] * Mat.M[3][1] - Mat.M[1][3] * Mat.M[2][2] * Mat.M[3][1] + Mat.M[1][3] * Mat.M[2][1] * Mat.M[3][2] -
    Mat.M[1][1] * Mat.M[2][3] * Mat.M[3][2] - Mat.M[1][2] * Mat.M[2][1] * Mat.M[3][3] + Mat.M[1][1] * Mat.M[2][2] * Mat.M[3][3]);
  Inverted.M[0][1] = InvDet * (
    Mat.M[0][3] * Mat.M[2][2] * Mat.M[3][1] - Mat.M[0][2] * Mat.M[2][3] * Mat.M[3][1] - Mat.M[0][3] * Mat.M[2][1] * Mat.M[3][2] +
    Mat.M[0][1] * Mat.M[2][3] * Mat.M[3][2] + Mat.M[0][2] * Mat.M[2][1] * Mat.M[3][3] - Mat.M[0][1] * Mat.M[2][2] * Mat.M[3][3]);
  Inverted.M[0][2] = InvDet * (
    Mat.M[0][2] * Mat.M[1][3] * Mat.M[3][1] - Mat.M[0][3] * Mat.M[1][2] * Mat.M[3][1] + Mat.M[0][3] * Mat.M[1][1] * Mat.M[3][2] -
    Mat.M[0][1] * Mat.M[1][3] * Mat.M[3][2] - Mat.M[0][2] * Mat.M[1][1] * Mat.M[3][3] + Mat.M[0][1] * Mat.M[1][2] * Mat.M[3][3]);
  Inverted.M[0][3] = InvDet * (
    Mat.M[0][3] * Mat.M[1][2] * Mat.M[2][1] - Mat.M[0][2] * Mat.M[1][3] * Mat.M[2][1] - Mat.M[0][3] * Mat.M[1][1] * Mat.M[2][2] +
    Mat.M[0][1] * Mat.M[1][3] * Mat.M[2][2] + Mat.M[0][2] * Mat.M[1][1] * Mat.M[2][3] - Mat.M[0][1] * Mat.M[1][2] * Mat.M[2][3]);
  Inverted.M[1][0] = InvDet * (
    Mat.M[1][3] * Mat.M[2][2] * Mat.M[3][0] - Mat.M[1][2] * Mat.M[2][3] * Mat.M[3][0] - Mat.M[1][3] * Mat.M[2][0] * Mat.M[3][2] +
    Mat.M[1][0] * Mat.M[2][3] * Mat.M[3][2] + Mat.M[1][2] * Mat.M[2][0] * Mat.M[3][3] - Mat.M[1][0] * Mat.M[2][2] * Mat.M[3][3]);
  Inverted.M[1][1] = InvDet * (
    Mat.M[0][2] * Mat.M[2][3] * Mat.M[3][0] - Mat.M[0][3] * Mat.M[2][2] * Mat.M[3][0] + Mat.M[0][3] * Mat.M[2][0] * Mat.M[3][2] -
    Mat.M[0][0] * Mat.M[2][3] * Mat.M[3][2] - Mat.M[0][2] * Mat.M[2][0] * Mat.M[3][3] + Mat.M[0][0] * Mat.M[2][2] * Mat.M[3][3]);
  Inverted.M[1][2] = InvDet * (
    Mat.M[0][3] * Mat.M[1][2] * Mat.M[3][0] - Mat.M[0][2] * Mat.M[1][3] * Mat.M[3][0] - Mat.M[0][3] * Mat.M[1][0] * Mat.M[3][2] +
    Mat.M[0][0] * Mat.M[1][3] * Mat.M[3][2] + Mat.M[0][2] * Mat.M[1][0] * Mat.M[3][3] - Mat.M[0][0] * Mat.M[1][2] * Mat.M[3][3]);
  Inverted.M[1][3] = InvDet * (
    Mat.M[0][2] * Mat.M[1][3] * Mat.M[2][0] - Mat.M[0][3] * Mat.M[1][2] * Mat.M[2][0] + Mat.M[0][3] * Mat.M[1][0] * Mat.M[2][2] -
    Mat.M[0][0] * Mat.M[1][3] * Mat.M[2][2] - Mat.M[0][2] * Mat.M[1][0] * Mat.M[2][3] + Mat.M[0][0] * Mat.M[1][2] * Mat.M[2][3]);
  Inverted.M[2][0] = InvDet * (
    Mat.M[1][1] * Mat.M[2][3] * Mat.M[3][0] - Mat.M[1][3] * Mat.M[2][1] * Mat.M[3][0] + Mat.M[1][3] * Mat.M[2][0] * Mat.M[3][1] -
    Mat.M[1][0] * Mat.M[2][3] * Mat.M[3][1] - Mat.M[1][1] * Mat.M[2][0] * Mat.M[3][3] + Mat.M[1][0] * Mat.M[2][1] * Mat.M[3][3]);
  Inverted.M[2][1] = InvDet * (
    Mat.M[0][3] * Mat.M[2][1] * Mat.M[3][0] - Mat.M[0][1] * Mat.M[2][3] * Mat.M[3][0] - Mat.M[0][3] * Mat.M[2][0] * Mat.M[3][1] +
    Mat.M[0][0] * Mat.M[2][3] * Mat.M[3][1] + Mat.M[0][1] * Mat.M[2][0] * Mat.M[3][3] - Mat.M[0][0] * Mat.M[2][1] * Mat.M[3][3]);
  Inverted.M[2][2] = InvDet * (
    Mat.M[0][1] * Mat.M[1][3] * Mat.M[3][0] - Mat.M[0][3] * Mat.M[1][1] * Mat.M[3][0] + Mat.M[0][3] * Mat.M[1][0] * Mat.M[3][1] -
    Mat.M[0][0] * Mat.M[1][3] * Mat.M[3][1] - Mat.M[0][1] * Mat.M[1][0] * Mat.M[3][3] + Mat.M[0][0] * Mat.M[1][1] * Mat.M[3][3]);
  Inverted.M[2][3] = InvDet * (
    Mat.M[0][3] * Mat.M[1][1] * Mat.M[2][0] - Mat.M[0][1] * Mat.M[1][3] * Mat.M[2][0] - Mat.M[0][3] * Mat.M[1][0] * Mat.M[2][1] +
    Mat.M[0][0] * Mat.M[1][3] * Mat.M[2][1] + Mat.M[0][1] * Mat.M[1][0] * Mat.M[2][3] - Mat.M[0][0] * Mat.M[1][1] * Mat.M[2][3]);
  Inverted.M[3][0] = InvDet * (
    Mat.M[1][2] * Mat.M[2][1] * Mat.M[3][0] - Mat.M[1][1] * Mat.M[2][2] * Mat.M[3][0] - Mat.M[1][2] * Mat.M[2][0] * Mat.M[3][1] +
    Mat.M[1][0] * Mat.M[2][2] * Mat.M[3][1] + Mat.M[1][1] * Mat.M[2][0] * Mat.M[3][2] - Mat.M[1][0] * Mat.M[2][1] * Mat.M[3][2]);
  Inverted.M[3][1] = InvDet * (
    Mat.M[0][1] * Mat.M[2][2] * Mat.M[3][0] - Mat.M[0][2] * Mat.M[2][1] * Mat.M[3][0] + Mat.M[0][2] * Mat.M[2][0] * Mat.M[3][1] -
    Mat.M[0][0] * Mat.M[2][2] * Mat.M[3][1] - Mat.M[0][1] * Mat.M[2][0] * Mat.M[3][2] + Mat.M[0][0] * Mat.M[2][1] * Mat.M[3][2]);
  Inverted.M[3][2] = InvDet * (
    Mat.M[0][2] * Mat.M[1][1] * Mat.M[3][0] - Mat.M[0][1] * Mat.M[1][2] * Mat.M[3][0] - Mat.M[0][2] * Mat.M[1][0] * Mat.M[3][1] +
    Mat.M[0][0] * Mat.M[1][2] * Mat.M[3][1] + Mat.M[0][1] * Mat.M[1][0] * Mat.M[3][2] - Mat.M[0][0] * Mat.M[1][1] * Mat.M[3][2]);
  Inverted.M[3][3] = InvDet * (
    Mat.M[0][1] * Mat.M[1][2] * Mat.M[2][0] - Mat.M[0][2] * Mat.M[1][1] * Mat.M[2][0] + Mat.M[0][2] * Mat.M[1][0] * Mat.M[2][1] -
    Mat.M[0][0] * Mat.M[1][2] * Mat.M[2][1] - Mat.M[0][1] * Mat.M[1][0] * Mat.M[2][2] + Mat.M[0][0] * Mat.M[1][1] * Mat.M[2][2]);

  return Inverted;
}

/// Checks if the matrix can be inverted (if the Determinant is non zero)
bool IsInvertible(Matrix4 Mat)
{
  return !NearlyEquals(Mat.GetDeterminant(),0);
}

/// Homogenous transform of a 4 dimensional Vector
/// @return Result = Vector*Mat
Vector4 TransformVector(Matrix4 Mat, Vector4 Vector)
{
  Vector4 Result = void;

  Result.Data[0] = Mat.M[0][0] * Vector.Data[0] + Mat.M[1][0] * Vector.Data[1] + Mat.M[2][0] * Vector.Data[2] + Mat.M[3][0] * Vector.Data[3];
  Result.Data[1] = Mat.M[0][1] * Vector.Data[0] + Mat.M[1][1] * Vector.Data[1] + Mat.M[2][1] * Vector.Data[2] + Mat.M[3][1] * Vector.Data[3];
  Result.Data[2] = Mat.M[0][2] * Vector.Data[0] + Mat.M[1][2] * Vector.Data[1] + Mat.M[2][2] * Vector.Data[2] + Mat.M[3][2] * Vector.Data[3];
  Result.Data[3] = Mat.M[0][3] * Vector.Data[0] + Mat.M[1][3] * Vector.Data[1] + Mat.M[2][3] * Vector.Data[2] + Mat.M[3][3] * Vector.Data[3];

  return Result;
}

/// Homogenous transform of a 3 dimensional Vector
/// @return Result = Vector.XYZ1*Mat
Vector3 TransformPosition(Matrix4 Mat, Vector3 Vector)
{
  return TransformVector(Mat, Vector.XYZ1).XYZ;
}

/// Transforms a direction, not taking the translation part of the matrix into account
/// @return Result = Vector.XYZ0*Mat
Vector3 TransformVector(Matrix4 Mat, Vector3 Vector)
{
  return TransformVector(Mat, Vector.XYZ0).XYZ;
}

/// Homogenous inverse transform of a 4 dimensional Vector
/// @return Result = Vector*Mat^-1
Vector4 InverseTransformVector(Matrix4 Mat, Vector4 Vector)
{
  Vector4 Result = void;

  Matrix4 Inverted = Mat.SafeInvert();

  Result.Data[0] = Inverted.M[0][0] * Vector.Data[0] + Inverted.M[1][0] * Vector.Data[1] + Inverted.M[2][0] * Vector.Data[2] + Inverted.M[3][0] * Vector.Data[3];
  Result.Data[1] = Inverted.M[0][1] * Vector.Data[0] + Inverted.M[1][1] * Vector.Data[1] + Inverted.M[2][1] * Vector.Data[2] + Inverted.M[3][1] * Vector.Data[3];
  Result.Data[2] = Inverted.M[0][2] * Vector.Data[0] + Inverted.M[1][2] * Vector.Data[1] + Inverted.M[2][2] * Vector.Data[2] + Inverted.M[3][2] * Vector.Data[3];
  Result.Data[3] = Inverted.M[0][3] * Vector.Data[0] + Inverted.M[1][3] * Vector.Data[1] + Inverted.M[2][3] * Vector.Data[2] + Inverted.M[3][3] * Vector.Data[3];

  return Result;
}

/// Homogenous inverse transform of a 3 dimensional Vector
/// @return Result = Vector.XYZ1*Mat^-1
Vector3 InverseTransformPosition(Matrix4 Mat, Vector3 Vector)
{
  return InverseTransformVector(Mat, Vector.XYZ1).XYZ;
}

/// InverseTransforms a direction, not taking the translation part of the matrix into account
/// @return Result = Vector.XYZ1*Mat^-1
Vector3 InverseTransformVector(Matrix4 Mat, Vector3 Vector)
{
  return InverseTransformVector(Mat, Vector.XYZ0).XYZ;
}

/// Returns transposed multiplication of the two matrices
Matrix4 MatrixMultiply(const ref Matrix4 Mat1, const ref Matrix4 Mat2)
{
  Matrix4 Result = void;

  Result.M[0][0] = Mat1.M[0][0] * Mat2.M[0][0] + Mat1.M[0][1] * Mat2.M[1][0] + Mat1.M[0][2] * Mat2.M[2][0] + Mat1.M[0][3] * Mat2.M[3][0];
  Result.M[0][1] = Mat1.M[0][0] * Mat2.M[0][1] + Mat1.M[0][1] * Mat2.M[1][1] + Mat1.M[0][2] * Mat2.M[2][1] + Mat1.M[0][3] * Mat2.M[3][1];
  Result.M[0][2] = Mat1.M[0][0] * Mat2.M[0][2] + Mat1.M[0][1] * Mat2.M[1][2] + Mat1.M[0][2] * Mat2.M[2][2] + Mat1.M[0][3] * Mat2.M[3][2];
  Result.M[0][3] = Mat1.M[0][0] * Mat2.M[0][3] + Mat1.M[0][1] * Mat2.M[1][3] + Mat1.M[0][2] * Mat2.M[2][3] + Mat1.M[0][3] * Mat2.M[3][3];

  Result.M[1][0] = Mat1.M[1][0] * Mat2.M[0][0] + Mat1.M[1][1] * Mat2.M[1][0] + Mat1.M[1][2] * Mat2.M[2][0] + Mat1.M[1][3] * Mat2.M[3][0];
  Result.M[1][1] = Mat1.M[1][0] * Mat2.M[0][1] + Mat1.M[1][1] * Mat2.M[1][1] + Mat1.M[1][2] * Mat2.M[2][1] + Mat1.M[1][3] * Mat2.M[3][1];
  Result.M[1][2] = Mat1.M[1][0] * Mat2.M[0][2] + Mat1.M[1][1] * Mat2.M[1][2] + Mat1.M[1][2] * Mat2.M[2][2] + Mat1.M[1][3] * Mat2.M[3][2];
  Result.M[1][3] = Mat1.M[1][0] * Mat2.M[0][3] + Mat1.M[1][1] * Mat2.M[1][3] + Mat1.M[1][2] * Mat2.M[2][3] + Mat1.M[1][3] * Mat2.M[3][3];

  Result.M[2][0] = Mat1.M[2][0] * Mat2.M[0][0] + Mat1.M[2][1] * Mat2.M[1][0] + Mat1.M[2][2] * Mat2.M[2][0] + Mat1.M[2][3] * Mat2.M[3][0];
  Result.M[2][1] = Mat1.M[2][0] * Mat2.M[0][1] + Mat1.M[2][1] * Mat2.M[1][1] + Mat1.M[2][2] * Mat2.M[2][1] + Mat1.M[2][3] * Mat2.M[3][1];
  Result.M[2][2] = Mat1.M[2][0] * Mat2.M[0][2] + Mat1.M[2][1] * Mat2.M[1][2] + Mat1.M[2][2] * Mat2.M[2][2] + Mat1.M[2][3] * Mat2.M[3][2];
  Result.M[2][3] = Mat1.M[2][0] * Mat2.M[0][3] + Mat1.M[2][1] * Mat2.M[1][3] + Mat1.M[2][2] * Mat2.M[2][3] + Mat1.M[2][3] * Mat2.M[3][3];

  Result.M[3][0] = Mat1.M[3][0] * Mat2.M[0][0] + Mat1.M[3][1] * Mat2.M[1][0] + Mat1.M[3][2] * Mat2.M[2][0] + Mat1.M[3][3] * Mat2.M[3][0];
  Result.M[3][1] = Mat1.M[3][0] * Mat2.M[0][1] + Mat1.M[3][1] * Mat2.M[1][1] + Mat1.M[3][2] * Mat2.M[2][1] + Mat1.M[3][3] * Mat2.M[3][1];
  Result.M[3][2] = Mat1.M[3][0] * Mat2.M[0][2] + Mat1.M[3][1] * Mat2.M[1][2] + Mat1.M[3][2] * Mat2.M[2][2] + Mat1.M[3][3] * Mat2.M[3][2];
  Result.M[3][3] = Mat1.M[3][0] * Mat2.M[0][3] + Mat1.M[3][1] * Mat2.M[1][3] + Mat1.M[3][2] * Mat2.M[2][3] + Mat1.M[3][3] * Mat2.M[3][3];

  return Result;
}

enum EAxisType
{
  X,
  Y,
  Z
}

Vector3 GetScaledAxis(Matrix4 Mat, EAxisType Type)
{
  final switch(Type)
  {
  case EAxisType.X:
    return Vector3(Mat.M[0][0],Mat.M[0][1],Mat.M[0][2]);
  case EAxisType.Y:
    return Vector3(Mat.M[1][0],Mat.M[1][1],Mat.M[1][2]);
  case EAxisType.Z:
    return Vector3(Mat.M[2][0],Mat.M[2][1],Mat.M[2][2]);
  }
  assert(false, "No Valid Axis Value");
}

Vector3 GetUnitAxis(Matrix4 Mat, EAxisType Type)
{
  final switch(Type)
  {
  case EAxisType.X:
    return Vector3(Mat.M[0][0],Mat.M[0][1],Mat.M[0][2]).SafeNormalizedCopy();
  case EAxisType.Y:
    return Vector3(Mat.M[1][0],Mat.M[1][1],Mat.M[1][2]).SafeNormalizedCopy();
  case EAxisType.Z:
    return Vector3(Mat.M[2][0],Mat.M[2][1],Mat.M[2][2]).SafeNormalizedCopy();
  }
  assert(false, "No Valid Axis Value");
}

/// 4x4 Matrix accessed first by row, then by column
/// Translation part is stored in the lower row (M[3][0] -> M[3][2])
align(16) struct Matrix4
{
  @nogc:
  @safe:
  nothrow:

  float[4][4] M;

  this(float[4][4] Data)
  {
    M[] = Data[];
  }

  this(Vector3 XAxis, Vector3 YAxis, Vector3 ZAxis, Vector3 Position = Vector3.ZeroVector)
  {
    M = [XAxis.XYZ0.Data,
         YAxis.XYZ0.Data,
         ZAxis.XYZ0.Data,
         Position.XYZ1.Data];
  }

  Vector3 Translation() @property const
  {
    return Vector3(M[3][0..3]);
  }

  Matrix4 opBinary(string Operator)(Matrix4 Mat) const
    if(Operator == "*")
  {
    return MatrixMultiply(this, Mat);
  }

  __gshared immutable Identity = Matrix4([
    [1, 0, 0, 0],
    [0, 1, 0, 0],
    [0, 0, 1, 0],
    [0, 0, 0, 1],
  ]);
}

unittest
{
    Matrix4 Mat = Matrix4([
      [ 1, 2, 3, 4],
      [ 5, 6, 7, 8],
      [ 9,10,11,12],
      [13,14,15,16]]);
    assert(Mat.M[0][0] == 1);
    assert(Mat.M[0][1] == 2);
    assert(Mat.M[0][2] == 3);
    assert(Mat.M[0][3] == 4);

    assert(Mat.M[1][0] == 5);
    assert(Mat.M[1][1] == 6);
    assert(Mat.M[1][2] == 7);
    assert(Mat.M[1][3] == 8);

    assert(Mat.M[2][0] == 9);
    assert(Mat.M[2][1] == 10);
    assert(Mat.M[2][2] == 11);
    assert(Mat.M[2][3] == 12);

    assert(Mat.M[3][0] == 13);
    assert(Mat.M[3][1] == 14);
    assert(Mat.M[3][2] == 15);
    assert(Mat.M[3][3] == 16);
}

unittest
{
  Matrix4 Original = Matrix4([
    [ 1, 2, 3, 4],
    [ 5, 6, 7, 8],
    [ 9,10,11,12],
    [13,14,15,16]]);
  Matrix4 ExpectedTranspose = Matrix4([
    [ 1, 5, 9,13],
    [ 2, 6,10,14],
    [ 3, 7,11,15],
    [ 4, 8,12,16]]);
  Matrix4 Transposed = Original.GetTransposed();
  assert(ExpectedTranspose.M[0][0] == Transposed.M[0][0]);
  assert(ExpectedTranspose.M[0][1] == Transposed.M[0][1]);
  assert(ExpectedTranspose.M[0][2] == Transposed.M[0][2]);
  assert(ExpectedTranspose.M[0][3] == Transposed.M[0][3]);

  assert(ExpectedTranspose.M[1][0] == Transposed.M[1][0]);
  assert(ExpectedTranspose.M[1][1] == Transposed.M[1][1]);
  assert(ExpectedTranspose.M[1][2] == Transposed.M[1][2]);
  assert(ExpectedTranspose.M[1][3] == Transposed.M[1][3]);

  assert(ExpectedTranspose.M[2][0] == Transposed.M[2][0]);
  assert(ExpectedTranspose.M[2][1] == Transposed.M[2][1]);
  assert(ExpectedTranspose.M[2][2] == Transposed.M[2][2]);
  assert(ExpectedTranspose.M[2][3] == Transposed.M[2][3]);

  assert(ExpectedTranspose.M[3][0] == Transposed.M[3][0]);
  assert(ExpectedTranspose.M[3][1] == Transposed.M[3][1]);
  assert(ExpectedTranspose.M[3][2] == Transposed.M[3][2]);
  assert(ExpectedTranspose.M[3][3] == Transposed.M[3][3]);
}

/// GetScaledAxis Value
unittest
{
  Matrix4 Mat = Matrix4([
    [ 1, 2, 3, 4],
    [ 5, 6, 7, 8],
    [ 9,10,11,12],
    [13,14,15,16]]);
  assert(Mat.GetScaledAxis(EAxisType.X) == Vector3(1,2,3));
  assert(Mat.GetScaledAxis(EAxisType.Y) == Vector3(5,6,7));
  assert(Mat.GetScaledAxis(EAxisType.Z) == Vector3(9,10,11));
}

/// GetUnitAxis Value
unittest
{
  Matrix4 Mat = Matrix4([
    [ 5, 0, 0, 4],
    [ 0, 6, 0, 8],
    [ 0, 0,11,12],
    [13,14,15,16]]);
  assert(Mat.GetUnitAxis(EAxisType.X) == Vector3(1,0,0));
  assert(Mat.GetUnitAxis(EAxisType.Y) == Vector3(0,1,0));
  assert(Mat.GetUnitAxis(EAxisType.Z) == Vector3(0,0,1));
}

/// Get Translation
unittest
{
  Matrix4 Mat = Matrix4([
    [ 1, 2, 3, 4],
    [ 5, 6, 7, 8],
    [ 9,10,11,12],
    [13,14,15,16]]);
  assert(Mat.Translation == Vector3(13,14,15));
}

/// Axis creation
unittest
{
  Matrix4 Mat = Matrix4(Vector3(1,0,0), Vector3(0,1,0), Vector3(0,0,1), Vector3(10,50,20));
  Matrix4 Expected = Matrix4([
    [1,0,0,0],
    [0,1,0,0],
    [0,0,1,0],
    [10,50,20,1]]);
    assert(Expected.M[0][0] == Mat.M[0][0]);
    assert(Expected.M[0][1] == Mat.M[0][1]);
    assert(Expected.M[0][2] == Mat.M[0][2]);
    assert(Expected.M[0][3] == Mat.M[0][3]);

    assert(Expected.M[1][0] == Mat.M[1][0]);
    assert(Expected.M[1][1] == Mat.M[1][1]);
    assert(Expected.M[1][2] == Mat.M[1][2]);
    assert(Expected.M[1][3] == Mat.M[1][3]);

    assert(Expected.M[2][0] == Mat.M[2][0]);
    assert(Expected.M[2][1] == Mat.M[2][1]);
    assert(Expected.M[2][2] == Mat.M[2][2]);
    assert(Expected.M[2][3] == Mat.M[2][3]);

    assert(Expected.M[3][0] == Mat.M[3][0]);
    assert(Expected.M[3][1] == Mat.M[3][1]);
    assert(Expected.M[3][2] == Mat.M[3][2]);
    assert(Expected.M[3][3] == Mat.M[3][3]);
}

/// (Inverse)Transform Position/Vector
unittest
{
  // Rotate 90 Degrees CCW around the Z Axis
  Matrix4 Mat = Matrix4(-Vector3.RightVector, Vector3.ForwardVector, Vector3.UpVector, Vector3(0,0,0));
  Vector3 Pos = Vector3(1,0,0);
  Vector3 ExpectedPos = Vector3(0,-1,0);

  Vector3 Transformed = Mat.TransformPosition(Pos);
  assert(ExpectedPos == Transformed);
  Transformed = Mat.InverseTransformPosition(Transformed);
  assert(Pos == Transformed);

  Transformed = Mat.TransformVector(Vector3.ForwardVector);
  assert(Transformed == -Vector3.RightVector);
  Transformed = Mat.InverseTransformVector(Transformed);
  assert(Transformed == Vector3.ForwardVector);

  Mat = Matrix4(Vector3.ForwardVector, Vector3.RightVector, Vector3.UpVector, Vector3(10,20,50));
  Pos = Vector3(1,0,0);
  ExpectedPos = Vector3(11,20,50);

  Transformed = Mat.TransformPosition(Pos);
  assert(ExpectedPos == Transformed);
  Transformed = Mat.InverseTransformPosition(Transformed);
  assert(Pos == Transformed);

  Transformed = Mat.TransformVector(Vector3.ForwardVector);
  assert(Transformed == Vector3.ForwardVector);
  Transformed = Mat.InverseTransformVector(Vector3.ForwardVector);
  assert(Transformed == Vector3.ForwardVector);

  assert(Mat.TransformVector(Vector4(0,0,0,2)) == Vector4(20, 40, 100, 2));
  assert(Mat.InverseTransformVector(Mat.TransformVector(Vector4(0,0,0,2))) == Vector4(0, 0, 0, 2));

}
/// Determinant
unittest
{
  assert(Matrix4.Identity.GetDeterminant() == 1);
  assert(Matrix4.Identity.IsInvertible());

  Matrix4 Mat = Matrix4([
    [ 1, 2, 3, 4],
    [ 5, 6, 7, 8],
    [ 9,10,11,12],
    [13,14,15,16]]);

  assert(Mat.GetDeterminant() == 0);
  assert(!Mat.IsInvertible());

  Mat = Matrix4(Vector3.ForwardVector, Vector3.RightVector, Vector3.UpVector, Vector3(10, 20, 50));
  assert(Mat.GetDeterminant() == 1);
  assert(Mat.IsInvertible());
}

/// Matrix multiplication
unittest
{
  assert(Matrix4.Identity * Matrix4.Identity == Matrix4.Identity);

  Matrix4 Mat = Matrix4([
    [ 1, 2, 3, 4],
    [ 5, 6, 7, 8],
    [ 9,10,11,12],
    [13,14,15,16]]);

  assert(Matrix4.Identity * Mat == Mat);

  Matrix4 Mat2 = Matrix4([
    [16,15,14,13],
    [12,11,10, 9],
    [ 8, 7, 6, 5],
    [ 4, 3, 2, 1]
    ]);

  Matrix4 Expected = Matrix4([
    [80, 70, 60, 50],
    [240, 214, 188, 162],
    [400, 358, 316, 274],
    [560, 502, 444, 386]
    ]);

  assert(Mat * Mat2 == Expected);
}

/// Matrix Inversion
unittest
{
  assert(Matrix4.Identity.SafeInvert() == Matrix4.Identity);

  Matrix4 Matrix = Matrix4([
    [ 1, 2, 3, 4],
    [ 5, 6, 7, 8],
    [ 9,10,11,12],
    [13,14,15,16]]);

  assert(Matrix.SafeInvert() == Matrix4.Identity);

  Matrix = Matrix4(Vector3.ForwardVector, Vector3.RightVector, Vector3.UpVector, Vector3(10, 20, 50));
  assert(Matrix.IsInvertible);
  assert(Matrix * Matrix.SafeInvert() == Matrix4.Identity);
}
