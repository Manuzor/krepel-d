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

  Transform GetLocalTransform() const
  {
    return Transformation;
  }

  Transform GetWorldTransform() const
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

  void MoveWorld(Vector3 Delta)
  {
    auto WorldTransform = GetWorldTransform();
    WorldTransform.Translation += Delta;
    SetWorldTransform(WorldTransform);
  }

  void MoveLocal(Vector3 Delta)
  {
    Transformation.Translation += Delta;
  }

  void SetRotation(Quaternion Quat)
  {
    Transformation.Rotation = Quat;
    auto OldTransform = GetWorldTransform();
    OldTransform.Rotation = Quat;
    SetWorldTransform(OldTransform);
  }



private:
  Transform Transformation = Transform();
}
