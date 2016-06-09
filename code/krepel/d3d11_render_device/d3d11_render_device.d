module krepel.d3d11_render_device.d3d11_render_device;

import krepel.memory;
import krepel.win32.directx.dxgi;
import krepel.win32.directx.d3d11;
import krepel.win32.directx.xinput;
import krepel.win32.directx.uuidof;
import krepel.string;
import krepel.container;
import krepel.render_device;
import krepel.log;
import krepel.math;
import krepel.resources;

version(D3D11_RuntimeLinking):

class DxState
{
  mixin RefCountSupport;

  IAllocator Allocator;
  HINSTANCE ProcessInstance;
  HWND WindowHandle;
  D3D_DRIVER_TYPE DriverType;
  D3D_FEATURE_LEVEL FeatureLevel;
  ID3D11Device Device;
  ID3D11Device1 Device1;
  ID3D11DeviceContext ImmediateContext;
  ID3D11DeviceContext1 ImmediateContext1;
  IDXGISwapChain SwapChain;
  IDXGISwapChain1 SwapChain1;
  ID3D11RenderTargetView RenderTargetView;
  debug ID3D11Debug DebugDevice;

  ~this()
  {

    ReleaseAndNullify(Device);
    ReleaseAndNullify(Device1);
    ReleaseAndNullify(ImmediateContext);
    ReleaseAndNullify(ImmediateContext1);
    ReleaseAndNullify(SwapChain);
    ReleaseAndNullify(SwapChain1);
    ReleaseAndNullify(RenderTargetView);
    debug
    {
      if(DebugDevice)
      {
        //DebugDevice.ReportLiveDeviceObjects(D3D11_RLDO_DETAIL);
        ReleaseAndNullify(DebugDevice);
      }
    }
  }
}

void ReleaseAndNullify(Type)(Type Instance)
  if(__traits(compiles, { Instance.Release(); Instance = null; }))
{
  if(Instance)
  {
    Instance.Release();
    Instance = null;
  }
}

class DxShaderCode
{
  mixin RefCountSupport;

  ID3DBlob Blob;

  ~this()
  {
    ReleaseAndNullify(Blob);
  }
}

class DxDepthStencilBuffer : IRenderDepthStencilBuffer
{
  ID3D11Texture2D Texture;
  ID3D11DepthStencilState State;
  ID3D11DepthStencilView View;

  ~this()
  {
    ReleaseAndNullify(Texture);
    ReleaseAndNullify(State);
    ReleaseAndNullify(View);
  }
}

class DxConstantBuffer : IRenderConstantBuffer
{
  ID3D11Buffer ConstantBuffer;

  ~this()
  {
    ReleaseAndNullify(ConstantBuffer);
  }
}

class DxRasterizerState : IRenderRasterizerState
{
  ID3D11RasterizerState RasterizerState;

  ~this()
  {
    ReleaseAndNullify(RasterizerState);
  }
}

class DxShader : IShader
{
  ARC!DxShaderCode Code;
}

class DxVertexBuffer : IRenderVertexBuffer
{
  ID3D11Buffer VertexBuffer;

  ~this()
  {
    ReleaseAndNullify(VertexBuffer);
  }
  uint Stride;
  uint Offset;
}


class DxIndexBuffer : IRenderIndexBuffer
{
  ID3D11Buffer IndexBuffer;

  uint IndexCount;
  uint IndexOffset;
  DXGI_FORMAT IndexFormat;

  ~this()
  {
    ReleaseAndNullify(IndexBuffer);
  }

}

class DxRenderMesh : IRenderMesh
{
  DxVertexBuffer VertexBuffer;
  DxIndexBuffer IndexBuffer;

  override uint GetIndexCount()
  {
    return IndexBuffer.IndexCount;
  }
}

class DxVertexShader : DxShader
{
  ID3D11VertexShader VertexShader;

  ~this()
  {
    ReleaseAndNullify(VertexShader);
  }
}

class DxPixelShader : DxShader
{
  ID3D11PixelShader PixelShader;

  ~this()
  {
    ReleaseAndNullify(PixelShader);
  }
}

