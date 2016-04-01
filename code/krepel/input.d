module krepel.input;

import krepel.math.vector2;

alias InputId = string;

struct InputButtonState
{
  bool IsDown;
}

struct InputPair_IdButton
{
  InputId Id;
  InputButtonState Button;
}

struct InputAxisState
{
  float Value;
}

struct InputPair_IdAxis
{
  InputId Id;
  InputAxisState Axis;
}

static struct MouseButtonState
{
  InputPair_IdButton[6] Values =
  [
    InputPair_IdButton(Mouse_Button_Unknown.Id, InputButtonState()),
    InputPair_IdButton(Mouse_Button_Left.Id,    InputButtonState()),
    InputPair_IdButton(Mouse_Button_Middle.Id,  InputButtonState()),
    InputPair_IdButton(Mouse_Button_Right.Id,   InputButtonState()),
    InputPair_IdButton(Mouse_Button_X1.Id,      InputButtonState()),
    InputPair_IdButton(Mouse_Button_X2.Id,      InputButtonState()),
  ];

  inout(InputButtonState)* opIndex(in InputId Id) inout
  {
    foreach(ref Pair; Values)
    {
      if(Pair.Id == Id) return &Pair.Button;
    }

    return null;
  }

  auto opDispatch(string Name)() inout
  {
    enum Code = "this[Mouse_Button" ~ Name ~ ".Id]";
    static assert(__traits(compiles, mixin(Code)), "Does not compile: " ~ Code);
    return mixin(Code);
  }
}

static struct MouseAxisState
{
  InputPair_IdAxis[2] Values =
  [
    InputPair_IdAxis(Mouse_Axis_X.Id),
    InputPair_IdAxis(Mouse_Axis_Y.Id),
  ];

  inout(InputAxisState)* opIndex(in InputId Id) inout
  {
    foreach(ref Pair; Values)
    {
      if(Pair.Id == Id) return &Pair.Axis;
    }

    return null;
  }

  auto opDispatch(string Name)() inout
  {
    enum Code = "this[Mouse_Axis" ~ Name ~ ".Id]";
    static assert(__traits(compiles, mixin(Code)), "Does not compile: " ~ Code);
    return mixin(Code);
  }
}

/// The state of a mouse in a given frame.
struct MouseState
{
  MouseButtonState Buttons;
  MouseAxisState Axes;
}

struct KeyboardState
{
  InputPair_IdButton[] Values =
  [
    InputPair_IdButton(Keyboard_Unknown.Id),
    InputPair_IdButton(Keyboard_Escape.Id),
    InputPair_IdButton(Keyboard_Space.Id),
    InputPair_IdButton(Keyboard_KeyW.Id),
    InputPair_IdButton(Keyboard_KeyA.Id),
    InputPair_IdButton(Keyboard_KeyS.Id),
    InputPair_IdButton(Keyboard_KeyD.Id),
  ];

  inout(InputButtonState)* opIndex(in InputId Id) inout
  {
    foreach(ref Pair; Values)
    {
      if(Pair.Id == Id) return &Pair.Button;
    }

    return null;
  }

  auto opDispatch(string Name)() inout
  {
    enum Code = "this[Keyboard_" ~ Name ~ ".Id]";
    static if(!__traits(compiles, mixin(Code)))
    {
      pragma(msg, "Does not compile: " ~ Code);
    }
    return mixin(Code);
  }
}

struct InputState
{
  MouseState Mouse;
  KeyboardState Keyboard;
}

enum InputModifier : uint
{
  LControl = 0b00000001,
  RControl = 0b00000010,
  LShift   = 0b00000100,
  RShift   = 0b00001000,
  LAlt     = 0b00010000,
  RAlt     = 0b00100000,
  LSuper   = 0b01000000,
  RSuper   = 0b10000000,

  Control = LControl | RControl,
  Shift   = LShift   | RShift,
  Alt     = LAlt     | RAlt,
  Super   = LSuper   | RSuper,
}

struct InputProperties
{
  InputId Id;
  bool IsAnalog;
}

immutable
{
  //
  // Mouse Buttons
  //
  InputProperties Mouse_Button_Unknown = { Id : "mouse_button_unknown" };

  InputProperties Mouse_Button_Left    = { Id : "mouse_button_left" };
  InputProperties Mouse_Button_Middle  = { Id : "mouse_button_middle" };
  InputProperties Mouse_Button_Right   = { Id : "mouse_button_right" };
  InputProperties Mouse_Button_X1      = { Id : "mouse_button_x1" };
  InputProperties Mouse_Button_X2      = { Id : "mouse_button_x2" };

  //
  // Mouse Axes
  //
  InputProperties Mouse_Axis_X     = { Id : "mouse_axis_x", IsAnalog : true };
  InputProperties Mouse_Axis_Y     = { Id : "mouse_axis_y", IsAnalog : true };

  //
  // Keyboard
  //
  // TODO(Manu): Keyboard definitions.
  InputProperties Keyboard_Unknown = { Id : "keyboard_unknown" };

  InputProperties Keyboard_Escape  = { Id : "keyboard_escape" };
  InputProperties Keyboard_Space   = { Id : "keyboard_space" };
  InputProperties Keyboard_KeyW    = { Id : "keyboard_key_w" };
  InputProperties Keyboard_KeyA    = { Id : "keyboard_key_a" };
  InputProperties Keyboard_KeyS    = { Id : "keyboard_key_s" };
  InputProperties Keyboard_KeyD    = { Id : "keyboard_key_d" };

  //
  // XInput Gamepad Buttons
  //
  // TODO(Manu): XInput Gamepad Button definitions.

  //
  // XInput Gamepad Axes
  //
  // TODO(Manu): XInput Gamepad Axis definitions.
}
