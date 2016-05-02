module krepel.conversion.parse_integer;

import krepel : Flag, Yes, No;
import krepel.string;
import krepel.conversion.conversion;
import Meta = krepel.meta;

template ParseInteger(IntegerType)
  if(Meta.IsIntegral!IntegerType)
{
  struct Result
  {
    Flag!"Success" Success;
    long Value;

    alias Value this;
  }

  Result ParseInteger(Source)(ref Source String, IntegerType ValueOnError = IntegerType.min)
  {
    String = TrimStart(String);

    bool Sign = false;

    if(String.length == 0)
    {
      return Result(No.Success, ValueOnError);
    }

    switch(String[0])
    {
    case '+':
      String = String[1..$];
      break;
    case '-':
      Sign = true;
      String = String[1..$];
      break;
    default:
      break;
    }

    ulong NumericalPart = 0;
    bool HasNumericalPart = false;

    while(String.length > 0 && IsDigit(String[0]))
    {
      NumericalPart *= 10;
      NumericalPart += String[0] - '0';
      HasNumericalPart = true;
      String = String[1..$];
    }

    if (!HasNumericalPart)
    {
      return Result(No.Success, ValueOnError);
    }

    auto Value = cast(IntegerType)NumericalPart;

    if(Sign)
    {
      static if(Meta.IsSigned!IntegerType)
      {
        Value = -Value; // Negate
      }
      else
      {
        // Unsigned types cannot have a '-' sign.
        return Result(No.Success, ValueOnError);
      }
    }

    return Result(Yes.Success, Value);
  }
}

alias ParseSignedInteger = ParseInteger!long;
alias ParseUnsignedInteger = ParseInteger!ulong;

version(unittest)
private void TestLong(string String, long Expected, int ExpectedRangeLength)
{
  auto Range = String[];
  auto Result = ParseInteger!long(Range);
  assert(Result.Success);
  long Value = Result;
  assert(Value == Expected);
  assert(Range.length == ExpectedRangeLength);
}

unittest
{
  import krepel.math;

  TestLong("1", 1, 0);
  TestLong("-1", -1, 0);
  TestLong("400000000", 400000000, 0);
  TestLong("-400000000", -400000000, 0);
  TestLong("23443A", 23443, 1);
  TestLong("  23443A", 23443, 1);
  TestLong("\n \r  \t23443A", 23443, 1);
  TestLong("76.55.43", 76, 6);

  auto String = "ABC";
  auto Range = String[];
  auto Value = ParseInteger!long(Range);
  assert(!Value.Success);
  assert(Value == long.min);
  assert(Range.length == 3);
}
