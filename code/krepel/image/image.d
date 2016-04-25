module krepel.image.image;

import krepel;
import Meta = krepel.meta;

import krepel.container.array;
import krepel.system.ifile;

import krepel.image.image_format;


struct ImageHeaderData
{
  uint NumMipLevels = 1;
  uint NumFaces = 1;
  uint NumArrayIndices = 1;

  uint Width;
  uint Height;
  uint Depth = 1;

  ImageFormat Format;


  @property uint WidthAtLevel(uint MipLevel = 0) const
  {
    assert(MipLevel < NumMipLevels, "Invalid mip level.");
    return Max(Width >> MipLevel, 1);
  }

  @property uint HeightAtLevel(uint MipLevel = 0) const
  {
    assert(MipLevel < NumMipLevels, "Invalid mip level.");
    return Max(Height >> MipLevel, 1);
  }

  @property uint DepthAtLevel(uint MipLevel = 0) const
  {
    assert(MipLevel < NumMipLevels, "Invalid mip level.");
    return Max(Depth >> MipLevel, 1);
  }
}

// Note(Manu): ezEngine allocates an additional 16 bytes so that the user can
// leverage that for alignment. However, I haven't seen it used yet so I'm
// omitting that. It seems you can easily add that later if necessary.
class ImageContainer
{
  ImageHeaderData HeaderData;
  alias HeaderData this;

  this(IAllocator Allocator)
  {
    this.Allocator = Allocator;
  }

  @property void Allocator(IAllocator NewAllocator)
  {
    SubImages.Allocator = NewAllocator;
    RawData.Allocator = NewAllocator;
  }

  uint NumBlocksX(uint MipLevel = 0) const
  {
    assert(this.Format.FormatType == ImageFormatType.BlockCompressed,
           "The number of blocks can only be retrieved for block compressed formats.");
    uint BlockSize = 4;
    return (WidthAtLevel(MipLevel) + BlockSize - 1) / BlockSize;
  }

  uint NumBlocksY(uint MipLevel = 0) const
  {
    assert(this.Format.FormatType == ImageFormatType.BlockCompressed,
           "The number of blocks can only be retrieved for block compressed formats.");
    uint BlockSize = 4;
    return (HeightAtLevel(MipLevel) + BlockSize - 1) / BlockSize;
  }

  @property inout(Type)[] ImageData(Type)() inout
  {
    auto DataSlice = RawData[0 .. Max(cast(long)$ - 16, cast(long)$)];
    return cast(typeof(return))DataSlice;
  }

  // TODO(Manu): The length of the returned range is probably wrong. Correct this.
  inout(Type)[] SubImageData(Type)(uint MipLevel = 0, uint Face = 0, uint ArrayIndex = 0) inout
  {
    const Offset = PointerToSubImageAt(MipLevel, Face, ArrayIndex).DataOffset;
    auto RawResult = RawData[Offset .. $];
    return cast(typeof(return))RawResult;
  }

  // TODO(Manu): Replace with PixelData that returns Type[] instead of Type*?
  inout(Type)* PixelPointer(Type)(uint MipLevel = 0, uint Face = 0, uint ArrayIndex = 0, uint X = 0, uint Y = 0, uint Z = 0) inout
  {
    assert(this.Format.FormatType == ImageFormatType.Linear,
           "Pixel pointer can only be retrieved for linear formats.");
    assert(X < Width);
    assert(Y < Height);
    assert(Z < Depth);

    auto Pointer = SubImageData!void(MipLevel, Face, ArrayIndex).ptr;

    Pointer += Z * DepthPitch(MipLevel);
    Pointer += Y * RowPitch(MipLevel);
    Pointer += X * this.Format.BitsPerPixel / 8;

    return cast(inout(Type)*)Pointer;
  }

