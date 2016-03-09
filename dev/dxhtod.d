import std.stdio;
import std.algorithm;
import std.conv;
import std.format;
import std.range;
import std.array;
import std.string;
import std.uni;
import std.file : readText;
import std.traits;
import std.typecons;
import std.datetime;

enum CodeType
{
  INVALID,

  HashDefine,
  Enum,
  Struct,
  Interface,
  Function,
}

struct BlockData
{
  CodeType Type;
  union
  {
    HashDefineData HashDefine;
    EnumData Enum;
    StructData Struct;
    InterfaceData Interface;
    FunctionData Function;
  }
}

struct HashDefineData
{
  char[] Name;
  bool HasParens;
  char[] Parameters;
  char[] Body;
}

struct EnumData
{
  static struct Entry
  {
    char[] Key;
    char[] Value;
  }

  char[] Name;
  Entry[] Entries;
}

struct StructData
{
  static struct Entry
  {
    char[] Type;
    char[] Name;
    int ArrayCount;
  }

  char[] Name;
  Entry[] Entries;
}

struct InterfaceData
{
  char[] GUIDString;
  char[] Name;
  char[] ParentName;
  FunctionData[] Functions;
}

// HRESULT WINAPI CreateDXGIFactory1(REFIID riid, _COM_Outptr_ void **ppFactory);
struct FunctionData
{
  static struct Param
  {
    char[] Comment;
    char[] Annotation;
    char[] Type;
    char[] Name;
  }

  char[] ReturnType;
  char[] Name;
  Param[] Params;
}

class FormattedOutput
{
  int IndentationLevel;
  string Newline = "\n";

  File* OutFilePtr;

  @property auto Indentation() { return " ".repeat(IndentationLevel); }
  void Indent(int Amount = 2) { IndentationLevel += Amount; }
  void Outdent(int Amount = 2) { IndentationLevel -= Amount; }

  @property ref File OutFile() { return *OutFilePtr; }

  void WriteIndentation()
  {
    this.writef("%-(%s%)", Indentation);
  }

  alias OutFile this;
}

FormattedOutput Log;

BlockData ParseHashDefine(ref char[] Source)
{
  auto Result = BlockData(CodeType.HashDefine);
  Result.HashDefine = HashDefineData.init;

  // Skip '#define'
  auto Prefix = Source.FastForwardUntil!(Char => Char.isWhite);
  Log.WriteIndentation();
  Log.writeln("Skipped: ", Prefix);

  Source.SkipWhiteSpace();

  char Delimiter;
  Result.HashDefine.Name = Source.FastForwardUntil!(Char => Char.IsDelimiter)(&Delimiter);
  Log.WriteIndentation();
  Log.writeln("Name: ", Result.HashDefine.Name);

  if(Delimiter == '(')
  {
    Result.HashDefine.HasParens = true;
    Log.WriteIndentation();
    Log.writeln("Found parens. TODO: More printing in here!");

    char[] Param;
    do
    {
      Param = Source.FastForwardUntil!(Char => Char == ',' || Char == ')')(&Delimiter).strip;
      if(Param.length)
      {
        Result.HashDefine.Parameters ~= Param;
      }
    } while(Delimiter != ')');
  }

  char LastCharOfThisLine;
  do
  {
    auto Line = Source.FastForwardUntil!(Char => Char == '\n' || Char == '\\')(&LastCharOfThisLine).strip;
    Log.WriteIndentation();
    Log.writeln("Line: ", Line);
    Log.WriteIndentation();
    Log.writefln("Last char of that line: '%c'", LastCharOfThisLine);

    if(Line.length)
    {
      Result.HashDefine.Body ~= Line ~ "\n";
    }
  } while(Source.length && LastCharOfThisLine == '\\');

  Result.HashDefine.Body = Result.HashDefine.Body.strip();
  Log.WriteIndentation();
  Log.writeln("Body: ", Result.HashDefine.Body);

  return Result;
}

