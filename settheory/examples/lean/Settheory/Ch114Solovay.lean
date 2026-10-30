import Mathlib.Data.List.Basic
import Mathlib.Tactic.IntervalCases

/-!
# 第 114 章 · Solovay 内模型与 HOD(Ω)

锚点（有限影子）：
- `odefP`/`odefP_shift`：参数化谓词（OD 的影子）与群移位交换——
  「定义随参数走」（§3.2.1 的 OD(Ω) 机制核）；
- `rot`/`rot4_id`/`evens_rot`/`orbit4`/`orbit_closed`：偶集不变与
  轨道封闭（不变对象）；
- `parts`/`inOD`/`inHOD`/`hod_od`/`hod_parts`：燃料递归 HOD——
  传递闭包齐可定义的闭包遗传（HOD(Ω) = {α | TC({α}) ⊆ OD(Ω)}）；
- `gpair`/`gpair_inj`/`gpair_decode`：窗口配对单射与解码——引理
  3.22(1) 的哥德尔配对整合机制（两个序列编码进一个）；
- `dchain`/`chainAll`/`dchain_all`：DC 链——引理 3.22(2) 的机制核。

本体（Col(ω,<κ)、V[G]、Solovay 定理 3.25）留在正文 docs/114-solovay.md。
-/

namespace Settheory.Ch114Solovay

/-- Z/8 窗口上的生成元：+2 环移（写成分支形，避免 mod 引理形态漂移）。 -/
def rot (x : Nat) : Nat := if x < 6 then x + 2 else x - 6

/-- 窗口内的周期性：生成元四次回到原点（轨道大小整除 4）。 -/
theorem rot4_id (x : Nat) (hx : x < 8) : rot (rot (rot (rot x))) = x := by
  interval_cases x <;> rfl

/-- 参数化谓词（OD 的影子）：k 的三点「星形」——由参数 k 生成的定义。 -/
def odefP (k x : Nat) : Prop :=
  x % 8 = k % 8 ∨ x % 8 = (k + 3) % 8 ∨ x % 8 = (k + 5) % 8

/-- 件 A：定义与群作用交换——j 步移位同时搬参数与对象，可定义性不变。 -/
theorem odefP_shift (j k x : Nat) :
    odefP ((k + j) % 8) ((x + j) % 8) ↔ odefP k x := by
  constructor
  · rintro (h | h | h)
    · exact Or.inl (by omega)
    · exact Or.inr (Or.inl (by omega))
    · exact Or.inr (Or.inr (by omega))
  · rintro (h | h | h)
    · exact Or.inl (by omega)
    · exact Or.inr (Or.inl (by omega))
    · exact Or.inr (Or.inr (by omega))

/-- 件 B：偶数集在生成元 rot 下不变（不变对象）。 -/
theorem evens_rot (x : Nat) : x % 2 = 0 ↔ rot x % 2 = 0 := by
  unfold rot
  split <;> omega

/-- 轨道：rot 的显式四点表（生成元的幂）。 -/
def orbit4 (x : Nat) : List Nat := [x, rot x, rot (rot x), rot (rot (rot x))]

/-- 件 B2：轨道对生成元封闭——轨道成员再移一位仍在轨道内（窗口内）。 -/
theorem orbit_closed (x : Nat) (hx : x < 8) : ∀ y ∈ orbit4 x, rot y ∈ orbit4 x := by
  intro y hy
  rcases List.mem_cons.1 hy with rfl | hy
  · simp [orbit4]
  rcases List.mem_cons.1 hy with rfl | hy
  · simp [orbit4]
  rcases List.mem_cons.1 hy with rfl | hy
  · simp [orbit4]
  rcases List.mem_cons.1 hy with rfl | hy
  · rw [rot4_id x hx]; simp [orbit4]
  cases hy

/-- 件 C 的组件函数：x 的「元素」（位分解——传递闭包的影子）。 -/
def parts (x : Nat) : List Nat := if x = 0 then [] else [x / 2]

/-- OD 的布尔化身（内联谓词体：def 阻断 Decidable 实例搜索）。 -/
def inOD (p x : Nat) : Bool :=
  decide (x % 8 = p % 8 ∨ x % 8 = (p + 3) % 8 ∨ x % 8 = (p + 5) % 8)

/-- HOD 的燃料递归：x 可定义且全部组件（递归）可定义。 -/
def inHOD : Nat → Nat → Nat → Bool
  | 0, _, _ => true
  | d + 1, p, x => inOD p x && (parts x).all (inHOD d p)

/-- HOD ⊆ OD：整体可定义（TC({x}) ⊆ OD 蕴含 x ∈ OD——因 x ∈ TC({x})）。 -/
theorem hod_od (d p x : Nat) (h : inHOD (d + 1) p x = true) : inOD p x = true := by
  simp only [inHOD, Bool.and_eq_true] at h
  exact h.1

/-- 闭包遗传：HOD 成员的组件仍是 HOD（TC 的齐性）。 -/
theorem hod_parts (d p x : Nat) (h : inHOD (d + 1) p x = true) :
    ∀ y ∈ parts x, inHOD d p y = true := by
  simp only [inHOD, Bool.and_eq_true] at h
  intro y hy
  exact List.all_eq_true.1 h.2 y hy

/-- 件 D：窗口配对（引理 3.22(1) 的哥德尔对应 g:ω×ω→ω 之有限替身）。 -/
def gpair (m k : Nat) : Nat := m + 8 * k

/-- 配对单射：一个序列可以无损编码两个序列。 -/
theorem gpair_inj {m₁ k₁ m₂ k₂ : Nat} (hm₁ : m₁ < 8) (hm₂ : m₂ < 8)
    (h : gpair m₁ k₁ = gpair m₂ k₂) : m₁ = m₂ ∧ k₁ = k₂ := by
  unfold gpair at h
  omega

/-- 解码：gpair 的两个分量复原（u(g(m,k)) 表的读回）。 -/
theorem gpair_decode (m k : Nat) (hm : m < 8) :
    gpair m k % 8 = m ∧ gpair m k / 8 = k := by
  unfold gpair
  omega

/-- 件 E：DC 链——由选择函数 next（有限层的选择=显式函数）递归生成。 -/
def dchain (next : Nat → Nat) (a : Nat) : Nat → List Nat
  | 0 => []
  | d + 1 => a :: dchain next (next a) d

/-- 链的逐对检查谓词。 -/
def chainAll (R : Nat → Nat → Bool) : List Nat → Bool
  | [] => true
  | [_] => true
  | x :: y :: t => R x y && chainAll R (y :: t)

/-- 引理 3.22(2) 机制核：全程后继存在（作为函数）⟹ 链的相邻对全部满足 R。 -/
theorem dchain_all (R : Nat → Nat → Bool) (next : Nat → Nat)
    (h : ∀ x, R x (next x) = true) : ∀ (d a : Nat),
    chainAll R (dchain next a d) = true := by
  intro d
  match d with
  | 0 => intro a; rfl
  | 1 => intro a; rfl
  | d + 2 =>
    intro a
    have ih := dchain_all R next h (d + 1) (next a)
    show (R a (next a) && chainAll R (dchain next (next a) (d + 1))) = true
    rw [h a]
    exact ih

/-- 交接样本：rot 与轨道在具体点上的取值（与 Julia/Python 同账）。 -/
example : rot 0 = 2 := by rfl

example : rot 6 = 0 := by rfl

example : orbit4 0 = [0, 2, 4, 6] := by rfl

example : gpair 3 5 = 43 := by rfl

example : dchain rot 0 5 = [0, 2, 4, 6, 0] := by rfl

end Settheory.Ch114Solovay
