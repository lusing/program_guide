# 07 集合、函数与等价关系

**对应原书 §2.1（pp. 80-102）。**

---

## 7.1 为什么群论要从集合论讲起

第 01 章的数论默认使用了"集合"与"函数"这两个词而从未定义它们。进入群论
之前必须补上这一课，原因很实际：**一个群就是一个带运算的集合，一个群
同态就是一个保持运算的函数**——集合论的词汇表就是群论的语法。原书把这一
节放在群章开头，正是"先修语法再读课文"的安排。

## 7.2 函数：三种性格

> **定义** 设 X、Y 是集合。函数 f : X → Y 是一个规则，把每个 x ∈ X
> 对应到唯一的 f(x) ∈ Y。X 称为定义域，Y 称为陪域。

单看定义什么也看不出，函数的三种"性格"才是主角：

> **定义** f : X → Y 称为
> - **单射**（injection，一对一）：f(x₁) = f(x₂) ⟹ x₁ = x₂；
> - **满射**（surjection，映到）：对每个 y ∈ Y 存在 x ∈ X 使 f(x) = y；
> - **双射**（bijection，一一对应）：既单又满。

双射的意思是 X 与 Y 的元素可以配对配尽——这是"两个集合一样大"的严格
定义（对无限集也一样：ℤ 与 2ℤ 一样大，令 f(n) = 2n）。三个基本事实
（原书命题 2.1 一带）值得全部亲手验证一遍：

1. **复合**：g∘f 定义为 (g∘f)(x) = g(f(x))，且**结合律**成立：
   h∘(g∘f) = (h∘g)∘f。证明是逐点等式，两边的 x 都等于 h(g(f(x)))。
2. **恒等**：每个集合有恒等函数 idx(x) = x，满足 f∘id = f = id∘f。
3. **可逆 ⟺ 双射**：若存在 g : Y → X 使 g∘f = id 且 f∘g = id，则 f
   必是双射（g 抵消了两个方向的"撞车"）；反之双射 f 的逆
   f⁻¹(y) = 唯一的 x 使 f(x) = y 确实是函数。且逆唯一。

有限集上还有一个免费午餐——**鸽笼原理的代数形式**：

> **命题** X 有限且 |X| = |Y| = n 时，对 f : X → Y：
> f 单射 ⟺ f 满射 ⟺ f 双射。

证：n 个鸽子进 n 个笼。"单而不满"意味着某笼空着，于是 n 只鸽子挤
n−1 个笼，必有两只同笼——与单射矛盾。对称地"满而不单"也矛盾。∎

（对无限集这彻底失效：n ↦ 2n 从 ℕ 到 ℕ 单而不满，n ↦ ⌊n/2⌋ 满而不单。
"部分能等于整体"恰是无限的定义性怪癖——戴德金正是用它定义无限。）

## 7.3 等价关系：把"相等"私有化

> **定义** 集合 X 上的关系 ~ 称为**等价关系**，若：
> (i) 自反：x ~ x；(ii) 对称：x ~ y ⟹ y ~ x；(iii) 传递：x ~ y, y ~ z
> ⟹ x ~ z。

等价关系是"某种意义上的相等"的公理化：同余 mod m（第 05 章）、同身高、
"两整数相差偶数"——都满足这三条。给定等价关系，定义 x 的**等价类**

  [x] = {y ∈ X : y ~ x}，

原书**引理 2.19**：x ~ y ⟺ [x] = [y]。证明值得写：若 x ~ y，则对任一
z ∈ [x]，z ~ x ~ y 给 z ∈ [y]，故 [x] ⊆ [y]，对称地反包含；反过来取
z = x 即得。于是**两个等价类要么相等要么不相交**（交非空则相等）。∎

于是等价关系把 X 切成**互不相交的等价类之并**——一个**划分**
（partition）。反过来，任给划分，定义 x ~ y ⟺ x、y 同块，立刻验证三条。
这就得到本节的主定理：

> **定理（等价关系 ↔ 划分）** 集合上的等价关系与划分一一对应。

商集 X/~ 就是"所有等价类组成的集合"——它是把 X 的信息**有损压缩**的
通用手段。第 05 章的 ℤ/mℤ（= {[0], [1], …, [m−1]}）、第 12 章的商群
G/N，走的都是这条路：先在旧集合上定义一个等价关系，再把等价类当作新
元素。**"造新数学对象的标准手法 = 取商"**，这是本教程第二次见到它，
也不会是最后一次。

一个计数练习收尾（本章 Prolog 通道的主角）：n 元集上的等价关系个数
= 贝尔数 B(n)。B(1) = 1, B(2) = 2, B(3) = 5, B(4) = 15——4 个元素的
集合竟有 15 种"打碎"方式。

## 7.4 机器验证一：Lean——单满双与可逆

