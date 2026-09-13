import Mathlib

namespace Lean4Verified.MathlibNumberTheory

open Nat

example : Nat.Prime 2 := by
  exact Nat.prime_two

example : Nat.gcd 18 24 = 6 := by
  decide

example : 7 ∣ 21 := by
  refine ⟨3, by decide⟩

end Lean4Verified.MathlibNumberTheory

