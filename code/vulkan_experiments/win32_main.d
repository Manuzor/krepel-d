module krepel.win32_main;
version(Windows):

import krepel;
import krepel.win32;
import krepel.memory.reference_counting;


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

__gshared bool GlobalRunning;

auto Verify(VkResult Result)
{
  import std.conv : to;
  assert(Result == VK_SUCCESS, Result.to!string);
  return Result;
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

  // Note(Manu): There's no point to add the stdout log sink since stdout
  // isn't attached to anything in a windows application. We add the VS log
  // sink instead.
  Log.Sinks ~= ToDelegate(&VisualStudioLogSink);

  Log.Info("=== Beginning of Log");
  scope(exit) Log.Info("=== End of Log");

  if(!Win32LoadXInput())
  {
    Log.Info("Failed to load XInput.");
  }

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
      auto State = MainAllocator.NewARC!VulkanState();
      State.Allocator = MainAllocator;

      State.LoadDLL();
      if(State.DLL)
      {
        Log.Info("Using Vulkan DLL %s", State.DLLName);

        State.CreateInstance();
        assert(State.Instance);
        scope(exit) State.DestroyInstance();

        State.LoadPhysicalDevices();

        State.CreateDevice();
        //assert(State.Device);
        //scope(exit) State.DestroyDevice();
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

class VulkanState
{
  IAllocator Allocator;

  string DLLName;
  HANDLE DLL;

  VkInstance Instance;
  VkDevice Device;
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
      auto Func = cast(typeof(vkGetInstanceProcAddr))GetProcAddress(DLL, "vkGetInstanceProcAddr");
      if(Func is null) return;
      DVulkanLoader.loadInstanceFunctions(Func);
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

void CreateInstance(VulkanState State)
{
  VkApplicationInfo ApplicationInfo;
  with(ApplicationInfo)
  {
    pApplicationName = "Vulkan Experiments".ptr;
    applicationVersion = VK_MAKE_VERSION(0, 0, 1);

    pEngineName = "Krepel".ptr,
    engineVersion = VK_MAKE_VERSION(0, 0, 1);

    apiVersion = VK_MAKE_VERSION(1, 0, 4);
  }

  const(char)*[1] Layers = [ "VK_LAYER_LUNARG_standard_validation".ptr ];

  VkInstanceCreateInfo CreateInfo;
  with(CreateInfo)
  {
    pApplicationInfo = &ApplicationInfo;
    enabledLayerCount = Layers.length;
    ppEnabledLayerNames = Layers.ptr;
  }

  VkInstance Instance;
  vkCreateInstance(&CreateInfo, null, &Instance).Verify;
  assert(Instance);
  DVulkanLoader.loadAllFunctions(Instance);
  State.Instance = Instance;
}

void DestroyInstance(VulkanState State)
{
  if(State.Instance)
  {
    vkDestroyInstance(State.Instance, null);
  }
}

void CreateDevice(VulkanState State)
{
  // TODO(Manu): TBD.
}

void LoadPhysicalDevices(VulkanState State)
{
  uint DeviceCount;
  vkEnumeratePhysicalDevices(State.Instance, &DeviceCount, null).Verify;
  if(DeviceCount)
  {
    auto Devices = State.Allocator.NewArray!VkPhysicalDevice(DeviceCount);
    scope(success) State.Allocator.Delete(Devices);

    vkEnumeratePhysicalDevices(State.Instance, &DeviceCount, Devices.ptr).Verify;

    foreach(ref Device; Devices)
    {
      VkPhysicalDeviceProperties DeviceProperties;
      vkGetPhysicalDeviceProperties(Device, &DeviceProperties);
      Log.Info("Device: %s", DeviceProperties.deviceName.ptr.fromStringz);
      Log.Info("API Version: %s.%s.%s",
               VK_VERSION_MAJOR(DeviceProperties.apiVersion),
               VK_VERSION_MINOR(DeviceProperties.apiVersion),
               VK_VERSION_PATCH(DeviceProperties.apiVersion));
    }
  }
  else
  {
    Log.Failure("Failed to enumerate devices.");
  }
}
