# 36 单型集合 II：常元声明法

> 对应读本：Nordström 书第 20 章（用类型定义集合——Π/Σ/+/Id/
> 有穷集合/N/List 的单型重铸）+ 附录 B（操作语义）。
> 代码：`examples/36_monosets/ex36_monosets.agda`——单型
> apply/natrec/split 与相等性声明、去除函数、操作语义两步
> 协议的可跑见证。

35 章造好了类型层（Set/El/函数类型）；本章把第一部分的全部
集合构造子**搬到类型层**——搬法统一得惊人：**引常量 + 声明
相等性**。这一章是「用类型论定义类型论」的第一次完整演练
（62 章 LF 把同一思想做成逻辑框架），也是 Agda/Coq/Lean 内核
里 `eliminator` 家族的直系 blueprint。

## 36.1 从规则组到常量声明

多型表述里，每个集合有形成/引入/消去/相等性**四组规则**
（28–30 章逐个见过）；单型表述里，同样的事只需两步：

```text
① 声明常量的类型（对应形成+引入+消去的前提结构）
② 声明计算等式（对应相等性规则）
```

以 Π 为例（书 20.1）——三个常元、一条等式，代替 28.3 的
六条规则：

```text
Π     : (X:Set, (El(X))Set)Set
λ     : (X:Set, Y:(El(X))Set, (x:El(X))El(Y(x)))El(Π(X,Y))
apply : (X:Set, Y:(El(X))Set, El(Π(X,Y)), x:El(X))El(Y(x))
apply(A, B, λ(A,B,b), a) = b(a) : El(B(a))     ← 唯一的等式
```

注意 **apply 现在是四参数**——先给集合 A、族 B，再给函数与
实参。单型的定义（书 ch.20 开篇）：**所有常元包含明确的信息
表明其变目属于哪些集合**。收益有二：

1. **判断自含全部信息**——「给定一个判断，重建此判断的推导
   是可能的」（推导重建 = 反方向读常量类型）；
2. **「消去 2 类」规则免费**——27.3 节约定省略的那些「分部
   相等则整体相等」规则，在单型层由类型层次上的对象替代
   直接得到。

代价：**程序携带大量与计算无关的信息**——apply 每次都要
喂 A、B。所以实现都配**去除函数**（erasure）：把单型表达式
的集合信息剥掉、得多型表达式；去除后单型推导成为多型的
正确推导（对推导长度归纳即证）。

Agda 件里单型 apply 与它的相等性声明（= 书里唯一的等式）：

```agda
monoApply : (X : Set) (Y : X → Set) (c : (x : X) → Y x) (a : X) → Y a
monoApply X Y c a = c a

apply-eq : (X : Set) (Y : X → Set) (b : (x : X) → Y x) (a : X)
           → monoApply X Y b a ≡ b a
apply-eq X Y b a = refl          -- apply(A,B,λ(A,B,b),a)=b(a)
```

## 36.2 七组常量声明总表

书 20.2–20.7 把其余构造子逐一重铸（每件**常元声明 + 相等性
声明**，机器件里 natrec/split 两组全供）：

| 组 | 常元 | 相等性声明 |
|---|---|---|
| Σ（20.2） | Σ/pair/split | split(A,B,C,d,pair(A,B,a,b)) = d(a,b) |
| +（20.3） | +/inl/inr/when | when(A,B,C,d,e,inl(A,B,a)) = d(a)；inr 同理**两条** |
| Id（20.4） | Id/id/idpeel | idpeel(A,a,b,C,d,id(A,a)) = d(a) |
| {}（20.5） | {}/case | （无等式——没有典则元可分派） |
| ⊤（20.5） | T/tt/caseₜ | caseₜ(C,b,tt) = b |
| N（20.6） | N/0/succ/natrec | natrec(C,d,e,0) = d；natrec(C,d,e,succ(a)) = e(a, natrec(C,d,e,a)) |
| List（20.7） | List/nil/cons/listrec | listrec(A,C,d,e,nil) = d；cons 同理 |

natrec 的单型形态（消去子**显式携带族 C**）：

```agda
monoNatrec : (C : ℕ → Set) → C zero
             → (∀ n → C n → C (suc n)) → (n : ℕ) → C n
monoNatrec C c step zero    = c
monoNatrec C c step (suc n) = step n (monoNatrec C c step n)
```