BlockData ParseEnum(ref char[] Source)
{
  auto Result = BlockData(CodeType.Enum);
  Result.Enum = EnumData.init;

  // Skip 'typedef'
  auto Prefix1 = Source.FastForwardUntil!(Char => Char.isWhite);
  Log.WriteIndentation();
  Log.writeln("Skipped: ", Prefix1);

  Source.SkipWhiteSpace();

  // Skip 'enum'
  auto Prefix2 = Source.FastForwardUntil!(Char => Char.isWhite);
  Log.WriteIndentation();
  Log.writeln("Skipped: ", Prefix2);

  // Read everything between 'enum' and '{'
  auto PseudoName = Source.FastForwardUntil!(Char => Char == '{').strip;
  Log.WriteIndentation();
  Log.writeln("Pseudo Name: ", PseudoName);

  Log.Indent();

  while(true)
  {
    Result.Enum.Entries.length++;
    auto Entry = &Result.Enum.Entries[$ - 1];
    scope(exit)
    {
      Log.WriteIndentation();
      Log.writeln("Entry: ", *Entry);
    }
    char Delimiter;
    Entry.Key = Source.FastForwardUntil!(Char => Char == '=' || Char == ',' || Char == '}')(&Delimiter).strip;
    if(Delimiter == '=')
    {
      Entry.Value = Source.FastForwardUntil!(Char => Char == ',' || Char == '}')(&Delimiter).strip;
    }

    if(Delimiter == '}') break;
    assert(Delimiter == ',');
  }

  Log.Outdent();

  // Extract the actual name.
  Result.Enum.Name = Source.FastForwardUntil!(Char => Char == ';').strip;
  Log.WriteIndentation();
  Log.writeln("Actual Name: ", Result.Enum.Name);

  return Result;
}

// TODO: Logging
BlockData ParseStruct(ref char[] Source)
{
  auto Result = BlockData(CodeType.Struct);
  Result.Struct = StructData.init;

  // Skip 'typedef'
  Source.FastForwardUntil!(Char => Char.isWhite);

  Source.SkipWhiteSpace();

  // Skip 'struct'
  Source.FastForwardUntil!(Char => Char.isWhite);

  // Read everything between 'struct' and '{'
  auto PseudoName = Source.FastForwardUntil!(Char => Char == '{').strip;

  while(true)
  {
    Source.SkipWhiteSpace();

    auto FirstToken = Source.FastForwardUntil!(Char => Char.isWhite);

    if(FirstToken == "}") break;

    Result.Struct.Entries.length++;
    auto Entry = &Result.Struct.Entries[$ - 1];

    Entry.Type = FirstToken;

    Source.SkipWhiteSpace();

    char LastChar;
    Entry.Name = Source.FastForwardUntil!(Char => Char == ';' || Char == '[')(&LastChar).strip;
    if(LastChar == '[')
    {
      // Read the number between the brackets [ 123 ]
      Entry.ArrayCount = Source.FastForwardUntil!(Char => Char == ']').strip.to!int;

      // Skip ';'
      Source.FastForwardUntil!(Char => Char == ';');
    }
  }

  // Extract the actual name.
  Result.Struct.Name = Source.FastForwardUntil!(Char => Char == ';').strip;

  return Result;
}

BlockData ParseInterface(ref char[] Source)
{
  auto Result = BlockData(CodeType.Interface);
  Result.Interface = InterfaceData.init;

  Source.FastForwardUntil!(Char => Char == '"');
  Result.Interface.GUIDString = Source.FastForwardUntil!(Char => Char == '"');
  Source.FastForwardUntil!(Char => Char == ')');

  Log.WriteIndentation();
  Log.writeln("GUID: ", Result.Interface.GUIDString);

  Source.SkipWhiteSpace();

  Result.Interface.Name = Source.FastForwardUntil!(Char => Char == ':').strip;
  Log.WriteIndentation();
  Log.writeln("Name: ", Result.Interface.Name);

  Source.SkipWhiteSpace();

  assert(Source.FastForwardUntil!(Char => Char.isWhite).strip == "public");

  Result.Interface.ParentName = Source.FastForwardUntil!(Char => Char == '{').strip;
  Log.WriteIndentation();
  Log.writeln("Parent Name: ", Result.Interface.ParentName);

  assert(Source.FastForwardUntil!(Char => Char == ':').strip == "public");

  Source.SkipWhiteSpace();

  Log.Indent();

  while(Source.length && Source.front != '}')
  {
    Result.Interface.Functions ~= ParseFunction(Source).Function;

    Source.SkipWhiteSpace();
  }

  Log.Outdent();

  // Skip trailing ';'
  Source.FastForwardUntil!(Char => Char == ';');

  return Result;
}

