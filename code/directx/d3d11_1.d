// Original file name: d3d11_1.idl
// Conversion date: 2016-Mar-29 18:38:16.9371094
module directx.d3d11_1;

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
}

// Note: Everything below this line is automatically converted and likely to
// contain errors. You should manually check it for validity, if you care
// enough.


public import directx.dxgi1_2;
public import directx.d3dcommon;
public import directx.d3d11;

alias D3D11_COPY_FLAGS = int;
enum : D3D11_COPY_FLAGS
{
  D3D11_COPY_NO_OVERWRITE = 0x00000001,
  D3D11_COPY_DISCARD      = 0x00000002,
}

alias D3D11_LOGIC_OP = int;
enum : D3D11_LOGIC_OP
{
  D3D11_LOGIC_OP_CLEAR         = 0,
  D3D11_LOGIC_OP_SET,
  D3D11_LOGIC_OP_COPY,
  D3D11_LOGIC_OP_COPY_INVERTED,
  D3D11_LOGIC_OP_NOOP,
  D3D11_LOGIC_OP_INVERT,
  D3D11_LOGIC_OP_AND,
  D3D11_LOGIC_OP_NAND,
  D3D11_LOGIC_OP_OR,
  D3D11_LOGIC_OP_NOR,
  D3D11_LOGIC_OP_XOR,
  D3D11_LOGIC_OP_EQUIV,
  D3D11_LOGIC_OP_AND_REVERSE,
  D3D11_LOGIC_OP_AND_INVERTED,
  D3D11_LOGIC_OP_OR_REVERSE,
  D3D11_LOGIC_OP_OR_INVERTED,
}

struct D3D11_RENDER_TARGET_BLEND_DESC1
{
  BOOL BlendEnable;
  BOOL LogicOpEnable;
  D3D11_BLEND SrcBlend;
  D3D11_BLEND DestBlend;
  D3D11_BLEND_OP BlendOp;
  D3D11_BLEND SrcBlendAlpha;
  D3D11_BLEND DestBlendAlpha;
  D3D11_BLEND_OP BlendOpAlpha;
  D3D11_LOGIC_OP LogicOp;
  UINT8 RenderTargetWriteMask;
}

struct D3D11_BLEND_DESC1
{
  BOOL AlphaToCoverageEnable;
  BOOL IndependentBlendEnable;
  D3D11_RENDER_TARGET_BLEND_DESC1[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT] RenderTarget;
}

mixin DEFINE_GUID!(ID3D11BlendState1, "cc86fabe-da55-401d-85e7-e3c9de2877e9");
// [uuid("cc86fabe-da55-401d-85e7-e3c9de2877e9")][object][local][pointer_default("unique")]
interface ID3D11BlendState1 : ID3D11BlendState
{
extern(Windows):

  void GetDesc1(
    // [annotation("_Out_")]
    D3D11_BLEND_DESC1* pDesc,
  );

}

struct D3D11_RASTERIZER_DESC1
{
  D3D11_FILL_MODE FillMode;
  D3D11_CULL_MODE CullMode;
  BOOL FrontCounterClockwise;
  INT DepthBias;
  FLOAT DepthBiasClamp;
  FLOAT SlopeScaledDepthBias;
  BOOL DepthClipEnable;
  BOOL ScissorEnable;
  BOOL MultisampleEnable;
  BOOL AntialiasedLineEnable;
  UINT ForcedSampleCount;
}

mixin DEFINE_GUID!(ID3D11RasterizerState1, "1217d7a6-5039-418c-b042-9cbe256afd6e");
// [uuid("1217d7a6-5039-418c-b042-9cbe256afd6e")][object][local][pointer_default("unique")]
interface ID3D11RasterizerState1 : ID3D11RasterizerState
{
extern(Windows):

  void GetDesc1(
    // [annotation("_Out_")]
    D3D11_RASTERIZER_DESC1* pDesc,
  );

}

alias D3D11_1_CREATE_DEVICE_CONTEXT_STATE_FLAG = int;
enum : D3D11_1_CREATE_DEVICE_CONTEXT_STATE_FLAG
{
  D3D11_1_CREATE_DEVICE_CONTEXT_STATE_SINGLETHREADED = 0x1,
}

