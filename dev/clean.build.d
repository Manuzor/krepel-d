module clean;

import build;

immutable ThisDir = dirName(__FILE__);

mixin AddBuildRule!("clean", BuildRule);


immutable WhiteList = [ "*build.log", "*sc.ini", "*.sln", "*.vs" ];

/// Clean out the build directory, without deleting the directory itself.
void BuildRule(ref BuildContext Context)
{
  auto BuildFiles = Context.BuildDir.dirEntries(SpanMode.shallow, false);
  auto ToClean = BuildFiles.filter!(Entry => !WhiteList.canFind!((Pattern, File) => File.globMatch(Pattern))(Entry.name))
                           .array;

  if(Context.Verbosity)
  {
    if(ToClean.empty) log("Nothing to clean.");
    else              logf("Cleaning up:%-(\n  %s%)", ToClean);
  }

  foreach(fileSystemItem; ToClean)
  {
    if(fileSystemItem.isFile)
    {
      remove(fileSystemItem.name);
    }
    else
    {
      assert(fileSystemItem.isDir);
      rmdirRecurse(fileSystemItem.name);
    }
  }

  if(Context.Verbosity > 1)
  {
    auto Ignored = BuildFiles.filter!(File => !ToClean.canFind(File));
    if(!Ignored.empty) logf("Ignored:%-(\n  %s%)", Ignored);
  }
}
