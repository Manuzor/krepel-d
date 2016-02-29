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
  {
    static assert(is(typeof(KeyArray[0] == Index)), InvalidKeyMessage!(InKeyType));

    auto ArrayIndex = Keys.CountUntil(Index);
    assert(ArrayIndex >= 0);
    return ValueArray[ArrayIndex];
  }

  void opIndexAssign(InValueType, InKeyType)(auto ref InValueType Value, auto ref InKeyType Index)
    if(is(InValueType : ValueType))
  {
    static assert(is(typeof(KeyArray[0] == Index)), InvalidKeyMessage!(InKeyType));

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

  enum InvalidKeyMessage(OtherKeyType) =
    Format("The type `%s` cannot be used as key because it is "
           "incomparable to `%s`. A proper definition of opEquals "
           "is required for this to work.",
           OtherKeyType.stringof,
           KeyType.stringof);
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

unittest
{
  mixin(SetupGlobalAllocatorForTesting!(1024));

  static struct MyKey
  {
    string Name;

    bool opEquals(in ref MyKey Other) const { return this.Name == Other.Name; }

    bool opEquals(in string Value) const
    {
      return this.Name == Value;
    }
  }

  static struct MyValue
  {
    string Data;
    float SomethingElse;
  }

  Map!(MyKey, MyValue) TheMap;
  TheMap[MyKey("this")] = MyValue("that", 3.1415f);

  assert(TheMap[MyKey("this")].Data == "that");
  assert(TheMap[MyKey("this")].SomethingElse == 3.1415f);

  // With the proper opEquals implementation, the key to this map can be
  // anything.
  assert(TheMap["this"].Data == "that");

  static struct InvalidKey {}

  static assert(!__traits(compiles, TheMap[InvalidKey()].Data == "that"));
}
