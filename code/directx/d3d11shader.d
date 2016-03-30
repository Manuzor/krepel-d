// Original file name: d3d11shader.h
// Conversion date: 2016-Mar-28 20:08:46.8177249
// Note: This header was ported by hand.
module directx.d3d11shader;

version(Windows):

import core.sys.windows.windows;

private mixin template DEFINE_GUID(ComType, alias IIDString)
{
  // Format of a UUID:
  // [0  1  2  3  4  5  6  7]  8  [9  10 11 12] 13 [14 15 16 17] 18 [19 20] [21 22] 23 [24 25] [26 27] [28 29] [30 31] [32 33] [34 35]
  // [x  x  x  x  x  x  x  x]  -  [x  x  x  x ] -  [x  x  x  x ] -  [x  x ] [x  x ]  - [x  x ] [x  x ] [x  x ] [x  x ] [x  x ] [x  x ]
  static assert(IIDString.length == 36, "Malformed UUID string:\nGot:             %-36s\nExpected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".Format(IIDString));
  static assert(IIDString[8]  == '-',   "Malformed UUID string:\nGot:             %-36s\nExpected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".Format(IIDString));
  static assert(IIDString[13] == '-',   "Malformed UUID string:\nGot:             %-36s\nExpected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".Format(IIDString));
  static assert(IIDString[18] == '-',   "Malformed UUID string:\nGot:             %-36s\nExpected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".Format(IIDString));
  static assert(IIDString[23] == '-',   "Malformed UUID string:\nGot:             %-36s\nExpected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".Format(IIDString));

  private import std.format : format;

  mixin(format("immutable IID IID_%s "
               "= { 0x%s, 0x%s, 0x%s, [0x%s, 0x%s, 0x%s, 0x%s, 0x%s, 0x%s, 0x%s, 0x%s] };",
               ComType.stringof,
               IIDString[ 0 ..  8], // IID.Data1    <=> [xxxxxxxx]-xxxx-xxxx-xxxx-xxxxxxxxxxxx
               IIDString[ 9 .. 13], // IID.Data2    <=> xxxxxxxx-[xxxx]-xxxx-xxxx-xxxxxxxxxxxx
               IIDString[14 .. 18], // IID.Data3    <=> xxxxxxxx-xxxx-[xxxx]-xxxx-xxxxxxxxxxxx
               IIDString[19 .. 21], // IID.Data4[0] <=> xxxxxxxx-xxxx-xxxx-[xx]xx-xxxxxxxxxxxx
               IIDString[21 .. 23], // IID.Data4[1] <=> xxxxxxxx-xxxx-xxxx-xx[xx]-xxxxxxxxxxxx
               IIDString[24 .. 26], // IID.Data4[2] <=> xxxxxxxx-xxxx-xxxx-xxxx-[xx]xxxxxxxxxx
               IIDString[26 .. 28], // IID.Data4[3] <=> xxxxxxxx-xxxx-xxxx-xxxx-xx[xx]xxxxxxxx
               IIDString[28 .. 30], // IID.Data4[4] <=> xxxxxxxx-xxxx-xxxx-xxxx-xxxx[xx]xxxxxx
               IIDString[30 .. 32], // IID.Data4[5] <=> xxxxxxxx-xxxx-xxxx-xxxx-xxxxxx[xx]xxxx
               IIDString[32 .. 34], // IID.Data4[6] <=> xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx[xx]xx
               IIDString[34 .. 36], // IID.Data4[7] <=> xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx[xx]
               ));
}


public import directx.d3dcommon;


alias D3D11_SHADER_VERSION_TYPE = int;
enum : D3D11_SHADER_VERSION_TYPE
{
  D3D11_SHVER_PIXEL_SHADER    = 0,
  D3D11_SHVER_VERTEX_SHADER   = 1,
  D3D11_SHVER_GEOMETRY_SHADER = 2,

