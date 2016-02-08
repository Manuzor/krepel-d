module krepel.memory.allocation;

import krepel;
import krepel.memory;
import Meta = krepel.meta;

alias MemoryRegion = ubyte[];
alias StaticMemoryRegion(size_t N) = ubyte[N];

MemoryRegion GlobalMemory;
Allocator!HeapMemory GlobalAllocator;

struct HeapMemory
{
  MemoryRegion Memory;
}

auto Allocate(ref HeapMemory Heap, size_t RequestedBytes)
{
  with(Heap)
  {
    // TODO(Manu): Alignment.

    if(RequestedBytes == 0 || RequestedBytes > Memory.length) return null;

    auto RequestedMemory = Memory[0 .. RequestedBytes];
    Memory = Memory[RequestedBytes .. $];
    return RequestedMemory;
  }
}

void Deallocate(ref HeapMemory Heap, MemoryRegion MemoryToDeallocate)
{
  // TODO(Manu): Implement deallocation.
}

struct StackMemory(size_t N)
{
  enum bool HasStaticMemory = N > 0;

  static if(HasStaticMemory) { bool UseStaticMemory = true; }
  else                       { enum bool UseStaticMemory = false; }

  // If UseStaticMemory, this is an index into `StaticMemory`, otherwise it is
  // an index into `Memory`.
  size_t AllocationMark;

  MemoryRegion Memory;
  StaticMemoryRegion!N StaticMemory = void;

  this(MemoryRegion Memory)
  {
    this.Memory = Memory;
  }
}

MemoryRegion Allocate(size_t N)(ref StackMemory!N Stack, size_t RequestedBytes)
{
  // TODO(Manu): Alignment.

  if(RequestedBytes == 0) return null;

  with(Stack)
  {
    auto NewMark = AllocationMark + RequestedBytes;
    typeof(return) AllocationRegion;

    static if(HasStaticMemory) if(UseStaticMemory)
    {
      if(NewMark > StaticMemory.length)
      {
        // Check whether we can allocate at all.
        if(NewMark > Memory.length) return null;
        UseStaticMemory = false;
        AllocationMark = 0;
        NewMark = RequestedBytes;
      }
      else
      {
        AllocationRegion = StaticMemory;
      }
    }

    if(!UseStaticMemory)
    {
      if(NewMark > Memory.length) return null;

      AllocationRegion = Memory;
    }

    auto RequestedMemory = AllocationRegion[AllocationMark .. NewMark];
    AllocationMark = NewMark;

    return RequestedMemory;
  }
}

struct Allocator(M)
{
  alias MemoryType = M;

  MemoryType Memory;

  // Create a new T and call it's constructor.
  T* New(T, ArgTypes...)(auto ref ArgTypes Args)
  {
    auto Bytes = T.sizeof;
    auto Raw = Memory.Allocate(Bytes);
    assert(Raw, "Out of memory.");
    return Meta.Emplace!T(cast(void[])Raw, Args);
  }

  version(none)
  T[] NewArray(size_t N, T, ArgTypes...)(auto ref ArgTypes Args)
  {
    // TODO(Manu): Implement.
    return null;
  }

  // Calls the destructor on the given Instance.
  // Deallocates memory if, and only if the current memory type supports deallocation.
  void Delete(T)(T* Instance)
  {
    Meta.Destroy(Instance);
    static if(__traits(hasMember, MemoryType, "Deallocate"))
    {
      Memory.Deallocate(Instance[0 .. T.sizeof]);
    }
  }

  version(none)
  void Delete(T)(T[] Array)
  {
    // TODO(Manu): Implement.
  }
}

//
// Unit Tests
//

// Dynamic-only stack allocation
unittest
{
  ubyte[1024] Buffer = void;

  StackMemory!0 Stack;
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

// Static-only stack allocation
unittest
{
  StackMemory!128 Stack;

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

// Hybrid stack allocation
unittest
{
  ubyte[1024] Buffer;
  auto Stack = StackMemory!40(Buffer[0..128]); // Hybrid stack with 40 Bytes static memory and 128 Bytes

  static assert(Stack.HasStaticMemory);

  auto Block1 = Stack.Allocate(32);
  assert(Block1);
  assert(Stack.AllocationMark == 32);
  assert(Block1.ptr == Stack.StaticMemory.ptr);

  auto Block2 = Stack.Allocate(32);
  assert(Block2);
  assert(Stack.AllocationMark == 32);
  assert(Block2.ptr == Stack.Memory.ptr);

  auto Block3 = Stack.Allocate(512);
  assert(Block3 is null);
  assert(Stack.AllocationMark == 32);
  assert(!Stack.UseStaticMemory);
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

  Allocator!(StackMemory!128) StackAllocator;

  auto Data = StackAllocator.New!TestData(false, 1337);
  static assert(Meta.IsPointer!(typeof(Data)), "New!() should always return a pointer!");
  assert(Data.Boolean == false);
  assert(Data.Integer == 1337);

  StackAllocator.Delete(Data);
  assert(Data.Integer == 0xdeadbeef);
}
