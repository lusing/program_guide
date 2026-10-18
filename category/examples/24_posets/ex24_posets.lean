/- ex23 —— 完备预序与剩余映射（Simmons 6.1/6.2）
   菱形上 f(x) := x ∧ a 保全部 sup，g := 公式查表，
   伴随定律十六格穷尽。 -/

inductive Diam : Type
  | dBot | dL | dR | dTop   -- ⊥ < a=dL, b=dR < ⊤

def leD : Diam → Diam → Bool
  | .dBot, _ => true
  | .dL, .dL => true
  | .dL, .dTop => true
  | .dR, .dR => true
  | .dR, .dTop => true
  | .dTop, .dTop => true
  | _, _ => false

def supD : Diam → Diam → Diam
  | .dBot, z => z
  | z, .dBot => z
  | .dL, .dL => .dL
  | .dR, .dR => .dR
  | .dTop, _ => .dTop
  | _, .dTop => .dTop
  | _, _ => .dTop          -- a 与 b 的 sup 是 ⊤

def infD : Diam → Diam → Diam
  | .dTop, z => z
  | z, .dTop => z
  | .dBot, _ => .dBot
  | _, .dBot => .dBot
  | .dL, .dL => .dL
  | .dR, .dR => .dR
  | _, _ => .dBot          -- a 与 b 的 inf 是 ⊥

def fMeet (x : Diam) : Diam := infD x .dL

/-- g(y) := ⋁{x | f x ≤ y}，按公式查表算出 -/
def gAdj : Diam → Diam
  | .dBot => .dR
  | .dL => .dTop
  | .dR => .dR
  | .dTop => .dTop

/-- 伴随定律：f(x) ≤ y ⟺ x ≤ g(y) —— 十六格穷尽 -/
theorem adjunction_law (x y : Diam) :
    leD (fMeet x) y = leD x (gAdj y) := by
  cases x <;> cases y <;> rfl

/-- 保二元 sup -/
theorem fMeet_join (x y : Diam) :
    fMeet (supD x y) = supD (fMeet x) (fMeet y) := by
  cases x <;> cases y <;> rfl

/-- 保空 sup：f(⊥) = ⊥ -/
example : fMeet .dBot = .dBot := rfl
