# 35 · SK 组合子：操作语义与终止性证明

> **第六部分 · 综合实战（33–35）** ｜ 全书结构与阅读路线见 [README](../README.md)

综合实战的收官章，取材 Stump《Verified Functional Programming in Agda》
第 9 章。前面各章 Agda 一直在「算别人」：自然数、列表、Vec、
代数结构。本章让 Agda 算**一门语言**——SK 组合子的小步操作语义，
再证明「S 自由片段的一切归约都会停机」，并据此造出一个**天生终止**的
规范化器 `normalize`。这是全书第一次把「语义学对象」整体装进类型
论，也是前文四条暗线的总汇：

* 14 章「命题即数据」——归约规则的每条前提就是一个构造子；
* 15 章「递归即归纳假设」——升级到良基版：归纳假设住进 `acc` 的字段；
* 17 章决策过程——`step?` 给出「一步归约」的判定与证物；
* 11 章规范化与卡住项——本章的 `Sfree` 为什么用归纳谓词而不是 Bool，
  坑位清单里有实测对照。

对应示例：`../examples/Ex35_combinators.agda`

**实测口径**（02 章）：本章报错文本均为 **Agda 2.9.0 + stdlib 3.0** 实测原样粘贴（复现用临时
探针已删除，报错路径显示为当时的探针路径）。

## 35.1 语法与一步归约：规则即构造子

SK 组合子的抽象语法，两个常量一个二元构造子（06 章 `data` 的最小手艺）：

```agda
data comb : Set where
  S K : comb
  app : (a b : comb) → comb
```

小步语义 `a ↝ b`（读作「a 一步归约到 b」）。Coq 里写
`Inductive step : comb → comb → Prop`，Agda 里一模一样——**每条推理
规则是一个构造子**，构造子的参数是规则的前提：

```agda
infix 4 _↝_
data _↝_ : comb → comb → Set where
  ↝K : ∀ a b → app (app K a) b ↝ a
  ↝S : ∀ a b c → app (app (app S a) b) c ↝ app (app a c) (app b c)
  ↝C1 : ∀ {a a′} (b : comb) → a ↝ a′ → app a b ↝ app a′ b
  ↝C2 : (a : comb) → ∀ {b b′} → b ↝ b′ → app a b ↝ app a b′
```

读法：`↝K a b` 是「K 规则」的证明**对象**，前提为零（∀ 量化的
元变量不算前提）；`↝C1 b u` 是「左子树归约一步，整体跟着归约」，
前提 `u : a ↝ a′` 就是它的「小前提」。构造子的**类型**恰好是规则的
结论式——想让 Agda 验收一条归约，交上构造子应用即可：

```agda
_ : app (app (app S K) K) S ↝ app (app K S) (app K S)
_ = ↝S K K S
```

这就是「命题即数据」第一次干正经活：`↝` 不是布尔判定，是**证明
集合**——有成员的集合（可归约）或空集（不可归约）。11 章用 Bool
+ `T` 谓词写过同类东西，35.3 会给出两种写法的实测胜负。

## 35.2 语义给「是什么」，算法给「怎么找」

`↝` 本身不会「执行」。想算一步，需要一个返回**结果 + 证物**的判定
过程（17 章 `Dec` 的放大版——不仅判真伪，还吐出 witness）：

```agda
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
```

三点手感：

* **子句顺序即归约策略**。`app (app (app S a) b) c` 排在
  `app (app K a) b` 前面，两个都命中时先试 S——最左内层优先由
  `with step? a` 递归进左子树实现。换策略就是换子句顺序，
  语义一行不改。
* **返回类型是 Σ**：`just (d , p)` 里 `p : c ↝ d`，调用方拿到结果
  的同时拿到「这确实是它的一步归约」的证书。`nothing` 则是
  「找不到」——注意它只说 step? 没找到，要论证「确实没有」需另证
  （对 `↝` 的构造子逐个排除，本章不需要，读者可自练）。
* `with` 套 `with`（左子树没有再看右子树）是 06/15 章的老招式，
  这里第一次承担「策略」职能。

## 35.3 尺寸度量、S 复制问题与 Sfree

终止性的弹药是一个度量：`size` = 语法树结点数，`app` 节点自身 +1：

```agda
size : comb → ℕ
size S = suc zero
size K = suc zero
size (app a b) = suc (size a + size b)
```

「一步归约 ⇒ 尺寸变小」成立吗？逐规则算账（下记 |t| 表 size t）：

* **K**：`|app (app K a) b| = |a| + 3`（外层 app、内层 app、K 结点），
  归约后剩 `|a|`——缩 3，稳赚；
