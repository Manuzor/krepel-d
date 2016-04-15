module krepel.scene.camera_component;

import krepel.scene.scene_component;
import krepel.math;
import krepel.memory;
import krepel.string;
import krepel.scene.game_object;

class CameraComponent : SceneComponent
{
  float FieldOfView;
  float Width;
  float Height;
  float NearPlane;
  float FarPlane;

  this(IAllocator Allocator, UString Name, GameObject Owner)
  {
    super(Allocator, Name, Owner);
  }

  Matrix4 GetProjectionMatrix()
  {
    return CreatePerspectiveMatrix(FieldOfView/2.0f, Width, Height, NearPlane, FarPlane);
  }

  Matrix4 GetViewMatrix()
  {
    auto Result = GetWorldTransform().ToMatrix();
    return Result.SafeInvert();
  }

  Matrix4 GetViewProjectionMatrix()
  {
    return GetViewMatrix() * GetProjectionMatrix();
  }
}
