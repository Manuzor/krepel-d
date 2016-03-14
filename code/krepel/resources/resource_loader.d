module krepel.resources.loader;

import krepel.resources.manager;
import krepel.memory;

interface IResourceLoader
{
  IResource Load(MemoryRegion Data);
}
