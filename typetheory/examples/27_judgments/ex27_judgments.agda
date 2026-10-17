----------------------------------------------------------------
-- 27 MLTT 的判断形式与一般规则 —— Agda 侧
-- 四种判断 + 前提/对称/传递/替换；等式动作全靠模式匹配 refl
----------------------------------------------------------------

open import Data.Nat using (ℕ; zero; suc; _+_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; trans; cong; subst)

-- ---- 判断 a : A：源码里的每行类型标注都是 ----
one : ℕ
one = suc zero

-- ---- 判断 A type ----
NatFun : Set
NatFun = ℕ → ℕ

-- ---- a ≡ b : A：定义相等，refl 居住 ----
defeq1 : (λ n → n + 1) 1 ≡ 2
defeq1 = refl

-- 0 + n 折叠（+ 递归在第一参数），n + 0 不折叠
defeq-dir : ∀ n → 0 + n ≡ n
defeq-dir n = refl

-- ---- A ≡ B ----
tyeq : _≡_ {A = Set} NatFun (ℕ → ℕ)
tyeq = refl

-- ---- 一般规则 ----

-- 前提
hyp-rule : (P : ℕ → Set) (n : ℕ) → P n → P n
hyp-rule P n h = h

-- 对称：模式匹配 refl 即得（J 的免费赠品）
sym-rule : ∀ (a b : ℕ) → a ≡ b → b ≡ a
sym-rule a .a refl = refl

-- 传递
trans-rule : ∀ (a b c : ℕ) → a ≡ b → b ≡ c → a ≡ c
trans-rule a .a c refl h2 = h2

-- 替换：J 的直接化身
subst-rule : ∀ {A : Set} (P : A → Set) {a b} → a ≡ b → P a → P b
subst-rule P refl pa = pa

-- 同余
cong-rule : ∀ (f : ℕ → ℕ) {a b} → a ≡ b → f a ≡ f b
cong-rule f refl = refl

-- ---- 定义相等 ≠ 命题相等 ----
not-defeq : ∀ n → n + 0 ≡ n      -- refl 过不了！
not-defeq zero    = refl
not-defeq (suc n) = cong suc (not-defeq n)


-- ---- 27.1 语法层四种运算的日常形态（组合/选取） ----
open import Data.Product using (_×_; _,_; proj₁; proj₂)

kcomb : (A B : Set) → A → B → A        -- K：丢第二支
kcomb A B a b = a
procomb : (A B : Set) → A → B → A × B  -- 组合：多元组壳 ⟨a,b⟩
procomb A B a b = a , b
sel1 : (A B : Set) → A × B → A         -- 选取：e.1
sel1 A B p = proj₁ p

-- ---- 27.2 典则元 vs 非典则：值与定义相等 ----
oneC : ℕ
oneC = suc zero                         -- 典则元：构造子形式
twoNC : ℕ
twoNC = oneC + oneC                     -- 非典则：+ 递归在第一参
two-is-two : twoNC ≡ 2
two-is-two = refl                       -- refl 过 ⟺ 值相同（lazy 只看最外层）

-- 类型等同 a : A, A ≡ B ⊢ a : B 的机器面 = transport
ty-eq-move : {A B : Set} → A ≡ B → A → B
ty-eq-move refl a = a
