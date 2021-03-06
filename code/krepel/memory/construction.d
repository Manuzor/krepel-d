module krepel.memory.construction;

import krepel.memory;
import Meta = krepel.meta;

private static import std.conv;

Type Construct(Type, ArgTypes...)(void[] RawMemory, auto ref ArgTypes Args)
  if(is(Type == class))
{
  return std.conv.emplace!Type(RawMemory, Args);
}

Type* Construct(Type, ArgTypes...)(void[] RawMemory, auto ref ArgTypes Args)
  if(!is(Type == class))
{
  return std.conv.emplace!Type(RawMemory, Args);
}

Type Construct(Type, ArgTypes...)(Type Instance, auto ref ArgTypes Args)
  if(is(Type == class))
{
  void[] RawMemory = (Instance.AsPointerTo!void)[0 .. Meta.ClassInstanceSizeOf!Type];
  return Construct!Type(RawMemory, Args);
}

Type* Construct(Type, ArgTypes...)(Type* Pointer, auto ref ArgTypes Args)
  if(!is(Type == class))
{
  return std.conv.emplace!Type(Pointer, Args);
}

void Destruct(Type)(Type Instance)
  if(is(Type == class))
{
  // TODO(Manu): assert(Instance)?
  if(Instance)
  {
    static if(Meta.HasMember!(Type, "__dtor")) Instance.__dtor();
    //BlitInitialData((&Instance)[0 .. 1]);
  }
}

version(none) // Note(Manu): Not implemented.
void Destruct(Type)(Type Instance)
  if(is(Type == interface))
{
  // TODO(Manu): Implement destruction off interfaces?!
}

void Destruct(Type)(Type* Instance)
  if(!Meta.IsClassOrInterface!Type)
{
  // TODO(Manu): assert(Instance)?
  if(Instance)
  {
    // TODO(Manu): Find out what the heck a xdtor is.
    //static if(Meta.HasMember!(Type, "__xdtor")) Instance.__dtor();

    static if(Meta.HasDestructor!Type)
    {
      // Call the destructor on the instance.
      Instance.__dtor();

      // Destruct all the members of Instance.
      foreach(MemberName; __traits(allMembers, Type))
      {
        static if(__traits(compiles, typeof(mixin(`Instance.` ~ MemberName))))
        {
          alias MemberType = typeof(mixin(`Instance.` ~ MemberName));
          static if(Meta.HasDestructor!MemberType && !Meta.IsPointer!MemberType)
          {
            static if(Meta.IsClassOrInterface!MemberType)
            {
              Destruct(mixin(`Instance.` ~ MemberName));
            }
            else
            {
              Destruct(mixin(`&Instance.` ~ MemberName));
            }
          }
        }
      }
    }

    // TODO(Manu): Decide whether it's actually necessary to blit over the
    // initial data. The thing should be *destructed* afterall, not
    // reinitialized.
    //BlitInitialData(Instance[0 .. 1]);
  }
}

void ConstructArray(Type)(Type[] Array)
{
  // Arrays of void are always uninitialized.
  static if(!Meta.IsVoid!Type)
  {
    static if(Meta.IsPlainOldData!Type)
    {
      BlitInitialData(Array);
    }
    else
    {
      static if(is(Type == class)) foreach(    Element; Array) Construct( Element);
      else                         foreach(ref Element; Array) Construct(&Element);
    }
  }
}

void ConstructArray(Type, ArgType)(Type[] Array, auto ref ArgType Arg)
  if(ArgTypes.length <= 1)
{
  // Arrays of void are always uninitialized.
  static if(!Meta.IsVoid!Type)
  {
    static if(Meta.IsPlainOldData!Type)
    {
      Array[] = Arg;
    }
    else
    {
      static if(is(Type == class)) foreach(    Element; Array) Construct( Element, Arg);
      else                         foreach(ref Element; Array) Construct(&Element, Arg);
    }
  }
}

/// Construct the given array from another array.
///
/// Both arrays must have the same length.
void ConstructArrayFromAnotherArray(Type, InitType)(Type[] Array, InitType[] InitializationData)
  if(!Meta.IsVoid!Type && !is(Type == interface))
{
  import krepel : Max;

  assert(Array.length == InitializationData.length);

  static if(Meta.IsPlainOldData!Type)
  {
    static assert(Meta.IsPlainOldData!InitType,
                  "Type " ~ Type.stringof ~ " is a POD type while " ~
                  InitType.stringof ~ " is not.");
    Array[] = InitializationData;
  }
  else
  {
    const NumToInit = Max(Array.length, InitializationData.length);
    foreach(Index; 0 .. NumToInit)
    {
      static if(is(Type == class))
      {
        Construct(Array[Index], InitializationData[Index]);
      }
      else
      {
        Construct(&Array[Index], InitializationData[Index]);
      }
    }
  }
}