mixin DEFINE_GUID!(ID3DDeviceContextState, "5c1e0d8a-7c23-48f9-8c59-a92958ceff11");
// [uuid("5c1e0d8a-7c23-48f9-8c59-a92958ceff11")][object][local][pointer_default("unique")]
interface ID3DDeviceContextState : ID3D11DeviceChild
{
extern(Windows):

}

mixin DEFINE_GUID!(ID3D11DeviceContext1, "bb2c6faa-b5fb-4082-8e6b-388b8cfa90e1");
// [uuid("bb2c6faa-b5fb-4082-8e6b-388b8cfa90e1")][object][local][pointer_default("unique")]
interface ID3D11DeviceContext1 : ID3D11DeviceContext
{
extern(Windows):

  void CopySubresourceRegion1(
    // [annotation("_In_")]
    ID3D11Resource pDstResource,
    // [annotation("_In_")]
    UINT DstSubresource,
    // [annotation("_In_")]
    UINT DstX,
    // [annotation("_In_")]
    UINT DstY,
    // [annotation("_In_")]
    UINT DstZ,
    // [annotation("_In_")]
    ID3D11Resource pSrcResource,
    // [annotation("_In_")]
    UINT SrcSubresource,
    // [annotation("_In_opt_")]
    in D3D11_BOX* pSrcBox,
    // [annotation("_In_")]
    UINT CopyFlags,
  );

  void UpdateSubresource1(
    // [annotation("_In_")]
    ID3D11Resource pDstResource,
    // [annotation("_In_")]
    UINT DstSubresource,
    // [annotation("_In_opt_")]
    in D3D11_BOX* pDstBox,
    // [annotation("_In_")]
    in void* pSrcData,
    // [annotation("_In_")]
    UINT SrcRowPitch,
    // [annotation("_In_")]
    UINT SrcDepthPitch,
    // [annotation("_In_")]
    UINT CopyFlags,
  );

  void DiscardResource(
    // [annotation("_In_")]
    ID3D11Resource pResource,
  );

  void DiscardView(
    // [annotation("_In_")]
    ID3D11View pResourceView,
  );

