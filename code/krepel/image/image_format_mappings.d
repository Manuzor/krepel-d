module krepel.image.image_format_mappings;

import krepel.image.image_format;

import directx.dxgiformat;

DXGI_FORMAT ImageFormatToDXGIFormat(ImageFormat KrepelFormat)
{
  final switch(KrepelFormat)
  {
    case ImageFormat.B8G8R8_UNorm:   goto case;
    case ImageFormat.B5G5R5X1_UNorm: goto case;
    case ImageFormat.Unknown:        return DXGI_FORMAT_UNKNOWN;

    case ImageFormat.R32G32B32A32_Typeless:       return DXGI_FORMAT_R32G32B32A32_TYPELESS;
    case ImageFormat.R32G32B32A32_Float:          return DXGI_FORMAT_R32G32B32A32_FLOAT;
    case ImageFormat.R32G32B32A32_UInt:           return DXGI_FORMAT_R32G32B32A32_UINT;
    case ImageFormat.R32G32B32A32_SInt:           return DXGI_FORMAT_R32G32B32A32_SINT;
    case ImageFormat.R32G32B32_Typeless:          return DXGI_FORMAT_R32G32B32_TYPELESS;
    case ImageFormat.R32G32B32_Float:             return DXGI_FORMAT_R32G32B32_FLOAT;
    case ImageFormat.R32G32B32_UInt:              return DXGI_FORMAT_R32G32B32_UINT;
    case ImageFormat.R32G32B32_SInt:              return DXGI_FORMAT_R32G32B32_SINT;
    case ImageFormat.R16G16B16A16_Typeless:       return DXGI_FORMAT_R16G16B16A16_TYPELESS;
    case ImageFormat.R16G16B16A16_Float:          return DXGI_FORMAT_R16G16B16A16_FLOAT;
    case ImageFormat.R16G16B16A16_UNorm:          return DXGI_FORMAT_R16G16B16A16_UNORM;
    case ImageFormat.R16G16B16A16_UInt:           return DXGI_FORMAT_R16G16B16A16_UINT;
    case ImageFormat.R16G16B16A16_SNorm:          return DXGI_FORMAT_R16G16B16A16_SNORM;
    case ImageFormat.R16G16B16A16_SInt:           return DXGI_FORMAT_R16G16B16A16_SINT;
    case ImageFormat.R32G32_Typeless:             return DXGI_FORMAT_R32G32_TYPELESS;
    case ImageFormat.R32G32_Float:                return DXGI_FORMAT_R32G32_FLOAT;
    case ImageFormat.R32G32_UInt:                 return DXGI_FORMAT_R32G32_UINT;
    case ImageFormat.R32G32_SInt:                 return DXGI_FORMAT_R32G32_SINT;
    case ImageFormat.R32G8X24_Typeless:           return DXGI_FORMAT_R32G8X24_TYPELESS;
    case ImageFormat.D32_Float_S8X24_UInt:        return DXGI_FORMAT_D32_FLOAT_S8X24_UINT;
    case ImageFormat.R32_Float_X8X24_Typeless:    return DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS;
    case ImageFormat.X32_Typeless_G8X24_UInt:     return DXGI_FORMAT_X32_TYPELESS_G8X24_UINT;
    case ImageFormat.R10G10B10A2_Typeless:        return DXGI_FORMAT_R10G10B10A2_TYPELESS;
    case ImageFormat.R10G10B10A2_UNorm:           return DXGI_FORMAT_R10G10B10A2_UNORM;
    case ImageFormat.R10G10B10A2_UInt:            return DXGI_FORMAT_R10G10B10A2_UINT;
    case ImageFormat.R11G11B10_Float:             return DXGI_FORMAT_R11G11B10_FLOAT;
    case ImageFormat.R8G8B8A8_Typeless:           return DXGI_FORMAT_R8G8B8A8_TYPELESS;
    case ImageFormat.R8G8B8A8_UNorm:              return DXGI_FORMAT_R8G8B8A8_UNORM;
    case ImageFormat.R8G8B8A8_UNorm_sRGB:         return DXGI_FORMAT_R8G8B8A8_UNORM_SRGB;
    case ImageFormat.R8G8B8A8_UInt:               return DXGI_FORMAT_R8G8B8A8_UINT;
    case ImageFormat.R8G8B8A8_SNorm:              return DXGI_FORMAT_R8G8B8A8_SNORM;
    case ImageFormat.R8G8B8A8_SInt:               return DXGI_FORMAT_R8G8B8A8_SINT;
    case ImageFormat.R16G16_Typeless:             return DXGI_FORMAT_R16G16_TYPELESS;
    case ImageFormat.R16G16_Float:                return DXGI_FORMAT_R16G16_FLOAT;
    case ImageFormat.R16G16_UNorm:                return DXGI_FORMAT_R16G16_UNORM;
    case ImageFormat.R16G16_UInt:                 return DXGI_FORMAT_R16G16_UINT;
    case ImageFormat.R16G16_SNorm:                return DXGI_FORMAT_R16G16_SNORM;
    case ImageFormat.R16G16_SInt:                 return DXGI_FORMAT_R16G16_SINT;
    case ImageFormat.R32_Typeless:                return DXGI_FORMAT_R32_TYPELESS;
    case ImageFormat.D32_Float:                   return DXGI_FORMAT_D32_FLOAT;
    case ImageFormat.R32_Float:                   return DXGI_FORMAT_R32_FLOAT;
    case ImageFormat.R32_UInt:                    return DXGI_FORMAT_R32_UINT;
    case ImageFormat.R32_SInt:                    return DXGI_FORMAT_R32_SINT;
    case ImageFormat.R24G8_Typeless:              return DXGI_FORMAT_R24G8_TYPELESS;
    case ImageFormat.D24_UNorm_S8_UInt:           return DXGI_FORMAT_D24_UNORM_S8_UINT;
    case ImageFormat.R24_UNorm_X8_Typeless:       return DXGI_FORMAT_R24_UNORM_X8_TYPELESS;
    case ImageFormat.X24_Typeless_G8_UInt:        return DXGI_FORMAT_X24_TYPELESS_G8_UINT;
    case ImageFormat.R8G8_Typeless:               return DXGI_FORMAT_R8G8_TYPELESS;
    case ImageFormat.R8G8_UNorm:                  return DXGI_FORMAT_R8G8_UNORM;
    case ImageFormat.R8G8_UInt:                   return DXGI_FORMAT_R8G8_UINT;
    case ImageFormat.R8G8_SNorm:                  return DXGI_FORMAT_R8G8_SNORM;
    case ImageFormat.R8G8_SInt:                   return DXGI_FORMAT_R8G8_SINT;
    case ImageFormat.R16_Typeless:                return DXGI_FORMAT_R16_TYPELESS;
    case ImageFormat.R16_Float:                   return DXGI_FORMAT_R16_FLOAT;
    case ImageFormat.D16_UNorm:                   return DXGI_FORMAT_D16_UNORM;
    case ImageFormat.R16_UNorm:                   return DXGI_FORMAT_R16_UNORM;
    case ImageFormat.R16_UInt:                    return DXGI_FORMAT_R16_UINT;
    case ImageFormat.R16_SNorm:                   return DXGI_FORMAT_R16_SNORM;
    case ImageFormat.R16_SInt:                    return DXGI_FORMAT_R16_SINT;
    case ImageFormat.R8_Typeless:                 return DXGI_FORMAT_R8_TYPELESS;
    case ImageFormat.R8_UNorm:                    return DXGI_FORMAT_R8_UNORM;
    case ImageFormat.R8_UInt:                     return DXGI_FORMAT_R8_UINT;
    case ImageFormat.R8_SNorm:                    return DXGI_FORMAT_R8_SNORM;
    case ImageFormat.R8_SInt:                     return DXGI_FORMAT_R8_SINT;
    case ImageFormat.A8_UNorm:                    return DXGI_FORMAT_A8_UNORM;
    case ImageFormat.R1_UNorm:                    return DXGI_FORMAT_R1_UNORM;
    case ImageFormat.R9G9B9E5_SharedExp:          return DXGI_FORMAT_R9G9B9E5_SHAREDEXP;
    case ImageFormat.BC1_Typeless:                return DXGI_FORMAT_BC1_TYPELESS;
    case ImageFormat.BC1_UNorm:                   return DXGI_FORMAT_BC1_UNORM;
    case ImageFormat.BC1_UNorm_sRGB:              return DXGI_FORMAT_BC1_UNORM_SRGB;
    case ImageFormat.BC2_Typeless:                return DXGI_FORMAT_BC2_TYPELESS;
    case ImageFormat.BC2_UNorm:                   return DXGI_FORMAT_BC2_UNORM;
    case ImageFormat.BC2_UNorm_sRGB:              return DXGI_FORMAT_BC2_UNORM_SRGB;
    case ImageFormat.BC3_Typeless:                return DXGI_FORMAT_BC3_TYPELESS;
    case ImageFormat.BC3_UNorm:                   return DXGI_FORMAT_BC3_UNORM;
    case ImageFormat.BC3_UNorm_sRGB:              return DXGI_FORMAT_BC3_UNORM_SRGB;
    case ImageFormat.BC4_Typeless:                return DXGI_FORMAT_BC4_TYPELESS;
    case ImageFormat.BC4_UNorm:                   return DXGI_FORMAT_BC4_UNORM;
    case ImageFormat.BC4_SNorm:                   return DXGI_FORMAT_BC4_SNORM;
    case ImageFormat.BC5_Typeless:                return DXGI_FORMAT_BC5_TYPELESS;
    case ImageFormat.BC5_UNorm:                   return DXGI_FORMAT_BC5_UNORM;
    case ImageFormat.BC5_SNorm:                   return DXGI_FORMAT_BC5_SNORM;
    case ImageFormat.B5G6R5_UNorm:                return DXGI_FORMAT_B5G6R5_UNORM;
    case ImageFormat.B5G5R5A1_UNorm:              return DXGI_FORMAT_B5G5R5A1_UNORM;
    case ImageFormat.B8G8R8A8_UNorm:              return DXGI_FORMAT_B8G8R8A8_UNORM;
    case ImageFormat.B8G8R8X8_UNorm:              return DXGI_FORMAT_B8G8R8X8_UNORM;
    case ImageFormat.R10G10B10_XR_BIAS_A2_UNorm:  return DXGI_FORMAT_R10G10B10_XR_BIAS_A2_UNORM;
    case ImageFormat.B8G8R8A8_Typeless:           return DXGI_FORMAT_B8G8R8A8_TYPELESS;
    case ImageFormat.B8G8R8A8_UNorm_sRGB:         return DXGI_FORMAT_B8G8R8A8_UNORM_SRGB;
    case ImageFormat.B8G8R8X8_Typeless:           return DXGI_FORMAT_B8G8R8X8_TYPELESS;
    case ImageFormat.B8G8R8X8_UNorm_sRGB:         return DXGI_FORMAT_B8G8R8X8_UNORM_SRGB;
    case ImageFormat.BC6H_Typeless:               return DXGI_FORMAT_BC6H_TYPELESS;
    case ImageFormat.BC6H_UF16:                   return DXGI_FORMAT_BC6H_UF16;
    case ImageFormat.BC6H_SF16:                   return DXGI_FORMAT_BC6H_SF16;
    case ImageFormat.BC7_Typeless:                return DXGI_FORMAT_BC7_TYPELESS;
    case ImageFormat.BC7_UNorm:                   return DXGI_FORMAT_BC7_UNORM;
    case ImageFormat.BC7_UNorm_sRGB:              return DXGI_FORMAT_BC7_UNORM_SRGB;
    case ImageFormat.B4G4R4A4_UNorm:              return DXGI_FORMAT_B4G4R4A4_UNORM;
  }
}

