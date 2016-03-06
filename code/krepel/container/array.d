module krepel.container.array;

import krepel;
import krepel.algorithm : Min, Max;
import Meta = krepel.meta;

/// A contiguous array of the given type.
///
/// This array implementation favors appending to the back of it, in terms of
/// performance (i.e. ~= and PushBack, PopBack) but operating on the front is
/// also accounted for and only slightly more expensive in some cases.
struct Array(T, A = typeof(null))
{
  @nogc:
  nothrow:

  enum size_t MinimumElementAllocationCount = 16;

  alias ElementType = T;

  static if(is(A == typeof(null)))
  {
    alias AllocatorType = typeof(GlobalAllocator);
    AllocatorType* AllocatorPtr = &GlobalAllocator;
  }
  else
  {
    alias AllocatorType = A;
    AllocatorType* AllocatorPtr;
  }

  ElementType[] AvailableMemory;

  // Is always a subset of AvailableMemory.
  ElementType[] Data;


  @property auto ref Allocator() inout { return *AllocatorPtr; }

  @property auto Capacity() const { return AvailableMemory.length; }

  @property auto Count() const { return Data.length; }
  @property auto opDollar() const { return Count; }

  @property bool IsEmpty() const { return Count == 0; }

  @property auto SlackFront() const { return Data.ptr - AvailableMemory.ptr; }
  @property auto SlackBack() const { return Capacity - Count - SlackFront; }

  // Note(Manu): Disable copy construction.
  @disable this(this);

  this(ref AllocatorType Allocator)
  {
    AllocatorPtr = &Allocator;
  }

  ~this()
  {
    ClearMemory();
  }

  void ClearMemory()
  {
    Clear();
    Allocator.DeleteUndestructed(AvailableMemory);
    AvailableMemory = null;
    Data = null;
  }

  void Clear()
  {
    DestructArray(Data);

    // Make sure Data.ptr is still within AvailableMemory
    // but has a length of 0.
    Data = AvailableMemory[0 .. 0];
  }

  inout(ElementType)[] opSlice(size_t LeftIndex, size_t RightIndex) inout
  {
    return Data[LeftIndex .. RightIndex];
  }

  inout(ElementType)[] opIndex() inout { return Data; }

  ref inout(ElementType) opIndex(IndexType)(IndexType Index) inout
   if(Meta.IsIntegral!IndexType)
  {
    return Data[Index];
  }

  /// Makes sure AvailableMemory is big enough to hold RequiredCapacity
  /// elements.
  ///
  /// This function tries to minimize the work it has to do, i.e. if there's
  /// enough Capacity already to store RequiredCapacity elements, then nothing
  /// is done. Note that this function might still modify the Data member,
  /// depending on the circumstances.
  ///
  /// The actual amount of allocated memory (if any) will be greater than
  /// RequiredCapacity in most cases.
  ///
  /// See_Also: ReserveFront
  void Reserve(size_t RequiredCapacity)
  {
    // If there's enough room in the back already, we don't do anything.
    if(Count + SlackBack >= RequiredCapacity) return;

    // If there's enough total memory available, we move all data to the
    // front.
    if(Capacity >= RequiredCapacity)
    {
      AlignDataFront();
      return;
    }

    auto NewCapacity = MinimumElementAllocationCount;
    while(NewCapacity < RequiredCapacity) NewCapacity *= 2;

    auto NewMemory = Allocator.NewUnconstructedArray!ElementType(NewCapacity);
    if(NewMemory.length == NewCapacity)
    {
      auto NewData = NewMemory[0 .. Count];
      Data.MoveTo(NewData);
      ClearMemory();
      AvailableMemory = NewMemory;
      Data = NewData;
    }
    else
    {
      // TODO(Manu): What to do when out of memory?
      assert(0, "Out of memory");
    }
  }


  /// Same as Reserve but reserves memory in the front for PushBack
  /// operations.
  ///
  /// See_Also: Reserve
  void ReserveFront(size_t RequiredCapacity)
  {
    // If there's enough room in the back already, we don't do anything.
    if(SlackFront + Count >= RequiredCapacity) return;

    // If there's enough total memory available, we move all data to the
    // front.
    if(Capacity >= RequiredCapacity)
    {
      AlignDataBack();
      return;
    }

    auto NewCapacity = MinimumElementAllocationCount;
    while(NewCapacity < RequiredCapacity) NewCapacity *= 2;

    auto NewMemory = Allocator.NewUnconstructedArray!ElementType(NewCapacity);
    if(NewMemory.length == NewCapacity)
    {
      auto NewData = NewMemory[$ - Count .. $];
      Data.MoveTo(NewData);
      ClearMemory();
      AvailableMemory = NewMemory;
      Data = NewData;
    }
    else
    {
      // TODO(Manu): What to do when out of memory?
      assert(0, "Out of memory");
    }
  }

