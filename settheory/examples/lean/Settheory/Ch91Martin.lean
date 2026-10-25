/-!
# 第 91 章 · 马丁公理之合理性与迭代力迫（冯琦第二卷 §3.4）

四件有限可证的引擎：

1. 一步迭代的相容分解（定理 3.14 的组合核心）：迭代条件 (p,q) 相容
   当且仅当两个分量分别相容——合并构造给出正向，投影给出反向。
2. 典型嵌入 i(p) = (p, 1_Q) 的完备性半边（引理 3.54(6)）：
   相冲完全由第一分量决定（第二分量是最大元，与一切相容）。
3. 有限支撑（定义 3.36）：迭代条件只在有限个坐标上偏离最大元；
   坐标式条件的相容合并检查器。
4. Solovay-Tennenbaum 记录函数（定理 3.18）的 Cantor 配对实现：
   π(β,γ) = ⟨β,γ⟩ 自然满足「第一分量不超过编号」。
-/

namespace Settheory.Ch91

open List

/-! ## 一、一步迭代的相容分解（定理 3.14 的组合核心） -/

/-- q 延拓 p（更强）。 -/
def Ext (p q : List Bool) : Prop := ∃ r, q = p ++ r

theorem Ext_refl (p : List Bool) : Ext p p := ⟨[], (append_nil p).symm⟩

/-- 串条件相容：存在公共延长（力迫相容的一般形态）。 -/
def agree (p q : List Bool) : Prop := ∃ r, Ext p r ∧ Ext q r

/-- 相容条件的公共延长（同意形态的记账）。 -/
theorem common_ext (p q : List Bool) (h : agree p q) :
    ∃ r, Ext p r ∧ Ext q r := h

/-- 迭代条件：第一步与第二步各一个串条件。 -/
abbrev IterCnd := List Bool × List Bool

/-- 迭代条件的延拓：两个分量分别延拓。 -/
def ExtPair (x y : IterCnd) : Prop := Ext x.1 y.1 ∧ Ext x.2 y.2

/-- 迭代相容的合并刻画：(p,q) 与 (p',q') 相容 ⟺ 分量分别相容。 -/
theorem iterAgree_iff (x y : IterCnd) :
    (∃ r : IterCnd, ExtPair x r ∧ ExtPair y r) ↔
      (agree x.1 y.1 ∧ agree x.2 y.2) := by
  constructor
  · rintro ⟨r, ⟨h1, h2⟩, ⟨h3, h4⟩⟩
    exact ⟨⟨r.1, h1, h3⟩, ⟨r.2, h2, h4⟩⟩
  · rintro ⟨⟨r1, e1, e2⟩, ⟨r2, e3, e4⟩⟩
    exact ⟨(r1, r2), ⟨e1, e3⟩, ⟨e2, e4⟩⟩

/-! ## 二、典型嵌入的完备性半边（引理 3.54(6)） -/

/-- 典型嵌入 i(p) = (p, 1_Q)；空串是第二步的最大元。 -/
def canon (p : List Bool) : IterCnd := (p, [])

/-- 相冲的双向换算：典型嵌入下的冲突完全由第一分量决定。 -/
theorem canon_incompat_iff (p p' : List Bool) :
    (¬ ∃ r, ExtPair (canon p) r ∧ ExtPair (canon p') r) ↔ ¬ agree p p' := by
  rw [iterAgree_iff]
  -- 第二分量 [] 与 [] 恒相容（最大元与一切相容）
  have hnil : agree ([] : List Bool) [] := ⟨[], Ext_refl [], Ext_refl []⟩
  constructor
  · intro h ha; exact h ⟨ha, hnil⟩
  · intro h ⟨ha, _⟩; exact h ha

/-! ## 三、有限支撑迭代（定义 3.36） -/

/-- 多步迭代的坐标条件：none 表示取该步最大元（支撑之外）。 -/
abbrev CondN := List (Option Bool)

/-- 支撑：偏离最大元的坐标个数（天然有限：不超过条件长度）。 -/
def spt (p : CondN) : Nat := p.countP Option.isSome

theorem spt_le (p : CondN) : spt p ≤ p.length :=
  p.countP_le_length

/-- 坐标延拓检查：p 决定的每一位都被 q 保持同值。 -/
def extCoordB (p q : CondN) : Bool :=
  (List.range (max p.length q.length)).all (fun i =>
    (p.getD i none).all (fun a => q.getD i none == some a))

/-- 相容两条件的合并：每个坐标取首先给出决定者。 -/
def mergeC (p q : CondN) : CondN :=
  zipWith (fun a b => match a, b with
    | some x, _ => some x
    | none, b' => b') p q

-- 支撑演示：[none, some true, none] 的支撑恰为 1
#eval spt [none, some true, none]

-- 相容对的合并通过双向坐标延拓检查；相冲对无法通过
#eval extCoordB [none, some true] (mergeC [none, some true] [some false, none])
#eval extCoordB [some false, none] (mergeC [none, some true] [some false, none])
#eval extCoordB [some true] (mergeC [some true] [some false])

/-! ## 四、Solovay-Tennenbaum 记录函数（Cantor 配对） -/

/-- Cantor 配对 π(β,γ) = (β+γ)(β+γ+1)/2 + γ。 -/
def cantor (b g : Nat) : Nat := (b + g) * (b + g + 1) / 2 + g

/-- 记录函数关键公理：π 的第一分量不超过编号——编号越大，
    被记录的偏序集名字在迭代中出现得越晚（定理 3.18 的 (b) 款）。 -/
theorem cantor_selfLE (b g : Nat) : b ≤ cantor b g := by
  unfold cantor
  have hge : b ≤ b + g := Nat.le_add_right b g
  have key : 2 * b ≤ (b + g) * (b + g + 1) := by
    cases hs : b + g with
    | zero =>
      have hb0 : b = 0 := by omega
      subst hb0
      simp
    | succ s =>
      rw [hs] at hge
      have h1 : (s + 1) * 2 ≤ (s + 1) * (s + 1 + 1) :=
        Nat.mul_le_mul_left _ (by omega)
      have h3 : b * 2 ≤ (s + 1) * 2 := Nat.mul_le_mul_right 2 hge
      omega
  have hEq : 2 * b / 2 = b := Nat.mul_div_cancel_left b (Nat.succ_pos 1)
  calc b = 2 * b / 2 := hEq.symm
    _ ≤ (b + g) * (b + g + 1) / 2 := Nat.div_le_div_right key
    _ ≤ (b + g) * (b + g + 1) / 2 + g := Nat.le_add_right _ _

-- 配对表：行 β、列 γ 的三角数编号
#eval (List.range 4).map (fun b => (List.range 4).map (fun g => cantor b g))

end Settheory.Ch91
