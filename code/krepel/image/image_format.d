module krepel.image.image_format;

import krepel;

enum ImageFormatType
{
  Unknown,
  Linear,
  BlockCompressed,
}

enum ImageFormat
{
  Unknown = 0,

  // 32b per component, 4 components
  R32G32B32A32_Typeless = 1,
  R32G32B32A32_Float = 2,
  R32G32B32A32_UInt = 3,
  R32G32B32A32_SInt = 4,

  // 32b per component, 3 components
  R32G32B32_Typeless = 5,
  R32G32B32_Float = 6,
  R32G32B32_UInt = 7,
  R32G32B32_SInt = 8,

  // 16b per component, 4 components
  R16G16B16A16_Typeless = 9,
  R16G16B16A16_Float = 10,
  R16G16B16A16_UNorm = 11,
  R16G16B16A16_UInt = 12,
  R16G16B16A16_SNorm = 13,
  R16G16B16A16_SInt = 14,

  // 32b per component, 2 components
  R32G32_Typeless = 15,
  R32G32_Float = 16,
  R32G32_UInt = 17,
  R32G32_SInt = 18,

  // Pseudo depth-stencil formats
  R32G8X24_Typeless = 19,
  D32_Float_S8X24_UInt = 20,
  R32_Float_X8X24_Typeless = 21,
  X32_Typeless_G8X24_UInt = 22,

  // 10b and 11b per component
  R10G10B10A2_Typeless = 23,
  R10G10B10A2_UNorm = 24,
  R10G10B10A2_UInt = 25,
  R10G10B10_XR_BIAS_A2_UNorm = 26,
  R11G11B10_Float = 27,

  // 8b per component, 4 components
  R8G8B8A8_UNorm = 28,
  R8G8B8A8_Typeless = 29,
  R8G8B8A8_UNorm_sRGB = 30,
  R8G8B8A8_UInt = 31,
  R8G8B8A8_SNorm = 32,
  R8G8B8A8_SInt = 33,

  B8G8R8A8_UNorm = 34,
  B8G8R8X8_UNorm = 35,
  B8G8R8A8_Typeless = 36,
  B8G8R8A8_UNorm_sRGB = 37,
  B8G8R8X8_Typeless = 38,
  B8G8R8X8_UNorm_sRGB = 39,

  // 16b per component, 2 components
  R16G16_Typeless = 40,
  R16G16_Float = 41,
  R16G16_UNorm = 42,
  R16G16_UInt = 43,
  R16G16_SNorm = 44,
  R16G16_SInt = 45,

  // 32b per component, 1 component
  R32_Typeless = 46,
  D32_Float = 47,
  R32_Float = 48,
  R32_UInt = 49,
  R32_SInt = 50,

  // Mixed 24b/8b formats
  R24G8_Typeless = 51,
  D24_UNorm_S8_UInt = 52,
  R24_UNorm_X8_Typeless = 53,
  X24_Typeless_G8_UInt = 54,

  // 8b per component, three components
  B8G8R8_UNorm = 55,

  // 8b per component, two components
  R8G8_Typeless = 56,
  R8G8_UNorm = 57,
  R8G8_UInt = 58,
  R8G8_SNorm = 59,
  R8G8_SInt = 60,

  // 5b and 6b per component
  B5G6R5_UNorm = 61,
  B5G5R5A1_UNorm = 62,
  B5G5R5X1_UNorm = 63,

  // 16b per component, one component
  R16_Typeless = 64,
  R16_Float = 65,
  D16_UNorm = 66,
  R16_UNorm = 67,
  R16_UInt = 68,
  R16_SNorm = 69,
  R16_SInt = 70,

  // 8b per component, one component
  R8_Typeless = 71,
  R8_UNorm = 72,
  R8_UInt = 73,
  R8_SNorm = 74,
  R8_SInt = 75,
  A8_UNorm = 76,

  // 1b per component, one component
  R1_UNorm = 77,
  R9G9B9E5_SharedExp = 78,

  // Block compression formats
  BC1_Typeless = 79,
  BC1_UNorm = 80,
  BC1_UNorm_sRGB = 81,
  BC2_Typeless = 82,
  BC2_UNorm = 83,
  BC2_UNorm_sRGB = 84,
  BC3_Typeless = 85,
  BC3_UNorm = 86,
  BC3_UNorm_sRGB = 87,
  BC4_Typeless = 88,
  BC4_UNorm = 89,
  BC4_SNorm = 90,
  BC5_Typeless = 91,
  BC5_UNorm = 92,
  BC5_SNorm = 93,
  BC6H_Typeless = 94,
  BC6H_UF16 = 95,
  BC6H_SF16 = 96,
  BC7_Typeless = 97,
  BC7_UNorm = 98,
  BC7_UNorm_sRGB = 99,

