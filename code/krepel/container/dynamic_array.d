module krepel.container.dynamic_array;

import krepel.memory;
import krepel.algorithm : Max;
import Meta = krepel.meta;

struct DynamicArray(T, A = typeof(null))
{
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

  this(ref AllocatorType Allocator)
  {
    AllocatorPtr = &Allocator;
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

  void Reserve(size_t NewCount)
  {
    if(Capacity >= NewCount) return;

    NewCount = Max(NewCount, MinimumElementAllocationCount);
    auto NewMemory = Allocator.NewUnconstructedArray!(ElementType)(NewCount);
    if(NewMemory.length == NewCount)
    {
      const Count = this.Count;
      // TODO(Manu): Move data instead of copying?
      NewMemory[0 .. Count] = Data[];
      DestructArray(Data);
      Allocator.DeleteUndestructed(AvailableMemory);
      AvailableMemory = NewMemory;
      Data = AvailableMemory[0 .. Count];
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
    const Offset = Data.ptr - AvailableMemory.ptr;
    const NewCount = Data.length + ArgTypes.length;
    auto InsertionIndex = Data.length;
    Reserve(NewCount);
    Data = AvailableMemory[Offset .. NewCount];
    foreach(ref Arg; Args)
    {
      static assert(Meta.IsConvertibleTo!(typeof(Arg), ElementType),
                    "Invalid argument type " ~ typeof(Arg).stringof);
      Data[InsertionIndex] = Arg;
      ++InsertionIndex;
    }
  }

  void PushBack(InputType : ElementType)(InputType[] Slice)
  {
    const Offset = Data.ptr - AvailableMemory.ptr;
    const OldCount = Data.length;
    const NewCount = OldCount + Slice.length;
    Reserve(NewCount);
    Data = AvailableMemory[Offset .. NewCount];
    Data[OldCount .. NewCount] = Slice[];
  }

  void PopBack(size_t Amount = 1)
  {
    DestructArray(Data[$-Amount .. $]);
    Data = Data[0 .. $ - Amount];
  }
}

template IsSomeDynamicArray(T)
{
  static if(is(T == DynamicArray!(T.ElementType, T.AllocatorType)))
  {
    enum bool IsSomeDynamicArray = true;
  }
  else
  {
    enum bool IsSomeDynamicArray = false;
  }
}

//
// Unit Tests
//

unittest
{
  mixin(SetupGlobalAllocatorForTesting!(400));

  DynamicArray!int Arr;
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
}

unittest
{
  alias AllocatorType = ForwardAllocator!(StaticStackMemory!1024);
  alias ArrayType = DynamicArray!(int, AllocatorType);

  AllocatorType Allocator;
  auto Array = ArrayType(Allocator);
  assert(Array.AllocatorPtr);

  Array.PushBack(0, 1, 2, 3, 4);

  auto Slice = Array[1 .. 3];
  assert(Slice.length == 2);
  assert(Slice[0] == 1);
  assert(Slice[1] == 2);
}