  // D3D11 Shaders
  D3D11_SHVER_HULL_SHADER     = 3,
  D3D11_SHVER_DOMAIN_SHADER   = 4,
  D3D11_SHVER_COMPUTE_SHADER  = 5,

  D3D11_SHVER_RESERVED0       = 0xFFF0,
}

alias D3D11_SHVER_GET_TYPE = (_Version) => (((_Version) >> 16) & 0xffff);
alias D3D11_SHVER_GET_MAJOR = (_Version) => (((_Version) >> 4) & 0xf);
alias D3D11_SHVER_GET_MINOR = (_Version) => (((_Version) >> 0) & 0xf);

// Slot ID for library function return
enum D3D_RETURN_PARAMETER_INDEX = -1;

alias D3D11_RESOURCE_RETURN_TYPE = D3D_RESOURCE_RETURN_TYPE;

alias D3D11_CBUFFER_TYPE = D3D_CBUFFER_TYPE;


struct D3D11_SIGNATURE_PARAMETER_DESC
{
  LPCSTR                      SemanticName;   // Name of the semantic
  UINT                        SemanticIndex;  // Index of the semantic
  UINT                        Register;       // Number of member variables
  D3D_NAME                    SystemValueType;// A predefined system value, or D3D_NAME_UNDEFINED if not applicable
  D3D_REGISTER_COMPONENT_TYPE ComponentType;  // Scalar type (e.g. uint, float, etc.)
  BYTE                        Mask;           // Mask to indicate which components of the register
                                              // are used (combination of D3D10_COMPONENT_MASK values)
  BYTE                        ReadWriteMask;  // Mask to indicate whether a given component is
                                              // never written (if this is an output signature) or
                                              // always read (if this is an input signature).
                                              // (combination of D3D_MASK_* values)
  UINT                        Stream;         // Stream index
  D3D_MIN_PRECISION           MinPrecision;   // Minimum desired interpolation precision
}

struct D3D11_SHADER_BUFFER_DESC
{
  LPCSTR                  Name;           // Name of the constant buffer
  D3D_CBUFFER_TYPE        Type;           // Indicates type of buffer content
  UINT                    Variables;      // Number of member variables
  UINT                    Size;           // Size of CB (in bytes)
  UINT                    uFlags;         // Buffer description flags
}

struct D3D11_SHADER_VARIABLE_DESC
{
  LPCSTR                  Name;           // Name of the variable
  UINT                    StartOffset;    // Offset in constant buffer's backing store
  UINT                    Size;           // Size of variable (in bytes)
  UINT                    uFlags;         // Variable flags
  LPVOID                  DefaultValue;   // Raw pointer to default value
  UINT                    StartTexture;   // First texture index (or -1 if no textures used)
  UINT                    TextureSize;    // Number of texture slots possibly used.
  UINT                    StartSampler;   // First sampler index (or -1 if no textures used)
  UINT                    SamplerSize;    // Number of sampler slots possibly used.
}

struct D3D11_SHADER_TYPE_DESC
{
  D3D_SHADER_VARIABLE_CLASS   Class;          // Variable class (e.g. object, matrix, etc.)
  D3D_SHADER_VARIABLE_TYPE    Type;           // Variable type (e.g. float, sampler, etc.)
  UINT                        Rows;           // Number of rows (for matrices, 1 for other numeric, 0 if not applicable)
  UINT                        Columns;        // Number of columns (for vectors & matrices, 1 for other numeric, 0 if not applicable)
  UINT                        Elements;       // Number of elements (0 if not an array)
  UINT                        Members;        // Number of members (0 if not a structure)
  UINT                        Offset;         // Offset from the start of structure (0 if not a structure member)
  LPCSTR                      Name;           // Name of type, can be NULL
}

alias D3D11_TESSELLATOR_DOMAIN = D3D_TESSELLATOR_DOMAIN;

alias D3D11_TESSELLATOR_PARTITIONING = D3D_TESSELLATOR_PARTITIONING;

