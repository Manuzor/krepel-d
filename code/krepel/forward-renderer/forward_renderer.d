module krepel.forward_renderer.forward_renderer;

import krepel;
import krepel.scene;
import krepel.render_device;
import krepel.resources;
import krepel.color;

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
  PrimitiveRenderComponent Component;
  SubMesh RenderedSubMesh;
}

struct WorldConstantBuffer
{
  Matrix4 ModelMatrix;
  Matrix4 ModelViewProjectionMatrix;
  Vector4 LightDir = Vector4(0,0.7,0.7,0);
  ColorLinear Color = ColorLinear(0.5f, 0.5f, 0.5f,0);
  ColorLinear AmbientColor = ColorLinear(0.5f, 0.5f, 0.5f,0);
}

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
  Matrix4 ViewProjMatrix;

  Vector4 BackgroundColor = Vector4(100 / 255.0f, 149 / 255.0f, 237 / 255.0f, 1.0f);

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

  void RegisterScene(SceneGraph Graph)
  {
    RegisteredSceneGraphs ~= Graph;
    foreach(GameObject ; Graph.GetGameObjects)
    {
      RegisterGameObject(GameObject);
    }
    Graph.OnComponentRegistered.Add(&OnComponentRegistered);
  }

  void OnComponentRegistered(GameObject Obj, GameComponent Component)
  {
    auto RenderComponent = cast(PrimitiveRenderComponent)Component;
    if(RenderComponent !is null)
    {
      RegisterComponent(RenderComponent);
    }
  }

  private void RegisterGameObject(GameObject GameObj)
  {
    foreach(Component ; GameObj.Components)
    {
      auto RenderComponent = cast(PrimitiveRenderComponent)(Component);
      if(RenderComponent !is null)
      {
        RegisterComponent(RenderComponent);
      }
    }
  }

  private void RegisterComponent(PrimitiveRenderComponent RenderComponent)
  {
    if(RenderComponent.GetMesh !is null)
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
        Resources.Component = RenderComponent;
        Resources.RenderedSubMesh = SubMesh;
        RenderResources[Id] = Resources;
      }
    }
  }

  void Render()
  {
    RenderDevice.ClearRenderTarget(BackgroundColor);
    foreach(ref Command ; RenderResources.Values)
    {
      WorldConstantBuffer WorldData;
      WorldData.ModelMatrix = Command.Component.GetWorldTransform.ToMatrix;
      WorldData.ModelViewProjectionMatrix = WorldData.ModelMatrix * GetViewProjectionMatrix;
      WorldData.ModelMatrix = WorldData.ModelMatrix.GetTransposed;
      WorldData.ModelViewProjectionMatrix = WorldData.ModelViewProjectionMatrix.GetTransposed;
      RenderDevice.UpdateConstantBuffer(Command.ConstantBuffer[0], WorldData.AsVoidRange);
      SetActiveConstantBuffer(Command.ConstantBuffer[0], 0);
      SetActiveMesh(Command.Mesh);
      SetActiveVertexShader(Command.VertexShader);
      SetActivePixelShader(Command.PixelShader);
      RenderDevice.DrawIndexed(Command.Mesh.GetIndexCount);
    }

  }

  void Present()
  {
    RenderDevice.Present();
  }
}