* **C1/C2**：`|app a b| = |a| + |b| + 1`，只动子树：子树缩 1 以上，
  整体跟着缩——只要子规则成立就成立；
* **S**：左边 `|a| + |b| + |c| + 3`，右边
  `|app (app a c) (app b c)| = |a| + |b| + 2|c| + 3`——
  **右边比左边多一个 |c|**。c 不是空树，S 规则净亏。

这就是 Stump 把讨论限制在「不含 S 的片段」的原因（书里 9.3 节原话
的实质）：不是 SK 演算不终止（它是，且更强——可证强规范化），
而是**这个便宜的度量**管不住复制。S 自由谓词用归纳 data 写：

```agda
data Sfree : comb → Set where
  sK : Sfree K
  sApp : ∀ {a b} → Sfree a → Sfree b → Sfree (app a b)
```

没有 `sS`——「不含 S」是**结构归纳定义**的谓词。于是「S 项不在
片段内」的写法是荒谬模式：想从 `Sfree (app S x)` 提取 `Sfree S`，
而 `Sfree S` 无构造子可匹配：

```agda
↝-size< (sApp (sApp (sApp () _) _) _) (↝S a b c)
```

一行不写，分支自动成立——17 章「空情形 = 零构造子」在**语义规则
层**的复刻。核心度量引理整容：

```agda
↝-size< : ∀ {a b} → Sfree a → a ↝ b → size b < size a
↝-size< (sApp (sApp sK sa) sb) (↝K a b) = x<3 (size a) (size b)
↝-size< (sApp (sApp (sApp () _) _) _) (↝S a b c)
↝-size< (sApp sa sb) (↝C1 {a} {a′} b u) =
  s≤s (+-monoˡ-< (size b) (↝-size< sa u))
↝-size< (sApp sa sb) (↝C2 a {b} {b′} u) =
  s≤s (+-monoʳ-< (size a) (↝-size< sb u))
```

读法与 15 章归纳完全一致：**对证明的构造子分情况 = 对语义规则
做 case 分析**。`↝K` 分支的算术引理 `x<3`（K 规则缩掉的三结点：

```agda
x<3 : (x y : ℕ) → x < suc (suc (suc (x + y)))
x<3 x zero rewrite +-identityʳ x = m<n⇒m<1+n (m<n⇒m<1+n (n<1+n x))
x<3 x (suc y) rewrite +-suc x y = m<n⇒m<1+n (x<3 x y)
```

又是标准归纳 + rewrite 搬家），`↝C1` 分支用 stdlib 单调性引理把
子树的缩小抬进 `app` 上下文。**注意两条搬运引理不同名**：
`+-monoˡ-< c p : a + c < b + c`（变化的一侧在左），
`+-monoʳ-< c p : c + a < c + b`（变化的一侧在右）——C2 分支用错
一个字母，实测报错拿 `b′` 和 `a` 硬碰：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe44.agda:62.38-79: error: [UnequalTerms]
The terms
  b′
and
  a
are not equal at type comb
when checking that the expression
+-monoˡ-< (size a) (↝-size< (andT₂ sa) u) has type
suc (size a + size b′) Data.Nat.≤ size a + size b
```

（这段报错来自开发中途的 Bool 版探针，`andT₂` 的来历见 35.6 坑 3；
结论与终版一致：换 `+-monoʳ-<` 即愈。）

**为什么 Sfree 用 `data` 而不是 Bool + `T`**——这不是风格洁癖，是
实测生死。Bool 版（`Sfree S = false; Sfree (app a b) = Sfree a ∧
Sfree b`，配 `T (Sfree a)` 当谓词）在分解卡住的合取时全线翻车：
`sa : T (Sfree a ∧ Sfree b)` 里的 `Sfree a` 是**中性项**（变量上的
函数调用，11.3 姿势三），任何要「先认出合取左右两侧再分情况」的
引理都无从落脚。探针实测（`andT₁ : T (x ∧ y) → T x` 消费
`T (Sfree a ∧ Sfree b)`）：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe44.agda:65.36-38: error: [UnequalTerms]
The terms
  Sfree a ∧ _y_104
and
  Sfree a
are not equal at type Bool
when checking that the expression sa has type
T ((Sfree a ∧ _y_104) ∧ _y_106)
```

而归纳谓词版把「分解」变成**模式匹配**：`sApp sa sb` 一拆，
`sa : Sfree a`、`sb : Sfree b` 各就各位，全程零合一。同一份数学，
Bool 版死于「合取是定义在卡住项上的函数调用」，谓词版活在其
「构造子」身份上——11 章「少分一次情况，少背一个义务」的又一次
兑现，只不过这次「情况」发生在证明里。

## 35.4 终止检查只认语法：normalize 与 acc 的函数字段

