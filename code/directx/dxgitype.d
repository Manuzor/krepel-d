// Original file name: dxgitype.idl
// Conversion date: 2016-Mar-17 19:01:39.3741388

module directx.dxgitype;

version(Windows):

import core.sys.windows.windows;

private mixin template DEFINE_GUID(ComType, alias IIDString)
{
  // Format of a UUID:
  // [0  1  2  3  4  5  6  7]  8  [9  10 11 12] 13 [14 15 16 17] 18 [19 20] [21 22] 23 [24 25] [26 27] [28 29] [30 31] [32 33] [34 35]
  // [x  x  x  x  x  x  x  x]  -  [x  x  x  x ] -  [x  x  x  x ] -  [x  x ] [x  x ]  - [x  x ] [x  x ] [x  x ] [x  x ] [x  x ] [x  x ]
  static assert(IIDString.length == 36, "Malformed UUID string:\nGot:             %-36s\nExpected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".Format(IIDString));
  static assert(IIDString[8]  == '-',   "Malformed UUID string:\nGot:             %-36s\nExpected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".Format(IIDString));
  static assert(IIDString[13] == '-',   "Malformed UUID string:\nGot:             %-36s\nExpected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".Format(IIDString));
  static assert(IIDString[18] == '-',   "Malformed UUID string:\nGot:             %-36s\nExpected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".Format(IIDString));
  static assert(IIDString[23] == '-',   "Malformed UUID string:\nGot:             %-36s\nExpected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".Format(IIDString));

  private import std.format : format;

  mixin(format("immutable IID IID_%s "
               "= { 0x%s, 0x%s, 0x%s, [0x%s, 0x%s, 0x%s, 0x%s, 0x%s, 0x%s, 0x%s, 0x%s] };",
               ComType.stringof,
               IIDString[ 0 ..  8], // IID.Data1    <=> [xxxxxxxx]-xxxx-xxxx-xxxx-xxxxxxxxxxxx
               IIDString[ 9 .. 13], // IID.Data2    <=> xxxxxxxx-[xxxx]-xxxx-xxxx-xxxxxxxxxxxx
               IIDString[14 .. 18], // IID.Data3    <=> xxxxxxxx-xxxx-[xxxx]-xxxx-xxxxxxxxxxxx
               IIDString[19 .. 21], // IID.Data4[0] <=> xxxxxxxx-xxxx-xxxx-[xx]xx-xxxxxxxxxxxx
               IIDString[21 .. 23], // IID.Data4[1] <=> xxxxxxxx-xxxx-xxxx-xx[xx]-xxxxxxxxxxxx
               IIDString[24 .. 26], // IID.Data4[2] <=> xxxxxxxx-xxxx-xxxx-xxxx-[xx]xxxxxxxxxx
               IIDString[26 .. 28], // IID.Data4[3] <=> xxxxxxxx-xxxx-xxxx-xxxx-xx[xx]xxxxxxxx
               IIDString[28 .. 30], // IID.Data4[4] <=> xxxxxxxx-xxxx-xxxx-xxxx-xxxx[xx]xxxxxx
               IIDString[30 .. 32], // IID.Data4[5] <=> xxxxxxxx-xxxx-xxxx-xxxx-xxxxxx[xx]xxxx
               IIDString[32 .. 34], // IID.Data4[6] <=> xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx[xx]xx
               IIDString[34 .. 36], // IID.Data4[7] <=> xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx[xx]
               ));

  /// Example: uuidof!IDXGIObject
  ref auto uuidof(T)() if(is(T == ComType)) { mixin("return IID_%s;".format(ComType.stringof)); }

  /// Example:
  ///   IDXGIObject Object = /* ... */;
  ///   auto Foo = Object.uuidof;
  ref auto uuidof(T)(auto ref in T) if(is(T == ComType)) { return uuidof!ComType; }
}

// Note: Everything below this line is automatically converted and likely to
// contain errors. You should manually check it for validity, if you care
// enough.


import directx.dxgiformat;

// TODO: Remove this once dmd includes directx errors in
// core.sys.windows.winerror.
public import directx.dxerror;

struct DXGI_RGB
{
  float Red;
  float Green;
  float Blue;
}

struct D3DCOLORVALUE
{
  float r;
  float g;
  float b;
  float a;
}

struct DXGI_RGBA
{
  float r;
  float g;
  float b;
  float a;
}

