module krepel.string.string;

import krepel.memory;
import krepel.container;


struct StringBase(CharType)
{
  @nogc:

  Array!CharType* Data;

  @property auto Allocator()
  {
    return Data != null ? Data.Allocator : GlobalAllocator;
  }

  this(IAllocator Allocator)
  {
    Data = Allocator.New!(Array!CharType);
    RefCount = Allocator.New!(uint);
    *RefCount = 1;
    Data.Allocator = Allocator;
  }

  this(const CharType[] String, IAllocator Allocator = GlobalAllocator)
  {
    this(Allocator);
    Data.PushBack(String);
    Data.PushBack('\0');
  }

  this(this)
  {
    (*RefCount)++;
  }

  ~this()
  {
    if (*RefCount == 1)
    {
      Allocator.Delete(RefCount);
      RefCount = null;
      Allocator.Delete!(Array!CharType)(Data);
      Data = null;
    }
    else
    {
      (*RefCount)--;
    }
  }

  void EnsureSingleCopy()
  {
    if (*RefCount != 1)
    {
      Array!CharType* NewData = Allocator.New!(Array!CharType)();
      (*RefCount)--;
      NewData.PushBack(Data.Data[]);
      Data = NewData;
      RefCount = Allocator.New!uint();
      *RefCount = 1;
    }
  }

  bool StartsWith(const CharType[] SearchString)
  {
    if (Count < SearchString.length)
    {
      return false;
    }
    else
    {
      return this[0 .. SearchString.length] == SearchString;
    }
  }

  bool EndsWith(const CharType[] SearchString)
  {
    if (Count < SearchString.length)
    {
      return false;
    }
    else
    {
      return this[$ - SearchString.length .. $] == SearchString;
    }
  }

  const(CharType[]) opIndex() const
  {
    return Data.Data[0..Count];
  }

  CharType opIndex(int Index) const
  {
    return Data.Data[Index];
  }

  void opIndexAssign(CharType Value, uint Index)
  {
    EnsureSingleCopy();
    Data.Data[Index] = Value;
  }

  ulong opDollar() const
  {
    return Count;
  }

  const(CharType[]) opSlice(ulong LeftIndex, ulong RightIndex) const
  {
    return Data.Data[LeftIndex .. RightIndex];
  }

  @property auto Count() const
  {
    return Data.Count - 1;
  }

  bool opEquals(const CharType[] String) const
  {
    return this[] == String;
  }

  bool opEquals(ref StringBase!CharType String) const
  {
    return this[] == String[];
  }

  const(CharType[]) ToChar() const
  {
    return this[];
  }

  alias ToChar this;

  uint* RefCount = null;
}

alias String = StringBase!wchar;

unittest
{
  StaticStackMemory!1024 StackMemory;
  GlobalAllocator = Wrap(StackMemory);

  String TestString = String("This is a Test");

  assert(TestString == "This is a Test");
  assert(TestString == TestString);
  assert(TestString != "Another String");

  auto AnotherString = TestString;

  AnotherString[2] = 'b';

  assert(TestString == "This is a Test");
  assert(AnotherString == "Thbs is a Test");

  assert(TestString.StartsWith("This"));
  assert(TestString.EndsWith("Test"));
}
