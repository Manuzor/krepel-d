module krepel.win32.directx.xinput;

public import core.sys.windows.windows;
public import directx.xinput;

version(XInput_RuntimeLinking)
{
  import krepel.log;

  bool LoadXInput()
  {
    string[3] DLLsToTry = [
      "xinput1_4.dll",
      "xinput9_1_0.dll",
      "xinput1_3.dll",
    ];

    foreach(DLLName; DLLsToTry)
    {
      auto DLL = LoadLibraryA(DLLName.ptr);
      if(DLL)
      {
        void* RawFunctionPointer;

        RawFunctionPointer = GetProcAddress(DLL, "XInputGetState".ptr);
        if(RawFunctionPointer) XInputGetState = cast(typeof(XInputGetState))RawFunctionPointer;

        RawFunctionPointer = GetProcAddress(DLL, "XInputSetState".ptr);
        if(RawFunctionPointer) XInputSetState = cast(typeof(XInputSetState))RawFunctionPointer;

        RawFunctionPointer = GetProcAddress(DLL, "XInputGetCapabilities".ptr);
        if(RawFunctionPointer) XInputGetCapabilities = cast(typeof(XInputGetCapabilities))RawFunctionPointer;

        RawFunctionPointer = GetProcAddress(DLL, "XInputGetAudioDeviceIds".ptr);
        if(RawFunctionPointer) XInputGetAudioDeviceIds = cast(typeof(XInputGetAudioDeviceIds))RawFunctionPointer;

        RawFunctionPointer = GetProcAddress(DLL, "XInputGetBatteryInformation".ptr);
        if(RawFunctionPointer) XInputGetBatteryInformation = cast(typeof(XInputGetBatteryInformation))RawFunctionPointer;

        RawFunctionPointer = GetProcAddress(DLL, "XInputGetKeystroke".ptr);
        if(RawFunctionPointer) XInputGetKeystroke = cast(typeof(XInputGetKeystroke))RawFunctionPointer;

        Log.Info("Successfully loaded library: %s", DLLName);

        return true;
      }
      else
      {
        Log.Warning("Failed to load library: %s", DLLName);
      }
    }

    Log.Failure("Unable to load XInput.");
    return false;
  }
}

