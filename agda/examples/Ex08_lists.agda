-- 第 08 章示例：列表专题
-- 全部声明都真实通过 agda 2.8.0 + stdlib 2.3 类型检查；
-- 「实测失败」的写法只以注释存在（放进正文会挂整个文件）。

module Ex08_lists where

open import Data.Nat using (ℕ; zero; suc; _+_; _*_; _<?_)
open import Data.List using
  (List; []; _∷_; _++_; map; filter; filterᵇ; zipWith; concat; foldr; foldl;
   reverse; reverseAcc; length; [_])
open import Data.Bool using (Bool; true; false)
open import Data.Product using (_,_; _×_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

------------------------------------------------------------------------
-- 1. 解剖：List 是「参数化 data」，构造子只有一元 [] 和二元 _∷_
--    stdlib 的 List 就是内建 Agda.Builtin.List 的重命名导出：
--      data List {a} (A : Set a) : Set a where
--        []  : List A
--        _∷_ : (x : A) (xs : List A) → List A   -- infixr 5
--    下面自带一份逐字同构的 MyList，用来对照「参数 {A} 去哪了」：
--    构造子的类型里 A 是**外层参数**，所以签名里根本看不到 (A : Set)。

data MyList (A : Set) : Set where
  m[]  : MyList A
  _m∷_ : A → MyList A → MyList A
infixr 5 _m∷_

toMy : List ℕ → MyList ℕ
toMy [] = m[]
toMy (x ∷ xs) = x m∷ toMy xs

fromMy : MyList ℕ → List ℕ
fromMy m[] = []
fromMy (x m∷ xs) = x ∷ fromMy xs

lit : List ℕ
lit = 1 ∷ 2 ∷ 3 ∷ []

_ : fromMy (toMy lit) ≡ lit
_ = refl

------------------------------------------------------------------------
-- 2. 「列表字面量」的真相：2.8 没有 [1,2,3]，只有单元素函数 [_]
--    实测反例（注释）：bad : List ℕ; bad = [ 1 , 2 , 3 ]
--    报 Not in scope: [ —— 因为 [ ... ] 是 mixfix 名字 [_]，
--    而 [_ , _] 里的逗号是 Data.Product 的配对构造子：

one : List ℕ
one = [ 42 ]                -- 即 42 ∷ []

tricky : List (ℕ × ℕ)
tricky = [ 1 , 2 ]          -- 单元素列表，元素是**对** (1 , 2)！

_ : tricky ≡ (1 , 2) ∷ []
_ = refl

------------------------------------------------------------------------
-- 3. 常用操作：都能算，也都以 refl 焊死

_ : map suc lit ≡ 2 ∷ 3 ∷ 4 ∷ []
_ = refl

even? : ℕ → Bool
even? zero = true
even? (suc zero) = false
even? (suc (suc n)) = even? n

-- filter 要「可判定的证明」，Bool 版另有名字 filterᵇ：
_ : filter (λ n → n <? 3) lit ≡ 1 ∷ 2 ∷ []
_ = refl

_ : filterᵇ even? lit ≡ 2 ∷ []
_ = refl

-- zipWith 遇短截断（长出来的尾巴直接丢）：
_ : zipWith _+_ (1 ∷ 2 ∷ 3 ∷ []) (10 ∷ 20 ∷ []) ≡ 11 ∷ 22 ∷ []
_ = refl

_ : concat (lit ∷ [] ∷ one ∷ []) ≡ 1 ∷ 2 ∷ 3 ∷ 42 ∷ []
_ = refl

_ : length lit ≡ 3
_ = refl

-- 裸 [] 的元素类型没人认领：`length []` 实测 UnsolvedMetaVariables，
-- 连「fixed : ℕ; fixed = length []」带签名也救不了（签名约束的是结果类型）。
-- 正解是显式填隐式参：
fixed : ℕ
fixed = length {A = ℕ} []

_ : fixed ≡ 0
_ = refl

------------------------------------------------------------------------
-- 4. _++_：在**左**参数上递归 → 左单位是 definitional 的，右单位不是
--    （右单位对开口变量要归纳，第 13 章见；对闭列表则全都能算出来）

++-left-id : ∀ {A : Set} (xs : List A) → [] ++ xs ≡ xs
++-left-id xs = refl

-- 实测反例（注释）：对开口变量 xs 用 refl 证右单位：
--   ++-right-id : ∀ {A : Set} (xs : List A) → xs ++ [] ≡ xs
--   ++-right-id xs = refl
-- 报错 [UnequalTerms]  xs ++ [] != xs of type List A

_ : lit ++ [] ≡ lit   -- 闭列表：归约得动，refl 就行
_ = refl

-- infixr 5：多条 ∷/++ 链一律往右梳
_ : 1 ∷ 2 ∷ [] ++ 3 ∷ [] ≡ 1 ∷ 2 ∷ 3 ∷ []
_ = refl

------------------------------------------------------------------------
-- 5. foldr / foldl：参数顺序与 Haskell 相同（函数、种子、列表），
--    但 Agda 严格求值，foldr 攒不出 Haskell 那样的惰性短路

_ : foldr _+_ 0 lit ≡ 6
_ = refl

_ : foldl (λ acc n → acc * 10 + n) 0 lit ≡ 123
_ = refl

-- foldr _∷_ [] 是恒等（种子是 []，把 ∷ 摊回去）：
_ : foldr _∷_ [] lit ≡ lit
_ = refl

------------------------------------------------------------------------
-- 6. 反转三写法：naive（每层 ++ 重抄左边）、累加器、以及标准库版

revNaive : ∀ {A : Set} → List A → List A
revNaive [] = []
revNaive (x ∷ xs) = revNaive xs ++ [ x ]

revAcc′ : ∀ {A : Set} → List A → List A → List A
revAcc′ acc [] = acc
revAcc′ acc (x ∷ xs) = revAcc′ (x ∷ acc) xs

revAccum : ∀ {A : Set} → List A → List A
revAccum xs = revAcc′ [] xs

_ : revNaive lit ≡ 3 ∷ 2 ∷ 1 ∷ []
_ = refl

_ : revAccum lit ≡ reverse lit
_ = refl

-- stdlib 的 reverse 就是 reverseAcc []，且 reverseAcc 是 foldl (flip _∷_)：
_ : reverseAcc one lit ≡ 3 ∷ 2 ∷ 1 ∷ 42 ∷ []
_ = refl

-- 累加器版本的「分配律」实例（一般陈述需要归纳，第 13 章）：
_ : revNaive (lit ++ one) ≡ reverse (lit ++ one)
_ = refl

_ : reverse (lit ++ one) ≡ reverse one ++ reverse lit
_ = refl

------------------------------------------------------------------------
-- 7. 预告 16 章：把长度写进类型，隐式参数 {n} 立刻开始「碍事」也立刻开始救场

module VecPreview where
  open import Data.Nat using (ℕ; zero; suc; _+_)
  open import Relation.Binary.PropositionalEquality using (_≡_; refl)
  data Vec (A : Set) : ℕ → Set where
    v[] : Vec A zero
    _v∷_ : {n : ℕ} → A → Vec A n → Vec A (suc n)
  infixr 5 _v∷_

  _v++_ : ∀ {A : Set} {n m : ℕ} → Vec A n → Vec A m → Vec A (n + m)
  v[]      v++ ys = ys
  (x v∷ xs) v++ ys = x v∷ (xs v++ ys)

  v3 : Vec ℕ 3
  v3 = 1 v∷ 2 v∷ 3 v∷ v[]

  _ : v3 v++ (4 v∷ v[]) ≡ 1 v∷ 2 v∷ 3 v∷ 4 v∷ v[]
  _ = refl

  _ : v[] v++ v3 ≡ v3    -- 左单位仍是 definitional
  _ = refl

  -- 实测反例（注释）：oops = v[] v++ v[]   → [UnsolvedMetaVariables]
  -- 两个隐式长度没人能定出来。
  -- 实测反例（注释）：wrong : Vec ℕ 4; wrong = 1 v∷ 2 v∷ 3 v∷ v[]
  --   → [UnequalTerms] 0 != 1  of type ℕ （拆到 v[] 时长度对不上）
  -- 长度进类型后，append 的结果类型 Vec A (n + m) 自动「记账」。
