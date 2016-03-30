module krepel.memory.reference_counting;

import krepel.memory.construction;
import krepel.memory.allocator_interface;
import Meta = krepel.meta;

struct RefCountPayloadData
{
  IAllocator Allocator;
  long RefCount;

  void AddRef()
  {
    // TODO(Manu): Thread safety.

    RefCount++;
  }

  void RemoveRef()
  {
    // TODO(Manu): Thread safety.

    RefCount--;
    assert(RefCount >= 0, "Invalid reference count.");
  }
}

/// Used for external reference-counting.
class RefCountWrapper(Type)
{
  RefCountPayloadData RefCountPayload;
  InPlace!Type.Data _Wrapped;

  this(ArgTypes...)(auto ref ArgTypes Args)
  {
    InPlace!Type.Construct(_Wrapped, Args);
  }

  ~this()
  {
    InPlace!Type.Destruct(_Wrapped);
  }

  alias _Wrapped this;
}

/// Pointer-like wrapper for reference-counted objects.
struct ARC(Type)
{
  Type _Instance;

  this(this)
  {
    assert(_Instance);
    _Instance.RefCountPayload.AddRef();
  }

  ~this()
  {
    assert(_Instance);
    _Instance.RefCountPayload.RemoveRef();
    if(_Instance.RefCountPayload.RefCount <= 0)
    {
      _Instance.RefCountPayload.Allocator.Delete(_Instance);
    }
  }

  alias _Instance this;
}

/// Convenience wrapper to query the current reference count of an object.
@property auto RefCount(Type)(auto ref in Type Object)
  if(Meta.HasMember!(Type, "RefCountPayload"))
{
  return Object.RefCountPayload.RefCount;
}

enum RefCountMode
{
  Auto,     // Either intrusive if the type has a RefCountPayload member, otherwise same as External.
  External, // Reference counting is done separately from the actual object.
}

/// Allocates an automatically reference-counted object and initializes it
/// with the given arguments.
auto NewARC(Type, RefCountMode Mode = RefCountMode.Auto, ArgTypes...)(IAllocator Allocator, auto ref ArgTypes Args)
  if(is(Type == class))
{
  enum BeInstrusive = Mode != RefCountMode.External && Meta.HasMember!(Type, "RefCountPayload");

  static if(BeInstrusive) alias InstanceType = Type;
  else                    alias InstanceType = RefCountWrapper!Type;

  auto Instance = Allocator.New!InstanceType(Args);
  Instance.RefCountPayload.Allocator = Allocator;
  Instance.RefCountPayload.RefCount = 1;

  auto Result = ARC!InstanceType(Instance);
  return Result;
}

//
// Unit Tests
//

version(unittest) import krepel.memory : CreateTestAllocator;

// NewARC for external reference counting
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

  RefCountWrapper!TestObject ObjectData;

  {
    int Message;
    ARC!(RefCountWrapper!TestObject) WrappedObject = TestAllocator.NewARC!TestObject(&Message);
    assert(Message == 1);
    assert(WrappedObject.Foo == 42);
    import krepel.math : IsNaN;
    assert(WrappedObject.Bar.IsNaN);

    ObjectData = WrappedObject._Instance;
    assert(ObjectData.RefCount == 1);
  }

  assert(ObjectData.RefCount == 0);
  assert(ObjectData.Foo == 42);
  assert(ObjectData.Bar == 3.1415f);
}

// NewARC for intrusive reference counting
unittest
{
  class TestObject
  {
    RefCountPayloadData RefCountPayload;
    int Foo = 42;

    ~this()
    {
      Foo = 94;
    }
  }

  auto TestAllocator = CreateTestAllocator();

  TestObject Object;

  {
    ARC!TestObject WrappedObject = TestAllocator.NewARC!TestObject();
    assert(WrappedObject.RefCount == 1);
    assert(WrappedObject.Foo == 42);

    Object = WrappedObject;
  }

  assert(Object.RefCount == 0);
  assert(Object.Foo == 94);
}
