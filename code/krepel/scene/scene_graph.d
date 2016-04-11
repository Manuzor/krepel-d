module krepel.scene.scene_graph;

import krepel;
import krepel.container;
import krepel.scene.game_object;
import krepel.string;
import krepel.scene.scene_component;

class SceneGraph
{
  IAllocator Allocator;
  this(IAllocator Allocator)
  {
    this.Allocator = Allocator;
    GameObjects.Allocator = Allocator;
  }

  Array!GameObject GameObjects;

  ARC!GameObject CreateDefaultGameObject(UString Name)
  {
    auto NewGO = Allocator.NewARC!GameObject(Allocator, Name);
    GameObjects ~= NewGO;
    NewGO.ConstructChild!SceneComponent(UString("Scene Component", Allocator));
    return NewGO;
  }

  GameObject[] GetGameObjects()
  {
    return GameObjects[];
  }

  void DestroyGameObject(ref ARC!GameObject Object)
  {
    GameObject GameObj = Object;
    auto Index = GameObjects[].CountUntil(GameObj);
    if(Index < 0)
    {
      Log.Warning("Tried to destroy non registered GameObject! Ignoring...");
      return;
    }
    GameObjects.RemoveAt(Index);
    Object.RefCountPayload.RemoveRef();
  }
}
