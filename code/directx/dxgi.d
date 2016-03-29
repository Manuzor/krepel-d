// Original file name: dxgi.idl
// Conversion date: 2016-Mar-17 18:37:50.2459586

module directx.dxgi;

version(Windows):

import core.sys.windows.windows;

private mixin template DEFINE_GUID(ComType, alias IIDString)
{
  static if(!is(ComType : IUnknown))
  {
    pragma(msg, "Warning: The type " ~ ComType.stringof ~ " does not derive from IUnknown.");
  }

  // Format of a UUID:
  // [0  1  2  3  4  5  6  7]  8  [9  10 11 12] 13 [14 15 16 17] 18 [19 20] [21 22] 23 [24 25] [26 27] [28 29] [30 31] [32 33] [34 35]
  // [x  x  x  x  x  x  x  x]  -  [x  x  x  x ] -  [x  x  x  x ] -  [x  x ] [x  x ]  - [x  x ] [x  x ] [x  x ] [x  x ] [x  x ] [x  x ]
  static assert(IIDString.length == 36, "Malformed UUID string:\nGot:             %-36s\nExpected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".Format(IIDString));
  static assert(IIDString[8]  == '-',   "Malformed UUID string:\nGot:             %-36s\nExpected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".Format(IIDString));
  static assert(IIDString[13] == '-',   "Malformed UUID string:\nGot:             %-36s\nExpected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".Format(IIDString));
  static assert(IIDString[18] == '-',   "Malformed UUID string:\nGot:             %-36s\nExpected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".Format(IIDString));
  static assert(IIDString[23] == '-',   "Malformed UUID string:\nGot:             %-36s\nExpected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".Format(IIDString));

  private import std.format : format;

  mixin(format("immutable IID IID_%s "
               "= { 0x%s, 0x%s, 0x%s, [0x%s, 0x%s, 0x%s, 0x%s, 0x%s, 0x%s, 0x%s, 0x%s] };",
               ComType.stringof,
               IIDString[ 0 ..  8], // IID.Data1    <=> [xxxxxxxx]-xxxx-xxxx-xxxx-xxxxxxxxxxxx
               IIDString[ 9 .. 13], // IID.Data2    <=> xxxxxxxx-[xxxx]-xxxx-xxxx-xxxxxxxxxxxx
               IIDString[14 .. 18], // IID.Data3    <=> xxxxxxxx-xxxx-[xxxx]-xxxx-xxxxxxxxxxxx
               IIDString[19 .. 21], // IID.Data4[0] <=> xxxxxxxx-xxxx-xxxx-[xx]xx-xxxxxxxxxxxx
               IIDString[21 .. 23], // IID.Data4[1] <=> xxxxxxxx-xxxx-xxxx-xx[xx]-xxxxxxxxxxxx
               IIDString[24 .. 26], // IID.Data4[2] <=> xxxxxxxx-xxxx-xxxx-xxxx-[xx]xxxxxxxxxx
               IIDString[26 .. 28], // IID.Data4[3] <=> xxxxxxxx-xxxx-xxxx-xxxx-xx[xx]xxxxxxxx
               IIDString[28 .. 30], // IID.Data4[4] <=> xxxxxxxx-xxxx-xxxx-xxxx-xxxx[xx]xxxxxx
               IIDString[30 .. 32], // IID.Data4[5] <=> xxxxxxxx-xxxx-xxxx-xxxx-xxxxxx[xx]xxxx
               IIDString[32 .. 34], // IID.Data4[6] <=> xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx[xx]xx
               IIDString[34 .. 36], // IID.Data4[7] <=> xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx[xx]
               ));

  /// Example: uuidof!IDXGIObject
  ref auto uuidof(T)() if(is(T == ComType)) { mixin("return IID_%s;".format(ComType.stringof)); }

  /// Example:
  ///   IDXGIObject Object = /* ... */;
  ///   auto Foo = Object.uuidof;
  ref auto uuidof(T)(auto ref in T) if(is(T == ComType)) { return uuidof!ComType; }
}

// Note: Everything below this line is automatically converted and likely to
// contain errors. You should manually check it for validity, if you care
// enough.


public import directx.dxgiformat;
public import directx.dxgitype;

