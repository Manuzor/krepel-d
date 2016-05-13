module krepel.scene.horizon_camera_game_object;

import krepel;
import krepel.scene;
import krepel.game_framework;
import krepel.engine;
import krepel.input;

class HorizonCamera : GameObject
{
  float LastYawAngle = -1;
  float LastPitchAngle = -1;
  float Pitch = PI/2.0f;
  float Yaw = 0.0f;
  CameraComponent CamComponent;
  this(IAllocator Allocator, UString Name, SceneGraph World)
  {
    super(Allocator, Name, World);

    CamComponent = ConstructChild!CameraComponent(UString("HorizonCamera", Allocator));
    CamComponent.RegisterComponent();
    with(CamComponent)
    {
      FieldOfView = PI/2;
      Width = 1280;
      Height = 720;
      NearPlane = 0.1f;
      FarPlane = 10.0f;
    }
  }

  override void Start()
  {
    auto InputContext = GlobalEngine.InputContexts[0];
    InputContext.RegisterInputSlot(InputType.Axis, "CameraX");
    InputContext.AddSlotMapping(Mouse.XPosition, "CameraX", -1.0f);

    InputContext.RegisterInputSlot(InputType.Axis, "CameraY");
    InputContext.AddSlotMapping(Mouse.YPosition, "CameraY", -1.0f);
  }

  override void Tick(TickData Tick)
  {
    auto InputContext = GlobalEngine.InputContexts[0];
    float YawAngle = InputContext["CameraX"].AxisValue;
    float PitchAngle = InputContext["CameraY"].AxisValue;
    float DeltaYaw = 0;
    float DeltaPitch = 0;
    if (LastYawAngle == -1)
    {
      LastYawAngle = YawAngle;
      LastPitchAngle = PitchAngle;
    }
    else
    {
      DeltaYaw = YawAngle - LastYawAngle;
      DeltaPitch = PitchAngle - LastPitchAngle;
      LastYawAngle = YawAngle;
      LastPitchAngle = PitchAngle;
    }
    DeltaYaw *= Tick.ElapsedTime  ;
    DeltaPitch *= Tick.ElapsedTime;
    Yaw += DeltaYaw;
    Pitch += DeltaPitch;
    Log.Info("Delta Yaw: %f", DeltaPitch);

    Quaternion Yaw = Quaternion(Vector3.UpVector, Yaw);
    Quaternion Pitch = Quaternion(Vector3.ForwardVector, Pitch);
    auto LocalTransform = CamComponent.GetLocalTransform();
    LocalTransform.Rotation = Yaw * Pitch;
    LocalTransform.Rotation.SafeNormalize();
    CamComponent.SetLocalTransform(LocalTransform);
  }


}
