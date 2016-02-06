module krepel.math.math;

import Meta = krepel.meta;


bool IsOdd(NumberType)(NumberType Number)
  if(Meta.IsIntegral!NumberType)
{
  // If the first bit is set, we have an odd number.
  return Number & 1;
}

alias IsEven = (N) => !IsOdd(N);

bool IsPowerOfTwo(NumberType)(NumberType Number)
  if(Meta.IsIntegral!NumberType)
{
  return (Number & (~Number + 1)) == Number;
}

//
// Unit Tests
//

// IsOdd / IsEven
unittest
{
  assert(!0.IsOdd);
  assert( 1.IsOdd);
  assert(!2.IsOdd);
  assert( 3.IsOdd);
  assert( 0.IsEven);
  assert(!1.IsEven);
  assert( 2.IsEven);
  assert(!3.IsEven);
}

// IsPowerOfTwo
unittest
{
  import std.algorithm;
  import std.range;
  import std.format;

  auto SomePOTs = [1, 2, 4, 8, 16, 32, 64, 128, 256, 512];

  foreach(POT; SomePOTs)
  {
    assert(POT.IsPowerOfTwo);
  }
  foreach(Number; iota(SomePOTs[0], SomePOTs.length).filter!(a => !SomePOTs.canFind(a)))
  {
    assert(!Number.IsPowerOfTwo, "%d is a power of two!?".format(Number));
  }
}
