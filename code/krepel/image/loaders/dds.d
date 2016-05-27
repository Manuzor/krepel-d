module krepel.image.loader.dds;

import krepel;
import krepel.algorithm;
import krepel.container.array;

import krepel.image;
import krepel.image.image_format_mappings;


struct DDS_PixelFormat
{
  uint Size;
  uint Flags;
  uint FourCC;
  uint RGBBitCount;
  uint RBitMask;
  uint GBitMask;
  uint BBitMask;
  uint ABitMask;
}

struct DDS_Header
{
  uint            Magic;
  uint            Size;
  uint            Flags;
  uint            Height;
  uint            Width;
  uint            PitchOrLinearSize;
  uint            Depth;
  uint            MipMapCount;
  uint[11]        Reserved1;
  DDS_PixelFormat DDSpf;
  uint            Caps;
  uint            Caps2;
  uint            Caps3;
  uint            Caps4;
  uint            Reserved2;
}

enum DDS_ResourceDimension
{
  TEXTURE1D = 2,
  TEXTURE2D = 3,
  TEXTURE3D = 4,
}

enum DDS_ResourceMiscFlags
{
  TEXTURECUBE = 0x4,
}

struct DDS_HeaderDxt10
{
  uint DxgiFormat;
  uint ResourceDimension;
  uint MiscFlag;
  uint ArraySize;
  uint MiscFlags2;
}

enum DDSD_Flags
{
  CAPS = 0x000001,
  HEIGHT = 0x000002,
  WIDTH = 0x000004,
  PITCH = 0x000008,
  PIXELFORMAT = 0x001000,
  MIPMAPCOUNT = 0x020000,
  LINEARSIZE = 0x080000,
  DEPTH = 0x800000,
}

enum DDPF_Flags
{
  ALPHAPIXELS = 0x00001,
  ALPHA = 0x00002,
  FOURCC = 0x00004,
  RGB = 0x00040,
  YUV = 0x00200,
  LUMINANCE = 0x20000,
}

enum DDS_Caps
{
  COMPLEX = 0x000008,
  MIPMAP = 0x400000,
  TEXTURE = 0x001000,
};

enum DDS_Caps2
{
  CUBEMAP = 0x000200,
  CUBEMAP_POSITIVEX = 0x000400,
  CUBEMAP_NEGATIVEX = 0x000800,
  CUBEMAP_POSITIVEY = 0x001000,
  CUBEMAP_NEGATIVEY = 0x002000,
  CUBEMAP_POSITIVEZ = 0x004000,
  CUBEMAP_NEGATIVEZ = 0x008000,
  VOLUME = 0x200000,
};

enum uint DDS_Magic = 0x20534444;
enum uint DDS_Dxt10FourCc = 0x30315844;


/// Read an entire struct from $(D Data).
///
/// Params:
///   Data   = The raw data to read from. Will be trimmed by the amount of
///            bytes read.
///   Result = The struct to read into. Will be left in its original state if
///            this function is not successful.
private bool ConsumeAndReadInto(Type)(ref void[] Data, Type* Result)
{
  static assert(is(Type == struct));

  if(Data.length < Type.sizeof) return false;

  auto NumBytesRead = ConsumeAndReadInto(Data, (cast(void*)Result)[0 .. Type.sizeof]);
  assert(NumBytesRead == Type.sizeof);

  return true;
}

/// Copies as many bytes from $(D Data) to $(D Result), up to
/// $(D Result.length) bytes.
///
/// Params:
///   Data   = The raw data to read from. Will be trimmed by the amount of
///            bytes read.
///   Result = The target memory to write into. Will be left in its original
///            state if this function is not successful.
private size_t ConsumeAndReadInto(ref void[] Data, void[] Result)
{
  assert(Result);

  auto Amount = Min(Result.length, Data.length);
  if(Amount == 0) return 0;

  // Blit the data over.
  Result[0 .. Amount] = Data[0 .. Amount];

  // Trim the data.
  Data = Data[Amount .. $];

  return Amount;
}

private void WriteInto(Type)(ref in Type Something, ref Array!ubyte OutputData)
{
  OutputData ~= (cast(ubyte*)&Something)[0 .. Type.sizeof];
}

