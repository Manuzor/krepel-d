module krepel.win32;
version(Windows):

// Most windows headers are here.
public import core.sys.windows.windows;

// Krepel specific win32 platform stuff, like memory allocation.
public import krepel.win32.win32;

public import krepel.win32.win32file;
public import krepel.win32.system;
