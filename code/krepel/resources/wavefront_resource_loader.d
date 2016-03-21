module krepel.resources.wavefront_resource_loader;

import krepel.resources;
import krepel.system;
import krepel.memory;
import krepel.math;
import krepel.container;
import krepel.conversion;
import krepel.string;
import krepel.log;

enum WavefrontLineType : string
{
  Unknown = "Unknown",
  Empty = "Empty",
  Comment = "Comment",
  Vertex = "Vertex",
  TextureCoordinate = "TextureCoordinate",
  Normal = "Normal",
  Face = "Face",
  ParameterSpace = "ParameterSpace",
  Object = "Object",
  SmoothingGroup = "SmoothingGroup",
  EOF = "EOF",
}

struct WaveFrontMesh
{

  Array!Vector3 Vertices;
  Array!Vector3 Normals;
  Array!Vector2 TextureCoordinates;
  Array!WaveFrontFaceDefinition Faces;

  this(IAllocator Allocator)
  {
    Vertices = Array!Vector3(Allocator);
    Normals = Array!Vector3(Allocator);
    TextureCoordinates = Array!Vector2(Allocator);
    Faces = Array!WaveFrontFaceDefinition(Allocator);
  }
}

struct WaveFrontVertexDefinition
{
  long VertexIndex = -1;
  long NormalIndex = -1;
  long TextureIndex = -1;
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
      case 'o':
        return WavefrontLineType.Object;
      case 's':
        return WavefrontLineType.SmoothingGroup;
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


  bool ParseVertexDefinition(out WaveFrontVertexDefinition VertexDefinition, ref char[] Range)
  {
    assert(CurrentLineType == WavefrontLineType.Face);
    VertexDefinition.VertexIndex = ParseLong(Range, 0);
    if (Find(Range, "/") == 0)
    {
      auto FindResult = Find(Range, "/", 1);
      if (FindResult != 1)
      {
        Range = Range[1..$];
        VertexDefinition.NormalIndex = ParseLong(Range, 0);

        FindResult = Find(Range, "/", 0);
        if (FindResult == 0)
        {
          Range = Range[1..$];
          VertexDefinition.TextureIndex = ParseLong(Range, 0);
        }
      }
      else if(FindResult == 1)
      {
        Range = Range[2..$];
        VertexDefinition.TextureIndex = ParseLong(Range, 0);
      }
    }
    return true;
  }

  bool ParseFace(out WaveFrontFaceDefinition Face)
  {
    assert(CurrentLineType == WavefrontLineType.Face);
    auto ToParse = Buffer[2..$];
    ParseVertexDefinition(Face.Vertices[0], ToParse);
    ParseVertexDefinition(Face.Vertices[1], ToParse);
    ParseVertexDefinition(Face.Vertices[2], ToParse);
    return true;
  }

  bool ParseVector3(out Vector3 Vector)
  {
    assert(CurrentLineType == WavefrontLineType.Vertex || CurrentLineType == WavefrontLineType.Normal);
    auto ToParse = Buffer[2..$];
    Vector.X = ParseFloat(ToParse);
    Vector.Y = ParseFloat(ToParse);
    Vector.Z = ParseFloat(ToParse);
    return true;
  }

  bool ParseVector2(out Vector2 TextureCoordinate)
  {
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
  WaveFrontMesh TempMesh;

  override IResource Load(IAllocator Allocator, IFile File)
  {
    MeshResource Mesh = Allocator.New!(MeshResource,IAllocator)(Allocator);
    TempMesh = WaveFrontMesh(Allocator);

    Lexer.Initialize(Allocator, File);

    while(Lexer.ProcessLine())
    {
      Log.Info(UString("Line: ") + Lexer.CurrentLineType);
      final switch(Lexer.CurrentLineType)
      {
      case WavefrontLineType.Unknown:
      case WavefrontLineType.Comment:
      case WavefrontLineType.Empty:
      case WavefrontLineType.SmoothingGroup:
      case WavefrontLineType.EOF:
      case WavefrontLineType.ParameterSpace:
        break;
      case WavefrontLineType.Vertex:
        Vector3 Vertex;
        Lexer.ParseVector3(Vertex);
        TempMesh.Vertices.PushBack(Vertex);
        break;
      case WavefrontLineType.TextureCoordinate:
        Vector2 Coordinate;
        Lexer.ParseVector2(Coordinate);
        TempMesh.TextureCoordinates.PushBack(Coordinate);
        break;
      case WavefrontLineType.Face:
        WaveFrontFaceDefinition Face;
        Lexer.ParseFace(Face);
        TempMesh.Faces.PushBack(Face);
        break;
      case WavefrontLineType.Normal:
        Vector3 Normal;
        Lexer.ParseVector3(Normal);
        TempMesh.Normals.PushBack(Normal);
        break;
      case WavefrontLineType.Object:
        break;
      }
    }

    return Mesh;
  }

  WavefrontLexer Lexer;
}

unittest
{
  import krepel.log;
  import krepel;
  import krepel.memory;
  import krepel.string;

  StaticStackMemory!50000 StackMemory;
  GlobalAllocator = StackMemory.Wrap;

  Log.Sinks.PushBack(ToDelegate(&StdoutLogSink));

  auto Manager = GlobalAllocator.New!ResourceManager(GlobalAllocator);
  auto WaveFrontLoader = GlobalAllocator.New!WavefrontResourceLoader();
  Manager.RegisterLoader(WaveFrontLoader, WString(".obj"));

  auto Result = Manager.LoadResource(WString("../unittest/Cube.obj"));
}
