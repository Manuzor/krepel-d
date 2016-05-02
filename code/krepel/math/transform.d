module krepel.math.transform;

import krepel.math.vector3;
import krepel.math.quaternion;
import krepel.math.matrix4;
import krepel.math.math;

Vector3 TransformDirection(in ref Transform Transformation, Vector3 Vec)
{
  with(Transformation)
  {
    return (Rotation * (Scale * Vec));
  }
}

Vector3 TransformPosition(in ref Transform Transformation, Vector3 Vec)
{
  with(Transformation)
  {
    return (Rotation * (Scale * Vec)) + Translation;
  }
}

Vector3 InverseTransformDirection(in ref Transform Transformation, Vector3 Vec)
{
  with(Transformation)
  {
    return krepel.math.quaternion.InverseTransformDirection(Rotation,Vec) * Scale.Reciprocal(0);
  }
}

Vector3 InverseTransformPosition(in ref Transform Transformation, Vector3 Vec)
{
  with(Transformation)
  {
    return krepel.math.quaternion.InverseTransformDirection(Rotation, Vec - Translation) * Scale.Reciprocal(0);
  }
}


Transform Concatenate(in ref Transform A, in ref Transform B)
{
  Transform Result = void;
  Result.Rotation = B.Rotation * A.Rotation;
  Result.Scale = B.Scale * A.Scale;
  Result.Translation = B.Rotation * (B.Scale * A.Translation) + B.Translation;
  return Result;
}

Transform InversedCopy(in ref Transform InputTransform)
{
  Transform Result = void;
  with(InputTransform)
  {
    Result.Rotation = krepel.math.quaternion.InversedCopy(Rotation);
    Result.Scale = Scale.Reciprocal();
    Result.Translation = krepel.math.quaternion.TransformDirection(Result.Rotation, Result.Scale * -Translation);
  }
  return Result;
}

struct Transform
{
  Vector3 Translation;
  Quaternion Rotation;
  Vector3 Scale;

  Matrix4 ToMatrix()
  {
    return CreateMatrixFromScaleRotateTranslate(Translation, Rotation, Scale);
  }

  void SetRelativeTo(in Transform ParentTransform)
  {
    const Vector3 ReciprocalScale = (ParentTransform.Scale.Reciprocal(0.0f));
    const Quaternion InverseRotation = krepel.math.quaternion.InversedCopy(ParentTransform.Rotation);

    Scale = Scale * ReciprocalScale;
    Translation = krepel.math.quaternion.TransformDirection(InverseRotation, (Translation - ParentTransform.Translation)) * ReciprocalScale;
    Rotation = InverseRotation * Rotation;
  }

  Transform opBinary(string Operator : "*")(in ref Transform Other)
  {
    return Concatenate(this, Other);
  }

  void opOpAssign(string Operator : "*")(in ref Transform Other)
  {
    this = Concatenate(this, Other);
  }

  __gshared immutable Identity = Transform(Vector3.ZeroVector, Quaternion.Identity, Vector3.UnitScaleVector);

}


unittest
{
  Transform A = Transform(Vector3(1,2,3), Quaternion.Identity, Vector3(5,4,3));
  assert(A.Translation == Vector3(1,2,3));
  assert(A.Rotation == Quaternion.Identity);
  assert(A.Scale == Vector3(5,4,3));
}

unittest
{
  Transform A = Transform(Vector3(1,2,3), Quaternion.Identity, Vector3.UnitScaleVector);
  Transform B = Transform(Vector3(5,6,7), Quaternion.Identity, Vector3.UnitScaleVector);

  auto Result = A * B;
  assert(Result.Translation == Vector3(6,8,10));
  assert(Result.Rotation == Quaternion.Identity);
  assert(Result.Scale == Vector3.UnitScaleVector);
  A = Transform(Vector3(1,2,3), Quaternion(Vector3(0,0,1), -PI/2), Vector3.UnitScaleVector);
  B = Transform(Vector3(0,0,0), Quaternion(Vector3(0,0,1), PI/2), Vector3.UnitScaleVector);

  Result = A * B;
  assert(Result.Translation.NearlyEquals(Vector3(-2,1,3)));
  assert(Result.Rotation.NearlyEquals(Quaternion.Identity));
  assert(Result.Scale.NearlyEquals(Vector3.UnitScaleVector));
}

unittest
{
  Transform A = Transform(Vector3(1,2,3), Quaternion(Vector3(0,0,1), -PI/2), Vector3(5,6,7));
  auto B = A.InversedCopy();

  auto Result = A * B;
  assert(Result.Translation.NearlyEquals(Vector3.ZeroVector));
  assert(Result.Rotation.NearlyEquals(Quaternion.Identity));
  assert(Result.Scale.NearlyEquals(Vector3.UnitScaleVector));
}
