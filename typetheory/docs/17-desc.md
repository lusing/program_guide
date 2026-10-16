# 17 描述算子、选择与引用

> 对应读本：Farmer《Simple Type Theory》第 14 章全部（不定描述
> AlonzoID、排序系统 AlonzoS、引用与求值 AlonzoQE）。
> 代码：`examples/17_desc/`——**Coq 主场**（ClassicalDescription 的
> iota 就是 I 算子的古典实现；ClassicalEpsilon 的 epsilon 是 ε；
> Print Assumptions 记账；深度嵌入往返定理）；**Lean 对照**
> （Classical.choose = ε、古典账本四件套、有限 AC 代码化）。

12 章把确定描述 I 放进了表达式七构造子（V6 的「恰一满足者」）。
本章给它配两个兄弟——不定描述 ε 与选择公理——再看两个变体：
带子类型的排序系统、带 quote/eval 的自反语言。这是 Farmer 全书
的「实用逻辑改装车间」：每种数学实践的刚需都对应一次语构手术。

## 17.1 I 与 ε：强弱之别与 AC 的入场

> **I x:α. A**（确定描述）：恰一满足者 ↦ 它；零个或多个 ↦ 无定义
> （V6）。
> **ε x:α. A**（不定描述）：有满足者 ↦ 其中**某个**（由选择函数
> f_α 决定）；零个 ↦ 无定义（14.1 的 V8）。

ε 比 I 强：**I 可以由 ε 定义，反之不行**（命题 14.1——
`Ix.A ≃ εx.(A ∧ ∃!x.A)`，机器版在 Coq 侧 `iota_eps_agree`）。
更强意味着表达力变现：`C = λs:{α}. εx. x∈s` 是**选择函数**（引理
14.2），于是——

> **定理 14.3（选择公理）**：在 AlonzoID 里，AC **有效**：
> `∃f:{α}→α. ∀s. s≠∅ ⇒ f s ∈ s`。

一句话总结家族关系：**I 不添表达力（可在纯逻辑里定义）、ε 添
（AC 随附）、HOL 系证明助手（HOL Light/Isabelle/HOL4）都原生带
ε**——Coq 与 Lean 的经典库（ClassicalChoice / Classical.em 系）
走的正是这条路。

## 17.2 Coq 主场：iota、epsilon 与古典账本

Coq 标准库的两层构造恰好是本章的教科书：**ClassicalDescription
的 `iota`**（以默认元素 + 存在唯一性为前提）就是 I；**ClassicalEpsilon
的 `epsilon`**（以 inhabited + 存在性为前提）就是 ε。`ex17_desc.v`
的四个实验：

```coq
Lemma square4_unique : exists! n, square4 n.      (* 唯一 n 使 n*n=4 *)
Theorem iota_two : two_by_iota = 2.               (* I 把它钉死为 2 *)
Theorem some_even_is_even :                        (* ε 只承诺「选的是偶数」 *)
  (exists n, Nat.even n = true) -> Nat.even some_even = true.
Theorem iota_eps_agree (P : nat -> Prop) :         (* 命题 14.1 机器版 *)
  (exists! x, P x) -> iota_via_eps P = iota 0 P.
```

`Print Assumptions iota_two` 打出账本：
`constructive_definite_description + classic`——**mini-HoTT 公理
记账制在这里同款适用**：描述算子的每一点便利都记在古典公理的
账上。选择公理的函数形态由 ClassicalChoice 的 `choice` 一行给出
（`ac_pointwise`：一次造出 f x = 2·x）。

**与 Farmer 的语义差**要挑明：Coq/Lean 的古典世界是**全定义**的
——ε 在零见证时也「返回某个默认值」（iota 的第一参数就是干这个
的），而 AlonzoID 的 ε 严格无定义。全古典逻辑抹掉了部分性这一层；
要「无定义的 ε」得回到 13 章的 TATU 语义（或在 HOL 系里约定
junk 值）。

## 17.3 Lean 对照：choose、四件套与有限 AC

`ex17_desc.lean` 的镜像三件：`Classical.choose` 作 ε（`theWitness`
被唯一性钉死为 2——注意 `noncomputable`：ε 是不可计算的原语）；
`#print axioms` 打出**古典四件套**（choice / propext / em /
Quot.sound），与 Coq 侧账本对照；有限 AC 代码化——

