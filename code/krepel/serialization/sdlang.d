module krepel.serialization.sdlang;

import krepel;
import krepel.string : UString;
import krepel.container;
import krepel.memory.reference_counting;
import krepel.system;

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
  bool IsAnonymous;
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
    string NumberSource;
    double Real;
    bool   Boolean;
    void*  Binary;   // TODO(Manu)
  }

  auto opCast(To)() const
  {
    //pragma(msg, "Casting SDL literal to: " ~ To.stringof);

    static if(is(To == string))
    {
      assert(Type == SDLLiteralType.String, "Cannot convert this value to " ~ To.stringof);
      return String;
    }
    else static if(Meta.IsNumeric!To)
    {
      assert(Type == SDLLiteralType.Number, "Cannot convert this value to " ~ To.stringof);
      auto Source = NumberSource[];

      static if(Meta.IsIntegral!To)
      {
        import krepel.conversion.parse_integer;
        auto ParseResult = ParseInteger!long(Source);
        assert(ParseResult.Success);
        return cast(To)ParseResult;
      }
      else static if(Meta.IsFloatingPoint!To)
      {
        import krepel.conversion.parse_float;

        auto ParseResult = ParseFloat(Source);
        assert(ParseResult.Success);
        return cast(To)ParseResult;
      }
      else
      {
        static assert(0, "Unsupported numeric type: " ~ To.stringof);
      }
    }
    else static if(is(To == bool))
    {
      assert(Type == SDLLiteralType.Boolean, "Cannot convert this value to " ~ To.stringof);
      return Boolean;
    }
    else
    {
      static assert(0, "Cannot convert an SDL literal to " ~ To.stringof);
    }
  }
}

enum SDLLiteralType
{
  INVALID,

