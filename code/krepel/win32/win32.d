module krepel.win32.win32;
version(Windows):

import core.sys.windows.windows;

import krepel.memory : AlignedPointer;
import krepel.math : IsPowerOfTwo;
import krepel.log;

/// Dynamically allocates memory from standard system procedures.
/// Params:
///   RequestedBytes = The number of bytes the resulting memory block should have.
///   Alignment      = The boundary to align the resulting memory region to.
void[] SystemMemoryAllocation(size_t RequestedBytes, size_t Alignment)
{
  AlignmentCheck(Alignment);

  if(RequestedBytes == 0) return null;

  // The MSDN dokumentation does not state anything about alignment when it comes to HeapAlloc.
  // Therefore we take care of it ourselves.

  DWORD Flags;
  //debug Flags |= HEAP_GENERATE_EXCEPTIONS;
  //debug Flags |= HEAP_ZERO_MEMORY;
  auto Heap = GetProcessHeap();
  auto RequestedMemoryPointer = HeapAlloc(Heap, Flags, cast(SIZE_T)(RequestedBytes + Alignment));
  auto AlignedMemoryPointer = AlignAndSavePadding(cast(ubyte*)RequestedMemoryPointer, Alignment);
  return cast(void[])AlignedMemoryPointer[0 .. RequestedBytes];
}

/// Tries to grow or shrink the given memory block by using standard system procedures.
/// Params:
///   Memory         = The memory block to reallocate.
///   RequestedBytes = The number of bytes the resulting memory block should have.
///   Alignment      = The boundary to align the resulting memory region to.
///                    Will only be used if the memory had to be moved.
void[] SystemMemoryReallocation(void[] Memory, size_t RequestedBytes, size_t Alignment)
{
  AlignmentCheck(Alignment);

  if(!Memory) return null;

  const PreviousPadding = *cast(ubyte*)(Memory.ptr - 1);
  const OriginalPointer = Memory.ptr - PreviousPadding;

  DWORD Flags;
  //debug Flags |= HEAP_GENERATE_EXCEPTIONS;
  //debug Flags |= HEAP_ZERO_MEMORY;
  auto Heap = GetProcessHeap();
  auto RequestedMemoryPointer = HeapReAlloc(Heap, Flags, cast(LPVOID)OriginalPointer,
                                            cast(SIZE_T)(RequestedBytes + Alignment));

  // Even if the resulting pointer did not change, the alignment might have
  // changed (by the user), so we just re-align the pointer and save the
  // potentially changed padding.
  auto AlignedMemoryPointer = AlignAndSavePadding(cast(ubyte*)RequestedMemoryPointer, Alignment);
  return cast(void[])AlignedMemoryPointer[0 .. RequestedBytes];
}

/// Dynamically allocates memory from standard system procedures.
/// Params:
///   Memory = The memory region to deallocate
bool SystemMemoryDeallocation(void[] Memory)
{
  if(Memory)
  {
    auto Heap = GetProcessHeap();
    const Padding = *cast(ubyte*)(Memory.ptr - 1);
    return HeapFree(Heap, 0, cast(LPVOID)(Memory.ptr - Padding)) != FALSE;
  }

  return false;
}

private void AlignmentCheck(size_t Alignment)
{
  assert(Alignment.IsPowerOfTwo, "Alignment must be a power of two.");
  assert(Alignment <= ubyte.max, "Alignment value must fit into 1 byte!");
}

/// Aligns the given pointer to the given alignment, makes sure there is at
/// least 1 byte of padding, and saves that padding in the byte just before
/// the resulting pointer.
private auto AlignAndSavePadding(ubyte* InputPointer, size_t Alignment)
{
  auto ResultPointer = AlignedPointer(InputPointer, Alignment);
  const WasAligned = ResultPointer == InputPointer;
  if(WasAligned) ResultPointer += Alignment;
  const Padding = ResultPointer - InputPointer;
  assert(Padding > 0, "Padding must always exist, otherwise we can't save the padding value anywhere!");

  // Save the padding value in the byte immediately to the left of the pointer the user will see.
  *(cast(ubyte*)ResultPointer - 1) = cast(ubyte)Padding;
  return ResultPointer;
}

