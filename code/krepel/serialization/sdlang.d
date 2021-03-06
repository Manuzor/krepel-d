module krepel.serialization.sdlang;

import krepel;
import krepel.system;

/// Class that contains and manages the (parsed) content of an SDL document.
class SDLDocument
{
  mixin RefCountSupport;

  /// The flat list of all nodes that you should never have to access directly.
  Array!SDLNode AllNodes;

  /// The root node of this document.
  ///
  /// Only serves as a container for all top-level nodes within the document.
  SDLNodeHandle Root;

  @property IAllocator Allocator() { return this.AllNodes.Allocator; }

  this(IAllocator Allocator)
  {
    this.AllNodes.Allocator = Allocator;
    this.AllNodes.Reserve(32);
    this.Root = CreateNode();
  }

  SDLNodeHandle CreateNode()
  {
    typeof(return) Result = void;
    Result.Document = this;
    Result.Index = this.AllNodes.Count;
    auto Node = &this.AllNodes.Expand();
    Node.Document = this;
    Node.Values.Allocator = this.Allocator;
    Node.Attributes.Allocator = this.Allocator;
    return Result;
  }
}

/// A reference to an SDL node.
///
/// It is discouraged to use raw pointers as the actual location in memory of
/// a node may change.
struct SDLNodeHandle
{
  SDLDocument Document;
  size_t Index;

  @property
  {
    inout(SDLNode)* _Ptr() inout
    {
      return this.Document is null ? null : &this.Document.AllNodes[this.Index];
    }

    bool IsValidHandle() const { return this._Ptr !is null; }
  }

  alias _Ptr this;
}

// TODO(Manu): Allow for some kind of patterns.
bool SDLIdentifierMatchesFilter(SDLIdentifier Identifier, string Filter)
{
  return Filter.empty || Identifier.Value == Filter;
}

// TODO(Manu): It feels like this iterator performs terribly. So, try to optimize it some time.
struct SDLNodeIterator
{
  SDLNodeHandle Current;
  string Filter;

  @property bool empty() const { return !Current.IsValidHandle; }

  @property size_t length()
  {
    auto Node = this.Current;
    typeof(return) NumMatches;
    while(Node.IsValidHandle)
    {
      if(SDLIdentifierMatchesFilter(Node.Name, this.Filter))
      {
        NumMatches++;
      }
      Node = Node.Next;
    }

    return NumMatches;
  }

  alias opDollar = length;

  @property inout(SDLNodeHandle) front() inout { return this.Current; }

  void popFront() { assert(this.Current.IsValidHandle); this.Current = this.Current.Next; }

  SDLNodeIterator opIndex(string ChildFilter)
  {
    return SDLNodeIterator(this.Current, ChildFilter);
  }

  SDLNodeHandle opIndex(IndexType)(IndexType Index)
    if(Meta.IsNumeric!IndexType)
  {
    auto Node = this.Current;
    auto RemainingMatchesToFind = Index;
    while(Node.IsValidHandle)
    {
      if(SDLIdentifierMatchesFilter(Node.Name, this.Filter))
      {
        if(RemainingMatchesToFind == 0)
          return Node;
        RemainingMatchesToFind--;
      }
      Node = Node.Next;
    }

    .Log.Failure("Out of bounds in SDLNodeIterator.");
    debug assert(false);
    else return SDLNodeHandle();
  }
}

struct SDLNode
{
  /// The document this node belongs to.
  SDLDocument Document;

  //
  // Siblings
  //
  SDLNodeHandle Next;

  SDLNodeHandle Previous;

  //
  // Parents and Children
  //
  SDLNodeHandle Parent;

  SDLNodeHandle FirstChild;

  //
  // Node properties
  //
  bool IsAnonymous;
  SDLIdentifier Namespace;
  SDLIdentifier Name;

  /// Note: In the same order as they appear in the file.
  Array!SDLLiteral Values;

  /// Note: In the same order as they appear in the file.
  Array!SDLAttribute Attributes;

  //
  // Data Access
  //
  @property SDLNodeIterator Nodes() { return SDLNodeIterator(this.FirstChild); }

