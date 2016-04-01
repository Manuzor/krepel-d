Krepel
======

Getting Started
---------------

### Windows

Download the [Digitial Mars D Compiler (DMD)](https://dlang.org/) with at least version 2.070.0 and extract it anywhere on your system. Then, use the command line to `cd` into the `external\` directory in this repository, and use `mklink /J dmd2 C:\<My Path To The DMD Installation Dir>`.

Once you've done that, run the script `init.bat` from the root of the repository to properly initialize your local working environment. You will only have to run this script once after cloning.

From now on you can use the script `build.bat` from the root of the repository to trigger compilation for various targets. To see all available build rules, use `build.bat -rules`.

#### Summary

1. Install or link dmd2 `~>2.070.0` in the `external/` directory.
1. Run `init.bat` from the repo root.
1. You're ready to use `build.bat` from the repo root to build individual targets. Run `build -Rules` to see available targets.

Notes
-----

* You should **never** use `git clean -xdf` on the repository root. It will delete the **content** of the folders you linked to in the `external/` folder. You should either use `build clean` or `git clean -xdf -e external`.
