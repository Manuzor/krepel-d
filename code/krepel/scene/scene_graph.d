module krepel.scene.scene_graph;

import krepel;
import krepel.container;
import krepel.scene.game_object;
import krepel.string;
import krepel.scene.scene_component;
import krepel.game_framework.tick;
import krepel.scene.component;

class SceneGraph
{
  Event!(GameObject) OnGameObjectAdded;
  Event!(GameObject) OnGameObjectRemoved;
  Event!(GameObject, GameComponent) OnComponentAdded;
  Event!(GameObject, GameComponent) OnComponentRegistered;
  Event!(GameObject, GameComponent) OnComponentRemoved;

  IAllocator Allocator;
  this(IAllocator Allocator)
  {
    this.Allocator = Allocator;
    GameObjects.Allocator = Allocator;
    OnGameObjectAdded = Event!(GameObject)(Allocator);
    OnGameObjectRemoved = Event!(GameObject)(Allocator);
    OnComponentAdded = Event!(GameObject, GameComponent)(Allocator);
    OnComponentRegistered = Event!(GameObject, GameComponent)(Allocator);
    OnComponentRemoved = Event!(GameObject, GameComponent)(Allocator);
  }

  Array!GameObject GameObjects;

  void NotifyComponentCreated(GameComponent Component)
  {
    OnComponentAdded(Component.Owner, Component);
  }

  void NotifyComponentRegistered(GameComponent Component)
  {
    OnComponentRegistered(Component.Owner, Component);
  }

  void NotifyComponentRemoved(GameComponent Component)
  {
    OnComponentRemoved(Component.Owner, Component);
  }

  GameObject CreateDefaultGameObject(UString Name)
  {
    auto NewGO = Allocator.New!GameObject(Allocator, Name, this);
    GameObjects ~= NewGO;
    NewGO.ConstructChild!SceneComponent(UString("Scene Component", Allocator));
    OnGameObjectAdded(NewGO);
    NewGO.Start();
    return NewGO;
  }

  GameObjectType CreateGameObject(GameObjectType)(UString Name)
    if(is(GameObjectType : GameObject))
  {
    auto NewGO = Allocator.New!(GameObjectType)(Allocator, Name, this);
    GameObjects ~= NewGO;
    OnGameObjectAdded(NewGO);
    NewGO.Start();
    return NewGO;
  }

  GameObject[] GetGameObjects()
  {
    return GameObjects[];
  }

  void DestroyGameObject(GameObject Object)
  {
    GameObject GameObj = Object;
    auto Index = GameObjects[].CountUntil(GameObj);
    if(Index < 0)
    {
      Log.Warning("Tried to destroy non registered GameObject! Ignoring...");
      return;
    }
    GameObjects.RemoveAt(Index);
    OnGameObjectRemoved(Object);
    Allocator.Delete(GameObj);
  }

  void Tick(TickData Tick)
  {
    foreach(Object; GameObjects)
    {
      if (Object.TickEnabled)
      {
        Object.Tick(Tick);
      }
    }
  }
}
