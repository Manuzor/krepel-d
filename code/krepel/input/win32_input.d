module krepel.input.win32_input;

import krepel;
import krepel.win32;
import krepel.win32.directx.xinput;

import krepel.input.input;
import krepel.input.system_input_slots;


class Win32InputContext : InputContext
{
  XINPUT_STATE[XUSER_MAX_COUNT] XInputPreviousState;

  this(IAllocator Allocator)
  {
    super(Allocator);
  }
}

Flag!"Processed" Win32ProcessInputMessage(HWND WindowHandle, UINT Message, WPARAM WParam, LPARAM LParam,
                                          Win32InputContext Input,
                                          LogData* Log = null)
{
  //
  // Keyboard messages
  //
  if(Message == WM_CHAR || Message == WM_UNICHAR)
  {
    if(WParam == UNICODE_NOCHAR) return Yes.Processed;
    Input.CharacterBuffer ~= cast(dchar)WParam;
    return Yes.Processed;
  }
  else if(Message >= WM_KEYFIRST && Message <= WM_KEYLAST)
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

    Input.UpdateSlotValue(KeyId, IsDown);

    return Yes.Processed;
  }

  //
  // Mouse messages
  //
  if(Message >= WM_MOUSEFIRST && Message <= WM_MOUSELAST)
  {
    //
    // Mouse position
    //
    if(Message == WM_MOUSEMOVE)
    {
      auto XClientAreaMouse = GET_X_LPARAM(LParam);
      Input.UpdateSlotValue(Mouse.XPosition, cast(float)XClientAreaMouse);

      auto YClientAreaMouse = GET_Y_LPARAM(LParam);
      Input.UpdateSlotValue(Mouse.YPosition, cast(float)YClientAreaMouse);

      return Yes.Processed;
    }

    //
    // Mouse buttons and wheels
    //
    switch(Message)
    {
      case WM_LBUTTONUP:
      case WM_LBUTTONDOWN:
      {
        bool IsDown = Message == WM_LBUTTONDOWN;
        Input.UpdateSlotValue(Mouse.LeftButton, IsDown);
      } break;

      case WM_RBUTTONUP:
      case WM_RBUTTONDOWN:
      {
        bool IsDown = Message == WM_RBUTTONDOWN;
        Input.UpdateSlotValue(Mouse.RightButton, IsDown);
      } break;

      case WM_MBUTTONUP:
      case WM_MBUTTONDOWN:
      {
        bool IsDown = Message == WM_MBUTTONDOWN;
        Input.UpdateSlotValue(Mouse.MiddleButton, IsDown);
      } break;

      case WM_XBUTTONUP:
      case WM_XBUTTONDOWN:
      {
        bool IsDown = Message == WM_XBUTTONDOWN;
        auto XButtonNumber = GET_XBUTTON_WPARAM(WParam);
        switch(XButtonNumber)
        {
          case 1: Input.UpdateSlotValue(Mouse.ExtraButton1, IsDown); break;
          case 2: Input.UpdateSlotValue(Mouse.ExtraButton2, IsDown); break;
          default: break;
        }
      } break;

      case WM_MOUSEWHEEL:
      {
        auto RawValue = GET_WHEEL_DELTA_WPARAM(WParam);
        auto Value = cast(float)RawValue / WHEEL_DELTA;
        Input.UpdateSlotValue(Mouse.VerticalWheelDelta, Value);
      } break;

      case WM_MOUSEHWHEEL:
      {
        auto RawValue = GET_WHEEL_DELTA_WPARAM(WParam);
        auto Value = cast(float)RawValue / WHEEL_DELTA;
        Input.UpdateSlotValue(Mouse.HorizontalWheelDelta, Value);
      } break;

      default: break;
    }

    return Yes.Processed;
  }

  //
  // Raw input messages.
  //
  if(Message == WM_INPUT)
  {
    UINT InputDataSize;
    GetRawInputData(cast(HRAWINPUT)LParam, RID_INPUT, null, &InputDataSize, RAWINPUTHEADER.sizeof);

    // Early out.
    if(InputDataSize == 0) return Yes.Processed;

    assert(InputDataSize <= RAWINPUT.sizeof, "We are querying only for raw mouse input data, for which RAWINPUT.sizeof should be enough.");

    RAWINPUT InputData = void;
    const BytesWritten = GetRawInputData(cast(HRAWINPUT)LParam, RID_INPUT, &InputData, &InputDataSize, RAWINPUTHEADER.sizeof);
    if(BytesWritten != InputDataSize)
    {
      Log.Failure("Failed to get raw input data.");
      Win32LogErrorCode(Log, GetLastError());
      return Yes.Processed;
    }

    // We only care about mouse input (at the moment).
    if(InputData.header.dwType != RIM_TYPEMOUSE)
    {
      return Yes.Processed;
    }

    // Only process relative mouse movement (for now).
    bool IsAbsoluteMouseMovement = InputData.data.mouse.usFlags & MOUSE_MOVE_ABSOLUTE;
    if(IsAbsoluteMouseMovement)
    {
      return Yes.Processed;
    }

    auto XMovement = cast(float)InputData.data.mouse.lLastX;
    Input.UpdateSlotValue(Mouse.XDelta, XMovement);

    auto YMovement = cast(float)InputData.data.mouse.lLastY;
    Input.UpdateSlotValue(Mouse.YDelta, YMovement);

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

void Win32PollXInput(Win32InputContext Input)
{
  if(Input.UserIndex < 0)
  {
    // Need a user index to poll for gamepad state.
    return;
  }

  auto UserIndex = cast(DWORD)Input.UserIndex;

  XINPUT_STATE NewControllerState;
  if(XInputGetState(UserIndex, &NewControllerState) != ERROR_SUCCESS)
  {
    // The gamepad seems to be disconnected.
    return;
  }

  if(Input.XInputPreviousState[UserIndex].dwPacketNumber == NewControllerState.dwPacketNumber)
  {
    // There are no updates for us.
    return;
  }

  scope(success) Input.XInputPreviousState[UserIndex] = NewControllerState;

  auto OldGamepad = &Input.XInputPreviousState[UserIndex].Gamepad;
  auto NewGamepad = &NewControllerState.Gamepad;

  //
  // Buttons
  //
  {
    void UpdateButton(Win32InputContext Input, InputId Id, WORD OldButtons, WORD NewButtons, WORD ButtonMask)
    {
      bool WasDown = cast(bool)(OldButtons & ButtonMask);
      bool IsDown = cast(bool)(NewButtons & ButtonMask);

      if(WasDown != IsDown)
      {
        Input.UpdateSlotValue(Id, IsDown);
      }
    }

    UpdateButton(Input, XInput.DPadUp,      OldGamepad.wButtons, NewGamepad.wButtons, XINPUT_GAMEPAD_DPAD_UP);
    UpdateButton(Input, XInput.DPadDown,    OldGamepad.wButtons, NewGamepad.wButtons, XINPUT_GAMEPAD_DPAD_DOWN);
    UpdateButton(Input, XInput.DPadLeft,    OldGamepad.wButtons, NewGamepad.wButtons, XINPUT_GAMEPAD_DPAD_LEFT);
    UpdateButton(Input, XInput.DPadRight,   OldGamepad.wButtons, NewGamepad.wButtons, XINPUT_GAMEPAD_DPAD_RIGHT);
    UpdateButton(Input, XInput.Start,       OldGamepad.wButtons, NewGamepad.wButtons, XINPUT_GAMEPAD_START);
    UpdateButton(Input, XInput.Back,        OldGamepad.wButtons, NewGamepad.wButtons, XINPUT_GAMEPAD_BACK);
    UpdateButton(Input, XInput.LeftThumb,   OldGamepad.wButtons, NewGamepad.wButtons, XINPUT_GAMEPAD_LEFT_THUMB);
    UpdateButton(Input, XInput.RightThumb,  OldGamepad.wButtons, NewGamepad.wButtons, XINPUT_GAMEPAD_RIGHT_THUMB);
    UpdateButton(Input, XInput.LeftBumper,  OldGamepad.wButtons, NewGamepad.wButtons, XINPUT_GAMEPAD_LEFT_SHOULDER);
    UpdateButton(Input, XInput.RightBumper, OldGamepad.wButtons, NewGamepad.wButtons, XINPUT_GAMEPAD_RIGHT_SHOULDER);
    UpdateButton(Input, XInput.A,           OldGamepad.wButtons, NewGamepad.wButtons, XINPUT_GAMEPAD_A);
    UpdateButton(Input, XInput.B,           OldGamepad.wButtons, NewGamepad.wButtons, XINPUT_GAMEPAD_B);
    UpdateButton(Input, XInput.X,           OldGamepad.wButtons, NewGamepad.wButtons, XINPUT_GAMEPAD_X);
    UpdateButton(Input, XInput.Y,           OldGamepad.wButtons, NewGamepad.wButtons, XINPUT_GAMEPAD_Y);
  }

  //
  // Triggers
  //
  {
    void UpdateTrigger(Win32InputContext Input, InputId Id, BYTE OldValue, BYTE NewValue)
    {
      if(OldValue != NewValue)
      {
        float NormalizedValue = NewValue / 255.0f;
        Input.UpdateSlotValue(Id, NormalizedValue);
      }
    }

    UpdateTrigger(Input, XInput.LeftTrigger, OldGamepad.bLeftTrigger, NewGamepad.bLeftTrigger);
    UpdateTrigger(Input, XInput.RightTrigger, OldGamepad.bRightTrigger, NewGamepad.bRightTrigger);
  }

  //
  // Thumbsticks
  //
  {
    void UpdateThumbStick(Win32InputContext Input, InputId Id, SHORT OldValue, SHORT NewValue)
    {
      if(OldValue != NewValue)
      {
        float NormalizedValue = void;
        if(NewValue > 0) NormalizedValue = NewValue / 32767.0f;
        else             NormalizedValue = NewValue / 32768.0f;
        Input.UpdateSlotValue(Id, NormalizedValue);
      }
    }

    UpdateThumbStick(Input, XInput.XLeftStick, OldGamepad.sThumbLX, NewGamepad.sThumbLX);
    UpdateThumbStick(Input, XInput.YLeftStick, OldGamepad.sThumbLY, NewGamepad.sThumbLY);
    UpdateThumbStick(Input, XInput.XRightStick, OldGamepad.sThumbRX, NewGamepad.sThumbRX);
    UpdateThumbStick(Input, XInput.YRightStick, OldGamepad.sThumbRY, NewGamepad.sThumbRY);
  }
}

void Win32RegisterAllMouseSlots(Win32InputContext Context,
                                LogData* Log = null)
{
  Context.RegisterInputSlot(InputType.Button, Mouse.LeftButton);
  Context.RegisterInputSlot(InputType.Button, Mouse.MiddleButton);
  Context.RegisterInputSlot(InputType.Button, Mouse.RightButton);
  Context.RegisterInputSlot(InputType.Button, Mouse.ExtraButton1);
  Context.RegisterInputSlot(InputType.Button, Mouse.ExtraButton2);

  Context.RegisterInputSlot(InputType.Axis, Mouse.XPosition);
  Context.RegisterInputSlot(InputType.Axis, Mouse.YPosition);

  Context.RegisterInputSlot(InputType.Action, Mouse.XDelta);
  Context.RegisterInputSlot(InputType.Action, Mouse.YDelta);
  Context.RegisterInputSlot(InputType.Action, Mouse.VerticalWheelDelta);
  Context.RegisterInputSlot(InputType.Action, Mouse.HorizontalWheelDelta);
  Context.RegisterInputSlot(InputType.Action, Mouse.LeftButton_DoubleClick);
  Context.RegisterInputSlot(InputType.Action, Mouse.MiddleButton_DoubleClick);
  Context.RegisterInputSlot(InputType.Action, Mouse.RightButton_DoubleClick);
  Context.RegisterInputSlot(InputType.Action, Mouse.ExtraButton1_DoubleClick);
  Context.RegisterInputSlot(InputType.Action, Mouse.ExtraButton2_DoubleClick);

  //
  // Register Mouse Raw Input
  //
  {
    RAWINPUTDEVICE Device;
    with(Device)
    {
      usUsagePage = 0x01;
      usUsage = 0x02;
    }

    if(RegisterRawInputDevices(&Device, 1, RAWINPUTDEVICE.sizeof))
    {
      Log.Info("Initialized raw input for mouse.");
    }
    else
    {
      Log.Failure("Failed to initialize raw input for mouse.");
    }
  }
}

void Win32RegisterAllKeyboardSlots(Win32InputContext Context,
                                   LogData* Log = null)
{
  foreach(MemberName; __traits(allMembers, Keyboard))
  {
    if(MemberName != Keyboard.Unknown)
    {
      enum Code = `Context.RegisterInputSlot(InputType.Button, Keyboard.` ~ MemberName ~ `);`;
      mixin(Code);
    }
  }
}

void Win32RegisterAllXInputSlots(Win32InputContext Context,
                                 LogData* Log = null)
{
  Context.RegisterInputSlot(InputType.Button, XInput.DPadUp);
  Context.RegisterInputSlot(InputType.Button, XInput.DPadDown);
  Context.RegisterInputSlot(InputType.Button, XInput.DPadLeft);
  Context.RegisterInputSlot(InputType.Button, XInput.DPadRight);
  Context.RegisterInputSlot(InputType.Button, XInput.Start);
  Context.RegisterInputSlot(InputType.Button, XInput.Back);
  Context.RegisterInputSlot(InputType.Button, XInput.LeftThumb);
  Context.RegisterInputSlot(InputType.Button, XInput.RightThumb);
  Context.RegisterInputSlot(InputType.Button, XInput.LeftBumper);
  Context.RegisterInputSlot(InputType.Button, XInput.RightBumper);
  Context.RegisterInputSlot(InputType.Button, XInput.A);
  Context.RegisterInputSlot(InputType.Button, XInput.B);
  Context.RegisterInputSlot(InputType.Button, XInput.X);
  Context.RegisterInputSlot(InputType.Button, XInput.Y);

  import krepel.win32.directx.xinput;

  Context.RegisterInputSlot(InputType.Axis, XInput.LeftTrigger);
  with(Context.ValueProperties.GetOrCreate(XInput.LeftTrigger))
  {
    DeadZone = XINPUT_GAMEPAD_TRIGGER_THRESHOLD / 255.0f;
  }

  Context.RegisterInputSlot(InputType.Axis, XInput.RightTrigger);
  with(Context.ValueProperties.GetOrCreate(XInput.RightTrigger))
  {
    DeadZone = XINPUT_GAMEPAD_TRIGGER_THRESHOLD / 255.0f;
  }

  Context.RegisterInputSlot(InputType.Axis, XInput.XLeftStick);
  with(Context.ValueProperties.GetOrCreate(XInput.XLeftStick))
  {
    PositiveDeadZone = XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE / 32767.0f;
    NegativeDeadZone = XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE / 32768.0f;
  }

  Context.RegisterInputSlot(InputType.Axis, XInput.YLeftStick);
  with(Context.ValueProperties.GetOrCreate(XInput.YLeftStick))
  {
    PositiveDeadZone = XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE / 32767.0f;
    NegativeDeadZone = XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE / 32768.0f;
  }

  Context.RegisterInputSlot(InputType.Axis, XInput.XRightStick);
  with(Context.ValueProperties.GetOrCreate(XInput.XRightStick))
  {
    PositiveDeadZone = XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE / 32767.0f;
    NegativeDeadZone = XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE / 32768.0f;
  }

  Context.RegisterInputSlot(InputType.Axis, XInput.YRightStick);
  with(Context.ValueProperties.GetOrCreate(XInput.YRightStick))
  {
    PositiveDeadZone = XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE / 32767.0f;
    NegativeDeadZone = XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE / 32768.0f;
  }
}
