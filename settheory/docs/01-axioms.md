# 01 · 公理：从 Cantor 到 Russell 悖论

> 事先应被告诫：不要把"集合"想象成任何旧式的东西；它是一个
> 由公理严格约束的对象。——Jech §1 的精神（意译）

本章覆盖 Jech §1：一阶语言、类与真类、九条公理、以及从公理
搭建起来的基本构造（有序对、关系、函数、等价关系）。机器通道
回答一个别处不存在的问题：**公理在证明助手里是什么？**

## 1.1 语言：一切从 ∈ 出发

集合论的一阶语言只有两个非逻辑符号：二元谓词 **∈**（隶属）与
**=**（相等，逻辑自带）。公式由原子公式 x ∈ y、x = y 经 ¬、∧、∨、
→、↔ 与量词 ∀x、∃x 生成。实践里我们会用大量缩写记号（⊆、⋃、
P(X)、{x : φ}……），但每个缩写都可以展开回只含 ∈ 和 = 的公式——
这是集合论"单谓词征服全部数学"的野心。

自然数的下标约定：变元 x₀, x₁, x₂… 在 Prolog 通道里被做成数据
`v(0)`, `v(1)`, `v(2)`，良型检查器是十几行规则（`examples/prolog/01_axioms.pl`）：

```prolog
termx(v(N)) :- integer(N), N >= 0, !.
termx(empty_const) :- !.
termx(upair_union(T)) :- !, termx(T).

form(mem(T1, T2)) :- termx(T1), termx(T2).
form(all(N, F))   :- integer(N), N >= 0, form(F).
```

注意 `termx` 认识三个形状：变元、常量 `empty_const`（空集，无穷
公理里用）、复合项 `upair_union(t)`（t ∪ {t}，配对+并的缩写）。
语言可以只有 ∈，但缩写让公理能读——这正是 Jech 说"公式里用
定义符号，但默认可展开"的形式化版本。

## 1.2 类：真类与集合的第一次分界

ZF 只有一类对象：集合。但**类**（class）这个直觉记号太好用，
数学实践离不开它。形式化地说，每个公式 φ(x, p₁, …, pₙ) 定义一个类

    C = {x : φ(x, p₁, …, pₙ)}

x ∈ C 当且仅当 φ(x, p₁, …, pₙ)。每个集合都是类（取公式 x ∈ S），
但有些类不是集合——**真类**（proper class）。第 00 章已经见过
第一个真类：Russell 类 {X : X ∉ X}。第二个是全类 V = {x : x = x}：
若 V 是集合，对它用分离就得到 Russell 类。

类运算 ⊆、∩、∪、−、⋃C 按元素逐点定义。关键事实（分离公理
的直接推论）：

> **类的安全性**：类与集合的交总是集合——"a subclass of a set
> is a set"。

这个口号在后续章节反复出现：它是"真类不能被吸收进集合"和
"集合内部随便切割"的平衡点。

## 1.3 九条公理：逐条讲清

以下按 Jech §1 的顺序给出，每条附"角色"与"机器形态"。

**I 外延性（Extensionality）** 若 X 与 Y 元素相同，则 X = Y：

    ∀u(u ∈ X ↔ u ∈ Y) → X = Y

集合由元素**完全决定**——不是"由元素加一个标签"决定。反方向
（相等则元素相同）是一阶逻辑的公理。**机器形态**：Lean 的
PSet 世界里它是定理 `PSet.Mem.ext`（`examples/lean/Settheory/Ch01Axioms.lean`）：

```lean
example {x y : PSet} (h : ∀ w, w ∈ x ↔ w ∈ y) : PSet.Equiv x y :=
  PSet.Mem.ext h
```

而在 Isabelle/ZF 里它是内核公理 `extension`（`examples/isabelle/ST01/Axioms.thy`
直接 `thm extension` 展示）：

```isabelle
extension : "A = B ⟷ A ⊆ B ∧ B ⊆ A"
```

注意陈述差异：Isabelle 版把两向合写成一个 iff。ST01 用它做了
第一件实事——配对的对称性：

```isabelle
lemma pair_commute: "Upair(a, b) = Upair(b, a)"
proof -
  have "Upair(a,b) ⊆ Upair(b,a)" by (auto simp: Upair_iff)
  moreover
  have "Upair(b,a) ⊆ Upair(a,b)" by (auto simp: Upair_iff)
  ultimately show ?thesis by (rule equalityI)
qed
```

