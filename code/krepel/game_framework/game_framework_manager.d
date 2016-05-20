module krepel.game_framework.game_framework_manager;

import krepel;
import krepel.scene;
import krepel.container;
import krepel.memory;
import krepel.game_framework.tick;
import krepel.scene;
import krepel.engine.subsystem;

class GameFrameworkManager : Subsystem
{
  Array!SceneGraph SceneGraphs;

  this(IAllocator Allocator)
  {
    this.Allocator = Allocator;
    SceneGraphs.Allocator = Allocator;
  }

  void RegisterScene(SceneGraph Graph)
  {
    SceneGraphs ~= Graph;
  }

  void UnregisterScene(SceneGraph Graph)
  {
    SceneGraphs.RemoveFirst(Graph);
  }

  override void Tick(TickData Tick)
  {
    foreach(Graph; SceneGraphs)
    {
      Graph.Tick(Tick);
    }
  }
}
