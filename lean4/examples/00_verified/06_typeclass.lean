namespace Lean4Verified.Typeclass

class SizeOf (α : Type) where
  sizeOf : α → Nat

instance : SizeOf Nat where
  sizeOf n := n

instance : SizeOf (List Nat) where
  sizeOf xs := xs.length

def totalSize {α : Type} [SizeOf α] (items : List α) : Nat :=
  items.foldl (fun acc x => acc + SizeOf.sizeOf x) 0

def demo1 : Nat := totalSize [1, 2, 3]
def demo2 : Nat := totalSize [[1, 2], [3], []]

end Lean4Verified.Typeclass

