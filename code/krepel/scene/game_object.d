module krepel.scene.game_object;

import krepel.memory;
import krepel.string;
import krepel.math;
import krepel.container;
import krepel.scene.component;
import krepel.scene.scene_component;

class GameObject
{
  mixin RefCountSupport;
  IAllocator Allocator;
  UString Name;
  Array!GameComponent Components;
  SceneComponent RootComponent;

  this(IAllocator Allocator, UString Name)
  {
    this.Allocator = Allocator;
    this.Name = Name;
    Components.Allocator = Allocator;
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
      if(Parent !is null)
      {
        Parent.Children ~= NewChild;
      }
    }

    return NewChild;
  }

  void DestroyAllComponents()
  {
    foreach(Component ; Components)
    {
      Allocator.Delete(Component);
    }
    Components.Clear();
  }
}