  String,
  Number,
  Boolean,
  Binary,
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
                       string OpeningSequence, string ClosingSequence,
                       bool* OutFoundClosingSequence = null, int Depth = 1)
{
  const MaxNum = Source.length;
  size_t NumToAdvance;
  string String;
  while(NumToAdvance < MaxNum)
  {
    String = Source[NumToAdvance .. MaxNum];
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

  // It's possible the Source was exhausted before we found a closing sequence.
  if(OutFoundClosingSequence) *OutFoundClosingSequence = String.StartsWith(ClosingSequence);

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
bool ParseDocumentFromString(SDLDocument Document, string SourceString, ref ParsingContext Context)
{
  auto Source = SourceData(SourceString);
  with(Source.StartLocation) { Line = 1; Column = 1; SourceIndex = 0; }
  with(Source.EndLocation)   { Line = 0; Column = 0; SourceIndex = SourceString.length; }

  return Document.ParseDocumentFromSource(Source, Context);
}

bool ParseDocumentFromSource(SDLDocument Document, ref SourceData Source, ref ParsingContext Context)
{
  return Document.ParseInnerNodes(Source, Context, &Document.FirstChild);
}

bool ParseInnerNodes(SDLDocument Document, ref SourceData Source, ref ParsingContext Context,
                     SDLNode* FirstNode)
{
  if(FirstNode is null)
  {
    debug assert(false, "Need first node to parse inner nodes.");
    else return false;
  }

  if(!Document.ParseNode(Source, Context, FirstNode))
  {
    return false;
  }

  SDLNode PreviousNode = *FirstNode;
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
  scope(exit) if(Node) Document.Allocator.Delete(Node);

  //
  // Parse Node Name and Namespace
  //
  if(!Document.ParseNamespaceAndName(Source, Context, &Node.Namespace, &Node.Name))
  {
    assert(Node.Namespace.empty);
    Node.Name = "content";
    Node.IsAnonymous = true;
  }

  //Source.SkipWhiteSpaceAndComments(Context, No.ConsumeNewLine);

  //
  // Protect against anonymous nodes that only contain attributes.
  //
  if(Source.length && Source.front == '=')
  {
    if(Context.Log)
    {
      Context.Log.Warning("%s(%s,%s): Anonymous node must have at least 1 value. "
                          "It appears you've only given it attributes.",
                          Context.Origin,
                          Source.StartLocation.Line,
                          Source.StartLocation.Column);
    }
    return false;
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
    SDLAttribute Attribute;

    if(!Document.ParseAttribute(Source, Context, &Attribute))
    {
      // There are no more attributes.
      break;
    }

    Node.Attributes ~= Attribute;
  }

  // Check for validity by trying to parse a literal here. If it succeeds, the
  // document is malformed.
  {
    auto _ = Source;
    if(Document.ParseLiteral(_, Context, null))
    {
      if(Context.Log)
      {
        Context.Log.Warning("%s(%s,%s): Unexpected literal",
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
    Source.AdvanceBy(1);
    bool FoundClosingBrace;
    auto ChildSource = Source.ParseNested(Context, "{", "}", &FoundClosingBrace);

    if(!FoundClosingBrace && Context.Log)
    {
      Context.Log.Warning("%s(%s,%s): The list of child nodes is not closed properly with curly braces.",
                          Context.Origin,
                          OriginalSource.StartLocation.Line,
                          OriginalSource.StartLocation.Column);
    }

    if(!Document.ParseInnerNodes(ChildSource, Context, &Node.FirstChild))
    {
      // TODO(Manu): What to do if there are no inner nodes? Ignore it?
    }
  }

  if(OutNode)
  {
    *OutNode = Node;
    Node = null;
  }
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
    // TODO(Manu): Result.Binary = ???;
    if(Context.Log)
    {
      Context.Log.Warning("%s(%s,%s): Binary values are not supported for now.",
                          Context.Origin,
                          Source.StartLocation.Line,
                          Source.StartLocation.Column);
    }

    Source.AdvanceBy(1);
    auto String = Source.ParseUntil!(Str => Str.front == ']')(Context);

    Result.Type = SDLLiteralType.Binary;
    Result.Binary = null;
  }
  else
  {
    auto Word = Source.ParseUntil!(Str => Str.front.IsWhite)(Context);

    if(Word.front.IsDigit || Word.front == '.' || Word.front == '+' || Word.front == '-')
    {
      Result.Type = SDLLiteralType.Number;
      Result.NumberSource = Word;
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

bool ParseAttribute(SDLDocument Document,
                    ref SourceData OriginalSource,
                    ref ParsingContext Context,
                    SDLAttribute* OutAttribute)
{
  auto Source = OriginalSource;
  SDLAttribute Result;

  //
  // Parse the namespace and the name
  //
  if(!Document.ParseNamespaceAndName(Source, Context, &Result.Namespace, &Result.Name))
  {
    return false;
  }

  //Source.SkipWhiteSpaceAndComments(Context, No.ConsumeNewLine);

  if(Source.empty || Source.IsAtSemanticLineDelimiter(Context))
  {
    goto MalformedAttribute;
  }

  if(Source.front != '=')
  {
    if(Context.Log)
    {
      Context.Log.Warning("%s(%s,%s): Expected an attribute (key-value pair) here.",
                          Context.Origin,
                          Source.StartLocation.Line,
                          Source.StartLocation.Column);
    }
    return false;
  }

  // Skip the '=' character.
  Source.AdvanceBy(1);

  //Source.SkipWhiteSpaceAndComments(Context, No.ConsumeNewLine);

  if(Source.empty || Source.IsAtSemanticLineDelimiter(Context))
  {
    goto MalformedAttribute;
  }

  //
  // Parse the value
  //
  if(!Document.ParseLiteral(Source, Context, &Result.Value))
  {
    goto MalformedAttribute;
  }

  if(OutAttribute) *OutAttribute = Result;
  OriginalSource = Source;
  return true;

MalformedAttribute:
  if(Context.Log)
  {
    Context.Log.Warning("%s(%s,%s): Malformed attribute.",
                        Context.Origin,
                        Source.StartLocation.Line,
                        Source.StartLocation.Column);
  }
  return false;
}

bool ParseNamespaceAndName(SDLDocument Document,
                           ref SourceData OriginalSource,
                           ref ParsingContext Context,
                           SDLIdentifier* OutNamespace,
                           SDLIdentifier* OutName)
{
  auto Source = OriginalSource;

  SDLIdentifier Identifier;
  if(!Document.ParseIdentifier(Source, Context, &Identifier))
  {
    // TODO(Manu): Logging.
    return false;
  }

  //Source.SkipWhiteSpaceAndComments(Context, No.ConsumeNewLine);

  if(Source.empty || Source.front != ':')
  {
    if(OutName) *OutName = Identifier;
    OriginalSource = Source;
    return true;
  }

  assert(Source.front == ':');
  Source.AdvanceBy(1);

  //Source.SkipWhiteSpaceAndComments(Context, No.ConsumeNewLine);

  SDLIdentifier SecondIdentifier;
  if(!Document.ParseIdentifier(Source, Context, &SecondIdentifier))
  {
    // TODO(Manu): Logging.
    return false;
  }

  if(OutNamespace) *OutNamespace = Identifier;
  if(OutName) *OutName = SecondIdentifier;
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
  auto Context = ParsingContext("SDL Test 2", .Log);

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
  auto Context = ParsingContext("SDL Test 3", .Log);

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
  auto Context = ParsingContext("SDL Test 4", .Log);

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

  auto Context = ParsingContext("SDL Test 5", .Log);

  auto Document = StackAllocator.New!SDLDocument(StackAllocator);
  Document.ParseDocumentFromString(`foo "bar"`, Context);

  auto Node = Document.FirstChild;
  assert(Node);
  assert(Node.Name == "foo");
  assert(Node.Values.length == 1);
  assert(Node.Values[0].Type == SDLLiteralType.String);
  assert(Node.Values[0].String == "bar", Node.Values[0].String);
}

// Parse simple document with attributes
unittest
{
  SystemMemory System;
  auto Stack = StackMemory(System.Allocate(2.MiB, 1));
  scope(exit) System.Deallocate(Stack.Memory);
  auto StackAllocator = Wrap(Stack);

  auto Context = ParsingContext("SDL Test 6", .Log);

  auto Document = StackAllocator.New!SDLDocument(StackAllocator);
  Document.ParseDocumentFromString(`foo "bar" baz="qux"`, Context);

  auto Node = Document.FirstChild;
  assert(Node);
  assert(Node.Name == "foo");
  assert(Node.Values.length == 1);
  assert(Node.Values[0].Type == SDLLiteralType.String);
  assert(Node.Values[0].String == "bar", Node.Values[0].String);
  assert(Node.Attributes.length == 1);
  assert(Node.Attributes[0].Name == "baz", Node.Attributes[0].Name);
  assert(Node.Attributes[0].Value.Type == SDLLiteralType.String);
  assert(Node.Attributes[0].Value.String == "qux", Node.Attributes[0].Value.String);
}

// Parse document with multiple nodes
unittest
{
  SystemMemory System;
  auto Stack = StackMemory(System.Allocate(2.MiB, 1));
  scope(exit) System.Deallocate(Stack.Memory);
  auto StackAllocator = Wrap(Stack);

  auto Context = ParsingContext("SDL Test 7", .Log);

  auto Document = StackAllocator.New!SDLDocument(StackAllocator);
  auto Source = q"(
    foo "bar"
    baz "qux"
  )";
  Document.ParseDocumentFromString(Source, Context);

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

// Parse document with child nodes
unittest
{
  SystemMemory System;
  auto Stack = StackMemory(System.Allocate(2.MiB, 1));
  scope(exit) System.Deallocate(Stack.Memory);
  auto StackAllocator = Wrap(Stack);

  auto Context = ParsingContext("SDL Test 8", .Log);

  auto Document = StackAllocator.New!SDLDocument(StackAllocator);
  auto Source = q"(
    foo "bar" {
      baz "qux" {
        baaz "quux"
      }
    }
  )";
  Document.ParseDocumentFromString(Source, Context);

  auto Node = Document.FirstChild;
  assert(Node);
  assert(Node.Name == "foo");
  assert(Node.Values.length == 1);
  assert(Node.Values[0].Type == SDLLiteralType.String);
  assert(Node.Values[0].String == "bar", Node.Values[0].String);

  Node = Node.FirstChild;
  assert(Node);
  assert(Node.Name == "baz");
  assert(Node.Values.length == 1);
  assert(Node.Values[0].Type == SDLLiteralType.String);
  assert(Node.Values[0].String == "qux", Node.Values[0].String);

  Node = Node.FirstChild;
  assert(Node);
  assert(Node.Name == "baaz");
  assert(Node.Values.length == 1);
  assert(Node.Values[0].Type == SDLLiteralType.String);
  assert(Node.Values[0].String == "quux", Node.Values[0].String);
}

unittest
{
  SystemMemory System;
  auto Stack = StackMemory(System.Allocate(2.MiB, 1));
  scope(exit) System.Deallocate(Stack.Memory);
  auto StackAllocator = Wrap(Stack);

  auto Context = ParsingContext("SDL Test 9", .Log);

  auto Document = StackAllocator.New!SDLDocument(StackAllocator);
  Document.ParseDocumentFromString(`answer 42`, Context);

  auto Node = Document.FirstChild;
  assert(Node);
  assert(Node.Name == "answer");
  assert(Node.Values.length == 1);
  assert(Node.Values[0].Type == SDLLiteralType.Number);
  assert(cast(int)Node.Values[0] == 42, Node.Values[0].NumberSource);
}

/// Parse document from file.
unittest
{
  SystemMemory System;
  auto Stack = StackMemory(System.Allocate(2.MiB, 1));
  scope(exit) System.Deallocate(Stack.Memory);
  auto StackAllocator = Wrap(Stack);

  auto FileName = "../unittest/sdlang/full.sdl"w;
  auto File = OpenFile(StackAllocator, FileName);
  scope(exit) CloseFile(StackAllocator, File);

  // TODO(Manu): Once we have WString => UString conversion, use the filename
  // as context.
  auto Context = ParsingContext("Full", .Log);
  auto Document = StackAllocator.New!SDLDocument(StackAllocator);
  auto SourceString = StackAllocator.NewArray!char(File.Size);
  auto BytesRead = File.Read(SourceString);
  assert(BytesRead == SourceString.length);
  assert(Document.ParseDocumentFromString(cast(string)SourceString, Context), SourceString);


  // foo "bar"
  auto Node = Document.FirstChild;
  assert(Node);
  assert(Node.Name == "foo");
  assert(Node.Values.Count == 1);
  assert(cast(string)Node.Values[0] == "bar");
  assert(Node.Attributes.IsEmpty);

  // foo "bar" "baz"
  Node = Node.Next;
  assert(Node);
  assert(Node.Name == "foo");
  assert(Node.Values.Count == 2);
  assert(cast(string)Node.Values[0] == "bar");
  assert(cast(string)Node.Values[1] == "baz");
  assert(Node.Attributes.IsEmpty);

  // foo "bar" baz="qux"
  Node = Node.Next;
  assert(Node);
  assert(Node.Name == "foo");
  assert(Node.Values.Count == 1);
  assert(cast(string)Node.Values[0] == "bar");
  assert(Node.Attributes.Count == 1);
  assert(Node.Attributes[0].Name == "baz");
  assert(cast(string)Node.Attributes[0].Value == "qux");

  // foo "bar" baz="qux" baaz="quux"
  Node = Node.Next;
  assert(Node);
  assert(Node.Name == "foo");
  assert(Node.Values.Count == 1);
  assert(cast(string)Node.Values[0] == "bar");
  assert(Node.Attributes.Count == 2);
  assert(Node.Attributes[0].Name == "baz");
  assert(cast(string)Node.Attributes[0].Value == "qux");
  assert(Node.Attributes[1].Name == "baaz");
  assert(cast(string)Node.Attributes[1].Value == "quux");

  // foo bar="baz"
  Node = Node.Next;
  assert(Node);
  assert(Node.Name == "foo");
  assert(Node.Values.IsEmpty);
  assert(Node.Attributes.Count == 1);
  assert(Node.Attributes[0].Name == "bar");
  assert(cast(string)Node.Attributes[0].Value == "baz");

  // "foo"
  Node = Node.Next;
  assert(Node);
  assert(Node.IsAnonymous);
  assert(Node.Name == "content");
  assert(Node.Values.Count == 1);
  assert(cast(string)Node.Values[0] == "foo");
  assert(Node.Attributes.IsEmpty == 1);

  // "foo" bar="baz"
  Node = Node.Next;
  assert(Node);
  assert(Node.IsAnonymous);
  assert(Node.Name == "content");
  assert(Node.Values.Count == 1);
  assert(cast(string)Node.Values[0] == "foo");
  assert(Node.Attributes.Count == 1);
  assert(Node.Attributes[0].Name == "bar");
  assert(cast(string)Node.Attributes[0].Value == "baz");

  /*
    foo {
      baz "baz"
    }
  */
  Node = Node.Next;
  assert(Node);
  assert(Node.Name == "foo");
  assert(Node.Values.IsEmpty);
  assert(Node.Attributes.IsEmpty);
  {
    auto Child = Node.FirstChild;
    assert(Child);
    assert(Child.Name == "bar");
    assert(Child.Values.Count == 1);
    assert(cast(string)Child.Values[0] == "baz");
    assert(Child.Attributes.IsEmpty == 1);
  }

  /+
    foo /*
    This is
    what you get
    when you support multi-line comments
    in a whitespace sensitive language. */ bar="baz"
  +/
  Node = Node.Next;
  assert(Node);
  assert(Node.Name == "foo");
  assert(Node.Values.IsEmpty);
  assert(Node.Attributes.length == 1);
  assert(Node.Attributes[0].Name == "answer");
  assert(cast(int)Node.Attributes[0].Value == 42);

  /+
    foo 1 2 "bar" baz="qux" {
      inner { 0 1 2 }
      "anon value"
      "anon value with nesting" {
        another-foo "bar" 1337 -92 "baz" qux="baaz"
      }
    }
  +/
  Node = Node.Next;
  assert(Node);
  assert(Node.Name == "foo");
  assert(Node.Values.Count == 3);
  assert(cast(int)Node.Values[0] == 1);
  assert(cast(int)Node.Values[1] == 2);
  assert(cast(string)Node.Values[2] == "bar");
  assert(Node.Attributes.Count == 1);
  assert(Node.Attributes[0].Name == "baz");
  assert(cast(string)Node.Attributes[0].Value == "qux");
  {
    // inner { 0 1 2 }
    auto Child = Node.FirstChild;
    assert(Child);
    assert(Child.Name == "inner");
    assert(Child.Values.Count == 0);
    assert(Child.Attributes.Count == 0);
    {
      auto ChildsChild = Child.FirstChild;
      assert(ChildsChild);
      assert(ChildsChild.IsAnonymous);
      assert(ChildsChild.Values.Count == 3);
      assert(cast(int)ChildsChild.Values[0] == 0);
      assert(cast(int)ChildsChild.Values[1] == 1);
      assert(cast(int)ChildsChild.Values[2] == 2);
      assert(ChildsChild.Attributes.IsEmpty);
    }

    // "anon value"
    Child = Child.Next;
    assert(Child);
    assert(Child.IsAnonymous);
    assert(Child.Values.Count == 1);
    assert(cast(string)Child.Values[0] == "anon value");
    assert(Child.Attributes.IsEmpty);

    /+
      "anon value with nesting" {
        another-foo "bar" 1337 -92 "baz" qux="baaz"
      }
    +/
    Child = Child.Next;
    assert(Child);
    assert(Child.IsAnonymous);
    assert(Child.Name == "content");
    assert(Child.Values.Count == 1);
    assert(cast(string)Child.Values[0] == "anon value with nesting");
    assert(Child.Attributes.IsEmpty);
    {
      // another-foo "bar" 1337 -92 "baz" qux="baaz"
      auto ChildsChild = Child.FirstChild;
      assert(ChildsChild);
      assert(ChildsChild.Name == "another-foo");
      assert(ChildsChild.Values.Count == 4);
      assert(cast(string)ChildsChild.Values[0] == "bar");
      assert(cast(int)ChildsChild.Values[1] == 1337);
      assert(cast(int)ChildsChild.Values[2] == -92);
      assert(cast(string)ChildsChild.Values[3] == "baz");
      assert(ChildsChild.Attributes.Count == 1);
      assert(ChildsChild.Attributes[0].Name == "qux");
      assert(cast(string)ChildsChild.Attributes[0].Value == "baaz");
    }
  }

  assert(Node.Next is null);
}
