module krepel_tests;

import build;

immutable thisDir = dirName(__FILE__);

mixin AddBuildRule!("krepel_tests", BuildAndRun);
mixin AddBuildRule!("krepel_tests_build_only", Build);

void Build(ref BuildContext Context)
{
  DoBuild(Context);
}

void BuildAndRun(ref BuildContext Context)
{
  if(DoBuild(Context))
  {
    Run(Context);
  }
}

bool DoBuild(ref BuildContext Context)
{
  with(Context)
  {
    OutFileName = "krepel_tests.exe";

    foreach(SourceDir; ["krepel", "directx"])
    {
      auto AbsoluteSourceDir = buildNormalizedPath(thisDir, SourceDir);
      Files ~= dirEntries(AbsoluteSourceDir, "*.d", SpanMode.breadth)  // Gather all *.d files
               .map!(a => a.name)                                      // Use only the name of DirEntry objects.
               .array;                                                 // Convert the range to a proper array.
    }

    //
    // Set runtime linking versions of DirectX
    //
    //BuildArgs ~= "-version=DXGI_RuntimeLinking";
    //BuildArgs ~= "-version=D3D11_RuntimeLinking";
    BuildArgs ~= "-version=XInput_RuntimeLinking";

    BuildArgs ~= "-unittest";
    BuildArgs ~= "-main";
  }

  return Compile(Context).CompilerStatus == 0;
}
