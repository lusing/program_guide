-- 第 49 章 · bracket abstraction：把 λ 抽象编译成 SK 组合子
-- 主题：带变量的组合子语法、最小的 λ 消除算法 λ*、它「消掉变量」与
--       「行为等价」两条正确性定理、传递闭包模块 tc 与多步归约 ↝⁺、
--       同余引理为什么要对归约序列归纳。
-- 所有代码在 Agda 2.9.0 + stdlib 3.0 下真实类型检查通过。
-- 取材：Aaron Stump《Verified Functional Programming in Agda》9.2.4
--       （图 9.12–9.19：varcomb / λ* / contains-var / subst / tc / λ*↝）。
-- 版本差异：原书的 `=string` 在 stdlib 3.0 是 Data.String 的 Bool 版 `_==_`
--       （决策过程是 `_≡?_`，`_≟_` 已在 3.0 弃用）；closures.agda 的
--       module basics 在这里改名 Closure；原书 comb 不含变量，本章按书的
--       做法另起一个 varcomb 上的归约关系，不回头改 35 章。
-- 一个先说清的事实：λ* 按 varcomb 的结构递归，λ*-↝ 按 v₁ 的结构归纳，
--       同余引理按归约序列的结构归纳——三处都不需要 35 章那套 Acc 机器，
--       所以本文件除了 --safe 之外不挂任何选项（无 postulate、无逃生门）。

