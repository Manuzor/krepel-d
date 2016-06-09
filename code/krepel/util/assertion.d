module krepel.assertion;

import Meta = krepel.meta;
import krepel.memory.construction;
import krepel.log;
import core.sys.windows.windows : DebugBreak;
import core.sys.windows.stacktrace;

private:

static bool IsAsserting = false;

// Note(Manu): Forward reference of this function is necessary here because
// the WinAPI bindings in druntime are still incomplete...
version(unittest) extern(Windows) bool IsDebuggerPresent();

/// Custom assert handler.
///
/// Instead of throwing an exception, like the default assert handler, this
/// will log a stack trace on the global log and trigger a platform specific
/// debug break.
///
/// When compiling for unit test (version(unittest)), this will only trigger
/// the debug break if a debugger is present. If none is present, it will
/// throw an AssertError. This allows unit tests to still use assertThrown and
/// is convenient as long as no debugger is attached...
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

  version(unittest)
  {
    import core.exception : AssertError;

    if(Message is null)
      Message = "Assertion failed.";
    if(IsDebuggerPresent())
      DebugBreak();
    throw new AssertError(Message);
  }
  else
  {
    DebugBreak();
  }
}

extern(C) void _d_assert(char[] FileName, uint Line)
{
  Assert(FileName, Line, null);
}

extern(C) void _d_assert_msg(string Message, char[] FileName, uint Line)
{
  Assert(FileName, Line, Message);
}
