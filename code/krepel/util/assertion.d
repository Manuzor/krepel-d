module krepel.assertion;

import Meta = krepel.meta;
import krepel.memory.construction;
import krepel.log;
import core.sys.windows.windows : DebugBreak;
import core.sys.windows.stacktrace;

private:

__gshared bool IsStackTraceInitialized = false;
__gshared bool IsAsserting = false;
__gshared void[Meta.ClassInstanceSizeOf!StackTrace] RawStackTraceMemory = void;

void Assert(char[] FileName, uint Line, string Message)
{
  if(!IsAsserting)
  {
    IsAsserting = true;
    scope(exit) IsAsserting = false;

    auto CurrentStackTrace = InPlace!StackTrace.New(8, null);

    if(Message) Log.BeginScope("Assertion stack trace\n  %s(%s): %s", FileName, Line, Message);
    else        Log.BeginScope("Assertion stack trace\n  %s(%s)", FileName, Line);

    foreach(Trace; CurrentStackTrace)
    {
      Log.Failure("%s", Trace);
    }

    Log.EndScope("Assertion stack trace.");
  }
  else
  {
    // Something went seriously wrong...
  }

  DebugBreak();
}

extern(C) void _d_assert(char[] FileName, uint Line)
{
  Assert(FileName, Line, null);
}

extern(C) void _d_assert_msg(string Message, char[] FileName, uint Line)
{
  Assert(FileName, Line, Message);
}
