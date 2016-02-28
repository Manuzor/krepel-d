module krepel.container.map;

import krepel;
import krepel.container.array;

struct Map(K, V)
{
  alias KeyType = K;
  alias ValueType = V;

  @property auto Keys() inout { return KeyArray[]; }
  @property auto Values() inout { return ValueArray[]; }

  auto ref opIndex(InKeyType)(auto ref InKeyType Index)
    if(is(InKeyType : KeyType))
  {
    auto ArrayIndex = Keys.CountUntil(Index);
    assert(ArrayIndex >= 0);
    return ValueArray[ArrayIndex];
  }

  void opIndexAssign(InValueType, InKeyType)(auto ref InValueType Value, auto ref InKeyType Index)
    if(is(InKeyType : KeyType) && is(InValueType : ValueType))
  {
    auto ArrayIndex = Keys.CountUntil(Index);
    if(ArrayIndex < 0)
    {
      KeyArray.PushBack(Index);
      ValueArray.PushBack(Value);
    }
    else
    {
      ValueArray[ArrayIndex] = Value;
    }
  }

private:
  Array!KeyType KeyArray;
  Array!ValueType ValueArray;
}

//
// Unit Tests
//

unittest
{
  import std.exception;
  import core.exception : AssertError;

  mixin(SetupGlobalAllocatorForTesting!(400));

  Map!(int, int) IntMap;

  IntMap[3] = 42;
  IntMap[4] = 1337;
  IntMap[9] = 99;

  assert(IntMap.Keys.length == 3);
  assert(IntMap.Values.length == 3);
  assertThrown!AssertError(IntMap[0]);
  assert(IntMap[4] == 1337);

  IntMap[4] = 1338;
  assert(IntMap[4] == 1338);
  assert(IntMap.Keys.length   == 3);
  assert(IntMap.Values.length == 3);
}
