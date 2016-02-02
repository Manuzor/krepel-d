module krepel;

nothrow:
@nogc:


// TODO(Manu): Custom assert?

auto ref Min(ArgTypes...)(ArgTypes Args)
  if(ArgTypes.length > 0)
{
  static if(ArgTypes.length == 1)
  {
    return Args[0];
  }
  else
  {
    auto A = Args[0];
    auto B = Min(Args[1 .. $]);
    return A < B ? A : B;
  }
}

auto ref Max(ArgTypes...)(ArgTypes Args)
  if(ArgTypes.length > 0)
{
  static if(ArgTypes.length == 1)
  {
    return Args[0];
  }
  else
  {
    auto A = Args[0];
    auto B = Max(Args[1 .. $]);
    return A > B ? A : B;
  }
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

struct Span(T)
{
  alias ElementType = T;

  size_t Count;
  ElementType* Data;

  @property size_t ByteCount() const { return Count * ElementType.sizeof; }

  struct Slice
  {
    size_t LeftIndex;
    size_t RightIndex;
  }

  auto opSlice(size_t Position)(size_t LeftIndex, size_t RightIndex)
  {
    return Slice(LeftIndex, RightIndex);
  }

  auto ref opIndex() inout { return this; }

  auto ref opIndex(size_t Index) inout
  {
    assert(Index < Count, "Index out of bounds.");
    return Data[Index];
  }

  auto opIndex(Slice Range)
  {
    return typeof(this)(Range.RightIndex - Range.LeftIndex, Data + Range.LeftIndex);
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

  @property size_t opDollar(size_t Position)() const
  {
    return Count;
  }

  // Range API:
  // TODO(Manu): Full Range API
  bool empty() const { return Count == 0; }
  auto front() inout { return this[0]; }
  auto popFront()    { return this[1 .. $]; }
  auto back() inout  { return this[$-1]; }
  auto popBack()     { return this[0 .. $-1]; }
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
