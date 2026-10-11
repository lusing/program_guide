import Mathlib.Analysis.Normed.Operator.Compact.Basic

/-!
# 第 12 章 · Sturm-Liouville 系统（Conway II.6*）

对应 `docs/12-sturm-liouville.md`。

本章在 mathlib 中没有直接形式化——Sturm-Liouville 理论涉及
微分算子的 Green 函数与紧积分算子的深层联系，超出当前库的覆盖。
Lean 通道仅确认背景（紧算子的定义），主要内容走数值通道：
- Julia/Python：Green 函数数值构造、特征值打靶法、有限元逼近。
- Prolog：无（纯数值内容）。
-/

open scoped RealInnerProductSpace

/-- 紧算子的定义回顾（本章的背景）。 -/
#check @IsCompactOperator
