module krepel.input.mouse;

import krepel.input.input;

enum Mouse
{
  Unknown = "Mouse_Unknown",

  //
  // Buttons
  //
  LeftButton              = "Mouse_LeftButton",
  MiddleButton            = "Mouse_MiddleButton",
  RightButton             = "Mouse_RightButton",
  ExtraButton1            = "Mouse_ExtraButton1",
  ExtraButton2            = "Mouse_ExtraButton2",

  //
  // Axes
  //
  XPosition = "Mouse_XPosition",
  YPosition = "Mouse_YPosition",

  //
  // Actions
  //
  XDelta                   = "Mouse_XDelta",
  YDelta                   = "Mouse_YDelta",
  VerticalWheelDelta       = "Mouse_VerticalWheelDelta",
  HorizontalWheelDelta     = "Mouse_HorizontalWheelDelta",
  LeftButton_DoubleClick   = "Mouse_LeftButton_DoubleClick",
  MiddleButton_DoubleClick = "Mouse_MiddleButton_DoubleClick",
  RightButton_DoubleClick  = "Mouse_RightButton_DoubleClick",
  ExtraButton1_DoubleClick = "Mouse_ExtraButton1_DoubleClick",
  ExtraButton2_DoubleClick = "Mouse_ExtraButton2_DoubleClick",
}

void RegisterAllMouseSlots(InputContext Context)
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
}
