namespace Lean4Verified.Functions

def square (n : Nat) : Nat := n * n
def applyTwice (f : Nat → Nat) (x : Nat) : Nat := f (f x)

def result1 : Nat := square 6
def result2 : Nat := applyTwice (fun x => x + 1) 10

theorem applyTwice_id (x : Nat) : applyTwice (fun t => t) x = x := by
  rfl

end Lean4Verified.Functions

