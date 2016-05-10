module krepel.engine.engine;

import krepel;
import krepel.input;
import krepel.scene;
import krepel.render_device;
import krepel.forward_renderer;
import krepel.game_framework;

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

  void Initialize(EngineCreationInformation Info)
  {
    version(Windows)
    {
      import krepel.d3d11_render_device;
      D3D11RenderDevice Device = EngineAllocator.New!D3D11RenderDevice(EngineAllocator);
      Device.DeviceState.ProcessInstance = Info.Instance;
      Device.DeviceState.WindowHandle = Info.WindowHandle;
    }
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
