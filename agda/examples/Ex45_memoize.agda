------------------------------------------------------------------------
-- 第 45 章配套示例：记忆化即类型优化——Shape 索引的 Trie 与 Memoizes 谓词
--
-- 全章一条主线：动态规划 = 归纳式思考 + 把归纳记忆化；记忆化策略
-- 的形状（Shape：num/beside/inside）决定缓存的数据结构（Trie），
-- 而「这个 Trie 确实在记忆 f」本身做成一个索引类型（Memoizes），
-- 让 Agda 替我们维护正确性。最后 get′ 按需填格，并证明取回的值
-- 就是 f 自己（get′-is-fn），再把整套机器包成用户友好的 get。
--
-- 移植说明（原书 Agda 2.6.3 + stdlib 1.7.2 → 本机 2.9.0 + stdlib 3.0）：
--  * map-dec 已删（1.7.2 起 deprecated，2.0 移除）→ 用 map′（Core 第 203 行）；
--  * Data.Fin 不再 re-export Properties 的 _≟_ → 显式开 Data.Fin.Properties；
--  * lookup∘tabulate 直接用 stdlib 正品（Data.Vec.Properties 第 1334 行）；
--  * 书中的 prop-setoid Has n Elements 机器（8.6 节）在 23 章已建，
--    这里用命题相等版 _Has_ 复刻：shape-fin 给出 Ix sh ≅ Fin ∣ sh ∣。
--
-- 类型检查：cd agda && ./build.sh Ex45_memoize
------------------------------------------------------------------------

module Ex45_memoize where

open import Level using (Level; _⊔_)
open import Function.Base using (id; _∘_)
open import Data.Nat using (ℕ; zero; suc; _+_; _*_; _^_)
open import Data.Fin using (Fin; toℕ)
open import Data.Fin.Properties using (_≡?_)
open import Data.Vec using (Vec; []; _∷_; lookup; tabulate)
open import Data.Vec.Properties using (lookup∘tabulate)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Product using (Σ; _×_; _,_; proj₁; proj₂; uncurry)
open import Relation.Nullary using (Dec; yes; no)
open import Relation.Nullary.Decidable using (map′)
open import Relation.Binary.PropositionalEquality
  using (_≡_; _≗_; refl; sym; trans; cong; cong₂; module ≡-Reasoning)

-- 23 章同款：函数外延（stdlib 3.0 不提供 funExt，实测全库零命中）。
postulate
  funExt : ∀ {a b : Level} {A : Set a} {B : A → Set b}
           {f g : (x : A) → B x} → ((x : A) → f x ≡ g x) → f ≡ g

-- 23 章同款：命题相等版同构记录（书 8.4 的 ≅-prop：cong 字段全免）。
record _≅_ {a b : Level} (A : Set a) (B : Set b) : Set (a ⊔ b) where
  field
    to      : A → B
    from    : B → A
    from∘to : ∀ x → from (to x) ≡ x
    to∘from : ∀ y → to (from y) ≡ y
infix 0 _≅_
open _≅_ public

≅-refl : ∀ {a : Level} {A : Set a} → A ≅ A
≅-refl = record { to = id; from = id; from∘to = λ _ → refl; to∘from = λ _ → refl }

≅-sym : ∀ {a b : Level} {A : Set a} {B : Set b} → A ≅ B → B ≅ A
≅-sym i = record
  { to      = from i
  ; from    = to i
  ; from∘to = to∘from i
  ; to∘from = from∘to i
  }

≅-trans : ∀ {a b c : Level} {A : Set a} {B : Set b} {C : Set c} →
          A ≅ B → B ≅ C → A ≅ C
≅-trans i j = record
  { to      = to j ∘ to i
  ; from    = from i ∘ from j
  ; from∘to = λ x → trans (cong (from i) (from∘to j (to i x))) (from∘to i x)
  ; to∘from = λ y → trans (cong (to j) (to∘from i (from j y))) (to∘from j y)
  }

-- 23 章同款：「A 有 n 个元素」= A ≅ Fin n。
infix 4 _Has_
_Has_ : ∀ {a : Level} → Set a → ℕ → Set a
A Has n = A ≅ Fin n

