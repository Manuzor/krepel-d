module krepel.input.input;

import krepel;
import krepel.math;
import krepel.container;
import krepel.string;
import krepel.event;

alias InputId = string;

enum InputType
{
  INVALID,

  /// Only valid for a single frame.
  Action,

  /// Has a persistent on/off state.
  Button,

  /// Has a persistent floating point state.
  Axis,
}

struct InputSlotData
{
  /// The type of this slot.
  InputType Type;

  /// The value of the slot.
  ///
  /// Interpretation depends on the $(D Type) of this slot.
  /// Note(Manu): Consider using the property functions below as they do type
  /// checking for you and express the purpose more clearly.
  float Value = 0.0f;

  /// The frame in which this value was updated.
  ulong Frame;

  @property
  {
    bool ButtonIsUp() const { return !this.ButtonIsDown; }
    void ButtonIsUp(bool Value) { this.ButtonIsDown = !Value; }

    bool ButtonIsDown() const
    {
      assert(this.Type == InputType.Button);
      return cast(bool)this.Value;
    }

    void ButtonIsDown(bool Value)
    {
      assert(this.Type == InputType.Button);
      this.Value = Value ? 1.0f : 0.0f;
    }

    float AxisValue() const
    {
      assert(this.Type == InputType.Axis);
      return this.Value;
    }

    void AxisValue(float NewValue)
    {
      assert(this.Type == InputType.Axis);
      this.Value = NewValue;
    }

    float ActionValue() const
    {
      assert(this.Type == InputType.Action);
      return this.Value;
    }

    void ActionValue(float NewValue)
    {
      assert(this.Type == InputType.Action);
      this.Value = NewValue;
    }
  }
}

struct InputAxisProperties
{
  float DeadZone = 0.0f;
  float Sensitivity = 1.0f;
  float Exponent = 1.0f;
}

//                         SlotId,      SlotData
alias InputEvent = Event!(InputId, InputSlotData);

// TODO(Manu): Implement ActionEvent so that user's can listen to a specific action.
class InputContext
{
  static struct TriggerPair
  {
    InputId SlotId;    // This is the slot that is triggered by TriggerId.
    InputId TriggerId; // This is the slot that will trigger SlotId.
  }

  InputContext Parent;
  string Name; // Mostly for debugging.

  Dictionary!(InputId, InputSlotData) Slots;
  Dictionary!(InputId, InputAxisProperties) AxisProperties;
  Array!TriggerPair Triggers;
  InputEvent ChangeEvent;

  ulong CurrentFrame;

  Array!dchar CharacterBuffer;


  this(IAllocator Allocator)
  {
    this.Allocator = Allocator;
  }

  @property void Allocator(IAllocator NewAllocator)
  {
    this.Slots.Allocator = NewAllocator;
    this.AxisProperties.Allocator = NewAllocator;
    this.Triggers.Allocator = NewAllocator;
    this.ChangeEvent.Allocator = NewAllocator;
    this.CharacterBuffer.Allocator = NewAllocator;
  }

  InputSlotData* opIndex(InputId SlotId)
  {
    auto Slot = this.Slots.Get(SlotId);
    if(Slot) return Slot;
    if(Parent) return Parent[SlotId];
    return null;
  }

  void RegisterInputSlot(InputType Type, InputId SlotId)
  {
    auto Slot = this.Slots.GetOrCreate(SlotId);
    assert(Slot);

    Slot.Type = Type;

    if(Type == InputType.Axis)
    {
      this.AxisProperties.GetOrCreate(SlotId);
    }
  }

  bool AddTrigger(InputId SlotId, InputId TriggerId)
  {
    // TODO(Manu): Eliminate duplicates.
    this.Triggers ~= TriggerPair(SlotId, TriggerId);
    return true;
  }

  bool RemoveTrigger(InputId SlotId, InputId TriggerId)
  {
    // TODO(Manu): Implement this.
    return false;
  }

  /// Return: Will return $(D false) if the slot does not exist.
  bool UpdateSlotValue(InputId TriggeringSlotId, float NewValue)
  {
    auto TriggeringSlot = Slots.Get(TriggeringSlotId);
    if(TriggeringSlot is null) return false;

    TriggeringSlot.Frame = this.CurrentFrame;
    TriggeringSlot.Value = AttuneInputValue(TriggeringSlotId, NewValue);

    foreach(Trigger; this.Triggers)
    {
      if(Trigger.TriggerId == TriggeringSlotId)
      {
        auto Slot = this.Slots.Get(Trigger.SlotId);
        if(Slot)
        {
          Slot.Frame = this.CurrentFrame;
          Slot.Value = AttuneInputValue(Trigger.SlotId, NewValue);
        }
      }
    }

    return true;
  }

  /// Applies special settings for the given input slot, if there are any, and
  /// returns an adjusted value.
  float AttuneInputValue(InputId SlotId, float RawValue)
  {
    auto AxisProps = this.AxisProperties.Get(SlotId);
    if(AxisProps)
    {
      // TODO(Manu): Implement this.
    }

    return RawValue;
  }

  void BeginInputFrame()
  {
    foreach(Id, ref Slot; this.Slots)
    {
      if(Slot.Frame < this.CurrentFrame)
        continue;

      this.ChangeEvent(Id, Slot);
    }
  }

  void EndInputFrame()
  {
    // This will never happen...
    assert(this.CurrentFrame < typeof(this.CurrentFrame).max);
    this.CurrentFrame++;

    this.CharacterBuffer.Clear();
  }
}
