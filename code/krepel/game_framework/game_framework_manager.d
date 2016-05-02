module krepel.game_framework.game_framework_manager;

import krepel;
import krepel.scene;
import krepel.container;
import krepel.memory;
import krepel.game_framework.tick;
import krepel.scene;

class GameFrameworkManager
{
  Array!SceneGraph SceneGraphs;
  IAllocator Allocator;
  float TimeDilation;
  float FixedTickInterval = 0.0166666f;
  float PendingElapsedTime = 0.0f;
  bool FixedTimeStep = true;
  float TimeElapsedFromStart = 0.0f;
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

  void TickManager(float ElapsedTime)
  {
    assert(ElapsedTime >= 0.0f);
    if (FixedTimeStep)
    {
      assert(FixedTickInterval > 0.0f, "Cannot have 0 or negative update interval");
      PendingElapsedTime += ElapsedTime;
      while(PendingElapsedTime >= FixedTickInterval)
      {
        PendingElapsedTime -= FixedTickInterval;
        TimeElapsedFromStart += FixedTickInterval;
        TickData UpdateData = TickData(FixedTickInterval, TimeDilation, TimeElapsedFromStart);
        foreach(Graph; SceneGraphs)
        {
          Graph.Tick(UpdateData);
        }
      }
    }
    else
    {
      TimeElapsedFromStart += ElapsedTime;
      TickData UpdateData = TickData(ElapsedTime, TimeDilation, TimeElapsedFromStart);
      foreach(Graph; SceneGraphs)
      {
        Graph.Tick(UpdateData);
      }
    }
  }
}