-- 和/积各保「Has」——正逆函数就是 23 章用过的 join/splitAt、combine/remQuot。
⊎-has : ∀ {m n} {A B : Set} → A Has m → B Has n → (A ⊎ B) Has (m + n)
⊎-has {m} {n} i j = record
  { to      = to′
  ; from    = from′
  ; from∘to = ft
  ; to∘from = tf
  }
  where
  open import Data.Fin using (join; splitAt)
  open import Data.Fin.Properties using (splitAt-join; join-splitAt)
  open import Data.Sum using () renaming (map to Smap)
  to′ : _ → Fin (m + n)
  to′ (inj₁ x) = join m n (inj₁ (to i x))
  to′ (inj₂ y) = join m n (inj₂ (to j y))
  from′ : Fin (m + n) → _
  from′ f with splitAt m f
  ... | inj₁ x = inj₁ (from i x)
  ... | inj₂ y = inj₂ (from j y)
  ft : ∀ s → from′ (to′ s) ≡ s
  ft (inj₁ x)
    rewrite splitAt-join m n (inj₁ (to i x)) = cong inj₁ (from∘to i x)
  ft (inj₂ y)
    rewrite splitAt-join m n (inj₂ (to j y)) = cong inj₂ (from∘to j y)
  -- to′ 就是「map 进 join」——对判别和逐分支 refl。
  to′-eq : ∀ s → to′ s ≡ join m n (Smap (to i) (to j) s)
  to′-eq (inj₁ x) = refl
  to′-eq (inj₂ y) = refl
  -- from′ 在 join 上可算：splitAt-join 把内层 with 喂成构造子，to∘from 收口。
  -- 两侧类型不同（A ⊎ B 对 Fin m ⊎ Fin n），所以是 Smap (from i) (from j) s。
  from′∘join : ∀ s → from′ (join m n s) ≡ Smap (from i) (from j) s
  from′∘join (inj₁ x) rewrite splitAt-join m n (inj₁ x) = refl
  from′∘join (inj₂ y) rewrite splitAt-join m n (inj₂ y) = refl
  -- 往返：先借 join-splitAt 把 f 改写成 join m n (splitAt m f)（两侧同 cong），
  -- 再逐段掐掉 from′∘join / to′-eq / join-splitAt。全程不碰「stuck 的 from′ f」。
  -- map 的往返：to∘from / to∘from 逐分支掐掉。
  smap-roundtrip : ∀ s → Smap (to i) (to j) (Smap (from i) (from j) s) ≡ s
  smap-roundtrip (inj₁ x) = cong inj₁ (to∘from i x)
  smap-roundtrip (inj₂ y) = cong inj₂ (to∘from j y)
  tf : ∀ f → to′ (from′ f) ≡ f
  tf f = begin
    to′ (from′ f)                        ≡⟨ cong (to′ ∘ from′) (sym (join-splitAt m n f)) ⟩
    to′ (from′ (join m n (splitAt m f))) ≡⟨ cong to′ (from′∘join (splitAt m f)) ⟩
    to′ (Smap (from i) (from j) (splitAt m f))
      ≡⟨ to′-eq (Smap (from i) (from j) (splitAt m f)) ⟩
    join m n (Smap (to i) (to j) (Smap (from i) (from j) (splitAt m f)))
      ≡⟨ cong (join m n) (smap-roundtrip (splitAt m f)) ⟩
    join m n (splitAt m f)               ≡⟨ join-splitAt m n f ⟩
    f                                    ∎
    where open ≡-Reasoning

