module krepel_tests;

import build;

immutable thisDir = dirName(__FILE__);

mixin AddBuildRule!("krepel_tests", KrepelTests_BuildAndRun);
mixin AddBuildRule!("krepel_tests_build_only", KrepelTests_BuildOnly);
mixin AddBuildRule!("krepel_tests_run_only", KrepelTests_RunOnly);

void KrepelTests_BuildAndRun(ref BuildContext Context)
{
  Prepare(Context);

  if(Compile(Context).CompilerStatus == 0)
  {
    Run(Context);
  }
}

void KrepelTests_BuildOnly(ref BuildContext Context)
{
  Prepare(Context);
  Compile(Context);
}

void KrepelTests_RunOnly(ref BuildContext Context)
{
  Prepare(Context);
  Run(Context);
}

private void Prepare(ref BuildContext Context)
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
}
