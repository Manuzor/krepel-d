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

  bool Deallocate(MemoryRegion MemoryToDeallocate)
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
