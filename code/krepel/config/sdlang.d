module krepel.config.sdlang;

import krepel;
import krepel.string : UString;
import krepel.container;
import krepel.memory.reference_counting;

/// Class that contains and manages the (parsed) content of an SDL document.
class SDLDocument
{
  /// Support reference counting.
  RefCountPayloadData RefCountPayload;

  /// The allocator used to allocate data for this document.
  ///
  /// Note: It's best to use a stack allocator, since the document itself will
  /// never deallocate individual nodes.
  IAllocator Allocator;

  /// The first node in the SDL document.
  SDLNode FirstChild;

  this(IAllocator Allocator)
  {
    this.Allocator = Allocator;
  }
}

class SDLNode
{
  /// The document this node belongs to.
  SDLDocument Document;

  //
  // Siblings
  //
  SDLNode Next;
  SDLNode Previous;

  //
  // Parents and Children
  //
  SDLNode Parent;
  SDLNode FirstChild;

  //
  // Node properties
  //
  SDLIdentifier Namespace;
  SDLIdentifier Name;
  Array!SDLLiteral Values;
  Array!SDLAttribute Attributes;

  this(SDLDocument Document)
  {
    assert(Document);

    this.Document = Document;
    this.Values.Allocator = Document.Allocator;
    this.Attributes.Allocator = Document.Allocator;
  }
}

struct SDLIdentifier
{
  const(char)[] Value;
  alias Value this;
}

struct SDLAttribute
{
  SDLIdentifier Namespace;
  SDLIdentifier Name;
  SDLLiteral Value;
}

struct SDLLiteral
{
  SDLLiteralType Type;
  union
  {
    string String;
    char   Character;
    int    Int32;
    long   Int64;
    float  Float;
    double Double;
    //cent   Decimal; // TODO(Manu): Not implemented in DMD.
    bool   Boolean;
    void*  Date;     // TODO(Manu)
    void*  DateTime; // TODO(Manu)
    void*  TimeSpan; // TODO(Manu)
    void*  Binary;   // TODO(Manu)
    typeof(null) Null;
  }
}

enum SDLLiteralType
{
  INVALID,

  String,
  Character,
  Int32,
  Int64,
  Float,
  Double,
  Decimal,
  Boolean,
  Date,
  DateTime,
  TimeSpan,
  Binary,
  Null,
}

//
// Parsing
//

struct SourceLocation
{
  long Line;        // 1-based.
  long Column;      // 1-based.
  long SourceIndex; // 0-based.
}

struct SourceData
{
  string Value;
  SourceLocation StartLocation;
  SourceLocation EndLocation; // Exclusive

  SourceData AdvanceBy(size_t N)
  {
    assert(N <= CurrentValue.length);
    auto Copy = this;

    foreach(_; 0 .. N) with(StartLocation)
    {
      if(Front == '\n')
      {
        Column = 1;
        Line++;
      }
      else
      {
        Column += 1;
      }

      SourceIndex++;
    }

    Copy.EndLocation = StartLocation;
    return Copy;
  }

  dchar Front() { return CurrentValue.front; }

  @property auto CurrentValue() { return Value[StartLocation.SourceIndex .. EndLocation.SourceIndex]; }

  alias CurrentValue this;
}

bool IsAtWhiteSpace(ref SourceData Source, ref ParsingContext Context)
{
  auto String = Source[];
  return String.length && String.front.IsWhite;
}

bool IsAtNewLine(ref SourceData Source, ref ParsingContext Context)
{
  auto String = Source[];
  return String.length && String.StartsWith("\n");
}

SourceData SkipWhiteSpace(ref SourceData OriginalSource, ref ParsingContext Context,
                          Flag!"ConsumeNewLine" ConsumeNewLine)
{
  auto Source = OriginalSource;

  while(Source.IsAtWhiteSpace(Context))
  {
    if(!ConsumeNewLine && Source.IsAtNewLine(Context)) break;
    Source.AdvanceBy(1);
  }

  auto NumToAdvance = Source.StartLocation.SourceIndex - OriginalSource.StartLocation.SourceIndex;
  return OriginalSource.AdvanceBy(NumToAdvance);
}

