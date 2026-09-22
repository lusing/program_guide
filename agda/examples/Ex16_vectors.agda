------------------------------------------------------------------------
-- 第 16 章示例：Vec——长度索引的列表，依赖编程招牌
--
-- Vec 定义解剖、head/tail/lookup 的索引形状、append/reverse 的索引
-- 算术（rewrite +sym 实录）、map/replicate/zip/unzip、with 判长度做
-- headOr、Vec↔List 双向换算与往返定律、tabulate/allFin「证明即索引」。
--
-- 类型检查：cd agda && agda examples/Ex16_vectors.agda
------------------------------------------------------------------------

module Ex16_vectors where

open import Data.Bool using (Bool; true; false)
open import Data.Nat using (ℕ; zero; suc; _+_; _*_)
open import Data.Nat.Properties
  using (_≟_; +-identityʳ; +-suc)
open import Data.Empty using (⊥; ⊥-elim)
open import Data.Fin using (Fin; toℕ; #_; fromℕ)
  renaming (zero to fzero; suc to fsuc)
open import Data.List using (List; []; _∷_; length)
open import Data.Maybe using (Maybe; just; nothing)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.Vec
  using (Vec; head; tail; lookup; _++_; reverse; replicate; zip; unzip; cast;
        tabulate; allFin; toList; fromList; _∷ʳ_)
open import Relation.Nullary using (Dec; yes; no; ¬_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; cong)

-- Vec 的构造子 [] ∷ 与 List 同名，import 时不具名带出——
-- 按期望类型分派（10 章实测规则），需要点名时写 Data.Vec._∷_。
open import Data.Vec using ([]; _∷_)

------------------------------------------------------------------------
-- 16.1 定义解剖：长度住在索引里
------------------------------------------------------------------------

-- stdlib 原文（Data.Vec.Base）：
--   data Vec (A : Set) : ℕ → Set where
--     []  : Vec A zero
--     _∷_ : (x : A) (xs : Vec A n) → Vec A (suc n)
-- A 是参数、ℕ 是索引：构造子负责把索引「算」出来——
-- [] 造 zero 长，∷ 将长度 +1。Vec A 3 和 Vec A 4 是**不同类型**。

-- 亲手验证索引算术卡类型：3 个元素配 3，多一个少一个都不行
v3 : Vec ℕ 3
v3 = 10 ∷ 20 ∷ 30 ∷ []

v4 : Vec ℕ 4
v4 = 40 ∷ v3                    -- Vec ℕ (suc 3) = Vec ℕ 4 ✓

-- 复刻一个最小版体会构造子的类型（换成自己的索引算术练习）：
data VecT (A : Set) : ℕ → Set where
  []T  : VecT A zero
  _∷T_ : ∀ {n} → (x : A) (xs : VecT A n) → VecT A (suc n)

toT : ∀ {A : Set} {n} → Vec A n → VecT A n
toT []       = []T
toT (x ∷ xs) = x ∷T toT xs

fromT : ∀ {A : Set} {n} → VecT A n → Vec A n
fromT []T       = []
fromT (x ∷T xs) = x ∷ fromT xs

fromT∘toT : ∀ {A : Set} {n} (v : Vec A n) → fromT (toT v) ≡ v
fromT∘toT []       = refl
fromT∘toT (x ∷ xs) = cong (x ∷_) (fromT∘toT xs)

------------------------------------------------------------------------
-- 16.2 越界不可表达：head/tail/lookup 都要「索引的形状」
------------------------------------------------------------------------

-- stdlib：head : Vec A (1 + n) → A（一行，[] 分支不存在所以不写）
--        tail : Vec A (1 + n) → Vec A n
--        lookup : Vec A n → Fin n → A
_ : head v3 ≡ 10
_ = refl

_ : tail v3 ≡ 20 ∷ 30 ∷ []
_ = refl

-- Fin 3 的下标怎么来？10 章全套：构造子、#_、fromℕ
i2 : Fin 3
i2 = # 2                        -- 类型检查期自动裁决 2 < 3

_ : lookup v3 i2 ≡ 30
_ = refl

_ : lookup v3 fzero ≡ 10
_ = refl

_ : lookup v3 (fromℕ 2) ≡ 30    -- fromℕ : (k : ℕ) → Fin (suc k)
_ = refl

-- 自己写「只有一行」的安全 head——覆盖率检查认可 [] 分支不存在：
head′ : ∀ {A : Set} {n} → Vec A (suc n) → A
head′ (x ∷ xs) = x

-- 想要「可能为空」的 head？把选择权交给类型：Maybe 版一行不缺
headMaybe : ∀ {A : Set} {n} → Vec A n → Maybe A
headMaybe {n = zero}  _      = nothing
headMaybe {n = suc n} (x ∷ _) = just x

------------------------------------------------------------------------
-- 16.3 append：索引算术直接写进类型
------------------------------------------------------------------------

-- stdlib：_++_ : Vec A m → Vec A n → Vec A (m + n)
--   []       ++ ys = ys
--   (x ∷ xs) ++ ys = x ∷ (xs ++ ys)
-- 为什么零 rewrite？结果索引 (m + n) 随第一个参数递归，
-- suc m + n **定义展开**成 suc (m + n)——「+ 按左参数递归」正好
-- 把递归方向做进了索引算术。
_ : (1 ∷ 2 ∷ []) ++ (3 ∷ []) ≡ 1 ∷ 2 ∷ 3 ∷ []
_ = refl

-- 反方向（结果索引 n + m）立刻撞墙——本章最痛一步，实录：
--   append′ (x ∷ xs) ys = x ∷ append′ xs ys
--   →  需要 Vec A (n + suc m)，手里是 Vec A (suc (n + m))
--   →  n + suc m 和 suc (n + m) 不定义相等（+ 不看右参数！）
-- 解药：rewrite +‑suc / +‑identityʳ 在类型层「移索引」。
append′ : ∀ {A : Set} {m n : ℕ} → Vec A m → Vec A n → Vec A (n + m)
append′ {m = zero}  {n}     []       ys rewrite +-identityʳ n = ys
append′ {m = suc m} {n}     (x ∷ xs) ys rewrite +-suc  n m    = x ∷ append′ xs ys

-- snoc：末尾加一个（16.2 预告的 _∷ʳ_ 在 stdlib 同样零 rewrite，
-- 因为索引是 suc n，不是 n + 1；下面证明它与 n + 1 的换算）
_ : (1 ∷ 2 ∷ []) ∷ʳ 3 ≡ 1 ∷ 2 ∷ 3 ∷ []
_ = refl

------------------------------------------------------------------------
-- 16.4 reverse：尾累加版的 sym rewrite（全章最痛实录）
------------------------------------------------------------------------

-- 目标：reverse′ : Vec A n → Vec A n，尾递归累加器。
-- 累加版辅助函数的正确索引是 (n + m)——剩余长度 + 已有长度？
-- 不：写 (m + n) 走不通，(n + m) 才顺手？实测两个方向：
--   go : Vec A m → Vec A n → Vec A (n + m)
--   go acc (x ∷ xs) = go (x ∷ acc) xs
-- 类型检查器：手里 (x ∷ acc) : Vec A (suc m)、xs : Vec A n，
-- 递归调用给 Vec A (n + suc m)，而目标 (suc n) + m ≡ suc (n + m)。
-- n + suc m ≇ suc (n + m)（又是「+ 按左参数递归」！）
-- 解药①：cons 枝 rewrite **sym** (+-suc n m)——反向等式把目标
-- 改写成手里那个形状（与 Coq 的 rewrite <- plus_n_Sm 完全同构）。
-- 解药②：外层 go [] xs 得 Vec A (n + 0)，配不上 Vec A n——
-- 此处**不能**在左端写 rewrite sym (+-identityʳ n)：rewrite 连上下文
-- 一起改写，xs : Vec A n 里的 n 也被换成 n + 0，账越算越大（实测
-- 报错 n + 0 != n，见文档 16.4）。改用 cast：显式递等式换索引，
-- 上下文纹丝不动。
reverse′ : ∀ {A : Set} {n} → Vec A n → Vec A n
reverse′ {A} {n = n} xs = cast (+-identityʳ n) (go [] xs)
  where
  go : ∀ {m n : ℕ} → Vec A m → Vec A n → Vec A (n + m)
  go acc [] = acc
  go {m} {suc n} acc (x ∷ xs) rewrite sym (+-suc n m) = go (x ∷ acc) xs

------------------------------------------------------------------------
-- 16.5 map/replicate/zip/unzip：保长函数全家
------------------------------------------------------------------------

map′ : ∀ {A B : Set} {n} → (A → B) → Vec A n → Vec B n
map′ f []       = []
map′ f (x ∷ xs) = f x ∷ map′ f xs

-- 保长：map 的索引 n 原样穿过类型——「长度不变」不是约定，是签名
_ : map′ suc v3 ≡ 11 ∷ 21 ∷ 31 ∷ []
_ = refl

_ : replicate 4 zero ≡ 0 ∷ 0 ∷ 0 ∷ 0 ∷ []   -- 个数写在第一个参数
_ = refl

_ : zip (1 ∷ 2 ∷ []) (true ∷ false ∷ []) ≡ (1 , true) ∷ (2 , false) ∷ []
_ = refl

-- unzip ∘ zip ≡ id：长度同步，zip 的两个参数共享同一个 n
zip∘unzip : ∀ {A B : Set} {n} (xs : Vec A n) (ys : Vec B n) →
            unzip (zip xs ys) ≡ (xs , ys)
zip∘unzip []       []       = refl
zip∘unzip (x ∷ xs) (y ∷ ys) rewrite zip∘unzip xs ys = refl

------------------------------------------------------------------------
-- 16.6 with 判定长度做 headOr——以及为什么 Vec 版可以不用 Dec
------------------------------------------------------------------------

-- List 版：空不空是**运行时**才知道的事（08 章）
headOrList : ∀ {A : Set} → A → List A → A
headOrList d []       = d
headOrList d (x ∷ xs) = x

-- Vec 版甲：长度做成显式参数，模式匹配直接裁决
headOr : ∀ {A : Set} → A → (n : ℕ) → Vec A n → A
headOr d zero    _       = d
headOr d (suc n) (x ∷ _) = x

-- Vec 版乙：隐式索引也能 with 一个**等式判定**逼出形状——
-- 体会 15 章的 Dec 在依赖匹配里怎么精化类型（yes 分支里 xs 被迫
-- 是 []，其证据荒谬；no 分支 [] 里证据荒谬，两边都一行不用算）：
headOrDec : ∀ {A : Set} {n} → A → Vec A n → A
headOrDec {A} {n} d xs with n ≟ zero | xs
... | yes () | (x ∷ xs)
... | no  ¬p | []                    = ⊥-elim (¬p refl)
... | yes _  | []                    = d
... | no  _  | (x ∷ xs)              = x

------------------------------------------------------------------------
-- 16.7 回到 List：forget/flow 双向换算 + 往返定律
------------------------------------------------------------------------

-- forget：丢长度（stdlib 同名 toList）
forget : ∀ {A : Set} {n} → Vec A n → List A
forget []       = []
forget (x ∷ xs) = x ∷ forget xs

-- flow：从长度找回索引（stdlib 同名 fromList——索引 (length xs)
-- 是「由输入算出来的类型」，依赖编程的招牌句式）
flow : ∀ {A : Set} (xs : List A) → Vec A (length xs)
flow []       = []
flow (x ∷ xs) = x ∷ flow xs

_ : forget (10 ∷ 20 ∷ []) ≡ 10 ∷ 20 ∷ []
_ = refl

_ : flow (10 ∷ 20 ∷ []) ≡ 10 ∷ 20 ∷ []   -- RHS 是 Vec（分派正确）
_ = refl

-- 往返定律①：Vec → List → Vec 不改变结构。
-- 难点：归纳假设里 v : Vec A n，而目标是 flow (forget v) : Vec A
-- (length (forget v))——两个索引 n 和 length (forget v) 里后者在
-- 归纳步骤中是变量 v，**化简不动**！先试普通等式，实测两条路都死：
--   flow∘forget (x ∷ v) = cong (x ∷_) (flow∘forget v)
--   →  n != length (forget v)  (stuck on variable v)
--   flow∘forget (x ∷ v) rewrite sym (len-forget v) = cong (x ∷_) …
--   →  rewrite 把上下文里 v : Vec A n 也改成 Vec A (length (forget v))，
--      递归调用立刻对不上号（见文档 16.7 实录）。
-- 先单证「索引账本」引理（这条本身能归纳证明）：
len-forget : ∀ {A : Set} {n} (v : Vec A n) → length (forget v) ≡ n
len-forget []       = refl
len-forget (x ∷ v)  = cong suc (len-forget v)

-- stdlib 的正解（Data.Vec.Properties 的 fromList∘toList 原样同款）：
-- 定理陈述本身把 cast 折进相等式。_≈[_]_ 来自
-- Data.Vec.Relation.Binary.Equality.Cast：
--   xs ≈[ eq ] ys  =  cast eq xs ≡ ys
-- 妙处在于 cast 的等式参数声明为**不相关**（.(eq : m ≡ n)），
-- 类型比较时不追究「哪个证明」，cong (x ∷_) 直接过关——
-- 上面的 len-forget 从「挡路的 rewrite」变成「喂给 ≈[] 的账本」。
open import Data.Vec.Relation.Binary.Equality.Cast using (_≈[_]_)

flow∘forget : ∀ {A : Set} {n} (v : Vec A n) → flow (forget v) ≈[ len-forget v ] v
flow∘forget []       = refl
flow∘forget (x ∷ v)  = cong (x ∷_) (flow∘forget v)

-- 往返定律②：List → Vec → List 恒等
forget∘flow : ∀ {A : Set} (xs : List A) → forget (flow xs) ≡ xs
forget∘flow []       = refl
forget∘flow (x ∷ xs) = cong (x ∷_) (forget∘flow xs)

-- 换算不折腾索引：flow 的类型里 length xs 是**计算**出来的——
-- 给什么长度进什么索引，这就是「类型即命题」的日常形态。

------------------------------------------------------------------------
-- 16.8 证明即索引：tabulate/allFin 与类型级计算小结
------------------------------------------------------------------------

-- Fin n 的下标函数与 Vec 互转：tabulate 是「用函数造表」
squares : Vec ℕ 4
squares = tabulate (λ i → toℕ i * toℕ i)

_ : squares ≡ 0 ∷ 1 ∷ 4 ∷ 9 ∷ []
_ = refl

-- allFin：Fin n 的全部 n 个居民排成一张表——「有多少证明」
-- 与「索引是多少」是同一件事的两面。
_ : allFin 3 ≡ fzero ∷ fsuc fzero ∷ fsuc (fsuc fzero) ∷ []
_ = refl

_ : lookup (allFin 3) (# 2) ≡ fsuc (fsuc fzero)
_ = refl

-- 本章世界观收束：
--   Fin 3 ≃ {0,1,2}：索引 = 小于 n 的证明
--   Vec A 3 ≃ 长度恰为 3 的表：索引 = 长度计算的结果
-- 两者都把「证明」搬进了类型——类型检查器顺手就把数不对的
-- 程序拒收（越界、错长、zip 不齐——全章一条 Fail 都不需要）。
