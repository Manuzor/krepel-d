module vulkan_experiments;

import build;

immutable thisDir = dirName(__FILE__);

mixin AddBuildRule!("vulkan_experiments", Executable);
mixin AddBuildRule!("vulkan_experiments_tests", ExecutableAndTests);

void Executable(ref BuildContext Context)
{
  Context.OutFileName = "vulkan_experiments.exe";
  Common(Context);
  Compile(Context);
}

void ExecutableAndTests(ref BuildContext Context)
{
  Context.OutFileName = "vulkan_experiments_tests.exe";
  Common(Context);
  Context.BuildArgs ~= "-unittest";
  if(Compile(Context).CompilerStatus == 0)
  {
    Run(Context);
  }
}

// Utility function to get all relevant source files.
void Common(ref BuildContext Context)
{
  with(Context)
  {
    // Add source files.
    // Note(Manu): DirectX is needed because krepel needs it internally.
    immutable DirectoriesToSearch = ["krepel", "directx", "vulkan", "vulkan_experiments"];
    foreach(SourceDir; DirectoriesToSearch)
    {
      auto AbsoluteSourceDir = buildNormalizedPath(thisDir, SourceDir);
      Files ~= dirEntries(AbsoluteSourceDir, "*.d", SpanMode.breadth)  // Gather all *.d files.
               .map!(a => a.name)                                      // Use only the name of DirEntry objects.
               .array;                                                 // Convert the range to a proper array.
    }

    BuildArgs ~= "-version=XInput_RuntimeLinking";
  }
}
