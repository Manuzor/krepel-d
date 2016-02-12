module krepel.span;

import krepel.algorithm : Min;
import Meta = krepel.meta;

version(unittest) {} else
{
  nothrow:
  @nogc:
}

/// Construct from a static array.
auto MakeSpan(size_t N, T)(ref T[N] Array)
{
  return Span!(T)(N, Array.ptr);
}

/// Construct from a count and a pointer to data.
auto MakeSpan(T)(size_t N, T* Data)
{
  return Span!T(N, Data);
}

/// Create span from a single object.
auto MakeSpan(T)(ref T Data)
  if(!Meta.IsArray!T)
{
  return Span!T(1, &Data);
}


static struct Span(T)
{
  alias ElementType = T;

  size_t Count;
  ElementType* Data;

  @property size_t ByteCount() const { return Count * ElementType.sizeof; }

  // Shallow member equality. Use `Equal` for full equality test.
  auto opBinary(string Op : "==", OtherType)(in ref OtherType Other)
  {
    return this.Data == Other.Data && this.Count == Other.Count;
  }

  typeof(this) opSlice(size_t Position)(size_t LeftIndex, size_t RightIndex)
  {
    assert(LeftIndex <= RightIndex, "Lower bound must not be bigger than the upper bound.");
    assert(RightIndex <= Count, "Upper bound exceeds its maximum.");

    auto NewCount = RightIndex - LeftIndex;
    assert(NewCount <= Count, "New count is out of bounds.");

    if(LeftIndex <= RightIndex
       && RightIndex <= Count
       && NewCount <= Count
       && NewCount > 0)
    {
      return typeof(return)(NewCount, Data + LeftIndex);
    }

    return typeof(return)();
  }

  auto ref opIndex() inout { return this; }

  auto ref opIndex(size_t Index) inout
  {
    assert(Index < Count, "Index out of bounds.");
    return Data[Index];
  }

  auto opIndex(typeof(this) TheSpan)
  {
    return TheSpan;
  }

  // Example: MySpan[] = 42; // Assign 42 to all elements.
  void opIndexAssign(T)(in T Value)
  {
    foreach(ref Element; Data)
    {
      Element = Value;
    }
  }

  // Example: MySpan[0] = 42; // Assign 42 to the first element in the Span.
  void opIndexAssign(T)(in T Value, size_t Index)
  {
    assert(Index < Count);
    Data[Index] = Value;
  }

  @property size_t opDollar(size_t _)() const
  {
    return Count;
  }

  auto opCast(TargetType : bool)() const { return Data && Count; }

  // Range API:
  bool empty() const { return Count == 0; }
  auto front() inout { return this[0]; }
  auto popFront()    { return this[1 .. $]; }
  auto back() inout  { return this[$-1]; }
  auto popBack()     { return this[0 .. $-1]; }
}

// TODO(Manu): This should probably be more specific (i.e. Data should be pointer, ElementType is a type, ...)
enum bool IsSomeSpan(T) = __traits(hasMember, T, "Data") && __traits(hasMember, T, "Count");

bool Equal(SpanTypeA, SpanTypeB)(SpanTypeA SpanA, SpanTypeB SpanB)
  if(IsSomeSpan!SpanTypeA && IsSomeSpan!SpanTypeB)
{
  if(SpanA.Data == SpanB.Data)
  {
    return SpanA.Count == SpanB.Count;
  }

  if(SpanA.Count != SpanB.Count)
  {
    return false;
  }

  immutable Count = SpanA.Count;
  for(size_t i; i < Count; i++)
  {
    if(SpanA.Data[i] != SpanB.Data[i])
    {
      return false;
    }
  }

  return true;
}

bool Contains(T)(in ref Span!T SomeSpan, in ref Span!T AnotherSpan)
{
  return AnotherSpan.Data > SomeSpan.Data &&
         AnotherSpan.Data - SomeSpan.Data <= Max(AnotherSpan.Count - SomeSpan.Count);
}

// Example: MySpan[0..2].Assign = 42; // Assign 42 to the first two elements in the Span.
void Assign(T)(Span!T Destination, in T Value)
{
  for(size_t i = 0; i < Destination.Count; ++i)
  {
    // NOTE(Manu): A bounds check here is superfluous.
    Destination.Data[i] = Value;
  }
}

