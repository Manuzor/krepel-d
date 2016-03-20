module krepel.conversion.parse_float;

import krepel.string;

bool IsDigit(CharType)(CharType Char)
{
  return Char - '0' >= 0 && Char - '0' < 10;
}

float ParseFloat(Source)(ref Source String, float ValueOnError = float.nan)
{
  String = TrimStart(String);

  bool Sign = false;

  if(String.length == 0)
  {
    return ValueOnError;
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
    return ValueOnError;
  }

  float Value = cast(float)NumericalPart;


  bool HasDecimalPoint = String.length > 0 && String[0] == '.';

  if(!HasDecimalPoint && String.length == 0 || (String[0] != '.' && String[0] != 'e' && String[0] != 'E'))
  {
    return Sign ? -Value : Value;
  }
  if(HasDecimalPoint)
  {
    String = String[1..$];
    long DecimalPart = 0;
    long DecimalDivider = 1;

    while(String.length > 0 && IsDigit(String[0]))
    {
        DecimalPart *= 10;
        DecimalPart += String[0] - '0';
        DecimalDivider *= 10;
        String = String[1..$];
    }

    Value += (cast(float)DecimalPart)/(cast(float)DecimalDivider);
  }

  if(String.length == 0 || (String[0] != 'e' && String[0] != 'E'))
  {
    return Sign ? -Value : Value;
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
    long ExponentPart = 0;
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

  return Sign ? -Value : Value;

}

version(unittest)
void TestFloat(string String, float Expected, int ExpectedRangeLength)
{
  auto Range = String[];
  float Value;
  Value = ParseFloat(Range);
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
  float Value = ParseFloat(Range);
  assert(IsNaN(Value));
  assert(Range.length == 3);
}
