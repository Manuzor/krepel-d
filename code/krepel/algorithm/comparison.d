module krepel.algorithm.comparison;


@nogc:

auto ref Min(ArgTypes...)(ArgTypes Args) @safe
  if(ArgTypes.length > 0)
{
  static if(ArgTypes.length == 1)
  {
    return Args[0];
  }
  else
  {
    auto A = Args[0];
    auto B = Min(Args[1 .. $]);
    return A < B ? A : B;
  }
}

auto ref Max(ArgTypes...)(ArgTypes Args) @safe
  if(ArgTypes.length > 0)
{
  static if(ArgTypes.length == 1)
  {
    return Args[0];
  }
  else
  {
    auto A = Args[0];
    auto B = Max(Args[1 .. $]);
    return A > B ? A : B;
  }
}

alias Clamp = (Value, LowerBound, UpperBound) => Max(LowerBound, Min(Value, UpperBound));

unittest
{
  assert(Clamp(0, 0, 0) == 0);
  assert(Clamp(1, 2, 3) == 2);
  assert(Clamp(4, 2, 3) == 3);
  assert(Clamp(-1.0f, 0.0f, 1.0f) == 0.0f);
  assert(Clamp(-0.5f, -1.0, 1.0) == -0.5);
}
