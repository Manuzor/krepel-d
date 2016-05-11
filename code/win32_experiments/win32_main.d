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
import krepel.engine;

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
  auto RawMemory = VirtualAlloc(null,
                                MemorySize,
                                MEM_RESERVE | MEM_COMMIT,
                                PAGE_READWRITE);
  if(RawMemory is null)
  {
    return 1;
  }
  assert(RawMemory);
  auto Heap = HeapMemory((cast(ubyte*)RawMemory)[0 .. MemorySize]);
  IAllocator MainAllocator = Heap.Wrap();

  Log = MainAllocator.New!LogData(MainAllocator);
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
      MeshResource Mesh = GlobalEngine.Resources.LoadMesh(WString("../data/mesh/Suzanne.obj", MainAllocator));
      scope(exit)
      {
        GlobalEngine.Resources.DestroyResource(Mesh);
      }

      SceneGraph Graph = MainAllocator.New!(SceneGraph)(MainAllocator);
      auto CameraObject= Graph.CreateDefaultGameObject(UString("Camera", MainAllocator));
      auto CameraComponent = CameraObject.ConstructChild!CameraComponent(UString("CameraComponent", MainAllocator), CameraObject.RootComponent);
      with(CameraComponent)
      {
        FieldOfView = PI/2;
        Width = 1280;
        Height = 720;
        NearPlane = 0.1f;
        FarPlane = 10.0f;
        SetWorldTransform(Transform(Vector3(0,0,2), Quaternion.Identity, Vector3.UnitScaleVector));
      }
      Matrix4 Mat = CameraComponent.GetViewProjectionMatrix().GetTransposed;

      auto SuzanneObj = Graph.CreateDefaultGameObject(UString("Suzanne", MainAllocator));
      auto RenderChild = SuzanneObj.ConstructChild!PrimitiveRenderComponent(UString("SuzanneRender", MainAllocator));
      RenderChild.SetMesh(Mesh);


      SuzanneObj = Graph.CreateDefaultGameObject(UString("Suzanne", MainAllocator));
      RenderChild = SuzanneObj.ConstructChild!PrimitiveRenderComponent(UString("SuzanneRender", MainAllocator));
      RenderChild.SetMesh(Mesh);
      SuzanneObj.RootComponent.SetWorldTransform(Transform(Vector3(2,0,0), Quaternion.Identity, Vector3.UnitScaleVector));
      GlobalEngine.Renderer.ActiveCamera = CameraComponent;

      GlobalEngine.Renderer.RegisterScene(Graph);

      version(XInput_RuntimeLinking) LoadXInput();


      auto SystemInput = cast(Win32InputContext)GlobalEngine.InputContexts[0];

      SystemInput.RegisterInputSlot(InputType.Button, "Quit");
      SystemInput.AddSlotMapping(Keyboard.Escape, "Quit");
      SystemInput.AddSlotMapping(XInput.Start, "Quit");

      SystemInput.RegisterInputSlot(InputType.Axis, "CameraX");
      SystemInput.AddSlotMapping(XInput.XLeftStick, "CameraX");
      SystemInput.AddSlotMapping(Keyboard.A, "CameraX", -1);
      SystemInput.AddSlotMapping(Keyboard.D, "CameraX",  1);

      SystemInput.RegisterInputSlot(InputType.Axis, "CameraY");
      SystemInput.AddSlotMapping(XInput.YLeftStick, "CameraY");
      SystemInput.AddSlotMapping(Keyboard.W, "CameraY",  1);
      SystemInput.AddSlotMapping(Keyboard.S, "CameraY", -1);

      SystemInput.RegisterInputSlot(InputType.Axis, "CameraZ");
      SystemInput.AddSlotMapping(XInput.YRightStick, "CameraZ", -1);
      SystemInput.AddSlotMapping(Keyboard.Q, "CameraZ", -1);
      SystemInput.AddSlotMapping(Keyboard.E, "CameraZ",  1);


      //SystemInput.ChangeEvent.Add = (Id, Slot)
      //{
      //  Log.Info("Input change '%s': %s %s", Id, Slot.Type, Slot.Value);
      //};

      auto Window = MainAllocator.New!WindowData(SystemInput);
      scope(exit) MainAllocator.Delete(Window);

      SetWindowLongPtrA(WindowHandle, GWLP_USERDATA, *cast(LONG_PTR*)&Window);
      scope(exit) SetWindowLongPtrA(WindowHandle, GWLP_USERDATA, cast(LONG_PTR)null);

      GlobalRunning = true;

      while(GlobalRunning)
      {
        SystemInput.BeginInputFrame();
        {
          Win32MessagePump();
          Win32PollXInput(SystemInput);
        }
        SystemInput.EndInputFrame();

        if(SystemInput["Quit"].ButtonIsDown)
        {
          .GlobalRunning = false;
          break;
        }

        //
        // Apply Input
        //
        Transform WorldTransform = CameraComponent.GetWorldTransform();
        WorldTransform.Translation.X += SystemInput["CameraX"].AxisValue * (1 / 3000.0f);
        WorldTransform.Translation.Y += SystemInput["CameraY"].AxisValue * (1 / 3000.0f);
        WorldTransform.Translation.Z += SystemInput["CameraZ"].AxisValue * (1 / 3000.0f);
        CameraComponent.SetWorldTransform(WorldTransform);
        Mat = CameraComponent.GetViewProjectionMatrix().GetTransposed;
        auto CurrentTransform = SuzanneObj.RootComponent.GetWorldTransform;
        Quaternion RotZ = Quaternion(Vector3.UpVector, 2 * PI * (1/3000f));
        CurrentTransform.Rotation *= RotZ;
        SuzanneObj.RootComponent.SetWorldTransform(CurrentTransform);

        GlobalEngine.Renderer.Render();

      }


    }
  }
  DestroyGlobalEngine();
  return 0;
}

void Win32MessagePump()
{
  MSG Message;
  while(PeekMessageA(&Message, null, 0, 0, PM_REMOVE))
  {
    switch(Message.message)
    {
      case WM_QUIT:
      {
        GlobalRunning = false;
      } break;

      default:
      {
        TranslateMessage(&Message);
        DispatchMessageA(&Message);
      } break;
    }
  }
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
      GlobalRunning = false;
    } break;

    case WM_DESTROY:
    {
      // TODO: Handle this as an error - recreate Window?
      GlobalRunning = false;
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
