module win32_experiments.win32_vkmap;

import krepel.input;

import core.sys.windows.windows;

typeof(Keyboard.Unknown) Win32MapVirtualKeyToKrepelKey(WPARAM VKCode)
{
  switch(VKCode)
  {
    case VK_ESCAPE: return Keyboard.Escape;
    case VK_SPACE:  return Keyboard.Space;
    case 'W':       return Keyboard.W;
    case 'A':       return Keyboard.A;
    case 'S':       return Keyboard.S;
    case 'D':       return Keyboard.D;
    default:        return Keyboard.Unknown;
  }
}
