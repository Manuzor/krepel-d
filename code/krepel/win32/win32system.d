module krepel.win32.system;

import krepel.system;

IFile CreateFile(const char[] Path)
{
  return new Win32File(Path);
}
