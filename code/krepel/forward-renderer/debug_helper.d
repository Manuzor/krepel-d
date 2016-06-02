module krepel.forward_renderer.debug_helper;

import krepel;
import krepel.resources;
import krepel.color;
import krepel.render_device;
import krepel.forward_renderer;
import krepel.engine;

struct DebugRenderMesh
{
  Array!Vertex Vertices;
  RenderPrimitiveTopology Mode = RenderPrimitiveTopology.LineList;
}

struct DebugRenderData
{
  DebugRenderMesh Mesh;
  Transform Transformation;
}

class DebugRenderHelper
{
  Array!DebugRenderData DataToRender;

  IAllocator Allocator;
  this(IAllocator Allocator)
  {
    this.Allocator = Allocator;
    DataToRender.Allocator = Allocator;
  }

  DebugRenderMesh CreateBox(Vector3 HalfDimensions, ColorLinear Color)
  {
    DebugRenderMesh Data;
    Data.Vertices.Allocator = Allocator;
    Array!Vector3 Positions;
    Positions.Allocator = Allocator;
    Data.Mode = RenderPrimitiveTopology.LineList;
    with(Positions)
    {
      PushBack(Vector3(-HalfDimensions.X, -HalfDimensions.Y, -HalfDimensions.Z));
      PushBack(Vector3(HalfDimensions.X, -HalfDimensions.Y, -HalfDimensions.Z));

      PushBack(Vector3(-HalfDimensions.X, HalfDimensions.Y, -HalfDimensions.Z));
      PushBack(Vector3(HalfDimensions.X, HalfDimensions.Y, -HalfDimensions.Z));

      PushBack(Vector3(-HalfDimensions.X, -HalfDimensions.Y, HalfDimensions.Z));
      PushBack(Vector3(HalfDimensions.X, -HalfDimensions.Y, HalfDimensions.Z));

      PushBack(Vector3(-HalfDimensions.X, HalfDimensions.Y, HalfDimensions.Z));
      PushBack(Vector3(HalfDimensions.X, HalfDimensions.Y, HalfDimensions.Z));

      PushBack(Vector3(-HalfDimensions.X, -HalfDimensions.Y, -HalfDimensions.Z));
      PushBack(Vector3(-HalfDimensions.X, HalfDimensions.Y, -HalfDimensions.Z));

      PushBack(Vector3(HalfDimensions.X, -HalfDimensions.Y, -HalfDimensions.Z));
      PushBack(Vector3(HalfDimensions.X, HalfDimensions.Y, -HalfDimensions.Z));

      PushBack(Vector3(-HalfDimensions.X, -HalfDimensions.Y, HalfDimensions.Z));
      PushBack(Vector3(-HalfDimensions.X, HalfDimensions.Y, HalfDimensions.Z));

      PushBack(Vector3(HalfDimensions.X, -HalfDimensions.Y, HalfDimensions.Z));
      PushBack(Vector3(HalfDimensions.X, HalfDimensions.Y, HalfDimensions.Z));

      PushBack(Vector3(-HalfDimensions.X, -HalfDimensions.Y, -HalfDimensions.Z));
      PushBack(Vector3(-HalfDimensions.X, -HalfDimensions.Y, HalfDimensions.Z));

      PushBack(Vector3(HalfDimensions.X, -HalfDimensions.Y, -HalfDimensions.Z));
      PushBack(Vector3(HalfDimensions.X, -HalfDimensions.Y, HalfDimensions.Z));

      PushBack(Vector3(-HalfDimensions.X, HalfDimensions.Y, -HalfDimensions.Z));
      PushBack(Vector3(-HalfDimensions.X, HalfDimensions.Y, HalfDimensions.Z));

      PushBack(Vector3(HalfDimensions.X, HalfDimensions.Y, -HalfDimensions.Z));
      PushBack(Vector3(HalfDimensions.X, HalfDimensions.Y, HalfDimensions.Z));
    }

    foreach(Position; Positions)
    {
      Data.Vertices.PushBack(
        Vertex(
          Position,
          Vector2.ZeroVector,
          Vector3.ZeroVector,
          Vector4.ZeroVector,
          Vector3.ZeroVector,
          Color)
      );
    }

    return Data;
  }