/// Log sink that outputs to Visual Studio's Output window.
void VisualStudioLogSink(LogLevel Level, char[] Message)
{
  char[1024] Buffer = void;

  final switch(Level)
  {
    case LogLevel.Info:    OutputDebugStringA("[Krepel] Info: "); break;
    case LogLevel.Warning: OutputDebugStringA("[Krepel] Warn: "); break;
    case LogLevel.Failure: OutputDebugStringA("[Krepel] Fail: "); break;
  }

  while(Message.length)
  {
    auto Amount = Min(Buffer.length - 1, Message.length);

    Buffer[Amount] = '\0';
    // Copy over the data.
    Buffer[0 .. Amount] = Message[0 .. Amount];

    OutputDebugStringA(cast(const(char)*)Buffer.ptr);

    Message = Message[Amount .. $];
  }

  OutputDebugStringA("\n");
}

string Win32MessageIdToString(DWORD MessageId)
{
  switch(MessageId)
  {
    case      0: return "WM_NULL";
    case      1: return "WM_CREATE";
    case      2: return "WM_DESTROY";
    case      3: return "WM_MOVE";
    case      5: return "WM_SIZE";
    case      6: return "WM_ACTIVATE";
    case      7: return "WM_SETFOCUS";
    case      8: return "WM_KILLFOCUS";
    case     10: return "WM_ENABLE";
    case     11: return "WM_SETREDRAW";
    case     12: return "WM_SETTEXT";
    case     13: return "WM_GETTEXT";
    case     14: return "WM_GETTEXTLENGTH";
    case     15: return "WM_PAINT";
    case     16: return "WM_CLOSE";
    case     17: return "WM_QUERYENDSESSION";
    case     18: return "WM_QUIT";
    case     19: return "WM_QUERYOPEN";
    case     20: return "WM_ERASEBKGND";
    case     21: return "WM_SYSCOLORCHANGE";
    case     22: return "WM_ENDSESSION";
    case     24: return "WM_SHOWWINDOW";
    case     26: return "WM_SETTINGCHANGE,WM_WININICHANGE";
    case     27: return "WM_DEVMODECHANGE";
    case     28: return "WM_ACTIVATEAPP";
    case     29: return "WM_FONTCHANGE";
    case     30: return "WM_TIMECHANGE";
    case     31: return "WM_CANCELMODE";
    case     32: return "WM_SETCURSOR";
    case     33: return "WM_MOUSEACTIVATE";
    case     34: return "WM_CHILDACTIVATE";
    case     35: return "WM_QUEUESYNC";
    case     36: return "WM_GETMINMAXINFO";
    case     38: return "WM_PAINTICON";
    case     39: return "WM_ICONERASEBKGND";
    case     40: return "WM_NEXTDLGCTL";
    case     42: return "WM_SPOOLERSTATUS";
    case     43: return "WM_DRAWITEM";
    case     44: return "WM_MEASUREITEM";
    case     45: return "WM_DELETEITEM";
    case     46: return "WM_VKEYTOITEM";
    case     47: return "WM_CHARTOITEM";
    case     48: return "WM_SETFONT";
    case     49: return "WM_GETFONT";
    case     50: return "WM_SETHOTKEY";
    case     51: return "WM_GETHOTKEY";
    case     55: return "WM_QUERYDRAGICON";
    case     57: return "WM_COMPAREITEM";
    case     65: return "WM_COMPACTING";
    case     68: return "WM_COMMNOTIFY";
    case     70: return "WM_WINDOWPOSCHANGING";
    case     71: return "WM_WINDOWPOSCHANGED";
    case     72: return "WM_POWER";
    case     74: return "WM_COPYDATA";
    case     75: return "WM_CANCELJOURNAL";
    case     78: return "WM_NOTIFY";
    case     80: return "WM_INPUTLANGCHANGEREQUEST";
    case     81: return "WM_INPUTLANGCHANGE";
    case     82: return "WM_TCARD";
    case     83: return "WM_HELP";
    case     84: return "WM_USERCHANGED";
    case     85: return "WM_NOTIFYFORMAT";
    case    123: return "WM_CONTEXTMENU";
    case    124: return "WM_STYLECHANGING";
    case    125: return "WM_STYLECHANGED";
    case    126: return "WM_DISPLAYCHANGE";
    case    127: return "WM_GETICON";
    case    128: return "WM_SETICON";
    case    129: return "WM_NCCREATE";
    case    130: return "WM_NCDESTROY";
    case    131: return "WM_NCCALCSIZE";
    case    132: return "WM_NCHITTEST";
    case    133: return "WM_NCPAINT";
    case    134: return "WM_NCACTIVATE";
    case    135: return "WM_GETDLGCODE";
    case    136: return "WM_SYNCPAINT";
    case    160: return "WM_NCMOUSEMOVE";
    case    161: return "WM_NCLBUTTONDOWN";
    case    162: return "WM_NCLBUTTONUP";
    case    163: return "WM_NCLBUTTONDBLCLK";
    case    164: return "WM_NCRBUTTONDOWN";
    case    165: return "WM_NCRBUTTONUP";
    case    166: return "WM_NCRBUTTONDBLCLK";
    case    167: return "WM_NCMBUTTONDOWN";
    case    168: return "WM_NCMBUTTONUP";
    case    169: return "WM_NCMBUTTONDBLCLK";
    case    171: return "WM_NCXBUTTONDOWN";
    case    172: return "WM_NCXBUTTONUP";
    case    173: return "WM_NCXBUTTONDBLCLK";
    case    255: return "WM_INPUT";
    case    256: return "WM_KEYDOWN";
    case    257: return "WM_KEYUP";
    case    258: return "WM_CHAR";
    case    259: return "WM_DEADCHAR";
    case    260: return "WM_SYSKEYDOWN";
    case    261: return "WM_SYSKEYUP";
    case    262: return "WM_SYSCHAR";
    case    263: return "WM_SYSDEADCHAR";
    case    264: return "WM_KEYLAST";
    case    265: return "WM_UNICHAR";
    case    272: return "WM_INITDIALOG";
    case    273: return "WM_COMMAND";
    case    274: return "WM_SYSCOMMAND";
    case    275: return "WM_TIMER";
    case    276: return "WM_HSCROLL";
    case    277: return "WM_VSCROLL";
    case    278: return "WM_INITMENU";
    case    279: return "WM_INITMENUPOPUP";
    case    287: return "WM_MENUSELECT";
    case    288: return "WM_MENUCHAR";
    case    289: return "WM_ENTERIDLE";
    case    290: return "WM_MENURBUTTONUP";
    case    291: return "WM_MENUDRAG";
    case    292: return "WM_MENUGETOBJECT";
    case    293: return "WM_UNINITMENUPOPUP";
    case    294: return "WM_MENUCOMMAND";
    case    295: return "WM_CHANGEUISTATE";
    case    296: return "WM_UPDATEUISTATE";
    case    297: return "WM_QUERYUISTATE";
    case    298: return "WM_NCMOUSEHOVER";
    case    299: return "WM_MOUSEHOVER";
    case    300: return "WM_NCMOUSELEAVE";
    case    301: return "WM_MOUSELEAVE";
    case    306: return "WM_CTLCOLORMSGBOX";
    case    307: return "WM_CTLCOLOREDIT";
    case    308: return "WM_CTLCOLORLISTBOX";
    case    309: return "WM_CTLCOLORBTN";
    case    310: return "WM_CTLCOLORDLG";
    case    311: return "WM_CTLCOLORSCROLLBAR";
    case    312: return "WM_CTLCOLORSTATIC";
    case    512: return "WM_MOUSEMOVE";
    case    513: return "WM_LBUTTONDOWN";
    case    514: return "WM_LBUTTONUP";
    case    515: return "WM_LBUTTONDBLCLK";
    case    516: return "WM_RBUTTONDOWN";
    case    517: return "WM_RBUTTONUP";
    case    518: return "WM_RBUTTONDBLCLK";
    case    519: return "WM_MBUTTONDOWN";
    case    520: return "WM_MBUTTONUP";
    case    521: return "WM_MBUTTONDBLCLK";
    case    522: return "WM_MOUSEWHEEL";
    case    523: return "WM_XBUTTONDOWN";
    case    524: return "WM_XBUTTONUP";
    case    525: return "WM_XBUTTONDBLCLK";
    case    526: return "WM_MOUSEHWHEEL";
    case    528: return "WM_PARENTNOTIFY";
    case    529: return "WM_ENTERMENULOOP";
    case    530: return "WM_EXITMENULOOP";
    case    531: return "WM_NEXTMENU";
    case    532: return "WM_SIZING";
    case    533: return "WM_CAPTURECHANGED";
    case    534: return "WM_MOVING";
    case    536: return "WM_POWERBROADCAST";
    case    537: return "WM_DEVICECHANGE";
    case    544: return "WM_MDICREATE";
    case    545: return "WM_MDIDESTROY";
    case    546: return "WM_MDIACTIVATE";
    case    547: return "WM_MDIRESTORE";
    case    548: return "WM_MDINEXT";
    case    549: return "WM_MDIMAXIMIZE";
    case    550: return "WM_MDITILE";
    case    551: return "WM_MDICASCADE";
    case    552: return "WM_MDIICONARRANGE";
    case    553: return "WM_MDIGETACTIVE";
    case    560: return "WM_MDISETMENU";
    case    561: return "WM_ENTERSIZEMOVE";
    case    562: return "WM_EXITSIZEMOVE";
    case    563: return "WM_DROPFILES";
    case    564: return "WM_MDIREFRESHMENU";
    case    689: return "WM_WTSSESSION_CHANGE";
    case    704: return "WM_TABLET_FIRST";
    case    735: return "WM_TABLET_LAST";
    case    768: return "WM_CUT";
    case    769: return "WM_COPY";
    case    770: return "WM_PASTE";
    case    771: return "WM_CLEAR";
    case    772: return "WM_UNDO";
    case    773: return "WM_RENDERFORMAT";
    case    774: return "WM_RENDERALLFORMATS";
    case    775: return "WM_DESTROYCLIPBOARD";
    case    776: return "WM_DRAWCLIPBOARD";
    case    777: return "WM_PAINTCLIPBOARD";
    case    778: return "WM_VSCROLLCLIPBOARD";
    case    779: return "WM_SIZECLIPBOARD";
    case    780: return "WM_ASKCBFORMATNAME";
    case    781: return "WM_CHANGECBCHAIN";
    case    782: return "WM_HSCROLLCLIPBOARD";
    case    783: return "WM_QUERYNEWPALETTE";
    case    784: return "WM_PALETTEISCHANGING";
    case    785: return "WM_PALETTECHANGED";
    case    786: return "WM_HOTKEY";
    case    791: return "WM_PRINT";
    case    792: return "WM_PRINTCLIENT";
    case    793: return "WM_APPCOMMAND";
    case    794: return "WM_THEMECHANGED";
    case    856: return "WM_HANDHELDFIRST";
    case    863: return "WM_HANDHELDLAST";
    case    864: return "WM_AFXFIRST";
    case    895: return "WM_AFXLAST";
    case    896: return "WM_PENWINFIRST";
    case    911: return "WM_PENWINLAST";
    case   1024: return "WM_USER";
    case  32768: return "WM_APP";

    default: return "<Unknown Windows Message ID>";
  }
}
