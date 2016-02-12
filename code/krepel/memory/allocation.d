module krepel.memory.allocation;

import krepel;
import krepel.memory;
import krepel.algorithm;
import Meta = krepel.meta;

__gshared ForwardAllocator!HeapMemory GlobalAllocator;

/// Memory Features
enum : ubyte
{
  SupportsAllocationOnly  = 0,
  SupportsReallocation    = 1 << 0,
  SupportsDeallocation    = 1 << 1,

  SupportsAllFeatures     = 0xFF,
}

mixin template MemoryMixinTemplate(size_t InFeatures)
{
  alias ThisIsAMemoryType = typeof(this);
  enum size_t Features = InFeatures;
}

template IsSomeMemory(M)
{
  static if(is(M.ThisIsAMemoryType)) enum bool IsSomeMemory = true;
  else                               enum bool IsSomeMemory = false;
}

struct ForwardAllocator(M)
{
  alias MemoryType = M;
  static assert(IsSomeMemory!MemoryType);

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
      static if(MemoryType.Features & SupportsDeallocation)
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
    Memory.Deallocate(cast(ubyte[])Array);
  }
}

/// Forwards all calls to the appropriate krepel.system.* functions.
struct SystemMemory
{
  mixin MemoryMixinTemplate!(SupportsAllFeatures);

  private import krepel.system;

  auto Allocate(size_t RequestedBytes)
  {
    return SystemMemoryAllocation(RequestedBytes);
  }

  auto Reallocate(MemoryRegion Memory, size_t RequestedBytes)
  {
    return SystemMemoryReallocation(Memory, RequestedBytes);
  }

  bool Deallocate(MemoryRegion MemoryToDeallocate)
  {
    return SystemMemoryDeallocation(MemoryToDeallocate);
  }
}

debug = DebugHeapMemory;

/// Can allocate arbitrary sizes of memory blocks and deallocate them in any order.
struct HeapMemory
{
  mixin MemoryMixinTemplate!(SupportsDeallocation);

  MemoryRegion Memory;
  MemoryRegion AllocatedMemory;

  debug(DebugHeapMemory) bool IsInitialized;

  private static struct Chunk
  {
    MemoryRegion NextChunk;
  }

  this(MemoryRegion AvailableMemory)
  {
    Initialize(AvailableMemory);
  }

  void Initialize(MemoryRegion AvailableMemory)
  {
    debug(DebugHeapMemory) assert(!IsInitialized, "Heap memory must not be initialized.");
    Memory = AvailableMemory;
    AllocatedMemory = AvailableMemory;
    debug(DebugHeapMemory) IsInitialized = true;
  }

  auto Allocate(size_t RequestedBytes)
  {
    debug(DebugHeapMemory) assert(IsInitialized, "Heap memory is not initialized.");

    // TODO(Manu): Alignment.

    if(RequestedBytes == 0) return null;

    // Make sure we only allocate enough to fit at least a Chunk in it.
    RequestedBytes = Max(RequestedBytes, Chunk.sizeof);

    if(RequestedBytes > AllocatedMemory.length) return null;

    auto RequestedMemory = AllocatedMemory[0 .. RequestedBytes];
    AllocatedMemory = AllocatedMemory[RequestedBytes .. $];
    return RequestedMemory;
  }

  bool Deallocate(MemoryRegion MemoryToDeallocate)
  {
    // TODO(Manu): Check whether MemoryToDeallocate actually belongs to this heap.
    // TODO(Manu): Implement deallocation.
    return true;
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
  mixin MemoryMixinTemplate!(SupportsAllocationOnly);

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

  bool Deallocate(ArgTypes...)(auto ref ArgTypes Args) { return false; }
}

struct HybridMemory(P, S)
{
  alias PrimaryMemoryType = P;
  alias SecondaryMemoryType = S;

  static assert(IsSomeMemory!PrimaryMemoryType && IsSomeMemory!SecondaryMemoryType);

  mixin MemoryMixinTemplate!(PrimaryMemoryType.Features | SecondaryMemoryType.Features);

  PrimaryMemoryType    PrimaryMemory;
  SecondaryMemoryType  SecondaryMemory;

  auto Allocate(size_t RequestedBytes)
  {
    auto RequestedMemory = PrimaryMemory.Allocate(RequestedBytes);
    if(RequestedMemory) return RequestedMemory;
    return SecondaryMemory.Allocate(RequestedBytes);
  }

  bool Deallocate(MemoryRegion MemoryToDeallocate)
  {
    return PrimaryMemory.Deallocate(MemoryToDeallocate) ||
           SecondaryMemory.Deallocate(MemoryToDeallocate);
  }
}

//
// Unit Tests
//

// System Memory Allocation
unittest
{
  SystemMemory SystemHeap;

  auto Block1 = SystemHeap.Allocate(32);
  assert(Block1);
  Block1[$-1] = cast(ubyte)123;

  auto Block2 = SystemHeap.Allocate(8);
  assert(Block2);
  Block2[] = 0xFU;
  foreach(ref Byte; Block2)
  {
    assert(Byte == 0xFU);
  }

  assert(SystemHeap.Deallocate(Block1));
  foreach(ref Byte; Block2)
  {
    assert(Byte == 0xFU);
  }

  assert(SystemHeap.Deallocate(Block2));
  debug {} else assert(!SystemHeap.Deallocate(Block2));
}

// Heap Memory Allocation
unittest
{
  ubyte[128] Buffer = void;
  for(int Index; Index < Buffer.length; Index++)
  {
    Buffer[Index] = cast(ubyte)Index;
  }

  auto Heap = HeapMemory(Buffer[0 .. 32]);

  auto Block1 = Heap.Allocate(16);
  assert(Block1.ptr == &Buffer[0]);
  assert(Block1.length == 16);
  auto Block2 = Heap.Allocate(16);
  assert(Block2.ptr == &Buffer[16]);
  assert(Block2.length == 16);

  assert(Heap.Allocate(1) is null);

  assert(Heap.Deallocate(Block1));
  Block1 = null; // Optional.

  auto Block3 = Heap.Allocate(16);
  // TODO(Manu): Can only test when deallocation is implemented.
  //assert(Block3.ptr == &Buffer[0]);
  //assert(Block3.length == 16);
}

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

// Static stack allocation
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

// HybridMemory tests
unittest
{
  ubyte[64] Buffer;
  auto Heap1  = HeapMemory(Buffer[ 0 .. 32]);
  auto Heap2  = HeapMemory(Buffer[32 .. 64]);
  auto Hybrid = HybridMemory!(HeapMemory*, HeapMemory*)(&Heap1, &Heap2);

  auto Block1 = Hybrid.Allocate(16);
  assert(Block1);
  assert(Block1.ptr == Heap1.Memory.ptr);
  auto Block2 = Hybrid.Allocate(16);
  assert(Block2);
  assert(Block2.ptr == Heap1.Memory.ptr + 16);
  auto Block3 = Hybrid.Allocate(16);
  assert(Block3);
  assert(Block3.ptr == Heap2.Memory.ptr);
  auto Block4 = Hybrid.Allocate(16);
  assert(Block4);
  assert(Block4.ptr == Heap2.Memory.ptr + 16);

  // We are out of memory now.
  assert(Hybrid.Allocate(1) is null);
}

// ForwardAllocator tests
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
