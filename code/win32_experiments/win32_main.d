module krepel.win32_main;
version(Windows):

import krepel;
import krepel.win32;


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

  // Note(Manu): There's no point to add the stdout log sink since stdout
  // isn't attached to anything in a windows application. We add the VS log
  // sink instead.
  Log.Sinks ~= ToDelegate(&VisualStudioLogSink);

  Log.Info("=== Beginning of Log");
  scope(exit) Log.Info("=== End of Log");

  if(!Win32LoadXInput())
  {
    Log.Info("Failed to load XInput.");
  }

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
    HWND Window = CreateWindowExA(0,
                                  WindowClass.lpszClassName,
                                  "The Title Text".ptr,
                                  WS_OVERLAPPEDWINDOW | WS_VISIBLE,
                                  CW_USEDEFAULT, CW_USEDEFAULT,
                                  CW_USEDEFAULT, CW_USEDEFAULT,
                                  null,
                                  null,
                                  Instance,
                                  null);

    if(Window)
    {
      import krepel.win32.directx.dxgi;
      import krepel.win32.directx.d3d11;

      version(DXGI_RuntimeLinking)  LoadDXGI();
      version(D3D11_RuntimeLinking) LoadD3D11();

      IDXGIFactory1 DXGIFactory;
      if(SUCCEEDED(CreateDXGIFactory1(&DXGIFactory.uuidof, cast(void**)&DXGIFactory)))
      {
        assert(DXGIFactory);

        Log.Info("Available Adapters:");

        UINT CurrentAdapterIndex;
        IDXGIAdapter1 DXGIAdapter;
        while(SUCCEEDED(DXGIFactory.EnumAdapters1(CurrentAdapterIndex, &DXGIAdapter)))
        {
          scope(exit) CurrentAdapterIndex++;
          DXGI_ADAPTER_DESC AdapterDesc = void;
          if(SUCCEEDED(DXGIAdapter.GetDesc(&AdapterDesc)))
          {
            Log.Info("Adapter[%d]: %s", CurrentAdapterIndex, AdapterDesc.Description[].ByUTF!char);
          }
          else
          {
            Log.Failure("Failed to get adapter %d's description.", CurrentAdapterIndex);
          }
        }
      }
      else
      {
        Log.Failure("Failed to create DXGI factory.");
      }

      DXGI_SWAP_CHAIN_DESC SwapChainDesc;
      with(SwapChainDesc)
      {
        BufferCount                        = 1;
        BufferDesc.Width                   = 640;
        BufferDesc.Height                  = 480;
        BufferDesc.Format                  = DXGI_FORMAT_R8G8B8A8_UNORM;
        BufferDesc.RefreshRate.Numerator   = 60;
        BufferDesc.RefreshRate.Denominator = 1;
        BufferUsage                        = DXGI_USAGE_RENDER_TARGET_OUTPUT;
        OutputWindow                       = Window;
        SampleDesc.Count                   = 1;
        SampleDesc.Quality                 = 0;
        Windowed                           = TRUE;
      }

      D3D_FEATURE_LEVEL[7] AllFeatureLevels = [
        D3D_FEATURE_LEVEL_11_1,
        D3D_FEATURE_LEVEL_11_0,
        D3D_FEATURE_LEVEL_10_1,
        D3D_FEATURE_LEVEL_10_0,
        D3D_FEATURE_LEVEL_9_3,
        D3D_FEATURE_LEVEL_9_2,
        D3D_FEATURE_LEVEL_9_1
      ];

      auto FeatureLevels = AllFeatureLevels[];
      D3D_FEATURE_LEVEL SupportedFeatureLevel;

      UINT CreateDeviceFlags = 0;
      debug CreateDeviceFlags |= D3D11_CREATE_DEVICE_DEBUG;

      ID3D11Device Device;
      IDXGISwapChain SwapChain;
      ID3D11DeviceContext ImmediateContext;
      HRESULT Result = D3D11CreateDeviceAndSwapChain(null,
                                                     D3D_DRIVER_TYPE_HARDWARE,
                                                     null,
                                                     CreateDeviceFlags,
                                                     FeatureLevels.ptr,
                                                     cast(UINT)FeatureLevels.length,
                                                     D3D11_SDK_VERSION,
                                                     &SwapChainDesc,
                                                     &SwapChain,
                                                     &Device,
                                                     &SupportedFeatureLevel,
                                                     &ImmediateContext);
      if (Result == E_INVALIDARG)
      {
        FeatureLevels.popFront();
        D3D11CreateDeviceAndSwapChain(null,
                                      D3D_DRIVER_TYPE_HARDWARE,
                                      null,
                                      CreateDeviceFlags,
                                      FeatureLevels.ptr,
                                      cast(UINT)FeatureLevels.length,
                                      D3D11_SDK_VERSION,
                                      &SwapChainDesc,
                                      &SwapChain,
                                      &Device,
                                      &SupportedFeatureLevel,
                                      &ImmediateContext);
      }

      assert(Device);
      assert(SwapChain);
      assert(ImmediateContext);

      GlobalRunning = true;

      while(GlobalRunning)
      {
        Win32ProcessPendingMessages();

        Wrapped.XINPUT_STATE ControllerState;
        if(XInputGetState(0, &ControllerState) == ERROR_SUCCESS)
        {
          Log.Info("Marvin!! XINPUT FUNKTIONIERT!!");
        }
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
