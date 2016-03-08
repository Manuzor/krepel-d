module krepel.memory.construction;

import krepel.memory;
import Meta = krepel.meta;

private static import std.conv;

// TODO(Manu): Get rid of phobos?

// Enable these when we got rid of phobos.
// @nogc:
// nothrow:
// pure:


Type Construct(Type, ArgTypes...)(MemoryRegion RawMemory, auto ref ArgTypes Args)
  if(is(Type == class))
{
  return std.conv.emplace!Type(cast(void[])RawMemory, Args);
}

Type* Construct(Type, ArgTypes...)(MemoryRegion RawMemory, auto ref ArgTypes Args)
  if(!is(Type == class))
{
  return std.conv.emplace!Type(cast(void[])RawMemory, Args);
}

Type Construct(Type, ArgTypes...)(Type Instance, auto ref ArgTypes Args)
  if(is(Type == class))
{
  MemoryRegion RawMemory = (cast(ubyte*)Instance)[0 .. Meta.ClassInstanceSizeOf!Type];
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

void Destruct(Type)(Type* Instance)
  if(!is(Type == class))
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
        alias MemberType = typeof(mixin(`Instance.` ~ MemberName));
        static if(Meta.HasDestructor!MemberType)
        {
          static if(is(MemberType == class))
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

    // TODO(Manu): Decide whether it's actually necessary to blit over the
    // initial data. The thing should be *destructed* afterall, not
    // reinitialized.
    //BlitInitialData(Instance[0 .. 1]);
  }
}

void ConstructArray(Type, ArgTypes...)(Type[] Array, auto ref ArgTypes Args)
{
  static if(Meta.IsPlainOldData!Type)
  {
    static      if(Args.length == 0) BlitInitialData(Array);
    else static if(Args.length == 1) Array[] = Args[0];
    else
    {
      static assert(false,"Cannot initialize plain old data "
                          "with more than one argument.");
    }
  }
  else
  {
    static if(is(Type == class)) foreach(    Element; Array) Construct(Element);
    else                         foreach(ref Element; Array) Construct(&Element);
  }
}


void DestructArray(Type)(Type[] Array)
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

private void BlitInitialData(Type)(Type[] BlitTargets)
{
  auto RawInit = cast(ubyte[])typeid(Type).initializer();

  foreach(ref Target; BlitTargets)
  {
    static if(is(Type == class))
      auto RawTarget = (cast(ubyte*) Target)[0 .. Meta.ClassInstanceSizeOf!Type];
    else
      auto RawTarget = (cast(ubyte*)&Target)[0 .. Type.sizeof];

    if(RawInit.ptr) RawTarget[] = RawInit[];
    else            RawTarget[] = 0;
  }
}


//
// Unit Tests
//

// Single struct object construction
unittest
{
  nothrow @nogc static struct TestData
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
