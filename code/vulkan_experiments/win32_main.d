module krepel.win32_main;
version(Windows):

import krepel;
import krepel.win32;


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
      auto VulkanDLL = LoadLibrary("vulkan-1.dll");
      if(VulkanDLL)
      {
        {
          auto Func = cast(typeof(vkGetInstanceProcAddr))GetProcAddress(VulkanDLL, "vkGetInstanceProcAddr");
          assert(Func, "Failed to load vkGetInstanceProcAddr.");
          DVulkanLoader.loadInstanceFunctions(Func);
        }

        VkApplicationInfo ApplicationInfo =
        {
          pApplicationName : "Vulkan Experiments".ptr,
          applicationVersion : VK_MAKE_VERSION(0, 0, 1),

          pEngineName : "Krepel".ptr,
          engineVersion : VK_MAKE_VERSION(0, 0, 1),

          apiVersion : VK_MAKE_VERSION(1, 0, 4),
        };

        const(char)*[1] Layers = [ "VK_LAYER_LUNARG_standard_validation".ptr ];

        VkInstanceCreateInfo CreateInfo =
        {
          pApplicationInfo : &ApplicationInfo,
          enabledLayerCount : Layers.length,
          ppEnabledLayerNames : Layers.ptr,
        };

        VkInstance Vulkan;
        vkCreateInstance(&CreateInfo, null, &Vulkan).Verify;
        DVulkanLoader.loadAllFunctions(Vulkan);
        scope(success) vkDestroyInstance(Vulkan, null);

        uint DeviceCount;
        vkEnumeratePhysicalDevices(Vulkan, &DeviceCount, null).Verify;
        if(DeviceCount)
        {
          auto Devices = MainAllocator.NewArray!VkPhysicalDevice(DeviceCount);
          scope(success) MainAllocator.Delete(Devices);

          vkEnumeratePhysicalDevices(Vulkan, &DeviceCount, Devices.ptr).Verify;

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
      else
      {
        Log.Failure("Failed to load vulkan-1.dll.");
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
