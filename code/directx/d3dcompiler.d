module directx.d3dcompiler;
version(Windows):

import core.sys.windows.windows;

public import directx.d3d11shader;

// TODO: directx.d3d10shader?
alias ID3D10Effect = void*;


enum D3D_COMPILER_VERSION = 47;

enum D3DCOMPILE_DEBUG                              = 1 << 0;
enum D3DCOMPILE_SKIP_VALIDATION                    = 1 << 1;
enum D3DCOMPILE_SKIP_OPTIMIZATION                  = 1 << 2;
enum D3DCOMPILE_PACK_MATRIX_ROW_MAJOR              = 1 << 3;
enum D3DCOMPILE_PACK_MATRIX_COLUMN_MAJOR           = 1 << 4;
enum D3DCOMPILE_PARTIAL_PRECISION                  = 1 << 5;
enum D3DCOMPILE_FORCE_VS_SOFTWARE_NO_OPT           = 1 << 6;
enum D3DCOMPILE_FORCE_PS_SOFTWARE_NO_OPT           = 1 << 7;
enum D3DCOMPILE_NO_PRESHADER                       = 1 << 8;
enum D3DCOMPILE_AVOID_FLOW_CONTROL                 = 1 << 9;
enum D3DCOMPILE_PREFER_FLOW_CONTROL                = 1 << 10;
enum D3DCOMPILE_ENABLE_STRICTNESS                  = 1 << 11;
enum D3DCOMPILE_ENABLE_BACKWARDS_COMPATIBILITY     = 1 << 12;
enum D3DCOMPILE_IEEE_STRICTNESS                    = 1 << 13;
enum D3DCOMPILE_OPTIMIZATION_LEVEL0                = 1 << 14;
enum D3DCOMPILE_OPTIMIZATION_LEVEL1                = 0;
enum D3DCOMPILE_OPTIMIZATION_LEVEL2                = (1 << 14) | (1 << 15);
enum D3DCOMPILE_OPTIMIZATION_LEVEL3                = 1 << 15;
enum D3DCOMPILE_RESERVED16                         = 1 << 16;
enum D3DCOMPILE_RESERVED17                         = 1 << 17;
enum D3DCOMPILE_WARNINGS_ARE_ERRORS                = 1 << 18;
enum D3DCOMPILE_RESOURCES_MAY_ALIAS                = 1 << 19;
enum D3DCOMPILE_ENABLE_UNBOUNDED_DESCRIPTOR_TABLES = 1 << 20;
enum D3DCOMPILE_ALL_RESOURCES_BOUND                = 1 << 21;

enum D3DCOMPILE_EFFECT_CHILD_EFFECT              = 1 << 0;
enum D3DCOMPILE_EFFECT_ALLOW_SLOW_OPS            = 1 << 1;

@property auto D3D_COMPILE_STANDARD_FILE_INCLUDE() { return cast(ID3DInclude)(cast(void*)null + 1); }

enum D3DCOMPILE_SECDATA_MERGE_UAV_SLOTS         = 0x00000001;
enum D3DCOMPILE_SECDATA_PRESERVE_TEMPLATE_SLOTS = 0x00000002;
enum D3DCOMPILE_SECDATA_REQUIRE_TEMPLATE_MATCH  = 0x00000004;

enum D3D_DISASM_ENABLE_COLOR_CODE            = 0x00000001;
enum D3D_DISASM_ENABLE_DEFAULT_VALUE_PRINTS  = 0x00000002;
enum D3D_DISASM_ENABLE_INSTRUCTION_NUMBERING = 0x00000004;
enum D3D_DISASM_ENABLE_INSTRUCTION_CYCLE     = 0x00000008;
enum D3D_DISASM_DISABLE_DEBUG_INFO           = 0x00000010;
enum D3D_DISASM_ENABLE_INSTRUCTION_OFFSET    = 0x00000020;
enum D3D_DISASM_INSTRUCTION_ONLY             = 0x00000040;
enum D3D_DISASM_PRINT_HEX_LITERALS           = 0x00000080;

enum D3D_GET_INST_OFFSETS_INCLUDE_NON_EXECUTABLE = 0x00000001;