class DxInputLayout : IRenderInputLayout
{
  ID3D11InputLayout InputLayout;

  ~this()
  {
    ReleaseAndNullify(InputLayout);
  }
}

D3D11_COMPARISON_FUNC ConvertComparisonEnum(RenderDepthCompareMethod Method)
{
  return Method + 1;
}

class DxInputLayoutDescription : IRenderInputLayoutDescription
{
  Array!D3D11_INPUT_ELEMENT_DESC InputDescription;
  Array!RenderInputLayoutDescription SourceDescriptions;

  this(IAllocator Allocator)
  {
    InputDescription.Allocator = Allocator;
    SourceDescriptions.Allocator = Allocator;
  }

  DXGI_FORMAT GetFormatFromDescription(RenderInputLayoutDescription Desc)
  {
    final switch(Desc.DataType)
    {
      case InputDescriptionDataType.Int:
        switch(Desc.NumberOfElements)
        {
          case 1:
            return DXGI_FORMAT_R32_UINT;
          case 2:
            return DXGI_FORMAT_R32G32_UINT;
          case 3:
            return DXGI_FORMAT_R32G32B32_UINT;
          case 4:
            return DXGI_FORMAT_R32G32B32A32_UINT;
          default:
            return DXGI_FORMAT_UNKNOWN;
        }
      case InputDescriptionDataType.Float:
        switch(Desc.NumberOfElements)
        {
          case 1:
            return DXGI_FORMAT_R32_FLOAT;
          case 2:
            return DXGI_FORMAT_R32G32_FLOAT;
          case 3:
            return DXGI_FORMAT_R32G32B32_FLOAT;
          case 4:
            return DXGI_FORMAT_R32G32B32A32_FLOAT;
          default:
            return DXGI_FORMAT_UNKNOWN;
        }
    }
  }

  void SetDescription(RenderInputLayoutDescription[] Desc)
  {
    SourceDescriptions.Clear();
    SourceDescriptions.PushBack(Desc[]);
    InputDescription.Clear();
    foreach(Index, SourceDescription; SourceDescriptions)
    {
      auto Format = GetFormatFromDescription(SourceDescription);
      if (Format == DXGI_FORMAT_UNKNOWN)
      {
        Log.Failure("Not suppported InputLayout Format");
      }
      with(SourceDescription)
      {
        InputDescription.PushBack(
          D3D11_INPUT_ELEMENT_DESC(
            SemanticName.Data.Data.ptr,
            SemanticIndex,
            Format,
            0,
            D3D11_APPEND_ALIGNED_ELEMENT,
            PerVertexData ? D3D11_INPUT_PER_VERTEX_DATA : D3D11_INPUT_PER_INSTANCE_DATA,
            0
          )
        );
      }
    }
  }
  //D3D11_INPUT_ELEMENT_DESC(  ),

}

ARC!DxShaderCode LoadAndCompileDxShader(DxState State, WString FileName, UString EntryPoint, UString Profile)
{
  UINT Flags = D3DCOMPILE_ENABLE_STRICTNESS;
  debug Flags |= D3DCOMPILE_DEBUG;

  ID3DBlob ShaderBlob;
  ID3DBlob ErrorBlob;
  scope(exit) if(ErrorBlob) ErrorBlob.Release();

  if(FAILED(D3DCompileFromFile(FileName.ptr,
                               null,
                               D3D_COMPILE_STANDARD_FILE_INCLUDE,
                               EntryPoint.ptr,
                               Profile.ptr,
                               Flags,
                               cast(UINT)0,
                               &ShaderBlob,
                               &ErrorBlob
                               )))
  {
    auto RawMessage = cast(char*)ErrorBlob.GetBufferPointer();
    auto MessageSize = ErrorBlob.GetBufferSize();
    auto Message = RawMessage[0 .. MessageSize];
    Log.Failure("Failed to compile shader: %s", Message);
    return typeof(return)();
  }

  Log.Info("Shader compiled successfully!");

  auto Result = State.Allocator.NewARC!DxShaderCode();
  Result.Blob = ShaderBlob;
  return Result;
}



