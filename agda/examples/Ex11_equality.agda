------------------------------------------------------------------------
-- 第 11 章示例：命题等式
--
-- ≡ 的 data 定义、refl 模式匹配（端点塌缩）、sym/trans/cong/subst 全家族、
-- J 规则（基于等式的归纳）、Leibniz 等式、≢（否定）、rewrite 关键字。
--
-- 类型检查：cd agda && agda examples/Ex11_equality.agda
------------------------------------------------------------------------

module Ex11_equality where

open import Data.Nat using (ℕ; zero; suc; _+_)
open import Data.Fin using (Fin)
open import Function using (case_of_; _∘_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; _≢_; refl; sym; trans; cong; cong₂; subst; J)

------------------------------------------------------------------------
-- 11.1 ≡ 只是一个普通的 data——与 Agda.Builtin.Equality 逐字同构的复制品
------------------------------------------------------------------------

-- Agda 内核里（lib/prim/Agda/Builtin/Equality.agda）：
--   data _≡_ {a} {A : Set a} (x : A) : A → Set a where
--     refl : x ≡ x
-- 自己也能造一个一模一样的（stdlib 的机器从此全部可用）：

data _==_ {A : Set} (x : A) : A → Set where
  refl= : x == x

-- 「等式证明只有一个构造子」意味着：对它做模式匹配 = 强制两端相等
sym-== : ∀ {A : Set} {x y : A} → x == y → y == x
sym-== refl= = refl=

------------------------------------------------------------------------
-- 11.2 refl = 把两边规约到同一个值
------------------------------------------------------------------------

_ : 1 + 1 ≡ 2
_ = refl

_ : 2 + 0 ≡ 2                      -- n + 0 在「具体数字」上也算得动
_ = refl

0+n : ∀ n → 0 + n ≡ n            -- 首参数为 0：直接 refl（+ 按第一参数递归）
0+n n = refl

_ : 2 + 3 ≡ 3 + 2                  -- 闭项能算平，「函数上的定律」算不动
_ = refl

_ : 2 + 2 ≡ 1 + 3                  -- 不同写法、同一规范值 4
_ = refl

------------------------------------------------------------------------
-- 11.3 模式匹配证明等式：refl 携带的等式约束（端点塌缩）
------------------------------------------------------------------------

-- cong 的项构造证明：唯一的构造子是 refl，匹配它的一刻 x 和 y 就合并了
cong-case : ∀ {A B : Set} (f : A → B) {x y : A} → x ≡ y → f x ≡ f y
cong-case f refl = refl

-- 同一条证明的 case-of 写法（case_of_ 的家在 Function，不在 Relation.Nullary）
cong-case₂ : ∀ {A B : Set} (f : A → B) {x y : A} (eq : x ≡ y) → f x ≡ f y
cong-case₂ f eq = case eq of λ { refl → refl }

-- with 版（与上两者全同型）
cong-with : ∀ {A B : Set} (f : A → B) {x y : A} (eq : x ≡ y) → f x ≡ f y
cong-with f {x} eq with eq
... | refl = refl

-- 具体值的「所有证明都等于 refl」：端点相同、又无其它构造子，分支自动塌光
uip₁ : (p : 1 ≡ 1) → p ≡ refl
uip₁ refl = refl

-- n + 0 ≡ n：refl 证不动（报错见正文 11.3），必须归纳
n+0 : ∀ n → n + 0 ≡ n
n+0 zero    = refl
n+0 (suc n) = cong suc (n+0 n)

-- 双向合成一个具体推导（trans/cong 都是现成构造子级一行）
_ : suc (2 + 0) + 0 ≡ 3
_ = trans (n+0 (suc (2 + 0))) (cong suc (n+0 2))

-- 二元同余
plus0-preserves-+ : ∀ {a b : ℕ} → a ≡ b → a + 0 ≡ b + 0
plus0-preserves-+ eq = cong₂ _+_ eq refl

-- 点模式：在左端「断言」某参数等于某项，同时从 eq ≡ refl 白捡 x ≡ y
swap-args : ∀ {A : Set} (x y : A) (eq : x ≡ y) → y ≡ x
swap-args x .x refl = refl

