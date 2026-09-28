-- 第 24 章 · intrinsic 与 extrinsic 证明：二叉查找树实战
-- 主题：布尔函数 / bool 命题化（T、Reflects）/ 纯命题三种「判断」；
--       BinTree 成员判定的 Maybe → Dec 升级；All 谓词与 IsBST（extrinsic）；
--       三分律 Tri/<-cmp；insert 的 extrinsic（算法+镜像证明）与
--       intrinsic（界做索引，±∞ 收口）两版；stdlib 3.0 对照。
-- 所有代码在 Agda 2.9.0 + stdlib 3.0 下真实类型检查通过。

module Ex24_intrinsic_extrinsic where

open import Level using (Level; _⊔_; 0ℓ)
open import Data.Nat using (ℕ; zero; suc; _+_; _≤_; _<_; _≤ᵇ_; z≤n; s≤s)
open import Data.Nat.Properties
  using (_≡?_; _≤?_; _<?_; <-cmp; <-trans; <-asym; ≤-trans; suc-injective)
open import Data.Bool.Base using (Bool; true; false; not; T; if_then_else_)
open import Data.Bool.Properties using (T?)
open import Data.Empty using (⊥; ⊥-elim)
open import Data.Maybe.Base using (Maybe; just; nothing)
open import Data.Product using (Σ; _×_; _,_; proj₁; proj₂)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Unit using (⊤; tt)
open import Relation.Nullary
  using (Dec; yes; no; ¬_; ⌊_⌋; toWitness; toWitnessFalse)
open import Relation.Nullary.Reflects using (Reflects; ofʸ; ofⁿ; invert)
open import Relation.Unary using (Decidable)
open import Relation.Binary
  using (DecidableEquality; Tri; tri<; tri≈; tri>; Trichotomous)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; sym; cong)

------------------------------------------------------------------------
-- 1. 三种「判断」的分野：Bool 函数 / bool 命题化 / 纯命题
------------------------------------------------------------------------

-- (a) 纯布尔函数：只会算，不会讲理（对照 17 章 _≟_ 配方的最内层 _≡ᵇ_）
leqᵇ : ℕ → ℕ → Bool
leqᵇ zero    _       = true
leqᵇ (suc _) zero    = false
leqᵇ (suc m) (suc n) = leqᵇ m n

_ : leqᵇ 3 5 ≡ true
_ = refl

_ : leqᵇ 5 3 ≡ false
_ = refl

-- (b) bool 命题化：T : Bool → Set（Data.Bool.Base），T true = ⊤、T false = ⊥；
--     带证据的判定走 Reflects + T?（17 章老朋友）
_ : T (leqᵇ 3 5)
_ = tt

_ : Dec (T (leqᵇ 5 3))
_ = T? (leqᵇ 5 3)

-- Dec 是 record：does（Bool）+ proof（Reflects）。两头都能取：
3≤5? : Dec (3 ≤ 5)
3≤5? = 3 ≤? 5

_ : ⌊ 3≤5? ⌋ ≡ true            -- Bool 那头：可算
_ = refl

-- 证据那头：proof 字段（构造子 _because_ 拆开即得）
3≤5-proof : Reflects (3 ≤ 5) true
3≤5-proof with 3≤5?
... | yes p = ofʸ p
... | no ¬p = ⊥-elim (¬p (s≤s (s≤s (s≤s z≤n))))

-- (c) 纯命题：直接堆构造子——不可「计算」，但结构里全是信息
3≤5-raw : 3 ≤ 5
3≤5-raw = s≤s (s≤s (s≤s z≤n))

-- 分工：Bool 快而哑；纯命题哑而能讲理；Dec = Bool + Reflects 桥，
-- 本章所有树操作都返回 Dec 版。

------------------------------------------------------------------------
-- 2. 二叉树与「良形」：size 索引版（形状信息进类型的预演）
------------------------------------------------------------------------

-- 教材 BinTree：空树 + 内部结点带值。stdlib 3.0 的 Data.Tree.Binary
-- 长得不一样（leaf 带叶值、没有 empty 构造子），对照见第 10 节。
data BinTree (A : Set) : Set where
  empty  : BinTree A
  branch : BinTree A → A → BinTree A → BinTree A

pattern leaf a = branch empty a empty