  // 4b per component
  B4G4R4A4_UNorm = 100,
}

@property uint            BitsPerPixel(ImageFormat Format) { return LookupTable[Format].BitsPerPixel; }
@property uint            RedMask(ImageFormat Format)      { return LookupTable[Format].RedMask;      }
@property uint            GreenMask(ImageFormat Format)    { return LookupTable[Format].GreenMask;    }
@property uint            BlueMask(ImageFormat Format)     { return LookupTable[Format].BlueMask;     }
@property uint            AlphaMask(ImageFormat Format)    { return LookupTable[Format].AlphaMask;    }
@property ImageFormatType FormatType(ImageFormat Format)   { return LookupTable[Format].FormatType;   }

ImageFormat FindMatchingImageFormatForPixelMaskAndBitsPerPixel(uint RedMask, uint GreenMask, uint BlueMask, uint AlphaMask,
                                                               uint BitsPerPixel,
                                                               LogData* Log = null)
{
  foreach(Candidate; LookupTable)
  {
    if(Candidate.RedMask == RedMask &&
       Candidate.GreenMask == GreenMask &&
       Candidate.BlueMask == BlueMask &&
       Candidate.AlphaMask == AlphaMask)
    {
      if(Candidate.BitsPerPixel == BitsPerPixel) return Candidate.Format;
      Log.Warning("%s matches the pixel mask but does not match with the requested bits per pixel.", Candidate.Format);
    }
  }

  return ImageFormat.Unknown;
}

