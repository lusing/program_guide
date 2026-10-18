/- ex25 —— 幺半集：Σ ⊣ U ⊣ Π（Simmons 6.8-6.11）
   R := (Bool, &&, true)。ΣX = X × Bool 配 (x,r)·s = (x, r∧s)；
   ΠX = (Bool → X) 配 (h·r)(s) = h(r∧s)。
   往返公式与三角恒等式：零公理。 -/

/-- ΣX = X × Bool 的作用 -/
def actS (p : Bool × Bool) (s : Bool) : Bool × Bool := (p.1, p.2 && s)

def unitS (x : Bool) : Bool × Bool := (x, true)

/-- g# : 函数 g 沿 unitS 的扩张 -/
def sharp (g : Bool → Bool) (p : Bool × Bool) : Bool := g p.1 && p.2

/-- (1) g# 保作用 —— andb 结合律 -/
theorem sharp_mor (g : Bool → Bool) (p : Bool × Bool) (s : Bool) :
    sharp g (actS p s) = (sharp g p && s) := by
  show (g p.1 && (p.2 && s)) = ((g p.1 && p.2) && s)
  exact (Bool.and_assoc _ _ _).symm

/-- (2) g# 延拓单位（true 是单位） -/
theorem sharp_eta (g : Bool → Bool) (x : Bool) :
    sharp g (unitS x) = g x := by
  simp [sharp, unitS]

/-- f 保作用的元素级形式 -/
def HomS (f : Bool × Bool → Bool) : Prop :=
  ∀ p s, f (actS p s) = (f p && s)

def flatH (f : Bool × Bool → Bool) (x : Bool) : Bool := f (x, true)

/-- 右往返：f♭♯ = f，用一次保作用 -/
theorem round_flat_sharp (f : Bool × Bool → Bool) (h : HomS f) (p : Bool × Bool) :
    (flatH f p.1 && p.2) = f p := by
  obtain ⟨x, r⟩ := p
  have key := h (x, true) r
  show (f (x, true) && r) = f (x, r)
  rw [← key]
  cases x <;> cases r <;> rfl

/-- ΠX 的作用（预复合）与余单位 -/
def actP (h : Bool → Bool) (r : Bool) : Bool → Bool := fun s => h (r && s)

def counitP (h : Bool → Bool) : Bool := h true

/-- η_A(a)(r) := a·r -/
def etaP (a : Bool) : Bool → Bool := fun r => a && r

/-- 三角恒等式（U ⊣ Π 的 unit 方向） -/
theorem tri_A (a : Bool) : counitP (etaP a) = a := by
  simp [counitP, etaP]

/-- 三步往返的元素级压平：态射律承担推理、实例化承担计算 -/
theorem pi_round3 (f : Bool → Bool → Bool)
    (h : ∀ a r s, f (a && r) s = f a (r && s)) (a r : Bool) :
    f (a && r) true = f a (r && true) :=
  h a r true

/-- 具体态射：f a s := a && s 本身保作用 -/
example (a r s : Bool) :
    (fun a s => a && s) (a && r) s = (fun a s => a && s) a (r && s) :=
  Bool.and_assoc a r s
