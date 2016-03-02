module krepel.container.map;

import krepel;
import krepel.container.array;

struct Map(K, V)
{
  alias KeyType = K;
  alias ValueType = V;

  @property auto Keys() inout { return KeyArray[]; }
  @property auto Values() inout { return ValueArray[]; }

  // TODO(Manu): Collapse with the other overload and make it `inout` once the
  // compiler allows this.
  auto opIndex()
  {
    return Zip(Keys, Values);
  }

  auto opIndex() const
  {
    return Zip(Keys, Values);
  }

  auto ref opIndex(InKeyType)(auto ref InKeyType Key)
  {
    static assert(is(typeof(KeyArray[0] == Key)), InvalidKeyMessage!(InKeyType));

    auto Index = Keys.CountUntil(Key);
    assert(Index >= 0);
    return ValueArray[Index];
  }

  void opIndexAssign(InValueType, InKeyType)(auto ref InValueType Value, auto ref InKeyType Key)
    if(is(InValueType : ValueType))
  {
    static assert(is(typeof(KeyArray[0] == Key)), InvalidKeyMessage!(InKeyType));

    auto Index = Keys.CountUntil(Key);
    if(Index < 0)
    {
      KeyArray.PushBack(Key);
      ValueArray.PushBack(Value);
    }
    else
    {
      ValueArray[Index] = Value;
    }
  }

  bool Contains(InKeyType)(auto ref InKeyType Key) const
  {
    return Keys.CountUntil(Key) >= 0;
  }

  void Remove(InKeyType)(auto ref InKeyType Key)
  {
    auto Index = Keys.CountUntil(Key);
    assert(Index >= 0, "The given Key does not exist. Consider using TryRemove instead.");
    RemoveAt(Index);
  }

  bool TryRemove(InKeyType)(auto ref InKeyType Key)
  {
    auto Index = Keys.CountUntil(Key);
    if(Index < 0) return false;
    RemoveAt(Index);
    return true;
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

  void RemoveAt(IndexType)(IndexType Index)
  {
    KeyArray.RemoveAtSwap(Index);
    ValueArray.RemoveAtSwap(Index);
  }
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

  void TestFunc(SomeRangeType)(auto ref SomeRangeType SomeRange)
  {
    static assert(Meta.IsRandomAccessRange!SomeRangeType);

    foreach(Key, Value; SomeRange)
    {
      // Note(Manu): The order in which we iterate is not defined, that's why
      // we have to test more liberally with the tests here.

      bool First  = Key == 3 && Value == 42;
      bool Second = Key == 4 && Value == 1338;
      bool Third  = Key == 9 && Value == 99;
      assert(First || Second || Third);
    }

    foreach(Pair; SomeRange)
    {
      // Note(Manu): The order in which we iterate is not defined, that's why
      // we have to test more liberally with the tests here.

      bool First  = Pair[0] == 3 && Pair[1] == 42;
      bool Second = Pair[0] == 4 && Pair[1] == 1338;
      bool Third  = Pair[0] == 9 && Pair[1] == 99;
      assert(First || Second || Third);
    }
  }

  TestFunc(IntMap[]);
  TestFunc((cast(const)IntMap)[]);
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
