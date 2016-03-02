module krepel.log;

import krepel;
import krepel.algorithm : Min;
import Meta = krepel.meta;

import krepel.container;

// TODO(Manu): Remove this. Logging should be independent.
import core.sys.windows.windows;

/// The global default log.
LogState Log;

struct LogState
{
  Array!char Buffer;
  Array!LogSink Sinks;

  void ClearBuffer()
  {
    Buffer.Clear();
  }

  void put(in char[] Chars)
  {
    Buffer.PushBack(Chars);
  }
}

enum LogLevel
{
  Info,
  Warning,
  Error,
}

alias LogSink = void delegate(LogLevel, char[]);

template LogMessageDispatch(LogLevel Level)
{
  void LogMessageDispatch(LogType, Char, ArgTypes...)(ref LogType Log, in Char[] Message, auto ref ArgTypes Args)
    if(Meta.IsSomeChar!Char)
  {
    FormattedWrite(&Log, Message, Args);

    scope(exit) Log.ClearBuffer();

    auto Buffer = Log.Buffer[];
    foreach(ref Sink ; Log.Sinks[])
    {
      Sink(Level, Buffer);
    }
  }
}

alias Info    = LogMessageDispatch!(LogLevel.Info);
alias Warning = LogMessageDispatch!(LogLevel.Warning);
alias Error   = LogMessageDispatch!(LogLevel.Error);


void StdoutLogSink(LogLevel Level, char[] Message)
{
  final switch(Level)
  {
    case LogLevel.Info:    io.write("Info: ");    break;
    case LogLevel.Warning: io.write("Warning: "); break;
    case LogLevel.Error:   io.write("Error: ");   break;
  }

  io.writeln(Message);
}

unittest
{
  char[1024] LogBuffer;
  struct MyLog
  {
    char[] EntireBuffer;
    char[] Buffer;
    LogSink[] Sinks;

    void ClearBuffer()
    {
      Buffer = EntireBuffer;
    }

    void put(in char[] Chars)
    {
      Buffer[0 .. Chars.length] = Chars[];
      Buffer = Buffer[Chars.length .. $];
    }
  }

  auto Log = MyLog(LogBuffer, LogBuffer);
  auto Message = "Hello";
  Log.Info(Message);
  assert(LogBuffer[0 .. Message.length] == Message);
}
