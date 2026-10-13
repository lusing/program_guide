# 00 · 导引：集合论与机器证明

> 没有人能把我们从 Cantor 为我们创造的乐园中驱逐出去。——David Hilbert
> （Jech 扉页题词）

## 0.1 这本教程讲什么

集合论有两个面孔。作为**语言**，它是整个数学的底座：函数、关系、
数系、空间，一切现代数学对象最终都用集合写出。作为**对象**，它本身
是一门深邃的数学：无穷有没有大小之分？实数有多少个？每条定理都能被
证明或者证伪吗？这些问题在十九世纪末还带着哲学气质，到二十世纪变成
了精确的数学问题，并且得到了精确到令人震惊的回答：

- **无穷确实有大小之分**：偶数和自然数一样多，但实数严格更多
  （Cantor，1874）。
- **"多少"可以无休止地分下去**：没有最大的无穷（Cantor 定理）。
- **有些问题数学回答不了**：连续统假设（"实数恰是第二小的无穷"）
  在标准公理系统 ZFC 中既不可证也不可驳（Gödel 1938 + Cohen 1963）。

Jech 的《Set Theory》是这门学科的标准研究生教材之一。本教程以它的
第一版（1978，Academic Press）为纲，覆盖全部 44 节：从 ZFC 公理出发，
经过序数、基数、公理选择、构造宇宙 L、力迫法、大基数，直到描述集合
论与决定性公理。每一章都自包含：定理给出完整证明或完整讲解，Jech 的
编号（如 "Jech §2.11"）只作溯源注记，不构成阅读依赖。

同时，这是一部**带着六个机器通道**的教程。集合论恰好是各证明助手
立场分歧最大的领域之一——这本身就是极好的教学素材，我们先卖个关子，
在 0.4 节展开。

## 0.2 为什么需要公理：从 Cantor 的乐园到 Russell 的炸弹

Cantor 最初的集合概念是天真而宽泛的：任何性质都确定一个集合，

> 全称概括（朴素但错误）：对任何性质 φ，存在集合 Y = {x : φ(x)}。

1901 年 Russell 检查了这条原则，发现了逻辑史上最著名的炸弹。把性质
取为 "x ∉ x"，得到 Russell 类

    R = {X : X ∉ X}

问：R 属于 R 吗？若 R ∈ R，按定义 R ∉ R；若 R ∉ R，按定义 R ∈ R。
两个方向都是矛盾。注意这不是"很难回答"，而是**任何回答都自我否决**——
命题 P ↔ ¬P 不可能被任何一致的理论满足。

这个悖论送给我们三条教训：

1. **全称概括必须放弃**，用其弱化版"分离模式"取代：性质只能在**已有**
   的集合内部划出子集（"a subclass of a set is a set"）。
2. **万有集不存在**：V = {x : x = x} 是"真类"（proper class）而非集合。
   悖论出在"集合的集合不设限"，不在"性质"这个想法本身。
3. 分离太弱，撑不起数学（连 X ∪ Y 的存在都推不出），必须补充"构造
   公理"：配对、并、幂集、无穷、替换。这就是 ZFC 的形状。

ZFC 的九条公理（Jech §1 的顺序）各自的角色：

| 公理 | 内容 | 角色 |
|---|---|---|
| 外延性 | 元素相同则集合相等 | 集合由元素决定 |
| 配对 | {a, b} 存在 | 构造基本积木 |
| 分离（模式） | {u ∈ X : φ(u)} 存在 | 安全的概括 |
| 并 | ⋃X 存在 | 聚合 |
| 幂集 | P(X) 存在 | 层级引擎（Cantor 定理的舞台） |
| 无穷 | 归纳集存在 | 承认实无穷 |
| 替换（模式） | 函数像 F[X] 是集合 | 超穷构造的通行证 |
| 正则性 | 每个非空集有 ∈-极小元 | 禁止 x ∈ x 与无穷下降链 |
| 选择 | 非空族有选择函数 | 本书最特殊的公理，第 05 章正题 |

前八条合称 ZF；加选择公理是 ZFC。第 01 章将逐条展开并展示它们如何
协作搭建整个数学世界。

## 0.3 本书的地图

Jech 第一版的 44 节构成七篇，本教程同样分七篇，外加导引与收官：