×-has : ∀ {m n} {A B : Set} → A Has m → B Has n → (A × B) Has (m * n)
×-has {m} {n} i j = record
  { to      = to′
  ; from    = from′
  ; from∘to = ft
  ; to∘from = tf
  }
  where
  open import Data.Fin using (combine; remQuot)
  open import Data.Fin.Properties using (remQuot-combine; combine-remQuot)
  -- 写成投影版（而非对 (x , y) 模式匹配）：to′ (from′ f) 里 from′ f 是中立项，
  -- 但 proj₁ (from′ f) 对「定义上就是二元组」的 from′ f 照样归约（11 章 stuckness
  -- 的正面用法）——整条 tf 链全程无 stuck 项。
  to′ : _ → Fin (m * n)
  to′ p = combine (to i (proj₁ p)) (to j (proj₂ p))
  from′ : Fin (m * n) → _
  from′ f = from i (proj₁ (remQuot {m} n f)) , from j (proj₂ (remQuot {m} n f))
  -- from′ 在 combine 上可算：remQuot-combine 是「关于 remQuot (combine a b)」的
  -- 等式，cong 把它推进 from′ 的两个投影（rewrite 找不到藏在 remQuot 复合里的
  -- 子项——RewritesNothing 实测坑，见正文）。
  from′∘combine : ∀ a b → from′ (combine a b) ≡ (from i a , from j b)
  from′∘combine a b
    = cong (λ p → from i (proj₁ p) , from j (proj₂ p)) (remQuot-combine a b)
  ft : ∀ p → from′ (to′ p) ≡ p
  ft (x , y) = trans (from′∘combine (to i x) (to j y))
                   (cong₂ _,_ (from∘to i x) (from∘to j y))
  -- 坑（23 章实录）：combine 的两个隐参 {m} {n} 与 remQuot 的 {m} 不同名，
  -- 这里必须 {m = m} 手工钉住，否则 UnsolvedMetaVariables。
  -- 往返：from′ f 的两个投影各掐一次 to∘from，正好折成 uncurry combine (remQuot n f)，
  -- 再由 combine-remQuot 收口。
  tf : ∀ f → to′ (from′ f) ≡ f
  tf f = begin
    to′ (from′ f)                 ≡⟨ refl ⟩
    combine (to i (from i (proj₁ (remQuot {m} n f))))
            (to j (from j (proj₂ (remQuot {m} n f))))
                                  ≡⟨ cong₂ (λ a b → combine a b)
                                           (to∘from i (proj₁ (remQuot {m} n f)))
                                           (to∘from j (proj₂ (remQuot {m} n f))) ⟩
    uncurry combine (remQuot {m} n f) ≡⟨ combine-remQuot {n = m} n f ⟩
    f                             ∎
    where open ≡-Reasoning

-- 23 章 23.7 只证了 Bool→A ≅ A×A（2^1 的特例）；一般定律 m^n 在这里补齐：
-- (Fin n → Fin m) 恰有 m^n 个元素——函数空间是指数运算，这正是记忆化的
-- 理论地基：定义域 ≅ Fin n 的函数 = 长度 n 的查找表（23.3 vec-iso）。
⇒-fin : ∀ m n → (Fin n → Fin m) Has (m ^ n)
-- 底：m^0 = 1，Fin 0 → Fin m 是「空域函数」= Fin 1 的唯一元素。
-- （Fin 1 只有一个构造子值：Data.Fin.zero——ℕ 的 zero 不在 Fin 里，
--   两个 zero 同名，这里必须限定 Data.Fin。）
⇒-fin m zero = record
  { to      = λ _ → Data.Fin.zero
  ; from    = λ _ ()
  ; from∘to = λ f → funExt λ ()
  ; to∘from = λ { Data.Fin.zero → refl }   -- Fin 1 只有一个元素：pattern 穷尽
  }
  where open import Data.Nat using (_^_)
⇒-fin m (suc n) = record
  { to      = to′
  ; from    = from′
  ; from∘to = ft
  ; to∘from = tf
  }
  where
  open import Data.Nat using (_^_)
  open import Data.Fin using (combine; remQuot)
  open import Data.Fin.Properties using (remQuot-combine; combine-remQuot)
  -- 指数递推 m^(n+1) = m · m^n 的「查表」实现：
  -- 函数 ⇔ （首项 , 尾部函数），往返全是 23 章 vec-cons≅ 的 Fin 版。
  -- （Fin 的构造子就叫 zero/suc，fsuc 是 23 章自己的改名，别混。）
  to′ : (Fin (suc n) → Fin m) → Fin (m ^ suc n)
  to′ f = combine (f Data.Fin.zero) (to (⇒-fin m n) (f ∘ Data.Fin.suc))
  from′ : Fin (m ^ suc n) → (Fin (suc n) → Fin m)
  from′ p Data.Fin.zero    = proj₁ (remQuot {m} (m ^ n) p)
  from′ p (Data.Fin.suc i) = from (⇒-fin m n) (proj₂ (remQuot {m} (m ^ n) p)) i
  -- from′ 在 combine 上可算（同 ×-has 的套路：cong 推进，rewrite 找不到
  -- 藏在 remQuot 复合里的子项）。逐分支给出「首项 , 尾部函数」的函数式。
  from′∘combine : ∀ a b → from′ (combine a b) ≡
    λ { Data.Fin.zero → a
      ; (Data.Fin.suc i) → from (⇒-fin m n) b i
      }
  from′∘combine a b = funExt λ
    { Data.Fin.zero → cong proj₁ (remQuot-combine a b)
    ; (Data.Fin.suc i) → cong (λ q → from (⇒-fin m n) (proj₂ q) i) (remQuot-combine a b)
    }
  ft : ∀ f → from′ (to′ f) ≡ f
  ft f = trans
    (from′∘combine (f Data.Fin.zero) (to (⇒-fin m n) (f ∘ Data.Fin.suc)))
    (funExt λ { Data.Fin.zero → refl
              ; (Data.Fin.suc i) → cong (λ g → g i)
                  (from∘to (⇒-fin m n) (f ∘ Data.Fin.suc))
              })
  -- 坑（2.9.0 实测）：remQuot 的隐参 {m} 不钉死时，Agda 为解
  -- m' * m ^ n ≟ m ^ suc n 去反转 _*_，50 层反转深度耗尽（InversionDepthReached
  -- 警告 + 元变量悬空）。两处都钉 {m}。
  tf : ∀ p → to′ (from′ p) ≡ p
  tf p = begin
    to′ (from′ p)
      ≡⟨ refl ⟩   -- from′ p zero 归约出 proj₁；from′ p ∘ suc 经 η 等于
                  -- from rec (proj₂ …)，于是 to rec 包上去可被 to∘from 掐掉
    combine (proj₁ (remQuot {m} (m ^ n) p))
            (to (⇒-fin m n) (from (⇒-fin m n) (proj₂ (remQuot {m} (m ^ n) p))))
      ≡⟨ cong (combine (proj₁ (remQuot {m} (m ^ n) p)))
               (to∘from (⇒-fin m n) (proj₂ (remQuot {m} (m ^ n) p))) ⟩
    uncurry combine (remQuot {m} (m ^ n) p)
      ≡⟨ combine-remQuot {n = m} (m ^ n) p ⟩
    p ∎
    where open ≡-Reasoning

