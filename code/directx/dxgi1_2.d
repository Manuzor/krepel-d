// Original file name: dxgi1_2.idl
// Conversion date: 2016-Mar-29 18:39:27.1374366
module directx.dxgi1_2;

version(Windows):

import core.sys.windows.windows;

private mixin template DEFINE_GUID(ComType, alias IIDString)
{
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
}

// Note: Everything below this line is automatically converted and likely to
// contain errors. You should manually check it for validity, if you care
// enough.


public import directx.dxgi;

mixin DEFINE_GUID!(IDXGIDisplayControl, "ea9dbf1a-c88e-4486-854a-98aa0138f30c");
// [object][uuid("ea9dbf1a-c88e-4486-854a-98aa0138f30c")][local][pointer_default("unique")]
interface IDXGIDisplayControl : IUnknown
{
extern(Windows):

  BOOL IsStereoEnabled();

  void SetStereoEnabled(
    BOOL enabled,
  );

}

struct DXGI_OUTDUPL_MOVE_RECT
{
  POINT SourcePoint;
  RECT DestinationRect;
}

struct DXGI_OUTDUPL_DESC
{
  DXGI_MODE_DESC ModeDesc;
  DXGI_MODE_ROTATION Rotation;
  BOOL DesktopImageInSystemMemory;
}

struct DXGI_OUTDUPL_POINTER_POSITION
{
  POINT Position;
  BOOL Visible;
}

alias DXGI_OUTDUPL_POINTER_SHAPE_TYPE = int;
enum : DXGI_OUTDUPL_POINTER_SHAPE_TYPE
{
  DXGI_OUTDUPL_POINTER_SHAPE_TYPE_MONOCHROME   = 0x00000001,
  DXGI_OUTDUPL_POINTER_SHAPE_TYPE_COLOR        = 0x00000002,
  DXGI_OUTDUPL_POINTER_SHAPE_TYPE_MASKED_COLOR = 0x00000004,
}

struct DXGI_OUTDUPL_POINTER_SHAPE_INFO
{
  UINT Type;
  UINT Width;
  UINT Height;
  UINT Pitch;
  POINT HotSpot;
}

struct DXGI_OUTDUPL_FRAME_INFO
{
  LARGE_INTEGER LastPresentTime;
  LARGE_INTEGER LastMouseUpdateTime;
  UINT AccumulatedFrames;
  BOOL RectsCoalesced;
  BOOL ProtectedContentMaskedOut;
  DXGI_OUTDUPL_POINTER_POSITION PointerPosition;
  UINT TotalMetadataBufferSize;
  UINT PointerShapeBufferSize;
}

mixin DEFINE_GUID!(IDXGIOutputDuplication, "191cfac3-a341-470d-b26e-a864f428319c");
// [object][uuid("191cfac3-a341-470d-b26e-a864f428319c")][local][pointer_default("unique")]
interface IDXGIOutputDuplication : IDXGIObject
{
extern(Windows):

  void GetDesc(
    // [out][annotation("_Out_")]
    DXGI_OUTDUPL_DESC* pDesc,
  );

  HRESULT AcquireNextFrame(
    // [in][annotation("_In_")]
    UINT TimeoutInMilliseconds,
    // [out][annotation("_Out_")]
    DXGI_OUTDUPL_FRAME_INFO* pFrameInfo,
    // [out][annotation("_COM_Outptr_")]
    IDXGIResource* ppDesktopResource,
  );

  HRESULT GetFrameDirtyRects(
    // [in][annotation("_In_")]
    UINT DirtyRectsBufferSize,
    // [out][annotation("_Out_writes_bytes_to_(DirtyRectsBufferSize, *pDirtyRectsBufferSizeRequired)")]
    RECT* pDirtyRectsBuffer,
    // [out][annotation("_Out_")]
    UINT* pDirtyRectsBufferSizeRequired,
  );