alias D3D11_TESSELLATOR_OUTPUT_PRIMITIVE = D3D_TESSELLATOR_OUTPUT_PRIMITIVE;

struct D3D11_SHADER_DESC
{
  UINT                    Version;                     // Shader version
  LPCSTR                  Creator;                     // Creator string
  UINT                    Flags;                       // Shader compilation/parse flags

  UINT                    ConstantBuffers;             // Number of constant buffers
  UINT                    BoundResources;              // Number of bound resources
  UINT                    InputParameters;             // Number of parameters in the input signature
  UINT                    OutputParameters;            // Number of parameters in the output signature

  UINT                    InstructionCount;            // Number of emitted instructions
  UINT                    TempRegisterCount;           // Number of temporary registers used
  UINT                    TempArrayCount;              // Number of temporary arrays used
  UINT                    DefCount;                    // Number of constant defines
  UINT                    DclCount;                    // Number of declarations (input + output)
  UINT                    TextureNormalInstructions;   // Number of non-categorized texture instructions
  UINT                    TextureLoadInstructions;     // Number of texture load instructions
  UINT                    TextureCompInstructions;     // Number of texture comparison instructions
  UINT                    TextureBiasInstructions;     // Number of texture bias instructions
  UINT                    TextureGradientInstructions; // Number of texture gradient instructions
  UINT                    FloatInstructionCount;       // Number of floating point arithmetic instructions used
  UINT                    IntInstructionCount;         // Number of signed integer arithmetic instructions used
  UINT                    UintInstructionCount;        // Number of unsigned integer arithmetic instructions used
  UINT                    StaticFlowControlCount;      // Number of static flow control instructions used
  UINT                    DynamicFlowControlCount;     // Number of dynamic flow control instructions used
  UINT                    MacroInstructionCount;       // Number of macro instructions used
  UINT                    ArrayInstructionCount;       // Number of array instructions used
  UINT                    CutInstructionCount;         // Number of cut instructions used
  UINT                    EmitInstructionCount;        // Number of emit instructions used
  D3D_PRIMITIVE_TOPOLOGY  GSOutputTopology;            // Geometry shader output topology
  UINT                    GSMaxOutputVertexCount;      // Geometry shader maximum output vertex count
  D3D_PRIMITIVE           InputPrimitive;              // GS/HS input primitive
  UINT                    PatchConstantParameters;     // Number of parameters in the patch constant signature
  UINT                    cGSInstanceCount;            // Number of Geometry shader instances
  UINT                    cControlPoints;              // Number of control points in the HS->DS stage
  D3D_TESSELLATOR_OUTPUT_PRIMITIVE HSOutputPrimitive;  // Primitive output by the tessellator
  D3D_TESSELLATOR_PARTITIONING HSPartitioning;         // Partitioning mode of the tessellator
  D3D_TESSELLATOR_DOMAIN  TessellatorDomain;           // Domain of the tessellator (quad, tri, isoline)
  // instruction counts
  UINT cBarrierInstructions;                           // Number of barrier instructions in a compute shader
  UINT cInterlockedInstructions;                       // Number of interlocked instructions
  UINT cTextureStoreInstructions;                      // Number of texture writes
}

struct D3D11_SHADER_INPUT_BIND_DESC
{
  LPCSTR                      Name;           // Name of the resource
  D3D_SHADER_INPUT_TYPE       Type;           // Type of resource (e.g. texture, cbuffer, etc.)
  UINT                        BindPoint;      // Starting bind point
  UINT                        BindCount;      // Number of contiguous bind points (for arrays)

  UINT                        uFlags;         // Input binding flags
  D3D_RESOURCE_RETURN_TYPE    ReturnType;     // Return type (if texture)
  D3D_SRV_DIMENSION           Dimension;      // Dimension (if texture)
  UINT                        NumSamples;     // Number of samples (0 if not MS texture)
}

