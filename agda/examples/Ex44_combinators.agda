-- 第 44 章 · SK 组合子的操作语义与终止性证明
-- 主题：用归纳定义写小步语义（规则即构造子）；size 度量与 S 自由片段;
--       良基性搬家（Acc _<_ → Acc _≺_）；normalize 为什么必须多收一个
--       Acc 参数——终止检查只认「结构变小」，递归走 acc 的函数字段。
-- 所有代码在 Agda 2.9.0 + stdlib 3.0 下真实类型检查通过。
-- 取材：Aaron Stump《Verified Functional Programming in Agda》第 9 章
--       （9.1 归纳定义的归约关系 / 9.2–9.3 终止性与 Acc）。

module Ex44_combinators where

open import Data.Maybe.Base using (Maybe; just; nothing)
open import Data.Product using (Σ; _,_; Σ-syntax)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

------------------------------------------------------------------------
-- 1. 语法与小步语义：规则即构造子
------------------------------------------------------------------------

-- SK 组合子的抽象语法：两个常量加一个二元应用。
data comb : Set where
  S K : comb
  app : (a b : comb) → comb

-- 一步归约关系 a ↝ b：Coq 里的 Inductive step，Agda 里就是 data，
-- 每条推理规则是一个构造子（12 章命题即数据的老手艺，第一次正经复用）。
infix 4 _↝_
data _↝_ : comb → comb → Set where
  ↝K : ∀ a b → app (app K a) b ↝ a
  ↝S : ∀ a b c → app (app (app S a) b) c ↝ app (app a c) (app b c)
  -- 两条迁移规则：上下文里归约（↝C1 归约左子树，↝C2 归约右子树）
  ↝C1 : ∀ {a a′} (b : comb) → a ↝ a′ → app a b ↝ app a′ b
  ↝C2 : (a : comb) → ∀ {b b′} → b ↝ b′ → app a b ↝ app a b′

-- 想「算」一步归约，需要一个判定过程：step? 返回归约结果 + 归约证明。
-- 这就是 15 章 Dec 的手法——语义给「是什么」，算法给「怎么找」。
Step : comb → Set
Step c = Σ[ d ∈ comb ] (c ↝ d)

step? : (c : comb) → Maybe (Step c)
step? S = nothing
step? K = nothing
step? (app (app (app S a) b) c) = just (app (app a c) (app b c) , ↝S a b c)
step? (app (app K a) b) = just (a , ↝K a b)
step? (app a b) with step? a
... | just (a′ , p) = just (app a′ b , ↝C1 b p)
... | nothing with step? b
...   | just (b′ , q) = just (app a b′ , ↝C2 a q)
...   | nothing = nothing

------------------------------------------------------------------------
-- 2. 尺寸度量与 S 自由片段
------------------------------------------------------------------------

open import Data.Nat using (ℕ; zero; suc; _+_; _<_)
open import Data.Nat.Base using (s≤s; z≤n)
open import Data.Nat.Properties
  using (m<n⇒m<1+n; n<1+n; +-suc; +-monoˡ-<; +-monoʳ-<; +-identityʳ)

-- 尺寸 = 结点个数：app 节点自身 +1。
size : comb → ℕ
size S = suc zero
size K = suc zero
size (app a b) = suc (size a + size b)

-- S 规则把 c 复制了两遍：size (app (app a c) (app b c)) 比左边多出
-- 一个 size c——S 让尺寸变大，「一步归约 ⇒ 尺寸变小」对含 S 的项不成立。
-- 所以像 Stump 一样把讨论限制在「不含 S 的片段」里；这里用归纳谓词
-- 而不是 Bool 函数（36 章「卡住项」的教训在 44.6 坑位清单有实测展开）：
data Sfree : comb → Set where
  sK : Sfree K
  sApp : ∀ {a b} → Sfree a → Sfree b → Sfree (app a b)

-- 两个自然数小引理：x < suc(suc(suc(x+y)))（K 规则里被丢掉的那段
-- 至少有 K 本身 + 外层 app 节点 + ... 三个 suc 的余量）。
x<3 : (x y : ℕ) → x < suc (suc (suc (x + y)))
x<3 x zero rewrite +-identityʳ x = m<n⇒m<1+n (m<n⇒m<1+n (n<1+n x))
x<3 x (suc y) rewrite +-suc x y = m<n⇒m<1+n (x<3 x y)

-- 核心度量引理：S 自由项一步归约，尺寸严格变小。
-- 每条规则一个分支——「对证明的构造子分情况」就是语义规则的 case 分析。
↝-size< : ∀ {a b} → Sfree a → a ↝ b → size b < size a
↝-size< (sApp (sApp sK sa) sb) (↝K a b) = x<3 (size a) (size b)
-- ↝S 分支：Sfree (app (app (app S a) b) c) 最深处要求 Sfree S，
-- 而 Sfree 没有对应构造子 → 荒谬模式，一行都不用写：
↝-size< (sApp (sApp (sApp () _) _) _) (↝S a b c)
↝-size< (sApp sa sb) (↝C1 {a} {a′} b u) =
  s≤s (+-monoˡ-< (size b) (↝-size< sa u))
↝-size< (sApp sa sb) (↝C2 a {b} {b′} u) =
  s≤s (+-monoʳ-< (size a) (↝-size< sb u))

