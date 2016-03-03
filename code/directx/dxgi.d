module dxgi;
version(Windows):

import core.sys.windows.windows;
public import dxgiformat;

private import std.format : format;

private enum _FACDXGI = 0x87a;
auto MAKE_DXGI_HRESULT(uint Code)
{
  return MAKE_HRESULT(1, _FACDXGI, Code);
}

auto MAKE_DXGI_STATUS(uint Code)
{
  return MAKE_HRESULT(0, _FACDXGI, Code);
}


struct DXGI_RGB
{
  float Red;
  float Green;
  float Blue;
}

struct DXGI_RGBA
{
  float r;
  float g;
  float b;
  float a;
}

struct DXGI_GAMMA_CONTROL
{
  DXGI_RGB        Scale;
  DXGI_RGB        Offset;
  DXGI_RGB[1025]  GammaCurve;
}

struct DXGI_GAMMA_CONTROL_CAPABILITIES
{
  BOOL         ScaleAndOffsetSupported;
  float        MaxConvertedValue;
  float        MinConvertedValue;
  UINT         NumGammaControlPoints;
  float[1025]  ControlPointPositions;
}

struct DXGI_RATIONAL
{
  UINT  Numerator;
  UINT  Denominator;
}

enum DXGI_MODE_SCANLINE_ORDER
{
  UNSPECIFIED       = 0,
  PROGRESSIVE       = 1,
  UPPER_FIELD_FIRST = 2,
  LOWER_FIELD_FIRST = 3,
}

enum DXGI_MODE_SCALING
{
  UNSPECIFIED = 0,
  CENTERED    = 1,
  STRETCHED   = 2,
}

enum DXGI_MODE_ROTATION
{
  UNSPECIFIED = 0,
  IDENTITY    = 1,
  ROTATE90    = 2,
  ROTATE180   = 3,
  ROTATE270   = 4,
}

struct DXGI_MODE_DESC
{
  UINT Width;
  UINT Height;
  DXGI_RATIONAL RefreshRate;
  DXGI_FORMAT Format;
  DXGI_MODE_SCANLINE_ORDER ScanlineOrdering;
  DXGI_MODE_SCALING Scaling;
}

// The following values are used with DXGI_SAMPLE_DESC.Quality:
enum DXGI_STANDARD_MULTISAMPLE_QUALITY_PATTERN = 0xffffffff;
enum DXGI_CENTER_MULTISAMPLE_QUALITY_PATTERN = 0xfffffffe;

struct DXGI_SAMPLE_DESC
{
  UINT Count;
  UINT Quality;
}

enum DXGI_COLOR_SPACE_TYPE
{
  RGB_FULL_G22_NONE_P709        = 0,
  RGB_FULL_G10_NONE_P709        = 1,
  RGB_STUDIO_G22_NONE_P709      = 2,
  RGB_STUDIO_G22_NONE_P2020     = 3,
  RESERVED                      = 4,
  YCBCR_FULL_G22_NONE_P709_X601 = 5,
  YCBCR_STUDIO_G22_LEFT_P601    = 6,
  YCBCR_FULL_G22_LEFT_P601      = 7,
  YCBCR_STUDIO_G22_LEFT_P709    = 8,
  YCBCR_FULL_G22_LEFT_P709      = 9,
  YCBCR_STUDIO_G22_LEFT_P2020   = 10,
  YCBCR_FULL_G22_LEFT_P2020     = 11,
  CUSTOM                        = 0xFFFFFFFF,
}
alias DXGI_COLOR_SPACE = DXGI_COLOR_SPACE_TYPE;

struct DXGI_JPEG_DC_HUFFMAN_TABLE
{
  BYTE[12]  CodeCounts;
  BYTE[12]  CodeValues;
}

struct DXGI_JPEG_AC_HUFFMAN_TABLE
{
  BYTE[16]   CodeCounts;
  BYTE[162]  CodeValues;
}

struct DXGI_JPEG_QUANTIZATION_TABLE
{
  BYTE[64]  Elements;
}

enum DXGI_CPU_ACCESS
{
  NONE       = 0,
  DYNAMIC    = 1,
  READ_WRITE = 2,
  SCRATCH    = 3,
  FIELD      = 15,
}