enum D3D_SHADER_REQUIRES_DOUBLES                       = 0x00000001;
enum D3D_SHADER_REQUIRES_EARLY_DEPTH_STENCIL           = 0x00000002;
enum D3D_SHADER_REQUIRES_UAVS_AT_EVERY_STAGE           = 0x00000004;
enum D3D_SHADER_REQUIRES_64_UAVS                       = 0x00000008;
enum D3D_SHADER_REQUIRES_MINIMUM_PRECISION             = 0x00000010;
enum D3D_SHADER_REQUIRES_11_1_DOUBLE_EXTENSIONS        = 0x00000020;
enum D3D_SHADER_REQUIRES_11_1_SHADER_EXTENSIONS        = 0x00000040;
enum D3D_SHADER_REQUIRES_LEVEL_9_COMPARISON_FILTERING  = 0x00000080;
enum D3D_SHADER_REQUIRES_TILED_RESOURCES               = 0x00000100;


struct D3D11_LIBRARY_DESC
{
  LPCSTR    Creator;           // The name of the originator of the library.
  UINT      Flags;             // Compilation flags.
  UINT      FunctionCount;     // Number of functions exported from the library.
}

struct D3D11_FUNCTION_DESC
{
  UINT                    Version;                     // Shader version
  LPCSTR                  Creator;                     // Creator string
  UINT                    Flags;                       // Shader compilation/parse flags

  UINT                    ConstantBuffers;             // Number of constant buffers
  UINT                    BoundResources;              // Number of bound resources

  UINT                    InstructionCount;            // Number of emitted instructions
  UINT                    TempRegisterCount;           // Number of temporary registers used
  UINT                    TempArrayCount;              // Number of temporary arrays used
  UINT                    DefCount;                    // Number of constant defines
  UINT                    DclCount;                    // Number of declarations (input + output)
  UINT                    TextureNormalInstructions;   // Number of non-categorized texture instructions
  UINT                    TextureLoadInstructions;     // Number of texture load instructions
  UINT                    TextureCompInstructions;     // Number of texture comparison instructions
  UINT                    TextureBiasInstructions;     // Number of texture bias instructions
  UINT                    TextureGradientInstructions; // Number of texture gradient instructions
  UINT                    FloatInstructionCount;       // Number of floating point arithmetic instructions used
  UINT                    IntInstructionCount;         // Number of signed integer arithmetic instructions used
  UINT                    UintInstructionCount;        // Number of unsigned integer arithmetic instructions used
  UINT                    StaticFlowControlCount;      // Number of static flow control instructions used
  UINT                    DynamicFlowControlCount;     // Number of dynamic flow control instructions used
  UINT                    MacroInstructionCount;       // Number of macro instructions used
  UINT                    ArrayInstructionCount;       // Number of array instructions used
  UINT                    MovInstructionCount;         // Number of mov instructions used
  UINT                    MovcInstructionCount;        // Number of movc instructions used
  UINT                    ConversionInstructionCount;  // Number of type conversion instructions used
  UINT                    BitwiseInstructionCount;     // Number of bitwise arithmetic instructions used
  D3D_FEATURE_LEVEL       MinFeatureLevel;             // Min target of the function byte code
  UINT64                  RequiredFeatureFlags;        // Required feature flags

  LPCSTR                  Name;                        // Function name
  INT                     FunctionParameterCount;      // Number of logical parameters in the function signature (not including return)
  BOOL                    HasReturn;                   // TRUE, if function returns a value, false - it is a subroutine
  BOOL                    Has10Level9VertexShader;     // TRUE, if there is a 10L9 VS blob
  BOOL                    Has10Level9PixelShader;      // TRUE, if there is a 10L9 PS blob
}

struct D3D11_PARAMETER_DESC
{
  LPCSTR                      Name;               // Parameter name.
  LPCSTR                      SemanticName;       // Parameter semantic name (+index).
  D3D_SHADER_VARIABLE_TYPE    Type;               // Element type.
  D3D_SHADER_VARIABLE_CLASS   Class;              // Scalar/Vector/Matrix.
  UINT                        Rows;               // Rows are for matrix parameters.
  UINT                        Columns;            // Components or Columns in matrix.
  D3D_INTERPOLATION_MODE      InterpolationMode;  // Interpolation mode.
  D3D_PARAMETER_FLAGS         Flags;              // Parameter modifiers.

