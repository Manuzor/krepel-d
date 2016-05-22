/// Primitives for low-level memory management.
///
/// Naming convention for these primitives is to let their name contain
/// "Memory", such as "HeapMemory".
module krepel.memory.allocator_primitives;

import krepel;
import krepel.memory;
import krepel.algorithm;
import krepel.math : IsPowerOfTwo, IsEven, IsOdd;
import Meta = krepel.meta;

struct MemoryVerifier
{
  import core.sys.windows.stacktrace;

  mixin CommonMemoryImplementation;

  bool Contains(in void[] SomeRegion){return false;}

  struct AllocationInfo
  {
    void[] Region;
    StackTrace Trace;
  }

  StaticStackMemory!(50.MiB) ArrayMemory;
  Array!(AllocationInfo) AllocatedMemory;
  IAllocator ChildAllocator;
  this(IAllocator Child)
  {
    ChildAllocator = Child;
    AllocatedMemory.Allocator = ArrayMemory.Wrap;
  }

  auto Allocate(size_t RequestedBytes, size_t Alignment = 0)
  {
    void[] NewMemory = ChildAllocator.Allocate(RequestedBytes, Alignment);

    AllocationInfo Info;
    Info.Region = NewMemory;
    Info.Trace = new StackTrace(2, null);
    foreach(Region; AllocatedMemory)
    {
      auto MaxStartAddress = Max(NewMemory.ptr, Region.Region.ptr);
      auto MinEndAddress = Min(NewMemory.ptr + NewMemory.length, Region.Region.ptr + Region.Region.length);
      if(Max(0, MinEndAddress - MaxStartAddress) > 0)
      {
        Log.Failure("Overlapping detected, between %x-%x and %x-%x of %d bytes\n======StackTrace first allocation:\n%s\n=====StackTrace conflicting allocation:\n%s",
          NewMemory.ptr,
          NewMemory.ptr + NewMemory.length,
          Region.Region.ptr,
          Region.Region.ptr + Region.Region.length,
          Max(0, MinEndAddress - MaxStartAddress),
          Region.Trace.toString(),
          Info.Trace.toString() );
        assert(0);
      }
    }
    AllocatedMemory ~= Info;
    return NewMemory;
  }

  /// See_Also: krepel.system.Deallocate
  bool Deallocate(void[] MemoryToDeallocate)
  {
    if (MemoryToDeallocate.ptr is null)
    {
      return false;
    }
    long MemoryIndex = -1;
    foreach(Index, Info; AllocatedMemory)
    {
      if (Info.Region == MemoryToDeallocate)
      {
        MemoryIndex = Index;
        break;
      }
    }
    if(MemoryIndex == -1 )
    {
      Log.Failure("Could not find allocation: %x-%x", MemoryToDeallocate.ptr, MemoryToDeallocate.ptr + MemoryToDeallocate.length);
    }

    assert(MemoryIndex > -1);
    AllocatedMemory.RemoveAtSwap(MemoryIndex);
    return ChildAllocator.Deallocate(MemoryToDeallocate);
  }
}

/// Forwards all calls to the appropriate krepel.system.* functions.
struct SystemMemory
{
  mixin CommonMemoryImplementation;

  private import krepel.system;

  /// See_Also: krepel.system.SystemMemoryAllocation
  auto Allocate(size_t RequestedBytes, size_t Alignment = 0)
  {
    return SystemMemoryAllocation(RequestedBytes,
                                  Alignment ? Alignment : GlobalDefaultAlignment);
  }

  /// See_Also: krepel.system.SystemMemoryReallocation
  auto Reallocate(void[] Memory, size_t RequestedBytes, size_t Alignment = 0)
  {
    return SystemMemoryReallocation(Memory,
                                    RequestedBytes,
                                    Alignment ? Alignment : GlobalDefaultAlignment);
  }

  /// See_Also: krepel.system.Deallocate
  bool Deallocate(void[] MemoryToDeallocate)
  {
    return SystemMemoryDeallocation(MemoryToDeallocate);
  }

