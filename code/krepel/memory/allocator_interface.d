module krepel.memory.allocator_interface;

import krepel.memory.common;
import krepel.memory.construction;
import krepel.memory.allocator_primitives : IsSomeMemory;

/// Global allocator instance.
IAllocator GlobalAllocator;

/// General allocator interface.
interface IAllocator
{
  @nogc nothrow
  {
    bool Contains(in MemoryRegion SomeRegion);

    MemoryRegion Allocate(size_t RequestedBytes, size_t Alignment = 0);

    bool Deallocate(MemoryRegion MemoryToDeallocate);
  }

  // TODO(Manu): Add @nogc and nothrow for the rest of the interface once Construct and Destruct are compatible.

  /// Creates a new instance of Type without constructing it.
  final Type* NewUnconstructed(Type)()
    if(!is(Type == class))
  {
    auto Raw = Allocate(Type.sizeof, Type.alignof);
    if(Raw is null) return null;
    assert(Raw.length >= Type.sizeof);
    auto Instance = cast(Type*)Raw.ptr;
    return Instance;
  }

  /// Ditto
  final Type NewUnconstructed(Type)()
    if(is(Type == class))
  {
    enum Size = Meta.ClassInstanceSizeOf!Type;
    enum Alignment = Meta.ClassInstanceAlignmentOf!Type;
    auto Raw = Allocate(Size, Alignment);
    if(Raw is null) return null;
    assert(Raw.length >= Type.sizeof);
    auto Instance = cast(Type)Raw.ptr;
    return Instance;
  }

  /// Free the memory occupied by Instance without destructing it.
  /// Note: If the memory type used does not support deallocation
  ///       (e.g. StackMemory), this function does nothing.
  final void DeleteUndestructed(Type)(Type* Instance)
    if(!is(Type == class))
  {
    if(Instance)
    {
      Deallocate((cast(ubyte*)Instance)[0 .. Type.sizeof]);
    }
  }

  /// Ditto
  final void DeleteUndestructed(Type)(Type Instance)
    if(is(Type == class))
  {
    if(Instance)
    {
      Deallocate((cast(ubyte*)Instance)[0 .. Type.sizeof]);
    }
  }

  /// Allocate a new instance of type Type and construct it using the given Args.
  final Type* New(Type, ArgTypes...)(auto ref ArgTypes Args)
    if(!is(Type == class))
  {
    return .Construct(NewUnconstructed!Type(), Args);
  }

  final Type New(Type, ArgTypes...)(auto ref ArgTypes Args)
    if(is(Type == class))
  {
    static assert(!__traits(isAbstractClass, Type), "Cannot instantiate abstract class.");
    enum Size = Meta.ClassInstanceSizeOf!Type;
    enum Alignment = Meta.ClassInstanceAlignmentOf!Type;
    auto Raw = Allocate(Size, Alignment);
    if(Raw is null) return null;
    assert(Raw.length >= Type.sizeof);
    auto Instance = cast(Type)Raw.ptr;

    .Construct(Instance, Args);
    return Instance;
  }

  /// Destruct the given Instance and free the memory occupied by it.
  /// Note: If the memory type used does not support deallocation
  ///       (e.g. StackMemory), this function only destructs Instance,
  ///       but does not free memory.
  final void Delete(Type)(Type* Instance)
    if(!is(Type == class))
  {
    if(Instance)
    {
      .Destruct(Instance);
      DeleteUndestructed(Instance);
    }
  }

  /// Ditto
  final void Delete(Type)(Type Instance)
    if(is(Type == class))
  {
    if(Instance)
    {
      .Destruct(Instance);
      DeleteUndestructed(Instance);
    }
  }

  /// Creates a new array of Type's without constructing them.
  final Type[] NewUnconstructedArray(Type)(size_t Count)
  {
    // TODO(Manu): Implement.
    auto RawMemory = Allocate(Count * Type.sizeof, Type.alignof);

    // Out of memory?
    if(RawMemory is null) return null;

    auto Array = cast(Type[])RawMemory[0 .. Count * Type.sizeof];
    return Array;
  }

