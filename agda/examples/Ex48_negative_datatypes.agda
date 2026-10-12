------------------------------------------------------------------------
-- 第 48 章配套示例：负类型与 strict positivity 检查
--
-- 承接 07 章（终止检查）与 43 章第 104 条（--safe 是日常体检），这一章讲
-- Agda 的另一道守门检查：**数据类型的正性**。原书 9.1.4 用它演示「如果
-- Agda 允许数据类型出现在函数箭头的左边会发生什么」，本章把那段内容扩成
-- 一次完整的实测：
--   ① 对照组：带函数域的类型完全合法（坏消息不是「函数域」，是「自指」）；
--   ② 负类型 Bad → 三行代码造出 ⊥ 的居民 → 一切命题可证；
--   ③ 为什么终止检查器救不了这次事故（badFunc 里没有递归调用）；
--   ④ 双重否定（positive 但不 strictly positive）默认同样被拒；
--   ⑤ record 版本：positivity 之外还有 ETA_EQUALITY 与 coinductive 两道门；
--   ⑥ 关掉检查的两种粒度：文件级 OPTIONS 与声明级 NO_POSITIVITY_CHECK。
--
-- 移植与升级说明（原书 Agda 2.2.14 → 本机 2.9.0 + stdlib 3.0）：
--  * 原书用 `{-# OPTIONS --no-positivity-check #-}`，2.9.0 这个选项**仍在**，
--    但网上常见的 `--unchecked-positivity` 在本机是 `Unrecognized option`
--    （实测，见本章坑位清单）；
--  * 原书说「positivity 会允许偶数个箭头」——那是理论上的正性；Agda 实现的
--    是**严格**正性，双重否定照样被拒（实测）；
--  * 原书用 IAL 的 `K`（空类型），这里换成 stdlib 的 `⊥`；
--  * 本章示例文件**不开**文件级的 positivity 开关，只用声明级的
--    `{-# NO_POSITIVITY_CHECK #-}`——每个坏类型都得当场签字，这正是
--    「显式承担责任」的写法（文件级 `--no-positivity-check` 见正文 48.6）；
--    文件头那个 `--guardedness` 是给第 ④ 节的 coinductive record 用的，
--    与 positivity 无关。
--
-- 一条重要的复现提示：正文 48.4 那段「类型检查器自己跑飞」的代码**不能**
-- 放进本文件——它会把 `agda` 拖进无界归约（实测 40 秒不返回，被 SIGALRM
-- 杀掉，退出码 142）。本文件只保留能通过类型检查的部分。
--
-- 类型检查：cd agda && ./build.sh Ex48_negative_datatypes
------------------------------------------------------------------------

