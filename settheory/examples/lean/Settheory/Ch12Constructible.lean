import Mathlib.ModelTheory.Definability

/-!
# 第 12 章 · 可构造层级：Gödel 的 L

L_α 层级：L₀ = ∅，L_{α+1} = def(L_α)（可定义子集），
L_λ = ⋃。L ⊆ V 是"最瘦的"包含全部序数的内模型。
mathlib 的 `Set.Definable` 承载 def(·) 的概念内核；
完整 L 层级由 Isabelle/ZF 的 Lset 承载（ST12）。
-/

open FirstOrder Language

/-! ## 一、可定义性（def 的概念内核） -/

/-! ## 二、L 的定义骨架（讲义） -/

/- ：集合族可定义 ⟺ 某公式（带参数）刻画——
   def(U) 的成员资格概念内核（见 ModelTheory/Definability）。 -/
/-
def(U) = cl(U ∪ {U}) ∩ P(U)：Gödel 闭包落回 U 的子集。
十个 Gödel 运算 F₁-F₁₀（配对/并/差/交/笛卡尔/dom/ran/…）
是闭包的生成元——引理 12.2：每个公式（对传递 U）可写成
Gödel 运算的复合（正规形式定理）。

定理 32：(i) L ⊨ ZF；(ii) L ⊨ V=L；(iii) L 是含全序数的
传递 ZF 模型中最小者。于是 Con(ZF) ⟹ Con(ZF + V=L)。
第 13 章：V=L ⟹ AC + GCH（相对一致性的巅峰）。

L_ω = V_ω = HF（有限层重合）；L_ω₁ ≠ V_ω₁（密度分歧）——
计算通道的 L_n 数值实验给出增长的对照。 -/
