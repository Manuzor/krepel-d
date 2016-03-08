module dxhtod;

import build;

immutable thisDir = dirName(__FILE__);

mixin AddBuildRule!("dxhtod", Dxhtod);

// Utility function to get all relevant source files.
void Dxhtod(ref BuildContext Context)
{
  Context.OutFileName = "dxhtod.exe";
  Context.Files ~= buildNormalizedPath(thisDir, "dxhtod.d");
  Context.BuildArgs = Context.BuildArgs.remove!(a => a == "-vgc");
  Compile(Context);
}
