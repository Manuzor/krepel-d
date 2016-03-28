module init;

import io = std.stdio;
import std.process;
import std.string;
import std.uni;
import std.algorithm;
import std.conv;
import std.array;
import std.range;
import std.path;
import std.file;

pragma(msg, "! Compiling init script");

// TODO: See below
// What this script does:
// - Initialize the git repo for development.
// - The equivalent to `mklink /J dmd2 C:\my\dir\to\dmd2
// - Compile druntime

// TODO: Will need to be platform specific.
const GitExecutable = "git.exe";

void initGit()
{
  // We 'wait()' here rather than letting the processes run in parallel to
  // ensure potential console output is in sequential order.

  // Turn off 'autocrlf' so git doesn't perform any line ending normalization by default.
  spawnProcess([GitExecutable, "config", "core.autocrlf", "false"]).wait();

  // Set the line endings used internally to 'lf'.
  spawnProcess([GitExecutable, "config", "core.eol", "lf"]).wait();

  version(Windows)
  {
    // Fix git trying to understand Windows file permissions.
    spawnProcess([GitExecutable, "config", "core.filemode", "false"]).wait();
  }
}

int main(string[] args)
{
  initGit();
  return 0;
}