  /// Free the memory occupied by the given Array without destructing its
  /// elements.
  /// Note: If the memory type used does not support deallocation
  ///       (e.g. StackMemory), this function does nothing.
  final void DeleteUndestructed(Type)(Type[] Array)
  {
    Deallocate(cast(ubyte[])Array);
  }

  /// Creates a new array of Type's and construct each element of it with the
  /// given Args.
  final Type[] NewArray(Type, ArgTypes...)(size_t Count, auto ref ArgTypes Args)
  {
    auto Array = NewUnconstructedArray!Type(Count);
    .Construct(Array, Args);
    return Array;
  }

  /// Destructs all elements of Array and frees the memory occupied by it.
  /// Note: If the memory type used does not support deallocation
  ///       (e.g. StackMemory), this function only destructs Instance,
  ///       but does not free memory.
  final void Delete(Type)(Type[] Array)
  {
    .Destruct(Array);
    DeleteUndestructed(Array);
  }
}

/// Used to get the size of a minimal IAllocator class instance.
package class MinimalAllocatorWrapper : IAllocator
{
@nogc:
nothrow:

  /// The actual memory to wrap.
  void* WrappedPtr;

  bool Contains(in MemoryRegion SomeRegion) { return false; }
  MemoryRegion Allocate(size_t RequestedBytes, size_t Alignment = 0) { return null; }
  bool Deallocate(MemoryRegion MemoryToDeallocate) { return false; }
}

template Wrap(SomeMemoryType)
  if(IsSomeMemory!SomeMemoryType)
{
  class WrapperClass : IAllocator
  {
  @nogc:
  nothrow:

    SomeMemoryType* WrappedPtr;

    final override bool Contains(in MemoryRegion SomeRegion)
    {
      assert(WrappedPtr);
      return WrappedPtr.Contains(SomeRegion);
    }

    final override MemoryRegion Allocate(size_t RequestedBytes, size_t Alignment = 0)
    {
      assert(WrappedPtr);
      return WrappedPtr.Allocate(RequestedBytes, Alignment);
    }

    final override bool Deallocate(MemoryRegion MemoryToDeallocate)
    {
      assert(WrappedPtr);
      return WrappedPtr.Deallocate(MemoryToDeallocate);
    }
  }

  WrapperClass Wrap(ref SomeMemoryType SomeMemory)
  {
    /// Note(Manu): The wrapper class is trivial to construct, so we just do
    /// it every time without thinking about whether it was already
    /// constructed or not.
    auto Wrapper = Construct!WrapperClass(SomeMemory.WrapperMemory);
    Wrapper.WrappedPtr = &SomeMemory;
    return Wrapper;
  }
}

//
// Unit Tests
//

version(unittest) import krepel.memory.allocator_primitives;

// IAllocator tests
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

  StaticStackMemory!128 Memory;
  auto StackAllocator = Wrap(Memory);

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

// IAllocator allocating class instances.
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

  StaticStackMemory!128 Memory;
  auto StackAllocator = Wrap(Memory);
  SuperClass Instance = StackAllocator.New!SubClass();
  assert(Instance);
  assert(Instance.Data == 1337);
}

// IAllocator
unittest
{
  StaticStackMemory!128 SomeStack;
  auto SomeAllocator = Wrap(SomeStack);
  assert(cast(void*)SomeAllocator == cast(void*)SomeStack.WrapperMemory.ptr);

  auto Mem = SomeAllocator.Allocate(32);
  Mem[] = 42;

  foreach(Byte; SomeStack.Memory[0 .. 32])
  {
    assert(Byte == 42);
  }

  foreach(Byte; SomeStack.Memory[32 .. $])
  {
    assert(Byte != 42);
  }

  static struct Foo
  {
    int Bar = 42;
  }

  assert(SomeAllocator.New!Foo().Bar == 42);
  assert(*cast(int*)(SomeStack.Memory[32 .. 32 + int.sizeof].ptr) == 42);
}
