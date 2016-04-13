module krepel.win32_main;
version(Windows):

import krepel;
import krepel.win32;
import krepel.win32.directx.xinput;
import krepel.memory;
import krepel.container;
import krepel.string;


import std.string : toStringz, fromStringz;

alias CString = const(char)*;
enum VK_LAYER_LUNARG_STANDARD_VALIDATION_NAME = "VK_LAYER_LUNARG_standard_validation";

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

__gshared bool Running;
__gshared IAllocator Allocator;

void Verify(VkResult Result, string File = __FILE__, size_t Line = __LINE__)
{
  import std.conv : to;

  if(Result != VK_SUCCESS)
  {
    Log.Failure("%s(%u): %s", File, Line, Result.to!string);
    DebugBreak();
    assert(false, "Vulkan verification failed. Check the log.");
  }
}

void Win32SetupConsole(CString Title)
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
  .Allocator = Heap.Wrap();
  scope(exit) .Allocator = null;

  Log = .Allocator.New!LogData(.Allocator);
  scope(success)
  {
    .Allocator.Delete(Log);
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
      auto Vulkan = .Allocator.NewARC!VulkanData(.Allocator);
      if(Vulkan.Initialize(Instance, Window))
      {
        Log.Info("Vulkan is initialized.");

        if(Vulkan.PrepareSwapchain())
        {
          Log.Info("Swapchain is prepared.");
        }
        else
        {
          Log.Info("Failed to prepare swap chain.");
        }
      }
      else
      {
        Log.Info("Failed to initialize Vulkan.");
      }
      // TODO: Vulkan.Destroy();
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
        .Running = false;
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
          .Running = false;
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
      .Running = false;
    } break;

    case WM_DESTROY:
    {
      // TODO: Handle this as an error - recreate Window?
      .Running = false;
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

class VulkanData
{
  RefCountPayloadData RefCountPayload;

  //
  // General Data
  //
  version(all)
  {

    HMODULE DLL;
    UString DLLName;

    PFN_vkCreateInstance vkCreateInstance;
    PFN_vkGetInstanceProcAddr vkGetInstanceProcAddr;
    PFN_vkEnumerateInstanceLayerProperties vkEnumerateInstanceLayerProperties;
    PFN_vkEnumerateInstanceExtensionProperties vkEnumerateInstanceExtensionProperties;

    VkInstance Instance;

    VkDebugReportCallbackEXT DebugReportCallback;

    size_t GpuIndex;
    VkPhysicalDevice Gpu;
    uint GpuCount;

    VkPhysicalDeviceProperties GpuProperties;
    VkPhysicalDeviceMemoryProperties GpuMemoryProperties;
    VkPhysicalDeviceFeatures GpuFeatures;

    uint QueueCount;
    Array!VkQueueFamilyProperties QueueProperties;

    VkSurfaceKHR Surface;

    uint QueueNodeIndex = uint.max; // For both graphics and presenting.

    VkDevice Device;
    VkQueue Queue;

    VkFormat Format;
    VkColorSpaceKHR ColorSpace;
  }

  //
  // Swapchain Data
  //
  version(all)
  {
    uint Width = 1200;
    uint Height = 720;

    VkCommandPool CommandPool;
    VkCommandBuffer SetupCommand;
    VkCommandBuffer DrawCommand;

    VkSwapchainKHR Swapchain;
    uint SwapchainImageCount;
    Array!SwapchainBufferData SwapchainBuffers;
    uint CurrentSwapchainBuffer;

    DepthData Depth;
  }

  //
  // Stuff
  //
  version(all)
  {
    bool UseStagingBuffer;
    enum TextureCount = 1;
    TextureData[TextureCount] Textures;
  }

  this(IAllocator Allocator)
  {
    DLLName = UString(Allocator);
    QueueProperties.Allocator = Allocator;
    SwapchainBuffers.Allocator = Allocator;
  }
}

struct SwapchainBufferData
{
  VkImage Image;
  VkCommandBuffer Command;
  VkImageView View;
}

struct DepthData
{
  VkFormat Format;

  VkImage Image;
  VkDeviceMemory Memory;
  VkImageView View;
}

struct TextureData
{
  VkSampler Sampler;

  VkImage Image;
  VkImageLayout ImageLayout;

  VkDeviceMemory Memory;
  VkImageView View;
  int TextureWidth;
  int TextureHeight;
}

bool Initialize(VulkanData Vulkan, HINSTANCE ProcessHandle, HWND WindowHandle)
{
  with(Vulkan)
  {
    //
    // Load DLL
    //
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
        return false;
      }
    }

    //
    // Load Crucial Functions Pointers
    //
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
          return false;
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
          return false;
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
          return false;
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
          return false;
        }
      }
    }


    //
    // Create Instance
    //
    {
      //
      // Instance Layers
      //
      auto LayerNames = Array!(CString)(.Allocator);
      {
        // Required extensions:
        bool SurfaceLayerFound;
        bool PlatformSurfaceLayerFound;

        uint LayerCount;
        vkEnumerateInstanceLayerProperties(&LayerCount, null).Verify;

        auto LayerProperties = Array!VkLayerProperties(.Allocator);
        LayerProperties.Expand(LayerCount);
        vkEnumerateInstanceLayerProperties(&LayerCount, LayerProperties.Data.ptr).Verify;

        Log.Info("Explicitly enabled instance layers:");
        foreach(ref Property; LayerProperties)
        {
          auto LayerName = Property.layerName.ptr.fromStringz;
          if(LayerName == VK_LAYER_LUNARG_STANDARD_VALIDATION_NAME)
          {
            LayerNames ~= VK_LAYER_LUNARG_STANDARD_VALIDATION_NAME.ptr;
          }
          else
          {
            Log.Info("  [ ] %s", LayerName);
            continue;
          }

          Log.Info("  [x] %s", LayerName);
        }
      }

      //
      // Instance Extensions
      //
      auto ExtensionNames = Array!(CString)(.Allocator);
      {
        // Required extensions:
        bool SurfaceExtensionFound;
        bool PlatformSurfaceExtensionFound;

        uint ExtensionCount;
        vkEnumerateInstanceExtensionProperties(null, &ExtensionCount, null).Verify;

        auto ExtensionProperties = Array!VkExtensionProperties(.Allocator);
        ExtensionProperties.Expand(ExtensionCount);
        vkEnumerateInstanceExtensionProperties(null, &ExtensionCount, ExtensionProperties.Data.ptr).Verify;

        Log.Info("Explicitly enabled instance extensions:");
        foreach(ref Property; ExtensionProperties)
        {
          auto ExtensionName = Property.extensionName.ptr.fromStringz;
          if(ExtensionName == VK_KHR_SURFACE_EXTENSION_NAME)
          {
            ExtensionNames ~= VK_KHR_SURFACE_EXTENSION_NAME.ptr;
            SurfaceExtensionFound = true;
          }
          else if(ExtensionName == VK_KHR_WIN32_SURFACE_EXTENSION_NAME)
          {
            ExtensionNames ~= VK_KHR_WIN32_SURFACE_EXTENSION_NAME.ptr;
            PlatformSurfaceExtensionFound = true;
          }
          else if(ExtensionName == VK_EXT_DEBUG_REPORT_EXTENSION_NAME)
          {
            ExtensionNames ~= VK_EXT_DEBUG_REPORT_EXTENSION_NAME.ptr;
          }
          else
          {
            Log.Info("  [ ] %s", ExtensionName);
            continue;
          }

          Log.Info("  [x] %s", ExtensionName);
        }

        bool Success = true;

        if(!SurfaceExtensionFound)
        {
          Log.Failure("Failed to load required extension: %s", VK_KHR_SURFACE_EXTENSION_NAME);
          Success = false;
        }

        if(!PlatformSurfaceExtensionFound)
        {
          Log.Failure("Failed to load required extension: %s", VK_KHR_WIN32_SURFACE_EXTENSION_NAME);
          Success = false;
        }

        if(!Success) return false;
      }

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

        enabledExtensionCount = cast(uint)ExtensionNames.Count;
        ppEnabledExtensionNames = ExtensionNames.Data.ptr;

        enabledLayerCount = cast(uint)LayerNames.Count;
        ppEnabledLayerNames = LayerNames.Data.ptr;
      }

      vkCreateInstance(&CreateInfo, null, &Instance).Verify;
      assert(Instance);
    }
    Log.Info("Created Vulkan instance.");

    //
    // Load Instance Functions
    //
    //PFN_vkGetDeviceProcAddr vkGetDeviceProcAddr;
    {
      LoadAllInstanceFunctions(vkGetInstanceProcAddr, Instance);
      //vkGetDeviceProcAddr = LoadInstanceFunction(vkGetInstanceProcAddr, Instance, "vkGetDeviceProcAddr".ptr, .vkGetDeviceProcAddr);
    }
    Log.Info("Finished loading instance functions.");

    //
    // Debugging setup
    //
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
          Instance,
          &DebugSetupInfo,
          null,
          &DebugReportCallback).Verify;
      }
      else
      {
        Log.Warning("Unable to set up debugging: vkCreateDebugReportCallbackEXT is null");
        return false;
      }
    }
    Log.Info("Debug Callback is set up.");

    //
    // Choose Physical Device
    //
    {
      vkEnumeratePhysicalDevices(Instance, &GpuCount, null).Verify;
      assert(GpuCount > 0);

      Log.Info("Found %u physical device(s).", GpuCount);

      auto Gpus = Array!VkPhysicalDevice(.Allocator);
      Gpus.Expand(GpuCount);

      vkEnumeratePhysicalDevices(Instance, &GpuCount, Gpus.Data.ptr).Verify;

      // Use the first Physical Device for now.
      GpuIndex = 0;
      Gpu = Gpus[GpuIndex];
    }
    Log.Info("Using physical device %u", GpuIndex);

    //
    // Queue and Physical Device Properties.
    //
    {
      vkGetPhysicalDeviceProperties(Gpu, &GpuProperties);
      vkGetPhysicalDeviceMemoryProperties(Gpu, &GpuMemoryProperties);
      vkGetPhysicalDeviceFeatures(Gpu, &GpuFeatures);

      vkGetPhysicalDeviceQueueFamilyProperties(Gpu, &QueueCount, null);
      QueueProperties.Expand(QueueCount);
      vkGetPhysicalDeviceQueueFamilyProperties(Gpu, &QueueCount, QueueProperties.Data.ptr);
    }
    Log.Info("Retrieved physical device and queue properties.");

    //
    // Create Win32 Surface
    //
    {
      VkWin32SurfaceCreateInfoKHR CreateInfo;
      with(CreateInfo)
      {
        hinstance = ProcessHandle;
        hwnd = WindowHandle;
      }

      vkCreateWin32SurfaceKHR(Instance, &CreateInfo, null, &Surface).Verify;
    }
    Log.Info("Created Win32 Surface.");

    //
    // Find Queue for Graphics and Presenting
    //
    {
      uint GraphicsIndex = uint.max;
      uint PresentIndex = uint.max;
      foreach(uint Index; 0 .. QueueCount)
      {
        VkBool32 SupportsPresenting;
        vkGetPhysicalDeviceSurfaceSupportKHR(Gpu, Index, Surface, &SupportsPresenting);

        if(QueueProperties[Index].queueFlags & VK_QUEUE_GRAPHICS_BIT)
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
        return false;
      }

      if(PresentIndex == uint.max)
      {
        Log.Failure("Unable to find Present queue.");
        return false;
      }

      if(GraphicsIndex != PresentIndex)
      {
        Log.Failure("(2)");
        return false;
      }

      QueueNodeIndex = GraphicsIndex;
    }

    //
    // Create Logical Device
    //
    {
      //
      // Device Layers
      //
      auto LayerNames = Array!(CString)(.Allocator);
      {
        // Required extensions:
        bool SurfaceLayerFound;
        bool PlatformSurfaceLayerFound;

        uint LayerCount;
        vkEnumerateDeviceLayerProperties(Gpu, &LayerCount, null).Verify;

        auto LayerProperties = Array!VkLayerProperties(.Allocator);
        LayerProperties.Expand(LayerCount);
        vkEnumerateDeviceLayerProperties(Gpu, &LayerCount, LayerProperties.Data.ptr).Verify;

        Log.Info("Explicitly enabled device layers:");
        foreach(ref Property; LayerProperties)
        {
          auto LayerName = Property.layerName.ptr.fromStringz;
          if(LayerName == VK_LAYER_LUNARG_STANDARD_VALIDATION_NAME)
          {
            LayerNames ~= VK_LAYER_LUNARG_STANDARD_VALIDATION_NAME.ptr;
          }
          else
          {
            Log.Info("  [ ] %s", LayerName);
            continue;
          }

          Log.Info("  [x] %s", LayerName);
        }
      }

      //
      // Device Extensions
      //
      auto ExtensionNames = Array!(CString)(.Allocator);
      {
        // Required extensions:
        bool SwapchainExtensionFound;

        uint ExtensionCount;
        vkEnumerateDeviceExtensionProperties(Gpu, null, &ExtensionCount, null).Verify;

        auto ExtensionProperties = Array!VkExtensionProperties(.Allocator);
        ExtensionProperties.Expand(ExtensionCount);
        vkEnumerateDeviceExtensionProperties(Gpu, null, &ExtensionCount, ExtensionProperties.Data.ptr).Verify;

        Log.Info("Explicitly enabled device extensions:");
        foreach(ref Property; ExtensionProperties)
        {
          auto ExtensionName = Property.extensionName.ptr.fromStringz;
          if(ExtensionName == VK_KHR_SWAPCHAIN_EXTENSION_NAME)
          {
            ExtensionNames ~= VK_KHR_SWAPCHAIN_EXTENSION_NAME.ptr;
            SwapchainExtensionFound = true;
          }
          else
          {
            Log.Info("  [ ] %s", ExtensionName);
            continue;
          }

          Log.Info("  [x] %s", ExtensionName);
        }

        bool Success = true;

        if(!SwapchainExtensionFound)
        {
          Log.Failure("Failed to load required extension: %s", VK_KHR_SWAPCHAIN_EXTENSION_NAME);
          Success = false;
        }

        if(!Success) return false;
      }

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

        enabledLayerCount = cast(uint)LayerNames.Count;
        ppEnabledLayerNames = LayerNames.Data.ptr;

        enabledExtensionCount = cast(uint)ExtensionNames.Count;
        ppEnabledExtensionNames = ExtensionNames.Data.ptr;

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
    {
      uint FormatCount;
      vkGetPhysicalDeviceSurfaceFormatsKHR(Gpu, Surface, &FormatCount, null).Verify;
      assert(FormatCount > 0);

      auto SurfaceFormats = Array!VkSurfaceFormatKHR(.Allocator);
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
  }

  // Done.
  return true;
}

