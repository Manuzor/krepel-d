module krepel.resources.resource_manager;

import krepel.resources.resource_loader;
import krepel.container;
import krepel.memory;
import krepel.string;
import krepel.system;

@nogc:

interface IResource
{

}

class ResourceManager
{
  this(IAllocator Allocator)
  {
    this.Allocator = Allocator;
  }


  Dictionary!(String, IResourceLoader) ResourceLoader;

  void RegisterLoader(IResourceLoader Loader, String FileExtension)
  {
    assert(!ResourceLoader.Contains(FileExtension));
    ResourceLoader[FileExtension] = Loader;
  }

  IResource LoadResource(String FileName)
  {
    auto FileExtensionIndex = FileName.FindLast(".");
    if (FileExtensionIndex >= 0)
    {
      IResourceLoader Loader;
      if (ResourceLoader.TryGet(FileName[FileExtensionIndex .. $], Loader))
      {
        auto File = OpenFile(Allocator, FileName, FileOpenMode.Read);
        auto Resource = Loader.Load(Allocator, File);
        CloseFile(Allocator, File);
        return Resource;
      }
    }

    return null;
  }

  IAllocator Allocator;
}