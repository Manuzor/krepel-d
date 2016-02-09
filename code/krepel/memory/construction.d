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

// TODO(Manu): Write some tests.
