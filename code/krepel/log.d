module krepel.log;

import krepel;
import krepel.algorithm : Clamp;
import Meta = krepel.meta;

import krepel.container;

/// The global default log.
LogData* Log;

struct LogData
{
  Array!char MessageBuffer;
  Array!LogSink Sinks;
  int Indentation;

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

  ScopeBegin,
  ScopeEnd,
}

struct LogSinkArgs
{
  LogLevel Level;
  char[] Message;
  int Indentation;
}

alias LogSink = void delegate(LogSinkArgs Args);

template LogMessageDispatch(LogLevel Level)
{
  void LogMessageDispatch(Char, ArgTypes...)(LogData* Log, in Char[] Message, auto ref ArgTypes Args)
    if(Meta.IsSomeChar!Char)
  {
    // We ignore when `Log is null` as this usually means that the given log
    // is not yet initialized. It is no reason to crash the program.
    if(Log is null) return;

    // Clear the buffer before doing FormattedWrite. Note(Manu): The nice
    // side-effect of this is that you can use the message buffer after this
    // function exits. See CreateScope.
    Log.ClearMessageBuffer();
    FormattedWrite(Log, Message, Args);

    LogSinkArgs SinkArgs;
    SinkArgs.Level = Level;
    SinkArgs.Message = Log.MessageBuffer[];
    SinkArgs.Indentation = Log.Indentation;

    auto Buffer = Log.MessageBuffer[];
    foreach(ref Sink ; Log.Sinks[])
    {
      Sink(SinkArgs);
    }
  }
}

alias Info    = LogMessageDispatch!(LogLevel.Info);
alias Warning = LogMessageDispatch!(LogLevel.Warning);
alias Failure = LogMessageDispatch!(LogLevel.Failure);

void Indent(LogData* Log, int By = 1)
{
  if(Log)
  {
    Log.Indentation = cast(int)Clamp(cast(long)Log.Indentation + By, 0, int.max);
    assert(Log.Indentation >= 0);
  }
}

void Dedent(LogData* Log, int By = 1)
{
  Log.Indent(-By);
}

void BeginScope(Char, ArgTypes...)(LogData* Log, in Char[] Message, auto ref ArgTypes Args)
  if(Meta.IsSomeChar!Char)
{
  if(Log is null) return;

  LogMessageDispatch!(LogLevel.ScopeBegin)(Log, Message, Args);
  Log.Indent();
}

void EndScope(Char, ArgTypes...)(LogData* Log, in Char[] Message, auto ref ArgTypes Args)
{
  if(Log is null) return;

  Log.Dedent();
  LogMessageDispatch!(LogLevel.ScopeEnd)(Log, Message, Args);
}

void StdoutLogSink(LogSinkArgs Args)
{
  static import std.stdio;

  with(Args)
  {
    final switch(Level)
    {
      case LogLevel.Info:       std.stdio.write("Info"); break;
      case LogLevel.Warning:    std.stdio.write("Warn"); break;
      case LogLevel.Failure:    std.stdio.write("Fail"); break;
      case LogLevel.ScopeBegin: std.stdio.write(" >>>"); break;
      case LogLevel.ScopeEnd:   std.stdio.write(" <<<"); break;
    }

    if(Message.length)
    {
      // Write a message prefix.
      std.stdio.write(": ");

      // Write indentation part.
      while(Indentation > 0)
      {
        std.stdio.write("  ");
        Indentation--;
      }

      // Write the actual message.
      std.stdio.writeln(Message);
    }
    else
    {
      std.stdio.writeln();
    }
  }
}

unittest
{
  auto TestAllocator = CreateTestAllocator();
  auto TestLog = LogData(TestAllocator);

  char[256] Buffer;
  void TestLogSink(LogSinkArgs Args)
  {
    with(Args)
    {
      final switch(Level)
      {
        case LogLevel.Info:       Buffer[0] = 'I'; break;
        case LogLevel.Warning:    Buffer[0] = 'W'; break;
        case LogLevel.Failure:    Buffer[0] = 'F'; break;
        case LogLevel.ScopeBegin: Buffer[0] = '>'; break;
        case LogLevel.ScopeEnd:   Buffer[0] = '<'; break;
      }
      Buffer[1 .. Message.length + 1][] = Message;
    }
  }
  TestLog.Sinks ~= &TestLogSink;

  auto Message = "Hello World.";
  (&TestLog).Failure(Message);
  assert(Buffer.front == 'F');
  assert(Buffer[1 .. Message.length + 1] == Message);
}