class D3D11RenderDevice : IRenderDevice
{
  DxState DeviceState;
  DxDepthStencilBuffer DepthStencilBuffer;
  IAllocator Allocator;
  RenderDeviceCreationDescription Description;
  this(IAllocator Allocator)
  {
    this.Allocator = Allocator;

    DeviceState = Allocator.New!DxState();
    DeviceState.Allocator = Allocator;
  }

  ~this()
  {
    Allocator.Delete(DeviceState);
  }

  override IShader LoadVertexShader(WString FileName, UString EntryPoint, UString Profile)
  {
    auto Code = DeviceState.LoadAndCompileDxShader(FileName, EntryPoint, Profile);
    DxVertexShader Shader = Allocator.New!DxVertexShader();
    Shader.Code = Code;

    if(FAILED(DeviceState.Device.CreateVertexShader(Code.Blob.GetBufferPointer(),
                                              Code.Blob.GetBufferSize(),
                                              null,
                                              &Shader.VertexShader)))
    {
      Log.Failure("Failed to create vertex shader.");
      Allocator.Delete(Shader);
      return null;
    }

    return Shader;
  }

  override IRenderInputLayoutDescription CreateInputLayoutDescription(RenderInputLayoutDescription[] Descriptions)
  {
    DxInputLayoutDescription Description = Allocator.New!DxInputLayoutDescription(Allocator);
    Description.SetDescription(Descriptions);

    return Description;
  }

  override void DestroyInputLayoutDescription(IRenderInputLayoutDescription Description)
  {
    Allocator.Delete(cast(DxInputLayoutDescription)Description);
  }

  override IRenderInputLayout CreateVertexShaderInputLayoutFromDescription(IShader Shader, IRenderInputLayoutDescription Description)
  {
    DxInputLayout VertexShaderLayout = Allocator.New!DxInputLayout();
    DxInputLayoutDescription InputDescription = cast(DxInputLayoutDescription)Description;
    assert(InputDescription !is null);
    if(FAILED(DeviceState.Device.CreateInputLayout(InputDescription.InputDescription.Data.ptr,
                                             cast(UINT)InputDescription.InputDescription.Count,
                                             (cast(DxVertexShader)Shader).Code.Blob.GetBufferPointer(),
                                             (cast(DxVertexShader)Shader).Code.Blob.GetBufferSize(),
                                             &VertexShaderLayout.InputLayout)))
    {
      Log.Failure("Failed to create input layout.");
      Allocator.Delete(VertexShaderLayout);
      return null;
    }
    return VertexShaderLayout;
  }

  override void DestroyInputLayout(IRenderInputLayout Layout)
  {
    Allocator.Delete(cast(DxInputLayout)Layout);
  }

  override IRenderRasterizerState CreateRasterizerState(RenderRasterizerDescription Description)
  {
    auto State = Allocator.New!DxRasterizerState();
    D3D11_RASTERIZER_DESC Desc;
    Desc.FillMode = Description.RasterizationMethod == RenderRasterizationMethod.Solid ? D3D11_FILL_SOLID : D3D11_FILL_WIREFRAME;
    final switch (Description.CullMode)
    {
      case RenderCullMode.None:
        Desc.CullMode = D3D11_CULL_NONE;
        break;
      case RenderCullMode.Back:
        Desc.CullMode = D3D11_CULL_BACK;
        break;
      case RenderCullMode.Front:
        Desc.CullMode = D3D11_CULL_FRONT;
        break;
    }
    Desc.FrontCounterClockwise = Description.WindingOrder == RenderWindingOrder.CounterClockWise;
    Desc.DepthClipEnable = Description.EnableDepthCulling;
    if(FAILED(DeviceState.Device.CreateRasterizerState(&Desc, &State.RasterizerState)))
    {
      Log.Failure("Failed to create rasterizer state");
      Allocator.Delete(State);
      return null;
    }
    return State;
  }