  UINT                        FirstInRegister;    // The first input register for this parameter.
  UINT                        FirstInComponent;   // The first input register component for this parameter.
  UINT                        FirstOutRegister;   // The first output register for this parameter.
  UINT                        FirstOutComponent;  // The first output register component for this parameter.
}


//////////////////////////////////////////////////////////////////////////////
// Interfaces ////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

alias LPD3D11SHADERREFLECTIONTYPE = ID3D11ShaderReflectionType*;
alias LPD3D11SHADERREFLECTIONVARIABLE = ID3D11ShaderReflectionVariable*;
alias LPD3D11SHADERREFLECTIONCONSTANTBUFFER = ID3D11ShaderReflectionConstantBuffer*;
alias LPD3D11SHADERREFLECTION = ID3D11ShaderReflection*;
alias LPD3D11LIBRARYREFLECTION = ID3D11LibraryReflection*;
alias LPD3D11FUNCTIONREFLECTION = ID3D11FunctionReflection*;
alias LPD3D11FUNCTIONPARAMETERREFLECTION = ID3D11FunctionParameterReflection*;

mixin DEFINE_GUID!(ID3D11ShaderReflectionType, "6E6FFA6A-9BAE-4613-A51E-91652D508C21");
interface ID3D11ShaderReflectionType
{
  HRESULT GetDesc(/*_Out_*/ D3D11_SHADER_TYPE_DESC* Desc);

  ID3D11ShaderReflectionType* GetMemberTypeByIndex(/*_In_*/ UINT Index);
  ID3D11ShaderReflectionType* GetMemberTypeByName(/*_In_*/ LPCSTR Name);
  LPCSTR GetMemberTypeName(/*_In_*/ UINT Index);

  HRESULT IsEqual(/*_In_*/ ID3D11ShaderReflectionType* pType);
  ID3D11ShaderReflectionType* GetSubType();
  ID3D11ShaderReflectionType* GetBaseClass();
  UINT GetNumInterfaces();
  ID3D11ShaderReflectionType* GetInterfaceByIndex(/*_In_*/ UINT uIndex);
  HRESULT IsOfType(/*_In_*/ ID3D11ShaderReflectionType* pType);
  HRESULT ImplementsInterface(/*_In_*/ ID3D11ShaderReflectionType* pBase);
};

mixin DEFINE_GUID!(ID3D11ShaderReflectionVariable, "51F23923-F3E5-4BD1-91CB-606177D8DB4C");
interface ID3D11ShaderReflectionVariable
{
  HRESULT GetDesc(/*_Out_*/ D3D11_SHADER_VARIABLE_DESC* Desc);

  ID3D11ShaderReflectionType* GetType();
  ID3D11ShaderReflectionConstantBuffer* GetBuffer();

  UINT GetInterfaceSlot(/*_In_*/ UINT uArrayIndex);
};

mixin DEFINE_GUID!(ID3D11ShaderReflectionConstantBuffer, "EB62D63D-93DD-4318-8AE8-C6F83AD371B8");
interface ID3D11ShaderReflectionConstantBuffer
{
  HRESULT GetDesc(D3D11_SHADER_BUFFER_DESC* Desc);

  ID3D11ShaderReflectionVariable* GetVariableByIndex(/*_In_*/ UINT Index);
  ID3D11ShaderReflectionVariable* GetVariableByName(/*_In_*/ LPCSTR Name);
};

// The ID3D11ShaderReflection IID may change from SDK version to SDK version
// if the reflection API changes.  This prevents new code with the new API
// from working with an old binary.  Recompiling with the new header
// will pick up the new IID.

