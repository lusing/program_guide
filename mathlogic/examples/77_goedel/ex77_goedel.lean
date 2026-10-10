/- ex77_goedel.lean —— 算术化与哥德尔编码（Mendelson §3.4）Lean 镜像
   平方配对 cp 单射 / 极小一阶语法树编码 gcf 单射 / subf 代入 /
   β-函数有界搜索与 CRT 见证 / dsub 自引骨架。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

-- ============ 一、平方配对与单射性 ============

theorem sq_step (s : Nat) : s * s + s < (s + 1) * (s + 1) := by
  show s * s + s < Nat.succ s * Nat.succ s
  rw [Nat.succ_mul, Nat.mul_succ]
  omega

theorem sq_mono (s1 s2 : Nat) (h : s1 <= s2) : s1 * s1 <= s2 * s2 :=
  Nat.mul_le_mul h h

def cp (a b : Nat) : Nat := (a + b) * (a + b) + b

theorem cp_inj : ∀ (a1 b1 a2 b2 : Nat),
    cp a1 b1 = cp a2 b2 → a1 = a2 ∧ b1 = b2 := by
  intro a1 b1 a2 b2 H
  unfold cp at H
  -- 平方项作为不透明原子交给纯线性推理（omega 不展开非线性积）
  have key : ∀ (p q r X Y Z : Nat), X + p < Y → Y <= Z → X + q = Z + r → q <= p → False := by
    intro p q r X Y Z h1 h2 h3 hq
    omega
  rcases Nat.lt_trichotomy (a1 + b1) (a2 + b2) with h | h | h
  · exact (key (a1 + b1) b1 b2 _ _ _ (sq_step (a1 + b1))
      (sq_mono (a1 + b1 + 1) (a2 + b2) (by omega)) H (by omega)).elim
  · rw [h] at H
    exact ⟨by omega, by omega⟩
  · exact (key (a2 + b2) b2 b1 _ _ _ (sq_step (a2 + b2))
      (sq_mono (a2 + b2 + 1) (a1 + b1) (by omega)) H.symm (by omega)).elim

def pr3 (a b c : Nat) : Nat := cp a (cp b c)

theorem pr3_inj (a1 b1 c1 a2 b2 c2 : Nat)
    (h : pr3 a1 b1 c1 = pr3 a2 b2 c2) : a1 = a2 ∧ b1 = b2 ∧ c1 = c2 := by
  obtain ⟨ha, hbc⟩ := cp_inj _ _ _ _ h
  obtain ⟨hb, hc⟩ := cp_inj _ _ _ _ hbc
  exact ⟨ha, hb, hc⟩

-- ============ 二、极小一阶语法与树编码 ============

inductive Tm : Type where
  | var (n : Nat)
  | num (n : Nat)

inductive Fm : Type where
  | eqt (t1 t2 : Tm)
  | neg (a : Fm)
  | imp (a b : Fm)
  | exq (x : Nat) (a : Fm)

def gct : Tm → Nat
  | .var n => pr3 0 n 0
  | .num n => pr3 0 n 1

def gcf : Fm → Nat
  | .eqt t1 t2 => pr3 1 (gct t1) (gct t2)
  | .neg a => pr3 2 (gcf a) 0
  | .imp a b => pr3 3 (gcf a) (gcf b)
  | .exq x a => pr3 4 x (gcf a)

theorem gct_inj : ∀ (t1 t2 : Tm), gct t1 = gct t2 → t1 = t2 := by
  intro t1 t2 h
  cases t1 <;> cases t2 <;> simp only [gct] at h <;>
    obtain ⟨h0, h1, h2⟩ := pr3_inj _ _ _ _ _ _ h <;>
    simp_all

