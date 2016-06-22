module krepel.win32_main;
version(Windows):

import krepel;
import krepel.win32;
import krepel.math;
import krepel.input;
import krepel.string;

import krepel.win32.directx.dxgi;
import krepel.win32.directx.d3d11;
import krepel.win32.directx.xinput;
import krepel.win32.directx.uuidof;

import krepel.d3d11_render_device;
import krepel.render_device;
import krepel.resources;
import krepel.scene;
import krepel.forward_renderer;
import krepel.physics;
import krepel.engine;
import krepel.color;

version(Windows):
import std.string : toStringz, fromStringz;

extern(Windows)
int WinMain(HINSTANCE Instance, HINSTANCE PreviousInstance,
            LPSTR CommandLine, int ShowCode)
{
  int Result = void;

  try
  {
    import core.runtime;

    Runtime.initialize();

    Result = MyWinMain(Instance, PreviousInstance, CommandLine, ShowCode);

    Runtime.terminate();
  }
  catch(Throwable Error)
  {

    auto ErrorString = Error.toString();
    auto ShortErrorString = ErrorString[0 .. Min(2000, ErrorString.length)];
    MessageBoxA(null, ShortErrorString.toStringz(),
                "Error",
                MB_OK | MB_ICONEXCLAMATION);

    Result = 0;
  }

  return Result;
}

__gshared bool GlobalRunning;

class WindowData
{
  Win32InputContext Input;

  this(Win32InputContext Input)
  {
    this.Input = Input;
  }
}

void Win32SetupConsole(in char* Title)
{
  static import core.stdc.stdio;

  AllocConsole();
  AttachConsole(GetCurrentProcessId());
  core.stdc.stdio.freopen("CON", "w", core.stdc.stdio.stdout);
  SetConsoleTitleA(Title);
}

