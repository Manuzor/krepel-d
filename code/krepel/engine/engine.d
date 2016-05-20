module krepel.engine.engine;

import krepel;
import krepel.input;
import krepel.scene;
import krepel.render_device;
import krepel.forward_renderer;
import krepel.game_framework;
import krepel.resources;
import krepel.chrono;
import krepel.engine.subsystem;

struct EngineCreationInformation
{
version(Windows)
  {
    import krepel.win32;
    HINSTANCE Instance;
    HANDLE WindowHandle;
  }
}

class Engine
{
  Array!InputContext InputContexts;
  ForwardRenderer Renderer;
  IRenderDevice RenderDevice;
  IAllocator EngineAllocator;
  ResourceManager Resources;
  bool RunEngine = true;
  GameFrameworkManager GameFramework;
  Timer FrameTimer;
  TickData FrameTimeData;
  Array!Subsystem Subsystems;

  this(IAllocator Allocator)
  {
    EngineAllocator = Allocator;
    InputContexts.Allocator = EngineAllocator;
    Subsystems.Allocator = Allocator;
  }

  void Initialize(EngineCreationInformation Info)
  {

    version(D3D11_RuntimeLinking)
    {
      import krepel.d3d11_render_device;
      D3D11RenderDevice Device = EngineAllocator.New!D3D11RenderDevice(EngineAllocator);
      RenderDevice = Device;
      Device.DeviceState.ProcessInstance = Info.Instance;
      Device.DeviceState.WindowHandle = Info.WindowHandle;
    }
    RenderDeviceCreationDescription Description;
    with(Description.DepthStencilDescription)
    {
      EnableDepthTest = true;
      DepthCompareFunc = RenderDepthCompareMethod.Less;
      EnableStencil = true;
    }
    RenderDevice.InitDevice(Description);

    Renderer = EngineAllocator.New!ForwardRenderer(EngineAllocator);
    Renderer.Initialize(RenderDevice);

    Resources = EngineAllocator.New!ResourceManager(EngineAllocator);
    auto WaveFrontLoader = EngineAllocator.New!WavefrontResourceLoader();
    Resources.RegisterLoader(WaveFrontLoader, WString(".obj", EngineAllocator));

    foreach(Index; 0..4)
    {
      version(Windows)
      {
        auto InputContext = EngineAllocator.New!Win32InputContext(EngineAllocator);
        InputContext.UserIndex = Index;

        if (Index == 0)
        {
          Win32RegisterAllKeyboardSlots(InputContext);
          Win32RegisterAllMouseSlots(InputContext);
        }
        Win32RegisterAllXInputSlots(InputContext);
        InputContexts ~= InputContext;
      }
    }

    GameFramework = EngineAllocator.New!GameFrameworkManager(EngineAllocator);
    Subsystems ~= GameFramework;

    with(FrameTimeData)
    {
      TimeFromStart = 0;
      TimeDilation = 1.0f;
      RealtimeElapsedTime = 0.0f;
    }
	FrameTimer.Start();
  }

  void RegisterScene(SceneGraph Graph)
  {
    GameFramework.RegisterScene(Graph);
    Renderer.RegisterScene(Graph);
  }

  bool Update()
  {
    FrameTimer.Stop();
    double ElapsedTime = FrameTimer.TotalElapsedSeconds();
    FrameTimer.Start();
    foreach(Input; InputContexts)
    {
      Input.BeginInputFrame();
      {
        Win32MessagePump();
        Win32PollXInput(cast(Win32InputContext)Input);
      }
      Input.EndInputFrame();

    }
    FrameTimeData.RealtimeElapsedTime = ElapsedTime;
    FrameTimeData.TimeFromStart += ElapsedTime;
    foreach(Subsystem; Subsystems)
    {
      Subsystem.TickSubsystem(ElapsedTime);
    }
    Renderer.Render();
    return RunEngine;
  }

  version(Windows) void Win32MessagePump()
  {
    import krepel.win32;
    MSG Message;
    while(PeekMessageA(&Message, null, 0, 0, PM_REMOVE))
    {
      switch(Message.message)
      {
        case WM_QUIT:
        {
          RunEngine = false;
        } break;

        default:
        {
          TranslateMessage(&Message);
          DispatchMessageA(&Message);
        } break;
      }
    }
  }

  void Destroy()
  {
    EngineAllocator.Delete(Renderer);
    EngineAllocator.Delete(RenderDevice);
    EngineAllocator.Delete(Resources);
    foreach(Input ; InputContexts)
    {
      EngineAllocator.Delete(Input);
    }
  }

}

Engine GlobalEngine;

void SetupGobalEngine(IAllocator Allocator, EngineCreationInformation Info)
{
  GlobalEngine = Allocator.New!Engine(Allocator);
  GlobalEngine.Initialize(Info);
}

void DestroyGlobalEngine()
{
  if (GlobalEngine)
  {
    GlobalEngine.Destroy();
    GlobalEngine.EngineAllocator.Delete(GlobalEngine);
  }
}