bool PrepareSwapchain(VulkanData Vulkan)
{
  with(Vulkan)
  {
    //
    // Create Command Pool
    //
    {
      VkCommandPoolCreateInfo CreateInfo;
      with(CreateInfo)
      {
        queueFamilyIndex = QueueNodeIndex;
        flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
      }

      vkCreateCommandPool(Device, &CreateInfo, null, &CommandPool).Verify;
      assert(CommandPool);
    }
    Log.Info("Created command pool.");

    //
    // Create Command Buffer
    //
    {
      VkCommandBufferAllocateInfo AllocateInfo;
      with(AllocateInfo)
      {
        commandPool = CommandPool;
        level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
        commandBufferCount = 1;
      }
      vkAllocateCommandBuffers(Device, &AllocateInfo, &DrawCommand).Verify;
    }
    Log.Info("Allocated command buffer for drawing.");

    //
    // Prepare Buffers
    //
    {
      scope(success) CurrentSwapchainBuffer = 0; // Reset.

      VkSwapchainKHR OldSwapchain = Swapchain;

      VkSurfaceCapabilitiesKHR SurfaceCapabilities;
      vkGetPhysicalDeviceSurfaceCapabilitiesKHR(Gpu, Surface, &SurfaceCapabilities).Verify;

      uint PresentModeCount;
      vkGetPhysicalDeviceSurfacePresentModesKHR(Gpu, Surface, &PresentModeCount, null).Verify;

      auto PresentModes = Array!VkPresentModeKHR(.Allocator);
      PresentModes.Expand(PresentModeCount);

      vkGetPhysicalDeviceSurfacePresentModesKHR(Gpu, Surface, &PresentModeCount, PresentModes.Data.ptr).Verify;

      VkExtent2D SwapchainExtent;

      if(SurfaceCapabilities.currentExtent.width == cast(uint)-1)
      {
        assert(SurfaceCapabilities.currentExtent.height == cast(uint)-1);

        SwapchainExtent.width = Width;
        SwapchainExtent.height = Height;
      }
      else
      {
        SwapchainExtent = SurfaceCapabilities.currentExtent;
        Width = SurfaceCapabilities.currentExtent.width;
        Height = SurfaceCapabilities.currentExtent.height;
      }

      VkPresentModeKHR SwapchainPresentMode = VK_PRESENT_MODE_FIFO_KHR;

      // Determine the number of VkImage's to use in the swap chain (we desire to
      // own only 1 image at a time, besides the images being displayed and
      // queued for display):
      uint DesiredNumberOfSwapchainImages = SurfaceCapabilities.minImageCount + 1;

      if (SurfaceCapabilities.maxImageCount > 0 &&
          (DesiredNumberOfSwapchainImages > SurfaceCapabilities.maxImageCount))
      {
        // Application must settle for fewer images than desired:
        DesiredNumberOfSwapchainImages = SurfaceCapabilities.maxImageCount;
      }

      VkSurfaceTransformFlagBitsKHR PreTransform;
      if(SurfaceCapabilities.supportedTransforms & VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR)
      {
        PreTransform = VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR;
      }
      else
      {
        PreTransform = SurfaceCapabilities.currentTransform;
      }

      VkSwapchainCreateInfoKHR SwapchainCreateInfo;
      with(SwapchainCreateInfo)
      {
        surface = Surface;
        minImageCount = DesiredNumberOfSwapchainImages;
        imageFormat = Format;
        imageColorSpace = ColorSpace;
        imageExtent = SwapchainExtent;
        imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
        preTransform = PreTransform;
        compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
        imageArrayLayers = 1;
        imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;
        queueFamilyIndexCount = 0;
        pQueueFamilyIndices = null;
        presentMode = SwapchainPresentMode;
        oldSwapchain = OldSwapchain;
        clipped = true;
      }

      vkCreateSwapchainKHR(Device, &SwapchainCreateInfo, null, &Swapchain).Verify;
      assert(Swapchain);
      Log.Info("Created Swapchain.");

      if(OldSwapchain)
      {
        vkDestroySwapchainKHR(Device, OldSwapchain, null);
        Log.Info("Destroyed previous swapchain.");
      }

      vkGetSwapchainImagesKHR(Device, Swapchain, &SwapchainImageCount, null).Verify;

      auto SwapchainImages = Array!VkImage(.Allocator);
      SwapchainImages.Expand(SwapchainImageCount);
      vkGetSwapchainImagesKHR(Device, Swapchain, &SwapchainImageCount, SwapchainImages.Data.ptr).Verify;

      SwapchainBuffers.Clear();
      SwapchainBuffers.Expand(SwapchainImageCount);

      foreach(uint Index; 0 .. SwapchainImageCount)
      {
        VkImageViewCreateInfo ColorAttachmentCreateInfo;
        with(ColorAttachmentCreateInfo)
        {
          format = Format;

          components.r = VK_COMPONENT_SWIZZLE_R;
          components.g = VK_COMPONENT_SWIZZLE_G;
          components.b = VK_COMPONENT_SWIZZLE_B;
          components.a = VK_COMPONENT_SWIZZLE_A;

          subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
          subresourceRange.baseMipLevel = 0;
          subresourceRange.levelCount = 1;
          subresourceRange.baseArrayLayer = 0;
          subresourceRange.layerCount = 1;

          viewType = VK_IMAGE_VIEW_TYPE_2D;
          flags = 0;
        }

        SwapchainBuffers[Index].Image = SwapchainImages[Index];

        // Render loop will expect image to have been used before and in
        // VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
        // layout and will change to COLOR_ATTACHMENT_OPTIMAL, so init the image
        // to that state.
        SetImageLayout(Vulkan, SwapchainBuffers[Index].Image,
                       cast(VkImageAspectFlags)VK_IMAGE_ASPECT_COLOR_BIT,
                       cast(VkImageLayout)VK_IMAGE_LAYOUT_UNDEFINED,
                       cast(VkImageLayout)VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
                       cast(VkAccessFlags)0);

        ColorAttachmentCreateInfo.image = SwapchainBuffers[Index].Image;

        vkCreateImageView(Device, &ColorAttachmentCreateInfo, null,
                          &SwapchainBuffers[Index].View).Verify;
      }
    }
    Log.Info("Prepared swap chain buffers.");

    //
    // Prepare Depth
    //
    {
      Depth.Format = VK_FORMAT_D16_UNORM;
      VkImageCreateInfo ImageCreateInfo;
      with(ImageCreateInfo)
      {
        imageType = VK_IMAGE_TYPE_2D;
        format = Depth.Format;
        extent = VkExtent3D(Width, Height, 1);
        mipLevels = 1;
        arrayLayers = 1;
        samples = VK_SAMPLE_COUNT_1_BIT;
        tiling = VK_IMAGE_TILING_OPTIMAL;
        usage = VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT;
      }

      // Create image.
      vkCreateImage(Device, &ImageCreateInfo, null, &Depth.Image).Verify;

      // Get memory requirements for this object.
      VkMemoryRequirements MemoryRequirements;
      vkGetImageMemoryRequirements(Device, Depth.Image, &MemoryRequirements);

      // Select memory size and type.
      VkMemoryAllocateInfo MemoryAllocateInfo;
      MemoryAllocateInfo.allocationSize = MemoryRequirements.size;
      auto Result = ExtractMemoryTypeFromProperties(Vulkan,
                                                    MemoryRequirements.memoryTypeBits,
                                                    0, // No requirements.
                                                    &MemoryAllocateInfo.memoryTypeIndex);
      assert(Result);

      // Allocate memory.
      vkAllocateMemory(Device, &MemoryAllocateInfo, null, &Depth.Memory).Verify;

      // Bind memory.
      vkBindImageMemory(Device, Depth.Image, Depth.Memory, 0).Verify;

      SetImageLayout(Vulkan, Depth.Image,
                     cast(VkImageAspectFlags)VK_IMAGE_ASPECT_DEPTH_BIT,
                     cast(VkImageLayout)VK_IMAGE_LAYOUT_UNDEFINED,
                     cast(VkImageLayout)VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
                     cast(VkAccessFlags)0);

      // Create image view.
      VkImageViewCreateInfo ImageViewCreateInfo;
      with(ImageViewCreateInfo)
      {
        image = Depth.Image;
        format = Depth.Format;
        subresourceRange = VkImageSubresourceRange(VK_IMAGE_ASPECT_DEPTH_BIT, 0, 1, 0, 1);
      }
      vkCreateImageView(Device, &ImageViewCreateInfo, null, &Depth.View).Verify;
    }
    Log.Info("Depth is prepared.");

    //
    // Prepare Textures
    //
    {
      const VkFormat TextureFormat = VK_FORMAT_B8G8R8A8_UNORM;
      VkFormatProperties FormatProperties;
      uint[2][TextureCount] TextureColors =
      [
        [ 0xffff0000, 0xff00ff00 ],
      ];

      vkGetPhysicalDeviceFormatProperties(Gpu, TextureFormat, &FormatProperties);

      foreach(Index; 0 .. TextureCount)
      {
        Log.Info("Setting up texture %u", Index);

        if ((FormatProperties.linearTilingFeatures & VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT) &&
            !UseStagingBuffer)
        {
          // Device can texture using linear textures.
          PrepareTextureImage(Vulkan, TextureColors[Index], &Vulkan.Textures[Index],
                              VK_IMAGE_TILING_LINEAR,
                              /*cast(VkImageUsageFlags)*/VK_IMAGE_USAGE_SAMPLED_BIT,
                              /*cast(VkFlags)*/VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT);
        }
        else if (FormatProperties.optimalTilingFeatures & VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT)
        {
          // Must use staging buffer to copy linear texture to optimized.
          TextureData StagingTexture;

          PrepareTextureImage(Vulkan, TextureColors[Index], &StagingTexture,
                              VK_IMAGE_TILING_LINEAR,
                              /*cast(VkImageUsageFlags)*/VK_IMAGE_USAGE_TRANSFER_SRC_BIT,
                              VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT);

          PrepareTextureImage(Vulkan, TextureColors[Index], &Vulkan.Textures[Index],
                              VK_IMAGE_TILING_OPTIMAL,
                              /*cast(VkImageUsageFlags)*/(VK_IMAGE_USAGE_TRANSFER_DST_BIT | VK_IMAGE_USAGE_SAMPLED_BIT),
                              VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);

          SetImageLayout(Vulkan, StagingTexture.Image,
                         /*cast(VkImageAspectFlags)*/VK_IMAGE_ASPECT_COLOR_BIT,
                         StagingTexture.ImageLayout,
                         VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
                         /*cast(VkAccessFlags)*/0);

          SetImageLayout(Vulkan, Vulkan.Textures[Index].Image,
                         VK_IMAGE_ASPECT_COLOR_BIT,
                         Vulkan.Textures[Index].ImageLayout,
                         VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                         0);

          VkImageCopy CopyRegion;
          with(CopyRegion)
          {
            srcSubresource.aspectMask = /*cast(VkImageAspectFlags)*/VK_IMAGE_ASPECT_COLOR_BIT;
            srcSubresource.layerCount = 1;

            // Same subresource data.
            dstSubresource = srcSubresource;

            extent = VkExtent3D(StagingTexture.TextureWidth, StagingTexture.TextureHeight, 1);
          }
          vkCmdCopyImage(Vulkan.SetupCommand, StagingTexture.Image,
                         VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, Vulkan.Textures[Index].Image,
                         VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &CopyRegion);

          SetImageLayout(Vulkan, Vulkan.Textures[Index].Image,
                         VK_IMAGE_ASPECT_COLOR_BIT,
                         VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                         Vulkan.Textures[Index].ImageLayout,
                         0);

          Vulkan.FlushSetupCommand();

          // Clean up staging resources.
          vkDestroyImage(Vulkan.Device, StagingTexture.Image, null);
          vkFreeMemory(Vulkan.Device, StagingTexture.Memory, null);
        }
        else
        {
          // Can't support VK_FORMAT_B8G8R8A8_UNORM !?
          assert(false, "No support for B8G8R8A8_UNORM as texture image format.");
        }

        // Create sampler.
        {
          VkSamplerCreateInfo SamplerCreateInfo;
          with(SamplerCreateInfo)
          {
            magFilter = VK_FILTER_NEAREST;
            minFilter = VK_FILTER_NEAREST;
            mipmapMode = VK_SAMPLER_MIPMAP_MODE_NEAREST;
            addressModeU = VK_SAMPLER_ADDRESS_MODE_REPEAT;
            addressModeV = VK_SAMPLER_ADDRESS_MODE_REPEAT;
            addressModeW = VK_SAMPLER_ADDRESS_MODE_REPEAT;
            anisotropyEnable = VK_FALSE;
            maxAnisotropy = 1;
            compareOp = VK_COMPARE_OP_NEVER;
            borderColor = VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE;
            unnormalizedCoordinates = VK_FALSE;
          }
          vkCreateSampler(Vulkan.Device, &SamplerCreateInfo, null, &Vulkan.Textures[Index].Sampler).Verify;
        }

        // Create image view.
        {
          VkImageViewCreateInfo ImageViewCreateInfo;
          with(ImageViewCreateInfo)
          {
            viewType = VK_IMAGE_VIEW_TYPE_2D;
            format = TextureFormat;
            components = VkComponentMapping(VK_COMPONENT_SWIZZLE_R,
                                            VK_COMPONENT_SWIZZLE_G,
                                            VK_COMPONENT_SWIZZLE_B,
                                            VK_COMPONENT_SWIZZLE_A);
            subresourceRange = VkImageSubresourceRange(VK_IMAGE_ASPECT_COLOR_BIT, 0, 1, 0, 1);
            image = Vulkan.Textures[Index].Image;
          }
          vkCreateImageView(Vulkan.Device, &ImageViewCreateInfo, null, &Vulkan.Textures[Index].View).Verify;
        }
      }
    }
    Log.Info("Textures are prepared.");

    //
    // Prepare Vertices
    //
    {
    }
    //Log.Info("Vertices are prepared.");

    //
    // Prepare Descriptor Layout
    //
    {
    }
    //Log.Info("Descriptor layout prepared.");

    //
    // Prepare Render Pass
    //
    {
    }
    //Log.Info("Render pass prepared.");

    //
    // Prepare Pipeline
    //
    {
    }
    //Log.Info("Pipeline prepared.");

    //
    // Prepare Descriptor Pool
    //
    {
    }
    //Log.Info("Descriptor pool prepared.");

    //
    // Prepare Descriptor Set
    //
    {
    }
    //Log.Info("Descriptor set prepared.");

    //
    // Prepare Framebuffers
    //
    {
    }
    //Log.Info("Framebuffers prepared.");
  }

  // Done.
  return true;
}

