module krepel.meta;

private import Phobos = std.traits;

// Creates a sequence of zero or more aliases (types, string literals, ...).
template AliasSequence(Args...)
{
  alias AliasSequence = Args;
}

//debug = krepel_meta_Equal;
template Equal(A, B)
{
  debug(krepel_meta_Equal) pragma(msg, "[krepel_meta_Equal] A = " ~ A.stringof);
  debug(krepel_meta_Equal) pragma(msg, "[krepel_meta_Equal] B = " ~ B.stringof);

  static if(is(A == B))
  {
    enum Equal = true;
  }
  else
  {
    enum Equal = false;
  }

  debug(krepel_meta_Equal) pragma(msg, "[krepel_meta_Equal] Result = " ~ Equal.stringof);
}

// Remove any type qualifiers from InputType.
// Unqualified!(shared(const SomeType)) => SomeType
template Unqualified(InputType)
{
       static if (is(InputType InnerType ==          immutable InnerType)) alias Unqualified = InnerType;
  else static if (is(InputType InnerType == shared inout const InnerType)) alias Unqualified = InnerType;
  else static if (is(InputType InnerType == shared inout       InnerType)) alias Unqualified = InnerType;
  else static if (is(InputType InnerType == shared       const InnerType)) alias Unqualified = InnerType;
  else static if (is(InputType InnerType == shared             InnerType)) alias Unqualified = InnerType;
  else static if (is(InputType InnerType ==        inout const InnerType)) alias Unqualified = InnerType;
  else static if (is(InputType InnerType ==        inout       InnerType)) alias Unqualified = InnerType;
  else static if (is(InputType InnerType ==              const InnerType)) alias Unqualified = InnerType;
  else                                                                     alias Unqualified = InputType;
}

//debug = krepel_meta_Map;
template Map(alias Func, Args...)
{
  debug(krepel_meta_Map) pragma(msg, "[krepel_meta_Map] Func = ", Func.stringof);

  template Impl(Args...)
  {
    static if (Args.length == 0)
    {
      debug(krepel_meta_Map) pragma(msg, "[krepel_meta_Map] Got empty Args list.");
      alias Impl = AliasSequence!();
    }
    else static if (Args.length == 1)
    {
      debug(krepel_meta_Map) pragma(msg, "[krepel_meta_Map] " ~ Args[0].stringof ~ " => " ~ Func!(Args[0]).stringof);
      alias Impl = AliasSequence!(Func!(Args[0]));
    }
    else // static if (Args.length > 1)
    {
      // NOTE(Manu): This case actually does nothing, it simply calls this template recursively.
      alias Impl = AliasSequence!(Impl!(Args[ 0  .. $/2]),
                                  Impl!(Args[$/2 ..  $ ]));
    }
  }

  alias Map = Impl!(Args);

  debug(krepel_meta_Map) pragma(msg, "[krepel_meta_Map] Result: " ~ Map.stringof);
}

unittest
{
  alias Types = Map!(Unqualified, int, const(int), shared(int));

  static assert(is(Types[0] == int));
  static assert(is(Types[1] == int));
  static assert(is(Types[2] == int));
}

//debug = krepel_meta_AnySatisy;
template AnySatisfy(alias Func, Args...)
{
  debug(krepel_meta_AnySatisy) pragma(msg, "[krepel_meta_AnySatisy] Func = ", Func.stringof);

  template Impl(Args...)
  {
    static if(Args.length == 0)
    {
      debug(krepel_meta_AnySatisy) pragma(msg, "[krepel_meta_AnySatisy] Got empty Args list.");
      enum Impl = false;
    }
    else static if(Args.length == 1)
    {
      debug(krepel_meta_AnySatisy) pragma(msg, "[krepel_meta_AnySatisy] " ~ Args[0].stringof ~ " => " ~ Func!(Args[0]).stringof);
      enum Impl = Func!(Args[0]);
    }
    else
    {
      enum Impl = Impl!(Args[ 0  .. $/2]) ||
                  Impl!(Args[$/2 ..  $ ]);
    }
  }

  alias AnySatisfy = Impl!(Args);

  debug(krepel_meta_AnySatisy) pragma(msg, "[krepel_meta_AnySatisy] Result = ", AnySatisfy.stringof);
}

unittest
{
  static assert(!AnySatisfy!(Unqualified));
  // TODO(Manu): More.
}

//debug = krepel_meta_AllSatisfy;
template AllSatisfy(alias Func, Args...)
{
  debug(krepel_meta_AllSatisfy) pragma(msg, "[krepel_meta_AllSatisfy] Func = ", Func.stringof);

  template Impl(Args...)
  {
    static if(Args.length == 0)
    {
      debug(krepel_meta_AllSatisfy) pragma(msg, "[krepel_meta_AllSatisfy] Got empty Args list.");
      enum Impl = true;
    }
    else static if(Args.length == 1)
    {
      debug(krepel_meta_AllSatisfy) pragma(msg, "[krepel_meta_AllSatisfy] " ~ Args[0].stringof ~ " => " ~ Func!(Args[0]).stringof);
      enum Impl = Func!(Args[0]);
    }
    else
    {
      enum Impl = Impl!(Args[ 0  .. $/2]) &&
                  Impl!(Args[$/2 ..  $ ]);
    }
  }

  alias AllSatisfy = Impl!(Args);

  debug(krepel_meta_AllSatisfy) pragma(msg, "[krepel_meta_AllSatisfy] Result = ", AllSatisfy.stringof);
}

unittest
{
  static assert(AllSatisfy!(Unqualified));
  // TODO(Manu): More.
}

//debug = krepel_meta_IsSomeChar;
template IsSomeChar(TypeToTest)
{
  debug(krepel_meta_IsSomeChar) pragma(msg, "[krepel_meta_IsSomeChar] TypeToTest == " ~ TypeToTest.stringof);

  alias AllowedTypes = AliasSequence!(char, dchar, wchar);
  debug(krepel_meta_IsSomeChar) pragma(msg, "[krepel_meta_IsSomeChar] AllowedTypes == " ~ AllowedTypes.stringof);

  alias Comparer(OtherType) = Equal!(Unqualified!TypeToTest, OtherType);
  debug(krepel_meta_IsSomeChar) pragma(msg, "[krepel_meta_IsSomeChar] Comparer == " ~ Comparer.stringof);

  alias IsSomeChar = AnySatisfy!(Comparer, AllowedTypes);
  debug(krepel_meta_IsSomeChar) pragma(msg, "[krepel_meta_IsSomeChar] Result = " ~ IsSomeChar.stringof);
}

unittest
{
  static assert( IsSomeChar!char);
  static assert( IsSomeChar!dchar);
  static assert( IsSomeChar!wchar);
  static assert( IsSomeChar!(immutable char));
  static assert(!IsSomeChar!int);
}

alias IsArray(T) = Phobos.isArray!T;
alias IsIntegral(T) = Phobos.isIntegral!T;
