module krepel.image.image;

import krepel;
import Meta = krepel.meta;

import krepel.system.ifile;

import krepel.image.image_format;


struct ImageHeaderData
{
  uint NumMipLevels;
  uint NumFaces;
  uint NumArrayIndices;

  uint Width;
  uint Height;
  uint Depth;

  ImageFormat Format;


  @property uint WidthAtLevel(uint MipLevel = 0) const
  {
    assert(MipLevel < NumMipLevels, "Invalid mip level.");
    return Clamp(Width >> MipLevel, 1, NumMipLevels);
  }

  @property uint HeightAtLevel(uint MipLevel = 0) const
  {
    assert(MipLevel < NumMipLevels, "Invalid mip level.");
    return Clamp(Height >> MipLevel, 1, NumMipLevels);
  }

  @property uint DepthAtLevel(uint MipLevel = 0) const
  {
    assert(MipLevel < NumMipLevels, "Invalid mip level.");
    return Clamp(Depth >> MipLevel, 1, NumMipLevels);
  }
}

class ImageContainer
{
  ImageHeaderData HeaderData;
  alias HeaderData this;
}

interface IImageLoader
{
  Flag!"Success" LoadImageFromData(void[] RawImageData, ImageContainer ResultImage);
}

extern(C)
{
  alias PFN_CreateLoader = IImageLoader function(IAllocator Allocator);
  alias PFN_DestroyLoader = void function(IAllocator Allocator, IImageLoader Loader);
}