------------------------------------------------------------------------
-- 45.1 形状即策略：Shape 决定缓存长什么样
------------------------------------------------------------------------

-- 记忆化策略只有三种积木：定长表、并置、嵌套。
--  * num n     —— 一张 n 格表（整表缓存：碰一格就填满全表）；
--  * beside    —— 两个缓存并排（键是左/右的判别和）；
--  * inside    —— 缓存的缓存（逐格缓存：指针先空着，用到才填）。
data Shape : Set where
  num    : ℕ → Shape
  beside : Shape → Shape → Shape
  inside : Shape → Shape → Shape

-- 三种积木已经能描述任意「trie」：二叉树 = 每层并置两份。
bintrie : ℕ → Shape
bintrie zero    = num 1
bintrie (suc n) = beside (bintrie n) (bintrie n)

-- 书上随手捏的怪形状（图 9.4）：beside (beside (num 3) (inside (num 2) (num 1)))
--                                  (inside (num 3) (num 1))
weird : Shape
weird = beside (beside (num 3) (inside (num 2) (num 1)))
               (inside (num 3) (num 1))

------------------------------------------------------------------------
-- 45.2 按图施工：Trie / 索引类型 Ix / 基数 ∣_∣
------------------------------------------------------------------------

private variable
  ℓ : Level
  B : Set ℓ
  sh m n : Shape

-- Trie 由 Shape 索引：形状进类型，缓存的形状错误在编译期就拦住。
-- nest 的递归参数是 Trie (Trie B n) m——非规则递归（参数自己变了），
-- 这正是 inside 的语义：不再缓存值，而是缓存「值的缓存」。
data Trie (B : Set ℓ) : Shape → Set ℓ where
  empty : {sh : Shape} → Trie B sh
  table : {n : ℕ} → Vec B n → Trie B (num n)
  both  : {m n : Shape} → Trie B m → Trie B n → Trie B (beside m n)
  nest  : {m n : Shape} → Trie (Trie B n) m → Trie B (inside m n)

-- 每个形状配套一个查找键类型：表用 Fin，并置用 ⊎（先判左右），
-- 嵌套用 ×（外层键 + 内层键）。
Ix : Shape → Set
Ix (num n)       = Fin n
Ix (beside m n)  = Ix m ⊎ Ix n
Ix (inside m n)  = Ix m × Ix n

-- 形状的基数（键的个数）：加法给 beside，乘法给 inside——
-- 类型代数（23 章）的 0/1/+/× 在这里变成缓存大小的算术。
∣_∣ : Shape → ℕ
∣ num m ∣      = m
∣ beside m n ∣ = ∣ m ∣ + ∣ n ∣
∣ inside m n ∣ = ∣ m ∣ * ∣ n ∣