两向包含 + 外延 = 相等。这就是公理"干活"的最小样板。

**II 配对（Pairing）** 对任何 a、b 存在 c 恰含 a、b。由外延性
c 唯一，记 {a, b}；单点集 {a} = {a, a}。**有序对**是本章第一个
非平凡定义（Kuratowski）：

    (a, b) = {{a}, {a, b}}

它满足 (a,b) = (c,d) ↔ a = c ∧ b = d（Jech (1.1)，习题 1.1）。
证明值得看一遍（三段式）：设 (a,b) = (c,d)。{a} ∈ (c,d) 展开
得 {a} = {c}（推出 a = c）或 {a} = {c,d}（推出 c ∈ {a}，即
c = a）。对称地得 b = d。ST01 把"a = c 的半边"完整机器化了：

```isabelle
lemma opair_injective_first:
  assumes h: "OPair(a,b) = OPair(c,d)"
  shows "a = c"
proof (rule ccontr)
  assume "a ≠ c"
  have step1: "{a} ∈ {{a}, {a,b}}" by (simp add: Upair_iff)
  have step2: "{a} ∈ {{c}, {c,d}}"
    using step1 h unfolding OPair_def by simp
  then have disj: "{a} = {c} ∨ {a} = {c,d}"
    by (auto simp: Upair_iff)
  then show False
  proof (elim disjE)
    assume "{a} = {c}"
    then have "a = c" by blast
    with ‹a ≠ c› show False by contradiction
  next
    assume "{a} = {c,d}"
    then have "c ∈ {a}" by (auto simp: Upair_iff)
    then have "a = c" by blast
    with ‹a ≠ c› show False by contradiction
  qed
qed
```

Python 通道对有限宇宙穷举验证了注入性（`examples/python/01_axioms.py`）：

```python
def opair(a, b):
    """Kuratowski 编码：(a,b) = {{a},{a,b}}"""
    return frozenset([frozenset([a]), frozenset([a, b])])

def opair_injective_test(universe):
    import itertools
    for a, b, c, d in itertools.product(universe, repeat=4):
        if opair(a, b) == opair(c, d):
            assert (a, b) == (c, d), f"反例：({a},{b}) == ({c},{d})"
    return True
```

4⁴ = 256 个组合全部通过；特例 (a,a) = {{a}} 的塌缩也被检验。
n 元组按 (a,b,c) = ((a,b),c) 嵌套定义，分量独立性由嵌套结构保持。

**III 分离（Separation，模式）** 对每个公式 φ(u, p)：

    ∀X ∀p ∃Y ∀u(u ∈ Y ↔ u ∈ X ∧ φ(u, p))

这是朴素概括的"安全版"：性质只能在已有集合内切割。一阶语言
不能量化"所有公式"，所以它**不是一条公理而是公理模式**——
每个 φ 一条实例。Prolog 通道用 `schema(_)` 标记模式实例
（01_axioms.pl 的 `separation_III(schema(_))`），这是处理模式的
标准深嵌入手法。

分离立刻给出：X ∩ Y、X − Y 是集合；空类 ∅ 是集合（分离于
任何 X，用性质 u ≠ u——前提是至少存在一个集合，无穷公理保证）。

**IV 并（Union）** ∀X ∃Y ∀u(u ∈ Y ↔ ∃z ∈ X, u ∈ z)。Y 唯一，
记 ⋃X。X ∪ Y := ⋃{X, Y}。

**V 幂集（Power Set）** ∀X ∃Y ∀u(u ∈ Y ↔ u ⊆ X)。记 P(X)。
Cantor 定理（第 00 章）说明幂集永远"更大"——层级引擎。习题
1.2 值得一做：**没有 X 使 P(X) ⊆ X**（否则 Cantor 的对角元素
D = {x ∈ X : x ∉ f(x)} 给出矛盾）。

**VI 无穷（Infinity）** 存在归纳集 S：∅ ∈ S 且 ∀y ∈ S, y ∪ {y} ∈ S。
这是唯一一条"直接断言无穷存在"的公理。自然数由

    N = ⋂{X : X 归纳}

