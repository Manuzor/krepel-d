module krepel.win32.xinput;

import krepel;
public import krepel.win32.xinput_wrapper;
import Wrapped = krepel.win32.xinput_wrapper;

import core.sys.windows.windows;

typeof(Wrapped.XInputGetState)*              XInputGetState              = (a, b)          => ERROR_DEVICE_NOT_CONNECTED;
typeof(Wrapped.XInputSetState)*              XInputSetState              = (a, b)          => ERROR_DEVICE_NOT_CONNECTED;
typeof(Wrapped.XInputGetCapabilities)*       XInputGetCapabilities       = (a, b, c)       => ERROR_DEVICE_NOT_CONNECTED;
typeof(Wrapped.XInputGetAudioDeviceIds)*     XInputGetAudioDeviceIds     = (a, b, c, d, e) => ERROR_DEVICE_NOT_CONNECTED;
typeof(Wrapped.XInputGetBatteryInformation)* XInputGetBatteryInformation = (a, b, c)       => ERROR_DEVICE_NOT_CONNECTED;
typeof(Wrapped.XInputGetKeystroke)*          XInputGetKeystroke          = (a, b, c)       => ERROR_DEVICE_NOT_CONNECTED;


// All versions of XInput that we support, in the order of preference.
immutable Win32XInputDllCandidates = [
  "xinput1_4.dll",
  "xinput9_1_0.dll",
  "xinput1_3.dll",
];

auto Win32TryLoadProcedure(FallbackType)(HANDLE ModuleHandle, string ProcedureName, FallbackType Fallback)
{
  auto Procedure = cast(FallbackType)GetProcAddress(ModuleHandle, ProcedureName.ptr);
  return Procedure ? Procedure : Fallback;
}

auto Win32LoadXInput()
{
  foreach(Candidate; Win32XInputDllCandidates)
  {
    auto LibraryHandle = LoadLibraryA(Candidate.ptr);
    if(LibraryHandle)
    {
      XInputGetState              = Win32TryLoadProcedure(LibraryHandle, "XInputGetState",              XInputGetState);
      XInputSetState              = Win32TryLoadProcedure(LibraryHandle, "XInputSetState",              XInputSetState);
      XInputGetCapabilities       = Win32TryLoadProcedure(LibraryHandle, "XInputGetCapabilities",       XInputGetCapabilities);
      XInputGetAudioDeviceIds     = Win32TryLoadProcedure(LibraryHandle, "XInputGetAudioDeviceIds",     XInputGetAudioDeviceIds);
      XInputGetBatteryInformation = Win32TryLoadProcedure(LibraryHandle, "XInputGetBatteryInformation", XInputGetBatteryInformation);
      XInputGetKeystroke          = Win32TryLoadProcedure(LibraryHandle, "XInputGetKeystroke",          XInputGetKeystroke);
      return true;
    }
  }

  Log.Info("Failed to load XInput.".MakeSpan);
  return false;
}