-- 底：Fin 0 没有元素（构造子都带 ℕ.suc 索引），荒谬模式收全部往返律。
fin0-has0 : Fin 0 Has 0
fin0-has0 = record
  { to = λ ()
  ; from = λ ()
  ; from∘to = λ ()
  ; to∘from = λ () }

-- 每个形状的键类型恰好有 ∣ sh ∣ 个元素：归纳直接组装 fin0-has0、
-- ⊎-has、×-has；num (suc n) 是自同构，≅-refl 一行收工。
shape-fin : (sh : Shape) → Ix sh Has ∣ sh ∣
shape-fin (num zero)    = fin0-has0
shape-fin (num (suc n)) = ≅-refl
shape-fin (beside m n)  = ⊎-has (shape-fin m) (shape-fin n)
shape-fin (inside m n)  = ×-has (shape-fin m) (shape-fin n)

-- 键相等可判定：借道 shape-fin 把键搬进 Fin，用 stdlib 的 _≟_，
-- 再 map′ 搬回来。stdlib 3.0 里 map-dec 已删（deprecated 于 1.7.2），
-- 正主是 Relation.Nullary.Decidable 的 map′（Core 第 203 行）。
Ix-dec : {sh : Shape} → (ix₁ ix₂ : Ix sh) → Dec (ix₁ ≡ ix₂)
Ix-dec {sh = sh} ix₁ ix₂
  = let s = shape-fin sh
    in map′
       (λ toix₁≡toix₂ → begin
          ix₁                ≡⟨ sym (from∘to s ix₁) ⟩
          from s (to s ix₁)  ≡⟨ cong (from s) toix₁≡toix₂ ⟩
          from s (to s ix₂)  ≡⟨ from∘to s ix₂ ⟩
          ix₂                ∎)
       (cong (to s))
       (to s ix₁ ≡? to s ix₂)
  where open ≡-Reasoning

-- Σ 的第一个分量常能由第二个推出来（B a 里藏着 a），
-- 这个构造子让 Agda 自己补：-, b = a , b。
-,_ : {A : Set ℓ} {a : A} {P : A → Set ℓ} → P a → Σ A P
-,_ {a = a} b = a , b

------------------------------------------------------------------------
-- 45.3 正确性进类型：Memoizes 谓词
------------------------------------------------------------------------

-- 同时定义（mutual）：MemoTrie f = 「一个 Trie」×「它确实在记忆 f 的证明」。
-- Memoizes 的索引多达三个（f、sh 藏在 Ix sh → B 里、Trie 值），
-- 不能改成参数：每个构造子对形状的要求不同（num 要 Vec、beside 要两个子 Trie……）。
mutual
  MemoTrie : {B : Set ℓ} {sh : Shape} → (Ix sh → B) → Set ℓ
  MemoTrie {B = B} {sh = sh} f = Σ (Trie B sh) (Memoizes f)

  data Memoizes {B : Set ℓ} : {sh : Shape} → (f : Ix sh → B) → Trie B sh → Set ℓ where
    -- 空 Trie 对任何函数都「空泛地」成立（vacuously true，14 章 ⊥ 的老朋友）。
    emptyM : {sh : Shape} {f : Ix sh → B} → Memoizes f empty
    -- 表正确 ⇔ 它就是 tabulate f（逐格采样 f 造出来的表）。
    tableM : {n : ℕ} {f : Ix (num n) → B} →
             Memoizes f (table (tabulate f))
    -- 并置正确 ⇔ 左右分别记忆 f 的 inj₁/inj₂ 两半。
    bothM  : {m n : Shape} {f : Ix (beside m n) → B} {t₁ : Trie B m} {t₂ : Trie B n} →
             Memoizes (f ∘ inj₁) t₁ →
             Memoizes (f ∘ inj₂) t₂ →
             Memoizes f (both t₁ t₂)
    -- 嵌套正确 ⇔ 每个外层键都对应一个正确记忆「f 固定外层键」的子 Trie。
    -- 注意 to-trie 把「逐键给子 Trie + 证明」的函数整体折成 nest。
    nestM  : {m n : Shape} {f : Ix (inside m n) → B}
             (subf : (ix : Ix m) → Σ (Trie B n) (Memoizes (f ∘ (ix ,_)))) →
             Memoizes f (nest (proj₁ (to-trie {f = f} subf)))

  -- to-trie：把「逐键的 MemoTrie」折成「一棵嵌套 Trie + 它的证明」。
  -- 类型已经说清一切：num 情形整体是一张表（tableM）；
  -- beside 情形递归折左右再 bothM；inside 情形继续往深处折。
  -- 坑（2.9.0 实测）：签名里写 MemoTrie 别名会触发 mutual 泛化的 genTel 推断失败，
  -- 必须内联展开成 Σ (Trie B n) (Memoizes …)（原书 2.6.3 无此问题）。
  to-trie
    : {B : Set ℓ} {m n : Shape} {f : Ix (inside m n) → B}
    → (subf : (ix : Ix m) → Σ (Trie B n) (Memoizes (f ∘ (ix ,_))))
    → Σ (Trie (Trie B n) m) (Memoizes (proj₁ ∘ subf))
  to-trie {m = num _}    _    = -, tableM
  to-trie {m = beside _ _} subf
    with proj₂ (to-trie (subf ∘ inj₁)) , proj₂ (to-trie (subf ∘ inj₂))
  ... | mt₁ , mt₂ = -, bothM mt₁ mt₂
  to-trie {m = inside _ _} subf = -, nestM (λ i → to-trie λ j → subf (i , j))