bool IsAtLineComment(ref SourceData Source, ref ParsingContext Context)
{
  auto String = Source[];
  return String.StartsWith("//") ||
         String.StartsWith("#") ||
         String.StartsWith("--");
}

bool IsAtMultiLineComment(ref SourceData Source, ref ParsingContext Context)
{
  auto String = Source[];
  return String.StartsWith("/*");
}

bool IsAtComment(ref SourceData Source, ref ParsingContext Context)
{
  return Source.IsAtLineComment(Context) || Source.IsAtMultiLineComment(Context);
}

SourceData SkipComments(ref SourceData OriginalSource, ref ParsingContext Context)
{
  auto Source = OriginalSource;

  while(true)
  {
    auto SourceString = Source[];
    if(Source.IsAtLineComment(Context))
    {
      auto NumToSkip = SourceString.length - SourceString.Find('\n').length;
      Source.AdvanceBy(Min(NumToSkip + 1, SourceString.length));
    }
    else if(Source.IsAtMultiLineComment(Context))
    {
      auto NumToSkip = SourceString.length - SourceString.Find("*/").length;
      Source.AdvanceBy(Min(NumToSkip + 2, SourceString.length));
    }
    else
    {
      break;
    }
  }

  auto NumToSkip = Source.StartLocation.SourceIndex - OriginalSource.StartLocation.SourceIndex;
  return OriginalSource.AdvanceBy(NumToSkip);
}

SourceData SkipWhiteSpaceAndComments(ref SourceData OriginalSource, ref ParsingContext Context,
                                     Flag!"ConsumeNewLine" ConsumeNewLine)
{
  auto Source = OriginalSource;

  while(true)
  {
    if(Source.IsAtWhiteSpace(Context))
    {
      if(!ConsumeNewLine && Source.IsAtNewLine(Context)) break;
      Source.SkipWhiteSpace(Context, ConsumeNewLine);
    }
    else if(Source.IsAtComment(Context))
    {
      Source.SkipComments(Context);
    }
    else
    {
      break;
    }
  }

  auto NumToSkip = Source.StartLocation.SourceIndex - OriginalSource.StartLocation.SourceIndex;
  return OriginalSource.AdvanceBy(NumToSkip);
}

/// Basically a new-line character or a semi-colon
bool IsAtSemanticLineDelimiter(ref SourceData Source, ref ParsingContext Context)
{
  return Source.length && Source.IsAtNewLine(Context) || Source.front == ';';
}

SourceData ParseUntil(alias Predicate)(ref SourceData Source, ref ParsingContext Context,)
{
  const MaxNum = Source.length;
  size_t NumToAdvance;
  while(NumToAdvance < MaxNum)
  {
    auto String = Source[NumToAdvance .. MaxNum];
    if(Predicate(String))
    {
      break;
    }

    ++NumToAdvance;
  }

  return Source.AdvanceBy(NumToAdvance);
}

SourceData ParseNested(ref SourceData Source, ref ParsingContext Context,
                       string OpeningSequence, string ClosingSequence, int Depth = 1)
{
  const MaxNum = Source.length;
  size_t NumToAdvance;
  while(NumToAdvance < MaxNum)
  {
    auto String = Source[NumToAdvance .. MaxNum];
    if(String.StartsWith(OpeningSequence))
    {
      NumToAdvance += OpeningSequence.length;
      Depth++;
    }
    else if(String.StartsWith(ClosingSequence))
    {
      Depth--;
      if(Depth <= 0) break;

      NumToAdvance += ClosingSequence.length;
    }
    else
    {
      NumToAdvance++;
    }
  }

  auto Result = Source.AdvanceBy(NumToAdvance);
  Source.AdvanceBy(Min(Source.length, ClosingSequence.length));
  return Result;
}