ImageFormat ImageFormatFromDXGIFormat(DXGI_FORMAT DXGIFormat)
{
  final switch(DXGIFormat)
  {
    case DXGI_FORMAT_UNKNOWN: return ImageFormat.Unknown;

    case DXGI_FORMAT_R32G32B32A32_TYPELESS:      return ImageFormat.R32G32B32A32_Typeless;
    case DXGI_FORMAT_R32G32B32A32_FLOAT:         return ImageFormat.R32G32B32A32_Float;
    case DXGI_FORMAT_R32G32B32A32_UINT:          return ImageFormat.R32G32B32A32_UInt;
    case DXGI_FORMAT_R32G32B32A32_SINT:          return ImageFormat.R32G32B32A32_SInt;
    case DXGI_FORMAT_R32G32B32_TYPELESS:         return ImageFormat.R32G32B32_Typeless;
    case DXGI_FORMAT_R32G32B32_FLOAT:            return ImageFormat.R32G32B32_Float;
    case DXGI_FORMAT_R32G32B32_UINT:             return ImageFormat.R32G32B32_UInt;
    case DXGI_FORMAT_R32G32B32_SINT:             return ImageFormat.R32G32B32_SInt;
    case DXGI_FORMAT_R16G16B16A16_TYPELESS:      return ImageFormat.R16G16B16A16_Typeless;
    case DXGI_FORMAT_R16G16B16A16_FLOAT:         return ImageFormat.R16G16B16A16_Float;
    case DXGI_FORMAT_R16G16B16A16_UNORM:         return ImageFormat.R16G16B16A16_UNorm;
    case DXGI_FORMAT_R16G16B16A16_UINT:          return ImageFormat.R16G16B16A16_UInt;
    case DXGI_FORMAT_R16G16B16A16_SNORM:         return ImageFormat.R16G16B16A16_SNorm;
    case DXGI_FORMAT_R16G16B16A16_SINT:          return ImageFormat.R16G16B16A16_SInt;
    case DXGI_FORMAT_R32G32_TYPELESS:            return ImageFormat.R32G32_Typeless;
    case DXGI_FORMAT_R32G32_FLOAT:               return ImageFormat.R32G32_Float;
    case DXGI_FORMAT_R32G32_UINT:                return ImageFormat.R32G32_UInt;
    case DXGI_FORMAT_R32G32_SINT:                return ImageFormat.R32G32_SInt;
    case DXGI_FORMAT_R32G8X24_TYPELESS:          return ImageFormat.R32G8X24_Typeless;
    case DXGI_FORMAT_D32_FLOAT_S8X24_UINT:       return ImageFormat.D32_Float_S8X24_UInt;
    case DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS:   return ImageFormat.R32_Float_X8X24_Typeless;
    case DXGI_FORMAT_X32_TYPELESS_G8X24_UINT:    return ImageFormat.X32_Typeless_G8X24_UInt;
    case DXGI_FORMAT_R10G10B10A2_TYPELESS:       return ImageFormat.R10G10B10A2_Typeless;
    case DXGI_FORMAT_R10G10B10A2_UNORM:          return ImageFormat.R10G10B10A2_UNorm;
    case DXGI_FORMAT_R10G10B10A2_UINT:           return ImageFormat.R10G10B10A2_UInt;
    case DXGI_FORMAT_R11G11B10_FLOAT:            return ImageFormat.R11G11B10_Float;
    case DXGI_FORMAT_R8G8B8A8_TYPELESS:          return ImageFormat.R8G8B8A8_Typeless;
    case DXGI_FORMAT_R8G8B8A8_UNORM:             return ImageFormat.R8G8B8A8_UNorm;
    case DXGI_FORMAT_R8G8B8A8_UNORM_SRGB:        return ImageFormat.R8G8B8A8_UNorm_sRGB;
    case DXGI_FORMAT_R8G8B8A8_UINT:              return ImageFormat.R8G8B8A8_UInt;
    case DXGI_FORMAT_R8G8B8A8_SNORM:             return ImageFormat.R8G8B8A8_SNorm;
    case DXGI_FORMAT_R8G8B8A8_SINT:              return ImageFormat.R8G8B8A8_SInt;
    case DXGI_FORMAT_R16G16_TYPELESS:            return ImageFormat.R16G16_Typeless;
    case DXGI_FORMAT_R16G16_FLOAT:               return ImageFormat.R16G16_Float;
    case DXGI_FORMAT_R16G16_UNORM:               return ImageFormat.R16G16_UNorm;
    case DXGI_FORMAT_R16G16_UINT:                return ImageFormat.R16G16_UInt;
    case DXGI_FORMAT_R16G16_SNORM:               return ImageFormat.R16G16_SNorm;
    case DXGI_FORMAT_R16G16_SINT:                return ImageFormat.R16G16_SInt;
    case DXGI_FORMAT_R32_TYPELESS:               return ImageFormat.R32_Typeless;
    case DXGI_FORMAT_D32_FLOAT:                  return ImageFormat.D32_Float;
    case DXGI_FORMAT_R32_FLOAT:                  return ImageFormat.R32_Float;
    case DXGI_FORMAT_R32_UINT:                   return ImageFormat.R32_UInt;
    case DXGI_FORMAT_R32_SINT:                   return ImageFormat.R32_SInt;
    case DXGI_FORMAT_R24G8_TYPELESS:             return ImageFormat.R24G8_Typeless;
    case DXGI_FORMAT_D24_UNORM_S8_UINT:          return ImageFormat.D24_UNorm_S8_UInt;
    case DXGI_FORMAT_R24_UNORM_X8_TYPELESS:      return ImageFormat.R24_UNorm_X8_Typeless;
    case DXGI_FORMAT_X24_TYPELESS_G8_UINT:       return ImageFormat.X24_Typeless_G8_UInt;
    case DXGI_FORMAT_R8G8_TYPELESS:              return ImageFormat.R8G8_Typeless;
    case DXGI_FORMAT_R8G8_UNORM:                 return ImageFormat.R8G8_UNorm;
    case DXGI_FORMAT_R8G8_UINT:                  return ImageFormat.R8G8_UInt;
    case DXGI_FORMAT_R8G8_SNORM:                 return ImageFormat.R8G8_SNorm;
    case DXGI_FORMAT_R8G8_SINT:                  return ImageFormat.R8G8_SInt;
    case DXGI_FORMAT_R16_TYPELESS:               return ImageFormat.R16_Typeless;
    case DXGI_FORMAT_R16_FLOAT:                  return ImageFormat.R16_Float;
    case DXGI_FORMAT_D16_UNORM:                  return ImageFormat.D16_UNorm;
    case DXGI_FORMAT_R16_UNORM:                  return ImageFormat.R16_UNorm;
    case DXGI_FORMAT_R16_UINT:                   return ImageFormat.R16_UInt;
    case DXGI_FORMAT_R16_SNORM:                  return ImageFormat.R16_SNorm;
    case DXGI_FORMAT_R16_SINT:                   return ImageFormat.R16_SInt;
    case DXGI_FORMAT_R8_TYPELESS:                return ImageFormat.R8_Typeless;
    case DXGI_FORMAT_R8_UNORM:                   return ImageFormat.R8_UNorm;
    case DXGI_FORMAT_R8_UINT:                    return ImageFormat.R8_UInt;
    case DXGI_FORMAT_R8_SNORM:                   return ImageFormat.R8_SNorm;
    case DXGI_FORMAT_R8_SINT:                    return ImageFormat.R8_SInt;
    case DXGI_FORMAT_A8_UNORM:                   return ImageFormat.A8_UNorm;
    case DXGI_FORMAT_R1_UNORM:                   return ImageFormat.R1_UNorm;
    case DXGI_FORMAT_R9G9B9E5_SHAREDEXP:         return ImageFormat.R9G9B9E5_SharedExp;
    case DXGI_FORMAT_BC1_TYPELESS:               return ImageFormat.BC1_Typeless;
    case DXGI_FORMAT_BC1_UNORM:                  return ImageFormat.BC1_UNorm;
    case DXGI_FORMAT_BC1_UNORM_SRGB:             return ImageFormat.BC1_UNorm_sRGB;
    case DXGI_FORMAT_BC2_TYPELESS:               return ImageFormat.BC2_Typeless;
    case DXGI_FORMAT_BC2_UNORM:                  return ImageFormat.BC2_UNorm;
    case DXGI_FORMAT_BC2_UNORM_SRGB:             return ImageFormat.BC2_UNorm_sRGB;
    case DXGI_FORMAT_BC3_TYPELESS:               return ImageFormat.BC3_Typeless;
    case DXGI_FORMAT_BC3_UNORM:                  return ImageFormat.BC3_UNorm;
    case DXGI_FORMAT_BC3_UNORM_SRGB:             return ImageFormat.BC3_UNorm_sRGB;
    case DXGI_FORMAT_BC4_TYPELESS:               return ImageFormat.BC4_Typeless;
    case DXGI_FORMAT_BC4_UNORM:                  return ImageFormat.BC4_UNorm;
    case DXGI_FORMAT_BC4_SNORM:                  return ImageFormat.BC4_SNorm;
    case DXGI_FORMAT_BC5_TYPELESS:               return ImageFormat.BC5_Typeless;
    case DXGI_FORMAT_BC5_UNORM:                  return ImageFormat.BC5_UNorm;
    case DXGI_FORMAT_BC5_SNORM:                  return ImageFormat.BC5_SNorm;
    case DXGI_FORMAT_B5G6R5_UNORM:               return ImageFormat.B5G6R5_UNorm;
    case DXGI_FORMAT_B5G5R5A1_UNORM:             return ImageFormat.B5G5R5A1_UNorm;
    case DXGI_FORMAT_B8G8R8A8_UNORM:             return ImageFormat.B8G8R8A8_UNorm;
    case DXGI_FORMAT_B8G8R8X8_UNORM:             return ImageFormat.B8G8R8X8_UNorm;
    case DXGI_FORMAT_R10G10B10_XR_BIAS_A2_UNORM: return ImageFormat.R10G10B10_XR_BIAS_A2_UNorm;
    case DXGI_FORMAT_B8G8R8A8_TYPELESS:          return ImageFormat.B8G8R8A8_Typeless;
    case DXGI_FORMAT_B8G8R8A8_UNORM_SRGB:        return ImageFormat.B8G8R8A8_UNorm_sRGB;
    case DXGI_FORMAT_B8G8R8X8_TYPELESS:          return ImageFormat.B8G8R8X8_Typeless;
    case DXGI_FORMAT_B8G8R8X8_UNORM_SRGB:        return ImageFormat.B8G8R8X8_UNorm_sRGB;
    case DXGI_FORMAT_BC6H_TYPELESS:              return ImageFormat.BC6H_Typeless;
    case DXGI_FORMAT_BC6H_UF16:                  return ImageFormat.BC6H_UF16;
    case DXGI_FORMAT_BC6H_SF16:                  return ImageFormat.BC6H_SF16;
    case DXGI_FORMAT_BC7_TYPELESS:               return ImageFormat.BC7_Typeless;
    case DXGI_FORMAT_BC7_UNORM:                  return ImageFormat.BC7_UNorm;
    case DXGI_FORMAT_BC7_UNORM_SRGB:             return ImageFormat.BC7_UNorm_sRGB;
    case DXGI_FORMAT_B4G4R4A4_UNORM:             return ImageFormat.B4G4R4A4_UNorm;
  }
}

