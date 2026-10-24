-- 第 74 章：基数：和、积与典型秩序（冯琦 §1.9）——Agda 通道
-- 两条构造性承载：(1) ℵ 序列符号演算——max 规则（推论 1.13：
-- κ+λ = κ·λ = max）写成决策过程，样例规范化全部 refl 一眼看穿；
-- (2) Gödel 配对（定义 1.97/1.98）的 ℕ 截面——pair/unpair 定义与
-- 0..200 往返恒等的批量 refl 验证（双射的完整证明由 Coq 通道承担，
-- 这里做"定义即可算"的构造性对拍）。
module Ch74_cardinals where

open import Data.Nat using (ℕ; zero; suc; _+_; _*_; _⊔_; _∸_; _≡ᵇ_)
open import Data.Nat.Properties using (_<?_)
open import Data.Bool using (Bool; true; false; if_then_else_; _∧_)
open import Data.List using (List; []; _∷_; _∷ʳ_)
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
open import Relation.Nullary using (⌊_⌋)

-- ---------- 序数指标：fin n | ωp n（ω+n）——符号演算的演示范围 ----------
data OIdx : Set where
  fin : ℕ → OIdx
  ωp  : ℕ → OIdx

olt : OIdx → OIdx → Bool
olt (fin m) (fin n) = ⌊ m <? n ⌋
olt (fin _) (ωp _)  = true
olt (ωp _)  (fin _) = false
olt (ωp m)  (ωp n)  = ⌊ m <? n ⌋

-- ---------- 符号基数（定义 1.93 的 ℵ 序列截面） ----------
data SCard : Set where
  fcard : ℕ → SCard
  aleph : OIdx → SCard

sclt : SCard → SCard → Bool
sclt (fcard m) (fcard n) = ⌊ m <? n ⌋
sclt (fcard _) (aleph _) = true
sclt (aleph _) (fcard _) = false
sclt (aleph a) (aleph b) = olt a b

smax : SCard → SCard → SCard
smax a b = if sclt a b then b else a

-- 推论 1.13：κ+λ = κ·λ = max（κ,λ 无穷）；有限退化普通算术
cadd : SCard → SCard → SCard
cadd (fcard m) (fcard n) = fcard (m + n)
cadd a b = smax a b

cmul : SCard → SCard → SCard
cmul (fcard m) (fcard n) = fcard (m * n)
cmul a b = smax a b

-- 样例规范化（全部 refl）：ℵ₂+ℵ₀ = ℵ₂、ℵ_ω·ℵ₃ = ℵ_ω、(ℵ₂+ℵ₁)·ℵ₀ = ℵ₂
ex1 : cadd (aleph (fin 2)) (aleph (fin 0)) ≡ aleph (fin 2)
ex1 = refl

ex2 : cmul (aleph (ωp 0)) (aleph (fin 3)) ≡ aleph (ωp 0)
ex2 = refl

ex3 : cmul (cadd (aleph (fin 2)) (aleph (fin 1))) (aleph (fin 0)) ≡ aleph (fin 2)
ex3 = refl

ex4 : cadd (fcard 3) (fcard 7) ≡ fcard 10
ex4 = refl

ex5 : cmul (fcard 3) (fcard 7) ≡ fcard 21
ex5 = refl

-- 后继基数（定义 1.92：κ⁺）：ℵ 序列走一步
csucc : SCard → SCard
csucc (fcard n) = fcard (suc n)          -- 有限：n⁺ = n+1
csucc (aleph (fin n)) = aleph (fin (suc n))
csucc (aleph (ωp n))  = aleph (ωp (suc n))

ex6 : csucc (aleph (fin 0)) ≡ aleph (fin 1)
ex6 = refl

-- aleph 不动点链（定理 1.91(2) 的程序版）：κ₀ = ℵ₀，κ_{n+1} = ℵ_{κ_n}
-- 指标本身就是基数符号——链的每一项把上一项"塞进指标"
chain : ℕ → SCard
chain zero = aleph (fin 0)
chain (suc n) = aleph (aleph-embed (chain n))   -- κ_{n+1} = ℵ_{κ_n}
  where
  -- SCard → OIdx 的嵌入：κ ↦ "ℵ_κ" 的指标（fin/ωp 两格演示域）
  aleph-embed : SCard → OIdx
  aleph-embed (fcard n) = fin n
  aleph-embed (aleph (fin n)) = ωp n        -- ℵ₀ 的指标作序数 = ω
  aleph-embed (aleph (ωp n))  = ωp n        -- 演示域封顶：形状稳定

-- κ₁ = ℵ_ω：链的第二步把 ℵ₀ 的指标读成 ω（初始序数的红利）
ex7 : chain 1 ≡ aleph (ωp 0)
ex7 = refl

-- ---------- Gödel 配对（定义 1.97/1.98）的 ℕ 截面 ----------
pair : ℕ → ℕ → ℕ
pair a b = (a ⊔ b) * (a ⊔ b) + offset a b
  where
  m-of : ℕ → ℕ → ℕ
  m-of a b = a ⊔ b
  offset : ℕ → ℕ → ℕ
  offset a b with ⌊ a <? (a ⊔ b) ⌋
  ... | true  = a                          -- a < m：偏移 a
  ... | false with ⌊ b <? (a ⊔ b) ⌋
  ...         | true  = (a ⊔ b) + b        -- a = m > b：偏移 m+b
  ...         | false = 2 * (a ⊔ b)        -- (m,m)：偏移 2m

-- 整数开方（燃油法：从 0 爬到 m² ≤ n 的最大 m）
sqrt : ℕ → ℕ
sqrt n = go 0 n
  where
  go : ℕ → ℕ → ℕ
  go m zero = m
  go m (suc fuel) = if ⌊ (suc m * suc m) <? suc n ⌋
                    then go (suc m) fuel
                    else go m fuel

unpair : ℕ → ℕ × ℕ
unpair p = let m = sqrt p in
           let t = p ∸ m * m in
           decode m t
  where
  decode : ℕ → ℕ → ℕ × ℕ
  decode m t with ⌊ t <? m ⌋
  ... | true  = t , m
  ... | false with ⌊ t ∸ m <? m ⌋
  ...         | true  = m , t ∸ m
  ...         | false = m , m

-- ---------- 往返恒等的批量 refl 验证 ----------
upto : ℕ → List ℕ
upto zero = []
upto (suc n) = upto n ∷ʳ n

allb : (ℕ → Bool) → List ℕ → Bool
allb f [] = true
allb f (x ∷ xs) = f x ∧ allb f xs

roundtrip-ok : ℕ → Bool
roundtrip-ok p with unpair p
... | a , b = pair a b ≡ᵇ p

-- 0..200 全网格往返恒等（双射的批量构造性见证）
grid-check : allb roundtrip-ok (upto 200) ≡ true
grid-check = refl

-- 样例（书页手算对拍）：Γ(2,5)=27、Γ(5,2)=32、Γ(3,3)=15
ex-pair1 : pair 2 5 ≡ 27
ex-pair1 = refl

ex-pair2 : pair 5 2 ≡ 32
ex-pair2 = refl

ex-pair3 : pair 3 3 ≡ 15
ex-pair3 = refl