enum DXGI_CPU_ACCESS_NONE            = 0;
enum DXGI_CPU_ACCESS_DYNAMIC         = 1;
enum DXGI_CPU_ACCESS_READ_WRITE      = 2;
enum DXGI_CPU_ACCESS_SCRATCH         = 3;
enum DXGI_CPU_ACCESS_FIELD           = 15;
enum DXGI_USAGE_SHADER_INPUT         = 0x00000010;
enum DXGI_USAGE_RENDER_TARGET_OUTPUT = 0x00000020;
enum DXGI_USAGE_BACK_BUFFER          = 0x00000040;
enum DXGI_USAGE_SHARED               = 0x00000080;
enum DXGI_USAGE_READ_ONLY            = 0x00000100;
enum DXGI_USAGE_DISCARD_ON_PRESENT   = 0x00000200;
enum DXGI_USAGE_UNORDERED_ACCESS     = 0x00000400;

alias DXGI_USAGE = UINT;

struct DXGI_FRAME_STATISTICS
{
  UINT PresentCount;
  UINT PresentRefreshCount;
  UINT SyncRefreshCount;
  LARGE_INTEGER SyncQPCTime;
  LARGE_INTEGER SyncGPUTime;
}

struct DXGI_MAPPED_RECT
{
  INT Pitch;
  BYTE* pBits;
}

struct DXGI_ADAPTER_DESC
{
  WCHAR[128] Description;
  UINT VendorId;
  UINT DeviceId;
  UINT SubSysId;
  UINT Revision;
  SIZE_T DedicatedVideoMemory;
  SIZE_T DedicatedSystemMemory;
  SIZE_T SharedSystemMemory;
  LUID AdapterLuid;
}

struct DXGI_OUTPUT_DESC
{
  WCHAR[32] DeviceName;
  RECT DesktopCoordinates;
  BOOL AttachedToDesktop;
  DXGI_MODE_ROTATION Rotation;
  HMONITOR Monitor;
}

struct DXGI_SHARED_RESOURCE
{
  HANDLE Handle;
}

enum UINT DXGI_RESOURCE_PRIORITY_MINIMUM = 0x28000000;

enum UINT DXGI_RESOURCE_PRIORITY_LOW = 0x50000000;

enum UINT DXGI_RESOURCE_PRIORITY_NORMAL = 0x78000000;

enum UINT DXGI_RESOURCE_PRIORITY_HIGH = 0xa0000000;

enum UINT DXGI_RESOURCE_PRIORITY_MAXIMUM = 0xc8000000;

alias DXGI_RESIDENCY = int;
enum : DXGI_RESIDENCY
{
  DXGI_RESIDENCY_FULLY_RESIDENT            = 1,
  DXGI_RESIDENCY_RESIDENT_IN_SHARED_MEMORY = 2,
  DXGI_RESIDENCY_EVICTED_TO_DISK           = 3,
}

struct DXGI_SURFACE_DESC
{
  UINT Width;
  UINT Height;
  DXGI_FORMAT Format;
  DXGI_SAMPLE_DESC SampleDesc;
}

alias DXGI_SWAP_EFFECT = int;
enum : DXGI_SWAP_EFFECT
{
  DXGI_SWAP_EFFECT_DISCARD         = 0,
  DXGI_SWAP_EFFECT_SEQUENTIAL      = 1,
  DXGI_SWAP_EFFECT_FLIP_SEQUENTIAL = 3,
  DXGI_SWAP_EFFECT_FLIP_DISCARD    = 4,
}

alias DXGI_SWAP_CHAIN_FLAG = int;
enum : DXGI_SWAP_CHAIN_FLAG
{
  DXGI_SWAP_CHAIN_FLAG_NONPREROTATED                   = 1,
  DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH               = 2,
  DXGI_SWAP_CHAIN_FLAG_GDI_COMPATIBLE                  = 4,
  DXGI_SWAP_CHAIN_FLAG_RESTRICTED_CONTENT              = 8,
  DXGI_SWAP_CHAIN_FLAG_RESTRICT_SHARED_RESOURCE_DRIVER = 16,
  DXGI_SWAP_CHAIN_FLAG_DISPLAY_ONLY                    = 32,
  DXGI_SWAP_CHAIN_FLAG_FRAME_LATENCY_WAITABLE_OBJECT   = 64,
  DXGI_SWAP_CHAIN_FLAG_FOREGROUND_LAYER                = 128,
  DXGI_SWAP_CHAIN_FLAG_FULLSCREEN_VIDEO                = 256,
  DXGI_SWAP_CHAIN_FLAG_YUV_VIDEO                       = 512,
  DXGI_SWAP_CHAIN_FLAG_HW_PROTECTED                    = 1024,
}

