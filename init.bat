@echo off
@setlocal
@set ThisDir=%~dp0

pushd "%ThisDir%"
rdmd -vcolumns -g -debug dev\init.d
@popd

@endlocal
