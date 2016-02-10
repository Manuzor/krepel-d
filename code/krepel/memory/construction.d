module krepel.memory.construction;

import Meta = krepel.meta;

void Construct(T, ArgTypes...)(T[] Array, ArgTypes Args)
{
  static if(ArgTypes.length)
  {
    static if(Meta.HasMember!(T, "__ctor")) foreach(ref Element; Array) Element.__ctor(Args);
    else                                    foreach(ref Element; Array) Element = T(Args);
  }
  else
  {
    // TODO(Manu): This does a copy operation, but can it be done another way?
    Array[] = T.init;
  }
}

void Construct(T, ArgTypes...)(ref T Instance, ArgTypes Args)
{
  // Make a single-element slice from `Instance` and call the other overload.
  Construct((&Instance)[0..1], Args);
}

void Destruct(T)(T[] Array)
{
  // TODO(Manu): See what Phobos' destroy() does that we don't.
  static if(Meta.HasMember!(T, "__dtor")) foreach(ref Element; Array) Element.__dtor();
  else                                    foreach(ref Element; Array) Element = T.init;
}

void Destruct(T)(ref T Instance)
{
  // Make a single-element slice from `Instance` and call the other overload.
  Destruct((&Instance)[0..1]);
}


//
// Unit Tests
//

// Construct single object
unittest
{
  nothrow @nogc static struct TestData
  {
    int Value;
    float Precision;
  }

  ubyte[TestData.sizeof] Buffer = 0;
  auto DataPtr = cast(TestData*)Buffer.ptr;
  Construct(*DataPtr, 42, 3.1415f);
  assert(DataPtr.Value == 42);
  assert(DataPtr.Precision == 3.1415f);
  Destruct(*DataPtr);
  assert(DataPtr.Value != 42);
  assert(DataPtr.Precision != 3.1415f);
}
