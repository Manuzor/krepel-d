module krepel.win32_main;
version(Windows):

import krepel;
import krepel.win32;
import krepel.math;
import krepel.input;

import krepel.win32.directx.dxgi;
import krepel.win32.directx.d3d11;
import krepel.win32.directx.xinput;
import krepel.win32.directx.uuidof;

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

  StateData State;
  State.ProcessInstance = Instance;

  WNDCLASSA WindowClass;
  with(WindowClass)
  {
    style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
    // The wrapped WinAPI of D requires a nothrow callback, which is a
    // ridiculous requirement since there's probably not even a single C++
    // application that passes a nothrow callback here.
    lpfnWndProc = cast(typeof(lpfnWndProc))cast(void*)&Win32MainWindowCallback;
    hInstance = Instance;
    lpszClassName = "D_WindowClass";
  }

  if(RegisterClassA(&WindowClass))
  {
    State.WindowHandle = CreateWindowExA(0,
                                         WindowClass.lpszClassName,
                                         "The Title Text".ptr,
                                         WS_OVERLAPPEDWINDOW | WS_VISIBLE,
                                         CW_USEDEFAULT, CW_USEDEFAULT,
                                         CW_USEDEFAULT, CW_USEDEFAULT,
                                         null,
                                         null,
                                         Instance,
                                         null);

    if(State.WindowHandle)
    {
      version(DXGI_RuntimeLinking)  LoadDXGI();
      version(D3D11_RuntimeLinking) LoadD3D11();

      InitDevice(&State);

      version(XInput_RuntimeLinking) LoadXInput();

      auto SystemInput = MainAllocator.New!InputContext(MainAllocator);
      scope(exit) MainAllocator.Delete(SystemInput);

      Win32RegisterAllKeyboardSlots(SystemInput);
      Win32RegisterAllMouseSlots(SystemInput);
      Win32RegisterAllXInputSlots(SystemInput);

      SystemInput.RegisterInputSlot(InputType.Button, "Quit");
      SystemInput.AddTrigger("Quit", Keyboard.Escape);
      SystemInput.AddTrigger("Quit", XInput.Start);

      //SystemInput.ChangeEvent.Add = (Id, Slot)
      //{
      //  Log.Info("Input change '%s': %s %s", Id, Slot.Type, Slot.Value);
      //};

      auto Window = MainAllocator.New!WindowData(SystemInput);
      scope(exit) MainAllocator.Delete(Window);

      SetWindowLongPtrA(State.WindowHandle, GWLP_USERDATA, *cast(LONG_PTR*)&Window);
      scope(exit) SetWindowLongPtrA(State.WindowHandle, GWLP_USERDATA, cast(LONG_PTR)null);

      GlobalRunning = true;

      while(GlobalRunning)
      {
        Win32MessagePump();

        Win32PollXInput(SystemInput);

        SystemInput.BeginInputFrame();
        scope(success) SystemInput.EndInputFrame();

        auto QuitInput = SystemInput["Quit"];
        if(QuitInput && QuitInput.ButtonIsDown) .GlobalRunning = false;

        Log.Info("Left Stick: %f", SystemInput[XInput.XLeftStick].AxisValue);

        auto CornflowerBlue = Vector4(100 / 255.0f, 149 / 255.0f, 237 / 255.0f, 1.0f);
        State.ImmediateContext.ClearRenderTargetView(State.RenderTargetView, CornflowerBlue.Data);
        State.SwapChain.Present(0, 0);

        if(SystemInput.CharacterBuffer.Count)
        {
          Log.Info("User typed: %s", SystemInput.CharacterBuffer[]);
        }
      }
    }
  }

  return 0;
}

/// Params:
///   WindowHandle = Can be $(D null).
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

class WindowData
{
  InputContext Input;

  this(InputContext Input)
  {
    this.Input = Input;
  }
}

struct StateData
{
  HINSTANCE ProcessInstance;
  HWND WindowHandle;
  D3D_DRIVER_TYPE DriverType;
  D3D_FEATURE_LEVEL FeatureLevel;
  ID3D11Device D3DDevice;
  ID3D11Device1 D3DDevice1;
  ID3D11DeviceContext ImmediateContext;
  ID3D11DeviceContext1 ImmediateContext1;
  IDXGISwapChain SwapChain;
  IDXGISwapChain1 SwapChain1;
  ID3D11RenderTargetView RenderTargetView;
}

