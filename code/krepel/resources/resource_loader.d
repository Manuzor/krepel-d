module krepel.resources.resource_loader;

import krepel.resources.resource_manager;
import krepel.system;
import krepel.memory;

interface IResourceLoader
{
  IResource Load(IAllocator Allocator, IFile Data);
}
