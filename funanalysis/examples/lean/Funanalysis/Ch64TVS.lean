import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Seminorm
import Mathlib.Analysis.LocallyConvex.WithSeminorms
import Mathlib.Analysis.LocallyConvex.AbsConvexOpen
import Mathlib.Analysis.Convex.Gauge

/-!
# 第 64 章 · 拓扑向量空间：半范数与 Minkowski 泛函（Rudin 第 1 章）

本树 mathlib 的局部凸理论是 Rudin 1.33–1.37 字典的现代机器化：

- `Seminorm`（1.33 的半范数结构：AddGroupSeminorm + 绝对齐次）；
- `SeminormFamily` + `WithSeminorms`（1.37：半范数族诱导局部凸拓扑）；
- `gauge`（Rudin 的 Minkowski 泛函 μ_A）；
- `gaugeSeminormFamily`（1.36：均衡凸开邻域的 gauge 全体生成同一拓扑），
  `gaugeSeminormFamily_ball` 即 1.36 的 V = {μ_V < 1}。
-/

-- 半范数结构（1.33）
#check @Seminorm
-- 半范数族（1.37 的 𝒫）
#check @SeminormFamily
-- Minkowski 泛函 μ_A（1.33 定义）
#check @gauge
-- 1.36 的机器化：gauge 半范数族的单位球 = 原集合
#check @gaugeSeminormFamily_ball

-- 手写件 1：ℝ² 上 p(x) = |x₁| 是半范数（Rudin 1.34 的最小实例：
-- {p = 0} = y 轴是子空间，p 不可分点）
-- 投影半范数 p(x) = |x.1|：范数半范数 ∘ 第一坐标（1.34 最小实例：
-- {p = 0} = y 轴是子空间，p 不可分点）
noncomputable def projSeminorm : Seminorm ℝ (ℝ × ℝ) :=
  (normSeminorm ℝ ℝ).comp (LinearMap.fst ℝ ℝ ℝ)

-- 半范数基本性质（1.34）：p(x) ≤ p(y) + p(x−y)——由次可加性直接推出
example (p : Seminorm ℝ (ℝ × ℝ)) (x y : ℝ × ℝ) :
    p x ≤ p y + p (x - y) := by
  have h : p (y + (x - y)) ≤ p y + p (x - y) := p.add_le' y (x - y)
  rwa [add_sub_cancel] at h
