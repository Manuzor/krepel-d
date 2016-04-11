module krepel.win32_main;
version(Windows):

import krepel;
import krepel.win32;
import krepel.win32.directx.xinput;
import krepel.memory;
import krepel.container;


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
      auto State = G.Allocator.NewARC!VulkanState();
      State.ProcessHandle = Instance;
      State.WindowHandle = Window;

      State.LoadDLL();
      if(State.DLL)
      {
        Log.Info("Using Vulkan DLL %s", State.DLLName);

        State.Initialize();
        State.Prepare();
        assert(State.Instance);
        scope(exit) State.Destroy();
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

class VulkanState
{
  string DLLName;
  HANDLE DLL;

  HINSTANCE ProcessHandle;
  HWND WindowHandle;

  VkInstance Instance;

  VkPhysicalDevice PhysicalDevice;
  VkPhysicalDeviceProperties PhysicalDeviceProperties;
  VkPhysicalDeviceMemoryProperties PhysicalDeviceMemoryProperties;

  VkDevice Device;

  VkQueue Queue;

  VkFormat DepthFormat;

  static struct SemaphoresData
  {
    VkSemaphore PresentComplete;
    VkSemaphore RenderComplete;
  }

  SemaphoresData Semaphores;
  VkSubmitInfo SubmitInfo;
  VkPipelineStageFlags SubmitPipelineStages = VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT;

  SwapChainData SwapChain;

  VkCommandPool CommandPool;

  VkCommandBuffer SetupCommandBuffer;

  // Command buffer for submitting a post present image barrier
  VkCommandBuffer PostPresentCommandBuffer;

  // Command buffer for submitting a pre present image barrier
  VkCommandBuffer PrePresentCommandBuffer;

  VkCommandBuffer[] DrawCommandBuffers;

  static struct DepthStencilData
  {
    VkImage Image;
    VkDeviceMemory Memory;
    VkImageView View;
  }

  DepthStencilData DepthStencil;

  VkRenderPass RenderPass;
  VkPipelineCache PipelineCache;

  VkFramebuffer[] FrameBuffers;

  uint Width = 1200;
  uint Height = 720;
}

struct SwapChainData
{
  VkInstance Instance;
  VkPhysicalDevice PhysicalDevice;
  VkDevice Device;
  VkSurfaceKHR Surface;

  VkFormat ColorFormat;
  VkColorSpaceKHR ColorSpace;

  VkSwapchainKHR SwapChainHandle;

  static struct Buffer
  {
    VkImage Image;
    VkImageView View;
  }

  uint ImageCount;
  VkImage[] Images;
  Buffer[] Buffers;

  uint QueueNodeIndex = uint.max;
}

void LoadDLL(VulkanState State)
{
  string[1] Candidates =
  [
    "vulkan-1.dll",
  ];

  foreach(DLLName; Candidates)
  {
    auto DLL = LoadLibrary("vulkan-1.dll");
    if(DLL)
    {
      auto Func = GetProcAddress(DLL, "vkGetInstanceProcAddr");
      if(Func is null)
      {
        Log.Warning("Failed to load Vulkan instance functions.");
        return;
      }

      .vkGetInstanceProcAddr = cast(typeof(vkGetInstanceProcAddr))Func;

      DVulkanLoader.loadInstanceFunctions(.vkGetInstanceProcAddr);
      State.DLLName = DLLName;
      State.DLL = DLL;
      return;
    }
    else
    {
      Log.Failure("Failed to load DLL: %s", DLLName);
    }
  }

  Log.Failure("Failed to load Vulkan.");
}

void Initialize(VulkanState State)
{
  VkApplicationInfo ApplicationInfo;
  with(ApplicationInfo)
  {
    pApplicationName = "Vulkan Experiments".ptr;
    applicationVersion = VK_MAKE_VERSION(0, 0, 1);

    pEngineName = "Krepel".ptr,
    engineVersion = VK_MAKE_VERSION(0, 0, 1);

    //apiVersion = VK_MAKE_VERSION(1, 0, 5);
  }

  enum VK_KHR_WIN32_SURFACE_EXTENSION_NAME = "VK_KHR_win32_surface";

  const(char)*[3] Extensions =
  [
    VK_KHR_SURFACE_EXTENSION_NAME.ptr,
    VK_KHR_WIN32_SURFACE_EXTENSION_NAME.ptr,
    VK_EXT_DEBUG_REPORT_EXTENSION_NAME.ptr,
  ];

  const(char)*[9] Layers =
  [
    //"VK_LAYER_LUNARG_standard_validation".ptr,

    "VK_LAYER_GOOGLE_threading".ptr,
    "VK_LAYER_LUNARG_mem_tracker".ptr,
    "VK_LAYER_LUNARG_object_tracker".ptr,
    "VK_LAYER_LUNARG_draw_state".ptr,
    "VK_LAYER_LUNARG_param_checker".ptr,
    "VK_LAYER_LUNARG_swapchain".ptr,
    "VK_LAYER_LUNARG_device_limits".ptr,
    "VK_LAYER_LUNARG_image".ptr,
    "VK_LAYER_GOOGLE_unique_objects".ptr,
  ];

  VkInstanceCreateInfo CreateInfo;
  with(CreateInfo)
  {
    pApplicationInfo = &ApplicationInfo;

    enabledExtensionCount = Extensions.length;
    ppEnabledExtensionNames = Extensions.ptr;

    enabledLayerCount = Layers.length;
    ppEnabledLayerNames = Layers.ptr;
  }

  vkCreateInstance(&CreateInfo, null, &State.Instance).Verify;
  assert(State.Instance);

  LoadAllInstanceFunctions(.vkGetInstanceProcAddr, State.Instance);
  //DVulkanLoader.loadAllFunctions(Instance);

  // Try loading vkGetDeviceProcAddr
  .vkGetDeviceProcAddr = LoadInstanceFunction(.vkGetInstanceProcAddr,
                                              State.Instance,
                                              "vkGetDeviceProcAddr".ptr,
                                              .vkGetDeviceProcAddr);
  assert(.vkGetDeviceProcAddr);

  //
  // Device setup
  //
  uint DeviceCount;
  vkEnumeratePhysicalDevices(State.Instance, &DeviceCount, null).Verify;
  if(DeviceCount)
  {
    auto PhysicalDevices = G.Allocator.NewArray!VkPhysicalDevice(DeviceCount);
    scope(success) G.Allocator.Delete(PhysicalDevices);

    vkEnumeratePhysicalDevices(State.Instance, &DeviceCount, PhysicalDevices.ptr).Verify;

    Log.Info("All physical Vulkan devices:");
    foreach(Index, Device; PhysicalDevices)
    {
      VkPhysicalDeviceProperties DeviceProperties;
      vkGetPhysicalDeviceProperties(Device, &DeviceProperties);
      Log.Info("  Device %d: %s", Index, DeviceProperties.deviceName.ptr.fromStringz);
      Log.Info("  API Version: %s.%s.%s",
               VK_VERSION_MAJOR(DeviceProperties.apiVersion),
               VK_VERSION_MINOR(DeviceProperties.apiVersion),
               VK_VERSION_PATCH(DeviceProperties.apiVersion));
    }

    // TODO(Manu): Choose vulkan device somehow?

    const DeviceIndex = 0;
    State.PhysicalDevice = PhysicalDevices[DeviceIndex];
    vkGetPhysicalDeviceProperties(State.PhysicalDevice, &State.PhysicalDeviceProperties);
    vkGetPhysicalDeviceMemoryProperties(State.PhysicalDevice, &State.PhysicalDeviceMemoryProperties);
    Log.Info("Using physical device %d: %s", DeviceIndex, fromStringz(State.PhysicalDeviceProperties.deviceName.ptr));
  }
  else
  {
    Log.Failure("Failed to enumerate devices.");
    return;
  }

  uint GraphicsQueueIndex;
  uint QueueCount;
  vkGetPhysicalDeviceQueueFamilyProperties(State.PhysicalDevice, &QueueCount, null);

  auto QueueProperties = G.Allocator.NewArray!VkQueueFamilyProperties(QueueCount);
  scope(success) G.Allocator.Delete(QueueProperties);

  vkGetPhysicalDeviceQueueFamilyProperties(State.PhysicalDevice, &QueueCount, QueueProperties.ptr);

  foreach(ref Queue; QueueProperties)
  {
    if(Queue.queueFlags & VK_QUEUE_GRAPHICS_BIT) break;
    GraphicsQueueIndex++;
  }
  assert(GraphicsQueueIndex < QueueCount);

  float[1] QueuePriorities = [ 0.0f ];
  VkDeviceQueueCreateInfo QueueDesc;
  with(QueueDesc)
  {
    queueFamilyIndex = GraphicsQueueIndex;
    queueCount = cast(uint)QueuePriorities.length;
    pQueuePriorities = QueuePriorities.ptr;
  }

  State.CreateDevice(QueueDesc);

  LoadAllDeviceFunctions(.vkGetDeviceProcAddr, State.Device);

  vkGetDeviceQueue(State.Device, GraphicsQueueIndex, 0, &State.Queue);

  //vkGetPhysicalDeviceMemoryProperties(State.PhysicalDevice, &State.PhysicalDeviceMemoryProperties);

  State.DepthFormat = ChooseDepthFormat(State.PhysicalDevice);

  with(State)
  {
    SwapChain.Instance = State.Instance;
    SwapChain.Device = State.Device;
  }

  // Is default initialized for now.
  VkSemaphoreCreateInfo SemaphoreDesc;
  vkCreateSemaphore(State.Device, &SemaphoreDesc, null, &State.Semaphores.PresentComplete).Verify;
  vkCreateSemaphore(State.Device, &SemaphoreDesc, null, &State.Semaphores.RenderComplete).Verify;

  with(State.SubmitInfo)
  {
    pWaitDstStageMask = &State.SubmitPipelineStages;
    waitSemaphoreCount = 1;
    pWaitSemaphores = &State.Semaphores.PresentComplete;
    signalSemaphoreCount = 1;
    pSignalSemaphores = &State.Semaphores.RenderComplete;
  }
}

void Prepare(VulkanState State)
{
  //
  // Setup Debugging
  //
  if(false && vkCreateDebugReportCallbackEXT)
  {
    VkDebugReportCallbackCreateInfoEXT DebugDesc;
    with(DebugDesc)
    {
      pfnCallback = &DebugMessageCallback;
      flags = VK_DEBUG_REPORT_ERROR_BIT_EXT | VK_DEBUG_REPORT_WARNING_BIT_EXT;
    }
    VkDebugReportCallbackEXT DebugReportCallback;
    vkCreateDebugReportCallbackEXT(
      State.Instance,
      &DebugDesc,
      null,
      &DebugReportCallback).Verify;
  }
  else
  {
    Log.Warning("Unable to set up debugging: vkCreateDebugReportCallbackEXT is null");
  }

  //
  // Create Command Pool
  //
  {
    VkCommandPoolCreateInfo CommandPoolDesc;
    with(CommandPoolDesc)
    {
      queueFamilyIndex = State.SwapChain.QueueNodeIndex;
      flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
    }
    vkCreateCommandPool(State.Device, &CommandPoolDesc, null, &State.CommandPool).Verify;
  }

  //
  // Create Setup Command Buffer
  //
  {
    if (State.SetupCommandBuffer != VK_NULL_HANDLE)
    {
      vkFreeCommandBuffers(State.Device, State.CommandPool, 1, &State.SetupCommandBuffer);
      State.SetupCommandBuffer = VK_NULL_HANDLE;
    }

    VkCommandBufferAllocateInfo CommandBufferAllocateInfo;
    with(CommandBufferAllocateInfo)
    {
      commandPool = State.CommandPool;
      level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
      commandBufferCount = 1;
    }

    vkAllocateCommandBuffers(State.Device,
                             &CommandBufferAllocateInfo,
                             &State.SetupCommandBuffer).Verify;

    VkCommandBufferBeginInfo CommandBufferBeginInfo = {};
    vkBeginCommandBuffer(State.SetupCommandBuffer, &CommandBufferBeginInfo).Verify;

  }

  //
  // Setup Swap Chain
  //
  CreateSwapChain(State.SwapChain,
                  State.SetupCommandBuffer,
                  State.Width,
                  State.Height);

  //
  // Create Command Buffers
  //

  // Create one command buffer per frame buffer
  // in the swap chain
  // Command buffers store a reference to the
  // frame buffer inside their render pass info
  // so for static usage withouth having to rebuild
  // them each frame, we use one per frame buffer
  {
    State.DrawCommandBuffers = G.Allocator.NewArray!VkCommandBuffer(State.SwapChain.ImageCount);

    VkCommandBufferAllocateInfo CommandBufferAllocateInfo = {};
    with(CommandBufferAllocateInfo)
    {
      commandPool = State.CommandPool;
      level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
      commandBufferCount = cast(uint)State.DrawCommandBuffers.length;
    }

    vkAllocateCommandBuffers(State.Device, &CommandBufferAllocateInfo, State.DrawCommandBuffers.ptr).Verify;

    // Command buffers for submitting present barriers
    CommandBufferAllocateInfo.commandBufferCount = 1;
    // Pre present
    vkAllocateCommandBuffers(State.Device, &CommandBufferAllocateInfo, &State.PrePresentCommandBuffer).Verify;
    // Post present
    vkAllocateCommandBuffers(State.Device, &CommandBufferAllocateInfo, &State.PostPresentCommandBuffer).Verify;
  }

  //
  // Setup Depth Stencil
  //

  {
    VkImageCreateInfo Image;
    with(Image)
    {
      imageType = VK_IMAGE_TYPE_2D;
      format = State.DepthFormat;
      extent = VkExtent3D(State.Width, State.Height, 1);
      mipLevels = 1;
      arrayLayers = 1;
      samples = VK_SAMPLE_COUNT_1_BIT;
      tiling = VK_IMAGE_TILING_OPTIMAL;
      usage = VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT | VK_IMAGE_USAGE_TRANSFER_SRC_BIT;
      flags = 0;
    }

    VkMemoryAllocateInfo MemoryAllocationInfo;

    VkImageViewCreateInfo DepthStencilView;
    with(DepthStencilView)
    {
      viewType = VK_IMAGE_VIEW_TYPE_2D;
      format = State.DepthFormat;
      flags = 0;
      subresourceRange.aspectMask = VK_IMAGE_ASPECT_DEPTH_BIT | VK_IMAGE_ASPECT_STENCIL_BIT;
      subresourceRange.baseMipLevel = 0;
      subresourceRange.levelCount = 1;
      subresourceRange.baseArrayLayer = 0;
      subresourceRange.layerCount = 1;
    }

    VkMemoryRequirements MemoryRequirements;

    vkCreateImage(State.Device, &Image, null, &State.DepthStencil.Image).Verify;
    vkGetImageMemoryRequirements(State.Device, State.DepthStencil.Image, &MemoryRequirements);
    MemoryAllocationInfo.allocationSize = MemoryRequirements.size;
    GetMemoryType(State.PhysicalDeviceMemoryProperties,
                  MemoryRequirements.memoryTypeBits,
                  VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
                  &MemoryAllocationInfo.memoryTypeIndex);
    vkAllocateMemory(State.Device, &MemoryAllocationInfo, null, &State.DepthStencil.Memory).Verify;

    vkBindImageMemory(State.Device, State.DepthStencil.Image, State.DepthStencil.Memory, 0).Verify;


    VkImageSubresourceRange SubresourceRange;
    with(SubresourceRange)
    {
      aspectMask = VK_IMAGE_ASPECT_DEPTH_BIT | VK_IMAGE_ASPECT_STENCIL_BIT;
      baseMipLevel = 0;
      levelCount = 1;
      layerCount = 1;
    }
    SetImageLayout(State.SetupCommandBuffer,
                   State.DepthStencil.Image,
                   VK_IMAGE_ASPECT_DEPTH_BIT | VK_IMAGE_ASPECT_STENCIL_BIT,
                   VK_IMAGE_LAYOUT_UNDEFINED,
                   VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
                   SubresourceRange);

    DepthStencilView.image = State.DepthStencil.Image;
    vkCreateImageView(State.Device, &DepthStencilView, null, &State.DepthStencil.View).Verify;
  }

  //
  // Setup Render Pass
  //
  {
    VkAttachmentDescription[2] Attachments;
    with(Attachments[0])
    {
      format         = State.SwapChain.ColorFormat;
      samples        = VK_SAMPLE_COUNT_1_BIT;
      loadOp         = VK_ATTACHMENT_LOAD_OP_CLEAR;
      storeOp        = VK_ATTACHMENT_STORE_OP_STORE;
      stencilLoadOp  = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
      stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
      initialLayout  = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
      finalLayout    = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
    }

    with(Attachments[1])
    {
      format = State.DepthFormat;
      samples = VK_SAMPLE_COUNT_1_BIT;
      loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR;
      storeOp = VK_ATTACHMENT_STORE_OP_STORE;
      stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
      stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
      initialLayout = VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;
      finalLayout = VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;
    }

    VkAttachmentReference ColorReference = {};
    ColorReference.attachment = 0;
    ColorReference.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

    VkAttachmentReference DepthReference = {};
    DepthReference.attachment = 1;
    DepthReference.layout = VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;

    VkSubpassDescription SubPass = {};
    with(SubPass)
    {
      pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
      flags = 0;
      inputAttachmentCount = 0;
      pInputAttachments = null;
      colorAttachmentCount = 1;
      pColorAttachments = &ColorReference;
      pResolveAttachments = null;
      pDepthStencilAttachment = &DepthReference;
      preserveAttachmentCount = 0;
      pPreserveAttachments = null;
    }

    VkRenderPassCreateInfo RenderPassInfo;
    with(RenderPassInfo)
    {
      attachmentCount = 2;
      pAttachments = Attachments.ptr;
      subpassCount = 1;
      pSubpasses = &SubPass;
      dependencyCount = 0;
      pDependencies = null;
    }

    vkCreateRenderPass(State.Device, &RenderPassInfo, null, &State.RenderPass).Verify;
  }

  //
  // Create Pipeline Cache
  //
  {
    VkPipelineCacheCreateInfo PipelineCacheCreateInfo;
    vkCreatePipelineCache(State.Device,
                          &PipelineCacheCreateInfo,
                          null,
                          &State.PipelineCache).Verify;
  }

  //
  // Setup Frame Buffer
  //
  {
    VkImageView[2] Attachments;

    // Depth/Stencil attachment is the same for all frame buffers
    Attachments[1] = State.DepthStencil.View;

    VkFramebufferCreateInfo FrameBufferCreateInfo = {};
    with(FrameBufferCreateInfo)
    {
      renderPass = State.RenderPass;
      attachmentCount = cast(uint)Attachments.length;
      pAttachments = Attachments.ptr;
      width = State.Width;
      height = State.Height;
      layers = 1;
    }

    // Create frame buffers for every swap chain image
    State.FrameBuffers = G.Allocator.NewArray!VkFramebuffer(State.SwapChain.ImageCount);
    foreach(Index; 0 .. State.FrameBuffers.length)
    {
      Attachments[0] = State.SwapChain.Buffers[Index].View;
      vkCreateFramebuffer(State.Device,
                          &FrameBufferCreateInfo,
                          null,
                          &State.FrameBuffers[Index]);
    }
  }

  //
  // Flush Setup Command Buffer
  //
  if(State.SetupCommandBuffer)
  {
    vkEndCommandBuffer(State.SetupCommandBuffer).Verify;

    VkSubmitInfo SubmitInfo;
    with(SubmitInfo)
    {
      commandBufferCount = 1;
      pCommandBuffers = &State.SetupCommandBuffer;
    }

    vkQueueSubmit(State.Queue, 1, &SubmitInfo, VK_NULL_HANDLE).Verify;

    vkQueueWaitIdle(State.Queue).Verify;

    vkFreeCommandBuffers(State.Device, State.CommandPool, 1, &State.SetupCommandBuffer);
    State.SetupCommandBuffer = VK_NULL_HANDLE;
  }
}

void Destroy(VulkanState State)
{
  if(State.Instance)
  {
    vkDestroyInstance(State.Instance, null);
  }
}

VkResult CreateDevice(VulkanState State, VkDeviceQueueCreateInfo RequestedQueues)
{
  const(char)*[1] EnabledExtensions =
  [
    VK_KHR_SWAPCHAIN_EXTENSION_NAME.ptr
  ];

  VkDeviceCreateInfo DeviceDesc;
  with(DeviceDesc)
  {
    queueCreateInfoCount = 1;
    pQueueCreateInfos = &RequestedQueues;

    enabledExtensionCount = cast(uint)EnabledExtensions.length;
    ppEnabledExtensionNames = EnabledExtensions.ptr;
  }

  return vkCreateDevice(State.PhysicalDevice, &DeviceDesc, null, &State.Device);
}

VkFormat ChooseDepthFormat(VkPhysicalDevice PhysicalDevice)
{
  VkFormat[5] Formats =
  [
    VK_FORMAT_D32_SFLOAT_S8_UINT,
    VK_FORMAT_D32_SFLOAT,
    VK_FORMAT_D24_UNORM_S8_UINT,
    VK_FORMAT_D16_UNORM_S8_UINT,
    VK_FORMAT_D16_UNORM
  ];

  foreach(ref Format; Formats[])
  {
    VkFormatProperties FormatProperties;
    vkGetPhysicalDeviceFormatProperties(PhysicalDevice, Format, &FormatProperties);
    if(FormatProperties.optimalTilingFeatures & VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT)
    {
      return Format;
    }
  }

  return VK_FORMAT_UNDEFINED;
}

void InitializeSurface(ref SwapChainData SwapChain, HINSTANCE ProcessHandle, HWND WindowHandle)
{
  VkWin32SurfaceCreateInfoKHR SufraceDesc;
  with(SufraceDesc)
  {
    hinstance = ProcessHandle;
    hwnd = WindowHandle;
  }
  vkCreateWin32SurfaceKHR(SwapChain.Instance, &SufraceDesc, null, &SwapChain.Surface).Verify;

  uint QueueCount;
  vkGetPhysicalDeviceQueueFamilyProperties(SwapChain.PhysicalDevice, &QueueCount, null);

  auto QueueProperties = G.Allocator.NewArray!VkQueueFamilyProperties(QueueCount);
  scope(success) G.Allocator.Delete(QueueProperties);

  vkGetPhysicalDeviceQueueFamilyProperties(SwapChain.PhysicalDevice, &QueueCount, QueueProperties.ptr);

  auto SupportsPresenting = G.Allocator.NewArray!VkBool32(QueueCount);
  scope(success) G.Allocator.Delete(SupportsPresenting);

  // Find presenter queues.
  foreach(uint Index, Element; SupportsPresenting)
  {
    vkGetPhysicalDeviceSurfaceSupportKHR(SwapChain.PhysicalDevice, Index, SwapChain.Surface, &Element);
  }

  uint GraphicsQueueNodeIndex = uint.max;
  uint PresentQueueNodeIndex = uint.max;

  foreach(uint Index; 0 .. QueueCount)
  {
    if(QueueProperties[Index].queueFlags & VK_QUEUE_GRAPHICS_BIT)
    {
      if(GraphicsQueueNodeIndex == uint.max)
      {
        GraphicsQueueNodeIndex = Index;
      }

      if(SupportsPresenting[Index])
      {
        GraphicsQueueNodeIndex = Index;
        PresentQueueNodeIndex = Index;
        break;
      }
    }
  }

  if(PresentQueueNodeIndex == uint.max)
  {
    // If there's no queue that supports present AND graphics, find a seperate
    // present queue.
    foreach(uint Index, Element; SupportsPresenting)
    {
      if(Element)
      {
        PresentQueueNodeIndex = Index;
        break;
      }
    }
  }

  if(GraphicsQueueNodeIndex == uint.max || PresentQueueNodeIndex == uint.max)
  {
    Log.Failure("Unable to find grapchis and/or present queue.");
    return;
  }

  // TODO Add support for separate graphics and present queue.
  if(GraphicsQueueNodeIndex != PresentQueueNodeIndex)
  {
    Log.Failure("Separate graphics and presenting queues are not supported yet.");
    return;
  }

  SwapChain.QueueNodeIndex = GraphicsQueueNodeIndex;

  uint FormatCount;
  vkGetPhysicalDeviceSurfaceFormatsKHR(SwapChain.PhysicalDevice, SwapChain.Surface, &FormatCount, null).Verify;
  assert(FormatCount > 0);

  auto SurfaceFormats = G.Allocator.NewArray!VkSurfaceFormatKHR(FormatCount);
  scope(success) G.Allocator.Delete(SurfaceFormats);


  uint ChosenFormat;
  if(FormatCount == 1 && SurfaceFormats[0].format == VK_FORMAT_UNDEFINED)
  {
    // If there's only 1 format, which is VK_FORMAT_UNDEFINED, it means
    // there's no preferred format.
    SwapChain.ColorFormat = VK_FORMAT_B8G8R8A8_UNORM;
  }
  else
  {
    // Always use the first format for now. If something like an SRGB format
    // is desired, SurfaceFormats must be searched for the best match.
    ChosenFormat = 0;

    SwapChain.ColorFormat = SurfaceFormats[ChosenFormat].format;
  }

  SwapChain.ColorSpace = SurfaceFormats[ChosenFormat].colorSpace;
}

void CreateSwapChain(ref SwapChainData SwapChain,
                     VkCommandBuffer CommandBuffer,
                     ref uint Width,
                     ref uint Height)
{
  auto OldSwapChainHandle = SwapChain.SwapChainHandle;

  if(!vkGetPhysicalDeviceSurfaceCapabilitiesKHR)
  {
    Log.Warning("Missing vkGetPhysicalDeviceSurfaceCapabilitiesKHR");
  }

  auto GetPhysicalDeviceSurfaceCapabilitiesKHR = cast(typeof(vkGetPhysicalDeviceSurfaceCapabilitiesKHR))vkGetDeviceProcAddr(SwapChain.Device, "vkGetPhysicalDeviceSurfaceCapabilitiesKHR");

  VkSurfaceCapabilitiesKHR SurfaceCapabilities;
  vkGetPhysicalDeviceSurfaceCapabilitiesKHR(SwapChain.PhysicalDevice, SwapChain.Surface, &SurfaceCapabilities).Verify;

  uint PresentModeCount;
  vkGetPhysicalDeviceSurfacePresentModesKHR(SwapChain.PhysicalDevice, SwapChain.Surface, &PresentModeCount, null);
  assert(PresentModeCount > 0);

  auto PresentModes = G.Allocator.NewArray!VkPresentModeKHR(PresentModeCount);
  scope(success) G.Allocator.Delete(PresentModes);

  vkGetPhysicalDeviceSurfacePresentModesKHR(SwapChain.PhysicalDevice, SwapChain.Surface, &PresentModeCount, PresentModes.ptr).Verify;

  VkExtent2D SwapChainExtent;
  if(SurfaceCapabilities.currentExtent.width)
  {
    assert(SurfaceCapabilities.currentExtent.width == SurfaceCapabilities.currentExtent.height);
    SwapChainExtent.width = Width;
    SwapChainExtent.height = Height;
  }
  else
  {
    SwapChainExtent = SurfaceCapabilities.currentExtent;
    Width = SwapChainExtent.width;
    Height = SwapChainExtent.height;
  }

  // Prefer mailbox mode if present, it's the lowest latency non-tearing present  mode
  VkPresentModeKHR SwapChainPresentMode = VK_PRESENT_MODE_FIFO_KHR;
  foreach(ref Mode; PresentModes)
  {
    if(Mode == VK_PRESENT_MODE_MAILBOX_KHR)
    {
      SwapChainPresentMode = VK_PRESENT_MODE_MAILBOX_KHR;
      break;
    }

    if(SwapChainPresentMode != VK_PRESENT_MODE_MAILBOX_KHR && Mode == VK_PRESENT_MODE_IMMEDIATE_KHR)
    {
      SwapChainPresentMode = VK_PRESENT_MODE_IMMEDIATE_KHR;
    }
  }

  uint DesiredNumberOfSwapChainImages = SurfaceCapabilities.minImageCount + 1;
  if(SurfaceCapabilities.maxImageCount > 0 && DesiredNumberOfSwapChainImages > SurfaceCapabilities.maxImageCount)
  {
    DesiredNumberOfSwapChainImages = SurfaceCapabilities.maxImageCount;
  }

  VkSurfaceTransformFlagsKHR PreTransform;
  if(SurfaceCapabilities.supportedTransforms & VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR)
  {
    PreTransform = VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR;
  }
  else
  {
    PreTransform = SurfaceCapabilities.currentTransform;
  }

  VkSwapchainCreateInfoKHR SwapChainDesc;
  with(SwapChainDesc)
  {
    surface = SwapChain.Surface;
    minImageCount = DesiredNumberOfSwapChainImages;
    imageFormat = SwapChain.ColorFormat;
    imageColorSpace = SwapChain.ColorSpace;
    imageExtent = SwapChainExtent;
    imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
    preTransform = cast(VkSurfaceTransformFlagBitsKHR)PreTransform;
    imageArrayLayers = 1;
    imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;
    queueFamilyIndexCount = 0;
    pQueueFamilyIndices = null;
    presentMode = SwapChainPresentMode;
    oldSwapchain = OldSwapChainHandle;
    clipped = true;
    compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
  }

  vkCreateSwapchainKHR(SwapChain.Device, &SwapChainDesc, null, &SwapChain.SwapChainHandle).Verify;

  if(OldSwapChainHandle)
  {
    vkDestroySwapchainKHR(SwapChain.Device, OldSwapChainHandle, null);
  }

  vkGetSwapchainImagesKHR(SwapChain.Device, SwapChain.SwapChainHandle, &SwapChain.ImageCount, null).Verify;
  assert(SwapChain.ImageCount);

  if(SwapChain.Images.ptr) G.Allocator.Delete(SwapChain.Images);
  SwapChain.Images = G.Allocator.NewArray!VkImage(SwapChain.ImageCount);

  vkGetSwapchainImagesKHR(SwapChain.Device, SwapChain.SwapChainHandle, &SwapChain.ImageCount, SwapChain.Images.ptr).Verify;

  if(SwapChain.Buffers.ptr) G.Allocator.Delete(SwapChain.Buffers);
  SwapChain.Buffers = G.Allocator.NewArray!(SwapChain.Buffer)(SwapChain.ImageCount);

  foreach(Index; 0 .. SwapChain.ImageCount)
  {
    VkImageViewCreateInfo ColorAttachmentView = {};
    with(ColorAttachmentView)
    {
      format = SwapChain.ColorFormat;
      components = VkComponentMapping(VK_COMPONENT_SWIZZLE_R,
                                      VK_COMPONENT_SWIZZLE_G,
                                      VK_COMPONENT_SWIZZLE_B,
                                      VK_COMPONENT_SWIZZLE_A);
      subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
      subresourceRange.baseMipLevel = 0;
      subresourceRange.levelCount = 1;
      subresourceRange.baseArrayLayer = 0;
      subresourceRange.layerCount = 1;
      viewType = VK_IMAGE_VIEW_TYPE_2D;
      flags = 0;
    }

    auto CurrentBuffer = &SwapChain.Buffers[Index];
    CurrentBuffer.Image = SwapChain.Images[Index];

    // Transform images from initial (undefined) to present layout
    VkImageSubresourceRange SubresourceRange;
    with(SubresourceRange)
    {
      aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
      baseMipLevel = 0;
      levelCount = 1;
      layerCount = 1;
    }
    SetImageLayout(CommandBuffer,
                   CurrentBuffer.Image,
                   SubresourceRange.aspectMask,
                   VK_IMAGE_LAYOUT_UNDEFINED,
                   VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
                   SubresourceRange);

    ColorAttachmentView.image = CurrentBuffer.Image;

    vkCreateImageView(SwapChain.Device, &ColorAttachmentView, null, &CurrentBuffer.View).Verify;
  }
}

void SetImageLayout(VkCommandBuffer CommandBuffer,
                    VkImage Image,
                    VkImageAspectFlags AspectMask,
                    VkImageLayout OldImageLayout,
                    VkImageLayout NewImageLayout,
                    VkImageSubresourceRange SubresourceRange)
{
  // Create an image barrier object
  VkImageMemoryBarrier ImageMemoryBarrier;
  with(ImageMemoryBarrier)
  {
    srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    oldLayout = OldImageLayout;
    newLayout = NewImageLayout;
    image = Image;
    subresourceRange = SubresourceRange;
  }

  // Source layouts (old)

  // Undefined layout
  // Only allowed as initial layout!
  // Make sure any writes to the image have been finished
  if (OldImageLayout == VK_IMAGE_LAYOUT_PREINITIALIZED)
  {
    ImageMemoryBarrier.srcAccessMask = VK_ACCESS_HOST_WRITE_BIT | VK_ACCESS_TRANSFER_WRITE_BIT;
  }

  // Old layout is color attachment
  // Make sure any writes to the color buffer have been finished
  if (OldImageLayout == VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
  {
    ImageMemoryBarrier.srcAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
  }

  // Old layout is depth/stencil attachment
  // Make sure any writes to the depth/stencil buffer have been finished
  if (OldImageLayout == VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL)
  {
    ImageMemoryBarrier.srcAccessMask = VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT;
  }

  // Old layout is transfer source
  // Make sure any reads from the image have been finished
  if (OldImageLayout == VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL)
  {
    ImageMemoryBarrier.srcAccessMask = VK_ACCESS_TRANSFER_READ_BIT;
  }

  // Old layout is shader read (sampler, input attachment)
  // Make sure any shader reads from the image have been finished
  if (OldImageLayout == VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL)
  {
    ImageMemoryBarrier.srcAccessMask = VK_ACCESS_SHADER_READ_BIT;
  }

  // Target layouts (new)

  // New layout is transfer destination (copy, blit)
  // Make sure any copyies to the image have been finished
  if (NewImageLayout == VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL)
  {
    ImageMemoryBarrier.dstAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
  }

  // New layout is transfer source (copy, blit)
  // Make sure any reads from and writes to the image have been finished
  if (NewImageLayout == VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL)
  {
    ImageMemoryBarrier.srcAccessMask = ImageMemoryBarrier.srcAccessMask | VK_ACCESS_TRANSFER_READ_BIT;
    ImageMemoryBarrier.dstAccessMask = VK_ACCESS_TRANSFER_READ_BIT;
  }

  // New layout is color attachment
  // Make sure any writes to the color buffer hav been finished
  if (NewImageLayout == VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL)
  {
    ImageMemoryBarrier.dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
    ImageMemoryBarrier.srcAccessMask = VK_ACCESS_TRANSFER_READ_BIT;
  }

  // New layout is depth attachment
  // Make sure any writes to depth/stencil buffer have been finished
  if (NewImageLayout == VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL)
  {
    ImageMemoryBarrier.dstAccessMask = ImageMemoryBarrier.dstAccessMask | VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT;
  }

  // New layout is shader read (sampler, input attachment)
  // Make sure any writes to the image have been finished
  if (NewImageLayout == VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL)
  {
    ImageMemoryBarrier.srcAccessMask = VK_ACCESS_HOST_WRITE_BIT | VK_ACCESS_TRANSFER_WRITE_BIT;
    ImageMemoryBarrier.dstAccessMask = VK_ACCESS_SHADER_READ_BIT;
  }

  // Put barrier on top
  VkPipelineStageFlags SourceStageFlags = VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;
  VkPipelineStageFlags DestinationStageFlags = VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;

  // Put barrier inside setup command buffer
  vkCmdPipelineBarrier(
    CommandBuffer,
    SourceStageFlags,
    DestinationStageFlags,
    0,
    0, null,
    0, null,
    1, &ImageMemoryBarrier);
}

VkBool32 GetMemoryType(VkPhysicalDeviceMemoryProperties PhysicalDeviceMemoryProperties,
                       uint TypeBits,
                       VkFlags Properties,
                       uint* TypeIndex)
{
  assert(TypeIndex);
  foreach(Index; 0 .. 32)
  {
    if(TypeBits & 1)
    {
      if((PhysicalDeviceMemoryProperties.memoryTypes[Index].propertyFlags & Properties) == Properties)
      {
        *TypeIndex = Index;
        return true;
      }
    }
    TypeBits >>= 1;
  }
  return false;
}

VkBool32 DebugMessageCallback(
  VkDebugReportFlagsEXT Flags,
  VkDebugReportObjectTypeEXT ObjectType,
  ulong SourceObject,
  size_t Location,
  int MessageCode,
  const char* LayerPrefix,
  const char* Message,
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