void DestructArray(Type)(Type[] Array)
{
  // Can't destruct an array of void.
  static if(!Meta.IsVoid!Type)
  {
    static if(Meta.IsPlainOldData!Type)
    {
      BlitInitialData(Array);
    }
    else
    {
      static if(is(Type == class)) foreach(    Element; Array) Destruct(Element);
      else                         foreach(ref Element; Array) Destruct(&Element);
    }
  }
}

private void BlitInitialData(Type)(Type[] BlitTargets)
{
  auto RawInit = cast(ubyte[])typeid(Type).initializer();

  foreach(ref Target; BlitTargets)
  {
    static if(is(Type == class))
      auto RawTarget = (Target.AsPointerTo!ubyte)[0 .. Meta.ClassInstanceSizeOf!Type];
    else
      auto RawTarget = (cast(ubyte*)&Target)[0 .. Type.sizeof];

    if(RawInit.ptr) RawTarget[] = RawInit[];
    else            RawTarget[] = 0;
  }
}


/// Template for creation of a class 'in-place', e.g. on the stack.
///
/// This implementation provides two options: Automatically
/// constructed/destructed instances and manually managed ones.
///
/// Example:
///   // Create a class on the stack.
///   class FooClass { int Data = 42; }
///   auto Foo = InPlace!FooClass.New();
///   assert(Foo.Data == 42);
///
///   // Manually manage construction and destruction.
///   InPlace!FooClass.Data FooData;
///   Foo = InPlace!FooClass.Construct(FooData);
///   assert(Foo.Data == 42);
template InPlace(Type)
  if(is(Type == class))
{
  import krepel.krepel;

  enum InstanceAlignment = Meta.ClassInstanceAlignmentOf!Type;
  enum InstanceSize = Meta.ClassInstanceSizeOf!Type;

  struct _Data(Flag!"SelfDestruct" SelfDestruct)
  {
    size_t _Offset;
    void[InstanceSize + InstanceAlignment] _Memory;

    @property inout(Type) _Payload() inout
    {
      auto RawPointer = _Memory.ptr + _Offset;
      auto Result = cast(inout(Type))RawPointer;
      return Result;
    }

    @disable this(this);

    static if(SelfDestruct)
    {
      ~this()
      {
        .Destruct(_Payload);
      }
    }

    alias _Payload this;
  }

  /// Use this to manually manage construction/destruction of the data.
  alias Data = _Data!(No.SelfDestruct);

  template IsSomeData(DataType)
  {
    static if(is(DataType == _Data!(Yes.SelfDestruct)) || is(DataType == _Data!(No.SelfDestruct)))
      enum IsSomeData = true;
    else
      enum IsSomeData = false;
  }

  Type Construct(DataType, ArgTypes...)(ref DataType SomeData, auto ref ArgTypes Args)
    if(IsSomeData!DataType)
  {
    auto BasePtr = SomeData._Memory.ptr;
    auto AlignedPtr = AlignedPointer(BasePtr, InstanceAlignment);
    SomeData._Offset = AlignedPtr - BasePtr;
    return .Construct(cast(Type)SomeData, Args);
  }

  void Destruct(DataType)(ref DataType SomeData)
  {
    .Destruct(cast(Type)SomeData);
  }

  auto New(ArgTypes...)(auto ref ArgTypes Args)
  {
    _Data!(Yes.SelfDestruct) Result;
    Construct(Result, Args);
    return Result;
  }
}


//
// Unit Tests
//

// Single struct object construction
unittest
{
  static struct TestData
  {
    int Value;
    float Precision;
  }

  ubyte[TestData.sizeof] Buffer = 0;
  auto DataPtr = cast(TestData*)Buffer.ptr;
  Construct(DataPtr, 42, 3.1415f);
  assert(DataPtr.Value == 42);
  assert(DataPtr.Precision == 3.1415f);

  Destruct(DataPtr);
  assert(DataPtr.Value == 42);
  assert(DataPtr.Precision == 3.1415f);
}

// Single class object construction
unittest
{
  class FooClass            {          int Data() { return 42;   } }
  class BarClass : FooClass { override int Data() { return 1337; } }

  void[1024] Buffer = void;
  auto Bar = cast(BarClass)Buffer.ptr;
  Construct!BarClass(Bar);
  assert(Bar.Data == 1337);
  FooClass Foo = Bar;
  assert(Foo.Data == 1337);
}

