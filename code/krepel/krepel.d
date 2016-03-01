module krepel.krepel;

public import Log = krepel.log;

private static import std.algorithm;
private static import std.format;

alias Find = std.algorithm.find;

alias StartsWith = std.algorithm.startsWith;

alias CountUntil = std.algorithm.countUntil;

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