class DDSImageLoader : IImageLoader
{
  override Flag!"Success" LoadImageFromData(void[] RawImageData, ImageContainer ResultImage)
  {
    if(RawImageData.length == 0) return No.Success;
    if(ResultImage is null)      return No.Success;

    DDS_Header Header;
    if(!RawImageData.ConsumeAndReadInto(&Header))
    {
      Log.Failure("Failed to read file header.");
      return No.Success;
    }

    if(Header.Magic != DDS_Magic)
    {
      Log.Failure("The file is not a recognized DDS file.");
      return No.Success;
    }

    if(Header.Size != 124)
    {
      Log.Failure("The file header size %u doesn't match the expected size of 124.", Header.Size);
      return No.Success;
    }

    // Required in every .dds file. According to the spec, CAPS and PIXELFORMAT are also required, but D3DX outputs
    // files not conforming to this.
    if((Header.Flags & DDSD_Flags.WIDTH) == 0 ||
       (Header.Flags & DDSD_Flags.HEIGHT) == 0)
    {
      Log.Failure("The file header doesn't specify the mandatory WIDTH or HEIGHT flag.");
      return No.Success;
    }

    if((Header.Caps & DDS_Caps.TEXTURE) == 0)
    {
      Log.Failure("The file header doesn't specify the mandatory TEXTURE flag.");
      return No.Success;
    }

    bool HasPitch = (Header.Flags & DDSD_Flags.PITCH) != 0;

    ResultImage.Width = Header.Width;
    ResultImage.Height = Header.Height;

    if(Header.DDSpf.Size != 32)
    {
      Log.Failure("The pixel format size %u doesn't match the expected value of 32.", Header.DDSpf.Size);
      return No.Success;
    }

    bool IsDxt10 = false;
    DDS_HeaderDxt10 HeaderDxt10;

    ImageFormat Format = ImageFormat.Unknown;

    // Data format specified in RGBA masks
    if((Header.DDSpf.Flags & DDPF_Flags.ALPHAPIXELS) != 0 || (Header.DDSpf.Flags & DDPF_Flags.RGB) != 0)
    {
      // Find format
      Format = FindMatchingImageFormatForPixelMaskAndBitsPerPixel(Header.DDSpf.RBitMask,
                                                                  Header.DDSpf.GBitMask,
                                                                  Header.DDSpf.BBitMask,
                                                                  Header.DDSpf.ABitMask,
                                                                  Header.DDSpf.RGBBitCount);

      if(Format == ImageFormat.Unknown)
      {
        Log.Failure("Failed to find suitable krepel format. (Bits per pixel: %u, Pixel mask R: %x, G: %x, B: %x, A: %x)",
                    Header.DDSpf.RGBBitCount,
                    Header.DDSpf.RBitMask, Header.DDSpf.GBitMask, Header.DDSpf.BBitMask, Header.DDSpf.ABitMask);
        return No.Success;
      }
    }
    else if((Header.DDSpf.Flags & DDPF_Flags.FOURCC) != 0)
    {
      if(Header.DDSpf.FourCC == DDS_Dxt10FourCc)
      {
        if(!RawImageData.ConsumeAndReadInto(&HeaderDxt10))
        {
          Log.Failure("Failed to read file header.");
          return No.Success;
        }
        IsDxt10 = true;

        Format = ImageFormatFromDXGIFormat(HeaderDxt10.DxgiFormat);

        if(Format == ImageFormat.Unknown)
        {
          Log.Failure("The DXGI format %u has no equivalent image format.", HeaderDxt10.DxgiFormat);
          return No.Success;
        }
      }
      else
      {
        Format = ImageFormatFromFourCC(Header.DDSpf.FourCC);

        if(Format == ImageFormat.Unknown)
        {
          Log.Failure("The FourCC code '%c%c%c%c' was not recognized.",
            (Header.DDSpf.FourCC >> 0) & 0xFF,
            (Header.DDSpf.FourCC >> 8) & 0xFF,
            (Header.DDSpf.FourCC >> 16) & 0xFF,
            (Header.DDSpf.FourCC >> 24) & 0xFF);
          return No.Success;
        }
      }
    }
    else
    {
      Log.Failure("The image format is neither specified as a pixel mask nor as a FourCC code.");
      return No.Success;
    }

    Log.Info("Using krepel format: %s", Format);
    ResultImage.Format = Format;

    bool IsComplex = (Header.Caps & DDS_Caps.COMPLEX) != 0;
    bool HasMipMaps = (Header.Caps & DDS_Caps.MIPMAP) != 0;
    bool IsCubeMap = (Header.Caps2 & DDS_Caps2.CUBEMAP) != 0;
    bool IsVolume = (Header.Caps2 & DDS_Caps2.VOLUME) != 0;

    // Complex flag must match cubemap or volume flag
    if(IsComplex != (IsCubeMap || IsVolume || HasMipMaps))
    {
      Log.Failure("The header specifies the COMPLEX flag, but has neither mip levels, cubemap faces or depth slices.");
      return No.Success;
    }

    if(HasMipMaps)
    {
      ResultImage.NumMipLevels = Header.MipMapCount;
    }

    // Cubemap and volume texture are mutually exclusive
    if(IsVolume && IsCubeMap)
    {
      Log.Failure("The header specifies both the VOLUME and CUBEMAP flags.");
      return No.Success;
    }

    if(IsCubeMap)
    {
      ResultImage.NumFaces = 6;
    }
    else if(IsVolume)
    {
      ResultImage.Depth = Header.Depth;
    }

    ResultImage.AllocateImageData();

    // If pitch is specified, it must match the computed value
    if(HasPitch && ResultImage.RowPitch(0) != Header.PitchOrLinearSize)
    {
      Log.Failure("The row pitch specified in the header doesn't match the expected pitch.");
      return No.Success;
    }

    auto Data = ResultImage.ImageData!void();

    if(RawImageData.ConsumeAndReadInto(Data) != Data.length)
    {
      Log.Failure("Failed to read image data.");
      return No.Success;
    }

    if(RawImageData.length)
    {
      Log.Warning("After reading the entire image data there are %d bytes left.", RawImageData.length);
    }

    return Yes.Success;
  }