  DebugRenderMesh CreateSphere(float Radius, ColorLinear Color,uint Subdivisions = 16)
  {

    DebugRenderMesh Data;
    Data.Vertices.Allocator = Allocator;
    Data.Mode = RenderPrimitiveTopology.LineList;

    float Angle = (2 * PI) / Subdivisions;
    Array!Vector3 Positions;
    Positions.Allocator = Allocator;
    struct SphereData
    {
      Vector3 StartVector;
      Quaternion Rotator;
    }
    SphereData[3] CircleDatas;
    CircleDatas[0] = SphereData(Vector3.ForwardVector * Radius, Quaternion(Vector3.UpVector, Angle));
    CircleDatas[1] = SphereData(Vector3.UpVector * Radius, Quaternion(Vector3.RightVector, Angle));
    CircleDatas[2] = SphereData(Vector3.RightVector * Radius, Quaternion(Vector3.ForwardVector, Angle));
    foreach(CircleData; CircleDatas)
    {
      Vector3 CurrentPosition = CircleData.StartVector;
      auto Rotator = CircleData.Rotator;
      foreach(uint Index; 0..Subdivisions)
      {
        Positions ~= CurrentPosition;
        CurrentPosition = Rotator.TransformDirection(CurrentPosition);
        Positions ~= CurrentPosition;
      }
    }

    foreach(Position; Positions)
    {
      Data.Vertices.PushBack(
        Vertex(
          Position,
          Vector2.ZeroVector,
          Vector3.ZeroVector,
          Vector4.ZeroVector,
          Vector3.ZeroVector,
          Color)
      );
    }

    return Data;
  }

  void AddBox(Transform Transformation, Vector3 HalfDimensions, ColorLinear Color)
  {
    AddData(Transformation, CreateBox(HalfDimensions, Color));
  }

  void AddSphere(Transform Transformation, float Radius, ColorLinear Color, uint Subdivisions = 16)
  {
    AddData(Transformation, CreateSphere(Radius, Color, Subdivisions));
  }

  void AddData(Transform Transformation, DebugRenderMesh Data)
  {
    DataToRender ~= DebugRenderData(Data, Transformation);
  }

  void Draw(IRenderDevice RenderDevice)
  {

    WorldConstantBuffer WorldData;
    foreach(RenderData; DataToRender)
    {
      IRenderConstantBuffer ConstantBuffer;
      WorldData.ModelMatrix = RenderData.Transformation.ToMatrix;
      WorldData.ModelViewProjectionMatrix = WorldData.ModelMatrix * GlobalEngine.Renderer.GetViewProjectionMatrix();
      WorldData.ModelMatrix = WorldData.ModelMatrix.GetTransposed;
      WorldData.ModelViewProjectionMatrix = WorldData.ModelViewProjectionMatrix.GetTransposed;
      WorldData.Color = RenderData.Mesh.Vertices[0].Color;
      ConstantBuffer = RenderDevice.CreateConstantBuffer(WorldData.AsVoidRange);
      RenderDevice.SetVertexShaderConstantBuffer(ConstantBuffer, 0);
      auto VertexBuffer = RenderDevice.CreateVertexBuffer(RenderData.Mesh.Vertices[]);
      scope(exit)
      {
        RenderDevice.ReleaseVertexBuffer(VertexBuffer);
        RenderDevice.ReleaseConstantBuffer(ConstantBuffer);
      }
      RenderDevice.SetVertexBuffer(VertexBuffer);
      RenderDevice.SetPrimitiveTopology(RenderData.Mesh.Mode);
      RenderDevice.Draw(cast(uint)RenderData.Mesh.Vertices.Count);
    }

    DataToRender.Clear();
  }

}
