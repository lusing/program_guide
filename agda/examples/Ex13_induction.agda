-- 第 13 章 · 归纳证明
-- 主题：归纳 = 递归函数；依赖消除视角；generalize 手艺；stdlib 对照。
-- 所有代码在 Agda 2.8.0 + stdlib 2.3 下真实类型检查通过。

module Ex13_induction where

open import Data.Nat using (ℕ; zero; suc; _+_)
open import Data.List using (List; _∷_; []; [_]; _++_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; cong)

------------------------------------------------------------------------
-- 1. 归纳 = 依赖消除：ℕ 的 recursor 视角
------------------------------------------------------------------------

-- 具体数值：算出来就行……
3+0≡3 : 3 + zero ≡ 3
3+0≡3 = refl

-- 但通项 n + zero ≡ n 算不动（_+_ 在第一个参数上递归，变量卡住右端）——
-- 于是需要本章主角：归纳。

-- 「证明 ∀ n → P n」的全部 apparatus 就是下面这个递归函数：
-- 给它 P zero（基例）和「P n → P (suc n)」（步例），它就能对任意 n 交货。
-- 注意 P 的第一个参数是 (ℕ → Set)——「族」而非「命题」，
-- 这正是归纳假设能随 n 变化的原因。
ℕ-ind : (P : ℕ → Set) → P zero → (∀ n → P n → P (suc n)) → (n : ℕ) → P n
ℕ-ind P base step zero    = base
ℕ-ind P base step (suc n) = step n (ℕ-ind P base step n)

-- 把 ∀ 命题写成 λ 就得到「命题族」P：证明 +idʳ 只是给 recursor 喂两个参数。
+-idʳ-via-ind : (n : ℕ) → n + zero ≡ n
+-idʳ-via-ind = ℕ-ind (λ n → n + zero ≡ n) refl (λ n ih → cong suc ih)

-- 直接写成递归函数（Agda 证明的常态：不显式调用 ind，模式匹配即消除）：
+-idʳ : (n : ℕ) → n + zero ≡ n
+-idʳ zero    = refl                      -- 基例：0 + zero → zero，两侧同形
+-idʳ (suc n) = cong suc (+-idʳ n)        -- 步例：+-idʳ n 就是归纳假设

------------------------------------------------------------------------
-- 2. generalize 的手艺：IH 太弱时把变量拉回参数表
------------------------------------------------------------------------

-- 例：(n + zero) + m ≡ n + m。
-- 写法 A：m 与 n 并列进参数表，递归调用时把 m 原样传下去——
-- 每个 (n , m) 一条等式，IH 天然够用。
+-0-absorb : (n : ℕ) (m : ℕ) → (n + zero) + m ≡ n + m
+-0-absorb zero    m = refl
+-0-absorb (suc n) m = cong suc (+-0-absorb n m)

-- 写法 B：where 里的内层函数——实测 Agda 2.8 的 where 子句
-- 左端可以引用外层子句的模式变量 m（相当于 Coq 的 intros 后再 induction，
-- 但 IH 被钉死在这个 m 上）。
+-0-absorb′ : (n : ℕ) (m : ℕ) → (n + zero) + m ≡ n + m
+-0-absorb′ n m = go n
  where
  go : (k : ℕ) → (k + zero) + m ≡ k + m   -- m 被「提前固化」：IH 只对这个 m 说话
  go zero    = refl
  go (suc k) = cong suc (go k)

-- 写法 B′：真正通用的 generalize——把 m 拉回 ∀ 里，
-- 内层匿名函数就是「∀ 假设」本体。
+-0-absorb″ : (n : ℕ) (m : ℕ) → (n + zero) + m ≡ n + m
+-0-absorb″ n = go n
  where
  go : (k : ℕ) → (o : ℕ) → (k + zero) + o ≡ k + o
  go zero    o = refl
  go (suc k) o rewrite go k o = refl

-- 「卡住的归纳」的修复版：∀ n → n + n + zero ≡ n + n。
-- 若对 n 归纳，步例需要的是「(n + suc n) + zero ≡ n + suc n」，
-- 而 IH 只谈 n + n——太弱（实测报错见教程正文）。
-- 正解：这种命题根本不用归纳——它就是 +-idʳ 在复合项 n + n 处的实例。
n+n+0 : ∀ n → n + n + zero ≡ n + n
n+n+0 n = +-idʳ (n + n)

