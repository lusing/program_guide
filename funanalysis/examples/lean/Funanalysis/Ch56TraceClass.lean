import Mathlib.Analysis.InnerProductSpace.Trace
import Mathlib.Analysis.InnerProductSpace.ProdL2

/-!
# 第 56 章 · 迹类算子与 Lidskii 迹公式（Lax 30）

mathlib 树中没有迹类理论（无 `TraceClass`），但有限维影子的
关键锚点在 `Analysis/InnerProductSpace/Trace.lean`：

- `LinearMap.trace_eq_sum_inner`：迹 = 对角内积和
  （Lax 30.3 定理 3 的有限维形态）；
- `IsSymmetric.trace_eq_sum_eigenvalues`：对称算子的迹 = 特征值和
  ——**Lidskii 迹公式的有限维全文**（对称情形）；
- `InnerProductSpace.trace_rankOne`：秩一算子的迹 = ⟪y, x⟫——
  第 54 章秩一 Fredholm 行列式 D = 1 + λ⟨v,u⟩ 的伴生锚点。
-/

variable {𝕜 : Type*} [RCLike 𝕜] {E : Type*} [NormedAddCommGroup E]
  [InnerProductSpace 𝕜 E] [FiniteDimensional 𝕜 E]

-- 迹 = 对角内积和（Lax 定理 3 有限维形态；注意命名空间是 LinearMap）
#check @LinearMap.trace_eq_sum_inner

-- Lidskii 的有限维版：对称算子迹 = 特征值和
#check @LinearMap.IsSymmetric.trace_eq_sum_eigenvalues

-- 秩一算子 tr(x ⊗ y) = ⟪y, x⟫
#check @InnerProductSpace.trace_rankOne
