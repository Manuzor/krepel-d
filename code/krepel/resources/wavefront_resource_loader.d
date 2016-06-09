module krepel.resources.wavefront_resource_loader;

import krepel;
import krepel.conversion;
import krepel.system;
import krepel.resources;
import krepel.log;

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
  Object,
  SmoothingGroup,
  EOF,
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

  void Clear()
  {
    Vertices.Clear();
    Normals.Clear();
    TextureCoordinates.Clear();
    Faces.Clear();
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
  WaveFrontVertexDefinition[4] Vertices;
}

struct WavefrontLexer
{
  void Initialize(IAllocator Allocator, IFile File)
  {
    this.Allocator = Allocator;
    CurrentLineType = WavefrontLineType.Unknown;
    this.File = File;
    Buffer.Allocator = Allocator;
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
    VertexDefinition.VertexIndex = ParseInteger!long(Range, 0) - 1;
    if (Find(Range, "/") == 0)
    {
      auto FindResult = Find(Range, "/", 1);
      if (FindResult != 1)
      {
        Range = Range[1..$];
        VertexDefinition.TextureIndex = ParseInteger!long(Range, 0) - 1;

        FindResult = Find(Range, "/", 0);
        if (FindResult == 0)
        {
          Range = Range[1..$];
          VertexDefinition.NormalIndex = ParseInteger!long(Range, 0) - 1;
        }
      }
      else if(FindResult == 1)
      {
        Range = Range[2..$];
        VertexDefinition.NormalIndex = ParseInteger!long(Range, 0) - 1;
      }
    }
    return true;
  }

  bool ParseString(ref UString String)
  {
    assert(CurrentLineType == WavefrontLineType.Object);
    String = UString(TrimStart(Buffer[2..$]), Allocator);
    return true;
  }

  bool ParseFace(out WaveFrontFaceDefinition Face)
  {
    assert(CurrentLineType == WavefrontLineType.Face);
    auto ToParse = Buffer[2..$];
    ParseVertexDefinition(Face.Vertices[0], ToParse);
    ParseVertexDefinition(Face.Vertices[1], ToParse);
    ParseVertexDefinition(Face.Vertices[2], ToParse);
    ParseVertexDefinition(Face.Vertices[3], ToParse);
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

  override void Destroy(IAllocator Allocator, Resource Resource)
  {
    MeshResource MeshResource = cast(MeshResource)Resource;
    Allocator.Delete(MeshResource);
  }

  override Resource Load(IAllocator Allocator, WString FileName, IFile File)
  {
    TempMesh.Clear();
    MeshResource Mesh = Allocator.New!MeshResource(Allocator, this, FileName);
    TempMesh = WaveFrontMesh(Allocator);

    Lexer.Initialize(Allocator, File);
    UString PendingMeshName = UString(Allocator);

    while(Lexer.ProcessLine())
    {
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
        FinishUpObject(Allocator, Mesh, PendingMeshName);
        Lexer.ParseString(PendingMeshName);
        break;
      }
    }

    FinishUpObject(Allocator, Mesh, PendingMeshName);

    return Mesh;
  }

