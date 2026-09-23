-- 第 07 章示例：递归与终止检查
-- 全部声明都真实通过 agda 2.8.0 + stdlib 2.3 类型检查。
-- 文中以「实测失败」标注的写法只以注释形式存在——它们是终止检查器
-- 拒绝的对象，放进正文会让整个文件检查不过。

module Ex07_recursion where

open import Data.Nat using (ℕ; zero; suc; _+_; _<_; _/_; ⌊_/2⌋)
open import Data.Bool using (Bool; true; false)
open import Data.List using (List; []; _∷_)
open import Data.Maybe.Base using (Maybe; just; nothing; _>>=_)
open import Data.Nat.Induction using (<-rec; <-wellFounded)
open import Data.Nat.Properties using (⌊n/2⌋<n)
open import Induction.WellFounded using (Acc; acc)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

------------------------------------------------------------------------
-- 1. 结构递归：递归参数必须是「模式里拆出来的更小变量」

-- 在第二个参数上递归同样合法（缩小的是被模式覆盖的那个参数）：
_∸′_ : ℕ → ℕ → ℕ
m     ∸′ zero    = m
zero  ∸′ suc n   = zero
suc m ∸′ suc n   = m ∸′ n

_ : 5 ∸′ 2 ≡ 3
_ = refl

_ : 2 ∸′ 5 ≡ 0
_ = refl

-- 2. with 把递归结果变成可匹配的对象
--    老式记法：续行点号 `...`（2.8.0 实测接受且不告警；stdlib 里仍大量在用）

double-with : ℕ → ℕ
double-with zero = zero
double-with (suc n) with double-with n
... | m = suc (suc m)

--    现代记法：with 子句重复完整左侧模式（stdlib 的新代码风格）

double-modern : ℕ → ℕ
double-modern zero = zero
double-modern (suc n) with double-modern n
double-modern (suc n) | m = suc (suc m)

_ : double-with 3 ≡ 6
_ = refl

_ : double-modern 4 ≡ 8
_ = refl

-- 一步剥两层（在 suc (suc n) 模式里递归到变量 n）——合法。
-- 这正是 stdlib 里 ⌊_/2⌋ 的写法（half 就是向下取整除二）：

half : ℕ → ℕ
half zero = zero
half (suc zero) = zero
half (suc (suc n)) = suc (half n)

_ : half 7 ≡ 3
_ = refl

_ : half 8 ≡ 4
_ = refl

-- 3. 互递归：调用环上「总和」在缩小即可（even/odd 各剥一层）

mutual
  even : ℕ → Bool
  even zero = true
  even (suc n) = odd n

  odd : ℕ → Bool
  odd zero = false
  odd (suc n) = even n

_ : even 10 ≡ true
_ = refl

_ : odd 10 ≡ false
_ = refl

------------------------------------------------------------------------
-- 4. 树上的互递归：把「子列表」显式拆成互递归伙伴
--    反例（实测 TerminationIssue）：
--      size-bad : Tree → ℕ
--      size-bad (node ts) = suc (sum (map size-bad ts))
--    终止检查器看不见 map 只对表的骨架递归，报错把「被当作参数传走的
--    size-bad」整个列为 Problematic call。

data Tree : Set where
  node : List Tree → Tree

mutual
  size : Tree → ℕ
  size (node ts) = suc (sizeList ts)

  sizeList : List Tree → ℕ
  sizeList [] = zero
  sizeList (t ∷ ts) = size t + sizeList ts

