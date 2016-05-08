module krepel.forward_renderer.forward_renderer;

import krepel;
import krepel.scene;
import krepel.render_device;
import krepel.resources;

struct RenderSubMeshResource
{
  PrimitiveRenderComponent Component;
  SubMesh Mesh;
}

struct RenderMeshResources
{
  IShader PixelShader;
  IShader VertexShader;
  IRenderMesh Mesh;
  IRenderConstantBuffer[16] ConstantBuffer;
  WorldConstantBuffer CurrentWorldConstantBufferContent;
}

struct WorldConstantBuffer
{
  Matrix4 ModelMatrix;
  Matrix4 ModelViewProjectionMatrix;
}


//TODO(Marvin): Rendering components should register somehow
// to the renderer so here we don't have to traverse the
// whole graph to collect the rendering components
class ForwardRenderer
{
  Array!SceneGraph RegisteredSceneGraphs;
  IRenderDevice RenderDevice;
  RenderMeshResources ActiveResources; //Used to avoid unnessecary calls to render API
  Dictionary!(SubMesh, IRenderMesh) MeshGraphicResources;
  Dictionary!(RenderSubMeshResource, RenderMeshResources) RenderResources;
  IAllocator Allocator;
  Array!IRenderConstantBuffer RegisteredConstantBuffers;

  IShader DefaultVertexShader;
  IShader DefaultPixelShader;
  IRenderInputLayout DefaultInputLayout;
  IRenderInputLayoutDescription DefaultInputLayoutDescription;
  IRenderRasterizerState DefaultRasterizerState;
  CameraComponent ActiveCamera;

  this(IAllocator Allocator)
  {
    this.Allocator = Allocator;
    MeshGraphicResources.Allocator = Allocator;
    RenderResources.Allocator = Allocator;
    RegisteredSceneGraphs.Allocator = Allocator;
    RegisteredConstantBuffers.Allocator = Allocator;
  }

  ~this()
  {
    RenderDevice.ReleaseVertexShader(DefaultVertexShader);
    RenderDevice.ReleasePixelShader(DefaultPixelShader);
    RenderDevice.DestroyInputLayoutDescription(DefaultInputLayoutDescription);
    RenderDevice.DestroyInputLayout(DefaultInputLayout);
    RenderDevice.ReleaseRasterizerState(DefaultRasterizerState);
    foreach(ConstantBuffer ; RegisteredConstantBuffers)
    {
      RenderDevice.ReleaseConstantBuffer(ConstantBuffer);
    }
  }

  void Initialize(IRenderDevice Device)
  {
    RenderDevice = Device;

    DefaultVertexShader = Device.LoadVertexShader(WString("../data/shader/first.hlsl", Allocator),
                                                    UString("VSMain", Allocator),
                                                    UString("vs_5_0", Allocator));

    RenderInputLayoutDescription[5] Layout =
    [
      RenderInputLayoutDescription(UString("POSITION", Allocator), 0, InputDescriptionDataType.Float, 3, true),
      RenderInputLayoutDescription(UString("UV", Allocator), 0, InputDescriptionDataType.Float, 2, true),
      RenderInputLayoutDescription(UString("NORMAL", Allocator), 0, InputDescriptionDataType.Float, 3, true),
      RenderInputLayoutDescription(UString("TANGENT", Allocator), 0, InputDescriptionDataType.Float, 4, true),
      RenderInputLayoutDescription(UString("BINORMAL", Allocator), 0, InputDescriptionDataType.Float, 3, true),
    ];
    DefaultInputLayoutDescription = RenderDevice.CreateInputLayoutDescription(Layout);

    DefaultInputLayout = RenderDevice.CreateVertexShaderInputLayoutFromDescription(DefaultVertexShader, DefaultInputLayoutDescription);


    RenderRasterizerDescription RasterDescription;
    DefaultRasterizerState = RenderDevice.CreateRasterizerState(RasterDescription);


    DefaultPixelShader = RenderDevice.LoadPixelShader(WString("../data/shader/first.hlsl", Allocator),
                                              UString("PSMain", Allocator),
                                              UString("ps_5_0", Allocator));


    SetDefaultState();
  }