-- 良形的第一条路：结点数做成索引——「这棵树有多大」写进类型，
-- 不用计算，更不用「证明计算是对的」。
data SizeTree : ℕ → Set where
  st-empty : SizeTree zero
  st-node  : ∀ {n m} → SizeTree n → ℕ → SizeTree m → SizeTree (suc (n + m))

st₃ : SizeTree 3
st₃ = st-node (st-node st-empty 1 st-empty) 2 (st-node st-empty 3 st-empty)

-- 非空树上的取根：st-empty 分支要求 zero ≡ suc n，索引直接判死——
-- intrinsic 的第一次出手：**不可能的分支根本不必写**（对照 18 章 Vec）。
st-head : ∀ {n} → SizeTree (suc n) → ℕ
st-head (st-node _ x _) = x

------------------------------------------------------------------------
-- 3. 成员命题 _∈_（纯命题版，Maguire 6.10）
------------------------------------------------------------------------

private
  variable
    A : Set
    a b : A
    t : BinTree A
    l r : BinTree A
    P : A → Set

infix 4 _∈_
data _∈_ {A : Set} : A → BinTree A → Set where
  here  : a ∈ branch l a r
  left  : a ∈ l → a ∈ branch l b r
  right : a ∈ r → a ∈ branch l b r

-- 本章示范树（严格 BST：左 < 根 < 右）
tree : BinTree ℕ
tree = branch (branch (leaf 1) 2 (leaf 3)) 4 (leaf 6)

3∈tree : 3 ∈ tree
3∈tree = left (right here)

-- 空树上没有成员：¬(a ∈ empty) 就是 a ∈ empty → ⊥，
-- 构造子一个都匹配不上——荒谬模式一行结案（06 章手艺）。
not-in-empty : (a : A) → ¬ (a ∈ empty)
not-in-empty a ()

------------------------------------------------------------------------
-- 4. 成员判定第一步：Maybe 版 search（extrinsic，负方向没证据）
------------------------------------------------------------------------

-- Maguire 6.7 的 n=5?：just 里塞「找到」的证据；nothing 什么也不说。
search∈ : (A : Set) → (D : (a b : A) → Dec (a ≡ b)) →
          (t : BinTree A) (a : A) → Maybe (a ∈ t)
search∈ A _≟_ empty a = nothing
search∈ A _≟_ (branch l x r) a with x ≟ a
... | yes refl = just here
... | no _ with search∈ A _≟_ l a
...   | just p = just (left p)
...   | nothing with search∈ A _≟_ r a
...   | just p = just (right p)
...   | nothing = nothing

_ : search∈ ℕ _≡?_ tree 4 ≡ just here
_ = refl

_ : search∈ ℕ _≡?_ tree 7 ≡ nothing
_ = refl

-- nothing 不带 ¬(7 ∈ tree)：想拿它去反驳别的命题，手里是空的。
-- 这就是 Maybe 版判断的信息损失（对照第 1 节）。

------------------------------------------------------------------------
-- 5. 成员判定完全体：Dec 版 ∈?（Maguire 6.11）
------------------------------------------------------------------------

∈? : (D : (a b : A) → Dec (a ≡ b)) → (t : BinTree A) → (a : A) → Dec (a ∈ t)
∈? _≟_ empty a = no λ ()
∈? _≟_ (branch l x r) a
  with x ≟ a | ∈? _≟_ l a | ∈? _≟_ r a
... | yes refl | _ | _ = yes here
... | no _ | yes a∈l | _ = yes (left a∈l)
... | no _ | no _ | yes a∈r = yes (right a∈r)
... | no x≢a | no a∉l | no a∉r
  = no λ { here → x≢a refl
         ; (left a∈l) → a∉l a∈l
         ; (right a∈r) → a∉r a∈r }

_ : ∈? _≡?_ tree 3 ≡ yes (left (right here))
_ = refl

_ : ∈? _≡?_ tree 7 ≡ no _
_ = refl

-- no 分支揣着 ¬(a ∈ t)：三个构造子各喂一个局部反证（17 章 any? 同款）。

------------------------------------------------------------------------
-- 6. All 谓词与 IsBST（extrinsic 不变式，Maguire 6.12–6.13）
------------------------------------------------------------------------