struct DXGI_SWAP_CHAIN_DESC
{
  DXGI_MODE_DESC BufferDesc;
  DXGI_SAMPLE_DESC SampleDesc;
  DXGI_USAGE BufferUsage;
  UINT BufferCount;
  HWND OutputWindow;
  BOOL Windowed;
  DXGI_SWAP_EFFECT SwapEffect;
  UINT Flags;
}

mixin DEFINE_GUID!(IDXGIObject, "aec22fb8-76f3-4639-9be0-28eb43a67a2e");
// [object][uuid("aec22fb8-76f3-4639-9be0-28eb43a67a2e")][local][pointer_default("unique")]
interface IDXGIObject : IUnknown
{
extern(Windows):

  HRESULT SetPrivateData(
    // [in][annotation("_In_")]
    REFGUID Name,
    // [in]
    UINT DataSize,
    // [in][annotation("_In_reads_bytes_(DataSize)")]
    in void* pData,
  );

  HRESULT SetPrivateDataInterface(
    // [in][annotation("_In_")]
    REFGUID Name,
    // [in][annotation("_In_")]
    in IUnknown* pUnknown,
  );

  HRESULT GetPrivateData(
    // [in][annotation("_In_")]
    REFGUID Name,
    // [in][out][annotation("_Inout_")]
    UINT* pDataSize,
    // [out][annotation("_Out_writes_bytes_(*pDataSize)")]
    void* pData,
  );

  HRESULT GetParent(
    // [in][annotation("_In_")]
    REFIID riid,
    // [out][retval][annotation("_COM_Outptr_")]
    void** ppParent,
  );

}

mixin DEFINE_GUID!(IDXGIDeviceSubObject, "3d3e0379-f9de-4d58-bb6c-18d62992f1a6");
// [object][uuid("3d3e0379-f9de-4d58-bb6c-18d62992f1a6")][local][pointer_default("unique")]
interface IDXGIDeviceSubObject : IDXGIObject
{
extern(Windows):

  HRESULT GetDevice(
    // [in][annotation("_In_")]
    REFIID riid,
    // [out][retval][annotation("_COM_Outptr_")]
    void** ppDevice,
  );

}

mixin DEFINE_GUID!(IDXGIResource, "035f3ab4-482e-4e50-b41f-8a7f8bd8960b");
// [object][uuid("035f3ab4-482e-4e50-b41f-8a7f8bd8960b")][local][pointer_default("unique")]
interface IDXGIResource : IDXGIDeviceSubObject
{
extern(Windows):

  HRESULT GetSharedHandle(
    // [out][annotation("_Out_")]
    HANDLE* pSharedHandle,
  );

  HRESULT GetUsage(
    // [out]
    DXGI_USAGE* pUsage,
  );

  HRESULT SetEvictionPriority(
    // [in]
    UINT EvictionPriority,
  );

  HRESULT GetEvictionPriority(
    // [out][retval][annotation("_Out_")]
    UINT* pEvictionPriority,
  );

}

mixin DEFINE_GUID!(IDXGIKeyedMutex, "9d8e1289-d7b3-465f-8126-250e349af85d");
// [object][uuid("9d8e1289-d7b3-465f-8126-250e349af85d")][local][pointer_default("unique")]
interface IDXGIKeyedMutex : IDXGIDeviceSubObject
{
extern(Windows):

  HRESULT AcquireSync(
    // [in]
    UINT64 Key,
    // [in]
    DWORD dwMilliseconds,
  );

  HRESULT ReleaseSync(
    // [in]
    UINT64 Key,
  );

}

enum UINT DXGI_MAP_READ = 1;

enum UINT DXGI_MAP_WRITE = 2;

enum UINT DXGI_MAP_DISCARD = 4;

mixin DEFINE_GUID!(IDXGISurface, "cafcb56c-6ac3-4889-bf47-9e23bbd260ec");
// [object][uuid("cafcb56c-6ac3-4889-bf47-9e23bbd260ec")][local][pointer_default("unique")]
interface IDXGISurface : IDXGIDeviceSubObject
{
extern(Windows):

  HRESULT GetDesc(
    // [out][annotation("_Out_")]
    DXGI_SURFACE_DESC* pDesc,
  );

  HRESULT Map(
    // [out][annotation("_Out_")]
    DXGI_MAPPED_RECT* pLockedRect,
    // [in]
    UINT MapFlags,
  );

  HRESULT Unmap(  );

}

