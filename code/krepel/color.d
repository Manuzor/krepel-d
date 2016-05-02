module krepel.color;

import krepel.math;
import krepel.algorithm;

struct ColorLinear
{
  union
  {
    struct { float R, G, B, A; };
    float[4] Data;
  }

  Vector4 opCast(To : Vector4)() const
  {
    return Vector4(Data);
  }

  ColorLinearUB opCast(To : ColorLinearUB)() const
  {
    typeof(return) Result = void;
    Result.R = cast(ubyte)Min(255.0f, (this.R * 255.0f) + 0.5f);
    Result.G = cast(ubyte)Min(255.0f, (this.G * 255.0f) + 0.5f);
    Result.B = cast(ubyte)Min(255.0f, (this.B * 255.0f) + 0.5f);
    Result.A = cast(ubyte)Min(255.0f, (this.A * 255.0f) + 0.5f);

    return Result;
  }

  Vector4 opCast(To : ColorGammaUB)() const
  {
    const GammaR = ConvertFromLinearToGamma(this.R);
    const GammaG = ConvertFromLinearToGamma(this.G);
    const GammaB = ConvertFromLinearToGamma(this.B);

    typeof(return) Result = void;
    Result.R = cast(ubyte)Min(255.0f, (GammaR * 255.0f) + 0.5f);
    Result.G = cast(ubyte)Min(255.0f, (GammaG * 255.0f) + 0.5f);
    Result.B = cast(ubyte)Min(255.0f, (GammaB * 255.0f) + 0.5f);
    Result.A = cast(ubyte)Min(255.0f, (this.A * 255.0f) + 0.5f);

    return Result;
  }

  // http://en.wikipedia.org/wiki/Luminance_%28relative%29
  @property float Luminance() const
  {
    return 0.2126f * this.R + 0.7152f * this.G + 0.0722f * this.B;
  }

  @property bool IsNormalized() const
  {
    return this.R <= 1.0f && this.G <= 1.0f && this.B <= 1.0f && this.A <= 1.0f &&
           this.R >= 0.0f && this.G >= 0.0f && this.B >= 0.0f && this.A >= 0.0f;
  }

  @property bool IsNaN() const
  {
    return this.R.IsNaN || this.G.IsNaN || this.B.IsNaN || this.A.IsNaN;
  }
}

static assert(ColorLinear.sizeof == 16);


struct ColorLinearUB
{
  union
  {
    struct { ubyte R, G, B, A; };
    ubyte[4] Data;
  }

  ColorLinear opCast(To : ColorLinear)() const
  {
    enum Factor = 1.0f / 255.0f;
    typeof(return) Result = void;
    Result.R = this.R * Factor;
    Result.G = this.G * Factor;
    Result.B = this.B * Factor;
    Result.A = this.A * Factor;
    return Result;
  }
}

static assert(ColorLinearUB.sizeof == 4);


struct ColorGammaUB
{
  union
  {
    struct { ubyte R, G, B, A; };
    ubyte[4] Data;
  }

  ColorLinear opCast(To : ColorLinear)() const
  {
    enum Factor = 1.0f / 255.0f;

    typeof(return) Result = void;
    Result.R = ConvertFromGammaToLinear(this.R * Factor);
    Result.G = ConvertFromGammaToLinear(this.G * Factor);
    Result.B = ConvertFromGammaToLinear(this.B * Factor);
    Result.A = this.A * Factor;

    return Result;
  }
}

static assert(ColorGammaUB.sizeof == 4);


@property ColorLinear InvertedColor(in ref ColorLinear Color)
{
  assert(Color.IsNormalized);
  return ColorLinear(1.0f - Color.R, 1.0f - Color.G, 1.0f - Color.B, 1.0f - Color.A);
}

ColorLinear ComplementaryColor(in ref ColorLinear Color)
{
  float Hue, Saturation, Value;
  Color.ExtractLinearHSV(Hue, Saturation, Value);

  auto Shifted = ColorLinearFromHSV((Hue + 180.0f) % 360.0f, Saturation, Value);
  Shifted.A = Color.A;
  return Shifted;
}