data All {A : Set} (P : A → Set) : BinTree A → Set where
  all-empty  : All P empty
  all-branch : All P l → P a → All P r → All P (branch l a r)

all? : (P : A → Set) → (P? : (a : A) → Dec (P a)) →
       (t : BinTree A) → Dec (All P t)
all? P P? empty = yes all-empty
all? P P? (branch l a r) with P? a | all? P P? l | all? P P? r
... | yes pa | yes al | yes ar = yes (all-branch al pa ar)
... | no ¬pa | _ | _ = no λ { (all-branch _ pa _) → ¬pa pa }
... | _ | no ¬al | _ = no λ { (all-branch al _ _) → ¬al al }
... | _ | _ | no ¬ar = no λ { (all-branch _ _ ar) → ¬ar ar }

-- BST：左子树全部 ≺ 根、根 ≺ 右子树全部、子树递归 BST。
-- 它是追加在**任意 BinTree** 上的性质——extrinsic 的标志：
-- 类型允许坏树存在，坏树只是交不出 IsBST 证据。
data IsBST {A : Set} (rel : A → A → Set) : BinTree A → Set where
  bst-empty  : IsBST rel empty
  bst-branch : All (λ v → rel v a) l →
               All (λ v → rel a v) r → IsBST rel l → IsBST rel r →
               IsBST rel (branch l a r)

-- 判定过程（Maguire 6.13）：is-bst? 把「是不是 BST」降成一个 Dec。
is-bst? : (t : BinTree ℕ) → Dec (IsBST _<_ t)
is-bst? empty = yes bst-empty
is-bst? (branch l a r)
  with all? (λ x → x < a) (λ x → x <? a) l | all? (λ x → a < x) (λ x → a <? x) r
       | is-bst? l | is-bst? r
... | yes l<a | yes a<r | yes bl | yes br = yes (bst-branch l<a a<r bl br)
... | no ¬l<a | _ | _ | _ = no λ { (bst-branch l<a _ _ _) → ¬l<a l<a }
... | _ | no ¬a<r | _ | _ = no λ { (bst-branch _ a<r _ _) → ¬a<r a<r }
... | _ | _ | no ¬bl | _ = no λ { (bst-branch _ _ bl _) → ¬bl bl }
... | _ | _ | _ | no ¬br = no λ { (bst-branch _ _ _ br) → ¬br br }

-- 书上说「这种手搭证明太累，交给 C-c C-a」。更干脆：既然有 is-bst?，
-- 直接 toWitness 从计算里钓出证据——这就是 Dec 相对纯命题的实战价值。
tree-is-bst : IsBST _<_ tree
tree-is-bst = toWitness {a? = is-bst? tree} tt

-- 坏树（4 被塞进 2 的左子树）判出 no；反证同样一口钓出：
bad-tree : BinTree ℕ
bad-tree = branch (leaf 4) 2 (leaf 1)

¬bad-bst : ¬ IsBST _<_ bad-tree
¬bad-bst = toWitnessFalse {a? = is-bst? bad-tree} tt

------------------------------------------------------------------------
-- 7. 三分律：intrinsic 比较的产物（Maguire 6.14）
------------------------------------------------------------------------

-- Tri / Trichotomous 直接 import stdlib（Relation.Binary.Definitions，
-- 构造子 tri< / tri≈ / tri> 与书同名）。书的 ℕ 三分证明手打一遍：
refute : ∀ {x y : ℕ} → ¬ x < y → ¬ suc x < suc y
refute x≮y (s≤s x<y) = x≮y x<y

<-cmp′ : (x y : ℕ) → Tri (x < y) (x ≡ y) (y < x)
<-cmp′ zero    zero    = tri≈ (λ ()) refl (λ ())
<-cmp′ zero    (suc y) = tri< (s≤s z≤n) (λ ()) (λ ())
<-cmp′ (suc x) zero    = tri> (λ ()) (λ ()) (s≤s z≤n)
<-cmp′ (suc x) (suc y) with <-cmp′ x y
... | tri< x<y x≉y x≰y =
  tri< (s≤s x<y) (λ { sx≈sy → x≉y (suc-injective sx≈sy) }) (refute x≰y)
... | tri≈ x≮y x≈y x≱y =
  tri≈ (refute x≮y) (cong suc x≈y) (refute x≱y)