private
{
  struct ImageFormatMetaData
  {
    ImageFormat Format;
    uint BitsPerPixel;
    uint RedMask;
    uint GreenMask;
    uint BlueMask;
    uint AlphaMask;
    ImageFormatType FormatType;
  }

  __gshared immutable ImageFormatMetaData[ImageFormat.max + 1] LookupTable =
  [
    { Format: ImageFormat.Unknown,                    BitsPerPixel: 0,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Unknown },

    { Format: ImageFormat.R32G32B32A32_Typeless,      BitsPerPixel: 128, RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R32G32B32A32_Float,         BitsPerPixel: 128, RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R32G32B32A32_UInt,          BitsPerPixel: 128, RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R32G32B32A32_SInt,          BitsPerPixel: 128, RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },

    { Format: ImageFormat.R32G32B32_Typeless,         BitsPerPixel: 96,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R32G32B32_Float,            BitsPerPixel: 96,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R32G32B32_UInt,             BitsPerPixel: 96,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R32G32B32_SInt,             BitsPerPixel: 96,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },

    { Format: ImageFormat.R16G16B16A16_Typeless,      BitsPerPixel: 64,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R16G16B16A16_Float,         BitsPerPixel: 64,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R16G16B16A16_UNorm,         BitsPerPixel: 64,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R16G16B16A16_UInt,          BitsPerPixel: 64,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R16G16B16A16_SNorm,         BitsPerPixel: 64,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R16G16B16A16_SInt,          BitsPerPixel: 64,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },

    { Format: ImageFormat.R32G32_Typeless,            BitsPerPixel: 64,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R32G32_Float,               BitsPerPixel: 64,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R32G32_UInt,                BitsPerPixel: 64,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R32G32_SInt,                BitsPerPixel: 64,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },

    { Format: ImageFormat.R32G8X24_Typeless,          BitsPerPixel: 64,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.D32_Float_S8X24_UInt,       BitsPerPixel: 64,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R32_Float_X8X24_Typeless,   BitsPerPixel: 64,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.X32_Typeless_G8X24_UInt,    BitsPerPixel: 64,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },

    { Format: ImageFormat.R10G10B10A2_Typeless,       BitsPerPixel: 32,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R10G10B10A2_UNorm,          BitsPerPixel: 32,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R10G10B10A2_UInt,           BitsPerPixel: 32,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R10G10B10_XR_BIAS_A2_UNorm, BitsPerPixel: 32,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R11G11B10_Float,            BitsPerPixel: 32,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },

    { Format: ImageFormat.R8G8B8A8_Typeless,          BitsPerPixel: 32,  RedMask: 0x000000FF, GreenMask: 0x0000FF00, BlueMask: 0x00FF0000, AlphaMask: 0xFF000000, FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R8G8B8A8_UNorm,             BitsPerPixel: 32,  RedMask: 0x000000FF, GreenMask: 0x0000FF00, BlueMask: 0x00FF0000, AlphaMask: 0xFF000000, FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R8G8B8A8_UNorm_sRGB,        BitsPerPixel: 32,  RedMask: 0x000000FF, GreenMask: 0x0000FF00, BlueMask: 0x00FF0000, AlphaMask: 0xFF000000, FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R8G8B8A8_UInt,              BitsPerPixel: 32,  RedMask: 0x000000FF, GreenMask: 0x0000FF00, BlueMask: 0x00FF0000, AlphaMask: 0xFF000000, FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R8G8B8A8_SNorm,             BitsPerPixel: 32,  RedMask: 0x000000FF, GreenMask: 0x0000FF00, BlueMask: 0x00FF0000, AlphaMask: 0xFF000000, FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R8G8B8A8_SInt,              BitsPerPixel: 32,  RedMask: 0x000000FF, GreenMask: 0x0000FF00, BlueMask: 0x00FF0000, AlphaMask: 0xFF000000, FormatType: ImageFormatType.Linear },

    { Format: ImageFormat.B8G8R8A8_UNorm,             BitsPerPixel: 32,  RedMask: 0x00FF0000, GreenMask: 0x0000FF00, BlueMask: 0x000000FF, AlphaMask: 0xFF000000, FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.B8G8R8X8_UNorm,             BitsPerPixel: 32,  RedMask: 0x00FF0000, GreenMask: 0x0000FF00, BlueMask: 0x000000FF, AlphaMask: 0x00000000, FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.B8G8R8A8_Typeless,          BitsPerPixel: 32,  RedMask: 0x00FF0000, GreenMask: 0x0000FF00, BlueMask: 0x000000FF, AlphaMask: 0xFF000000, FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.B8G8R8A8_UNorm_sRGB,        BitsPerPixel: 32,  RedMask: 0x00FF0000, GreenMask: 0x0000FF00, BlueMask: 0x000000FF, AlphaMask: 0xFF000000, FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.B8G8R8X8_Typeless,          BitsPerPixel: 32,  RedMask: 0x00FF0000, GreenMask: 0x0000FF00, BlueMask: 0x000000FF, AlphaMask: 0xFF000000, FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.B8G8R8X8_UNorm_sRGB,        BitsPerPixel: 32,  RedMask: 0x00FF0000, GreenMask: 0x0000FF00, BlueMask: 0x000000FF, AlphaMask: 0x00000000, FormatType: ImageFormatType.Linear },

    { Format: ImageFormat.R16G16_Typeless,            BitsPerPixel: 32,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R16G16_Float,               BitsPerPixel: 32,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R16G16_UNorm,               BitsPerPixel: 32,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R16G16_UInt,                BitsPerPixel: 32,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R16G16_SNorm,               BitsPerPixel: 32,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R16G16_SInt,                BitsPerPixel: 32,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },

    { Format: ImageFormat.R32_Typeless,               BitsPerPixel: 32,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.D32_Float,                  BitsPerPixel: 32,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R32_Float,                  BitsPerPixel: 32,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R32_UInt,                   BitsPerPixel: 32,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R32_SInt,                   BitsPerPixel: 32,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },

    { Format: ImageFormat.R24G8_Typeless,             BitsPerPixel: 32,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.D24_UNorm_S8_UInt,          BitsPerPixel: 32,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R24_UNorm_X8_Typeless,      BitsPerPixel: 32,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.X24_Typeless_G8_UInt,       BitsPerPixel: 32,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },

    { Format: ImageFormat.B8G8R8_UNorm,               BitsPerPixel: 24,  RedMask: 0x00FF0000, GreenMask: 0x0000FF00, BlueMask: 0x000000FF, AlphaMask: 0x00000000, FormatType: ImageFormatType.Linear },

    { Format: ImageFormat.R8G8_Typeless,              BitsPerPixel: 16,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R8G8_UNorm,                 BitsPerPixel: 16,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R8G8_UInt,                  BitsPerPixel: 16,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R8G8_SNorm,                 BitsPerPixel: 16,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R8G8_SInt,                  BitsPerPixel: 16,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },

    { Format: ImageFormat.B5G6R5_UNorm,               BitsPerPixel: 16,  RedMask: 0xF800,     GreenMask: 0x07E0,     BlueMask: 0x001F,     AlphaMask: 0x0000,     FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.B5G5R5A1_UNorm,             BitsPerPixel: 16,  RedMask: 0x7C00,     GreenMask: 0x03E0,     BlueMask: 0x001F,     AlphaMask: 0x8000,     FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.B5G5R5X1_UNorm,             BitsPerPixel: 16,  RedMask: 0x7C00,     GreenMask: 0x03E0,     BlueMask: 0x001F,     AlphaMask: 0x0000,     FormatType: ImageFormatType.Linear },

    { Format: ImageFormat.R16_Typeless,               BitsPerPixel: 16,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R16_Float,                  BitsPerPixel: 16,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.D16_UNorm,                  BitsPerPixel: 16,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R16_UNorm,                  BitsPerPixel: 16,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R16_UInt,                   BitsPerPixel: 16,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R16_SNorm,                  BitsPerPixel: 16,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R16_SInt,                   BitsPerPixel: 16,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },

    { Format: ImageFormat.R8_Typeless,                BitsPerPixel: 8,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R8_UNorm,                   BitsPerPixel: 8,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R8_UInt,                    BitsPerPixel: 8,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R8_SNorm,                   BitsPerPixel: 8,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.R8_SInt,                    BitsPerPixel: 8,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },
    { Format: ImageFormat.A8_UNorm,                   BitsPerPixel: 8,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },

    { Format: ImageFormat.R1_UNorm,                   BitsPerPixel: 1,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },

    { Format: ImageFormat.R9G9B9E5_SharedExp,         BitsPerPixel: 32,  RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.Linear },

    { Format: ImageFormat.BC1_Typeless,               BitsPerPixel: 4,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.BlockCompressed },
    { Format: ImageFormat.BC1_UNorm,                  BitsPerPixel: 4,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.BlockCompressed },
    { Format: ImageFormat.BC1_UNorm_sRGB,             BitsPerPixel: 4,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.BlockCompressed },
    { Format: ImageFormat.BC2_Typeless,               BitsPerPixel: 8,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.BlockCompressed },
    { Format: ImageFormat.BC2_UNorm,                  BitsPerPixel: 8,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.BlockCompressed },
    { Format: ImageFormat.BC2_UNorm_sRGB,             BitsPerPixel: 8,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.BlockCompressed },
    { Format: ImageFormat.BC3_Typeless,               BitsPerPixel: 8,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.BlockCompressed },
    { Format: ImageFormat.BC3_UNorm,                  BitsPerPixel: 8,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.BlockCompressed },
    { Format: ImageFormat.BC3_UNorm_sRGB,             BitsPerPixel: 8,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.BlockCompressed },
    { Format: ImageFormat.BC4_Typeless,               BitsPerPixel: 4,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.BlockCompressed },
    { Format: ImageFormat.BC4_UNorm,                  BitsPerPixel: 4,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.BlockCompressed },
    { Format: ImageFormat.BC4_SNorm,                  BitsPerPixel: 4,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.BlockCompressed },
    { Format: ImageFormat.BC5_Typeless,               BitsPerPixel: 8,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.BlockCompressed },
    { Format: ImageFormat.BC5_UNorm,                  BitsPerPixel: 8,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.BlockCompressed },
    { Format: ImageFormat.BC5_SNorm,                  BitsPerPixel: 8,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.BlockCompressed },
    { Format: ImageFormat.BC6H_Typeless,              BitsPerPixel: 8,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.BlockCompressed },
    { Format: ImageFormat.BC6H_UF16,                  BitsPerPixel: 8,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.BlockCompressed },
    { Format: ImageFormat.BC6H_SF16,                  BitsPerPixel: 8,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.BlockCompressed },
    { Format: ImageFormat.BC7_Typeless,               BitsPerPixel: 8,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.BlockCompressed },
    { Format: ImageFormat.BC7_UNorm,                  BitsPerPixel: 8,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.BlockCompressed },
    { Format: ImageFormat.BC7_UNorm_sRGB,             BitsPerPixel: 8,   RedMask: 0,          GreenMask: 0,          BlueMask: 0,          AlphaMask: 0,          FormatType: ImageFormatType.BlockCompressed },

    { Format: ImageFormat.B4G4R4A4_UNorm,             BitsPerPixel: 16,  RedMask: 0x0F00,     GreenMask: 0x00F0,     BlueMask: 0x000F,     AlphaMask: 0xF000,     FormatType: ImageFormatType.Linear },
  ];
}
