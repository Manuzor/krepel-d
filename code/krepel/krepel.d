module krepel.krepel;

public import Log = krepel.log;

// These are useful to have range functionality for standard slices.
public import std.range : empty, popFront, popBack, front, back, save, put;

private static import std.algorithm;
private static import std.format;
private static import std.range;

alias Find = std.algorithm.find;

alias StartsWith = std.algorithm.startsWith;

alias CountUntil = std.algorithm.countUntil;

alias Zip = std.range.zip;

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
