module krepel.win32.win32file;

import core.sys.windows.windows;
import krepel.system.ifile;
import krepel.memory;
import krepel.win32;
import krepel.container;

version(Windows):

class Win32File : IFile
{

  HANDLE FileHandle = INVALID_HANDLE_VALUE;

  void OpenFile(const wchar[] Path, FileOpenMode Mode)
  {
    DWORD OpenMode = 0;
    if ((Mode & FileOpenMode.Read) != 0)
    {
      OpenMode |= GENERIC_READ;
    }
    if ((Mode & FileOpenMode.Write) != 0)
    {
      OpenMode |= GENERIC_WRITE;
    }
    auto NewHandle = CreateFile(
      Path.ptr,
      OpenMode,
      0,
      null,
      ((OpenMode & GENERIC_WRITE) != 0) ? OPEN_ALWAYS : OPEN_EXISTING,
      FILE_ATTRIBUTE_NORMAL,
      null
      );
    assert(NewHandle != INVALID_HANDLE_VALUE);
    FileHandle = NewHandle;
  }

  void CloseFile()
  {
    auto Result = CloseHandle(FileHandle);
    assert(Result != 0);
    FileHandle = INVALID_HANDLE_VALUE;
  }

  override ulong Read(void[] Region)
  {
    assert(FileHandle != INVALID_HANDLE_VALUE);

    long TotalBytesRead = 0;

    for (long BytesToRead = Region.length; BytesToRead > 0; BytesToRead -= uint.max)
    {
      DWORD BytesRead = 0;
      DWORD TryAmountToRead = 0;
      if (BytesToRead > uint.max)
      {
        TryAmountToRead = uint.max;
      }
      else
      {
        TryAmountToRead = cast(uint)BytesToRead;
      }
      auto Result = ReadFile(
        FileHandle,
        (cast(void*)Region.ptr) + TotalBytesRead,
        TryAmountToRead,
        &BytesRead,
        null
        );
      assert(Result);
      TotalBytesRead += BytesRead;
      // Stop reading as we won't get more out of the file
      if (BytesRead < TryAmountToRead)
      {
        break;
      }
    }
    return TotalBytesRead;
  }

  override ulong Write(void[] Region)
  {
    assert(FileHandle != INVALID_HANDLE_VALUE);

    long TotalBytesWritten = 0;

    for (long BytesToWrite = Region.length; BytesToWrite > 0; BytesToWrite -= uint.max)
    {
      DWORD BytesWritten = 0;
      DWORD TryAmountToWrite = 0;
      if (BytesToWrite > uint.max)
      {
        TryAmountToWrite = uint.max;
      }
      else
      {
        TryAmountToWrite = cast(uint)BytesToWrite;
      }
      auto Result = WriteFile(
        FileHandle,
        (cast(void*)Region.ptr) + TotalBytesWritten,
        TryAmountToWrite,
        &BytesWritten,
        null
        );
      assert(Result);
      TotalBytesWritten += BytesWritten;
    }
    return TotalBytesWritten;
  }

  override ulong MoveCursor(long RelativeMove)
  {
    assert(FileHandle != INVALID_HANDLE_VALUE);

    LARGE_INTEGER NewPosition;

    auto Result = SetFilePointerEx(
      FileHandle,
      RelativeMove.LargeInteger,
      &NewPosition,
      FILE_CURRENT
      );
    assert(Result);

    return NewPosition.QuadPart;
  }

  override ulong SetCursorPosition(bool FromStart, ulong Position)
  {
    assert(FileHandle != INVALID_HANDLE_VALUE);

    LARGE_INTEGER NewPosition;

    auto Result = SetFilePointerEx(
      FileHandle,
      Position.LargeInteger,
      &NewPosition,
      FromStart ? FILE_BEGIN : FILE_END
      );
    assert(Result);

    return NewPosition.QuadPart;
  }
}
