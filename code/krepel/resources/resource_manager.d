module krepel.resources.resource_manager;

import krepel.resources.resource;
import krepel.resources.resource_loader;
import krepel.resources.resource_mesh;
import krepel.container;
import krepel.memory;
import krepel.string;
import krepel.system;



class ResourceManager
{
  this(IAllocator Allocator)
  {
    this.Allocator = Allocator;
    ResourceLoader = Dictionary!(WString, IResourceLoader)(Allocator);
  }

  Dictionary!(WString, IResourceLoader) ResourceLoader;

  void RegisterLoader(IResourceLoader Loader, WString FileExtension)
  {
    assert(!ResourceLoader.Contains(FileExtension));
    ResourceLoader[FileExtension] = Loader;
  }

  Resource LoadResource(WString FileName)
  {
    auto FileExtensionIndex = FileName.FindLast(".");
    if (FileExtensionIndex >= 0)
    {
      IResourceLoader Loader;
      if (ResourceLoader.TryGet(FileName[FileExtensionIndex .. $], Loader))
      {
        auto File = OpenFile(Allocator, FileName, FileOpenMode.Read);
        auto Resource = Loader.Load(Allocator, FileName, File);
        CloseFile(Allocator, File);
        return Resource;
      }
    }

    return null;
  }

  void DestroyResource(Resource Resource)
  {
    if(Resource !is null)
    {
      Resource.Loader.Destroy(Allocator, Resource);
    }
  }

  ResourceType Load(ResourceType)(WString FileName)
    if(is(ResourceType : Resource))
  {
    auto Resource = LoadResource(FileName);
    ResourceType TargetResource = cast(ResourceType)Resource;
    if(TargetResource is null)
    {
      Resource.Loader.Destroy(Allocator, Resource);
    }
    return TargetResource;
  }

  MeshResource LoadMesh(WString FileName)
  {
    return Load!MeshResource(FileName);
  }

  IAllocator Allocator;
}