... | tri> x≮y x≉y x>y =
  tri> (refute x≮y) (λ { sx≈sy → x≉y (suc-injective sx≈sy) }) (s≤s x>y)

-- 与 stdlib 正品同型——转手即验（读库百遍的 15 章配方）：
check-cmp : Trichotomous _≡_ _<_
check-cmp = <-cmp′

-- 为什么 insert 需要 Trichotomous 而不是三次 Dec：每个 Dec 调用都逼你
-- 处理 yes/no 两枝 + 携带反证；Tri 一次分案三个分支，且「三选一并互斥」
-- 打包在构造子里——反证也随身。

------------------------------------------------------------------------
-- 8. extrinsic 版 insert：算法与保序证明分开写（Maguire 6.15）
------------------------------------------------------------------------

-- 算法本身：类型里没有任何 BST 信息，喂任何 BinTree 都跑
insert : ℕ → BinTree ℕ → BinTree ℕ
insert a empty = leaf a
insert a (branch l x r) with <-cmp a x
... | tri< _ _ _ = branch (insert a l) x r
... | tri≈ _ _ _ = branch l x r
... | tri> _ _ _ = branch l x (insert a r)

-- 引理一：All 保持。证明形状 = 计算形状（同款 with <-cmp，15 章剧本）。
all-insert : (P : ℕ → Set) (a : ℕ) → P a →
             ∀ {t} → All P t → All P (insert a t)
all-insert P a pa {empty} all-empty = all-branch all-empty pa all-empty
all-insert P a pa {branch l x r} (all-branch al px ar) with <-cmp a x
... | tri< a<x _ _ = all-branch (all-insert P a pa al) px ar
... | tri≈ _ a=x _ = all-branch al px ar
... | tri> _ _ x<a = all-branch al px (all-insert P a pa ar)

-- 引理二 + 主定理：BST 保持。extrinsic 的全部负担：一份算法、
-- 两份「形状相同」的镜像证明。
bst-insert : (a : ℕ) {t : BinTree ℕ} → IsBST _<_ t → IsBST _<_ (insert a t)
bst-insert a {empty} bst-empty =
  bst-branch all-empty all-empty bst-empty bst-empty
bst-insert a {branch l x r} (bst-branch l<x x<r bl br) with <-cmp a x
... | tri< a<x _ _ =
  bst-branch (all-insert (λ v → v < x) a a<x l<x) x<r
             (bst-insert a bl) br
... | tri≈ _ a=x _ = bst-branch l<x x<r bl br
... | tri> _ _ x<a =
  bst-branch l<x (all-insert (λ v → x < v) a x<a x<r)
             bl (bst-insert a br)

------------------------------------------------------------------------
-- 9. intrinsic 版 BST：证明进索引（Maguire 6.16–6.17）
------------------------------------------------------------------------

