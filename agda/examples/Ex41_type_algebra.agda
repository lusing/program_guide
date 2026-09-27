------------------------------------------------------------------------
-- 第 41 章配套示例：类型的代数——ADT 作为半环
--
-- ≅（类型同构记录）与它上的「0 1 + ×」半环定律；有限类型与基数
-- （Fin 的 join/splitAt、combine/remQuot，全部对接 stdlib 正品定律）；
-- Vec 作为特征函数（Vec A n ≅ Fin n → A，书 §8.3 vec-iso）；
-- ADT 的通用表示（Bool ≅ 1+1、Ratio ≅ ℕ×ℕ、List ≅ 1+A·X、
-- List ≅ Σ n. Aⁿ 即「A* = 1 + A + A² + …」）；函数即指数
-- （curry/case 两条指数律，外加一条「看着像但其实假」的分配律反例）；
-- 「半环不是环」的实测证人（加法消去律失效、2×X ≢ X）；
-- 最后用 stdlib Algebra 的 Monoid 束把 (Set, ×, ⊤) 与 (Set, ⊎, ⊥) 登记造册。
--
-- 类型检查：cd agda && ./build.sh Ex41_type_algebra
------------------------------------------------------------------------

module Ex41_type_algebra where

open import Level using (Level; _⊔_; 0ℓ) renaming (suc to lsuc)
  -- 实测坑×2：① stdlib 的 Level 把 Agda.Primitive 的 lsuc **改名**成 suc
  -- 再 public 转发（Level.agda 第 13–15 行），直接 using (lsuc) 报
  -- ModuleDoesntExport；② 若在 using 与 renaming 里各点名一次 suc，
  -- Agda 2.9.0 当场拒绝：RepeatedNamesInImportDirective——
  -- renaming 自己会挑选该名字，using 里不要再列（正文 41.9 实录）。
open import Function.Base using (id; _∘_; const)
open import Function.Bundles using (_↔_; mk↔ₛ′)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; trans; cong; cong₂; _≢_)
open import Relation.Nullary using (¬_)
open import Relation.Binary.Structures using (IsEquivalence)
open import Algebra using (Monoid)
open import Data.Unit using (⊤; tt)
open import Data.Empty using (⊥; ⊥-elim)
open import Data.Bool using (Bool; true; false; not)
open import Data.Sum using (_⊎_; inj₁; inj₂; [_,_]′)
import Data.Sum as Sum
open import Data.Product
  using (Σ; Σ-syntax; _×_; _,_; proj₁; proj₂; curry; uncurry; swap)
import Data.Product as Prod
open import Data.Nat using (ℕ; zero; suc; _+_; _*_)
open import Data.Fin
  using (Fin; toℕ; fromℕ; splitAt; join; combine; remQuot)
  renaming (zero to fzero; suc to fsuc)
open import Data.Fin.Properties
  using (splitAt-join; join-splitAt; remQuot-combine; combine-remQuot)
open import Data.Fin.Permutation using (Permutation; ↔⇒≡)
open import Data.List.Base using (List; []; _∷_; length)
open import Data.Vec using (Vec; lookup; toList; fromList)
import Data.Vec as V
open import Data.Vec.Properties using (toList∘fromList)

-- 17 章同款公理：函数相等要外延。stdlib 3.0 仍不提供 funExt（实测全库零命中）。
postulate
  funExt : ∀ {a b : Level} {A : Set a} {B : A → Set b}
           {f g : (x : A) → B x} → ((x : A) → f x ≡ g x) → f ≡ g

------------------------------------------------------------------------
-- 41.1 类型同构记录 _≅_：正逆函数 + 两侧往返律
------------------------------------------------------------------------

-- 书里的 Iso 活在 Setoid 上，多背 to-cong/from-cong 两个同余字段；
-- 我们直接走「命题相等版」（等价于书中的 ≅-prop）：cong 全免——
-- 任何函数自动保 ≡。字段名沿用书中习惯：from∘to 谈左类型，to∘from 谈右类型。
record _≅_ {a b : Level} (A : Set a) (B : Set b) : Set (a ⊔ b) where
  field
    to      : A → B
    from    : B → A
    from∘to : ∀ x → from (to x) ≡ x
    to∘from : ∀ y → to (from y) ≡ y
infix 0 _≅_

-- 实测坑：算子名 record 的字段不会自动裸进作用域（NotInScope: from，
-- 提示里却有 _≅_.from）——补一行 open 才顺手（正文 41.1 实录）。
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
  -- 复合的左往返：先把内层 from j ∘ to j 掐掉（from∘to j 喂 to i x），
  -- 再掐外层 from i ∘ to i（from∘to i 喂 x）。两条都是 from∘to！
  ; from∘to = λ x → trans (cong (from i) (from∘to j (to i x))) (from∘to i x)
  ; to∘from = λ y → trans (cong (to j) (to∘from i (from j y))) (to∘from j y)
  }

