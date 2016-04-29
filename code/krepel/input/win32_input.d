module krepel.input.win32_vkmap;

import krepel;
import krepel.win32;

import krepel.input.input;
import krepel.input.keyboard;
import krepel.input.mouse;


Flag!"Processed" Win32ProcessInputMessage(HWND WindowHandle, UINT Message, WPARAM WParam, LPARAM LParam,
                                          ref InputQueueData InputQueue,
                                          LogData* Log = null)
{
  //
  // Keyboard messages
  //
  if(Message >= WM_KEYFIRST && Message <= WM_KEYLAST)
  {
    //Log.Info("Keyboard message: %s", Win32MessageIdToString(Message));

    auto VKCode = WParam;
    auto WasDown = (LParam & (1 << 30)) != 0;
    auto IsDown = (LParam & (1 << 31)) == 0;

    if(WasDown == IsDown)
    {
      // No change.
      return Yes.Processed;
    }

    InputId KeyId = Win32VirtualKeyToInputId(VKCode, LParam);

    if(KeyId is null)
    {
      Log.Warning("Unable to map virtual key code %d (Hex: 0x%x)", VKCode, VKCode);
      return Yes.Processed;
    }

    InputValueData KeyValue;
    KeyValue.Type = InputType.Button;
    KeyValue.ButtonIsDown = IsDown;
    InputQueue.Enqueue(KeyId, KeyValue);

    return Yes.Processed;
  }

  //
  // Mouse messages
  //
  if(Message >= WM_MOUSEFIRST && Message <= WM_MOUSELAST)
  {
    InputId Id;
    InputValueData Value;

    switch(Message)
    {
      case WM_LBUTTONUP:
      case WM_LBUTTONDOWN:
      {
        Id = Mouse.LeftButton;
        Value.Type = InputType.Button;
        Value.ButtonIsDown = Message == WM_LBUTTONDOWN;
      } break;

      case WM_RBUTTONUP:
      case WM_RBUTTONDOWN:
      {
        Id = Mouse.RightButton;
        Value.Type = InputType.Button;
        Value.ButtonIsDown = Message == WM_RBUTTONDOWN;
      } break;

      case WM_MBUTTONUP:
      case WM_MBUTTONDOWN:
      {
        Id = Mouse.MiddleButton;
        Value.Type = InputType.Button;
        Value.ButtonIsDown = Message == WM_MBUTTONDOWN;
      } break;

      case WM_XBUTTONUP:
      case WM_XBUTTONDOWN:
      {
        // TODO(Manu): Check which one it is.
        Id = Mouse.ExtraButton1;
        Id = Mouse.ExtraButton2;
        Value.Type = InputType.Button;
        Value.ButtonIsDown = Message == WM_XBUTTONDOWN;
      } break;

      // TODO(Manu): Mouse wheel, etc.

      default: break;
    }

    if(Id)
    {
      InputQueue.Enqueue(Id, Value);
    }

    return Yes.Processed;
  }

  //
  // Raw input messages
  //
  if(Message == WM_INPUT)
  {
    Log.Info("Raw input message: %s", Win32MessageIdToString(Message));

    return Yes.Processed;
  }

  return No.Processed;
}

