module krepel.event;

import krepel.krepel;
import krepel.memory;
import krepel.container.array;

struct Event(ArgTypes...)
{
  alias ListenerType = void delegate(ArgTypes);

  Array!ListenerType Listeners;

  this(IAllocator Allocator)
  {
    this.Allocator = Allocator;
  }

  @property void Allocator(IAllocator NewAllocator)
  {
    this.Listeners.Allocator = NewAllocator;
  }

  void Add(ListenerType Listener)
  {
    this.Listeners ~= Listener;
  }

  bool Remove(ListenerType Listener)
  {
    auto Index = this.Listeners[].CountUntil(Listener);
    if(Index < 0) return false;

    // Note(Manu): Don't use RemoveAtSwap to maintain the order the listeners were added.
    this.Listeners.RemoveAt(Index);
    return true;
  }

  void opCall(ArgTypes...)(auto ref ArgTypes Args)
  {
    foreach(Listener; this.Listeners)
    {
      Listener(Args);
    }
  }
}

//
// Unit Tests
//

unittest
{
  auto TestAllocator = CreateTestAllocator();

  auto TheEvent = Event!int(TestAllocator);

  auto Listener = (int Val) => assert(Val == 42);
  TheEvent.Add(ToDelegate(Listener));
  TheEvent(42);
  TheEvent.Remove(ToDelegate(Listener));
  TheEvent(1337);
}

unittest
{
  auto TestAllocator = CreateTestAllocator();

  auto TheEvent = Event!(int*)(TestAllocator);
  TheEvent.Add( (int* Val){ assert(*Val == 42); *Val = 1337; } );
  TheEvent.Add( (int* Val){ assert(*Val == 1337); *Val = 0xC0FFEE; } );

  auto Value = 42;
  TheEvent(&Value);
  assert(Value == 0xC0FFEE);

  // Try once more.
  Value = 42;
  TheEvent(&Value);
  assert(Value == 0xC0FFEE);
}