-- 记法：≅ 的传递复合（相当于 _∘_ 之于 ≡）。
infixr 8 _∘↮_
_∘↮_ : ∀ {a b c : Level} {A : Set a} {B : Set b} {C : Set c} →
       A ≅ B → B ≅ C → A ≅ C
_∘↮_ = ≅-trans

-- 与 stdlib `_↔_`（17 章）对照：↔ 多背的两个 cong 字段在这里白送，
-- 而 mk↔ₛ′ 恰好只要 to/from 加两条逐点律——≅ 与 ↔ 装袋的内容等量。
-- 注意 mk↔ₛ′ 参数顺序坑（17 章实测）：第一条交 to∘from（右/left-复合），第二条 from∘to。
≅⇒↔ : ∀ {a b : Level} {A : Set a} {B : Set b} → A ≅ B → A ↔ B
≅⇒↔ i = mk↔ₛ′ (to i) (from i) (to∘from i) (from∘to i)

------------------------------------------------------------------------
-- 41.2 有限数与特征函数：Bool ≅ Fin 2（10/16 章 Fin 的续命）
------------------------------------------------------------------------

-- 书中的 toFin/fromFin：Bool 是「二元类型」的代表。
toFin : Bool → Fin 2
toFin false = fzero
toFin true  = fsuc fzero

fromFin : Fin 2 → Bool
fromFin fzero        = false
fromFin (fsuc fzero) = true

bool≅fin : Bool ≅ Fin 2
bool≅fin = record
  { to      = toFin
  ; from    = fromFin
  ; from∘to = λ { false → refl ; true → refl }
  ; to∘from = λ { fzero → refl ; (fsuc fzero) → refl }
  }

-- stdlib 对照（实测口径）：Haskell 式 toEnum/fromEnum 在 stdlib 3.0
-- **不存在**（全库 grep 零命中）；正主是 toℕ / fromℕ / fromℕ<。
-- fromℕ 永远装得进 Fin (suc n)，且 toℕ∘fromℕ 是恒等——归纳一算便知：
toℕ-fromℕ : ∀ n → toℕ (fromℕ n) ≡ n
toℕ-fromℕ zero    = refl
toℕ-fromℕ (suc n) = cong suc (toℕ-fromℕ n)

-- 但 fromℕ∘toℕ 回不去：toℕ 把上界擦了，超出 Fin n 的自然数无穷多。
-- 「有限类型枚举器」的全部要点：把上界 n 留在**类型**里。

------------------------------------------------------------------------
-- 41.3 Vec 即特征函数：Vec A n ≅ (Fin n → A)（书 §8.3 vec-iso）
------------------------------------------------------------------------

Vec′ : Set → ℕ → Set
Vec′ A n = Fin n → A

toVec′ : ∀ {A n} → Vec A n → Vec′ A n
toVec′ = lookup

-- 反方向把「按索引查」折回「逐点构造」。递归时传 (f ∘ fsuc)：
-- 索引域变大（Fin n → Fin (suc n)），值域就变小——函数对定义域逆变。
-- 直接传 f 的写法当场报错（正文 41.3 实录），这就是书里 "backwards" 警告的实感。
fromVec′ : ∀ {A : Set} {n : ℕ} → Vec′ A n → Vec A n
fromVec′ {n = zero}  f = V.[]
fromVec′ {n = suc n} f = f fzero V.∷ fromVec′ (f ∘ fsuc)

fromVec′∘toVec′ : ∀ {A n} (v : Vec A n) → fromVec′ (toVec′ v) ≡ v
fromVec′∘toVec′ V.[]       = refl
fromVec′∘toVec′ (x V.∷ xs) rewrite fromVec′∘toVec′ xs = refl

-- 另一侧是函数等式，没有定义相等：先证逐点（对索引归纳——递归调用
-- 变小的是 ix，13 章归纳剧本换到 Fin 布景），再 funExt 收口。
toVec′-pointwise : ∀ {A n} (f : Vec′ A n) (i : Fin n) →
                   lookup (fromVec′ f) i ≡ f i
toVec′-pointwise f fzero     = refl
toVec′-pointwise f (fsuc ix) = toVec′-pointwise (f ∘ fsuc) ix

vec≅⇒ : ∀ {A n} → Vec A n ≅ Vec′ A n
vec≅⇒ = record
  { to      = toVec′
  ; from    = fromVec′
  ; from∘to = fromVec′∘toVec′
  ; to∘from = λ f → funExt (toVec′-pointwise f)
  }