------------------------------------------------------------------------
-- 45.4 类型即规范：Agda 替我们合成唯一的 Trie
------------------------------------------------------------------------

-- 演示函数：把键翻译成自然数（shape-fin 走一圈再 toℕ）。
dummy : (sh : Shape) → Ix sh → ℕ
dummy sh ix = toℕ (to (shape-fin sh) ix)

-- 对 weird 形状给一份「部分填充」的记忆化证明：左左填满、左右空、
-- 右侧三个子表只填第二个。类型精确到——能填出这个证明的 Trie 只有一棵。
_ : Memoizes
    (dummy weird)
    (both (both (table (0 ∷ 1 ∷ 2 ∷ [])) empty)
          (nest (table (empty ∷ table (6 ∷ []) ∷ empty ∷ []))))
_ = bothM (bothM tableM emptyM)
          (nestM λ { Data.Fin.zero → -, emptyM
                   ; (Data.Fin.suc Data.Fin.zero) → -, tableM
                   ; (Data.Fin.suc (Data.Fin.suc Data.Fin.zero)) → -, emptyM
                   })

-- 反方向更惊人：只写证明、把 Trie 挖空留给 Agda——
--
--   _ : Memoizes (dummy weird) {!!}
--   _ = bothM (bothM tableM emptyM)
--             (nestM λ { zero → -, emptyM ; (suc zero) → -, tableM ; ... })
--
-- 在编辑器里对 {!!} 按 C-c C-s（Solve），Agda 合成的必然是上面那一棵——
-- Memoizes 的索引精确到完全约束缓存内容。源码里不留洞（build.sh 要求零洞），
-- 上面显式写出的那棵就是 Solve 的唯一产物。

------------------------------------------------------------------------
-- 45.5 按需填充：replace 与 get′
------------------------------------------------------------------------

-- 替换 nestM 的 subf 里的一支：键相等就换新证明，否则查旧表。
-- Ix-dec 在这里第一次上岗（17/24 章的 Dec 剧本换布景）。
replace
  : {B : Set ℓ} {m n : Shape} {f : Ix (inside m n) → B}
  → {fst : Trie B n}
  → (x : Ix m)
  → Memoizes (f ∘ (x ,_)) fst
  → ((ix : Ix m) → MemoTrie (f ∘ (ix ,_)))
  → MemoTrie f
replace {f = f} x sub-mem subf
  = -, nestM (λ ix →
      case Ix-dec ix x of λ
        { (yes refl) → -, sub-mem
        ; (no _)     → subf ix
        })
  where -- case_of_ 必须层级多态：分支返回的 MemoTrie 活在 Set ℓ，
        -- 而 Agda.Builtin 自带的 case_of_ 只收 Set₀（2.9 实测坑）。
        case_of_ : {a b : Level} {A : Set a} {B : Set b} → A → (A → B) → B
        case x of f = f x

-- 主事件：在「带证明的 Trie」里查键。
-- 命中就返回值；未命中就**只**造出需要的那一格（惰性填充），
-- 顺手返回填充后的新 Trie（Agda 无 mutation，用返回新值模拟更新）。
get′ : {B : Set ℓ} {sh : Shape} {f : Ix sh → B} {t : Trie B sh} →
       Memoizes f t → (ix : Ix sh) → B × MemoTrie f
