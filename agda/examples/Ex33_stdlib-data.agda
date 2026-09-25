module Ex33_stdlib-data where

-- 第 33 章配套示例：Data 找路术 —— List 关系树 / Fin 构造 / Tree.AVL 新路径。

open import Data.Nat using (ℕ; zero; suc; _+_)
open import Data.Nat.Properties using (_≤?_)

-- ── 件 1：List 门面很薄，map / filter / length / _++_ 都在 Data.List.Base（被门面转发）。
open import Data.List using (List; []; _∷_; map; filter; length; _++_)

xs : List ℕ
xs = map (λ n → n + 1) (0 ∷ 1 ∷ [])
xs-again : List ℕ
xs-again = xs ++ (2 ∷ [])

-- ── 件 2：filter 要 Decidable 谓词（30 章坑 6）。`5 ≤? n : Dec (5 ≤ n)` 直接当谓词。
ge5 : List ℕ
ge5 = filter (λ n → 5 ≤? n) (3 ∷ 7 ∷ 9 ∷ [])

-- ── 件 3：Fin —— 关键心智 zero : Fin (suc n)。
--   fromℕ< : .(m < n) → Fin n，压进 Fin n 要一个失败证明。
open import Data.Fin using (Fin; zero; suc; fromℕ<; #_)

fin0 : Fin (suc zero)
fin0 = zero

-- 证明构造块：s≤s 一层层剥掉 suc，z≤n 是 _≤_ 的最底层构造子。
open import Data.Nat using (s≤s; z≤n)
open import Data.Nat.Properties using (≤-refl)

fin7 : Fin 10
fin7 = fromℕ< {7} {10}
  (s≤s (s≤s (s≤s (s≤s (s≤s (s≤s (s≤s (s≤s z≤n))))))))  -- 8 ≤ 10 ≡ 7 < 10
  -- 坑：fromℕ< 的 m 只出现在被擦除的证明里，结果类型推不出它，证明必须手工搭。

fin1 : Fin (suc (suc zero))
fin1 = fromℕ< {1} {2} (s≤s ≤-refl)   -- 显式给出 1 < 2 的证明

-- ── 件 4：3.0 大搬家 Data.AVL → Data.Tree.AVL（例子里不真建树，仅验证新路径可 import，
--   并造出造树所需的 StrictTotalOrder 整包）。键就是它的 Carrier。
open import Level using (0ℓ)
open import Relation.Binary.Bundles using (StrictTotalOrder)
open import Data.Nat.Properties using (<-strictTotalOrder)

nt : StrictTotalOrder 0ℓ 0ℓ 0ℓ
nt = <-strictTotalOrder