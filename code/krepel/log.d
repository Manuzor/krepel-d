module krepel.log;

import krepel;
import krepel.algorithm : Min;
import Meta = krepel.meta;

// TODO(Manu): Remove this. Logging should be independent.
import core.sys.windows.windows;

nothrow:
@nogc:

void Info(T, ArgTypes...)(T[] Message, ArgTypes Args)
  if(Meta.IsSomeChar!T)
{
  // TODO(Manu): Use Args!

  char[1024] Buffer = void;

  while(Message.length)
  {
    auto Amount = Min(Buffer.length - 1, Message.length);

    Buffer[Amount] = '\0';
    // Copy over the data.
    Buffer[0 .. Amount] = Message[0 .. Amount];

    OutputDebugStringA(cast(const(char)*)Buffer.ptr);

    Message = Message[Amount .. $];
  }

  OutputDebugStringA("\n");
}