enum DXGI_USAGE : uint
{
  SHADER_INPUT         = 0x00000010,
  RENDER_TARGET_OUTPUT = 0x00000020,
  BACK_BUFFER          = 0x00000040,
  SHARED               = 0x00000080,
  READ_ONLY            = 0x00000100,
  DISCARD_ON_PRESENT   = 0x00000200,
  UNORDERED_ACCESS     = 0x00000400,
}

struct DXGI_FRAME_STATISTICS
{
  UINT           PresentCount;
  UINT           PresentRefreshCount;
  UINT           SyncRefreshCount;
  LARGE_INTEGER  SyncQPCTime;
  LARGE_INTEGER  SyncGPUTime;
}

struct DXGI_MAPPED_RECT
{
  INT    Pitch;
  BYTE*  pBits;
}

struct DXGI_ADAPTER_DESC
{
  WCHAR[128]  Description;
  UINT        VendorId;
  UINT        DeviceId;
  UINT        SubSysId;
  UINT        Revision;
  SIZE_T      DedicatedVideoMemory;
  SIZE_T      DedicatedSystemMemory;
  SIZE_T      SharedSystemMemory;
  LUID        AdapterLuid;
}

struct DXGI_OUTPUT_DESC
{
  WCHAR[32]           DeviceName;
  RECT                DesktopCoordinates;
  BOOL                AttachedToDesktop;
  DXGI_MODE_ROTATION  Rotation;
  HMONITOR            Monitor;
}

struct DXGI_SHARED_RESOURCE
{
  HANDLE  Handle;
}

enum DXGI_RESOURCE_PRIORITY
{
  MINIMUM = 0x28000000,
  LOW     = 0x50000000,
  NORMAL  = 0x78000000,
  HIGH    = 0xa0000000,
  MAXIMUM = 0xc8000000,
}

enum DXGI_RESIDENCY
{
  FULLY_RESIDENT            = 1,
  RESIDENT_IN_SHARED_MEMORY = 2,
  EVICTED_TO_DISK           = 3,
}

struct DXGI_SURFACE_DESC
{
  UINT              Width;
  UINT              Height;
  DXGI_FORMAT       Format;
  DXGI_SAMPLE_DESC  SampleDesc;
}

enum DXGI_SWAP_EFFECT
{
  DISCARD         = 0,
  SEQUENTIAL      = 1,
  FLIP_SEQUENTIAL = 3,
  FLIP_DISCARD    = 4,
}

enum DXGI_SWAP_CHAIN_FLAG
{
  NONPREROTATED                   = 1,
  ALLOW_MODE_SWITCH               = 2,
  GDI_COMPATIBLE                  = 4,
  RESTRICTED_CONTENT              = 8,
  RESTRICT_SHARED_RESOURCE_DRIVER = 16,
  DISPLAY_ONLY                    = 32,
  FRAME_LATENCY_WAITABLE_OBJECT   = 64,
  FOREGROUND_LAYER                = 128,
  FULLSCREEN_VIDEO                = 256,
  YUV_VIDEO                       = 512,
  HW_PROTECTED                    = 1024,
}

struct DXGI_SWAP_CHAIN_DESC
{
  DXGI_MODE_DESC    BufferDesc;
  DXGI_SAMPLE_DESC  SampleDesc;
  DXGI_USAGE        BufferUsage;
  UINT              BufferCount;
  HWND              OutputWindow;
  BOOL              Windowed;
  DXGI_SWAP_EFFECT  SwapEffect;
  UINT              Flags;
}



mixin template DeclareIID(ComType, alias IIDString)
{
  static if(!is(ComType : IUnknown))
  pragma(msg, "Warning: The type " ~ ComType.stringof ~ " does not derive from IUnknown.");

  // Format of a UUID:
  // [0  1  2  3  4  5  6  7]  8  [9  10 11 12] 13 [14 15 16 17] 18 [19 20] [21 22] 23 [24 25] [26 27] [28 29] [30 31] [32 33] [34 35]
  // [x  x  x  x  x  x  x  x]  -  [x  x  x  x ] -  [x  x  x  x ] -  [x  x ] [x  x ]  - [x  x ] [x  x ] [x  x ] [x  x ] [x  x ] [x  x ]
  static assert(IIDString.length == 36, "Malformed UUID string:\nGot:             %-36s\nExpected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".Format(IIDString));
  static assert(IIDString[8]  == '-',   "Malformed UUID string:\nGot:             %-36s\nExpected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".Format(IIDString));
  static assert(IIDString[13] == '-',   "Malformed UUID string:\nGot:             %-36s\nExpected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".Format(IIDString));
  static assert(IIDString[18] == '-',   "Malformed UUID string:\nGot:             %-36s\nExpected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".Format(IIDString));
  static assert(IIDString[23] == '-',   "Malformed UUID string:\nGot:             %-36s\nExpected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".Format(IIDString));

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
}

