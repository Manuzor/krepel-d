module krepel.resources.wavefront_resource_loader;

import krepel.resources;
import krepel.system;
import krepel.memory;

enum WavefrontLineType
{
  Unknown,
  Empty,
  Comment,
  Vertex,
  TextureCoordinate,
  Normal,
  Face,
  ParameterSpace,
}

struct WavefrontLexer
{
  void Initialize(IAllocator Allocator, IFile File)
  {
    this.Allocator = Allocator;
    CurrentLineType = WavefrontLineType.Unknown;
    this.File = File;
  }

  WavefrontLineType FindAndIdentifyValidLine()
  {
    return WavefrontLineType.Unknown;
  }

  bool FindLineStart()
  {
    return false;
  }

  IAllocator Allocator;
  IFile File;
  WavefrontLineType CurrentLineType;
}

class WavefrontResourceLoader : IResourceLoader
{
  override IResource Load(IAllocator Allocator, IFile File)
  {
    return null;
  }
}
