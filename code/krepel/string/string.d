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

  ulong Find(const(CharType[]) SearchString, ulong SearchStardIndex = 0) const
  {
    long SearchIndex = SearchStardIndex;
    while(SearchString.length + SearchIndex <= Count)
    {
      if (this[SearchIndex .. SearchIndex + SearchString.length] == SearchString)
      {
        return SearchIndex;
      }
      SearchIndex++;
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
    return Count;
  }

  StringBase!CharType ConcatCopy(const(CharType[]) OtherString) const
  {
    StringBase!CharType Result = StringBase!CharType(this);
    Result.Concat(OtherString);
    return Result;
  }

  StringBase!CharType opBinary(string Operator : "+")(const(CharType[]) OtherString)
  {
    return ConcatCopy(OtherString);
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

  void opAssign(const CharType[] Chars)
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
    this = StringBase!CharType(Chars);
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
  StaticStackMemory!2048 StackMemory;
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

  TestString = "TESTESTEST";
  assert(TestString.ReplaceAll("TEST", "TEST") == 2);
  assert(TestString == "TESTESTEST");
  assert(TestString.ReplaceAll("TEST", "FOO") == 2);
  assert(TestString == "FOOESFOO");

  TestString = String("Conc").ConcatCopy("atenation");

  assert(TestString == "Concatenation");

  TestString = String("Another ") + "Test" + " for" + " concatenation";

  assert(TestString == "Another Test for concatenation");

  AnotherString = TestString;

  assert(AnotherString.Concat(". And again.") == 42);

  assert(TestString == "Another Test for concatenation");
  assert(AnotherString == "Another Test for concatenation. And again.");
}
