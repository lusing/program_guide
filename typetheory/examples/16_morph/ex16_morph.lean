/- ============================================================
   16 理论态射与小理论方法 —— Lean 旗舰（Farmer ch.13）
   「在一个理论里证一次，翻译到所有实例」的三层机器面：
     · 语义层：MON 作为结构参数——唯一幺元定理证一遍，
       在 (ℕ,0,+) 与 (ℕ,1,×) 两处运输（Φ⁺ 与 Φ✱）
     · 语构层：翻译 ν 在公式 AST 上逐构造子爬行；
       义务（obligation）= 公理像在目标理论中的有效性，
       由 Nat 引理清偿
     · 负例：GRP → (ℕ,1,×) 的逆元公理像失败——
       见证 2 被机器揪出（Ψ✱ 不是态射）
   ============================================================ -/

-- ============================================================
-- 一、小理论 MON 与它的定理（证明一次）
-- ============================================================
structure Monoid where
  carrier : Type
  mul : carrier → carrier → carrier
  e : carrier
  assoc : ∀ x y z, mul (mul x y) z = mul x (mul y z)
  lid : ∀ x, mul e x = x
  rid : ∀ x, mul x e = x

/-- 书 13.1 的 X_o：双侧幺元唯一。——在「小理论」里证一次 -/
theorem unique_two_sided_id (M : Monoid) :
    ∀ x : M.carrier, (∀ y : M.carrier, M.mul x y = y ∧ M.mul y x = y) → x = M.e := by
  intro x h
  obtain ⟨h1, _⟩ := h M.e
  -- x·e = e（把 x 当幺元用）；又 e 是右幺元：x·e = x ⟹ x = e
  rw [M.rid x] at h1
  exact h1

-- ============================================================
-- 二、两个运输实例（Φ⁺ 与 Φ✱）
-- ============================================================
def NatAddMonoid : Monoid where
  carrier := Nat
  mul := (· + ·)
  e := 0
  assoc := fun _ _ _ => Nat.add_assoc _ _ _
  lid := fun x => Nat.zero_add x
  rid := fun x => Nat.add_zero x

def NatMulMonoid : Monoid where
  carrier := Nat
  mul := (· * ·)
  e := 1
  assoc := fun _ _ _ => Nat.mul_assoc _ _ _
  lid := fun x => Nat.one_mul x
  rid := fun x => Nat.mul_one x

-- 同一条定理运输两次：加法幺元 0 唯一、乘法幺元 1 唯一
example : ∀ x : Nat, (∀ y, x + y = y ∧ y + x = y) → x = 0 :=
  unique_two_sided_id NatAddMonoid
example : ∀ x : Nat, (∀ y, x * y = y ∧ y * x = y) → x = 1 :=
  unique_two_sided_id NatMulMonoid

-- ============================================================
-- 三、语构层：翻译 ν 在公式 AST 上爬行 + 义务清偿
-- ============================================================
/-- 源语言的项与公式（MON 的语言：mul/e 两个符号） -/
inductive MTm where
  | mul : MTm → MTm → MTm
  | e : MTm
  | var : Nat → MTm
inductive MFm where
  | eq : MTm → MTm → MFm
  | imp : MFm → MFm → MFm
  | all : MFm → MFm            -- ∀.（单变量，de Bruijn）

/-- 目标语言的解释：一个「符号 → 操作」的查表 -/
structure Target where
  op : Nat → Nat → Nat
  unit : Nat
  opAssoc : ∀ x y z, op (op x y) z = op x (op y z)
  opLid : ∀ x, op unit x = x
  opRid : ∀ x, op x unit = x

/-- 翻译 ν：基型映射平凡（都落 Nat），常数映射 e ↦ unit、
    mul ↦ op——公式的爬行与书 13.3.1 的 ν 定义逐步对应 -/
def evalT (T : Target) (ρ : List Nat) : MTm → Nat
  | .mul a b => T.op (evalT T ρ a) (evalT T ρ b)
  | .e => T.unit
  | .var k => ρ[k]!

/-- 直接给出可用的语义：holds T ρ f -/
def holds (T : Target) : List Nat → MFm → Prop
  | ρ, .eq a b => evalT T ρ a = evalT T ρ b
  | ρ, .imp p q => holds T ρ p → holds T ρ q
  | ρ, .all f => ∀ v : Nat, holds T (v :: ρ) f

/-- MON 三公理的像在目标 T 中有效 = 翻译的三条义务全部清偿 -/
def obligationsHold (T : Target) : Prop :=
  holds T [] (.all (.all (.all (.imp (.eq (.mul (.mul (.var 2) (.var 1)) (.var 0))
                                        (.mul (.mul (.var 2) (.var 1)) (.var 0)))
                                   (.eq (.mul (.mul (.var 2) (.var 1)) (.var 0))
                                        (.mul (.var 2) (.mul (.var 1) (.var 0))))))))
  ∧ holds T [] (.all (.eq (.mul .e (.var 0)) (.var 0)))
  ∧ holds T [] (.all (.eq (.mul (.var 0) .e) (.var 0)))

-- Φ⁺：加法目标的三条义务全部成立（由 Nat 引理清偿）
theorem plusObligations : obligationsHold
    { op := (· + ·), unit := 0
      opAssoc := fun _ _ _ => Nat.add_assoc _ _ _
      opLid := fun x => Nat.zero_add x
      opRid := fun x => Nat.add_zero x } := by
  refine ⟨fun v w z => by simp [evalT, holds, Nat.add_assoc],
          fun v => by simp [evalT, holds, Nat.zero_add],
          fun v => by simp [evalT, holds, Nat.add_zero]⟩

-- Φ✱：乘法目标同构地清偿
theorem mulObligations : obligationsHold
    { op := (· * ·), unit := 1
      opAssoc := fun _ _ _ => Nat.mul_assoc _ _ _
      opLid := fun x => Nat.one_mul x
      opRid := fun x => Nat.mul_one x } := by
  refine ⟨fun v w z => by simp [evalT, holds, Nat.mul_assoc],
          fun v => by simp [evalT, holds, Nat.one_mul],
          fun v => by simp [evalT, holds, Nat.mul_one]⟩

-- ============================================================
-- 四、负例：GRP → (ℕ,1,×) 不是态射
-- ============================================================
structure Group where
  toMonoid : Monoid
  inv : toMonoid.carrier → toMonoid.carrier
  invL : ∀ x, toMonoid.mul (inv x) x = toMonoid.e
  invR : ∀ x, toMonoid.mul x (inv x) = toMonoid.e

/-- 逆元公理的像：∀x ∃y. y·x = 1 ∧ x·y = 1（乘法目标）——不成立。
    义务失败 ⟹ 翻译不是态射 ⟹ 定理不能运输。见证：2。 -/
example : ¬ (∀ x : Nat, ∃ y : Nat, y * x = 1 ∧ x * y = 1) := by
  intro h
  obtain ⟨y, hy, _⟩ := h 2
  -- y * 2 = 1 在 Nat 上无解（y=0 给 0，y≥1 给 ≥2）
  cases y with
  | zero => simp at hy
  | succ n => rw [Nat.succ_mul] at hy; omega

-- 对照（Prolog 侧）：把同一逆元公理像放到模 2 加法表（xor）上，
-- 0⁻¹=0、1⁻¹=1，义务通过——Ψ⁺ 是态射；乘法/合取表上义务失败。