BlockData ParseFunction(ref char[] Source)
{
  auto Result = BlockData(CodeType.Function);
  Result.Function = FunctionData.init;

  auto ReturnType = Source.FastForwardUntil!(Char => Char.isWhite).strip;
  if(ReturnType == "virtual")
  {
    ReturnType = Source.FastForwardUntil!(Char => Char.isWhite).strip;
  }

  Result.Function.ReturnType = ReturnType;
  Log.WriteIndentation();
  Log.writeln("Return type: ", Result.Function.ReturnType);

  // Skip the call type (WINAPI, STDMETHODCALL, ...)
  auto CallType = Source.FastForwardUntil!(Char => Char.isWhite);
  Log.WriteIndentation();
  Log.writeln("Call type: ", CallType);

  Result.Function.Name = Source.FastForwardUntil!(Char => Char == '(');
  Log.WriteIndentation();
  Log.writeln("Name: ", Result.Function.Name);

  Log.Indent();

  while(true)
  {
    Result.Function.Params.length++;
    auto Param = &Result.Function.Params[$ - 1];
    scope(exit)
    {
      Log.WriteIndentation();
      Log.writeln("+++ Param: ", *Param);
    }

    Source.SkipWhiteSpace();

    if(Source.front == '/')
    {
      // Skip leading '/*'
      Source.popFrontN(2);

      // Skip until trailing '/' and omit '*' at the end of the result.
      Param.Comment = Source.FastForwardUntil!(Char => Char == '/')[0 .. $-1].strip;
      Log.WriteIndentation();
      Log.writeln("Param comment: ", Param.Comment);

      Source.SkipWhiteSpace();
    }

    if(Source.front == '_')
    {
      // It is assumed that there's no space in the '_Abc_Def_(Xyz,UWS)' annotations.
      Param.Annotation = Source.FastForwardUntil!(Char => Char.isWhite);
      Source.SkipWhiteSpace();
    }

    Log.WriteIndentation();
    Log.writeln("Param annotation: ", Param.Annotation);

    Param.Type = Source.FastForwardUntil!(Char => Char.isWhite);

    if(Param.Type == "const")
    {
      Param.Type ~= " ";
      Param.Type ~= Source.FastForwardUntil!(Char => Char.isWhite);
    }

    // Parse trailing '*' and 'const' modifier.
    while(true)
    {
      Source.SkipWhiteSpace();

      if(Source.front == '*')
      {
        Param.Type ~= '*';
        Source.popFront();
      }
      else if(Source.startsWith("const"))
      {
        Param.Type ~= " const ";
        Source.popFrontN("const".length);
      }
      else
      {
        break;
      }
    }

    Log.WriteIndentation();
    Log.writeln("Param type: ", Param.Type);
    assert(Param.Type.length);

    char Delimiter;
    Param.Name = Source.FastForwardUntil!(Char => Char == ',' || Char == ')')(&Delimiter);

    Log.WriteIndentation();
    Log.writeln("Param name: ", Param.Name);

    if(Delimiter == ')') break;
    assert(Delimiter == ',');
  }

  Log.Outdent();

  // Skip trailing ';'
  Source.FastForwardUntil!(Char => Char == ';');

  return Result;
}

bool IsDelimiter(CharType)(CharType Char)
{
  return Char.isWhite ||
         Char == '(' ||
         Char == ')' ||
         Char == '[' ||
         Char == ']' ||
         Char == '{' ||
         Char == '}' ||
         Char == '=' ||
         Char == ',' ||
         Char == ';';
}

/// Advances Source until Predicate(a) is true and returns the part of Source as a slice that has been skipped.
/// The matching char is written to LastCharOutPtr and not included in the return value or the advanced Source.
char[] FastForwardUntil(alias Predicate)(ref char[] Source, char* LastCharOutPtr = null)
{
  auto NewSource = Source.find!Predicate();
  if(NewSource.empty)
  {
    swap(NewSource, Source);
    return NewSource;
  }

  auto Result = Source[0 .. $ - NewSource.length];
  if(NewSource.length)
  {
    if(LastCharOutPtr) *LastCharOutPtr = NewSource[0];
    NewSource.popFront();
  }
  Source = NewSource;
  return Result;
}

void SkipWhiteSpace(ref char[] Source)
{
  Source = Source.stripLeft();
}