  override IRenderDepthStencilBuffer CreateDepthStencilBuffer(RenderDepthStencilDescription Description)
  {
    DxDepthStencilBuffer Buffer = Allocator.New!DxDepthStencilBuffer();

    RECT ClientRect;
    GetClientRect(DeviceState.WindowHandle, &ClientRect);
    auto WindowWidth = ClientRect.right - ClientRect.left;
    auto WindowHeight = ClientRect.bottom - ClientRect.top;
    D3D11_TEXTURE2D_DESC DescDepth;
    with(DescDepth)
    {
      Width = WindowWidth;
      Height = WindowHeight;
      MipLevels = 1;
      ArraySize = 1;
      Format = DXGI_FORMAT_D32_FLOAT_S8X24_UINT;
      SampleDesc.Count = 1;
      SampleDesc.Quality = 0;
      Usage = D3D11_USAGE_DEFAULT;
      BindFlags = D3D11_BIND_DEPTH_STENCIL;
      CPUAccessFlags = 0;
      MiscFlags = 0;
    }
    if(FAILED(DeviceState.Device.CreateTexture2D( &DescDepth, NULL, &Buffer.Texture )))
    {
      Allocator.Delete(Buffer);
      Log.Failure("Failed to create depth stencil texture");
      return null;
    }

    D3D11_DEPTH_STENCIL_DESC DepthStencilDescription;
    with(DepthStencilDescription)
    {
      // Depth test parameters
      DepthEnable = Description.EnableDepthTest;
      DepthWriteMask = D3D11_DEPTH_WRITE_MASK_ALL;
      DepthFunc = ConvertComparisonEnum(Description.DepthCompareFunc);

      // Stencil test parameters
      StencilEnable = Description.EnableStencil;
      StencilReadMask = 0xFF;
      StencilWriteMask = 0xFF;

      // Stencil operations if pixel is front-facing
      FrontFace.StencilFailOp = D3D11_STENCIL_OP_KEEP;
      FrontFace.StencilDepthFailOp = D3D11_STENCIL_OP_INCR;
      FrontFace.StencilPassOp = D3D11_STENCIL_OP_KEEP;
      FrontFace.StencilFunc = D3D11_COMPARISON_ALWAYS;

      // Stencil operations if pixel is back-facing
      BackFace.StencilFailOp = D3D11_STENCIL_OP_KEEP;
      BackFace.StencilDepthFailOp = D3D11_STENCIL_OP_DECR;
      BackFace.StencilPassOp = D3D11_STENCIL_OP_KEEP;
      BackFace.StencilFunc = D3D11_COMPARISON_ALWAYS;
    }
    // Create depth stencil state
    if(FAILED(DeviceState.Device.CreateDepthStencilState(&DepthStencilDescription, &Buffer.State)))
    {
      Allocator.Delete(Buffer);
      Log.Failure("Failed to create depth stencil state");
      return null;
    }

    D3D11_DEPTH_STENCIL_VIEW_DESC ViewDescription;
    with(ViewDescription)
    {
      Format = DXGI_FORMAT_D32_FLOAT_S8X24_UINT;
      ViewDimension = D3D11_DSV_DIMENSION_TEXTURE2D;
      Texture2D.MipSlice = 0;
    }
    // Create the depth stencil view
    if(FAILED(DeviceState.Device.CreateDepthStencilView( Buffer.Texture, // Depth stencil texture
                                      &ViewDescription, // Depth stencil desc
                                      &Buffer.View )))  // [out] Depth stencil view
    {
      Allocator.Delete(Buffer);
      Log.Failure("Failed to create depth stencil view");
      return null;
    }

    return Buffer;

  }

  override void ReleaseDepthStencilBuffer(IRenderDepthStencilBuffer Buffer)
  {
    auto DepthStencilBuffer = cast(DxDepthStencilBuffer)Buffer;
    Allocator.Delete(DepthStencilBuffer);
  }

  override void ReleaseRasterizerState(IRenderRasterizerState State)
  {
    auto DxState = cast(DxRasterizerState)State;
    Allocator.Delete(DxState);
  }
  override void SetRasterizerState(IRenderRasterizerState State)
  {
    auto DxState = cast(DxRasterizerState)State;
    DeviceState.ImmediateContext.RSSetState(DxState.RasterizerState);
  }

