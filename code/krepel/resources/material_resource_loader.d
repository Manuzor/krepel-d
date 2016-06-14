module krepel.resources.material_resource_loader;

import krepel;
import krepel.resources;
import krepel.serialization.sdlang;
import krepel.system;
import krepel.conversion;

class MaterialResourceLoader : IResourceLoader
{
  override Resource Load(IAllocator Allocator, WString FileName, IFile Data)
  {
    auto Context = SDLParsingContext(FileName.ToUTF8(), .Log);
    auto Document = Allocator.New!SDLDocument(Allocator);
    scope(exit) Allocator.Delete(Document);

    auto SourceString = Allocator.NewArray!char(Data.Size);
    scope(exit) Allocator.DeleteUndestructed(SourceString);
    auto BytesRead = Data.Read(SourceString);
    assert(BytesRead == SourceString.length);
    assert(Document.ParseDocumentFromString(cast(string)SourceString, Context), SourceString);
    return null;
  }

  override void Destroy(IAllocator Allocator, Resource Resource)
  {

  }
}