{-# OPTIONS --guardedness #-}

module Ex48_negative_datatypes where

open import Data.Empty using (⊥; ⊥-elim)
open import Data.Nat using (ℕ; zero; suc)
open import Data.Product using (_×_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

------------------------------------------------------------------------
-- ① 对照组：函数域本身完全合法
------------------------------------------------------------------------

-- 「构造子带一个函数域」从来不是问题。下面这个类型把 ℕ → ℕ 整个装进
-- 数据里，strict positivity 检查全程沉默——因为 FunBox 自己没出现在任何
-- 箭头的左边。
data FunBox : Set where
  box : (ℕ → ℕ) → FunBox

unbox : FunBox → ℕ → ℕ
unbox (box f) = f

funbox-test : unbox (box suc) zero ≡ suc zero
funbox-test = refl

-- 真正的递归数据也一律安全：出现的每一处都在箭头的**右边**。
data Tree : Set where
  leaf : Tree
  node : Tree × Tree → Tree

-- 甚至「对另一个类型取函数」也行，只要那个类型不是自己。
data Ctx : Set where
  cxt : (Tree → ⊥) → Ctx

-- 连**递归**类型带函数域都可以——关键在于箭头左边不能是它自己。
-- RV 是归纳的、自指的（num/fn 都造 RV），但 fn 收的是 `ℕ → RV`，
-- RV 在箭头右边（正出现），检查照样放行。
data RV : Set where
  num : ℕ → RV
  fn  : (ℕ → RV) → RV

headRV : RV → RV
headRV (num n) = num n
headRV (fn f)  = f zero

rv-test : headRV (fn (λ n → num (suc n))) ≡ num (suc zero)
rv-test = refl

------------------------------------------------------------------------
-- ② 负类型：三行代码把整个逻辑炸掉
------------------------------------------------------------------------

-- Bad 的唯一构造子接收一个 `Bad → ⊥`——Bad 出现在箭头**左边**，这就是
-- 「负出现」（术语借自逻辑：A ⊃ B 里 A 是负出现，因为 A ⊃ B ≡ ¬A ∨ B）。
-- 默认的 strict positivity 检查会当场拒绝；这里用声明级开关放行，
-- 好把后面的事故全部跑完。
{-# NO_POSITIVITY_CHECK #-}

data Bad : Set where
  bad : (Bad → ⊥) → Bad

-- 事故一：自应用。badFunc 接一个 Bad，拆出其中的函数 f : Bad → ⊥，
-- 然后把**手上这个 Bad**（bad f）喂给 f。注意这里没有递归调用——
-- 定义右侧出现的 badFunc 一个都没有，终止检查器无从插手。
badFunc : Bad → ⊥
badFunc (bad f) = f (bad f)

-- 事故二：把 badFunc 自己塞进 bad，得到一个闭合项，它就是 ⊥ 的居民。
-- 类型检查器只检查「它类型对不对」（对：bad badFunc : Bad，
-- badFunc : Bad → ⊥，应用结果 : ⊥），从不把它归约到底，于是顺利放行。
inconsistency : ⊥
inconsistency = badFunc (bad badFunc)

-- 事故三：⊥ 一旦有居民，⊥-elim 就能把任何命题「证」出来。
-- 这就是 Curry–Howard 侧的完全失效：Set 里所有内容不再互相区分。
-- （顺手一条实测：3.0 里 ⊥-elim 的隐式参数名不是 `A` 而是 `Whatever`，
-- 想点名它得写 `{Whatever = A}`，写 `{A = A}` 直接 WrongNamedArgument。）
evil : (A : Set) → A
evil A = ⊥-elim inconsistency

------------------------------------------------------------------------
-- ③ positive 但不 strictly positive：双重否定
------------------------------------------------------------------------

-- 理论上的「正性」允许类型出现在**偶数个**箭头左边（两次取反相互抵消），
-- 双重否定 ((Med → ⊥) → ⊥) 正是这种形状。原书 9.1.4 特别说明了这点。
--
-- 实测：Agda 2.9.0 实现的检查比理论更强——默认选项下这个定义同样报
-- `[NotStrictlyPositive]`（报错文案连「偶数个箭头」都不区分，见正文 48.3
-- 的原文）。下面靠声明级开关放行。
{-# NO_POSITIVITY_CHECK #-}

data Med : Set where
  med : ((Med → ⊥) → ⊥) → Med

-- 有意思的是：想从 Med 造 ⊥，得写**真递归**，而这一次终止检查器在岗。
-- 正文里那条 TerminationIssue 原文就是这么来的：positivity 与 termination
-- 是两道独立的门，关掉前者不会让后者失效。

------------------------------------------------------------------------
-- ④ record 版本：三道闸门一个一个过
------------------------------------------------------------------------

-- record 也受 positivity 检查（正文 48.5 有原文），而且它还要多过两道门：
-- 递归 record 的 η 相等（`{-# ETA_EQUALITY #-}`）与归纳性声明（`coinductive`，
-- 需要 --guardedness）。三道门全过，同样得到 ⊥ 的居民。
--
-- 注意 `{-# ETA_EQUALITY #-}` 是**裸写法**，不带类型名（带名字直接 ParseError，
-- 实测见坑位清单）；它作用于紧随其后的那个 record。
{-# NO_POSITIVITY_CHECK #-}
{-# ETA_EQUALITY #-}

record BadR : Set where
  coinductive
  field
    badR : BadR → ⊥

-- 拆 record 字段拿到函数，再拿这个 record 自己喂进去——和第 ② 节同构。
badFuncR : BadR → ⊥
badFuncR r = BadR.badR r r

inconsistencyR : ⊥
inconsistencyR = badFuncR (record { badR = badFuncR })

-- 到这里可以说清「为什么必须有这道检查」了：Agda 的数据类型是**归纳**定义，
-- 归纳意味着「有限次构造子应用得到的值」。允许负出现等于允许一个值把
-- 「如何从它自己造出它自己」当作构造参数携带，自应用就此诞生；
-- 而自应用既是矛盾（Curry–Howard 侧）又是发散（计算侧）。
-- 07 章的终止检查守的是**函数定义**那条线，positivity 守的是**数据类型声明**
-- 这条线；两条线各自独立，缺一个都可能被绕过去。
