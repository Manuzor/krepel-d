module krepel.log;

import krepel;
import Meta = krepel.meta;

// TODO(Manu): Remove this. Logging should be independent.
import core.sys.windows.windows;

nothrow:
@nogc:

void Info(T, ArgTypes...)(Span!T Message, ArgTypes Args)
  if(Meta.IsSomeChar!T)
{
  char[1024] Buffer_ = void;
  Span!char Buffer = MakeSpan(Buffer_);

  while(Message.Count)
  {
    auto Amount = Min(Buffer.Count - 1, Message.Count);

    Buffer[Amount] = '\0';
    // Copy over the data.
    Buffer[0..Amount].Assign = Message[0 .. Amount];
    
    OutputDebugStringA(cast(const(char)*)Buffer.Data);

    Message = Message[Amount .. $];
  }

  OutputDebugStringA("\n");
}