  void VSSetConstantBuffers1(
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - 1 )")]
    UINT StartSlot,
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - StartSlot )")]
    UINT NumBuffers,
    // [annotation("_In_reads_opt_(NumBuffers)")]
    ID3D11Buffer* ppConstantBuffers,
    // [annotation("_In_reads_opt_(NumBuffers)")]
    in UINT* pFirstConstant,
    // [annotation("_In_reads_opt_(NumBuffers)")]
    in UINT* pNumConstants,
  );

  void HSSetConstantBuffers1(
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - 1 )")]
    UINT StartSlot,
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - StartSlot )")]
    UINT NumBuffers,
    // [annotation("_In_reads_opt_(NumBuffers)")]
    ID3D11Buffer* ppConstantBuffers,
    // [annotation("_In_reads_opt_(NumBuffers)")]
    in UINT* pFirstConstant,
    // [annotation("_In_reads_opt_(NumBuffers)")]
    in UINT* pNumConstants,
  );

  void DSSetConstantBuffers1(
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - 1 )")]
    UINT StartSlot,
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - StartSlot )")]
    UINT NumBuffers,
    // [annotation("_In_reads_opt_(NumBuffers)")]
    ID3D11Buffer* ppConstantBuffers,
    // [annotation("_In_reads_opt_(NumBuffers)")]
    in UINT* pFirstConstant,
    // [annotation("_In_reads_opt_(NumBuffers)")]
    in UINT* pNumConstants,
  );

  void GSSetConstantBuffers1(
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - 1 )")]
    UINT StartSlot,
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - StartSlot )")]
    UINT NumBuffers,
    // [annotation("_In_reads_opt_(NumBuffers)")]
    ID3D11Buffer* ppConstantBuffers,
    // [annotation("_In_reads_opt_(NumBuffers)")]
    in UINT* pFirstConstant,
    // [annotation("_In_reads_opt_(NumBuffers)")]
    in UINT* pNumConstants,
  );

  void PSSetConstantBuffers1(
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - 1 )")]
    UINT StartSlot,
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - StartSlot )")]
    UINT NumBuffers,
    // [annotation("_In_reads_opt_(NumBuffers)")]
    ID3D11Buffer* ppConstantBuffers,
    // [annotation("_In_reads_opt_(NumBuffers)")]
    in UINT* pFirstConstant,
    // [annotation("_In_reads_opt_(NumBuffers)")]
    in UINT* pNumConstants,
  );

  void CSSetConstantBuffers1(
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - 1 )")]
    UINT StartSlot,
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - StartSlot )")]
    UINT NumBuffers,
    // [annotation("_In_reads_opt_(NumBuffers)")]
    ID3D11Buffer* ppConstantBuffers,
    // [annotation("_In_reads_opt_(NumBuffers)")]
    in UINT* pFirstConstant,
    // [annotation("_In_reads_opt_(NumBuffers)")]
    in UINT* pNumConstants,
  );

  void VSGetConstantBuffers1(
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - 1 )")]
    UINT StartSlot,
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - StartSlot )")]
    UINT NumBuffers,
    // [annotation("_Out_writes_opt_(NumBuffers)")]
    ID3D11Buffer* ppConstantBuffers,
    // [annotation("_Out_writes_opt_(NumBuffers)")]
    UINT* pFirstConstant,
    // [annotation("_Out_writes_opt_(NumBuffers)")]
    UINT* pNumConstants,
  );

  void HSGetConstantBuffers1(
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - 1 )")]
    UINT StartSlot,
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - StartSlot )")]
    UINT NumBuffers,
    // [annotation("_Out_writes_opt_(NumBuffers)")]
    ID3D11Buffer* ppConstantBuffers,
    // [annotation("_Out_writes_opt_(NumBuffers)")]
    UINT* pFirstConstant,
    // [annotation("_Out_writes_opt_(NumBuffers)")]
    UINT* pNumConstants,
  );

  void DSGetConstantBuffers1(
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - 1 )")]
    UINT StartSlot,
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - StartSlot )")]
    UINT NumBuffers,
    // [annotation("_Out_writes_opt_(NumBuffers)")]
    ID3D11Buffer* ppConstantBuffers,
    // [annotation("_Out_writes_opt_(NumBuffers)")]
    UINT* pFirstConstant,
    // [annotation("_Out_writes_opt_(NumBuffers)")]
    UINT* pNumConstants,
  );

  void GSGetConstantBuffers1(
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - 1 )")]
    UINT StartSlot,
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - StartSlot )")]
    UINT NumBuffers,
    // [annotation("_Out_writes_opt_(NumBuffers)")]
    ID3D11Buffer* ppConstantBuffers,
    // [annotation("_Out_writes_opt_(NumBuffers)")]
    UINT* pFirstConstant,
    // [annotation("_Out_writes_opt_(NumBuffers)")]
    UINT* pNumConstants,
  );

  void PSGetConstantBuffers1(
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - 1 )")]
    UINT StartSlot,
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - StartSlot )")]
    UINT NumBuffers,
    // [annotation("_Out_writes_opt_(NumBuffers)")]
    ID3D11Buffer* ppConstantBuffers,
    // [annotation("_Out_writes_opt_(NumBuffers)")]
    UINT* pFirstConstant,
    // [annotation("_Out_writes_opt_(NumBuffers)")]
    UINT* pNumConstants,
  );

  void CSGetConstantBuffers1(
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - 1 )")]
    UINT StartSlot,
    // [annotation("_In_range_( 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - StartSlot )")]
    UINT NumBuffers,
    // [annotation("_Out_writes_opt_(NumBuffers)")]
    ID3D11Buffer* ppConstantBuffers,
    // [annotation("_Out_writes_opt_(NumBuffers)")]
    UINT* pFirstConstant,
    // [annotation("_Out_writes_opt_(NumBuffers)")]
    UINT* pNumConstants,
  );

  void SwapDeviceContextState(
    // [annotation("_In_")]
    ID3DDeviceContextState pState,
    // [annotation("_Outptr_opt_")]
    ID3DDeviceContextState* ppPreviousState,
  );

  void ClearView(
    // [annotation("_In_")]
    ID3D11View pView,
    // [annotation("_In_")]
    in FLOAT[4] Color,
    // [annotation("_In_reads_opt_(NumRects)")]
    in D3D11_RECT* pRect,
    UINT NumRects,
  );

  void DiscardView1(
    // [annotation("_In_")]
    ID3D11View pResourceView,
    // [annotation("_In_reads_opt_(NumRects)")]
    in D3D11_RECT* pRects,
    UINT NumRects,
  );

}

