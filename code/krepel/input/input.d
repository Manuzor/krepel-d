module krepel.input.input;

import krepel;
import krepel.container;
import krepel.string;

alias InputId = string;

enum InputType
{
  Button,
  Axis,
}

struct InputButton
{
  bool IsDown;
}

struct InputAxis
{
  float Value;
}

struct InputSource
{
  InputId Id;
  InputType Type;
  union
  {
    InputButton _Button;
    InputAxis _Axis;
  }

  this(InputId Id, InputButton Button)
  {
    this.Id = Id;
    this.Type = InputType.Button;
    this._Button = Button;
  }

  this(InputId Id, InputAxis Axis)
  {
    this.Id = Id;
    this.Type = InputType.Axis;
    this._Axis = Axis;
  }

  @property ref auto Button() inout
  {
    assert(Type == InputType.Button);
    return _Button;
  }

  @property ref auto Axis() inout
  {
    assert(Type == InputType.Axis);
    return _Axis;
  }
}

struct InputQueue
{
  Array!InputSource Data;

  this(IAllocator Allocator)
  {
    Data.Allocator = Allocator;
  }

  alias Data this;
}

// TODO(Manu): Input context that handles the action mapping.
