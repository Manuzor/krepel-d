module krepel.scene.component;

import krepel.string;
import krepel.memory;
import krepel.scene.game_object;

class GameComponent
{
  IAllocator Allocator;
  UString Name;
  GameObject Owner;

  this(IAllocator Allocator, UString Name, GameObject Owner)
  {
    this.Allocator = Allocator;
    this.Name = Name;
    this.Owner = Owner;
  }
}