-- 空表：整表采样一次（全章唯一调用 f 的地方），取出要的那格。
get′ {sh = num x} {f = f} emptyM a =
  let t = tabulate f
  in lookup t a , table t , tableM
-- 空并置：递归一侧，另一侧留 empty。
get′ {sh = beside m n} emptyM (inj₁ x)
  with get′ emptyM x
... | b , t₁ , memo = b , both t₁ empty , bothM memo emptyM
get′ {sh = beside m n} emptyM (inj₂ y)
  with get′ emptyM y
... | b , t₂ , memo = b , both empty t₂ , bothM emptyM memo
-- 空嵌套：递归内层，再用 replace 装回外层的 x 支。
get′ {sh = inside m n} {f = f} emptyM (x , y)
  with get′ {f = f ∘ (x ,_)} emptyM y
... | b , _ , sub-mem = b , replace x sub-mem (λ ix → -, emptyM)
-- 已有表：直接查（f 早被采样过了）。
get′ {sh = num _} {t = table t} tableM a = lookup t a , table t , tableM
-- 已有并置：递归对应一侧，另一侧原样保留。
get′ {sh = beside m n} (bothM l r) (inj₁ x)
  with get′ l x
... | b , t₁ , memo = b , both t₁ _ , bothM memo r
get′ {sh = beside m n} (bothM l r) (inj₂ y)
  with get′ r y
... | b , t₂ , memo = b , both _ t₂ , bothM l memo
-- 已有嵌套：取出 x 支的子证明，递归，再 replace 装回。
-- （书上脚注：这里忘了 replace 会直接导致类型检查不过——
--   类型逼着你在更新后维持「全树都被记忆」的全局不变式。）
get′ {sh = inside m n} (nestM subf) (x , y)
  with subf x
... | _ , sub-mem
  with get′ sub-mem y
... | b , _ , _ = b , replace x sub-mem subf

-- 正确性：get′ 取回的值逐点等于 f 自己（_≗_ 记法 = 逐点相等，20 章）。
-- 对证明项归纳：每个构造子一条，全部一行——表情形用 stdlib 的
-- lookup∘tabulate（Data.Vec.Properties 第 1334 行，原书手抄版同款）。
get′-is-fn : {B : Set ℓ} {sh : Shape} {f : Ix sh → B} {t : Trie B sh} →
             (mt : Memoizes f t) → (λ ix → proj₁ (get′ mt ix)) ≗ f
get′-is-fn {sh = num _} emptyM x = lookup∘tabulate _ x
get′-is-fn {sh = beside _ _} emptyM (inj₁ x) = get′-is-fn emptyM x
get′-is-fn {sh = beside _ _} emptyM (inj₂ y) = get′-is-fn emptyM y
get′-is-fn {sh = inside _ _} emptyM (x , y) = get′-is-fn emptyM y
get′-is-fn {sh = num _} tableM x = lookup∘tabulate _ x
get′-is-fn {sh = beside _ _} (bothM t₁ _) (inj₁ x) = get′-is-fn t₁ x
get′-is-fn {sh = beside _ _} (bothM _ t₂) (inj₂ y) = get′-is-fn t₂ y
get′-is-fn {sh = inside _ _} (nestM subf) (x , y) = get′-is-fn (proj₂ (subf x)) y

------------------------------------------------------------------------
-- 45.6 打包出厂：对用户隐藏 Ix
------------------------------------------------------------------------

-- 用户手里是 A → B，不是 Ix sh → B。给一座桥：A ≅ Ix sh（由基数匹配
-- 经 fin-iso 式的 ≅-trans 搭出），f 就改写成 Ix 上的 f′。
module Memoizer {A : Set} {B : Set ℓ} (sh : Shape)
                (f : A → B)
                (sized : A Has ∣ sh ∣) where

  private
    A≅Ix : A ≅ Ix sh
    A≅Ix = ≅-trans sized (≅-sym (shape-fin sh))

    f′ : Ix sh → B
    f′ = f ∘ from A≅Ix

  Memoized : Set ℓ
  Memoized = MemoTrie f′

  -- 出厂接口：喂旧缓存 + 一个 A，吐（值 , 新缓存）。内部走 get′。
  get : Memoized → A → B × Memoized
  get (_ , memo) a = get′ memo (to A≅Ix a)

  -- 出厂正确性：get 取回的值就是 f a。
  -- get′-is-fn 给的是 f′ (to A≅Ix a) = f (from A≅Ix (to A≅Ix a))，
  -- 再掐一次 from∘to 的往返（cong f 保 ≡）。
  get-is-fn : (mt : Memoized) → (a : A) → proj₁ (get mt a) ≡ f a
  get-is-fn (_ , memo) a = trans (get′-is-fn memo (to A≅Ix a))
                               (cong f (from∘to A≅Ix a))