-- 指数递推台阶：Aⁿ⁺¹ = A·Aⁿ 的类型版。
-- （签名字面量上 A 必须钉在 Set：Vec 是 Set ℓ → ℕ → Set ℓ 的层级多态，
--  两侧都多态时 ≅ 的层级元变量会悬空——实测 UnsolvedMetaVariables。）
vec-cons≅ : ∀ {A : Set} {n} → Vec A (suc n) ≅ (A × Vec A n)
vec-cons≅ = record
  { to      = λ { (x V.∷ xs) → x , xs }
  ; from    = λ { (x , xs) → x V.∷ xs }
  ; from∘to = λ { (x V.∷ xs) → refl }
  ; to∘from = λ { (x , xs) → refl }
  }

-- 「A⁰ = 1」：零长 Vec 恰好是 ⊤。定律只需一条分支就穷尽——
-- Vec A 0 只有 []，Agda 自己数得清（10 章索引无解的老手艺）。
unit0≅⊤ : ∀ {A : Set} → Vec A 0 ≅ ⊤
to (unit0≅⊤ {A = A}) V.[] = tt
from (unit0≅⊤) _ = V.[]
from∘to (unit0≅⊤) V.[] = refl
to∘from unit0≅⊤ x = refl

------------------------------------------------------------------------
-- 41.4 类型上的加法与乘法：0/1/+/* 的半环定律（全部作为 ≅ 交货）
------------------------------------------------------------------------

-- 半环零件：0 = ⊥，1 = ⊤，A + B = A ⊎ B，A × B = 积类型。
0ᵗ 1ᵗ : Set
0ᵗ = ⊥
1ᵗ = ⊤

-- ⊎/× 保同构（进 stdlib 代数束时充当 ∙-cong；形状 = Congruent₂）。
⊎-preserves-≅ : ∀ {A B C D : Set} → A ≅ B → C ≅ D → (A ⊎ C) ≅ (B ⊎ D)
⊎-preserves-≅ i j = record
  { to      = Sum.map (to i) (to j)
  ; from    = Sum.map (from i) (from j)
  ; from∘to = λ { (inj₁ x) → cong inj₁ (from∘to i x)
                ; (inj₂ y) → cong inj₂ (from∘to j y) }
  ; to∘from = λ { (inj₁ y) → cong inj₁ (to∘from i y)
                ; (inj₂ y) → cong inj₂ (to∘from j y) }
  }

×-preserves-≅ : ∀ {A B C D : Set} → A ≅ B → C ≅ D → (A × C) ≅ (B × D)
×-preserves-≅ i j = record
  { to      = Prod.map (to i) (to j)
  ; from    = Prod.map (from i) (from j)
  ; from∘to = λ { (x , y) → cong₂ _,_ (from∘to i x) (from∘to j y) }
  ; to∘from = λ { (x , y) → cong₂ _,_ (to∘from i x) (to∘from j y) }
  }

-- 加法单位元：A + 0 ≅ A。⊥ 侧一个分支都不用写（荒谬模式，06/12 章）。
⊎-identityʳ-≅ : ∀ {A : Set} → (A ⊎ 0ᵗ) ≅ A
to ⊎-identityʳ-≅ (inj₁ a) = a
to ⊎-identityʳ-≅ (inj₂ ())
from ⊎-identityʳ-≅ a = inj₁ a
from∘to ⊎-identityʳ-≅ (inj₁ a) = refl
from∘to ⊎-identityʳ-≅ (inj₂ ())
to∘from ⊎-identityʳ-≅ a = refl

-- 加法交换律/结合律。
⊎-comm-≅ : ∀ {A B : Set} → (A ⊎ B) ≅ (B ⊎ A)
to ⊎-comm-≅ (inj₁ a) = inj₂ a
to ⊎-comm-≅ (inj₂ b) = inj₁ b
from ⊎-comm-≅ (inj₁ b) = inj₂ b
from ⊎-comm-≅ (inj₂ a) = inj₁ a
from∘to ⊎-comm-≅ (inj₁ a) = refl
from∘to ⊎-comm-≅ (inj₂ b) = refl
to∘from ⊎-comm-≅ (inj₁ b) = refl
to∘from ⊎-comm-≅ (inj₂ a) = refl

⊎-assoc-≅ : ∀ {A B C : Set} → ((A ⊎ B) ⊎ C) ≅ (A ⊎ (B ⊎ C))
to ⊎-assoc-≅ (inj₁ (inj₁ a)) = inj₁ a
to ⊎-assoc-≅ (inj₁ (inj₂ b)) = inj₂ (inj₁ b)
to ⊎-assoc-≅ (inj₂ c) = inj₂ (inj₂ c)
from ⊎-assoc-≅ (inj₁ a) = inj₁ (inj₁ a)
from ⊎-assoc-≅ (inj₂ (inj₁ b)) = inj₁ (inj₂ b)
from ⊎-assoc-≅ (inj₂ (inj₂ c)) = inj₂ c
from∘to ⊎-assoc-≅ (inj₁ (inj₁ a)) = refl
from∘to ⊎-assoc-≅ (inj₁ (inj₂ b)) = refl
from∘to ⊎-assoc-≅ (inj₂ c) = refl
to∘from ⊎-assoc-≅ (inj₁ a) = refl
to∘from ⊎-assoc-≅ (inj₂ (inj₁ b)) = refl
to∘from ⊎-assoc-≅ (inj₂ (inj₂ c)) = refl

-- 乘法单位元：A × 1 ≅ A 全程 refl——record η 白送的功劳（09 章）。
×-identityʳ-≅ : ∀ {A : Set} → (A × 1ᵗ) ≅ A
to ×-identityʳ-≅ = proj₁
from ×-identityʳ-≅ a = a , tt
from∘to ×-identityʳ-≅ p = refl
to∘from ×-identityʳ-≅ a = refl

-- 乘法零元：A × 0 ≅ 0——左边根本没人，⊥-elim 一统两侧。
×-zeroʳ-≅ : ∀ {A : Set} → (A × 0ᵗ) ≅ 0ᵗ
to ×-zeroʳ-≅ p = ⊥-elim (proj₂ p)
from ×-zeroʳ-≅ x = ⊥-elim x
from∘to ×-zeroʳ-≅ x = ⊥-elim (proj₂ x)
to∘from ×-zeroʳ-≅ x = ⊥-elim x

-- 乘法交换/结合。
×-comm-≅ : ∀ {A B : Set} → (A × B) ≅ (B × A)
to ×-comm-≅ = swap
from ×-comm-≅ = swap
from∘to ×-comm-≅ p = refl
to∘from ×-comm-≅ p = refl

×-assoc-≅ : ∀ {A B C : Set} → ((A × B) × C) ≅ (A × (B × C))
to ×-assoc-≅ ((a , b) , c) = a , (b , c)
from ×-assoc-≅ (a , (b , c)) = (a , b) , c
from∘to ×-assoc-≅ p = refl
to∘from ×-assoc-≅ p = refl

-- 分配律：A × (B + C) ≅ (A×B) + (A×C)。四条分支各走各的。
×-distribˡ-≅ : ∀ {A B C : Set} → (A × (B ⊎ C)) ≅ ((A × B) ⊎ (A × C))
to ×-distribˡ-≅ (a , inj₁ b) = inj₁ (a , b)
to ×-distribˡ-≅ (a , inj₂ c) = inj₂ (a , c)
from ×-distribˡ-≅ (inj₁ (a , b)) = a , inj₁ b
from ×-distribˡ-≅ (inj₂ (a , c)) = a , inj₂ c
from∘to ×-distribˡ-≅ (a , inj₁ b) = refl
from∘to ×-distribˡ-≅ (a , inj₂ c) = refl
to∘from ×-distribˡ-≅ (inj₁ p) = refl
to∘from ×-distribˡ-≅ (inj₂ p) = refl

-- 剩下的左版定律都不用自己证：交换律 + 右版 = 左版（代数课的把戏，
-- 在这里是同构复合一行的事）。
⊎-identityˡ-≅ : ∀ {A : Set} → (0ᵗ ⊎ A) ≅ A
⊎-identityˡ-≅ = ≅-sym ⊎-comm-≅ ∘↮ ⊎-identityʳ-≅

×-identityˡ-≅ : ∀ {A : Set} → (1ᵗ × A) ≅ A
×-identityˡ-≅ = ≅-sym ×-comm-≅ ∘↮ ×-identityʳ-≅

×-zeroˡ-≅ : ∀ {A : Set} → (0ᵗ × A) ≅ 0ᵗ
×-zeroˡ-≅ = ≅-sym ×-comm-≅ ∘↮ ×-zeroʳ-≅

-- 把这堆定律用起来：Vec A 3 ≅ A × A × A，即「A³」。
-- 每一段都是前面零件的复合：拆一个头（vec-cons≅）、递归、尾部收 ⊤。
vec³≅A³ : ∀ {A : Set} → Vec A 3 ≅ (A × A × A)
vec³≅A³ {A = A} = c3
  where
  c1 : Vec A 1 ≅ A
  c1 = vec-cons≅ ∘↮ ×-preserves-≅ ≅-refl unit0≅⊤ ∘↮ ×-identityʳ-≅ {A = A}
  c2 : Vec A 2 ≅ (A × A)
  c2 = vec-cons≅ ∘↮ ×-preserves-≅ ≅-refl c1
  c3 : Vec A 3 ≅ (A × A × A)
  c3 = vec-cons≅ ∘↮ ×-preserves-≅ ≅-refl c2

------------------------------------------------------------------------
-- 41.5 有限类型与基数：A Has n = A ≅ Fin n
------------------------------------------------------------------------

infix 4 _Has_
_Has_ : ∀ {a : Level} → Set a → ℕ → Set a
A Has n = A ≅ Fin n

-- 0 个元素的类型是 ⊥，1 个元素的类型是 ⊤——两条都是「一行代码同构」。
⊥-has0 : ⊥ Has 0
to ⊥-has0 ()
from ⊥-has0 ()
from∘to ⊥-has0 ()
to∘from ⊥-has0 ()

⊤-has1 : ⊤ Has 1
to ⊤-has1 _ = fzero
from ⊤-has1 _ = tt
from∘to ⊤-has1 _ = refl
to∘from ⊤-has1 fzero = refl

-- 加法算牌：m 个 + n 个 = m+n 个。stdlib 的 join/splitAt 就是这两侧，
-- 往返律 splitAt-join / join-splitAt 早已在 Data.Fin.Properties 里证好。
fin⊎≅fin+ : ∀ m n → (Fin m ⊎ Fin n) ≅ Fin (m + n)
fin⊎≅fin+ m n = record
  { to      = join m n
  ; from    = splitAt m
  ; from∘to = splitAt-join m n
  ; to∘from = join-splitAt m n
  }

-- 乘法算牌：m×n 网格 ↔ Fin (m*n)。正主 combine/remQuot，定律同款。
-- 坑：combine 的 m n 全是隐式（Base 第 179 行），remQuot 只显式收「除数」n；
-- 两边的隐式 {m} 名字都对不上时，用 {n = p} 手工钉住（下方 to∘from）。
fin×≅fin× : ∀ p q → (Fin p × Fin q) ≅ Fin (p * q)
to (fin×≅fin× p q) = uncurry combine
from (fin×≅fin× p q) = remQuot q
from∘to (fin×≅fin× p q) (i , j) = remQuot-combine i j
to∘from (fin×≅fin× p q) = combine-remQuot {n = p} q

-- 两个「算牌器」：基数各自已知 → 和/积的基数相乘加。
⊎-has : ∀ {A B : Set} {m n} → A Has m → B Has n → (A ⊎ B) Has (m + n)
⊎-has i j = ≅-trans (⊎-preserves-≅ i j) (fin⊎≅fin+ _ _)

×-has : ∀ {A B : Set} {m n} → A Has m → B Has n → (A × B) Has (m * n)
×-has i j = ≅-trans (×-preserves-≅ i j) (fin×≅fin× _ _)

-- 例：Bool ⊎ Bool 有 4 个元素。
2bool-has4 : (Bool ⊎ Bool) Has 4
2bool-has4 = ⊎-has bool≅fin bool≅fin

-- 基数唯一吗？「同构 ⇒ 基数相等」是 stdlib 正品 ↔⇒≡：
-- 它吃一个 Permutation m n（= Fin m ↔ Fin n，Permutation.agda 第 53–54 行），
-- 吐出 m ≡ n。我们的 ≅ 经 ≅⇒↔ 换袋即可投喂。
has⇒≡ : ∀ {a : Level} {A : Set a} {m n} → A Has m → A Has n → m ≡ n
has⇒≡ i j = ↔⇒≡ (≅⇒↔ (≅-sym i ∘↮ j))

fin-iso : ∀ {m n} → Fin m Has n → m ≡ n
fin-iso i = ↔⇒≡ (≅⇒↔ i)

-- ⊤ ⊎ ⊤ 有 2 个元素，Bool 有 2 个元素 → 同基数 → 同构。
-- 这就是书中「1+1 = 2 = Bool」的双向记账。
⊤⊤-has2 : (⊤ ⊎ ⊤) Has 2
⊤⊤-has2 = ⊎-has ⊤-has1 ⊤-has1

bool≅1+1 : Bool ≅ (1ᵗ ⊎ 1ᵗ)
bool≅1+1 = bool≅fin ∘↮ ≅-sym ⊤⊤-has2

-- 手搓版（不借道 Fin，直观演示 1+1 怎么「就是」Bool）：
bool≅1+1-v2 : Bool ≅ (1ᵗ ⊎ 1ᵗ)
to bool≅1+1-v2 false = inj₁ tt
to bool≅1+1-v2 true  = inj₂ tt
from bool≅1+1-v2 (inj₁ _) = false
from bool≅1+1-v2 (inj₂ _) = true
from∘to bool≅1+1-v2 false = refl
from∘to bool≅1+1-v2 true  = refl
to∘from bool≅1+1-v2 (inj₁ _) = refl
to∘from bool≅1+1-v2 (inj₂ _) = refl
------------------------------------------------------------------------
-- 41.6 ADT 的通用表示：把构造子读成 1 / + / ×
------------------------------------------------------------------------

-- 例一（书 §8.2 原案）：有理数骨架 Ratio = mkRatio ℕ ℕ。
-- 一个构造子、两个字段 ⇒ Ratio ≅ ℕ × ℕ。四字段全 refl。
data Ratio : Set where
  mkRatio : (numerator denominator : ℕ) → Ratio

ratio≅× : Ratio ≅ (ℕ × ℕ)
to ratio≅× (mkRatio n d) = n , d
from ratio≅× (n , d) = mkRatio n d
from∘to ratio≅× (mkRatio n d) = refl   -- 必须对 r 做模式匹配：
                                       -- η/单构造子不是 refl 白送的（区别于 ×/⊤ 的 record η）
to∘from ratio≅× p = refl

-- 例二：List A 的递归方程 X ≅ 1 + A·X（构造子 [] 出 1，∷ 出 A×X）。
list≅1+AX : ∀ {A : Set} → List A ≅ (1ᵗ ⊎ (A × List A))
to list≅1+AX [] = inj₁ tt
to list≅1+AX (x ∷ xs) = inj₂ (x , xs)
from list≅1+AX (inj₁ _) = []
from list≅1+AX (inj₂ (x , xs)) = x ∷ xs
from∘to list≅1+AX [] = refl
from∘to list≅1+AX (x ∷ xs) = refl
to∘from list≅1+AX (inj₁ _) = refl
to∘from list≅1+AX (inj₂ _) = refl

-- 例三（本章压轴）：把递归方程「解」出来——
-- A* = 1 + A + A² + A³ + …  即 List A ≅ Σ[ n ∈ ℕ ] Vec A n。
-- 坑（实测口径）：stdlib 的 fromList∘toList 是「先 cast 再 refl」的
-- ≈[] 路子（Vec.Properties 第 1445 行），塞不进 ≅ 字段；直接对
-- (length (toList v) , fromList (toList v)) ≡ (n , v) 用 cong 猜 lambda
-- 更糟——高阶元变量 _n (k = …) 一堆无解（实测 UnsolvedConstraints）。
-- 对策：给归纳步一个**显式签名**的辅助函数 cons，cong 就不再需要猜。
toΣ∘fromΣ : ∀ {A : Set} {n} (v : Vec A n) →
            (length (toList v) , fromList (toList v)) ≡ (n , v)
toΣ∘fromΣ V.[]       = refl
toΣ∘fromΣ {A = A} (x V.∷ xs) = cong cons (toΣ∘fromΣ xs)
  where
  cons : (Σ[ k ∈ ℕ ] Vec A k) → (Σ[ k ∈ ℕ ] Vec A k)
  cons (k , v) = suc k , x V.∷ v

list≅Σ : ∀ {A : Set} → List A ≅ Σ[ n ∈ ℕ ] Vec A n
to list≅Σ xs = length xs , fromList xs
from list≅Σ (_ , v) = toList v
from∘to list≅Σ xs = toList∘fromList xs
to∘from list≅Σ (n , v) = toΣ∘fromΣ v

------------------------------------------------------------------------
-- 41.7 函数即指数：⇒ 吃下 curry/case，也吃掉一条「假分配律」
------------------------------------------------------------------------

-- 指数律一：C^(A×B) ≅ (C^B)^A —— 这就是 curry/uncurry，05/09 章老朋友。
-- 从右往左的往返律是逐点函数等式，funExt 出场（17 章口径）。
curry≅ : ∀ {A B C : Set} → ((A × B → C) ≅ (A → B → C))
curry≅ = record
  { to      = curry
  ; from    = uncurry
  ; from∘to = λ f → refl                      -- uncurry∘curry：η 直接白送
  ; to∘from = λ f → funExt λ a → refl         -- 逐点：curry(uncurry f) a =λ f a（η）
  }

-- 指数律二：C^(A+B) ≅ C^A × C^B —— case 的拆分。
-- from 用 [_,_]′（Data.Sum），to 把 f 分别 precompose inj₁/inj₂。
case≅ : ∀ {A B C : Set} → (A ⊎ B → C) ≅ ((A → C) × (B → C))
case≅ = record
  { to      = λ f → (f ∘ inj₁) , (f ∘ inj₂)
  ; from    = λ { (g , h) → [ g , h ]′ }
  ; from∘to = λ f → funExt λ { (inj₁ a) → refl ; (inj₂ b) → refl }
    -- ⊎ 没有 η-expansion（函数对「和型定义域」只能逐分支），refl 卡住——
    -- 必须 funExt + 分支匹配（实测报错：Sum.[…]′ x 与 f x 不相等）。
  ; to∘from = λ { (g , h) →
      cong₂ _,_ (funExt λ a → refl) (funExt λ b → refl) }
  }

-- 推论（书中 "2 → A = A + A"）：Bool → A ≅ A × A。
-- 它其实是 case≅ 在 2 ≅ 1+1（bool≅1+1）之下的实例；这里直接手搓，
-- 顺便看看 from∘to 又要把 funExt 请出来（逐点：false 支、true 支）。
2⇒A≅A×A : ∀ {A : Set} → (Bool → A) ≅ (A × A)
2⇒A≅A×A {A = A} = record
  { to      = λ f → f false , f true
  ; from    = λ { (g , h) → λ { false → g ; true → h } }
  ; from∘to = λ f → funExt λ { false → refl ; true → refl }
  ; to∘from = λ { (g , h) → refl }
  }

-- 指数律三（半环不满足的「分配」）：(A×B)⇒C ≅ (A⇒C)×(B⇒C)？
-- 看着像 log(A·B)=log A + log B，其实**假**：A=⊤, B=⊥, C=⊥ 时
-- 左边 ⊤×⊥→⊥ 有唯一函数（∅ 上函数），右边 (⊤→⊥)×(⊥→⊥) 第一腿没人——
-- 左边 inhabited、右边空，同构不存在。下面把这反例形式化。
¬⇒-distrib : ¬ ((⊤ × ⊥ → ⊥) ≅ ((⊤ → ⊥) × (⊥ → ⊥)))
¬⇒-distrib i = proj₁ (to i (λ p → ⊥-elim (proj₂ p))) tt
  -- 若 i 存在：把「⊤×⊥→⊥」（常函数即可，右侧永远无证人）送过去，
  -- 取出 (⊤→⊥) 分量、喂 tt —— 造出 ⊥ 的元素，矛盾。

------------------------------------------------------------------------
-- 41.8 半环不是环：消去律失效、2×X ≢ X 的实测证人
------------------------------------------------------------------------

-- 环要求加法有逆（即消去律）。类型上没有：ℕ（作为 List A 的化身）
-- 满足 X ≅ 1 + X —— 「加一个还是它自己」，若可消去就推出 0 ≅ 1，荒谬。
-- 证人一：ℕ ≅ 1 ⊎ ℕ，零归纳量（to = suc, from = case 0/left）。
-- 这里用 book 版：to/from 直接拿 1ℕ→ℕ 与「判零」。
ℕ≅1+ℕ : ℕ ≅ (1ᵗ ⊎ ℕ)
to ℕ≅1+ℕ zero = inj₁ tt
to ℕ≅1+ℕ (suc n) = inj₂ n
from ℕ≅1+ℕ (inj₁ _) = zero
from ℕ≅1+ℕ (inj₂ n) = suc n
from∘to ℕ≅1+ℕ zero = refl
from∘to ℕ≅1+ℕ (suc n) = refl
to∘from ℕ≅1+ℕ (inj₁ _) = refl
to∘from ℕ≅1+ℕ (inj₂ n) = refl

-- 证人二：加法消去律失效的三连——
-- ① ⊤ ⊎ ℕ ≅ ℕ（上面那条反过来），② ⊥ ⊎ ℕ ≅ ℕ（左单位），
-- ③ 但 ⊤ ≢ ⊥：若 ⊤ ≅ ⊥，把 tt 送过去即得 ⊥ 元素。
-- 于是 A⊎C ≅ B⊎C 推不出 A ≅ B。
⊤≇⊥ : ¬ (⊤ ≅ ⊥)
⊤≇⊥ i = to i tt

no-cancel : ((⊤ ⊎ ℕ) ≅ ℕ) × (ℕ ≅ (⊥ ⊎ ℕ)) × ¬ (⊤ ≅ ⊥)
no-cancel = ≅-sym ℕ≅1+ℕ , ≅-sym ⊎-identityˡ-≅ , ⊤≇⊥
  -- 第一支：⊤⊎ℕ ≅ ℕ（41.8 证人一的镜像）；
  -- 第二支：ℕ ≅ ⊥⊎ℕ（41.4 左单位律的镜像，⊥-elim 白送）；
  -- 第三支：⊤ ≅ ⊥ 绝无可能。三条并排 = 「A⊎C ≅ B⊎C ⇏ A ≅ B」的完整证人。

-- 证人三：2 × X ≢ X（书的 "no fixed points for 2×_"）。
-- 取 X = Fin 1：左边基数 2×1=2，右边基数 1。↔⇒≡ 把同构折算成
-- 自然数等式，2 ≡ 1 被模式匹配当场拒绝（refl 造不出它，`()`)。
2×1≅2 : (Bool × Fin 1) Has 2
2×1≅2 = ×-has bool≅fin ≅-refl      -- 2*1 归约到 2，×-has 直接交差

2≢1 : 2 ≡ 1 → ⊥
2≢1 ()                              -- suc (suc _) ≡ suc _ 无 refl 实例

¬2×1≅1 : ¬ ((Bool × Fin 1) ≅ Fin 1)
¬2×1≅1 i = 2≢1 (has⇒≡ 2×1≅2 i)      -- 若同构存在：has⇒≡ 吐出 2 ≡ 1

-- 出口：多项式方程可以有类型解！X ≅ 1 + X×X 的非平凡解就是二叉树。
-- 「半环不是环」的另一面：不是没有减法，而是解住在无穷类型里
-- （22 章余归纳的伏笔：Stream A 满足 S ≅ A × S）。
data Tree : Set where
  leaf  : Tree
  node  : (l r : Tree) → Tree

tree-iso : Tree ≅ (1ᵗ ⊎ (Tree × Tree))
to tree-iso leaf = inj₁ tt
to tree-iso (node l r) = inj₂ (l , r)
from tree-iso (inj₁ _) = leaf
from tree-iso (inj₂ (l , r)) = node l r
from∘to tree-iso leaf = refl
from∘to tree-iso (node l r) = refl
to∘from tree-iso (inj₁ _) = refl
to∘from tree-iso (inj₂ _) = refl

------------------------------------------------------------------------
-- 41.9 登记造册：(Set, ×, ⊤) 与 (Set, ⊎, ⊥) 都是 stdlib Monoid 束
------------------------------------------------------------------------

-- _≅_ 是等价关系（IsEquivalence 三件套直接喂）。
-- 实测坑：不钉死层级写 IsEquivalence _≅_ 会留下无解层级元变量
-- （`_b_ = Level.zero (blocked on _b_)`）——异构 record 的参数
-- 必须显式实例化到 Set₀ 这一层。
≅-isEq : IsEquivalence (_≅_ {a = 0ℓ} {b = 0ℓ})
≅-isEq = record
  { refl  = ≅-refl
  ; sym   = ≅-sym
  ; trans = ≅-trans
  }

-- Monoid 束（29 章口径）：嵌套 record，isMonoid 里再套 isSemigroup/isMagma。
-- 实测坑：Algebra.Bundles 3.0 的 Monoid 需要两个层级参数 (lsuc 0ℓ) 0ℓ
-- ——Carrier 是 Set（活过 ⊤/⊥ 于 Set 之上？不：⊥ : Set，Set : Set₁，
-- Carrier = Set 住在 Set₁），故首参 suc 0ℓ。
×-⊤-monoid : Monoid (lsuc 0ℓ) 0ℓ
×-⊤-monoid = record
  { Carrier  = Set
  ; _≈_      = _≅_
  ; _∙_      = _×_
  ; ε        = ⊤
  ; isMonoid = record
      { isSemigroup = record
          { isMagma = record
              { isEquivalence = ≅-isEq
              ; ∙-cong        = ×-preserves-≅
              }
          ; assoc = λ A B C → ×-assoc-≅
          }
      ; identity = (λ A → ×-identityˡ-≅) , (λ A → ×-identityʳ-≅)
      }
  }

⊎-⊥-monoid : Monoid (lsuc 0ℓ) 0ℓ
⊎-⊥-monoid = record
  { Carrier  = Set
  ; _≈_      = _≅_
  ; _∙_      = _⊎_
  ; ε        = ⊥
  ; isMonoid = record
      { isSemigroup = record
          { isMagma = record
              { isEquivalence = ≅-isEq
              ; ∙-cong        = ⊎-preserves-≅
              }
          ; assoc = λ A B C → ⊎-assoc-≅
          }
      ; identity = (λ A → ⊎-identityˡ-≅) , (λ A → ⊎-identityʳ-≅)
      }
  }

-- 两个幺半群共用 ⊎/× 与 ≅「≈」，再配分配律 ×-distribˡ-≅、零元 ×-zeroˡ/ʳ-≅，
-- 半环的全部公理到齐——这就是「ADT 是半环」的完整登记。
-- （完整的 Semiring 束要三层 Structures 嵌套，29 章已演练；此处点到为止：
-- 类型世界有 0,1,+,× 且满足半环定律，但**没有**减法——41.8 已证。）
