module build;

public import std.string;
public import std.uni;
public import std.algorithm;
public import std.conv;
public import std.array;
public import std.range;
public import std.regex;
public import std.format;
public import std.datetime;

public import std.file;
public import std.path;
public import std.process;

import io = std.stdio;
public import std.experimental.logger;

debug pragma(msg, "! Compiling build script");

enum PlatformKind
{
  Win32
}

enum ConfigurationKind
{
  Debug,
  Release,
}

enum ArchitectureKind
{
  x64,
  x86,
}

enum CompilerKind
{
  DMD,
}

struct BuildContext
{
  int Verbosity;

  PlatformKind Platform;
  ConfigurationKind Configuration;
  ArchitectureKind Architecture;
  CompilerKind Compiler;


  /// The path to the dmd executable.
  string DMDPath;

  /// The path to build the compiler in.
  string BuildDir;

  /// The path to the directory this build was invoked in.
  string CallDir;

  /// The path to the root of the repo.
  string RootDir;

  /// The name of the build, e.g. "krepel". Will produce "krepel.exe" on Windows if it's a binary.
  string OutFileName;

  string[] Files;
  string[] BuildArgs;
  string[] UserArgs;
}

string ToString(in ref BuildContext Context)
{
  string Result;

  Result ~= "\n  PlatformKind      = " ~ Context.Platform.to!string;
  Result ~= "\n  ConfigurationKind = " ~ Context.Configuration.to!string;
  Result ~= "\n  ArchitectureKind  = " ~ Context.Architecture.to!string;
  Result ~= "\n  CompilerKind      = " ~ Context.Compiler.to!string;
  Result ~= "\n  DMDPath       = " ~ Context.DMDPath.to!string;
  Result ~= "\n  BuildDir      = " ~ Context.BuildDir.to!string;
  Result ~= "\n  OutFileName   = " ~ Context.OutFileName.to!string;
  Result ~= "\n  Files         = " ~ Context.Files.to!string;
  Result ~= "\n  BuildArgs     = " ~ Context.BuildArgs.to!string;
  Result ~= "\n  UserArgs      = " ~ Context.UserArgs.to!string;

  return Result;
}

struct BuildRuleData
{
  alias RuleFunc = void delegate(ref BuildContext);

  string Name;
  RuleFunc Functor;
  //string[] dependencies;
}

BuildRuleData[] GlobalBuildRules;

// Usage: mixin AddBuildRule!myFunc;
mixin template AddBuildRule(alias BuildName, alias BuildFunc)
{
  static this()
  {
    static import std.functional;
    static import build;

    BuildRuleData Rule_; // Avoid name conflicts by adding an underscore...
    Rule_.Name = BuildName;
    Rule_.Functor = .std.functional.toDelegate(&BuildFunc);

    .build.GlobalBuildRules ~= Rule_;
  }
}

void CopyFile(SourceType, DestinationType)(in ref BuildContext Context,
                                           SourceType Source, DestinationType Destination)
{
  if(Context.Verbosity > 1)
  {
    logf("Copy: %s => %s", Source, Destination);
  }

  std.file.copy(Source, Destination);
}

// NOTE(Manu): In case we need this some time, this detects a file extension from given build arguments.
auto DetectOutFileExtension(string[] Args, CompilerKind Compiler, PlatformKind Platform)
{
  final switch(Compiler)
  {
    case CompilerKind.DMD:
    {
      auto LibPos = Args.countUntil!(a => a.equal("-lib"));
      auto SharedPos = Args.countUntil!(a => a.equal("-shared"));
      auto ObjPos = Args.countUntil!(a => a.equal("-c"));

      final switch(Platform)
      {
        case PlatformKind.Win32:
        {
          if([LibPos, SharedPos, ObjPos].all!(a => a < 0)) return ".exe";
          else if(LibPos    > max(SharedPos, ObjPos))      return ".lib";
          else if(SharedPos > max(SharedPos, ObjPos))      return ".dll";
          else if(ObjPos    > max(SharedPos, ObjPos))      return ".obj";
        } break;
      }
    } break;
  }

  assert(0, "Unreachable code.");
}



struct CompilationResult
{
  // Will hold the exit code of the Compiler, if no other error occurred before invoking it.
  int CompilerStatus;

  // Behave like a bool.
  private bool Success;
  alias Success this;
}

