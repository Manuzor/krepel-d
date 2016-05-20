module krepel.win32.system;

import krepel.system;
import krepel.memory;

version(Windows):

/// Creates and opens a file at the given path
IFile OpenFile(IAllocator Allocator, const wchar[] Path, FileOpenMode Mode = FileOpenMode.Read)
{
  auto NewFile = Allocator.New!Win32File();
  NewFile.OpenFile(Path, Mode);
  
  return NewFile;
}

/// Closes and destroys the file handle.
/// Params:
/// File = The file handle to destroy, the File is no longer valid after this call
void CloseFile(IAllocator Allocator, IFile File)
{
  Win32File WinFile = cast(Win32File)File;
  WinFile.CloseFile();
  Allocator.Delete(WinFile);
}

/// Converts a long to a LARGE_INTEGER (useful for WINAPI calls, which expect 64 bit values as LARGE_INTEGER)
LARGE_INTEGER LargeInteger(long Value)
{
  LARGE_INTEGER LargeValue = {QuadPart: Value};
  return LargeValue;
}
