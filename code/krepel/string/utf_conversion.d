module krepel.string.utf_conversion;

import krepel.util;

bool ValidByte(const(char[]) UTFChar)
{
  if( UTFChar.length == 0 )
  {
    return false;
  }
  else
  {
    return UTFChar[0] <= 0xF4U && (UTFChar[0] < 0xC0U || UTFChar[0] > 0xC1U );
  }
}

uint ExtractCodePoint( const(char[]) UTFChar )
{
  uint Length = ValidChar( UTFChar );
  if( Length == 0U )
  {
    return Length;
  }
  else
  {
    //Extract code point by filtering out the continuation and byte count marks and shifting the code points value together.

    uint Result = 0U;
    switch( Length )
    {
      // Easiest case BXXXXXXX; we want the Xes, but B is always 0 so simply return the value.
    case 1U:
      Result = UTFChar[0];
      // Second case is BBBXXXXX BBXXXXXX, so we filter the second byte by 0x3FU.
      // Then filter the first by 0x1FU and shift it 6 bits to the left, to attaChar it to the second value
      break;
    case 2U:
      Result = UTFChar[ 1U ] & 0x3FU; // Extract lower value, filtering continuation part
      Result |= ( cast( uint ) ( UTFChar[ 0U ] & 0x1FU ) ) << 6U; // Add upper value, filtering 2 byte mark
      break;
      // Third case is BBBBXXXX BBXXXXXX BBXXXXXX, so we filter the third byte by 0x3FU.
      // Then filter the second by 0x3FU and shift it 6 bits to the left, to attaChar it to the output value
      // Then filter the first by 0x0FU and shift it 12 bits to the left, to attaChar it to the output value
    case 3U:
      Result = UTFChar[ 2U ] & 0x3FU;
      Result |= ( cast( uint ) ( UTFChar[ 1U ] & 0x3FU ) ) << 6U;
      Result |= ( cast( uint ) ( UTFChar[ 0U ] & 0x0FU ) ) << 12U;
      break;
      // Fourth case is BBBBBXXX BBXXXXXX BBXXXXXX BBXXXXXX, so we filter the fourth byte by 0x3FU.
      // Then filter the third by 0x3FU and shift it 6 bits to the left, to attaChar it to the output value
      // Then filter the second by 0x3FU and shift it 12 bits to the left, to attaChar it to the output value
      // Then filter the first by 0x007U and shift it 18 bits to the left, to attaChar it to the output value
    case 4U:
      Result = UTFChar[ 3U ] & 0x3FU;
      Result |= (cast(uint) (UTFChar[ 2U ] & 0x3FU)) << 6U;
      Result |= (cast(uint) (UTFChar[ 1U ] & 0x3FU)) << 12U;
      Result |= (cast(uint) (UTFChar[ 0U ] & 0x07U)) << 18U;
      break;
    default:
      break;
    }
    return Result;
  }
}


uint ValidChar( const char[] UTFChar )
{

  bool Result = true;
  Result &= ValidByte( UTFChar );
  uint NumBytes = CharSize( UTFChar );
  if( NumBytes == 2U )
  {
    Result = Result && ( UTFChar[0] < 0xD8U || UTFChar[0] >0xDFU );
  }
  for( uint i = 1; Result && i < NumBytes; ++i )
  {
    Result = Result && ValidByte(UTFChar[i..i+1]) && ( UTFChar[ i ] & 0xC0U ) == 0x80U;
  }

  if( !Result )
  {
    return 0U;
  }
  else
  {
    return NumBytes;
  }
}


uint CharSize( const (char[]) UTFChar )
{
  uint NumBytes;

  if( ( UTFChar[0] & 0x80U ) == 0 )
  {
    return ValidByte( UTFChar ) ? 1 : 0;
  }
  else if( ( UTFChar[0] & 0xE0U ) == 0xC0U )
  {
    NumBytes = 2;
  }
  else if( ( UTFChar[0] & 0xF0U ) == 0xE0U )
  {
    NumBytes = 3;
  }
  else if( ( UTFChar[0] & 0xF8U ) == 0xF0U )
  {
    NumBytes = 4;
  }
  else
  {
    NumBytes = 0;
  }
  return NumBytes;
}

uint ValidChar( const (wchar[]) UTFChar, Endian Endiannes )
{
  bool Result = true;
  uint NumBytes = CharSize( UTFChar, Endiannes);

  wchar Byte1 = UTFChar[0];
  wchar Byte2 = UTFChar[1];
  if(Endiannes == Endian.Big)
  {
    Byte1 = ByteSwapUShort(Byte1);
    Byte2 = ByteSwapUShort(Byte2);
  }

  if( NumBytes == 2U )
  {
    Result = Result && ( Byte1 >= 0xD800U || Byte1 < 0xDC00 ) && ( Byte2 >= 0xDC00U || Byte2 < 0xE000U );
  }

  if( !Result )
  {
    return 0U;
  }
  else
  {
    return NumBytes;
  }
}

enum Endian
{
  Little,
  Big,
}

uint CharSize(const (wchar[]) UTFChar, Endian Endiannes)
{
  wchar MyByte = UTFChar[0];
  if (Endiannes == Endian.Big)
  {
    MyByte = ByteSwapUShort( MyByte );
  }

  if( MyByte < 0xD800U || MyByte >= 0xE000U )
  {
    return 1;
  }
  else
  {
    return 2;
  }
}

uint ExtractCodePoint( const (wchar[]) UTFChar, Endian Endiannes )
{
  uint Length = ValidChar( UTFChar, Endiannes );
  if( Length == 0U )
  {
    return Length;
  }
  else
  {
    //Extract code point by filtering out the continuation and byte count marks and shifting the code points value together.

    uint Result = 0U;
    wchar Byte1;
    wchar Byte2;
    switch( Length )
    {
      // Easiest case, Value is equal to its code point so simply return the value.
    case 1U:
      if(Endiannes == Endian.Big)
      {
        Byte1 = ByteSwapUShort( UTFChar[0] );
      }
      else
      {
        Byte1 = UTFChar[0];
      }
      Result = Byte1;
      break;
      // Second case using lead and trail surrogates
    case 2U:
      if(Endiannes == Endian.Big)
      {
          Byte1 = ByteSwapUShort(UTFChar[0]);
          Byte2 = ByteSwapUShort(UTFChar[1]);
      }
      else
      {
        Byte1 = UTFChar[0];
        Byte2 = UTFChar[1];
      }
      Byte1 -= 0xD800U;
      Byte2 -= 0xDC00U;
      Byte1 = cast(wchar)(Byte1 << 10);
      Result = Byte1 | Byte2;
      Result += 0x10000U;
      break;
    default:
      break;
    }
    return Result;
  }
}
