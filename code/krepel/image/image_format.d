module krepel.image.image_format;

enum ImageFormatType
{
  Unknown,
  Linear,
  BlockCompressed,
}

enum ImageFormat
{
  Unknown,

  // 32b per component, 4 components
  R32G32B32A32_Typeless,
  R32G32B32A32_Float,
  R32G32B32A32_UInt,
  R32G32B32A32_SInt,

  // 32b per component, 3 components
  R32G32B32_Typeless,
  R32G32B32_Float,
  R32G32B32_UInt,
  R32G32B32_SInt,

  // 16b per component, 4 components
  R16G16B16A16_Typeless,
  R16G16B16A16_Float,
  R16G16B16A16_UNorm,
  R16G16B16A16_UInt,
  R16G16B16A16_SNorm,
  R16G16B16A16_SInt,

  // 32b per component, 2 components
  R32G32_Typeless,
  R32G32_Float,
  R32G32_UInt,
  R32G32_SInt,

  // Pseudo depth-stencil formats
  R32G8X24_Typeless,
  D32_Float_S8X24_UInt,
  R32_Float_X8X24_Typeless,
  X32_Typeless_G8X24_UInt,

  // 10b and 11b per component
  R10G10B10A2_Typeless,
  R10G10B10A2_UNorm,
  R10G10B10A2_UInt,
  R10G10B10_XR_BIAS_A2_UNorm,
  R11G11B10_Float,

  // 8b per component, 4 components
  R8G8B8A8_UNorm,
  R8G8B8A8_Typeless,
  R8G8B8A8_UNorm_sRGB,
  R8G8B8A8_UInt,
  R8G8B8A8_SNorm,
  R8G8B8A8_SInt,

  B8G8R8A8_UNorm,
  B8G8R8X8_UNorm,
  B8G8R8A8_Typeless,
  B8G8R8A8_UNorm_sRGB,
  B8G8R8X8_Typeless,
  B8G8R8X8_UNorm_sRGB,

  // 16b per component, 2 components
  R16G16_Typeless,
  R16G16_Float,
  R16G16_UNorm,
  R16G16_UInt,
  R16G16_SNorm,
  R16G16_SInt,

  // 32b per component, 1 component
  R32_Typeless,
  D32_Float,
  R32_Float,
  R32_UInt,
  R32_SInt,

  // Mixed 24b/8b formats
  R24G8_Typeless,
  D24_UNorm_S8_UInt,
  R24_UNorm_X8_Typeless,
  X24_Typeless_G8_UInt,

  // 8b per component, three components
  B8G8R8_UNorm,

  // 8b per component, two components
  R8G8_Typeless,
  R8G8_UNorm,
  R8G8_UInt,
  R8G8_SNorm,
  R8G8_SInt,

  // 5b and 6b per component
  B5G6R5_UNorm,
  B5G5R5A1_UNorm,
  B5G5R5X1_UNorm,

  // 16b per component, one component
  R16_Typeless,
  R16_Float,
  D16_UNorm,
  R16_UNorm,
  R16_UInt,
  R16_SNorm,
  R16_SInt,

  // 8b per component, one component
  R8_Typeless,
  R8_UNorm,
  R8_UInt,
  R8_SNorm,
  R8_SInt,
  A8_UNorm,

  // 1b per component, one component
  R1_UNorm,
  R9G9B9E5_SharedExp,

  // Block compression formats
  BC1_Typeless,
  BC1_UNorm,
  BC1_UNorm_sRGB,
  BC2_Typeless,
  BC2_UNorm,
  BC2_UNorm_sRGB,
  BC3_Typeless,
  BC3_UNorm,
  BC3_UNorm_sRGB,
  BC4_Typeless,
  BC4_UNorm,
  BC4_SNorm,
  BC5_Typeless,
  BC5_UNorm,
  BC5_SNorm,
  BC6H_Typeless,
  BC6H_UF16,
  BC6H_SF16,
  BC7_Typeless,
  BC7_UNorm,
  BC7_UNorm_sRGB,

  // 4b per component
  B4G4R4A4_UNorm,
}

@property uint            BitsPerPixel(ImageFormat Format) { return LookupTable[Format].BitsPerPixel; }
@property uint            RedMask(ImageFormat Format)      { return LookupTable[Format].RedMask;      }
@property uint            GreenMask(ImageFormat Format)    { return LookupTable[Format].GreenMask;    }
@property uint            BlueMask(ImageFormat Format)     { return LookupTable[Format].BlueMask;     }
@property uint            AlphaMask(ImageFormat Format)    { return LookupTable[Format].AlphaMask;    }
@property ImageFormatType FormatType(ImageFormat Format)   { return LookupTable[Format].FormatType;   }

ImageFormat ImageFormatFromPixelMask(uint RedMask, uint GreenMask, uint BlueMask, uint AlphaMask)
{
  foreach(ref MetaData; LookupTable)
  {
    if(MetaData.RedMask == RedMask &&
       MetaData.GreenMask == GreenMask &&
       MetaData.BlueMask == BlueMask &&
       MetaData.AlphaMask == AlphaMask)
    {
      return MetaData.Format;
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