  HRESULT GetFrameMoveRects(
    // [in][annotation("_In_")]
    UINT MoveRectsBufferSize,
    // [out][annotation("_Out_writes_bytes_to_(MoveRectsBufferSize, *pMoveRectsBufferSizeRequired)")]
    DXGI_OUTDUPL_MOVE_RECT* pMoveRectBuffer,
    // [out][annotation("_Out_")]
    UINT* pMoveRectsBufferSizeRequired,
  );

  HRESULT GetFramePointerShape(
    // [in][annotation("_In_")]
    UINT PointerShapeBufferSize,
    // [out][annotation("_Out_writes_bytes_to_(PointerShapeBufferSize, *pPointerShapeBufferSizeRequired)")]
    void* pPointerShapeBuffer,
    // [out][annotation("_Out_")]
    UINT* pPointerShapeBufferSizeRequired,
    // [out][annotation("_Out_")]
    DXGI_OUTDUPL_POINTER_SHAPE_INFO* pPointerShapeInfo,
  );

  HRESULT MapDesktopSurface(
    // [out][annotation("_Out_")]
    DXGI_MAPPED_RECT* pLockedRect,
  );

  HRESULT UnMapDesktopSurface();

  HRESULT ReleaseFrame();

}

alias DXGI_ALPHA_MODE = int;
enum : DXGI_ALPHA_MODE
{
  DXGI_ALPHA_MODE_UNSPECIFIED   = 0,
  DXGI_ALPHA_MODE_PREMULTIPLIED = 1,
  DXGI_ALPHA_MODE_STRAIGHT      = 2,
  DXGI_ALPHA_MODE_IGNORE        = 3,
  DXGI_ALPHA_MODE_FORCE_DWORD   = 0xffffffff,
}

mixin DEFINE_GUID!(IDXGISurface2, "aba496dd-b617-4cb8-a866-bc44d7eb1fa2");
// [object][uuid("aba496dd-b617-4cb8-a866-bc44d7eb1fa2")][local][pointer_default("unique")]
interface IDXGISurface2 : IDXGISurface1
{
extern(Windows):

  HRESULT GetResource(
    // [in][annotation("_In_")]
    REFIID riid,
    // [out][annotation("_COM_Outptr_")]
    void** ppParentResource,
    // [out][annotation("_Out_")]
    UINT* pSubresourceIndex,
  );

}

mixin DEFINE_GUID!(IDXGIResource1, "30961379-4609-4a41-998e-54fe567ee0c1");
// [object][uuid("30961379-4609-4a41-998e-54fe567ee0c1")][local][pointer_default("unique")]
interface IDXGIResource1 : IDXGIResource
{
extern(Windows):

  HRESULT CreateSubresourceSurface(
    UINT index,
    // [out][annotation("_COM_Outptr_")]
    IDXGISurface2* ppSurface,
  );

  HRESULT CreateSharedHandle(
    // [in][annotation("_In_opt_")]
    in SECURITY_ATTRIBUTES* pAttributes,
    // [in][annotation("_In_")]
    DWORD dwAccess,
    // [in][annotation("_In_opt_")]
    LPCWSTR lpName,
    // [out][annotation("_Out_")]
    HANDLE* pHandle,
  );

}

alias DXGI_OFFER_RESOURCE_PRIORITY = int;
enum : DXGI_OFFER_RESOURCE_PRIORITY
{
  DXGI_OFFER_RESOURCE_PRIORITY_LOW    = 1,
  DXGI_OFFER_RESOURCE_PRIORITY_NORMAL,
  DXGI_OFFER_RESOURCE_PRIORITY_HIGH,
}

mixin DEFINE_GUID!(IDXGIDevice2, "05008617-fbfd-4051-a790-144884b4f6a9");
// [object][uuid("05008617-fbfd-4051-a790-144884b4f6a9")][local][pointer_default("unique")]
interface IDXGIDevice2 : IDXGIDevice1
{
extern(Windows):

