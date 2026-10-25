-- 第 90 章 · 力迫基本理论与 CH/AC 独立性（冯琦第二卷 §3.1-3.3）
-- 三件样品：定理 3.1 的相遇链递归引擎（稠密集记录 + 嵌套链 +
-- 相遇记账）；条件决定比特与泛型对角避让；Fn(n,2) 的布尔相容
-- 检查器与 3^n 条件枚举（ccc 有限计数的机器面）。
module Ch90_forcing where

open import Data.Nat using (ℕ; zero; suc; _+_; _∸_; _<_; s≤s)
open import Data.Nat.Properties using (+-identityʳ; +-suc)
open import Data.Bool using (Bool; true; false; not; _∧_)
open import Data.Maybe using (Maybe; just; nothing)
open import Data.List using (List; []; _∷_; _++_; length; replicate; map; concat)
open import Data.List.Properties using (length-++; length-replicate)
open import Data.Product using (_×_; _,_; ∃)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; sym; trans; cong)
open import Relation.Nullary using (¬_)
open import Data.Unit using (⊤)

-- ---------- 一、稠密相遇链（定理 3.1 的递归引擎） ----------

-- q 延拓 p（更强条件）：q = p ++ r
Ext : List Bool → List Bool → Set
Ext p q = ∃ λ r → q ≡ p ++ r

-- 带选择函数的稠密集：dext 把任何条件延拓成 Dmem 的成员。
-- 真正的稠密集 ∀p∃q 非构造地给见证；可数模型里枚举稠密集后
-- 逐个选见证——这正是定理 3.1 的证明。
record Dense : Set₁ where
  constructor mkDense
  field
    Dmem : List Bool → Set
    dext : List Bool → List Bool
    is-ext : ∀ p → Ext p (dext p)
    hits : ∀ p → Dmem (dext p)

open Dense public

-- 从条件 p 出发逐集延长：相邻两项由 is-ext 见证
chainFrom : List Bool → List Dense → List (List Bool)
chainFrom p [] = p ∷ []
chainFrom p (d ∷ ds) = p ∷ chainFrom (dext d p) ds

chain : List Dense → List (List Bool)
chain = chainFrom []

-- 相邻延拓性：链中每个内部相邻对满足 Ext
-- （按稠密集序列结构陈述，避免链头在变量表上卡壳）
ExtStep : List Bool → List Dense → Set
ExtStep p [] = ⊤
ExtStep p (d ∷ ds) = Ext p (dext d p) × ExtStep (dext d p) ds

chainExt : ∀ p (ds : List Dense) → ExtStep p ds
chainExt p [] = _
chainExt p (d ∷ ds) = is-ext d p , chainExt (dext d p) ds

-- 点对索引：Nth xs i x 表示 xs 的第 i 项是 x
data Nth {a} {A : Set a} : List A → ℕ → A → Set a where
  here  : ∀ {x xs} → Nth (x ∷ xs) zero x
  there : ∀ {x y xs n} → Nth xs n y → Nth (x ∷ xs) (suc n) y

-- 越界取 [] 的链上按位访问
nthL : List (List Bool) → ℕ → List Bool
nthL [] _ = []
nthL (x ∷ _) zero = x
nthL (_ ∷ xs) (suc k) = nthL xs k

-- 链头总是出发点
chainHeadL : ∀ q ds → nthL (chainFrom q ds) zero ≡ q
chainHeadL q [] = refl
chainHeadL q (d ∷ ds) = refl

-- 第 k 个稠密集在链的第 k+1 个节点处被相遇（定理 3.1 的记账）
chainMeets : ∀ p (ds : List Dense) k d → Nth ds k d →
  Dmem d (nthL (chainFrom p ds) (suc k))
chainMeets p (d₀ ∷ ds) zero .d₀ here
  rewrite chainHeadL (dext d₀ p) ds = hits d₀ p
chainMeets p (d₀ ∷ ds) (suc k) d (there nd) =
  chainMeets (dext d₀ p) ds k d nd
chainMeets p [] zero d ()
chainMeets p [] (suc k) d ()

-- ---------- 二、决定比特与泛型对角避让 ----------

-- 越界取 false 的按位访问（对应书里 [n]! 的默认语义）
nthB : List Bool → ℕ → Bool
nthB [] _ = false
nthB (x ∷ xs) zero = x
nthB (x ∷ xs) (suc k) = nthB xs k

-- 决定第 n 位的延长：补零到长度 n+1
decider : ℕ → List Bool → List Bool
decider n p = p ++ replicate (suc n ∸ length p) false

deciderExt : ∀ n p → Ext p (decider n p)
deciderExt n p = replicate (suc n ∸ length p) false , refl