mixin DEFINE_GUID!(IDXGISurface1, "4AE63092-6327-4c1b-80AE-BFE12EA32B86");
// [object][uuid("4AE63092-6327-4c1b-80AE-BFE12EA32B86")][local][pointer_default("unique")]
interface IDXGISurface1 : IDXGISurface
{
extern(Windows):

  HRESULT GetDC(
    // [in]
    BOOL Discard,
    // [out][annotation("_Out_")]
    HDC* phdc,
  );

  HRESULT ReleaseDC(
    // [in][annotation("_In_opt_")]
    RECT* pDirtyRect,
  );

}

mixin DEFINE_GUID!(IDXGIAdapter, "2411e7e1-12ac-4ccf-bd14-9798e8534dc0");
// [object][uuid("2411e7e1-12ac-4ccf-bd14-9798e8534dc0")][local][pointer_default("unique")]
interface IDXGIAdapter : IDXGIObject
{
extern(Windows):

  HRESULT EnumOutputs(
    // [in]
    UINT Output,
    // [in][out][annotation("_COM_Outptr_")]
    IDXGIOutput* ppOutput,
  );

  HRESULT GetDesc(
    // [out][annotation("_Out_")]
    DXGI_ADAPTER_DESC* pDesc,
  );

  HRESULT CheckInterfaceSupport(
    // [in][annotation("_In_")]
    REFGUID InterfaceName,
    // [out][annotation("_Out_")]
    LARGE_INTEGER* pUMDVersion,
  );

}

enum UINT DXGI_ENUM_MODES_INTERLACED = 1;

enum UINT DXGI_ENUM_MODES_SCALING = 2;

mixin DEFINE_GUID!(IDXGIOutput, "ae02eedb-c735-4690-8d52-5a8dc20213aa");
// [object][uuid("ae02eedb-c735-4690-8d52-5a8dc20213aa")][local][pointer_default("unique")]
interface IDXGIOutput : IDXGIObject
{
extern(Windows):

  HRESULT GetDesc(
    // [out][annotation("_Out_")]
    DXGI_OUTPUT_DESC* pDesc,
  );

  HRESULT GetDisplayModeList(
    // [in]
    DXGI_FORMAT EnumFormat,
    // [in]
    UINT Flags,
    // [in][out][annotation("_Inout_")]
    UINT* pNumModes,
    // [out][annotation("_Out_writes_to_opt_(*pNumModes,*pNumModes)")]
    DXGI_MODE_DESC* pDesc,
  );

  HRESULT FindClosestMatchingMode(
    // [in][annotation("_In_")]
    in DXGI_MODE_DESC* pModeToMatch,
    // [out][annotation("_Out_")]
    DXGI_MODE_DESC* pClosestMatch,
    // [in][annotation("_In_opt_")]
    IUnknown pConcernedDevice,
  );

  HRESULT WaitForVBlank(  );

  HRESULT TakeOwnership(
    // [in][annotation("_In_")]
    IUnknown pDevice,
    BOOL Exclusive,
  );

  void ReleaseOwnership(  );

  HRESULT GetGammaControlCapabilities(
    // [out][annotation("_Out_")]
    DXGI_GAMMA_CONTROL_CAPABILITIES* pGammaCaps,
  );

  HRESULT SetGammaControl(
    // [in][annotation("_In_")]
    in DXGI_GAMMA_CONTROL* pArray,
  );

  HRESULT GetGammaControl(
    // [out][annotation("_Out_")]
    DXGI_GAMMA_CONTROL* pArray,
  );

  HRESULT SetDisplaySurface(
    // [in][annotation("_In_")]
    IDXGISurface pScanoutSurface,
  );

  HRESULT GetDisplaySurfaceData(
    // [in][annotation("_In_")]
    IDXGISurface pDestination,
  );

  HRESULT GetFrameStatistics(
    // [out][annotation("_Out_")]
    DXGI_FRAME_STATISTICS* pStats,
  );

}

enum DXGI_MAX_SWAP_CHAIN_BUFFERS        = 16;
enum DXGI_PRESENT_TEST                  = 0x00000001;
enum DXGI_PRESENT_DO_NOT_SEQUENCE       = 0x00000002;
enum DXGI_PRESENT_RESTART               = 0x00000004;
enum DXGI_PRESENT_DO_NOT_WAIT           = 0x00000008;
enum DXGI_PRESENT_STEREO_PREFER_RIGHT   = 0x00000010;
enum DXGI_PRESENT_STEREO_TEMPORARY_MONO = 0x00000020;
enum DXGI_PRESENT_RESTRICT_TO_OUTPUT    = 0x00000040;
enum DXGI_PRESENT_USE_DURATION          = 0x00000100;