// http://en.literateprograms.org/RGB_to_HSV_color_space_conversion_%28C%29
void ExtractLinearHSV(in ref ColorLinear Source, out float Hue, out float Saturation, out float Value)
{
  Value = Max(Source.R, Source.G, Source.B);

  if(Value.NearlyEquals(0)) return;

  const ValueInverse = 1.0f / Value;
  float Norm_R = Source.R * ValueInverse;
  float Norm_G = Source.G * ValueInverse;
  float Norm_B = Source.B * ValueInverse;
  float RGB_Min = Min(Norm_R, Norm_G, Norm_B);
  float RGB_Max = Max(Norm_R, Norm_G, Norm_B);

  Saturation = RGB_Max - RGB_Min;

  if(Saturation == 0) return;

  // Normalize saturation
  const RGB_Delta_Inverse = 1.0f / Saturation;
  Norm_R = (Norm_R - RGB_Min) * RGB_Delta_Inverse;
  Norm_G = (Norm_G - RGB_Min) * RGB_Delta_Inverse;
  Norm_B = (Norm_B - RGB_Min) * RGB_Delta_Inverse;

  // Hue
  if(RGB_Max == Norm_R)
  {
    Hue = 60.0f * (Norm_G - Norm_B);

    if(Hue < 0) Hue += 360.0f;
  }
  else if(RGB_Max == Norm_G)
  {
    Hue = 120.0f + 60.0f * (Norm_B - Norm_R);
  }
  else
  {
    Hue = 240.0f + 60.0f * (Norm_R - Norm_G);
  }
}

// http://www.rapidtables.com/convert/color/hsv-to-rgb.htm
ColorLinear ColorLinearFromHSV(float Hue, float Saturation, float Value)
{
  assert(Hue <= 360 && Hue >= 0, "HSV hue value is in invalid range.");
  assert(Saturation <= 1 && Value >= 0, "HSV saturation value is in invalid range.");
  assert(Value <= 1 && Value >= 0, "HSV value is in invalid range.");

  ColorLinear Result;

  float C = Saturation * Value;
  float X = C * (1.0f - Abs(((Hue / 60.0f) % 2) - 1.0f));
  float M = Value - C;

  Result.A = 1.0f;

  if (Hue < 60)
  {
    Result.R = C + M;
    Result.G = X + M;
    Result.B = 0 + M;
  }
  else if (Hue < 120)
  {
    Result.R = X + M;
    Result.G = C + M;
    Result.B = 0 + M;
  }
  else if (Hue < 180)
  {
    Result.R = 0 + M;
    Result.G = C + M;
    Result.B = X + M;
  }
  else if (Hue < 240)
  {
    Result.R = 0 + M;
    Result.G = X + M;
    Result.B = C + M;
  }
  else if (Hue < 300)
  {
    Result.R = X + M;
    Result.G = 0 + M;
    Result.B = C + M;
  }
  else
  {
    Result.R = C + M;
    Result.G = 0 + M;
    Result.B = X + M;
  }

  return Result;
}

float ConvertFromGammaToLinear(in float Gamma)
{
  auto Linear = Gamma <= 0.04045f ? Gamma / 12.92f : ((Gamma + 0.055f) / 1.055f) ^^ 2.4f;
  return Linear;
}

float ConvertFromLinearToGamma(in float Linear)
{
  auto Gamma = Linear <= 0.0031308f ? 12.92f * Linear : 1.055f * (Linear ^^ 1.0f / 2.4f) - 0.055f;
  return Gamma;
}