theorem gcf_inj : ∀ (φ1 φ2 : Fm), gcf φ1 = gcf φ2 → φ1 = φ2 := by
  intro φ1
  induction φ1 with
  | eqt t1 t2 =>
    intro φ2 h; cases φ2 <;> simp only [gcf] at h
    · obtain ⟨h0, h1, h2⟩ := pr3_inj _ _ _ _ _ _ h
      rw [gct_inj _ _ h1, gct_inj _ _ h2]
    · obtain ⟨h0, _, _⟩ := pr3_inj _ _ _ _ _ _ h; omega
    · obtain ⟨h0, _, _⟩ := pr3_inj _ _ _ _ _ _ h; omega
    · obtain ⟨h0, _, _⟩ := pr3_inj _ _ _ _ _ _ h; omega
  | neg a iha =>
    intro φ2 h; cases φ2 <;> simp only [gcf] at h
    · obtain ⟨h0, _, _⟩ := pr3_inj _ _ _ _ _ _ h; omega
    · obtain ⟨h0, h1, h2⟩ := pr3_inj _ _ _ _ _ _ h
      rw [iha _ h1]
    · obtain ⟨h0, _, _⟩ := pr3_inj _ _ _ _ _ _ h; omega
    · obtain ⟨h0, _, _⟩ := pr3_inj _ _ _ _ _ _ h; omega
  | imp a b iha ihb =>
    intro φ2 h; cases φ2 <;> simp only [gcf] at h
    · obtain ⟨h0, _, _⟩ := pr3_inj _ _ _ _ _ _ h; omega
    · obtain ⟨h0, _, _⟩ := pr3_inj _ _ _ _ _ _ h; omega
    · obtain ⟨h0, h1, h2⟩ := pr3_inj _ _ _ _ _ _ h
      rw [iha _ h1, ihb _ h2]
    · obtain ⟨h0, _, _⟩ := pr3_inj _ _ _ _ _ _ h; omega
  | exq x a iha =>
    intro φ2 h; cases φ2 <;> simp only [gcf] at h
    · obtain ⟨h0, _, _⟩ := pr3_inj _ _ _ _ _ _ h; omega
    · obtain ⟨h0, _, _⟩ := pr3_inj _ _ _ _ _ _ h; omega
    · obtain ⟨h0, _, _⟩ := pr3_inj _ _ _ _ _ _ h; omega
    · obtain ⟨h0, h1, h2⟩ := pr3_inj _ _ _ _ _ _ h
      rw [h1, iha _ h2]

example : (gcf (.eqt (.var 0) (.num 0)), gcf (.neg (.eqt (.var 0) (.var 0))),
           gcf (.exq 0 (.eqt (.var 0) (.var 0))))
    = (1891, 10, 38) := by native_decide

-- ============ 三、代入：语法层现场 ============

def subt : Tm → Nat → Tm → Tm
  | .var n, x, u => if n == x then u else .var n
  | .num n, _, _ => .num n

-- 天真代入：绑定位撞名整体保留（侧条件文档线；本章 u 恒取闭项 num n）
def subf : Fm → Nat → Tm → Fm
  | .eqt t1 t2, x, u => .eqt (subt t1 x u) (subt t2 x u)
  | .neg a, x, u => .neg (subf a x u)
  | .imp a b, x, u => .imp (subf a x u) (subf b x u)
  | .exq y a, x, u => if y == x then .exq y a else .exq y (subf a x u)

example : (subf (.eqt (.var 0) (.var 1)) 0 (.num 5),
           subf (.exq 0 (.eqt (.var 0) (.var 0))) 0 (.num 5),
           subf (.exq 1 (.eqt (.var 0) (.var 1))) 0 (.num 5))
    = (.eqt (.num 5) (.var 1),
       .exq 0 (.eqt (.var 0) (.var 0)),
       .exq 1 (.eqt (.num 5) (.var 1))) := by rfl

-- ============ 四、β-函数：中国剩余的序列编码 ============

def beta (b c i : Nat) : Nat := b % (1 + (i + 1) * c)

def bcheck (b c : Nat) : List Nat → Nat → Bool
  | [], _ => true
  | v :: rest, i => (beta b c i == v) && bcheck b c rest (i + 1)

def findb (xs : List Nat) (c b fuel : Nat) : Option Nat :=
  match fuel with
  | 0 => none
  | f + 1 => if bcheck b c xs 0 then some b else findb xs c (b + 1) f

-- c=6：模族 7,13,19 两两互素——CRT 保证解存在，搜索必命中
example : (match findb [2, 5, 1] 6 0 2000 with
           | some b => bcheck b 6 [2, 5, 1] 0
           | none => false) = true := by native_decide

-- 搜索见证：b=590——590 mod 7=2, 590 mod 13=5, 590 mod 19=1 逐位还原
example : findb [2, 5, 1] 6 0 2000 = some 590 := by native_decide
example : bcheck 590 6 [2, 5, 1] 0 = true := by native_decide

-- c=2：模族 3,9 非互素且余数冲突——搜索扑空（CRT 条件的现场）
example : findb [2, 7] 2 0 500 = none := by native_decide

-- ============ 五、自引骨架 ============

def Tdiag : Fm := .eqt (.var 0) (.var 1)
def dsub (n : Nat) : Fm := subf Tdiag 0 (.num n)

-- 嵌套配对码值快速增长：两步从 4555 到百万级（native 侧可全程算）
example : (List.range 3).map (fun n => gcf (dsub n)) = [4555, 1055755, 157439755] := by native_decide

def findfix : Nat → Option Nat
  | 0 => none
  | f + 1 => if gcf (dsub (f + 1)) == f + 1 then some (f + 1) else findfix f

-- 有界搜索「gcf (dsub n) = n」无解——真不动点引理（书 3.5）需要 β 的
-- 行内序列构造，文档线
example : findfix 200 = none := by native_decide

-- ============ 账本 ============

#print axioms cp_inj
#print axioms gcf_inj
