module krepel.log;

import krepel;
import krepel.algorithm : Min;
import Meta = krepel.meta;

import krepel.container;

/// The global default log.
LogData* Log;

struct LogData
{
  Array!char MessageBuffer;
  Array!LogSink Sinks;

  this(IAllocator Allocator)
  {
    this.Allocator = Allocator;
  }

  @property void Allocator(IAllocator SomeAllocator)
  {
    MessageBuffer.Allocator = SomeAllocator;
    Sinks.Allocator = SomeAllocator;
  }

  void ClearMessageBuffer()
  {
    MessageBuffer.Clear();
  }

  void put(in char[] Chars)
  {
    MessageBuffer ~= Chars;
  }
}

enum LogLevel
{
  Info,
  Warning,
  Failure,
}

alias LogSink = void delegate(LogLevel, char[]);

template LogMessageDispatch(LogLevel Level)
{
  void LogMessageDispatch(Char, ArgTypes...)(LogData* Log, in Char[] Message, auto ref ArgTypes Args)
    if(Meta.IsSomeChar!Char)
  {
    // When null is passed for Log, we don't crash but don't do anything.
    if(Log is null) return;

    FormattedWrite(Log, Message, Args);

    scope(exit) Log.ClearMessageBuffer();

    auto Buffer = Log.MessageBuffer[];
    foreach(ref Sink ; Log.Sinks[])
    {
      Sink(Level, Buffer);
    }
  }
}

alias Info    = LogMessageDispatch!(LogLevel.Info);
alias Warning = LogMessageDispatch!(LogLevel.Warning);
alias Failure = LogMessageDispatch!(LogLevel.Failure);

void StdoutLogSink(LogLevel Level, char[] Message)
{
  static import std.stdio;

  final switch(Level)
  {
    case LogLevel.Info:    std.stdio.write("Info: "); break;
    case LogLevel.Warning: std.stdio.write("Warn: "); break;
    case LogLevel.Failure: std.stdio.write("Fail: "); break;
  }

  std.stdio.writeln(Message);
}

unittest
{
  auto TestAllocator = CreateTestAllocator();
  auto TestLog = LogData(TestAllocator);

  char[256] Buffer;
  void TestLogSink(LogLevel Level, char[] Message)
  {
    final switch(Level)
    {
      case LogLevel.Info:    Buffer[0] = 'I'; break;
      case LogLevel.Warning: Buffer[0] = 'W'; break;
      case LogLevel.Failure: Buffer[0] = 'F'; break;
    }
    Buffer[1 .. Message.length + 1][] = Message;
  }
  TestLog.Sinks ~= &TestLogSink;

  auto Message = "Hello World.";
  (&TestLog).Failure(Message);
  assert(Buffer.front == 'F');
  assert(Buffer[1 .. Message.length + 1] == Message);
}
