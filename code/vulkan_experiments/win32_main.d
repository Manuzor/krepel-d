module krepel.win32_main;
version(Windows):

import krepel;
import krepel.system;
import krepel.win32;
import krepel.win32.directx.xinput;
import krepel.container;
import krepel.string;
import krepel.math;
import krepel.image;


import std.string : toStringz, fromStringz;

alias CString = const(char)*;
enum VK_LAYER_LUNARG_STANDARD_VALIDATION_NAME = "VK_LAYER_LUNARG_standard_validation";

void HandleError(Throwable Error)
{
  auto ErrorString = Error.toString();
  string MessageBoxMessage;
  if(.Log)
  {
    .Log.Failure("%s", Error);
    MessageBoxMessage = "An error occurred. Check the log.";
  }
  else
  {
    MessageBoxMessage = ErrorString[0 .. Min(2000, ErrorString.length)];
  }
  MessageBoxA(null, MessageBoxMessage.toStringz(),
              "Error",
              MB_OK | MB_ICONEXCLAMATION);
}

extern(Windows)
int WinMain(HINSTANCE Instance, HINSTANCE PreviousInstance,
            LPSTR CommandLine, int ShowCode)
{
  int Result = void;

  try
  {
    import core.runtime;

    Runtime.initialize();

    {
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
      scope(exit)
      {
        .Allocator.Delete(Log);
        Log = null;
      }

      debug
      {
        Win32SetupConsole("Krepel Console".ptr);
        Log.Sinks ~= ToDelegate(&StdoutLogSink);
      }
      Log.Sinks ~= ToDelegate(&VisualStudioLogSink);

      Log.Info("=== Beginning of Log ===");
      scope(exit) Log.Info("=== End of Log ===");

      // User another try-catch block to ensure the log still lives.
      try
      {
        Result = MyWinMain(Instance, PreviousInstance, CommandLine, ShowCode);
      }
      catch(Throwable Error)
      {
        HandleError(Error);
      }
    }

    Runtime.terminate();
  }
  catch(Throwable Error)
  {
    HandleError(Error);
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
  if(Result != VK_SUCCESS)
  {
    Log.Failure("%s(%u): %s", File, Line, Result);
    DebugBreak();
    assert(false, "Vulkan verification failed. Check the log.");
  }
}

void PrintSampledTextureProperties(LogData* Log, VkPhysicalDevice Gpu, VkFormat TextureFormat)
{
  VkImageFormatProperties Props;
  vkGetPhysicalDeviceImageFormatProperties(Gpu,
                                           TextureFormat,
                                           VK_IMAGE_TYPE_2D,
                                           VK_IMAGE_TILING_OPTIMAL,
                                           VK_IMAGE_USAGE_SAMPLED_BIT,
                                           0,
                                           &Props);
  Log.BeginScope("Physical Device Image Format Properties (%s)", TextureFormat);
  {
    Log.Info("maxExtent       = %s", Props.maxExtent);
    Log.Info("maxMipLevels    = %s", Props.maxMipLevels);
    Log.Info("maxArrayLayers  = %s", Props.maxArrayLayers);
    Log.Info("sampleCounts    = %s", Props.sampleCounts);
    Log.Info("maxResourceSize = %s", Props.maxResourceSize);
  }
  Log.EndScope("---");
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
  version(XInput_RuntimeLinking) LoadXInput();

  auto Vulkan = Allocator.New!VulkanData(Allocator);
  scope(exit) if(Vulkan) .Allocator.Delete(Vulkan);

  if(!CreateVulkanInstance(Vulkan, No.InstanceValidation))
  {
    Log.Failure("Failed to create vulkan instance.");
    return 1;
  }

  WNDCLASSA WindowClass;
  with(WindowClass)
  {
    style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
    lpfnWndProc = cast(WNDPROC)cast(void*)&Win32MainWindowCallback;
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
      bool VulkanInitialized;

      {
        Log.BeginScope("Initializing Vulkan.");
        VulkanInitialized = Vulkan.Initialize(Instance, Window, No.DeviceValidation);
        if(VulkanInitialized) Log.EndScope("Vulkan initialized successfully.");
        else                  Log.EndScope("Failed to initialize Vulkan.");
      }

      if(VulkanInitialized) Log.EndScope("Vulkan initialized successfully.");
      else                  Log.EndScope("Failed to initialize Vulkan.");

      if(VulkanInitialized)
      {
        scope(success) Vulkan.Cleanup();

        SetWindowLongPtr(Window, GWLP_USERDATA, cast(LONG_PTR)Vulkan.AsPointerTo!void);
        scope(exit) SetWindowLongPtr(Window, GWLP_USERDATA, cast(LONG_PTR)null);

        {
          Log.BeginScope("Preparing Swapchain for the first time.");
          Vulkan.IsPrepared = Vulkan.PrepareSwapchain(1200, 720);
          if(Vulkan.IsPrepared) Log.EndScope("Swapchain is prepared.");
          else                  Log.EndScope("Failed to prepare Swapchain.");
        }

        if(Vulkan.IsPrepared)
        {
          //
          // Main Loop
          //
          Vulkan.DepthStencilValue = 1.0f;
          Vulkan.DepthStencilIncrement = 0.0f;
          .Running = true;
          while(.Running)
          {
            Win32ProcessPendingMessages();

            Vulkan.DepthStencilValue = Clamp(Vulkan.DepthStencilValue + Vulkan.DepthStencilIncrement, 0.8f, 1.0f);

            if(Vulkan.DepthStencilValue == 1.0f)
            {
              Vulkan.DepthStencilIncrement = -0.001;
            }
            else if(Vulkan.DepthStencilValue == 0.8f)
            {
              Vulkan.DepthStencilIncrement = 0.001;
            }

            //Log.Info("Depth Stencil Value Sample: %f", Vulkan.DepthStencilValue);

            if(.IsResizeRequested)
            {
              Log.BeginScope("Resizing swapchain.");
              scope(exit) Log.EndScope("Finished resizing swapchain.");
              Vulkan.Resize(.ResizeRequest_Width, .ResizeRequest_Height);
              .IsResizeRequested = false;
            }

            RedrawWindow(Window, null, null, RDW_INTERNALPAINT);
          }
        }
      }
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
  while(PeekMessageA(&Message, null, 0, 0, PM_REMOVE))
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
          PostQuitMessage(0);
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

__gshared bool IsResizeRequested;
__gshared uint ResizeRequest_Width;
__gshared uint ResizeRequest_Height;

extern(Windows)
LRESULT Win32MainWindowCallback(HWND Window, UINT Message,
                                WPARAM WParam, LPARAM LParam)
{
  enum RESIZE_EVENT_ID = 1337;
  enum MILLISECONDS_TO_WAIT_BEFORE_RESIZING = 200;

  LRESULT Result;

  auto Vulkan = cast(VulkanData)cast(void*)GetWindowLongPtr(Window, GWLP_USERDATA);

  switch(Message)
  {
    case WM_CLOSE:
    {
      // TODO: Handle this with a message to the user?
      PostQuitMessage(0);
    } break;

    case WM_DESTROY:
    {
      // TODO: Handle this as an error - recreate Window?
      PostQuitMessage(0);
    } break;

    case WM_SYSKEYDOWN: goto case; // fallthrough
    case WM_SYSKEYUP:   goto case; // fallthrough
    case WM_KEYDOWN:    goto case; // fallthrough
    case WM_KEYUP: assert(0, "Keyboard messages are handled in the main loop.");

    case WM_ACTIVATEAPP:
    {
      //OutputDebugStringA("WM_ACTIATEAPP\n");
    } break;

    case WM_SIZE:
    {
      if(Vulkan && WParam != SIZE_MINIMIZED)
      {
        .IsResizeRequested = true;
        .ResizeRequest_Width = LParam & 0xffff;
        .ResizeRequest_Height = (LParam & 0xffff0000) >> 16;

        //Vulkan.Resize(NewWidth, NewHeight);
      }
    } break;

    case WM_PAINT:
    {
      PAINTSTRUCT Paint;

      RECT Rect;
      auto MustBeginEndPaint = cast(bool)GetUpdateRect(Window, &Rect, FALSE);

      if(MustBeginEndPaint) BeginPaint(Window, &Paint);
      scope(exit) if(MustBeginEndPaint) EndPaint(Window, &Paint);

      if(Vulkan && Vulkan.IsPrepared)
      {
        Vulkan.Draw();
      }
    } break;

    default:
    {
      Result = DefWindowProcA(Window, Message, WParam, LParam);
    } break;
  }

  return Result;
}

struct VulkanPhysicalDeviceData
{
  size_t                           Index;
  VkPhysicalDevice                 Handle;
  VkPhysicalDeviceProperties       Properties;
  VkPhysicalDeviceMemoryProperties MemoryProperties;
  VkPhysicalDeviceFeatures         Features;
  Array!VkQueueFamilyProperties    QueueProperties;

  @property void Allocator(IAllocator NewAllocator)
  {
    QueueProperties.Allocator = NewAllocator;
  }
}

struct VulkanDeviceData
{
  const(VulkanPhysicalDeviceData)* OwnerGpu;
  VkDevice Handle;
}

class VulkanData
{
  bool IsPrepared;

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

    uint GpuCount;
    VulkanPhysicalDeviceData Gpu;
    VulkanDeviceData Device;

    VkSurfaceKHR Surface;

    uint QueueNodeIndex = uint.max; // For both graphics and presenting.

    VkQueue Queue;

    VkFormat Format;
    VkColorSpaceKHR ColorSpace;
  }

  //
  // Swapchain Data
  //
  version(all)
  {
    uint Width;
    uint Height;

    VkCommandPool CommandPool;
    VkCommandBuffer SetupCommand;
    VkCommandBuffer DrawCommand;

    VkSwapchainKHR Swapchain;
    uint SwapchainImageCount;
    Array!SwapchainBufferData SwapchainBuffers;
    uint CurrentBufferIndex;

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

    VertexBufferData Vertices;
    IndexBufferData Indices;

    VkPipelineLayout PipelineLayout;
    VkDescriptorSetLayout DescriptorSetLayout;

    VkRenderPass RenderPass;
    VkPipeline Pipeline;

    VkDescriptorPool DescriptorPool;
    VkDescriptorSet DescriptorSet;

    Array!VkFramebuffer Framebuffers;

    float DepthStencilValue = 1.0f;
    float DepthStencilIncrement = 0.0f;
  }

  this(IAllocator Allocator)
  {
    DLLName = UString(Allocator);
    Gpu.Allocator = Allocator;
    SwapchainBuffers.Allocator = Allocator;
    Framebuffers.Allocator = Allocator;
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

struct VertexBufferData
{
  VkBuffer Buffer;
  VkDeviceMemory Memory;

  uint BindID;
  uint NumVertices;
  VkVertexInputBindingDescription[1] VertexInputBindingDescs;
  VkVertexInputAttributeDescription[2] VertexInputAttributeDescs;
}

struct IndexBufferData
{
  VkBuffer Buffer;
  VkDeviceMemory Memory;

  uint NumIndices;
}

bool CreateVulkanInstance(VulkanData Vulkan, Flag!"InstanceValidation" InstanceValidation)
{
  with(Vulkan)
  {
    //
    // Load DLL
    //
    {
      Log.BeginScope("Loading Vulkan DLL.");
      scope(exit) Log.EndScope("");

      auto FileName = "vulkan-1.dll";
      DLL = LoadLibraryA(FileName.ptr);
      if(DLL)
      {
        char[1.KiB] Buffer;
        auto CharCount = GetModuleFileNameA(DLL, Buffer.ptr, cast(DWORD)Buffer.length);
        DLLName = Buffer[0 .. CharCount];
        Log.Info("Loaded Vulkan DLL: %s", DLLName.Data);
      }
      else
      {
        Log.Failure("Failed to load DLL: %s", FileName);
        return false;
      }
    }

    //
    // Load Crucial Functions Pointers
    //
    {
      // These have to be loaded with GetProcAddress because for everything else
      // we need a Vulkan instance, which is obtained later.
      Log.BeginScope("First Stage of loading Vulkan function pointers.");
      scope(exit) Log.EndScope("");

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
      Log.BeginScope("Creating Vulkan instance.");
      scope(exit) Log.EndScope("");

      //
      // Instance Layers
      //
      auto LayerNames = Array!(CString)(.Allocator);
      if(InstanceValidation)
      {
        // Required extensions:
        bool SurfaceLayerFound;
        bool PlatformSurfaceLayerFound;

        uint LayerCount;
        vkEnumerateInstanceLayerProperties(&LayerCount, null).Verify;

        auto LayerProperties = Array!VkLayerProperties(.Allocator);
        LayerProperties.Expand(LayerCount);
        vkEnumerateInstanceLayerProperties(&LayerCount, LayerProperties.Data.ptr).Verify;

        Log.BeginScope("Explicitly enabled instance layers:");
        scope(success) Log.EndScope("==========");
        foreach(ref Property; LayerProperties)
        {
          auto LayerName = Property.layerName.ptr.fromStringz;
          if(LayerName == VK_LAYER_LUNARG_STANDARD_VALIDATION_NAME)
          {
            LayerNames ~= VK_LAYER_LUNARG_STANDARD_VALIDATION_NAME.ptr;
          }
          else
          {
            Log.Info("[ ] %s", LayerName);
            continue;
          }

          Log.Info("[x] %s", LayerName);
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

        Log.BeginScope("Explicitly enabled instance extensions:");
        scope(success) Log.EndScope("==========");
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
            Log.Info("[ ] %s", ExtensionName);
            continue;
          }

          Log.Info("[x] %s", ExtensionName);
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

    //
    // Load Instance Functions
    //
    //PFN_vkGetDeviceProcAddr vkGetDeviceProcAddr;
    {
      Log.BeginScope("Loading all Vulkan instance functions.");
      scope(exit) Log.EndScope("Finished loading instance functions.");

      LoadAllInstanceFunctions(vkGetInstanceProcAddr, Instance);
      //vkGetDeviceProcAddr = LoadInstanceFunction(vkGetInstanceProcAddr, Instance, "vkGetDeviceProcAddr".ptr, .vkGetDeviceProcAddr);
    }

    //
    // Debugging setup
    //
    {
      Log.BeginScope("Setting up Vulkan debugging.");
      scope(exit) Log.EndScope("Finished debug setup.");

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

    //
    // Choose Physical Device
    //
    {
      Log.BeginScope("Choosing physical device.");
      scope(exit) Log.EndScope("Finished choosing physical device.");

      vkEnumeratePhysicalDevices(Instance, &GpuCount, null).Verify;
      assert(GpuCount > 0);

      Log.Info("Found %u physical device(s).", GpuCount);

      auto Gpus = Array!VkPhysicalDevice(.Allocator);
      Gpus.Expand(GpuCount);

      vkEnumeratePhysicalDevices(Instance, &GpuCount, Gpus.Data.ptr).Verify;

      // Use the first Physical Device for now.
      auto Index = 0;
      auto Handle = Gpus[Index];

      Gpu.Index = Index;
      Gpu.Handle = Handle;
    }

    //
    // Queue and Physical Device Properties.
    //
    {
      Log.BeginScope("Querying for physical device and queue properties.");
      scope(exit) Log.EndScope("Retrieved physical device and queue properties.");

      vkGetPhysicalDeviceProperties(Gpu.Handle, &Gpu.Properties);
      vkGetPhysicalDeviceMemoryProperties(Gpu.Handle, &Gpu.MemoryProperties);
      vkGetPhysicalDeviceFeatures(Gpu.Handle, &Gpu.Features);

      uint QueueCount;
      vkGetPhysicalDeviceQueueFamilyProperties(Gpu.Handle, &QueueCount, null);
      Gpu.QueueProperties.Clear();
      Gpu.QueueProperties.Expand(QueueCount);
      vkGetPhysicalDeviceQueueFamilyProperties(Gpu.Handle, &QueueCount, Gpu.QueueProperties.Data.ptr);
    }
  }

  return true;
}

bool Initialize(VulkanData Vulkan, HINSTANCE ProcessHandle, HWND WindowHandle, Flag!"DeviceValidation" DeviceValidation)
{
  with(Vulkan)
  {

    //
    // Create Win32 Surface
    //
    {
      Log.BeginScope("Creating Win32 Surface.");
      scope(exit) Log.EndScope("Created Win32 Surface.");

      VkWin32SurfaceCreateInfoKHR CreateInfo;
      with(CreateInfo)
      {
        hinstance = ProcessHandle;
        hwnd = WindowHandle;
      }

      vkCreateWin32SurfaceKHR(Instance, &CreateInfo, null, &Surface).Verify;
    }

    //
    // Find Queue for Graphics and Presenting
    //
    {
      Log.BeginScope("Finding queue indices for graphics and presenting.");
      scope(exit) Log.EndScope("Done finding queue indices.");

      uint GraphicsIndex = uint.max;
      uint PresentIndex = uint.max;
      foreach(uint Index, QueueProperties; Gpu.QueueProperties)
      {
        VkBool32 SupportsPresenting;
        vkGetPhysicalDeviceSurfaceSupportKHR(Gpu.Handle, Index, Surface, &SupportsPresenting);

        if(QueueProperties.queueFlags & VK_QUEUE_GRAPHICS_BIT)
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
        Log.Failure("Support for separate graphics and present queue not implemented.");
        return false;
      }

      QueueNodeIndex = GraphicsIndex;
    }

    //
    // Create Logical Device
    //
    {
      Log.BeginScope("Creating Device.");
      scope(exit) Log.EndScope("Device created.");

      //
      // Device Layers
      //
      auto LayerNames = Array!(CString)(.Allocator);
      if(DeviceValidation)
      {
        // Required extensions:
        bool SurfaceLayerFound;
        bool PlatformSurfaceLayerFound;

        uint LayerCount;
        vkEnumerateDeviceLayerProperties(Gpu.Handle, &LayerCount, null).Verify;

        auto LayerProperties = Array!VkLayerProperties(.Allocator);
        LayerProperties.Expand(LayerCount);
        vkEnumerateDeviceLayerProperties(Gpu.Handle, &LayerCount, LayerProperties.Data.ptr).Verify;

        Log.BeginScope("Explicitly enabled device layers:");
        scope(exit) Log.EndScope("==========");
        foreach(ref Property; LayerProperties)
        {
          auto LayerName = Property.layerName.ptr.fromStringz;
          if(LayerName == VK_LAYER_LUNARG_STANDARD_VALIDATION_NAME)
          {
            LayerNames ~= VK_LAYER_LUNARG_STANDARD_VALIDATION_NAME.ptr;
          }
          else
          {
            Log.Info("[ ] %s", LayerName);
            continue;
          }

          Log.Info("[x] %s", LayerName);
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
        vkEnumerateDeviceExtensionProperties(Gpu.Handle, null, &ExtensionCount, null).Verify;

        auto ExtensionProperties = Array!VkExtensionProperties(.Allocator);
        ExtensionProperties.Expand(ExtensionCount);
        vkEnumerateDeviceExtensionProperties(Gpu.Handle, null, &ExtensionCount, ExtensionProperties.Data.ptr).Verify;

        Log.BeginScope("Explicitly enabled device extensions:");
        scope(exit) Log.EndScope("==========");
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
            Log.Info("[ ] %s", ExtensionName);
            continue;
          }

          Log.Info("[x] %s", ExtensionName);
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

      // TODO(Manu): Verify the enabled features are actually supported.
      VkPhysicalDeviceFeatures EnabledFeatures;
      with(EnabledFeatures)
      {
        shaderClipDistance = VK_TRUE;
        shaderCullDistance = VK_TRUE;
        textureCompressionBC = VK_TRUE;
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

      vkCreateDevice(Gpu.Handle, &DeviceCreateInfo, null, &Device.Handle).Verify;
      assert(Device.Handle);
      Device.OwnerGpu = &Gpu;

      vkGetDeviceQueue(Device.Handle, QueueNodeIndex, 0, &Queue);
      assert(Queue);
    }

    //
    // Get Physical Device Format and Color Space.
    //
    {
      Log.BeginScope("Gathering physical device format and color space.");
      scope(exit) Log.EndScope("Got format and color space for the previously created Win32 surface.");

      uint FormatCount;
      vkGetPhysicalDeviceSurfaceFormatsKHR(Gpu.Handle, Surface, &FormatCount, null).Verify;
      assert(FormatCount > 0);

      auto SurfaceFormats = Array!VkSurfaceFormatKHR(.Allocator);
      SurfaceFormats.Expand(FormatCount);

      vkGetPhysicalDeviceSurfaceFormatsKHR(Gpu.Handle, Surface, &FormatCount, SurfaceFormats.Data.ptr).Verify;

      if(FormatCount == 1 && SurfaceFormats[0].format == VK_FORMAT_UNDEFINED)
      {
        Format = VK_FORMAT_B8G8R8A8_UNORM;
      }
      else
      {
        Format = SurfaceFormats[0].format;
      }
      Log.Info("Format: %s", Format);

      ColorSpace = SurfaceFormats[0].colorSpace;
      Log.Info("Color Space: %s", ColorSpace);
    }
  }

  // Done.
  return true;
}

bool PrepareSwapchain(VulkanData Vulkan, uint NewWidth, uint NewHeight)
{
  with(Vulkan)
  {
    //
    // Create Command Pool
    //
    {
      Log.BeginScope("Creating command pool.");
      scope(exit) Log.EndScope("Finished creating command pool.");

      VkCommandPoolCreateInfo CreateInfo;
      with(CreateInfo)
      {
        queueFamilyIndex = QueueNodeIndex;
        flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
      }

      vkCreateCommandPool(Device.Handle, &CreateInfo, null, &CommandPool).Verify;
      assert(CommandPool);
    }

    //
    // Create Command Buffer
    //
    {
      Log.BeginScope("Creating command buffers.");
      scope(exit) Log.EndScope("Finished creating command buffers.");

      VkCommandBufferAllocateInfo AllocateInfo;
      with(AllocateInfo)
      {
        commandPool = CommandPool;
        level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
        commandBufferCount = 1;
      }

      // Create the draw command buffer.
      vkAllocateCommandBuffers(Device.Handle, &AllocateInfo, &DrawCommand).Verify;

      // Create the setup command buffer.
      vkAllocateCommandBuffers(Device.Handle, &AllocateInfo, &SetupCommand).Verify;
    }

    //
    // Prepare Buffers
    //
    {
      Log.BeginScope("Creating swapchain buffers.");
      scope(exit) Log.EndScope("Finished creating swapchain buffers.");

      scope(success) CurrentBufferIndex = 0; // Reset.

      VkSwapchainKHR OldSwapchain = Swapchain;

      VkSurfaceCapabilitiesKHR SurfaceCapabilities;
      vkGetPhysicalDeviceSurfaceCapabilitiesKHR(Gpu.Handle, Surface, &SurfaceCapabilities).Verify;

      uint PresentModeCount;
      vkGetPhysicalDeviceSurfacePresentModesKHR(Gpu.Handle, Surface, &PresentModeCount, null).Verify;

      auto PresentModes = Array!VkPresentModeKHR(.Allocator);
      PresentModes.Expand(PresentModeCount);

      vkGetPhysicalDeviceSurfacePresentModesKHR(Gpu.Handle, Surface, &PresentModeCount, PresentModes.Data.ptr).Verify;

      VkExtent2D SwapchainExtent;

      if(SurfaceCapabilities.currentExtent.width == cast(uint)-1)
      {
        assert(SurfaceCapabilities.currentExtent.height == cast(uint)-1);

        SwapchainExtent.width = NewWidth;
        SwapchainExtent.height = NewHeight;
      }
      else
      {
        SwapchainExtent = SurfaceCapabilities.currentExtent;
      }
      Width = SwapchainExtent.width;
      Height = SwapchainExtent.height;
      Log.Info("Swapchain extents: ", SwapchainExtent);

      VkPresentModeKHR SwapchainPresentMode = VK_PRESENT_MODE_FIFO_KHR;

      // Determine the number of VkImage's to use in the swapchain (we desire to
      // own only 1 image at a time, besides the images being displayed and
      // queued for display):
      uint DesiredNumberOfSwapchainImages = SurfaceCapabilities.minImageCount + 1;

      if(SurfaceCapabilities.maxImageCount > 0 &&
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

      vkCreateSwapchainKHR(Device.Handle, &SwapchainCreateInfo, null, &Swapchain).Verify;
      assert(Swapchain);
      Log.Info("Created Swapchain.");

      if(OldSwapchain)
      {
        vkDestroySwapchainKHR(Device.Handle, OldSwapchain, null);
        Log.Info("Destroyed previous swapchain.");
      }

      vkGetSwapchainImagesKHR(Device.Handle, Swapchain, &SwapchainImageCount, null).Verify;

      auto SwapchainImages = Array!VkImage(.Allocator);
      SwapchainImages.Expand(SwapchainImageCount);
      vkGetSwapchainImagesKHR(Device.Handle, Swapchain, &SwapchainImageCount, SwapchainImages.Data.ptr).Verify;

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
        SetImageLayout(Vulkan.SetupCommand,
                       SwapchainBuffers[Index].Image,
                       cast(VkImageAspectFlags)VK_IMAGE_ASPECT_COLOR_BIT,
                       cast(VkImageLayout)VK_IMAGE_LAYOUT_UNDEFINED,
                       cast(VkImageLayout)VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
                       cast(VkAccessFlags)0);

        ColorAttachmentCreateInfo.image = SwapchainBuffers[Index].Image;

        vkCreateImageView(Device.Handle, &ColorAttachmentCreateInfo, null,
                          &SwapchainBuffers[Index].View).Verify;
      }
    }

    //
    // Prepare Depth
    //
    {
      Log.BeginScope("Preparing depth.");
      scope(exit) Log.EndScope("Finished preparing depth.");

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
      vkCreateImage(Device.Handle, &ImageCreateInfo, null, &Depth.Image).Verify;

      // Get memory requirements for this object.
      VkMemoryRequirements MemoryRequirements;
      vkGetImageMemoryRequirements(Device.Handle, Depth.Image, &MemoryRequirements);

      // Select memory size and type.
      VkMemoryAllocateInfo MemoryAllocateInfo;
      MemoryAllocateInfo.allocationSize = MemoryRequirements.size;
      auto Result = ExtractMemoryTypeFromProperties(Vulkan.Gpu.MemoryProperties,
                                                    MemoryRequirements.memoryTypeBits,
                                                    0, // No requirements.
                                                    &MemoryAllocateInfo.memoryTypeIndex);
      assert(Result);

      // Allocate memory.
      vkAllocateMemory(Device.Handle, &MemoryAllocateInfo, null, &Depth.Memory).Verify;

      // Bind memory.
      vkBindImageMemory(Device.Handle, Depth.Image, Depth.Memory, 0).Verify;

      // Begin recording in the setup command buffer.
      VkCommandBufferInheritanceInfo InheritanceInfo;
      VkCommandBufferBeginInfo BeginInfo;
      BeginInfo.pInheritanceInfo = &InheritanceInfo;
      vkBeginCommandBuffer(SetupCommand, &BeginInfo).Verify;

      SetImageLayout(SetupCommand, Depth.Image,
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
      vkCreateImageView(Device.Handle, &ImageViewCreateInfo, null, &Depth.View).Verify;
    }

    //
    // Prepare Textures
    //
    version(all)
    {
      {
        auto CreateLoader = cast(PFN_CreateLoader)GetProcAddress(null, "krCreateImageLoader_DDS");
        assert(CreateLoader !is null);

        auto DestroyLoader = cast(PFN_DestroyLoader)GetProcAddress(null, "krDestroyImageLoader_DDS");
        assert(DestroyLoader !is null);

        IImageLoader Loader = CreateLoader(.Allocator);
        scope(exit) DestroyLoader(.Allocator, Loader);

        auto File = OpenFile(.Allocator, "../data/ezLogo_DXT1_NoMips_D.dds");
        scope(exit) CloseFile(.Allocator, File);

        auto FileContent = .Allocator.NewArray!void(File.Size);
        scope(exit) .Allocator.Delete(FileContent);

        auto BytesRead = File.Read(FileContent);
        assert(BytesRead == FileContent.length);

        auto Image = .Allocator.New!ImageContainer(.Allocator);
        scope(exit) .Allocator.Delete(Image);

        if(Loader.LoadImageFromData(FileContent, Image))
        {
          Log.Info("Loaded image file.");
        }
        else
        {
          Log.Warning("Failed to load image file.");
        }

        assert(IsImageCompatibleWithGpu(Vulkan.Gpu, Image),
               "Physical device is not compatible with the image.");

        UploadedTextureData Texture;
        if(UploadTexture(Vulkan.Device, Vulkan.SetupCommand, Image, /* out */ Texture))
        {
          Log.Info("Texture uploaded successfully.");
        }
        else
        {
          Log.Failure("Failed to upload texture data.");
        }
      }
    }
    else
    {
      Log.BeginScope("Preparing textures.");
      scope(exit) Log.EndScope("Finished preparing textures.");

      const VkFormat TextureFormat = VK_FORMAT_B8G8R8A8_UNORM;
      VkFormatProperties FormatProperties;
      uint[2][TextureCount] TextureColors =
      [
        [ 0xffff0000, 0xff00ff00 ],
      ];

      vkGetPhysicalDeviceFormatProperties(Gpu, TextureFormat, &FormatProperties);

      Log.PrintSampledTextureProperties(Gpu, VK_FORMAT_R8G8B8A8_UNORM);
      Log.PrintSampledTextureProperties(Gpu, VK_FORMAT_B8G8R8A8_UNORM);
      Log.PrintSampledTextureProperties(Gpu, VK_FORMAT_BC1_RGBA_UNORM_BLOCK);
      Log.PrintSampledTextureProperties(Gpu, VK_FORMAT_BC2_UNORM_BLOCK);
      Log.PrintSampledTextureProperties(Gpu, VK_FORMAT_BC3_UNORM_BLOCK);
      Log.PrintSampledTextureProperties(Gpu, VK_FORMAT_BC4_UNORM_BLOCK);
      Log.PrintSampledTextureProperties(Gpu, VK_FORMAT_BC5_UNORM_BLOCK);
      Log.PrintSampledTextureProperties(Gpu, VK_FORMAT_BC7_UNORM_BLOCK);

      foreach(Index; 0 .. TextureCount)
      {
        Log.Info("Setting up texture %u", Index);

        if((FormatProperties.linearTilingFeatures & VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT) &&
            !UseStagingBuffer)
        {
          // Device can texture using linear textures.
          //PrepareTextureImage(Vulkan, TextureColors[Index], &Vulkan.Textures[Index],
          //                    VK_IMAGE_TILING_LINEAR,
          //                    VK_IMAGE_USAGE_SAMPLED_BIT,
          //                    VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT);

          auto CreateLoader = cast(PFN_CreateLoader)GetProcAddress(null, "krCreateImageLoader_DDS");
          assert(CreateLoader !is null);

          auto DestroyLoader = cast(PFN_DestroyLoader)GetProcAddress(null, "krDestroyImageLoader_DDS");
          assert(DestroyLoader !is null);

          IImageLoader Loader = CreateLoader(.Allocator);
          scope(exit) DestroyLoader(.Allocator, Loader);

          auto File = OpenFile(.Allocator, "../data/pups.dds");
          scope(exit) CloseFile(.Allocator, File);

          auto FileContent = .Allocator.NewArray!void(File.Size);
          scope(exit) .Allocator.Delete(FileContent);

          auto BytesRead = File.Read(FileContent);
          assert(BytesRead == FileContent.length);

          auto Image = .Allocator.New!ImageContainer(.Allocator);
          scope(exit) .Allocator.Delete(Image);

          if(Loader.LoadImageFromData(FileContent, Image))
          {
            Log.Info("Loaded image file.");
          }
          else
          {
            Log.Warning("Failed to load image file.");
          }

          auto Texture = &Textures[Index];

          // TODO(Manu): These should not be needed.
          Texture.TextureWidth = Image.Width;
          Texture.TextureHeight = Image.Height;

          VkImageCreateInfo ImageCreateInfo;
          with(ImageCreateInfo)
          {
            imageType = VK_IMAGE_TYPE_2D;
            format = VK_FORMAT_R8G8B8A8_UNORM;
            extent = VkExtent3D(Image.Width, Image.Height, 1);
            mipLevels = 1;
            arrayLayers = 1;
            samples = VK_SAMPLE_COUNT_1_BIT;
            tiling = VK_IMAGE_TILING_LINEAR;
            initialLayout = VK_IMAGE_LAYOUT_PREINITIALIZED;
            usage = VK_IMAGE_USAGE_SAMPLED_BIT;
            sharingMode = VK_SHARING_MODE_EXCLUSIVE;
          }
          Log.Info("Number of MIP levels: %d", ImageCreateInfo.mipLevels);

          vkCreateImage(Vulkan.Device.Handle, &ImageCreateInfo, null, &Texture.Image).Verify;

          VkMemoryRequirements MemoryRequirements;
          vkGetImageMemoryRequirements(Vulkan.Device.Handle, Texture.Image, &MemoryRequirements);

          VkMemoryAllocateInfo MemoryAllocateInfo;
          MemoryAllocateInfo.allocationSize = MemoryRequirements.size;
          auto Result = ExtractMemoryTypeFromProperties(Vulkan.Gpu.MemoryProperties,
                                                        MemoryRequirements.memoryTypeBits,
                                                        VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT,
                                                        &MemoryAllocateInfo.memoryTypeIndex);
          assert(Result);

          // Allocate memory
          vkAllocateMemory(Vulkan.Device.Handle, &MemoryAllocateInfo, null, &Texture.Memory).Verify;

          // Bind memory
          vkBindImageMemory(Vulkan.Device.Handle, Texture.Image, Texture.Memory, 0).Verify;

          // Uploading the data to the GPU.
          {
            VkImageSubresource Subresource;
            Subresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
            VkSubresourceLayout Layout;
            vkGetImageSubresourceLayout(Vulkan.Device.Handle, Texture.Image, &Subresource,
                                        &Layout);

            void* TargetData;
            vkMapMemory(Vulkan.Device.Handle, Texture.Memory, 0, MemoryAllocateInfo.allocationSize, 0, &TargetData).Verify;

            version(all)
            {
              auto SourceData = Image.ImageData!void();
            }
            else
            {
              auto UncompressedImage = .Allocator.New!ImageContainer(.Allocator);
              scope(exit) .Allocator.Delete(UncompressedImage);

              import krepel.image.converters.image_conversion_interface;

              auto CreateImageConverter = cast(PFN_CreateImageConverter)GetProcAddress(null, "krCreateImageConverter_BC1_BGRA");
              auto DestroyImageConverter = cast(PFN_DestroyImageConverter)GetProcAddress(null, "krDestroyImageConverter_BC1_BGRA");

              auto Converter = CreateImageConverter(.Allocator);
              scope(exit) DestroyImageConverter(.Allocator, Converter);

              Converter.ConvertImage(Image, UncompressedImage, ImageFormat.B8G8R8A8_UNorm);

              auto SourceData = UncompressedImage.ImageData!void;
            }

            // Blit the data over.
            TargetData[0 .. SourceData.length] = SourceData;

            vkUnmapMemory(Vulkan.Device.Handle, Texture.Memory);
          }

          Texture.ImageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
          SetImageLayout(Vulkan.SetupCommand, Texture.Image,
                         cast(VkImageAspectFlags)VK_IMAGE_ASPECT_COLOR_BIT,
                         cast(VkImageLayout)VK_IMAGE_LAYOUT_PREINITIALIZED,
                         Texture.ImageLayout,
                         cast(VkAccessFlags)VK_ACCESS_HOST_WRITE_BIT);
          // Setting the image layout does not reference the actual memory so no need to add a mem ref.
        }
        else if(FormatProperties.optimalTilingFeatures & VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT)
        {
          // Must use staging buffer to copy linear texture to optimized.
          TextureData StagingTexture;

          PrepareTextureImage(Vulkan.Device, Vulkan.SetupCommand,
                              TextureColors[Index], &StagingTexture,
                              VK_IMAGE_TILING_LINEAR,
                              VK_IMAGE_USAGE_TRANSFER_SRC_BIT,
                              VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT);

          PrepareTextureImage(Vulkan.Device, Vulkan.SetupCommand,
                              TextureColors[Index], &Vulkan.Textures[Index],
                              VK_IMAGE_TILING_OPTIMAL,
                              (VK_IMAGE_USAGE_TRANSFER_DST_BIT | VK_IMAGE_USAGE_SAMPLED_BIT),
                              VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);

          SetImageLayout(Vulkan.SetupCommand, StagingTexture.Image,
                         VK_IMAGE_ASPECT_COLOR_BIT,
                         StagingTexture.ImageLayout,
                         VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
                         0);

          SetImageLayout(Vulkan.SetupCommand, Vulkan.Textures[Index].Image,
                         VK_IMAGE_ASPECT_COLOR_BIT,
                         Vulkan.Textures[Index].ImageLayout,
                         VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                         0);

          VkImageCopy CopyRegion;
          with(CopyRegion)
          {
            srcSubresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
            srcSubresource.layerCount = 1;

            // Same subresource data.
            dstSubresource = srcSubresource;

            extent = VkExtent3D(StagingTexture.TextureWidth, StagingTexture.TextureHeight, 1);
          }
          vkCmdCopyImage(Vulkan.SetupCommand, StagingTexture.Image,
                         VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, Vulkan.Textures[Index].Image,
                         VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &CopyRegion);

          SetImageLayout(Vulkan.SetupCommand, Vulkan.Textures[Index].Image,
                         VK_IMAGE_ASPECT_COLOR_BIT,
                         VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                         Vulkan.Textures[Index].ImageLayout,
                         0);

          Vulkan.FlushSetupCommand();

          // Clean up staging resources.
          vkDestroyImage(Vulkan.Device.Handle, StagingTexture.Image, null);
          vkFreeMemory(Vulkan.Device.Handle, StagingTexture.Memory, null);
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
          vkCreateSampler(Vulkan.Device.Handle, &SamplerCreateInfo, null, &Vulkan.Textures[Index].Sampler).Verify;
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
          vkCreateImageView(Vulkan.Device.Handle, &ImageViewCreateInfo, null, &Vulkan.Textures[Index].View).Verify;
        }
      }
    }

    //
    // Prepare Vertices and Indices
    //
    {
      Log.BeginScope("Preparing vertices.");
      scope(exit) Log.EndScope("Finished preparing vertices.");

      static struct VertexData
      {
        Vector3 Position;
        Vector2 TexCoord;
      }

      auto TopLeft     = VertexData(Vector3(-1.0f, -1.0f,  0.25f), Vector2(0.0f, 0.0f));
      auto TopRight    = VertexData(Vector3( 1.0f, -1.0f,  0.25f), Vector2(1.0f, 0.0f));
      auto BottomLeft  = VertexData(Vector3(-1.0f,  1.0f,  1.00f), Vector2(0.0f, 1.0f));
      auto BottomRight = VertexData(Vector3( 1.0f,  1.0f,  1.00f), Vector2(1.0f, 1.0f));
      VertexData[4] Geometry =
      [
        /*0*/TopLeft,    /*1*/TopRight,
        /*2*/BottomLeft, /*3*/BottomRight,
      ];
      Vertices.NumVertices = Geometry.length;

      uint[6] IndexData =
      [
        0, 3, 1,
        0, 2, 3,
      ];
      Indices.NumIndices = IndexData.length;

      // Vertex Buffer Setup
      {
        VkBufferCreateInfo BufferCreateInfo;
        with(BufferCreateInfo)
        {
          size = Geometry.ByteCount;
          usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT;
        }
        vkCreateBuffer(Device.Handle, &BufferCreateInfo, null, &Vertices.Buffer).Verify;

        VkMemoryRequirements MemoryRequirements;
        vkGetBufferMemoryRequirements(Device.Handle, Vertices.Buffer, &MemoryRequirements);

        VkMemoryAllocateInfo MemoryAllocateInfo;
        with(MemoryAllocateInfo)
        {
          allocationSize = MemoryRequirements.size;
          auto Result = ExtractMemoryTypeFromProperties(Vulkan.Gpu.MemoryProperties,
                                                        MemoryRequirements.memoryTypeBits,
                                                        VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT,
                                                        &memoryTypeIndex);
          assert(Result);
        }

        vkAllocateMemory(Device.Handle, &MemoryAllocateInfo, null, &Vertices.Memory).Verify;

        // Copy data from host to the device.
        {
          void* RawData;
          vkMapMemory(Device.Handle, Vertices.Memory, 0, MemoryAllocateInfo.allocationSize, 0, &RawData).Verify;
          scope(success) vkUnmapMemory(Device.Handle, Vertices.Memory);

          auto Target = (cast(VertexData*)RawData)[0 .. Geometry.length];
          Target[] = Geometry[];
        }

        vkBindBufferMemory(Device.Handle, Vertices.Buffer, Vertices.Memory, 0).Verify;

        Vertices.BindID = 0;

        with(Vertices.VertexInputBindingDescs[0])
        {
          binding = Vertices.BindID;
          stride = VertexData.sizeof;
          inputRate = VK_VERTEX_INPUT_RATE_VERTEX;
        }

        with(Vertices.VertexInputAttributeDescs[0])
        {
          binding = Vertices.BindID;
          location = 0;
          format = VK_FORMAT_R32G32B32_SFLOAT;
          offset = 0;
        }

        with(Vertices.VertexInputAttributeDescs[1])
        {
          binding = Vertices.BindID;
          location = 1;
          format = VK_FORMAT_R32G32_SFLOAT;
          offset = typeof(VertexData.Position).sizeof;
        }
      }

      // Index Buffer Setup
      {
        VkBufferCreateInfo BufferCreateInfo;
        with(BufferCreateInfo)
        {
          size = IndexData.ByteCount;
          usage = VK_BUFFER_USAGE_INDEX_BUFFER_BIT;
        }
        vkCreateBuffer(Device.Handle, &BufferCreateInfo, null, &Indices.Buffer).Verify;

        VkMemoryRequirements MemoryRequirements;
        vkGetBufferMemoryRequirements(Device.Handle, Indices.Buffer, &MemoryRequirements);

        VkMemoryAllocateInfo MemoryAllocateInfo;
        with(MemoryAllocateInfo)
        {
          allocationSize = MemoryRequirements.size;
          auto Result = ExtractMemoryTypeFromProperties(Vulkan.Gpu.MemoryProperties,
                                                        MemoryRequirements.memoryTypeBits,
                                                        VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT,
                                                        &memoryTypeIndex);
          assert(Result);
        }

        vkAllocateMemory(Device.Handle, &MemoryAllocateInfo, null, &Indices.Memory).Verify;

        // Copy data from host to the device.
        {
          void* RawData;
          vkMapMemory(Device.Handle, Indices.Memory, 0, MemoryAllocateInfo.allocationSize, 0, &RawData).Verify;
          scope(success) vkUnmapMemory(Device.Handle, Indices.Memory);

          auto Target = (cast(uint*)RawData)[0 .. IndexData.length];
          Target[] = IndexData[];
        }

        vkBindBufferMemory(Device.Handle, Indices.Buffer, Indices.Memory, 0).Verify;
      }
    }

    //
    // Prepare Descriptor Layout
    //
    {
      Log.BeginScope("Preparing descriptor layout.");
      scope(exit) Log.EndScope("Finished preparing descriptor layout.");

      VkDescriptorSetLayoutBinding LayoutBinding;
      with(LayoutBinding)
      {
        binding = Vertices.BindID; // TODO: Should I do that?
        descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
        descriptorCount = TextureCount;
        stageFlags = VK_SHADER_STAGE_FRAGMENT_BIT;
      }

      VkDescriptorSetLayoutCreateInfo DescriptorLayoutCreateInfo;
      with(DescriptorLayoutCreateInfo)
      {
        bindingCount = 1;
        pBindings = &LayoutBinding;
      }

      vkCreateDescriptorSetLayout(Device.Handle, &DescriptorLayoutCreateInfo, null, &DescriptorSetLayout).Verify;

      VkPipelineLayoutCreateInfo PipelineLayoutCreateInfo;
      with(PipelineLayoutCreateInfo)
      {
        setLayoutCount = 1;
        pSetLayouts = &DescriptorSetLayout;
      }
      vkCreatePipelineLayout(Device.Handle, &PipelineLayoutCreateInfo, null, &PipelineLayout).Verify;
    }

    //
    // Prepare Render Pass
    //
    {
      Log.BeginScope("Preparing render pass.");
      scope(exit) Log.EndScope("Finished preparing render pass.");

      VkAttachmentDescription[2] Attachments;
      with(Attachments[0])
      {
        format = Format;
        samples = VK_SAMPLE_COUNT_1_BIT;
        loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR;
        storeOp = VK_ATTACHMENT_STORE_OP_STORE;
        stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
        stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
        initialLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
        finalLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
      }

      with(Attachments[1])
      {
        format = Depth.Format;
        samples = VK_SAMPLE_COUNT_1_BIT;
        loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR;
        storeOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
        stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
        stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
        initialLayout = VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;
        finalLayout = VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;
      }

      VkAttachmentReference ColorReference;
      with(ColorReference)
      {
        attachment = 0;
        layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
      }

      VkAttachmentReference DepthReference;
      with(DepthReference)
      {
        attachment = 1;
        layout = VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;
      }

      VkSubpassDescription SubpassDesc;
      with(SubpassDesc)
      {
        pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
        colorAttachmentCount = 1;
        pColorAttachments = &ColorReference;
        pDepthStencilAttachment = &DepthReference;
      }

      VkRenderPassCreateInfo RenderPassCreateInfo;
      with(RenderPassCreateInfo)
      {
        attachmentCount = Attachments.length;
        pAttachments = Attachments.ptr;
        subpassCount = 1;
        pSubpasses = &SubpassDesc;
      }

      vkCreateRenderPass(Device.Handle, &RenderPassCreateInfo, null, &RenderPass).Verify;
    }

    //
    // Prepare Pipeline
    //
    {
      Log.BeginScope("Preparing pipeline.");
      scope(exit) Log.EndScope("Finished preparing pipeline.");

      // Two shader stages: vs and fs
      VkPipelineShaderStageCreateInfo[2] Stages;

      //
      // Vertex Shader
      //
      auto VertexShaderStage = &Stages[0];
      {
        VertexShaderStage.stage = VK_SHADER_STAGE_VERTEX_BIT;
        VertexShaderStage.pName = "main".ptr;

        auto Filename = "../data/shader/tri/vert.spv"w;
        Log.BeginScope("Loading vertex shader from file: %s", Filename);
        scope(exit) Log.EndScope("");

        auto File = OpenFile(.Allocator, Filename);
        scope(exit) CloseFile(.Allocator, File);

        auto ShaderCode = .Allocator.NewArray!void(File.Size);
        scope(exit) .Allocator.Delete(ShaderCode);

        auto BytesRead = File.Read(ShaderCode);
        assert(BytesRead == ShaderCode.length);

        VkShaderModuleCreateInfo ShaderModuleCreateInfo;
        with(ShaderModuleCreateInfo)
        {
          codeSize = ShaderCode.length; // In bytes, regardless of the fact that typeof(*pCode) == uint.
          pCode = cast(const(uint)*)ShaderCode.ptr; // As a const(uint)*, for some reason...
        }
        vkCreateShaderModule(Device.Handle, &ShaderModuleCreateInfo, null, &VertexShaderStage._module).Verify;
      }
      scope(exit) vkDestroyShaderModule(Device.Handle, VertexShaderStage._module, null);

      //
      // Fragment Shader
      //
      auto FragmentShaderStage = &Stages[1];
      {
        FragmentShaderStage.stage = VK_SHADER_STAGE_FRAGMENT_BIT;
        FragmentShaderStage.pName = "main";

        auto Filename = "../data/shader/tri/frag.spv"w;
        Log.BeginScope("Loading vertex shader from file: %s", Filename);
        scope(exit) Log.EndScope("");

        auto File = OpenFile(.Allocator, Filename);
        scope(exit) CloseFile(.Allocator, File);

        auto ShaderCode = .Allocator.NewArray!void(File.Size);
        scope(exit) .Allocator.Delete(ShaderCode);

        auto BytesRead = File.Read(ShaderCode);
        assert(BytesRead == ShaderCode.length);

        VkShaderModuleCreateInfo ShaderModuleCreateInfo;
        with(ShaderModuleCreateInfo)
        {
          codeSize = ShaderCode.length; // In bytes, regardless of the fact that typeof(*pCode) == uint.
          pCode = cast(const(uint)*)ShaderCode.ptr; // As a const(uint)*, for some reason...
        }
        vkCreateShaderModule(Device.Handle, &ShaderModuleCreateInfo, null, &FragmentShaderStage._module).Verify;
      }
      scope(exit) vkDestroyShaderModule(Device.Handle, FragmentShaderStage._module, null);

      VkPipelineVertexInputStateCreateInfo VertexInputState;
      with(VertexInputState)
      {
        vertexBindingDescriptionCount = Vertices.VertexInputBindingDescs.length;
        pVertexBindingDescriptions    = Vertices.VertexInputBindingDescs.ptr;
        vertexAttributeDescriptionCount = Vertices.VertexInputAttributeDescs.length;
        pVertexAttributeDescriptions    = Vertices.VertexInputAttributeDescs.ptr;
      }

      VkPipelineInputAssemblyStateCreateInfo InputAssemblyState;
      with(InputAssemblyState)
      {
        topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
      }

      VkPipelineViewportStateCreateInfo ViewportState;
      with(ViewportState)
      {
        viewportCount = 1;
        scissorCount = 1;
      }

      VkPipelineRasterizationStateCreateInfo RasterizationState;
      with(RasterizationState)
      {
        polygonMode = VK_POLYGON_MODE_FILL;
        cullMode = VK_CULL_MODE_BACK_BIT;
        frontFace = VK_FRONT_FACE_COUNTER_CLOCKWISE;
        depthClampEnable = VK_FALSE;
        rasterizerDiscardEnable = VK_FALSE;
        depthBiasEnable = VK_FALSE;
      }

      VkPipelineMultisampleStateCreateInfo MultisampleState;
      with(MultisampleState)
      {
        rasterizationSamples = VK_SAMPLE_COUNT_1_BIT;
      }

      VkPipelineDepthStencilStateCreateInfo DepthStencilState;
      with(DepthStencilState)
      {
        depthTestEnable = VK_TRUE;
        depthWriteEnable = VK_TRUE;
        depthCompareOp = VK_COMPARE_OP_LESS_OR_EQUAL;
        depthBoundsTestEnable = VK_FALSE;
        back.failOp = VK_STENCIL_OP_KEEP;
        back.passOp = VK_STENCIL_OP_KEEP;
        back.compareOp = VK_COMPARE_OP_ALWAYS;
        stencilTestEnable = VK_FALSE;
        front = back;
      }

      VkPipelineColorBlendAttachmentState[1] ColorBlendStateAttachments;
      with(ColorBlendStateAttachments[0])
      {
        colorWriteMask = 0xf;
        blendEnable = VK_FALSE;
      }

      VkPipelineColorBlendStateCreateInfo ColorBlendState;
      with(ColorBlendState)
      {
        attachmentCount = ColorBlendStateAttachments.length;
        pAttachments = ColorBlendStateAttachments.ptr;
      }

      VkDynamicState[VK_DYNAMIC_STATE_RANGE_SIZE] DynamicStates;
      VkPipelineDynamicStateCreateInfo DynamicState;
      with(DynamicState)
      {
        DynamicStates[dynamicStateCount++] = VK_DYNAMIC_STATE_VIEWPORT;
        DynamicStates[dynamicStateCount++] = VK_DYNAMIC_STATE_SCISSOR;
        pDynamicStates = DynamicStates.ptr;
      }

      VkGraphicsPipelineCreateInfo GraphicsPipelineCreateInfo;
      with(GraphicsPipelineCreateInfo)
      {
        stageCount = Stages.length;
        pStages = Stages.ptr;
        pVertexInputState = &VertexInputState;
        pInputAssemblyState = &InputAssemblyState;
        pViewportState = &ViewportState;
        pRasterizationState = &RasterizationState;
        pMultisampleState = &MultisampleState;
        pDepthStencilState = &DepthStencilState;
        pColorBlendState = &ColorBlendState;
        pDynamicState = &DynamicState;
        layout = PipelineLayout;
        renderPass = RenderPass;
      }

      VkPipelineCacheCreateInfo PipelineCacheCreateInfo;
      VkPipelineCache PipelineCache;
      vkCreatePipelineCache(Device.Handle, &PipelineCacheCreateInfo, null, &PipelineCache).Verify;
      scope(exit) vkDestroyPipelineCache(Device.Handle, PipelineCache, null);

      vkCreateGraphicsPipelines(Device.Handle, PipelineCache,
                                1, &GraphicsPipelineCreateInfo,
                                null,
                                &Pipeline).Verify;
    }

    //
    // Prepare Descriptor Pool
    //
    {
      Log.BeginScope("Preparing descriptor pool.");
      scope(exit) Log.EndScope("Finished preparing descriptor pool.");

      VkDescriptorPoolSize TypeCount;
      with(TypeCount)
      {
        type = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
        descriptorCount = TextureCount;
      }
      VkDescriptorPoolCreateInfo DescriptorPoolCreateInfo;
      with(DescriptorPoolCreateInfo)
      {
        maxSets = 1;
        poolSizeCount = 1;
        pPoolSizes = &TypeCount;
      }

      vkCreateDescriptorPool(Device.Handle, &DescriptorPoolCreateInfo, null, &DescriptorPool).Verify;
    }

    //
    // Prepare Descriptor Set
    //
    {
      Log.BeginScope("Preparing descriptor set.");
      scope(exit) Log.EndScope("Finished preparing descriptor set.");

      VkDescriptorSetAllocateInfo DescriptorSetAllocateInfo;
      with(DescriptorSetAllocateInfo)
      {
        descriptorPool = DescriptorPool;
        descriptorSetCount = 1;
        pSetLayouts = &DescriptorSetLayout;
      }
      vkAllocateDescriptorSets(Device.Handle, &DescriptorSetAllocateInfo, &DescriptorSet).Verify;

      VkDescriptorImageInfo[TextureCount] TextureDescriptors;
      foreach(Index; 0 .. TextureCount)
      {
        TextureDescriptors[Index].sampler = Textures[Index].Sampler;
        TextureDescriptors[Index].imageView = Textures[Index].View;
        TextureDescriptors[Index].imageLayout = VK_IMAGE_LAYOUT_GENERAL;
      }

      VkWriteDescriptorSet WriteDescriptorSet;
      with(WriteDescriptorSet)
      {
        dstSet = DescriptorSet;
        descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
        descriptorCount = TextureDescriptors.length;
        pImageInfo = TextureDescriptors.ptr;
      }
      vkUpdateDescriptorSets(Device.Handle,
                             1, &WriteDescriptorSet,
                             0, null);
    }

    //
    // Prepare Framebuffers
    //
    {
      Log.BeginScope("Preparing framebuffers.");
      scope(exit) Log.EndScope("Finished preparing framebuffers.");

      VkImageView[2] Attachments;
      Attachments[1] = Depth.View;

      VkFramebufferCreateInfo FramebufferCreateInfo;
      with(FramebufferCreateInfo)
      {
        renderPass = RenderPass;
        attachmentCount = Attachments.length;
        pAttachments = Attachments.ptr;
        width = Width;
        height = Height;
        layers = 1;
      }

      Framebuffers.Clear();
      Framebuffers.Expand(SwapchainImageCount);

      foreach(Index; 0 .. SwapchainImageCount)
      {
        Attachments[0] = SwapchainBuffers[Index].View;
        vkCreateFramebuffer(Device.Handle, &FramebufferCreateInfo, null, &Framebuffers[Index]).Verify;
      }
    }
  }

  // Done.
  return true;
}

void SetImageLayout(VkCommandBuffer CommandBuffer,
                    VkImage Image,
                    VkImageAspectFlags AspectMask,
                    VkImageLayout OldImageLayout,
                    VkImageLayout NewImageLayout,
                    VkAccessFlags SourceAccessMask)
{
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

  vkCmdPipelineBarrier(CommandBuffer,                   // commandBuffer
                       SourceStages, DestinationStages, // dstStageMask, srcStageMask
                       0,                               // dependencyFlags
                       0, null,                         // memoryBarrierCount, pMemoryBarriers
                       0, null,                         // bufferMemoryBarrierCount, pBufferMemoryBarriers
                       1, &ImageMemoryBarrier);         // imageMemoryBarrierCount, pImageMemoryBarriers
}

Flag!"PerfectMatch" ExtractMemoryTypeFromProperties(VkPhysicalDeviceMemoryProperties GpuMemoryProperties,
                                                  uint TypeBits,
                                                  VkFlags RequirementsMask,
                                                  uint* TypeIndex)
{
  // Search memtypes to find first index with those properties
  foreach(Index; 0 .. 32)
  {
    if(TypeBits.HasBit(Index))
    {
      // Type is available, does it match user properties?
      const PropertyFlags = GpuMemoryProperties.memoryTypes[Index].propertyFlags;
      const FilteredFlags = PropertyFlags * RequirementsMask;
      if(FilteredFlags == RequirementsMask)
      {
        *TypeIndex = Index;
        return Yes.PerfectMatch;
      }
    }
  }

  return No.PerfectMatch;
}

void PrepareTextureImage(VulkanDeviceData Device, VkCommandBuffer CommandBuffer,
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

  vkCreateImage(Device.Handle, &ImageCreateInfo, null, &Texture.Image).Verify;

  VkMemoryRequirements MemoryRequirements;
  vkGetImageMemoryRequirements(Device.Handle, Texture.Image, &MemoryRequirements);

  VkMemoryAllocateInfo MemoryAllocateInfo;
  with(MemoryAllocateInfo)
  {
    allocationSize = MemoryRequirements.size;
    auto HasMatch = ExtractMemoryTypeFromProperties(Device.OwnerGpu.MemoryProperties,
                                                    MemoryRequirements.memoryTypeBits,
                                                    RequiredProperties,
                                                    &memoryTypeIndex);

    assert(HasMatch);
  }

  // Allocate memory
  vkAllocateMemory(Device.Handle, &MemoryAllocateInfo, null, &Texture.Memory).Verify;

  // Bind memory
  vkBindImageMemory(Device.Handle, Texture.Image, Texture.Memory, 0).Verify;

  if(RequiredProperties & VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT)
  {
    VkImageSubresource Subresource;
    Subresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
    VkSubresourceLayout Layout;
    void* Data;

    vkGetImageSubresourceLayout(Device.Handle, Texture.Image, &Subresource,
                                &Layout);

    vkMapMemory(Device.Handle, Texture.Memory, 0, MemoryAllocateInfo.allocationSize, 0, &Data).Verify;

    for(int Y = 0; Y < TextureHeight; Y++)
    {
      auto Row = cast(uint*)(Data + Layout.rowPitch * Y);
      for(int X = 0; X < TextureWidth; X++)
      {
        const ColorIndex = (X & 1) ^ (Y & 1);
        Row[X] = TextureColors[ColorIndex];
      }
    }

    vkUnmapMemory(Device.Handle, Texture.Memory);
  }

  Texture.ImageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
  SetImageLayout(CommandBuffer, Texture.Image,
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

    vkFreeCommandBuffers(Device.Handle, CommandPool, 1, &SetupCommand);
    SetupCommand = VK_NULL_HANDLE;
  }
}

__gshared bool IsDrawing;

void Draw(VulkanData Vulkan)
{
  .IsDrawing = true;
  scope(exit) .IsDrawing = false;

  with(Vulkan)
  {
    VkFence NullFence;
    VkResult Error;

    VkSemaphore PresentCompleteSemaphore;
    {
      VkSemaphoreCreateInfo PresentCompleteSemaphoreCreateInfo;
      vkCreateSemaphore(Device.Handle, &PresentCompleteSemaphoreCreateInfo, null, &PresentCompleteSemaphore).Verify;
    }
    scope(exit) vkDestroySemaphore(Device.Handle, PresentCompleteSemaphore, null);

    // Get the index of the next available swapchain image:
    auto Timeout = ulong.max;
    Error = vkAcquireNextImageKHR(Device.Handle, Swapchain, Timeout,
                                  PresentCompleteSemaphore, NullFence,
                                  &CurrentBufferIndex);

    switch(Error)
    {
      case VK_ERROR_OUT_OF_DATE_KHR:
      {
        // Swapchain is out of date (e.g. the window was resized) and must be
        // recreated:
        Vulkan.Resize(Vulkan.Width, Vulkan.Height);
        Vulkan.Draw();
      } break;
      case VK_SUBOPTIMAL_KHR:
      {
        // Swapchain is not as optimal as it could be, but the platform's
        // presentation engine will still present the image correctly.
      } break;
      default: Verify(Error);
    }

    // Assume the command buffer has been run on current_buffer before so
    // we need to set the image layout back to COLOR_ATTACHMENT_OPTIMAL
    SetImageLayout(Vulkan.SetupCommand,
                   SwapchainBuffers[CurrentBufferIndex].Image,
                   VK_IMAGE_ASPECT_COLOR_BIT,
                   VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
                   VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                   0);
    Vulkan.FlushSetupCommand();

    // Wait for the present complete semaphore to be signaled to ensure
    // that the image won't be rendered to until the presentation
    // engine has fully released ownership to the application, and it is
    // okay to render to the image.

    // FIXME/TODO: DEAL WITH VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
    Vulkan.CreateDrawCommand();

    // Submit the draw command to the queue.
    {
      VkPipelineStageFlags PipelineStageFlags = VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT;
      VkSubmitInfo SubmitInfo;
      with(SubmitInfo)
      {
        waitSemaphoreCount = 1;
        pWaitSemaphores = &PresentCompleteSemaphore;
        pWaitDstStageMask = &PipelineStageFlags;
        commandBufferCount = 1;
        pCommandBuffers = &DrawCommand;
        signalSemaphoreCount = 0;
        pSignalSemaphores = null;
      }

      vkQueueSubmit(Queue,
                    1, &SubmitInfo,
                    NullFence).Verify;
    }

    // Present the results.
    {
      VkPresentInfoKHR Present;
      with(Present)
      {
        swapchainCount = 1;
        pSwapchains = &Swapchain;
        pImageIndices = &CurrentBufferIndex;
      }

      Error = vkQueuePresentKHR(Queue, &Present);
      switch(Error)
      {
        case VK_ERROR_OUT_OF_DATE_KHR:
        {
          // Swapchain is out of date (e.g. the window was resized) and must be
          // recreated:
          Vulkan.Resize(Vulkan.Width, Vulkan.Height);
        } break;
        case VK_SUBOPTIMAL_KHR:
        {
          // Swapchain is not as optimal as it could be, but the platform's
          // presentation engine will still present the image correctly.
        } break;
        default: Verify(Error);
      }
    }

    // Wait for the queue to complete.
    vkQueueWaitIdle(Queue).Verify;
  }
}

void CreateDrawCommand(VulkanData Vulkan)
{
  with(Vulkan)
  {
    {
      VkCommandBufferInheritanceInfo CommandBufferInheritanceInfo;
      assert(CommandBufferInheritanceInfo.sType == VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_INFO);
      VkCommandBufferBeginInfo CommandBufferBeginInfo;
      assert(CommandBufferBeginInfo.sType == VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO);
      CommandBufferBeginInfo.pInheritanceInfo = &CommandBufferInheritanceInfo;
      vkBeginCommandBuffer(DrawCommand, &CommandBufferBeginInfo).Verify;
    }
    scope(exit) vkEndCommandBuffer(DrawCommand).Verify;

    //
    // Render Pass
    //
    {
      // Begin render pass.
      {
        VkClearValue[2] ClearValues;
        with(ClearValues[0])
        {
          const CornflowerBlue = Vector4(100 / 255.0f, 149 / 255.0f, 237 / 255.0f, 1.0f);
          color.float32[] = CornflowerBlue.Data[];
        }
        with(ClearValues[1])
        {
          depthStencil.depth = Vulkan.DepthStencilValue;
          depthStencil.stencil = 0;
        }

        VkRenderPassBeginInfo RenderPassBeginInfo;
        with(RenderPassBeginInfo)
        {
          renderPass = RenderPass;
          framebuffer = Framebuffers[CurrentBufferIndex];
          renderArea.extent.width = Width;
          renderArea.extent.height = Height;
          clearValueCount = ClearValues.length;
          pClearValues = ClearValues.ptr;
        }
        vkCmdBeginRenderPass(DrawCommand, &RenderPassBeginInfo, VK_SUBPASS_CONTENTS_INLINE);
      }
      scope(exit) vkCmdEndRenderPass(DrawCommand);

      vkCmdBindPipeline(DrawCommand, VK_PIPELINE_BIND_POINT_GRAPHICS, Pipeline);
      vkCmdBindDescriptorSets(DrawCommand, VK_PIPELINE_BIND_POINT_GRAPHICS,
                              PipelineLayout, 0,
                              1, &DescriptorSet,
                              0, null);

      // Set Viewport
      {
        VkViewport Viewport = void;
        with(Viewport)
        {
          x = 0.0f;
          y = 0.0f;
          height = cast(float)Height;
          width = cast(float)Width;
          minDepth = 0.0f;
          maxDepth = 1.0f;
        }
        vkCmdSetViewport(DrawCommand, 0, 1, &Viewport);
      }

      // Set Scissor
      {
        VkRect2D Scissor;
        with(Scissor)
        {
          extent.width = Width;
          extent.height = Height;
        }
        vkCmdSetScissor(DrawCommand, 0, 1, &Scissor);
      }

      {
        VkDeviceSize VertexBufferOffset;
        vkCmdBindVertexBuffers(DrawCommand, Vertices.BindID,
                               1, &Vertices.Buffer,
                               &VertexBufferOffset);
      }

      {
        VkDeviceSize IndexBufferOffset;
        vkCmdBindIndexBuffer(DrawCommand,
                             Indices.Buffer,
                             IndexBufferOffset,
                             VK_INDEX_TYPE_UINT32);

      }

      vkCmdDrawIndexed(DrawCommand,
                       Indices.NumIndices, // indexCount
                       1,                  // instanceCount
                       0,                  // firstIndex
                       0,                  // vertexOffset
                       0);                 // firstInstance
    }

    VkImageMemoryBarrier PrePresentBarrier;
    with(PrePresentBarrier)
    {
      srcAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
      dstAccessMask = VK_ACCESS_MEMORY_READ_BIT;
      oldLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
      newLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
      srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
      dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
      with(subresourceRange)
      {
        aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
        baseMipLevel = 0;
        levelCount = 1;
        baseArrayLayer = 0;
        layerCount = 1;
      }
      image = SwapchainBuffers[CurrentBufferIndex].Image;
    }

    vkCmdPipelineBarrier(DrawCommand,                          // commandBuffer
                         VK_PIPELINE_STAGE_ALL_COMMANDS_BIT,   // srcStageMask
                         VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, // dstStageMask
                         0,                                    // dependencyFlags
                         0, null,                              // memoryBarrierCount, pMemoryBarriers
                         0, null,                              // bufferMemoryBarrierCount, pBufferMemoryBarriers
                         1, &PrePresentBarrier);               // imageMemoryBarrierCount, pImageMemoryBarriers
  }
}

void Resize(VulkanData Vulkan, uint NewWidth, uint NewHeight)
{
  // Don't react to resize until after first initialization.
  if(!Vulkan.IsPrepared) return;

  Log.Info("Resizing to %ux%u.", NewWidth, NewHeight);

  // In order to properly resize the window, we must re-create the swapchain
  // AND redo the command buffers, etc.

  // First, perform part of the Cleanup() function:
  Vulkan.DestroySwapchainData();

  // Second, re-perform the Prepare() function, which will re-create the
  // swapchain:
  Vulkan.IsPrepared = Vulkan.PrepareSwapchain(NewWidth, NewHeight);
}

void DestroySwapchainData(VulkanData Vulkan)
{
  assert(Vulkan.IsPrepared);

  Vulkan.IsPrepared = false;

  foreach(Framebuffer; Vulkan.Framebuffers)
  {
    vkDestroyFramebuffer(Vulkan.Device.Handle, Framebuffer, null);
  }
  Vulkan.Framebuffers.Clear();

  vkDestroyDescriptorPool(Vulkan.Device.Handle, Vulkan.DescriptorPool, null);

  if(Vulkan.SetupCommand)
  {
    vkFreeCommandBuffers(Vulkan.Device.Handle, Vulkan.CommandPool, 1, &Vulkan.SetupCommand);
  }
  vkFreeCommandBuffers(Vulkan.Device.Handle, Vulkan.CommandPool, 1, &Vulkan.DrawCommand);
  vkDestroyCommandPool(Vulkan.Device.Handle, Vulkan.CommandPool, null);

  vkDestroyPipeline(Vulkan.Device.Handle, Vulkan.Pipeline, null);
  vkDestroyRenderPass(Vulkan.Device.Handle, Vulkan.RenderPass, null);
  vkDestroyPipelineLayout(Vulkan.Device.Handle, Vulkan.PipelineLayout, null);
  vkDestroyDescriptorSetLayout(Vulkan.Device.Handle, Vulkan.DescriptorSetLayout, null);

  vkDestroyBuffer(Vulkan.Device.Handle, Vulkan.Indices.Buffer, null);
  vkFreeMemory(Vulkan.Device.Handle, Vulkan.Indices.Memory, null);

  vkDestroyBuffer(Vulkan.Device.Handle, Vulkan.Vertices.Buffer, null);
  vkFreeMemory(Vulkan.Device.Handle, Vulkan.Vertices.Memory, null);

  foreach(ref Texture; Vulkan.Textures)
  {
    vkDestroyImageView(Vulkan.Device.Handle, Texture.View, null);
    vkDestroyImage(Vulkan.Device.Handle,     Texture.Image, null);
    vkFreeMemory(Vulkan.Device.Handle,       Texture.Memory, null);
    vkDestroySampler(Vulkan.Device.Handle,   Texture.Sampler, null);
  }

  foreach(ref Buffer; Vulkan.SwapchainBuffers)
  {
    vkDestroyImageView(Vulkan.Device.Handle, Buffer.View, null);
  }
  Vulkan.SwapchainBuffers.Clear();

  vkDestroyImageView(Vulkan.Device.Handle, Vulkan.Depth.View, null);
  vkDestroyImage(Vulkan.Device.Handle,     Vulkan.Depth.Image, null);
  vkFreeMemory(Vulkan.Device.Handle,       Vulkan.Depth.Memory, null);
}

void Cleanup(VulkanData Vulkan)
{
  Log.BeginScope("Vulkan cleanup.");
  scope(exit) Log.EndScope("Finished Vulkan cleanup.");

  if(Vulkan.IsPrepared)
  {
    Vulkan.DestroySwapchainData();
  }

  vkDestroySwapchainKHR(Vulkan.Device.Handle, Vulkan.Swapchain, null);
  vkDestroyDevice(Vulkan.Device.Handle, null);
  vkDestroyDebugReportCallbackEXT(Vulkan.Instance, Vulkan.DebugReportCallback, null);

  vkDestroySurfaceKHR(Vulkan.Instance, Vulkan.Surface, null);
  vkDestroyInstance(Vulkan.Instance, null);
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

Flag!"IsCompatible" IsImageCompatibleWithGpu(VulkanPhysicalDeviceData Gpu, ImageContainer Image)
{
  VkFormat VulkanTextureFormat = ImageFormatToVulkan(Image.Format);
  if(VulkanTextureFormat == VK_FORMAT_UNDEFINED)
  {
    Log.Failure("Unable to find corresponding Vulkan format for %s.", Image.Format);
    return No.IsCompatible;
  }

  VkFormatProperties FormatProperties;
  vkGetPhysicalDeviceFormatProperties(Gpu.Handle, VulkanTextureFormat, &FormatProperties);

  bool SupportsImageSampling = FormatProperties.optimalTilingFeatures & VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT;
  if(!SupportsImageSampling)
  {
    Log.Failure("%s: Cannot sample this format with optimal tiling.", VulkanTextureFormat);
    return No.IsCompatible;
  }

  VkImageFormatProperties ImageProperties;
  vkGetPhysicalDeviceImageFormatProperties(Gpu.Handle,
                                           VulkanTextureFormat,
                                           VK_IMAGE_TYPE_2D,
                                           VK_IMAGE_TILING_OPTIMAL,
                                           VK_IMAGE_USAGE_SAMPLED_BIT,
                                           0,
                                           &ImageProperties);

  auto ImageExtent = VkExtent3D(Image.Width, Image.Height, 1);
  if(ImageProperties.maxExtent.width  < ImageExtent.width ||
     ImageProperties.maxExtent.height < ImageExtent.height ||
     ImageProperties.maxExtent.depth  < ImageExtent.depth)
  {
    Log.Failure("Given image extent (%s) does not fit the devices' maximum extent (%s).",
                ImageExtent,
                ImageProperties.maxExtent);
    return No.IsCompatible;
  }

  if(Image.NumMipLevels > ImageProperties.maxMipLevels)
  {
    Log.Failure("Physical device accepts a maximum of %d Mip levels, the given image has %d",
                ImageProperties.maxMipLevels, Image.NumMipLevels);
    return No.IsCompatible;
  }

  if(Image.NumArrayIndices > ImageProperties.maxArrayLayers)
  {
    Log.Failure("Physical device accepts a maximum of %d array layers, the given image has %d",
                ImageProperties.maxArrayLayers, Image.NumArrayIndices);
    return No.IsCompatible;
  }

  // TODO(Manu): sampleCounts, maxResourceSize?

  return Yes.IsCompatible;
}

struct UploadedTextureData
{
  @disable this(this);

  VkImage ImageHandle;
  VkImageLayout ImageLayoutHandle;
  VkDeviceMemory MemoryHandle;
  VkImageView ImageViewHandle;
}

/// Note: You should verify that it's possible to uploading the given Image to
/// the device using IsImageCompatibleWithGpu.
Flag!"Success" UploadTexture(VulkanDeviceData Device, VkCommandBuffer CommandBuffer, ImageContainer Image,
                             out UploadedTextureData Result)
{
  //
  // 1. Allocate a temporary buffer.
  // 2. Blit the image data into that.
  // 3. Allocate an image with optimal tiling
  // 4. Blit the buffer data into the image.
  // 5. Deallocate the temporary buffer.
  //

  //
  // Create the temporary buffer and upload the data to it.
  //
    auto ImageData = Image.ImageData!void;

    VkBufferCreateInfo Temp_BufferCreateInfo;
    with(Temp_BufferCreateInfo)
    {
      usage = VK_BUFFER_USAGE_TRANSFER_SRC_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;
      size = ImageData.length;
    }

    VkBuffer Temp_Buffer;
    vkCreateBuffer(Device.Handle, &Temp_BufferCreateInfo, null, &Temp_Buffer).Verify;
    scope(exit) vkDestroyBuffer(Device.Handle, Temp_Buffer, null);

    VkMemoryRequirements Temp_MemoryRequirements;
    vkGetBufferMemoryRequirements(Device.Handle, Temp_Buffer, &Temp_MemoryRequirements);

    VkMemoryAllocateInfo Temp_MemoryAllocationInfo;
    with(Temp_MemoryAllocationInfo)
    {
      allocationSize = Temp_MemoryRequirements.size;
      bool Succeeded = ExtractMemoryTypeFromProperties(Device.OwnerGpu.MemoryProperties,
                                                       Temp_MemoryRequirements.memoryTypeBits,
                                                       VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT,
                                                       &memoryTypeIndex);
      assert(Succeeded);
    }

    VkDeviceMemory Temp_Memory;
    vkAllocateMemory(Device.Handle, &Temp_MemoryAllocationInfo, null, &Temp_Memory).Verify;
    scope(exit) vkFreeMemory(Device.Handle, Temp_Memory, null);

    // Copy over the image data to the temporary buffer.
    {
      void* RawData;
      vkMapMemory(Device.Handle,
                  Temp_Memory,
                  0, // offset
                  VK_WHOLE_SIZE,
                  0, // flags
                  &RawData).Verify;
      scope(exit) vkUnmapMemory(Device.Handle, Temp_Memory);

      RawData[0 .. ImageData.length] = ImageData;
    }

    vkBindBufferMemory(Device.Handle, Temp_Buffer, Temp_Memory, 0).Verify;

  //
  // Create the actual texture image.
  //
    // Now that we have the buffer in place, holding the texture data, we copy
    // it over to an image.
    VkFormat VulkanTextureFormat = ImageFormatToVulkan(Image.Format);
    assert(VulkanTextureFormat != VK_FORMAT_UNDEFINED);

    VkImageCreateInfo Image_CreateInfo;
    with(Image_CreateInfo)
    {
      imageType = VK_IMAGE_TYPE_2D;
      format = VulkanTextureFormat;
      extent = VkExtent3D(Image.Width, Image.Height, 1);
      // TODO(Manu): Support all mip levels!
      //mipLevels = Image.NumMipLevels;
      //arrayLayers = Image.NumArrayIndices;
      mipLevels = 1;
      arrayLayers = 1;
      samples = VK_SAMPLE_COUNT_1_BIT; // TODO(Manu): Should probably be passed in, because it must be consistent with the renderpass, etc.
      tiling = VK_IMAGE_TILING_OPTIMAL;
      initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
      usage = VK_IMAGE_USAGE_SAMPLED_BIT | VK_IMAGE_USAGE_TRANSFER_DST_BIT;
      sharingMode = VK_SHARING_MODE_EXCLUSIVE;
    }
    vkCreateImage(Device.Handle, &Image_CreateInfo, null, &Result.ImageHandle).Verify;

    VkMemoryRequirements Image_MemoryRequirements;
    vkGetImageMemoryRequirements(Device.Handle, Result.ImageHandle, &Image_MemoryRequirements);

    VkMemoryAllocateInfo Image_MemoryAllocateInfo;
    with(Image_MemoryAllocateInfo)
    {
      allocationSize = Image_MemoryRequirements.size;
      auto HasMatch = ExtractMemoryTypeFromProperties(Device.OwnerGpu.MemoryProperties,
                                                      Image_MemoryRequirements.memoryTypeBits,
                                                      VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT,
                                                      &memoryTypeIndex);
      assert(HasMatch);
      if(!HasMatch) return No.Success;
    }

    // Allocate image memory
    vkAllocateMemory(Device.Handle, &Image_MemoryAllocateInfo, null, &Result.MemoryHandle).Verify;

    // Bind image and image memory
    vkBindImageMemory(Device.Handle, Result.ImageHandle, Result.MemoryHandle, 0).Verify;

    // Since the initial layout is VK_IMAGE_LAYOUT_UNDEFINED, and this image
    // is a blit-target, we set its current layout to
    // VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL.
    SetImageLayout(CommandBuffer,
                   Result.ImageHandle,
                   VK_IMAGE_ASPECT_COLOR_BIT,
                   VK_IMAGE_LAYOUT_UNDEFINED,
                   VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                   0);

  //
  // Copy the buffered data over to the image memory.
  //
    VkBufferImageCopy Copy;
    with(Copy)
    {
      imageExtent = Image_CreateInfo.extent;
      with(imageSubresource)
      {
        aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
        mipLevel = 0; // TODO(Manu): Support all mip levels.
        baseArrayLayer = 0;
        layerCount = 1; // TODO(Manu): Should be more than 1.
      }
    }
    vkCmdCopyBufferToImage(CommandBuffer,
                           Temp_Buffer,
                           Result.ImageHandle,
                           VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                           1,
                           &Copy);

  return Yes.Success;
}