定义为最小归纳集（分离+并的产物：交集分离于任何归纳集）。
von Neumann 方案 n+1 = n ∪ {n} 让每个 n 传递且 n = {m : m < n}。
Julia 通道把它跑了起来（`examples/julia/01_axioms.jl`）：

```julia
vn_succ(n) = (n..., n)                  # n+1 = n ∪ {n}（元组的并）

v0 = ()                                  # 0 = ∅
v1 = vn_succ(v0)                         # 1 = {∅}
v2 = vn_succ(v1)                         # 2 = {∅,{∅}}
v3 = vn_succ(v2)                         # 3 = {∅,{∅},{∅,{∅}}}
```

`v3[3] == v2` 断言"3 的最后一个元素是 2"——正是 n+1 = n ∪ {n}
的元素侧描述。

**VII 替换（Replacement，模式）** 对每个"函数性"公式 φ(x, y, p)
（每个 x 至多一个 y）：

    ∀X ∃Y ∀y(y ∈ Y ↔ ∃x ∈ X, φ(x, y, p))

函数像是集合。它是超穷构造的通行证：第 02 章的超穷递归、
第 09 章的秩层级 V = ⋃V_α 都靠它把"逐段构造"装配成集合。
习题 1.14（分离可由替换推出）的构造极漂亮：

> 令 F = {(x, x) : φ(x)}。F 是函数，{x ∈ X : φ(x)} = F[X]。

"分离 ⊆ 替换"与"替换 ⊄ 分离"——后者在构造 ω+ω 或 V_ω 时
显形（分离造不出"新秩"的集合）。

**VIII 正则性（Regularity，Foundation）** 每个非空集有 ∈-极小元。
它禁止 x ∈ x、禁止无穷 ∈-下降链，保证宇宙按秩分层。第 09 章正题。

**IX 选择（Choice）** 每个非空集族有选择函数。它与前八条性质
不同：断言存在性而不给出定义。第 05 章正题；本篇内先当它存在。

## 1.4 从公理到基本构造

有了公理，第 00 章承诺的"基本积木"逐一落地：

- **关系**：n 元关系是 n 元组的集合；R ⊆ X×Y 的域、值域、场。
- **笛卡尔积** X×Y = {(x,y) : x ∈ X ∧ y ∈ Y} 是集合，因为
  X×Y ⊆ P(P(X ∪ Y))（有序对的 Kuratowski 编码有两层幂集）。
- **函数**：单值关系。f : X → Y 的集合记 Y^X ⊆ P(X×Y)。
- **限制与扩张**：f↾X、f 的扩张 g ⊇ f。
- **等价关系与划分**：等价类 [x]，商 X/= 是划分；反之每个
  划分定义等价关系。

这些构造的每一步都在"消耗公理"：积用配对+并+幂+分离；商用
分离（于 P(X)）；函数替换像用替换。**数学实践的全部日常对象
就这样从 ∈ 一个谓词里生长出来。**

Coq 通道把"消耗公理"做成了显式记账（`examples/coq/Ch01_axioms.v`）。
先声明一个"ZF 结构"——载体 + 隶属关系 + 四条公理的证据：

```coq
Record ZFStructure {A : Type} {mem : A -> A -> Prop} : Prop := BuildZF
  {
    zf_extensional :
      forall x y : A, (forall u, mem u x <-> mem u y) -> x = y ;
    zf_pairing :
      forall a b : A, exists c, forall u, mem u c <-> (u = a \/ u = b) ;
    zf_union :
      forall X : A, exists c, forall u,
        mem u c <-> exists z, mem z X /\ mem u z ;
    zf_power :
      forall X : A, exists c, forall u,
        mem u c <-> (forall w, mem w u -> mem w X)
  }.
```

然后**用公理证定理**——单点集的存在性：

```coq
Lemma singleton_exists :
  forall a : A, exists c, forall u, mem u c <-> u = a.
Proof.
  intros a.
  destruct (zf_pairing ZF a a) as [c Hc].
  exists c.
  intros u. rewrite Hc. split.
  - intros [H | H]; assumption.
  - intro H. left; assumption.
Qed.
```

读法：取配对 {a, a}，其成员条件 u = a ∨ u = a 退化为 u = a。
`Print Assumptions` 报告 `Closed under the global context`——
这个定理不依赖任何 Coq 公理，依赖全部集中在 Section 变量
ZF（我们的公理包）上。**公理是假设、定理是消耗假设的推导**，
浅嵌入让这条界线从哲学变成类型。

