import Mathlib

namespace Lean4Verified.MathlibRing

variable (a b : ℤ)

example : (a + b) ^ 2 = a ^ 2 + 2 * a * b + b ^ 2 := by
  ring

example : (a - b) * (a + b) = a ^ 2 - b ^ 2 := by
  ring

end Lean4Verified.MathlibRing