mixin template DeclareMember_uuidof()
{
  //mixin("immutable __gshared uuidof = IID_%s;".format(typeof(this).stringof));
  mixin("static @property auto uuidof() { return IID_%s; }".format(typeof(this).stringof));
}


extern(C) const(IID) IID_IDXGIObject;

//DeclareIID(IDXGIObject, "aec22fb8-76f3-4639-9be0-28eb43a67a2e")
interface IDXGIObject : IUnknown
{
extern(Windows):
  mixin DeclareMember_uuidof;

  HRESULT SetPrivateData(REFGUID Name,
                         UINT DataSize,
                         const(void)* pData);

  HRESULT SetPrivateDataInterface(REFGUID Name,
                                  const(IUnknown)* pUnknown);

  HRESULT GetPrivateData(REFGUID Name,
                         UINT* pDataSize,
                         void* pData);

  HRESULT GetParent(REFIID riid,
                    void** ppParent);
}


extern(C) const(IID) IID_IDXGIDeviceSubObject;

//DeclareIID(IDXGIDeviceSubObject, "3d3e0379-f9de-4d58-bb6c-18d62992f1a6")
interface IDXGIDeviceSubObject : IDXGIObject
{
extern(Windows):
  mixin DeclareMember_uuidof;

  HRESULT GetDevice(REFIID riid,
                    void** ppDevice);
}



extern(C) const(IID) IID_IDXGIResource;

//DeclareIID(IDXGIResource, "035f3ab4-482e-4e50-b41f-8a7f8bd8960b")
interface IDXGIResource : IDXGIDeviceSubObject
{
extern(Windows):
  mixin DeclareMember_uuidof;

  HRESULT GetSharedHandle(HANDLE* pSharedHandle);

  HRESULT GetUsage(DXGI_USAGE* pUsage);

  HRESULT SetEvictionPriority(UINT EvictionPriority);

  HRESULT GetEvictionPriority(UINT* pEvictionPriority);
}



extern(C) const(IID) IID_IDXGIKeyedMutex;

//DeclareIID(IDXGIKeyedMutex, "9d8e1289-d7b3-465f-8126-250e349af85d")
interface IDXGIKeyedMutex : IDXGIDeviceSubObject
{
extern(Windows):
  mixin DeclareMember_uuidof;

  HRESULT AcquireSync(UINT64 Key,
                      DWORD dwMilliseconds);

  HRESULT ReleaseSync(UINT64 Key);
}

enum DXGI_MAP : uint
{
  DXGI_MAP_READ    = 1,
  DXGI_MAP_WRITE   = 2,
  DXGI_MAP_DISCARD = 4,
}


extern(C) const(IID) IID_IDXGISurface;

//DeclareIID(IDXGISurface, "cafcb56c-6ac3-4889-bf47-9e23bbd260ec")
interface IDXGISurface : IDXGIDeviceSubObject
{
extern(Windows):
  mixin DeclareMember_uuidof;

  HRESULT GetDesc(DXGI_SURFACE_DESC* pDesc);

  HRESULT Map(DXGI_MAPPED_RECT* pLockedRect, UINT MapFlags);

  HRESULT Unmap();
}


extern(C) const(IID) IID_IDXGISurface1;

//DeclareIID(IDXGISurface1, "4AE63092-6327-4c1b-80AE-BFE12EA32B86")
interface IDXGISurface1 : IDXGISurface
{
extern(Windows):
  mixin DeclareMember_uuidof;

  HRESULT GetDC(BOOL Discard,
                HDC* phdc);

  HRESULT ReleaseDC(RECT* pDirtyRect);
}


