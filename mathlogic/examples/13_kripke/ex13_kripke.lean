/- ex13 —— Kripke 语义：LEM 的两世界反例（Lean 4 版） -/

namespace Ex13

inductive Form where
  | fvar (n : Nat) : Form
  | imp (a b : Form) : Form
  | or_ (a b : Form) : Form
  | neg (a : Form) : Form

open Form

inductive World where
  | w0 : World
  | w1 : World

open World

inductive Le : World → World → Prop
  | r00 : Le w0 w0
  | r01 : Le w0 w1
  | r11 : Le w1 w1

open Le

/-- 原子知识：世界 0 无，世界 1 有 -/
inductive Knows : World → Nat → Prop
  | k1 : ∀ {n}, Knows w1 n

/-- 强制关系 -/
def Forces : World → Form → Prop
  | w, fvar n => Knows w n
  | w, imp a b => ∀ w', Le w w' → Forces w' a → Forces w' b
  | w, or_ a b => Forces w a ∨ Forces w b
  | w, neg a => ∀ w', Le w w' → Forces w' a → False

/-- 单调性 -/
theorem knowsMono {w w' n} (r : Le w w') (k : Knows w n) : Knows w' n := by
  cases r
  · exact k
  · exact absurd k (by intro k'; cases k')
  · exact k

theorem leTrans {a b c} (r1 : Le a b) (r2 : Le b c) : Le a c :=
  match r1, r2 with
  | r00, r' => r'
  | r01, r11 => r01
  | r11, r11 => r11

theorem monotone {w w' f} (r : Le w w') (h : Forces w f) : Forces w' f := by
  induction f generalizing w w' with
  | fvar n => exact knowsMono r h
  | imp a b iha ihb =>
      intro w'' r' ha
      exact h w'' (leTrans r r') ha
  | or_ a b iha ihb =>
      cases h with
      | inl ha => exact Or.inl (iha r ha)
      | inr hb => exact Or.inr (ihb r hb)
  | neg a iha =>
      intro w'' r' ha
      exact h w'' (leTrans r r') ha

/-- 旗舰：LEM 在世界 0 不被强制 -/
theorem lemCounter : ¬ Forces w0 (or_ (fvar 0) (neg (fvar 0))) := by
  intro h
  cases h with
  | inl ha => exact absurd ha (by intro k; cases k)
  | inr hn => exact hn w1 r01 .k1

-- 附注：DNE 在两世界框架不是反例（¬¬p 在 w0 不被强制，
-- 蕴含空真）——见 Mints §7.2 的三世界例（文档）。

-- lemCounter 零公理：'Ex13.lemCounter' does not depend on any axioms

/- 坑位速记（Lean 侧）：
   - `by cases r <;> cases r' <;> exact ‹_›` 处理 Le 的复合
     （三分支穷尽后剩余目标由上下文 auto-solve）；
   - Knows w0 n 无构造子——`intro k; cases k` 一行收。 -/

end Ex13