  override Flag!"Success" WriteImageToArray(ImageContainer Image, ref Array!ubyte RawImageData)
  {
    bool HasMipMaps = Image.NumMipLevels > 1;
    bool IsVolume = Image.Depth > 1;
    bool IsCubeMap = Image.NumFaces > 1;
    bool IsArray = Image.NumArrayIndices > 1;

    bool IsDxt10 = false;

    DDS_Header FileHeader;
    DDS_HeaderDxt10 HeaderDxt10;

    FileHeader.Magic = DDS_Magic;
    FileHeader.Size = 124;
    FileHeader.Width = Image.Width;
    FileHeader.Height = Image.Height;

    // Required in every .dds file.
    FileHeader.Flags = DDSD_Flags.WIDTH | DDSD_Flags.HEIGHT | DDSD_Flags.CAPS | DDSD_Flags.PIXELFORMAT;

    if(HasMipMaps)
    {
      FileHeader.Flags |= DDSD_Flags.MIPMAPCOUNT;
      FileHeader.MipMapCount = Image.NumMipLevels;
    }

    if(IsVolume)
    {
      // Volume and array are incompatible
      if(IsArray)
      {
        Log.Failure("The image is both an array and volume texture. This is not supported.");
        return No.Success;
      }

      FileHeader.Flags |= DDSD_Flags.DEPTH;
      FileHeader.Depth = Image.Depth;
    }

    switch (Image.Format.FormatType)
    {
    case ImageFormatType.Linear:
      FileHeader.Flags |= DDSD_Flags.PITCH;
      FileHeader.PitchOrLinearSize = Image.RowPitch(0);
      break;

    case ImageFormatType.BlockCompressed:
      FileHeader.Flags |= DDSD_Flags.LINEARSIZE;
      FileHeader.PitchOrLinearSize = 0; // TODO(Manu): sub-image size
      break;

    default:
      Log.Failure("Unknown image format type.");
      return No.Success;
    }

    FileHeader.Caps = DDS_Caps.TEXTURE;

    if(IsCubeMap)
    {
      if(Image.NumFaces != 6)
      {
        Log.Failure("The image is a cubemap, but has %u faces instead of the expected 6.", Image.NumFaces);
        return No.Success;
      }

      if(IsVolume)
      {
        Log.Failure("The image is both a cubemap and volume texture. This is not supported.");
        return No.Success;
      }

      FileHeader.Caps |= DDS_Caps.COMPLEX;
      FileHeader.Caps2 |= DDS_Caps2.CUBEMAP |
        DDS_Caps2.CUBEMAP_POSITIVEX | DDS_Caps2.CUBEMAP_NEGATIVEX |
        DDS_Caps2.CUBEMAP_POSITIVEY | DDS_Caps2.CUBEMAP_NEGATIVEY |
        DDS_Caps2.CUBEMAP_POSITIVEZ | DDS_Caps2.CUBEMAP_NEGATIVEZ;
    }

    if(IsArray)
    {
      FileHeader.Caps |= DDS_Caps.COMPLEX;

      // Must be written as DXT10
      IsDxt10 = true;
    }

    if(IsVolume)
    {
      FileHeader.Caps |= DDS_Caps.COMPLEX;
      FileHeader.Caps2 |= DDS_Caps2.VOLUME;
    }

    if(HasMipMaps)
    {
      FileHeader.Caps |= DDS_Caps.MIPMAP | DDS_Caps.COMPLEX;
    }

    FileHeader.DDSpf.Size = 32;

    uint RedMask = Image.Format.RedMask;
    uint GreenMask = Image.Format.GreenMask;
    uint BlueMask = Image.Format.BlueMask;
    uint AlphaMask = Image.Format.AlphaMask;

    uint FourCc = Image.Format.ImageFormatToFourCC();
    auto DxgiFormat = Image.Format.ImageFormatToDXGIFormat();

    // When not required to use a DXT10 texture, try to write a legacy DDS by specifying FourCC or pixel masks
    if(!IsDxt10)
    {
      // The format has a known mask and we would also recognize it as the same when reading back in, since multiple formats may have the same pixel masks
      ImageFormat MatchingFormat = FindMatchingImageFormatForPixelMaskAndBitsPerPixel(Image.Format.RedMask,
                                                                                      Image.Format.BlueMask,
                                                                                      Image.Format.GreenMask,
                                                                                      Image.Format.AlphaMask,
                                                                                      Image.Format.BitsPerPixel);

      if((RedMask | GreenMask | BlueMask | AlphaMask) && Image.Format == MatchingFormat)
      {
        FileHeader.DDSpf.Flags = DDPF_Flags.ALPHAPIXELS | DDPF_Flags.RGB;
        FileHeader.DDSpf.RBitMask = RedMask;
        FileHeader.DDSpf.GBitMask = GreenMask;
        FileHeader.DDSpf.BBitMask = BlueMask;
        FileHeader.DDSpf.ABitMask = AlphaMask;
        FileHeader.DDSpf.RGBBitCount = Image.Format.BitsPerPixel;
      }
      // The format has a known FourCC
      else if(FourCc != 0)
      {
        FileHeader.DDSpf.Flags = DDPF_Flags.FOURCC;
        FileHeader.DDSpf.FourCC = FourCc;
      }
      else
      {
        // Fallback to DXT10 path
        IsDxt10 = true;
      }
    }

    if(IsDxt10)
    {
      // We must write a DXT10 file, but there is no matching DXGI_FORMAT - we could also try converting, but that is rarely intended when writing .dds
      if(DxgiFormat == 0)
      {
        Log.Failure("The image needs to be written as a DXT10 file, but no matching DXGI format was found for '%s'.", Image.Format);
        return No.Success;
      }

      FileHeader.DDSpf.Flags = DDPF_Flags.FOURCC;
      FileHeader.DDSpf.FourCC = DDS_Dxt10FourCc;

      HeaderDxt10.DxgiFormat = DxgiFormat;

      if(IsVolume)
      {
        HeaderDxt10.ResourceDimension = DDS_ResourceDimension.TEXTURE3D;
      }
      else if(Image.Height > 1)
      {
        HeaderDxt10.ResourceDimension = DDS_ResourceDimension.TEXTURE2D;
      }
      else
      {
        HeaderDxt10.ResourceDimension = DDS_ResourceDimension.TEXTURE1D;
      }

      if(IsCubeMap)
      {
        HeaderDxt10.MiscFlag = DDS_ResourceMiscFlags.TEXTURECUBE;
      }

      // NOT multiplied by number of cubemap faces
      HeaderDxt10.ArraySize = Image.NumArrayIndices;

      // Can be used to describe the alpha channel usage, but automatically makes it incompatible with the D3DX libraries if not 0.
      HeaderDxt10.MiscFlags2 = 0;
    }

    FileHeader.WriteInto(RawImageData);

    if(IsDxt10)
    {
      HeaderDxt10.WriteInto(RawImageData);
    }

    RawImageData ~= Image.ImageData!ubyte;

    return Yes.Success;
  }
}

export extern(C)
{
  IImageLoader krCreateImageLoader_DDS(IAllocator Allocator)
  {
    return Allocator.New!DDSImageLoader;
  }
  static assert(is(typeof(&krCreateImageLoader_DDS) : PFN_CreateLoader));

  void krDestroyImageLoader_DDS(IAllocator Allocator, IImageLoader Loader)
  {
    auto RealLoader = cast(DDSImageLoader)Loader;
    assert(RealLoader, "Invalid given type.");
    Allocator.Delete(RealLoader);
  }
  static assert(is(typeof(&krDestroyImageLoader_DDS) : PFN_DestroyLoader));
}