  SDLLiteral Attribute(string Key)
  {
    foreach(ref Attr; this.Attributes)
    {
      if(SDLIdentifierMatchesFilter(Attr.Name, Key))
        return Attr.Value;
    }

    return SDLLiteral();
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

enum SDLLiteralType
{
  INVALID,

  String,
  Number,
  Boolean,
  Binary,
}

struct SDLLiteral
{
  SDLLiteralType Type;
  union
  {
    string String;
    string NumberSource;
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

  @property bool IsValid() const { return this.Type != SDLLiteralType.INVALID; }
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

bool IsAtWhiteSpace(ref SourceData Source, ref SDLParsingContext Context)
{
  auto String = Source[];
  return String.length && String.front.IsWhite;
}

bool IsAtNewLine(ref SourceData Source, ref SDLParsingContext Context)
{
  auto String = Source[];
  return String.length && String.StartsWith("\n");
}

SourceData SkipWhiteSpace(ref SourceData OriginalSource, ref SDLParsingContext Context,
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

bool IsAtLineComment(ref SourceData Source, ref SDLParsingContext Context)
{
  auto String = Source[];
  return String.StartsWith("//") ||
         String.StartsWith("#") ||
         String.StartsWith("--");
}

bool IsAtMultiLineComment(ref SourceData Source, ref SDLParsingContext Context)
{
  auto String = Source[];
  return String.StartsWith("/*");
}

bool IsAtComment(ref SourceData Source, ref SDLParsingContext Context)
{
  return Source.IsAtLineComment(Context) || Source.IsAtMultiLineComment(Context);
}

SourceData SkipComments(ref SourceData OriginalSource, ref SDLParsingContext Context)
{
  auto Source = OriginalSource;

  while(true)
  {
    auto SourceString = Source[];
    if(Source.IsAtLineComment(Context))
    {
      auto NumToSkip = SourceString.length - SourceString.FindInCharArray('\n').length;
      Source.AdvanceBy(Min(NumToSkip + 1, SourceString.length));
    }
    else if(Source.IsAtMultiLineComment(Context))
    {
      auto NumToSkip = SourceString.length - SourceString.FindInCharArray("*/").length;
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

SourceData SkipWhiteSpaceAndComments(ref SourceData OriginalSource, ref SDLParsingContext Context,
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
bool IsAtSemanticLineDelimiter(ref SourceData Source, ref SDLParsingContext Context)
{
  return Source.length && Source.IsAtNewLine(Context) || Source.front == ';';
}

SourceData ParseUntil(alias Predicate)(ref SourceData Source, ref SDLParsingContext Context,)
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

SourceData ParseNested(ref SourceData Source, ref SDLParsingContext Context,
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

SourceData ParseEscaped(ref SourceData Source, ref SDLParsingContext Context,
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

struct SDLParsingContext
{
  /// An identifier for the string source, e.g. a file name. Used in log
  /// messages.
  string Origin;

  LogData* Log;
}

/// Convenience overload to accept a plain string instead of SourceData.
bool ParseDocumentFromString(SDLDocument Document, string SourceString, ref SDLParsingContext Context)
{
  auto Source = SourceData(SourceString);
  with(Source.StartLocation) { Line = 1; Column = 1; SourceIndex = 0; }
  with(Source.EndLocation)   { Line = 0; Column = 0; SourceIndex = SourceString.length; }

  return Document.ParseDocumentFromSource(Source, Context);
}

bool ParseDocumentFromSource(SDLDocument Document, ref SourceData Source, ref SDLParsingContext Context)
{
  return Document.ParseInnerNodes(Source, Context, &Document.Root.FirstChild);
}

bool ParseInnerNodes(SDLDocument Document, ref SourceData Source, ref SDLParsingContext Context,
                     SDLNodeHandle* FirstNode)
{
  if(FirstNode is null)
  {
    Log.Failure("Need first node to parse inner nodes.");
    debug assert(false);
    else return false;
  }

  if(!Document.ParseNode(Source, Context, FirstNode))
  {
    return false;
  }

  SDLNodeHandle PreviousNode = *FirstNode;
  SDLNodeHandle NewNode;
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
                     ref SDLParsingContext Context,
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
               ref SDLParsingContext Context,
               SDLNodeHandle* OutNode)
{
  auto Source = OriginalSource;
  Source.SkipWhiteSpaceAndComments(Context, Yes.ConsumeNewLine);

  if(Source.empty) return false;

  auto Node = Document.CreateNode();

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
    *OutNode = Node;

  OriginalSource = Source;
  return true;
}

bool ParseLiteral(SDLDocument Document,
                  ref SourceData OriginalSource,
                  ref SDLParsingContext Context,
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
                    ref SDLParsingContext Context,
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
                           ref SDLParsingContext Context,
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
// Query
//

private static struct SpecData
{
  string NodeName;
  int NodeIndex; // Is always available. Defaults to 0.
  string AttributeName; // Is only available for "leaf node specs".
  int ValueIndex = -1; // Is only available for "leaf node specs".
}

private SpecData QueryParseNodeSpec(ref SourceData Source, ref SDLParsingContext Context, bool* Success)
{
  import krepel.conversion.parse_integer;

  if(Success)
    *Success = true;
  SpecData Result;

  if(Source.empty)
    return Result;

  auto Origin = Context.Origin;
  auto Line = Source.StartLocation.Line;
  auto Column = Source.StartLocation.Column;

  int NodeIndexSpecBeginIndex  = cast(int)Source[].CountUntil('[');
  int AttributeSpecIndex       = cast(int)Source[].CountUntil('@');
  int ValueIndexSpecIndex      = cast(int)Source[].CountUntil('#');

  //
  // Validate
  //
  if(ValueIndexSpecIndex >= 0 && AttributeSpecIndex >= 0)
  {
    if(Success)
      *Success = false;
    .Log.Failure("%s(%d,%d): Both a value index and attribute spec were given, when only one of them is allowed to exist at once.",
                 Origin, Line, Column);
    return Result;
  }

  if(NodeIndexSpecBeginIndex >= 0)
  {
    if(ValueIndexSpecIndex >= 0 && ValueIndexSpecIndex < NodeIndexSpecBeginIndex ||
       AttributeSpecIndex  >= 0 && AttributeSpecIndex  < NodeIndexSpecBeginIndex)
    {
      if(Success)
        *Success = false;
      .Log.Failure("%s(%d,%d): The node index spec is expected to come first, not the value index or attribute spec.",
                   Origin, Line, Column);
      return Result;
    }
  }

  //
  // Extract the actual data.
  //
  auto NodeName = Source.ParseUntil!(Str => Str.front == '[' || Str.front == '@' || Str.front == '#')(Context);
  Result.NodeName = NodeName;

  if(!Source.empty && Source.front == '[')
  {
    Source.AdvanceBy(1);
    bool FoundClosingBracket;
    auto NodeIndexSource = Source.ParseNested(Context, "[", "]", &FoundClosingBracket);
    if(NodeIndexSource.empty)
    {
      if(Success)
        *Success = false;
      .Log.Failure("%s(%d,%d): Empty node index spec is not allowed.",
                   Origin, NodeIndexSource.StartLocation.Line, NodeIndexSource.StartLocation.Column);
      return Result;
    }
    if(!FoundClosingBracket)
    {
      if(Success)
        *Success = false;
      .Log.Failure("%s(%d,%d): Missing closing bracket for node index spec.",
                   Origin, NodeIndexSource.StartLocation.Line, NodeIndexSource.StartLocation.Column);
      return Result;
    }

    auto NodeIndexString = NodeIndexSource[];
    auto ParseResult = ParseInteger!(typeof(Result.NodeIndex))(NodeIndexString);
    if(!ParseResult.Success)
    {
      if(Success)
        *Success = false;
      .Log.Failure("%s(%d,%d): Failed to parse integer.",
                   Origin, NodeIndexSource.StartLocation.Line, NodeIndexSource.StartLocation.Column);
      return Result;
    }

    Result.NodeIndex = cast(typeof(Result.NodeIndex))ParseResult;
  }

  if(!Source.empty)
  {
    if(Source.front == '@')
    {
      Source.AdvanceBy(1);
      if(Source.empty)
      {
        if(Success)
          *Success = false;
        .Log.Failure("%s(%d,%d): Empty attribute spec is not allowed.",
                     Origin, Source.StartLocation.Line, Source.StartLocation.Column);
        return Result;
      }

      Result.AttributeName = Source;
    }
    else if(Source.front == '#')
    {
      Source.AdvanceBy(1);
      if(Source.empty)
      {
        if(Success)
          *Success = false;
        .Log.Failure("%s(%d,%d): Empty value index spec is not allowed.",
                     Origin, Source.StartLocation.Line, Source.StartLocation.Column);
        return Result;
      }

      auto ValueIndexString = Source[];
      auto ParseResult = ParseInteger!(typeof(Result.ValueIndex))(ValueIndexString);
      if(!ParseResult.Success)
      {
        if(Success)
          *Success = false;
        .Log.Failure("%s(%d,%d): Failed to parse integer.",
                     Origin, Source.StartLocation.Line, Source.StartLocation.Column);
        return Result;
      }

      Result.ValueIndex = cast(typeof(Result.ValueIndex))ParseResult;
    }
  }

  return Result;
}

ReturnType Query(ReturnType)(SDLNodeHandle Node, string QueryString, bool* Success = null, LogData* Log = .Log)
{
  if(Success)
    *Success = true;
  typeof(return) Result;

  auto Source = SourceData(QueryString);
  with(Source.StartLocation) { Line = 1; Column = 1; SourceIndex = 0; }
  with(Source.EndLocation)   { Line = 0; Column = 0; SourceIndex = Source.Value.length; }
  auto Context = SDLParsingContext("Query");

  // Only one of the following may be set at a given time.
  int ValueIndex = -1;
  string AttributeName;

  while(true)
  {
    auto NodeSpec = Source.ParseUntil!(Str => Str.front == '/')(Context);
    if(NodeSpec.empty)
      break;

    bool IsValidNodeSpec;
    auto Spec = QueryParseNodeSpec(NodeSpec, Context, &IsValidNodeSpec);

    if(!IsValidNodeSpec)
    {
      if(Success)
        *Success = false;
      // Note(Manu): QueryParseNodeSpec logs when there are errors, so there's
      // no need to log something here as well.
      return Result;
    }

    if(!Spec.NodeName.empty)
    {
      Node = Node.Nodes[Spec.NodeName][Spec.NodeIndex];
    }
    else if(!Source.empty)
    {
      if(Success)
        *Success = false;
      .Log.Failure("%s(%d,%d): Empty node name is only allowed as the last node spec.",
                   Context.Origin, Source.StartLocation.Line, Source.StartLocation.Column);
      return Result;
    }

    if(Source.empty)
    {
      ValueIndex = Spec.ValueIndex;
      AttributeName = Spec.AttributeName;

      // We are at the end of the query string.
      break;
    }
    else
    {
      assert(Source.front == '/');

      if(Spec.ValueIndex >= 0)
      {
        if(Success)
          *Success = false;
        .Log.Failure("%s(%d,%d): Value index spec is only allowed at the end of the query string.",
                     Context.Origin, NodeSpec.StartLocation.Line, NodeSpec.StartLocation.Column);
        return Result;
      }

      Source.AdvanceBy(1);

      if(Source.empty)
      {
        if(Success)
          *Success = false;
        .Log.Failure("%s(%d,%d): Expected more content after the '/' but found none.",
                     Context.Origin, Source.StartLocation.Line, Source.StartLocation.Column);
        return Result;
      }
    }
  }

  static if(is(ReturnType == SDLNodeHandle))
  {
    if(AttributeName)
    {
      if(Success)
        *Success = false;
      .Log.Failure("%s: Result type is requested to be a SDLNodeHandle, but the query string contained a attribute spec.", Context.Origin);
      return Result;
    }
    return Node;
  }
  else
  {
    if(AttributeName) return cast(ReturnType)Node.Attribute(AttributeName);
    else              return cast(ReturnType)Node.Values[Max(0, ValueIndex)];
  }
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
  auto Context = SDLParsingContext("SDL Test 1", .Log);

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

// AdvanceBy
unittest
{
  auto Source = MakeSourceDataForTesting("foobar", 0);
  assert(Source == "foobar");
  assert(Source.AdvanceBy(1) == "f");
  assert(Source == "oobar");
  assert(Source.AdvanceBy(5) == "oobar");
  assert(Source.empty);
}

// ParseUntil
unittest
{
  auto Context = SDLParsingContext("SDL Test 2", .Log);

  {
    auto Source = MakeSourceDataForTesting(`foo "bar"`, 0);

    auto Result = Source.ParseUntil!(S => S.front.IsWhite)(Context);
    assert(Result.StartLocation.SourceIndex == 0, Result);
    assert(Result.EndLocation.SourceIndex == 3, Result);
    assert(Source.StartLocation.SourceIndex == 3, Source);
    assert(Source.EndLocation.SourceIndex == Source.Value.length, Source);
  }

  {
    auto Source = MakeSourceDataForTesting("foobar", 0);

    auto Result = Source.ParseUntil!(Str => Str.front == 'f')(Context);
    assert(Result.empty);
    assert(Source == "foobar");
  }
}

// ParseNested
unittest
{
  auto Context = SDLParsingContext("SDL Test 3", .Log);

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
  auto Context = SDLParsingContext("SDL Test 4", .Log);

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
  auto TestAllocator = CreateTestAllocator!StackMemory();

  auto Context = SDLParsingContext("SDL Test 5", .Log);

  auto Document = TestAllocator.New!SDLDocument(TestAllocator);
  Document.ParseDocumentFromString(`foo "bar"`, Context);

  auto Node = Document.Root.FirstChild;
  assert(Node.IsValidHandle);
  assert(Node.Name == "foo");
  assert(Node.Values.length == 1);
  assert(Node.Values[0].Type == SDLLiteralType.String);
  assert(Node.Values[0].String == "bar", Node.Values[0].String);
}

// Parse simple document with attributes
unittest
{
  auto TestAllocator = CreateTestAllocator!StackMemory();

  auto Context = SDLParsingContext("SDL Test 6", .Log);

  auto Document = TestAllocator.New!SDLDocument(TestAllocator);
  Document.ParseDocumentFromString(`foo "bar" baz="qux"`, Context);

  auto Node = Document.Root.FirstChild;
  assert(Node.IsValidHandle);
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
  auto TestAllocator = CreateTestAllocator!StackMemory();

  auto Context = SDLParsingContext("SDL Test 7", .Log);

  auto Document = TestAllocator.New!SDLDocument(TestAllocator);
  auto Source = q"(
    foo "bar"
    baz "qux"
  )";
  Document.ParseDocumentFromString(Source, Context);

  auto Node = Document.Root.FirstChild;
  assert(Node.IsValidHandle);
  assert(Node.Name == "foo");
  assert(Node.Values.length == 1);
  assert(Node.Values[0].Type == SDLLiteralType.String);
  assert(Node.Values[0].String == "bar", Node.Values[0].String);

  Node = Node.Next;
  assert(Node.IsValidHandle);
  assert(Node.Name == "baz");
  assert(Node.Values.length == 1);
  assert(Node.Values[0].Type == SDLLiteralType.String);
  assert(Node.Values[0].String == "qux", Node.Values[0].String);
}

// Parse document with child nodes
unittest
{
  auto TestAllocator = CreateTestAllocator!StackMemory();

  auto Context = SDLParsingContext("SDL Test 8", .Log);

  auto Document = TestAllocator.New!SDLDocument(TestAllocator);
  auto Source = q"(
    foo "bar" {
      baz "qux" {
        baaz "quux"
      }
    }
  )";
  Document.ParseDocumentFromString(Source, Context);

  auto Node = Document.Root.FirstChild;
  assert(Node.IsValidHandle);
  assert(Node.Name == "foo");
  assert(Node.Values.length == 1);
  assert(Node.Values[0].Type == SDLLiteralType.String);
  assert(Node.Values[0].String == "bar", Node.Values[0].String);

  Node = Node.FirstChild;
  assert(Node.IsValidHandle);
  assert(Node.Name == "baz");
  assert(Node.Values.length == 1);
  assert(Node.Values[0].Type == SDLLiteralType.String);
  assert(Node.Values[0].String == "qux", Node.Values[0].String);

  Node = Node.FirstChild;
  assert(Node.IsValidHandle);
  assert(Node.Name == "baaz");
  assert(Node.Values.length == 1);
  assert(Node.Values[0].Type == SDLLiteralType.String);
  assert(Node.Values[0].String == "quux", Node.Values[0].String);
}

unittest
{
  auto TestAllocator = CreateTestAllocator!StackMemory();

  auto Context = SDLParsingContext("SDL Test 9", .Log);

  auto Document = TestAllocator.New!SDLDocument(TestAllocator);
  Document.ParseDocumentFromString(`answer 42`, Context);

  auto Node = Document.Root.FirstChild;
  assert(Node.IsValidHandle);
  assert(Node.Name == "answer");
  assert(Node.Values.length == 1);
  assert(Node.Values[0].Type == SDLLiteralType.Number);
  assert(cast(int)Node.Values[0] == 42, Node.Values[0].NumberSource);
}

// Parse document from file.
unittest
{
  void TheActualTest(SDLDocument Document)
  {
    // foo "bar"
    auto Node = Document.Root.FirstChild;
    assert(Node.IsValidHandle);
    assert(Node.Name == "foo");
    assert(Node.Values.Count == 1);
    assert(cast(string)Node.Values[0] == "bar");
    assert(Node.Attributes.IsEmpty);

    // foo "bar" "baz"
    Node = Node.Next;
    assert(Node.IsValidHandle);
    assert(Node.Name == "foo");
    assert(Node.Values.Count == 2);
    assert(cast(string)Node.Values[0] == "bar");
    assert(cast(string)Node.Values[1] == "baz");
    assert(Node.Attributes.IsEmpty);

    // foo "bar" baz="qux"
    Node = Node.Next;
    assert(Node.IsValidHandle);
    assert(Node.Name == "foo");
    assert(Node.Values.Count == 1);
    assert(cast(string)Node.Values[0] == "bar");
    assert(Node.Attributes.Count == 1);
    assert(Node.Attributes[0].Name == "baz");
    assert(cast(string)Node.Attributes[0].Value == "qux");

    // foo "bar" baz="qux" baaz="quux"
    Node = Node.Next;
    assert(Node.IsValidHandle);
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
    assert(Node.IsValidHandle);
    assert(Node.Name == "foo");
    assert(Node.Values.IsEmpty);
    assert(Node.Attributes.Count == 1);
    assert(Node.Attributes[0].Name == "bar");
    assert(cast(string)Node.Attributes[0].Value == "baz");

    // "foo"
    Node = Node.Next;
    assert(Node.IsValidHandle);
    assert(Node.IsAnonymous);
    assert(Node.Name == "content");
    assert(Node.Values.Count == 1);
    assert(cast(string)Node.Values[0] == "foo");
    assert(Node.Attributes.IsEmpty == 1);

    // "foo" bar="baz"
    Node = Node.Next;
    assert(Node.IsValidHandle);
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
    assert(Node.IsValidHandle);
    assert(Node.Name == "foo");
    assert(Node.Values.IsEmpty);
    assert(Node.Attributes.IsEmpty);
    {
      auto Child = Node.FirstChild;
      assert(Child.IsValidHandle);
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
    assert(Node.IsValidHandle);
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
    assert(Node.IsValidHandle);
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
      assert(Child.IsValidHandle);
      assert(Child.Name == "inner");
      assert(Child.Values.Count == 0);
      assert(Child.Attributes.Count == 0);
      {
        auto ChildsChild = Child.FirstChild;
        assert(ChildsChild.IsValidHandle);
        assert(ChildsChild.IsAnonymous);
        assert(ChildsChild.Values.Count == 3);
        assert(cast(int)ChildsChild.Values[0] == 0);
        assert(cast(int)ChildsChild.Values[1] == 1);
        assert(cast(int)ChildsChild.Values[2] == 2);
        assert(ChildsChild.Attributes.IsEmpty);
      }

      // "anon value"
      Child = Child.Next;
      assert(Child.IsValidHandle);
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
      assert(Child.IsValidHandle);
      assert(Child.IsAnonymous);
      assert(Child.Name == "content");
      assert(Child.Values.Count == 1);
      assert(cast(string)Child.Values[0] == "anon value with nesting");
      assert(Child.Attributes.IsEmpty);
      {
        // another-foo "bar" 1337 -92 "baz" qux="baaz"
        auto ChildsChild = Child.FirstChild;
        assert(ChildsChild.IsValidHandle);
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

    assert(!Node.Next.IsValidHandle);
  }

  auto TestAllocator = CreateTestAllocator!StackMemory();

  auto FileName = "../unittest/sdlang/full.sdl"w;
  auto File = OpenFile(TestAllocator, FileName);
  scope(exit) CloseFile(TestAllocator, File);

  // TODO(Manu): Once we have WString => UString conversion, use the filename
  // as context.
  auto Context = SDLParsingContext("Full", .Log);
  auto Document = TestAllocator.New!SDLDocument(TestAllocator);

  scope(exit) TestAllocator.Delete(Document);
  auto SourceString = TestAllocator.NewArray!char(File.Size);
  auto BytesRead = File.Read(SourceString);
  assert(BytesRead == SourceString.length);
  assert(Document.ParseDocumentFromString(cast(string)SourceString, Context), SourceString);

  TheActualTest(Document);

  // Force a reallocation of all nodes to see whether the SDLNodeRefs work as intended.
  Document.AllNodes.Reserve(Document.AllNodes.Capacity + 1);

  TheActualTest(Document);
}

unittest
{
  auto TestAllocator = CreateTestAllocator!StackMemory();

  const SourceString = q"(
    foo "bar" {
      baz "qux" key="value" {
        baaz "quux" answer=42
      }
    }
  )";

  auto Document = TestAllocator.New!SDLDocument(TestAllocator);
  scope(exit) TestAllocator.Delete(Document);

  auto ParsingContext = SDLParsingContext("Convenience", .Log);
  Document.ParseDocumentFromString(SourceString, ParsingContext);

  assert(cast(string)Document.Root.Nodes["foo"][0].Values[0] == "bar");
  assert(cast(string)Document.Root.Nodes["foo"][0].Nodes["baz"][0].Values[0] == "qux");
  assert(cast(string)Document.Root.Nodes["foo"][0].Nodes["baz"][0].Nodes["baaz"][0].Values[0] == "quux");
  assert(Document.Root.Nodes["baz"].length == 0);

  foreach(Node; Document.Root.Nodes)
  {
    assert(cast(string)Node.Values[0] == "bar");
  }

  assert(!Document.Root.Nodes["foo"][0].Attribute("bar").IsValid);
  assert(cast(string)Document.Root.Nodes["foo"][0].Nodes["baz"][0].Attribute("key") == "value");
  assert(cast(int)Document.Root.Nodes["foo"][0].Nodes["baz"][0].Nodes["baaz"][0].Attribute("answer") == 42);
}

// Query
unittest
{
  auto TestAllocator = CreateTestAllocator!StackMemory();

  auto Context = SDLParsingContext("Query Test 1", .Log);

  auto Document = TestAllocator.New!SDLDocument(TestAllocator);
  auto Source = q"(
    Foo "Bar" "Bar?" "Bar!" Key="Value" {
      Baz "Qux" {
        Baaz "Quux" 1337 answer=42
        Baaz "Fuux" 123  answer=43
      }

      Baz "Sup" {
        Baaz "Quux, again"
      }
    }
  )";
  Document.ParseDocumentFromString(Source, Context);

  assert(Document.Root.Query!string("Foo") == "Bar");
  assert(Document.Root.Query!string("Foo[0]") == "Bar");
  assert(Document.Root.Query!string("Foo#0") == "Bar");
  assert(Document.Root.Query!string("Foo[0]#0") == "Bar");
  assert(Document.Root.Query!string("Foo#1") == "Bar?");
  assert(Document.Root.Query!string("Foo[0]#1") == "Bar?");
  assert(Document.Root.Query!string("Foo#2") == "Bar!");
  assert(Document.Root.Query!string("Foo[0]#2") == "Bar!");
  assert(Document.Root.Query!string("Foo@Key") == "Value");
  assert(Document.Root.Query!string("Foo/Baz") == "Qux");
  assert(Document.Root.Query!string("Foo/Baz[1]") == "Sup");
  assert(Document.Root.Query!string("Foo/Baz/Baaz") == "Quux");
  assert(Document.Root.Query!string("Foo/Baz[1]/Baaz") == "Quux, again");
  assert(Document.Root.Query!int("Foo/Baz/Baaz#1") == 1337);
  assert(Document.Root.Query!int("Foo/Baz/Baaz@answer") == 42);
  assert(Document.Root.Query!string("Foo/Baz/Baaz[1]") == "Fuux");
  assert(Document.Root.Query!int("Foo/Baz/Baaz[1]#1") == 123);
  assert(Document.Root.Query!int("Foo/Baz/Baaz[1]@answer") == 43);

  auto Foo = Document.Root.Query!SDLNodeHandle("Foo");
  assert(Foo.IsValidHandle);
  assert(Foo.Values.length == 3);
  assert(Foo.Attributes.length == 1);
  assert(cast(string)Foo.Attribute("Key") == "Value");
  assert(Foo.Query!string("#0") == "Bar");
  assert(Foo.Query!string("Baz") == "Qux");
}