struct D3D11_VIDEO_DECODER_SUB_SAMPLE_MAPPING_BLOCK
{
  UINT ClearSize;
  UINT EncryptedSize;
}

struct D3D11_VIDEO_DECODER_BUFFER_DESC1
{
  D3D11_VIDEO_DECODER_BUFFER_TYPE BufferType;
  UINT DataOffset;
  UINT DataSize;
  // [annotation("_Field_size_opt_(IVSize)")]
  void* pIV;
  UINT IVSize;
  // [annotation("_Field_size_opt_(SubSampleMappingCount)")]
  D3D11_VIDEO_DECODER_SUB_SAMPLE_MAPPING_BLOCK* pSubSampleMappingBlock;
  UINT SubSampleMappingCount;
}

struct D3D11_VIDEO_DECODER_BEGIN_FRAME_CRYPTO_SESSION
{
  ID3D11CryptoSession pCryptoSession;
  UINT BlobSize;
  // [annotation("_Field_size_opt_(BlobSize)")]
  void* pBlob;
  GUID* pKeyInfoId;
  UINT PrivateDataSize;
  // [annotation("_Field_size_opt_(PrivateDataSize)")]
  void* pPrivateData;
}

alias D3D11_VIDEO_DECODER_CAPS = int;
enum : D3D11_VIDEO_DECODER_CAPS
{
  D3D11_VIDEO_DECODER_CAPS_DOWNSAMPLE          = 0x1,
  D3D11_VIDEO_DECODER_CAPS_NON_REAL_TIME       = 0x02,
  D3D11_VIDEO_DECODER_CAPS_DOWNSAMPLE_DYNAMIC  = 0x04,
  D3D11_VIDEO_DECODER_CAPS_DOWNSAMPLE_REQUIRED = 0x08,
  D3D11_VIDEO_DECODER_CAPS_UNSUPPORTED         = 0x10,
}

alias D3D11_VIDEO_PROCESSOR_BEHAVIOR_HINTS = int;
enum : D3D11_VIDEO_PROCESSOR_BEHAVIOR_HINTS
{
  D3D11_VIDEO_PROCESSOR_BEHAVIOR_HINT_MULTIPLANE_OVERLAY_ROTATION               = 0x01,
  D3D11_VIDEO_PROCESSOR_BEHAVIOR_HINT_MULTIPLANE_OVERLAY_RESIZE                 = 0x02,
  D3D11_VIDEO_PROCESSOR_BEHAVIOR_HINT_MULTIPLANE_OVERLAY_COLOR_SPACE_CONVERSION = 0x04,
  D3D11_VIDEO_PROCESSOR_BEHAVIOR_HINT_TRIPLE_BUFFER_OUTPUT                      = 0x08,
}

struct D3D11_VIDEO_PROCESSOR_STREAM_BEHAVIOR_HINT
{
  BOOL Enable;
  UINT Width;
  UINT Height;
  DXGI_FORMAT Format;
}

alias D3D11_CRYPTO_SESSION_STATUS = int;
enum : D3D11_CRYPTO_SESSION_STATUS
{
  D3D11_CRYPTO_SESSION_STATUS_OK                   = 0,
  D3D11_CRYPTO_SESSION_STATUS_KEY_LOST             = 1,
  D3D11_CRYPTO_SESSION_STATUS_KEY_AND_CONTENT_LOST = 2,
}

struct D3D11_KEY_EXCHANGE_HW_PROTECTION_INPUT_DATA
{
  UINT PrivateDataSize;
  UINT HWProtectionDataSize;
  BYTE[4] pbInput;
}