  override IShader LoadPixelShader(WString FileName, UString EntryPoint, UString Profile)
  {
    auto Code = DeviceState.LoadAndCompileDxShader(FileName, EntryPoint, Profile);
    DxPixelShader Shader = Allocator.New!DxPixelShader();
    Shader.Code = Code;

    if(FAILED(DeviceState.Device.CreatePixelShader(Code.Blob.GetBufferPointer(),
                                              Code.Blob.GetBufferSize(),
                                              null,
                                              &Shader.PixelShader)))
    {
      Log.Failure("Failed to create pixel shader.");
      Allocator.Delete(Shader);
      return null;
    }

    return Shader;
  }

  override IRenderConstantBuffer CreateConstantBuffer(void[] Data)
  {
    auto ConstantBuffer = Allocator.New!DxConstantBuffer();
    D3D11_BUFFER_DESC Description;
    with(Description)
    {
      ByteWidth = cast(uint)AlignedSize(Data.length, 16);
      Usage = D3D11_USAGE_DYNAMIC;
      BindFlags = D3D11_BIND_CONSTANT_BUFFER;
      CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
      MiscFlags = 0;
      StructureByteStride = 0;
    }

    D3D11_SUBRESOURCE_DATA InitData;
    InitData.pSysMem = Data.ptr;

    if(FAILED(DeviceState.Device.CreateBuffer(&Description, &InitData, &ConstantBuffer.ConstantBuffer)))
    {
      Log.Failure("Could not create constant buffer!");
      Allocator.Delete(ConstantBuffer);
      return null;
    }

    return ConstantBuffer;
  }

  override void SetVertexShaderConstantBuffer(IRenderConstantBuffer Buffer, uint Index)
  {
    DxConstantBuffer ConstantBuffer = cast(DxConstantBuffer)Buffer;
    DeviceState.ImmediateContext.VSSetConstantBuffers(Index, 1, &ConstantBuffer.ConstantBuffer);
  }

  override void UpdateConstantBuffer(IRenderConstantBuffer ConstantBuffer, void[] Data, uint Offset = 0)
  {
    auto DxBuffer = cast(DxConstantBuffer)ConstantBuffer;

    D3D11_MAPPED_SUBRESOURCE MappedResource;
    DeviceState.ImmediateContext.Map(DxBuffer.ConstantBuffer, 0, D3D11_MAP_WRITE_DISCARD, 0, &MappedResource);
    MappedResource.pData[Offset .. Data.length + Offset] = Data[];
    DeviceState.ImmediateContext.Unmap(DxBuffer.ConstantBuffer, 0);
  }

  override void ReleaseConstantBuffer(IRenderConstantBuffer Buffer)
  {
    DxConstantBuffer ConstantBuffer = cast(DxConstantBuffer)Buffer;
    Allocator.Delete(ConstantBuffer);
  }


  override IRenderVertexBuffer CreateVertexBuffer(Vertex[] Vertices)
  {
    DxVertexBuffer Buffer = Allocator.New!DxVertexBuffer();
    D3D11_BUFFER_DESC BufferDesc;
    with(BufferDesc)
    {
      Usage = D3D11_USAGE_DEFAULT;
      ByteWidth = cast(UINT)Vertices.ByteCount;
      BindFlags = D3D11_BIND_VERTEX_BUFFER;
      CPUAccessFlags = 0;
    }
    D3D11_SUBRESOURCE_DATA InitData;
    InitData.pSysMem = Vertices.ptr;


    if(FAILED(DeviceState.Device.CreateBuffer(&BufferDesc, &InitData, &Buffer.VertexBuffer)))
    {
      Log.Failure("Failed to create vertex buffer.");
      Allocator.Delete(Buffer);
      return null;
    }

    Buffer.Stride = Vertex.sizeof;
    Buffer.Offset = 0;
    return Buffer;
  }
  override void ReleaseVertexBuffer(IRenderVertexBuffer Buffer)
  {
    Allocator.Delete(cast(DxVertexBuffer)Buffer);
  }

