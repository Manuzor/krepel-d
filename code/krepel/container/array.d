module krepel.container.array;

import krepel;
import krepel.algorithm : Min, Max;
import Meta = krepel.meta;

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
  }

  void Clear()
  {
    DestructArray(Data);
    Data = null;
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

  @property auto Count() const { return Data.length; }
  @property bool IsEmpty() const { return Count == 0; }

  @property auto SlackLeft() const { return Data.ptr - AvailableMemory.ptr; }
  @property auto SlackRight() const { return Capacity - Count - SlackLeft; }

  void Reserve(size_t NewCount)
  {
    // If there's enough space to the right of the current Data region, we
    // don't have to do anything.
    if(Count + SlackRight >= NewCount) return;

    // If we still have enough total memory available to account for NewCount,
    // we just move the current Data region to the left.
    if(Capacity >= NewCount)
    {
      assert(SlackLeft > 0,
             "When there's not enough room on the right of Data, but "
             "there's enough Capacity for NewCount, then the Data region must "
             "be somewhere to the right of AvailableMemory.ptr.");

      AvailableMemory[0 .. Count].CopyFrom(Data);
      Data = AvailableMemory[0 .. Count];
      return;
    }

    // If there is truly not enough space left, we allocate new space, move
    // the old data over to the new memory region and update AvailableMemory
    // and Data.
    NewCount = Max(NewCount, MinimumElementAllocationCount);
    auto NewMemory = Allocator.NewUnconstructedArray!ElementType(NewCount);
    if(NewMemory.length == NewCount)
    {
      const Count = this.Count;
      NewMemory[0 .. Count] = Data[];
      ClearMemory();
      AvailableMemory = NewMemory;
      Data = AvailableMemory[0 .. Count];
    }
    else
    {
      // TODO(Manu): What to do when out of memory?
      assert(0, "Out of memory");
    }
  }

  void PushBack(ArgTypes...)(in auto ref ArgTypes Args)
    if(ArgTypes.length)
  {
    auto PreviousCount = this.Count;

    // Reserve enough memory
    const NewCount = Data.length + ArgTypes.length;
    Reserve(NewCount);

    auto InsertionIndex = this.Count;
    Data = AvailableMemory[SlackLeft .. NewCount];
    foreach(ref Arg; Args)
    {
      static assert(Meta.IsConvertibleTo!(typeof(Arg), ElementType),
                    Format("Expected something that is convertible to %s, got %s",
                           ElementType.stringof, typeof(Arg).stringof));

      Data[InsertionIndex] = Arg;
      ++InsertionIndex;
    }
  }

  void PushBack(InputType : ElementType)(in InputType[] Slice)
  {
    // Reserve enough memory
    const OldCount = Data.length;
    const NewCount = Data.length + Slice.length;
    Reserve(NewCount);
    Data = AvailableMemory[SlackLeft .. NewCount];
    Data[OldCount .. NewCount] = Slice[];
  }

  void opOpAssign(string Op : "~", ArgType)(in auto ref ArgType Arg)
  {
    PushBack(Arg);
  }

  void PopBack(size_t Amount = 1)
  {
    DestructArray(Data[$-Amount .. $]);
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

    Hole[0 .. NumElementsToMove] = Data[$ - NumElementsToMove .. $];

    Data = Data[0 .. $ - CountToRemove];
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
  mixin(SetupGlobalAllocatorForTesting!(400));

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