mixin DEFINE_GUID!(ID3D11ShaderReflection, "8d536ca1-0cca-4956-a837-786963755584");
interface ID3D11ShaderReflection : IUnknown
{
  HRESULT QueryInterface(/*_In_*/ REFIID iid,
                         /*_Out_*/ LPVOID* pv);
  ULONG AddRef();
  ULONG Release();

  HRESULT GetDesc(/*_Out_*/ D3D11_SHADER_DESC* Desc);

  ID3D11ShaderReflectionConstantBuffer* GetConstantBufferByIndex(/*_In_*/ UINT Index);
  ID3D11ShaderReflectionConstantBuffer* GetConstantBufferByName(/*_In_*/ LPCSTR Name);

  HRESULT GetResourceBindingDesc(/*_In_*/ UINT ResourceIndex,
                                 /*_Out_*/ D3D11_SHADER_INPUT_BIND_DESC* Desc);

  HRESULT GetInputParameterDesc(/*_In_*/ UINT ParameterIndex,
                                /*_Out_*/ D3D11_SIGNATURE_PARAMETER_DESC* Desc);
  HRESULT GetOutputParameterDesc(/*_In_*/ UINT ParameterIndex,
                                 /*_Out_*/ D3D11_SIGNATURE_PARAMETER_DESC* Desc);
  HRESULT GetPatchConstantParameterDesc(/*_In_*/ UINT ParameterIndex,
                                        /*_Out_*/ D3D11_SIGNATURE_PARAMETER_DESC* Desc);

  ID3D11ShaderReflectionVariable* GetVariableByName(/*_In_*/ LPCSTR Name);

  HRESULT GetResourceBindingDescByName(/*_In_*/ LPCSTR Name,
                                       /*_Out_*/ D3D11_SHADER_INPUT_BIND_DESC* Desc);

  UINT GetMovInstructionCount();
  UINT GetMovcInstructionCount();
  UINT GetConversionInstructionCount();
  UINT GetBitwiseInstructionCount();

  D3D_PRIMITIVE GetGSInputPrimitive();
  BOOL IsSampleFrequencyShader();

  UINT GetNumInterfaceSlots();
  HRESULT GetMinFeatureLevel(/*_Out_*/ D3D_FEATURE_LEVEL* pLevel);

  UINT GetThreadGroupSize(/*_Out_opt_*/ UINT* pSizeX,
                          /*_Out_opt_*/ UINT* pSizeY,
                          /*_Out_opt_*/ UINT* pSizeZ);

  UINT64 GetRequiresFlags();
};

mixin DEFINE_GUID!(ID3D11LibraryReflection, "54384F1B-5B3E-4BB7-AE01-60BA3097CBB6");
interface ID3D11LibraryReflection : IUnknown
{
  HRESULT QueryInterface(/*_In_*/ REFIID iid, /*_Out_*/ LPVOID* ppv);
  ULONG AddRef();
  ULONG Release();

  HRESULT GetDesc(/*_Out_*/ D3D11_LIBRARY_DESC* pDesc);

  ID3D11FunctionReflection* GetFunctionByIndex(/*_In_*/ INT FunctionIndex);
};

mixin DEFINE_GUID!(ID3D11FunctionReflection, "207BCECB-D683-4A06-A8A3-9B149B9F73A4");
interface ID3D11FunctionReflection
{
  HRESULT GetDesc(/*_Out_*/ D3D11_FUNCTION_DESC* pDesc);

  ID3D11ShaderReflectionConstantBuffer* GetConstantBufferByIndex(/*_In_*/ UINT BufferIndex);
  ID3D11ShaderReflectionConstantBuffer* GetConstantBufferByName(/*_In_*/ LPCSTR Name);

  HRESULT GetResourceBindingDesc(/*_In_*/ UINT ResourceIndex,
                                 /*_Out_*/ D3D11_SHADER_INPUT_BIND_DESC* pDesc);

  ID3D11ShaderReflectionVariable* GetVariableByName(/*_In_*/ LPCSTR Name);