先试天真版：

```agda
eval : comb → comb
eval c with step? c
... | just (d , p) = eval d
... | nothing = c
```

语义上没问题（S 自由片段必停），类型检查器一票否决——`d` 不是
`c` 的子模式，语法上看不出「变小」：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe44b.agda:31.1-34.18: error: [TerminationIssue]
Termination checking failed for the following functions:
  eval
Problematic calls:
  eval c | step? c
  eval d
    (at /Volumes/mac004/code/programming/agda/examples/TmpProbe44b.agda:33.22-26)
```

Coq 用户此刻去写 `Function ... by well_founded` 或 `Fixpoint` 换
recursor；Agda 的答案朴素到只有半个词：**把「d 比 c 小」这段知识
随身携带**，塞进第二个参数：

```agda
normalize : (c : comb) → Acc _≺_ c → comb
normalize c (acc h) with step? c
... | just (d , p) = normalize d (h p)
... | nothing = c
```

`Acc` 是可达性谓词（stdlib `Induction.WellFounded`）：

```agda
data Acc {A : Set a} (_<_ : Rel A ℓ) (x : A) : Set (a ⊔ ℓ) where
  acc : (∀ {y} → y < x → Acc _<_ y) → Acc _<_ x
```

拆开看：`Acc _<_ x` 的意思是「x 的每个可比邻居 y 都可归」，
`acc h` 里那个 `h` 就是**良基归纳假设的函数形态**——输入一个更小的
`y` 和「y 比 x 小」的证据，吐 `Acc y`。normalize 的递归调用
`normalize d (h p)`：`p : c ↝ d`，而 `h` 正吃这个证据——终止检查
器看到递归参数是 `acc` 字段喂出来的，天然严格变小，放行。
15 章口诀「递归调用即归纳假设」的良基版：**归纳假设现在是签名里
看得见的函数参数**。

两个实测定盘细节，都是新手必踩：

**其一，方向**。`Acc` 字段要「小的在左」（`y < x`），而归约证据
`p : c ↝ d` 里小的 `d` 在右。直接写 `Acc _↝_` 会拧着来——实测
（把终版的 `Acc _≺_` 换成 `Acc _↝_`、`go` 签名照写时的报错）：

```text
/Volumes/mac004/code/programming/agda/examples/TmpProbe44.agda:56.21-27: error: [UnequalTypes]
The type
  ℕ
is not a subtype of
  suc _y_107 Data.Nat.≤ size a
when checking that the inferred type of an application
  ℕ
matches the expected type
  suc _y_107 Data.Nat.≤ size a
```

报错满纸天书是这类「方向拧了」问题的常态。解法干净：起个反向别名
再谈可达性——

```agda
_≺_ : comb → comb → Set
a ≺ b = b ↝ a
```

模式匹配时 Agda 自动展开别名（它就是普通的定义级等式），
`go {y} p` 里照旧拿 `↝C1/↝C2` 拆 `p`。

**其二，搬家**。有了「一步归约 ⇒ size 变小」（`↝-size<`）和
「归约不引入 S」（`↝-Sfree`），把 ℕ 上现成的良基性搬过来：

```agda
⇓↝ : ∀ {a} → Acc _<_ (size a) → Sfree a → Acc _≺_ a
⇓↝ {a} (acc h) sa = acc go
  where
  go : ∀ {y} → y ≺ a → Acc _≺_ y
  go {y} p = ⇓↝ (h (↝-size< sa p)) (↝-Sfree sa p)

Sfree⇒Acc↝ : ∀ {a} → Sfree a → Acc _≺_ a
Sfree⇒Acc↝ {a} s = ⇓↝ (<-wellFounded (size a)) s
```

逐行读：`h` 只会接受「size 更小」的项，所以每次递归前先用
`↝-size< sa p` 递上这张尺寸证明；而 `⇓↝` 下一层要处理的是 `y` 的
归约，`Sfree y` 得有人负责——`↝-Sfree sa p` 现证。`<-wellFounded`
（`Data.Nat.Induction`）是 stdlib 的「ℕ 的 < 良基」正品证书。
**终止性证明的全部内容就是这两引理 + 一次搬运**，没有任何一步
依赖「SK 的直觉」。

## 35.5 自反传递闭包：结果顺手带证，算例能 `refl`

`normalize` 只吐最终项；「它确实是从原项归约来的」另立门面——
自反传递闭包（对照 stdlib `Relation.Binary.ReflexiveClosure`，
16 章推理链的关系版）：

```agda
data _↝⋆_ : comb → comb → Set where
  id↝ : ∀ a → a ↝⋆ a
  step↝ : ∀ {a b c} → a ↝ b → b ↝⋆ c → a ↝⋆ c

