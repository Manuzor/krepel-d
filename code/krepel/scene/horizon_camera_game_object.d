module krepel.scene.horizon_camera_game_object;

import krepel;
import krepel.scene;
import krepel.game_framework;

class HorizonCamera : GameObject
{

  CameraComponent CamComponent;
  this(IAllocator Allocator, UString Name, SceneGraph World)
  {
    super(Allocator, Name, World);

    CamComponent = ConstructChild!CameraComponent(UString("HorizonCamera", Allocator));
    with(CamComponent)
    {
      FieldOfView = PI/2;
      Width = 1280;
      Height = 720;
      NearPlane = 0.1f;
      FarPlane = 10.0f;
    }
  }
    override void Tick(TickData Tick)
    {

    }


}
