namespace Lean4Verified.Structures

structure Point where
  x : Int
  y : Int
deriving Repr

def moveX (p : Point) (dx : Int) : Point :=
  { p with x := p.x + dx }

def origin : Point := { x := 0, y := 0 }
def moved : Point := moveX origin 5

theorem moveX_zero (p : Point) : moveX p 0 = p := by
  cases p
  simp [moveX]

end Lean4Verified.Structures
