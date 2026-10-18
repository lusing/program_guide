/- ex24 —— 截面与三个超幂函子（Simmons 6.5）
   三元素链 0 ≤ 1 ≤ 2、单调 phi : x ↦ min(x+1, 2)。
   伴随串 ∃(phi) ⊣ I(phi) ⊣ ∀(phi)：两条包含等式各 64 格穷尽
   （X、Y 须为下闭截面；非闭组合被假设消灭）。 -/

inductive Ch3 : Type
  | c0 | c1 | c2

def phi : Ch3 → Ch3
  | .c0 => .c1
  | .c1 => .c2
  | .c2 => .c2

def leC : Ch3 → Ch3 → Bool
  | .c0, _ => true
  | .c1, .c1 => true
  | .c1, .c2 => true
  | .c2, .c2 => true
  | _, _ => false

/-- Lean 的 Bool 蕴含 -/
def impb (a b : Bool) : Bool := !a || b

def inclP (X Y : Ch3 → Bool) : Bool :=
  impb (X .c0) (Y .c0) && impb (X .c1) (Y .c1) && impb (X .c2) (Y .c2)

/-- ∃(phi)(X) := ⋃{ ↓phi(x) | x ∈ X } ——直接像 + 下闭包 -/
def existsF (X : Ch3 → Bool) : Ch3 → Bool := fun s =>
  (X .c0 && leC s (phi .c0)) || (X .c1 && leC s (phi .c1)) || (X .c2 && leC s (phi .c2))

/-- I(phi)(Y) := 逆像 -/
def invF (Y : Ch3 → Bool) : Ch3 → Bool := fun t => Y (phi t)

/-- ∀(phi)(X) := (⋃{ ↑phi(t) | t ∉ X })′ ——对偶像 -/
def allF (X : Ch3 → Bool) : Ch3 → Bool := fun s =>
  !((!X .c0 && leC (phi .c0) s) || (!X .c1 && leC (phi .c1) s) || (!X .c2 && leC (phi .c2) s))

/-- 下闭截面判定 -/
def closedP (P : Ch3 → Bool) : Bool :=
  impb (P .c1) (P .c0) && impb (P .c2) (P .c0) && impb (P .c2) (P .c1)

/-- 伴随串左半：∃(phi)(X) ⊆ Y ⟺ X ⊆ I(phi)(Y) —— 64 格穷尽 -/
theorem exists_left_adjoint (X Y : Ch3 → Bool)
    (hX : closedP X = true) (hY : closedP Y = true) :
    inclP (existsF X) Y = inclP X (invF Y) := by
  simp only [closedP, impb] at hX hY
  revert hX hY
  simp only [inclP, existsF, invF, phi, leC, impb]
  cases X Ch3.c0 <;> cases X Ch3.c1 <;> cases X Ch3.c2 <;>
    cases Y Ch3.c0 <;> cases Y Ch3.c1 <;> cases Y Ch3.c2 <;>
    intro hX hY <;> simp_all

/-- 伴随串右半：Y ⊆ ∀(phi)(X) ⟺ I(phi)(Y) ⊆ X —— 64 格穷尽 -/
theorem all_right_adjoint (Y X : Ch3 → Bool)
    (hY : closedP Y = true) (hX : closedP X = true) :
    inclP Y (allF X) = inclP (invF Y) X := by
  simp only [closedP, impb] at hY hX
  revert hY hX
  simp only [inclP, allF, invF, phi, leC, impb]
  cases Y Ch3.c0 <;> cases Y Ch3.c1 <;> cases Y Ch3.c2 <;>
    cases X Ch3.c0 <;> cases X Ch3.c1 <;> cases X Ch3.c2 <;>
    intro hY hX <;> simp_all
