module krepel.input.keyboard;

import krepel.input.input;

enum Keyboard
{
  Unknown = "Keyboard_Unknown",

  Escape       = "Keyboard_Escape",
  Space        = "Keyboard_Space",
  Tab          = "Keyboard_Tab",
  LeftShift    = "Keyboard_LeftShift",
  LeftControl  = "Keyboard_LeftControl",
  LeftAlt      = "Keyboard_LeftAlt",
  LeftSystem   = "Keyboard_LeftSystem",
  RightShift   = "Keyboard_RightShift",
  RightControl = "Keyboard_RightControl",
  RightAlt     = "Keyboard_RightAlt",
  RightSystem  = "Keyboard_RightSystem",
  Application  = "Keyboard_Application",
  Backspace    = "Keyboard_Backspace",
  Return       = "Keyboard_Return",

  Insert   = "Keyboard_Insert",
  Delete   = "Keyboard_Delete",
  Home     = "Keyboard_Home",
  End      = "Keyboard_End",
  PageUp   = "Keyboard_PageUp",
  PageDown = "Keyboard_PageDown",

  Up    = "Keyboard_Up",
  Down  = "Keyboard_Down",
  Left  = "Keyboard_Left",
  Right = "Keyboard_Right",

  //
  // Digit Keys
  //
  Digit_0  = "Keyboard_Digit_0",
  Digit_1  = "Keyboard_Digit_1",
  Digit_2  = "Keyboard_Digit_2",
  Digit_3  = "Keyboard_Digit_3",
  Digit_4  = "Keyboard_Digit_4",
  Digit_5  = "Keyboard_Digit_5",
  Digit_6  = "Keyboard_Digit_6",
  Digit_7  = "Keyboard_Digit_7",
  Digit_8  = "Keyboard_Digit_8",
  Digit_9  = "Keyboard_Digit_9",

  //
  // Numpad
  //
  Numpad_Add      = "Keyboard_Numpad_Add",
  Numpad_Subtract = "Keyboard_Numpad_Subtract",
  Numpad_Multiply = "Keyboard_Numpad_Multiply",
  Numpad_Divide   = "Keyboard_Numpad_Divide",
  Numpad_Decimal  = "Keyboard_Numpad_Decimal",
  Numpad_Enter    = "Keyboard_Numpad_Enter",

  Numpad_0 = "Keyboard_Numpad_0",
  Numpad_1 = "Keyboard_Numpad_1",
  Numpad_2 = "Keyboard_Numpad_2",
  Numpad_3 = "Keyboard_Numpad_3",
  Numpad_4 = "Keyboard_Numpad_4",
  Numpad_5 = "Keyboard_Numpad_5",
  Numpad_6 = "Keyboard_Numpad_6",
  Numpad_7 = "Keyboard_Numpad_7",
  Numpad_8 = "Keyboard_Numpad_8",
  Numpad_9 = "Keyboard_Numpad_9",

  //
  // F-Keys
  //
  F1  = "Keyboard_F1",
  F2  = "Keyboard_F2",
  F3  = "Keyboard_F3",
  F4  = "Keyboard_F4",
  F5  = "Keyboard_F5",
  F6  = "Keyboard_F6",
  F7  = "Keyboard_F7",
  F8  = "Keyboard_F8",
  F9  = "Keyboard_F9",
  F10 = "Keyboard_F10",
  F11 = "Keyboard_F11",
  F12 = "Keyboard_F12",
  F13 = "Keyboard_F13",
  F14 = "Keyboard_F14",
  F15 = "Keyboard_F15",
  F16 = "Keyboard_F16",
  F17 = "Keyboard_F17",
  F18 = "Keyboard_F18",
  F19 = "Keyboard_F19",
  F20 = "Keyboard_F20",
  F21 = "Keyboard_F21",
  F22 = "Keyboard_F22",
  F23 = "Keyboard_F23",
  F24 = "Keyboard_F24",

  //
  // Keys
  //
  A = "Keyboard_A",
  B = "Keyboard_B",
  C = "Keyboard_C",
  D = "Keyboard_D",
  E = "Keyboard_E",
  F = "Keyboard_F",
  G = "Keyboard_G",
  H = "Keyboard_H",
  I = "Keyboard_I",
  J = "Keyboard_J",
  K = "Keyboard_K",
  L = "Keyboard_L",
  M = "Keyboard_M",
  N = "Keyboard_N",
  O = "Keyboard_O",
  P = "Keyboard_P",
  Q = "Keyboard_Q",
  R = "Keyboard_R",
  S = "Keyboard_S",
  T = "Keyboard_T",
  U = "Keyboard_U",
  V = "Keyboard_V",
  W = "Keyboard_W",
  X = "Keyboard_X",
  Y = "Keyboard_Y",
  Z = "Keyboard_Z",
}

void RegisterAllKeyboardSlots(InputContext Context)
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