struct DXGI_GAMMA_CONTROL
{
  DXGI_RGB Scale;
  DXGI_RGB Offset;
  DXGI_RGB[1025] GammaCurve;
}

struct DXGI_GAMMA_CONTROL_CAPABILITIES
{
  BOOL ScaleAndOffsetSupported;
  float MaxConvertedValue;
  float MinConvertedValue;
  UINT NumGammaControlPoints;
  float[1025] ControlPointPositions;
}

struct DXGI_RATIONAL
{
  UINT Numerator;
  UINT Denominator;
}

alias DXGI_MODE_SCANLINE_ORDER = int;
enum : DXGI_MODE_SCANLINE_ORDER
{
  DXGI_MODE_SCANLINE_ORDER_UNSPECIFIED       = 0,
  DXGI_MODE_SCANLINE_ORDER_PROGRESSIVE       = 1,
  DXGI_MODE_SCANLINE_ORDER_UPPER_FIELD_FIRST = 2,
  DXGI_MODE_SCANLINE_ORDER_LOWER_FIELD_FIRST = 3,
}

alias DXGI_MODE_SCALING = int;
enum : DXGI_MODE_SCALING
{
  DXGI_MODE_SCALING_UNSPECIFIED = 0,
  DXGI_MODE_SCALING_CENTERED    = 1,
  DXGI_MODE_SCALING_STRETCHED   = 2,
}

alias DXGI_MODE_ROTATION = int;
enum : DXGI_MODE_ROTATION
{
  DXGI_MODE_ROTATION_UNSPECIFIED = 0,
  DXGI_MODE_ROTATION_IDENTITY    = 1,
  DXGI_MODE_ROTATION_ROTATE90    = 2,
  DXGI_MODE_ROTATION_ROTATE180   = 3,
  DXGI_MODE_ROTATION_ROTATE270   = 4,
}

struct DXGI_MODE_DESC
{
  UINT Width;
  UINT Height;
  DXGI_RATIONAL RefreshRate;
  DXGI_FORMAT Format;
  DXGI_MODE_SCANLINE_ORDER ScanlineOrdering;
  DXGI_MODE_SCALING Scaling;
}

enum DXGI_STANDARD_MULTISAMPLE_QUALITY_PATTERN = 0xffffffff;

enum DXGI_CENTER_MULTISAMPLE_QUALITY_PATTERN = 0xfffffffe;

struct DXGI_SAMPLE_DESC
{
  UINT Count;
  UINT Quality;
}

alias DXGI_COLOR_SPACE_TYPE = int;
enum : DXGI_COLOR_SPACE_TYPE
{
  DXGI_COLOR_SPACE_RGB_FULL_G22_NONE_P709        = 0,
  DXGI_COLOR_SPACE_RGB_FULL_G10_NONE_P709        = 1,
  DXGI_COLOR_SPACE_RGB_STUDIO_G22_NONE_P709      = 2,
  DXGI_COLOR_SPACE_RGB_STUDIO_G22_NONE_P2020     = 3,
  DXGI_COLOR_SPACE_RESERVED                      = 4,
  DXGI_COLOR_SPACE_YCBCR_FULL_G22_NONE_P709_X601 = 5,
  DXGI_COLOR_SPACE_YCBCR_STUDIO_G22_LEFT_P601    = 6,
  DXGI_COLOR_SPACE_YCBCR_FULL_G22_LEFT_P601      = 7,
  DXGI_COLOR_SPACE_YCBCR_STUDIO_G22_LEFT_P709    = 8,
  DXGI_COLOR_SPACE_YCBCR_FULL_G22_LEFT_P709      = 9,
  DXGI_COLOR_SPACE_YCBCR_STUDIO_G22_LEFT_P2020   = 10,
  DXGI_COLOR_SPACE_YCBCR_FULL_G22_LEFT_P2020     = 11,
  DXGI_COLOR_SPACE_CUSTOM                        = 0xFFFFFFFF,
}

struct DXGI_JPEG_DC_HUFFMAN_TABLE
{
  BYTE[12] CodeCounts;
  BYTE[12] CodeValues;
}

struct DXGI_JPEG_AC_HUFFMAN_TABLE
{
  BYTE[16] CodeCounts;
  BYTE[162] CodeValues;
}

struct DXGI_JPEG_QUANTIZATION_TABLE
{
  BYTE[64] Elements;
}