InputId Win32VirtualKeyToInputId(WPARAM VKCode, LPARAM lParam)
{
  const ScanCode = cast(UINT)((lParam & 0x00ff0000) >> 16);
  const IsExtended = (lParam & 0x01000000) != 0;

  switch(VKCode)
  {
    //
    // Special Key Handling
    //
    case VK_SHIFT:
    {
      VKCode = MapVirtualKey(ScanCode, MAPVK_VSC_TO_VK_EX);
      return Win32VirtualKeyToInputId(VKCode, lParam);
    }

    case VK_CONTROL:
    {
      VKCode = IsExtended ? VK_RCONTROL : VK_LCONTROL;
      return Win32VirtualKeyToInputId(VKCode, lParam);
    }

    case VK_MENU:
    {
      VKCode = IsExtended ? VK_RMENU : VK_LMENU;
      return Win32VirtualKeyToInputId(VKCode, lParam);
    }

    //
    // Common Keys
    //
    case VK_LSHIFT: return Keyboard.LeftShift;
    case VK_RSHIFT: return Keyboard.RightShift;

    case VK_LMENU: return Keyboard.LeftAlt;
    case VK_RMENU: return Keyboard.RightAlt;

    case VK_LCONTROL: return Keyboard.LeftControl;
    case VK_RCONTROL: return Keyboard.RightControl;

    case VK_ESCAPE:   return Keyboard.Escape;
    case VK_SPACE:    return Keyboard.Space;
    case VK_TAB:      return Keyboard.Tab;
    case VK_LWIN:     return Keyboard.LeftSystem;
    case VK_RWIN:     return Keyboard.RightSystem;
    case VK_APPS:     return Keyboard.Application;
    case VK_BACK:     return Keyboard.Backspace;
    case VK_RETURN:   return IsExtended ? Keyboard.Numpad_Enter : Keyboard.Return;

    case VK_INSERT: return Keyboard.Insert;
    case VK_DELETE: return Keyboard.Delete;
    case VK_HOME:   return Keyboard.Home;
    case VK_END:    return Keyboard.End;
    case VK_NEXT:   return Keyboard.PageUp;
    case VK_PRIOR:  return Keyboard.PageDown;

    case VK_UP:    return Keyboard.Up;
    case VK_DOWN:  return Keyboard.Down;
    case VK_LEFT:  return Keyboard.Left;
    case VK_RIGHT: return Keyboard.Right;

    //
    // Digit Keys
    //
    case '0': return Keyboard.Digit_0;
    case '1': return Keyboard.Digit_1;
    case '2': return Keyboard.Digit_2;
    case '3': return Keyboard.Digit_3;
    case '4': return Keyboard.Digit_4;
    case '5': return Keyboard.Digit_5;
    case '6': return Keyboard.Digit_6;
    case '7': return Keyboard.Digit_7;
    case '8': return Keyboard.Digit_8;
    case '9': return Keyboard.Digit_9;

    //
    // Numpad
    //
    case VK_MULTIPLY: return Keyboard.Numpad_Multiply;
    case VK_ADD:      return Keyboard.Numpad_Add;
    case VK_SUBTRACT: return Keyboard.Numpad_Subtract;
    case VK_DECIMAL:  return Keyboard.Numpad_Decimal;
    case VK_DIVIDE:   return Keyboard.Numpad_Divide;

    case VK_NUMPAD0: return Keyboard.Numpad_0;
    case VK_NUMPAD1: return Keyboard.Numpad_1;
    case VK_NUMPAD2: return Keyboard.Numpad_2;
    case VK_NUMPAD3: return Keyboard.Numpad_3;
    case VK_NUMPAD4: return Keyboard.Numpad_4;
    case VK_NUMPAD5: return Keyboard.Numpad_5;
    case VK_NUMPAD6: return Keyboard.Numpad_6;
    case VK_NUMPAD7: return Keyboard.Numpad_7;
    case VK_NUMPAD8: return Keyboard.Numpad_8;
    case VK_NUMPAD9: return Keyboard.Numpad_9;

    //
    // F-Keys
    //
    case VK_F1:  return Keyboard.F1;
    case VK_F2:  return Keyboard.F2;
    case VK_F3:  return Keyboard.F3;
    case VK_F4:  return Keyboard.F4;
    case VK_F5:  return Keyboard.F5;
    case VK_F6:  return Keyboard.F6;
    case VK_F7:  return Keyboard.F7;
    case VK_F8:  return Keyboard.F8;
    case VK_F9:  return Keyboard.F9;
    case VK_F10: return Keyboard.F10;
    case VK_F11: return Keyboard.F11;
    case VK_F12: return Keyboard.F12;
    case VK_F13: return Keyboard.F13;
    case VK_F14: return Keyboard.F14;
    case VK_F15: return Keyboard.F15;
    case VK_F16: return Keyboard.F16;
    case VK_F17: return Keyboard.F17;
    case VK_F18: return Keyboard.F18;
    case VK_F19: return Keyboard.F19;
    case VK_F20: return Keyboard.F20;
    case VK_F21: return Keyboard.F21;
    case VK_F22: return Keyboard.F22;
    case VK_F23: return Keyboard.F23;
    case VK_F24: return Keyboard.F24;

    //
    // Keys
    //
    case 'A': return Keyboard.A;
    case 'B': return Keyboard.B;
    case 'C': return Keyboard.C;
    case 'D': return Keyboard.D;
    case 'E': return Keyboard.E;
    case 'F': return Keyboard.F;
    case 'G': return Keyboard.G;
    case 'H': return Keyboard.H;
    case 'I': return Keyboard.I;
    case 'J': return Keyboard.J;
    case 'K': return Keyboard.K;
    case 'L': return Keyboard.L;
    case 'M': return Keyboard.M;
    case 'N': return Keyboard.N;
    case 'O': return Keyboard.O;
    case 'P': return Keyboard.P;
    case 'Q': return Keyboard.Q;
    case 'R': return Keyboard.R;
    case 'S': return Keyboard.S;
    case 'T': return Keyboard.T;
    case 'U': return Keyboard.U;
    case 'V': return Keyboard.V;
    case 'W': return Keyboard.W;
    case 'X': return Keyboard.X;
    case 'Y': return Keyboard.Y;
    case 'Z': return Keyboard.Z;

    //
    // Mouse Buttons
    //
    case VK_LBUTTON:  return Mouse.LeftButton;
    case VK_MBUTTON:  return Mouse.MiddleButton;
    case VK_RBUTTON:  return Mouse.RightButton;
    case VK_XBUTTON1: return Mouse.ExtraButton1;
    case VK_XBUTTON2: return Mouse.ExtraButton2;

    default: return null;
  }
}