private uint MakeFourCC(string Code)()
{
  static assert(Code.length == 4);
  return cast(uint)(Code[0])       |
         cast(uint)(Code[1]) << 8  |
         cast(uint)(Code[2]) << 16 |
         cast(uint)(Code[3]) << 24;
}

uint ImageFormatToFourCC(ImageFormat KrepelFormat)
{
  switch(KrepelFormat)
  {
    default: return 0;

    case ImageFormat.BC1_UNorm: return MakeFourCC!("DXT1");
    case ImageFormat.BC2_UNorm: return MakeFourCC!("DXT3");
    case ImageFormat.BC3_UNorm: return MakeFourCC!("DXT5");
    case ImageFormat.BC4_UNorm: return MakeFourCC!("ATI1");
    case ImageFormat.BC5_UNorm: return MakeFourCC!("ATI2");
  }
}

ImageFormat ImageFormatFromFourCC(uint FourCC)
{
  switch(FourCC)
  {
    default: return ImageFormat.Unknown;

    case MakeFourCC!("DXT1"): return ImageFormat.BC1_UNorm;
    case MakeFourCC!("DXT2"): goto case;
    case MakeFourCC!("DXT3"): return ImageFormat.BC2_UNorm;
    case MakeFourCC!("DXT4"): goto case;
    case MakeFourCC!("DXT5"): return ImageFormat.BC3_UNorm;
    case MakeFourCC!("ATI1"): return ImageFormat.BC4_UNorm;
    case MakeFourCC!("ATI2"): return ImageFormat.BC5_UNorm;
  }
}