module Intr (A : Set) (rel : A → A → Set)
            (trans : ∀ {x y z} → rel x y → rel y z → rel x z)
            (asym  : ∀ {x y} → rel x y → ¬ rel y x) where

  -- 上下界做成索引：empty 必须附带 lo ≺ hi 的证据；
  -- 空区间上连空树都造不出来——非法状态不可表达。
  data BST : A → A → Set where
    ◃empty : ∀ {lo hi} → rel lo hi → BST lo hi
    ◃node  : ∀ {lo hi} (a : A) → BST lo a → BST a hi → BST lo hi

  -- 界内插入：没有「保序定理」要证——类型正确性由模式匹配免费交付。
  ◃insert : (cmp : Trichotomous {A = A} _≡_ rel) →
            (a : A) → ∀ {lo hi} → rel lo a → rel a hi →
            BST lo hi → BST lo hi
  ◃insert cmp a lo<a a<hi (◃empty _) =
    ◃node a (◃empty lo<a) (◃empty a<hi)
  ◃insert cmp a lo<a a<hi (◃node x l r) with cmp a x
  ... | tri< a<x _ _ = ◃node x (◃insert cmp a lo<a a<x l) r
  ... | tri≈ _ a=x _ = ◃node x l r
  ... | tri> _ _ x<a = ◃node x l (◃insert cmp a x<a a<hi r)

  -- 成员证据直接活在 BST 的索引上：
  data _◃∈_ : ∀ {lo hi} → A → BST lo hi → Set where
    ◃here  : ∀ {lo a hi} (l : BST lo a) (r : BST a hi) →
             a ◃∈ ◃node a l r
    ◃left  : ∀ {lo a hi} {b} (l : BST lo a) (r : BST a hi) →
             b ◃∈ l → b ◃∈ ◃node a l r
    ◃right : ∀ {lo a hi} {b} (l : BST lo a) (r : BST a hi) →
             b ◃∈ r → b ◃∈ ◃node a l r

  -- 两条「区间一致性」引理：intrinsic 的负方向靠它们反驳另一侧子树。
  -- 界化把不变式做进了索引，反证也就顺着索引掉下来。
  ◃lo<hi : ∀ {lo hi} → (t : BST lo hi) → rel lo hi
  ◃lo<hi (◃empty lo<hi) = lo<hi
  ◃lo<hi (◃node x l r) = trans (◃lo<hi l) (◃lo<hi r)

  ◃notBelow : ∀ {lo hi b} → (t : BST lo hi) → b ◃∈ t → ¬ rel b lo
  ◃notBelow (◃empty _)        ()
  ◃notBelow (◃node x l r) (◃here .l .r)   = asym (◃lo<hi l)
  ◃notBelow (◃node x l r) (◃left  .l .r p) = ◃notBelow l p
  ◃notBelow (◃node x l r) (◃right .l .r p) q =
    ◃notBelow r p (trans q (◃lo<hi l))

  ◃notAbove : ∀ {lo hi b} → (t : BST lo hi) → b ◃∈ t → ¬ rel hi b
  ◃notAbove (◃empty _)        ()
  ◃notAbove (◃node x l r) (◃here .l .r)    = asym (◃lo<hi r)
  ◃notAbove (◃node x l r) (◃left  .l .r p) q =
    ◃notAbove l p (trans (◃lo<hi r) q)
  ◃notAbove (◃node x l r) (◃right .l .r p) = ◃notAbove r p

  -- intrinsic 查询返回 ⊎：找到给成员证据，找不到给**完整反证**。
  -- ◃empty 分支 = 不可能分支：b ◃∈ ◃empty p 没有构造子，λ () 直接结案——
  -- 这就是「对不可能分支返回 ⊥」。
  --
  -- 注意「嵌套 with」的坑（见 docs/24 坑位清单）：外层 with (cmp b x) 的
  -- tri< 分支里若再开一个 with 去 match 递归结果，单 `...` 永远咬住**最内层**
  -- with，导致 tri≈/tri> 分支被当成 match ⊎ 的构造子而报
  -- ConstructorPatternInWrongDatatype。标准解法：把「拿到 ⊎ 之后怎么合并」
  -- 提成三个小引理，每层只管一层。
  ◃go< : ∀ {lo x hi b} → rel b x → ¬ b ≡ x →
         (l : BST lo x) (r : BST x hi) →
         (b ◃∈ l ⊎ ¬ (b ◃∈ l)) → b ◃∈ ◃node x l r ⊎ ¬ (b ◃∈ ◃node x l r)
  ◃go< b<x ¬b≈x l r (inj₁ p)  = inj₁ (◃left l r p)
  ◃go< b<x ¬b≈x l r (inj₂ ¬p) =
    inj₂ λ { (◃here  .l .r)   → ¬b≈x refl
           ; (◃left  .l .r q) → ¬p q
           ; (◃right .l .r q) → ◃notBelow r q b<x }

  ◃go≈ : ∀ {lo x hi} (b : A) → b ≡ x →
         (l : BST lo x) (r : BST x hi) → b ◃∈ ◃node x l r ⊎ ¬ (b ◃∈ ◃node x l r)
  ◃go≈ x refl l r = inj₁ (◃here l r)

  ◃go> : ∀ {lo x hi b} → rel x b → ¬ b ≡ x →
         (l : BST lo x) (r : BST x hi) →
         (b ◃∈ r ⊎ ¬ (b ◃∈ r)) → b ◃∈ ◃node x l r ⊎ ¬ (b ◃∈ ◃node x l r)
  ◃go> x<b ¬b≈x l r (inj₁ p)  = inj₁ (◃right l r p)
  ◃go> x<b ¬b≈x l r (inj₂ ¬p) =
    inj₂ λ { (◃here  .l .r)   → ¬b≈x refl
           ; (◃left  .l .r q) → ◃notAbove l q x<b
           ; (◃right .l .r q) → ¬p q }

  ◃search : (cmp : Trichotomous {A = A} _≡_ rel) →
            (b : A) → ∀ {lo hi} → rel lo b → rel b hi →
            (t : BST lo hi) → b ◃∈ t ⊎ ¬ (b ◃∈ t)
  ◃search cmp b lo<b b<hi (◃empty _) = inj₂ λ ()
  ◃search cmp b lo<b b<hi (◃node x l r) with cmp b x
  ... | tri<  b<x ¬b≈x _   = ◃go<  b<x ¬b≈x l r (◃search cmp b lo<b b<x l)
  ... | tri≈  _   b≈x  _   = ◃go≈ b b≈x l r
  ... | tri>  _   ¬b≈x x<b = ◃go> x<b ¬b≈x l r (◃search cmp b x<b b<hi r)

