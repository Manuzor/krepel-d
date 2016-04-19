module krepel.image.loader.dds;

import krepel;
import krepel.image;

class DDSImageLoader : IImageLoader
{
  Flag!"Success" LoadImageFromData(void[] RawImageData, ImageContainer ResultImage)
  {
    if(RawImageData.length == 0) return No.Success;
    if(ResultImage is null)      return No.Success;

    // TODO(Manu): Implement.

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
    Allocator.Delete(Loader);
  }
  static assert(is(typeof(&krDestroyImageLoader_DDS) : PFN_DestroyLoader));
}
