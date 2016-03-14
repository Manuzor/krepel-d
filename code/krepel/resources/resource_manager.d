module krepel.resources.manager;

import krepel.resources.loader;
import krepel.container;
import krepel.memory;
import krepel.string;

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

  IAllocator Allocator;
}