  bool Contains(in void[] SomeRegion)
  {
    /// TODO(Manu): Support this somehow?
    return false;
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
  void[] Memory;
  size_t DefaultAlignment = GlobalDefaultAlignment;

  debug(HeapMemory) @property bool IsInitialized() const { return cast(bool)FirstBlock; }

  /// The number of bytes needed by a block header.
  enum BlockOverhead = BlockData.sizeof;

  /// The number of bytes required to make use of a block in the case the user
  /// requests 1 byte of memory with an alignment of 1.
  enum MinimumBlockSize = BlockOverhead + 1;

  mixin CommonMemoryImplementation;


  this(void[] AvailableMemory)
  {
    Initialize(AvailableMemory);
  }

  ~this()
  {
    Deinitialize();
  }

  void Initialize(void[] AvailableMemory)
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

  auto CalculateRequiredBlockSize(size_t RequestedBytes, size_t Alignment = 0) const
  {
    debug(HeapMemory)
    {
      assert(Alignment == 0 || Alignment < ubyte.max,
             "Alignment value is supposed to fit into 1 byte.");
      alias DeadBeefType = typeof(0xDeadBeef);
    }
    if(RequestedBytes == 0)
    {
      return 0;
    }

    if(Alignment == 0)
    {
      Alignment = DefaultAlignment;
    }
    const RequiredBytes = RequestedBytes + Alignment;
    const PaddingToAchieveAnEvenBlockSize = RequiredBytes.IsEven ? 0 : 1;
    debug(HeapMemory) auto RequiredBlockSize = BlockOverhead + RequiredBytes + PaddingToAchieveAnEvenBlockSize + DeadBeefType.sizeof;
    else              auto RequiredBlockSize = BlockOverhead + RequiredBytes + PaddingToAchieveAnEvenBlockSize;

    assert(RequiredBlockSize.IsEven);

    return RequiredBlockSize;
  }

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

    const RequiredBlockSize = CalculateRequiredBlockSize(RequestedBytes, Alignment);

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
    assert(RemainingAvailableSize.IsEven);

    if(RemainingAvailableSize >= MinimumBlockSize)
    {
      // We have enough space left for a new block, so we create one here.

      Block.Size = RequiredBlockSize;
      auto NewBlock = NextBlock(Block);
      NewBlock.Size = RemainingAvailableSize;
      NewBlock.IsAllocated = false;
    }

    debug(HeapMemory)
    {
      auto DeadBeefPointer = cast(DeadBeefType*)(cast(void*)Block + Block.Size - DeadBeefType.sizeof);
      *DeadBeefPointer = 0xDeadBeef;
    }

    return UserPointer[0 .. RequestedBytes];
  }

  bool Deallocate(void[] MemoryToDeallocate)
  {
    if(!MemoryToDeallocate) return false;
    if(!Contains(MemoryToDeallocate)) return false;

    ubyte PaddingSize = *cast(ubyte*)(MemoryToDeallocate.ptr - 1);
    auto Block = cast(BlockData*)(MemoryToDeallocate.ptr - PaddingSize - BlockData.sizeof);

    assert(IsValidBlockPointer(Block));

    assert(Block.Size.IsEven);
    //assert(Block.Size > 0);

    Block.IsAllocated = false;

    return true;
  }

