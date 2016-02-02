module win32_experiments;

import build;

immutable thisDir = dirName(__FILE__);

mixin AddBuildRule!("win32_experiments", BuildRule);


void BuildRule(ref BuildContext Context)
{
  trace("Building win32_experiments");

  with(Context)
  {
    OutFileName = "win32_experiments.exe";

    foreach(SourceDir; ["krepel", "win32_experiments"])
    {
      auto AbsoluteSourceDir = buildNormalizedPath(thisDir, SourceDir);
      Files ~= dirEntries(AbsoluteSourceDir, "*.d", SpanMode.breadth)  // Gather all *.d files
               .map!(a => a.name)                              // Use only the name of DirEntry objects.
               .array;                                         // Convert the range to a proper array.
    }
  }

  Compile(Context);
}
