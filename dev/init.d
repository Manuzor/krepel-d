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
// - The equivalent to `mklink /L dmd2 C:\my\dir\to\dmd2
// - Compile druntime

int main(string[] args)
{
  io.stderr.writeln("The init script is not implemented yet, sorry.");
  return 1;
}
