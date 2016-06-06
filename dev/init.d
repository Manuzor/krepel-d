module init;

import std.stdio;
import std.process;
import std.string;
import std.uni;
import std.algorithm;
import std.conv;
import std.array;
import std.range;
import std.path;
import std.file;

import std.experimental.logger;

// Note(Manu): Located in "dev/file_logger_wrapper.d"
import file_logger_wrapper;


pragma(msg, "! Compiling init script");

// What this script does:
// - Initialize the git repo for development.
// - Generate a sc.ini file.
// - TODO: The equivalent to `mklink /J dmd2 C:\my\dir\to\dmd2


class ContextData
{
  int Verbosity = 1;

  string CallDir;
  string RootDir;
  string BuildDir;
  string WorkspaceDir;

  // TODO: Will need to be platform specific.
  string GitExecutable = "git.exe";
}

void initGit(ContextData Context)
{
  // We 'wait()' here rather than letting the processes run in parallel to
  // ensure potential console output is in sequential order.

  // Turn off 'autocrlf' so git doesn't perform any line ending normalization by default.
  spawnProcess([Context.GitExecutable, "config", "core.autocrlf", "false"]).wait();

  // Set the line endings used internally to 'lf'.
  spawnProcess([Context.GitExecutable, "config", "core.eol", "lf"]).wait();

  version(Windows)
  {
    // Fix git trying to understand Windows file permissions.
    spawnProcess([Context.GitExecutable, "config", "core.filemode", "false"]).wait();
  }
}

