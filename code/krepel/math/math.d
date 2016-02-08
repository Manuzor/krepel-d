module krepel.math.math;

import std.math;

float Sqrt(float value)
{
  // TODO replace with own (opcode?)
  return std.math.sqrt(value);
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

// NaN Test
unittest
{
  float f;
  float correct =1.0f;
  assert(IsNaN(f));
  assert(!IsNaN(correct));
}