/// Defines a set of predefined named colors.
interface Colors
{
static @property:
  ColorLinear AliceBlue()            { return cast(ColorLinear)ColorGammaUB(0xF0, 0xF8, 0xFF, 0xFF); };
  ColorLinear AntiqueWhite()         { return cast(ColorLinear)ColorGammaUB(0xFA, 0xEB, 0xD7, 0xFF); };
  ColorLinear Aqua()                 { return cast(ColorLinear)ColorGammaUB(0x00, 0xFF, 0xFF, 0xFF); };
  ColorLinear Aquamarine()           { return cast(ColorLinear)ColorGammaUB(0x7F, 0xFF, 0xD4, 0xFF); };
  ColorLinear Azure()                { return cast(ColorLinear)ColorGammaUB(0xF0, 0xFF, 0xFF, 0xFF); };
  ColorLinear Beige()                { return cast(ColorLinear)ColorGammaUB(0xF5, 0xF5, 0xDC, 0xFF); };
  ColorLinear Bisque()               { return cast(ColorLinear)ColorGammaUB(0xFF, 0xE4, 0xC4, 0xFF); };
  ColorLinear Black()                { return cast(ColorLinear)ColorGammaUB(0x00, 0x00, 0x00, 0xFF); };
  ColorLinear BlanchedAlmond()       { return cast(ColorLinear)ColorGammaUB(0xFF, 0xEB, 0xCD, 0xFF); };
  ColorLinear Blue()                 { return cast(ColorLinear)ColorGammaUB(0x00, 0x00, 0xFF, 0xFF); };
  ColorLinear BlueViolet()           { return cast(ColorLinear)ColorGammaUB(0x8A, 0x2B, 0xE2, 0xFF); };
  ColorLinear Brown()                { return cast(ColorLinear)ColorGammaUB(0xA5, 0x2A, 0x2A, 0xFF); };
  ColorLinear BurlyWood()            { return cast(ColorLinear)ColorGammaUB(0xDE, 0xB8, 0x87, 0xFF); };
  ColorLinear CadetBlue()            { return cast(ColorLinear)ColorGammaUB(0x5F, 0x9E, 0xA0, 0xFF); };
  ColorLinear Chartreuse()           { return cast(ColorLinear)ColorGammaUB(0x7F, 0xFF, 0x00, 0xFF); };
  ColorLinear Chocolate()            { return cast(ColorLinear)ColorGammaUB(0xD2, 0x69, 0x1E, 0xFF); };
  ColorLinear Coral()                { return cast(ColorLinear)ColorGammaUB(0xFF, 0x7F, 0x50, 0xFF); };
  ColorLinear CornflowerBlue()       { return cast(ColorLinear)ColorGammaUB(0x64, 0x95, 0xED, 0xFF); };
  ColorLinear Cornsilk()             { return cast(ColorLinear)ColorGammaUB(0xFF, 0xF8, 0xDC, 0xFF); };
  ColorLinear Crimson()              { return cast(ColorLinear)ColorGammaUB(0xDC, 0x14, 0x3C, 0xFF); };
  ColorLinear Cyan()                 { return cast(ColorLinear)ColorGammaUB(0x00, 0xFF, 0xFF, 0xFF); };
  ColorLinear DarkBlue()             { return cast(ColorLinear)ColorGammaUB(0x00, 0x00, 0x8B, 0xFF); };
  ColorLinear DarkCyan()             { return cast(ColorLinear)ColorGammaUB(0x00, 0x8B, 0x8B, 0xFF); };
  ColorLinear DarkGoldenRod()        { return cast(ColorLinear)ColorGammaUB(0xB8, 0x86, 0x0B, 0xFF); };
  ColorLinear DarkGray()             { return cast(ColorLinear)ColorGammaUB(0xA9, 0xA9, 0xA9, 0xFF); };
  ColorLinear DarkGreen()            { return cast(ColorLinear)ColorGammaUB(0x00, 0x64, 0x00, 0xFF); };
  ColorLinear DarkKhaki()            { return cast(ColorLinear)ColorGammaUB(0xBD, 0xB7, 0x6B, 0xFF); };
  ColorLinear DarkMagenta()          { return cast(ColorLinear)ColorGammaUB(0x8B, 0x00, 0x8B, 0xFF); };
  ColorLinear DarkOliveGreen()       { return cast(ColorLinear)ColorGammaUB(0x55, 0x6B, 0x2F, 0xFF); };
  ColorLinear DarkOrange()           { return cast(ColorLinear)ColorGammaUB(0xFF, 0x8C, 0x00, 0xFF); };
  ColorLinear DarkOrchid()           { return cast(ColorLinear)ColorGammaUB(0x99, 0x32, 0xCC, 0xFF); };
  ColorLinear DarkRed()              { return cast(ColorLinear)ColorGammaUB(0x8B, 0x00, 0x00, 0xFF); };
  ColorLinear DarkSalmon()           { return cast(ColorLinear)ColorGammaUB(0xE9, 0x96, 0x7A, 0xFF); };
  ColorLinear DarkSeaGreen()         { return cast(ColorLinear)ColorGammaUB(0x8F, 0xBC, 0x8F, 0xFF); };
  ColorLinear DarkSlateBlue()        { return cast(ColorLinear)ColorGammaUB(0x48, 0x3D, 0x8B, 0xFF); };
  ColorLinear DarkSlateGray()        { return cast(ColorLinear)ColorGammaUB(0x2F, 0x4F, 0x4F, 0xFF); };
  ColorLinear DarkTurquoise()        { return cast(ColorLinear)ColorGammaUB(0x00, 0xCE, 0xD1, 0xFF); };
  ColorLinear DarkViolet()           { return cast(ColorLinear)ColorGammaUB(0x94, 0x00, 0xD3, 0xFF); };
  ColorLinear DeepPink()             { return cast(ColorLinear)ColorGammaUB(0xFF, 0x14, 0x93, 0xFF); };
  ColorLinear DeepSkyBlue()          { return cast(ColorLinear)ColorGammaUB(0x00, 0xBF, 0xFF, 0xFF); };
  ColorLinear DimGray()              { return cast(ColorLinear)ColorGammaUB(0x69, 0x69, 0x69, 0xFF); };
  ColorLinear DodgerBlue()           { return cast(ColorLinear)ColorGammaUB(0x1E, 0x90, 0xFF, 0xFF); };
  ColorLinear FireBrick()            { return cast(ColorLinear)ColorGammaUB(0xB2, 0x22, 0x22, 0xFF); };
  ColorLinear FloralWhite()          { return cast(ColorLinear)ColorGammaUB(0xFF, 0xFA, 0xF0, 0xFF); };
  ColorLinear ForestGreen()          { return cast(ColorLinear)ColorGammaUB(0x22, 0x8B, 0x22, 0xFF); };
  ColorLinear Fuchsia()              { return cast(ColorLinear)ColorGammaUB(0xFF, 0x00, 0xFF, 0xFF); };
  ColorLinear Gainsboro()            { return cast(ColorLinear)ColorGammaUB(0xDC, 0xDC, 0xDC, 0xFF); };
  ColorLinear GhostWhite()           { return cast(ColorLinear)ColorGammaUB(0xF8, 0xF8, 0xFF, 0xFF); };
  ColorLinear Gold()                 { return cast(ColorLinear)ColorGammaUB(0xFF, 0xD7, 0x00, 0xFF); };
  ColorLinear GoldenRod()            { return cast(ColorLinear)ColorGammaUB(0xDA, 0xA5, 0x20, 0xFF); };
  ColorLinear Gray()                 { return cast(ColorLinear)ColorGammaUB(0x80, 0x80, 0x80, 0xFF); };
  ColorLinear Green()                { return cast(ColorLinear)ColorGammaUB(0x00, 0x80, 0x00, 0xFF); };
  ColorLinear GreenYellow()          { return cast(ColorLinear)ColorGammaUB(0xAD, 0xFF, 0x2F, 0xFF); };
  ColorLinear HoneyDew()             { return cast(ColorLinear)ColorGammaUB(0xF0, 0xFF, 0xF0, 0xFF); };
  ColorLinear HotPink()              { return cast(ColorLinear)ColorGammaUB(0xFF, 0x69, 0xB4, 0xFF); };
  ColorLinear IndianRed()            { return cast(ColorLinear)ColorGammaUB(0xCD, 0x5C, 0x5C, 0xFF); };
  ColorLinear Indigo()               { return cast(ColorLinear)ColorGammaUB(0x4B, 0x00, 0x82, 0xFF); };
  ColorLinear Ivory()                { return cast(ColorLinear)ColorGammaUB(0xFF, 0xFF, 0xF0, 0xFF); };
  ColorLinear Khaki()                { return cast(ColorLinear)ColorGammaUB(0xF0, 0xE6, 0x8C, 0xFF); };
  ColorLinear Lavender()             { return cast(ColorLinear)ColorGammaUB(0xE6, 0xE6, 0xFA, 0xFF); };
  ColorLinear LavenderBlush()        { return cast(ColorLinear)ColorGammaUB(0xFF, 0xF0, 0xF5, 0xFF); };
  ColorLinear LawnGreen()            { return cast(ColorLinear)ColorGammaUB(0x7C, 0xFC, 0x00, 0xFF); };
  ColorLinear LemonChiffon()         { return cast(ColorLinear)ColorGammaUB(0xFF, 0xFA, 0xCD, 0xFF); };
  ColorLinear LightBlue()            { return cast(ColorLinear)ColorGammaUB(0xAD, 0xD8, 0xE6, 0xFF); };
  ColorLinear LightCoral()           { return cast(ColorLinear)ColorGammaUB(0xF0, 0x80, 0x80, 0xFF); };
  ColorLinear LightCyan()            { return cast(ColorLinear)ColorGammaUB(0xE0, 0xFF, 0xFF, 0xFF); };
  ColorLinear LightGoldenRodYellow() { return cast(ColorLinear)ColorGammaUB(0xFA, 0xFA, 0xD2, 0xFF); };
  ColorLinear LightGray()            { return cast(ColorLinear)ColorGammaUB(0xD3, 0xD3, 0xD3, 0xFF); };
  ColorLinear LightGreen()           { return cast(ColorLinear)ColorGammaUB(0x90, 0xEE, 0x90, 0xFF); };
  ColorLinear LightPink()            { return cast(ColorLinear)ColorGammaUB(0xFF, 0xB6, 0xC1, 0xFF); };
  ColorLinear LightSalmon()          { return cast(ColorLinear)ColorGammaUB(0xFF, 0xA0, 0x7A, 0xFF); };
  ColorLinear LightSeaGreen()        { return cast(ColorLinear)ColorGammaUB(0x20, 0xB2, 0xAA, 0xFF); };
  ColorLinear LightSkyBlue()         { return cast(ColorLinear)ColorGammaUB(0x87, 0xCE, 0xFA, 0xFF); };
  ColorLinear LightSlateGray()       { return cast(ColorLinear)ColorGammaUB(0x77, 0x88, 0x99, 0xFF); };
  ColorLinear LightSteelBlue()       { return cast(ColorLinear)ColorGammaUB(0xB0, 0xC4, 0xDE, 0xFF); };
  ColorLinear LightYellow()          { return cast(ColorLinear)ColorGammaUB(0xFF, 0xFF, 0xE0, 0xFF); };
  ColorLinear Lime()                 { return cast(ColorLinear)ColorGammaUB(0x00, 0xFF, 0x00, 0xFF); };
  ColorLinear LimeGreen()            { return cast(ColorLinear)ColorGammaUB(0x32, 0xCD, 0x32, 0xFF); };
  ColorLinear Linen()                { return cast(ColorLinear)ColorGammaUB(0xFA, 0xF0, 0xE6, 0xFF); };
  ColorLinear Magenta()              { return cast(ColorLinear)ColorGammaUB(0xFF, 0x00, 0xFF, 0xFF); };
  ColorLinear Maroon()               { return cast(ColorLinear)ColorGammaUB(0x80, 0x00, 0x00, 0xFF); };
  ColorLinear MediumAquaMarine()     { return cast(ColorLinear)ColorGammaUB(0x66, 0xCD, 0xAA, 0xFF); };
  ColorLinear MediumBlue()           { return cast(ColorLinear)ColorGammaUB(0x00, 0x00, 0xCD, 0xFF); };
  ColorLinear MediumOrchid()         { return cast(ColorLinear)ColorGammaUB(0xBA, 0x55, 0xD3, 0xFF); };
  ColorLinear MediumPurple()         { return cast(ColorLinear)ColorGammaUB(0x93, 0x70, 0xDB, 0xFF); };
  ColorLinear MediumSeaGreen()       { return cast(ColorLinear)ColorGammaUB(0x3C, 0xB3, 0x71, 0xFF); };
  ColorLinear MediumSlateBlue()      { return cast(ColorLinear)ColorGammaUB(0x7B, 0x68, 0xEE, 0xFF); };
  ColorLinear MediumSpringGreen()    { return cast(ColorLinear)ColorGammaUB(0x00, 0xFA, 0x9A, 0xFF); };
  ColorLinear MediumTurquoise()      { return cast(ColorLinear)ColorGammaUB(0x48, 0xD1, 0xCC, 0xFF); };
  ColorLinear MediumVioletRed()      { return cast(ColorLinear)ColorGammaUB(0xC7, 0x15, 0x85, 0xFF); };
  ColorLinear MidnightBlue()         { return cast(ColorLinear)ColorGammaUB(0x19, 0x19, 0x70, 0xFF); };
  ColorLinear MintCream()            { return cast(ColorLinear)ColorGammaUB(0xF5, 0xFF, 0xFA, 0xFF); };
  ColorLinear MistyRose()            { return cast(ColorLinear)ColorGammaUB(0xFF, 0xE4, 0xE1, 0xFF); };
  ColorLinear Moccasin()             { return cast(ColorLinear)ColorGammaUB(0xFF, 0xE4, 0xB5, 0xFF); };
  ColorLinear NavajoWhite()          { return cast(ColorLinear)ColorGammaUB(0xFF, 0xDE, 0xAD, 0xFF); };
  ColorLinear Navy()                 { return cast(ColorLinear)ColorGammaUB(0x00, 0x00, 0x80, 0xFF); };
  ColorLinear OldLace()              { return cast(ColorLinear)ColorGammaUB(0xFD, 0xF5, 0xE6, 0xFF); };
  ColorLinear Olive()                { return cast(ColorLinear)ColorGammaUB(0x80, 0x80, 0x00, 0xFF); };
  ColorLinear OliveDrab()            { return cast(ColorLinear)ColorGammaUB(0x6B, 0x8E, 0x23, 0xFF); };
  ColorLinear Orange()               { return cast(ColorLinear)ColorGammaUB(0xFF, 0xA5, 0x00, 0xFF); };
  ColorLinear OrangeRed()            { return cast(ColorLinear)ColorGammaUB(0xFF, 0x45, 0x00, 0xFF); };
  ColorLinear Orchid()               { return cast(ColorLinear)ColorGammaUB(0xDA, 0x70, 0xD6, 0xFF); };
  ColorLinear PaleGoldenRod()        { return cast(ColorLinear)ColorGammaUB(0xEE, 0xE8, 0xAA, 0xFF); };
  ColorLinear PaleGreen()            { return cast(ColorLinear)ColorGammaUB(0x98, 0xFB, 0x98, 0xFF); };
  ColorLinear PaleTurquoise()        { return cast(ColorLinear)ColorGammaUB(0xAF, 0xEE, 0xEE, 0xFF); };
  ColorLinear PaleVioletRed()        { return cast(ColorLinear)ColorGammaUB(0xDB, 0x70, 0x93, 0xFF); };
  ColorLinear PapayaWhip()           { return cast(ColorLinear)ColorGammaUB(0xFF, 0xEF, 0xD5, 0xFF); };
  ColorLinear PeachPuff()            { return cast(ColorLinear)ColorGammaUB(0xFF, 0xDA, 0xB9, 0xFF); };
  ColorLinear Peru()                 { return cast(ColorLinear)ColorGammaUB(0xCD, 0x85, 0x3F, 0xFF); };
  ColorLinear Pink()                 { return cast(ColorLinear)ColorGammaUB(0xFF, 0xC0, 0xCB, 0xFF); };
  ColorLinear Plum()                 { return cast(ColorLinear)ColorGammaUB(0xDD, 0xA0, 0xDD, 0xFF); };
  ColorLinear PowderBlue()           { return cast(ColorLinear)ColorGammaUB(0xB0, 0xE0, 0xE6, 0xFF); };
  ColorLinear Purple()               { return cast(ColorLinear)ColorGammaUB(0x80, 0x00, 0x80, 0xFF); };
  ColorLinear RebeccaPurple()        { return cast(ColorLinear)ColorGammaUB(0x66, 0x33, 0x99, 0xFF); };
  ColorLinear Red()                  { return cast(ColorLinear)ColorGammaUB(0xFF, 0x00, 0x00, 0xFF); };
  ColorLinear RosyBrown()            { return cast(ColorLinear)ColorGammaUB(0xBC, 0x8F, 0x8F, 0xFF); };
  ColorLinear RoyalBlue()            { return cast(ColorLinear)ColorGammaUB(0x41, 0x69, 0xE1, 0xFF); };
  ColorLinear SaddleBrown()          { return cast(ColorLinear)ColorGammaUB(0x8B, 0x45, 0x13, 0xFF); };
  ColorLinear Salmon()               { return cast(ColorLinear)ColorGammaUB(0xFA, 0x80, 0x72, 0xFF); };
  ColorLinear SandyBrown()           { return cast(ColorLinear)ColorGammaUB(0xF4, 0xA4, 0x60, 0xFF); };
  ColorLinear SeaGreen()             { return cast(ColorLinear)ColorGammaUB(0x2E, 0x8B, 0x57, 0xFF); };
  ColorLinear SeaShell()             { return cast(ColorLinear)ColorGammaUB(0xFF, 0xF5, 0xEE, 0xFF); };
  ColorLinear Sienna()               { return cast(ColorLinear)ColorGammaUB(0xA0, 0x52, 0x2D, 0xFF); };
  ColorLinear Silver()               { return cast(ColorLinear)ColorGammaUB(0xC0, 0xC0, 0xC0, 0xFF); };
  ColorLinear SkyBlue()              { return cast(ColorLinear)ColorGammaUB(0x87, 0xCE, 0xEB, 0xFF); };
  ColorLinear SlateBlue()            { return cast(ColorLinear)ColorGammaUB(0x6A, 0x5A, 0xCD, 0xFF); };
  ColorLinear SlateGray()            { return cast(ColorLinear)ColorGammaUB(0x70, 0x80, 0x90, 0xFF); };
  ColorLinear Snow()                 { return cast(ColorLinear)ColorGammaUB(0xFF, 0xFA, 0xFA, 0xFF); };
  ColorLinear SpringGreen()          { return cast(ColorLinear)ColorGammaUB(0x00, 0xFF, 0x7F, 0xFF); };
  ColorLinear SteelBlue()            { return cast(ColorLinear)ColorGammaUB(0x46, 0x82, 0xB4, 0xFF); };
  ColorLinear Tan()                  { return cast(ColorLinear)ColorGammaUB(0xD2, 0xB4, 0x8C, 0xFF); };
  ColorLinear Teal()                 { return cast(ColorLinear)ColorGammaUB(0x00, 0x80, 0x80, 0xFF); };
  ColorLinear Thistle()              { return cast(ColorLinear)ColorGammaUB(0xD8, 0xBF, 0xD8, 0xFF); };
  ColorLinear Tomato()               { return cast(ColorLinear)ColorGammaUB(0xFF, 0x63, 0x47, 0xFF); };
  ColorLinear Turquoise()            { return cast(ColorLinear)ColorGammaUB(0x40, 0xE0, 0xD0, 0xFF); };
  ColorLinear Violet()               { return cast(ColorLinear)ColorGammaUB(0xEE, 0x82, 0xEE, 0xFF); };
  ColorLinear Wheat()                { return cast(ColorLinear)ColorGammaUB(0xF5, 0xDE, 0xB3, 0xFF); };
  ColorLinear White()                { return cast(ColorLinear)ColorGammaUB(0xFF, 0xFF, 0xFF, 0xFF); };
  ColorLinear WhiteSmoke()           { return cast(ColorLinear)ColorGammaUB(0xF5, 0xF5, 0xF5, 0xFF); };
  ColorLinear Yellow()               { return cast(ColorLinear)ColorGammaUB(0xFF, 0xFF, 0x00, 0xFF); };
  ColorLinear YellowGreen()          { return cast(ColorLinear)ColorGammaUB(0x9A, 0xCD, 0x32, 0xFF); };
}