  // TODO(Manu): Replace with BlockData that returns Type[] instead of Type*?
  inout(Type)* BlockPointer(Type)(uint MipLevel = 0, uint Face = 0, uint ArrayIndex = 0, uint BlockX = 0, uint BlockY = 0, uint Z = 0) inout
  {
    assert(this.Format.FormatType == ImageFormatType.BlockCompressed,
           "Block pointer can only be retrieved for block compressed formats.");

    auto Pointer = SubImageData!void(MipLevel, Face, ArrayIndex).ptr;

    Pointer += Z * DepthPitch(MipLevel);

    const BlockSize = 4;
    const uint NumBlocksX = WidthAtLevel(MipLevel) / BlockSize;
    const uint BlockIndex = BlockX + NumBlocksX * BlockY;

    Pointer += BlockIndex * BlockSize * BlockSize * this.Format.BitsPerPixel / 8;

    return cast(inout(Type)*)Pointer;
  }

  uint RowPitch(uint MipLevel = 0) const
  {
    return PointerToSubImageAt(MipLevel, 0, 0).RowPitch;
  }

  uint DepthPitch(uint MipLevel = 0) const
  {
    return PointerToSubImageAt(MipLevel, 0, 0).DepthPitch;
  }

  uint DataOffset(uint MipLevel = 0, uint Face = 0, uint ArrayIndex = 0) const
  {
    return PointerToSubImageAt(MipLevel, Face, ArrayIndex).DataOffset;
  }

  void AllocateImageData()
  {
    SubImages.Clear();
    RawData.Clear();

    SubImages.Expand(NumMipLevels * NumFaces * NumArrayIndices);

    uint DataSize = 0;

    bool IsCompressed = this.Format.FormatType == ImageFormatType.BlockCompressed;
    auto BitsPerPixel = this.Format.BitsPerPixel;

    foreach(ArrayIndex; 0 .. NumArrayIndices)
    {
      foreach(Face; 0 .. NumFaces)
      {
        foreach(MipLevel; 0 .. NumMipLevels)
        {
          auto SubImage = PointerToSubImageAt(MipLevel, Face, ArrayIndex);
          SubImage.DataOffset = DataSize;

          if(IsCompressed)
          {
            const uint BlockSize = 4;
            SubImage.RowPitch = 0;
            SubImage.DepthPitch = NumBlocksX(MipLevel) * NumBlocksY(MipLevel) * BlockSize * BlockSize * BitsPerPixel / 8;
          }
          else
          {
            SubImage.RowPitch = WidthAtLevel(MipLevel) * BitsPerPixel / 8;
            SubImage.DepthPitch = HeightAtLevel(MipLevel) * SubImage.RowPitch;
          }

          DataSize += SubImage.DepthPitch * DepthAtLevel(MipLevel);
        }
      }
    }

    RawData.Expand(DataSize);
  }

  void DeallocateImageData()
  {
    RawData.ClearMemory();
    SubImages.ClearMemory();
  }

private:
  static struct SubImage
  {
    int RowPitch;
    int DepthPitch;
    int DataOffset;
  }

  inout(SubImage)* PointerToSubImageAt(uint MipLevel, uint Face, uint ArrayIndex) inout
  {
    assert(MipLevel < this.NumMipLevels, "Invalid mip level");
    assert(Face < this.NumFaces, "Invalid uiFace");
    assert(ArrayIndex < this.NumArrayIndices, "Invalid array slice");
    return &SubImages[MipLevel + NumMipLevels * (Face + NumFaces * ArrayIndex)];
  }

  // TODO(Manu): Use an in-place array for SubImages once we have one.
  Array!SubImage SubImages;
  Array!ubyte RawData;
}

interface IImageLoader
{
  Flag!"Success" LoadImageFromData(void[] RawImageData, ImageContainer ResultImage);
  Flag!"Success" WriteImageToArray(ImageContainer Image, ref Array!ubyte RawImageData);
}

extern(C)
{
  alias PFN_CreateLoader = IImageLoader function(IAllocator Allocator);
  alias PFN_DestroyLoader = void function(IAllocator Allocator, IImageLoader Loader);
}
