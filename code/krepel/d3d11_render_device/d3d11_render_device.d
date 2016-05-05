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

  ~this()
  {
    if(Device) ReleaseAndNullify(Device);
    if(Device1) ReleaseAndNullify(Device1);
    if(ImmediateContext) ReleaseAndNullify(ImmediateContext);
    if(ImmediateContext1) ReleaseAndNullify(ImmediateContext1);
    if(SwapChain) ReleaseAndNullify(SwapChain);
    if(SwapChain1) ReleaseAndNullify(SwapChain1);
    if(RenderTargetView) ReleaseAndNullify(RenderTargetView);
  }
}

void ReleaseAndNullify(Type)(Type Instance)
  if(__traits(compiles, { Instance.Release(); Instance = null; }))
{
  Instance.Release();
  Instance = null;
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

class DxConstantBuffer : IConstantBuffer
{
  ID3D11Buffer ConstantBuffer;

  ~this()
  {
    ReleaseAndNullify(ConstantBuffer);
  }
}

class DxShader : IShader
{
  ARC!DxShaderCode Code;
}

class DxRenderMesh : IRenderMesh
{
  ID3D11Buffer VertexBuffer;
  ID3D11Buffer IndexBuffer;
  uint Stride;
  uint Offset;
  uint IndexCount;
  uint IndexOffset;
  DXGI_FORMAT IndexFormat;

  override uint GetIndexCount()
  {
    return IndexCount;
  }

  ~this()
  {
    ReleaseAndNullify(VertexBuffer);
    ReleaseAndNullify(IndexBuffer);
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
  IAllocator Allocator;
  this(IAllocator Allocator)
  {
    this.Allocator = Allocator;

    DeviceState = Allocator.New!DxState();
    DeviceState.Allocator = Allocator;
  }

  IShader LoadVertexShader(WString FileName, UString EntryPoint, UString Profile)
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

  IRenderInputLayoutDescription CreateInputLayoutDescription(RenderInputLayoutDescription[] Descriptions)
  {
    DxInputLayoutDescription Description = Allocator.New!DxInputLayoutDescription(Allocator);
    Description.SetDescription(Descriptions);

    return Description;
  }

  void DestroyInputLayoutDescription(IRenderInputLayoutDescription Description)
  {
    Allocator.Delete(cast(DxInputLayoutDescription)Description);
  }

  IRenderInputLayout CreateVertexShaderInputLayoutFromDescription(IShader Shader, IRenderInputLayoutDescription Description)
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

  void DestroyInputLayout(IRenderInputLayout Layout)
  {
    Allocator.Delete(cast(DxInputLayout)Layout);
  }

  IShader LoadPixelShader(WString FileName, UString EntryPoint, UString Profile)
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

  IConstantBuffer CreateConstantBuffer(void[] Data)
  {
    auto ConstantBuffer = Allocator.New!DxConstantBuffer();
    D3D11_BUFFER_DESC Description;
    with(Description)
    {
      ByteWidth = cast(uint)Data.length;
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

  void SetVertexShaderConstantBuffer(IConstantBuffer Buffer, uint Index)
  {
    DxConstantBuffer ConstantBuffer = cast(DxConstantBuffer)Buffer;
    DeviceState.ImmediateContext.VSSetConstantBuffers(Index, 1, &ConstantBuffer.ConstantBuffer);
  }

  void ReleaseConstantBuffer(IConstantBuffer Buffer)
  {
    DxConstantBuffer ConstantBuffer = cast(DxConstantBuffer)Buffer;
    Allocator.Delete(ConstantBuffer);
  }

  IRenderMesh CreateRenderMesh(SubMesh Mesh)
  {
    DxRenderMesh RenderMesh = Allocator.New!DxRenderMesh();

    D3D11_BUFFER_DESC BufferDesc;
    with(BufferDesc)
    {
      Usage = D3D11_USAGE_DEFAULT;
      ByteWidth = cast(UINT)Mesh.Vertices[].ByteCount;
      BindFlags = D3D11_BIND_VERTEX_BUFFER;
      CPUAccessFlags = 0;
    }
    D3D11_SUBRESOURCE_DATA InitData;
    InitData.pSysMem = Mesh.Vertices.Data.ptr;


    if(FAILED(DeviceState.Device.CreateBuffer(&BufferDesc, &InitData, &RenderMesh.VertexBuffer)))
    {
      Log.Failure("Failed to create vertex buffer.");
    }

    BufferDesc.ByteWidth = cast(UINT)Mesh.Indices[].ByteCount;
    BufferDesc.BindFlags = D3D11_BIND_INDEX_BUFFER;

    InitData.pSysMem = Mesh.Indices.Data.ptr;

    if(FAILED(DeviceState.Device.CreateBuffer(&BufferDesc, &InitData, &RenderMesh.IndexBuffer)))
    {
      Log.Failure("Failed to create vertex buffer.");
    }

    RenderMesh.Stride = Vertex.sizeof;
    RenderMesh.Offset = 0;
    RenderMesh.IndexCount = cast(uint)Mesh.Indices.Count;
    RenderMesh.IndexOffset = 0;
    RenderMesh.IndexFormat = DXGI_FORMAT_R32_UINT;

    return RenderMesh;
  }

  void ReleaseRenderMesh(IRenderMesh Mesh)
  {
    DxRenderMesh DxMesh = cast(DxRenderMesh)Mesh;
    Allocator.Delete(DxMesh);
  }

  void SetMesh(IRenderMesh Mesh)
  {
    DxRenderMesh DxMesh = cast(DxRenderMesh)Mesh;

    assert(DxMesh);

    DeviceState.ImmediateContext.IASetVertexBuffers(0, 1, &DxMesh.VertexBuffer, &DxMesh.Stride, &DxMesh.Offset);
    DeviceState.ImmediateContext.IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
    DeviceState.ImmediateContext.IASetIndexBuffer(DxMesh.IndexBuffer, DxMesh.IndexFormat, DxMesh.IndexOffset);
  }

  void ReleaseVertexShader(IShader Shader)
  {
    if (Shader)
    {
      Allocator.Delete(cast(DxVertexShader)Shader);
    }
  }

  void ReleasePixelShader(IShader Shader)
  {
    if (Shader)
    {
      Allocator.Delete(cast(DxPixelShader)Shader);
    }
  }

  void SetInputLayout(IRenderInputLayout Layout)
  {
    DeviceState.ImmediateContext.IASetInputLayout((cast(DxInputLayout)Layout).InputLayout);
  }

  void ClearRenderTarget(Vector4 Color)
  {
    DeviceState.ImmediateContext.ClearRenderTargetView(DeviceState.RenderTargetView, Color.Data);
  }

  void SetVertexShader(IShader Shader)
  {
    DeviceState.ImmediateContext.VSSetShader((cast(DxVertexShader)Shader).VertexShader, null, 0);
  }

  void SetPixelShader(IShader Shader)
  {
    DeviceState.ImmediateContext.PSSetShader((cast(DxPixelShader)Shader).PixelShader, null, 0);
  }

  void Draw(uint VertexCount, uint Offset = 0)
  {
    DeviceState.ImmediateContext.Draw(VertexCount, Offset);
  }

  void DrawIndexed(uint VertexCount, uint IndexOffset = 0, uint VertexOffset = 0)
  {
    DeviceState.ImmediateContext.DrawIndexed(VertexCount, IndexOffset, VertexOffset);
  }

  void Present()
  {
    DeviceState.SwapChain.Present(0, 0);
  }

  bool InitDevice()
  {
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

    DeviceState.ImmediateContext.OMSetRenderTargets(1, &DeviceState.RenderTargetView, null);

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
