module krepel.container.dictionary;

import krepel;
import krepel.container.array;

struct Dictionary(K, V)
{
  alias KeyType = K;
  alias ValueType = V;

  this(IAllocator Allocator)
  {
    this.Allocator = Allocator;
  }

  @property auto Keys() inout { return KeyArray[]; }
  @property auto Values() inout { return ValueArray[]; }

  @property IAllocator Allocator()
  {
    assert(KeyArray.Allocator is ValueArray.Allocator);
    return KeyArray.Allocator;
  }

  @property void Allocator(IAllocator NewAllocator)
  {
    KeyArray.Allocator = NewAllocator;
    ValueArray.Allocator = NewAllocator;
  }

  void Clear()
  {
    KeyArray.Clear();
    ValueArray.Clear();
  }

  void ClearMemory()
  {
    KeyArray.ClearMemory();
    ValueArray.ClearMemory();
  }

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

  /// Note: The key MUST exist.
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

  /// Gets the value corresponding to Key.
  ///
  /// Returns: A pointer to the value or null if it can't be found.
  ValueType* Get(InKeyType)(auto ref InKeyType Key, ValueType* FallbackValue = null)
  {
    static assert(is(typeof(KeyArray[0] == Key)), InvalidKeyMessage!(InKeyType));

    auto Index = Keys.CountUntil(Key);
    if(Index < 0) return FallbackValue;
    return &ValueArray[Index];
  }

  bool TryGet(InKeyType, OutValueType)(auto ref InKeyType Key, out OutValueType Value)
  {
    if(Contains(Key))
    {
      Value = this[Key];
      return true;
    }
    return false;
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

  auto TestAllocator = CreateTestAllocator();

  auto Dict = Dictionary!(int, int)(TestAllocator);

  Dict[3] = 42;
  Dict[4] = 1337;
  Dict[9] = 99;

  assert(Dict.Keys.length == 3);
  assert(Dict.Values.length == 3);
  assertThrown!AssertError(Dict[0]);
  assert(Dict[4] == 1337);

  Dict[4] = 1338;
  assert(Dict[4] == 1338);
  assert(Dict.Keys.length   == 3);
  assert(Dict.Values.length == 3);

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

  TestFunc(Dict[]);
  TestFunc((cast(const)Dict)[]);

  assert(Dict.Get(42) is null);
  assert(Dict.Get(4) is &Dict[4]);
}

unittest
{
  auto TestAllocator = CreateTestAllocator();

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

  auto Dict = Dictionary!(MyKey, MyValue)(TestAllocator);
  Dict[MyKey("this")] = MyValue("that", 3.1415f);

  assert(Dict[MyKey("this")].Data == "that");
  assert(Dict[MyKey("this")].SomethingElse == 3.1415f);

  // With the proper opEquals implementation, the key to this dictionary can
  // be anything.
  assert(Dict["this"].Data == "that");

  static struct InvalidKey {}

  static assert(!__traits(compiles, Dict[InvalidKey()].Data == "that"));
}
