module krepel.memory.allocation;

import krepel;
import krepel.memory;
import krepel.algorithm;
import krepel.math : IsPowerOfTwo, IsEven, IsOdd;
import Meta = krepel.meta;

/// The global default allocator.
__gshared ForwardAllocator!HeapMemory GlobalAllocator;

/// Memory Features
enum : ubyte
{
  SupportsAllocationOnly  = 0,
  SupportsReallocation    = 1 << 0,
  SupportsDeallocation    = 1 << 1,
}

/// Common functionality for all memory types.
mixin template MemoryMixinTemplate(size_t InFeatures)
{
  alias ThisIsAMemoryType = typeof(this);
  enum size_t Features = InFeatures;
}

/// Adds the Contains function to a memory type so it can be asked whether a
/// given memory region or pointer belongs to this memory.
mixin template MemoryContainsCheckMixin(alias Member)
{
  bool Contains(const MemoryRegion SomeRegion) const
  {
    return SomeRegion.ptr >= Member.ptr &&
           SomeRegion.ptr - Member.ptr + SomeRegion.length < Member.length;
  }

  bool Contains(const ubyte* SomePointer) const
  {
    return SomePointer >= Member.ptr &&
           SomePointer < Member.ptr + Member.length;
  }
}

/// A template to determine whether the given type is a memory type.
template IsSomeMemory(M)
{
  static if(is(M.ThisIsAMemoryType)) enum bool IsSomeMemory = true;
  else                               enum bool IsSomeMemory = false;
}

/// An allocator that wraps a given memory type used to allocate single
/// objects or entire arrays.
struct ForwardAllocator(M)
{
  alias MemoryType = M;
  static assert(IsSomeMemory!MemoryType);

  MemoryType Memory;

  /// Creates a new instance of T without constructing it.
  T* NewUnconstructed(T)()
  {
    auto Raw = Memory.Allocate(T.sizeof, T.alignof);
    if(Raw is null) return null;
    assert(Raw.length >= T.sizeof);
    auto Instance = cast(T*)Raw.ptr;
    return Instance;
  }

  /// Free the memory occupied by Instance without destructing it.
  /// Note: If the memory type used does not support deallocation
  ///       (e.g. StackMemory), this function does nothing.
  void DeleteUndestructed(T)(T* Instance)
  {
    static if(MemoryType.Features & SupportsDeallocation)
    {
      if(Instance)
      {
        Memory.Deallocate(Instance[0 .. T.sizeof]);
      }
    }
  }

  /// Allocate a new instance of type T and construct it using the given Args.
  T* New(T, ArgTypes...)(auto ref ArgTypes Args)
  {
    auto Instance = NewUnconstructed!T();
    Construct(*Instance, Args);
    return Instance;
  }

  /// Destruct the given Instance and free the memory occupied by it.
  /// Note: If the memory type used does not support deallocation
  ///       (e.g. StackMemory), this function only destructs Instance,
  ///       but does not free memory.
  void Delete(T)(T* Instance)
  {
    if(Instance)
    {
      Destruct(*Instance);
      DeleteUndestructed(Instance);
    }
  }

  /// Creates a new array of T's without constructing them.
  T[] NewUnconstructedArray(T)(size_t Count)
  {
    // TODO(Manu): Implement.
    auto RawMemory = Memory.Allocate(Count * T.sizeof, T.alignof);

    // Out of memory?
    if(RawMemory is null) return null;

    auto Array = cast(T[])RawMemory[0 .. Count * T.sizeof];
    return Array;
  }

  /// Free the memory occupied by the given Array without destructing its
  /// elements.
  /// Note: If the memory type used does not support deallocation
  ///       (e.g. StackMemory), this function does nothing.
  void DeleteUndestructed(T)(T[] Array)
  {
    static if(MemoryType.Features & SupportsDeallocation)
    {
      Memory.Deallocate(cast(ubyte[])Array);
    }
  }

  /// Creates a new array of T's and construct each element of it with the
  /// given Args.
  T[] NewArray(T, ArgTypes...)(size_t Count, auto ref ArgTypes Args)
  {
    auto Array = NewUnconstructedArray!T(Count);
    Construct(Array, Args);
    return Array;
  }

  /// Destructs all elements of Array and frees the memory occupied by it.
  /// Note: If the memory type used does not support deallocation
  ///       (e.g. StackMemory), this function only destructs Instance,
  ///       but does not free memory.
  void Delete(T)(T[] Array)
  {
    Destruct(Array);
    DeleteUndestructed(Array);
  }
}

/// Forwards all calls to the appropriate krepel.system.* functions.
struct SystemMemory
{
  mixin MemoryMixinTemplate!(SupportsReallocation | SupportsDeallocation);

