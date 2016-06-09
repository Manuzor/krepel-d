@echo off
@setlocal EnableDelayedExpansion

@set ThisDir=%~dp0

@REM :: Change to repo root directory
pushd "%ThisDir%"

  @set ExtraFiles=--extra-file="%CD%\dev\file_logger_wrapper.d"
  @for /r %%f in (*.build.d) do set ExtraFiles=!ExtraFiles! --extra-file="%%f"

  @set DMDArgs=-vcolumns -g -debug
  @set RDMDArgs=%ExtraFiles%
  @set BuildFile=%CD%\dev\build.d

  external\dmd2\windows\bin\rdmd.exe %DMDArgs% %RDMDArgs% "%BuildFile%" -v -Win32 -Debug %*
@popd

@endlocal