  HRESULT OfferResources(
    // [in][annotation("_In_")]
    UINT NumResources,
    // [in][size_is("NumResources")][annotation("_In_reads_(NumResources)")]
    in IDXGIResource* ppResources,
    // [in][annotation("_In_")]
    DXGI_OFFER_RESOURCE_PRIORITY Priority,
  );

  HRESULT ReclaimResources(
    // [in][annotation("_In_")]
    UINT NumResources,
    // [in][size_is("NumResources")][annotation("_In_reads_(NumResources)")]
    in IDXGIResource* ppResources,
    // [out][size_is("NumResources")][annotation("_Out_writes_all_opt_(NumResources)")]
    BOOL* pDiscarded,
  );

  HRESULT EnqueueSetEvent(
    // [in][annotation("_In_")]
    HANDLE hEvent,
  );

}

enum UINT DXGI_ENUM_MODES_STEREO = 4;

enum UINT DXGI_ENUM_MODES_DISABLED_STEREO = 8;

enum DWORD DXGI_SHARED_RESOURCE_READ = 0x80000000;

enum DWORD DXGI_SHARED_RESOURCE_WRITE = 1;

struct DXGI_MODE_DESC1
{
  UINT Width;
  UINT Height;
  DXGI_RATIONAL RefreshRate;
  DXGI_FORMAT Format;
  DXGI_MODE_SCANLINE_ORDER ScanlineOrdering;
  DXGI_MODE_SCALING Scaling;
  BOOL Stereo;
}

alias DXGI_SCALING = int;
enum : DXGI_SCALING
{
  DXGI_SCALING_STRETCH              = 0,
  DXGI_SCALING_NONE                 = 1,
  DXGI_SCALING_ASPECT_RATIO_STRETCH = 2,
}

struct DXGI_SWAP_CHAIN_DESC1
{
  UINT Width;
  UINT Height;
  DXGI_FORMAT Format;
  BOOL Stereo;
  DXGI_SAMPLE_DESC SampleDesc;
  DXGI_USAGE BufferUsage;
  UINT BufferCount;
  DXGI_SCALING Scaling;
  DXGI_SWAP_EFFECT SwapEffect;
  DXGI_ALPHA_MODE AlphaMode;
  UINT Flags;
}

struct DXGI_SWAP_CHAIN_FULLSCREEN_DESC
{
  DXGI_RATIONAL RefreshRate;
  DXGI_MODE_SCANLINE_ORDER ScanlineOrdering;
  DXGI_MODE_SCALING Scaling;
  BOOL Windowed;
}

struct DXGI_PRESENT_PARAMETERS
{
  UINT DirtyRectsCount;
  RECT* pDirtyRects;
  RECT* pScrollRect;
  POINT* pScrollOffset;
}

mixin DEFINE_GUID!(IDXGISwapChain1, "790a45f7-0d42-4876-983a-0a55cfe6f4aa");
// [object][uuid("790a45f7-0d42-4876-983a-0a55cfe6f4aa")][local][pointer_default("unique")]
interface IDXGISwapChain1 : IDXGISwapChain
{
extern(Windows):

  HRESULT GetDesc1(
    // [out][annotation("_Out_")]
    DXGI_SWAP_CHAIN_DESC1* pDesc,
  );

  HRESULT GetFullscreenDesc(
    // [out][annotation("_Out_")]
    DXGI_SWAP_CHAIN_FULLSCREEN_DESC* pDesc,
  );

  HRESULT GetHwnd(
    // [out][annotation("_Out_")]
    HWND* pHwnd,
  );

  HRESULT GetCoreWindow(
    // [in][annotation("_In_")]
    REFIID refiid,
    // [out][annotation("_COM_Outptr_")]
    void** ppUnk,
  );

  HRESULT Present1(
    // [in]
    UINT SyncInterval,
    // [in]
    UINT PresentFlags,
    // [in][annotation("_In_")]
    in DXGI_PRESENT_PARAMETERS* pPresentParameters,
  );