  private import krepel.system;

  /// See_Also: krepel.system.SystemMemoryAllocation
  auto Allocate(size_t RequestedBytes, size_t Alignment = 0)
  {
    return SystemMemoryAllocation(RequestedBytes,
                                  Alignment ? Alignment : GlobalDefaultAlignment);
  }

  /// See_Also: krepel.system.SystemMemoryReallocation
  auto Reallocate(MemoryRegion Memory, size_t RequestedBytes, size_t Alignment = 0)
  {
    return SystemMemoryReallocation(Memory,
                                    RequestedBytes,
                                    Alignment ? Alignment : GlobalDefaultAlignment);
  }

  /// See_Also: krepel.system.Deallocate
  bool Deallocate(MemoryRegion MemoryToDeallocate)
  {
    return SystemMemoryDeallocation(MemoryToDeallocate);
  }
}

debug = DebugHeapMemory;

/// Can allocate arbitrary sizes of memory blocks and deallocate them in any
/// order.
///
/// Uses and implicit free list and a first-fit for allocations.
///
/// Layout of a memory block:
/// [********][??????????*][.??????????????]
///  \ Tag  /  \ Padding /  \ User Memory /
///
/// * => Reserved memory, implementation overhead.
/// ? => Unknown number of bytes
/// . => Byte used by the user
///
/// The `Tag` size is exactly size_t.sizeof bytes. It contains the size of the
/// block and a flag whether this block is allocated or not.
///
/// Padding is >= 1 byte. The byte to the far right encodes a ubyte value that
/// states the actual padding size. This value is used to free memory in an
/// efficient way while guaranteeing alignment requirements.
struct HeapMemory
{
  mixin MemoryMixinTemplate!(SupportsDeallocation);
  mixin MemoryContainsCheckMixin!(Memory);

  MemoryRegion Memory;
  size_t DefaultAlignment = GlobalDefaultAlignment;

  debug(DebugHeapMemory) @property bool IsInitialized() const { return cast(bool)FirstBlock; }

  // We need at least 1 byte for padding, so we can store the actual padding
  // value in that byte.
  enum MinimumPadding = 1;

  // A block consists of at least the Tag header and some padding. The
  // actual size of the padding is not known at compile-time, as it depends
  // on the given memory block and alignment.
  enum MinimumBlockOverhead = BlockData.sizeof + MinimumPadding;

  // The size a valid block must have at least, which is the
  // MinimumBlockOverhead plus at least 1 byte for the user.
  enum MinimumBlockSize = MinimumBlockOverhead + 1;


  this(MemoryRegion AvailableMemory)
  {
    Initialize(AvailableMemory);
  }

  void Initialize(MemoryRegion AvailableMemory)
  {
    debug(DebugHeapMemory)
    {
      assert(!IsInitialized, "Heap memory must not be initialized.");
      assert(DefaultAlignment.IsPowerOfTwo, "DefaultAlignment is expected to be a power of two.");
    }

    Memory = AvailableMemory;

    auto BlockSize = Memory.length;
    if(BlockSize.IsOdd) BlockSize--;
    FirstBlock = cast(BlockData*)Memory.ptr;
    FirstBlock.Size = BlockSize;
    FirstBlock.IsAllocated = false;
  }

  auto Allocate(size_t RequestedBytes, size_t Alignment = 0)
  {
    debug(DebugHeapMemory) assert(IsInitialized, "Heap memory is not initialized.");

    if(RequestedBytes == 0) return null;

    if(Alignment == 0) Alignment = DefaultAlignment;

    const RequestedBytesAligned = AlignedSize(RequestedBytes, 2);
    const MinimumRequiredBlockSize = MinimumBlockOverhead + RequestedBytesAligned;

    auto Block = cast(BlockData*)Memory.ptr;
    while(true)
    {
      // We cannot know the actual padding size, so FindFreeBlock might
      // return unusable results. This is why we use a while-loop here, so we
      // can try again with a different block that fits potentially.

      Block = FindFreeBlock(Block, MinimumRequiredBlockSize);
      if(!Block) break;

      auto UserMemoryPointer = AlignedPointer(cast(ubyte*)Block + MinimumBlockOverhead, Alignment);
      const PaddingSize = cast(ubyte)(UserMemoryPointer - cast(ubyte*)Block - BlockData.sizeof);
      const AvailableSize = Block.Size - BlockData.sizeof - PaddingSize;
      assert(AvailableSize.IsEven);

      if(AvailableSize < RequestedBytes) continue;

      // Actually allocate the current block.
      {
        *(UserMemoryPointer - 1) = PaddingSize;
        Block.IsAllocated = true;
      }

      // See if we can create a new block from the remaining block memory;
      {
        const RemainingBlockSize = AvailableSize - RequestedBytesAligned;
        if(RemainingBlockSize >= MinimumBlockSize)
        {
          Block.Size = BlockData.sizeof + PaddingSize + RequestedBytesAligned;
          auto NewFreeBlock = NextBlock(Block);
          NewFreeBlock.IsAllocated = false;
          NewFreeBlock.Size = RemainingBlockSize;
        }
      }

      return UserMemoryPointer[0 .. RequestedBytes];
    }

    // At this point, we are out of memory.
    return null;
  }