-- 归约不引入 S：S 自由性沿 ↝ 保持（⇓↝ 递归里要用它喂 IH）。
↝-Sfree : ∀ {a b} → Sfree a → a ↝ b → Sfree b
↝-Sfree (sApp (sApp sK sa) sb) (↝K a b) = sa
↝-Sfree (sApp (sApp (sApp () _) _) _) (↝S a b c)
↝-Sfree (sApp sa sb) (↝C1 {a} {a′} b u) = sApp (↝-Sfree sa u) sb
↝-Sfree (sApp sa sb) (↝C2 a {b} {b′} u) = sApp sa (↝-Sfree sb u)

------------------------------------------------------------------------
-- 3. 良基性搬家：从 _<_ 的 Acc 搬到 _≺_ 的 Acc
------------------------------------------------------------------------

open import Induction.WellFounded using (Acc; acc)
open import Data.Nat.Induction using (<-wellFounded)

-- Acc 的字段形如 ∀ {y} → y < x → Acc y：「小的一边在左」。
-- 归约方向是 a ↝ b（b 更小），直接 Acc _↝_ 会拧着——取反向别名：
_≺_ : comb → comb → Set
a ≺ b = b ↝ a

-- 搬家三步：① ℕ 的 < 良基（stdlib 现成）；② size 把 ↝ 压进 <
-- （↝-size<）；③ 归约不引入 S（↝-Sfree）让 IH 续得上。
⇓↝ : ∀ {a} → Acc _<_ (size a) → Sfree a → Acc _≺_ a
⇓↝ {a} (acc h) sa = acc go
  where
  go : ∀ {y} → y ≺ a → Acc _≺_ y
  go {y} p = ⇓↝ (h (↝-size< sa p)) (↝-Sfree sa p)

Sfree⇒Acc↝ : ∀ {a} → Sfree a → Acc _≺_ a
Sfree⇒Acc↝ {a} s = ⇓↝ (<-wellFounded (size a)) s

------------------------------------------------------------------------
-- 4. normalize：递归走 acc 的函数字段
------------------------------------------------------------------------

-- 先看「天真版」的下场（探针复现，全文见 docs/44 的 44.4）：
--   eval : comb → comb
--   eval c with step? c
--   ... | just (d , p) = eval d      -- Termination checking failed!
--   ... | nothing = c
-- d 是 c 的归约结果，不是 c 的子模式——终止检查只看语法，不懂语义。
-- 解法：把「d 比 c 小」这段知识随身携带，塞进第二个参数：
normalize : (c : comb) → Acc _≺_ c → comb
normalize c (acc h) with step? c
... | just (d , p) = normalize d (h p)   -- 递归调用的终止性由 h 担保
... | nothing = c

-- h : ∀ {x} → x ≺ c → Acc _≺_ x，而 p : c ↝ d 即 d ≺ c——
-- (h p) 正是 Acc _≺_ d。终止检查看到递归参数严格变小（acc 的字段
-- 只能吐出「更小元素」的 Acc），放行。这就是 13 章「递归即归纳假设」
-- 的良基版：归纳假设住在 acc 的函数字段里。

-- 多跑一步，结果就在类型里：normalize 产出的同时附上「可达」证明。
data _↝⋆_ : comb → comb → Set where
  id↝ : ∀ a → a ↝⋆ a
  step↝ : ∀ {a b c} → a ↝ b → b ↝⋆ c → a ↝⋆ c

-- 自反传递闭包是 14 章 begin-≡ 推理链的关系版（对照 stdlib
-- Relation.Binary.ReflexiveClosure）。
normalize-↝⋆ : (c : comb) (t : Acc _≺_ c) → c ↝⋆ normalize c t
normalize-↝⋆ c (acc h) with step? c
... | just (d , p) = step↝ p (normalize-↝⋆ d (h p))
... | nothing = id↝ c

------------------------------------------------------------------------
-- 5. 算例：能算的全算出来（36 章的反射检查，这回对象是归约）
------------------------------------------------------------------------

-- K (K K) K ↝ K K ↝ 正常。Sfree 证明手工给出（也可 with 决策过程造）：
t₃ : comb
t₃ = app (app K (app K K)) K

t₃-sfree : Sfree t₃
t₃-sfree = sApp (sApp sK (sApp sK sK)) sK

nf₃ : comb
nf₃ = normalize t₃ (Sfree⇒Acc↝ t₃-sfree)

nf₃-is : nf₃ ≡ app K K
nf₃-is = refl                      -- 一步 K 规则，算完就是 K K

nf₃-↝⋆ : t₃ ↝⋆ nf₃
nf₃-↝⋆ = normalize-↝⋆ t₃ (Sfree⇒Acc↝ t₃-sfree)   -- 定义展开后 = 一条 ↝K

-- SKK S ↝⋆ S：含 S 项 normalize 用不了（Sfree⇒Acc↝ 喂不进去），
-- 但「存在归约序列」仍可逐规则构造——语义不欠算法的账：
I-comb : comb
I-comb = app (app S K) K

demo : app I-comb S ↝⋆ S
demo = step↝ (↝S K K S) (step↝ (↝K S (app K S)) (id↝ S))
-- 第一步 S K K S ↝ K S (K S)，第二步 K 规则丢掉冗余参数。

-- 反面教材在类型层也被拒：Ω = S (K I) (S (K I) S) 之类发散项
-- 根本进不了 normalize 的定义域（Sfree 证不出来，postulate 除外）。
-- 44.6 坑位：为什么「Bool 判定 + T 谓词」写 Sfree 会在卡住的
-- 合取上翻车——归纳谓词版免谈计算，只谈证明，反而一路顺风。
