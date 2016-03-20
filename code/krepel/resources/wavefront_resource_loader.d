module krepel.resources.wavefront_resource_loader;

import krepel.resources;
import krepel.system;
import krepel.memory;
import krepel.math;
import krepel.container;
import krepel.conversion;

@nogc:
nothrow:

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
  EOF,
}

struct WaveFrontVertexDefinition
{
  int VertexIndex = -1;
  int NormalIndex = -1;
  int TextureIndex = -1;
}

struct WaveFrontFaceDefinition
{
  WaveFrontVertexDefinition[3] Vertices;
}

struct WavefrontLexer
{
  @nogc:
  nothrow:

  void Initialize(IAllocator Allocator, IFile File)
  {
    this.Allocator = Allocator;
    CurrentLineType = WavefrontLineType.Unknown;
    this.File = File;
  }

  WavefrontLineType IdentifyValidLine(typeof(Buffer) Buffer)
  {
    if (Buffer.Count > 0)
    {
      switch (Buffer[0])
      {
      case 'v':
        if (Buffer.Count > 1)
        {
          switch(Buffer[1])
          {
          case 't':
            return WavefrontLineType.TextureCoordinate;
          case 'n':
            return WavefrontLineType.Normal;
          case 'p':
            return WavefrontLineType.ParameterSpace;
          case ' ':
            return WavefrontLineType.Vertex;
          default:
            return WavefrontLineType.Unknown;
          }

        }
        else
        {
          return WavefrontLineType.Empty;
        }
      case 'f':
        return WavefrontLineType.Face;
      case '#':
        return WavefrontLineType.Comment;
      default:
        return WavefrontLineType.Unknown;
      }
    }
    else
    {
      return WavefrontLineType.EOF;
    }
  }

  bool ProcessLine()
  {
    Buffer.Clear();
    File.ReadLine(Buffer);
    CurrentLineType = IdentifyValidLine(Buffer);
    return Buffer.Count > 0;
  }

  bool ParseVector3(out Vector3 Vector)
  {
    import std.conv;
    assert(CurrentLineType == WavefrontLineType.Vertex);
    auto ToParse = Buffer[2..$];
    Vector.X = ParseFloat(ToParse);
    Vector.Y = ParseFloat(ToParse);
    Vector.Z = ParseFloat(ToParse);
    return true;
  }

  bool ParseVector2(out Vector2 TextureCoordinate)
  {
    import std.conv;
    assert(CurrentLineType == WavefrontLineType.TextureCoordinate);
    auto ToParse = Buffer[3..$];
    TextureCoordinate.X = ParseFloat(ToParse);
    TextureCoordinate.Y = ParseFloat(ToParse);
    return true;
  }

  Array!char Buffer;
  IAllocator Allocator;
  IFile File;
  WavefrontLineType CurrentLineType;
}

class WavefrontResourceLoader : IResourceLoader
{
  override IResource Load(IAllocator Allocator, IFile File)
  {
    MeshResource Mesh = Allocator.New!(MeshResource,IAllocator)(Allocator);

    return Mesh;
  }
}
