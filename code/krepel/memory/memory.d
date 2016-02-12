module krepel.memory.memory;
import krepel.math;

alias KiB = a => a * 1024;
alias MiB = a => a * 1024.KiB;
alias GiB = a => a * 1024.MiB;
alias TiB = a => a * 1024.GiB;
alias PiB = a => a * 1024.TiB;

alias KB = a => a * 1000;
alias MB = a => a * 1000.KiB;
alias GB = a => a * 1000.MiB;
alias TB = a => a * 1000.GiB;
alias PB = a => a * 1000.TiB;

alias MemoryRegion = ubyte[];
alias StaticMemoryRegion(size_t N) = ubyte[N];

enum GlobalDefaultAlignment = size_t.sizeof;

auto AlignedSize(size_t Size, size_t Alignment)
{
  assert(Alignment.IsPowerOfTwo, "The Alignment must be a power of two.");

  if(Alignment == 0)
    return Size;

  return ((Size + Alignment - 1) / Alignment) * Alignment;
}

auto AlignedPointer(T)(T* Pointer, size_t Alignment)
{
  return cast(T*)AlignedSize(cast(size_t)Pointer, Alignment);
}

alias SetBit    = (Bits, Position) => Bits |  (1 << Position);
alias RemoveBit = (Bits, Position) => Bits & ~(1 << Position);

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
