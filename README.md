Krepel
======

Getting Started
---------------

### Windows

Download the [Digitial Mars D Compiler (DMD)](https://dlang.org/) with at least version 2.070.0 and extract it anywhere on your system. Then, use the command line to `cd` into the `external\` directory in this repository, and use `mklink /J dmd2 C:\<My Path To The DMD Installation Dir>`.

Once you've done that, you can use the script `build.bat` from the root of the repository to trigger compilation for various targets. To see all available build rules, use `build.bat -rules`.
