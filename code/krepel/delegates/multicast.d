module krepel.delegates.multicast;

import krepel;

struct MultiCastDelegate(DelegateArgs...)
{
  Array!(void delegate(DelegateArgs)) Listeners;

  this(IAllocator Allocator)
  {
    Listeners.Allocator = Allocator;
  }

  void Bind(void delegate(DelegateArgs) DelegateToBind)
  {
    Listeners ~= DelegateToBind;
  }

  void Call(DelegateArgs Arguments)
  {
    foreach(Delegate; Listeners)
    {
      Delegate(Arguments);
    }
  }

  void opOpAssign(string Operator)(void delegate(DelegateArgs) DelegateToBind)
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

  void opCall(DelegateArgs Arguments)
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

  auto IntCallbacks = MultiCastDelegate!(int)(Allocator);
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
