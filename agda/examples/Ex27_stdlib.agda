------------------------------------------------------------------------
-- 第 27 章示例：标准库「综合应用小厨房」
--
-- 本章示例不再自造轮子，而是把 stdlib 2.3 里八个真实存在的高级件
-- 拼进同一个文件：每个小节对应正文里讲过的一个 import 路径，
-- 全部经 Agda 2.8.0 类型检查通过。
------------------------------------------------------------------------

module Ex27_stdlib where

-- ════════════════════════════════════════════════════════════════════
-- 件 1/8：Data.Nat.Base —— 只管定义（ℕ、zero/suc、算术符）
-- 证明全部住在 Data.Nat.Properties，这里故意一个都不 import。
-- ════════════════════════════════════════════════════════════════════

open import Data.Nat.Base
  using (ℕ; zero; suc; _+_; _≤_; z≤n; s≤s)

-- 注意：这里刻意不 import 任何证明——Base 层只有定义没有引理，
-- 后面用到 ≡ 时要靠件 3 的 PropEq import 补上。

-- ════════════════════════════════════════════════════════════════════
-- 件 2/8：Data.Nat.Properties —— 证明仓库
-- _≤?_、+-assoc、+-comm、+-mono-≤、≤-decTotalOrder、≤-Reasoning 都在这。
-- ════════════════════════════════════════════════════════════════════

open import Data.Nat.Properties
  using (_≤?_; +-assoc; +-comm; +-mono-≤; ≤-decTotalOrder)

-- ≤-Reasoning 是嵌套 module：Agda 2.8 的 using() 选不中它（实测报
-- ModuleDoesntExport 警告且真的绑不上），只能走限定名打开——28 章坑位。
import Data.Nat.Properties as NP

-- 单调性引理直接拿来用，不用自己归纳。注意 z≤n 的隐式上界是自由 metavar，
-- 所以先把两个 ≤ 证据写成带类型标注的引理、再喂给 +-mono-≤——否则整条
-- `?m + ?o := 3` 之类的算术 unification 会留下无解约束（实测坑）。
one≤3 : 1 ≤ 3
one≤3 = s≤s z≤n

two≤4 : 2 ≤ 4
two≤4 = s≤s (s≤s z≤n)

plus-monotone-demo : 1 + 2 ≤ 3 + 4
plus-monotone-demo = +-mono-≤ one≤3 two≤4

-- ════════════════════════════════════════════════════════════════════
-- 件 3/8：≡-Reasoning 推理链。注意：嵌套 module 一律进不了 using()
-- 名单（见件 2 注释），只能限定名打开。
-- ════════════════════════════════════════════════════════════════════

open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; cong)
import Relation.Binary.PropositionalEquality as PE

shuffle : ∀ a b c → (a + b) + c ≡ (a + c) + b
shuffle a b c = begin
  (a + b) + c  ≡⟨ +-assoc a b c ⟩
  a + (b + c)  ≡⟨ cong (λ x → a + x) (+-comm b c) ⟩
  a + (c + b)  ≡⟨ sym (+-assoc a c b) ⟩
  (a + c) + b  ∎
  where open PE.≡-Reasoning

-- ════════════════════════════════════════════════════════════════════
-- 件 4/8：≤-Reasoning —— ≡ 步与 ≤ 步混链（Data.Nat.Properties 提供）
-- ════════════════════════════════════════════════════════════════════

mixed-chain : 1 + 2 ≤ 4
mixed-chain = begin
  1 + 2   ≡⟨ +-comm 1 2 ⟩
  2 + 1   ≡⟨⟩
  3       ≤⟨ s≤s (s≤s (s≤s z≤n)) ⟩
  4       ∎
  where open NP.≤-Reasoning

-- ════════════════════════════════════════════════════════════════════
-- 件 5/8：Dec 与 ⌊_⌋ —— 判定结果剥证据，喂给 if
-- （Relation.Nullary.Decidable + Data.Bool.Base）
-- ════════════════════════════════════════════════════════════════════

open import Data.List.Base using (List; []; _∷_; zipWith; foldr; merge)
open import Data.Bool.Base using (if_then_else_)
open import Relation.Nullary.Decidable using (⌊_⌋)

takeWhile≤ : ℕ → List ℕ → List ℕ
takeWhile≤ k []        = []
takeWhile≤ k (x ∷ xs)  = if ⌊ x ≤? k ⌋ then x ∷ takeWhile≤ k xs else []

takeWhile≤-run : takeWhile≤ 3 (2 ∷ 3 ∷ 5 ∷ 1 ∷ []) ≡ 2 ∷ 3 ∷ []
takeWhile≤-run = refl

-- ════════════════════════════════════════════════════════════════════
-- 件 6/8：Data.List.Base 的 zipWith —— 截断语义写进等式即证
-- （对照件 7 的 Vec.zipWith：长度相等的要求搬到类型里）
-- ════════════════════════════════════════════════════════════════════