enum D3DCOMPILER_STRIP_FLAGS
{
  D3DCOMPILER_STRIP_REFLECTION_DATA = 0x00000001,
  D3DCOMPILER_STRIP_DEBUG_INFO      = 0x00000002,
  D3DCOMPILER_STRIP_TEST_BLOBS      = 0x00000004,
  D3DCOMPILER_STRIP_PRIVATE_DATA    = 0x00000008,
  D3DCOMPILER_STRIP_ROOT_SIGNATURE  = 0x00000010,
  D3DCOMPILER_STRIP_FORCE_DWORD     = 0x7fffffff,
}

enum D3D_BLOB_PART
{
  D3D_BLOB_INPUT_SIGNATURE_BLOB,
  D3D_BLOB_OUTPUT_SIGNATURE_BLOB,
  D3D_BLOB_INPUT_AND_OUTPUT_SIGNATURE_BLOB,
  D3D_BLOB_PATCH_CONSTANT_SIGNATURE_BLOB,
  D3D_BLOB_ALL_SIGNATURE_BLOB,
  D3D_BLOB_DEBUG_INFO,
  D3D_BLOB_LEGACY_SHADER,
  D3D_BLOB_XNA_PREPASS_SHADER,
  D3D_BLOB_XNA_SHADER,
  D3D_BLOB_PDB,
  D3D_BLOB_PRIVATE_DATA,
  D3D_BLOB_ROOT_SIGNATURE,

  D3D_BLOB_TEST_ALTERNATE_SHADER = 0x8000,
  D3D_BLOB_TEST_COMPILE_DETAILS,
  D3D_BLOB_TEST_COMPILE_PERF,
  D3D_BLOB_TEST_COMPILE_REPORT,
}

struct D3D_SHADER_DATA
{
  LPCVOID pBytecode;
  SIZE_T BytecodeLength;
}

enum D3D_COMPRESS_SHADER_KEEP_ALL_PARTS = 0x00000001;