BlockData[] Parse(ref char[] Source)
{
  typeof(return) Result;

  char[] Token;

  while(Source.length)
  {
    Source.SkipWhiteSpace();

    auto SourceCopy = Source;
    Token = SourceCopy.FastForwardUntil!(Char => Char.IsDelimiter).strip;
    if(Token.length == 0) break;

    Log.writeln("Token: ", Token);
    Log.Indent();

    switch(Token)
    {
      case "#define": Result ~= ParseHashDefine(Source); break;
      case "typedef":
      {
        Source.SkipWhiteSpace();

        Token = SourceCopy.FastForwardUntil!(Char => Char.IsDelimiter).strip;
        Log.writeln("=> ", Token);
        switch(Token)
        {
          case "enum":   Result ~= ParseEnum(Source);   break;
          case "struct": Result ~= ParseStruct(Source); break;
          default: assert(0);
        }
      } break;
      case "MIDL_INTERFACE": Result ~= ParseInterface(Source);  break;
      default: Result ~= ParseFunction(Source);   break;
    }

    Log.Outdent();
    Log.writefln("%-(%s%)", "-".repeat(10));
  }

  return Result;
}

void EmitHashDefine(ref HashDefineData HashDefine, FormattedOutput Output)
{
  if(HashDefine.HasParens)
  {
    // Emit D function
  }
  else
  {
    // Emit enum constant
    // TODO(Manu): Clean up HashDefine.Body
    Output.writef("%-(%s%)enum %s = %s;%s", Output.Indentation, HashDefine.Name, HashDefine.Body, Output.Newline);
  }
}

void EmitEnum(ref EnumData Enum, FormattedOutput Output)
{
  Output.writef("%-(%s%)enum %s%s%-(%s%){%s", Output.Indentation, Enum.Name, Output.Newline, Output.Indentation, Output.Newline);
  Output.Indent();

  ulong MaxLen;
  foreach(ref Entry; Enum.Entries[])
  {
    MaxLen = max(MaxLen, Entry.Key.length);
  }

  foreach(ref Entry; Enum.Entries[])
  {
    Output.writef("%-(%s%)%s", Output.Indentation, Entry.Key);
    if(Entry.Value.length)
    {
      Output.writef("%-(%s%) = %s", " ".repeat(MaxLen - Entry.Key.length), Entry.Value);
    }
    Output.write(",", Output.Newline);
  }
  Output.Outdent();
  Output.writef("%-(%s%)}%s", Output.Indentation, Output.Newline);
}

void EmitStruct(ref StructData Struct, FormattedOutput Output)
{
  Output.writef("%-(%s%)struct %s%s%-(%s%){%s", Output.Indentation, Struct.Name, Output.Newline, Output.Indentation, Output.Newline);
  Output.Indent();

  //ulong MaxLen;
  //foreach(ref Entry; Struct.Entries[])
  //{
  //  MaxLen = max(MaxLen, Entry.Type.length);
  //}

  foreach(ref Entry; Struct.Entries[])
  {
    Output.writef("%-(%s%)%s", Output.Indentation, Entry.Type);
    if(Entry.ArrayCount)
    {
      Output.writef("[%d]", Entry.ArrayCount);
    }
    //Output.writef("%-(%s%)", " ".repeat(MaxLen - Entry.Type.length));
    Output.writef(" %s;%s", Entry.Name, Output.Newline);
  }
  Output.Outdent();
  Output.writef("%-(%s%)}%s", Output.Indentation, Output.Newline);
}

void EmitInterface(ref InterfaceData Interface, FormattedOutput Output)
{
  Output.writef("%-(%s%)mixin DeclareIID!(%s, \"%s\");%s", Output.Indentation, Interface.Name, Interface.GUIDString, Output.Newline);
  Output.writef("%-(%s%)interface %s : %s%s", Output.Indentation, Interface.Name, Interface.ParentName, Output.Newline);
  Output.writef("%-(%s%){%sextern(Windows):%s%s", Output.Indentation, Output.Newline, Output.Newline, Output.Newline);
  Output.Indent();

  foreach(ref Function; Interface.Functions)
  {
    EmitFunction(Function, Output, Yes.AddPrefix, No.AddExternWindows);
  }

  Output.Outdent();
  Output.writef("%-(%s%)}%s", Output.Indentation, Output.Newline);
}

