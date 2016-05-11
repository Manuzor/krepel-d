module krepel.engine.engine;

import krepel;
import krepel.input;
import krepel.scene;
import krepel.render_device;
import krepel.forward_renderer;
import krepel.game_framework;
import krepel.resources;

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

  this(IAllocator Allocator)
  {
    EngineAllocator = Allocator;
    InputContexts.Allocator = EngineAllocator;
  }

  void Initialize(EngineCreationInformation Info)
  {

    version(Windows)
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
    Device.InitDevice(Description);

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
        // Note(Manu): Let's pretend the system is user 0 for now.
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
  }

  bool Update()
  {
    return false;
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