normalize-↝⋆ : (c : comb) (t : Acc _≺_ c) → c ↝⋆ normalize c t
normalize-↝⋆ c (acc h) with step? c
... | just (d , p) = step↝ p (normalize-↝⋆ d (h p))
... | nothing = id↝ c
```

签名即定理：「normalize 的输出可从输入归约到达」。证明与 normalize
**同构**——同一台递归，多长一条证物链，这正是 Agda 程序即证明的
字面演示。

算例验收（11 章「单元测试只在失败时开口」，这回测的是归约器）：

```agda
t₃ : comb
t₃ = app (app K (app K K)) K

t₃-sfree : Sfree t₃
t₃-sfree = sApp (sApp sK (sApp sK sK)) sK

nf₃-is : normalize t₃ (Sfree⇒Acc↝ t₃-sfree) ≡ app K K
nf₃-is = refl
```

含 S 项呢？`SKK S ↝⋆ S` 里 normalize 用不了（Sfree 喂不进
`Sfree⇒Acc↝`），但「存在归约序列」照样逐构造子手构：

```agda
demo : app I-comb S ↝⋆ S
demo = step↝ (↝S K K S) (step↝ (↝K S (app K S)) (id↝ S))
```

语义不欠算法的账：`↝⋆` 对全体 `comb` 说话，`normalize` 只承包
S 自由片段——片段外的项**并非不能归约**，只是本度量管不到它们的
终止性。书里习题（Stump 9.4）继续往前推：给 S 配多集合序或
「复制次数」更精巧的度量，SK 全片段也能规范化——本章止步于
「便宜度量 + 明确边界」，边界本身写进了签名。

## 35.6 坑位清单（实测）

1. **语义递归过不了终止检查**：`eval d`（d 是归约结果而非子模式）
   报 `TerminationIssue`，点名 `eval c | step? c` 与 `eval d` 两处
   （35.4）——解药是把终止性做成参数：`Acc _≺_ c`。
2. **Acc 字段方向**：`y < x` 小的在左；`a ↝ b` 小的在右。直接
   `Acc _↝_` 的报错是「ℕ 不是 `suc _y ≤ size a` 的子类型」这种
   天书（35.4）——先写反向别名 `a ≺ b = b ↝ a` 再动手，报错立愈。
3. **Bool + `T` 写片段谓词死于卡住合取**：`T (Sfree a ∧ Sfree b)`
   无法分情况（`Sfree a` 中性，合一报
   `Sfree a ∧ _y_104 != Sfree a`，35.3）；顺带的姊妹坑是把
   `andT it it = it` 当恒等式用——同名字段模式要求两侧同型，实测
   `when checking that all occurrences of pattern variable it have
   the same type`。归纳谓词版 `sApp sa sb` 一行拆伙，零合一。
4. **`+-monoˡ-<` / `+-monoʳ-<` 方向**：ˡ/ʳ 标「变化操作数所在侧」，
   c 钉另一侧（15 章坑 9 同一家族）。C2 分支（右边在缩）误用 ˡ 版，
   报错拿 `b′` 撞 `a`（35.3 贴文）——`≤` 版同理，用前 `:Check`。
5. **构造子的 fixity 声明位置**：给 `data` 里的符号构造子声明
   `infixr` 必须写在 **data 之后**（名字要先在作用域），写在前面报
   `UnknownNamesInFixityDecl`（数据类型名 `_↝_` 可写在 data 前，
   构造子不行——差别的根源是「谁引入作用域」）。
6. **`open import` 是位置敏感的**：本模块把 `Σ-syntax` 的 import
   写在用 `Σ[ d ∈ comb ]` 的定义之后，报 `Not in scope: Σ[`——
   与多数语言「import 全文件生效」不同，Agda 的作用域从 import
   出现处起算（06 章老规矩，第一次在长文件里咬人）。
7. **空片段要留后路**：`Sfree⇒Acc↝` 只承包 S 自由项；含 S 项的
   归约序列（如 `SKK S ↝⋆ S`）仍可手构证明，或另换度量——「度量
   管不到」≠「事实不成立」，签名边界写清楚就不会误伤。
8. **荒谬模式的嵌套深度别猜**：`↝S` 分支的 `()` 要一路拆到
   `Sfree S` 才落得下：`sApp (sApp (sApp () _) _) _`——按
   「app 结点数」数 sApp 的层数，或用 MakeCase（`C-c C-c`）让
   Agda 摆出骨架再填（02 章工具链）。
---
上一章：[34 · 实战：可验证插入排序](34-sorting.md) ｜ 下一章：[36 · 标准库阅读指南](36-stdlib-guide.md) ｜ 返回：[README](../README.md)
