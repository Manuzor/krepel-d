module krepel.framework.scene_component;

import krepel.memory;
import krepel.string;
import krepel.framework.component;
import krepel.math;
import krepel.container;

class SceneComponent : GameComponent
{
  SceneComponent Parent;
  Array!SceneComponent Children;

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



private:
  Transform Transformation;
}
