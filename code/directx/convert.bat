@echo off

setlocal

set ThisDir=%~dp0
set RepoRoot=%ThisDir%..\..
set BuildDir=%RepoRoot%\build

pushd "%RepoRoot%"
  echo Building converter...
  call build.bat midltod
popd

pushd "%ThisDir%"
  set Converter=..\..\build\midltod.exe
  set Log=%BuildDir%\midltod.log

  echo Converting...

  if exist "%Log%" del "%Log%"

  rem Uncomment the ones you want converted.

  rem "%Converter%" dxgi.idl       dxgi.d       2>> "%Log%"
  rem "%Converter%" dxgitype.idl   dxgitype.d   2>> "%Log%"
  rem "%Converter%" dxgiformat.idl dxgiformat.d 2>> "%Log%"
  rem "%Converter%" dxgi1_2.idl    dxgi1_2.d    2>> "%Log%"
  rem "%Converter%" dxgi1_3.idl    dxgi1_3.d    2>> "%Log%"
  rem "%Converter%" dxgi1_4.idl    dxgi1_4.d    2>> "%Log%"
  rem "%Converter%" dxgi1_5.idl    dxgi1_5.d    2>> "%Log%"
  rem "%Converter%" d3dcommon.idl  d3dcommon.d  2>> "%Log%"
  rem "%Converter%" d3d11.idl      d3d11.d      2>> "%Log%"
  rem "%Converter%" d3d11_1.idl    d3d11_1.d    2>> "%Log%"
  rem "%Converter%" d3d11_2.idl    d3d11_2.d    2>> "%Log%"
  rem "%Converter%" d3d11_3.idl    d3d11_3.d    2>> "%Log%"
  rem "%Converter%" d3d11_4.idl    d3d11_4.d    2>> "%Log%"
popd
endlocal