struct D3D11_KEY_EXCHANGE_HW_PROTECTION_OUTPUT_DATA
{
  UINT PrivateDataSize;
  UINT MaxHWProtectionDataSize;
  UINT HWProtectionDataSize;
  UINT64 TransportTime;
  UINT64 ExecutionTime;
  BYTE[4] pbOutput;
}

struct D3D11_KEY_EXCHANGE_HW_PROTECTION_DATA
{
  UINT HWProtectionFunctionID;
  D3D11_KEY_EXCHANGE_HW_PROTECTION_INPUT_DATA* pInputData;
  D3D11_KEY_EXCHANGE_HW_PROTECTION_OUTPUT_DATA* pOutputData;
  HRESULT Status;
}

struct D3D11_VIDEO_SAMPLE_DESC
{
  UINT Width;
  UINT Height;
  DXGI_FORMAT Format;
  DXGI_COLOR_SPACE_TYPE ColorSpace;
}

mixin DEFINE_GUID!(ID3D11VideoContext1, "A7F026DA-A5F8-4487-A564-15E34357651E");
// [uuid("A7F026DA-A5F8-4487-A564-15E34357651E")][object][local][pointer_default("unique")]
interface ID3D11VideoContext1 : ID3D11VideoContext
{
extern(Windows):

  HRESULT SubmitDecoderBuffers1(
    // [annotation("_In_")]
    ID3D11VideoDecoder pDecoder,
    // [annotation("_In_")]
    UINT NumBuffers,
    // [annotation("_In_reads_(NumBuffers)")]
    in D3D11_VIDEO_DECODER_BUFFER_DESC1* pBufferDesc,
  );

  HRESULT GetDataForNewHardwareKey(
    // [annotation("_In_")]
    ID3D11CryptoSession pCryptoSession,
    // [annotation("_In_")]
    UINT PrivateInputSize,
    // [annotation("_In_reads_(PrivateInputSize)")]
    in void* pPrivatInputData,
    // [annotation("_Out_")]
    UINT64* pPrivateOutputData,
  );

  HRESULT CheckCryptoSessionStatus(
    // [annotation("_In_")]
    ID3D11CryptoSession pCryptoSession,
    // [annotation("_Out_")]
    D3D11_CRYPTO_SESSION_STATUS* pStatus,
  );

  HRESULT DecoderEnableDownsampling(
    // [annotation("_In_")]
    ID3D11VideoDecoder pDecoder,
    // [annotation("_In_")]
    DXGI_COLOR_SPACE_TYPE InputColorSpace,
    // [annotation("_In_")]
    in D3D11_VIDEO_SAMPLE_DESC* pOutputDesc,
    // [annotation("_In_")]
    UINT ReferenceFrameCount,
  );

  HRESULT DecoderUpdateDownsampling(
    // [annotation("_In_")]
    ID3D11VideoDecoder pDecoder,
    // [annotation("_In_")]
    in D3D11_VIDEO_SAMPLE_DESC* pOutputDesc,
  );

  void VideoProcessorSetOutputColorSpace1(
    // [annotation("_In_")]
    ID3D11VideoProcessor pVideoProcessor,
    // [annotation("_In_")]
    DXGI_COLOR_SPACE_TYPE ColorSpace,
  );

  void VideoProcessorSetOutputShaderUsage(
    // [annotation("_In_")]
    ID3D11VideoProcessor pVideoProcessor,
    // [annotation("_In_")]
    BOOL ShaderUsage,
  );

  void VideoProcessorGetOutputColorSpace1(
    // [annotation("_In_")]
    ID3D11VideoProcessor pVideoProcessor,
    // [annotation("_Out_")]
    DXGI_COLOR_SPACE_TYPE* pColorSpace,
  );

  void VideoProcessorGetOutputShaderUsage(
    // [annotation("_In_")]
    ID3D11VideoProcessor pVideoProcessor,
    // [annotation("_Out_")]
    BOOL* pShaderUsage,
  );

  void VideoProcessorSetStreamColorSpace1(
    // [annotation("_In_")]
    ID3D11VideoProcessor pVideoProcessor,
    // [annotation("_In_")]
    UINT StreamIndex,
    // [annotation("_In_")]
    DXGI_COLOR_SPACE_TYPE ColorSpace,
  );