void EmitFunction(ref FunctionData Function, FormattedOutput Output, Flag!"AddPrefix" AddFrefix = Yes.AddPrefix, Flag!"AddExternWindows" AddExternWindows = Yes.AddExternWindows)
{
  scope(failure) Log.writeln("Failure emitting function: ", Function);

  Output.WriteIndentation();
  if(AddExternWindows) Output.write("extern(Windows) ");
  Output.writef("%s %s(", Function.ReturnType, Function.Name);

  Output.Indent();
  foreach(ref Param; Function.Params)
  {
    scope(failure) Log.writeln("Failure emitting param: ", Param);
    Output.write(Output.Newline);
    Output.WriteIndentation();

    auto Scan = Param.Type;
    if(Scan.startsWith("const"))
    {
      Scan.popFrontN("const ".length);
    }

    char[] InnerType = Scan.FastForwardUntil!(Char => Char.isWhite || Char == '*');

    bool IsInterfaceType   = InnerType.front == 'I' && InnerType.any!(Char => Char.isLower);
    bool IsArrayParameter  = cast(bool)Param.Annotation.canFind("_reads_", "_writes_");
    bool IsRefParameter    = cast(bool)Param.Annotation.canFind("_Out_", "_Inout_");
    bool IsInParameter     = cast(bool)Param.Type.canFind(" const", "const ");
    bool IsOutPtrParameter = cast(bool)Param.Annotation.canFind("_Outptr_");

    if(IsInParameter || IsOutPtrParameter)
    {
      assert(IsInParameter != IsOutPtrParameter, "`in` and `outptr` parameters are mutually exclusive.");
    }

    if(IsInterfaceType)
    {
      if(IsRefParameter || IsOutPtrParameter) Output.write("ref ");
      if(IsInParameter)                       Output.write("in ");

      Output.write(InnerType);

      if(IsArrayParameter) Output.write("*");
    }
    else
    {
      auto NumPointers = Param.Type.count("*");

      if(NumPointers == 0)
      {
        assert(!IsRefParameter, "Can't pass by `ref` without a pointer in C/C++.");
        assert(!IsInParameter, "This doesn't make sense.");

        // This type has no pointers, so it's simply passed by value.
        Output.write(InnerType);
      }
      else
      {
        if(IsArrayParameter)
        {
          if(IsInParameter) Output.write("in ");
          Output.writef("%s%-(%s%)", InnerType, "*".repeat(NumPointers));
        }
        else if(IsOutPtrParameter)
        {
          Output.writef("%s%-(%s%)", InnerType, "*".repeat(NumPointers));
        }
        else
        {
          // I'd like to assert that we have a 'ref' parameter here but I
          // can't since some VALUE* parameters are not annotated with _Out_
          // or the like.
          //assert(IsRefParameter);

          Output.write("ref ");
          if(IsInParameter) Output.write("in ");
          Output.write(InnerType);
        }
      }
    }

    Output.writef(" %s,", Param.Name);
  }
  Output.Outdent();

  Output.write(Output.Newline);
  Output.WriteIndentation();
  Output.writef(");%s%s", Output.Newline, Output.Newline);
}

void EmitBlocks(BlockData[] Blocks, FormattedOutput Output)
{
  foreach(ref Block; Blocks)
  {
    Output.write(Output.Newline);
    final switch(Block.Type)
    {
      case CodeType.HashDefine: EmitHashDefine(Block.HashDefine, Output); break;
      case CodeType.Enum:       EmitEnum(Block.Enum, Output);             break;
      case CodeType.Struct:     EmitStruct(Block.Struct, Output);         break;
      case CodeType.Interface:  EmitInterface(Block.Interface, Output);   break;
      case CodeType.Function:   EmitFunction(Block.Function, Output);     break;
      case CodeType.INVALID: assert(0);
    }
  }
}

void main(string[] Args)
{
  const Program = Args[0];
  Args = Args[1 .. $];

  assert(Args.length == 1, "Need 1 argument.");

  Log = new FormattedOutput();
  Log.OutFilePtr = &stderr;

  auto Output = new FormattedOutput();
  Output.OutFilePtr = &stdout;

  auto Filename = Args[0];
  char[] InputBuffer = Filename.readText!(char[]);

  auto Blocks = Parse(InputBuffer);

  Log.writefln("%-(%s%)", "=".repeat(72));

  Output.write("// Original file name: ", Filename, Output.Newline);
  Output.write("// Conversion date: ", Clock.currTime, Output.Newline);
  Output.write(Output.Newline, Output.Newline);

  EmitBlocks(Blocks, Output);
}