  HRESULT GetResourceBindingDescByName(/*_In_*/ LPCSTR Name,
                                       /*_Out_*/ D3D11_SHADER_INPUT_BIND_DESC* pDesc);

  // Use D3D_RETURN_PARAMETER_INDEX to get description of the return value.
  ID3D11FunctionParameterReflection* GetFunctionParameter(/*_In_*/ INT ParameterIndex);
};

mixin DEFINE_GUID!(ID3D11FunctionParameterReflection, "42757488-334F-47FE-982E-1A65D08CC462");
interface ID3D11FunctionParameterReflection
{
  HRESULT GetDesc(/*_Out_*/ D3D11_PARAMETER_DESC* pDesc);
};

mixin DEFINE_GUID!(ID3D11Module, "CAC701EE-80FC-4122-8242-10B39C8CEC34");
interface ID3D11Module : IUnknown
{
  HRESULT QueryInterface(/*_In_*/ REFIID iid, /*_Out_*/ LPVOID* ppv);
  ULONG AddRef();
  ULONG Release();

  // Create an instance of a module for resource re-binding.
  HRESULT CreateInstance(/*_In_opt_*/ LPCSTR pNamespace,
                         /*_COM_Outptr_*/ ID3D11ModuleInstance** ppModuleInstance);
};


mixin DEFINE_GUID!(ID3D11ModuleInstance, "469E07F7-045A-48D5-AA12-68A478CDF75D");
interface ID3D11ModuleInstance : IUnknown
{
  HRESULT QueryInterface(/*_In_*/ REFIID iid, /*_Out_*/ LPVOID* ppv);
  ULONG AddRef();
  ULONG Release();

  //
  // Resource binding API.
  //
  HRESULT BindConstantBuffer(/*_In_*/ UINT uSrcSlot, /*_In_*/ UINT uDstSlot, /*_In_*/ UINT cbDstOffset);
  HRESULT BindConstantBufferByName(/*_In_*/ LPCSTR pName, /*_In_*/ UINT uDstSlot, /*_In_*/ UINT cbDstOffset);

  HRESULT BindResource(/*_In_*/ UINT uSrcSlot, /*_In_*/ UINT uDstSlot, /*_In_*/ UINT uCount);
  HRESULT BindResourceByName(/*_In_*/ LPCSTR pName, /*_In_*/ UINT uDstSlot, /*_In_*/ UINT uCount);

  HRESULT BindSampler(/*_In_*/ UINT uSrcSlot, /*_In_*/ UINT uDstSlot, /*_In_*/ UINT uCount);
  HRESULT BindSamplerByName(/*_In_*/ LPCSTR pName, /*_In_*/ UINT uDstSlot, /*_In_*/ UINT uCount);

  HRESULT BindUnorderedAccessView(/*_In_*/ UINT uSrcSlot, /*_In_*/ UINT uDstSlot, /*_In_*/ UINT uCount);
  HRESULT BindUnorderedAccessViewByName(/*_In_*/ LPCSTR pName, /*_In_*/ UINT uDstSlot, /*_In_*/ UINT uCount);

  HRESULT BindResourceAsUnorderedAccessView(/*_In_*/ UINT uSrcSrvSlot, /*_In_*/ UINT uDstUavSlot, /*_In_*/ UINT uCount);
  HRESULT BindResourceAsUnorderedAccessViewByName(/*_In_*/ LPCSTR pSrvName, /*_In_*/ UINT uDstUavSlot, /*_In_*/ UINT uCount);
};


mixin DEFINE_GUID!(ID3D11Linker, "59A6CD0E-E10D-4C1F-88C0-63ABA1DAF30E");
interface ID3D11Linker : IUnknown
{
  HRESULT QueryInterface(/*_In_*/ REFIID iid, /*_Out_*/ LPVOID* ppv);
  ULONG AddRef();
  ULONG Release();