| 篇 | 章 | 内容 | 关键词 |
|---|---|---|---|
| 一 | 01–09 | 公理集合论 | ZFC、序数、基数、实数、AC、基数算术、滤子、共尾性、秩层级 |
| 二 | 10–15 | 传递模型 | 绝对性、Gödel 的 L、AC+GCH 的相对一致性、Lévy 层级、OD/HOD |
| 三 | 16–22 | 力迫 | 偏序与泛型、力迫定理、布尔值模型、CH 独立性、对称模型 |
| 四 | 23–28 | 力迫的应用 | Suslin 问题、Martin 公理、迭代力迫、组合问题 |
| 五 | 29–34 | 可测基数 | 测度问题、超幂与初等嵌入、Silver 不可辨别、L[U] |
| 六 | 35–40 | 其他大基数 | 紧基数、实值可测、理想饱和、大基数与 GCH |
| 七 | 41–46 | 描述集合论 | Borel/解析集、投影层级、Solovay 模型、决定性公理 AD |

一条贯穿全书的暗线：**"多大"与"多可定义"的相互作用**。Cantor 定理
说幂集永远更大；Gödel 的 L 说"可定义的部分"满足 GCH；Cohen 的力迫
说我们可以向宇宙里加进全新的集合；大基数说某些无穷大到足以"看见"
整个宇宙的影子（j : V → M）；决定性公理则说实数集上的一场无穷博弈
可以代替选择公理，换来一个更规整的实数世界。

## 0.4 六个机器通道的立场

集合论是各证明助手"哲学分歧"最尖锐的领域。Lean/Coq/Agda 是**类型论**：
每个对象先有类型，"x ∈ x" 这样的命题根本无法成型；Isabelle/HOL 是
**带类型的经典高阶逻辑**；而 ZFC 是**无类型的一阶理论**。于是产生了
一个在其他领域不存在的问题：机器到底该怎样"谈"集合论？本教程用六条
通道给出六种回答，每章至少演示其一。

### Lean 4 + mathlib：公理在类型论里变成什么

Type 宇宙是分层的：`Type 0` 的居民是小类型，而 `Type 0` 自己住在
`Type 1` 里。Russell 悖论在这个塔里无法成像——不存在"所有类型的类型"。
mathlib 在这个宇宙里搭建了全套 `Ordinal`（von Neumann 序数）与
`Cardinal`（基数）理论，`SetTheory/ZFC` 里还有一个 ZFC 内模型
（`PSet`，第 01 章详述）。来看导引文件 `examples/lean/Settheory/Ch00Intro.lean`
里的三段：

```lean
def typeHierarchy : Type 1 := Type 0
```

这行定义能通过检查，本身就是类型层级的活证据：`Type 0` 是 `Type 1`
的**居民**（def 的右侧类型是 `Type 1`，左侧给出 `Type 0` 作为项）。
"ℕ ∈ ℕ" 则不是良型命题——Membership 实例要求左边类型的元素类型恰为
右边类型，这在塔里找不到位置。

```lean
example : (1 : Ordinal) = (0 : Ordinal) + 1 := by simp

example : (1 : Ordinal) + 1 = 2 := one_add_one_eq_two
```

mathlib 中序数的后继由 `SuccOrder` 实例给出（`succ o = o + 1`），
1 = 0+1、2 = 1+1 这些 von Neumann 事实是库内定理。

```lean
example (κ : Cardinal) : κ < 2 ^ κ := Cardinal.cantor κ
```

Cantor 定理——本书反复使用的引擎——在 mathlib 里是一行调用。**注意
一个意味深长的现象**：在 ZFC 里，"幂集存在"（幂集公理）与"没有满射
X → P(X)"（Cantor 论证）是两件事，前者是公理；在类型论里 `X -> Prop`
天然存在，Cantor 论证照旧成立——**公理与定理的身份在两个世界间流动**，
这是本教程机器通道的第一课。

### Isabelle/ZF：正统的一阶集合论

Isabelle 发行版自带一个 **ZF object-logic**：把无类型一阶集合论直接
做进逻辑内核，全类 V 无法命名（只有集合变元），九条公理以
`axiomatization` 声明。这是与 Lean 完全相反的哲学：不做塔，直接住在
乐园里。`examples/isabelle/ST00/Intro.thy` 抽查了库里的公理原貌：

