import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.InnerProductSpace.Projection.Minimal
import Mathlib.Analysis.InnerProductSpace.Dual

/-!
# 第 00 章 · 机器已经知道哪些泛函分析

对应 `docs/00-intro.md`。本文件不做实质证明，而是把本教程要讲的
四大支柱定理的 mathlib 形态列出来，作为"机器知识地图"：
每一条 `#check` 都是一次机器对陈述的确认。

- Conway I.4.1 的 Cauchy–Schwarz 不等式（CBS）
- Conway I.2.5 的闭凸集最近点存在性
- Conway I.2.6 的投影正交刻画
- Conway I.3.4 的 Riesz 表示定理
-/

open scoped RealInnerProductSpace InnerProductSpace

-- **CBS 不等式（复情形的一般形式）**：`⟪x, y⟫` 的模平方不超过 `⟪x, x⟫` 与 `⟪y, y⟫` 实部之积
#check @inner_mul_inner_self_le

-- **闭凸集最近点**（完备空间）：非空完备凸集上范数达到下确界的点存在
#check @exists_norm_eq_iInf_of_complete_convex

-- **投影的正交刻画**：v 到子空间 K 的距离在 u 处达到，当且仅当 u - v ⊥ K
#check @Submodule.norm_eq_iInf_iff_inner_eq_zero

-- **Riesz 表示**：Hilbert 空间到其对偶的共轭线性等距同构
#check @InnerProductSpace.toDual

/-!
机器也"知道"具体的空间是 Hilbert 空间。
下面两个 `example` 用实例搜索直接确认：

1. 复数域 ℂ 本身是一维复 Hilbert 空间（完备的内积空间）；
2. `EuclideanSpace ℝ (Fin n)` 是实 Hilbert 空间，且对任意 n 成立。
-/

example : CompleteSpace ℂ := by infer_instance

example {n : ℕ} : CompleteSpace (EuclideanSpace ℝ (Fin n)) := by infer_instance

/-!
最后做一个完整的小证明作为热身：在实内积空间中，
内积对两个变元都连续——这是 Conway I.1 末尾的注记。
这里只验证一维的情形：ℝ 上的内积就是乘法。
-/

example (a b : ℝ) : ⟪a, b⟫_ℝ = a * b := by simp; ring