------------------------------------------------------------------------
-- 11.4 subst / transport：类型沿着等式走
------------------------------------------------------------------------

-- subst (λ k → Fin k) ：索引沿等式「平移」，11.3 的 refl 模式就是它的证明
cast : ∀ {n m : ℕ} → n ≡ m → Fin n → Fin m
cast eq = subst (λ k → Fin k) eq

cast-id : ∀ {n} (i : Fin n) → cast refl i ≡ i
cast-id i = refl

-- subst 把「一个等式事实」搬进「另一类命题」：这里搬进 (λ k → k + 0 ≡ k)
subst-use : subst (λ k → k + 0 ≡ k) (sym (n+0 2)) refl ≡ refl
subst-use = refl

------------------------------------------------------------------------
-- 11.5 J：基于等式的归纳（stdlib 原语，sym/trans/subst 皆可由它派生）
------------------------------------------------------------------------

-- Relation.Binary.PropositionalEquality.Properties 的源码就是
--   J B refl b = b —— 「对等式归纳」=「把目标里 y 换成 x、eq 换成 refl」
trans-via-J : ∀ {A : Set} {x y z : A} → x ≡ y → y ≡ z → x ≡ z
trans-via-J {x = x} {z = z} p q = J (λ w _ → w ≡ z → x ≡ z) p (λ r → r) q

------------------------------------------------------------------------
-- 11.6 Leibniz 等式：不可区分即相等（加餐）
------------------------------------------------------------------------

-- Leibniz 版「相等」：一切性质可传递。注意它在 Set₁（∀ 量化了谓词族）
Leib : ∀ (A : Set) → A → A → Set₁
Leib A x y = (P : A → Set) → P x → P y

≡⇒Leib : ∀ {A : Set} {x y : A} → x ≡ y → Leib A x y
≡⇒Leib eq P = subst P eq

-- 反向：取「聪明的谓词」P := λ z → x ≡ z 即可从性质造出等式本身
Leib⇒≡ : ∀ {A : Set} {x y : A} → Leib A x y → x ≡ y
Leib⇒≡ {x = x} l = l (λ z → x ≡ z) refl

------------------------------------------------------------------------
-- 11.7 ≠：否定就是「吃假设的函数」
------------------------------------------------------------------------

-- _≢_ {A = A} x y = ¬ x ≡ y = (x ≡ y) → ⊥：构造不出证据，就交出反驳函数
0≢1 : 0 ≢ 1
0≢1 ()                            -- 0 ≡ 1 是「零构造子上的不可能索引」，分支不存在

suc-≠ : ∀ {n : ℕ} → suc n ≢ n     -- 直串方程 suc n = n 过不了 occurs check
suc-≠ ()

≢-sym : 1 ≢ 0                     -- 注意复合方向：f ∘ g 先算 g
≢-sym = 0≢1 ∘ sym

------------------------------------------------------------------------
-- 11.8 rewrite：子句级的改写（2.8 实测没有项级 rewrite … in …，见正文）
------------------------------------------------------------------------

-- rewrite eq：把目标里 eq 左端的出现换成右端，然后 refl 收官
rw-cong : ∀ {x y : ℕ} → x ≡ y → suc x ≡ suc y
rw-cong {x} eq rewrite eq = refl

-- 反向改写：rewrite sym eq
rw-sym : ∀ {x y : ℕ} → x ≡ y → suc y ≡ suc x
rw-sym {x} eq rewrite sym eq = refl

-- rewrite 与「refl 模式」殊途同归：rw-mode 就是 rw-cong 的免 rewrite 版
rw-mode : ∀ {x y : ℕ} → x ≡ y → suc x ≡ suc y
rw-mode refl = refl

-- 拿引理当改写规则用（与 cong suc (n+0 n) 同型，但方向是「把已知等式代入目标」）
rw-lemma : ∀ n → suc (n + 0) ≡ suc n
rw-lemma n rewrite n+0 n = refl