------------------------------------------------------------------------
-- 45.7 跑一遍：斐波那契的「按表记忆」实例
------------------------------------------------------------------------

-- 形状：num 45 —— 一张 45 格表（整表缓存策略）。
fibo-shape : Shape
fibo-shape = num 45

-- 斐波那契：A = Fin 45（定义域恰好 45 个值），B = ℕ。
-- （Fin 的构造子限定 Data.Fin.zero/suc——ℕ 的 zero/suc 同名常撞，本章节节踩。）
-- TERMINATING  pragma 的理由：inject₁ 保 toℕ 值不变（Data.Fin.Properties
-- 的 toℕ-inject₁），递归的键严格变小，但 Agda 的终止检查器看不穿 inject₁
-- 是「结构子项的抬界」——实测 TerminationIssue，只能手动放行（正文 45.7 实录）。
{-# TERMINATING #-}
fiboIx : Fin 45 → ℕ
fiboIx Data.Fin.zero = 0
fiboIx (Data.Fin.suc Data.Fin.zero) = 1
-- 坑：i : Fin 43，而 fiboIx 要 Fin 45——inject₁ 把上界抬两位（stdlib 2.0 起
-- inject+ 改名 _↑ˡ_ 且带弃用警告，inject₁ 是「抬一阶」的正主）。
fiboIx (Data.Fin.suc (Data.Fin.suc i)) =
  fiboIx (inject₁ (Data.Fin.suc i)) + fiboIx (inject₁ (inject₁ i))
  where open import Data.Fin using (inject₁)

open import Data.Fin using (inject≤)
open import Data.Nat using (_≤_; z≤n; s≤s)

-- 从 ℕ 造 Fin 45 的键：# n : Fin (suc n)，inject≤ 抬到 Fin 45。
-- 抬界要 suc n ≤ 45 的证明——25 章的实例搜索老手艺：z≤n/s≤s 注册成实例，
-- Agda 逐层 unwrap 自动构造（10 层、31 层都照拆，实测秒回）。
private instance
  find-z≤n : ∀ {n} → 0 ≤ n
  find-z≤n = z≤n
  find-s≤s : ∀ {m n} ⦃ m≤n : m ≤ n ⦄ → suc m ≤ suc n
  find-s≤s ⦃ m≤n ⦄ = s≤s m≤n

key : (n : ℕ) ⦃ pf : suc n ≤ 45 ⦄ → Fin 45
-- fromℕ n : Fin (suc n) 无证明负担；inject≤ 抬到 Fin 45。
-- 两个坑（2.9.0 实测）：① inject≤ 的界证明是 dotted（irrelevant），
-- 不会反向把 m 钉成 suc n——隐参 {m = suc n} 必须手写；
-- ② #_ 依赖 True (n <? m) 可计算，对变量 n 是 stuck 项，根本不能用。
key n ⦃ pf ⦄ = inject≤ {m = suc n} (fromℕ n) pf
  where open import Data.Fin using (fromℕ)

fibo : (n : ℕ) ⦃ pf : suc n ≤ 45 ⦄ → ℕ
fibo n ⦃ pf ⦄ = fiboIx (key n ⦃ pf ⦄)

-- Fin 45 恰好有 45 个元素：shape-fin 直接给。
fibo-sized : Fin 45 Has ∣ fibo-shape ∣
fibo-sized = shape-fin fibo-shape

-- 出厂机器（模块实例化：fibo-shape + fiboIx + fibo-sized）。
open module FibMemo = Memoizer fibo-shape fiboIx fibo-sized

-- 空缓存起跑，连查三键。类型层面已经保证：每次 get 返回的值
-- 都 ≡ fiboIx 对应键（get-is-fn），且新缓存仍是 Memoized。
run : ℕ × Memoized → ℕ
run (b0 , m0) =
  let m1 = proj₂ (get m0 (key 10))
      m2 = proj₂ (get m1 (key 20))
      b3 , _ = get m2 (key 30)
  in b0 + b3

-- 终检：从空缓存出发连查四键，返回值与「直接算 fibo」逐点相等（refl 即终审）。
_ : run (get (empty , emptyM) (key 7)) ≡ fibo 7 + fibo 30
_ = refl
