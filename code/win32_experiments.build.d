module win32_experiments;

import build;

immutable thisDir = dirName(__FILE__);

mixin AddBuildRule!("win32_experiments", Win32Experiments);
mixin AddBuildRule!("win32_experiments_tests", Win32ExperimentsTests);

void Win32Experiments(ref BuildContext Context)
{
  Context.OutFileName = "win32_experiments.exe";
  Win32ExperimentsCommon(Context);
  Compile(Context);
}

void Win32ExperimentsTests(ref BuildContext Context)
{
  Context.OutFileName = "win32_experiments_tests.exe";
  Win32ExperimentsCommon(Context);
  Context.BuildArgs ~= "-unittest";
  if(Compile(Context).CompilerStatus == 0)
  {
    Run(Context);
  }
}

// Utility function to get all relevant source files.
void Win32ExperimentsCommon(ref BuildContext Context)
{
  with(Context)
  {
    // Add source files.
    immutable DirectoriesToSearch = ["krepel", "win32_experiments"];
    foreach(SourceDir; DirectoriesToSearch)
    {
      auto AbsoluteSourceDir = buildNormalizedPath(thisDir, SourceDir);
      Files ~= dirEntries(AbsoluteSourceDir, "*.d", SpanMode.breadth)  // Gather all *.d files
               .map!(a => a.name)                                      // Use only the name of DirEntry objects.
               .array;                                                 // Convert the range to a proper array.
    }

    //
    // DirectX files.
    //
    auto DirectXFiles = chain(only("dxgiformat.d", "dxerror.d", "dxgitype.d", "dxgi.d", "dxgi1_2.d"),
                              only("d3dcommon.d", "d3dcompiler.d", "d3d11.d", "d3d11_1.d", "d3d11shader.d", "d3d11sdklayers.d"),
                              only("xinput.d"));
    foreach(FileName; DirectXFiles)
    {
      Files ~= buildNormalizedPath(thisDir, "directx", FileName);
    }

    //
    // Set runtime linking versions
    //
    BuildArgs ~= "-version=DXGI_RuntimeLinking";
    BuildArgs ~= "-version=D3D11_RuntimeLinking";
    BuildArgs ~= "-version=D3DCompiler_RuntimeLinking";
    BuildArgs ~= "-version=XInput_RuntimeLinking";
  }
}
