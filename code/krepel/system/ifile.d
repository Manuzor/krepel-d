module krepel.system.ifile;

import krepel.memory;
import krepel.container;
import krepel.meta;

@nogc:
nothrow:

enum FileOpenMode
{
  Read = 0x1,
  Write = 0x2
}

interface IFile
{
  @nogc:
  nothrow:

  /// Reads data from a file
  /// Params:
  /// Region = Where the data will be written into which was red from the file
  /// Returns: Returns the amount of bytes written into Region. The value is >= 0 and <= Region.length.
  long Read(MemoryRegion Region)
  in
  {
    assert(Region.length > 0);
  }
  out(result)
  {
    assert(result >= 0);
  }

  /// Reads data from a file until it finds a \r or \n or the eof
  /// Params:
  /// Array = Where the data will be written into which was red from the file
  /// Returns: Returns the amount of bytes written into Region. The value is >= 0 and <= Region.length.
  long ReadLine(CharType)(ref Array!CharType Array)
    if(IsSomeChar!CharType)
  out(result)
  {
    assert(result >= 0);
  }
  body
  {
    CharType[10] Buffer;
    while(true)
    {
      auto CurPosition = MoveCursor(0);
      auto ReadCount = Read(cast(ubyte[])Buffer);
      foreach(Index; 0 .. ReadCount)
      {
        //Reached newline
        if(Buffer[Index] == '\r' || Buffer[Index] == '\n')
        {
          Array.PushBack(Buffer[0..Index]);
          SetCursorPosition(true, CurPosition + Index + 1);
          return Array.Count;
        }
      }
      //Reached EOF
      if (ReadCount < 10)
      {
        Array.PushBack(Buffer[0..ReadCount]);
        return Array.Count;
      }
      else
      {
        Array.PushBack(Buffer);
      }
    }
  }

  /// Moves the cursor relative to the current position
  /// Params:
  /// RelativeMove = Positive values will move the cursor towards the end of a file,
  /// while negative values will move the cursor towards the beginning of the file.
  ///
  /// Move will stop at either end of the file.
  long MoveCursor(long RelativeMove);

  /// Sets the cursor position at an absolute position, either from start or backwards from end
  /// Params:
  /// FromStart = If true, the Position will be the position in the file from the start,
  ///             so 0 will be at the start of the file.
  ///             If false, the Position will be subtracted from the end of the file,
  ///             e.g. a Value of 1 will Point at the last Character of the file
  /// Position = The Position to set according to the FromStart value.
  long SetCursorPosition(bool FromStart, long Position)
  in
  {
    assert(Position >= 0);
  }

  long Write(MemoryRegion Region)
  in
  {
    assert(Region.length > 0);
  }
  out(result)
  {
    assert(result >= 0);
  }

}
