import Mathlib.Data.List.Basic
import Mathlib.Tactic.IntervalCases

/-!
# 第 115 章 · Lévy 扩张正则性与 L(ℝ) 理论不变性

锚点（有限影子）：
- `bval`/`bval_perm`：命题公式的布尔值与对换 τ 的**对称保真**——
  公式与布尔值同步变换（同质嵌入的语义面）；
- `F_conj`/`tau_inv_eval`：主超滤的共轭与**双点不变证书**——
  τ-不变公式的真值在两个泛型求值点相等（定理 3.26/3.27 的
  「L(ℝ)-理论不变」机制核）；
- `noninv_counter`：非不变布尔值在双点上翻车——不变性必须
  限定公式（边界声明）；
- `inX`/`inA1`/`modI_eq`/`modI_ideal`：博雷尔包裹的 mod-I 同余
  （引理 3.23(3) 的 A₁ 见证机制——差集吞进理想）。

本体（κ-饱和、随机实数、黑白分明律、完备子集的 f-单射、
Solovay 定理 3.25、Woodin 同质嵌入）留在正文 docs/115-invariance.md。
-/

namespace Settheory.Ch115Invariance

/-- 三点底集 {0,1,2} 上的对换 τ = swap(0,1)（生成 {id,τ} ≅ C2）。 -/
def tau (i : Nat) : Nat := if i = 0 then 1 else if i = 1 then 0 else 2

theorem tau_tau (i : Nat) (hi : i < 3) : tau (tau i) = i := by
  interval_cases i <;> rfl

theorem tau_0 : tau 0 = 1 := by rfl

theorem tau_1 : tau 1 = 0 := by rfl

/-- 子集 = 点到 Bool 的函数（P(3) 的元素）。 -/
abbrev Subset := Nat → Bool

/-- τ 在子集上的作用（(τ·b)(τ i) = b(i) 的实现形）。 -/
def tb (b : Subset) : Subset := fun i => b (tau i)

def compl (b : Subset) : Subset := fun i => !b i

def inter (a b : Subset) : Subset := fun i => a i && b i

def unio (a b : Subset) : Subset := fun i => a i || b i

/-- 主超滤（P(3) 上点 i 的超滤）：b ∈ F_i ⟺ i ∈ b。 -/
def memF (i : Nat) (b : Subset) : Prop := b i = true

/-- 命题公式（有限理论片段的替身）。 -/
inductive Formula : Type
  | var : Nat → Formula
  | neg : Formula → Formula
  | conj : Formula → Formula → Formula
  | disj : Formula → Formula → Formula

open Formula

/-- 公式的布尔值（布尔值模型的有限版）。 -/
def bval : Formula → (Nat → Subset) → Subset
  | var n, v => v n
  | neg φ, v => compl (bval φ v)
  | conj φ ψ, v => inter (bval φ v) (bval ψ v)
  | disj φ ψ, v => unio (bval φ v) (bval ψ v)

/-- τ 在赋值上的提升。 -/
def tv (v : Nat → Subset) : Nat → Subset := fun n => tb (v n)

/-- 件 E（对称保真）：布尔值与公式同步变换——⟦φ⟧_{v^τ} = τ·⟦φ⟧_v。 -/
theorem bval_perm (φ : Formula) (v : Nat → Subset) :
    bval φ (tv v) = tb (bval φ v) := by
  induction φ with
  | var n => rfl
  | neg φ ih => simp only [bval]; rw [ih]; funext i; simp [compl, tb]
  | conj φ ψ ih1 ih2 =>
    simp only [bval]; rw [ih1, ih2]; funext i; simp [inter, tb]
  | disj φ ψ ih1 ih2 =>
    simp only [bval]; rw [ih1, ih2]; funext i; simp [unio, tb]

/-- 滤子共轭：τ 把 F_i 的成员资格搬到 F_{τ i}——(τ·b)(τ i) = b(i)。 -/
theorem F_conj (i : Nat) (hi : i < 3) (b : Subset) :
    (tb b) (tau i) = b i := by
  simp [tb, tau_tau i hi]

/-- 件 A 旗舰（双点不变证书）：τ-不变公式的布尔值在共轭双点上
真值相等——L(ℝ)-理论不变性的有限化身。 -/
theorem tau_inv_eval (φ : Formula) (v : Nat → Subset)
    (hinv : tb (bval φ v) = bval φ v) :
    memF 0 (bval φ v) ↔ memF 1 (bval φ v) := by
  have e1 : tb (bval φ v) 1 = bval φ v 0 := by
    simpa [tau] using F_conj 0 (by omega) (bval φ v)
  have e2 : tb (bval φ v) 0 = bval φ v 1 := by
    simpa [tau] using F_conj 1 (by omega) (bval φ v)
  unfold memF
  constructor
  · intro h; rw [← hinv, e1]; exact h
  · intro h; rw [← hinv, e2]; exact h

/-- 非不变布尔值在双点上翻车——不变性必须限定公式（边界反例）。 -/
theorem noninv_counter :
    (fun i : Nat => if i = 0 then true else false) 0 = true ∧
    (fun i : Nat => if i = 0 then true else false) 1 = false := by
  constructor <;> simp

/-- ── 件 B：博雷尔包裹的 mod-I 同余（引理 3.23(3) 的 A₁ 机制） ──

星形谓词（114 章的连续性）：s-可定义的实数集影子。 -/
def odefP (k x : Nat) : Prop :=
  x % 8 = k % 8 ∨ x % 8 = (k + 3) % 8 ∨ x % 8 = (k + 5) % 8

/-- 旧模型实数集的影子：R(V[s]) ↦ 偶集。 -/
def inS (x : Nat) : Prop := x % 2 = 0

/-- X：由参数 s（取 0）可定义的集合。 -/
def inX (x : Nat) : Prop := odefP 0 x

/-- A₁ := X ∩ S（博雷尔包裹——mod 理想的代表）。 -/
def inA1 (x : Nat) : Prop := inX x ∧ inS x

/-- 在 S 上 X 与 A₁ 同真假（X ∩ S = A₁ ∩ S 的谓词形）。 -/
theorem modI_eq (x : Nat) (hx : inS x) : inX x ↔ inA1 x := by
  constructor
  · intro h; exact ⟨h, hx⟩
  · intro h; exact h.1

/-- 差集全落理想：X△A₁ 的成员必在 S 之外（理想 = 奇集的幂集）。 -/
theorem modI_ideal (x : Nat)
    (h : (inX x ∧ ¬ inA1 x) ∨ (¬ inX x ∧ inA1 x)) : ¬ inS x := by
  rcases h with ⟨hx, hna⟩ | ⟨hx, hna⟩
  · intro hs; exact hna ⟨hx, hs⟩
  · obtain ⟨hx', hs⟩ := hna
    intro hs'; exact hx hx'

/-- 样本：星形 {0,3,5}（mod 8）在窗口 0..7 的命中。 -/
example : inX 0 := by unfold inX odefP; omega

example : inX 3 := by unfold inX odefP; omega

example : inX 5 := by unfold inX odefP; omega

example : ¬ inX 1 := by unfold inX odefP; omega

end Settheory.Ch115Invariance
