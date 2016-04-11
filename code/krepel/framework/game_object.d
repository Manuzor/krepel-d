module krepel.framework.game_object;

import krepel.memory;
import krepel.string;
import krepel.math;
import krepel.container;
import krepel.framework.component;
import krepel.framework.scene_component;

class GameObject
{
  IAllocator Allocator;
  UString Name;
  Array!GameComponent Components;
  SceneComponent RootComponent;

  Transform GetWorldTransform()
  {
    assert(RootComponent !is null);
    return RootComponent.GetLocalTransform;
  }
}
