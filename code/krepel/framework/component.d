module krepel.framework.component;

import krepel.string;
import krepel.memory;
import krepel.framework.game_object;

class GameComponent
{
  RefCountPayloadData RefCountPayload;
  IAllocator Allocator;
  UString Name;
  GameObject Owner;
}