-- 实测的另一种失败（注释）：嵌套递归参数不是模式变量
--   f-bad : ℕ → ℕ
--   f-bad zero = zero
--   f-bad (suc n) = f-bad (f-bad n)
-- 哪怕加 {-# OPTIONS --termination-depth=2 #-} 也照样不过
--（termination-depth 微调的是「增减计数」，不是放行任意嵌套调用的许可证）。

t1 : Tree
t1 = node []

t2 : Tree
t2 = node (t1 ∷ t1 ∷ [])

_ : size t2 ≡ 3
_ = refl

_ : sizeList (t2 ∷ t1 ∷ []) ≡ 4
_ = refl

------------------------------------------------------------------------
-- 5. 度量递归（well-founded recursion）：拿 ℕ 的 _<_ 当终止论据
--    方式一：对 Acc _<_ n 证明本身做结构递归——递归论据从「数据」
--    换成了「良基性的证据」。

⌊log2⌋-acc : (n : ℕ) → Acc _<_ n → ℕ
⌊log2⌋-acc zero _ = zero
⌊log2⌋-acc (suc zero) _ = zero
⌊log2⌋-acc (suc n′@(suc n)) (acc rs) =
  suc (⌊log2⌋-acc (suc ⌊ n /2⌋) (rs (⌊n/2⌋<n n′)))

⌊log2⌋′ : ℕ → ℕ
⌊log2⌋′ n = ⌊log2⌋-acc n (<-wellFounded n)

_ : ⌊log2⌋′ 1 ≡ zero
_ = refl

_ : ⌊log2⌋′ 8 ≡ 3
_ = refl

--    方式二：stdlib 打包好的不动点组合子 <-rec
--    （第一个显式参数是「逐点返回值」的谓词 P : ℕ → Set）

⌊log2⌋″ : ℕ → ℕ
⌊log2⌋″ = <-rec (λ _ → ℕ) step
  where
    step : (n : ℕ) → ({ m : ℕ } → m < n → ℕ) → ℕ
    step zero _ = zero
    step (suc zero) _ = zero
    step (suc n′@(suc n)) rec = suc (rec {m = suc ⌊ n /2⌋} (⌊n/2⌋<n n′))

_ : ⌊log2⌋″ 8 ≡ 3
_ = refl

_ : ⌊log2⌋′ 16 ≡ ⌊log2⌋″ 16
_ = refl

------------------------------------------------------------------------
-- 6. fuel：把「算不完」显式编码进返回类型 Maybe

data Expr : Set where
  val : ℕ → Expr
  _⟨+⟩_ : Expr → Expr → Expr
  _⟨÷⟩_ : Expr → Expr → Expr

-- 除以零是「部分」的：没有足够证据就说 nothing。
divMaybe : ℕ → ℕ → Maybe ℕ
divMaybe x (suc d) = just (x / suc d)
divMaybe x zero = nothing

eval : ℕ → Expr → Maybe ℕ
eval zero _ = nothing
eval (suc fuel) (val n) = just n
eval (suc fuel) (a ⟨+⟩ b) =
  eval fuel a >>= λ x → eval fuel b >>= λ y → just (x + y)
eval (suc fuel) (a ⟨÷⟩ b) =
  eval fuel a >>= λ x → eval fuel b >>= λ y → divMaybe x y

-- fuel 够：算出结果
_ : eval 5 (val 3 ⟨+⟩ val 4) ≡ just 7
_ = refl

-- fuel 耗尽：诚实返回 nothing，而不是卡死
_ : eval 0 (val 3 ⟨÷⟩ val 0) ≡ nothing
_ = refl

-- 嵌套深度超过燃料：也返回 nothing
_ : eval 1 ((val 1 ⟨+⟩ val 2) ⟨+⟩ val 3) ≡ nothing
_ = refl

-- 除零的「部分性」与燃料无关，永远 nothing
_ : eval 9 (val 8 ⟨÷⟩ val 0) ≡ nothing
_ = refl

_ : eval 9 (val 8 ⟨÷⟩ val 3) ≡ just 2
_ = refl

------------------------------------------------------------------------
-- 7. 逃生门速写（都实测过；这里只留注释，理由见正文「代价」一节）
--
-- {-# OPTIONS --no-termination-check #-}   全局关掉，连 stdlib 也照关不误
-- {-# OPTIONS --partial-definitions #-}    实测：Unrecognized option
--                                          （--help 里对应的是
--                                           --allow-incomplete-matches 等）
-- {-# NON_TERMINATING #-}  单个函数免检——下面这个能「证明」⊥：
--   bad : ∀ {A : Set} → A
--   bad = bad
-- 开 --safe 后，NON_TERMINATING/TERMINATING/postulate 一律被拒
-- （SafeFlagPostulate / SafeFlagNonTerminating / SafeFlagTerminating）。