-- 硬要归纳也可以：步例里现场把 ∀-引理实例到复合项上（Agda 版 generalize）。
n+n+0-ind : ∀ n → n + n + zero ≡ n + n
n+n+0-ind zero    = refl
n+n+0-ind (suc n) rewrite +-idʳ (n + suc n) = refl

-- with 抽象：先把复合子项提成变量再实例化（对应 Coq 的 remember/revert）。
n+n+0-with : ∀ n m → (n + m) + zero ≡ n + m
n+n+0-with n m with n + m
... | k = +-idʳ k

-- 等式方向决定 rewrite 成败：拿 n ≡ n + zero 去 rewrite，
-- 会把目标里所有裸 n 都膨胀成 n + zero（实测报错见正文）。
-- 正确做法：先 sym 摆正方向，或干脆 rewrite 时给全实例。
flip-direction : ∀ n → n ≡ n + zero
flip-direction zero    = refl
flip-direction (suc n) = cong suc (flip-direction n)

back-to-right : ∀ n → n + zero ≡ n
back-to-right n = sym (flip-direction n)

------------------------------------------------------------------------
-- 3. 交换律：双引理套路
------------------------------------------------------------------------

-- 引理 1（搬 S）：m + suc n ≡ suc (m + n)——对 m 归纳，方向顺手。
+-suc : (m n : ℕ) → m + suc n ≡ suc (m + n)
+-suc zero    n = refl
+-suc (suc m) n rewrite +-suc m n = refl

+-comm : (m n : ℕ) → m + n ≡ n + m
+-comm zero    n rewrite +-idʳ n = refl
+-comm (suc m) n rewrite +-comm m n | +-suc n m = refl
-- ↑ rewrite a | b 依次施加两个等式：先把 m + n 换成 n + m，
--   再把 n + suc m 折回 suc (n + m)。

------------------------------------------------------------------------
-- 4. 结合律 + 归纳变元的正确选择
------------------------------------------------------------------------

-- 对 m（递归纳在左侧）顺利；若对 o 归纳，基例 (m + n) + zero ≡ m + (n + zero)
-- 两侧都卡在「变量 + zero」上，refl 直接报错（实测见正文）。
+-assoc : (m n o : ℕ) → (m + n) + o ≡ m + (n + o)
+-assoc zero    n o = refl
+-assoc (suc m) n o rewrite +-assoc m n o = refl

------------------------------------------------------------------------
-- 5. 列表归纳：append 与 rev-rev（强化引理开路）
------------------------------------------------------------------------

-- 右单位元：定义在左参数上，右参数是 [] 就「动不了」→ 必须归纳。
++-nil : ∀ {A : Set} (xs : List A) → xs ++ [] ≡ xs
++-nil []       = refl
++-nil (x ∷ xs) rewrite ++-nil xs = refl

++-assoc′ : ∀ {A : Set} (xs ys zs : List A) →
            (xs ++ ys) ++ zs ≡ xs ++ (ys ++ zs)
++-assoc′ []       ys zs = refl
++-assoc′ (x ∷ xs) ys zs rewrite ++-assoc′ xs ys zs = refl

-- 本节的 reverse：教科书递归（stdlib 用累加器定义，见第 7 节对照）
rev : ∀ {A : Set} → List A → List A
rev []       = []
rev (x ∷ xs) = rev xs ++ [ x ]

-- 强化引理：rev 是 ++ 的反同态。ys 泛化在参数表里（generalize！），
-- 基例需要 ++-nil 实例到复合项 rev ys 上——泛化与引理复用同时登场。
rev-++ : ∀ {A : Set} (xs ys : List A) →
         rev (xs ++ ys) ≡ rev ys ++ rev xs
rev-++ []       ys rewrite ++-nil (rev ys) = refl
rev-++ (x ∷ xs) ys
  rewrite rev-++ xs ys | ++-assoc′ (rev ys) (rev xs) [ x ] = refl

