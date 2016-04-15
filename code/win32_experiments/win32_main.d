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

  auto State = MainAllocator.NewARC!DxState();
  State.Allocator = MainAllocator;
  State.ProcessInstance = Instance;

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
      version(D3D11_RuntimeLinking)
      {
        LoadD3D11();
        LoadD3D11ShaderCompiler();
      }

      State.InitDevice();

      auto VertexShaderCode = State.LoadAndCompileDxShader(WString("../data/shader/first.hlsl", State.Allocator),
                                                           UString("VSMain", State.Allocator),
                                                           UString("vs_5_0", State.Allocator));

      ID3D11VertexShader VertexShader;
      scope(exit) if(VertexShader) VertexShader.Release();
      if(FAILED(State.Device.CreateVertexShader(VertexShaderCode.Blob.GetBufferPointer(),
                                                VertexShaderCode.Blob.GetBufferSize(),
                                                null,
                                                &VertexShader)))
      {
        Log.Failure("Failed to create vertex shader.");
      }

      D3D11_INPUT_ELEMENT_DESC[1] Layout =
      [
        D3D11_INPUT_ELEMENT_DESC( "POSITION", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 0, D3D11_INPUT_PER_VERTEX_DATA, 0 ),
      ];

      ID3D11InputLayout VertexShaderLayout;
      scope(exit) if(VertexShaderLayout) VertexShaderLayout.Release();
      if(FAILED(State.Device.CreateInputLayout(Layout.ptr,
                                               cast(UINT)Layout.length,
                                               VertexShaderCode.Blob.GetBufferPointer(),
                                               VertexShaderCode.Blob.GetBufferSize(),
                                               &VertexShaderLayout)))
      {
        Log.Failure("Failed to create input layout.");
      }

      State.ImmediateContext.IASetInputLayout(VertexShaderLayout);

      auto PixelShaderCode = State.LoadAndCompileDxShader(WString("../data/shader/first.hlsl", State.Allocator),
                                                          UString("PSMain", State.Allocator),
                                                          UString("ps_5_0", State.Allocator));

      ID3D11PixelShader PixelShader;
      scope(exit) if(PixelShader) PixelShader.Release();
      if(FAILED(State.Device.CreatePixelShader(PixelShaderCode.Blob.GetBufferPointer(),
                                               PixelShaderCode.Blob.GetBufferSize(),
                                               null,
                                               &PixelShader)))
      {
        Log.Failure("Failed to create pixel shader.");
      }

      static struct SimpleVertex
      {
        Vector3 Position;
      }

      SimpleVertex[3] Vertices =
      [
        SimpleVertex(Vector3( 0.0f,  0.5f,  0.5f)),
        SimpleVertex(Vector3( 0.5f, -0.5f,  0.5f)),
        SimpleVertex(Vector3(-0.5f, -0.5f,  0.5f)),
      ];

      D3D11_BUFFER_DESC VertexBufferDesc;
      with(VertexBufferDesc)
      {
        Usage = D3D11_USAGE_DEFAULT;
        ByteWidth = cast(UINT)Vertices.ByteCount;
        BindFlags = D3D11_BIND_VERTEX_BUFFER;
        CPUAccessFlags = 0;
      }
      D3D11_SUBRESOURCE_DATA InitData;
      InitData.pSysMem = Vertices.ptr;

      ID3D11Buffer VertexBuffer;
      if(FAILED(State.Device.CreateBuffer(&VertexBufferDesc, &InitData, &VertexBuffer)))
      {
        Log.Failure("Failed to create vertex buffer.");
      }

      UINT Stride = SimpleVertex.sizeof;
      UINT Offset = 0;
      State.ImmediateContext.IASetVertexBuffers(0, 1, &VertexBuffer, &Stride, &Offset);
      State.ImmediateContext.IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);

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
        State.ImmediateContext.ClearRenderTargetView(State.RenderTargetView, CornflowerBlue.Data);
        State.ImmediateContext.VSSetShader(VertexShader, null, 0);
        State.ImmediateContext.PSSetShader(PixelShader, null, 0);
        State.ImmediateContext.Draw(3, 0);
        State.SwapChain.Present(0, 0);
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

class DxState
{
  mixin RefCountSupport;

  IAllocator Allocator;
  HINSTANCE ProcessInstance;
  HWND WindowHandle;
  D3D_DRIVER_TYPE DriverType;
  D3D_FEATURE_LEVEL FeatureLevel;
  ID3D11Device Device;
  ID3D11Device1 Device1;
  ID3D11DeviceContext ImmediateContext;
  ID3D11DeviceContext1 ImmediateContext1;
  IDXGISwapChain SwapChain;
  IDXGISwapChain1 SwapChain1;
  ID3D11RenderTargetView RenderTargetView;

