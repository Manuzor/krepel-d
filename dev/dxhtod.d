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
  char[] Name;
}

// HRESULT WINAPI CreateDXGIFactory1(REFIID riid, _COM_Outptr_ void **ppFactory);
struct FunctionData
{
  static struct Param
  {
    char[] Type;
    char[] Name;
  }

  char[] ReturnType;
  char[] Name;
  Param[] Params;
}

BlockData ParseHashDefine(ref char[] Source)
{
  auto Result = BlockData(CodeType.HashDefine);
  Result.HashDefine = HashDefineData.init;

  // Skip '#define'
  auto Prefix = Source.FastForwardUntil!(Char => Char.isWhite);
  stderr.writeln("  Skipped: ", Prefix);

  // Skip white space
  Source = Source.stripLeft();

  char Delimiter;
  Result.HashDefine.Name = Source.FastForwardUntil!(Char => Char.IsDelimiter)(&Delimiter);
  stderr.writeln("  Name: ", Result.HashDefine.Name);

  if(Delimiter == '(')
  {
    Result.HashDefine.HasParens = true;
    stderr.writeln("  Found parens. TODO: More printing in here!");

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
    stderr.writeln("  Line: ", Line);
    stderr.writefln("  Last char of that line: '%c'", LastCharOfThisLine);

    if(Line.length)
    {
      Result.HashDefine.Body ~= Line ~ "\n";
    }
  } while(Source.length && LastCharOfThisLine == '\\');

  Result.HashDefine.Body = Result.HashDefine.Body.strip();
  stderr.writeln("  Body: ", Result.HashDefine.Body);

  return Result;
}

BlockData ParseEnum(ref char[] Source)
{
  auto Result = BlockData(CodeType.Enum);
  Result.Enum = EnumData.init;

  // Skip 'typedef'
  auto Prefix1 = Source.FastForwardUntil!(Char => Char.isWhite);
  stderr.writeln("  Skipped: ", Prefix1);

  // Skip white space
  Source = Source.stripLeft();

  // Skip 'enum'
  auto Prefix2 = Source.FastForwardUntil!(Char => Char.isWhite);
  stderr.writeln("  Skipped: ", Prefix2);

  // Read everything between 'enum' and '{'
  auto PseudoName = Source.FastForwardUntil!(Char => Char == '{').strip;
  stderr.writeln("  Pseudo Name: ", PseudoName);

  while(true)
  {
    Result.Enum.Entries.length++;
    auto Entry = &Result.Enum.Entries[$ - 1];
    scope(exit) stderr.writeln("    Entry: ", *Entry);
    char Delimiter;
    Entry.Key = Source.FastForwardUntil!(Char => Char == '=' || Char == ',' || Char == '}')(&Delimiter).strip;
    if(Delimiter == '=')
    {
      Entry.Value = Source.FastForwardUntil!(Char => Char == ',' || Char == '}')(&Delimiter).strip;
    }

    if(Delimiter == '}') break;
    assert(Delimiter == ',');
  }

  // Extract the actual name.
  Result.Enum.Name = Source.FastForwardUntil!(Char => Char == ';').strip;
  stderr.writeln("  Actual Name: ", Result.Enum.Name);

  return Result;
}