// Example: MySpan[0..2].Assign = AnotherSpan[0..2]; // Copy the first two elements from AnotherSpan to MySpan.
auto Assign(T, U)(Span!T Destination, in Span!U Source)
  //if(__traits(compiles, { Destination.Data[0] = Source.Data[0]; }))
{
  auto CopyAmount = Min(Destination.Count, Source.Count);

  for(size_t i = 0; i < CopyAmount; ++i)
  {
    // NOTE(Manu): A bounds check here is superfluous.
    Destination.Data[i] = Source.Data[i];
  }
}

//
// Unit Tests
//

version(unittest):


// MakeSpan from static array
unittest
{
  immutable int[10] Integers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
  auto IntSpan = MakeSpan(Integers);
  for(int Index = 0; Index < 10; ++Index)
  {
    assert(Integers[Index] == IntSpan[Index]);
  }
}

// MakeSpan from size and pointer
unittest
{
  immutable int[10] Integers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
  auto IntSpan = MakeSpan(3, Integers.ptr + 3);
  assert(IntSpan[0] == 3);
  assert(IntSpan[1] == 4);
  assert(IntSpan[2] == 5);
}

// MakeSpan from a single object
unittest
{
  struct S { int Value; }
  immutable Something = S(1337);
  // TODO(Manu): Causes infinite loop.
  //foreach(ref Instance; MakeSpan(Something))
  //{
  //  assert(Instance.Value == 1337);
  //}
}

// Span.opBinary ==
unittest
{
  int[3] FirstArray  = [0, 1, 2];
  int[3] SecondArray = [0, 1, 2];

  assert(MakeSpan(FirstArray) == MakeSpan(FirstArray));
  assert(MakeSpan(FirstArray) != MakeSpan(SecondArray));
}

// Span.opIndex []
unittest
{
  auto Value = 42;
  auto TheSpan = MakeSpan(Value);
  assert(TheSpan[] == TheSpan);
}

// Span.opIndex [Index]
unittest
{
  {
    int[3] Integers = [0, 1, 2];
    auto TheSpan = MakeSpan(Integers);
    assert(TheSpan[0] == 0);
    assert(TheSpan[1] == 1);
    assert(TheSpan[2] == 2);
  }

  {
    static struct S { int Value; }
    auto Instance = S(42);
    //auto TheSpan = MakeSpan(Instance);
    //TheSpan[0].Value = 1337;
    //assert(Instance.Value == 1337);
  }
}

// Span.opIndex [Slice]
unittest
{
  import std.exception;
  import core.exception;

  int[6] Integers = [0, 1, 2, 3, 4, 5];
  auto TheSpan = MakeSpan(Integers);
  assert(TheSpan[0 ..  $ ].Data  == TheSpan.Data);
  assert(TheSpan[0 ..  $ ].Count == TheSpan.Count);
  assert(TheSpan[1 ..  $ ].Data  == TheSpan.Data  + 1);
  assert(TheSpan[1 ..  $ ].Count == TheSpan.Count - 1);
  assert(TheSpan[0 .. $-1].Data  == TheSpan.Data     );
  assert(TheSpan[0 .. $-1].Count == TheSpan.Count - 1);

  assert(TheSpan[0 .. 1][0] == 0);
  assert(!TheSpan[0 .. 0]);

  // Out-of-range cases
  assertThrown!AssertError(TheSpan[  1 ..   0]);
  assertThrown!AssertError(TheSpan[100 ..  99]);
  assertThrown!AssertError(TheSpan[  0 .. 100]);
  assertThrown!AssertError(TheSpan[  5 ..  10]);
}

// Equal
unittest
{
  int[6] BigArray = [0, 1, 2, 3, 4, 5];
  int[3] FirstArray = [0, 1, 2];
  int[3] SecondArray = [3, 4, 5];

  assert( Equal(MakeSpan(FirstArray), MakeSpan(FirstArray)));
  assert( Equal(MakeSpan(FirstArray), MakeSpan(3, BigArray.ptr    )));
  assert(!Equal(MakeSpan(FirstArray), MakeSpan(2, BigArray.ptr    )));
  assert(!Equal(MakeSpan(FirstArray), MakeSpan(3, BigArray.ptr + 1)));

  assert(Equal(MakeSpan(SecondArray), MakeSpan(SecondArray)));
  assert(Equal(MakeSpan(SecondArray), MakeSpan(3, BigArray.ptr + 3)));
}
