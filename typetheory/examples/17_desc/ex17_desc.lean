/- ============================================================
   17 描述算子、选择与引用 —— Lean 对照（Farmer ch.14）
     · Classical.choose = ε（不定描述）：有见证就选一个，
       choose_spec 是它的「承诺」——与 Coq 的 epsilon 互为镜像
     · #print axioms 记账：choice / em / propext / Quot.sound
       ——古典代价四件套（对照 Coq 侧 Print Assumptions）
     · 有限 AC 代码化：∀x∈域 ∃y R x y ⟹ 显式造出选择函数
     · 引用：深度嵌入 + Ω + 求值往返定理（V8/V9 的样本）
   ============================================================ -/

-- ============================================================
-- 一、ε 见证选择器：Classical.choose
-- ============================================================
-- 唯一解样本：恰一个 n 使 n * n = 4（Nat 上只有 2）
theorem sq4_unique : ∃ n : Nat, n * n = 4 ∧ ∀ m : Nat, m * m = 4 → m = n := by
  refine ⟨2, by rfl, ?_⟩
  intro m hm
  match m with
  | 0 => simp at hm
  | 1 => simp at hm
  | (m + 2) =>
    match m with
    | 0 => rfl
    | 1 => simp at hm
    | (k + 2) =>
      have h4 : (4:Nat) ≤ k + 2 + 2 := by omega
      have h16 : (4:Nat) * 4 ≤ (k + 2 + 2) * (k + 2 + 2) := Nat.mul_le_mul h4 h4
      rw [hm] at h16
      omega

-- ε 选出见证，唯一性把它钉死为 2
noncomputable def theWitness : Nat := Classical.choose sq4_unique

example : theWitness = 2 := by
  have h := (Classical.choose_spec sq4_unique).1  -- theWitness * theWitness = 4
  obtain ⟨w, _, huniq⟩ := sq4_unique
  exact (huniq _ h).trans (huniq 2 (by rfl)).symm

-- ε 不需要唯一：任何存在命题都能选（多见证时任选其一）
theorem some_even_choice :
    ∃ n : Nat, n % 2 = 0 ∧ n > 0 ∧ ∀ m, m % 2 = 0 ∧ m > 0 ∧ m < n → False := by
  exact ⟨2, by rfl, by omega, by intro m hm; omega⟩

/- 与 Coq 侧的差异：Lean 的 choose 天生全定义（古典世界无 ⊥），
   Farmer 的 ε 在零见证时【无定义】——部分性是 AlonzoID 的语义
   条款 V8，全古典逻辑里这一层被抹平。语构见正文 17.2。 -/

-- ============================================================
-- 二、古典账本（对照 Coq 的 Print Assumptions）
-- ============================================================
/-- 选择公理的直接形态：函数一次性选出 -/
theorem ac_finite {α : Type} {R : α → α → Prop}
    (h : ∀ x, ∃ y, R x y) (dom : List α) :
    ∃ f : α → α, ∀ x ∈ dom, R x (f x) := by
  -- 对每个 x 用 ε（choose）取见证，拼成函数
  refine ⟨fun x => Classical.choose (h x), ?_⟩
  intro x _
  exact Classical.choose_spec (h x)

#print axioms ac_finite
-- choice, propext, Classical.em, Quot.sound —— 古典四件套

-- ============================================================
-- 三、引用与求值：深度嵌入的往返（AlonzoQE 的 V8/V9 样本）
-- ============================================================
inductive Exp where
  | num : Nat → Exp
  | plus : Exp → Exp → Exp
  | mul : Exp → Exp → Exp
deriving Repr, BEq

/-- 浅层语义 -/
def sem : Exp → Nat
  | .num n => n
  | .plus a b => sem a + sem b
  | .mul a b => sem a * sem b

/-- ε 型即 Exp 自身；q_* 是「构造子的逻辑常数版」（表 14.5） -/
def qNum (n : Nat) : Exp := .num n
def qPlus (a b : Exp) : Exp := .plus a b
def qMul (a b : Exp) : Exp := .mul a b

/-- Ω：按 14.3.2 的递归逐构造子爬行 -/
def omega : Exp → Exp
  | .num n => qNum n
  | .plus a b => qPlus (omega a) (omega b)
  | .mul a b => qMul (omega a) (omega b)

/-- ⌜·⌝：浅层数据提升为语法 -/
def quoteNat (n : Nat) : Exp := .num n

-- 往返定理 1：Ω 恒等（构造子与逻辑常数一一对应时引用不丢信息）
theorem omega_id (e : Exp) : omega e = e := by
  induction e with
  | num n => rfl
  | plus a b iha ihb => simp [omega, qPlus, iha, ihb]
  | mul a b iha ihb => simp [omega, qMul, iha, ihb]

-- 往返定理 2：求值引用 = 浅层求值
theorem eval_of_quoted (e : Exp) : sem (omega e) = sem e := by
  rw [omega_id]

-- 往返定理 3：自然数的引用求值即自身
theorem eval_quote_nat (n : Nat) : sem (quoteNat n) = n := rfl

-- 样本断言
example : sem (.plus (.num 2) (.mul (.num 3) (.num 4))) = 14 := rfl
example : omega (.plus (.num 2) (.num 3)) = .plus (.num 2) (.num 3) := rfl
example : sem (omega (.mul (.num 5) (.num 6))) = 30 := by
  rw [eval_of_quoted]; rfl
