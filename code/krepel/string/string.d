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

  this(this)
  {
    (*RefCount)++;
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

  const(CharType[]) opIndex() const
  {
    return Data.Data;
  }

  const(CharType[]) opSlice(size_t LeftIndex, size_t RightIndex) const
  {
    return Data.Data[LeftIndex .. RightIndex];
  }

  @property auto Count() const
  {
    return Data.Count;
  }

  uint* RefCount = null;
}

alias String = StringBase!wchar;