SourceData ParseEscaped(ref SourceData Source, ref ParsingContext Context,
                        dchar EscapeDelimiter, string DelimiterSequence, Flag!"ConsumeNewLine" ConsumeNewLine)
{
  const MaxNum = Source.length;
  size_t NumToAdvance;

  while(NumToAdvance < MaxNum)
  {
    auto String = Source[NumToAdvance .. MaxNum];
    if(String.front == EscapeDelimiter)
    {
      // TODO(Manu): Resolve escaped char. Skip for now.
      NumToAdvance = Min(NumToAdvance + 2, MaxNum);
    }
    else if(!ConsumeNewLine && String.front == '\n' ||
            String.StartsWith(DelimiterSequence))
    {
      break;
    }
    else
    {
      NumToAdvance++;
    }
  }

  auto Result = Source.AdvanceBy(NumToAdvance);
  Source.AdvanceBy(Min(Source.length, DelimiterSequence.length));
  return Result;
}

struct ParsingContext
{
  /// An identifier for the string source, e.g. a file name. Used in log
  /// messages.
  string Origin;

  LogData* Log;
}

/// Convenience overload to accept a plain string instead of SourceData.
bool Parse(SDLDocument Document, string SourceString, ref ParsingContext Context)
{
  auto Source = SourceData(SourceString);
  with(Source.StartLocation) { Line = 1; Column = 1; SourceIndex = 0; }
  with(Source.EndLocation)   { Line = 0; Column = 0; SourceIndex = SourceString.length; }

  return Document.Parse(Source, Context);
}

bool Parse(SDLDocument Document, ref SourceData Source, ref ParsingContext Context)
{
  if(!Document.ParseNode(Source, Context, &Document.FirstChild))
  {
    if(Context.Log)
    {
      Context.Log.Warning("%s(%s,%s) Unable to parse SDL document.",
                         Context.Origin,
                         Source.StartLocation.Line,
                         Source.StartLocation.Column);
    }
    return false;
  }

  SDLNode PreviousNode = Document.FirstChild;
  SDLNode NewNode;
  while(Document.ParseNode(Source, Context, &NewNode))
  {
    PreviousNode.Next = NewNode;
    NewNode.Previous = PreviousNode;
    PreviousNode = NewNode;
  }
  return true;
}

@property bool IsValidIdentifierFirstChar(dchar Char)
{
  return Char.IsAlpha || Char == '_';
}

@property bool IsValidIdentifierMiddleChar(dchar Char)
{
  return Char.IsValidIdentifierFirstChar ||
         Char.IsDigit ||
         Char == '-' ||
         Char == '.' ||
         Char == '$';
}

@property bool IsValidIdentifier(string Identifier)
{
  auto FirstChar = Identifier.front;
  if(!FirstChar.IsValidIdentifierFirstChar)
  {
    return false;
  }

  Identifier.popFront();
  foreach(Char; Identifier)
  {
    if(!Char.IsValidIdentifierMiddleChar)
    {
      return false;
    }
  }

  return true;
}

bool ParseIdentifier(SDLDocument Document,
                     ref SourceData OriginalSource,
                     ref ParsingContext Context,
                     SDLIdentifier* Result)
{
  auto Source = OriginalSource;
  Source.SkipWhiteSpaceAndComments(Context, No.ConsumeNewLine);

  if(Source.empty || Source.IsAtSemanticLineDelimiter(Context)) return false;

  auto String = Source[];
  if(!String.front.IsValidIdentifierFirstChar)
  {
    if(Context.Log)
    {
      Context.Log.Warning("%s(%s,%s) Invalid identifier ([A-z_][A-z0-9\\-_.$]*)",
                         Context.Origin,
                         Source.StartLocation.Line,
                         Source.StartLocation.Column);
    }
    return false;
  }

  String.popFront();
  size_t Count = 1; // 1 because the first character is valid and already consumed.

  while(String.length && String.front.IsValidIdentifierMiddleChar)
  {
    String.popFront();
    Count++;
  }

  if(Result) *Result = Source.AdvanceBy(Count);
  OriginalSource = Source;
  return true;
}