BlockData ParseStruct(ref char[] Source)
{
  auto Result = BlockData(CodeType.Struct);
  Result.Struct = StructData.init;

  // Skip 'typedef'
  Source.FastForwardUntil!(Char => Char.isWhite);

  // Skip white space
  Source = Source.stripLeft();

  // Skip 'struct'
  Source.FastForwardUntil!(Char => Char.isWhite);

  // Read everything between 'struct' and '{'
  auto PseudoName = Source.FastForwardUntil!(Char => Char == '{').strip;

  while(true)
  {
    // Skip white space
    Source = Source.stripLeft();

    auto FirstToken = Source.FastForwardUntil!(Char => Char.isWhite);

    if(FirstToken == "}") break;

    Result.Struct.Entries.length++;
    auto Entry = &Result.Struct.Entries[$ - 1];

    Entry.Type = FirstToken;

    // Skip white space
    Source = Source.stripLeft();

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
  return Result;
}

BlockData ParseFunction(ref char[] Source)
{
  auto Result = BlockData(CodeType.Function);
  Result.Function = FunctionData.init;

  Result.Function.ReturnType = Source.FastForwardUntil!(Char => Char.isWhite);
  stderr.writeln("  Return type: ", Result.Function.ReturnType);

  // Skip the call type (WINAPI, STDMETHODCALL, ...)
  auto CallType = Source.FastForwardUntil!(Char => Char.isWhite);
  stderr.writeln("  Call type: ", CallType);

  Result.Function.Name = Source.FastForwardUntil!(Char => Char.IsDelimiter);
  stderr.writeln("  Name: ", Result.Function.Name);

  char Delimiter;
  while(true)
  {
    Result.Function.Params.length++;
    auto Param = &Result.Function.Params[$ - 1];
    scope(exit) stderr.writeln("    Param: ", *Param);

    auto ParamSource = Source.FastForwardUntil!(Char => Char == ',' || Char == ')')(&Delimiter);

    // Skip white space
    Source = Source.stripLeft();

    while(ParamSource.front == '_')
    {
      ParamSource.FastForwardUntil!(Char => Char.isWhite);

      // Skip white space
      Source = Source.stripLeft();
    }

    ulong LastTypeDelimiterIndex;
    foreach(Index, Char; ParamSource)
    {
      if(Char.isWhite || Char == '*')
      {
        LastTypeDelimiterIndex = Index;
      }
    }

    LastTypeDelimiterIndex++;
    Param.Type = ParamSource[0 .. LastTypeDelimiterIndex].strip.removechars(" ");
    Param.Name = ParamSource[LastTypeDelimiterIndex .. $].strip;

    if(Delimiter == ')') break;
    assert(Delimiter == ',');
  }

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
  if(NewSource.empty) return NewSource;
  auto Result = Source[0 .. $ - NewSource.length];
  if(NewSource.length)
  {
    if(LastCharOutPtr) *LastCharOutPtr = NewSource[0];
    NewSource.popFront();
  }
  Source = NewSource;
  return Result;
}

BlockData[] Parse(ref char[] Source)
{
  typeof(return) Result;

  char[] Token;

  while(Source.length)
  {
    // Skip white space
    Source = Source.stripLeft();

    auto SourceCopy = Source;
    Token = SourceCopy.FastForwardUntil!(Char => Char.IsDelimiter).strip;
    if(Token.length == 0) break;

    stderr.writeln("Token: ", Token);

    switch(Token)
    {
      case "#define": Result ~= ParseHashDefine(Source); break;
      case "typedef":
      {
        // Skip white space
        Source = Source.stripLeft();

        Token = SourceCopy.FastForwardUntil!(Char => Char.IsDelimiter).strip;
        stderr.writeln("=> ", Token);
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

    stderr.writeln("----------");
  }

  return Result;
}

class ConversionOutput
{
  int IndentationLevel;
  string Newline = "\n";

  File* OutFilePtr;

  @property auto Indentation() { return " ".repeat(IndentationLevel); }
  void Indent(int Amount = 2) { IndentationLevel += Amount; }
  void Outdent(int Amount = 2) { IndentationLevel -= Amount; }

  @property ref File OutFile() { return *OutFilePtr; }

  alias OutFile this;
}

void EmitHashDefine(ref BlockData Block, ConversionOutput Output)
{
  assert(Block.Type == CodeType.HashDefine);

  if(Block.HashDefine.HasParens)
  {
    // Emit D function
  }
  else
  {
    // Emit enum constant
    // TODO(Manu): Clean up HashDefine.Body
    Output.writef("%-(%s%)enum %s = %s;%s", Output.Indentation, Block.HashDefine.Name, Block.HashDefine.Body, Output.Newline);
  }
}

void EmitEnum(ref BlockData Block, ConversionOutput Output)
{
  assert(Block.Type == CodeType.Enum);

  Output.writef("%-(%s%)enum %s%s%-(%s%){%s", Output.Indentation, Block.Enum.Name, Output.Newline, Output.Indentation, Output.Newline);
  Output.Indent();

  ulong MaxLen;
  foreach(ref Entry; Block.Enum.Entries[])
  {
    MaxLen = max(MaxLen, Entry.Key.length);
  }

  foreach(ref Entry; Block.Enum.Entries[])
  {
    Output.writef("%-(%s%)%s", Output.Indentation, Entry.Key);
    if(Entry.Value.length)
    {
      Output.writef("%-(%s%) = %s", " ".repeat(MaxLen - Entry.Key.length), Entry.Value);
    }
    Output.write(",", Output.Newline);
  }
  Output.Outdent();
  Output.writef("%-(%s%)}%s%s", Output.Indentation, Output.Newline, Output.Newline);
}

void EmitStruct(ref BlockData Block, ConversionOutput Output)
{
  assert(Block.Type == CodeType.Struct);

  Output.writef("%-(%s%)struct %s%s%-(%s%){%s", Output.Indentation, Block.Struct.Name, Output.Newline, Output.Indentation, Output.Newline);
  Output.Indent();

  //ulong MaxLen;
  //foreach(ref Entry; Block.Struct.Entries[])
  //{
  //  MaxLen = max(MaxLen, Entry.Type.length);
  //}

  foreach(ref Entry; Block.Struct.Entries[])
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
  Output.writef("%-(%s%)}%s%s", Output.Indentation, Output.Newline, Output.Newline);
}

void EmitInterface(ref BlockData Block, ConversionOutput Output)
{
}

void EmitFunction(ref BlockData Block, ConversionOutput Output)
{
  assert(Block.Type == CodeType.Function);
  Output.writef("%-(%s%)extern(Windows) %s %s(", Output.Indentation, Block.Function.ReturnType, Block.Function.Name);
  auto ParamPrefix = " ".repeat(Output.IndentationLevel + "extern(Windows)".length + 1 + Block.Function.ReturnType.length + Block.Function.Name.length + 1);

  foreach(ref Param; Block.Function.Params)
  {
    Output.writef("%s %s,%s%-(%s%)", Param.Type, Param.Name, Output.Newline, ParamPrefix);
  }

  Output.writef(");%s%s", Output.Newline, Output.Newline);
}

void EmitBlocks(BlockData[] Blocks, ConversionOutput Output)
{
  foreach(ref Block; Blocks)
  {
    final switch(Block.Type)
    {
      case CodeType.HashDefine: EmitHashDefine(Block, Output); break;
      case CodeType.Enum:       EmitEnum(Block, Output);       break;
      case CodeType.Struct:     EmitStruct(Block, Output);     break;
      case CodeType.Interface:  EmitInterface(Block, Output);  break;
      case CodeType.Function:   EmitFunction(Block, Output);   break;
      case CodeType.INVALID: assert(0);
    }
  }
}

void main(string[] Args)
{
  const Program = Args[0];
  Args = Args[1 .. $];

  assert(Args.length == 1, "Need 1 argument.");

  auto Output = new ConversionOutput();
  Output.OutFilePtr = &stdout;

  char[] InputBuffer = Args[0].readText!(char[]);

  auto Blocks = Parse(InputBuffer);

  EmitBlocks(Blocks, Output);
}