  override IRenderIndexBuffer CreateIndexBuffer(uint[] Indices)
  {
    DxIndexBuffer Buffer = Allocator.New!DxIndexBuffer();
    D3D11_BUFFER_DESC BufferDesc;
    with(BufferDesc)
    {
      Usage = D3D11_USAGE_DEFAULT;
      ByteWidth = cast(UINT)Indices.ByteCount;
      BindFlags = D3D11_BIND_INDEX_BUFFER;
      CPUAccessFlags = 0;
    }
    D3D11_SUBRESOURCE_DATA InitData;
    InitData.pSysMem = Indices.ptr;

    if(FAILED(DeviceState.Device.CreateBuffer(&BufferDesc, &InitData, &Buffer.IndexBuffer)))
    {
      Log.Failure("Failed to create index buffer.");
      Allocator.Delete(Buffer);
      return null;
    }
    Buffer.IndexCount = cast(uint)Indices.length;
    Buffer.IndexOffset = 0;
    Buffer.IndexFormat = DXGI_FORMAT_R32_UINT;
    return Buffer;
  }
  override void ReleaseIndexBuffer(IRenderIndexBuffer Buffer)
  {
    Allocator.Delete(cast(DxIndexBuffer)Buffer);
  }

  override void SetVertexBuffer(IRenderVertexBuffer Buffer)
  {
    DxVertexBuffer DxBuffer = cast(DxVertexBuffer)Buffer;
    DeviceState.ImmediateContext.IASetVertexBuffers(0, 1, &DxBuffer.VertexBuffer, &DxBuffer.Stride, &DxBuffer.Offset);
  }

  override void SetIndexBuffer(IRenderIndexBuffer Buffer)
  {
    DxIndexBuffer DxBuffer = cast(DxIndexBuffer)Buffer;
    DeviceState.ImmediateContext.IASetIndexBuffer(DxBuffer.IndexBuffer, DxBuffer.IndexFormat, DxBuffer.IndexOffset);
  }

  void SetPrimitiveTopology(RenderPrimitiveTopology Topology)
  {
    D3D_PRIMITIVE_TOPOLOGY DxTopology;
    final switch(Topology)
    {
      case RenderPrimitiveTopology.LineList:
        DxTopology = D3D11_PRIMITIVE_TOPOLOGY_LINELIST;
        break;
      case RenderPrimitiveTopology.TriangleList:
        DxTopology = D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST;
        break;
    }
    DeviceState.ImmediateContext.IASetPrimitiveTopology(DxTopology);
  }


  override IRenderMesh CreateRenderMesh(SubMesh Mesh)
  {
    DxRenderMesh RenderMesh = Allocator.New!DxRenderMesh();

    RenderMesh.VertexBuffer = cast(DxVertexBuffer)CreateVertexBuffer(Mesh.Vertices[]);
    RenderMesh.IndexBuffer = cast(DxIndexBuffer)CreateIndexBuffer(Mesh.Indices[]);

    return RenderMesh;
  }

  override void ReleaseRenderMesh(IRenderMesh Mesh)
  {
    DxRenderMesh DxMesh = cast(DxRenderMesh)Mesh;
    ReleaseVertexBuffer(DxMesh.VertexBuffer);
    ReleaseIndexBuffer(DxMesh.IndexBuffer);
    Allocator.Delete(DxMesh);
  }

  override void SetMesh(IRenderMesh Mesh)
  {
    DxRenderMesh DxMesh = cast(DxRenderMesh)Mesh;

    assert(DxMesh);

    SetVertexBuffer(DxMesh.VertexBuffer);
    SetPrimitiveTopology(RenderPrimitiveTopology.TriangleList);
    SetIndexBuffer(DxMesh.IndexBuffer);
  }

  override void ReleaseVertexShader(IShader Shader)
  {
    if (Shader)
    {
      Allocator.Delete(cast(DxVertexShader)Shader);
    }
  }

  override void ReleasePixelShader(IShader Shader)
  {
    if (Shader)
    {
      Allocator.Delete(cast(DxPixelShader)Shader);
    }
  }

  override void SetInputLayout(IRenderInputLayout Layout)
  {
    DeviceState.ImmediateContext.IASetInputLayout((cast(DxInputLayout)Layout).InputLayout);
  }

