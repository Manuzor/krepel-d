module krepel.math.transform;

import krepel.math.vector3;
import krepel.math.quaternion;
import krepel.math.matrix4;

struct Transform
{
  Vector3 Translation;
  Quaternion Rotation;
  Vector3 Scale;

  Matrix4 ToMatrix()
  {
    return CreateMatrixFromScaleRotateTranslate(Translation, Rotation, Scale);
  }

  Transform Inverse()
  {
    Transform Result = void;
    Result.Rotation = Rotation.InversedCopy();
    Result.Scale = Scale.Reciprocal();
    Result.Translation = Result.Rotation.TransformVector(Result.Scale * -Translation);
    return Result;
  }

  void SetRelativeTo(in ref Transform ParentTransform)
  {
    const Vector3 ReciprocalScale = (ParentTransform.Scale.Reciprocal(0.0f));
    const Quaternion InverseRotation = ParentTransform.Rotation.InversedCopy();

    Scale = Scale * ReciprocalScale;
    Translation = InverseRotation.TransformVector((Translation - ParentTransform.Translation)) * ReciprocalScale;
    Rotation = InverseRotation * Rotation;
  }

}
