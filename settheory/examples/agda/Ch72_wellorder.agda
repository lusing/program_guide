-- 第 72 章：秩序与序数算术（冯琦 §1.8.1-1.8.3）
-- 自然列表（定义 1.71）的构造性承载：前 n 个有限序数的升序列表、
-- 雪崩赋名次 av（x 的名次 = x 之前 X 里的元素个数 = min k n）、
-- 名次恒等与单调性的完整证明。
module Ch72_wellorder where

open import Data.Nat using (ℕ; zero; suc; _<_; _≤_; z≤n; s≤s)
open import Data.Nat.Properties using (≤-refl; ≤-trans)
open import Data.List using (List; []; _∷_; length)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; cong; trans)

-- ---------- 有限冯诺伊曼序数（承接 71 章） ----------

data Von : Set where
  v0 : Von
  vs : Von → Von

vsize : Von → ℕ
vsize v0 = zero
vsize (vs n) = suc (vsize n)

-- 第 k 个冯诺伊曼序数：vN k = {v0, …, v_{k-1}}
vN : ℕ → Von
vN zero = v0
vN (suc k) = vs (vN k)

vsize-vN : ∀ k → vsize (vN k) ≡ k
vsize-vN zero = refl
vsize-vN (suc k) = cong suc (vsize-vN k)

-- ---------- 自然列表：{v0, …, v_{n-1}} 的升序列表 ----------

infixl 5 _∶_
_∶_ : List Von → Von → List Von   -- snoc（自造，避开 stdlib 的 ∷ʳ/snoc 更名）
[] ∶ x = x ∷ []
(y ∷ ys) ∶ x = y ∷ (ys ∶ x)

up : ℕ → List Von                  -- 定义 1.71：X 的自然列表（升序枚举）
up zero = []
up (suc n) = up n ∶ vN n

len-∶ : ∀ (l : List Von) x → length (l ∶ x) ≡ suc (length l)
len-∶ [] x = refl
len-∶ (y ∷ ys) x = cong suc (len-∶ ys x)

len-up : ∀ n → length (up n) ≡ n   -- ot(X) = |X|：序型恰是长度
len-up zero = refl
len-up (suc n) = trans (len-∶ (up n) (vN n)) (cong suc (len-up n))

-- ---------- 雪崩赋名次：av k n = ot(vN k ∩ up n) ----------
-- x = vN k 的名次 = x 之前 X = {v0,…,v_{n-1}} 里的元素个数。
-- 有限带里它就是 min k n——结构递归直接实现。

av : ℕ → ℕ → ℕ
av zero n = zero
av (suc k) zero = zero
av (suc k) (suc n) = suc (av k n)

-- 名次恒等（引理 1.14 / 命题 1.22 的方向一）：x ∈ X 时名次 = 位次。
-- k ≤ n ⟹ av k n = k：x 之前恰有 k 个元素（v0..v_{k-1} 全在 X 里）。
av≡ : ∀ {k n} → k ≤ n → av k n ≡ k
av≡ z≤n = refl
av≡ (s≤s p) = cong suc (av≡ p)

-- 截断（方向二）：x ∉ X（k > n）时名次 = ot(X) = n——列表已尽，
-- "前段的列表是列表的前段"（命题 1.22）的截断读法。
av-trunc : ∀ {k n} → n ≤ k → av k n ≡ n
av-trunc {zero} {zero} p = refl
av-trunc {suc k} {zero} p = refl
av-trunc {suc k} {suc n} (s≤s p) = cong suc (av-trunc p)

-- 名次单调（雪崩映射保序）：x < y 且两者都在 X 里 ⟹ 名次严格递增。
-- k < m ≤ n ⟹ av k n < av m n——两边用名次恒等化成 k < m。
-- 注意：rewrite 表达式看不到 where 块的绑定（scope 隔离），k≤n 的
-- 推导必须内联；a ≤ suc a 自证两行归纳（s≤s ≤-refl 给的是
-- suc a ≤ suc a，方向不对）。
≤-suc : ∀ {a : ℕ} → a ≤ suc a
≤-suc {zero} = z≤n
≤-suc {suc a} = s≤s ≤-suc

av-mono : ∀ {k m n} → suc k ≤ m → m ≤ n → suc (av k n) ≤ av m n
av-mono {k} {m} {n} sk≤m m≤n
  rewrite av≡ {k} {n} (≤-trans ≤-suc (≤-trans sk≤m m≤n))
        | av≡ {m} {n} m≤n
  = sk≤m

-- ---------- 决定性抽查：名次表 ----------
-- av 2 5 = 2（v2 在 {v0..v4} 里排第 2 位）；av 5 2 = 2（截断）；
check-∈ : av 2 5 ≡ 2
check-∈ = refl

check-trunc : av 5 2 ≡ 2
check-trunc = refl

-- ot(X) = |X|（len-up）与名次恒等合读：av n n ≡ n——自然列表
-- 把 X 铺满 [0, ot(X))：位次与名次在全域重合（雪崩映射是双射）。
check-full : av 4 4 ≡ 4
check-full = refl