  override void ClearRenderTarget(Vector4 Color)
  {
    DeviceState.ImmediateContext.ClearRenderTargetView(DeviceState.RenderTargetView, Color.Data);
    DeviceState.ImmediateContext.ClearDepthStencilView(DepthStencilBuffer.View, D3D11_CLEAR_DEPTH | D3D11_CLEAR_STENCIL, 1.0f, 0);
  }

  override void SetVertexShader(IShader Shader)
  {
    DeviceState.ImmediateContext.VSSetShader((cast(DxVertexShader)Shader).VertexShader, null, 0);
  }

  override void SetPixelShader(IShader Shader)
  {
    DeviceState.ImmediateContext.PSSetShader((cast(DxPixelShader)Shader).PixelShader, null, 0);
  }

  override void Draw(uint VertexCount, uint Offset = 0)
  {
    DeviceState.ImmediateContext.Draw(VertexCount, Offset);
  }

  override void DrawIndexed(uint VertexCount, uint IndexOffset = 0, uint VertexOffset = 0)
  {
    DeviceState.ImmediateContext.DrawIndexed(VertexCount, IndexOffset, VertexOffset);
  }

  override void Present()
  {
    DeviceState.SwapChain.Present(Description.EnableVSync ? 1 : 0, 0);
  }

