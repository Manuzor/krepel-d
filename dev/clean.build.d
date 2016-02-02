module clean;

import build;

immutable ThisDir = dirName(__FILE__);

mixin AddBuildRule!("clean", BuildRule);


void BuildRule(ref BuildContext Context)
{
  trace("Cleaning build files.");

  // Clean out the build directory, but don't delete the directory itself.
  auto BuildFiles = Context.BuildDir.dirEntries(SpanMode.shallow, false)
                                    .filter!(a => !a.name.baseName.equal("build.log")); // Don't delete the build log file.
  foreach(fileSystemItem; BuildFiles)
  {
    if(fileSystemItem.isFile)
    {
      fileSystemItem.name.remove();
    }
    else
    {
      fileSystemItem.name.rmdirRecurse();
      assert(fileSystemItem.isDir);
    }
  }
}
