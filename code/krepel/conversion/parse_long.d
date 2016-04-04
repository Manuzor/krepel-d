module krepel.conversion.parse_long;

import krepel : Flag, Yes, No;
import krepel.string;
import krepel.conversion.conversion;

struct ParseLongResult
{
  Flag!"Success" Success;
  long Value;

  alias Value this;
}

ParseLongResult ParseLong(Source)(ref Source String, long ValueOnError = long.min)
{
  String = TrimStart(String);

  bool Sign = false;

  if(String.length == 0)
  {
    return ParseLongResult(No.Success, ValueOnError);
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

  long NumericalPart = 0;
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
    return ParseLongResult(No.Success, ValueOnError);
  }

  long Value = Sign ? -NumericalPart : NumericalPart;
  return ParseLongResult(Yes.Success, Value);
}

version(unittest)
void TestLong(string String, long Expected, int ExpectedRangeLength)
{
  auto Range = String[];
  auto Result = ParseLong(Range);
  assert(Result.Success);
  float Value = Result;
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
  auto Value = ParseLong(Range);
  assert(!Value.Success);
  assert(Value == long.min);
  assert(Range.length == 3);
}
