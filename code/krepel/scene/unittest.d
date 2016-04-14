module krepel.scene.test;


unittest
{
  import krepel.scene;
  import krepel.memory;
  import krepel.container;
  import krepel.math;
  import krepel.string;
  auto Allocator = CreateTestAllocator();

  SceneGraph Graph = Allocator.New!SceneGraph(Allocator);
  GameObject GO = Graph.CreateDefaultGameObject(UString("TestObject", Allocator));
  assert(Graph.GameObjects.Count == 1);
  assert(GO.Name == "TestObject");
  assert(GO.RootComponent !is null);
  assert(GO.RootComponent.Name == "Scene Component");
  assert(GO.Components.Count == 1);
  assert(GO.GetWorldTransform() == Transform.Identity);
  Graph.DestroyGameObject(GO);
  assert(Graph.GameObjects.Count == 0);
}