  BOOL IsTemporaryMonoSupported();

  HRESULT GetRestrictToOutput(
    // [out][annotation("_Out_")]
    IDXGIOutput* ppRestrictToOutput,
  );

  HRESULT SetBackgroundColor(
    // [in][annotation("_In_")]
    in DXGI_RGBA* pColor,
  );

  HRESULT GetBackgroundColor(
    // [out][annotation("_Out_")]
    DXGI_RGBA* pColor,
  );

  HRESULT SetRotation(
    // [in][annotation("_In_")]
    DXGI_MODE_ROTATION Rotation,
  );

  HRESULT GetRotation(
    // [out][annotation("_Out_")]
    DXGI_MODE_ROTATION* pRotation,
  );

}

mixin DEFINE_GUID!(IDXGIFactory2, "50c83a1c-e072-4c48-87b0-3630fa36a6d0");
// [object][uuid("50c83a1c-e072-4c48-87b0-3630fa36a6d0")][local][pointer_default("unique")]
interface IDXGIFactory2 : IDXGIFactory1
{
extern(Windows):

  BOOL IsWindowedStereoEnabled();

  HRESULT CreateSwapChainForHwnd(
    // [in][annotation("_In_")]
    IUnknown pDevice,
    // [in][annotation("_In_")]
    HWND hWnd,
    // [in][annotation("_In_")]
    in DXGI_SWAP_CHAIN_DESC1* pDesc,
    // [in][annotation("_In_opt_")]
    in DXGI_SWAP_CHAIN_FULLSCREEN_DESC* pFullscreenDesc,
    // [in][annotation("_In_opt_")]
    IDXGIOutput pRestrictToOutput,
    // [out][annotation("_COM_Outptr_")]
    IDXGISwapChain1* ppSwapChain,
  );

  HRESULT CreateSwapChainForCoreWindow(
    // [in][annotation("_In_")]
    IUnknown pDevice,
    // [in][annotation("_In_")]
    IUnknown pWindow,
    // [in][annotation("_In_")]
    in DXGI_SWAP_CHAIN_DESC1* pDesc,
    // [in][annotation("_In_opt_")]
    IDXGIOutput pRestrictToOutput,
    // [out][annotation("_COM_Outptr_")]
    IDXGISwapChain1* ppSwapChain,
  );

  HRESULT GetSharedResourceAdapterLuid(
    // [annotation("_In_")]
    HANDLE hResource,
    // [annotation("_Out_")]
    LUID* pLuid,
  );

  HRESULT RegisterStereoStatusWindow(
    // [in][annotation("_In_")]
    HWND WindowHandle,
    // [in][annotation("_In_")]
    UINT wMsg,
    // [out][annotation("_Out_")]
    DWORD* pdwCookie,
  );

  HRESULT RegisterStereoStatusEvent(
    // [in][annotation("_In_")]
    HANDLE hEvent,
    // [out][annotation("_Out_")]
    DWORD* pdwCookie,
  );

  void UnregisterStereoStatus(
    // [in][annotation("_In_")]
    DWORD dwCookie,
  );

  HRESULT RegisterOcclusionStatusWindow(
    // [in][annotation("_In_")]
    HWND WindowHandle,
    // [in][annotation("_In_")]
    UINT wMsg,
    // [out][annotation("_Out_")]
    DWORD* pdwCookie,
  );

  HRESULT RegisterOcclusionStatusEvent(
    // [in][annotation("_In_")]
    HANDLE hEvent,
    // [out][annotation("_Out_")]
    DWORD* pdwCookie,
  );

  void UnregisterOcclusionStatus(
    // [in][annotation("_In_")]
    DWORD dwCookie,
  );