  override bool InitDevice(RenderDeviceCreationDescription Description)
  {
    this.Description = Description;
    version(DXGI_RuntimeLinking)  LoadDXGI();

    LoadD3D11();
    LoadD3D11ShaderCompiler();
    HRESULT Result;

    RECT ClientRect;
    GetClientRect(DeviceState.WindowHandle, &ClientRect);
    auto WindowWidth = ClientRect.right - ClientRect.left;
    auto WindowHeight = ClientRect.bottom - ClientRect.top;

    UINT CreateDeviceFlags = 0;
    debug CreateDeviceFlags |= D3D11_CREATE_DEVICE_DEBUG;

    D3D_DRIVER_TYPE[3] DriverTypes =
    [
      D3D_DRIVER_TYPE_HARDWARE,
      D3D_DRIVER_TYPE_WARP,
      D3D_DRIVER_TYPE_REFERENCE,
    ];

    D3D_FEATURE_LEVEL[4] FeatureLevels =
    [
      D3D_FEATURE_LEVEL_11_1,
      D3D_FEATURE_LEVEL_11_0,
      D3D_FEATURE_LEVEL_10_1,
      D3D_FEATURE_LEVEL_10_0,
    ];

    foreach(DriverType; DriverTypes)
    {
      Result = D3D11CreateDevice(null, DriverType, null, CreateDeviceFlags,
                                 FeatureLevels.ptr, cast(UINT)FeatureLevels.length,
                                 D3D11_SDK_VERSION,
                                 &DeviceState.Device, &DeviceState.FeatureLevel, &DeviceState.ImmediateContext);
      if(Result == E_INVALIDARG)
      {
        // DirectX 11.0 platforms will not recognize D3D_FEATURE_LEVEL_11_1 so
        // we need to retry without it.
        auto TrimmedFeatureLevels = FeatureLevels[1 .. $];
        Result = D3D11CreateDevice(null, DriverType, null, CreateDeviceFlags,
                                   TrimmedFeatureLevels.ptr, cast(UINT)TrimmedFeatureLevels.length,
                                   D3D11_SDK_VERSION,
                                   &DeviceState.Device, &DeviceState.FeatureLevel, &DeviceState.ImmediateContext);
      }

      if(SUCCEEDED(Result))
        break;
    }

    if(FAILED(Result))
      return false;

    debug
    {
      DeviceState.Device.QueryInterface(uuidof!ID3D11Debug, cast(void**)&DeviceState.DebugDevice);
    }

    // Obtain DXGI factory from device.
    IDXGIFactory1 DXGIFactory;
    scope(exit) if(DXGIFactory) DXGIFactory.Release();
    {
      IDXGIDevice DXGIDevice;
      scope(exit) if(DXGIDevice) DXGIDevice.Release();
      Result = DeviceState.Device.QueryInterface(uuidof!IDXGIDevice, cast(void**)&DXGIDevice);
      if(SUCCEEDED(Result))
      {

        IDXGIAdapter Adapter;
        scope(exit) if(Adapter) Adapter.Release();
        DXGIDevice.GetAdapter(&Adapter);
        if(SUCCEEDED(Result))
        {

          Result = Adapter.GetParent(uuidof!IDXGIFactory1, cast(void**)&DXGIFactory);
        }
      }
    }
    if(FAILED(Result))
      return false;

    IDXGIFactory2 DXGIFactory2;
    scope(exit) if(DXGIFactory2) DXGIFactory2.Release();
    Result = DXGIFactory.QueryInterface(uuidof!IDXGIFactory2, cast(void**)&DXGIFactory2);
    if(DXGIFactory2)
    {

      Result = DeviceState.Device.QueryInterface(uuidof!ID3D11Device1, cast(void**)&DeviceState.Device1);
      if(SUCCEEDED(Result))
      {
        DeviceState.ImmediateContext.QueryInterface(uuidof!ID3D11DeviceContext1, cast(void**)&DeviceState.ImmediateContext1);
      }

      DXGI_SWAP_CHAIN_DESC1 SwapChainDesc;
      with(SwapChainDesc)
      {
        Width = WindowWidth;
        Height = WindowHeight;
        Format = DXGI_FORMAT_R8G8B8A8_UNORM;
        SampleDesc.Count = 1;
        SampleDesc.Quality = 0;
        BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
        BufferCount = 1;

        Result = DXGIFactory2.CreateSwapChainForHwnd(DeviceState.Device, DeviceState.WindowHandle, &SwapChainDesc, null, null, &DeviceState.SwapChain1);
        if(SUCCEEDED(Result))
        {
          Result = DeviceState.SwapChain1.QueryInterface(uuidof!IDXGISwapChain, cast(void**)&DeviceState.SwapChain);
        }
      }
    }
    else
    {
      // DirectX 11.0 systems
      DXGI_SWAP_CHAIN_DESC SwapChainDesc;
      with(SwapChainDesc)
      {
        BufferCount = 1;
        BufferDesc.Width = WindowWidth;
        BufferDesc.Height = WindowHeight;
        BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
        BufferDesc.RefreshRate.Numerator = 60;
        BufferDesc.RefreshRate.Denominator = 1;
        BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
        OutputWindow = DeviceState.WindowHandle;
        SampleDesc.Count = 1;
        SampleDesc.Quality = 0;
        Windowed = TRUE;
      }

      Result = DXGIFactory.CreateSwapChain(DeviceState.Device, &SwapChainDesc, &DeviceState.SwapChain);
    }

    DXGIFactory.MakeWindowAssociation(DeviceState.WindowHandle, DXGI_MWA_NO_ALT_ENTER);

    if(FAILED(Result)) return false;

    ID3D11Texture2D BackBuffer;
    scope(exit) if(BackBuffer) BackBuffer.Release();
    Result = DeviceState.SwapChain.GetBuffer(0, uuidof!ID3D11Texture2D, cast(void**)&BackBuffer);
    if(FAILED(Result)) return false;

    DeviceState.Device.CreateRenderTargetView(BackBuffer, null, &DeviceState.RenderTargetView);

    if(FAILED(Result)) return false;

    DepthStencilBuffer = cast(DxDepthStencilBuffer)CreateDepthStencilBuffer(Description.DepthStencilDescription);

    DeviceState.ImmediateContext.OMSetDepthStencilState(DepthStencilBuffer.State, 1);
    DeviceState.ImmediateContext.OMSetRenderTargets(1, &DeviceState.RenderTargetView, DepthStencilBuffer.View);

    D3D11_VIEWPORT ViewPort;
    with(ViewPort)
    {
      TopLeftX = 0.0f;
      TopLeftY = 0.0f;
      Width = cast(FLOAT)WindowWidth;
      Height = cast(FLOAT)WindowHeight;
      MinDepth = 0.0f;
      MaxDepth = 1.0f;
    }

    DeviceState.ImmediateContext.RSSetViewports(1, &ViewPort);

    return true;
  }

}
