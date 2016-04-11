module krepel.string.string;

import krepel.memory;
import krepel.container;

bool StartsWith(CharType)(const CharType[] String, const CharType[] SearchString)
{
  if (String.length < SearchString.length)
  {
    return false;
  }
  else
  {
    return String[0 .. SearchString.length] == SearchString;
  }
}

bool EndsWith(CharType)(const CharType[] String, const CharType[] SearchString)
{
  if (String.length < SearchString.length)
  {
    return false;
  }
  else
  {
    return String[$ - SearchString.length .. $] == SearchString;
  }
}

ulong Find(CharType)(const CharType[] String, const(CharType[]) SearchString, ulong SearchStardIndex = 0)
{
  long SearchIndex = SearchStardIndex;
  while(SearchString.length + SearchIndex <= String.length)
  {
    if (String[SearchIndex .. SearchIndex + SearchString.length] == SearchString)
    {
      return SearchIndex;
    }
    SearchIndex++;
  }
  return -1;
}

ulong FindLast(CharType)(const CharType[] String, const(CharType[]) SearchString)
{
  long SearchIndex = String.length - SearchString.length;
  while(SearchIndex >= 0)
  {
    if (String[SearchIndex .. SearchIndex + SearchString.length] == SearchString)
    {
      return SearchIndex;
    }
    SearchIndex--;
  }
  return -1;
}

inout (CharType[]) TrimStart(CharType)(inout(CharType[]) String)
{
  ulong Index = 0;
  while(Index < String.length)
  {
    if(String[Index] != ' ' && String[Index] != '\t' && String[Index] != '\n' && String[Index] != '\r')
    {
      return String[Index .. $];
    }
    Index++;
  }
  return String[$..$];
}

inout (CharType[]) TrimEnd(CharType)(inout(CharType[]) String)
{
  ulong Index = String.length - 1;
  while(Index >= 0)
  {
    if(String[Index] != ' ' && String[Index] != '\t' && String[Index] != '\n' && String[Index] != '\r')
    {
      return String[0 .. Index];
    }
    Index--;
  }
  return String[0..0];
}

inout (CharType[]) Trim(CharType)(inout(CharType[]) String)
{
  return TrimStart(TrimEnd(String));
}


struct StringBase(CharType)
{
  Array!CharType* Data;

  @property auto Allocator()
  {
    return Data.Allocator;
  }

  this(IAllocator Allocator)
  {
    Data = Allocator.New!(Array!CharType)(Allocator);
    RefCount = Allocator.New!(uint);
    *RefCount = 1;
    Data.PushBack('\0');
  }

  this(const CharType[] String, IAllocator Allocator)
  {
    this(Allocator);
    Data.PopFront();
    Data.PushBack(String);
    Data.PushBack('\0');
  }

  this(this)
  {
    (*RefCount)++;
  }

  ~this()
  {
    if(RefCount != null)
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
  }

  void EnsureSingleCopy()
  {
    if (*RefCount != 1)
    {
      Array!CharType* NewData = Allocator.New!(Array!CharType)(Allocator);
      (*RefCount)--;
      NewData.PushBack(Data.Data[]);
      Data = NewData;
      RefCount = Allocator.New!uint();
      *RefCount = 1;
    }
  }

  bool StartsWith(const CharType[] SearchString)
  {
    if (ByteCount < SearchString.length)
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
    if (ByteCount < SearchString.length)
    {
      return false;
    }
    else
    {
      return this[$ - SearchString.length .. $] == SearchString;
    }
  }

  ulong Find(const(CharType[]) SearchString, ulong SearchStardIndex = 0) const
  {
    long SearchIndex = SearchStardIndex;
    while(SearchString.length + SearchIndex <= ByteCount)
    {
      if (this[SearchIndex .. SearchIndex + SearchString.length] == SearchString)
      {
        return SearchIndex;
      }
      SearchIndex++;
    }
    return -1;
  }

  ulong FindLast(const(CharType[]) SearchString) const
  {
    long SearchIndex = ByteCount - SearchString.length;
    while(SearchIndex >= 0)
    {
      if (this[SearchIndex .. SearchIndex + SearchString.length] == SearchString)
      {
        return SearchIndex;
      }
      SearchIndex--;
    }
    return -1;
  }

