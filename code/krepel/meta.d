module krepel.meta;

private static import std.traits;
private static import std.conv;
private static import std.bitmanip;

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

//debug = krepel_meta_AnySatisfy;
template AnySatisfy(alias Func, Args...)
{
  debug(krepel_meta_AnySatisfy) pragma(msg, "[krepel_meta_AnySatisfy] Func = ", Func.stringof);

  template Impl(Args...)
  {
    static if(Args.length == 0)
    {
      debug(krepel_meta_AnySatisfy) pragma(msg, "[krepel_meta_AnySatisfy] Got empty Args list.");
      enum Impl = false;
    }
    else static if(Args.length == 1)
    {
      debug(krepel_meta_AnySatisfy) pragma(msg, "[krepel_meta_AnySatisfy] " ~ Args[0].stringof ~ " => " ~ Func!(Args[0]).stringof);
      enum Impl = Func!(Args[0]);
    }
    else
    {
      enum Impl = Impl!(Args[ 0  .. $/2]) ||
                  Impl!(Args[$/2 ..  $ ]);
    }
  }

  alias AnySatisfy = Impl!(Args);

  debug(krepel_meta_AnySatisfy) pragma(msg, "[krepel_meta_AnySatisfy] Result = ", AnySatisfy.stringof);
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

template IsConvertibleTo(SourceType, DestType)
{
  static if(is(SourceType : DestType)) enum IsConvertibleTo = true;
  else                                 enum IsConvertibleTo = false;
}

template HasMember(ArgTypes...)
  if(ArgTypes.length == 2)
{
  static if(is(ArgTypes[0])) alias Type = ArgTypes[0];
  else                       alias Type = typeof(ArgTypes[0]);

  enum bool HasMember = __traits(hasMember, Type, ArgTypes[1]);
}

template ClassInstanceSizeOf(Type)
{
  static assert(is(Type == class), "The type " ~ Type.stringof ~ " is not a class.");
  enum ClassInstanceSizeOf = __traits(classInstanceSize, Type);
}

enum bool IsPlainOldData(Type) = __traits(isPOD, Type);

template HasDestructor(Type)
{
  static if(__traits(hasMember, Type, "__dtor"))
  {
    enum HasDestructor = true;
  }
  else
  {
    enum HasDestructor = false;
  }
}

alias IsArray                = std.traits.isArray;
alias IsIntegral             = std.traits.isIntegral;
alias IsPointer              = std.traits.isPointer;
alias ClassInstanceAlignment = std.traits.classInstanceAlignment;

/// Example:
/// struct A
/// {
///   mixin(Bitfields!(
///                    bool, "a", 1,
///                    uint, "b", 2,
///                    int,  "a", 3,
///                    uint, "",  2, // Padding so this entire thing is 8 bits.
///                    ));
/// }
alias Bitfields  = std.bitmanip.bitfields;


//
// Unit Tests
//


unittest
{
  alias Types = Map!(Unqualified, int, const(int), shared(int));

  static assert(is(Types[0] == int));
  static assert(is(Types[1] == int));
  static assert(is(Types[2] == int));
}

unittest
{
  static assert(!AnySatisfy!(Unqualified));
  // TODO(Manu): More.
}

unittest
{
  static assert(AllSatisfy!(Unqualified));
  // TODO(Manu): More.
}

unittest
{
  static assert( IsSomeChar!char);
  static assert( IsSomeChar!dchar);
  static assert( IsSomeChar!wchar);
  static assert( IsSomeChar!(immutable char));
  static assert(!IsSomeChar!int);
}