mixin DEFINE_GUID!(IDXGISwapChain, "310d36a0-d2e7-4c0a-aa04-6a9d23b8886a");
// [object][uuid("310d36a0-d2e7-4c0a-aa04-6a9d23b8886a")][local][pointer_default("unique")]
interface IDXGISwapChain : IDXGIDeviceSubObject
{
extern(Windows):

  HRESULT Present(
    // [in]
    UINT SyncInterval,
    // [in]
    UINT Flags,
  );

  HRESULT GetBuffer(
    // [in]
    UINT Buffer,
    // [in][annotation("_In_")]
    REFIID riid,
    // [in][out][annotation("_COM_Outptr_")]
    void** ppSurface,
  );

  HRESULT SetFullscreenState(
    // [in]
    BOOL Fullscreen,
    // [in][annotation("_In_opt_")]
    IDXGIOutput pTarget,
  );

  HRESULT GetFullscreenState(
    // [out][annotation("_Out_opt_")]
    BOOL* pFullscreen,
    // [out][annotation("_COM_Outptr_opt_result_maybenull_")]
    IDXGIOutput* ppTarget,
  );

  HRESULT GetDesc(
    // [out][annotation("_Out_")]
    DXGI_SWAP_CHAIN_DESC* pDesc,
  );

  HRESULT ResizeBuffers(
    // [in]
    UINT BufferCount,
    // [in]
    UINT Width,
    // [in]
    UINT Height,
    // [in]
    DXGI_FORMAT NewFormat,
    // [in]
    UINT SwapChainFlags,
  );

  HRESULT ResizeTarget(
    // [in][annotation("_In_")]
    in DXGI_MODE_DESC* pNewTargetParameters,
  );

  HRESULT GetContainingOutput(
    // [out][annotation("_COM_Outptr_")]
    IDXGIOutput* ppOutput,
  );

  HRESULT GetFrameStatistics(
    // [out][annotation("_Out_")]
    DXGI_FRAME_STATISTICS* pStats,
  );

  HRESULT GetLastPresentCount(
    // [out][annotation("_Out_")]
    UINT* pLastPresentCount,
  );

}

enum DXGI_MWA_NO_WINDOW_CHANGES = 1 << 0;
enum DXGI_MWA_NO_ALT_ENTER      = 1 << 1;
enum DXGI_MWA_NO_PRINT_SCREEN   = 1 << 2;
enum DXGI_MWA_VALID             = 0x7;

mixin DEFINE_GUID!(IDXGIFactory, "7b7166ec-21c7-44ae-b21a-c9ae321ae369");
// [object][uuid("7b7166ec-21c7-44ae-b21a-c9ae321ae369")][local][pointer_default("unique")]
interface IDXGIFactory : IDXGIObject
{
extern(Windows):

  HRESULT EnumAdapters(
    // [in]
    UINT Adapter,
    // [out][annotation("_COM_Outptr_")]
    IDXGIAdapter* ppAdapter,
  );

  HRESULT MakeWindowAssociation(
    HWND WindowHandle,
    UINT Flags,
  );

  HRESULT GetWindowAssociation(
    // [out][annotation("_Out_")]
    HWND* pWindowHandle,
  );

  HRESULT CreateSwapChain(
    // [in][annotation("_In_")]
    IUnknown pDevice,
    // [in][annotation("_In_")]
    DXGI_SWAP_CHAIN_DESC* pDesc,
    // [out][annotation("_COM_Outptr_")]
    IDXGISwapChain* ppSwapChain,
  );

  HRESULT CreateSoftwareAdapter(
    // [in]
    HMODULE Module,
    // [out][annotation("_COM_Outptr_")]
    IDXGIAdapter* ppAdapter,
  );

}

extern(Windows) @nogc nothrow
{
  alias PFN_CREATE_DXGI_FACTORY = HRESULT function(REFIID riid, void **ppFactory);
  alias PFN_CREATE_DXGI_FACTORY_1 = HRESULT function(REFIID riid, void **ppFactory);

  version(DXGI_RuntimeLinking)
  {
    __gshared
    {
      PFN_CREATE_DXGI_FACTORY CreateDXGIFactory = (REFIID riid, void **ppFactory) => DXGI_ERROR_NOT_CURRENTLY_AVAILABLE;
      PFN_CREATE_DXGI_FACTORY_1 CreateDXGIFactory1 = (REFIID riid, void **ppFactory) => DXGI_ERROR_NOT_CURRENTLY_AVAILABLE;
    }
  }
  else
  {
    HRESULT CreateDXGIFactory(REFIID riid, void **ppFactory);
    HRESULT CreateDXGIFactory1(REFIID riid, void **ppFactory);
  }
}

