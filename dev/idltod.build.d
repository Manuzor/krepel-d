module idltod;

import build;

immutable thisDir = dirName(__FILE__);

mixin AddBuildRule!("idltod", Idltod);

// Utility function to get all relevant source files.
void Idltod(ref BuildContext Context)
{
  Context.OutFileName = "idltod.exe";
  Context.Files ~= buildNormalizedPath(thisDir, "idltod.d");
  Context.BuildArgs = Context.BuildArgs.remove!(a => a == "-vgc");
  Compile(Context);
}
