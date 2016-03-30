module krepel.memory.reference_counting;

import krepel.memory.construction;
import krepel.memory.allocator_interface;
import Meta = krepel.meta;

/// Allocation data for reference counted objects.
class ARCData(Type)
{
  IAllocator Allocator;
  long RefCount;
  InPlace!Type.Data Instance;

  this(IAllocator Allocator, long InitialRefCount)
  {
    this.Allocator = Allocator;
    this.RefCount = InitialRefCount;
  }

  void AddRef()
  {
    // TODO(Manu): Thread safety.unt)++;

    RefCount++;
  }

  void RemoveRef()
  {
    // TODO(Manu): Thread safety.

    RefCount--;

    assert(RefCount >= 0, "Invalid reference count.");
    if(RefCount <= 0)
    {
      InPlace!Type.Destruct(Instance);
      Allocator.Delete(this);
    }
  }
}

/// Pointer-like wrapper for reference-counted objects.
struct ARC(Type)
{
  ARCData!Type _Data;

  @property inout(Type) _Instance() inout
  {
    assert(_Data);
    return _Data.Instance;
  }

  this(this)
  {
    assert(_Data);
    _Data.AddRef();
  }

  ~this()
  {
    assert(_Data);
    _Data.RemoveRef();
  }

  alias _Instance this;
}

@property auto RefCount(Type)(ref in ARC!Type Object)
{
  return Object._Data.RefCount;
}

/// Allocates an automatically reference-counted object and initializes it
/// with the given arguments.
ARC!Type NewARC(Type, ArgTypes...)(IAllocator Allocator, auto ref ArgTypes Args)
  if(is(Type == class))
{
  auto Data = Allocator.New!(ARCData!Type)(Allocator, 1);
  InPlace!Type.Construct(Data.Instance, Args);
  auto Result = ARC!Type(Data);
  return Result;
}

//
// Unit Tests
//

version(unittest) import krepel.memory : CreateTestAllocator;

// NewARC
unittest
{
  class TestObject
  {
    int Foo = 42;
    float Bar;

    this(int* Message)
    {
      assert(Message);
      *Message += 1;
    }

    ~this()
    {
      Bar = 3.1415f;
    }
  }

  auto TestAllocator = CreateTestAllocator();

  ARCData!TestObject* ObjectData;

  {
    int Message;
    auto WrappedObject = TestAllocator.NewARC!TestObject(&Message);
    assert(Message == 1);
    assert(WrappedObject.Foo == 42);
    import krepel.math : IsNaN;
    assert(WrappedObject.Bar.IsNaN);

    ObjectData = &WrappedObject._Data;
    assert(ObjectData.RefCount == 1);
  }

  assert(ObjectData.RefCount == 0);
  assert(ObjectData.Instance.Foo == 42);
  assert(ObjectData.Instance.Bar == 3.1415f);
}
