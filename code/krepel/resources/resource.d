module krepel.resources.resource;

import krepel.resources;
import krepel.string;

class Resource
{
  this(IResourceLoader Loader, WString FileName)
  {
    this.Loader = Loader;
    this.FileName = FileName;
  }

  IResourceLoader Loader;
  WString FileName;
}