bool ParseNode(SDLDocument Document,
               ref SourceData OriginalSource,
               ref ParsingContext Context,
               SDLNode* OutNode)
{
  auto Source = OriginalSource;
  Source.SkipWhiteSpaceAndComments(Context, Yes.ConsumeNewLine);

  if(Source.empty) return false;

  auto Node = Document.Allocator.New!SDLNode(Document);

  SDLIdentifier Identifier;
  if(Document.ParseIdentifier(Source, Context, &Identifier))
  {
    //Source.SkipWhiteSpaceAndComments(Context, No.ConsumeNewLine);

    if(Source.empty)
    {
      Node.Name = Identifier;
    }
    else
    {
      auto CurrentChar = Source.front;
      if(CurrentChar == ':')
      {
        Node.Namespace = Identifier;
        if(Document.ParseIdentifier(Source, Context, &Identifier))
        {
          Node.Name = Identifier;
        }
        else
        {
          Node.Name = "content";
        }
      }
      else if(CurrentChar == '=')
      {
        if(Context.Log)
        {
          Context.Log.Warning("%s(%s,%s): Anonymous node must have at least 1 value.",
                              Context.Origin,
                              Source.StartLocation.Line,
                              Source.StartLocation.Column);
        }
        return false;
      }
      else
      {
        Node.Name = Identifier;
      }
    }
  }
  else
  {
    Node.Name = "content";
  }

  //
  // Parsing Values
  //
  while(true)
  {
    SDLLiteral Value;
    if(!Document.ParseLiteral(Source, Context, &Value))
    {
      break;
    }
    Node.Values.PushBack(Value);
  }

  //
  // Parsing Attributes
  //
  while(true)
  {
    if(!Document.ParseIdentifier(Source, Context, &Identifier))
    {
      // There are no more attributes.
      break;
    }

    //Source.SkipWhiteSpaceAndComments(Context, No.ConsumeNewLine);

    if(Source.front != '=')
    {
      if(Context.Log)
      {
        Context.Log.Warning("%s(%s,%s): Expected an attribute here.",
                            Context.Origin,
                            Source.StartLocation.Line,
                            Source.StartLocation.Column);
      }
      return false;
    }
  }

  //Source.SkipWhiteSpaceAndComments(Context, Yes.ConsumeNewLine);
  Source.SkipWhiteSpaceAndComments(Context, No.ConsumeNewLine);

  if(Source.length && Source.front == '{')
  {
    // TODO(Manu): Parse children.
  }

  if(OutNode) *OutNode = Node;
  else Document.Allocator.Delete(Node);
  OriginalSource = Source;
  return true;
}

