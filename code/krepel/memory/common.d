module krepel.memory.common;
import krepel.math;

@nogc:
nothrow:
pure:

alias KiB = (const Bytes) => Bytes * (cast(size_t)1024);
alias MiB = (const Bytes) => Bytes * (cast(size_t)1024).KiB;
alias GiB = (const Bytes) => Bytes * (cast(size_t)1024).MiB;
alias TiB = (const Bytes) => Bytes * (cast(size_t)1024).GiB;
alias PiB = (const Bytes) => Bytes * (cast(size_t)1024).TiB;

alias KB  = (const Bytes) => Bytes * (cast(size_t)1000);
alias MB  = (const Bytes) => Bytes * (cast(size_t)1000).KB;
alias GB  = (const Bytes) => Bytes * (cast(size_t)1000).MB;
alias TB  = (const Bytes) => Bytes * (cast(size_t)1000).GB;
alias PB  = (const Bytes) => Bytes * (cast(size_t)1000).TB;

alias MemoryRegion = ubyte[];
alias StaticMemoryRegion(size_t N) = ubyte[N];

/// Note: Apparently it's a good idea to have an alignment of 16. See
///       https://en.wikipedia.org/wiki/Data_structure_alignment#x86
enum GlobalDefaultAlignment = 16;

auto AlignedSize(const size_t Size, const size_t Alignment)
{
  if(Alignment == 0)
    return Size;

  assert(Alignment.IsPowerOfTwo, "The Alignment must be a power of two.");
  return ((Size + Alignment - 1) / Alignment) * Alignment;
}

auto AlignedPointer(T)(const T* Pointer, const size_t Alignment)
{
  return cast(T*)AlignedSize(cast(size_t)Pointer, Alignment);
}

alias SetBit    = (const Bits, const Position) => Bits |  (1 << Position);
alias RemoveBit = (const Bits, const Position) => Bits & ~(1 << Position);
alias HasBit    = (const Bits, const Position) => cast(bool)(Bits &  (1 << Position));

version(unittest)
{
  /// Usage: mixin(SetupGlobalAllocatorForTesting!1024);
  template SetupGlobalAllocatorForTesting(size_t N)
  {
    import krepel : Format;
    enum SetupGlobalAllocatorForTesting = q{
      ubyte[%s] _SetupGlobalAllocatorForTesting_Buffer;
      auto _SetupGlobalAllocatorForTesting_Heap = HeapMemory(_SetupGlobalAllocatorForTesting_Buffer);
      auto _SetupGlobalAllocatorForTesting_PreviousGlobalAllocator = .GlobalAllocator;
      .GlobalAllocator = Wrap(_SetupGlobalAllocatorForTesting_Heap);
      scope(exit) .GlobalAllocator = _SetupGlobalAllocatorForTesting_PreviousGlobalAllocator;
    }.Format(N.stringof);
  }
}

//
// Unit Tests
//

unittest
{
  assert(AlignedSize(99,  0) ==  99);
  assert(AlignedSize(99,  1) ==  99);
  assert(AlignedSize(99,  2) == 100);
  assert(AlignedSize(99,  4) == 100);
  assert(AlignedSize(99,  8) == 104);
  assert(AlignedSize(99, 16) == 112);
  assert(AlignedSize(99, 32) == 128);

  assert(AlignedSize(100 - 1, 2) == 100);
  assert(AlignedSize(101 - 1, 2) == 100);
}

unittest
{
  ubyte[8] Bytes;
  for(ubyte i; i < Bytes.length; i++) Bytes[i] = i;

  assert(AlignedPointer(Bytes.ptr + 1, 4) == Bytes.ptr + 4);
}

unittest
{
  assert(SetBit(0b0000, 0) == 0b0001);
  assert(SetBit(0b0000, 1) == 0b0010);
  assert(SetBit(0b0000, 2) == 0b0100);
  assert(SetBit(0b0000, 3) == 0b1000);
}

unittest
{
  assert(RemoveBit(0b1111, 0) == 0b1110);
  assert(RemoveBit(0b1111, 1) == 0b1101);
  assert(RemoveBit(0b1111, 2) == 0b1011);
  assert(RemoveBit(0b1111, 3) == 0b0111);
  assert(RemoveBit(0b1111, 4) == 0b1111);
}

unittest
{
  assert(!HasBit(0b1010, 0));
  assert( HasBit(0b1010, 1));
  assert(!HasBit(0b1010, 2));
  assert( HasBit(0b1010, 3));
}
