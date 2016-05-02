module krepel.conversion.parse_float;

import krepel : Flag, Yes, No;
import krepel.string;
import krepel.conversion.conversion;

struct ParseFloatResult
{
  Flag!"Success" Success;
  double Value;

  alias Value this;
}

ParseFloatResult ParseFloat(Source)(ref Source String, double ValueOnError = double.nan)
{
  String = TrimStart(String);

  bool Sign = false;

  if(String.length == 0)
  {
    return ParseFloatResult(No.Success, ValueOnError);
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
    return ParseFloatResult(No.Success, ValueOnError);
  }

  auto Value = cast(double)NumericalPart;

  bool HasDecimalPoint = String.length > 0 && String[0] == '.';

  if(!HasDecimalPoint && String.length == 0 || (String[0] != '.' && String[0] != 'e' && String[0] != 'E'))
  {
    return ParseFloatResult(Yes.Success, Sign ? -Value : Value);
  }
  if(HasDecimalPoint)
  {
    String = String[1..$];
    ulong DecimalPart = 0;
    ulong DecimalDivider = 1;

    while(String.length > 0 && IsDigit(String[0]))
    {
        DecimalPart *= 10;
        DecimalPart += String[0] - '0';
        DecimalDivider *= 10;
        String = String[1..$];
    }

    Value += (cast(double)DecimalPart)/(cast(double)DecimalDivider);
  }

  if(String.length == 0 || (String[0] != 'e' && String[0] != 'E'))
  {
    return ParseFloatResult(Yes.Success, Sign ? -Value : Value);
  }
  else if(String[0] == 'e' || String[0] == 'E')
  {
    String = String[1..$];
    bool ExponentSign = false;

    switch(String[0])
    {
    case '+':
      String = String[1..$];
      break;
    case '-':
      ExponentSign = true;
      String = String[1..$];
      break;
    default:
      break;
    }
    ulong ExponentPart = 0;
    while(String.length > 0 && IsDigit(String[0]))
    {
        ExponentPart *= 10;
        ExponentPart += String[0] - '0';
        String = String[1..$];
    }

    long ExponentValue = 1;
    foreach(Exp ; 0..ExponentPart)
    {
      ExponentValue *= 10;
    }

    Value = (ExponentSign ? (Value / ExponentValue) : (Value * ExponentValue));
  }

  return ParseFloatResult(Yes.Success, Sign ? -Value : Value);
}

version(unittest)
void TestFloat(string String, double Expected, int ExpectedRangeLength)
{
  auto Range = String[];
  auto Result = ParseFloat(Range);
  assert(Result.Success);
  auto Value = cast(double)Result;
  assert(Value == Expected);
  assert(Range.length == ExpectedRangeLength);
}

unittest
{
  import krepel.math;

  TestFloat("1", 1.0f, 0);
  TestFloat("-1", -1.0f, 0);
  TestFloat("1.5", 1.5f, 0);
  TestFloat("-1.5", -1.5f, 0);
  TestFloat("1E10", 1e10f, 0);
  TestFloat("1E-10", 1e-10f, 0);
  TestFloat("-1E-10", -1e-10f, 0);
  TestFloat("-1E10", -1e10f, 0);
  TestFloat("1.234E-10", 1.234e-10f, 0);
  TestFloat("-1.234E-10", -1.234e-10f, 0);

  TestFloat("1e10", 1e10f, 0);
  TestFloat("1e-10", 1e-10f, 0);
  TestFloat("-1e-10", -1e-10f, 0);
  TestFloat("-1e10", -1e10f, 0);
  TestFloat("1.234e-10", 1.234e-10f, 0);
  TestFloat("-1.234e-10", -1.234e-10f, 0);

  TestFloat("23443A", 23443, 1);
  TestFloat("  23443A", 23443, 1);
  TestFloat("\n \r  \t23443A", 23443, 1);
  TestFloat("76.55.43", 76.55, 3);

  auto String = "ABC";
  auto Range = String[];
  auto Value = ParseFloat(Range);
  assert(!Value.Success);
  assert(IsNaN(Value));
  assert(Range.length == 3);
}
