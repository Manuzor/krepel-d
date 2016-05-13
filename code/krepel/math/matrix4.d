module krepel.math.matrix4;

import krepel.math.vector3;
import krepel.math.vector4;
import krepel.math.quaternion;
import krepel.math.math;

@safe:

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

Quaternion ToQuaternion(Matrix4 M)
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
  return Result;
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
Vector4 TransformDirection(Matrix4 Mat, Vector4 Vector)
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
  return TransformDirection(Mat, Vector.XYZ1).XYZ;
}

/// Transforms a direction, not taking the translation part of the matrix into account
/// @return Result = Vector.XYZ0*Mat
Vector3 TransformDirection(Matrix4 Mat, Vector3 Vector)
{
  return TransformDirection(Mat, Vector.XYZ0).XYZ;
}

/// Homogenous inverse transform of a 4 dimensional Vector
/// @return Result = Vector*Mat^-1
Vector4 InverseTransformDirection(Matrix4 Mat, Vector4 Vector)
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
  return InverseTransformDirection(Mat, Vector.XYZ1).XYZ;
}

/// InverseTransforms a direction, not taking the translation part of the matrix into account
/// @return Result = Vector.XYZ1*Mat^-1
Vector3 InverseTransformDirection(Matrix4 Mat, Vector3 Vector)
{
  return InverseTransformDirection(Mat, Vector.XYZ0).XYZ;
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
  return Vector3(Mat.M[Type][0..3]);
}

Vector3 GetUnitAxis(Matrix4 Mat, EAxisType Type)
{
  return GetScaledAxis(Mat, Type).SafeNormalizedCopy();
}

/// Create a Left-Hand-Side Perspective Matrix
Matrix4 CreatePerspectiveMatrix(float HalfFOVY, float Width, float Height, float NearPlane, float FarPlane)
{
  return Matrix4([
    [1.0f/ Tan(HalfFOVY), 0.0f, 0.0f, 0.0f],
    [0.0f, Width/ Tan(HalfFOVY)/Height, 0.0f, 0.0f],
    [0.0f, 0.0f, ((NearPlane == FarPlane) ? 1.0f : FarPlane / (FarPlane - NearPlane)), 1.0f],
    [0.0f, 0.0f, -NearPlane * ((NearPlane == FarPlane) ? 1.0f : FarPlane / (FarPlane - NearPlane)), 0.0f],
    ]);
}

Matrix4 CreateOrthogonalMatrix(float Width, float Height, float ZScale, float ZOffset)
{
  return Matrix4([
    [Width ? (1.0f/Width) : 1.0f, 0.0f, 0.0f, 0.0f],
    [0.0f, Height ? (1.0f/Height) : 1.0f, 0.0f, 0.0f],
    [0.0f, 0.0f, ZScale, 0.0f],
    [0.0f, 0.0f, ZOffset * ZScale, 1.0f]
    ]);
}

Matrix4 CreateLookAtMatrix(Vector3 Target, Vector3 Position, Vector3 Up = Vector3.UpVector)
{
  auto Direction = (Target - Position);
  return CreateLookDirMatrix(Direction, Position, Up);
}

Matrix4 CreateLookDirMatrix(Vector3 Direction, Vector3 Position, Vector3 Up = Vector3.UpVector)
{
  Direction = Direction.SafeNormalizedCopy;
  Vector3 Right = Direction ^ Up.SafeNormalizedCopy;
  Up = Right ^ Direction;
  return Matrix4(
    Direction,
    Right,
    Up,
    Position
  );
}

Matrix4 CreateMatrixFromScaleRotateTranslate(Vector3 Position, Quaternion Rotation, Vector3 Scale = Vector3.UnitScaleVector)
{
  Matrix4 Result;

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

  Result.M[0][3] = 0.0f;
  Result.M[1][3] = 0.0f;
  Result.M[2][3] = 0.0f;
  Result.M[3][3] = 1.0f;

  Result[3][0] = Position.X;
  Result[3][1] = Position.Y;
  Result[3][2] = Position.Z;

  return Result;
}

/// 4x4 Matrix accessed first by row, then by column
/// Translation part is stored in the lower row (M[3][0] -> M[3][2])
struct Matrix4
{
  @safe:

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

  auto ref opIndex(int Index) inout
  {
    return M[Index];
  }

  auto ref opIndex(int Row, int Column) inout
  {
    return M[Row][Column];
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
  assert(ExpectedTranspose == Transposed);
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

  Transformed = Mat.TransformDirection(Vector3.ForwardVector);
  assert(Transformed == -Vector3.RightVector);
  Transformed = Mat.InverseTransformDirection(Transformed);
  assert(Transformed == Vector3.ForwardVector);

  Mat = Matrix4(Vector3.ForwardVector, Vector3.RightVector, Vector3.UpVector, Vector3(10,20,50));
  Pos = Vector3(1,0,0);
  ExpectedPos = Vector3(11,20,50);

  Transformed = Mat.TransformPosition(Pos);
  assert(ExpectedPos == Transformed);
  Transformed = Mat.InverseTransformPosition(Transformed);
  assert(Pos == Transformed);

  Transformed = Mat.TransformDirection(Vector3.ForwardVector);
  assert(Transformed == Vector3.ForwardVector);
  Transformed = Mat.InverseTransformDirection(Vector3.ForwardVector);
  assert(Transformed == Vector3.ForwardVector);

  assert(Mat.TransformDirection(Vector4(0,0,0,2)) == Vector4(20, 40, 100, 2));
  assert(Mat.InverseTransformDirection(Mat.TransformDirection(Vector4(0,0,0,2))) == Vector4(0, 0, 0, 2));

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

// Transform Matrix
unittest
{
  const Transform = CreateMatrixFromScaleRotateTranslate(Vector3(1,2,3), Quaternion.Identity, Vector3(2,2,2));
  const Input = Vector3(10,20,30);
  const ResultPosition = Transform.TransformPosition(Input);
  const ResultVector = Transform.TransformDirection(Input);
  assert(ResultPosition == Vector3(21,42,63));
  assert(ResultVector == Vector3(20,40,60));
}

// opIndex
unittest
{
  Matrix4 Mat = Matrix4.Identity;

  assert(Mat[0][0] == 1);
  assert(Mat[0][1] == 0);
  assert(Mat[0][2] == 0);
  assert(Mat[0][3] == 0);

  Mat[0][1] = 10;
  assert(Mat[0][1] == 10);


  assert(Mat[1, 0] == 0);
  assert(Mat[1, 1] == 1);
  assert(Mat[1, 2] == 0);
  assert(Mat[1, 3] == 0);

  Mat[1, 1] = 10;
  assert(Mat[1, 1] == 10);

}

unittest
{
  auto Mat = CreateLookAtMatrix(Vector3.ZeroVector, Vector3.ForwardVector, Vector3.UpVector);
  auto Result = Mat.TransformDirection(Vector3.ForwardVector);
  assert(Result == -Vector3.ForwardVector);
  Result = Mat.TransformPosition(Vector3.ForwardVector);

  assert(Result == Vector3.ZeroVector);
}

unittest
{
  assert(Quaternion.Identity.ToRotationMatrix.ToQuaternion == Quaternion.Identity);
}
