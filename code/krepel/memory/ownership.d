module krepel.memory.ownership;

nothrow:
@nogc:

struct Owned(T)
{
  alias ElementType = T;

  ElementType* Data;

  alias Data this;
}

auto Own(ArgType)(auto ref ArgType Arg)
{
  static if(is(ArgType T : T*)) { return Owned!T(Arg); }        // Arg is a pointer, pass it directly.
  else                          { return Owned!ArgType(&Arg); } // Arg is not a pointer, so take its address.
}

version(unittest) int NumberOfCopies;
unittest
{
  static struct S
  {
    this(this) nothrow @nogc { ++NumberOfCopies; }
  }

  S Instance;
  auto Copy = Instance;

  auto First = Own(Instance);
  assert(NumberOfCopies == 1);
  auto Second = Own(&Instance);
  static assert(is(typeof(First) == typeof(Second)));
  assert(NumberOfCopies == 1);
  assert(*Second == *First, "Content equality test failed.");
  assert(Second == First, "Pointer equality failed.");
}