  void PushBack(ArgTypes...)(auto ref ArgTypes Args)
    if(ArgTypes.length)
  {
    auto NewData = ExpandUninitialized(ArgTypes.length);
    size_t InsertionIndex;
    foreach(ref Arg; Args)
    {
      static assert(Meta.IsConvertibleTo!(typeof(Arg), ElementType),
                    Format("Expected something that is convertible to %s, got %s",
                           ElementType.stringof, typeof(Arg).stringof));

      NewData[InsertionIndex++] = Arg;
    }
  }

  void PushBack(InputType : ElementType)(InputType[] Slice)
  {
    const NumNewElements = Slice.length;
    if(NumNewElements)
    {
      ExpandUninitialized(NumNewElements)[] = Slice[];
    }
  }

  void opOpAssign(string Op : "~", ArgType)(auto ref ArgType Arg)
  {
    PushBack(Arg);
  }

  void PopBack(size_t Amount = 1)
  {
    DestructArray(Data[$ - Amount .. $]);
    Data = Data[0 .. $ - Amount];
  }

  // TODO(Manu): PushFront

  void PopFront(size_t Amount = 1)
  {
    DestructArray(Data[0 .. Amount]);
    Data = Data[Amount .. $];
  }

  @property ref auto Front() inout { return Data[0]; }
  @property ref auto Back() inout { return Data[0]; }

  void RemoveAt(IndexType, CountType)(IndexType Index, CountType CountToRemove = 1)
  {
    assert(CountToRemove >= 0 && Index >= 0 && Index + CountToRemove <= Count);

    const EndIndex = Index + CountToRemove;
    auto Hole = Data[Index .. EndIndex];
    DestructArray(Hole);

    Data[EndIndex .. $].CopyTo(Data[Index .. $ - CountToRemove]);
    Data = Data[0 .. $ - CountToRemove];
  }

  void RemoveAtSwap(IndexType, CountType)(IndexType Index, CountType CountToRemove = 1)
  {
    auto Hole = Data[Index .. Index + CountToRemove];
    DestructArray(Hole);

    const NumElementsAfterHole = Data.length - (Index + CountToRemove);
    const NumElementsToMove = Min(Hole.length, NumElementsAfterHole);

    Data[$ - NumElementsToMove .. $].MoveTo(Hole[0 .. NumElementsToMove]);

    Data = Data[0 .. $ - CountToRemove];
  }

  ElementType[] ExpandUninitialized(size_t NumNewElements)
  {
    assert(NumNewElements >= 1);
    const OldCount = this.Count;
    const NewCount = OldCount + NumNewElements;
    Reserve(NewCount);
    const Offset = SlackFront;
    assert(Capacity >= Offset + NewCount);
    Data = AvailableMemory[Offset .. Offset + NewCount];
    auto Result = Data[$ - NumNewElements .. $];
    return Result;
  }

  /// Expand (at the back) by a single element without initializing it.
  ref ElementType ExpandUninitialized() { return ExpandUninitialized(1)[0]; }

  ElementType[] Expand(size_t NumNewElements)
  {
    auto Result = ExpandUninitialized(NumNewElements);
    ConstructArray(Result);
    return Result;
  }

  /// Expand (at the back) by a single element.
  ref ElementType Expand() { return Expand(1)[0]; }

  /// Makes sure all Data is moved to the front of AvailableMemory. You will
  /// only need this when you alternate a lot between PushBack and PushFront.
  void AlignDataFront()
  {
    if(SlackFront)
    {
      const Count = this.Count;
      auto NewData = AvailableMemory[0 .. Count];
      Data.CopyTo(NewData);
      Data = NewData;
    }
  }

  /// Makes sure all Data is moved to the back of AvailableMemory. You will
  /// only need this when you alternate a lot between PushBack and PushFront.
  void AlignDataBack()
  {
    if(SlackBack)
    {
      const Count = this.Count;
      auto NewData = AvailableMemory[$ - Count .. $];
      Data.CopyTo(NewData);
      Data = NewData;
    }
  }

  /// InputRange interface
  alias empty = IsEmpty;
  /// Ditto
  alias front = Front;
  /// Ditto
  alias popFront = PopFront;

  /// ForwardRange interface
  // TODO(Manu): Implement proper copying.
  //auto save() const { return this; }

  /// BidirectionalRange interface
  alias back = Back;
  /// Ditto
  alias popBack = PopBack;