-- 定理：rev 是自身的逆。步例把 rev-++ 实例到 (rev xs , [ x ])——
-- 「证明的难度分布由定义的形状决定」的又一体现。
rev-rev : ∀ {A : Set} (xs : List A) → rev (rev xs) ≡ xs
rev-rev []       = refl
rev-rev (x ∷ xs)
  rewrite rev-++ (rev xs) [ x ] | rev-rev xs = refl
-- 解释：rev (rev xs ++ [ x ]) --rev-++--> rev [ x ] ++ rev (rev xs)
--       --IH--> rev [ x ] ++ xs，其中 rev [ x ] 规约成 x ∷ []，refl 收尾。

------------------------------------------------------------------------
-- 6. 归纳假设的类型怎么看：递归调用即 IH（完全体）
------------------------------------------------------------------------

-- 下面这份「批注版」把每个成分对应回教科书归纳法：
--   要证  ∀ n → P n，其中 P := λ n → n + zero ≡ n
--   基例  P zero，即 refl : zero + zero ≡ zero
--   步例  ∀ n → P n → P (suc n)，即函数
--         λ n ih → cong suc ih，ih : n + zero ≡ n 正是归纳假设
+-idʳ-annotated : (n : ℕ) → n + zero ≡ n   -- ∀ n → P n
+-idʳ-annotated zero    = refl             -- base : P zero
+-idʳ-annotated (suc n) =                  -- step : P n → P (suc n)
  cong suc (+-idʳ-annotated n)             --        ↑ 递归调用即 IH

-- 同一手法：反同态引理的递归调用 rev-++ xs ys 的类型
-- `rev (xs ++ ys) ≡ rev ys ++ rev xs` 就是列表版「归纳假设」。

------------------------------------------------------------------------
-- 7. stdlib 对照：证明一次，读库百遍
------------------------------------------------------------------------

-- stdlib 的 ℕ/List 引理命名规律：
--   上标 ˡ/ʳ 标记「特殊的那侧」：+-identityˡ : zero + n ≡ n，
--   +-identityʳ : n + zero ≡ n；++-assoc / ++-identityʳ 同理。
--   证明脚本与本章逐字同构（读源码 Data/Nat/Properties.agda 第 543 行起）。

open import Data.Nat.Properties
  using () renaming (+-identityʳ to std-+-identityʳ; +-identityˡ to std-+-identityˡ
                   ; +-suc to std-+-suc; +-assoc to std-+-assoc
                   ; +-comm to std-+-comm)

-- 本章引理与 stdlib 同名命题「同型」——互相直接转写：
check-ʳ : ∀ n → n + zero ≡ n
check-ʳ = std-+-identityʳ

check-ˡ : ∀ n → zero + n ≡ n            -- 左单位元是纯计算，stdlib 也一行 refl
check-ˡ = std-+-identityˡ

check-suc : ∀ m n → m + suc n ≡ suc (m + n)
check-suc = std-+-suc

check-assoc : ∀ m n o → (m + n) + o ≡ m + (n + o)
check-assoc = std-+-assoc

check-comm : ∀ m n → m + n ≡ n + m
check-comm = std-+-comm

-- 列表侧：stdlib 的 reverse 用累加器 reverseAcc（即 _ʳ++_）定义，
-- 于是它的反同态/对合引理也按累加器路线组织：
open import Data.List
  renaming (reverse to std-reverse)    -- 与本章 rev 区分
open import Data.List.Properties
  using () renaming (++-identityʳ to std-++-nil; ++-assoc to std-++-assoc
                   ; reverse-++ to std-rev-++; reverse-involutive to std-rev-rev)

check-++-nil : ∀ {A : Set} (xs : List A) → xs ++ [] ≡ xs
check-++-nil = std-++-nil

check-++-assoc : ∀ {A : Set} (xs ys zs : List A) →
                 (xs ++ ys) ++ zs ≡ xs ++ (ys ++ zs)
check-++-assoc = std-++-assoc

check-rev-++ : ∀ {A : Set} (xs ys : List A) →
               std-reverse (xs ++ ys) ≡ std-reverse ys ++ std-reverse xs
check-rev-++ = std-rev-++

check-rev-rev : ∀ {A : Set} (xs : List A) →
                std-reverse (std-reverse xs) ≡ xs
check-rev-rev = std-rev-rev
