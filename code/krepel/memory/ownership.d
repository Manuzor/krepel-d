deprecated("This module is not ready for use yet.")
module krepel.memory.ownership;

struct Owned(T)
{
  alias ElementType = T;

  ElementType* DataPtr;

  @property ref ElementType Data() { return *DataPtr; }

  alias Data this;
}

auto Own(ArgType)(auto ref ArgType Arg)
{
  static if(is(ArgType T : T*)) { return Owned!T(Arg); }        // Arg is a pointer, pass it directly.
  else                          { return Owned!ArgType(&Arg); } // Arg is not a pointer, so take its address.
}

version(unittest)
{
  static struct S
  {
    __gshared int NumberOfCopies;

    int Value = 42;
    this(this) { ++NumberOfCopies; }
  }

  auto SomeFunction(ref S Instance) { assert(Instance.Value == 42); }
}

unittest
{
  S Instance;
  assert(S.NumberOfCopies == 0);

  auto Copy = Instance;
  assert(S.NumberOfCopies == 1);

  auto First = Own(Instance);
  assert(S.NumberOfCopies == 1);

  auto Second = Own(&Instance);
  static assert(is(typeof(First) == typeof(Second)));
  assert(S.NumberOfCopies == 1);

  assert(Second.Value == 42);
  assert(Second == First, "Content equality test failed.");

  // Try UFCS.
  // NOTE(Manu): UFCS only works for stuff at module scope.
  Second.SomeFunction();
}
