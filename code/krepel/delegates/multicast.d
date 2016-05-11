module krepel.delegates.multicast;

import krepel;

struct MultiCastDelegate(ReturnType, DelegateArgs...)
{
  Array!(ReturnType delegate(DelegateArgs)) Listeners;

  this(IAllocator Allocator)
  {
    Listeners.Allocator = Allocator;
  }

  void Bind(ReturnType delegate(DelegateArgs) DelegateToBind)
  {
    Listeners ~= DelegateToBind;
  }

  ReturnType Call(DelegateArgs Arguments)
  {
    static if(is(ReturnType == void))
    {
      foreach(Delegate; Listeners)
      {
        Delegate(Arguments);
      }
    }
    else
    {
      ReturnType Value;
      foreach(Delegate; Listeners)
      {
        Value = Delegate(Arguments);
      }
      return Value;
    }
  }

  void opOpAssign(string Operator)(ReturnType delegate(DelegateArgs) DelegateToBind)
  {
    static if(Operator == "~" || Operator == "+")
    {
      Bind(DelegateToBind);
    }
    else static if(Operator == "-")
    {
      foreach (Index, Delegate; Listeners)
      {
        if(Delegate == DelegateToBind)
        {
          Listeners.RemoveAtSwap(Index);
          break;
        }
      }
    }
  }

  ReturnType opCall(DelegateArgs Arguments)
  {
    return Call(Arguments);
  }
}

unittest
{
  auto Allocator = CreateTestAllocator();
  int NumCalled = 0;
  void Test(int Value)
  {
    assert(Value == 3);
    NumCalled++;
  }

  auto IntCallbacks = MultiCastDelegate!(void, int)(Allocator);
  IntCallbacks.Bind(&Test);

  IntCallbacks.Call(3);
  assert(NumCalled == 1);
  IntCallbacks(3);
  assert(NumCalled == 2);
  IntCallbacks ~= &Test;
  IntCallbacks(3);
  assert(NumCalled == 4);
  IntCallbacks -= &Test;
  IntCallbacks -= &Test;
  IntCallbacks(3);
  assert(NumCalled == 4);

}
