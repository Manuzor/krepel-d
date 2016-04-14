module krepel.scene.component;

import krepel.string;
import krepel.memory;
import krepel.scene.game_object;
import krepel.game_framework.tick;

class GameComponent
{
  IAllocator Allocator;
  UString Name;
  GameObject Owner;

  bool TickEnabled;

  this(IAllocator Allocator, UString Name, GameObject Owner)
  {
    this.Allocator = Allocator;
    this.Name = Name;
    this.Owner = Owner;
  }

  void Tick(TickData Tick)
  {

  }
}