mixin DEFINE_GUID!(IDXGIDevice, "54ec77fa-1377-44e6-8c32-88fd5f44c84c");
// [object][uuid("54ec77fa-1377-44e6-8c32-88fd5f44c84c")][local][pointer_default("unique")]
interface IDXGIDevice : IDXGIObject
{
extern(Windows):

  HRESULT GetAdapter(
    // [out][annotation("_COM_Outptr_")]
    IDXGIAdapter* pAdapter,
  );

  HRESULT CreateSurface(
    // [in][annotation("_In_")]
    in DXGI_SURFACE_DESC* pDesc,
    // [in]
    UINT NumSurfaces,
    // [in]
    DXGI_USAGE Usage,
    // [in][annotation("_In_opt_")]
    in DXGI_SHARED_RESOURCE* pSharedResource,
    // [out][annotation("_COM_Outptr_")]
    IDXGISurface* ppSurface,
  );

  HRESULT QueryResourceResidency(
    // [in][size_is("NumResources")][annotation("_In_reads_(NumResources)")]
    in IUnknown* ppResources,
    // [out][size_is("NumResources")][annotation("_Out_writes_(NumResources)")]
    DXGI_RESIDENCY* pResidencyStatus,
    // [in]
    UINT NumResources,
  );

  HRESULT SetGPUThreadPriority(
    // [in]
    INT Priority,
  );

  HRESULT GetGPUThreadPriority(
    // [out][retval][annotation("_Out_")]
    INT* pPriority,
  );

}

alias DXGI_ADAPTER_FLAG = int;
enum : DXGI_ADAPTER_FLAG
{
  DXGI_ADAPTER_FLAG_NONE        = 0,
  DXGI_ADAPTER_FLAG_REMOTE      = 1,
  DXGI_ADAPTER_FLAG_SOFTWARE    = 2,
  DXGI_ADAPTER_FLAG_FORCE_DWORD = 0xFFFFFFFF,
}

struct DXGI_ADAPTER_DESC1
{
  WCHAR[128] Description;
  UINT VendorId;
  UINT DeviceId;
  UINT SubSysId;
  UINT Revision;
  SIZE_T DedicatedVideoMemory;
  SIZE_T DedicatedSystemMemory;
  SIZE_T SharedSystemMemory;
  LUID AdapterLuid;
  UINT Flags;
}

struct DXGI_DISPLAY_COLOR_SPACE
{
  FLOAT[2][8] PrimaryCoordinates;
  FLOAT[2][16] WhitePoints;
}

mixin DEFINE_GUID!(IDXGIFactory1, "770aae78-f26f-4dba-a829-253c83d1b387");
// [object][uuid("770aae78-f26f-4dba-a829-253c83d1b387")][local][pointer_default("unique")]
interface IDXGIFactory1 : IDXGIFactory
{
extern(Windows):

  HRESULT EnumAdapters1(
    // [in]
    UINT Adapter,
    // [out][annotation("_COM_Outptr_")]
    IDXGIAdapter1* ppAdapter,
  );

  BOOL IsCurrent(  );

}

mixin DEFINE_GUID!(IDXGIAdapter1, "29038f61-3839-4626-91fd-086879011a05");
// [object][uuid("29038f61-3839-4626-91fd-086879011a05")][local][pointer_default("unique")]
interface IDXGIAdapter1 : IDXGIAdapter
{
extern(Windows):

  HRESULT GetDesc1(
    // [out][annotation("_Out_")]
    DXGI_ADAPTER_DESC1* pDesc,
  );

}

mixin DEFINE_GUID!(IDXGIDevice1, "77db970f-6276-48ba-ba28-070143b4392c");
// [object][uuid("77db970f-6276-48ba-ba28-070143b4392c")][local][pointer_default("unique")]
interface IDXGIDevice1 : IDXGIDevice
{
extern(Windows):

  HRESULT SetMaximumFrameLatency(
    // [in]
    UINT MaxLatency,
  );

  HRESULT GetMaximumFrameLatency(
    // [out][annotation("_Out_")]
    UINT* pMaxLatency,
  );

}