  bool Deallocate(MemoryRegion MemoryToDeallocate)
  {
    if(!MemoryToDeallocate) return false;

    ubyte PaddingSize = *(MemoryToDeallocate.ptr - 1);
    auto Block = cast(BlockData*)(MemoryToDeallocate.ptr - PaddingSize - BlockData.sizeof);

    if(!IsValidBlockPointer(Block)) return false;

    Block.IsAllocated = false;
    MergeAdjacentFreeBlocks(Block);

    return true;
  }

private:

  /// Represents the static data of a block. The actual memory block itself
  /// will be much larger than this.
  ///
  /// Note: The size of a block must be an even number. The lowest-order bit
  ///       is used as a flag.
  static struct BlockData
  {
    size_t HeaderData;

    @property size_t Size() { return HeaderData.RemoveBit(0); }
    @property void Size(size_t NewBlockSize)
    {
      assert(NewBlockSize.IsEven);
      // Preserve the allocation bit (first bit).
      HeaderData = NewBlockSize | (HeaderData & 1);
    }

    @property bool IsAllocated() { return HeaderData & 1; }
    @property void IsAllocated(bool Value)
    {
      HeaderData = HeaderData.RemoveBit(0) | (Value ? 1 : 0);
    }
  }

  static assert(BlockData.sizeof == size_t.sizeof);

  BlockData* FirstBlock;

  /// Gets the next block pointer to the "right" of the given block.
  BlockData* NextBlock(BlockData* Block)
  {
    assert(Block);
    return cast(BlockData*)(cast(ubyte*)Block + Block.Size);
  }

  BlockData* FindFreeBlock(BlockData* Block, size_t RequiredBlockSize)
  {
    while(IsValidBlockPointer(Block) &&
          (Block.IsAllocated || Block.Size < RequiredBlockSize))
    {
      Block = NextBlock(Block);
    }

    return Block;
  }

  /// A valid block pointer is a block that is not null and belongs to this heap's memory.
  bool IsValidBlockPointer(BlockData* Block)
  {
    return Block &&
           cast(ubyte*)Block - Memory.ptr <= Memory.length - MinimumBlockSize;
  }

  void MergeAdjacentFreeBlocks(BlockData* Block)
  {
    auto NewBlockSize = Block.Size;
    auto NeighborBlock = NextBlock(Block);
    while(IsValidBlockPointer(NeighborBlock) && !NeighborBlock.IsAllocated)
    {
      NewBlockSize += NeighborBlock.Size;
      NeighborBlock = NextBlock(NeighborBlock);
    }

    Block.Size = NewBlockSize;
  }
}

struct StackMemory
{
  MemoryRegion Memory;
  size_t AllocationMark;

  size_t DefaultAlignment = GlobalDefaultAlignment;

  bool IsInitialized;

  this(MemoryRegion AvailableMemory)
  {
    Initialize(AvailableMemory);
  }

  void Initialize(MemoryRegion AvailableMemory)
  {
    debug assert(!IsInitialized);

    Memory = AvailableMemory;
    IsInitialized = true;
  }

  mixin StackMemoryTemplate;
  mixin MemoryContainsCheckMixin!(Memory);
}

struct StaticStackMemory(size_t N)
{
  static assert(N > 0, "Need at least one byte of static memory.");

  StaticMemoryRegion!N Memory;
  size_t AllocationMark;

  size_t DefaultAlignment = GlobalDefaultAlignment;

  enum bool IsInitialized = true;

  mixin StackMemoryTemplate;
  mixin MemoryContainsCheckMixin!(Memory);
}

/// Common functionality for stack memory.
mixin template StackMemoryTemplate()
{
  mixin MemoryMixinTemplate!(SupportsAllocationOnly);

  MemoryRegion Allocate(size_t RequestedBytes, size_t Alignment = 0)
  {
    debug assert(IsInitialized, "This stack memory is not initialized.");

    if(RequestedBytes == 0) return null;

    if(Alignment == 0) Alignment = DefaultAlignment;

    const MemoryPointer = &Memory[AllocationMark];
    auto AlignedMemoryPointer = AlignedPointer(MemoryPointer, Alignment);
    const Padding = AlignedMemoryPointer - &Memory[AllocationMark];
    const NewMark = AllocationMark + Padding + RequestedBytes;

    // Out of memory?
    if(NewMark > Memory.length) return null;

    auto RequestedMemory = AlignedMemoryPointer[0 .. RequestedBytes];
    AllocationMark = NewMark;
    return RequestedMemory;
  }
}

