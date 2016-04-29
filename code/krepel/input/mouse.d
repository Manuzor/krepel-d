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
  XPosition  = "Mouse_XPosition",
  YPosition  = "Mouse_YPosition",
  XDelta     = "Mouse_XDelta",
  YDelta     = "Mouse_YDelta",
  WheelDelta = "Mouse_WheelDelta",

  //
  // Actions
  //
  LeftButton_DoubleClick   = "Mouse_LeftButton_DoubleClick",
  MiddleButton_DoubleClick = "Mouse_MiddleButton_DoubleClick",
  RightButton_DoubleClick  = "Mouse_RightButton_DoubleClick",
  ExtraButton1_DoubleClick = "Mouse_ExtraButton1_DoubleClick",
  ExtraButton2_DoubleClick = "Mouse_ExtraButton2_DoubleClick",
}

void RegisterAllMouseSlots(InputContext Context)
{
  Context.RegisterButton(Mouse.LeftButton);
  Context.RegisterButton(Mouse.MiddleButton);
  Context.RegisterButton(Mouse.RightButton);
  Context.RegisterButton(Mouse.ExtraButton1);
  Context.RegisterButton(Mouse.ExtraButton2);

  Context.RegisterAxis(Mouse.XPosition);
  Context.RegisterAxis(Mouse.YPosition);
  Context.RegisterAxis(Mouse.XDelta);
  Context.RegisterAxis(Mouse.YDelta);
  Context.RegisterAxis(Mouse.WheelDelta);

  Context.RegisterAction(Mouse.LeftButton_DoubleClick);
  Context.RegisterAction(Mouse.MiddleButton_DoubleClick);
  Context.RegisterAction(Mouse.RightButton_DoubleClick);
  Context.RegisterAction(Mouse.ExtraButton1_DoubleClick);
  Context.RegisterAction(Mouse.ExtraButton2_DoubleClick);
}