bool ParseLiteral(SDLDocument Document,
                  ref SourceData OriginalSource,
                  ref ParsingContext Context,
                  SDLLiteral* OutLiteral)
{
  auto Source = OriginalSource;
  Source.SkipWhiteSpaceAndComments(Context, No.ConsumeNewLine);

  if(Source.empty || Source.IsAtSemanticLineDelimiter(Context)) return false;

  SDLLiteral Result;

  dchar CurrentChar = Source.front;
  if(CurrentChar == '"')
  {
    Source.AdvanceBy(1);
    auto String = Source.ParseEscaped(Context, '\\', `"`, No.ConsumeNewLine);

    Result.Type = SDLLiteralType.String;
    Result.String = String;
  }
  else if(CurrentChar == '`')
  {
    Source.AdvanceBy(1);
    auto String = Source.ParseUntil!(Str => Str.front == '`')(Context);

    Result.Type = SDLLiteralType.String;
    Result.String = String;
  }
  else if(CurrentChar == '[')
  {
    Result.Type = SDLLiteralType.Binary;
    // TODO(Manu): Result.Binary = ???;
  }
  else
  {
    auto Word = Source.ParseUntil!(Str => Str.front.IsWhite)(Context);

    if(Word.front.IsDigit || Word.front == '.')
    {

    }
    else if(Word == "true" || Word == "on")
    {
      Result.Type = SDLLiteralType.Boolean;
      Result.Boolean = true;
    }
    else if(Word == "false" || Word == "off")
    {
      Result.Type = SDLLiteralType.Boolean;
      Result.Boolean = false;
    }
    else if(Word == "null")
    {
      Result.Type = SDLLiteralType.Null;
      Result.Null = null;
    }
    else
    {
      if(Context.Log)
      {
        Context.Log.Warning("%s(%s,%s): Unable to parse value.",
                            Context.Origin,
                            Source.StartLocation.Line,
                            Source.StartLocation.Column);
      }
      return false;
    }
  }

  if(OutLiteral) *OutLiteral = Result;
  OriginalSource = Source;
  return true;
}

//
// Unit Tests
//

/// Add a global log for testing.
version(none)
shared static this()
{
  SystemMemory Mem;
  auto SysAllocator = Wrap(Mem);

  .Log = SysAllocator.New!LogData();
  .Log.Allocator = Wrap(*SysAllocator.New!SystemMemory());
  .Log.Sinks ~= ToDelegate(&StdoutLogSink);
  version(Windows)
  {
    import krepel.win32 : VisualStudioLogSink;
    .Log.Sinks ~= ToDelegate(&VisualStudioLogSink);
  }
}

version(unittest) private auto MakeSourceDataForTesting(string Value, size_t Offset)
{
  auto Source = SourceData(Value);
  with(Source.StartLocation) { Line = 1; Column = 1; SourceIndex = Offset; }
  with(Source.EndLocation)   { Line = 0; Column = 0; SourceIndex = Source.Value.length; }

  return Source;
}

// SkipWhiteSpaceAndComments
unittest
{
  auto Context = ParsingContext("SDL Test 1", .Log);

  {
    auto Source = MakeSourceDataForTesting("// hello\nworld", 0);

    auto Result = Source.SkipWhiteSpaceAndComments(Context, Yes.ConsumeNewLine);
    assert(Result.StartLocation.SourceIndex == 0, Result);
    assert(Result.EndLocation.SourceIndex == 9, Result);
    assert(Source.StartLocation.SourceIndex == 9, Source);
    assert(Source.EndLocation.SourceIndex == Source.Value.length, Source);
  }
  {
    auto Source = MakeSourceDataForTesting(q"(
// C++ style

/*
C style multiline
*/

/*foo=true*/

# Shell style

-- Lua style

text)", 0);

    auto Result = Source.SkipWhiteSpaceAndComments(Context, Yes.ConsumeNewLine);
    assert(Result.StartLocation.SourceIndex == 0, Result);
    assert(Result.EndLocation.SourceIndex == 83, Result);
    assert(Source.StartLocation.SourceIndex == 83, Source);
    assert(Source.EndLocation.SourceIndex == Source.Value.length, Source);
    assert(Source == "text", Source);
  }
}

// ParseUntil
unittest
{
  auto Context = ParsingContext("SDL Test 1", .Log);

  {
    auto Source = MakeSourceDataForTesting(`foo "bar"`, 0);

    auto Result = Source.ParseUntil!(S => S.front.IsWhite)(Context);
    assert(Result.StartLocation.SourceIndex == 0, Result);
    assert(Result.EndLocation.SourceIndex == 3, Result);
    assert(Source.StartLocation.SourceIndex == 3, Source);
    assert(Source.EndLocation.SourceIndex == Source.Value.length, Source);
  }
}