extern(C) const(IID) IID_IDXGIAdapter;

//DeclareIID(IDXGIAdapter, "2411e7e1-12ac-4ccf-bd14-9798e8534dc0")
interface IDXGIAdapter : IDXGIObject
{
extern(Windows):
  mixin DeclareMember_uuidof;

  HRESULT EnumOutputs(UINT Output,
                      IDXGIOutput** ppOutput);

  HRESULT GetDesc(DXGI_ADAPTER_DESC* pDesc);

  HRESULT CheckInterfaceSupport(REFGUID InterfaceName,
                                LARGE_INTEGER* pUMDVersion);
}

enum DXGI_ENUM_MODES : uint
{
  INTERLACED = 1,
  SCALING    = 2,
}


extern(C) const(IID) IID_IDXGIOutput;

//DeclareIID(IDXGIOutput, "ae02eedb-c735-4690-8d52-5a8dc20213aa")
interface IDXGIOutput : IDXGIObject
{
extern(Windows):
  mixin DeclareMember_uuidof;

  HRESULT GetDesc(DXGI_OUTPUT_DESC* pDesc);

  HRESULT GetDisplayModeList(DXGI_FORMAT EnumFormat,
                             UINT Flags,
                             UINT* pNumModes,
                             DXGI_MODE_DESC* pDesc);

  HRESULT FindClosestMatchingMode(const(DXGI_MODE_DESC)* pModeToMatch,
                                  DXGI_MODE_DESC* pClosestMatch,
                                  IUnknown* pConcernedDevice);

  HRESULT WaitForVBlank();
  HRESULT TakeOwnership(IUnknown* pDevice,
                        BOOL Exclusive);

  void ReleaseOwnership();

  HRESULT GetGammaControlCapabilities(DXGI_GAMMA_CONTROL_CAPABILITIES* pGammaCaps);

  HRESULT SetGammaControl(const(DXGI_GAMMA_CONTROL)* pArray);

  HRESULT GetGammaControl(DXGI_GAMMA_CONTROL* pArray);

  HRESULT SetDisplaySurface(IDXGISurface* pScanoutSurface);

  HRESULT GetDisplaySurfaceData(IDXGISurface* pDestination);

  HRESULT GetFrameStatistics(DXGI_FRAME_STATISTICS* pStats);
}


enum DXGI_MAX_SWAP_CHAIN_BUFFERS = 16;

enum DXGI_PRESENT
{
  TEST                  = 0x00000001,
  DO_NOT_SEQUENCE       = 0x00000002,
  RESTART               = 0x00000004,
  DO_NOT_WAIT           = 0x00000008,
  STEREO_PREFER_RIGHT   = 0x00000010,
  STEREO_TEMPORARY_MONO = 0x00000020,
  RESTRICT_TO_OUTPUT    = 0x00000040,
  USE_DURATION          = 0x00000100,
}


extern(C) const(IID) IID_IDXGISwapChain;

//DeclareIID(IDXGISwapChain, "310d36a0-d2e7-4c0a-aa04-6a9d23b8886a")
interface IDXGISwapChain : IDXGIDeviceSubObject
{
extern(Windows):
  mixin DeclareMember_uuidof;

  HRESULT Present(UINT SyncInterval,
                  UINT Flags);

  HRESULT GetBuffer(UINT Buffer,
                    REFIID riid,
                    void** ppSurface);

  HRESULT SetFullscreenState(BOOL Fullscreen,
                             IDXGIOutput* pTarget);

  HRESULT GetFullscreenState(BOOL* pFullscreen,
                             IDXGIOutput** ppTarget);

  HRESULT GetDesc(DXGI_SWAP_CHAIN_DESC* pDesc);

  HRESULT ResizeBuffers(UINT BufferCount,
                        UINT Width,
                        UINT Height,
                        DXGI_FORMAT NewFormat,
                        UINT SwapChainFlags);

  HRESULT ResizeTarget(const(DXGI_MODE_DESC)* pNewTargetParameters);

  HRESULT GetContainingOutput(IDXGIOutput** ppOutput);

  HRESULT GetFrameStatistics(DXGI_FRAME_STATISTICS* pStats);

  HRESULT GetLastPresentCount(UINT* pLastPresentCount);

}

