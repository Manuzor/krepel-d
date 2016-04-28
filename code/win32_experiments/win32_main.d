module krepel.win32_main;
version(Windows):

import krepel;
import krepel.win32;
import krepel.math;
import krepel.string;

import krepel.win32.directx.dxgi;
import krepel.win32.directx.d3d11;
import krepel.win32.directx.xinput;
import krepel.win32.directx.uuidof;

import krepel.d3d11_render_device;
import krepel.render_device;
import krepel.resources;

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
  D3D11RenderDevice Device = MainAllocator.New!D3D11RenderDevice(MainAllocator);
  Device.DeviceState.ProcessInstance = Instance;

  WNDCLASSA WindowClass;
  with(WindowClass)
  {
    style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
    lpfnWndProc = &Win32MainWindowCallback;
    hInstance = Instance;
    lpszClassName = "D_WindowClass";
  }

  if(RegisterClassA(&WindowClass))
  {
    Device.DeviceState.WindowHandle = CreateWindowExA(0,
                                         WindowClass.lpszClassName,
                                         "The Title Text".ptr,
                                         WS_OVERLAPPEDWINDOW | WS_VISIBLE,
                                         CW_USEDEFAULT, CW_USEDEFAULT,
                                         CW_USEDEFAULT, CW_USEDEFAULT,
                                         null,
                                         null,
                                         Instance,
                                         null);

    if(Device.DeviceState.WindowHandle)
    {

      Device.InitDevice();

      auto VertexShader = Device.LoadVertexShader(WString("../data/shader/first.hlsl", Device.DeviceState.Allocator),
                                                      UString("VSMain", Device.DeviceState.Allocator),
                                                      UString("vs_5_0", Device.DeviceState.Allocator));
      scope(exit)
      {
        if (VertexShader)
        {
          Device.ReleaseVertexShader(VertexShader);
        }
      }

      RenderInputLayoutDescription[5] Layout =
      [
        RenderInputLayoutDescription(UString("POSITION", MainAllocator), 0, InputDescriptionDataType.Float, 3, true),
        RenderInputLayoutDescription(UString("UV", MainAllocator), 0, InputDescriptionDataType.Float, 2, true),
        RenderInputLayoutDescription(UString("NORMAL", MainAllocator), 0, InputDescriptionDataType.Float, 3, true),
        RenderInputLayoutDescription(UString("TANGENT", MainAllocator), 0, InputDescriptionDataType.Float, 4, true),
        RenderInputLayoutDescription(UString("BINORMAL", MainAllocator), 0, InputDescriptionDataType.Float, 3, true),
      ];
      auto InputLayoutDescription = Device.CreateInputLayoutDescription(Layout);
      scope(exit) Device.DestroyInputLayoutDescription(InputLayoutDescription);
      auto InputLayout = Device.CreateVertexShaderInputLayoutFromDescription(VertexShader, InputLayoutDescription);
      scope(exit) Device.DestroyInputLayout(InputLayout);
      Device.SetInputLayout(InputLayout);


      auto PixelShader = Device.LoadPixelShader(WString("../data/shader/first.hlsl", Device.DeviceState.Allocator),
                                                UString("PSMain", Device.DeviceState.Allocator),
                                                UString("ps_5_0", Device.DeviceState.Allocator));
      scope(exit)
      {
        if (PixelShader)
        {
          Device.ReleasePixelShader(PixelShader);
        }
      }

      ResourceManager Manager = MainAllocator.New!ResourceManager(MainAllocator);
      auto WaveFrontLoader = MainAllocator.New!WavefrontResourceLoader();
      Manager.RegisterLoader(WaveFrontLoader, WString(".obj", MainAllocator));
      MeshResource Mesh = Manager.LoadMesh(WString("../data/mesh/Cube.obj", MainAllocator));

      IRenderMesh RenderMesh = Device.CreateRenderMesh(Mesh.Meshes[0]);
      scope(exit)
      {
        Device.ReleaseRenderMesh(RenderMesh);
        Manager.DestroyResource(Mesh);
        MainAllocator.Delete(WaveFrontLoader);
        MainAllocator.Delete(Manager);
      }

      version(XInput_RuntimeLinking) LoadXInput();

      GlobalRunning = true;

      while(GlobalRunning)
      {
        Win32ProcessPendingMessages();

        XINPUT_STATE ControllerState;
        if(XInputGetState(0, &ControllerState) == ERROR_SUCCESS)
        {
          Log.Info("Marvin!! XINPUT FUNKTIONIERT!!");
        }

        auto CornflowerBlue = Vector4(100 / 255.0f, 149 / 255.0f, 237 / 255.0f, 1.0f);
        Device.ClearRenderTarget(CornflowerBlue);
        Device.SetVertexShader(VertexShader);
        Device.SetPixelShader(PixelShader);
        Device.SetMesh(RenderMesh);
        Device.DrawIndexed(RenderMesh.GetIndexCount());
        Device.Present();
      }
    }
  }

  return 0;
}

void Win32ProcessPendingMessages()
{
  MSG Message;
  if(PeekMessageA(&Message, null, 0, 0, PM_REMOVE))
  {
    switch(Message.message)
    {
      case WM_QUIT:
      {
        GlobalRunning = false;
      } break;

      case WM_SYSKEYDOWN: goto case; // fallthrough
      case WM_SYSKEYUP:   goto case; // fallthrough
      case WM_KEYDOWN:    goto case; // fallthrough
      case WM_KEYUP:
      {
        auto VKCode = Message.wParam;

        if(VKCode == VK_SPACE)
        {
          Log.Info("Space");
        }
        else if(VKCode == VK_ESCAPE)
        {
          GlobalRunning = false;
        }

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
LRESULT Win32MainWindowCallback(HWND Window, UINT Message,
                                WPARAM WParam, LPARAM LParam) nothrow
{
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

    case WM_SYSKEYDOWN: goto case; // fallthrough
    case WM_SYSKEYUP:   goto case; // fallthrough
    case WM_KEYDOWN:    goto case; // fallthrough
    case WM_KEYUP: assert(0, "Keyboard messages are handled in the main loop.");

    case WM_ACTIVATEAPP:
    {
      //OutputDebugStringA("WM_ACTIATEAPP\n");
    } break;

    case WM_PAINT:
    {
      PAINTSTRUCT Paint;
      HDC DeviceContext = BeginPaint(Window, &Paint);
      //win32_main_dimension WindowDim = Win32GetWindowDimension(Window);
      //Win32DisplayBufferInWindow(&GlobalBackbuffer, DeviceContext,
      //                           WindowDim.Width, WindowDim.Height);

      EndPaint(Window, &Paint);
    } break;

    default:
    {
      // OutputDebugStringA("Default\n");
      Result = DefWindowProcA(Window, Message, WParam, LParam);
    } break;
  }

  return Result;
}