void SetImageLayout(VulkanData Vulkan,
                    VkImage Image,
                    VkImageAspectFlags AspectMask,
                    VkImageLayout OldImageLayout,
                    VkImageLayout NewImageLayout,
                    VkAccessFlags SourceAccessMask)
{
  if(Vulkan.SetupCommand == VK_NULL_HANDLE)
  {
    VkCommandBufferAllocateInfo SetupCommandBufferAllocateInfo;
    with(SetupCommandBufferAllocateInfo)
    {
      commandPool = Vulkan.CommandPool;
      level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
      commandBufferCount = 1;
    }

    vkAllocateCommandBuffers(Vulkan.Device, &SetupCommandBufferAllocateInfo, &Vulkan.SetupCommand).Verify;

    VkCommandBufferInheritanceInfo InheritanceInfo;
    VkCommandBufferBeginInfo BeginInfo;
    BeginInfo.pInheritanceInfo = &InheritanceInfo;
    vkBeginCommandBuffer(Vulkan.SetupCommand, &BeginInfo).Verify;
  }

  VkImageMemoryBarrier ImageMemoryBarrier;
  with(ImageMemoryBarrier)
  {
    srcAccessMask = SourceAccessMask;
    oldLayout = OldImageLayout;
    newLayout = NewImageLayout;
    image = Image;
    subresourceRange = VkImageSubresourceRange(AspectMask, 0, 1, 0, 1);

    if(NewImageLayout == VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL)
    {
      // Make sure anything that was copying from this image has completed.
      dstAccessMask = VK_ACCESS_TRANSFER_READ_BIT;
    }

    if(NewImageLayout == VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
    {
      dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
    }

    if(NewImageLayout == VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL)
    {
      dstAccessMask = VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT;
    }

    if(NewImageLayout == VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL)
    {
      // Make sure any Copy or CPU writes to image are flushed.
      dstAccessMask = VK_ACCESS_SHADER_READ_BIT | VK_ACCESS_INPUT_ATTACHMENT_READ_BIT;
    }
  }

  VkPipelineStageFlags SourceStages = VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;
  VkPipelineStageFlags DestinationStages = VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;

  vkCmdPipelineBarrier(Vulkan.SetupCommand,             // commandBuffer
                       SourceStages, DestinationStages, // dstStageMask, srcStageMask
                       0,                               // dependencyFlags
                       0, null,                         // memoryBarrierCount, pMemoryBarriers
                       0, null,                         // bufferMemoryBarrierCount, pBufferMemoryBarriers
                       1, &ImageMemoryBarrier);         // imageMemoryBarrierCount, pImageMemoryBarriers
}

bool ExtractMemoryTypeFromProperties(VulkanData Vulkan,
                                     uint32_t TypeBits,
                                     VkFlags RequirementsMask,
                                     uint* TypeIndex)
{
  // Search memtypes to find first index with those properties
  foreach(Index; 0 .. 32)
  {
    if(TypeBits & 1)
    {
      // Type is available, does it match user properties?
      const PropertyFlags = Vulkan.GpuMemoryProperties.memoryTypes[Index].propertyFlags;
      if((PropertyFlags & RequirementsMask) == RequirementsMask)
      {
        *TypeIndex = Index;
        return true;
      }
    }
    TypeBits >>= 1;
  }

  // No memory types matched, return failure
  return false;
}

void PrepareTextureImage(VulkanData Vulkan,
                         uint[2] TextureColors,
                         TextureData* Texture,
                         VkImageTiling Tiling,
                         VkImageUsageFlags Usage,
                         VkFlags RequiredProperties)
{
  const VkFormat TextureFormat = VK_FORMAT_B8G8R8A8_UNORM;
  const int TextureWidth = 2;
  const int TextureHeight = 2;

  Texture.TextureWidth = TextureWidth;
  Texture.TextureHeight = TextureHeight;

  VkImageCreateInfo ImageCreateInfo;
  with(ImageCreateInfo)
  {
    imageType = VK_IMAGE_TYPE_2D;
    format = TextureFormat;
    extent = VkExtent3D(TextureWidth, TextureHeight, 1);
    mipLevels = 1;
    arrayLayers = 1;
    samples = VK_SAMPLE_COUNT_1_BIT;
    tiling = Tiling;
    usage = Usage;
    initialLayout = VK_IMAGE_LAYOUT_PREINITIALIZED;
  }

  vkCreateImage(Vulkan.Device, &ImageCreateInfo, null, &Texture.Image).Verify;

  VkMemoryRequirements MemoryRequirements;
  vkGetImageMemoryRequirements(Vulkan.Device, Texture.Image, &MemoryRequirements);

  VkMemoryAllocateInfo MemoryAllocateInfo;
  MemoryAllocateInfo.allocationSize = MemoryRequirements.size;
  auto Result = ExtractMemoryTypeFromProperties(Vulkan,
                                                MemoryRequirements.memoryTypeBits,
                                                RequiredProperties,
                                                &MemoryAllocateInfo.memoryTypeIndex);
  assert(Result);

  // Allocate memory
  vkAllocateMemory(Vulkan.Device, &MemoryAllocateInfo, null, &Texture.Memory).Verify;

  // Bind memory
  vkBindImageMemory(Vulkan.Device, Texture.Image, Texture.Memory, 0).Verify;

  if (RequiredProperties & VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT)
  {
    VkImageSubresource Subresource;
    Subresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
    VkSubresourceLayout Layout;
    void* Data;

    vkGetImageSubresourceLayout(Vulkan.Device, Texture.Image, &Subresource,
                                &Layout);

    vkMapMemory(Vulkan.Device, Texture.Memory, 0, MemoryAllocateInfo.allocationSize, 0, &Data).Verify;

    for(int Y = 0; Y < TextureHeight; Y++)
    {
      auto Row = cast(uint*)(Data + Layout.rowPitch * Y);
      for(int X = 0; X < TextureWidth; X++)
      {
        const ColorIndex = (X & 1) ^ (Y & 1);
        Row[X] = TextureColors[ColorIndex];
      }
    }

    vkUnmapMemory(Vulkan.Device, Texture.Memory);
  }

  Texture.ImageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
  SetImageLayout(Vulkan, Texture.Image,
                 cast(VkImageAspectFlags)VK_IMAGE_ASPECT_COLOR_BIT,
                 cast(VkImageLayout)VK_IMAGE_LAYOUT_PREINITIALIZED,
                 Texture.ImageLayout,
                 cast(VkAccessFlags)VK_ACCESS_HOST_WRITE_BIT);
  // Setting the image layout does not reference the actual memory so no need to add a mem ref.
}

void FlushSetupCommand(VulkanData Vulkan)
{
  with(Vulkan)
  {
    if(SetupCommand is VK_NULL_HANDLE) return;

    vkEndCommandBuffer(SetupCommand).Verify;

    VkSubmitInfo SubmitInfo;
    with(SubmitInfo)
    {
      commandBufferCount = 1;
      pCommandBuffers = &SetupCommand;
    }
    VkFence NullFence;
    vkQueueSubmit(Queue, 1, &SubmitInfo, NullFence).Verify;

    vkQueueWaitIdle(Queue).Verify;

    vkFreeCommandBuffers(Device, CommandPool, 1, &SetupCommand);
    SetupCommand = VK_NULL_HANDLE;
  }
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