  void FinishUpObject(IAllocator Allocator, MeshResource Mesh, UString MeshName)
  {
    if (TempMesh.Vertices.Count > 0)
    {
      SubMesh NewSubMesh = Allocator.New!SubMesh(Allocator);
      auto DefinedVertices = Dictionary!(WaveFrontVertexDefinition, int)();
      DefinedVertices.Allocator = Allocator;
      foreach(FaceDefinition; TempMesh.Faces)
      {
        int VertexIndex = void;
        WaveFrontFaceDefinition[2] FaceArray;
        auto FaceRange = FaceArray[0..1];
        FaceRange[0].Vertices[0..3] = FaceDefinition.Vertices[0..3];
        if (FaceDefinition.Vertices[3].VertexIndex != -1)
        {
          FaceArray[1].Vertices[0] = FaceDefinition.Vertices[0];
          FaceArray[1].Vertices[1] = FaceDefinition.Vertices[2];
          FaceArray[1].Vertices[2] = FaceDefinition.Vertices[3];
          FaceRange = FaceArray[0..2];
        }
        foreach(TriangleDefinition; FaceRange)
        {
          foreach(Index, VertexDefinition; TriangleDefinition.Vertices[0..3])
          {
            if (DefinedVertices.TryGet(TriangleDefinition.Vertices[Index], VertexIndex))
            {
              NewSubMesh.Indices.PushBack(VertexIndex);
            }
            else
            {
              Vertex NewVertex = void;
              NewVertex.Position = TempMesh.Vertices[VertexDefinition.VertexIndex];
              if(VertexDefinition.NormalIndex != -1)
              {
                NewVertex.Normal = TempMesh.Normals[VertexDefinition.NormalIndex];
              }
              if(VertexDefinition.TextureIndex != -1)
              {
                NewVertex.TextureCoordinate = TempMesh.TextureCoordinates[VertexDefinition.TextureIndex];
              }
              NewVertex.Color = Colors.White;
              NewSubMesh.Indices.PushBack(cast(int)NewSubMesh.Vertices.Count);
              DefinedVertices[VertexDefinition] = cast(int)NewSubMesh.Vertices.Count;
              NewSubMesh.Vertices.PushBack(NewVertex);
            }
          }
        }
      }
      NewSubMesh.Name = MeshName;
      Mesh.Meshes.PushBack(NewSubMesh);

      TempMesh.Faces.Clear();
    }
  }

  WavefrontLexer Lexer;
}

unittest
{
  import krepel.log;
  import krepel;
  import krepel.memory;
  import krepel.string;

  auto TestAllocator = CreateTestAllocator();

  auto Manager = TestAllocator.New!ResourceManager(TestAllocator);
  auto WaveFrontLoader = TestAllocator.New!WavefrontResourceLoader();
  Manager.RegisterLoader(WaveFrontLoader, WString(".obj", TestAllocator));

  MeshResource Result = Manager.LoadMesh(WString("../unittest/Cube.obj", TestAllocator));
  assert(Result !is null);
  assert(Result.Meshes.Count == 1);
  auto SubMesh = Result.Meshes[0];
  assert(SubMesh);
  assert(SubMesh.Name == "Cube");
  assert(SubMesh.Vertices.Count == 24);
  assert(SubMesh.Indices.Count == 36);
  Manager.DestroyResource(Result);

  Result = Manager.LoadMesh(WString("../unittest/CubeOnlyIndex.obj", TestAllocator));
  assert(Result);
  assert(Result.Meshes.Count == 1);
  SubMesh = Result.Meshes[0];
  assert(SubMesh);
  assert(SubMesh.Name == "Cube");
  assert(SubMesh.Vertices.Count == 8);
  assert(SubMesh.Indices.Count == 36);
  Manager.DestroyResource(Result);

  Result = Manager.LoadMesh(WString("../unittest/TwoObjects.obj", TestAllocator));
  assert(Result);
  assert(Result.Meshes.Count == 2);
  SubMesh = Result.Meshes[0];
  assert(SubMesh);
  assert(SubMesh.Name == "Icosphere");
  SubMesh = Result.Meshes[1];
  assert(SubMesh);
  assert(SubMesh.Name == "Cube");
  Manager.DestroyResource(Result);

  Result = Manager.LoadMesh(WString("../unittest/QuadCube.obj", TestAllocator));
  assert(Result);
  assert(Result.Meshes.Count == 1);
  SubMesh = Result.Meshes[0];
  assert(SubMesh);
  assert(SubMesh.Name == "Cube");
  assert(SubMesh.Indices.Count == 36);
  assert(SubMesh.Vertices.Count == 24);
  Manager.DestroyResource(Result);

  TestAllocator.Delete(WaveFrontLoader);
  TestAllocator.Delete(Manager);
}