enum DXGI_MWA
{
  NO_WINDOW_CHANGES = 1 << 0,
  NO_ALT_ENTER      = 1 << 1,
  NO_PRINT_SCREEN   = 1 << 2,
  VALID             = 0x7,
}


extern(C) const(IID) IID_IDXGIFactory;

//DeclareIID(IDXGIFactory, "7b7166ec-21c7-44ae-b21a-c9ae321ae369")
interface IDXGIFactory : IDXGIObject
{
extern(Windows):
  mixin DeclareMember_uuidof;

  HRESULT EnumAdapters(UINT Adapter,
                       IDXGIAdapter** ppAdapter);

  HRESULT MakeWindowAssociation(HWND WindowHandle,
                                UINT Flags);

  HRESULT GetWindowAssociation(HWND* pWindowHandle);

  HRESULT CreateSwapChain(IUnknown* pDevice,
                          DXGI_SWAP_CHAIN_DESC* pDesc,
                          IDXGISwapChain** ppSwapChain);

  HRESULT CreateSoftwareAdapter(HMODULE Module,
                                IDXGIAdapter** ppAdapter);

}

extern(Windows) HRESULT CreateDXGIFactory1(REFIID riid, void** ppFactory);


extern(C) const(IID) IID_IDXGIDevice;

//DeclareIID(IDXGIDevice, "54ec77fa-1377-44e6-8c32-88fd5f44c84c")
interface IDXGIDevice : IDXGIObject
{
extern(Windows):
  mixin DeclareMember_uuidof;

  HRESULT GetAdapter(IDXGIAdapter** pAdapter);

  HRESULT CreateSurface(const(DXGI_SURFACE_DESC)* pDesc,
                        UINT NumSurfaces,
                        DXGI_USAGE Usage,
                        const(DXGI_SHARED_RESOURCE)* pSharedResource,
                        IDXGISurface** ppSurface);

  HRESULT QueryResourceResidency(const(IUnknown*)* ppResources,
                                 DXGI_RESIDENCY* pResidencyStatus,
                                 UINT NumResources);

  HRESULT SetGPUThreadPriority(INT Priority);

  HRESULT GetGPUThreadPriority(INT* pPriority);
}

enum DXGI_ADAPTER_FLAG
{
  NONE ,
  REMOTE  = 1,
  SOFTWARE  = 2,
  FORCE_DWORDxffffffff,
}

struct DXGI_ADAPTER_DESC1
{
  WCHAR[128]  Description;
  UINT        VendorId;
  UINT        DeviceId;
  UINT        SubSysId;
  UINT        Revision;
  SIZE_T      DedicatedVideoMemory;
  SIZE_T      DedicatedSystemMemory;
  SIZE_T      SharedSystemMemory;
  LUID        AdapterLuid;
  UINT        Flags;
}

struct DXGI_DISPLAY_COLOR_SPACE
{
  FLOAT[8][2]   PrimaryCoordinates;
  FLOAT[16][2]  WhitePoints;
}


extern(C) const(IID) IID_IDXGIFactory1;

//DeclareIID(IDXGIFactory1, "770aae78-f26f-4dba-a829-253c83d1b387")
interface IDXGIFactory1 : IDXGIFactory
{
extern(Windows):
  mixin DeclareMember_uuidof;

  HRESULT EnumAdapters1(UINT Adapter,
                        IDXGIAdapter1** ppAdapter);

  BOOL IsCurrent();
}


extern(C) const(IID) IID_IDXGIAdapter1;

//DeclareIID(IDXGIAdapter1, "29038f61-3839-4626-91fd-086879011a05")
interface IDXGIAdapter1 : IDXGIAdapter
{
extern(Windows):
  mixin DeclareMember_uuidof;

  HRESULT GetDesc1(DXGI_ADAPTER_DESC1* pDesc);
}


extern(C) const(IID) IID_IDXGIDevice1;

//DeclareIID(IDXGIDevice1, "77db970f-6276-48ba-ba28-070143b4392c")
interface IDXGIDevice1 : IDXGIDevice
{
extern(Windows):
  mixin DeclareMember_uuidof;

  HRESULT SetMaximumFrameLatency(UINT MaxLatency);

  HRESULT GetMaximumFrameLatency(UINT* pMaxLatency);
}
