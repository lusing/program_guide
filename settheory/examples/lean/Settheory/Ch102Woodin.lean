import Mathlib.Data.Finset.Basic
import Mathlib.Data.Finset.Card

/-!
# 第 102 章 · 武丁基数

锚点（有限影子）：
- 闭包点 `closed f κ`（∀ i<κ, f i<κ）——定义 1.25/定理 1.36(c)(d)
  中「κ 对 f 封闭」条款的可判定影子；
- 见证依赖函数：后继型 f 在有限层无非零闭包点——
  「每个函数都有足够强见证」是全称量词，见证必须随 f 变化；
- `FWit` 见证与 f-谢拉赫型条款（闭包 + 层捕获）。
武丁本体（定义 1.24/1.25、定理 1.36-1.38）留在正文。
-/

namespace Settheory.Ch102

/-- f-闭包：∀ i<κ, f i<κ（定义 1.25(i) 的有限影子）。 -/
def closed (f : ℕ → ℕ) (κ : ℕ) : Prop :=
  ∀ i < κ, f i < κ

/-- 后继型函数：i≤3 时 i+1，否则 5。在 [1,5] 内无闭包点——
「共尾爬升」的函数把见证逼到边界之外。 -/
def fsucc : ℕ → ℕ := fun i => if i ≤ 3 then i + 1 else 5

theorem fsucc_gt (i : ℕ) (h : i < 5) : i < fsucc i := by
  by_cases h4 : i ≤ 3
  · simp [fsucc, h4]
  · simp only [fsucc, if_neg h4]
    omega

/-- 后继函数在 1..5 处闭包全部失败：fsucc(κ-1) 恰落在
κ-1 与 κ 之间——整数无此空隙。 -/
theorem fsucc_no_closed : ∀ κ, 1 ≤ κ → κ ≤ 5 → ¬ closed fsucc κ := by
  intro κ h1 h5 hcl
  have hi : κ - 1 < κ := Nat.sub_lt (by omega) (by omega)
  have hlt : fsucc (κ - 1) < κ := hcl (κ - 1) hi
  have hgt : κ - 1 < fsucc (κ - 1) := fsucc_gt (κ - 1) (by omega)
  omega

/-- 常值函数 c1 的闭包点：一切 κ≥2。 -/
def c1 : ℕ → ℕ := fun _ => 1

theorem c1_closed (κ : ℕ) (h : 2 ≤ κ) : closed c1 κ := by
  intro i hi
  simp only [c1]
  omega

/-- 见证记录：临界点、j(f)(κ) 层号、捕获的层集。 -/
structure FWit where
  κ : ℕ
  jfκ : ℕ
  cap : Finset ℕ

/-- f-谢拉赫型条款：闭包 + j(f)(κ)>κ + 第 j(f)(κ) 层被捕获
（V_{j(f)(κ)}⊆M 的影子）。 -/
def fShelah (f : ℕ → ℕ) (w : FWit) : Prop :=
  closed f w.κ ∧ w.κ < w.jfκ ∧ w.jfκ ∈ w.cap

/-- 伪见证样本：c1 在 (κ=2, j(f)(κ)=3, cap={3}) 处成立。 -/
example : fShelah c1 { κ := 2, jfκ := 3, cap := {3} } := by
  show closed c1 2 ∧ 2 < 3 ∧ 3 ∈ ({3} : Finset ℕ)
  exact ⟨c1_closed 2 (by omega), by omega, by simp⟩

/-- 同一条款对后继函数失败——闭包一款就断了。 -/
example : ¬ fShelah fsucc { κ := 2, jfκ := 3, cap := {3} } := by
  intro h
  exact fsucc_no_closed 2 (by omega) (by omega) h.1

/-- 抬高单点：f(1)=3、其余为 1。 -/
def c13 : ℕ → ℕ := fun i => if i = 1 then 3 else 1

/-- c13 在 κ=2 处闭包失败（f(1)=3 ≮ 2）。 -/
example : ¬ closed c13 2 := by
  intro hcl
  have h2 := hcl 1 (by omega)
  simp [c13] at h2

/-- c13 在 κ=4 处闭包成立。 -/
theorem c13_closed_4 : closed c13 4 := by
  intro i _hi
  by_cases h : i = 1
  · simp [c13, h]
  · simp [c13, h]

/-- 见证必须随函数变化：c1 的闭包见证含一切 κ≥2，
而 c13 的闭包见证从 κ=4 才开始——「单一 κ 对一切函数
都够格」在有限层已被 c1/c13 分离证伪。 -/
theorem witnesses_depend :
    (∀ κ, 2 ≤ κ → κ ≤ 4 → closed c1 κ) ∧
    (∀ κ, 1 ≤ κ → κ ≤ 3 → ¬ closed c13 κ) := by
  constructor
  · intro κ h2 _; exact c1_closed κ h2
  · intro κ h1 h3 hcl
    by_cases hκ : κ = 1
    · subst hκ
      have h0 := hcl 0 (by omega)
      simp [c13] at h0
    · have h1' := hcl 1 (by omega)
      simp [c13] at h1'
      omega

end Settheory.Ch102
