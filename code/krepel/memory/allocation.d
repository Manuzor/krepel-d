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
/// given memory region belongs to them.
mixin template MemoryContainsCheckMixin(alias Member)
{
  bool Contains(const MemoryRegion SomeRegion) const
  {
    bool IsWithinLeftBound  = SomeRegion.ptr >= Member.ptr;
    bool IsWithinRightBound = SomeRegion.ptr + SomeRegion.length <= Member.ptr + Member.length;
    return IsWithinLeftBound && IsWithinRightBound;
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

  /// Creates a new instance of Type without constructing it.
  Type* NewUnconstructed(Type)()
  {
    auto Raw = Memory.Allocate(Type.sizeof, Type.alignof);
    if(Raw is null) return null;
    assert(Raw.length >= Type.sizeof);
    auto Instance = cast(Type*)Raw.ptr;
    return Instance;
  }

  /// Free the memory occupied by Instance without destructing it.
  /// Note: If the memory type used does not support deallocation
  ///       (e.g. StackMemory), this function does nothing.
  void DeleteUndestructed(Type)(Type* Instance)
  {
    static if(MemoryType.Features & SupportsDeallocation)
    {
      if(Instance)
      {
        Memory.Deallocate(Instance[0 .. Type.sizeof]);
      }
    }
  }

  /// Allocate a new instance of type Type and construct it using the given Args.
  Type* New(Type, ArgTypes...)(auto ref ArgTypes Args)
    if(!is(Type == class))
  {
    return NewUnconstructed!Type().Construct(Args);
  }

  Type New(Type, ArgTypes...)(auto ref ArgTypes Args)
    if(is(Type == class))
  {
    static assert(!__traits(isAbstractClass, Type), "Cannot instantiate abstract class.");
    enum SizeOfT = __traits(classInstanceSize, Type);
    enum AlignmentOfT = Meta.ClassInstanceAlignment!Type;
    auto Raw = Memory.Allocate(SizeOfT, AlignmentOfT);
    if(Raw is null) return null;
    assert(Raw.length >= Type.sizeof);
    auto Instance = cast(Type)Raw.ptr;

    Construct(Instance, Args);
    return Instance;
  }

  /// Destruct the given Instance and free the memory occupied by it.
  /// Note: If the memory type used does not support deallocation
  ///       (e.g. StackMemory), this function only destructs Instance,
  ///       but does not free memory.
  void Delete(Type)(Type* Instance)
  {
    if(Instance)
    {
      Destruct(Instance);
      DeleteUndestructed(Instance);
    }
  }

  /// Creates a new array of Type's without constructing them.
  Type[] NewUnconstructedArray(Type)(size_t Count)
  {
    // TODO(Manu): Implement.
    auto RawMemory = Memory.Allocate(Count * Type.sizeof, Type.alignof);

    // Out of memory?
    if(RawMemory is null) return null;

    auto Array = cast(Type[])RawMemory[0 .. Count * Type.sizeof];
    return Array;
  }

  /// Free the memory occupied by the given Array without destructing its
  /// elements.
  /// Note: If the memory type used does not support deallocation
  ///       (e.g. StackMemory), this function does nothing.
  void DeleteUndestructed(Type)(Type[] Array)
  {
    static if(MemoryType.Features & SupportsDeallocation)
    {
      Memory.Deallocate(cast(ubyte[])Array);
    }
  }

  /// Creates a new array of Type's and construct each element of it with the
  /// given Args.
  Type[] NewArray(Type, ArgTypes...)(size_t Count, auto ref ArgTypes Args)
  {
    auto Array = NewUnconstructedArray!Type(Count);
    Construct(Array, Args);
    return Array;
  }

  /// Destructs all elements of Array and frees the memory occupied by it.
  /// Note: If the memory type used does not support deallocation
  ///       (e.g. StackMemory), this function only destructs Instance,
  ///       but does not free memory.
  void Delete(Type)(Type[] Array)
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

debug = HeapMemory;

/// Can allocate arbitrary sizes of memory blocks and deallocate them in any
/// order.
///
/// Uses an implicit free list and a first-fit for allocations.
///
/// Usually a block has a boundary tag at the end to indicate the size of that
/// block. This is done to enable bidirectional traversal from any given
/// block. This implementation, however, does not require such a boundary tag.
/// When allocating memory, a linear search is performed, starting from the
/// first block. Along the way, all adjacent free blocks are merged, until a
/// suitable block is found that satisfies the block size requirements of that
/// allocation request. Thus, we lazily merge adjacent free blocks on demand
/// only.
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

  debug(HeapMemory) @property bool IsInitialized() const { return cast(bool)FirstBlock; }

  /// The number of bytes needed by a block header.
  enum BlockOverhead = size_t.sizeof;

  /// The number of bytes required to make use of a block in the case the user
  /// requests 1 byte of memory with an alignment of 1.
  enum MinimumBlockSize = BlockOverhead + 1;


  this(MemoryRegion AvailableMemory)
  {
    Initialize(AvailableMemory);
  }

  void Initialize(MemoryRegion AvailableMemory)
  {
    debug(HeapMemory)
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

  void Deinitialize() { FirstBlock = null; }

  auto Allocate(size_t RequestedBytes, size_t Alignment = 0)
  {
    debug(HeapMemory)
    {
      assert(IsInitialized, "Heap memory is not initialized.");
      assert(Alignment == 0 || Alignment < ubyte.max,
             "Alignment value is supposed to fit into 1 byte.");
      alias DeadBeefType = typeof(0xDeadBeef);
    }

    if(RequestedBytes == 0) return null;

    if(Alignment == 0) Alignment = DefaultAlignment;

    const RequiredBytes = RequestedBytes + Alignment;
    debug(HeapMemory) const RequiredBlockSize = BlockOverhead + RequiredBytes + DeadBeefType.sizeof;
    else                   const RequiredBlockSize = BlockOverhead + RequiredBytes;

    auto Block = FindFreeBlockAndMergeAdjacent(FirstBlock, RequiredBlockSize);

    // No suitable block was found, so we are out of memory for this
    // allocation request.
    if(!Block) return null;

    const PotentialUserPointer = cast(ubyte*)Block + BlockOverhead;
    auto UserPointer = AlignedPointer(PotentialUserPointer, Alignment);
    if(UserPointer == PotentialUserPointer)
    {
      // The UserPointer is perfectly aligned. However, we need space to save
      // the padding value, so we shift to the next alignment boundary.
      UserPointer += Alignment;
    }
    const PaddingSize = UserPointer - PotentialUserPointer;
    assert(PaddingSize > 0 && PaddingSize <= Alignment);

    // Save padding size.
    *(UserPointer - 1) = cast(ubyte)PaddingSize;
    Block.IsAllocated = true;

    const RemainingAvailableSize = Block.Size - RequiredBlockSize;

    if(RemainingAvailableSize >= MinimumBlockSize)
    {
      // We have enough space left for a new block, so we create one here.

      Block.Size = RequiredBlockSize;
      auto NewBlock = NextBlock(Block);
      NewBlock.Size = AlignedSize(RemainingAvailableSize - 1, 2);
      NewBlock.IsAllocated = false;
    }

    debug(HeapMemory)
    {
      auto DeadBeefPointer = cast(DeadBeefType*)(cast(ubyte*)Block + Block.Size - DeadBeefType.sizeof);
      *DeadBeefPointer = 0xDeadBeef;
    }

    return UserPointer[0 .. RequestedBytes];
  }

  bool Deallocate(MemoryRegion MemoryToDeallocate)
  {
    if(!MemoryToDeallocate) return false;

    ubyte PaddingSize = *(MemoryToDeallocate.ptr - 1);
    auto Block = cast(BlockData*)(MemoryToDeallocate.ptr - PaddingSize - BlockData.sizeof);

    if(!IsValidBlockPointer(Block)) return false;

    Block.IsAllocated = false;

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

  /// Traverses all blocks, merging free adjacent blocks together, until a
  /// block is found that has the RequiredBlockSize (first fit).
  BlockData* FindFreeBlockAndMergeAdjacent(BlockData* Block, size_t RequiredBlockSize)
  {
    while(IsValidBlockPointer(Block))
    {
      if(!Block.IsAllocated)
      {
        MergeAdjacentFreeBlocks(Block);
        if(Block.Size >= RequiredBlockSize)
        {
          return Block;
        }
      }

      Block = NextBlock(Block);
    }

    return null;
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

    if(NewBlockSize != Block.Size)
    {
      assert(NewBlockSize > Block.Size, "We are supposed to merge free "
                                        "blocks together and GAIN space "
                                        "here, not lose it!");

      Block.Size = NewBlockSize;
    }
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

    const MemoryPointer = Memory.ptr + AllocationMark;
    auto AlignedMemoryPointer = AlignedPointer(MemoryPointer, Alignment);
    const Padding = AlignedMemoryPointer - MemoryPointer;
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

  auto Block3 = SystemHeap.Allocate(9, 16);
  assert(Block3);
  assert(Block3.ptr == AlignedPointer(Block3.ptr, 16));
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
  ubyte[256] HeapBuffer;
  auto Stack  = StaticStackMemory!32();
  auto Heap   = HeapMemory(HeapBuffer[]);
  auto Hybrid = HybridMemory!(typeof(Stack)*, typeof(Heap)*)(&Stack, &Heap);

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
  assert(Data.Boolean == false);
  assert(Data.Integer == 0xDeadBeef);

  Data = StackAllocator.NewUnconstructed!TestData();
  // StackAllocator's memory is initialized to zero, so all the unconstructed
  // data we get from it must also be 0.
  assert(Data.Boolean == false);
  assert(Data.Integer == 0);
  Construct(Data);
  assert(Data.Boolean == true);
  assert(Data.Integer == 42);
}

// ForwardAllocator allocating class instances.
unittest
{
  class SuperClass
  {
    int Data() { return 42; }
  }

  class SubClass : SuperClass
  {
    override int Data() { return 1337; }
  }

  ForwardAllocator!(StaticStackMemory!128) StackAllocator;
  SuperClass Instance = StackAllocator.New!SubClass();
  assert(Instance);
  assert(Instance.Data == 1337);
}