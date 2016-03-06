module krepel.win32.win32file;

import core.sys.windows.windows;
import krepel.system.ifile;
import krepel.memory;

class Win32File : IFile
{
  HANDLE FileHandle;

  this(const char[] Path)
  {
    //auto NewHandle = CreateFile(
    //  Path.ptr,
    //  GENERIC_READ | GENERIC_WRITE,
    //  0,
    //  null,
    //  OPEN_EXISTING,
    //  FILE_ATTRIBUTE_NORMAL
    //  );
  }

  override int Read(MemoryRegion Region, int MaxRead)
  {
    return 0;
  }

  override void MoveCursor(int RelativeMove)
  {

  }

  override void SetCursorPostion(bool FromStart, int Position)
  {

  }
}
