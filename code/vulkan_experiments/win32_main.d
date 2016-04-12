module krepel.win32_main;
version(Windows):

import krepel;
import krepel.win32;
import krepel.win32.directx.xinput;
import krepel.memory;
import krepel.container;
import krepel.string;


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

import vulkan;
import vulkan_experiments.helper;

struct GlobalData
{
  bool Running;
  IAllocator Allocator;
}

__gshared GlobalData G;


auto Verify(VkResult Result)
{
  import std.conv : to;
  assert(Result == VK_SUCCESS, Result.to!string);
  return Result;
}

void Win32SetupConsole(const(char)* Title)
{
  static import core.stdc.stdio;

  AllocConsole();
  AttachConsole(GetCurrentProcessId());
  core.stdc.stdio.freopen("CON".ptr, "w".ptr, core.stdc.stdio.stdout);
  SetConsoleTitleA(Title);
}

int MyWinMain(HINSTANCE Instance, HINSTANCE PreviousInstance,
              LPSTR CommandLine, int ShowCode)
{
  debug Win32SetupConsole("Krepel Console".ptr);

  void* BaseAddress;
  debug BaseAddress = cast(void*)2.TiB;
  const MemorySize = 6.GiB;
  auto RawMemory = VirtualAlloc(BaseAddress,
                                MemorySize,
                                MEM_RESERVE | MEM_COMMIT,
                                PAGE_READWRITE);
  if(RawMemory is null)
  {
    return 1;
  }
  assert(RawMemory);
  auto Heap = HeapMemory((cast(ubyte*)RawMemory)[0 .. MemorySize]);
  G.Allocator = Heap.Wrap();

  Log = G.Allocator.New!LogData(G.Allocator);
  scope(success)
  {
    G.Allocator.Delete(Log);
    Log = null;
  }

  debug Log.Sinks ~= ToDelegate(&StdoutLogSink);
  Log.Sinks ~= ToDelegate(&VisualStudioLogSink);

  Log.Info("=== Beginning of Log");
  scope(exit) Log.Info("=== End of Log");

  version(XInput_RuntimeLinking) LoadXInput();

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
      OptionData Options;
      AllOnTheStack(Instance, Window, Options);
    }
    else
    {
      Log.Failure("Unable to create window.");
    }
  }
  else
  {
    Log.Failure("Failed to create window class.");
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
        G.Running = false;
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
          G.Running = false;
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
      G.Running = false;
    } break;

    case WM_DESTROY:
    {
      // TODO: Handle this as an error - recreate Window?
      G.Running = false;
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

struct OptionData
{
  bool Validate;
}

/// Params:
///   Options = Unused for now.
void AllOnTheStack(HINSTANCE ProcessHandle, HWND WindowHandle, OptionData Options)
{
  //
  // Load DLL
  //
  HMODULE DLL;
  auto DLLName = UString(G.Allocator);
  {
    DLL = LoadLibrary("vulkan-1.dll");
    if(DLL)
    {
      char[1.KiB] Buffer;
      auto CharCount = GetModuleFileNameA(DLL, Buffer.ptr, cast(DWORD)Buffer.length);
      DLLName = Buffer[0 .. CharCount];
    }
    else
    {
      Log.Failure("Failed to load DLL: %s", DLLName);
      return;
    }
  }

  //
  // Load Crucial Functions Pointers
  //
  PFN_vkCreateInstance vkCreateInstance;
  PFN_vkGetInstanceProcAddr vkGetInstanceProcAddr;
  PFN_vkEnumerateInstanceLayerProperties vkEnumerateInstanceLayerProperties;
  PFN_vkEnumerateInstanceExtensionProperties vkEnumerateInstanceExtensionProperties;
  {
    // These have to be loaded with GetProcAddress because for everything else
    // we need a Vulkan instance, which is obtained later.

    //
    // vkCreateInstance
    //
    {
      auto Func = GetProcAddress(DLL, "vkCreateInstance".ptr);
      if(Func)
      {
        vkCreateInstance = cast(typeof(vkCreateInstance))Func;
      }
      else
      {
        Log.Failure("Unable to load function from Vulkan DLL: vkCreateInstance");
        return;
      }
    }

    //
    // vkGetInstanceProcAddr
    //
    {
      auto Func = GetProcAddress(DLL, "vkGetInstanceProcAddr".ptr);
      if(Func)
      {
        vkGetInstanceProcAddr = cast(typeof(vkGetInstanceProcAddr))Func;
      }
      else
      {
        Log.Failure("Unable to load function from Vulkan DLL: vkGetInstanceProcAddr");
        return;
      }
    }

    //
    // vkEnumerateInstanceLayerProperties
    //
    {
      auto Func = GetProcAddress(DLL, "vkEnumerateInstanceLayerProperties".ptr);
      if(Func)
      {
        vkEnumerateInstanceLayerProperties = cast(typeof(vkEnumerateInstanceLayerProperties))Func;
      }
      else
      {
        Log.Failure("Unable to load function from Vulkan DLL: vkEnumerateInstanceLayerProperties");
        return;
      }
    }

    //
    // vkEnumerateInstanceExtensionProperties
    //
    {
      auto Func = GetProcAddress(DLL, "vkEnumerateInstanceExtensionProperties".ptr);
      if(Func)
      {
        vkEnumerateInstanceExtensionProperties = cast(typeof(vkEnumerateInstanceExtensionProperties))Func;
      }
      else
      {
        Log.Failure("Unable to load function from Vulkan DLL: vkEnumerateInstanceExtensionProperties");
        return;
      }
    }
  }

  //
  // Create Instance
  //
  VkInstance Vulkan;
  {
    // TODO: Check for the existance of the requested layers and extensions
    // first.

    const(char)*[1] Layers = [
      "VK_LAYER_LUNARG_standard_validation".ptr
    ];

    const(char)*[3] Extensions =
    [
      VK_KHR_SURFACE_EXTENSION_NAME.ptr,
      VK_KHR_WIN32_SURFACE_EXTENSION_NAME.ptr,
      VK_EXT_DEBUG_REPORT_EXTENSION_NAME.ptr,
    ];

    VkApplicationInfo ApplicationInfo;
    with(ApplicationInfo)
    {
      pApplicationName = "Vulkan Experiments".ptr;
      applicationVersion = VK_MAKE_VERSION(0, 0, 1);

      pEngineName = "Krepel".ptr,
      engineVersion = VK_MAKE_VERSION(0, 0, 1);

      apiVersion = VK_MAKE_VERSION(1, 0, 8);
    }

    VkInstanceCreateInfo CreateInfo;
    with(CreateInfo)
    {
      pApplicationInfo = &ApplicationInfo;

      enabledExtensionCount = Extensions.length;
      ppEnabledExtensionNames = Extensions.ptr;

      enabledLayerCount = Layers.length;
      ppEnabledLayerNames = Layers.ptr;
    }

    vkCreateInstance(&CreateInfo, null, &Vulkan).Verify;
    assert(Vulkan);
  }
  Log.Info("Created Vulkan instance.");

  //
  // Load Instance Functions
  //
  //PFN_vkGetDeviceProcAddr vkGetDeviceProcAddr;
  {
    LoadAllInstanceFunctions(vkGetInstanceProcAddr, Vulkan);
    //vkGetDeviceProcAddr = LoadInstanceFunction(vkGetInstanceProcAddr, Vulkan, "vkGetDeviceProcAddr".ptr, .vkGetDeviceProcAddr);
  }
  Log.Info("Finished loading instance functions.");

  //
  // Debugging setup
  //
  VkDebugReportCallbackEXT DebugReportCallback;
  {
    if(vkCreateDebugReportCallbackEXT !is null)
    {
      VkDebugReportCallbackCreateInfoEXT DebugSetupInfo;
      with(DebugSetupInfo)
      {
        pfnCallback = &DebugMessageCallback;
        flags = VK_DEBUG_REPORT_ERROR_BIT_EXT | VK_DEBUG_REPORT_WARNING_BIT_EXT;
      }
      vkCreateDebugReportCallbackEXT(
        Vulkan,
        &DebugSetupInfo,
        null,
        &DebugReportCallback).Verify;
    }
    else
    {
      Log.Warning("Unable to set up debugging: vkCreateDebugReportCallbackEXT is null");
      return;
    }
  }
  Log.Info("Debug Callback is set up.");

  //
  // Choose Physical Device
  //
  size_t GpuIndex;
  VkPhysicalDevice Gpu;
  uint GpuCount;
  {
    vkEnumeratePhysicalDevices(Vulkan, &GpuCount, null).Verify;
    assert(GpuCount > 0);

    Log.Info("Found %u physical device(s).", GpuCount);

    auto Gpus = Array!VkPhysicalDevice(G.Allocator);
    Gpus.Expand(GpuCount);

    vkEnumeratePhysicalDevices(Vulkan, &GpuCount, Gpus.Data.ptr).Verify;

    // Use the first Physical Device for now.
    GpuIndex = 0;
    Gpu = Gpus[GpuIndex];
  }
  Log.Info("Using physical device %u", GpuIndex);

  //
  // Queue and Physical Device Properties.
  //
  VkPhysicalDeviceProperties GpuProps;
  VkPhysicalDeviceMemoryProperties GpuMemoryProps;
  VkPhysicalDeviceFeatures GpuFeatures;
  uint QueueCount;
  auto QueueProps = Array!VkQueueFamilyProperties(G.Allocator);
  {
    vkGetPhysicalDeviceProperties(Gpu, &GpuProps);
    vkGetPhysicalDeviceMemoryProperties(Gpu, &GpuMemoryProps);
    vkGetPhysicalDeviceFeatures(Gpu, &GpuFeatures);

    vkGetPhysicalDeviceQueueFamilyProperties(Gpu, &QueueCount, null);
    QueueProps.Expand(QueueCount);
    vkGetPhysicalDeviceQueueFamilyProperties(Gpu, &QueueCount, QueueProps.Data.ptr);
  }
  Log.Info("Retrieved physical device and queue properties.");

  //
  // Create Win32 Surface
  //
  VkSurfaceKHR Surface;
  {
    VkWin32SurfaceCreateInfoKHR CreateInfo;
    with(CreateInfo)
    {
      hinstance = ProcessHandle;
      hwnd = WindowHandle;
    }

    vkCreateWin32SurfaceKHR(Vulkan, &CreateInfo, null, &Surface).Verify;
  }
  Log.Info("Created Win32 Surface.");

  //
  // Find Queue for Graphics and Presenting
  //
  uint QueueNodeIndex = uint.max; // For both graphics and presenting.
  {
    uint GraphicsIndex = uint.max;
    uint PresentIndex = uint.max;
    foreach(uint Index; 0 .. QueueCount)
    {
      VkBool32 SupportsPresenting;
      vkGetPhysicalDeviceSurfaceSupportKHR(Gpu, Index, Surface, &SupportsPresenting);

      if(QueueProps[Index].queueFlags & VK_QUEUE_GRAPHICS_BIT)
      {
        if(GraphicsIndex == uint.max)
        {
          GraphicsIndex = Index;
        }

        if(SupportsPresenting)
        {
          GraphicsIndex = Index;
          PresentIndex = Index;
        }
      }
    }

    // TODO: Support for separate graphics and present queue?
    // See tri-demo 1.0.8 line 2200

    if(GraphicsIndex == uint.max)
    {
      Log.Failure("Unable to find Graphics queue.");
      return;
    }

    if(PresentIndex == uint.max)
    {
      Log.Failure("Unable to find Present queue.");
      return;
    }

    if(GraphicsIndex != PresentIndex)
    {
      Log.Failure("(2)");
      return;
    }

    QueueNodeIndex = GraphicsIndex;
  }

  //
  // Create Logical Device
  //
  VkDevice Device;
  VkQueue Queue;
  {
    const(char)*[1] Layers = [
      "VK_LAYER_LUNARG_standard_validation".ptr,
    ];

    //const(char)*[0] Extensions = [
    //];
    const(char)*[] Extensions = null;

    float[1] QueuePriorities = [
      0.0f,
    ];

    VkDeviceQueueCreateInfo QueueCreateInfo;
    with(QueueCreateInfo)
    {
      queueFamilyIndex = QueueNodeIndex;
      queueCount = QueuePriorities.length;
      pQueuePriorities = QueuePriorities.ptr;
    }

    VkPhysicalDeviceFeatures EnabledFeatures;
    with(EnabledFeatures)
    {
      shaderClipDistance = VK_TRUE;
    }

    VkDeviceCreateInfo DeviceCreateInfo;
    with(DeviceCreateInfo)
    {
      queueCreateInfoCount = 1;
      pQueueCreateInfos = &QueueCreateInfo;

      enabledLayerCount = Layers.length;
      ppEnabledLayerNames = Layers.ptr;

      enabledExtensionCount = cast(uint)Extensions.length;
      ppEnabledExtensionNames = Extensions.ptr;

      pEnabledFeatures = &EnabledFeatures;
    }

    vkCreateDevice(Gpu, &DeviceCreateInfo, null, &Device).Verify;
    assert(Device);

    vkGetDeviceQueue(Device, QueueNodeIndex, 0, &Queue);
    assert(Queue);
  }
  Log.Info("Created logical device and retrieved the queue.");

  //
  // Get Physical Device Format and Color Space.
  //
  VkFormat Format;
  VkColorSpaceKHR ColorSpace;
  {
    uint FormatCount;
    vkGetPhysicalDeviceSurfaceFormatsKHR(Gpu, Surface, &FormatCount, null).Verify;
    assert(FormatCount > 0);

    auto SurfaceFormats = Array!VkSurfaceFormatKHR(G.Allocator);
    SurfaceFormats.Expand(FormatCount);

    vkGetPhysicalDeviceSurfaceFormatsKHR(Gpu, Surface, &FormatCount, SurfaceFormats.Data.ptr).Verify;

    if(FormatCount == 1 && SurfaceFormats[0].format == VK_FORMAT_UNDEFINED)
    {
      Format = VK_FORMAT_B8G8R8A8_UNORM;
    }
    else
    {
      Format = SurfaceFormats[0].format;
    }

    ColorSpace = SurfaceFormats[0].colorSpace;
  }
  Log.Info("Got format and color space for the previously created Win32 surface.");

  // Done.
  return;
}

extern(Windows) VkBool32 DebugMessageCallback(
  VkDebugReportFlagsEXT Flags,
  VkDebugReportObjectTypeEXT ObjectType,
  ulong SourceObject,
  size_t Location,
  int MessageCode,
  in char* LayerPrefix,
  in char* Message,
  void* UserData)
{
  if(Flags & VK_DEBUG_REPORT_ERROR_BIT_EXT)
  {
    Log.Failure("[%s] %d: %s", fromStringz(LayerPrefix), MessageCode, fromStringz(Message));
  }
  else if(Flags & VK_DEBUG_REPORT_WARNING_BIT_EXT)
  {
    Log.Warning("[%s] %d: %s", fromStringz(LayerPrefix), MessageCode, fromStringz(Message));
  }

  return false;
}
