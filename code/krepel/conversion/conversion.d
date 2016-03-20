module krepel.conversion.conversion;

bool IsDigit(CharType)(CharType Char)
{
  return Char - '0' >= 0 && Char - '0' < 10;
}