-- ——±∞ 抬升：造 A↑ = A ⊕ {±∞}，让「无界」也有构造子可喂——

data ℕ↑ : Set where
  -∞ +∞ : ℕ↑
  ↑ : ℕ → ℕ↑

data _<∞_ : ℕ↑ → ℕ↑ → Set where
  -∞<↑  : ∀ {x} → -∞ <∞ ↑ x
  ↑<↑   : ∀ {x y} → x < y → ↑ x <∞ ↑ y
  ↑<+∞  : ∀ {x} → ↑ x <∞ +∞
  -∞<+∞ : -∞ <∞ +∞

-- 书称「工作量大但细节无趣」：8 个平凡分支 + 1 个lift 分支。
<∞-cmp : ∀ x y → Tri (x <∞ y) (x ≡ y) (y <∞ x)
<∞-cmp -∞ -∞ = tri≈ (λ ()) refl (λ ())
<∞-cmp -∞ +∞ = tri< -∞<+∞ (λ ()) (λ ())
<∞-cmp -∞ (↑ b) = tri< -∞<↑ (λ ()) (λ { () })
<∞-cmp +∞ -∞ = tri> (λ ()) (λ ()) -∞<+∞
<∞-cmp +∞ +∞ = tri≈ (λ ()) refl (λ ())
<∞-cmp +∞ (↑ b) = tri> (λ { () }) (λ ()) ↑<+∞
<∞-cmp (↑ b) -∞ = tri> (λ ()) (λ ()) -∞<↑
<∞-cmp (↑ b) +∞ = tri< ↑<+∞ (λ ()) (λ { () })
<∞-cmp (↑ x) (↑ y) with <-cmp x y
... | tri< x<y ¬x≡y ¬y<x =
  tri< (↑<↑ x<y) (λ { refl → ¬x≡y refl }) (λ { (↑<↑ y<x) → ¬y<x y<x })
... | tri≈ ¬x<x refl ¬y<y =
  tri≈ (λ { (↑<↑ x<x) → ¬x<x x<x }) refl (λ { (↑<↑ y<y) → ¬y<y y<y })
... | tri> ¬x<y ¬x≡y y<x =
  tri> (λ { (↑<↑ x<y) → ¬x<y x<y }) (λ { refl → ¬x≡y refl }) (↑<↑ y<x)

-- intrinsic 的 Dec 查询还要两条序公理——对 <∞ 都只有几个机械分支：
<∞-asym : ∀ {x y} → x <∞ y → ¬ (y <∞ x)
<∞-asym -∞<↑       ()
<∞-asym (↑<↑ x<y) (↑<↑ y<x) = <-asym x<y y<x
<∞-asym ↑<+∞       ()
<∞-asym -∞<+∞      ()

<∞-trans : ∀ {x y z} → x <∞ y → y <∞ z → x <∞ z
<∞-trans -∞<↑       (↑<↑ y<z) = -∞<↑
<∞-trans -∞<↑       ↑<+∞      = -∞<+∞
<∞-trans (↑<↑ x<y)  (↑<↑ y<z) = ↑<↑ (<-trans x<y y<z)
<∞-trans (↑<↑ x<y)  ↑<+∞      = ↑<+∞
<∞-trans ↑<+∞       ()
<∞-trans -∞<+∞      ()

