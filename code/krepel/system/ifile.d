module krepel.system.ifile;

import krepel.memory;

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
  /// MaxRead = The Maxmimum amount of bytes to read from the file
  /// Returns: Returns the amount of bytes written into Region. The value is >= 0 and <= MaxRead.
  long Read(MemoryRegion Region, long MaxRead)
  in
  {
    assert(MaxRead > 0);
    assert(Region.length >= MaxRead);
  }
  out(result)
  {
    assert(result > 0);
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
  long SetCursorPostion(bool FromStart, long Position)
  in
  {
    assert(Position >= 0);
  }

}
