module krepel.input.input;

import krepel;
import krepel.math;
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
  InputType Type;
  InputId Id;
  union
  {
    InputButton _Button;
    InputAxis _Axis;
  }

  this(InputType Type, InputId Id)
  {
    this.Type = Type;
    this.Id = Id;
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

alias InputQueueData = Array!InputSource;

class InputContext
{
  // Maps Trigger-source => Target, e.g. Keyboard_Escape => Quit
  Dictionary!(InputId, InputSource) InputMap;
  InputContext Parent;

  this(IAllocator Allocator)
  {
    InputMap.Allocator = Allocator;
  }

  auto opIndex(InputId Id)
  {
    foreach(ref Input; InputMap.Values)
    {
      if(Input.Id == Id)
      {
        return &Input;
      }
    }

    if(Parent)
    {
      return Parent[Id];
    }

    return null;
  }

  void RegisterInput(ArgTypes...)(InputSource Input, ArgTypes TriggerIds)
    if(ArgTypes.length && is(ArgTypes[0] : InputId))
  {
    foreach(TriggerId; TriggerIds)
    {
      // TODO(Manu): We are potentially overwriting existing input slots. Is that ok?
      InputMap[TriggerId] = Input;
    }
  }

  bool MapInput(ref InputSource Source)
  {
    auto Target = InputMap.Get(Source.Id);
    if(Target is null) return false;
    final switch(Target.Type)
    {
      case InputType.Button:
      {
        final switch(Source.Type)
        {
          case InputType.Button:
          {
            Target.Button = Source.Button;
          } break;
          case InputType.Axis:
          {
            Target.Button.IsDown = !Source.Axis.Value.NearlyEquals(0);
          } break;
        }
      } break;
      case InputType.Axis:
      {
        final switch(Source.Type)
        {
          case InputType.Button:
          {
            Target.Axis.Value = Source.Button.IsDown ? 1.0f : 0.0f;
          } break;
          case InputType.Axis:
          {
            Target.Axis = Source.Axis;
          } break;
        }
      } break;
    }
    return true;
  }
}