「C 是参数」正是「判断自含信息」的体现——Coq 的 `nat_rect`、
Lean 的 `Nat.rec`、Agda 消去子模板的公共参数，全是这个形状。
另两处与多型版的差异值得记：单型的函数式常元**前束**
（currying 次序固定），且**选取子的参数次序**不同（split
的族 C 提到最前）。

## 36.3 多型 ↔ 单型：Salvesen 定理

「去除后单型推导是多型正确推导」只说了一半。反方向如何
——多型的每个可导判断都能从单型去除得到吗？**不能**。
Salvesen 1988 [91]：

> 多型理论中存在可导判断，它不能由单型理论中的任何可导
> 判断通过去除而得。

两个表述**本质不同**——多型更强。直觉：多型里 `λx.x` 可以
在**任意** A→B 语境下复用（同一语法项多个类型），单型里
恒等函数必须逐 (A,B) 实例化（λ(A,A,x)x 与 λ(B,B,x)x 是不同
的项），「泛型复用」的判断多型能导、单型的去除像够不着。
这与程序语言的**let 多态**（43 章）与隐式参数（48 章）
遥相呼应——多型不是单型的糖，是更强的表达力。

外延相等性的警示（书 ch.20 开篇末）：「如果我们陈述外延
相等性 Eq 于类型理论之中，那么我们将不能推导……」——
单型化的收益全部以**可判定性**为前提，Eq 一进来判断层
就被命题推理渗透（29.3 的失守在单型层同样成立）。

## 36.4 操作语义：选取子的两步协议

附录 B 给出全书求值规则的形式描述，与 36.2 的相等性声明
一一对应。**构造子形式已被求值**（succ(d)、⟨c,d⟩、λ(c)、
sup(c,d)、pair、inl/inr、nil/cons 全是值）；计算发生在选取
子上，全部遵守同一个协议（27.4 首见，此处全表）：

```text
case_i(a,b⃗)      a ⟶ iₖ 则继续求 bₖ
natrec(a,b,c)     a ⟶ 0 则求 b；a ⟶ succ(d) 则求 c(d, natrec(d,b,c))
listrec(a,b,c)    a ⟶ nil 则求 b；a ⟶ cons(d,e) 则求 c(d,e,listrec(e,b,c))
apply(a,b)        a ⟶ λ(c) 则求 c(b)
funsplit(a,b)     a ⟶ λ(c) 则求 b(c)
split(a,b)        a ⟶ ⟨c,d⟩ 则求 b(c,d)
when(a,b,c)       a ⟶ inl(d) 则求 b(d)；a ⟶ inr(e) 则求 c(e)
wrec(a,b)         a ⟶ sup(c,d) 则求 b(c,d,(x)wrec(d(x),b))
```

「先求主参数、再按典则形状分派」——**递归参数（natrec 的
natrec(d,b,c)、wrec 的 (x)wrec(d(x),b)）在分派时重新组装**，
惰性求值（书 1.1：`succ(2^ℵ)` 已是部分求值形）保证这个语义
可实现。Agda 件里两步协议跑成一个可执行见证：

```agda
eval-double : ℕ → ℕ
eval-double n = monoNatrec (λ _ → ℕ) zero (λ _ v → suc (suc v)) n

_ : eval-double 3 ≡ 6        -- 0→2→4→6：分派三层、每层 +2
_ = refl
_ : eval-double 0 ≡ zero     -- natrec(0,d,e)=d：相等性声明 1
_ = refl
```

对照现代实现：这段协议就是 Agda 编译器对模式匹配的编译
目标、Coq 的 `Fixpoint` 展开式、Lean 的 recursors 求值——
**附录 B 是三大证明助手内核求值器的共同祖先**。

> **坑位速记**
> ① 单型 apply 的参数序（X,Y,c,a）照书 20.1 抄——Y 是族
>   `(x : X) → Set` 不是集合，写成 `Set → Set` 会丢依赖性；
> ② `monoCase⊥` 的荒谬分支用 `()` 模式——⊥ 无构造子，
>   签名给 `(a : ⊥)` 而不是match 之外的任何形状；
> ③ 相等性声明的机器面就是 refl 能过的等式——若 refl 过
>   不了，说明你的「常元定义」没有按声明展开（定义体直写
>   而非 postulate）；
> ④ erase 教学占位用 `n + 0` 而非 `n`——真去除是语法层
>   投影，Agda 表达不了「丢掉类型参数」这个元操作（要靠
>   编译器/提取器，41 章的 extraction 才是它的工程实现）。

---

上一章：[35 类型与单型集合 I](35-monotypes.md) · 下一章：[37 杂例三讲](37-examples.md)
