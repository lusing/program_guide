import Mathlib.Data.Nat.Sqrt
import Mathlib.SetTheory.Ordinal.Arithmetic
import Mathlib.SetTheory.ZFC.VonNeumann
import Mathlib.Tactic

open Set Function ZFSet

/-!
# 第 84 章 · KP 与可采纳集合：一阶逻辑植入 KP（冯琦第二卷 §1.1）

冯琦 §1.1 的任务是把「一阶逻辑」整套语法语义植入 KP 集合论：公式是集合、
满足关系是 Δ-关系、有限层次 V_ω 是彻底有限集 HF 的世界。本文件机器化其中
三块硬骨头：

1. **Gödel–Cantor 配对** `J(m,n) = (m+n)(m+n+1)/2 + n`：ℕ×ℕ → ℕ 的双射
   （定义 1.22 一切语法编码的地基），给出显式反函数并用 `Nat.sqrt` 证明
   左逆方程；逻辑符 10、变元码 J(5,n+11)、常元码 J(7,n+11) 的互异由此而来。
2. **Δ₀ 公式的内化与绝对性**：有界公式归纳类型 `Fm`（成员、相等、否定、
   合取、有界全称），在集合载体 `M : Set ZFSet` 上用真实的集合隶属 `∈` 求值；
   传递载体上 Δ₀ 语义与全宇宙语义等价——这正是 Δ₀-分离/收集可内在化的根。
3. **有限累积层次 V_n 与 HF = V_ω**：直接调用 mathlib 的 von Neumann 层次
   `ZFSet.vonNeumann o`（`V₀=∅, V_{o+1}=𝒫(V_o)`），机器证明层层传递、
   对配对/并集/分离封闭；每个有限序数 n 属于 V_{n+1}，而 ω 不属于任何 V_n，
   即 V_ω 是 KP⁻ 的天然模型——「无穷公理」为什么是 KP 相对 KP⁻ 唯一新增的那条。
-/

namespace Settheory.Ch84

/-! ## 1. Cantor 配对：定义 1.22 的编码地基 -/

/-- Cantor 配对 `J(m,n) = T(m+n) + n`，`T(s)=s(s+1)/2`。 -/
def cantorJ (m n : ℕ) : ℕ :=
  (m + n) * (m + n + 1) / 2 + n

/- `J` 的逆：由平方数夹逼恢复对角线指标 s=m+n。
`T_s ≤ k < T_{s+1}` 等价于 `(2s+1)² ≤ 8k+1 < (2s+3)²`，
故 `r = ⌊√(8k+1)⌋` 给出 `s = (r-1)/2`（自然数地板除法）。 -/
def cantorUnpair (k : ℕ) : ℕ × ℕ :=
  let r := Nat.sqrt (8 * k + 1)
  let s := (r - 1) / 2
  let n := k - s * (s + 1) / 2
  (s - n, n)

/-- `unpair (J m n) = (m,n)`：配对编码可无损解码（定义 1.22 解码端）。 -/
theorem cantor_unpair_j (m n : ℕ) : cantorUnpair (cantorJ m n) = (m, n) := by
  set s := m + n
  set k := cantorJ m n
  have heven : 2 ∣ s * (s + 1) := by
    by_cases h : s % 2 = 0
    · exact dvd_mul_of_dvd_left (Nat.dvd_of_mod_eq_zero h) _
    · have : (s + 1) % 2 = 0 := by omega
      exact dvd_mul_of_dvd_right (Nat.dvd_of_mod_eq_zero this) _
  have hk : k = s * (s + 1) / 2 + n := by simp [k, cantorJ, s]
  have hT : 2 * (s * (s + 1) / 2) = s * (s + 1) := Nat.mul_div_cancel' heven
  have he2 : 8 * k + 1 = 4 * (s * (s + 1)) + 8 * n + 1 := by
    rw [hk]
    calc 8 * (s * (s + 1) / 2 + n) + 1
        = 4 * (2 * (s * (s + 1) / 2)) + 8 * n + 1 := by ring
      _ = 4 * (s * (s + 1)) + 8 * n + 1 := by rw [hT]
  have h1 : (2 * s + 1) ^ 2 ≤ 8 * k + 1 := by nlinarith
  have hns : n ≤ s := by simp [s]
  have h2 : 8 * k + 1 < (2 * s + 3) ^ 2 := by nlinarith
  -- 平方根 r 满足 (2s+1)² ≤ 8k+1 < (2s+3)²，故 r ∈ {2s+1, 2s+2}，
  -- 两种情况下地板除法 (r-1)/2 都恰为 s。
  have hl : 2 * s + 1 ≤ Nat.sqrt (8 * k + 1) := Nat.le_sqrt'.mpr h1
  have hu : Nat.sqrt (8 * k + 1) < 2 * s + 3 := Nat.sqrt_lt'.mpr h2
  have hs : (Nat.sqrt (8 * k + 1) - 1) / 2 = s := by omega
  have hn : k - s * (s + 1) / 2 = n := by
    rw [hk, Nat.add_sub_cancel_left]
  simp only [cantorUnpair, hs, hn]
  have hsm : s - n = m := by
    have hs' : s = m + n := rfl
    omega
  rw [hsm]

