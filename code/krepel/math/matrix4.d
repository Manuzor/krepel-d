module krepel.math.matrix4;

import krepel.math.vector3;

@nogc:
@safe:
nothrow:

Matrix4 GetTransposed(Matrix4 Mat)
{
  Matrix4 Transposed;

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

/// Returns transposed multiplication of the two matrices
Matrix4 MatrixMultiply(const ref Matrix4 Mat1, const ref Matrix4 Mat2)
{
  Matrix4 Result;

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

Vector3 GetAxis(Matrix4 Mat, EAxisType Type)
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

/// GetAxis Value
unittest
{
  Matrix4 Mat = Matrix4([
    [ 1, 2, 3, 4],
    [ 5, 6, 7, 8],
    [ 9,10,11,12],
    [13,14,15,16]]);
  assert(Mat.GetAxis(EAxisType.X) == Vector3(1,2,3));
  assert(Mat.GetAxis(EAxisType.Y) == Vector3(5,6,7));
  assert(Mat.GetAxis(EAxisType.Z) == Vector3(9,10,11));
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
