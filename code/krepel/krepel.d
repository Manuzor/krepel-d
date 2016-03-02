module krepel.krepel;

public import krepel.log;

debug public import io = std.stdio;

// These are useful to have range functionality for standard slices.
public import std.range : empty, popFront, popBack, front, back, save, put;

private static import std.algorithm;
private static import std.format;
private static import std.range;


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
