module krepel.win32.win32;
version(Windows):

import core.sys.windows.windows;

import krepel.memory;

/// Dynamically allocates memory from standard system procedures.
/// Params:
///   RequestedBytes = The number of bytes the resulting memory block should have.
MemoryRegion SystemMemoryAllocation(size_t RequestedBytes)
{
  DWORD Flags;
  debug Flags |= HEAP_GENERATE_EXCEPTIONS;
  //debug Flags |= HEAP_ZERO_MEMORY;
  auto Heap = GetProcessHeap();
  auto RequestedMemoryPointer = HeapAlloc(Heap, Flags, cast(SIZE_T)RequestedBytes);
  return cast(MemoryRegion)RequestedMemoryPointer[0 .. RequestedBytes];
}

/// Tries to grow or shrink the given memory block by using standard system procedures.
/// Params:
///   Memory         = The memory block to reallocate.
///   RequestedBytes = The number of bytes the resulting memory block should have.
MemoryRegion SystemMemoryReallocation(MemoryRegion Memory, size_t RequestedBytes)
{
  DWORD Flags;
  //debug Flags |= HEAP_GENERATE_EXCEPTIONS;
  //debug Flags |= HEAP_ZERO_MEMORY;
  auto Heap = GetProcessHeap();
  auto RequestedMemoryPointer = HeapReAlloc(Heap, Flags, cast(LPVOID)Memory.ptr, cast(SIZE_T)RequestedBytes);
  return cast(MemoryRegion)RequestedMemoryPointer[0 .. RequestedBytes];
}

/// Dynamically allocates memory from standard system procedures.
/// Params:
///   Memory = The memory region to deallocate
bool SystemMemoryDeallocation(MemoryRegion Memory)
{
  auto Heap = GetProcessHeap();
  return HeapFree(Heap, 0, cast(LPVOID)Memory.ptr) != FALSE;
}