/// Wraps two other memory types.
///
/// When allocating from the first memory fails, it tries the second one.
struct HybridMemory(P, S)
{
  alias PrimaryMemoryType = P;
  alias SecondaryMemoryType = S;

  static assert(IsSomeMemory!PrimaryMemoryType && IsSomeMemory!SecondaryMemoryType);

  mixin MemoryMixinTemplate!(PrimaryMemoryType.Features | SecondaryMemoryType.Features);

  PrimaryMemoryType    PrimaryMemory;
  SecondaryMemoryType  SecondaryMemory;


  auto Allocate(size_t RequestedBytes, size_t Alignment = 0)
  {
    auto RequestedMemory = PrimaryMemory.Allocate(RequestedBytes, Alignment);
    if(RequestedMemory) return RequestedMemory;
    return SecondaryMemory.Allocate(RequestedBytes, Alignment);
  }

  bool Deallocate(MemoryRegion MemoryToDeallocate)
  {
    static if(PrimaryMemoryType.Features & SupportsDeallocation)
    {
      if(PrimaryMemory.Contains(MemoryToDeallocate))
      {
        return PrimaryMemory.Deallocate(MemoryToDeallocate);
      }
    }

    static if(SecondaryMemoryType.Features & SupportsDeallocation)
    {
      return SecondaryMemory.Deallocate(MemoryToDeallocate);
    }
  }

  bool Contains(SomeType)(auto ref SomeType Something)
  {
    return PrimaryMemory.Contains(Something) || SecondaryMemory.Contains(Something);
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
  //debug {} else assert(!SystemHeap.Deallocate(Block2));
}

// Heap Memory Allocation
unittest
{
  ubyte[256] Buffer = void;
  for(int Index; Index < Buffer.length; Index++)
  {
    Buffer[Index] = cast(ubyte)Index;
  }

  auto Heap = HeapMemory(Buffer[]);

  auto Block1 = Heap.Allocate(16);
  assert(Block1.length == 16);
  auto Block2 = Heap.Allocate(16);
  assert(Block2.ptr != Block1.ptr);
  assert(Block2.length == 16);

  // TODO(Manu): Test reliably for the out-of-memory case somehow.
  //assert(Heap.Allocate(1) is null);

  assert(Heap.Deallocate(Block1));

  auto Block3 = Heap.Allocate(16);
  assert(Block3.ptr == Block1.ptr);
  assert(Block3.length == 16);
}

// Dynamic stack allocation
unittest
{
  ubyte[1024] Buffer = void;

  StackMemory Stack;
  // Only assign 128 bytes as memory.
  Stack.Initialize(Buffer[0 .. 128]);
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
  ubyte[256] Buffer;
  auto Heap1  = HeapMemory(Buffer[  0 .. 128]);
  auto Heap2  = HeapMemory(Buffer[128 .. 256]);
  auto Hybrid = HybridMemory!(HeapMemory*, HeapMemory*)(&Heap1, &Heap2);

  auto Block1 = Hybrid.Allocate(16);
  assert(Block1);
  assert(Block1.length == 16);
  assert(Heap1.Contains(Block1));
  auto Block2 = Hybrid.Allocate(16);
  assert(Block2.length == 16);
  assert(Heap1.Contains(Block1));
  auto Block3 = Hybrid.Allocate(16);
  assert(Block3.length == 16);
  assert(Heap1.Contains(Block1));
  auto Block4 = Hybrid.Allocate(16);
  assert(Block4);

  // TODO(Manu): Test reliably for the out-of-memory case somehow.
  //assert(Heap.Allocate(1) is null);
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
      Integer = 0xDeadBeef;
    }
  }

  ForwardAllocator!(StaticStackMemory!128) StackAllocator;

  auto Data = StackAllocator.New!TestData(false, 1337);
  static assert(Meta.IsPointer!(typeof(Data)), "New!() should always return a pointer!");
  assert(AlignedPointer(Data, TestData.alignof) == Data);
  assert(Data.Boolean == false);
  assert(Data.Integer == 1337);

  StackAllocator.Delete(Data);
  assert(Data.Integer == 0xDeadBeef);

  Data = StackAllocator.NewUnconstructed!TestData();
  assert(Data.Integer == 0);
  Construct(*Data);
  assert(Data.Boolean == true);
  assert(Data.Integer == 42);
}