**文件：`examples/lean/Abstractalgebra/Ch07SetsFunctions.lean`。**
mathlib 把函数三种性格做成 `Function.Injective/Surjective/Bijective`，
可逆做成 `Function.Bijective ↔ ∃ inverse`。文件证明四件事：

```lean
-- 单射的可复合性：单 ∘ 单 = 单
example {f : α → β} {g : β → γ} (hf : Function.Injective f)
    (hg : Function.Injective g) : Function.Injective (g ∘ f) :=
  hg.comp hf

-- 双射 ⇔ 存在双侧逆（mathlib 的 Function.Bijective 定义层完成）
example (f : α ≃ β) : Function.Bijective f := f.injective.and f.surjective

-- 恒等函数是复合的单位元
example (f : α → β) : f ∘ Function.id = f := rfl
```

等价关系一侧用 mathlib 的 `Setoid`（带等价关系的类型）与 `Quotient`：
文件以"模 3 同余"为样例，验证等价类恰有三块，并引用
`Quotient.mk`——第 12 章商群的直接预演。鸽笼原理的代数形式在文件中以
`Fintype` 版出现：`Function.Injective f ↔ Function.Surjective f`
（对 α → β 且 card 相等，mathlib 的 `Function.Bijective` 有限引理链）。

## 7.5 机器验证二：Julia——穷举三条性格

**文件：`examples/julia/07_sets_functions.jl`** 在小集合上把 7.2 节全部
断言**穷举到底**。核心是四个谓词与一个枚举器：

```julia
# n 元集间的全部函数：f 编码为向量 f[i] = 像
all_functions(n, m) = [Tuple(Int.(digits(i; base=n, pad=m))) .+ 1
                       for i in 0:(n^m - 1)]

is_injective(f) = length(unique(collect(f))) == length(f)
is_surjective(f, m) = length(unique(collect(f))) == m
```

（digits 按位展开枚举全部映射。）断言组：(1) 对 3 元集间的全部 3³ = 27
个函数，逐一核对"单 ⟺ 满 ⟺ 双"在 |X| = |Y| 时三者重合——鸽笼命题的
机器版；(2) |X| = 3, |Y| = 4 时存在单而不满（3! = 6 个），无满射——
不等势的方向性；(3) 双射个数恰为 n!（3 元集 6 个，4 元集 24 个）；
(4) 复合结合律在 2 元集间的全部函数对上逐点成立。

等价关系部分：4 元集上的全部 2⁴² = 65536?? 太多——改用"划分枚举"路径
（贝尔数 B(4) = 15）：枚举 15 个划分，逐个验证其诱导关系满足三条公理，
并断言**等价关系数 = 划分数 = 15**——7.3 节对应定理的可数化复现。

## 7.6 机器验证三：Python 与 Prolog

**文件：`examples/python/07_sets_functions.py`**：用 itertools 复算
Julia 全部断言（单满双重合、双射 = n!、贝尔数 B(4) = 15——自实现划分
枚举器 `set_partitions`，并对每个划分验证三公理）；额外计算 B(5) = 52
作上界样本。

**文件：`examples/prolog/07_sets_functions.pl`** 把"关系"表示为序对列表，
三条公理直译：

```prolog
reflexive(R, Xs)  :- forall(member(X, Xs), member(X-X, R)).
symmetric(R)      :- forall(member(X-Y, R), member(Y-X, R)).
transitive(R)     :- forall((member(X-Y, R), member(Y-Z, R)), member(X-Z, R)).
equivalence(R, Xs) :- reflexive(R, Xs), symmetric(R), transitive(R).
```

`forall/2` 在这里语义正确（验证侧是全称）。文件断言：模 3 同余（0..4 上）
是等价关系，其等价类恰为 {[0,3],[1,4],[2]}；"≤"对称性破产（给出反例
序对）；并用 CLPFD 数出 4 元集的 15 个划分——与 Julia/Python 三方互证。

## 7.7 要点回顾

1. 函数三性格：单射防撞车、满射保覆盖、双射 = 配对配尽；复合满足结合律，
   双射 ⟺ 存在（唯一的）双侧逆。
2. 有限等势集上：单 ⟺ 满 ⟺ 双（鸽笼）；无限集上全盘失效。
3. 等价关系 = 私有化的"相等"；等价类两两不相交或相等；等价关系 ↔ 划分
   一一对应（贝尔数数它）。
4. 商集 X/~ = 把等价类当新元素——"造新对象的取商手法"第二次登场
   （第一次是 ℤ/mℤ）。
5. 群论的地基已就位：下一章把"双射"本身当作代数对象——置换登场。

*对应示例：`examples/lean/Abstractalgebra/Ch07SetsFunctions.lean`、
`examples/julia/07_sets_functions.jl`、`examples/python/07_sets_functions.py`、
`examples/prolog/07_sets_functions.pl`。*

---

上一章：[06 日期与天数](06-calendar.md) · 下一章：[08 置换](08-permutations.md)