```isabelle
thm extension        (* A = B ⟷ A ⊆ B ∧ B ⊆ A *)
thm infinity         (* 0 ∈ Inf ∧ (∀y∈Inf. succ(y) ∈ Inf *)
thm foundation       (* A = 0 ∨ (∃x∈A. ∀y∈x. y ∉ A) *)
```

三条公理逐字对应 Jech §1 的清单（外延、无穷、正则）。更有分量的
是 Isabelle/ZF 库自带的 **Constructible** 会话——Paulson 把 Gödel 的
相对一致性证明（L 的全部理论，第 12–13 章的正题）形式化了，这是任何
其他证明助手都没有的官方资产。本书第二篇将反复以它为锚点。

### Coq：把悖论拆成 transport

Coq 与 Lean 同属类型论，但我们在导引文件 `examples/coq/Ch00_intro.v`
里做了一个更精细的实验：Russell 炸弹的**安全拆解版**。原版悖论需要
"x ∈ x"；命题层的类似物是 "¬P = P"。这个等式在 Coq 里是**可以假设**
的（它是关于任意命题 P 的假设），于是可以观察它如何爆炸：

```coq
Lemma nprp : forall P : Prop, (~ P) <> P.
Proof.
  intros P E.
  (* 双向通道：c 把 ¬P 送进 P，c' 把 P 送回 ¬P *)
  pose (c := fun np => match E in _ = T return T with eq_refl => np end).
  pose (c' := fun p => match (eq_sym E) in _ = T return T with eq_refl => p end).
  (* t : ¬P 自指：t(p) = c'(p)(p) *)
  assert (t : ~ P) by (intro p; exact (c' p p)).
  exact (t (c t)).
Qed.
```

读法：假设等式 E : ¬P = P，`match E in _ = T return T` 是 Coq 的
transport——把 ¬P 的居民沿 E 运输到 P（c），以及反向（c'）。于是
t(p) := c'(p)(p) 是良型的 ¬P 居民，而 `t (c t)` 把 t 沿通道运进 P 再
喂给自己：False。`Print Assumptions` 报告 `Closed under the global
context`——**零公理、零排中律**。这就是 Russell 论证在类型论里的
正确形态：悖论不发生在"集合"层，而发生在"不允许的自指通道"层；
transport 是合法通道，所以 ¬P = P 一旦假设就立即爆炸。紧接着的
Cantor 定理是它的对角线推论：

```coq
Theorem cantor_diagonal :
  forall (X : Type) (f : X -> X -> Prop),
    exists g : X -> Prop, forall x : X, g x <> f x x.
Proof.
  intros X f.
  exists (fun x => ~ f x x).
  intros x. apply nprp.
Qed.
```

对任何"名单" f 都能**显式**造出逃逸者 g = λx. ¬f x x——对角线是
一台程序，不只是存在性论证。

### Agda：HF——有限集合论的标准模型

Agda 通道给出构造性视角。`examples/agda/Ch00_intro.agda` 定义了
**遗传有限集合**（HF）：每个集合由其（有限）元素列表给出——

```agda
data HF : Set where
  mk : (X : List HF) -> HF

_∈h_ : HF -> HF -> Set
x ∈h mk X = x ∈ X
```

HF 是 "ZFC − 无穷公理" 的标准模型：配对、并、幂集、分离对它全部
成立（可以构造性验证），而无穷公理失败（HF 的每个成员都是有限的）。
第 01、02 章将把 HF 做成完整的小型集合论，作为"公理如何被模型满足"
的第一个实例。注意 `x ∈h mk X` 是证明相关的（同一集合可有多张成员
表）——外延性需要商处理，这个裂缝恰恰对应了 ZFC 里"外延性是公理而非
定义"的事实。

### Julia / Python：把定理当机器开

数值通道承担两类任务。其一：**让构造性定理跑起来**。对角线机器
（`examples/julia/00_intro.jl`）接受任何有限名单，输出逃逸者并报告
逃逸距离：

```julia
function diagonal_escape(list::Vector{Float64}, n::Int)
    flips = [1 - binary_digits(list[k], n)[k] for k in 1:n]
    return from_digits(flips)
end
```

