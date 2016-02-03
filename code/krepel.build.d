module krepel_tests;

import build;

immutable thisDir = dirName(__FILE__);

mixin AddBuildRule!("krepel_tests", Tests);


void Tests(ref BuildContext Context)
{
  with(Context)
  {
    OutFileName = "krepel_tests.exe";

    foreach(SourceDir; ["krepel"])
    {
      auto AbsoluteSourceDir = buildNormalizedPath(thisDir, SourceDir);
      Files ~= dirEntries(AbsoluteSourceDir, "*.d", SpanMode.breadth)  // Gather all *.d files
               .map!(a => a.name)                                      // Use only the name of DirEntry objects.
               .array;                                                 // Convert the range to a proper array.
    }

    BuildArgs ~= "-unittest";
    BuildArgs ~= "-main";
  }

  if(Compile(Context).CompilerStatus == 0)
  {
    Run(Context);
  }
}
