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