-- ——±∞ 收口：把界藏回类型外，得到用户友好的 BST——
open Intr ℕ↑ _<∞_ <∞-trans <∞-asym

BST∞ : Set
BST∞ = BST -∞ +∞

∅∞ : BST∞
∅∞ = ◃empty -∞<+∞

insert∞ : ℕ → BST∞ → BST∞
insert∞ a = ◃insert <∞-cmp (↑ a) -∞<↑ ↑<+∞

-- 种一棵 {2,4,6}：三次插入零证明义务（对照第 8 节每次调用都要喂证据）
t∞ : BST∞
t∞ = insert∞ 6 (insert∞ 4 (insert∞ 2 ∅∞))

-- 界证据 -∞<↑ b 与 ↑ b<+∞ 永远现成，所以界化查询可以封装成 Dec 版：
∈∞? : (b : ℕ) (t : BST∞) → Dec ((↑ b) ◃∈ t)
∈∞? b t with ◃search <∞-cmp (↑ b) -∞<↑ ↑<+∞ t
... | inj₁ p = yes p
... | inj₂ ¬p = no ¬p

-- 4 在树里：yes 侧带成员证据（toWitness 从计算里钓出来）。
-- 注意 found4 的类型 (↑ 4) ◃∈ t∞——证据活在**索引**上，
-- 而第 4 节 Maybe 版只给一个光秃秃的 just。
found4 : (↑ 4) ◃∈ t∞
found4 = toWitness {a? = ∈∞? 4 t∞} tt

-- 5 不在树里：计算走 inj₂ 分支——◃empty 上的成员类型没有构造子，
-- 荒谬模式 λ () 当场结案（第 9 节 ◃search 第一行）。
¬5∈t∞ : ¬ ((↑ 5) ◃∈ t∞)
¬5∈t∞ = toWitnessFalse {a? = ∈∞? 5 t∞} tt

-- ——对照总结（正文详论）——
-- extrinsic：算法朴素、证明可搬运、和教科书同步；
--            但每个操作配一份镜像证明，坏树世界照常运行。
-- intrinsic：正确性 = 构造本身，零镜像证明、非法输入不可表达；
--            但类型被不变式绑架：界一变要 cast/±∞ 收口，
--            中途破坏不变式的算法（堆的 sift-up）根本无法照搬。

------------------------------------------------------------------------
-- 10. stdlib 3.0 对照
------------------------------------------------------------------------

-- ① 3.0 没有模块 Data.Tree（2.x 的 rose-tree 之家搬进目录
--    Data/Tree/{Rose,Binary,AVL}）；二叉树正品 = Data.Tree.Binary：
import Data.Tree.Binary as Std

-- std 版 leaf 携带叶值：教材 empty ≡ 值为 ⊤ 的 leaf
toStd : BinTree A → Std.Tree A ⊤
toStd empty = Std.leaf tt
toStd (branch l a r) = Std.node (toStd l) a (toStd r)

-- ② stdlib 的树版 All 是「双谓词」（结点的 P + 叶的 Q）：
import Data.Tree.Binary.Relation.Unary.All as StdAll

toStdAll : ∀ {t} → All P t → StdAll.All P (λ _ → ⊤) (toStd t)
toStdAll all-empty = StdAll.leaf tt
toStdAll (all-branch al pa ar) = StdAll.node (toStdAll al) pa (toStdAll ar)

-- ③ Dec/Reflects：Relation.Nullary.Decidable.Core（17 章钉过）；
--    Tri/Trichotomous：Relation.Binary.Definitions（第 7 节直接 import）；
--    <-cmp：Data.Nat.Properties（check-cmp 验过同型）；
--    T：Data.Bool.Base（本章 15 行）。
-- ④ Data.Tree.AVL（3.0 里以 StrictTotalOrder 参数化的模块）：
--    查找走 Comparator、返回 Maybe——「计算先跑、Properties 里再证」
--    的 stdlib 口味，即 extrinsic 混搭；纯 intrinsic（本章 ◃BST）
--    在 stdlib 只出现在「形状」上（Vec 的长度、AVL/Height 的高度索引）。
import Data.Tree.AVL.Height as AVlh
