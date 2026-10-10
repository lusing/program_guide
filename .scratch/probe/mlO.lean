def nbcol (adj : Nat → Nat → Bool) (col : Nat → Nat) (d v : Nat) : List Nat :=
  ((List.range d).filter (fun u => adj u v)).map col
def pick (L : List Nat) : Nat := 0  -- 占位
def greedy (adj : Nat → Nat → Bool) : Nat → Nat → Nat
  | 0, _ => 0
  | d'+1, v =>
      if v < d' then greedy adj d' v
      else pick (nbcol adj (greedy adj d') d' v)

example (adj : Nat → Nat → Bool) (d' i : Nat) (hj : d' = d') :
    greedy adj (d'+1) i ≠ greedy adj (d'+1) d' := by
  show (if i < d' then greedy adj d' i
        else pick (nbcol adj (greedy adj d') d' i))
       ≠ pick (nbcol adj (greedy adj d') d' d')
  sorry
