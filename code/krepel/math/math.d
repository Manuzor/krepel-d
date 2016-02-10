module krepel.math.math;

import std.math;
import krepel.algorithm.comparison;

float Sqrt(float value)
{
  // TODO replace with own (opcode?)
  return std.math.sqrt(value);
}

float Abs(float value)
{
  // TODO replace with own (opcode?)
  return std.math.abs(value);
}

bool IsNaN(float value)
{
  bool result;
  asm
  {
    fld value; // Load value to float stack ST(0)
    ftst; // Compare ST(0) with 0.0
    fstsw AX; // Write FPU Status Register to AX (16 Bit)
    and AX, 0x4500; // Filter interesting bits (C0 C2 C3)
    cmp AX, 0x4500; // Check if C0 C2 and C3 are set
    lahf; // Load result of cmp into AH
    and AH, 0x41; // Filter intereseting bits (CF, ZF)
    xor AH, 0x40; // Check if ZF is set and CF is zero.
    mov result, AH; // Write result into bool variable
  }
  return !result;
}

/// Checks if a and b are equals with respect to some epsilon
/// Epsilon gets scaled by the bigger of the two values to compare
/// to compensate the reduced precision when using higher magnitudes
bool NearlyEquals(float a, float b, float epsilon = 1.0e-4f)
{
  // Scale epsilon along the magnitude of the bigger of the two.
  // This way we compoensate the reduced precision on bigger values.
  return Abs(a - b) < Max(epsilon, (epsilon * Max(Abs(a), Abs(b))));
}

/// Nearly Equals
unittest
{
  float a = 1.0f;
  float b = 1.0f + 1.0e-5f;
  float c = 10.0f;

  float d = 1e10f;
  // Default epsilon tolerates precision within 4 decimal points,
  // so values are marked as different when they differ by 1e6f, when the order of magnitude is as 1e10f (10-4=6)
  // A difference of 1e5f should be equal;
  float e = 1e10f + 1e5f;
  float f = 1e11f;
  float g = 1e10f + 1e6f;

  assert(NearlyEquals(a,b));
  assert(!NearlyEquals(a,c));

  assert(NearlyEquals(d,e));
  assert(!NearlyEquals(d,f));
  assert(!NearlyEquals(d,g));
}

/// NaN Test
unittest
{
  float f;
  float correct =1.0f;
  assert(IsNaN(f));
  assert(!IsNaN(correct));
}
