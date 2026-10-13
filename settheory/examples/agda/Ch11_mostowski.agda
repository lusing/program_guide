-- 第 11 章 传递模型：Mostowski 坍缩的构造性骨架
--
-- 良基 + 外延 ⟹ 唯一同构于传递类。π(x) = π[ext(x)]。
-- 有限版完全可计算：外延良基图的坍缩是"把图读成嵌套集合"。

module Ch11_mostowski where

open import Data.Nat using (ℕ; zero; suc)
open import Data.List using (List; []; _∷_; map)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 目标域：嵌套列表（HF 编码）
data HFL : Set where
  hfl : List HFL -> HFL

-- 外延良基图的接口：点集带 ext 函数（成员表）
record ExtGraph : Set₁ where
  field
    Point : Set
    ext   : Point → List Point
    wf-depth : Point → ℕ          -- 良基性的有限见证（高度）

open ExtGraph

-- 坍缩：对高度归纳
collapse : (G : ExtGraph) → (x : Point G) → ℕ → HFL
collapse G x zero = hfl []        -- 高度 0 的退化（安全阀）
collapse G x (suc d) =
  hfl (map (λ z → collapse G z d) (ext G x))

-- ---------- 一个具体例子：三点链 a E b（b 的 ext 是 a） ----------

-- 点：三元素枚举
data P3 : Set where
  pa pb pc : P3

G3 : ExtGraph
G3 = record
  { Point = P3
  ; ext = λ { pa → [] ; pb → pa ∷ [] ; pc → pa ∷ pb ∷ [] }
  ; wf-depth = λ { pa → 1 ; pb → 2 ; pc → 3 }
  }

-- 坍缩结果：pa ↦ ∅、pb ↦ {∅}、pc ↦ {∅,{∅}}（von Neumann 数！）
collapse-pa : collapse G3 pa 1 ≡ hfl []
collapse-pa = refl

collapse-pb : collapse G3 pb 2 ≡ hfl (hfl [] ∷ [])
collapse-pb = refl

collapse-pc : collapse G3 pc 3 ≡ hfl (hfl [] ∷ hfl (hfl [] ∷ []) ∷ [])
collapse-pc = refl

-- 外延良基图坍缩成传递集合编码——Mostowski 定理的有限化身。
