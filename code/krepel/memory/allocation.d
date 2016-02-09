module krepel.memory.allocation;

import krepel;
import krepel.memory;
import Meta = krepel.meta;

alias MemoryRegion = ubyte[];
alias StaticMemoryRegion(size_t N) = ubyte[N];

__gshared ForwardAllocator!HeapMemory GlobalAllocator;

struct ForwardAllocator(M)
{
  alias MemoryType = M;

  enum bool CanDeallocate = Meta.HasMember!(MemoryType, "Deallocate");

  MemoryType Memory;

  // Create a new T and call it's constructor.
  T* New(T, ArgTypes...)(auto ref ArgTypes Args)
  {
    auto Raw = Memory.Allocate(T.sizeof);
    if(Raw is null) return null;
    auto Instance = cast(T*)Raw.ptr;
    Construct(*Instance, Args);
    return Instance;
  }

  // Calls the destructor on the given Instance.
  // Deallocates memory only if the current memory type supports deallocation.
  void Delete(T)(T* Instance)
  {
    if(Instance)
    {
      Destruct(*Instance);
      static if(CanDeallocate)
      {
        Memory.Deallocate(Instance[0 .. T.sizeof]);
      }
    }
  }

  // NOTE: The allocated array will not be initialized!
  T[] NewArray(T)(size_t Count)
  {
    // TODO(Manu): Implement.
    auto RawMemory = Memory.Allocate(Count * T.sizeof);

    // Out of memory?
    if(RawMemory is null) return null;

    auto Array = cast(T[])RawMemory;
    assert(Array.length == Count);
    return Array;
  }

  // NOTE: Destructors won't be called!
  void Delete(T)(T[] Array)
  {
    static if(CanDeallocate)
    {
      Memory.Deallocate(cast(ubyte[])Array);
    }
  }
}

struct HeapMemory
{
  MemoryRegion Memory;

  auto Allocate(size_t RequestedBytes)
  {
    // TODO(Manu): Alignment.

    if(RequestedBytes == 0 || RequestedBytes > Memory.length) return null;

    auto RequestedMemory = Memory[0 .. RequestedBytes];
    Memory = Memory[RequestedBytes .. $];
    return RequestedMemory;
  }

  void Deallocate(MemoryRegion MemoryToDeallocate)
  {
    // TODO(Manu): Implement.
  }
}

struct StackMemory
{
  MemoryRegion Memory;
  size_t AllocationMark;

  mixin StackMemoryAllocationMixin;
}

struct StaticStackMemory(size_t N)
{
  static assert(N > 0, "Need at least one byte of static memory.");

  enum StaticCount = N;

  StaticMemoryRegion!N Memory;
  size_t AllocationMark;

  mixin StackMemoryAllocationMixin;
}

mixin template StackMemoryAllocationMixin()
{
  MemoryRegion Allocate(size_t RequestedBytes)
  {
    // TODO(Manu): Alignment.

    if(RequestedBytes == 0) return null;

    auto NewMark = AllocationMark + RequestedBytes;

    // Out of memory?
    if(NewMark > Memory.length) return null;

    auto RequestedMemory = Memory[AllocationMark .. NewMark];
    AllocationMark = NewMark;
    return RequestedMemory;
  }
}

//
// Unit Tests
//

// Dynamic stack allocation
unittest
{
  ubyte[1024] Buffer = void;

  StackMemory Stack;
  // Only assign 128 bytes as memory.
  Stack.Memory = Buffer[0 .. 128];
  assert(Stack.AllocationMark == 0);

  auto Block1 = Stack.Allocate(32);
  assert(Block1.length == 32);
  assert(Stack.AllocationMark == 32);
  for(size_t Index = 0; Index < Block1.length; Index++)
  {
    assert(Block1[Index] == Buffer[Index]);
  }

  auto Block2 = Stack.Allocate(64);
  assert(Block2.length == 64);
  assert(Block2.ptr == Block1.ptr + Block1.length);
  assert(Stack.AllocationMark == 32 + 64);
  for(size_t Index = 0; Index < Block2.length; Index++)
  {
    assert(Block2[Index] == Buffer[Block1.length + Index]);
  }

  // There's still room for a bit more, but 512 will not fit.
  auto Block3 = Stack.Allocate(512);
  assert(Block3 is null);
  assert(Stack.AllocationMark == 32 + 64, "Allocation mark should be unchanged.");
}

// Static allocation
unittest
{
  StaticStackMemory!128 Stack;

  auto Block1 = Stack.Allocate(32);
  assert(Block1);
  assert(Stack.AllocationMark == 32);

  auto Block2 = Stack.Allocate(64);
  assert(Block2);
  assert(Stack.AllocationMark == 32 + 64);

  auto Block3 = Stack.Allocate(128);
  assert(Block3 is null);
  assert(Stack.AllocationMark == 32 + 64);
}

unittest
{
  static struct TestData
  {
    bool Boolean = true;
    int Integer = 42;

    ~this()
    {
      Integer = 0xdeadbeef;
    }
  }

  ForwardAllocator!(StaticStackMemory!128) StackAllocator;

  auto Data = StackAllocator.New!TestData(false, 1337);
  static assert(Meta.IsPointer!(typeof(Data)), "New!() should always return a pointer!");
  assert(Data.Boolean == false);
  assert(Data.Integer == 1337);

  StackAllocator.Delete(Data);
  assert(Data.Integer == 0xdeadbeef);
}
