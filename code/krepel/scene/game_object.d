module krepel.scene.game_object;

import krepel.memory;
import krepel.string;
import krepel.math;
import krepel.container;
import krepel.scene.component;
import krepel.scene.scene_component;
import krepel.game_framework.tick;
import krepel.scene.scene_graph;

class GameObject
{
  mixin RefCountSupport;
  IAllocator Allocator;
  UString Name;
  Array!GameComponent Components;
  SceneComponent RootComponent;
  SceneGraph World;

  bool TickEnabled = true;

  this(IAllocator Allocator, UString Name, SceneGraph World)
  {
    this.Allocator = Allocator;
    this.Name = Name;
    Components.Allocator = Allocator;
    this.World = World;
  }

  ~this()
  {
    DestroyAllComponents();
  }

  Transform GetWorldTransform()
  {
    assert(RootComponent !is null);
    return RootComponent.GetLocalTransform;
  }

  ComponentType ConstructChild(ComponentType)(UString Name, SceneComponent Parent = null)
    if(is(ComponentType : GameComponent))
  {
    auto NewChild = Allocator.New!ComponentType(Allocator, Name, this);
    Components ~= NewChild;
    static if(is(ComponentType : SceneComponent))
    {
      NewChild.Parent = Parent;
      if(RootComponent is null && Parent is null)
      {
        RootComponent = NewChild;
      }
      else if(Parent !is null)
      {
        Parent.Children ~= NewChild;
      }
      else if (RootComponent !is null)
      {
        NewChild.Parent = RootComponent;
        RootComponent.Children ~= NewChild;
      }
    }
    World.NotifyComponentCreated(NewChild);
    return NewChild;
  }

  void DestroyAllComponents()
  {
    foreach(Component ; Components)
    {
      World.NotifyComponentRemoved(Component);
      Allocator.Delete(Component);
    }
    Components.Clear();
  }

  void Start()
  {
  }

  void Tick(TickData Tick)
  {
    foreach(Component; Components)
    {
      if (Component.TickEnabled)
      {
        Component.Tick(Tick);
      }
    }
  }
}
