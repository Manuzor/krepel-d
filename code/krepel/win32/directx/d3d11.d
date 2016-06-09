module krepel.win32.directx.d3d11;

public import core.sys.windows.windows;
public import directx.d3d11_1;
public import directx.d3dcompiler;
public import directx.d3d11sdklayers;

version(D3D11_RuntimeLinking)
{
  import krepel.log;
  import krepel.container : Only;

  bool LoadD3D11()
  {
    foreach(DLLName; Only("d3d11.dll"))
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

  bool LoadD3D11ShaderCompiler()
  {
    foreach(DLLName; Only("d3dcompiler_47.dll"))
    {
      auto DLL = LoadLibraryA(DLLName.ptr);
      if(DLL)
      {
        void* RawFunctionPointer;

        RawFunctionPointer = GetProcAddress(DLL, "D3DCompileFromFile".ptr);
        if(RawFunctionPointer) D3DCompileFromFile = cast(typeof(D3DCompileFromFile))RawFunctionPointer;

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