extern(Windows) @nogc nothrow
{
  alias PFN_D3DReadFileToBlob = HRESULT function(LPCWSTR pFileName, ID3DBlob* ppContents);
  alias PFN_D3DWriteBlobToFile = HRESULT function(ID3DBlob pBlob, LPCWSTR pFileName, BOOL bOverwrite);
  alias PFN_D3DCompile = HRESULT function(LPCVOID pSrcData, SIZE_T SrcDataSize, LPCSTR pSourceName, in D3D_SHADER_MACRO* pDefines, ID3DInclude pInclude, LPCSTR pEntrypoint, LPCSTR pTarget, UINT Flags1, UINT Flags2, ID3DBlob* ppCode, ID3DBlob* ppErrorMsgs);
  alias PFN_D3DCompile2 = HRESULT function(LPCVOID pSrcData, SIZE_T SrcDataSize, LPCSTR pSourceName, in D3D_SHADER_MACRO* pDefines, ID3DInclude pInclude, LPCSTR pEntrypoint, LPCSTR pTarget, UINT Flags1, UINT Flags2, UINT SecondaryDataFlags, LPCVOID pSecondaryData, SIZE_T SecondaryDataSize, ID3DBlob* ppCode, ID3DBlob* ppErrorMsgs);
  alias PFN_D3DCompileFromFile = HRESULT function(LPCWSTR pFileName, in D3D_SHADER_MACRO* pDefines, ID3DInclude pInclude, LPCSTR pEntrypoint, LPCSTR pTarget, UINT Flags1, UINT Flags2, ID3DBlob* ppCode, ID3DBlob* ppErrorMsgs);
  alias PFN_D3DPreprocess = HRESULT function(LPCVOID pSrcData, SIZE_T SrcDataSize, LPCSTR pSourceName, in D3D_SHADER_MACRO* pDefines, ID3DInclude pInclude, ID3DBlob* ppCodeText, ID3DBlob* ppErrorMsgs);
  alias PFN_D3DGetDebugInfo = HRESULT function(LPCVOID pSrcData, SIZE_T SrcDataSize, ID3DBlob* ppDebugInfo);
  alias PFN_D3DReflect = HRESULT function(LPCVOID pSrcData, SIZE_T SrcDataSize, REFIID pInterface, void** ppReflector);
  alias PFN_D3DReflectLibrary = HRESULT function(LPCVOID pSrcData, SIZE_T SrcDataSize, REFIID riid, LPVOID* ppReflector);
  alias PFN_D3DDisassemble = HRESULT function(LPCVOID pSrcData, SIZE_T SrcDataSize, UINT Flags, LPCSTR szComments, ID3DBlob* ppDisassembly);
  alias PFN_D3DDisassembleRegion = HRESULT function(LPCVOID pSrcData, SIZE_T SrcDataSize, UINT Flags, LPCSTR szComments, SIZE_T StartByteOffset, SIZE_T NumInsts, SIZE_T* pFinishByteOffset, ID3DBlob* ppDisassembly);
  alias PFN_D3DCreateLinker = HRESULT function(ID3D11Linker* ppLinker);
  alias PFN_D3DLoadModule = HRESULT function(LPCVOID pSrcData, SIZE_T cbSrcDataSize, ID3D11Module* ppModule);
  alias PFN_D3DCreateFunctionLinkingGraph = HRESULT function(UINT uFlags, ID3D11FunctionLinkingGraph* ppFunctionLinkingGraph);
  alias PFN_D3DGetTraceInstructionOffsets = HRESULT function(LPCVOID pSrcData, SIZE_T SrcDataSize, UINT Flags, SIZE_T StartInstIndex, SIZE_T NumInsts, SIZE_T* pOffsets, SIZE_T* pTotalInsts);
  alias PFN_D3DGetInputSignatureBlob = HRESULT function(LPCVOID pSrcData, SIZE_T SrcDataSize, ID3DBlob* ppSignatureBlob);
  alias PFN_D3DGetOutputSignatureBlob = HRESULT function(LPCVOID pSrcData, SIZE_T SrcDataSize, ID3DBlob* ppSignatureBlob);
  alias PFN_D3DGetInputAndOutputSignatureBlob = HRESULT function(LPCVOID pSrcData, SIZE_T SrcDataSize, ID3DBlob* ppSignatureBlob);
  alias PFN_D3DStripShader = HRESULT function(LPCVOID pShaderBytecode, SIZE_T BytecodeLength, UINT uStripFlags, ID3DBlob* ppStrippedBlob);
  alias PFN_D3DGetBlobPart = HRESULT function(LPCVOID pSrcData, SIZE_T SrcDataSize, D3D_BLOB_PART Part, UINT Flags, ID3DBlob* ppPart);
  alias PFN_D3DSetBlobPart = HRESULT function(LPCVOID pSrcData, SIZE_T SrcDataSize, D3D_BLOB_PART Part, UINT Flags, LPCVOID pPart, SIZE_T PartSize, ID3DBlob* ppNewShader);
  alias PFN_D3DCreateBlob = HRESULT function(SIZE_T Size, ID3DBlob* ppBlob);
  alias PFN_D3DCompressShaders = HRESULT function(UINT uNumShaders, D3D_SHADER_DATA* pShaderData, UINT uFlags, ID3DBlob* ppCompressedData);
  alias PFN_D3DDecompressShaders = HRESULT function(LPCVOID pSrcData, SIZE_T SrcDataSize, UINT uNumShaders, UINT uStartIndex, UINT* pIndices, UINT uFlags, ID3DBlob* ppShaders, UINT* pTotalShaders);
  alias PFN_D3DDisassemble10Effect = HRESULT function(ID3D10Effect pEffect, UINT Flags, ID3DBlob* ppDisassembly);

  version(D3DCompiler_RuntimeLinking)
  {
    __gshared
    {
      private enum DefaultStubReturnValue = ERROR_DEVICE_NOT_CONNECTED;

      PFN_D3DReadFileToBlob D3DReadFileToBlob = (pFileName, ppContents) => DefaultStubReturnValue;
      PFN_D3DWriteBlobToFile D3DWriteBlobToFile = (pBlob, pFileName, bOverwrite) => DefaultStubReturnValue;
      PFN_D3DCompile D3DCompile = (pSrcData, SrcDataSize, pSourceName, pDefines, pInclude, pEntrypoint, pTarget, Flags1, Flags2, ppCode, ppErrorMsgs) => DefaultStubReturnValue;
      PFN_D3DCompile2 D3DCompile2 = (pSrcData, SrcDataSize, pSourceName, pDefines, pInclude, pEntrypoint, pTarget, Flags1, Flags2, SecondaryDataFlags, pSecondaryData, SecondaryDataSize, ppCode, ppErrorMsgs) => DefaultStubReturnValue;
      PFN_D3DCompileFromFile D3DCompileFromFile = (pFileName, pDefines, pInclude, pEntrypoint, pTarget, Flags1, Flags2, ppCode, ppErrorMsgs) => DefaultStubReturnValue;
      PFN_D3DPreprocess D3DPreprocess = (pSrcData, SrcDataSize, pSourceName, pDefines, pInclude, ppCodeText, ppErrorMsgs) => DefaultStubReturnValue;
      PFN_D3DGetDebugInfo D3DGetDebugInfo = (pSrcData, SrcDataSize, ppDebugInfo) => DefaultStubReturnValue;
      PFN_D3DReflect D3DReflect = (pSrcData, SrcDataSize, pInterface, ppReflector) => DefaultStubReturnValue;
      PFN_D3DReflectLibrary D3DReflectLibrary = (pSrcData, SrcDataSize, riid, ppReflector) => DefaultStubReturnValue;
      PFN_D3DDisassemble D3DDisassemble = (pSrcData, SrcDataSize, Flags, szComments, ppDisassembly) => DefaultStubReturnValue;
      PFN_D3DDisassembleRegion D3DDisassembleRegion = (pSrcData, SrcDataSize, Flags, szComments, StartByteOffset, NumInsts, pFinishByteOffset, ppDisassembly) => DefaultStubReturnValue;
      PFN_D3DCreateLinker D3DCreateLinker = (ppLinker) => DefaultStubReturnValue;
      PFN_D3DLoadModule D3DLoadModule = (pSrcData, cbSrcDataSize, ppModule) => DefaultStubReturnValue;
      PFN_D3DCreateFunctionLinkingGraph D3DCreateFunctionLinkingGraph = (uFlags, ppFunctionLinkingGraph) => DefaultStubReturnValue;
      PFN_D3DGetTraceInstructionOffsets D3DGetTraceInstructionOffsets = (pSrcData, SrcDataSize, Flags, StartInstIndex, NumInsts, pOffsets, pTotalInsts) => DefaultStubReturnValue;
      PFN_D3DGetInputSignatureBlob D3DGetInputSignatureBlob = (pSrcData, SrcDataSize, ppSignatureBlob) => DefaultStubReturnValue;
      PFN_D3DGetOutputSignatureBlob D3DGetOutputSignatureBlob = (pSrcData, SrcDataSize, ppSignatureBlob) => DefaultStubReturnValue;
      PFN_D3DGetInputAndOutputSignatureBlob D3DGetInputAndOutputSignatureBlob = (pSrcData, SrcDataSize, ppSignatureBlob) => DefaultStubReturnValue;
      PFN_D3DStripShader D3DStripShader = (pShaderBytecode, BytecodeLength, uStripFlags, ppStrippedBlob) => DefaultStubReturnValue;
      PFN_D3DGetBlobPart D3DGetBlobPart = (pSrcData, SrcDataSize, Part, Flags, ppPart) => DefaultStubReturnValue;
      PFN_D3DSetBlobPart D3DSetBlobPart = (pSrcData, SrcDataSize, Part, Flags, pPart, PartSize, ppNewShader) => DefaultStubReturnValue;
      PFN_D3DCreateBlob D3DCreateBlob = (Size, ppBlob) => DefaultStubReturnValue;
      PFN_D3DCompressShaders D3DCompressShaders = (uNumShaders, pShaderData, uFlags, ppCompressedData) => DefaultStubReturnValue;
      PFN_D3DDecompressShaders D3DDecompressShaders = (pSrcData, SrcDataSize, uNumShaders, uStartIndex, pIndices, uFlags, ppShaders, pTotalShaders) => DefaultStubReturnValue;
      PFN_D3DDisassemble10Effect D3DDisassemble10Effect = (pEffect, Flags, ppDisassembly) => DefaultStubReturnValue;
    }
  }
  else
  {
    HRESULT D3DReadFileToBlob(/*_In_*/ LPCWSTR pFileName, /*_Out_*/ ID3DBlob* ppContents);
    HRESULT D3DWriteBlobToFile(/*_In_*/ ID3DBlob pBlob, /*_In_*/ LPCWSTR pFileName,
                               /*_In_*/ BOOL bOverwrite);
    HRESULT D3DCompile(/*_In_reads_bytes_(SrcDataSize)*/ LPCVOID pSrcData, /*_In_*/ SIZE_T SrcDataSize,
                       /*_In_opt_*/ LPCSTR pSourceName,
                       /*_In_reads_opt_(_Inexpressible_(pDefines->Name != NULL))*/ in D3D_SHADER_MACRO* pDefines,
                       /*_In_opt_*/ ID3DInclude pInclude,
                       /*_In_opt_*/ LPCSTR pEntrypoint,
                       /*_In_*/ LPCSTR pTarget,
                       /*_In_*/ UINT Flags1,
                       /*_In_*/ UINT Flags2,
                       /*_Out_*/ ID3DBlob* ppCode,
                       /*_Always_(_Outptr_opt_result_maybenull_)*/ ID3DBlob* ppErrorMsgs);
    HRESULT D3DCompile2(/*_In_reads_bytes_(SrcDataSize)*/ LPCVOID pSrcData, /*_In_*/ SIZE_T SrcDataSize,
                        /*_In_opt_*/ LPCSTR pSourceName,
                        /*_In_reads_opt_(_Inexpressible_(pDefines->Name != NULL))*/ in D3D_SHADER_MACRO* pDefines,
                        /*_In_opt_*/ ID3DInclude pInclude,
                        /*_In_*/ LPCSTR pEntrypoint,
                        /*_In_*/ LPCSTR pTarget,
                        /*_In_*/ UINT Flags1,
                        /*_In_*/ UINT Flags2,
                        /*_In_*/ UINT SecondaryDataFlags,
                        /*_In_reads_bytes_opt_(SecondaryDataSize)*/ LPCVOID pSecondaryData,
                        /*_In_*/ SIZE_T SecondaryDataSize,
                        /*_Out_*/ ID3DBlob* ppCode,
                        /*_Always_(_Outptr_opt_result_maybenull_)*/ ID3DBlob* ppErrorMsgs);
    HRESULT D3DCompileFromFile(/*_In_*/ LPCWSTR pFileName, /*_In_reads_opt_(_Inexpressible_(pDefines->Name != NULL))*/ in D3D_SHADER_MACRO* pDefines,
                               /*_In_opt_*/ ID3DInclude pInclude,
                               /*_In_*/ LPCSTR pEntrypoint,
                               /*_In_*/ LPCSTR pTarget,
                               /*_In_*/ UINT Flags1,
                               /*_In_*/ UINT Flags2,
                               /*_Out_*/ ID3DBlob* ppCode,
                               /*_Always_(_Outptr_opt_result_maybenull_)*/ ID3DBlob* ppErrorMsgs);
    HRESULT D3DPreprocess(/*_In_reads_bytes_(SrcDataSize)*/ LPCVOID pSrcData, /*_In_*/ SIZE_T SrcDataSize,
                          /*_In_opt_*/ LPCSTR pSourceName,
                          /*_In_opt_*/ in D3D_SHADER_MACRO* pDefines,
                          /*_In_opt_*/ ID3DInclude pInclude,
                          /*_Out_*/ ID3DBlob* ppCodeText,
                          /*_Always_(_Outptr_opt_result_maybenull_)*/ ID3DBlob* ppErrorMsgs);
    HRESULT D3DGetDebugInfo(/*_In_reads_bytes_(SrcDataSize)*/ LPCVOID pSrcData, /*_In_*/ SIZE_T SrcDataSize,
                            /*_Out_*/ ID3DBlob* ppDebugInfo);
    HRESULT D3DReflect(/*_In_reads_bytes_(SrcDataSize)*/ LPCVOID pSrcData, /*_In_*/ SIZE_T SrcDataSize,
                       /*_In_*/ REFIID pInterface,
                       /*_Out_*/ void** ppReflector);
    HRESULT D3DReflectLibrary(/*__in_bcount(SrcDataSize)*/ LPCVOID pSrcData, /*__in*/ SIZE_T SrcDataSize,
                              /*__in*/ REFIID riid,
                              /*__out*/ LPVOID* ppReflector);
    HRESULT D3DDisassemble(/*_In_reads_bytes_(SrcDataSize)*/ LPCVOID pSrcData, /*_In_*/ SIZE_T SrcDataSize,
                           /*_In_*/ UINT Flags,
                           /*_In_opt_*/ LPCSTR szComments,
                           /*_Out_*/ ID3DBlob* ppDisassembly);
    HRESULT D3DDisassembleRegion(/*_In_reads_bytes_(SrcDataSize)*/ LPCVOID pSrcData, /*_In_*/ SIZE_T SrcDataSize,
                                 /*_In_*/ UINT Flags,
                                 /*_In_opt_*/ LPCSTR szComments,
                                 /*_In_*/ SIZE_T StartByteOffset,
                                 /*_In_*/ SIZE_T NumInsts,
                                 /*_Out_opt_*/ SIZE_T* pFinishByteOffset,
                                 /*_Out_*/ ID3DBlob* ppDisassembly);
    HRESULT D3DCreateLinker(/*__out*/ ID3D11Linker* ppLinker);
    HRESULT D3DLoadModule(/*_In_*/ LPCVOID pSrcData, /*_In_*/ SIZE_T cbSrcDataSize,
                          /*_Out_*/ ID3D11Module* ppModule);
    HRESULT D3DCreateFunctionLinkingGraph(/*_In_*/ UINT uFlags, /*_Out_*/ ID3D11FunctionLinkingGraph* ppFunctionLinkingGraph);
    HRESULT D3DGetTraceInstructionOffsets(/*_In_reads_bytes_(SrcDataSize)*/ LPCVOID pSrcData, /*_In_*/ SIZE_T SrcDataSize,
                                          /*_In_*/ UINT Flags,
                                          /*_In_*/ SIZE_T StartInstIndex,
                                          /*_In_*/ SIZE_T NumInsts,
                                          /*_Out_writes_to_opt_(NumInsts, min(NumInsts, *pTotalInsts))*/ SIZE_T* pOffsets,
                                          /*_Out_opt_*/ SIZE_T* pTotalInsts);
    HRESULT D3DGetInputSignatureBlob(/*_In_reads_bytes_(SrcDataSize)*/ LPCVOID pSrcData, /*_In_*/ SIZE_T SrcDataSize,
                                     /*_Out_*/ ID3DBlob* ppSignatureBlob);
    HRESULT D3DGetOutputSignatureBlob(/*_In_reads_bytes_(SrcDataSize)*/ LPCVOID pSrcData, /*_In_*/ SIZE_T SrcDataSize,
                                      /*_Out_*/ ID3DBlob* ppSignatureBlob);
    HRESULT D3DGetInputAndOutputSignatureBlob(/*_In_reads_bytes_(SrcDataSize)*/ LPCVOID pSrcData, /*_In_*/ SIZE_T SrcDataSize,
                                              /*_Out_*/ ID3DBlob* ppSignatureBlob);
    HRESULT D3DStripShader(/*_In_reads_bytes_(BytecodeLength)*/ LPCVOID pShaderBytecode, /*_In_*/ SIZE_T BytecodeLength,
                           /*_In_*/ UINT uStripFlags,
                           /*_Out_*/ ID3DBlob* ppStrippedBlob);
    HRESULT D3DGetBlobPart(/*_In_reads_bytes_(SrcDataSize)*/ LPCVOID pSrcData,
                           /*_In_*/ SIZE_T SrcDataSize,
                           /*_In_*/ D3D_BLOB_PART Part,
                           /*_In_*/ UINT Flags,
                           /*_Out_*/ ID3DBlob* ppPart);
    HRESULT D3DSetBlobPart(/*_In_reads_bytes_(SrcDataSize)*/ LPCVOID pSrcData,
                           /*_In_*/ SIZE_T SrcDataSize,
                           /*_In_*/ D3D_BLOB_PART Part,
                           /*_In_*/ UINT Flags,
                           /*_In_reads_bytes_(PartSize)*/ LPCVOID pPart,
                           /*_In_*/ SIZE_T PartSize,
                           /*_Out_*/ ID3DBlob* ppNewShader);
    HRESULT D3DCreateBlob(/*_In_*/ SIZE_T Size, /*_Out_*/ ID3DBlob* ppBlob);
    HRESULT D3DCompressShaders(/*_In_*/ UINT uNumShaders, /*_In_reads_(uNumShaders)*/ D3D_SHADER_DATA* pShaderData,
                               /*_In_*/ UINT uFlags,
                               /*_Out_*/ ID3DBlob* ppCompressedData);
    HRESULT D3DDecompressShaders(/*_In_reads_bytes_(SrcDataSize)*/ LPCVOID pSrcData, /*_In_*/ SIZE_T SrcDataSize,
                                 /*_In_*/ UINT uNumShaders,
                                 /*_In_*/ UINT uStartIndex,
                                 /*_In_reads_opt_(uNumShaders)*/ UINT* pIndices,
                                 /*_In_*/ UINT uFlags,
                                 /*_Out_writes_(uNumShaders)*/ ID3DBlob* ppShaders,
                                 /*_Out_opt_*/ UINT* pTotalShaders);
    HRESULT D3DDisassemble10Effect(/*_In_*/ ID3D10Effect pEffect, /*_In_*/ UINT Flags,
                                   /*_Out_*/ ID3DBlob* ppDisassembly);
  }
}
