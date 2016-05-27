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
  float Pitch = 0;
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
      FarPlane = 1000.0f;
    }
  }

  override void Start()
  {
    auto InputContext = GlobalEngine.InputContexts[0];
    InputContext.RegisterInputSlot(InputType.Axis, "CameraForward");
    InputContext.AddSlotMapping(Keyboard.W, "CameraForward", 1);
    InputContext.AddSlotMapping(Keyboard.S, "CameraForward", -1);

    InputContext.RegisterInputSlot(InputType.Axis, "CameraRight");
    InputContext.AddSlotMapping(Keyboard.D, "CameraRight", 1);
    InputContext.AddSlotMapping(Keyboard.A, "CameraRight", -1);


    InputContext.RegisterInputSlot(InputType.Axis, "CameraX");
    InputContext.AddSlotMapping(Mouse.XPosition, "CameraX", 1.0f);

    InputContext.RegisterInputSlot(InputType.Axis, "CameraY");
    InputContext.AddSlotMapping(Mouse.YPosition, "CameraY", 1.0f);
  }

  override void Tick(TickData Tick)
  {
    auto InputContext = GlobalEngine.InputContexts[0];
    float YawAngle = InputContext["CameraX"].AxisValue;
    float PitchAngle = InputContext["CameraY"].AxisValue;
    float MoveForward = InputContext["CameraForward"].AxisValue;
    float MoveRight = InputContext["CameraRight"].AxisValue;
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

    Quaternion Yaw = Quaternion(Vector3.UpVector, Yaw);
    Quaternion Pitch = Quaternion(Vector3.RightVector, Pitch);
    auto LocalTransform = CamComponent.GetLocalTransform();
    Vector3 DeltaMove = CamComponent.GetWorldTransform().ForwardVector * MoveForward * Tick.ElapsedTime;
    LocalTransform.Translation += DeltaMove;
    LocalTransform.Translation += LocalTransform.RightVector * MoveRight * Tick.ElapsedTime;
    LocalTransform.Rotation = Yaw * Pitch;
    LocalTransform.Rotation.SafeNormalize();
    CamComponent.SetLocalTransform(LocalTransform);
  }


}