  /// RandomAccessRange interface
  // Note(Manu): opIndex is implemented above.
  alias length = Count;

  /// OutputRange interface
  alias put = PushBack;
}

template IsSomeArray(T)
{
  static if(is(T == Array!(T.ElementType, T.AllocatorType)))
  {
    enum bool IsSomeArray = true;
  }
  else
  {
    enum bool IsSomeArray = false;
  }
}

//
// Unit Tests
//

unittest
{
  alias IntArray = Array!int;
  static assert(Meta.IsInputRange!IntArray);
}

unittest
{
  mixin(SetupGlobalAllocatorForTesting!(1024));

  Array!int Arr;
  assert(Arr.Count == 0);
  static assert(!__traits(compiles, Arr.PushBack()));
  Arr.PushBack(123);
  assert(Arr.Count == 1);
  assert(Arr[0] == 123);
  Arr.PushBack(42, 1337, 666);
  assert(Arr.Count == 4);
  assert(Arr[1] == 42);
  assert(Arr[2] == 1337);
  assert(Arr[3] == 666);
  assert(Arr[][1] == 42);
  assert(Arr[][2] == 1337);
  assert(Arr[][3] == 666);
  assert(Arr[1..2].length == 1);
  assert(Arr[1..2][0] == 42);
  Arr.PopBack();
  assert(Arr.Count == 3);
  assert(Arr[0] == 123);
  assert(Arr[1] == 42);
  assert(Arr[2] == 1337);
  Arr.RemoveAt(0);
  assert(Arr.Count == 2);
  assert(Arr[0] == 42);
  Arr ~= 666;
  assert(Arr.Count == 3);
  Arr.RemoveAtSwap(0);
  assert(Arr.Count == 2);
  assert(Arr[0] == 666);
  assert(Arr[1] == 1337);

  Arr.ExpandUninitialized(2)[] = 768;
  assert(Arr.Count == 4);
  assert(Arr[0] == 666);
  assert(Arr[1] == 1337);
  assert(Arr[2] == 768);
  assert(Arr[3] == 768);

  Arr.RemoveAtSwap(1);
  assert(Arr.Count == 3);
  assert(Arr[0] == 666);
  assert(Arr[1] == 768);
  assert(Arr[2] == 768);

  Arr.PopBack();
  assert(Arr.Count == 2);
  assert(Arr[0] == 666);
  assert(Arr[1] == 768);

  int[3] Stuff = [4, 5, 9];
  Arr.PushBack(Stuff);
  assert(Arr.Count == 5);
  assert(Arr[0] == 666);
  assert(Arr[1] == 768);
  assert(Arr[2] == Stuff[0]);
  assert(Arr[3] == Stuff[1]);
  assert(Arr[4] == Stuff[2]);

  assert(Arr.Expand() == 0);

  Arr.Reserve(120);
  assert(Arr.Capacity >= 120);
  assert(Arr.Count == 6);
  assert(Arr[0] == 666);
  assert(Arr[1] == 768);
  assert(Arr[2] == Stuff[0]);
  assert(Arr[3] == Stuff[1]);
  assert(Arr[4] == Stuff[2]);
  assert(Arr[5] == 0);

  const OldCapacity = Arr.Capacity;
  Arr.Clear();
  assert(Arr.IsEmpty);
  assert(Arr.Capacity == OldCapacity);
  Arr ~= Stuff;
  assert(Arr.Count == 3);
  foreach(Index; 0 .. 3) assert(Arr[Index] == Stuff[Index]);

  Arr.ClearMemory();
  assert(Arr.IsEmpty);
  assert(Arr.Capacity == 0);

  Arr.Reserve(120);
  assert(Arr.Capacity >= 120);
  assert(Arr.Count == 0);

  Arr.PushBack(4, 5, 9);
  assert(Arr.Count == 3);
  assert(Arr[0] == 4);
  assert(Arr[1] == 5);
  assert(Arr[2] == 9);
}

unittest
{
  alias AllocatorType = ForwardAllocator!(StaticStackMemory!1024);
  alias ArrayType = Array!(int, AllocatorType);

  AllocatorType Allocator;
  auto Array = ArrayType(Allocator);
  assert(Array.AllocatorPtr);

  Array.PushBack(0, 1, 2, 3, 4);

  auto Slice = Array[1 .. 3];
  assert(Slice.length == 2);
  assert(Slice[0] == 1);
  assert(Slice[1] == 2);

  static assert(!__traits(compiles, Array.PushBack(1.0)),
                "A double is not implicitly convertible to an int.");
}
