import std.stdio;
import std.algorithm;
import std.conv;
import std.format;
import std.range;
import std.array;
import std.string;
import std.ascii : isDigit;
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
  Alias,
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
    AliasData Alias;
  }
}

struct HashDefineData
{
  char[] Name;
  bool HasParens;
  char[][] Parameters;
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

struct AliasData
{
  char[] NewName;
  char[] OldName;
}

class FormattedOutput
{
  int IndentationLevel;
  string Newline = "\n";
  //string Indentation;

  File OutFile;

  @property auto Indentation() { return ' '.repeat(IndentationLevel); }
  void Indent(int Amount = 2)
  {
    IndentationLevel += Amount;
  }

  void Outdent(int Amount = 2)
  {
    IndentationLevel = max(0, IndentationLevel - Amount);
  }

  void WriteIndentation()
  {
    this.write(Indentation);
  }

  alias OutFile this;
}

struct SpecialCaseData
{
  alias EmitterCallbackFunc = void function(ref char[] Source, FormattedOutput Output);

  EmitterCallbackFunc* EmitterCallback;
}

SpecialCaseData[] SpecialCases;
FormattedOutput Log;

BlockData ParseHashDefine(ref char[] Source)
{
  auto Result = BlockData(CodeType.HashDefine);
  Result.HashDefine = HashDefineData.init;

  // Skip '#define'
  auto Prefix = Source.FastForwardUntil!(Char => Char.isWhite);
  Log.write(Log.Indentation);
  Log.writeln("Skipped: ", Prefix);

  Source.SkipWhiteSpace();

  char Delimiter;
  Result.HashDefine.Name = Source.FastForwardUntil!(Char => Char.IsDelimiter)(&Delimiter);
  Log.write(Log.Indentation);
  Log.writeln("Name: ", Result.HashDefine.Name);

  Log.Indent();

  if(Delimiter == '(')
  {
    Result.HashDefine.HasParens = true;
    Log.write(Log.Indentation);
    Log.writeln("Found parens.");

    char[] Param;
    do
    {
      Param = Source.FastForwardUntil!(Char => Char == ',' || Char == ')')(&Delimiter).strip;
      if(Param.length)
      {
        Result.HashDefine.Parameters ~= Param;
        Log.writeln("Param: ", Param);
      }
    } while(Delimiter != ')');
  }

  Log.Outdent();

  char LastCharOfThisLine;
  do
  {
    auto Line = Source.FastForwardUntil!(Char => Char == '\n' || Char == '\\')(&LastCharOfThisLine).strip;
    Log.write(Log.Indentation);
    Log.writeln("Line: ", Line);
    Log.write(Log.Indentation);
    Log.writefln("Last char of that line: '%c'", LastCharOfThisLine);

    if(Line.length)
    {
      Result.HashDefine.Body ~= Line ~ "\n";
    }
  } while(Source.length && LastCharOfThisLine == '\\');

  Result.HashDefine.Body = Result.HashDefine.Body.strip();
  Log.write(Log.Indentation);
  Log.writeln("Body: ", Result.HashDefine.Body);

  return Result;
}

BlockData ParseEnum(ref char[] Source)
{
  auto Result = BlockData(CodeType.Enum);
  Result.Enum = EnumData.init;

  // Skip 'typedef'
  auto Prefix1 = Source.FastForwardUntil!(Char => Char.isWhite);
  Log.write(Log.Indentation);
  Log.writeln("Skipped: ", Prefix1);

  Source.SkipWhiteSpace();

  // Skip 'enum'
  auto Prefix2 = Source.FastForwardUntil!(Char => Char.isWhite);
  Log.write(Log.Indentation);
  Log.writeln("Skipped: ", Prefix2);

  // Read everything between 'enum' and '{'
  auto PseudoName = Source.FastForwardUntil!(Char => Char == '{').strip;
  Log.write(Log.Indentation);
  Log.writeln("Pseudo Name: ", PseudoName);

  Log.Indent();

  while(true)
  {
    Result.Enum.Entries.length++;
    auto Entry = &Result.Enum.Entries[$ - 1];
    scope(exit)
    {
      Log.write(Log.Indentation);
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
  Log.write(Log.Indentation);
  Log.writeln("Actual Name: ", Result.Enum.Name);

  return Result;
}

BlockData ParseStruct(ref char[] Source)
{
  auto Result = BlockData(CodeType.Struct);
  Result.Struct = StructData.init;
  scope(failure) Log.writeln("Failed struct so far: ", Result.Struct);

  // Skip 'typedef'
  Source.FastForwardUntil!(Char => Char.isWhite);

  Source.SkipWhiteSpace();

  // Skip 'struct'
  Source.FastForwardUntil!(Char => Char.isWhite);

  // Read everything between 'struct' and '{'
  auto PseudoName = Source.FastForwardUntil!(Char => Char == '{').strip;
  Log.write(Log.Indentation);
  Log.writeln("Pseudo name: ", PseudoName);
  Log.write(Log.Indentation);
  Log.writeln("Struct members:");

  Log.Indent();

  while(true)
  {
    Source.SkipWhiteSpace();

    auto FirstToken = Source.FastForwardUntil!(Char => Char.isWhite);

    if(FirstToken == "}") break;

    Result.Struct.Entries.length++;
    auto Entry = &Result.Struct.Entries[$ - 1];

    Entry.Type = FirstToken;
    Log.write(Log.Indentation);
    Log.writeln("Type: ", Entry.Type);

    Source.SkipWhiteSpace();

    char LastChar;
    Entry.Name = Source.FastForwardUntil!(Char => Char == ';' || Char == '[')(&LastChar).strip;
    Log.write(Log.Indentation);
    Log.writeln("Name: ", Entry.Name);
    if(LastChar == '[')
    {
      // Read the number between the brackets [ 123 ]
      Entry.ArrayCount = Source.FastForwardUntil!(Char => Char == ']').strip.to!int;
      Log.write(Log.Indentation);
      Log.writeln("Array count: ", Entry.ArrayCount);

      // Skip ';'
      Source.FastForwardUntil!(Char => Char == ';');
    }
  }

  Log.Outdent();

  // Extract the actual name.
  Result.Struct.Name = Source.FastForwardUntil!(Char => Char == ';').strip;
  Log.write(Log.Indentation);
  Log.writeln("Struct name: ", Result.Struct.Name);

  return Result;
}

BlockData ParseInterface(ref char[] Source)
{
  auto Result = BlockData(CodeType.Interface);
  Result.Interface = InterfaceData.init;

  Source.FastForwardUntil!(Char => Char == '"');
  Result.Interface.GUIDString = Source.FastForwardUntil!(Char => Char == '"');
  Source.FastForwardUntil!(Char => Char == ')');

  Log.write(Log.Indentation);
  Log.writeln("GUID: ", Result.Interface.GUIDString);

  Source.SkipWhiteSpace();

  Result.Interface.Name = Source.FastForwardUntil!(Char => Char == ':').strip;
  Log.write(Log.Indentation);
  Log.writeln("Name: ", Result.Interface.Name);

  Source.SkipWhiteSpace();

  assert(Source.FastForwardUntil!(Char => Char.isWhite).strip == "public");

  Result.Interface.ParentName = Source.FastForwardUntil!(Char => Char == '{').strip;
  Log.write(Log.Indentation);
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
  Log.write(Log.Indentation);
  Log.writeln("Return type: ", Result.Function.ReturnType);

  // Skip the call type (WINAPI, STDMETHODCALL, ...)
  auto CallType = Source.FastForwardUntil!(Char => Char.isWhite);
  Log.write(Log.Indentation);
  Log.writeln("Call type: ", CallType);

  Result.Function.Name = Source.FastForwardUntil!(Char => Char == '(');
  Log.write(Log.Indentation);
  Log.writeln("Name: ", Result.Function.Name);

  Log.Indent();

  while(true)
  {
    Result.Function.Params.length++;
    auto Param = &Result.Function.Params[$ - 1];
    scope(exit)
    {
      Log.write(Log.Indentation);
      Log.writeln("+++ Param: ", *Param);
    }

    Source.SkipWhiteSpace();

    if(Source.front == '/')
    {
      // Skip leading '/*'
      Source.popFrontN(2);

      // Skip until trailing '/' and omit '*' at the end of the result.
      Param.Comment = Source.FastForwardUntil!(Char => Char == '/')[0 .. $-1].strip;
      Log.write(Log.Indentation);
      Log.writeln("Param comment: ", Param.Comment);

      Source.SkipWhiteSpace();
    }

    if(Source.front == '_')
    {
      // It is assumed that there's no space in the '_Abc_Def_(Xyz,UWS)' annotations.
      Param.Annotation = Source.FastForwardUntil!(Char => Char.isWhite);
      Source.SkipWhiteSpace();
    }

    Log.write(Log.Indentation);
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

    Log.write(Log.Indentation);
    Log.writeln("Param type: ", Param.Type);
    assert(Param.Type.length);

    char Delimiter;
    Param.Name = Source.FastForwardUntil!(Char => Char == ',' || Char == ')')(&Delimiter);

    Log.write(Log.Indentation);
    Log.writeln("Param name: ", Param.Name);

    if(Delimiter == ')') break;
    assert(Delimiter == ',');
  }

  Log.Outdent();

  // Skip trailing ';'
  Source.FastForwardUntil!(Char => Char == ';');

  return Result;
}

BlockData ParseAlias(ref char[] Source)
{
  auto Result = BlockData(CodeType.Alias);
  Result.Alias = AliasData.init;

  Source.SkipWhiteSpace();

  Source.FastForwardUntil!(Char => Char.isWhite);

  Result.Alias.OldName = Source.FastForwardUntil!(Char => Char.isWhite);
  Log.write(Log.Indentation);
  Log.writeln("Old name: ", Result.Alias.OldName);

  Result.Alias.NewName = Source.FastForwardUntil!(Char => Char == ';');
  Log.write(Log.Indentation);
  Log.writeln("New name: ", Result.Alias.NewName);

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

  {
    auto TempSource = Source.find("#ifndef");
    TempSource.popFrontN("#ifndef".length);
    TempSource.SkipWhiteSpace();
    auto GuardID = TempSource.FastForwardUntil!(Char => Char.isWhite);
    TempSource = TempSource.find("#define");
    TempSource.popFrontN("#define".length);
    TempSource.SkipWhiteSpace();
    if(TempSource.FastForwardUntil!(Char => Char.isWhite) == GuardID)
    {
      Source = TempSource;
    }
  }

  while(Source.length)
  {
    while(true)
    {
      Source.SkipWhiteSpace();

      if(Source.startsWith("#if"))
      {
        Source.popFrontN(3);
        auto FirstEndif = Source.find("#endif");
        auto FirstIf = Source.find("#if");
        if(FirstIf.ptr < FirstEndif.ptr)
        {
          Source = FirstIf;
          continue;
        }

        assert(FirstEndif.length);

        Source = FirstEndif["#endif".length .. $];
        Source.SkipWhiteSpace();
      }
      else if(Source.startsWith("#include") || Source.startsWith("//") || Source.startsWith("#endif"))
      {
        Source.FastForwardUntil!(Char => Char == '\n');
      }
      else if(Source.startsWith("/*"))
      {
        Source = Source.find("*/");
      }
      else
      {
        break;
      }
    }

    auto SourceCopy = Source;
    char[] Token = SourceCopy.FastForwardUntil!(Char => Char.IsDelimiter).strip;
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
          default:       Result ~= ParseAlias(Source);  break;
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
    Output.write(Output.Indentation);
    Output.writef("pure nothrow @nogc auto %s", HashDefine.Name);

    Output.write("(");
    foreach(Index, ref Param; HashDefine.Parameters)
    {
      Output.writef("%sType", Param);
      if(Index < HashDefine.Parameters.length - 1)
      {
        Output.write(", ");
      }
    }
    Output.write(")");

    Output.write("(");
    foreach(Index, ref Param; HashDefine.Parameters)
    {
      Output.writef("auto ref %sType %s", Param, Param);
      if(Index < HashDefine.Parameters.length - 1)
      {
        Output.write(", ");
      }
    }
    Output.write(")", Output.Newline);

    Output.write(Output.Indentation);
    Output.write("{", Output.Newline);
    Output.Indent();

    Output.write(Output.Indentation);
    Output.writef("return %s;%s", HashDefine.Body, Output.Newline);

    Output.Outdent();
    Output.write(Output.Indentation);
    Output.write("}", Output.Newline);
  }
  else
  {
    // Emit enum constant
    auto Body = HashDefine.Body.strip;
    if(Body.front == '(')
    {
      Body.popFront();
      Body = Body.FastForwardUntil!(Char => Char == ')').strip;
    }
    if(Body.endsWith("UL")) Body = Body[0 .. $-2];
    if(Body.endsWith("L"))  Body = Body[0 .. $-1];
    Output.writef("%-(%s%)enum %s = %s;%s", Output.Indentation, HashDefine.Name, Body, Output.Newline);
  }
}

void EmitEnum(ref EnumData Enum, FormattedOutput Output)
{
  Output.writef("%-(%s%)enum %s%s%-(%s%){%s", Output.Indentation, Enum.Name, Output.Newline, Output.Indentation, Output.Newline);
  Output.Indent();

  auto Entries = Enum.Entries.dup;
  auto Prefix = commonPrefix(Enum.Name, Entries[0].Key);

  ulong MaxLen;
  foreach(ref Entry; Entries)
  {
    auto Key = Entry.Key[Prefix.length .. $];

    if(Key.front.isDigit)
    {
      // Make sure we have a leading '_' for enum keys that start with a
      // digit.
      if(Prefix.back == '_')
      {
        Key = Entry.Key[Prefix.length - 1 .. $];
      }
      else
      {
        Key = "_" ~ Key;
      }
      assert(Key.front == '_');
    }
    else if(Key.front == '_')
    {
      Key.popFront();
    }

    Entry.Key = Key;
    MaxLen = max(MaxLen, Key.length);
  }

  foreach(ref Entry; Entries)
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

  if(Prefix != Enum.Name)
  {
    Output.writef("%salias %s = %s;%s", Output.Indentation, Prefix[0 .. $-1], Enum.Name, Output.Newline);
  }
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
    EmitFunction(Function, Output, No.AddExternWindows);
  }

  Output.Outdent();
  Output.writef("%-(%s%)}%s", Output.Indentation, Output.Newline);
}

void EmitFunction(ref FunctionData Function, FormattedOutput Output, Flag!"AddExternWindows" AddExternWindows = Yes.AddExternWindows)
{
  scope(failure) Log.writeln("Failure emitting function: ", Function);

  Output.write(Output.Indentation);
  if(AddExternWindows) Output.write("extern(Windows) ");
  Output.writef("%s %s(", Function.ReturnType, Function.Name);

  Output.Indent();
  foreach(ref Param; Function.Params)
  {
    scope(failure) Log.writeln("Failure emitting param: ", Param);
    Output.write(Output.Newline);
    Output.write(Output.Indentation);

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
  Output.write(Output.Indentation);
  Output.writef(");%s%s", Output.Newline, Output.Newline);
}

void EmitAlias(ref AliasData Alias, FormattedOutput Output)
{
  Output.write(Output.Indentation);
  Output.writef("alias %s = %s;%s", Alias.NewName, Alias.OldName, Output.Newline);
}

void EmitD3DCOLORVALUE(ref AliasData Alias, FormattedOutput Output)
{
  assert(Alias.OldName == "D3DCOLORVALUE");
  Output.write(Output.Indentation, "struct ", Alias.NewName, Output.Newline,
               Output.Indentation, "{", Output.Newline);

  Output.Indent();

  Output.write(Output.Indentation, "float r;", Output.Newline,
               Output.Indentation, "float g;", Output.Newline,
               Output.Indentation, "float b;", Output.Newline,
               Output.Indentation, "float a;", Output.Newline);

  Output.Outdent();

  Output.write(Output.Indentation, "}", Output.Newline);
}

void EmitBlocks(BlockData[] Blocks, FormattedOutput Output)
{
  foreach(ref Block; Blocks)
  {
    Output.write(Output.Newline);

    final switch(Block.Type)
    {
      case CodeType.HashDefine:
      {
        EmitHashDefine(Block.HashDefine, Output);
        break;
      }
      case CodeType.Enum:
      {
        EmitEnum(Block.Enum, Output);
        break;
      }
      case CodeType.Struct:
      {
        EmitStruct(Block.Struct, Output);
        break;
      }
      case CodeType.Interface:
      {
        EmitInterface(Block.Interface, Output);
        break;
      }
      case CodeType.Function:
      {
        EmitFunction(Block.Function, Output);
        break;
      }
      case CodeType.Alias:
      {
        if(Block.Alias.OldName == "D3DCOLORVALUE")
        {
          EmitD3DCOLORVALUE(Block.Alias, Output);
        }
        else
        {
          EmitAlias(Block.Alias, Output);
        }

        break;
      }
      case CodeType.INVALID: assert(0, Block.Type.to!string);
    }
  }
}

void main(string[] Args)
{
  const Program = Args[0];
  Args = Args[1 .. $];

  assert(Args.length == 2, "Need 2 arguments.");

  Log = new FormattedOutput();
  Log.OutFile = stderr;

  auto InFilename  = Args[0];
  auto OutFilename = Args[1];

  char[] InputBuffer = InFilename.readText!(char[]);

  auto Blocks = Parse(InputBuffer);

  auto Output = new FormattedOutput();
  if(OutFilename == "-")
  {
    Output.OutFile = stdout;
  }
  else
  {
    Output.OutFile.open(OutFilename, "w");
  }

  Log.writefln("%-(%s%)", "=".repeat(72));

  Output.write("// Original file name: ", InFilename, Output.Newline);
  Output.write("// Conversion date: ", Clock.currTime, Output.Newline);
  Output.write(Output.Newline);

  EmitBlocks(Blocks, Output);
}