{-# OPTIONS --safe #-}

module Ex49_bracket_abstraction where

open import Data.Bool using (Bool; true; false; _∨_; if_then_else_)
open import Data.Nat using (ℕ; suc; _+_)
open import Data.Product using (Σ; _,_)
open import Data.String using (String; _==_)
open import Relation.Binary.Definitions using (Transitive)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

------------------------------------------------------------------------
-- 1. 带变量的组合子
------------------------------------------------------------------------

-- 35 章的 comb 只有 S、K、app 三个构造子，没有变量，因此表达不了
-- 「参数还没定值的那半个函数」。照书加一个 var：变量的类型随便选，
-- 这里用 String，反正它只参与名字比较，不参与任何逻辑。
data varcomb : Set where
  S K : varcomb
  app : (a b : varcomb) → varcomb
  var : (s : String) → varcomb

-- 书里的例子：项 S K x 写成
S-K-x : varcomb
S-K-x = app (app S K) (var "x")

------------------------------------------------------------------------
-- 2. 小步语义：规则与 35 章同名，宿主类型换成 varcomb
------------------------------------------------------------------------

infix 4 _↝_
data _↝_ : varcomb → varcomb → Set where
  ↝K : ∀ a b → app (app K a) b ↝ a
  ↝S : ∀ a b c → app (app (app S a) b) c ↝ app (app a c) (app b c)
  ↝C1 : ∀ {a a′} (b : varcomb) → a ↝ a′ → app a b ↝ app a′ b
  ↝C2 : (a : varcomb) → ∀ {b b′} → b ↝ b′ → app a b ↝ app a b′

-- 为什么不 import 35 章的 _↝_ 复用：它住在 comb → comb → Set，
-- 而这里左右两端都必须是 varcomb。作者在书里自己也承认这是
-- 「令人遗憾的重复」，取舍是让前面的开发不背索引参数的负担。
-- 值得背下来的反面知识是：**规则的形状**可以参数化（见第 6 节 tc），
-- 关系的**类型**却不容易跟着参数走——除非把 S/K/app 也提成参数。

-- 后面每条定理都要用到「K 忽略第二个参数」这个动作，先钉一发：
K-drops : ∀ (a : varcomb) → app (app K S) a ↝ S
K-drops a = ↝K S a

------------------------------------------------------------------------
-- 3. bracket abstraction：λ* 把 λ 抽象编译成组合子
------------------------------------------------------------------------

-- λ* s v 返回一个不含变量 s、行为等同 λs.v 的组合子。四条方程就是
-- 消元的全部知识：与 s 无关的体（S、K、未命中的变量）一律加 K 前缀
-- 「忽略参数」；命中变量返回 S K K（恒等）；应用用 S 把参数分给两侧。
λ* : (s : String) → varcomb → varcomb
λ* s S = app K S
λ* s K = app K K
λ* s (app c₁ c₂) = app (app S (λ* s c₁)) (λ* s c₂)
λ* s (var s′) = if s == s′ then app (app S K) K else app K (var s′)

-- 第一条方程读法：λs.S 是「给什么都返回 S」，而 app K S 拿到参数 a 时
-- 由 ↝K 直接吐回 S。K 的全部用途就是造常数函数。

------------------------------------------------------------------------
-- 4. 第一条正确性定理：变量确实被消掉了
------------------------------------------------------------------------

contains-var : String → varcomb → Bool
contains-var s S = false
contains-var s K = false
contains-var s (app c₁ c₂) = contains-var s c₁ ∨ contains-var s c₂
contains-var s (var s′) = s == s′

-- keep 把「值 + 它等于自己的等式」打包成一对（19 章第 4 节；stdlib 里
-- 同一个主意的现代拼写是 Function.Inspect 的 inspect）。裸 with 只能
-- 分到 true/false，等式就丢了，rewrite 没料可用——报错现场见 49.11 坑位 2。
keep : ∀ {A : Set} (x : A) → Σ A (λ y → x ≡ y)
keep x = x , refl

λ*-binds : ∀ (s : String) (v : varcomb) → contains-var s (λ* s v) ≡ false
λ*-binds s S = refl
λ*-binds s K = refl
λ*-binds s (app c₁ c₂) rewrite λ*-binds s c₁ | λ*-binds s c₂ = refl
λ*-binds s (var s′) with keep (s == s′)
λ*-binds s (var s′) | true , p rewrite p = refl
λ*-binds s (var s′) | false , p rewrite p = p

-- 变量分支两种情形：命中时 λ* 产出 app (app S K) K，里面没有变量，refl
-- 收工；没命中时产出 app K (var s′)，目标规约成 (s == s′) ≡ false——
-- 手上那条 p 正好是这个类型，所以最后一行写 `= p` 而不是 `= refl`
-- （rewrite 只换掉它认得的那一份 s == s′，第二份留着，实测见 49.11 坑位 3）。

------------------------------------------------------------------------
-- 5. 替换：β 的另一半
------------------------------------------------------------------------

-- 把 c 代进 c′ 中出现的变量 s。参数顺序（被代入的项在最前）照书。
subst : varcomb → String → varcomb → varcomb
subst c s S = S
subst c s K = K
subst c s (app c₁ c₂) = app (subst c s c₁) (subst c s c₂)
subst c s (var s′) = if s == s′ then c else var s′

-- 替换算给谁看：λ 演算里 (λs.c′) 的体 c′ 可能含 s，β 规约就是代入。
subst-demo : subst (var "y") "x" (app (var "x") (var "z")) ≡
             app (var "y") (var "z")
subst-demo = refl

subst-miss : subst (var "y") "x" (app (app S K) (var "z")) ≡
             app (app S K) (var "z")
subst-miss = refl

------------------------------------------------------------------------
-- 6. 传递闭包：从一步归约到多步归约
------------------------------------------------------------------------

-- 原书住在 closures.agda 的 module basics，参数化在「一个类型 + 该类型上
-- 的一个二元关系」；这里改名 Closure，实例化到 varcomb 上的 ↝。
module Closure {A : Set} (_>_ : A → A → Set) where
  data tc : A → A → Set where
    tc-step : ∀ {a b} → a > b → tc a b
    tc-trans : ∀ {a b c} → tc a b → tc b c → tc a c

open Closure _↝_

infix 4 _↝⁺_
_↝⁺_ : varcomb → varcomb → Set
_↝⁺_ = tc

-- 一步自动是多步：书的证明里到处写 lift，这里同样给个别名。
lift : ∀ {a b} → a ↝ b → a ↝⁺ b
lift = tc-step

-- tc 天生传递：stdlib 的 Transitive 展开后与 tc-trans 逐字同形。
↝⁺-trans : Transitive _↝⁺_
↝⁺-trans = tc-trans

-- 手拼一条两步序列，看清 tc-trans 只是「把两段接起来」的胶水。
two-steps : app (app (app S K) K) (app K K) ↝⁺ app K K
two-steps =
  tc-trans (tc-step (↝S K K (app K K)))             -- ↝ K (K K) (K (K K))
           (tc-step (↝K (app K K) (app K (app K K))))  -- ↝ K K

-- ↝⁺ 是「一步或多步」，不含自反闭包（书的 + 记号同义）。想要可自反的那版，
-- stdlib 现成件是 Relation.Binary.ReflexiveClosure。

------------------------------------------------------------------------
-- 7. 三条辅助引理：恒等组合子与两条同余
------------------------------------------------------------------------

-- S K K 是恒等函数：S 规则复制参数，K 规则丢掉多出来的那一份。
id↝ : ∀ (a : varcomb) → app (app (app S K) K) a ↝⁺ a
id↝ a = tc-trans (tc-step (↝S K K a)) (tc-step (↝K a (app K a)))

-- 关键缺口：tc 只保证「序列能接起来」，不保证「序列能塞进上下文」，
-- 所以 ↝ 有的两条同余规则在 ↝⁺ 上得重新证。证明是对**归约序列**本身
-- 归纳：tc-step 是基例（一层上下文，用一步同余），tc-trans 把两段各自
-- 加上上下文再接起来。
trans-Cong1 : ∀ {a a′} (b : varcomb) → a ↝⁺ a′ → app a b ↝⁺ app a′ b
trans-Cong1 b (tc-step d) = tc-step (↝C1 b d)
trans-Cong1 b (tc-trans d₁ d₂) =
  tc-trans (trans-Cong1 b d₁) (trans-Cong1 b d₂)

trans-Cong2 : ∀ (a : varcomb) {b b′} → b ↝⁺ b′ → app a b ↝⁺ app a b′
trans-Cong2 a (tc-step d) = tc-step (↝C2 a d)
trans-Cong2 a (tc-trans d₁ d₂) =
  tc-trans (trans-Cong2 a d₁) (trans-Cong2 a d₂)

-- 三处递归都顺着构造子走：λ* 顺着 varcomb，同余引理顺着 tc 的证明，
-- 主定理顺着 v₁。35 章 normalize 要 Acc 是因为递归顺着项但「项在语法上
-- 没变小」；这里语法真的在变小，终止检查一眼放行，所以整个文件
-- 不挂 --guardedness、也不需要 --safe 之外的任何开关。

------------------------------------------------------------------------
-- 8. 主定理：λ* 的产出行为等同 λ 抽象
------------------------------------------------------------------------

-- 陈述：app (λ* s v₁) v₂ 多步归约到「把 v₂ 代进 v₁ 的 s」。
-- 这正是 β 规则，只是换用组合子的语言重写。
λ*-↝ : ∀ (v₁ v₂ : varcomb) (s : String) →
       app (λ* s v₁) v₂ ↝⁺ subst v₂ s v₁
λ*-↝ S v₂ s = lift (↝K S v₂)
λ*-↝ K v₂ s = lift (↝K K v₂)
λ*-↝ (app c₁ c₂) v₂ s =
  tc-trans (tc-step (↝S (λ* s c₁) (λ* s c₂) v₂))
    (tc-trans (trans-Cong1 (app (λ* s c₂) v₂) (λ*-↝ c₁ v₂ s))
              (trans-Cong2 (subst v₂ s c₁) (λ*-↝ c₂ v₂ s)))
λ*-↝ (var s′) v₂ s with keep (s == s′)
λ*-↝ (var s′) v₂ s | true , p rewrite p = id↝ v₂
λ*-↝ (var s′) v₂ s | false , p rewrite p = lift (↝K (var s′) v₂)

-- app 分支三步棋：① ↝S 把 v₂ 同时递给左右（S 的全部作用就是分发参数）；
-- ② trans-Cong1 用 IH₁ 把左半换成 subst v₂ s c₁，右半原地不动；
-- ③ trans-Cong2 再用 IH₂ 换右半。两次都要同余，因为归纳假设说的是子项，
-- 目标说的是整项。S/K 分支是「K 吞掉参数」的一步归约；变量分支要么走
-- 恒等组合子 id↝，要么走 K-drops 的镜像 ↝K。

-- 把主定理实例化到一个具体项上，替读者把「行为等同」落地：
β-at-S : app (λ* "x" (var "x")) S ↝⁺ S
β-at-S = λ*-↝ (var "x") S "x"

-- 检查这一行时 Agda 自己算出 λ* "x" (var "x") = app (app S K) K、
-- subst S "x" (var "x") = S，然后发现 λ*-↝ 的产出类型与之吻合。

------------------------------------------------------------------------
-- 9. 算例：把 Agda 当计算器（原书习题 1 的四项 + 尺寸账）
--    等号右边全部由检查器 normalize 出来，refl 验收。
------------------------------------------------------------------------

-- (a) λx. λy. x  写成组合子是 S (K K) (S K K)
abs-a : varcomb
abs-a = λ* "x" (λ* "y" (var "x"))

abs-a-is : abs-a ≡ app (app S (app K K)) (app (app S K) K)
abs-a-is = refl

-- (b) λx. λy. y  是 S (S (K S) (K K)) (K K)
abs-b : varcomb
abs-b = λ* "x" (λ* "y" (var "y"))

abs-b-is : abs-b ≡
           app (app S (app (app S (app K S)) (app K K))) (app K K)
abs-b-is = refl

-- (c) λs. λz. s z  是 S (S (K S) (S (K K) (S K K))) (S (S (K S) (K K)) (K K))
abs-c : varcomb
abs-c = λ* "s" (λ* "z" (app (var "s") (var "z")))

abs-c-is : abs-c ≡
  app (app S
         (app (app S (app K S))
              (app (app S (app K K)) (app (app S K) K))))
      (app (app S (app (app S (app K S)) (app K K))) (app K K))
abs-c-is = refl

-- (d) λx. x x  是 S (S K K) (S K K)
abs-d : varcomb
abs-d = λ* "x" (app (var "x") (var "x"))

abs-d-is : abs-d ≡ app (app S (app (app S K) K)) (app (app S K) K)
abs-d-is = refl

-- 尺寸账：size 数结点个数，与 35 章同一个定义。
size : varcomb → ℕ
size S = 1
size K = 1
size (var s) = 1
size (app a b) = suc (size a + size b)

size-x : size (var "x") ≡ 1
size-x = refl

size-I : size (λ* "x" (var "x")) ≡ 5
size-I = refl

size-xx : size (λ* "x" (app (var "x") (var "x"))) ≡ 13
size-xx = refl

size-xyx : size (λ* "x" (λ* "y" (var "x"))) ≡ 11
size-xyx = refl

size-c : size abs-c ≡ 35
size-c = refl

-- 逐层记账：消掉内层 z 之后是 11，再消外层 s 才是 35。
size-inner : size (λ* "z" (app (var "s") (var "z"))) ≡ 11
size-inner = refl

-- 原书那句「我们的算法把尺寸翻了一倍还不止」现在有了数：
-- 1 ↦ 5、3 ↦ 13、3 ↦ 11。书里提到的替代算法靠引入 I/B/C 等派生组合子
-- 换长度，代价是语法要多开构造子——那正是原书习题 4 的意思。
