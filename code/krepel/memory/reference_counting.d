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
  static if(SupportsRefCounting!Type) alias StoredType = Type;
  else                                alias StoredType = RefCountWrapper!Type;

  StoredType _StoredInstance;
  @property inout(Type) _Instance() inout { return _StoredInstance; }

  this(this)
  {
    assert(_StoredInstance);
    _StoredInstance.RefCountPayload.AddRef();
  }

  ~this()
  {
    assert(_StoredInstance);
    _StoredInstance.RefCountPayload.RemoveRef();
    if(_StoredInstance.RefCountPayload.RefCount <= 0)
    {
      _StoredInstance.RefCountPayload.Allocator.Delete(_StoredInstance);
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

/// We assume a type supports reference counting when it has a member called
/// "RefCountPayload".
enum SupportsRefCounting(Type) = Meta.HasMember!(Type, "RefCountPayload");

/// Allocates an automatically reference-counted object and initializes it
/// with the given arguments.
ARC!Type NewARC(Type, ArgTypes...)(IAllocator Allocator, auto ref ArgTypes Args)
  if(is(Type == class))
{
  // ARC got the actual type figured out already, so we leverage that.
  alias InstanceType = ARC!Type.StoredType;

  auto Instance = Allocator.New!InstanceType(Args);
  Instance.RefCountPayload.Allocator = Allocator;
  Instance.RefCountPayload.RefCount = 1;

  auto Result = ARC!Type(Instance);
  return Result;
}

//
// Unit Tests
//


// NewARC for external reference counting
unittest
{
  import krepel.memory : CreateTestAllocator;

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
    ARC!TestObject WrappedObject = TestAllocator.NewARC!TestObject(&Message);
    assert(Message == 1);
    assert(WrappedObject.Foo == 42);
    import krepel.math : IsNaN;
    assert(WrappedObject.Bar.IsNaN);

    ObjectData = WrappedObject._StoredInstance;
    assert(ObjectData.RefCount == 1);
  }

  assert(ObjectData.RefCount == 0);
  assert(ObjectData.Foo == 42);
  assert(ObjectData.Bar == 3.1415f);
}

// NewARC for intrusive reference counting
unittest
{
  import krepel.memory : CreateTestAllocator;

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
