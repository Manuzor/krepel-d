module krepel.win32.directx.uuidof;

import Meta = krepel.meta;

/// Example: uuidof!IDXGIObject
auto uuidof(Type)()
{
  static import std.format;
  enum UnformattedCode = q{
    static import %1$s;
    return &%1$s.IID_%2$s;
  };
  enum Code = std.format.format(UnformattedCode,
                                Meta.ModuleNameOf!Type,
                                Type.stringof);
  //pragma(msg, Code);
  mixin(Code);
}
