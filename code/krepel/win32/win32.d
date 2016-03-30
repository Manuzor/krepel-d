module krepel.win32.win32;
version(Windows):

import core.sys.windows.windows;

import krepel.memory : AlignedPointer;
import krepel.math : IsPowerOfTwo;
import krepel.log;

/// Dynamically allocates memory from standard system procedures.
/// Params:
///   RequestedBytes = The number of bytes the resulting memory block should have.
///   Alignment      = The boundary to align the resulting memory region to.
void[] SystemMemoryAllocation(size_t RequestedBytes, size_t Alignment)
{
  AlignmentCheck(Alignment);

  if(RequestedBytes == 0) return null;

  // The MSDN dokumentation does not state anything about alignment when it comes to HeapAlloc.
  // Therefore we take care of it ourselves.

  DWORD Flags;
  //debug Flags |= HEAP_GENERATE_EXCEPTIONS;
  //debug Flags |= HEAP_ZERO_MEMORY;
  auto Heap = GetProcessHeap();
  auto RequestedMemoryPointer = HeapAlloc(Heap, Flags, cast(SIZE_T)(RequestedBytes + Alignment));
  auto AlignedMemoryPointer = AlignAndSavePadding(cast(ubyte*)RequestedMemoryPointer, Alignment);
  return cast(void[])AlignedMemoryPointer[0 .. RequestedBytes];
}

/// Tries to grow or shrink the given memory block by using standard system procedures.
/// Params:
///   Memory         = The memory block to reallocate.
///   RequestedBytes = The number of bytes the resulting memory block should have.
///   Alignment      = The boundary to align the resulting memory region to.
///                    Will only be used if the memory had to be moved.
void[] SystemMemoryReallocation(void[] Memory, size_t RequestedBytes, size_t Alignment)
{
  AlignmentCheck(Alignment);

  if(!Memory) return null;

  const PreviousPadding = *cast(ubyte*)(Memory.ptr - 1);
  const OriginalPointer = Memory.ptr - PreviousPadding;

  DWORD Flags;
  //debug Flags |= HEAP_GENERATE_EXCEPTIONS;
  //debug Flags |= HEAP_ZERO_MEMORY;
  auto Heap = GetProcessHeap();
  auto RequestedMemoryPointer = HeapReAlloc(Heap, Flags, cast(LPVOID)OriginalPointer,
                                            cast(SIZE_T)(RequestedBytes + Alignment));

  // Even if the resulting pointer did not change, the alignment might have
  // changed (by the user), so we just re-align the pointer and save the
  // potentially changed padding.
  auto AlignedMemoryPointer = AlignAndSavePadding(cast(ubyte*)RequestedMemoryPointer, Alignment);
  return cast(void[])AlignedMemoryPointer[0 .. RequestedBytes];
}

/// Dynamically allocates memory from standard system procedures.
/// Params:
///   Memory = The memory region to deallocate
bool SystemMemoryDeallocation(void[] Memory)
{
  if(Memory)
  {
    auto Heap = GetProcessHeap();
    const Padding = *cast(ubyte*)(Memory.ptr - 1);
    return HeapFree(Heap, 0, cast(LPVOID)(Memory.ptr - Padding)) != FALSE;
  }

  return false;
}

private void AlignmentCheck(size_t Alignment)
{
  assert(Alignment.IsPowerOfTwo, "Alignment must be a power of two.");
  assert(Alignment <= ubyte.max, "Alignment value must fit into 1 byte!");
}

/// Aligns the given pointer to the given alignment, makes sure there is at
/// least 1 byte of padding, and saves that padding in the byte just before
/// the resulting pointer.
private auto AlignAndSavePadding(ubyte* InputPointer, size_t Alignment)
{
  auto ResultPointer = AlignedPointer(InputPointer, Alignment);
  const WasAligned = ResultPointer == InputPointer;
  if(WasAligned) ResultPointer += Alignment;
  const Padding = ResultPointer - InputPointer;
  assert(Padding > 0, "Padding must always exist, otherwise we can't save the padding value anywhere!");

  // Save the padding value in the byte immediately to the left of the pointer the user will see.
  *(cast(ubyte*)ResultPointer - 1) = cast(ubyte)Padding;
  return ResultPointer;
}

/// Log sink that outputs to Visual Studio's Output window.
void VisualStudioLogSink(LogLevel Level, char[] Message)
{
  char[1024] Buffer = void;

  final switch(Level)
  {
    case LogLevel.Info:    OutputDebugStringA("Info: ");    break;
    case LogLevel.Warning: OutputDebugStringA("Warning: "); break;
    case LogLevel.Failure: OutputDebugStringA("Failure: "); break;
  }

  while(Message.length)
  {
    auto Amount = Min(Buffer.length - 1, Message.length);

    Buffer[Amount] = '\0';
    // Copy over the data.
    Buffer[0 .. Amount] = Message[0 .. Amount];

    OutputDebugStringA(cast(const(char)*)Buffer.ptr);

    Message = Message[Amount .. $];
  }

  OutputDebugStringA("\n");
}
