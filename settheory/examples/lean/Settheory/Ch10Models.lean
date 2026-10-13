import Mathlib.ModelTheory.Bundled

/-!
# 第 10 章 · 模型：相对一致性与一阶语义

mathlib 的 ModelTheory 框架提供语言/结构/初等映射的通用理论；
集合论侧的"模型=类"语义在 Isabelle/ZF 的 Formula 承载（ST10）。
-/

open FirstOrder Language

/-! ## 一、语言与结构 -/

/-- 任意语言的任意结构是一对（载体 + 解释函数）——
    Jech §10 的 2𝔄 = ⟨A, P^2𝔄, F^2𝔄, c^2𝔄⟩ 形态的 mathlib 版。 -/
example (L : Language) (M : Type) [L.Structure M] : True := trivial

/-! ## 二、相对一致性（讲义） -/

/-!
Con(T) ⟹ Con(T + A) 的标准路线：构造 M ⊨ T + A。
Gödel 第二不完备：Con(ZFC) 不可在 ZFC 内证；完备性定理：
Con ⟺ 有（集合）模型——故 `∃M, M ⊨ ZFC` 不可证。
两类模型：集合模型（可量化的对象）与类模型（定义性的化身）。
第 12-13 章的 L 与第 17 章起的力迫都走类模型路线；
mathlib 的初等子结构/Tarski 准则在
`ModelTheory/ElementarySubmodel` 一层提供通用形态。
-/