  bool Contains(in void[] SomeRegion) const
  {
    const MemberBegin = FirstBlock;
    const MemberEnd = Memory.ptr + Memory.length;
    const RegionBegin = SomeRegion.ptr;
    const RegionEnd = SomeRegion.ptr + SomeRegion.length;
    return MemberBegin <= RegionBegin && // Lower bound
           RegionEnd <= MemberEnd;       // Upper bound
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
      assert(NewBlockSize > 0);
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
  static BlockData* NextBlock(BlockData* Block)
  {
    assert(Block);
    assert(Block.Size != 0);
    return cast(BlockData*)(cast(void*)Block + Block.Size);
  }

  auto IterateBlocks(BlockData* Start) const
  {
    static struct BlockRange
    {
      BlockData* Current;
      const BlockData* End;

      @property bool empty() const { return Current >= End; }
      @property BlockData* front() { return Current; }
      void popFront() { Current = NextBlock(Current); }
    }

    return BlockRange(Start, cast(BlockData*)(Memory.ptr + Memory.length));
  }


  /// Traverses all blocks, merging free adjacent blocks together, until a
  /// block is found that has the RequiredBlockSize (first fit).
  BlockData* FindFreeBlockAndMergeAdjacent(BlockData* Start, size_t RequiredBlockSize)
  {
    assert(RequiredBlockSize.IsEven);

    foreach(Block; IterateBlocks(Start))
    {
      if(!Block.IsAllocated)
      {
        MergeAdjacentFreeBlocks(Block);
        if(Block.Size >= RequiredBlockSize)
        {
          return Block;
        }
      }
    }

    return null;
  }

  /// Marches through the entire heap memory to ensure the given $(D Block) is
  /// actually a block pointer of this heap. No validation for the contents of
  /// the block are made. is valid.
  ///
  /// Remarks: This function can be very slow.
  bool IsValidBlockPointer(BlockData* Block) const
  {
    if(Block is null) return false;

    foreach(ValidBlock; IterateBlocks(Block))
    {
      if(Block is ValidBlock) return true;
    }

    return false;
  }

  /// Assumes $(D Block) is free and a valid block pointer.
  void MergeAdjacentFreeBlocks(BlockData* Block)
  {
    size_t NewBlockSize;
    foreach(NeighborBlock; IterateBlocks(Block))
    {
      if(NeighborBlock.IsAllocated) break; // Stop merging.
      NewBlockSize += NeighborBlock.Size;
    }

    // If we managed to merge some blocks, "expand" the given Block by
    // updating its size.
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
  void[] Memory;
  size_t AllocationMark;

  size_t DefaultAlignment = GlobalDefaultAlignment;

  bool IsInitialized;

  this(void[] AvailableMemory)
  {
    Initialize(AvailableMemory);
  }

  void Initialize(void[] AvailableMemory)
  {
    debug assert(!IsInitialized);

    Memory = AvailableMemory;
    IsInitialized = true;
  }

  mixin CommonStackMemoryImplementation;
  mixin Contains_DefaultImplementation!Memory;
}

struct StaticStackMemory(size_t N)
{
  static assert(N > 0, "Need at least one byte of static memory.");

  void[N] Memory;
  size_t AllocationMark;

  size_t DefaultAlignment = GlobalDefaultAlignment;

  enum bool IsInitialized = true;

  mixin CommonStackMemoryImplementation;
  mixin Contains_DefaultImplementation!Memory;
}

/// Common functionality for stack memory.
mixin template CommonStackMemoryImplementation()
{
  mixin CommonMemoryImplementation;

  void[] Allocate(size_t RequestedBytes, size_t Alignment = 0)
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

  bool Deallocate(void[] Memory)
  {
    return false;
  }
}


/// Common functionality for all memory types.
///
/// You should probably place this mixin last in your struct because it adds
/// data members to it and will mess up implicit member initialization.
mixin template CommonMemoryImplementation()
{
  alias ThisIsAMemoryType = typeof(this);

  private import krepel.memory.allocator_interface : MinimalAllocatorWrapper;
  package void[Meta.ClassInstanceSizeOf!MinimalAllocatorWrapper] WrapperMemory = void;
}

/// Adds the Contains() function to a memory type so it can be asked whether a
/// given memory region belongs to them.
mixin template Contains_DefaultImplementation(alias Member)
{
  bool Contains(in void[] SomeRegion) const
  {
    const MemberBegin = Member.ptr;
    const MemberEnd = Member.ptr + Member.length;
    const RegionBegin = SomeRegion.ptr;
    const RegionEnd = SomeRegion.ptr + SomeRegion.length;
    return MemberBegin <= RegionBegin && // Lower bound
           RegionEnd <= MemberEnd;       // Upper bound
  }
}

/// A template to determine whether the given type is a memory type.
template IsSomeMemory(M)
{
  static if(is(M.ThisIsAMemoryType)) enum bool IsSomeMemory = true;
  else                               enum bool IsSomeMemory = false;
}

//
// Unit Tests
//

// System Memory Allocation
unittest
{
  SystemMemory SystemHeap;

  auto Block1 = cast(ubyte[])SystemHeap.Allocate(32);
  assert(Block1);
  Block1[$-1] = cast(ubyte)123;

  auto Block2 = cast(ubyte[])SystemHeap.Allocate(8);
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

  auto Block3 = cast(ubyte[])SystemHeap.Allocate(9, 16);
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

// More Heap Memory
unittest
{
  ubyte[1.KiB] Buffer = void;
  foreach(Index, ref Byte; Buffer)
  {
    Byte = cast(ubyte)Index;
  }

  auto Heap = HeapMemory(Buffer[]);

  static struct AllocationInfo
  {
    bool IsAllocated;
    size_t Size;
    size_t Alignment;
    void[] Memory;
    void[] BlockMemory;

    @property size_t Padding() const { return *(cast(ubyte*)Memory.ptr - 1); }
    @property size_t Overhead() const { return HeapMemory.BlockOverhead + Padding; }
  }

  AllocationInfo TestAllocate(ref HeapMemory Heap, size_t Size, size_t Alignment)
  {
    AllocationInfo Result;
    Result.IsAllocated = true;
    Result.Size = Size;
    Result.Alignment = Alignment;
    auto BlockSize = Heap.CalculateRequiredBlockSize(Size, Alignment);
    Result.Memory = Heap.Allocate(Size, Alignment);
    Result.BlockMemory = (Result.Memory.ptr - Result.Overhead)[0 .. BlockSize];
    return Result;
  }

  void TestDeallocate(ref HeapMemory Heap, ref AllocationInfo Info)
  {
    assert(Info.IsAllocated);

    Heap.Deallocate(Info.Memory);
    Info.IsAllocated = false;
  }

  auto FirstAllocation = TestAllocate(Heap, 10, 8);
  assert(FirstAllocation.Memory.length == FirstAllocation.Size);
  assert(cast(ulong)FirstAllocation.Memory.ptr % FirstAllocation.Alignment == 0, "Pointer is not aligned to a multiple of the given alignment.");
  foreach(Index, Byte; cast(ubyte[])FirstAllocation.Memory)
  {
    const Number = FirstAllocation.Overhead + Index;
    assert(Byte == cast(ubyte)Number);
  }

  // Back up some crucial data.
  auto FirstMemory = FirstAllocation.Memory;
  auto FirstBlockMemory = FirstAllocation.BlockMemory;
  void[512] FirstBlockMemoryBackupBuffer = void;
  auto FirstBlockMemoryBackup = FirstBlockMemoryBackupBuffer[0 .. FirstBlockMemory.length];
  FirstBlockMemoryBackup[] = FirstBlockMemory[];

  TestDeallocate(Heap, FirstAllocation);

  FirstAllocation = TestAllocate(Heap, FirstAllocation.Size, FirstAllocation.Alignment);

  // Compare the new data with the backed-up version and ensure they're identical.
  assert(FirstAllocation.Memory is FirstMemory);
  assert(FirstAllocation.BlockMemory is FirstBlockMemory);
  assert(FirstAllocation.BlockMemory == FirstBlockMemoryBackup, "Contents should not have changed.");

  auto SecondAllocation = TestAllocate(Heap, 13, 32);
  assert(SecondAllocation.Memory.length == SecondAllocation.Size);
  assert(cast(ulong)SecondAllocation.Memory.ptr % SecondAllocation.Alignment == 0);
  for(size_t Index = 0; Index < SecondAllocation.Size; Index++)
  {
    const Base = FirstAllocation.BlockMemory.length + SecondAllocation.Overhead;
    const Number = Base + Index;
    const Byte = *cast(ubyte*)&SecondAllocation.Memory[Index];
    //io.writefln("Comparing Index %d: %d == %d", Index, Byte, Number);
    assert(Byte == cast(ubyte)Number);
  }

  // Make sure the data of the second allocation stays the same.
  for(size_t Index = 0; Index < FirstAllocation.Size; Index++)
  {
    const Number = FirstAllocation.Overhead + Index;
    const Byte = *cast(ubyte*)&FirstAllocation.Memory[Index];
    assert(Byte == cast(ubyte)Number);
  }

  // Back up block data.
  FirstMemory = FirstAllocation.Memory;
  FirstBlockMemory = FirstAllocation.BlockMemory;
  FirstBlockMemoryBackup[] = FirstBlockMemory[];
  auto SecondMemory = SecondAllocation.Memory;
  auto SecondBlockMemory = SecondAllocation.BlockMemory;
  void[512] SecondBlockMemoryBackupBuffer = void;
  auto SecondBlockMemoryBackup = SecondBlockMemoryBackupBuffer[0 .. SecondBlockMemory.length];
  SecondBlockMemoryBackup[] = SecondBlockMemory[];

  TestDeallocate(Heap, SecondAllocation);
  assert(FirstAllocation.BlockMemory == FirstBlockMemoryBackup);
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
    assert((cast(ubyte[])Block1)[Index] == Buffer[Index]);
  }

  auto Block2 = Stack.Allocate(64);
  assert(Block2.length == 64);
  assert(Block2.ptr == Block1.ptr + Block1.length);
  assert(Stack.AllocationMark == 32 + 64);
  for(size_t Index = 0; Index < Block2.length; Index++)
  {
    assert((cast(ubyte[])Block2)[Index] == Buffer[Block1.length + Index]);
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
