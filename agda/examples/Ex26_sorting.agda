------------------------------------------------------------------------
-- 第 26 章示例：可验证插入排序——sorted 谓词 + 重排证明
--
-- insert/sort 结构递归；Sorted 用两个归纳谓词（AllLe/Sorted）刻画；
-- 重排用 stdlib 的归纳版 Permutation（Data.List.
-- Relation.Binary.Permutation.Propositional 的 _↭_，实测选它）；
-- 主定理 sort-correct : Sorted (sort xs) × (sort xs ↭ xs)；
-- 附：length-sort（≡-Reasoning 计算链，对照 coq 21 章 rewrite）与
-- Vec 保长版 sortV（16 章 cast 回收）。
--
-- 类型检查：cd agda && agda examples/Ex26_sorting.agda
------------------------------------------------------------------------

module Ex26_sorting where

open import Data.Empty using (⊥; ⊥-elim)
open import Data.Nat using (ℕ; zero; suc; _≤_; z≤n; s≤s)
open import Data.Nat.Properties using (_≤?_; ≤-trans)
open import Data.List using (List; []; _∷_; length)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Relation.Nullary using (yes; no; ¬_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; trans; cong; module ≡-Reasoning)
open ≡-Reasoning

-- 重排关系：stdlib 现成的归纳定义（4 构造子：refl/prep/swap/trans）。
-- 实测过程见文档 26.4：Setoid 版要随身带 Pointwise 证据，噪音大；
-- 这个 Propositional 版最薄，直接用。类型 _↭_ 不具名导入，
-- 构造子一律限定 P.xxx——避开与 PropEq 的 refl/trans 撞名。
open import Data.List.Relation.Binary.Permutation.Propositional
  using (_↭_)
import Data.List.Relation.Binary.Permutation.Propositional as P

open import Data.Vec using (Vec; []; _∷_; toList; fromList; cast)

------------------------------------------------------------------------
-- 26.1 算法：结构递归干净得像白开水
------------------------------------------------------------------------

-- insert 假定 ys 已有序，把 x 插进正确位置；sort 递归排尾插头。
-- 递归都走在 List 结构上，终止检查一眼过（07 章）。
insert : ℕ → List ℕ → List ℕ
insert x [] = x ∷ []
insert x (y ∷ ys) with x ≤? y
insert x (y ∷ ys) | yes _ = x ∷ y ∷ ys
insert x (y ∷ ys) | no _ = y ∷ insert x ys

sort : List ℕ → List ℕ
sort [] = []
sort (x ∷ xs) = insert x (sort xs)

_ : sort (5 ∷ 3 ∷ 1 ∷ 8 ∷ []) ≡ 1 ∷ 3 ∷ 5 ∷ 8 ∷ []
_ = refl

_ : sort (3 ∷ 3 ∷ 1 ∷ []) ≡ 1 ∷ 3 ∷ 3 ∷ []
_ = refl

-- 能跑 ≠ 正确。「跑了几组都对」与「对」之间的鸿沟用两条性质填：
-- 有序 + 是重排。只满足其一的垃圾函数比比皆是（常返 [] 有序但丢
-- 数据；id 保数据但未必有序）。

------------------------------------------------------------------------
-- 26.2 性质一：Sorted——两个互相搭手的归纳谓词
------------------------------------------------------------------------

-- AllLe x ys：x 不大於 ys 的**每一个**元素（coq 21 章 le_all 同款）。
-- 为什么不用「相邻两两 ≤」？那样 insert 保序要另证「局部推全局」；
-- 全场压制版一步到位，代价是引理要随身带 AllLe。
data AllLe : ℕ → List ℕ → Set where
  le[] : ∀ {x} → AllLe x []
  le∷ : ∀ {x y ys} → x ≤ y → AllLe x ys → AllLe x (y ∷ ys)

data Sorted : List ℕ → Set where
  s[] : Sorted []
  s∷ : ∀ {x xs} → AllLe x xs → Sorted xs → Sorted (x ∷ xs)

-- ≤ 传递性穿透 AllLe（coq 21 章引理 le_all_le 的镜像）
allLe-trans : ∀ {a b : ℕ} {xs : List ℕ} →
              a ≤ b → AllLe b xs → AllLe a xs
