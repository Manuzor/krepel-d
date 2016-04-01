module krepel.resources.resource_loader;

import krepel.resources.resource_manager;
import krepel.resources.resource;
import krepel.system;
import krepel.memory;
import krepel.string;

interface IResourceLoader
{
  Resource Load(IAllocator Allocator, WString FileName, IFile Data);
  void Destroy(IAllocator Allocator, Resource Resource);
}
