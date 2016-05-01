module krepel.input;

public import krepel.input.input;
public import krepel.input.system_input_slots;

version(Windows)
{
  public import krepel.input.win32_input;
}
