@echo off
@setlocal
@set ThisDir=%~dp0

pushd "%ThisDir%"
rdmd -vcolumns -g -debug --extra-file=dev\file_logger_wrapper.d dev\init.d
@popd

@endlocal
