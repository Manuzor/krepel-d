module file_logger_wrapper;

import std.stdio : File;
import std.range : drop;
import std.experimental.logger;

// Override this file logger and provide a more sane output format.
class FileLoggerWrapper : FileLogger
{
  import std.concurrency;

  string BaseDir;


  this(in string FileName, const LogLevel TheLogLevel = LogLevel.all) @safe { super(FileName, TheLogLevel); }
  this(File TheFile, const LogLevel TheLogLevel = LogLevel.all) @safe { super(TheFile, TheLogLevel); }

  override protected void beginLogMsg(string TheFile, int line, string funcName,
                                      string prettyFuncName, string moduleName, LogLevel logLevel,
                                      Tid threadId, SysTime timestamp, Logger logger)
  @safe
  {
    auto TextWriter = this.file.lockingTextWriter();
    TextWriter.formattedWrite("[%02u:%02u:%02u.%03d] %s(%s): ",
                              timestamp.hour, timestamp.minute, timestamp.second, timestamp.fracSecs.split!"msecs".msecs,
                              TheFile.drop(BaseDir.length + 1), // +1 for the trailing slash
                              line);
  }

}
