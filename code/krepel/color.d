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

@property
{
  alias Color_AliceBlue            = () => cast(ColorLinear)ColorGammaUB(0xF0, 0xF8, 0xFF, 0xFF);
  alias Color_AntiqueWhite         = () => cast(ColorLinear)ColorGammaUB(0xFA, 0xEB, 0xD7, 0xFF);
  alias Color_Aqua                 = () => cast(ColorLinear)ColorGammaUB(0x00, 0xFF, 0xFF, 0xFF);
  alias Color_Aquamarine           = () => cast(ColorLinear)ColorGammaUB(0x7F, 0xFF, 0xD4, 0xFF);
  alias Color_Azure                = () => cast(ColorLinear)ColorGammaUB(0xF0, 0xFF, 0xFF, 0xFF);
  alias Color_Beige                = () => cast(ColorLinear)ColorGammaUB(0xF5, 0xF5, 0xDC, 0xFF);
  alias Color_Bisque               = () => cast(ColorLinear)ColorGammaUB(0xFF, 0xE4, 0xC4, 0xFF);
  alias Color_Black                = () => cast(ColorLinear)ColorGammaUB(0x00, 0x00, 0x00, 0xFF);
  alias Color_BlanchedAlmond       = () => cast(ColorLinear)ColorGammaUB(0xFF, 0xEB, 0xCD, 0xFF);
  alias Color_Blue                 = () => cast(ColorLinear)ColorGammaUB(0x00, 0x00, 0xFF, 0xFF);
  alias Color_BlueViolet           = () => cast(ColorLinear)ColorGammaUB(0x8A, 0x2B, 0xE2, 0xFF);
  alias Color_Brown                = () => cast(ColorLinear)ColorGammaUB(0xA5, 0x2A, 0x2A, 0xFF);
  alias Color_BurlyWood            = () => cast(ColorLinear)ColorGammaUB(0xDE, 0xB8, 0x87, 0xFF);
  alias Color_CadetBlue            = () => cast(ColorLinear)ColorGammaUB(0x5F, 0x9E, 0xA0, 0xFF);
  alias Color_Chartreuse           = () => cast(ColorLinear)ColorGammaUB(0x7F, 0xFF, 0x00, 0xFF);
  alias Color_Chocolate            = () => cast(ColorLinear)ColorGammaUB(0xD2, 0x69, 0x1E, 0xFF);
  alias Color_Coral                = () => cast(ColorLinear)ColorGammaUB(0xFF, 0x7F, 0x50, 0xFF);
  alias Color_CornflowerBlue       = () => cast(ColorLinear)ColorGammaUB(0x64, 0x95, 0xED, 0xFF);
  alias Color_Cornsilk             = () => cast(ColorLinear)ColorGammaUB(0xFF, 0xF8, 0xDC, 0xFF);
  alias Color_Crimson              = () => cast(ColorLinear)ColorGammaUB(0xDC, 0x14, 0x3C, 0xFF);
  alias Color_Cyan                 = () => cast(ColorLinear)ColorGammaUB(0x00, 0xFF, 0xFF, 0xFF);
  alias Color_DarkBlue             = () => cast(ColorLinear)ColorGammaUB(0x00, 0x00, 0x8B, 0xFF);
  alias Color_DarkCyan             = () => cast(ColorLinear)ColorGammaUB(0x00, 0x8B, 0x8B, 0xFF);
  alias Color_DarkGoldenRod        = () => cast(ColorLinear)ColorGammaUB(0xB8, 0x86, 0x0B, 0xFF);
  alias Color_DarkGray             = () => cast(ColorLinear)ColorGammaUB(0xA9, 0xA9, 0xA9, 0xFF);
  alias Color_DarkGreen            = () => cast(ColorLinear)ColorGammaUB(0x00, 0x64, 0x00, 0xFF);
  alias Color_DarkKhaki            = () => cast(ColorLinear)ColorGammaUB(0xBD, 0xB7, 0x6B, 0xFF);
  alias Color_DarkMagenta          = () => cast(ColorLinear)ColorGammaUB(0x8B, 0x00, 0x8B, 0xFF);
  alias Color_DarkOliveGreen       = () => cast(ColorLinear)ColorGammaUB(0x55, 0x6B, 0x2F, 0xFF);
  alias Color_DarkOrange           = () => cast(ColorLinear)ColorGammaUB(0xFF, 0x8C, 0x00, 0xFF);
  alias Color_DarkOrchid           = () => cast(ColorLinear)ColorGammaUB(0x99, 0x32, 0xCC, 0xFF);
  alias Color_DarkRed              = () => cast(ColorLinear)ColorGammaUB(0x8B, 0x00, 0x00, 0xFF);
  alias Color_DarkSalmon           = () => cast(ColorLinear)ColorGammaUB(0xE9, 0x96, 0x7A, 0xFF);
  alias Color_DarkSeaGreen         = () => cast(ColorLinear)ColorGammaUB(0x8F, 0xBC, 0x8F, 0xFF);
  alias Color_DarkSlateBlue        = () => cast(ColorLinear)ColorGammaUB(0x48, 0x3D, 0x8B, 0xFF);
  alias Color_DarkSlateGray        = () => cast(ColorLinear)ColorGammaUB(0x2F, 0x4F, 0x4F, 0xFF);
  alias Color_DarkTurquoise        = () => cast(ColorLinear)ColorGammaUB(0x00, 0xCE, 0xD1, 0xFF);
  alias Color_DarkViolet           = () => cast(ColorLinear)ColorGammaUB(0x94, 0x00, 0xD3, 0xFF);
  alias Color_DeepPink             = () => cast(ColorLinear)ColorGammaUB(0xFF, 0x14, 0x93, 0xFF);
  alias Color_DeepSkyBlue          = () => cast(ColorLinear)ColorGammaUB(0x00, 0xBF, 0xFF, 0xFF);
  alias Color_DimGray              = () => cast(ColorLinear)ColorGammaUB(0x69, 0x69, 0x69, 0xFF);
  alias Color_DodgerBlue           = () => cast(ColorLinear)ColorGammaUB(0x1E, 0x90, 0xFF, 0xFF);
  alias Color_FireBrick            = () => cast(ColorLinear)ColorGammaUB(0xB2, 0x22, 0x22, 0xFF);
  alias Color_FloralWhite          = () => cast(ColorLinear)ColorGammaUB(0xFF, 0xFA, 0xF0, 0xFF);
  alias Color_ForestGreen          = () => cast(ColorLinear)ColorGammaUB(0x22, 0x8B, 0x22, 0xFF);
  alias Color_Fuchsia              = () => cast(ColorLinear)ColorGammaUB(0xFF, 0x00, 0xFF, 0xFF);
  alias Color_Gainsboro            = () => cast(ColorLinear)ColorGammaUB(0xDC, 0xDC, 0xDC, 0xFF);
  alias Color_GhostWhite           = () => cast(ColorLinear)ColorGammaUB(0xF8, 0xF8, 0xFF, 0xFF);
  alias Color_Gold                 = () => cast(ColorLinear)ColorGammaUB(0xFF, 0xD7, 0x00, 0xFF);
  alias Color_GoldenRod            = () => cast(ColorLinear)ColorGammaUB(0xDA, 0xA5, 0x20, 0xFF);
  alias Color_Gray                 = () => cast(ColorLinear)ColorGammaUB(0x80, 0x80, 0x80, 0xFF);
  alias Color_Green                = () => cast(ColorLinear)ColorGammaUB(0x00, 0x80, 0x00, 0xFF);
  alias Color_GreenYellow          = () => cast(ColorLinear)ColorGammaUB(0xAD, 0xFF, 0x2F, 0xFF);
  alias Color_HoneyDew             = () => cast(ColorLinear)ColorGammaUB(0xF0, 0xFF, 0xF0, 0xFF);
  alias Color_HotPink              = () => cast(ColorLinear)ColorGammaUB(0xFF, 0x69, 0xB4, 0xFF);
  alias Color_IndianRed            = () => cast(ColorLinear)ColorGammaUB(0xCD, 0x5C, 0x5C, 0xFF);
  alias Color_Indigo               = () => cast(ColorLinear)ColorGammaUB(0x4B, 0x00, 0x82, 0xFF);
  alias Color_Ivory                = () => cast(ColorLinear)ColorGammaUB(0xFF, 0xFF, 0xF0, 0xFF);
  alias Color_Khaki                = () => cast(ColorLinear)ColorGammaUB(0xF0, 0xE6, 0x8C, 0xFF);
  alias Color_Lavender             = () => cast(ColorLinear)ColorGammaUB(0xE6, 0xE6, 0xFA, 0xFF);
  alias Color_LavenderBlush        = () => cast(ColorLinear)ColorGammaUB(0xFF, 0xF0, 0xF5, 0xFF);
  alias Color_LawnGreen            = () => cast(ColorLinear)ColorGammaUB(0x7C, 0xFC, 0x00, 0xFF);
  alias Color_LemonChiffon         = () => cast(ColorLinear)ColorGammaUB(0xFF, 0xFA, 0xCD, 0xFF);
  alias Color_LightBlue            = () => cast(ColorLinear)ColorGammaUB(0xAD, 0xD8, 0xE6, 0xFF);
  alias Color_LightCoral           = () => cast(ColorLinear)ColorGammaUB(0xF0, 0x80, 0x80, 0xFF);
  alias Color_LightCyan            = () => cast(ColorLinear)ColorGammaUB(0xE0, 0xFF, 0xFF, 0xFF);
  alias Color_LightGoldenRodYellow = () => cast(ColorLinear)ColorGammaUB(0xFA, 0xFA, 0xD2, 0xFF);
  alias Color_LightGray            = () => cast(ColorLinear)ColorGammaUB(0xD3, 0xD3, 0xD3, 0xFF);
  alias Color_LightGreen           = () => cast(ColorLinear)ColorGammaUB(0x90, 0xEE, 0x90, 0xFF);
  alias Color_LightPink            = () => cast(ColorLinear)ColorGammaUB(0xFF, 0xB6, 0xC1, 0xFF);
  alias Color_LightSalmon          = () => cast(ColorLinear)ColorGammaUB(0xFF, 0xA0, 0x7A, 0xFF);
  alias Color_LightSeaGreen        = () => cast(ColorLinear)ColorGammaUB(0x20, 0xB2, 0xAA, 0xFF);
  alias Color_LightSkyBlue         = () => cast(ColorLinear)ColorGammaUB(0x87, 0xCE, 0xFA, 0xFF);
  alias Color_LightSlateGray       = () => cast(ColorLinear)ColorGammaUB(0x77, 0x88, 0x99, 0xFF);
  alias Color_LightSteelBlue       = () => cast(ColorLinear)ColorGammaUB(0xB0, 0xC4, 0xDE, 0xFF);
  alias Color_LightYellow          = () => cast(ColorLinear)ColorGammaUB(0xFF, 0xFF, 0xE0, 0xFF);
  alias Color_Lime                 = () => cast(ColorLinear)ColorGammaUB(0x00, 0xFF, 0x00, 0xFF);
  alias Color_LimeGreen            = () => cast(ColorLinear)ColorGammaUB(0x32, 0xCD, 0x32, 0xFF);
  alias Color_Linen                = () => cast(ColorLinear)ColorGammaUB(0xFA, 0xF0, 0xE6, 0xFF);
  alias Color_Magenta              = () => cast(ColorLinear)ColorGammaUB(0xFF, 0x00, 0xFF, 0xFF);
  alias Color_Maroon               = () => cast(ColorLinear)ColorGammaUB(0x80, 0x00, 0x00, 0xFF);
  alias Color_MediumAquaMarine     = () => cast(ColorLinear)ColorGammaUB(0x66, 0xCD, 0xAA, 0xFF);
  alias Color_MediumBlue           = () => cast(ColorLinear)ColorGammaUB(0x00, 0x00, 0xCD, 0xFF);
  alias Color_MediumOrchid         = () => cast(ColorLinear)ColorGammaUB(0xBA, 0x55, 0xD3, 0xFF);
  alias Color_MediumPurple         = () => cast(ColorLinear)ColorGammaUB(0x93, 0x70, 0xDB, 0xFF);
  alias Color_MediumSeaGreen       = () => cast(ColorLinear)ColorGammaUB(0x3C, 0xB3, 0x71, 0xFF);
  alias Color_MediumSlateBlue      = () => cast(ColorLinear)ColorGammaUB(0x7B, 0x68, 0xEE, 0xFF);
  alias Color_MediumSpringGreen    = () => cast(ColorLinear)ColorGammaUB(0x00, 0xFA, 0x9A, 0xFF);
  alias Color_MediumTurquoise      = () => cast(ColorLinear)ColorGammaUB(0x48, 0xD1, 0xCC, 0xFF);
  alias Color_MediumVioletRed      = () => cast(ColorLinear)ColorGammaUB(0xC7, 0x15, 0x85, 0xFF);
  alias Color_MidnightBlue         = () => cast(ColorLinear)ColorGammaUB(0x19, 0x19, 0x70, 0xFF);
  alias Color_MintCream            = () => cast(ColorLinear)ColorGammaUB(0xF5, 0xFF, 0xFA, 0xFF);
  alias Color_MistyRose            = () => cast(ColorLinear)ColorGammaUB(0xFF, 0xE4, 0xE1, 0xFF);
  alias Color_Moccasin             = () => cast(ColorLinear)ColorGammaUB(0xFF, 0xE4, 0xB5, 0xFF);
  alias Color_NavajoWhite          = () => cast(ColorLinear)ColorGammaUB(0xFF, 0xDE, 0xAD, 0xFF);
  alias Color_Navy                 = () => cast(ColorLinear)ColorGammaUB(0x00, 0x00, 0x80, 0xFF);
  alias Color_OldLace              = () => cast(ColorLinear)ColorGammaUB(0xFD, 0xF5, 0xE6, 0xFF);
  alias Color_Olive                = () => cast(ColorLinear)ColorGammaUB(0x80, 0x80, 0x00, 0xFF);
  alias Color_OliveDrab            = () => cast(ColorLinear)ColorGammaUB(0x6B, 0x8E, 0x23, 0xFF);
  alias Color_Orange               = () => cast(ColorLinear)ColorGammaUB(0xFF, 0xA5, 0x00, 0xFF);
  alias Color_OrangeRed            = () => cast(ColorLinear)ColorGammaUB(0xFF, 0x45, 0x00, 0xFF);
  alias Color_Orchid               = () => cast(ColorLinear)ColorGammaUB(0xDA, 0x70, 0xD6, 0xFF);
  alias Color_PaleGoldenRod        = () => cast(ColorLinear)ColorGammaUB(0xEE, 0xE8, 0xAA, 0xFF);
  alias Color_PaleGreen            = () => cast(ColorLinear)ColorGammaUB(0x98, 0xFB, 0x98, 0xFF);
  alias Color_PaleTurquoise        = () => cast(ColorLinear)ColorGammaUB(0xAF, 0xEE, 0xEE, 0xFF);
  alias Color_PaleVioletRed        = () => cast(ColorLinear)ColorGammaUB(0xDB, 0x70, 0x93, 0xFF);
  alias Color_PapayaWhip           = () => cast(ColorLinear)ColorGammaUB(0xFF, 0xEF, 0xD5, 0xFF);
  alias Color_PeachPuff            = () => cast(ColorLinear)ColorGammaUB(0xFF, 0xDA, 0xB9, 0xFF);
  alias Color_Peru                 = () => cast(ColorLinear)ColorGammaUB(0xCD, 0x85, 0x3F, 0xFF);
  alias Color_Pink                 = () => cast(ColorLinear)ColorGammaUB(0xFF, 0xC0, 0xCB, 0xFF);
  alias Color_Plum                 = () => cast(ColorLinear)ColorGammaUB(0xDD, 0xA0, 0xDD, 0xFF);
  alias Color_PowderBlue           = () => cast(ColorLinear)ColorGammaUB(0xB0, 0xE0, 0xE6, 0xFF);
  alias Color_Purple               = () => cast(ColorLinear)ColorGammaUB(0x80, 0x00, 0x80, 0xFF);
  alias Color_RebeccaPurple        = () => cast(ColorLinear)ColorGammaUB(0x66, 0x33, 0x99, 0xFF);
  alias Color_Red                  = () => cast(ColorLinear)ColorGammaUB(0xFF, 0x00, 0x00, 0xFF);
  alias Color_RosyBrown            = () => cast(ColorLinear)ColorGammaUB(0xBC, 0x8F, 0x8F, 0xFF);
  alias Color_RoyalBlue            = () => cast(ColorLinear)ColorGammaUB(0x41, 0x69, 0xE1, 0xFF);
  alias Color_SaddleBrown          = () => cast(ColorLinear)ColorGammaUB(0x8B, 0x45, 0x13, 0xFF);
  alias Color_Salmon               = () => cast(ColorLinear)ColorGammaUB(0xFA, 0x80, 0x72, 0xFF);
  alias Color_SandyBrown           = () => cast(ColorLinear)ColorGammaUB(0xF4, 0xA4, 0x60, 0xFF);
  alias Color_SeaGreen             = () => cast(ColorLinear)ColorGammaUB(0x2E, 0x8B, 0x57, 0xFF);
  alias Color_SeaShell             = () => cast(ColorLinear)ColorGammaUB(0xFF, 0xF5, 0xEE, 0xFF);
  alias Color_Sienna               = () => cast(ColorLinear)ColorGammaUB(0xA0, 0x52, 0x2D, 0xFF);
  alias Color_Silver               = () => cast(ColorLinear)ColorGammaUB(0xC0, 0xC0, 0xC0, 0xFF);
  alias Color_SkyBlue              = () => cast(ColorLinear)ColorGammaUB(0x87, 0xCE, 0xEB, 0xFF);
  alias Color_SlateBlue            = () => cast(ColorLinear)ColorGammaUB(0x6A, 0x5A, 0xCD, 0xFF);
  alias Color_SlateGray            = () => cast(ColorLinear)ColorGammaUB(0x70, 0x80, 0x90, 0xFF);
  alias Color_Snow                 = () => cast(ColorLinear)ColorGammaUB(0xFF, 0xFA, 0xFA, 0xFF);
  alias Color_SpringGreen          = () => cast(ColorLinear)ColorGammaUB(0x00, 0xFF, 0x7F, 0xFF);
  alias Color_SteelBlue            = () => cast(ColorLinear)ColorGammaUB(0x46, 0x82, 0xB4, 0xFF);
  alias Color_Tan                  = () => cast(ColorLinear)ColorGammaUB(0xD2, 0xB4, 0x8C, 0xFF);
  alias Color_Teal                 = () => cast(ColorLinear)ColorGammaUB(0x00, 0x80, 0x80, 0xFF);
  alias Color_Thistle              = () => cast(ColorLinear)ColorGammaUB(0xD8, 0xBF, 0xD8, 0xFF);
  alias Color_Tomato               = () => cast(ColorLinear)ColorGammaUB(0xFF, 0x63, 0x47, 0xFF);
  alias Color_Turquoise            = () => cast(ColorLinear)ColorGammaUB(0x40, 0xE0, 0xD0, 0xFF);
  alias Color_Violet               = () => cast(ColorLinear)ColorGammaUB(0xEE, 0x82, 0xEE, 0xFF);
  alias Color_Wheat                = () => cast(ColorLinear)ColorGammaUB(0xF5, 0xDE, 0xB3, 0xFF);
  alias Color_White                = () => cast(ColorLinear)ColorGammaUB(0xFF, 0xFF, 0xFF, 0xFF);
  alias Color_WhiteSmoke           = () => cast(ColorLinear)ColorGammaUB(0xF5, 0xF5, 0xF5, 0xFF);
  alias Color_Yellow               = () => cast(ColorLinear)ColorGammaUB(0xFF, 0xFF, 0x00, 0xFF);
  alias Color_YellowGreen          = () => cast(ColorLinear)ColorGammaUB(0x9A, 0xCD, 0x32, 0xFF);
}