/-- `J` 单射：解码即左逆。 -/
theorem cantorJ_inj : Function.Injective (fun p : ℕ × ℕ => cantorJ p.1 p.2) := by
  rintro ⟨m, n⟩ ⟨m', n'⟩ h
  have := congr_arg cantorUnpair h
  rwa [cantor_unpair_j, cantor_unpair_j] at this

/-- 变元码与常元码（定义 1.22：逻辑符占 10，变元 `v_n` 编作 `J(5,n+11)`，
常元 `c_n` 编作 `J(7,n+11)`）。两个族各自单射且彼此永不相碰——语法对象
有了互不混淆的自然数身份证。 -/
def varCode (n : ℕ) : ℕ := cantorJ 5 (n + 11)
def constCode (n : ℕ) : ℕ := cantorJ 7 (n + 11)

theorem varCode_inj : Function.Injective varCode := by
  intro n n' h
  have h' : cantorJ 5 (n + 11) = cantorJ 5 (n' + 11) := h
  have e : (5, n + 11) = (5, n' + 11) := cantorJ_inj h'
  simpa using e

theorem var_ne_const (n m : ℕ) : varCode n ≠ constCode m := by
  intro h
  have h' : cantorJ 5 (n + 11) = cantorJ 7 (m + 11) := h
  have e : (5, n + 11) = (7, m + 11) := cantorJ_inj h'
  obtain ⟨h5, _⟩ := Prod.ext_iff.mp e
  omega

/-! ## 2. Δ₀ 公式的内化与传递载体上的绝对性 -/

/-- Δ₀（有界）公式：量词只允许 `∀ v_i ∈ v_j` 的形状。这是 Lévy 层级的第零层
（冯琦定义 1.4 的有界表达式概念）。 -/
inductive Fm where
  | mem (i j : ℕ)
  | eq  (i j : ℕ)
  | neg (p : Fm)
  | and (p q : Fm)
  | ball (i j : ℕ) (p : Fm)   -- 对所有 v_i ∈ v_j 有 p

export Fm (mem eq neg and ball)

/-- `M` 传递：y ∈ x ∈ M ⇒ y ∈ M（元素的元素仍在 M 中）。 -/
def TransSet (M : Set ZFSet) : Prop :=
  ∀ ⦃x y : ZFSet⦄, y ∈ x → x ∈ M → y ∈ M

/-- 公式在载体 `M` 中相对环境 `env` 的真值；隶属关系用真实的集合 `∈`，
有界量词的变元额外要求落在 `M` 内（相对化语义）。 -/
def evalFm (M : Set ZFSet) (env : ℕ → ZFSet) : Fm → Prop
  | mem i j  => env i ∈ env j
  | eq i j   => env i = env j
  | neg p    => ¬ evalFm M env p
  | and p q  => evalFm M env p ∧ evalFm M env q
  | ball i j p => ∀ x ∈ M, x ∈ env j → evalFm M (update env i x) p

/-- 全宇宙语义：有界量词不加载体守卫。 -/
def evalV (env : ℕ → ZFSet) : Fm → Prop :=
  evalFm Set.univ env

/-- **Δ₀ 绝对性定理（冯琦引理 1.3 的内核 / 定理 1.19 的零阶形态）**：
M 传递且环境取值都在 M 中时，任何 Δ₀ 公式在 M 中的相对真值与在全宇宙中的
真值相同。关键步只有有界量词一支：`x ∈ env j` 而 `env j ∈ M`，传递性把
守卫 `x ∈ M` 自动补齐。 -/
theorem delta0_absolute (M : Set ZFSet) (hM : TransSet M)
    (env : ℕ → ZFSet) (henv : ∀ i, env i ∈ M) :
    ∀ (p : Fm), evalFm M env p ↔ evalV env p
  | mem i j => Iff.rfl
  | eq i j  => Iff.rfl
  | neg p   => (delta0_absolute M hM env henv p).not
  | and p q => (delta0_absolute M hM env henv p).and
      (delta0_absolute M hM env henv q)
  | ball i j p => by
    have hup : ∀ (x : ZFSet), x ∈ M → (∀ l, update env i x l ∈ M) := by
      intro x hx l
      by_cases h : l = i
      · rw [h]; simpa using hx
      · rw [Function.update_apply, if_neg h]; exact henv l
    constructor
    · intro h x _ hx
      have xM : x ∈ M := hM hx (henv j)
      exact (delta0_absolute M hM (update env i x) (hup x xM) p).mp
        (h x xM hx)
    · intro h x xM hx
      exact (delta0_absolute M hM (update env i x) (hup x xM) p).mpr
        (h x (by trivial) hx)

/-! ## 3. 有限累积层次 V_n 与彻底有限集 HF -/

/-- `V n = V_n`：mathlib 的 von Neumann 层次在有限序数处的取值
（冯琦定义 1.21：V₀=∅，V_{n+1}=𝒫(V_n)）。 -/
noncomputable def vLevel (n : ℕ) : ZFSet := ZFSet.vonNeumann (n : Ordinal)

/-- 每一层都传递（mathlib `isTransitive_vonNeumann`，此处换写成载体谓词）。 -/
theorem vLevel_trans (n : ℕ) : TransSet (vLevel n : Set ZFSet) := by
  have h := ZFSet.isTransitive_vonNeumann (n : Ordinal)
  intro x y hyx hx
  exact h.mem_trans hyx hx

/-- `V_{n+1} = 𝒫(V_n)`。 -/
theorem vLevel_succ (n : ℕ) : vLevel (n + 1) = ZFSet.powerset (vLevel n) :=
  ZFSet.vonNeumann_add_one (n : Ordinal)

/-- 层次单调上升：m ≤ n ⇒ V_m ⊆ V_n。 -/
theorem vLevel_mono {m n : ℕ} (h : m ≤ n) : vLevel m ⊆ vLevel n :=
  ZFSet.vonNeumann_subset_of_le (by exact_mod_cast h)

/-- **配对公理在层次上的验证**：x,y ∈ V_n 则 {x,y} ∈ V_{n+1}。 -/
theorem vLevel_pair (n : ℕ) {x y : ZFSet}
    (hx : x ∈ vLevel n) (hy : y ∈ vLevel n) :
    ({x, y} : ZFSet) ∈ vLevel (n + 1) := by
  rw [vLevel_succ, ZFSet.mem_powerset]
  intro z hz
  rw [mem_pair] at hz
  rcases hz with rfl | rfl <;> tauto

/-- **并集公理在层次上的验证**：x ∈ V_{n+1} ⇒ ⋃₀ x ∈ V_{n+1}。
x ⊆ V_n 且 V_n 传递，故 ⋃₀ x ⊆ V_n。 -/
theorem vLevel_union (n : ℕ) {x : ZFSet} (hx : x ∈ vLevel (n + 1)) :
    ZFSet.sUnion x ∈ vLevel (n + 1) := by
  rw [vLevel_succ, ZFSet.mem_powerset] at *
  intro z hz
  rcases mem_sUnion.mp hz with ⟨w, hw, hzw⟩
  have hwn : w ∈ vLevel n := ZFSet.subset_def.mp hx hw
  exact vLevel_trans n hzw hwn

/-- **Δ₀-分离的层次形态**：x ∈ V_{n+1} 时对它做分离的产物仍在 V_{n+1} 中
（`ZFSet.sep` 即「由条件 p 从 x 切出子集」；`sep_subset` 保证其 ⊆ x）。
Δ₀ 限定的意义不在「切」这一步——层次对任意子集封闭——而在条件 p 的
绝对性（上一节）：在层次内切与在 V 内切是同一切。 -/
theorem vLevel_separation (n : ℕ) (p : ZFSet → Prop) {x : ZFSet}
    (hx : x ∈ vLevel (n + 1)) : ZFSet.sep p x ∈ vLevel (n + 1) := by
  rw [vLevel_succ, ZFSet.mem_powerset] at *
  intro z hz
  exact ZFSet.subset_def.mp hx (ZFSet.sep_subset hz)

/-! ### HF = V_ω -/

/-- `V_ω = ⋃_n V_n`：彻底有限集（hereditarily finite sets）全体。 -/
def hfSet : Set ZFSet := Set.iUnion fun n => (vLevel n : Set ZFSet)

/-- V_ω 传递。 -/
theorem hf_trans : TransSet hfSet := by
  intro x y hyx hx
  rcases mem_iUnion.mp hx with ⟨n, hn⟩
  exact mem_iUnion.mpr ⟨n, vLevel_trans n hyx hn⟩

/-- V_ω 对配对封闭。 -/
theorem hf_pair {x y : ZFSet} (hx : x ∈ hfSet) (hy : y ∈ hfSet) :
    ({x, y} : ZFSet) ∈ hfSet := by
  rcases mem_iUnion.mp hx with ⟨m, hm⟩
  rcases mem_iUnion.mp hy with ⟨k, hk⟩
  refine mem_iUnion.mpr ⟨max m k + 1,
    vLevel_pair (max m k) (vLevel_mono (le_max_left m k) hm)
      (vLevel_mono (le_max_right m k) hk)⟩

/-- V_ω 对并集封闭。 -/
theorem hf_union {x : ZFSet} (hx : x ∈ hfSet) : ZFSet.sUnion x ∈ hfSet := by
  rcases mem_iUnion.mp hx with ⟨n, hn⟩
  cases n with
  | zero =>
    have h0 : vLevel 0 = (∅ : ZFSet) := by
      simp [vLevel, ZFSet.vonNeumann_zero]
    rw [h0] at hn
    exact (ZFSet.notMem_empty x hn).elim
  | succ n => exact mem_iUnion.mpr ⟨n + 1, vLevel_union n hn⟩

/-- von Neumann 有限序数 n（Lean 序数经 `toZFSet` 落地为集合）。 -/
noncomputable def vNat (n : ℕ) : ZFSet := (n : Ordinal).toZFSet

/-- `n ∈ V_{n+1}`：每个有限序数都是彻底有限集（秩 n < n+1）。 -/
theorem vNat_mem_level (n : ℕ) : vNat n ∈ vLevel (n + 1) := by
  show (n : Ordinal).toZFSet ∈ ZFSet.vonNeumann ((n + 1 : ℕ) : Ordinal)
  rw [mem_vonNeumann, Ordinal.rank_toZFSet]
  simp

/-- 第一个无穷序数 ω 作为集合。 -/
noncomputable def vOmega : ZFSet := Ordinal.omega0.toZFSet

/-- **ω 不是任何 V_n 的元素**：若 ω ∈ V_n，则秩 ω < n；但每个有限 n 都有
n < ω（`natCast_lt_omega0`），矛盾于序数 `<' 的反对称。V_ω 里没有无穷集合，
它满足 KP⁻ 的全部公理——这就是 KP = KP⁻ + 无穷公理（定义 1.6、1.7）
在有限世界里的分界。 -/
theorem omega_not_hf : vOmega ∉ hfSet := by
  intro h
  rcases mem_iUnion.mp h with ⟨n, hn⟩
  have hn' : vOmega ∈ ZFSet.vonNeumann (n : Ordinal) := hn
  have h1 : Ordinal.omega0 < (n : Ordinal) := by
    rw [mem_vonNeumann] at hn'
    simp only [vOmega, Ordinal.rank_toZFSet] at hn'
    exact hn'
  have h2 : (n : Ordinal) < Ordinal.omega0 := Ordinal.natCast_lt_omega0 n
  exact lt_asymm h1 h2

end Settheory.Ch84
