import Mathlib.Analysis.InnerProductSpace.l2Space
import Mathlib.Analysis.InnerProductSpace.ProdL2
import Mathlib.Analysis.Fourier.AddCircle

/-!
# 第 06 章 · 同构分类、圆周 Fourier 变换与直和（Conway I.5-6）

对应 `docs/06-fourier-sums.md`。本章在机器中复现 §I.5-§I.6 主线：

1. **同构 = 保内积的双射**（Conway 5.1-5.2）：mathlib 的
   `LinearIsometryEquiv`。
2. **分类定理**（Conway 5.4）：两个 Hilbert 空间同构 ⟺ 维数相同。
   mathlib 的承载者：`HilbertBasis.repr` 是到 ℓ²(ι) 的等距同构。
3. **圆周上的 Fourier 变换**（Conway 5.6-5.11）：mathlib 已有完整的
   圆周理论——`fourier`、`fourierCoeff`、`fourierBasis` 与
   **Parseval 恒等式** `hasSum_sq_fourierCoeff`。
4. **Hilbert 直和**（Conway 6.1-6.4）：有限和 = `ProdL2`，
   一般和 = `lp 2`。
-/

open scoped RealInnerProductSpace InnerProductSpace

/-!
## 1. 同构 = 保内积（Conway 5.1）

Hilbert 空间的**同构**是保内积的线性双射。mathlib 用
`LinearIsometryEquiv`（等距线性双射）承载；由极化恒等式，
保范与保内积在 内积空间上是等价的。
-/

section Iso

-- LinearIsometryEquiv 的定义形态：线性等距双射
#check @LinearIsometryEquiv

-- 保内积的线性等距：`LinearIsometry.inner_map_map`（Conway 5.2 的核心）
#check @LinearIsometry.inner_map_map

end Iso

/-!
## 2. 分类定理（Conway 5.4）

`HilbertBasis` 的 `repr` 字段是 E 与 ℓ²(ι, 𝕜) 的等距同构——
"每个 Hilbert 空间都等距同构于某个 ℓ²(ι)"，ι 是它的维数。
两个空间同构 ⟺ 指标集同势（互相嵌入强制等势）。
-/

section HilbertBasis

-- HilbertBasis 的核心：repr : E ≃ₗᵢ ℓ²(ι)
#check @HilbertBasis.mk
#check @HilbertBasis.repr

-- HilbertBasis 给出到 lp 2 的等距同构（Conway 5.4 的机器形态）
example {ι : Type*} {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    [CompleteSpace E] (b : HilbertBasis ι ℝ E) :
    E ≃ₗᵢ[ℝ] lp (fun _ : ι => ℝ) 2 := b.repr

end HilbertBasis

/-!
## 3. 圆周上的 Fourier 变换（Conway 5.6-5.11）

取 T > 0，加法圆周 AddCircle T = ℝ/(T·ℤ)，其上 Haar 测度正规化。
mathlib 已形式化 Conway 5.6-5.11 的全部：
- `fourier n`：第 n 个 Fourier 基函数（Conway 5.7 的 e_n）；
- `fourierBasis : HilbertBasis ℤ ℂ (L²)`：(e_n) 是 Hilbert 基；
- `hasSum_sq_fourierCoeff`：**Parseval 恒等式**（Conway 5.10）。
-/

section FourierCircle

-- Fourier 基函数与 Fourier 系数
#check @fourier
#check @fourierCoeff

-- (fourier n) 是 L² 上的 Hilbert 基（Conway 5.7 + 5.8）
#check @fourierBasis

-- Parseval 恒等式：系数模平方之和 = L² 范数平方（Conway 5.10 机器形态）
#check @hasSum_sq_fourierCoeff

end FourierCircle

/-!
## 4. Hilbert 直和（Conway 6.1-6.4）

两个空间的直和：`ProdL2`——笛卡尔积配上 ℓ² 型内积
`⟪(x,y), (x',y')⟫ = ⟪x,x'⟫ + ⟪y,y'⟫`。任意族的直和是 `lp 2`。
-/

section DirectSum

-- ProdL2（WithLp 2 (E₁ × E₂)）上的内积空间结构与完备性
example {E₁ E₂ : Type*} [NormedAddCommGroup E₁] [InnerProductSpace ℝ E₁]
    [NormedAddCommGroup E₂] [InnerProductSpace ℝ E₂]
    [CompleteSpace E₁] [CompleteSpace E₂] :
    CompleteSpace (WithLp 2 (E₁ × E₂)) := by infer_instance

-- lp 2 的完备性（任意族的直和完备）
example {I : Type*} {G : I → Type*} [∀ i, NormedAddCommGroup (G i)]
    [∀ i, InnerProductSpace ℝ (G i)] [∀ i, CompleteSpace (G i)] :
    CompleteSpace (lp G 2) := by infer_instance

end DirectSum

/-!
## 5. 单侧移位（Conway 5.3 预告，II.2.10 再见）

S(α₁,α₂,…) = (0,α₁,α₂,…) 是 ℓ² 的等距（非满）。mathlib 中它作为
`lp` 上的移位出现在后续章节；这里只确认等距不双射的构造性事实
由数值通道（docs 第 06 章）演示。
-/