int MyWinMain(HINSTANCE Instance, HINSTANCE PreviousInstance,
              LPSTR CommandLine, int ShowCode)
{
  //MessageBoxA(null, "Hello World?", "Hello", MB_OK);

  const MemorySize = 6.GiB;
  auto RawMemory = VirtualAlloc(cast(void*)0x0000010000000000,
                                MemorySize,
                                MEM_RESERVE | MEM_COMMIT,
                                PAGE_READWRITE);
  if(RawMemory is null)
  {
    return 1;
  }
  assert(RawMemory);
  //auto Heap = HeapMemory((cast(ubyte*)RawMemory)[0 .. MemorySize]);
  auto Heap = SystemMemory();
  debug
  {
    MemoryVerifier Verifier = MemoryVerifier(Heap.Wrap());
    IAllocator MainAllocator = Verifier.Wrap();
  }
  else
  {
    IAllocator MainAllocator = Heap.Wrap();
  }

  StaticStackMemory!(10.KiB) LogMemory;

  Log = MainAllocator.New!LogData(LogMemory.Wrap);
  Log.MessageBuffer.Reserve(5.KiB);
  scope(success)
  {
    MainAllocator.Delete(Log);
    Log = null;
  }

  debug Win32SetupConsole("Krepel Console - Win32 Experiments".ptr);

  Log.Sinks ~= ToDelegate(&StdoutLogSink);
  Log.Sinks ~= ToDelegate(&VisualStudioLogSink);

  Log.Info("=== Beginning of Log");
  scope(exit) Log.Info("=== End of Log");


  WNDCLASSA WindowClass;
  with(WindowClass)
  {
    style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
    lpfnWndProc = cast(typeof(lpfnWndProc))cast(void*)&Win32MainWindowCallback;
    hInstance = Instance;
    lpszClassName = "D_WindowClass";
  }

  if(RegisterClassA(&WindowClass))
  {
    auto WindowHandle = CreateWindowExA(0,
                                        WindowClass.lpszClassName,
                                        "The Title Text".ptr,
                                        WS_OVERLAPPEDWINDOW | WS_VISIBLE,
                                        CW_USEDEFAULT, CW_USEDEFAULT,
                                        CW_USEDEFAULT, CW_USEDEFAULT,
                                        null,
                                        null,
                                        Instance,
                                        null);

    EngineCreationInformation Info;
    Info.Instance = Instance;
    Info.WindowHandle = WindowHandle;
    SetupGobalEngine(MainAllocator, Info);

    if(WindowHandle)
    {
      MeshResource UnitPlane = GlobalEngine.Resources.LoadMesh(WString("../data/mesh/UnitPlane.obj", MainAllocator));
      MeshResource Cube = GlobalEngine.Resources.LoadMesh(WString("../data/mesh/Cube.obj", MainAllocator));
      scope(exit)
      {
        GlobalEngine.Resources.DestroyResource(UnitPlane);
      }


      PolyShapeData BoxShape = CreatePolyShapeFromBox(MainAllocator, Vector3.UnitScaleVector);

      PrimitiveRenderComponent RenderChild;

      SceneGraph Graph = MainAllocator.New!(SceneGraph)(MainAllocator);
      GlobalEngine.RegisterScene(Graph);
      auto CameraObject= Graph.CreateGameObject!HorizonCamera(UString("Camera", MainAllocator));
      auto CameraComponent = cast(CameraComponent)CameraObject.RootComponent;
      CameraComponent.SetWorldTransform(Transform(Vector3(-5,0,3), Quaternion.Identity, Vector3.UnitScaleVector));
      Matrix4 Mat = CameraComponent.GetViewProjectionMatrix().GetTransposed;
      auto Plane = Graph.CreateDefaultGameObject(UString("Plane", MainAllocator));
      auto PlanePhysicsChild = Plane.ConstructChild!PhysicsComponent(UString("PlanePhysics", MainAllocator));
      PlaneShapeData ShapeData = PlaneShapeData(Vector4(0,0,1,0));
      PlanePhysicsChild.ComponentBody.Shape.SetPlane(ShapeData);
      PlanePhysicsChild.ComponentBody.BodyMovability = Movability.Static;
      PlanePhysicsChild.ComponentBody.Mass = float.infinity;
      PlanePhysicsChild.RegisterComponent();
      RenderChild = Plane.ConstructChild!PrimitiveRenderComponent(UString("PlaneRender", MainAllocator), PlanePhysicsChild);
      PlanePhysicsChild.SetWorldTransform(Transform(Vector3(0,0,-1), Quaternion.Identity, Vector3.UnitScaleVector* 100));
      RenderChild.SetMesh(UnitPlane);
      //RenderChild.BodyColor = Colors.Green;
      RenderChild.RegisterComponent();

      auto Sphere = Graph.CreateDefaultGameObject(UString("Sphere", MainAllocator));
      auto SpherePhysicsChild = Sphere.ConstructChild!PhysicsComponent(UString("SpherePhysics", MainAllocator));
      auto SphereData = SphereShapeData(1.0f);
      SpherePhysicsChild.ComponentBody.Shape.SetPoly(BoxShape);
      //SpherePhysicsChild.ComponentBody.Restitution = 0.9f;
      SpherePhysicsChild.ComponentBody.Mass = 1.0f;
      SpherePhysicsChild.ComponentBody.SetBoxInertiaTensor(Vector3.UnitScaleVector);
      SpherePhysicsChild.RegisterComponent();
      RenderChild = Sphere.ConstructChild!PrimitiveRenderComponent(UString("SphereRender", MainAllocator), SpherePhysicsChild);
      RenderChild.SetWorldTransform(Transform(Vector3(0,0,0), Quaternion.Identity, Vector3.UnitScaleVector));
      RenderChild.SetMesh(Cube);
      RenderChild.RegisterComponent();
      SpherePhysicsChild.SetWorldTransform(Transform(Vector3(0,0,1.0f), Quaternion(Vector3.UnitScaleVector, 1.0f), Vector3.UnitScaleVector));
      SpherePhysicsChild.SetWorldTransform(Transform(Vector3(0,0,2.0f), Quaternion.Identity, Vector3.UnitScaleVector));

      auto Sphere2 = Graph.CreateDefaultGameObject(UString("Sphere2", MainAllocator));
      auto Sphere2PhysicsChild = Sphere2.ConstructChild!PhysicsComponent(UString("Sphere2Physics", MainAllocator));
      Sphere2PhysicsChild.ComponentBody.Shape.SetPoly(BoxShape);
      //Sphere2PhysicsChild.ComponentBody.BodyMovability = Movability.Static;
      SpherePhysicsChild.ComponentBody.SetBoxInertiaTensor(Vector3.UnitScaleVector);

      Sphere2PhysicsChild.RegisterComponent();
      RenderChild = Sphere2.ConstructChild!PrimitiveRenderComponent(UString("Sphere2Render", MainAllocator), Sphere2PhysicsChild);
      Sphere2PhysicsChild.SetWorldTransform(Transform(Vector3(0.0f,0.0f,5), Quaternion.Identity, Vector3.UnitScaleVector));
      RenderChild.SetMesh(Cube);
      RenderChild.RegisterComponent();


      GlobalEngine.Renderer.ActiveCamera = CameraComponent;
      const float Distance = 3.5f;
      const Vector3 Offset = Vector3(3,3,2);

      ColorLinear[10] BodyColors = [Colors.White, Colors.Red, Colors.Green, Colors.Blue, Colors.Orange, Colors.Yellow, Colors.Lime, Colors.Pink, Colors.Azure, Colors.Magenta];

      for(int X=0; X < 2; X++)
      {
        for(int Y=0; Y< 2; Y++)
        {
          for(int Z =0; Z<2;Z++)
          {
            auto CubeObj = Graph.CreateDefaultGameObject(UString("Cube", MainAllocator));
            auto CubePhysicsChild = CubeObj.ConstructChild!PhysicsComponent(UString("CubePhysics", MainAllocator));
            CubePhysicsChild.ComponentBody.Shape.SetPoly(BoxShape);
            CubePhysicsChild.ComponentBody.Mass = 1.0f;
            CubePhysicsChild.ComponentBody.SetBoxInertiaTensor(Vector3.UnitScaleVector);
            CubePhysicsChild.RegisterComponent();
            RenderChild = CubeObj.ConstructChild!PrimitiveRenderComponent(UString("CubeRender", MainAllocator), CubePhysicsChild);
            RenderChild.SetWorldTransform(Transform(Vector3(0,0,0), Quaternion.Identity, Vector3.UnitScaleVector));
            RenderChild.SetMesh(Cube);
            RenderChild.BodyColor = BodyColors[(Z*2*2+Y*2+X)%BodyColors.length];
            RenderChild.RegisterComponent();

            CubePhysicsChild.SetWorldTransform(Transform(Offset+ Vector3(X*Distance,Y*Distance,Z*Distance)));
          }
        }
      }





      version(XInput_RuntimeLinking) LoadXInput();


      auto User1Input = cast(Win32InputContext)GlobalEngine.InputContexts[0];

      User1Input.RegisterInputSlot(InputType.Button, "Quit");
      User1Input.AddSlotMapping(Keyboard.Escape, "Quit");
      User1Input.AddSlotMapping(XInput.Start, "Quit");

      User1Input.RegisterInputSlot(InputType.Axis, "ObjX");
      User1Input.RegisterInputSlot(InputType.Axis, "ObjY");
      User1Input.RegisterInputSlot(InputType.Axis, "ObjZ");
      User1Input.AddSlotMapping(Keyboard.Q, "ObjZ");
      User1Input.AddSlotMapping(Keyboard.E, "ObjZ", -1);
      User1Input.AddSlotMapping(Keyboard.Right, "ObjY");
      User1Input.AddSlotMapping(Keyboard.Left, "ObjY", -1);
      User1Input.AddSlotMapping(Keyboard.Up, "ObjX");
      User1Input.AddSlotMapping(Keyboard.Down, "ObjX", -1);


      auto Window = MainAllocator.New!WindowData(User1Input);
      scope(exit) MainAllocator.Delete(Window);

      SetWindowLongPtrA(WindowHandle, GWLP_USERDATA, *cast(LONG_PTR*)&Window);
      scope(exit) SetWindowLongPtrA(WindowHandle, GWLP_USERDATA, cast(LONG_PTR)null);

      GlobalRunning = true;
      float Angle = 0.0f;
      while(GlobalRunning)
      {


        if(User1Input["Quit"].ButtonIsDown)
        {
          .GlobalRunning = false;
          break;
        }

        //
        // Apply Input
        //
        SpherePhysicsChild.ComponentBody.ApplyForceCenter(Vector3(User1Input["ObjX"].AxisValue,User1Input["ObjY"].AxisValue, User1Input["ObjZ"].AxisValue));
        //auto Position = SpherePhysicsChild.GetWorldTransform.Translation + SpherePhysicsChild.GetWorldTransform.TransformDirection(Vector3(0,0,1));
        auto Force =Vector3(User1Input["ObjX"].AxisValue,User1Input["ObjY"].AxisValue, User1Input["ObjZ"].AxisValue);
        //SpherePhysicsChild.ComponentBody.ApplyForceWorld( Vector3(User1Input["ObjX"].AxisValue,User1Input["ObjY"].AxisValue, User1Input["ObjZ"].AxisValue), Position);
        //GlobalEngine.DebugHelper.AddLine(Position, Force, Colors.Black);
        Angle += GlobalEngine.FrameTimeData.ElapsedTime;
        Quaternion Rotation = Quaternion(Vector3.ForwardVector, Angle);
        //Sphere2.RootComponent.SetRotation(Rotation);
        //Sphere.RootComponent.MoveWorld(Vector3(User1Input["ObjX"].AxisValue,User1Input["ObjY"].AxisValue, User1Input["ObjZ"].AxisValue) * GlobalEngine.FrameTimeData.ElapsedTime);
        ColorLinear[6] Colors = [Colors.Lime, Colors.Red, Colors.Blue, Colors.Pink, Colors.Orange, Colors.Yellow ];
        //GlobalEngine.DebugHelper.AddPolyShape(Transform(Vector3(0,0,3), Quaternion.Identity, Vector3.UnitScaleVector), BoxShape, Colors, 0.1f);
        GlobalRunning = GlobalEngine.Update();


      }


    }
  }
  DestroyGlobalEngine();
  return 0;
}