-- 决定稠密性：任何条件都能延拓到第 n 位被决定（长度公式）
deciderLen : ∀ n p → length (decider n p) ≡ length p + (suc n ∸ length p)
deciderLen n p = trans (length-++ p)
  (cong (length p +_) (length-replicate (suc n ∸ length p)))

-- 演示：decider 2 [true] 的长度恰为 3（第 0/1/2 位全被决定）
demoDeciderLen : length (decider 2 (true ∷ [])) ≡ 3
demoDeciderLen = refl

-- 前缀保持已决定的比特：p ⊩ g(n)=b ⇒ 任何含 p 的泛型都如此
forcedBit : ∀ p r i → i < length p → nthB (p ++ r) i ≡ nthB p i
forcedBit [] r i ()
forcedBit (x ∷ xs) r zero h = refl
forcedBit (x ∷ xs) r (suc i) (s≤s h) = forcedBit xs r i h

-- 泛型对角避让：第 k 步在位置 k 翻转 b_k 的比特
flipB : List Bool → ℕ → Bool
flipB b k = not (nthB b k)

genBuildFrom : ℕ → List (List Bool) → List Bool
genBuildFrom _ [] = []
genBuildFrom k (b ∷ bs) = flipB b k ∷ genBuildFrom (suc k) bs

-- 分支表按位访问
nthBs : List (List Bool) → ℕ → List Bool
nthBs [] _ = []
nthBs (x ∷ xs) zero = x
nthBs (x ∷ xs) (suc k) = nthBs xs k

-- Bool 的两个构造子都满足 not b ≢ b
¬-self-flip : ∀ b → ¬ (not b ≡ b)
¬-self-flip false ()
¬-self-flip true ()

-- 生成串第 j 位恰为第 j 个地基分支第 k0+j 位的翻转
genBit : ∀ bs k0 j → j < length bs →
  nthB (genBuildFrom k0 bs) j ≡ flipB (nthBs bs j) (k0 + j)
genBit [] k0 j ()
genBit (b ∷ bs) k0 zero h
  rewrite +-identityʳ k0 = refl
genBit (b ∷ bs) k0 (suc j) (s≤s h) =
  trans (genBit bs (suc k0) j h)
        (cong (flipB (nthBs bs j)) (sym (+-suc k0 j)))

-- 泛型分支与每个地基分支 b_k 在第 k 位不同（例 3.3 对角稠密集）
genericAvoids : ∀ bs k → k < length bs →
  ¬ (nthB (genBuildFrom zero bs) k ≡ nthB (nthBs bs k) k)
genericAvoids bs k hk h =
  ¬-self-flip (nthB (nthBs bs k) k) (trans (sym (genBit bs zero k hk)) h)

-- ---------- 三、Fn(n,2) 的布尔相容检查器与计数（ccc 有限引擎） ----------

eqbB : Bool → Bool → Bool
eqbB true c = c
eqbB false c = not c

-- 相容：公共定义域上取值一致（agree f g = true）
agree : List (Maybe Bool) → List (Maybe Bool) → Bool
agree [] _ = true
agree _ [] = true
agree (just b ∷ f) (just c ∷ g) = eqbB b c ∧ agree f g
agree (just b ∷ f) (nothing ∷ g) = agree f g
agree (nothing ∷ f) (_ ∷ g) = agree f g

-- 零填充：None 补 0，把条件变成全函数
conv : Maybe Bool → Bool
conv (just b) = b
conv nothing = false

-- 相冲条件的零填充不同：公共位上取值相反 ⇒ 填充后列表首项不同
demoIncompat :
  let f0 = just true ∷ nothing ∷ []
      g0 = just false ∷ just true ∷ []
  in agree f0 g0 ≡ false × ¬ (map conv f0 ≡ map conv g0)
demoIncompat = refl , λ ()

-- Fn(n,2) 恰有 3^n 个条件（每个坐标：未定义/取 0/取 1）
allConds : ℕ → List (List (Maybe Bool))
allConds zero = [] ∷ []
allConds (suc n) =
  concat (map (λ l → (nothing ∷ l) ∷ (just true ∷ l) ∷ (just false ∷ l) ∷ [])
              (allConds n))

demoCard : length (allConds 3) ≡ 27
demoCard = refl

-- 全函数空间恰有 2^n 个（反链上界）
allTots : ℕ → List (List Bool)
allTots zero = [] ∷ []
allTots (suc n) =
  concat (map (λ l → (true ∷ l) ∷ (false ∷ l) ∷ []) (allTots n))

demoTot : length (allTots 3) ≡ 8
demoTot = refl

-- 长度 2 的条件空间恰 3^2 = 9 个；填充像至多 2^2 = 4 个
demoSmall : length (allConds 2) ≡ 9 × length (allTots 2) ≡ 4
demoSmall = refl , refl