```lean
theorem ac_finite {α} {R : α → α → Prop}
    (h : ∀ x, ∃ y, R x y) (dom : List α) :
    ∃ f : α → α, ∀ x ∈ dom, R x (f x) :=
  ⟨fun x => Classical.choose (h x), fun x _ => Classical.choose_spec (h x)⟩
```

「对每个 x 选一个见证」在代码层就是**函数抽象 + choose**——AC
的函数形态与 λ 抽象的形状完全同构，这是「AC = 函数存在性的
古典版」最直白的读法。

## 17.4 AlonzoS：排序系统与子类型

第二个变体把「类型」推广为**排序**（sort, 14.2）：U1–U5 五条构造
——比 Alonzo 多出**原子排序** `AtSort(s)`。排序系统 (B, A, ξ) 给
每个原子排序指定一个**类型** ξ(s)，框架条款 F5 要求 `D_σ ⊆
D_{ξ(σ)}`——**子类型 = 域的包含**。定型规则同步放宽（如 Eq 只
要求 ξ(σ)=ξ(τ)），quasitype（6.9 节的谓词子型）就此获得了语构
身份：16 章 Ψ′✱ 把群论映到 {r ≠ 0} 用的正是这层机制。与 22 章
（MLTT 的子集类型）对照：Church 式路线用「域包含」做子类型，
Martin-Löf 路线用 Σ 型打包见证——两种哲学，同一需求。

## 17.5 AlonzoQE：引用与求值

第三个变体最赛博：新增类型 **ε**（表达式自身当值）与两个算子——
**引用** `⌜A⌝`（V8：值 = A 的语法树）和**求值** `⟦A⟧`（V9：把
ε 型的值再跑一遍求值）。配套的**逻辑常数** q-eq/q-app/q-abs/q-dd/
q-op/q-quo（表 14.5）把每个表达式构造子都翻成 ε→ε 的函数——
构造子与常数一一对应，语言的「元层」被压进对象层。Lisp 的
quote/eval 在类型论里的直系亲戚；cttqe（Farmer 等的引理系统）
是它的工程版。证明系统有个诚实的缺口：**只对 eval-free 公式完
备**（14.3.4）——带 eval 的公式会「在语法里跑语义」，哥德尔式
的自指在门口探头。

机器面（Coq 与 Lean 双份）：深度嵌入的往返定理——

```lean
def omega : Exp → Exp                      -- Ω：按 14.3.2 逐构造子爬行
  | .num n => qNum n
  | .plus a b => qPlus (omega a) (omega b)
  | .mul a b => qMul (omega a) (omega b)

theorem omega_id (e : Exp) : omega e = e            -- 引用不丢信息
theorem eval_of_quoted (e : Exp) : sem (omega e) = sem e
```

`omega_id` 是 V8 的定理化身（构造子与逻辑常数一一对应时 Ω 是
恒等）；`eval_of_quoted` 是「求值引用 = 求值本体」的最小版本。
反身证明助手（MetaCoq、Lean 的引用机制）走的就是这条路的工业
加强版——19 章归纳族的「LF 自举」味道在此提前一嗅。

> **坑位速记**
> ① Coq 8.20 里 `iota` 在 **ClassicalDescription**（不在
>   ClassicalEpsilon）；签名是 `iota [A] (i : A) P`——第二参是
>   **默认元素**不是 inhabited（epsilon 才要 inhabited）；
> ② Coq 的 `exists!` 析构是**三层** intro 模式 `[x [Hx Huni]]`，
>   且 `exists! x, P x -> Q` 会被解析成 `exists! x, (P x -> Q)`
>   ——前提必须加括号；
> ③ 自定义谓词（square4）喂给 lia 前要 `unfold`——simpl 不展开
>   Prop 定义，lia 看不见约束就报 Cannot find witness；
> ④ Lean core **没有 ∃! 记号**（mathlib 的）：展开成
>   `∃ n, p n ∧ ∀ m, p m → m = n`；
> ⑤ `Classical.choose` 的 def 要标 `noncomputable`；其
>   choose_spec 给的是整个合取，取 `.1` 才是见证性质；
> ⑥ omega 拒绝非线性假设（m*m=4 直接「无可用约束」）——先
>   rw 换成常数不等式再 omega。

---

上一章：[16 理论态射与小理论方法](16-morphisms.md) · 下一章：[18 System F](18-systemf.md)