allLe-trans {xs = []} a≤b le[] = le[]
allLe-trans a≤b (le∷ b≤y rest) =
  le∷ (≤-trans a≤b b≤y) (allLe-trans a≤b rest)

-- 3 ≰ 1：空模式一口气拆完（10/15 章回收；26.3 的 no 分支要用它的逆）
3≰1 : ¬ (3 ≤ 1)
3≰1 (s≤s ())

-- ¬(a ≤ b) → b ≤ a：手写版「全序的反面」。zero 情况靠 ⊥-elim：
-- 0 ≤ n 恒真（z≤n），证据 h 荒谬。Agda 不会像 Coq lia 那样自动
-- 补这一步，但三步模式匹配就是全部难度。
¬≤→≥ : ∀ {m n : ℕ} → ¬ (m ≤ n) → n ≤ m
¬≤→≥ {zero} {n} h = ⊥-elim (h z≤n)
¬≤→≥ {suc m} {zero} h = z≤n
¬≤→≥ {suc m} {suc n} h = s≤s (¬≤→≥ (λ mn → h (s≤s mn)))

-- 保序主引理：把 x 插进「z 压得住」的表，z 仍压得住结果。
-- 关键泛化（coq 同款坑位）：不能只对 z = x 证（那是 allLe 保持
-- 自反的弱版），z 必须**独立量化**，否则 no 分支的归纳假设对不上。
allLe-insert : ∀ {z} (x : ℕ) (ys : List ℕ) →
               z ≤ x → AllLe z ys → AllLe z (insert x ys)
allLe-insert x [] z≤x le[] = le∷ z≤x le[]
allLe-insert {z} x (y ∷ ys) z≤x (le∷ z≤y rest) with x ≤? y
... | yes _ = le∷ z≤x (le∷ z≤y rest)
... | no _ = le∷ z≤y (allLe-insert x ys z≤x rest)

-- 插入保序：结构归纳 + 每次 with 复用 insert 自己那次 ≤? 判定——
-- 「和定义同步 case-split」是 Agda 证明的第一姿势（13 章剧本）。
sorted-insert : (x : ℕ) → ∀ {ys} → Sorted ys → Sorted (insert x ys)
sorted-insert x {[]} ss = s∷ le[] s[]
sorted-insert x {y ∷ ys} (s∷ a s) with x ≤? y
... | yes x≤y = s∷ (le∷ x≤y (allLe-trans x≤y a)) (s∷ a s)
... | no ¬xy = s∷ (allLe-insert x ys (¬≤→≥ ¬xy) a) (sorted-insert x s)

sorted-sort : ∀ ys → Sorted (sort ys)
sorted-sort [] = s[]
sorted-sort (x ∷ xs) = sorted-insert x (sorted-sort xs)

-- 具体见证：排序结果的有序性不是断言，是一个可检查的证明项
sorted-351 : Sorted (sort (5 ∷ 3 ∷ 1 ∷ []))
sorted-351 = sorted-sort (5 ∷ 3 ∷ 1 ∷ [])

------------------------------------------------------------------------
-- 26.3 性质二：↭ 重排——stdlib 的 4 构造子归纳版
------------------------------------------------------------------------

-- stdlib 构造子（限定写 P.xxx）：
--   P.refl : xs ↭ xs
--   P.prep : ∀ x → xs ↭ ys → x ∷ xs ↭ x ∷ ys
--   P.swap : ∀ x y → xs ↭ ys → x ∷ y ∷ xs ↭ y ∷ x ∷ ys
--   P.trans : xs ↭ ys → ys ↭ zs → xs ↭ zs
-- 它**不是**「自造或 stdlib 二选一」：本仓库实测两者后选了它。

_ : (3 ∷ 1 ∷ 2 ∷ []) ↭ (1 ∷ 3 ∷ 2 ∷ [])
_ = P.swap 3 1 P.refl

-- 对称性 stdlib Properties 里现成（自证版见文档 26.3）
↭-sym-demo : ∀ {xs ys : List ℕ} → xs ↭ ys → ys ↭ xs
↭-sym-demo = P.↭-sym

