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

/-! 【闭包算子与闭元互同构】（高级范畴论 5.1 定理 5.1.1/5.1.2）——
链 {0 < 1} 上 F = 常底 ⊣ G = 常顶（两侧恒真）；GF ≡ 1 闭包、
FG ≡ 0 开核；闭元 {1} 与开元 {0} 经 F 互同构。零公理。 -/
inductive Ch2 : Type
  | c0 | c1

def le2 : Ch2 → Ch2 → Bool
  | .c0, _ => true
  | .c1, .c1 => true
  | _, _ => false

def Fbot (_ : Ch2) : Ch2 := .c0
def Gtop (_ : Ch2) : Ch2 := .c1

theorem galois_pair (a b : Ch2) : le2 (Fbot a) b = le2 a (Gtop b) := by
  cases a <;> cases b <;> rfl

theorem gf_one (a : Ch2) : Gtop (Fbot a) = .c1 := by cases a <;> rfl
theorem fg_zero (b : Ch2) : Fbot (Gtop b) = .c0 := by cases b <;> rfl

def closedA : Ch2 → Bool
  | .c1 => true | .c0 => false

theorem closedA_ok (a : Ch2) (h : closedA a = true) : Gtop (Fbot a) = a := by
  cases a with
  | c1 => rfl
  | c0 => exact absurd h (by simp [closedA])

/-- 定理 5.1.2 的互逆：F₀/G₀ 单点互逆 -/
theorem F0_G0_inverse :
    Gtop (Fbot .c1) = .c1 ∧ Fbot (Gtop .c0) = .c0 := ⟨rfl, rfl⟩