程序对 52 个精心挑选的实数跑出正的逃逸距离——但这只是有限名单的
失败。Cantor 的贡献是把"每份有限名单都失败"升级为"任何可数名单都
失败"；数值机器演示前者，**永远无法替代后者**，这个边界本身是教学
内容。其二：**给超穷对象画像**。`examples/python/00_intro.py` 演算
康托集的三进制地址学：

```python
def ternary_address(x, n=12):
    """返回 x 的 n 位三进制展开数字（用 Fraction 精确计算）"""
    from fractions import Fraction
    y = Fraction(x).limit_denominator(10**9)
    ...
```

1/9 的主地址 0.01000...₃ 含数字 1，端点的备选地址 0.00222...₃ 不含——
"康托集 = 可用 0 与 2 写出的点"，于是 |C| = 2^ℵ₀。注意这里**必须用
Fraction**：浮点的 1/9 在三进制展开第 12 位就漂出 1，错误的三进制
地址会直接推翻断言——数值通道的第一条军规是先保证算术精确。

### Prolog：一阶语言的语法现场

Prolog 通道把一阶语言本身做成数据（深嵌入）。`examples/prolog/00_intro.pl`
用项/公式归纳定义给出良型性检查器，并逐条验证公理的形状：

```prolog
form(mem(T1, T2)) :- term(T1), term(T2).
form(all(N, F))   :- integer(N), N >= 0, form(F).

axiom(extensionality,
       all(0, all(1, imp(all(2, iff(mem(v(2), v(0)), mem(v(2), v(1)))),
                        eq(v(0), v(1)))))).

axiom(pairing,
       all(0, all(1, ex(2, all(3,
          iff(mem(v(3), v(2)),
              or(eq(v(3), v(0)), eq(v(3), v(1))))))))).
```

`axiom(Name, F)` 存的是公式的**语法**，`form_chk/1` 独立复检其良型性
——外延与配对两条都以"良型 OK"通过。文件里还有一个 Russell 炸弹的
程序形态：两条互指规则 `p :- not_p.` 与 `not_p :- not_p` 的镜像，一旦
真的去 `call(p)` 就无限递归——**不一致的程序形态正是递归不终止**，
而 Prolog 的规则恰好只能描述一阶逻辑的可计算片段。

## 0.5 各章的机器化边界

不是所有定理都适合机器化。本教程的分工协议（继承自泛函分析教程）：

- **基础篇（01–09）**：mathlib 的 `SetTheory/{Ordinal, Cardinal, ZFC}`
  与 Isabelle/ZF 库（`Ordinal`、`CardinalArith`、`Zorn`、`AC`）几乎
  全覆盖——完整机器证明为主。
- **L 篇（10–15）**：Isabelle/ZF `Constructible` 独家锚点。
- **力迫篇（16–28）**：mathlib 没有力迫开发（如实标注）；Lean/Isabelle
  走布尔代数与偏序官方基础 + 自建有限玩具模型，Coq 做 HF 上的有限
  力迫，Julia/Python 做 Aronszajn 树与组合计算，Prolog 做泛型搜索。
  力迫定理本体以正文完整讲解为主。
- **大基数篇（29–40）**：共尾性/正则/不可达有官方锚点；可测以上的
  一致性强度以讲解为主 + 有限超幂等组合实验。
- **描述集合论篇（41–46）**：Borel/可测有 mathlib 锚点；
  Gale–Stewart 有限博弈是 Agda/Prolog 的完美场地；Solovay 模型与 AD
  本体讲解。

每章末尾会注明该章哪些结论被机器证实、哪些以讲解承载、以及**为什么**
机器暂时做不到（通常是：库未开发、工程量超出教程范围、或数学上根本
不可判定）。

## 0.6 如何使用本教程

1. **只读 docs/ 也能学**：正文自包含，代码段都嵌在讲解里；
   `examples/` 是同内容的可运行副本。
2. **跑起来**：全量验证 `pwsh -NoProfile -Command '& ./build.ps1 -All'`，
   单章验证 `-Chapter 00`。
3. **对照原书**：Jech 编号贯穿全文，但没有它你不会迷路。
4. **做习题**：各章习题分"纸笔 / 机器"两档，机器习题给出验证命令。

---

上一章：（本书起点） · 下一章：[01 公理：从 Cantor 到 Russell 悖论](docs/01-axioms.md)
