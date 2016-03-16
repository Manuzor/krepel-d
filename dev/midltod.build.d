module midltod;

import build;

immutable thisDir = dirName(__FILE__);

mixin AddBuildRule!("midltod", Midltod);

// Utility function to get all relevant source files.
void Midltod(ref BuildContext Context)
{
  Context.OutFileName = "midltod.exe";
  Context.Files ~= buildNormalizedPath(thisDir, "midltod.d");
  Context.BuildArgs = Context.BuildArgs.remove!(a => a == "-vgc");
  Compile(Context);
}