bool InitDevice(StateData* State)
{
  HRESULT Result;

  RECT ClientRect;
  GetClientRect(State.WindowHandle, &ClientRect);
  auto WindowWidth = ClientRect.right - ClientRect.left;
  auto WindowHeight = ClientRect.bottom - ClientRect.top;

  UINT CreateDeviceFlags = 0;
  debug CreateDeviceFlags |= D3D11_CREATE_DEVICE_DEBUG;

  D3D_DRIVER_TYPE[3] DriverTypes =
  [
    D3D_DRIVER_TYPE_HARDWARE,
    D3D_DRIVER_TYPE_WARP,
    D3D_DRIVER_TYPE_REFERENCE,
  ];

  D3D_FEATURE_LEVEL[4] FeatureLevels =
  [
    D3D_FEATURE_LEVEL_11_1,
    D3D_FEATURE_LEVEL_11_0,
    D3D_FEATURE_LEVEL_10_1,
    D3D_FEATURE_LEVEL_10_0,
  ];

  foreach(DriverType; DriverTypes)
  {
    Result = D3D11CreateDevice(null, DriverType, null, CreateDeviceFlags,
                               FeatureLevels.ptr, cast(UINT)FeatureLevels.length,
                               D3D11_SDK_VERSION,
                               &State.D3DDevice, &State.FeatureLevel, &State.ImmediateContext);
    if(Result == E_INVALIDARG)
    {
      // DirectX 11.0 platforms will not recognize D3D_FEATURE_LEVEL_11_1 so
      // we need to retry without it.
      auto TrimmedFeatureLevels = FeatureLevels[1 .. $];
      Result = D3D11CreateDevice(null, DriverType, null, CreateDeviceFlags,
                                 TrimmedFeatureLevels.ptr, cast(UINT)TrimmedFeatureLevels.length,
                                 D3D11_SDK_VERSION,
                                 &State.D3DDevice, &State.FeatureLevel, &State.ImmediateContext);
    }

    if(SUCCEEDED(Result))
      break;
  }

  if(FAILED(Result))
    return false;

  // Obtain DXGI factory from device.
  IDXGIFactory1 DXGIFactory;
  {
    IDXGIDevice DXGIDevice;
    Result = State.D3DDevice.QueryInterface(uuidof!IDXGIDevice, cast(void**)&DXGIDevice);
    if(SUCCEEDED(Result))
    {
      scope(exit) DXGIDevice.Release();

      IDXGIAdapter Adapter;
      DXGIDevice.GetAdapter(&Adapter);
      if(SUCCEEDED(Result))
      {
        scope(exit) Adapter.Release();

        Result = Adapter.GetParent(uuidof!IDXGIFactory1, cast(void**)&DXGIFactory);
      }
    }
  }
  if(FAILED(Result))
    return false;

  scope(exit) DXGIFactory.Release();

  IDXGIFactory2 DXGIFactory2;
  Result = DXGIFactory.QueryInterface(uuidof!IDXGIFactory2, cast(void**)&DXGIFactory2);
  if(DXGIFactory2)
  {
    scope(exit) DXGIFactory2.Release();

    Result = State.D3DDevice.QueryInterface(uuidof!ID3D11Device1, cast(void**)&State.D3DDevice1);
    if(SUCCEEDED(Result))
    {
      State.ImmediateContext.QueryInterface(uuidof!ID3D11DeviceContext1, cast(void**)&State.ImmediateContext1);
    }

    DXGI_SWAP_CHAIN_DESC1 SwapChainDesc;
    with(SwapChainDesc)
    {
      Width = WindowWidth;
      Height = WindowHeight;
      Format = DXGI_FORMAT_R8G8B8A8_UNORM;
      SampleDesc.Count = 1;
      SampleDesc.Quality = 0;
      BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
      BufferCount = 1;

      Result = DXGIFactory2.CreateSwapChainForHwnd(State.D3DDevice, State.WindowHandle, &SwapChainDesc, null, null, &State.SwapChain1);
      if(SUCCEEDED(Result))
      {
        Result = State.SwapChain1.QueryInterface(uuidof!IDXGISwapChain, cast(void**)&State.SwapChain);
      }
    }
  }
  else
  {
    // DirectX 11.0 systems
    DXGI_SWAP_CHAIN_DESC SwapChainDesc;
    with(SwapChainDesc)
    {
      BufferCount = 1;
      BufferDesc.Width = WindowWidth;
      BufferDesc.Height = WindowHeight;
      BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
      BufferDesc.RefreshRate.Numerator = 60;
      BufferDesc.RefreshRate.Denominator = 1;
      BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
      OutputWindow = State.WindowHandle;
      SampleDesc.Count = 1;
      SampleDesc.Quality = 0;
      Windowed = TRUE;
    }

    Result = DXGIFactory.CreateSwapChain(State.D3DDevice, &SwapChainDesc, &State.SwapChain);
  }

  DXGIFactory.MakeWindowAssociation(State.WindowHandle, DXGI_MWA_NO_ALT_ENTER);

  if(FAILED(Result)) return false;

  ID3D11Texture2D BackBuffer;
  Result = State.SwapChain.GetBuffer(0, uuidof!ID3D11Texture2D, cast(void**)&BackBuffer);
  if(FAILED(Result)) return false;

  scope(exit) BackBuffer.Release();

  State.D3DDevice.CreateRenderTargetView(BackBuffer, null, &State.RenderTargetView);

  if(FAILED(Result)) return false;

  State.ImmediateContext.OMSetRenderTargets(1, &State.RenderTargetView, null);

  D3D11_VIEWPORT ViewPort;
  with(ViewPort)
  {
    TopLeftX = 0.0f;
    TopLeftY = 0.0f;
    Width = cast(FLOAT)WindowWidth;
    Height = cast(FLOAT)WindowHeight;
    MinDepth = 0.0f;
    MaxDepth = 1.0f;
  }

  State.ImmediateContext.RSSetViewports(1, &ViewPort);

  return true;
}
