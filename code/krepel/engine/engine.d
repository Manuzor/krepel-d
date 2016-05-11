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
  }

  bool Update()
  {
    return false;
  }

  void Destroy()
  {

  }

}

Engine GlobalEngine;

void SetupGobalEngine(IAllocator Allocator, EngineCreationInformation Info)
{
  GlobalEngine = Allocator.New!Engine();
  GlobalEngine.EngineAllocator = Allocator;

  GlobalEngine.Initialize(Info);
}
