module krepel.system.system;

import krepel.win32.system;

/// ReadFile
unittest
{
  import krepel.memory;
  import krepel.system.ifile;
  import std.conv;

  StaticStackMemory!1024 SomeStack;
  auto SomeAllocator = Wrap(SomeStack);

  IFile File = OpenFile(SomeAllocator, "../unittest/FileTest.txt");

  auto Region = SomeAllocator.Allocate(128);

  long BytesRead = File.Read(Region);

  CloseFile(SomeAllocator, File);

  assert(BytesRead == 15, BytesRead.to!string());
  assert(cast(char[])Region[0..BytesRead] == "Some Test Data\n");
}

/// WriteFile
unittest
{
  import krepel.memory;
  import krepel.system.ifile;
  import std.conv;

  StaticStackMemory!1024 SomeStack;
  auto SomeAllocator = Wrap(SomeStack);

  IFile File = OpenFile(SomeAllocator, "../unittest/tmp/WriteFileTest.txt", FileOpenMode.Write);

  auto Region = SomeAllocator.Allocate(128);

  Region[0..20] = cast(ubyte[])"Some Other Test Data";

  long BytesRead = File.Write(Region[0..20]);

  CloseFile(SomeAllocator, File);

  File = OpenFile(SomeAllocator, "../unittest/tmp/WriteFileTest.txt");

  Region = SomeAllocator.Allocate(128);

  BytesRead = File.Read(Region);

  CloseFile(SomeAllocator, File);

  assert(BytesRead == 20);
  assert(cast(char[])Region[0..BytesRead] == "Some Other Test Data");

}

/// File Cursor
unittest
{
  import krepel.memory;
  import krepel.system.ifile;
  import std.conv;

  StaticStackMemory!1024 SomeStack;
  auto SomeAllocator = Wrap(SomeStack);

  IFile File = OpenFile(SomeAllocator, "../unittest/FileTest.txt");

  auto Region = SomeAllocator.Allocate(128);

  auto Position = File.MoveCursor(0);
  assert(Position == 0);
  Position = File.MoveCursor(5);
  assert(Position == 5);
  Position = File.SetCursorPosition(false, 0);
  assert(Position == 15);
  Position = File.SetCursorPosition(true, 5);
  assert(Position == 5);

  long BytesRead = File.Read(Region);

  CloseFile(SomeAllocator, File);

  assert(BytesRead == 10, BytesRead.to!string());
  assert(cast(char[])Region[0..BytesRead] == "Test Data\n");
}

/// Read Line
unittest
{
  import krepel.container;
  import krepel.memory;
  import krepel.system.ifile;

  StaticStackMemory!1024 SomeStack;
  auto SomeAllocator = Wrap(SomeStack);

  IFile File = OpenFile(SomeAllocator, "../unittest/ReadLineTest.txt");
  Array!char Data = Array!char(SomeAllocator);

  File.ReadLine!char(Data);
  assert(Data.Count == 10);
  assert(Data.Data[] == "First line");
  Data.Clear();
  assert(Data.Count == 0);
  File.ReadLine(Data);
  assert(Data.Count == 11);
  assert(Data.Data[] == "Second line");
  Data.Clear();
  assert(Data.Count == 0);
  File.ReadLine(Data);
  assert(Data.Count == 10);
  assert(Data.Data[] == "Third line");

  CloseFile(SomeAllocator, File);

}

/// Size
unittest
{
  import krepel.container;
  import krepel.memory;
  import krepel.system.ifile;

  StaticStackMemory!1024 SomeStack;
  auto SomeAllocator = Wrap(SomeStack);

  IFile File = OpenFile(SomeAllocator, "../unittest/FileTest.txt");
  assert(File.Size == 15);
  CloseFile(SomeAllocator, File);
  assert(File.Size == 0);
}
