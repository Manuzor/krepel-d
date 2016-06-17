module krepel.resources.material_resource_loader;

import krepel;
import krepel.resources;
import krepel.serialization.sdlang;
import krepel.system;
import krepel.conversion;

class MaterialResourceLoader : IResourceLoader
{
  void LoadSubMaterialAPI(SubMaterial Material, SDLNodeHandle Node, UString APIName, IAllocator Allocator)
  {
    auto Definitions = Array!ShaderDefinition(Allocator);
    foreach(DefinitionNode; SDLNodeIterator(Node.FirstChild))
    {
      ShaderDefinition Definition;
      if(DefinitionNode.Name == "Vertex")
      {
        Definition.Type = ShaderType.VertexShader;
      }
      else if(DefinitionNode.Name == "Pixel")
      {
        Definition.Type = ShaderType.PixelShader;
      }
      else if(DefinitionNode.Name == "Compute")
      {
        Definition.Type = ShaderType.ComputeShader;
      }
      else if(DefinitionNode.Name == "Tesselation")
      {
        Definition.Type = ShaderType.TesselationShader;
      }
      else if(DefinitionNode.Name == "Geometry")
      {
        Definition.Type = ShaderType.GeometryShader;
      }
      auto File = DefinitionNode.Nodes["File"][0];
      if (File.IsValidHandle)
      {
        Definition.ShaderFile = UString(File.Values[0].String, Allocator);
      }
      else
      {
        Log.Warning("Shader Type '%s' is missing ShaderFile in Shader %s", APIName, DefinitionNode.Name);
      }
      Definitions ~= Definition;
    }
  }

  void LoadSubMaterial(MaterialResource Resource, SDLNodeHandle Node, UString Name, IAllocator Allocator)
  {
    SubMaterial NewSubMaterial = Allocator.New!SubMaterial(Allocator);
    NewSubMaterial.Name = Name;
    foreach(APINode; SDLNodeIterator(Node.FirstChild))
    {
      LoadSubMaterialAPI(NewSubMaterial, APINode, UString(APINode.Name, Allocator), Allocator);
    }
    Resource.Materials ~= NewSubMaterial;
  }

  override Resource Load(IAllocator Allocator, WString FileName, IFile Data)
  {
    auto Context = SDLParsingContext(FileName.ToUTF8(), .Log);
    auto Document = Allocator.New!SDLDocument(Allocator);
    scope(exit) Allocator.Delete(Document);

    auto SourceString = Allocator.NewArray!char(Data.Size);
    scope(exit) Allocator.DeleteUndestructed(SourceString);
    auto BytesRead = Data.Read(SourceString);
    assert(BytesRead == SourceString.length);
    assert(Document.ParseDocumentFromString(cast(string)SourceString, Context), SourceString);
    MaterialResource NewMaterial = Allocator.New!MaterialResource(Allocator, this, FileName);
    auto Node = Document.Root.FirstChild;
    while(Node.IsValidHandle)
    {
      LoadSubMaterial(NewMaterial, Node, UString(Node.Name, Allocator), Allocator);
      Node = Node.Next;
    }
    return NewMaterial;
  }

  override void Destroy(IAllocator Allocator, Resource Resource)
  {

  }
}

unittest
{
  auto TestAllocator = CreateTestAllocator();

  auto Manager = TestAllocator.New!ResourceManager(TestAllocator);
  auto MaterialLoader = TestAllocator.New!MaterialResourceLoader();
  Manager.RegisterLoader(MaterialLoader, WString(".mat", TestAllocator));

  auto Resource = Manager.Load!MaterialResource(WString("../unittest/Materials/testmaterial.mat", TestAllocator));
  assert(Resource !is null);
  assert(Resource.Materials.Count == 1);
}