zip-truncates : zipWith _+_ (1 ∷ 2 ∷ []) (3 ∷ 4 ∷ 5 ∷ []) ≡ 4 ∷ 6 ∷ []
zip-truncates = refl

-- ════════════════════════════════════════════════════════════════════
-- 件 7/8：Data.Vec + Data.Fin —— tabulate/lookup 互为逆的纯 refl 时刻
-- 两个模块的 []、∷ 与 List/Nat 同名，全用限定名避开二义性。
-- ════════════════════════════════════════════════════════════════════

import Data.Vec.Base as V
import Data.Fin.Base as F
open import Function.Base using (_∘_)

-- stdlib 把 Vec 的 tabulate 写成递归（f zero ∷ tabulate (f ∘ suc)），
-- 所以 lookup∘tabulate 不是免费 refl，得对 Fin 归纳——这本身就是
-- 「读源码学证明」的标本（件 1 的 tabulate 定义就在 Data.Vec.Base）。
lookup-tabulate : ∀ {A : Set} {n : ℕ} (f : F.Fin n → A) (i : F.Fin n) →
                  V.lookup (V.tabulate f) i ≡ f i
lookup-tabulate {n = zero}  f ()
lookup-tabulate {n = suc n} f F.zero    = refl
lookup-tabulate {n = suc n} f (F.suc i) = lookup-tabulate (f ∘ F.suc) i

vec-zip : V.Vec ℕ 2
vec-zip = V.zipWith _+_ (1 V.∷ 2 V.∷ V.[]) (3 V.∷ 4 V.∷ V.[])

vec-zip-run : vec-zip ≡ (4 V.∷ 6 V.∷ V.[])
vec-zip-run = refl

-- Fin 与不等式证明的联动：用 inject≤ 把「长度不等」搬成「元素加宽」。
n≤1+n : ∀ m → m ≤ suc m
n≤1+n zero    = z≤n
n≤1+n (suc m) = s≤s (n≤1+n m)

-- 单独给引理标注完整类型：inject≤ 的证明参数是 erases 的 `.(m ≤ n)`，
-- 期望类型不会灌进来，行内 s≤s 链的隐式 size 会留成无解 metavar（实测坑）
suc≤+1 : ∀ m → suc (suc m) ≤ suc (suc (suc m))
suc≤+1 m = s≤s (s≤s (n≤1+n m))

shift-up : ∀ {n} (i : F.Fin n) → F.Fin (suc (suc n))
shift-up {zero}    ()
shift-up {suc m} i = F.inject≤ (F.suc i) (suc≤+1 m)

-- shift-up 对 which-Fin 是无关参数（值不依赖它），不给标注就是无解 metavar
shift-run : F.toℕ (shift-up {n = 2} (F.suc F.zero)) ≡ 2
shift-run = refl

-- ════════════════════════════════════════════════════════════════════
-- 件 8/8：Data.List.Sort —— 官方归并排序，附赠两个定理
--   sort-↭ : ∀ xs → sort xs ↭ xs   （输出是输入的重排）
--   sort-↗ : ∀ xs → Sorted (sort xs) （输出有序）
-- 这正是第 26 章手写插入排序所证明的东西——stdlib 早就装好了。
-- ════════════════════════════════════════════════════════════════════

-- DecTotalOrder 是个 record 包（bundle），打开它才能取出内部的
-- totalOrder 子包喂给 Sorted 谓词——stdlib 代数层的标准体操。
open import Relation.Binary.Bundles using (DecTotalOrder)
open DecTotalOrder ≤-decTotalOrder using () renaming (totalOrder to ≤-total)

open import Data.List.Relation.Binary.Permutation.Propositional using (_↭_)
open import Data.List.Relation.Unary.Sorted.TotalOrder ≤-total using (Sorted)
open import Data.List.Sort ≤-decTotalOrder using (sort; sort-↭; sort-↗)

list-312 : List ℕ
list-312 = 3 ∷ 1 ∷ 2 ∷ []

-- 定理实例化到具体输入。（实测坑：`sort list-312 ≡ 1 ∷ 2 ∷ 3 ∷ []`
-- 写不成 refl——mergeSort 的递归走 Data.Nat.Induction 的
-- well-founded 快速版，闭项也不在编译期展开；定理照用不误。）
sort-is-permutation : sort list-312 ↭ list-312
sort-is-permutation = sort-↭ list-312

sort-is-sorted : Sorted (sort list-312)
sort-is-sorted = sort-↗ list-312

-- 想 refl 出真正的排序结果，用 mergeSort 的结构递归零件 merge：
merge-run : merge _≤?_ (1 ∷ 3 ∷ []) (2 ∷ 4 ∷ []) ≡ 1 ∷ 2 ∷ 3 ∷ 4 ∷ []
merge-run = refl

-- 收个尾：foldr 也是 List.Base 的，凑一锅标准库风味
merge-fold-check : foldr _+_ 0 (merge _≤?_ (1 ∷ 3 ∷ []) (2 ∷ 4 ∷ [])) ≡ 10
merge-fold-check = refl
