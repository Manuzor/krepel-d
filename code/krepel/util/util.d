module krepel.util.util;

struct ByteSwapUnion
{
  union
  {
    ushort Short;
    struct
    {
      ubyte Byte1;
      ubyte Byte2;
    }
  }
}

void[] AsVoidRange(Type)(ref Type Instance)
  if(is(Type == struct))
{
  return (cast(void*)(&Instance))[0..Type.sizeof];
}

ushort ByteSwapUShort(ushort Short)
{
  ByteSwapUnion Tmp = void;
  Tmp.Short = Short;
  ubyte Swap = Tmp.Byte1;
  Tmp.Byte1 = Tmp.Byte2;
  Tmp.Byte2 = Swap;
  return Tmp.Short;
}

unittest
{
  ushort Test = 0xAABB;
  ushort Result = ByteSwapUShort(Test);

  assert(Result == 0xBBAA);
}