/// Generates the `sc.ini` file that is used by dmd for some platform
/// configuration stuff.
///
/// Usually, this file is pre-installed with the dmd compiler. However, this
/// is not very flexible as it demands you to re- install dmd once a new
/// visual studio version is installed, or uninstalled. It's just too
/// unflexible. Therefore we generate this file here on our own with all the
/// data we need.
void generateSCIni(ContextData Context)
{
  auto FindVisualStudioDir()
  {
    foreach(EnvVarName; ["VS140COMNTOOLS", "VS120COMNTOOLS", "VS110COMNTOOLS"])
    {
      auto VsToolsDir = environment.get(EnvVarName);
      if(VsToolsDir)
      {
        if(Context.Verbosity > 2)
        {
          logf(`Found VS Tools dir in environment variable "%s": %s`, EnvVarName, VsToolsDir);
        }

        return buildNormalizedPath(VsToolsDir, "..", "..");
      }
      if(Context.Verbosity > 1)
      {
        logf(`No environment variable "%s" found.`, EnvVarName);
      }
    }

    return null;
  }

  struct IniSectionData
  {
    string[] DFLAGS;
    string[] LIB;
    string LINKCMD;
  }

  auto DmdSrcDir = buildNormalizedPath(Context.RootDir, "external", "dmd2", "src");
  auto DmdWindowsDir = buildNormalizedPath(Context.RootDir, "external", "dmd2", "windows");


  IniSectionData[string] Sections;
  Sections["Environment32"] = IniSectionData();
  Sections["Environment32"].DFLAGS ~= "%DFLAGS%";
  Sections["Environment64"] = IniSectionData();
  Sections["Environment64"].DFLAGS ~= "%DFLAGS%";


  // e.g. -I"C:\krepel\external\dmd2\src\druntime\import"
  Sections["Environment32"].DFLAGS ~= `"-I` ~ buildNormalizedPath(DmdSrcDir, "druntime", "import") ~ `"`;
  Sections["Environment64"].DFLAGS ~= `"-I` ~ buildNormalizedPath(DmdSrcDir, "druntime", "import") ~ `"`;

  // e.g. -I"C:\krepel\external\dmd2\src\phobos"
  Sections["Environment32"].DFLAGS ~= `"-I` ~ buildNormalizedPath(DmdSrcDir, "phobos") ~ `"`;
  Sections["Environment64"].DFLAGS ~= `"-I` ~ buildNormalizedPath(DmdSrcDir, "phobos") ~ `"`;

  Sections["Environment32"].DFLAGS ~= "user32.lib";
  Sections["Environment32"].DFLAGS ~= "phobos.lib";
  Sections["Environment64"].DFLAGS ~= "user32.lib";
  Sections["Environment64"].DFLAGS ~= "phobos64.lib";


  Sections["Environment32"].LIB ~= buildNormalizedPath(DmdWindowsDir, "lib");
  Sections["Environment64"].LIB ~= buildNormalizedPath(DmdWindowsDir, "lib64");


  auto VisualStudioDir = FindVisualStudioDir();
  assert(VisualStudioDir, "Unable to find Visual Studio directory. "
                          "Make sure it's installed and the VSxxCOMNTOOLS "
                          "environment variable is set (xx == a number).");

  if(Context.Verbosity > 3)
  {
    log("Visual Studio Directory: ", VisualStudioDir);
  }

  Sections["Environment64"].LIB ~= buildNormalizedPath(VisualStudioDir, "VC", "lib", "amd64");
  // TODO(Manu): Sections["Environment32"].LIB ~= buildNormalizedPath(VisualStudioDir, "VC", "lib", "??");

  string WindowsKitsLibSubfolder;

  auto WindowsKitsDir = [
    buildNormalizedPath(environment.get("ProgramFiles(x86)", ""), "Windows Kits"),
    buildNormalizedPath(environment.get("ProgramFiles", ""), "Windows Kits"),
    buildNormalizedPath("C:", "Program Files (x86)", "Windows Kits"),
    buildNormalizedPath("C:", "Program Files", "Windows Kits"),
  ].find!(a => a.exists && a.isDir).front;

  auto WindowsLibDirs = [
    // Windows 10 first
    buildNormalizedPath(WindowsKitsDir, "10", "Lib"),

    // Then try Windows 8.1
    buildNormalizedPath(WindowsKitsDir, "8.1", "Lib"),

    // And finally Windows 8. We won't go below that.
    buildNormalizedPath(WindowsKitsDir, "8.0", "Lib"),
  ];

  foreach(Path; WindowsLibDirs)
  {
    if(Path.exists)
    {
      foreach(WindowsSDKLibDir; Path.dirEntries(SpanMode.shallow).array.sort!"b.name < a.name")
      {
        auto FinalPath = buildNormalizedPath(WindowsSDKLibDir, "um", "x86");
        if(FinalPath.exists) Sections["Environment32"].LIB ~= FinalPath;

        FinalPath = buildNormalizedPath(WindowsSDKLibDir, "ucrt", "x86");
        if(FinalPath.exists) Sections["Environment32"].LIB ~= FinalPath;

        FinalPath = buildNormalizedPath(WindowsSDKLibDir, "um", "x64");
        if(FinalPath.exists) Sections["Environment64"].LIB ~= FinalPath;

        FinalPath = buildNormalizedPath(WindowsSDKLibDir, "ucrt", "x64");
        if(FinalPath.exists) Sections["Environment64"].LIB ~= FinalPath;
      }
    }
  }

  Sections["Environment32"].LINKCMD = buildNormalizedPath(VisualStudioDir, "VC", "bin", "link.exe");
  Sections["Environment64"].LINKCMD = buildNormalizedPath(VisualStudioDir, "VC", "bin", "amd64", "link.exe");

  //
  // Write the file.
  //
  {
    auto OutFilePath = buildNormalizedPath(Context.RootDir, "build", "sc.ini");
    auto OutFile = File(OutFilePath, "w");
    foreach(Pair; Sections.byKeyValue())
    {
      auto SectionName = Pair.key;
      auto Section = Pair.value;
      OutFile.writeln('[', SectionName, ']');
      if(Section.DFLAGS) OutFile.writefln("DFLAGS=%-(%s %)", Section.DFLAGS);
      if(Section.LIB) OutFile.writefln(`LIB=%-("%s";%)"`, Section.LIB);
      // Note(Manu): The reference sc.ini does not enclose the LINKCMD with quotes thus we don't write "%s".
      if(Section.LINKCMD) OutFile.writefln(`LINKCMD=%s`, Section.LINKCMD);
      OutFile.writeln();
    }
  }
}

int main(string[] args)
{
  auto Context = new ContextData();
  Context.CallDir = getcwd().absolutePath;
  Context.RootDir = buildNormalizedPath(__FILE__.dirName, "..").absolutePath;
  Context.BuildDir = buildNormalizedPath(Context.RootDir, "build");
  Context.WorkspaceDir = buildNormalizedPath(Context.RootDir, "workspace");

  auto BuildLogger = new MultiLogger();
  auto defaultLog = new FileLoggerWrapper(stderr);
  defaultLog.BaseDir = Context.RootDir;
  BuildLogger.insertLogger("DefaultLog", defaultLog);
  sharedLog = BuildLogger;

  // TODO: Will need to be platform specific.
  Context.GitExecutable = "git.exe";

  initGit(Context);
  generateSCIni(Context);

  return 0;
}
