module krepel.input;

public import krepel.input.input;
public import krepel.input.keyboard;
public import krepel.input.mouse;

version(Windows)
{
  public import krepel.input.xinput; // Note(Manu): Is there XInput on Posix?!
  public import krepel.input.win32_vkmap;
}
