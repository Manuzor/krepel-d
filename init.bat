@echo off
@setlocal
@set ThisDir=%~dp0

@set RDMD=%~dp0external\dmd2\windows\bin\rdmd.exe

pushd "%ThisDir%"
  "%RDMD%" -vcolumns -g -debug --extra-file=dev\file_logger_wrapper.d dev\init.d
@popd

@endlocal
