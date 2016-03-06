module krepel.win32.system;

import krepel.system;

version(Windows):
@nogc:
nothrow:

/// Creates and opens a file at the given path
IFile OpenFile(const wchar[] Path, FileOpenMode Mode = FileOpenMode.Read)
{
  //TODO(Marvin): Create file using allocators
  //auto NewFile = new Win32File();
  //NewFile.OpenFile(Path, Mode);

  return null;
}

/// Closes and destroys the file handle.
/// Params:
/// File = The file handle to destroy, the File is no longer valid after this call
void CloseFile(IFile File)
{
  Win32File WinFile = cast(Win32File)File;
  WinFile.CloseFile();
}

/// Converts a long to a LARGE_INTEGER (useful for WINAPI calls, which expect 64 bit values as LARGE_INTEGER)
LARGE_INTEGER LargeInteger(long Value)
{
  LARGE_INTEGER LargeValue;
  LargeValue.QuadPart = Value;
  return LargeValue;
}