  bool ReplaceFirst(const(CharType[]) SearchString, const(CharType[]) ReplaceString)
  {
    long SearchIndex = Find(SearchString);
    if (SearchIndex == -1)
    {
      return false;
    }
    EnsureSingleCopy();
    Data.RemoveAt(SearchIndex, SearchString.length);
    Data.Insert(SearchIndex, ReplaceString);
    return true;
  }

  long ReplaceAll(const(CharType[]) SearchString, const(CharType[]) ReplaceString)
  {
    long StartSearchIndex = 0;
    long SearchIndex = 0;
    long ReplaceCount = 0;
    while(SearchIndex >= 0)
    {
      SearchIndex = Find(SearchString, StartSearchIndex);
      if (SearchIndex >= 0)
      {
        EnsureSingleCopy();
        Data.RemoveAt(SearchIndex, SearchString.length);
        Data.Insert(SearchIndex, ReplaceString);
        StartSearchIndex = SearchIndex + ReplaceString.length;
        ReplaceCount++;
      }
    }
    return ReplaceCount;
  }

  long Concat(const(CharType[]) OtherString)
  {
    EnsureSingleCopy();
    Data.PopBack(); // Remove \0 from End of first string.
    Data.PushBack(OtherString);
    Data.PushBack('\0');
    return ByteCount;
  }

  StringBase!CharType ConcatCopy(const(CharType[]) OtherString)
  {
    StringBase!CharType Result = StringBase!CharType(this, this.Allocator);
    Result.Concat(OtherString);
    return Result;
  }

  StringBase!CharType opBinary(string Operator : "+")(const(CharType[]) OtherString)
  {
    return ConcatCopy(OtherString);
  }

  const(CharType)[] opIndex() const
  {
    return Data.Data[0..ByteCount];
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

  // TODO(Marvin): Which allocator for assignment ?
  //void opAssign(const CharType[] Chars)
  //{
  //  this = StringBase!CharType(Chars);
  //}

  ulong opDollar() const
  {
    return ByteCount;
  }

  const(CharType)[] opSlice(ulong LeftIndex, ulong RightIndex) const
  {
    return Data.Data[LeftIndex .. RightIndex];
  }

  @property auto ByteCount() const
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

alias WString = StringBase!wchar;
alias UString = StringBase!char;

unittest
{
  StaticStackMemory!2048 StackMemory;
  auto TestAllocator = Wrap(StackMemory);

  WString TestString = WString("This is a Test", TestAllocator);

  assert(TestString == "This is a Test");
  assert(TestString == TestString);
  assert(TestString != "Another String");

  auto AnotherString = TestString;

  AnotherString[2] = 'b';

  assert(TestString == "This is a Test");
  assert(AnotherString == "Thbs is a Test");

  assert(TestString.StartsWith("This"));
  assert(!TestString.StartsWith("Test"));
  assert(TestString.EndsWith("Test"));
  assert(!TestString.EndsWith("bar"));
  assert(TestString.Find("is") == 2);
  assert(TestString.Find(TestString) == 0);
  assert(TestString.Find("foo") == -1);

  assert(TestString.ReplaceFirst("This is a", "Yet another"));
  assert(TestString == "Yet another Test");
  assert(TestString.ReplaceAll("t", "f") ==  3);
  assert(TestString == "Yef anofher Tesf");

  //TODO(Marvin): Retest when assign is back again
  //TestString = "TESTESTEST";
  TestString = WString("TESTESTEST", TestAllocator);
  assert(TestString.ReplaceAll("TEST", "TEST") == 2);
  assert(TestString == "TESTESTEST");
  assert(TestString.ReplaceAll("TEST", "FOO") == 2);
  assert(TestString == "FOOESFOO");

  TestString = WString("Conc", TestAllocator).ConcatCopy("atenation");

  assert(TestString == "Concatenation");

  TestString = WString("Another ", TestAllocator) + "Test" + " for" + " concatenation";

  assert(TestString == "Another Test for concatenation");

  AnotherString = TestString;

  assert(AnotherString.Concat(". And again.") == 42);

  assert(TestString == "Another Test for concatenation");
  assert(AnotherString == "Another Test for concatenation. And again.");
  assert(AnotherString.FindLast(".") == 41);
  assert(AnotherString.Find(".") == 30);
}