  // Link the shader and produce a shader blob suitable to D3D runtime.
  HRESULT Link(/*_In_*/ ID3D11ModuleInstance* pEntry,
               /*_In_*/ LPCSTR pEntryName,
               /*_In_*/ LPCSTR pTargetName,
               /*_In_*/ UINT uFlags,
               /*_COM_Outptr_*/ ID3DBlob** ppShaderBlob,
               /*_Always_(_Outptr_opt_result_maybenull_)*/ ID3DBlob** ppErrorBuffer);

  // Add an instance of a library module to be used for linking.
  HRESULT UseLibrary(/*_In_*/ ID3D11ModuleInstance* pLibraryMI);

  // Add a clip plane with the plane coefficients taken from a cbuffer entry for 10L9 shaders.
  HRESULT AddClipPlaneFromCBuffer(/*_In_*/ UINT uCBufferSlot, /*_In_*/ UINT uCBufferEntry);
};


mixin DEFINE_GUID!(ID3D11LinkingNode, "D80DD70C-8D2F-4751-94A1-03C79B3556DB");
interface ID3D11LinkingNode : IUnknown
{
  HRESULT QueryInterface(/*_In_*/ REFIID iid, /*_Out_*/ LPVOID* ppv);
  ULONG AddRef();
  ULONG Release();
};


mixin DEFINE_GUID!(ID3D11FunctionLinkingGraph, "54133220-1CE8-43D3-8236-9855C5CEECFF");
interface ID3D11FunctionLinkingGraph : IUnknown
{
  HRESULT QueryInterface(/*_In_*/ REFIID iid, /*_Out_*/ LPVOID* ppv);
  ULONG AddRef();
  ULONG Release();

  // Create a shader module out of FLG description.
  HRESULT CreateModuleInstance(/*_COM_Outptr_*/ ID3D11ModuleInstance** ppModuleInstance,
                               /*_Always_(_Outptr_opt_result_maybenull_)*/ ID3DBlob** ppErrorBuffer);

  HRESULT SetInputSignature(/*__in_ecount(cInputParameters)*/ const D3D11_PARAMETER_DESC* pInputParameters,
                            /*_In_*/ UINT cInputParameters,
                            /*_COM_Outptr_*/ ID3D11LinkingNode** ppInputNode);

  HRESULT SetOutputSignature(/*__in_ecount(cOutputParameters)*/ const D3D11_PARAMETER_DESC* pOutputParameters,
                             /*_In_*/ UINT cOutputParameters,
                             /*_COM_Outptr_*/ ID3D11LinkingNode** ppOutputNode);

  HRESULT CallFunction(/*_In_opt_*/ LPCSTR pModuleInstanceNamespace,
                       /*_In_*/ ID3D11Module* pModuleWithFunctionPrototype,
                       /*_In_*/ LPCSTR pFunctionName,
                       /*_COM_Outptr_*/ ID3D11LinkingNode** ppCallNode);

  HRESULT PassValue(/*_In_*/ ID3D11LinkingNode* pSrcNode,
                    /*_In_*/ INT SrcParameterIndex,
                    /*_In_*/ ID3D11LinkingNode* pDstNode,
                    /*_In_*/ INT DstParameterIndex);

  HRESULT PassValueWithSwizzle(/*_In_*/ ID3D11LinkingNode* pSrcNode,
                               /*_In_*/ INT SrcParameterIndex,
                               /*_In_*/ LPCSTR pSrcSwizzle,
                               /*_In_*/ ID3D11LinkingNode* pDstNode,
                               /*_In_*/ INT DstParameterIndex,
                               /*_In_*/ LPCSTR pDstSwizzle);

  HRESULT GetLastError(/*_Always_(_Outptr_opt_result_maybenull_)*/ ID3DBlob** ppErrorBuffer);

  HRESULT GenerateHlsl(/*_In_*/ UINT uFlags,                 // uFlags is reserved for future use.
                       /*_COM_Outptr_*/ ID3DBlob** ppBuffer);
};
