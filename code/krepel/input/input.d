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

  Action, // Has no data attached to and is a one-time thing.
  Button, // Has a persistent state on/off state.
  Axis,   // Has a floating point value state.
}

struct InputValueData
{
  InputType Type;
  float Value = 0.0f; // You should not use this value directly. Use the properties below.

  @property
  {
    bool ButtonIsDown()
    {
      assert(this.Type == InputType.Button);
      return cast(bool)this.Value;
    }

    void ButtonIsDown(bool Value)
    {
      assert(this.Type == InputType.Button);
      this.Value = Value ? 1.0f : 0.0f;
    }

    float AxisValue()
    {
      assert(this.Type == InputType.Axis);
      return this.Value;
    }

    void AxisValue(float NewValue)
    {
      assert(this.Type == InputType.Axis);
      this.Value = NewValue;
    }
  }
}

struct InputQueueData
{
  static struct QueueItem
  {
    InputId Id;
    InputValueData Value;
  }

  Array!QueueItem Items;


  this(IAllocator Allocator)
  {
    this.Allocator = Allocator;
  }

  @property void Allocator(IAllocator NewAllocator)
  {
    this.Items.Allocator = NewAllocator;
  }

  void Clear()
  {
    this.Items.Clear();
  }

  void Enqueue(InputId Id, InputValueData Value)
  {
    this.Items ~= QueueItem(Id, Value);
  }

  int opApply(int delegate(InputId, InputValueData) Loop)
  {
    int Result;

    foreach(ref Item; Items[])
    {
      Result = Loop(Item.Id, Item.Value);
      if(Result) break;
    }

    return Result;
  }
}

//                               SlotId,       OldValue,       NewValue
alias InputActionEvent = Event!(InputId, InputValueData, InputValueData);

// TODO(Manu): Implement ChangeEvent
class InputContext
{
  static struct TriggerPair
  {
    InputId SlotId;    // This is the slot that is triggered by TriggerId.
    InputId TriggerId; // This is the slot that will trigger SlotId.
  }

  InputContext Parent;
  string Name; // Mostly for debugging.

  Dictionary!(InputId, InputValueData) Slots;
  Array!TriggerPair Triggers;
  InputActionEvent ChangeEvent;


  this(IAllocator Allocator)
  {
    this.Allocator = Allocator;
  }

  @property void Allocator(IAllocator NewAllocator)
  {
    this.Slots.Allocator = NewAllocator;
    this.Triggers.Allocator = NewAllocator;
    this.ChangeEvent.Allocator = NewAllocator;
  }

  InputValueData* opIndex(InputId SlotId)
  {
    auto Slot = this.Slots.Get(SlotId);
    if(Slot) return Slot;
    if(Parent) return Parent[SlotId];
    return null;
  }

  void RegisterInputSlot(InputId SlotId, InputType Type)
  {
    auto Slot = this.Slots.GetOrCreate(SlotId);
    assert(Slot);

    Slot.Type = Type;
  }

  void RegisterButton(InputId NewButtonId)
  {
    RegisterInputSlot(NewButtonId, InputType.Button);
  }

  void RegisterAxis(InputId NewAxisId)
  {
    RegisterInputSlot(NewAxisId, InputType.Axis);
  }

  void RegisterAction(InputId NewActionId)
  {
    RegisterInputSlot(NewActionId, InputType.Action);
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

  bool MapInput(InputId TriggeringSlotId, InputValueData NewValue)
  {
    auto TriggeringSlot = Slots.Get(TriggeringSlotId);
    if(TriggeringSlot is null) return false;

    UpdateSlotValue(TriggeringSlotId, TriggeringSlot, NewValue);

    foreach(Trigger; this.Triggers)
    {
      if(Trigger.TriggerId == TriggeringSlotId)
      {
        auto Slot = this.Slots.Get(Trigger.SlotId);
        if(Slot)
        {
          UpdateSlotValue(Trigger.SlotId, Slot, NewValue);
        }
      }
    }

    return true;
  }

  bool AddListener(InputId SlotId, InputActionEvent.ListenerType Listener)
  {
    this.ChangeEvent.Add(Listener);
    // TODO(Manu): Avoid duplicates?
    return true;
  }

  bool RemoveListener(InputId SlotId, InputActionEvent.ListenerType Listener)
  {
    return this.ChangeEvent.Remove(Listener);
  }

  void UpdateSlotValue(InputId SlotId, InputValueData* Slot, InputValueData NewValue)
  {
    auto OldValue = *Slot;

    // Note(Manu): The actual type of the input doesn't matter. We just map
    // the float values. I just hope that's fine...
    Slot.Value = NewValue.Value;

    this.ChangeEvent(SlotId, OldValue, NewValue);
  }
}