  void SetDefaultState()
  {
    with(RenderDevice)
    {
      SetInputLayout(DefaultInputLayout);
      SetRasterizerState(DefaultRasterizerState);
    }
    SetActiveVertexShader(DefaultVertexShader);
    SetActivePixelShader(DefaultPixelShader);
  }

  void SetActiveVertexShader(IShader Shader)
  {
    if(ActiveResources.VertexShader != Shader)
    {
      RenderDevice.SetVertexShader(Shader);
      ActiveResources.VertexShader = Shader;
    }
  }

  void SetActiveMesh(IRenderMesh Mesh)
  {
    if(ActiveResources.Mesh != Mesh)
    {
      RenderDevice.SetMesh(Mesh);
      ActiveResources.Mesh = Mesh;
    }
  }

  void SetActivePixelShader(IShader Shader)
  {
    if(ActiveResources.PixelShader != Shader)
    {
      RenderDevice.SetPixelShader(Shader);
      ActiveResources.PixelShader = Shader;
    }
  }

  void SetActiveConstantBuffer(IRenderConstantBuffer Buffer, uint Index)
  {
    if(ActiveResources.ConstantBuffer[Index] != Buffer)
    {
      RenderDevice.SetVertexShaderConstantBuffer(Buffer, Index);
      ActiveResources.ConstantBuffer[Index] = Buffer;
    }
  }

  Matrix4 GetViewProjectionMatrix()
  {
    if(ActiveCamera !is null)
    {
      return ActiveCamera.GetViewProjectionMatrix();
    }
    else
    {
      return Matrix4.Identity;
    }
  }

  //TODO(Marvin): This does not handle post-register-creation of render components (aka dynamic creation)
  void RegisterScene(SceneGraph Graph)
  {
    RegisteredSceneGraphs ~= Graph;
    foreach(GameObject ; Graph.GetGameObjects)
    {
      RegisterGameObject(GameObject);
    }
  }

  private void RegisterGameObject(GameObject GameObj)
  {
    foreach(Component ; GameObj.Components)
    {
      auto RenderComponent = cast(PrimitiveRenderComponent)(Component);
      if(RenderComponent !is null && RenderComponent.GetMesh !is null)
      {
        foreach(SubMesh ; RenderComponent.GetMesh.Meshes)
        {
          IRenderMesh* RegisteredMesh = MeshGraphicResources.Get(SubMesh);
          IRenderMesh MeshGraphic = null;
          if (RegisteredMesh !is null)
          {
            MeshGraphic = *RegisteredMesh;
          }
          if(MeshGraphic is null)
          {
            MeshGraphic = RenderDevice.CreateRenderMesh(SubMesh);
            MeshGraphicResources[SubMesh] = MeshGraphic;
          }
          assert(MeshGraphic !is null);
          auto Id = RenderSubMeshResource(RenderComponent, SubMesh);
          RenderMeshResources Resources;
          Resources.VertexShader = DefaultVertexShader;
          Resources.PixelShader = DefaultPixelShader;
          WorldConstantBuffer Buffer;
          Buffer.ModelMatrix = RenderComponent.GetWorldTransform().ToMatrix();
          Buffer.ModelViewProjectionMatrix =
            RenderComponent.GetWorldTransform().ToMatrix() * GetViewProjectionMatrix();
          Resources.ConstantBuffer[0] = RenderDevice.CreateConstantBuffer(Buffer.AsVoidRange);
          Resources.Mesh = MeshGraphic;
          RenderResources[Id] = Resources;
        }
      }
    }
  }

  private void RenderScene(SceneGraph Graph)
  {

  }
}