CompilationResult Compile(ref BuildContext Context)
{
  typeof(return) Result;

  if(!Context.OutFileName)
  {
    critical("No OutFileName given before compiling.");
    return Result; // NOTE(Manu): Result evaluates to false by default!
  }

  if(Context.Verbosity > 1)
  {
    logf("BuildContext:%s", Context.ToString);
  }

  string CompilerPath;
  final switch(Context.Compiler)
  {
    case CompilerKind.DMD:
    {
      CompilerPath = Context.DMDPath;
    } break;
  }

  string OutFileName = "-of" ~ Context.OutFileName;

  auto Command = array(chain([CompilerPath,      // e.g.: dmd.exe
                              OutFileName,],     // e.g.: -ofkrepel.exe (on Windows for an executable)
                             Context.Files,      // e.g.: code/main.d code/util.d
                             Context.BuildArgs,  // e.g.: -vcolumns -w -version=UNICODE
                             Context.UserArgs,   // e.g.: -v -vtls
                             ));
  if(Context.Verbosity)
  {
    logf("Command: %-(%s %)", Command);
    log("+++ Compiling +++");
  }
  scope(exit) if(Context.Verbosity) log("--- Compiling ---");

  // No error on our side so far, so set the Result to true;
  Result = true;
  Result.CompilerStatus = spawnProcess(Command).wait();
  return Result;
}

void ExecuteBuildRule(ref BuildContext Context, ref BuildRuleData BuildRule)
{
  auto CurrentWorkingDirectory = getcwd();
  if(Context.Verbosity)
  {
    logf("Executing build rule: %s", BuildRule.Name);
  }

  // TODO(Manu): BuildRule.dependencies?
  BuildRule.Functor(Context);
  chdir(CurrentWorkingDirectory);
}

string uniquePlatformKindString(in ref BuildContext Context)
{
  auto Result = "%s_%s_%s".format(Context.Platform,
                                  Context.Configuration,
                                  Context.Compiler);
  return Result.asLowerCase.to!string;
}

void Win32Build(ref BuildContext Context, ref BuildRuleData BuildRule)
{
  if(Context.Verbosity)
  {
    logf("Win32 %s", Context.Configuration);
  }

  final switch(Context.Configuration)
  {
    case ConfigurationKind.Debug:
    {
      Context.BuildArgs ~= "-gc";       // Debug symbols.
      Context.BuildArgs ~= "-debug";    // Compile in debug mode.
      Context.BuildArgs ~= "-unittest"; // Allow unit tests to be built.
    } break;

    case ConfigurationKind.Release:
    {
      Context.BuildArgs ~= "-release"; // Compile in release mode.
      Context.BuildArgs ~= "-inline";  // Try inlining functions..
      Context.BuildArgs ~= "-O";       // Optimize.
    } break;
  }

  final switch(Context.Architecture)
  {
    case ArchitectureKind.x64:
    {
      Context.BuildArgs ~= "-m64";
    } break;

    case ArchitectureKind.x86:
    {
      Context.BuildArgs ~= "-m32mscoff";
    } break;
  }

  // Make sure the build dir exists.
  mkdirRecurse(Context.BuildDir);

  auto DmdDir = buildNormalizedPath(Context.RootDir, "external", "dmd2");

  Context.DMDPath = buildNormalizedPath(DmdDir, "windows", "bin", "dmd.exe");

  // Copy over the sc.ini file to the build dir.
  CopyFile(Context, buildNormalizedPath(Context.RootDir, "dev", "sc.ini"),
                    buildNormalizedPath(Context.BuildDir, "sc.ini"));

  string[] ImportPath;
  string[] Libs;
  string[] LibPath;

  // DRuntime
  ImportPath ~= buildNormalizedPath(DmdDir, "src", "druntime", "import");

  // Phobos
  ImportPath ~= buildNormalizedPath(DmdDir, "src", "phobos");
  LibPath ~= buildNormalizedPath(DmdDir, "windows", "lib64");
  Libs ~= "phobos64.lib";

  // PlatformKind specific libraries.
  Libs ~= "user32.lib";

  // TODO: Maybe do this in some init.d script? Could also make some mklinks in that init script.
  auto FindVisualStudioDir()
  {
    foreach(EnvVarName; ["VS140COMNTOOLS", "VS120COMNTOOLS", "VS110COMNTOOLS"])
    {
      auto VsToolsDir = environment.get(EnvVarName);
      if(VsToolsDir)
      {
        return buildNormalizedPath(VsToolsDir, "..", "..");
      }
    }

    return null;
  }

  auto VisualStudioDir = FindVisualStudioDir();
  assert(VisualStudioDir);

  LibPath ~= buildNormalizedPath(VisualStudioDir, "VC", "lib", "amd64");

  // TODO: Find the windows kit more dynamically.
  auto WindowsSdkDir = buildNormalizedPath("C:", "Program Files (x86)", "Windows Kits", "10");
  auto UcrtVersion = "10.0.10586.0";
  LibPath ~= buildNormalizedPath(WindowsSdkDir, "Lib", UcrtVersion, "um", "x64");
  LibPath ~= buildNormalizedPath(WindowsSdkDir, "Lib", UcrtVersion, "ucrt", "x64");

  Context.BuildArgs ~= ImportPath.map!(a => `-I"` ~ a ~ `"`).array;
  Context.BuildArgs ~= LibPath.map!(a => `-L/LIBPATH:"` ~ a ~ `"`).array;
  Context.BuildArgs ~= Libs;

  string LinkerPath;
  final switch(Context.Architecture)
  {
    case ArchitectureKind.x64:
    {
      LinkerPath = buildNormalizedPath(VisualStudioDir, "VC", "bin", "amd64", "link.exe");
    } break;

    case ArchitectureKind.x86:
    {
      LinkerPath = buildNormalizedPath(VisualStudioDir, "VC", "bin", "link.exe");
    } break;
  }

  // Set LINKCMD to tell dmd which linker executable to use.
  environment["LINKCMD"] = LinkerPath;

  if(Context.Verbosity > 3)
  {
    logf("Environment:\n  %-(%s = %s,\n  %)", environment.toAA());
  }

  ExecuteBuildRule(Context, BuildRule);
}

