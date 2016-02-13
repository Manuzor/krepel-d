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

  ElementType[] Capacity;

  // Is always a subset of Capacity.
  ElementType[] Data;

  @property auto ref Allocator() inout { return *AllocatorPtr; }

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

  inout(ElementType)[] opIndex(T)(T[] Slice) inout
    if(is(T : inout(ElementType)))
  {
    return Slice;
  }

  auto Count() const { return Data.length; }

  void Reserve(size_t NewCount)
  {
    if(Capacity.length >= NewCount) return;

    NewCount = Max(NewCount, MinimumElementAllocationCount);
    auto NewMemory = Allocator.NewUnconstructedArray!(ElementType)(NewCount);
    if(NewMemory.length == NewCount)
    {
      const Count = this.Count;
      // TODO(Manu): Move data instead of copying?
      NewMemory[0 .. Count] = Data[];
      Destruct(Data);
      Allocator.DeleteUndestructed(Capacity);
      Capacity = NewMemory;
      Data = Capacity[0 .. Count];
    }
    else
    {
      // TODO(Manu): What to do when out of memory?
      assert(0, "Out of memory");
    }
  }

  void PushBack(ArgTypes...)(auto ref ArgTypes Args)
  {
    static assert(is(ArgTypes[0] : ElementType),
                  "The input type " ~ ArgTypes[0].stringof ~
                  " is not compatible to " ~ ElementType.stringof);

    const Offset = Data.ptr - Capacity.ptr;
    auto NewCount = Data.length + ArgTypes.length;
    auto InsertionIndex = Data.length;
    Reserve(Data.length + ArgTypes.length);
    Data = Capacity[Offset .. NewCount];
    foreach(Arg; Args)
    {
      Data[InsertionIndex] = Arg;
      ++InsertionIndex;
    }
  }

  void PopBack(size_t Amount = 1)
  {
    Destruct(Data[$-Amount .. $]);
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
  ubyte[100 * int.sizeof] Buffer;
  GlobalAllocator.Memory.Initialize(Buffer[]);
  scope(exit) GlobalAllocator.Memory.Memory = null;

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