extern(Windows)
LRESULT Win32MainWindowCallback(HWND WindowHandle, UINT Message,
                                WPARAM WParam, LPARAM LParam)
{
  auto Window = cast(WindowData)cast(void*)GetWindowLongPtrW(WindowHandle, GWLP_USERDATA);

  if(Window is null) return DefWindowProcA(WindowHandle, Message, WParam, LParam);


  LRESULT Result = 0;

  switch(Message)
  {
    case WM_CLOSE:
    {
      // TODO: Handle this with a message to the user?
      GlobalEngine.RunEngine = false;
    } break;

    case WM_DESTROY:
    {
      // TODO: Handle this as an error - recreate Window?
      GlobalEngine.RunEngine = false;
    } break;

    case WM_KEYFIRST:   .. case WM_KEYLAST:   goto case; // fallthrough
    case WM_MOUSEFIRST: .. case WM_MOUSELAST: goto case; // fallthrough
    case WM_INPUT:
    {
      // TODO(Manu): Deal with the return value?
      Win32ProcessInputMessage(WindowHandle, Message, WParam, LParam,
                               Window.Input,
                               .Log);
    } break;

    case WM_ACTIVATEAPP:
    {
      //OutputDebugStringA("WM_ACTIATEAPP\n");
    } break;

    case WM_PAINT:
    {
      PAINTSTRUCT Paint;
      HDC DeviceContext = BeginPaint(WindowHandle, &Paint);
      //win32_main_dimension WindowDim = Win32GetWindowDimension(WindowHandle);
      //Win32DisplayBufferInWindow(&GlobalBackbuffer, DeviceContext,
      //                           WindowDim.Width, WindowDim.Height);

      EndPaint(WindowHandle, &Paint);
    } break;

    default:
    {
      // OutputDebugStringA("Default\n");
      Result = DefWindowProcA(WindowHandle, Message, WParam, LParam);
    } break;
  }

  return Result;
}