void PrintHelp()
{
  // Don't use the logging system here.
  io.writefln("Build script arguments:
  -Win32     For a Win32 build (default when compiling on Windows Platforms)
  -Debug     For a debug Configuration build (default)
  -Release   For a release Configuration build
  -dmd       When you want to use dmd (default)
  -BuildDir  Where to build stuff.
  -Rules     Show all possible build rules and exit.
  -Help      Show this message and exit.
  -v         Be more verbose. Can be supplied multiple times (e.g. -vvvv).
  -Quiet     Reset Verbosity to zero.
  --         Stop processing Args and pass everything else to the Compiler.");
}

void PrintRules()
{
  io.writefln("%-(%s\n%)", GlobalBuildRules.map!(a => a.Name));
}

// Override this file logger and provide a more sane output format.
class FileLoggerWrapper : FileLogger
{
  import std.concurrency;

  string BaseDir;


  this(in string FileName, const LogLevel TheLogLevel = LogLevel.all) @safe { super(FileName, TheLogLevel); }
  this(io.File TheFile, const LogLevel TheLogLevel = LogLevel.all) @safe { super(TheFile, TheLogLevel); }

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

int main(string[] Args)
{
  auto BeginTime = Clock.currTime();
  auto CallDir = getcwd();
  auto RootDir = buildNormalizedPath(__FILE__.dirName, "..");

  auto BuildLogger = new MultiLogger();
  auto defaultLog = new FileLoggerWrapper(io.stderr);
  defaultLog.BaseDir = RootDir;
  BuildLogger.insertLogger("DefaultLog", defaultLog);
  sharedLog = BuildLogger;

  // Throw away Args[0]
  Args = Args[1 .. $];

  BuildContext BaseBuildContext;
  BaseBuildContext.CallDir = CallDir;
  BaseBuildContext.RootDir = RootDir;
  BaseBuildContext.BuildDir = buildNormalizedPath(BaseBuildContext.RootDir, "build");

  BaseBuildContext.BuildArgs = [
    "-de",              // Treat use of deprecated features as errors.
    "-vcolumns",        // Show column information in diagnostics.
    "-w",               // Treat warnings as errors.
    "-version=UNICODE", // Compile in UNICODE mode.
    "-vgc",             // Show gc allocations.
  ];

  int numberOfUnknownArguments;
  string[] buildRuleNames;
  foreach(index, arg; Args)
  {
    auto CleanArg = arg.stripLeft!isWhite.asLowerCase();

    if(arg.matchFirst(`^-{2}[hH][eE][lL][pP]+$`))
    {
      PrintHelp();
      return 1;
    }
    else if(CleanArg.equal("-rules"))
    {
      PrintRules();
      return 1;
    }
    else if(arg.matchFirst(`^-[vV]+$`))
    {
      BaseBuildContext.Verbosity += arg.length;
    }
    else if(CleanArg.equal("-win32"))
    {
      BaseBuildContext.Platform = PlatformKind.Win32;
    }
    else if(CleanArg.equal("-quiet"))
    {
      BaseBuildContext.Verbosity = 0;
    }
    else if(CleanArg.equal("-debug"))
    {
      BaseBuildContext.Configuration = ConfigurationKind.Debug;
    }
    else if(CleanArg.equal("-release"))
    {
      BaseBuildContext.Configuration = ConfigurationKind.Release;
    }
    else if(CleanArg.equal("-dmd"))
    {
      BaseBuildContext.Compiler = CompilerKind.DMD;
    }
    else if(CleanArg.startsWith("-builddir="))
    {
      BaseBuildContext.BuildDir = arg.drop("-builddir=".length);
    }
    else if(arg.equal("--"))
    {
      BaseBuildContext.UserArgs = Args[index + 1 .. $];
      break;
    }
    else if(arg.startsWith("-"))
    {
      // Don't abort immediately to show all errors, not just the first.
      ++numberOfUnknownArguments;

      errorf("Unknown Argument: %s", arg);
    }
    else // Assume it is a build rule.
    {
      buildRuleNames ~= arg;
    }
  }

  if(numberOfUnknownArguments)
  {
    return 1;
  }

  if(buildRuleNames.empty)
  {
    io.writefln("No build rule was given. Choose from these:");
    PrintRules();
    return 1;
  }

  BaseBuildContext.BuildDir = BaseBuildContext.BuildDir.asAbsolutePath.array;
  mkdirRecurse(BaseBuildContext.BuildDir);
  chdir(BaseBuildContext.BuildDir);

  // Now that we have the build dir, create a log file there.
  {
    auto BuildLogFile = new FileLoggerWrapper("build.log");
    BuildLogFile.BaseDir = RootDir;
    BuildLogFile.log(Clock.currTime().toISOExtString());
    BuildLogger.insertLogger("BuildLogFile", BuildLogFile);
  }

  if(BaseBuildContext.Verbosity > 1)
  {
    logf("CallDir:  %s", BaseBuildContext.CallDir);
    logf("RootDir:  %s", BaseBuildContext.RootDir);
  }

  if(BaseBuildContext.Verbosity)
  {
    logf("BuildDir: %s", BaseBuildContext.BuildDir);
  }

  foreach(buildRuleName; buildRuleNames)
  {
    // Find the matching build rule.
    auto BuildRule = GlobalBuildRules.find!(a => a.Name == buildRuleName);

    if(BuildRule.empty)
    {
      // Tolerance for matching build rule names.
      const matchingTolerance = 4;

      // Find candidates for the given buildRuleName.
      auto candidates = GlobalBuildRules.map!(a => a.Name)
                                        .filter!(a => levenshteinDistance(a, buildRuleName) < matchingTolerance);

      errorf(`Unable to find a build rule with the given name "%s".`, buildRuleName);

      if(!candidates.empty)
      {
        errorf("Did you mean this?%-(\n    %s%)", candidates);
      }

      error("Use -Rules to see all possible rules");

      break;
    }

    // Make a copy.
    auto Context = BaseBuildContext;

    if(Context.Verbosity)
    {
      logf(`Building rule "%s"`, buildRuleName);
    }

    auto BuildStartTime = Clock.currTime();

    final switch(Context.Platform)
    {
      case PlatformKind.Win32:
      {
        Win32Build(Context, BuildRule.front());
      } break;
    }

    auto BuildTime = BuildStartTime - Clock.currTime();
    if(Context.Verbosity)
    {
      logf("Build rule finished in %s", BuildTime);
    }
  }

  auto Duration = Clock.currTime() - BeginTime;
  logf("Total build time: %s", Duration);

  return 0;
}
