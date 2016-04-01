module krepel.win32.directx.d3d11;

public import core.sys.windows.windows;
public import directx.d3d11_1;

version(D3D11_RuntimeLinking)
{
  import krepel.log;

  bool LoadD3D11()
  {
    string[1] DLLsToTry = [
      "d3d11.dll"
    ];

    foreach(DLLName; DLLsToTry)
    {
      auto DLL = LoadLibraryA(DLLName.ptr);
      if(DLL)
      {
        void* RawFunctionPointer;

        RawFunctionPointer = GetProcAddress(DLL, "D3D11CreateDevice".ptr);
        if(RawFunctionPointer) D3D11CreateDevice = cast(typeof(D3D11CreateDevice))RawFunctionPointer;

        RawFunctionPointer = GetProcAddress(DLL, "D3D11CreateDeviceAndSwapChain".ptr);
        if(RawFunctionPointer) D3D11CreateDeviceAndSwapChain = cast(typeof(D3D11CreateDeviceAndSwapChain))RawFunctionPointer;

        Log.Info("Successfully loaded library: %s", DLLName);

        return true;
      }
      else
      {
        Log.Warning("Failed to load library: %s", DLLName);
      }
    }

    Log.Failure("Unable to load D3D11.");
    return false;
  }
}


