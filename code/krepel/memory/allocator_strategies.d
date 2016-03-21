/// Higher-level memory management strategies that makes use of allocator
/// primitives found in krepel.memory.allocator_primitives.
///
/// Strategy implementations should be named something with "Allocator", such
/// as "HybridAllocator". This will distringuish the higher level constructs
/// from allocator primitives, even though they share the same interface.
module krepel.memory.allocator_strategies;

import krepel.memory.common;
import krepel.memory.allocator_primitives;
import krepel.memory.allocator_interface;

/// Maintains an array of heap memory blocks of a given size
struct AutoHeapAllocator
{
  @nogc:
  nothrow:

  import krepel.container.array;

  /// Change this to affect the size of newly allocated heaps.
  size_t HeapSize;

  /// This allocator is used to allocate the heaps and their memories.
  IAllocator Allocator;

  /// The array of heaps used for allocating user memory.
  Array!HeapMemory Heaps;

  mixin CommonMemoryImplementation;


  bool Contains(in void[] SomeRegion)
  {
    foreach(ref Heap ; Heaps[])
    {
      if(Heap.Contains(SomeRegion)) return true;
    }
    return false;
  }

  /// Tries to allocate memory with the currently existing heaps and creates a
  /// new one if that fails.
  void[] Allocate(size_t RequestedBytes, size_t Alignment = 0)
  {
    // TODO(Manu): When we can gather some memory stats, we can check here
    // which heaps potentially have enough memory for RequestedBytes.
    foreach(ref Heap; Heaps[])
    {
      auto Memory = Heap.Allocate(RequestedBytes, Alignment);
      if(Memory) return Memory;
    }

    EnsureValidState();

    // TODO(Manu): assert(RequestedBytes < HeapSize)?
    const NewHeapSize = Max(RequestedBytes, HeapSize);
    auto NewHeap = &Heaps.Expand();
    auto NewHeapMemory = Allocator.Allocate(NewHeapSize, 1);
    NewHeap.Initialize(NewHeapMemory);

    return NewHeap.Allocate(RequestedBytes, Alignment);
  }

  bool Deallocate(void[] MemoryToDeallocate)
  {
    foreach(ref Heap; Heaps[])
    {
      if(Heap.Contains(MemoryToDeallocate))
      {
        return Heap.Deallocate(MemoryToDeallocate);
      }
    }

    return false;
  }

private:
  void EnsureValidState()
  {
    if(Allocator is null) Allocator = GlobalAllocator;

    if(HeapSize == 0)
    {
      // TODO(Manu): Logging?
      debug assert(false, "No heap size set for this AutoHeapAllocator.");
      else HeapSize = 1024;
    }

    if(Heaps.InternalAllocator is null) Heaps.InternalAllocator = Allocator;
  }
}


/// Wraps two other memory types.
///
/// When allocating from the first memory fails, it tries the second one.
struct HybridAllocator(P, S)
{
  alias PrimaryMemoryType = P;
  alias SecondaryMemoryType = S;

  static assert(IsSomeMemory!PrimaryMemoryType && IsSomeMemory!SecondaryMemoryType);

  PrimaryMemoryType    PrimaryMemory;
  SecondaryMemoryType  SecondaryMemory;

  mixin CommonMemoryImplementation;


  auto Allocate(size_t RequestedBytes, size_t Alignment = 0)
  {
    auto RequestedMemory = PrimaryMemory.Allocate(RequestedBytes, Alignment);
    if(RequestedMemory.length == RequestedBytes) return RequestedMemory;
    return SecondaryMemory.Allocate(RequestedBytes, Alignment);
  }

  bool Deallocate(void[] MemoryToDeallocate)
  {
    if(PrimaryMemory.Contains(MemoryToDeallocate))
    {
      return PrimaryMemory.Deallocate(MemoryToDeallocate);
    }
    return SecondaryMemory.Deallocate(MemoryToDeallocate);
  }

  bool Contains(SomeType)(auto ref SomeType Something)
  {
    return PrimaryMemory.Contains(Something) || SecondaryMemory.Contains(Something);
  }
}

//
// Unit Tests
//

// AutoHeapAllocator - Minimal tests.
unittest
{
  struct S
  {
    long First;
    long Second;
    long[2] More;
  }
  static assert(S.sizeof == 32);

  mixin(SetupGlobalAllocatorForTesting!2048);

  // Auto heap allocator using 64 bytes as heap size and the global allocator.
  auto AutoHeap = AutoHeapAllocator(64);
  auto Allocator = Wrap(AutoHeap);

  auto A = Allocator.New!S;
  auto B = Allocator.New!S;
  auto C = Allocator.New!S;

  assert(AutoHeap.Heaps.Count > 1);

  Allocator.Delete(A);
}

// HybridAllocator tests
unittest
{
  ubyte[256] HeapBuffer;
  auto Stack  = StaticStackMemory!32();
  auto Heap   = HeapMemory(HeapBuffer[]);
  auto Hybrid = HybridAllocator!(typeof(Stack)*, typeof(Heap)*)(&Stack, &Heap);

  auto Block1 = Hybrid.Allocate(16, 1);
  assert(Block1);
  assert(Block1.length == 16);
  assert(Stack.Contains(Block1));
  auto Block2 = Hybrid.Allocate(16, 1);
  assert(Block2.length == 16);
  assert(Stack.Contains(Block2));
  auto Block3 = Hybrid.Allocate(16);
  assert(Block3.length == 16);
  assert(!Stack.Contains(Block3));
  assert(Heap.Contains(Block3));
  auto Block4 = Hybrid.Allocate(16);
  assert(Block4);

  // Note(Manu): Cannot deallocate Block1 and Block2 since it's a stack
  // allocator.

  assert(Hybrid.Deallocate(Block3));
  assert(Hybrid.Deallocate(Block4));

  // TODO(Manu): Test reliably for the out-of-memory case somehow.
  //assert(Heap.Allocate(1) is null);
}
