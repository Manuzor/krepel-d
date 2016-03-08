module krepel.system.system;

import krepel.win32.system;

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