  HRESULT CreateSwapChainForComposition(
    // [in][annotation("_In_")]
    IUnknown pDevice,
    // [in][annotation("_In_")]
    in DXGI_SWAP_CHAIN_DESC1* pDesc,
    // [in][annotation("_In_opt_")]
    IDXGIOutput pRestrictToOutput,
    // [out][annotation("_COM_Outptr_")]
    IDXGISwapChain1* ppSwapChain,
  );

}

alias DXGI_GRAPHICS_PREEMPTION_GRANULARITY = int;
enum : DXGI_GRAPHICS_PREEMPTION_GRANULARITY
{
  DXGI_GRAPHICS_PREEMPTION_DMA_BUFFER_BOUNDARY  = 0,
  DXGI_GRAPHICS_PREEMPTION_PRIMITIVE_BOUNDARY   = 1,
  DXGI_GRAPHICS_PREEMPTION_TRIANGLE_BOUNDARY    = 2,
  DXGI_GRAPHICS_PREEMPTION_PIXEL_BOUNDARY       = 3,
  DXGI_GRAPHICS_PREEMPTION_INSTRUCTION_BOUNDARY = 4,
}

alias DXGI_COMPUTE_PREEMPTION_GRANULARITY = int;
enum : DXGI_COMPUTE_PREEMPTION_GRANULARITY
{
  DXGI_COMPUTE_PREEMPTION_DMA_BUFFER_BOUNDARY   = 0,
  DXGI_COMPUTE_PREEMPTION_DISPATCH_BOUNDARY     = 1,
  DXGI_COMPUTE_PREEMPTION_THREAD_GROUP_BOUNDARY = 2,
  DXGI_COMPUTE_PREEMPTION_THREAD_BOUNDARY       = 3,
  DXGI_COMPUTE_PREEMPTION_INSTRUCTION_BOUNDARY  = 4,
}

struct DXGI_ADAPTER_DESC2
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
  DXGI_GRAPHICS_PREEMPTION_GRANULARITY GraphicsPreemptionGranularity;
  DXGI_COMPUTE_PREEMPTION_GRANULARITY ComputePreemptionGranularity;
}

mixin DEFINE_GUID!(IDXGIAdapter2, "0AA1AE0A-FA0E-4B84-8644-E05FF8E5ACB5");
// [object][uuid("0AA1AE0A-FA0E-4B84-8644-E05FF8E5ACB5")][local][pointer_default("unique")]
interface IDXGIAdapter2 : IDXGIAdapter1
{
extern(Windows):

  HRESULT GetDesc2(
    // [out][annotation("_Out_")]
    DXGI_ADAPTER_DESC2* pDesc,
  );

}

mixin DEFINE_GUID!(IDXGIOutput1, "00cddea8-939b-4b83-a340-a685226666cc");
// [object][uuid("00cddea8-939b-4b83-a340-a685226666cc")][local][pointer_default("unique")]
interface IDXGIOutput1 : IDXGIOutput
{
extern(Windows):

  HRESULT GetDisplayModeList1(
    // [in]
    DXGI_FORMAT EnumFormat,
    // [in]
    UINT Flags,
    // [in][out][annotation("_Inout_")]
    UINT* pNumModes,
    // [out][annotation("_Out_writes_to_opt_(*pNumModes,*pNumModes)")]
    DXGI_MODE_DESC1* pDesc,
  );

  HRESULT FindClosestMatchingMode1(
    // [in][annotation("_In_")]
    in DXGI_MODE_DESC1* pModeToMatch,
    // [out][annotation("_Out_")]
    DXGI_MODE_DESC1* pClosestMatch,
    // [in][annotation("_In_opt_")]
    IUnknown pConcernedDevice,
  );

  HRESULT GetDisplaySurfaceData1(
    // [in][annotation("_In_")]
    IDXGIResource pDestination,
  );

  HRESULT DuplicateOutput(
    // [in][annotation("_In_")]
    IUnknown pDevice,
    // [out][annotation("_COM_Outptr_")]
    IDXGIOutputDuplication* ppOutputDuplication,
  );

}
