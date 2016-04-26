module krepel.krepel;

public import krepel.log;

debug public import io = std.stdio;

// These are useful to have range functionality for standard slices.
public import std.range : empty, popFront, popBack, front, back, save, put;

private static import std.algorithm;
private static import std.format;
private static import std.range;
private static import std.utf;
private static import std.typecons;


alias Find = std.algorithm.find;

alias StartsWith = std.algorithm.startsWith;
alias CountUntil = std.algorithm.countUntil;
alias CopyTo     = std.algorithm.copy;

/// Alternative to CopyTo with just another wording and argument order.
/// See_Also: CopyTo
auto CopyFrom(DestinationType, SourceType)(auto ref DestinationType Destination, auto ref SourceType Source)
{
  return Source.CopyTo(Destination);
}

auto MoveTo(SourceType, DestinationType)(auto ref SourceType Source, auto ref DestinationType Destination)
{
  // TODO(Manu): Make this a true move instead of a copy.
  return Source.CopyTo(Destination);
}

auto MoveFrom(DestinationType, SourceType)(auto ref DestinationType Destination, auto ref SourceType Source)
{
  return Source.MoveTo(Destination);
}

alias Zip = std.range.zip;
alias Put = std.range.put;

auto Format(FormatType, ArgTypes...)(auto ref FormatType FormatString, auto ref ArgTypes Args)
{
  if(__ctfe)
  {
    return std.format.format(FormatString, Args);
  }
  else
  {
    assert(0, "Not implemented.");
  }
}

alias FormattedWrite = std.format.formattedWrite;

alias ToDelegate = std.functional.toDelegate;

alias ByUTF = std.utf.byUTF;

alias Yes  = std.typecons.Yes;
alias No   = std.typecons.No;
alias Flag = std.typecons.Flag;

/// A bidirectional range yielding all enum values from .min to .max.
static struct EnumIterator(EnumType)
  // TODO(Manu): Constraint to ensure EnumType is actually an enum.
{
  EnumType _Front = EnumType.min;
  EnumType _Back = EnumType.max;

  @property bool empty() const { return _Front > _Back; }
  @property inout(EnumType) front() inout { assert(!empty); return _Front; }
  @property inout(EnumType) back() inout { assert(!empty); return _Back; }
  void popFront() { _Front = cast(EnumType)(cast(ulong)_Front + 1); }
  void popBack()  { _Back  = cast(EnumType)(cast(ulong)_Back  - 1); }
}

/// Tracks whether the value of a given type was set or not.
///
/// Mostly useful for members of structs/classes.
struct TrackedValue(Type)
{
  bool IsSet;
  Type _Value = void;

  this(AssignType)(AssignType Value)
  {
    this.Value = Value;
  }

  /// Getter
  @property inout(Type) Value() inout
  {
    assert(this.IsSet);
    return cast(typeof(return))this._Value;
  }

  /// Setter
  @property void Value(AssignType)(AssignType NewValue)
  {
    this._Value = NewValue;
    this.IsSet = true;
  }

  void opAssign(AssignType)(AssignType NewValue)
  {
    this.Value = NewValue;
  }

  inout(Type) ValueOr(FallbackType : Type)(FallbackType FallbackValue) inout
  {
    return this.IsSet ? this._Value : FallbackValue;
  }

  inout(To) opCast(To)() inout
  {
    return cast(typeof(return))this.Value;
  }
}

// A nicer name for optional values, e.g. `Optional!int Count;`.
alias Optional = TrackedValue;

// A nicer name for required values, e.g. `Optional!Vector3 Extents;`.
alias Required = TrackedValue;

//
// Unit Tests
//

unittest
{
  enum Foo
  {
    Bar,
    Baz
  }
  // TODO(Manu): Find out why EnumIterator is not a bidirectional range in
  // terms of Meta.IsBidirectionalRange, even though it behaves like one.
  //static assert(Meta.IsBidirectionalRange!(EnumIterator!Foo),
  //              "The EnumIterator template should be a bidirectional range.");
  static assert(Meta.IsInputRange!(EnumIterator!Foo));

  auto Iter = EnumIterator!Foo();
  assert(Iter.front == Foo.Bar);
  Iter.popFront();
  assert(Iter.front == Foo.Baz);
  Iter.popFront();
  assert(Iter.empty);

  int Count;
  foreach(_; EnumIterator!Foo()) { Count++; }
  assert(Count == 2);
}

unittest
{
  import core.exception : AssertError;
  import std.exception : assertThrown;

  TrackedValue!int Integer;
  assert(!Integer.IsSet);
  assertThrown!AssertError(Integer.Value == 0);
  assertThrown!AssertError(cast(byte)Integer == 0);
  assert(Integer.ValueOr(1337) == 1337);
  Integer.Value = 42;
  assert(Integer.Value == 42);
  assert(Integer.ValueOr(1337) == 42);
  assert(cast(float)Integer == 42.0f);

  static struct FooData
  {
    int Data;

    inout(To) opCast(To : int)() inout { return this.Data; }

    void opAssign(Type)(Type Value)
    {
      this.Data = cast(int)Value;
    }
  }

  static struct BarData
  {
    float Data;

    To opCast(To)()
    {
      return cast(typeof(return))this.Data;
    }
  }

  TrackedValue!FooData Foo;
  Foo = BarData(42.0f);
  assert(cast(int)Foo == 42);
}