// ParseNested
unittest
{
  auto Context = ParsingContext("SDL Test 1", .Log);

  {
    auto Source = MakeSourceDataForTesting(`foo { bar }; baz`, 5);

    auto Result = Source.ParseNested(Context, "{", "}");
    assert(Result.StartLocation.SourceIndex == 5, Result);
    assert(Result.EndLocation.SourceIndex == 10, Result);
    assert(Source.StartLocation.SourceIndex == 11, Source);
    assert(Source.EndLocation.SourceIndex == Source.Value.length, Source);
  }
  {
    auto Source = MakeSourceDataForTesting(`foo { bar { baz } }; qux`, 5);

    auto Result = Source.ParseNested(Context, "{", "}");
    assert(Result.StartLocation.SourceIndex == 5, Result);
    assert(Result.EndLocation.SourceIndex == 18, Result);
    assert(Source.StartLocation.SourceIndex == 19, Source);
    assert(Source.EndLocation.SourceIndex == Source.Value.length, Source);
  }
}

// ParseEscaped
unittest
{
  auto Context = ParsingContext("SDL Test 1", .Log);

  {
    auto Source = MakeSourceDataForTesting(`foo "bar" "baz"`, 5);

    auto Result = Source.ParseEscaped(Context, '\\', `"`, Yes.ConsumeNewLine);
    assert(Result.StartLocation.SourceIndex == 5, Result);
    assert(Result.EndLocation.SourceIndex   == 8, Result);
    assert(Source.StartLocation.SourceIndex == 9, Source);
    assert(Source.EndLocation.SourceIndex   == Source.Value.length, Source);
  }

  {
    auto Source = MakeSourceDataForTesting(`foo "bar\"baz" "qux"`, 5);

    auto Result = Source.ParseEscaped(Context, '\\', `"`, Yes.ConsumeNewLine);
    assert(Result.StartLocation.SourceIndex == 5, Result);
    assert(Result.EndLocation.SourceIndex   == 13, Result);
    assert(Source.StartLocation.SourceIndex == 14, Source);
    assert(Source.EndLocation.SourceIndex   == Source.Value.length, Source);
  }
}

// Parse simple document
unittest
{
  SystemMemory System;
  auto Stack = StackMemory(System.Allocate(2.MiB, 1));
  scope(exit) System.Deallocate(Stack.Memory);
  auto StackAllocator = Wrap(Stack);

  auto Context = ParsingContext("SDL Test 1", .Log);

  auto Document = StackAllocator.New!SDLDocument(StackAllocator);
  Document.Parse(`foo "bar"`, Context);

  auto Node = Document.FirstChild;
  assert(Node);
  assert(Node.Name == "foo");
  assert(Node.Values.length == 1);
  assert(Node.Values[0].Type == SDLLiteralType.String);
  assert(Node.Values[0].String == "bar", Node.Values[0].String);
}

// Parse document with multiple nodes
unittest
{
  SystemMemory System;
  auto Stack = StackMemory(System.Allocate(2.MiB, 1));
  scope(exit) System.Deallocate(Stack.Memory);
  auto StackAllocator = Wrap(Stack);

  auto Context = ParsingContext("SDL Test 1", .Log);

  auto Document = StackAllocator.New!SDLDocument(StackAllocator);
  auto Source = q"(
    foo "bar"
    baz "qux"
  )";
  Document.Parse(Source, Context);

  auto Node = Document.FirstChild;
  assert(Node);
  assert(Node.Name == "foo");
  assert(Node.Values.length == 1);
  assert(Node.Values[0].Type == SDLLiteralType.String);
  assert(Node.Values[0].String == "bar", Node.Values[0].String);

  Node = Node.Next;
  assert(Node);
  assert(Node.Name == "baz");
  assert(Node.Values.length == 1);
  assert(Node.Values[0].Type == SDLLiteralType.String);
  assert(Node.Values[0].String == "qux", Node.Values[0].String);
}