## 1.5 HF：公理可以被满足

"公理"还有一种身份：**被模型满足**。遗传有限集合 HF 是最小
的例子——"ZFC − 无穷公理"的标准模型。Agda 通道把它做了出来
（`examples/agda/Ch01_hf.agda`）：

```agda
data HF : Set where
  mk : (X : List HF) -> HF

_∈h_ : HF -> HF -> Set
x ∈h mk X = x ∈ X

pairh : HF -> HF -> HF
pairh a b = mk (a ∷ b ∷ [])
```

配对公理在 HF 中成立——`pairh` 就是满足性证据（构造即证明）。
成员刻证的入场券有两个构造子：

```agda
pair-member-left : (a b w : HF) -> w ≡ a -> w ∈h pairh a b
pair-member-left a b .a refl = here refl

pair-member-right : (a b w : HF) -> w ≡ b -> w ∈h pairh a b
pair-member-right a b .b refl = there (here refl)
```

但 HF 也暴露了一个深刻的裂缝——**外延性不免费**：

```agda
dup-sub-single : (a : HF) -> mk (a ∷ a ∷ []) ⊆h mk (a ∷ [])
dup-sub-single a w (here refl) = here refl
dup-sub-single a w (there (here refl)) = here refl
dup-sub-single a w (there (there ()))

single-sub-dup : (a : HF) -> mk (a ∷ []) ⊆h mk (a ∷ a ∷ [])
single-sub-dup a w (here refl) = here refl
```

`mk (a ∷ a ∷ [])` 与 `mk (a ∷ [])` 元素完全相同（互相包含），
但作为构造项不相等——`refl` 会卡住。这就是**证明相关性**
（proof relevance）：同一个集合有多张成员表。ZFC 的回应是把
外延性列为公理（等式公理的加强）；类型论的回应是做商
（mathlib 的 `ZFSet` = PSet 商掉 `Equiv`）或规范化（列表排序
去重）。第 02 章将继续这条线。

## 1.6 机器通道的总图景

本章七通道各就各位：

| 通道 | 公理的身份 | 文件 |
|---|---|---|
| Lean+mathlib | Type 世界降格为构造；PSet 世界是定理 | `Settheory/Ch01Axioms.lean` |
| Isabelle/ZF | 内核 axiomatization，直接使用 | `ST01/Axioms.thy` |
| Coq | Record 字段（假设），推导显式消耗 | `Ch01_axioms.v` |
| Agda | HF 模型满足配对；外延性裂缝可见 | `Ch01_hf.agda` |
| Julia | 构造子（pair/filter/map/powerset） | `01_axioms.jl` |
| Python | Kuratowski 编码穷举验证 | `01_axioms.py` |
| Prolog | 模式的 schema 深嵌入 + 良型检查 | `01_axioms.pl` |

Julia 侧还有一段对照值得记（01_axioms.jl）：对任何 g : X → P(X)，
对角线集 D = {x ∈ X : x ∉ g(x)} 不在 g 的像中——Cantor 定理的
有限预演。程序世界的集合（哈希集合）天然外延、天然有有限选择
函数；**公理的"费用"只在无穷处出现**，这是数值通道反复回访的
主题。

## 1.7 习题精选

1. **（纸笔）** 习题 1.1：验证 Kuratowski 有序对满足 (1.1)。
   （机器版：ST01 的 `opair_injective_first` 与 Python 穷举。）
2. **（纸笔）** 习题 1.2：没有 X 使 P(X) ⊆ X。用 Russell 悖论的
   对角元素。
3. **（纸笔）** 习题 1.10（归纳原理）：A ⊆ N，0 ∈ A 且
   n ∈ A → n+1 ∈ A，则 A = N。（提示：N 的定义就是最小归纳集。）
4. **（机器）** 习题 1.14：分离可由替换推出。（构造：F = {(x,x) :
   φ(x)}，见 01_axioms.pl 的元事实 3。）
5. **（纸笔）** 习题 1.15：并/幂/替换可以弱化为"存在包含集"版本
   （(1.8)-(1.10)），配合分离恢复完整——理解"分离补全存在性"
   的分工。

---

上一章：[00 导引](docs/00-intro.md) · 下一章：[02 序数与超穷归纳递归](docs/02-ordinals.md)