  void VideoProcessorSetStreamMirror(
    // [annotation("_In_")]
    ID3D11VideoProcessor pVideoProcessor,
    // [annotation("_In_")]
    UINT StreamIndex,
    // [annotation("_In_")]
    BOOL Enable,
    // [annotation("_In_")]
    BOOL FlipHorizontal,
    // [annotation("_In_")]
    BOOL FlipVertical,
  );

  void VideoProcessorGetStreamColorSpace1(
    // [annotation("_In_")]
    ID3D11VideoProcessor pVideoProcessor,
    // [annotation("_In_")]
    UINT StreamIndex,
    // [annotation("_Out_")]
    DXGI_COLOR_SPACE_TYPE* pColorSpace,
  );

  void VideoProcessorGetStreamMirror(
    // [annotation("_In_")]
    ID3D11VideoProcessor pVideoProcessor,
    // [annotation("_In_")]
    UINT StreamIndex,
    // [annotation("_Out_")]
    BOOL* pEnable,
    // [annotation("_Out_")]
    BOOL* pFlipHorizontal,
    // [annotation("_Out_")]
    BOOL* pFlipVertical,
  );

  HRESULT VideoProcessorGetBehaviorHints(
    // [annotation("_In_")]
    ID3D11VideoProcessor pVideoProcessor,
    // [annotation("_In_")]
    UINT OutputWidth,
    // [annotation("_In_")]
    UINT OutputHeight,
    // [annotation("_In_")]
    DXGI_FORMAT OutputFormat,
    // [annotation("_In_")]
    UINT StreamCount,
    // [annotation("_In_reads_(StreamCount)")]
    in D3D11_VIDEO_PROCESSOR_STREAM_BEHAVIOR_HINT* pStreams,
    // [annotation("_Out_")]
    UINT* pBehaviorHints,
  );

}

mixin DEFINE_GUID!(ID3D11VideoDevice1, "29DA1D51-1321-4454-804B-F5FC9F861F0F");
// [uuid("29DA1D51-1321-4454-804B-F5FC9F861F0F")][object][local][pointer_default("unique")]
interface ID3D11VideoDevice1 : ID3D11VideoDevice
{
extern(Windows):

  HRESULT GetCryptoSessionPrivateDataSize(
    // [annotation("_In_")]
    in GUID* pCryptoType,
    // [annotation("_In_opt_")]
    in GUID* pDecoderProfile,
    // [annotation("_In_")]
    in GUID* pKeyExchangeType,
    // [annotation("_Out_")]
    UINT* pPrivateInputSize,
    // [annotation("_Out_")]
    UINT* pPrivateOutputSize,
  );

  HRESULT GetVideoDecoderCaps(
    // [annotation("_In_")]
    in GUID* pDecoderProfile,
    // [annotation("_In_")]
    UINT SampleWidth,
    // [annotation("_In_")]
    UINT SampleHeight,
    // [annotation("_In_")]
    in DXGI_RATIONAL* pFrameRate,
    // [annotation("_In_")]
    UINT BitRate,
    // [annotation("_In_opt_")]
    in GUID* pCryptoType,
    // [annotation("_Out_")]
    UINT* pDecoderCaps,
  );

  HRESULT CheckVideoDecoderDownsampling(
    // [annotation("_In_")]
    in D3D11_VIDEO_DECODER_DESC* pInputDesc,
    // [annotation("_In_")]
    DXGI_COLOR_SPACE_TYPE InputColorSpace,
    // [annotation("_In_")]
    in D3D11_VIDEO_DECODER_CONFIG* pInputConfig,
    // [annotation("_In_")]
    in DXGI_RATIONAL* pFrameRate,
    // [annotation("_In_")]
    in D3D11_VIDEO_SAMPLE_DESC* pOutputDesc,
    // [annotation("_Out_")]
    BOOL* pSupported,
    // [annotation("_Out_")]
    BOOL* pRealTimeHint,
  );

  HRESULT RecommendVideoDecoderDownsampleParameters(
    // [annotation("_In_")]
    in D3D11_VIDEO_DECODER_DESC* pInputDesc,
    // [annotation("_In_")]
    DXGI_COLOR_SPACE_TYPE InputColorSpace,
    // [annotation("_In_")]
    in D3D11_VIDEO_DECODER_CONFIG* pInputConfig,
    // [annotation("_In_")]
    in DXGI_RATIONAL* pFrameRate,
    // [annotation("_Out_")]
    D3D11_VIDEO_SAMPLE_DESC* pRecommendedOutputDesc,
  );

}

