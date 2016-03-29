module krepel.win32.directx.dxgi;

public import core.sys.windows.windows;
public import directx.dxgi;

version(DXGI_RuntimeLinking)
{
  import krepel.log;

  bool LoadDXGI()
  {
    string[1] DLLsToTry = [
      "dxgi.dll"
    ];

    foreach(DLLName; DLLsToTry)
    {
      auto DLL = LoadLibraryA(DLLName.ptr);
      if(DLL)
      {
        void* RawFunctionPointer;

        RawFunctionPointer = GetProcAddress(DLL, "CreateDXGIFactory".ptr);
        if(RawFunctionPointer) CreateDXGIFactory = cast(typeof(CreateDXGIFactory))RawFunctionPointer;

        RawFunctionPointer = GetProcAddress(DLL, "CreateDXGIFactory1".ptr);
        if(RawFunctionPointer) CreateDXGIFactory1 = cast(typeof(CreateDXGIFactory1))RawFunctionPointer;

        return true;
      }
      else
      {
        Log.Warning("Failed to load library: %s", DLLName);
      }
    }

    Log.Failure("Unable to load DXGI.");
    return false;
  }
}