// Array of structs
version(unittest) static int DestructionCount;
unittest
{
  DestructionCount = 0;

  static struct TestData
  {
    int Value = 42;

    ~this() { DestructionCount++; }
  }

  ubyte[5 * TestData.sizeof] Buffer;
  const Size = TestData.sizeof;
  auto Array = cast(TestData[])Buffer[0 .. 5 * TestData.sizeof];
  foreach(ref Element; Array) assert(Element.Value == 0);
  assert(Array[0].Value == 0);
  ConstructArray(Array);
  foreach(ref Element; Array)
  {
    assert(Element.Value == 42);
    Element.Value = 1337;
  }
  assert(DestructionCount == 0);
  DestructArray(Array);
  assert(DestructionCount == Array.length);
  foreach(ref Element; Array) assert(Element.Value == 1337);
}

// ConstructArrayFromAnotherArray
unittest
{
  {
    int[3] Source;
    int[3] Data = [ 1, 2, 3 ];

    assert(Source[0] == 0);
    assert(Source[1] == 0);
    assert(Source[2] == 0);

    ConstructArrayFromAnotherArray(Source[], Data[]);

    assert(Source[0] == 1);
    assert(Source[1] == 2);
    assert(Source[2] == 3);
  }

  {
    static struct Foo
    {
      int Value = 42;
      ~this() {}
    }
    static assert(!Meta.IsPlainOldData!Foo);

    Foo[3] Source;
    Foo[3] Data = [ Foo(1), Foo(2), Foo(3) ];

    assert(Source[0].Value == 42);
    assert(Source[1].Value == 42);
    assert(Source[2].Value == 42);

    ConstructArrayFromAnotherArray(Source[], Data[]);

    assert(Source[0].Value == 1);
    assert(Source[1].Value == 2);
    assert(Source[2].Value == 3);
  }

  {
    Object FakePointer(size_t Address)
    {
      return cast(Object)cast(void*)Address;
    }

    Object[3] Source;
    Object[3] Data = [ FakePointer(1), FakePointer(2), FakePointer(3) ];

    assert(Source[0] is null);
    assert(Source[1] is null);
    assert(Source[2] is null);

    ConstructArrayFromAnotherArray(Source[], Data[]);

    assert(Source[0] == FakePointer(1));
    assert(Source[1] == FakePointer(2));
    assert(Source[2] == FakePointer(3));
  }
}

version(unittest) int BazDataDestructionCount;
version(unittest) int BarDataDestructionCount;
version(unittest) int FooDataDestructionCount;
unittest
{
  static struct BazData
  {
    int Data = 179;

    ~this() { BazDataDestructionCount++; }
  }

  static struct BarData
  {
    int Data = 1337;
    BazData Baz;

    ~this() { BarDataDestructionCount++; }
  }

  import krepel.container.array;

  static struct FooData
  {
    int Data = 42;
    BarData Bar;
    Array!int Integers;

    ~this() { FooDataDestructionCount++; }
  }

  void[FooData.sizeof] RawFoo = void;
  auto FooPointer = Construct!FooData(RawFoo);
  assert(FooPointer);
  assert(FooPointer.Data == 42);
  assert(FooPointer.Bar.Data == 1337);
  assert(FooPointer.Bar.Baz.Data == 179);
  Destruct(FooPointer);
  assert(FooDataDestructionCount == 1);
  assert(BarDataDestructionCount == 1);
  assert(BazDataDestructionCount == 1);
}

// InPlace
unittest
{
  static class FooClass
  {
    int Data = 42;

    this(int* Message)
    {
      (*Message)++;
    }

    ~this()
    {
      Data = 1337;
    }
  }

  FooClass Foo;
  {
    int Message;
    auto WrappedFoo = InPlace!FooClass.New(&Message);
    Foo = WrappedFoo;
    assert(Message == 1);
    assert(Foo.Data == 42);
  }
  assert(Foo.Data == 1337);

  {
    int Message;
    InPlace!FooClass.Data WrappedFoo;
    Foo = WrappedFoo;
    InPlace!FooClass.Construct(WrappedFoo, &Message);
    assert(Message == 1);
    assert(WrappedFoo.Data == 42);

    InPlace!FooClass.Destruct(WrappedFoo);
    assert(WrappedFoo.Data == 1337);

    // Construct it again...
    InPlace!FooClass.Construct(WrappedFoo, &Message);
    assert(Message == 2);
    assert(WrappedFoo.Data == 42);

    // ... but don't destruct anymore to prove this kind of data does not
    // destruct itself at the end of the scope.
  }
  assert(Foo.Data == 42);
}
