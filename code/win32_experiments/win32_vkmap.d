module win32_experiments.win32_vkmap;

import krepel.input;

import core.sys.windows.windows;

immutable(InputProperties*) Win32MapVirtualKeyToKrepelKey(WPARAM VKCode)
{
  switch(VKCode)
  {
    case VK_ESCAPE: return &Keyboard_Escape;
    case VK_SPACE:  return &Keyboard_Space;
    case 'W':       return &Keyboard_KeyW;
    case 'A':       return &Keyboard_KeyA;
    case 'S':       return &Keyboard_KeyS;
    case 'D':       return &Keyboard_KeyD;

    default:        return &Keyboard_Unknown;
  }
}