mixin DEFINE_GUID!(ID3D11VideoProcessorEnumerator1, "465217F2-5568-43CF-B5B9-F61D54531CA1");
// [uuid("465217F2-5568-43CF-B5B9-F61D54531CA1")][object][local][pointer_default("unique")]
interface ID3D11VideoProcessorEnumerator1 : ID3D11VideoProcessorEnumerator
{
extern(Windows):

  HRESULT CheckVideoProcessorFormatConversion(
    // [annotation("_In_")]
    DXGI_FORMAT InputFormat,
    // [annotation("_In_")]
    DXGI_COLOR_SPACE_TYPE InputColorSpace,
    // [annotation("_In_")]
    DXGI_FORMAT OutputFormat,
    // [annotation("_In_")]
    DXGI_COLOR_SPACE_TYPE OutputColorSpace,
    // [annotation("_Out_")]
    BOOL* pSupported,
  );

}

mixin DEFINE_GUID!(ID3D11Device1, "a04bfb29-08ef-43d6-a49c-a9bdbdcbe686");
// [uuid("a04bfb29-08ef-43d6-a49c-a9bdbdcbe686")][object][local][pointer_default("unique")]
interface ID3D11Device1 : ID3D11Device
{
extern(Windows):

  void GetImmediateContext1(
    // [annotation("_Outptr_")]
    ID3D11DeviceContext1* ppImmediateContext,
  );

  HRESULT CreateDeferredContext1(
    UINT ContextFlags,
    // [annotation("_COM_Outptr_opt_")]
    ID3D11DeviceContext1* ppDeferredContext,
  );

  HRESULT CreateBlendState1(
    // [annotation("_In_")]
    in D3D11_BLEND_DESC1* pBlendStateDesc,
    // [annotation("_COM_Outptr_opt_")]
    ID3D11BlendState1* ppBlendState,
  );

  HRESULT CreateRasterizerState1(
    // [annotation("_In_")]
    in D3D11_RASTERIZER_DESC1* pRasterizerDesc,
    // [annotation("_COM_Outptr_opt_")]
    ID3D11RasterizerState1* ppRasterizerState,
  );

  HRESULT CreateDeviceContextState(
    UINT Flags,
    // [annotation("_In_reads_( FeatureLevels )")]
    in D3D_FEATURE_LEVEL* pFeatureLevels,
    UINT FeatureLevels,
    UINT SDKVersion,
    REFIID EmulatedInterface,
    // [annotation("_Out_opt_")]
    D3D_FEATURE_LEVEL* pChosenFeatureLevel,
    // [annotation("_Out_opt_")]
    ID3DDeviceContextState* ppContextState,
  );

  HRESULT OpenSharedResource1(
    // [annotation("_In_")]
    HANDLE hResource,
    // [annotation("_In_")]
    REFIID returnedInterface,
    // [annotation("_COM_Outptr_")]
    void** ppResource,
  );

  HRESULT OpenSharedResourceByName(
    // [annotation("_In_")]
    LPCWSTR lpName,
    // [annotation("_In_")]
    DWORD dwDesiredAccess,
    // [annotation("_In_")]
    REFIID returnedInterface,
    // [annotation("_COM_Outptr_")]
    void** ppResource,
  );

}

mixin DEFINE_GUID!(ID3DUserDefinedAnnotation, "b2daad8b-03d4-4dbf-95eb-32ab4b63d0ab");
// [uuid("b2daad8b-03d4-4dbf-95eb-32ab4b63d0ab")][object][local][pointer_default("unique")]
interface ID3DUserDefinedAnnotation : IUnknown
{
extern(Windows):

  INT BeginEvent(
    // [annotation("_In_")]
    LPCWSTR Name,
  );

  INT EndEvent(  );

  void SetMarker(
    // [annotation("_In_")]
    LPCWSTR Name,
  );

  BOOL GetStatus(  );

}