-- 插入即重排：x ∷ ys ↭ insert x ys。与 26.2 同一个 with，
-- yes 分支两端定义相等（P.refl），no 分支 swap + prep ∘ IH。
insert-↭ : (x : ℕ) (ys : List ℕ) → (x ∷ ys) ↭ insert x ys
insert-↭ x [] = P.refl
insert-↭ x (y ∷ ys) with x ≤? y
... | yes _ = P.refl
... | no _ = P.trans (P.swap {xs = ys} {ys = ys} x y P.refl)
                (P.prep y (insert-↭ x ys))

sort-↭ : ∀ xs → sort xs ↭ xs
sort-↭ [] = P.refl
sort-↭ (x ∷ xs) =
  P.trans (P.↭-sym (insert-↭ x (sort xs))) (P.prep x (sort-↭ xs))
-- 读法：insert x (sort xs) ↭[sym] x ∷ sort xs ↭[prep x ∘ IH] x ∷ xs。
-- coq 21 章是同一条链，只是它用 rewrite 把等式往目标里塞。

------------------------------------------------------------------------
-- 26.4 主定理：正确 = 有序 × 重排（12 章 ×、13 章归纳全套回收）
------------------------------------------------------------------------

sort-correct : (xs : List ℕ) → Sorted (sort xs) × (sort xs ↭ xs)
sort-correct xs = sorted-sort xs , sort-↭ xs

-- 两个分量各自是独立定理——拆性质再合取，陈述即目录。
perm-531 : sort (5 ∷ 3 ∷ 1 ∷ []) ↭ (5 ∷ 3 ∷ 1 ∷ [])
perm-531 = proj₂ (sort-correct (5 ∷ 3 ∷ 1 ∷ []))

------------------------------------------------------------------------
-- 26.5 赠品一：保长（≡-Reasoning 计算链，对照 coq rewrite 链）
------------------------------------------------------------------------

length-insert : (x : ℕ) (ys : List ℕ) → length (insert x ys) ≡ suc (length ys)
length-insert x [] = refl
length-insert x (y ∷ ys) with x ≤? y
... | yes _ = refl
... | no _ = cong suc (length-insert x ys)

-- coq 那边的风格：三行 rewrite + reflexivity；证据全塞进「看不见的
-- 当前目标」。Agda 这边 calc 链把每一跳写明（14 章）：
length-sort : (xs : List ℕ) → length (sort xs) ≡ length xs
length-sort [] = refl
length-sort (x ∷ xs) = begin
  length (sort (x ∷ xs))
 ≡⟨⟩
  length (insert x (sort xs))
 ≡⟨ length-insert x (sort xs) ⟩
  suc (length (sort xs))
 ≡⟨ cong suc (length-sort xs) ⟩
  suc (length xs)
 ∎

------------------------------------------------------------------------
-- 26.6 赠品二：Vec 索引版——长度写进类型，排序不增不删（16 章回收）
------------------------------------------------------------------------

-- sortV : Vec ℕ n → Vec ℕ n——签名本身就是「保长」定理：
-- 想偷一个元素？返回类型里的 n 凑不出来。
-- 16.7 的往返定律在这里上岗（length-toList 即当年的 len-forget）。
length-toList : ∀ {m} → (v : Vec ℕ m) → length (toList v) ≡ m
length-toList [] = refl
length-toList (x ∷ xs) = cong suc (length-toList xs)

sortV : ∀ {n} → Vec ℕ n → Vec ℕ n
sortV {n = n} v =
  cast (trans (length-sort (toList v)) (length-toList v))
       (fromList (sort (toList v)))

-- toList/fromList/cast 三件套：List 侧做算法，Vec 侧交还索引——
-- 16.7 的往返定律在这里上岗（length-toList 即当年的 len-forget）。

-- 收尾对照 coq 21 章：那边 sorted/Permutation/主定理三段戏，这边
-- 一一对应；多出来的只有「谓词构造子的模式匹配纪律」和
-- 「no 分支手喂 ¬≤→≥」两处 Agda 特色学费。
