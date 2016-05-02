module krepel.scene.scene_component;

import krepel.memory;
import krepel.string;
import krepel.scene.component;
import krepel.math;
import krepel.container;
import krepel.scene.game_object;

class SceneComponent : GameComponent
{
  SceneComponent Parent;
  Array!SceneComponent Children;

  this(IAllocator Allocator, UString Name, GameObject Owner)
  {
    super(Allocator, Name, Owner);
    Children.Allocator = Allocator;
    Transformation = Transform.Identity;
  }

  Transform GetLocalTransform()
  {
    return Transformation;
  }

  Transform GetWorldTransform()
  {
    if (Parent)
    {
      return Parent.GetWorldTransform() * Transformation;
    }
    return Transformation;
  }

  void SetLocalTransform(Transform NewTransform)
  {
    Transformation = NewTransform;
  }

  void SetWorldTransform(Transform NewTransform)
  {
    if(Parent !is null)
    {
      NewTransform.SetRelativeTo(Parent.GetWorldTransform());
    }
    Transformation = NewTransform;
  }



private:
  Transform Transformation;
}