  ~this()
  {
    if(Device) ReleaseAndNullify(Device);
    if(Device1) ReleaseAndNullify(Device1);
    if(ImmediateContext) ReleaseAndNullify(ImmediateContext);
    if(ImmediateContext1) ReleaseAndNullify(ImmediateContext1);
    if(SwapChain) ReleaseAndNullify(SwapChain);
    if(SwapChain1) ReleaseAndNullify(SwapChain1);
    if(RenderTargetView) ReleaseAndNullify(RenderTargetView);
  }
}

bool InitDevice(DxState State)
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
                               &State.Device, &State.FeatureLevel, &State.ImmediateContext);
    if(Result == E_INVALIDARG)
    {
      // DirectX 11.0 platforms will not recognize D3D_FEATURE_LEVEL_11_1 so
      // we need to retry without it.
      auto TrimmedFeatureLevels = FeatureLevels[1 .. $];
      Result = D3D11CreateDevice(null, DriverType, null, CreateDeviceFlags,
                                 TrimmedFeatureLevels.ptr, cast(UINT)TrimmedFeatureLevels.length,
                                 D3D11_SDK_VERSION,
                                 &State.Device, &State.FeatureLevel, &State.ImmediateContext);
    }

    if(SUCCEEDED(Result))
      break;
  }

  if(FAILED(Result))
    return false;

  // Obtain DXGI factory from device.
  IDXGIFactory1 DXGIFactory;
  scope(exit) if(DXGIFactory) DXGIFactory.Release();
  {
    IDXGIDevice DXGIDevice;
    scope(exit) if(DXGIDevice) DXGIDevice.Release();
    Result = State.Device.QueryInterface(uuidof!IDXGIDevice, cast(void**)&DXGIDevice);
    if(SUCCEEDED(Result))
    {

      IDXGIAdapter Adapter;
      scope(exit) if(Adapter) Adapter.Release();
      DXGIDevice.GetAdapter(&Adapter);
      if(SUCCEEDED(Result))
      {

        Result = Adapter.GetParent(uuidof!IDXGIFactory1, cast(void**)&DXGIFactory);
      }
    }
  }
  if(FAILED(Result))
    return false;

  IDXGIFactory2 DXGIFactory2;
  scope(exit) if(DXGIFactory2) DXGIFactory2.Release();
  Result = DXGIFactory.QueryInterface(uuidof!IDXGIFactory2, cast(void**)&DXGIFactory2);
  if(DXGIFactory2)
  {

    Result = State.Device.QueryInterface(uuidof!ID3D11Device1, cast(void**)&State.Device1);
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

      Result = DXGIFactory2.CreateSwapChainForHwnd(State.Device, State.WindowHandle, &SwapChainDesc, null, null, &State.SwapChain1);
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

    Result = DXGIFactory.CreateSwapChain(State.Device, &SwapChainDesc, &State.SwapChain);
  }

  DXGIFactory.MakeWindowAssociation(State.WindowHandle, DXGI_MWA_NO_ALT_ENTER);

  if(FAILED(Result)) return false;

  ID3D11Texture2D BackBuffer;
  scope(exit) if(BackBuffer) BackBuffer.Release();
  Result = State.SwapChain.GetBuffer(0, uuidof!ID3D11Texture2D, cast(void**)&BackBuffer);
  if(FAILED(Result)) return false;

  State.Device.CreateRenderTargetView(BackBuffer, null, &State.RenderTargetView);

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

void ReleaseAndNullify(Type)(Type Instance)
  if(__traits(compiles, { Instance.Release(); Instance = null; }))
{
  Instance.Release();
  Instance = null;
}

class DxShaderCode
{
  mixin RefCountSupport;

  ID3DBlob Blob;

  ~this()
  {
    ReleaseAndNullify(Blob);
  }
}

ARC!DxShaderCode LoadAndCompileDxShader(DxState State, WString FileName, UString EntryPoint, UString Profile)
{
  UINT Flags = D3DCOMPILE_ENABLE_STRICTNESS;
  debug Flags |= D3DCOMPILE_DEBUG;

  ID3DBlob ShaderBlob;
  ID3DBlob ErrorBlob;
  scope(exit) if(ErrorBlob) ErrorBlob.Release();

  if(FAILED(D3DCompileFromFile(FileName.ptr,
                               null,
                               D3D_COMPILE_STANDARD_FILE_INCLUDE,
                               EntryPoint.ptr,
                               Profile.ptr,
                               Flags,
                               cast(UINT)0,
                               &ShaderBlob,
                               &ErrorBlob
                               )))
  {
    auto RawMessage = cast(char*)ErrorBlob.GetBufferPointer();
    auto MessageSize = ErrorBlob.GetBufferSize();
    auto Message = RawMessage[0 .. MessageSize];
    Log.Failure("Failed to compile shader: %s", Message);
    return typeof(return)();
  }

  Log.Info("Shader compiled successfully!");

  auto Result = State.Allocator.NewARC!DxShaderCode();
  Result.Blob = ShaderBlob;
  return Result;
}
