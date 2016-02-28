module krepel.math.math;

import std.math;
import krepel.algorithm.comparison;
import Meta = krepel.meta;

@safe:
@nogc:
nothrow:

/// Returns the square root of the given Value
float Sqrt(float Value)
{
  // TODO replace with own (opcode?)
  return std.math.sqrt(Value);
}

/// Returns the absolute Value (the positive Value)
float Abs(float Value)
{
  // TODO replace with own (opcode?)
  return std.math.abs(Value);
}

/// Checks if the given float Value is QNaN
bool IsNaN(float Value)
{
  bool Result;
  asm @nogc @safe nothrow
  {
    fld Value; // Load Value to float stack ST(0)
    ftst; // Compare ST(0) with 0.0
    fstsw AX; // Write FPU Status Register to AX (16 Bit)
    and AX, 0x4500; // Filter interesting bits (C0 C2 C3)
    cmp AX, 0x4500; // Check if C0 C2 and C3 are set
    lahf; // Load result of cmp into AH
    and AH, 0x41; // Filter intereseting bits (CF, ZF)
    xor AH, 0x40; // Check if ZF is set and CF is zero.
    mov Result, AH; // Write result into bool variable
  }
  return !Result;
}

/// Checks if a and b are equals with respect to some epsilon
/// Epsilon gets scaled by the bigger of the two Values to compare
/// to compensate the reduced precision when using higher magnitudes
bool NearlyEquals(float A, float B, float Epsilon = 1.0e-4f)
{
  // Scale epsilon along the magnitude of the bigger of the two.
  // This way we compoensate the reduced precision on bigger Values.
  return Abs(A - B) < Max(Epsilon, (Epsilon * Max(Abs(A), Abs(B))));
}

/// Checks whether the given number is an odd number.
/// Note: The given number must be an integral type.
/// See_Also: IsEven
bool IsOdd(NumberType)(NumberType Number)
  if(Meta.IsIntegral!NumberType)
{
  // If the first bit is set, we have an odd number.
  return Number & 1;
}

/// Checks whether the given number is an even number.
/// Note: The given number must be an integral type.
/// See_Also: IsOdd
alias IsEven = (N) => !IsOdd(N);

/// Checks whether the given number is a power of two.
/// Note: The given number must be an integral type.
bool IsPowerOfTwo(NumberType)(NumberType Number)
  if(Meta.IsIntegral!NumberType)
{
  return (Number & (~Number + 1)) == Number;
}

//
// Unit Tests
//

/// Nearly Equals
unittest
{
  float A = 1.0f;
  float B = 1.0f + 1.0e-5f;
  float C = 10.0f;

  float D = 1e10f;
  // Default epsilon tolerates precision within 4 decimal points,
  // so Values are marked as different when they differ by 1e6f, when the order of magnitude is as 1e10f (10-4=6)
  // A difference of 1e5f should be equal;
  float E = 1e10f + 1e5f;
  float F = 1e11f;
  float G = 1e10f + 1e6f;

  assert(NearlyEquals(A,B));
  assert(!NearlyEquals(A,C));

  assert(NearlyEquals(D,E));
  assert(!NearlyEquals(D,F));
  assert(!NearlyEquals(D,G));
}

/// NaN Test
unittest
{
  float F;
  float Correct = 1.0f;
  assert(IsNaN(F));
  assert(!IsNaN(Correct));
}

// IsOdd / IsEven
unittest
{
  assert(!0.IsOdd);
  assert( 1.IsOdd);
  assert(!2.IsOdd);
  assert( 3.IsOdd);

  assert( 0.IsEven);
  assert(!1.IsEven);
  assert( 2.IsEven);
  assert(!3.IsEven);
}

// IsPowerOfTwo
unittest
{
  ulong[10] SomePOTs = [1, 2, 4, 8, 16, 32, 64, 128, 256, 512];
  ulong[27] NonPOTs = [3, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 33];

  foreach(SomePOT; SomePOTs)
  {
    assert(SomePOT.IsPowerOfTwo);
  }

  foreach(NonPOT; NonPOTs)
  {
    assert(!NonPOT.IsPowerOfTwo);
  }
}
