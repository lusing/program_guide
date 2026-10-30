# 18 · HOL-Hoare：从三元组到可终止程序证明

对应示例：`../examples/T18_hoare.thy`

## 18.1 从手写规则到使用 HOL-Hoare

霍尔逻辑要回答的问题很具体：**一段命令式程序是否满足预期规格？** 规格写成前件与后件，程序正确性写成三元组。手工定义一门 IMP 语言、再逐条证明赋值、顺序、条件和循环规则，有助于理解逻辑内核；但验证真实例子时，还要重复实现状态更新、语法翻译和验证条件生成器。

Isabelle 2026 发行版已经提供了完整的 `HOL-Hoare` 会话。本章直接使用其中的 `Hoare_Logic`，把重点放在四件更实用的事情上：

1. 部分正确性与完全正确性到底分别承诺什么；
2. `VARS`、`INV`、`VAR` 这些表面语法如何变成正式定义；
3. `vcg` 系列方法能把证明推进到哪一步，哪些数学内容仍要由我们完成；
4. 如何从完全正确性定理得到部分正确性定理和满足后件的结果函数。

理论的入口只有两行：

```isabelle
theory T18_hoare
  imports "HOL-Hoare.Hoare_Logic"
begin
```

如果在一个自建会话里使用这个限定导入，还要在 `ROOT` 中声明会话依赖。本项目主会话的相关部分是：

```isabelle
session IsaTut = "HOL-Eisbach" +
  options [document = false]
  sessions
    "HOL-Hoare"
  theories
    T18_hoare
```

`sessions` 解决的是**构建依赖**；`imports` 解决的是**当前理论使用哪个库理论**。两者缺一不可。本章所有定义和规则都在正文给出，不需要打开发行版源码才能理解示例。

## 18.2 三元组到底断言什么

### 状态、断言与程序

`HOL-Hoare` 不固定程序状态必须是“变量名到整数的函数”。状态类型可以是任意 `'a`，断言就是状态集合，布尔条件也是状态集合：

```isabelle
type_synonym 'a bexp = "'a set"
type_synonym 'a assn = "'a set"
type_synonym 'a sem = "'a \<Rightarrow> 'a \<Rightarrow> bool"
```

写成谓词时，`s \<in> P` 就是“状态 `s` 满足断言 `P`”。采用集合而不是另造断言类型，可以直接使用交集、并集、补集和子集关系。

程序的抽象语法只有四种构造：

```isabelle
datatype 'a com =
  Basic "'a \<Rightarrow> 'a"
| Seq "'a com" "'a com"
| Cond "'a bexp" "'a com" "'a com"
| While "'a bexp" "'a com"

abbreviation SKIP where "SKIP \<equiv> Basic id"
```

- `Basic f` 用函数 `f` 一次性更新状态；赋值是它最常见的特例。
- `Seq c1 c2` 先执行 `c1`，再执行 `c2`。
- `Cond b c1 c2` 根据当前状态是否属于集合 `b` 选择分支。
- `While b c` 在条件属于 `b` 时反复执行 `c`。
- `SKIP` 不改变状态，因为恒等函数 `id` 返回原状态。

### 大步语义 `Sem`

`Sem c s s'` 表示：程序 `c` 可以从初态 `s` 执行到终态 `s'`。它由六条归纳规则生成：

```isabelle
inductive Sem :: "'a com \<Rightarrow> 'a sem"
where
  "Sem (Basic f) s (f s)"
| "Sem c1 s s'' \<Longrightarrow> Sem c2 s'' s' \<Longrightarrow> Sem (Seq c1 c2) s s'"
| "s \<in> b \<Longrightarrow> Sem c1 s s' \<Longrightarrow> Sem (Cond b c1 c2) s s'"
| "s \<notin> b \<Longrightarrow> Sem c2 s s' \<Longrightarrow> Sem (Cond b c1 c2) s s'"
| "s \<notin> b \<Longrightarrow> Sem (While b c) s s"
| "s \<in> b \<Longrightarrow> Sem c s s'' \<Longrightarrow> Sem (While b c) s'' s' \<Longrightarrow>
   Sem (While b c) s s'"
```

最后两条是理解终止性的关键。循环条件为假时，循环立即以原状态结束；条件为真时，必须先执行一次循环体，再从中间状态执行同一个循环。若条件永远为真，就无法由这些规则构造出一个终态。

这个语言是确定性的：同一个程序从同一个初态出发，如果有终态，终态唯一。

```isabelle
lemma Sem_deterministic:
  "Sem c s s1 \<Longrightarrow> Sem c s s2 \<Longrightarrow> s1 = s2"
```

“确定性”不等于“必然终止”：它只禁止两个不同终态，并不保证存在一个终态。

### 部分正确性 `Valid`

核心定义是：

```isabelle
definition Valid :: "'a bexp \<Rightarrow> 'a com \<Rightarrow> 'a anno \<Rightarrow> 'a bexp \<Rightarrow> bool"
where
  "Valid p c a q \<equiv>
     \<forall>s s'. Sem c s s' \<longrightarrow> s \<in> p \<longrightarrow> s' \<in> q"
```

读作：对于任意初态 `s` 和终态 `s'`，**如果**程序能从 `s` 执行到 `s'`，并且 `s` 满足前件 `p`，**那么** `s'` 满足后件 `q`。

这里没有“程序一定到达某个 `s'`”这一项，所以它是部分正确性。参数 `a` 是证明所需的程序注解，后面讲循环时会看到它保存不变式和变式；运行语义 `Sem c s s'` 只看 `c`，不看 `a`。

### 完全正确性 `ValidTC`

完全正确性把量词结构改成了“对每个满足前件的初态，都存在一个合格终态”：

```isabelle
definition ValidTC :: "'a bexp \<Rightarrow> 'a com \<Rightarrow> 'a anno \<Rightarrow> 'a bexp \<Rightarrow> bool"
where
  "ValidTC p c a q \<equiv>
     \<forall>s. s \<in> p \<longrightarrow> (\<exists>t. Sem c s t \<and> t \<in> q)"
```

它同时保证两件事：

1. **终止**：存在 `t` 使得 `Sem c s t`；
2. **结果正确**：这个 `t` 满足后件 `q`。

因此完全正确性蕴含部分正确性：

```isabelle
lemma tc_implies_pc:
  "ValidTC p c a q \<Longrightarrow> Valid p c a q"
```

反过来不成立。18.8 会给出一个永不终止、却满足任意部分正确性后件的循环，把这个差别落到实处。

## 18.3 从 VARS 到状态元组

直接写 `Basic`、`Seq` 和状态集合很啰嗦，所以库提供了命令式记法：

```isabelle
VARS x y
  {P}
  c
  {Q}
```

花括号表示部分正确性；完全正确性改用方括号：

```isabelle
VARS x y
  [P]
  c
  [Q]
```

程序记法包括：

```isabelle
SKIP
x := e
c1; c2
IF b THEN c1 ELSE c2 FI
WHILE b INV {I} DO c OD
WHILE b INV {I} VAR {v} DO c OD
```

### `VARS` 列表不是声明，而是状态布局

`VARS (x::int) y` 把状态组织成 `(x, y)`；三个变量 `VARS x y z` 对应右嵌套的 `(x, (y, z))`。语法翻译器把断言中的自由名字按这个位置布局抽象成状态集合。

例如，下面这个表面断言：

```isabelle
{x < y}
```

可以理解成：

```isabelle
{s. case s of (x, y) \<Rightarrow> x < y}
```

而赋值：

```isabelle
x := x + 1
```

可以理解成如下的基本状态变换：

```isabelle
Basic (\<lambda>(x, y). (x + 1, y))
```

这里只替换元组中 `x` 的位置，`y` 原样保留。前件、循环条件和后件也使用同一套状态布局，所以程序变量不会在翻译后变成互不相干的 HOL 自由变量。

### 程序变量与逻辑变量

`VARS` 列表里的名字是程序变量；列表外的名字仍然是逻辑变量。例如在 `VARS (x::int)` 中，`x` 会随赋值改变，而逻辑变量 `a` 不在状态元组里，可用来记录 `x` 的初值。

这条区分是书写规格的基本功：若把 `a` 也放进 `VARS`，却不给它安排合适的语义角色，就可能让它在程序翻译中变成一个可写状态分量，而不是固定的数学参数。

### 程序与注解分开保存

抽象程序 `'a com` 不保存循环不变式。另一棵注解树 `'a anno` 才保存证明信息：

```isabelle
datatype 'a anno =
  Abasic
| Aseq "'a anno" "'a anno"
| Acond "'a anno" "'a anno"
| Awhile "'a set" "'a \<Rightarrow> nat" "nat \<Rightarrow> 'a anno"
```

`Awhile` 的三个参数依次表示不变式、自然数变式，以及可能依赖旧变式值的循环体注解。于是同一个运行程序可以配不同证明注解，而 `Sem` 完全不受这些注解影响。

`VARS` 翻译器同时构造 `c` 和 `a`，最终得到：

```isabelle
Valid p c a q
```

或：

```isabelle
ValidTC p c a q
```

这也解释了为什么部分正确性的循环即使不写 `VAR`，打印时仍可能出现 `VAR {0}`：省略写法会补一个平凡的零变式，而部分正确性规则根本不使用它。

### 四条非循环规则

库已经证明了基本规则。`SKIP` 只要求前件蕴含后件：

```isabelle
lemma SkipRule:
  "p \<subseteq> q \<Longrightarrow> Valid p (Basic id) a q"
```

赋值或一般状态变换采用“向后替换”：

```isabelle
lemma BasicRule:
  "p \<subseteq> {s. f s \<in> q} \<Longrightarrow> Valid p (Basic f) a q"
```

`{s. f s \<in> q}` 表示：执行 `f` 之后的状态必须落入 `q`。这正是最弱前件思想。

顺序组合需要中间断言 `Q`：

```isabelle
lemma SeqRule:
  "Valid P c1 a1 Q \<Longrightarrow> Valid Q c2 a2 R \<Longrightarrow>
   Valid P (Seq c1 c2) (Aseq a1 a2) R"
```

条件规则把条件为真和为假分别交给两个分支：

```isabelle
lemma CondRule:
  "p \<subseteq> {s. (s \<in> b \<longrightarrow> s \<in> w) \<and> (s \<notin> b \<longrightarrow> s \<in> w')} \<Longrightarrow>
   Valid w c1 a1 q \<Longrightarrow> Valid w' c2 a2 q \<Longrightarrow>
   Valid p (Cond b c1 c2) (Acond a1 a2) q"
```

实际写程序时通常不必手动逐条应用它们，`vcg` 会按语法树选择规则。

## 18.4 第一个程序：赋值与 vcg

下面证明：若 `x` 初值为 `a`，执行 `x := x + 1` 后，`x = a + 1`。

```isabelle
lemma increment: "VARS (x::int)
  {x = a}
  x := x + 1
  {x = a + 1}"
  by vcg_simp
```

`a` 是逻辑变量，`x` 是程序变量。证明完成后，`a` 在定理中成为一个可任意实例化的模式变量，所以这条定理对任何整数初值都成立。

`by vcg_simp` 做了两层工作：

1. `vcg` 根据程序结构应用霍尔规则，把三元组转成普通 HOL 验证条件；
2. 附加的化简步骤展开状态元组、赋值和集合成员关系，并尝试解决简单算术目标。

本例唯一的实质验证条件可以写成：

```isabelle
x = a \<Longrightarrow> x + 1 = a + 1
```

化简器可以直接关闭它。

库提供四种方法：

| 方法 | 三元组 | 额外化简 |
|---|---|---|
| `vcg` | 部分正确性 | 无 |
| `vcg_simp` | 部分正确性 | 有 |
| `vcg_tc` | 完全正确性 | 无 |
| `vcg_tc_simp` | 完全正确性 | 有 |

`vcg` 不是 SMT 求解器，也不会替我们寻找循环不变式。它负责的是**程序结构到逻辑目标的机械翻译**。

## 18.5 条件与顺序

下面程序把 `m` 设为 `x` 与 `y` 的较大值：

```isabelle
lemma maximum: "VARS (x::int) y m
  {True}
  IF x < y THEN m := y ELSE m := x FI
  {m = max x y}"
  by vcg_simp
```

前件是 `True`，表示对初态没有限制。`vcg_simp` 根据 `CondRule` 产生两个分支的验证条件：

- 在 `x < y` 分支中，赋值后 `m = y`，需要证明 `y = max x y`；
- 在 `\<not> x < y` 分支中，赋值后 `m = x`，需要证明 `x = max x y`。

`max` 的定义与线性序化简规则正好覆盖这两种情况，所以不需要额外证明脚本。

顺序组合则遵循 `SeqRule`：前一条语句的后件成为后一条语句的前件。下一节的幂程序先顺序执行两次赋值，再进入循环，可以同时看到这两种结构如何组合。

## 18.6 循环部分正确性：不变式

下面程序计算 `x^n`。`p` 保存已累计的幂，`i` 保存已经乘法的次数：

```isabelle
lemma power_pc: "VARS (p::int) i
  {True}
  p := 1;
  i := 0;
  WHILE i < n
  INV {p = x^i \<and> i \<le> n}
  DO p := p * x;
     i := i + 1
  OD
  {p = x^n}"
  apply vcg_simp
  by auto
```

这里 `p` 和 `x` 是 `int`，`i` 和 `n` 是 `nat`。`i` 作为指数和循环计数器使用，`n` 通过与 `i` 的比较得到同一类型。

### 为什么需要这个不变式

循环规则不能只看循环体的一次执行，还必须找到每次迭代都成立的事实。本例使用：

```isabelle
p = x^i \<and> i \<le> n
```

它同时记录“算到哪里”和“计数器没有越过终点”。部分正确性的循环规则要求三组验证条件：

```isabelle
p \<subseteq> i
Valid (i \<inter> b) c (A 0) i
i \<inter> (-b) \<subseteq> q
```

换成通常的霍尔逻辑语言，就是：

1. **初始化**：进入循环前，前件蕴含不变式；
2. **保持**：在不变式和循环条件都成立时执行循环体，结束后不变式仍成立；
3. **退出**：不变式和循环条件为假共同蕴含后件。

对应到幂程序：

- 初始化后 `p = 1`、`i = 0`，所以 `p = x^0`；自然数还给出 `0 \<le> n`。
- 若 `p = x^i`、`i \<le> n` 且 `i < n`，一次循环体把 `p` 更新为 `x^i * x = x^(i+1)`，并把 `i` 更新为 `i+1`，仍有 `i+1 \<le> n`。
- 退出时有 `\<not> i < n`，也就是 `n \<le> i`；结合不变式中的 `i \<le> n` 得到 `i = n`，于是 `p = x^n`。

`vcg_simp` 负责生成这些目标并处理赋值替换，`auto` 完成剩余算术。若没有 `i \<le> n`，退出阶段就只能知道 `p = x^i` 和 `n \<le> i`，无法把指数 `i` 替换成 `n`。

### 循环规则本身

库中的完整部分正确性规则是：

```isabelle
lemma WhileRule:
  "p \<subseteq> i \<Longrightarrow>
   Valid (i \<inter> b) c (A 0) i \<Longrightarrow>
   i \<inter> (-b) \<subseteq> q \<Longrightarrow>
   Valid p (While b c) (Awhile i v A) q"
```

结论中的 `Awhile i v A` 保存注解；第二个前提只关心循环体能否保持 `i`。这里的 `v` 不出现在任何前提中，再次说明**部分正确性不使用变式证明终止**。

## 18.7 vcg 不是自动证明器

列表反转比幂运算更能显示工具分工。程序把 `xs` 的元素逐个压到 `ys` 前端：

```isabelle
lemma reverse_pc: "VARS (xs::int list) ys
  {xs = X}
  ys := [];
  WHILE xs \<noteq> []
  INV {rev xs @ ys = rev X}
  DO ys := hd xs # ys;
     xs := tl xs
  OD
  {ys = rev X}"
  apply vcg_simp
  apply (simp add: neq_Nil_conv)
  apply auto
  done
```

逻辑变量 `X` 保存输入列表。初始化后 `xs = X`、`ys = []`，所以不变式变成 `rev X @ [] = rev X`。

保持不变式的关键是下面这个列表恒等式。若 `xs \<noteq> []`，则：

```isabelle
rev (tl xs) @ (hd xs # ys) = rev xs @ ys
```

原因是 `rev xs = rev (tl xs) @ [hd xs]`。把 `hd xs` 移到 `ys` 前端，只是改变了追加的结合方式。

退出时 `xs = []`，不变式化为 `[] @ ys = rev X`，即 `ys = rev X`。

证明脚本中的三步不能混为一谈：

1. `vcg_simp` 生成并化简初始化、保持、退出三类验证条件；
2. `simp add: neq_Nil_conv` 把非空列表条件展开成可处理的头尾结构；
3. `auto` 完成剩余的列表等式推理。

VCG 不会发明 `rev xs @ ys = rev X`，也不会自动想到非空列表分解。**程序结构由 VCG 处理，数据结构中的数学定理由 HOL 证明工具处理。**

## 18.8 部分正确性不保证终止

下面这条定理初看像悖论：循环永远执行 `SKIP`，后件却是 `False`。

```isabelle
lemma divergence_pc: "VARS (x::nat)
  {True}
  WHILE True
  INV {True}
  DO SKIP
  OD
  {False}"
  by vcg_simp
```

它完全合法。`WHILE True` 不可能使用 `Sem` 的“条件为假，循环结束”规则；使用另一条规则时，又必须继续构造同一个循环的执行。因此不存在终态 `s'` 使得这个循环从任意初态到达 `s'`。

回到部分正确性定义：

```isabelle
\<forall>s s'. Sem c s s' \<longrightarrow> s \<in> p \<longrightarrow> s' \<in> q
```

当 `Sem c s s'` 永远为假时，整个蕴含对任意 `q` 都成立。这里的前提 `False` 没有被证明，后件 `False` 也没有被证明；被证明的只是“**若存在终态，则它满足后件**”，而根本不存在这样的终态。

这就是部分正确性不能单独用于证明程序可用的原因。若规格还要求程序必须返回结果，就要使用完全正确性，并给循环提供变式。

## 18.9 完全正确性：VAR 与 vcg_tc

幂程序的完全正确性版本只多了一项表面注解，并把花括号改成方括号：

```isabelle
lemma power_tc: "VARS (p::int) i
  [True]
  p := 1;
  i := 0;
  WHILE i < n
  INV {p = x^i \<and> i \<le> n}
  VAR {n - i}
  DO p := p * x;
     i := i + 1
  OD
  [p = x^n]"
  apply vcg_tc_simp
  by auto
```

`VAR {n - i}` 给出循环变式，类型是 `nat`。进入循环体时有 `i < n`，执行 `i := i + 1` 后，表达式 `n - i` 严格减小。自然数不存在无限严格下降序列，因此循环不能无限执行。

### 完全正确性循环规则在检查什么

库中的规则是：

```isabelle
lemma WhileRuleTC:
  "p \<subseteq> i \<Longrightarrow>
   (\<And>n::nat.
      ValidTC (i \<inter> b \<inter> {s. v s = n}) c (A n)
              (i \<inter> {s. v s < n})) \<Longrightarrow>
   i \<inter> (-b) \<subseteq> q \<Longrightarrow>
   ValidTC p (While b c) (Awhile i v (\<lambda>n. A n)) q"
```

这里规则前提中的 `n` 是“本轮开始时的变式值”，不是特指幂程序里的变量 `n`。循环体必须：

1. 在不变式 `i`、循环条件 `b` 和 `v s = n` 下开始；
2. 终止；
3. 到达仍满足不变式、且变式小于旧值 `n` 的状态。

初始化和退出条件与部分正确性相同。终止证明由对旧变式值 `n` 的良基归纳完成：每执行一次循环体，后续循环只需在一个更小的自然数上终止。

### 不变式和变式不能互相替代

- 不变式回答“每轮之后仍然知道什么”，用于保持规格并推出后件；
- 变式回答“为什么最多只能再执行有限轮”，用于终止性。

一个只证明 `p = x^i` 的不变式可能足以推出部分正确性，却不包含终止信息；一个只会减小的变式也不能单独证明 `p = x^n`。完全正确性证明通常需要两者合作。

### `nat` 截断减法的警告

`nat` 中，当 `i > n` 时，`n - i = 0`。这不会让 VCG 错把不终止程序判成终止，因为规则要求每一轮都**严格减小**；但它意味着我们不能只凭“表达式里有减法”就断言它会下降。

本例的循环条件 `i < n` 直接给出了所需界，不变式中的 `i \<le> n` 也始终保持这一信息。换用其他循环条件或变式时，应明确检查边界状态和截断行为，而不是机械照抄 `VAR {n - i}`。

## 18.10 列表程序与终止性

列表反转的完全正确性证明使用 `length xs` 作为变式：

```isabelle
lemma reverse_tc: "VARS (xs::int list) ys
  [xs = X]
  ys := [];
  WHILE xs \<noteq> []
  INV {rev xs @ ys = rev X}
  VAR {length xs}
  DO ys := hd xs # ys;
     xs := tl xs
  OD
  [ys = rev X]"
  apply vcg_tc_simp
  apply (auto simp: neq_Nil_conv)
  done
```

非空列表满足：

```isabelle
length (tl xs) < length xs
```

所以每轮循环都使变式严格减小。不变式仍负责解释为什么最终得到 `rev X`，变式则排除了无限循环。

与 18.7 相比，后件文字完全相同，但定理的保证更强：对于任何满足 `xs = X` 的初态，程序不仅会终止，而且终态中的 `ys` 就是 `rev X`。如果循环体误写成只修改 `ys` 而不执行 `xs := tl xs`，部分正确性仍可能因为不变式推理失败而无法直接通过；即使把不变式弱化成 `True` 凑出某种部分正确性，`length xs` 不下降也会让完全正确性验证条件暴露问题。

## 18.11 从完全正确性提取结果

完全正确性已经包含部分正确性，因此不必重证一遍幂程序。可以把通用定理 `tc_implies_pc` 应用到 `power_tc`：

```isabelle
lemmas power_pc_from_tc = tc_implies_pc[OF power_tc]
```

`OF` 用 `power_tc` 满足 `tc_implies_pc` 的前提，得到的定理使用花括号三元组，程序、注解和后件保持不变。

更一般地，完全正确性还能提取满足后件的结果函数：

```isabelle
lemma tc_extract_function:
  "ValidTC p c a q \<Longrightarrow>
   \<exists>f. \<forall>s. s \<in> p \<longrightarrow> f s \<in> q"
```

证明思路直接来自 `ValidTC` 的定义：对每个满足前件的 `s`，定义中已经存在一个满足后件的终态；用选择算子为每个这样的 `s` 选一个结果，就得到函数 `f`。前件之外的状态不受这条定理约束。

这里的“提取”是**逻辑上的存在性结果**，不是代码生成。它没有自动给出可执行定义，也没有替代 `export_code`。若想进一步定义具体函数，可以在有存在性定理后使用 `SOME` 选择结果，再证明该定义满足后件；若还想导出程序，则需要另行提供代码方程。

可用下面两条命令查看库定理及本例生成的部分正确性定理：

```isabelle
thm power_pc_from_tc
thm tc_extract_function
```

## 18.12 HOL-Hoare 其他模块与使用边界

`HOL-Hoare` 不只有本章导入的核心逻辑。按问题选择模块，比一次性导入所有理论更可靠：

| 模块 | 适用内容 |
|---|---|
| `Hoare_Syntax` | `VARS`、赋值、条件、循环及注解的具体语法 |
| `Hoare_Tac` | 验证条件生成器的实现基础 |
| `Hoare_Logic` | 大步语义、部分/完全正确性、证明规则和四种 VCG 方法 |
| `Examples` | 乘法、幂、阶乘、平方根、列表等部分正确性示例 |
| `ExamplesTC` | 完全正确性、结果函数提取和嵌套循环变式示例 |
| `Hoare_Logic_Abort` | 用 `option` 状态建模运行时错误和 `Abort` |
| `Pointers0`、`Heap`、`HeapSyntax`、`Pointer_Examples` | 指针、堆和指针程序示例 |
| `SepLogHeap`、`Separation` | 堆断言、分离合取等分离逻辑设施 |
| `SchorrWaite` | 更大的指针图算法验证案例 |

核心 `Hoare_Logic` 已包含本章所需全部内容。`Hoare_Logic_Abort` 和指针、分离逻辑模块会提供自己的语义或同名语法设施；不同霍尔逻辑的具体语法翻译不能无差别合并。应按目标问题选择一个入口，而不是把所有模块堆进 `imports`。

本章的工作流可以压缩成一张检查表：

1. 先决定需要部分正确性还是完全正确性，选择 `{}` 或 `[]`；
2. 用 `VARS` 固定程序状态布局，用逻辑变量记录输入和数学参数；
3. 为每个循环写出足以推出后件的 `INV`；
4. 完全正确性再给出自然数 `VAR`，检查每轮严格减小；
5. 用对应的 VCG 方法生成验证条件，再用 `simp`、`auto` 或其他证明方法解决数学目标；
6. 若已证完全正确性，用 `tc_implies_pc` 复用结果，不要重复证明部分正确性。

---

## 本章坑位清单（实测）

1. **把 `{}` 与 `[]` 当成纯排版差别**：前者是 `Valid`，只保证“若终止则正确”；后者是 `ValidTC`，还保证存在终态。
2. **用永不终止循环证明任意后件后误以为逻辑矛盾**：部分正确性的执行前提是假的，蕴含可以空泛成立；需要终止保证时改证完全正确性。
3. **循环只写不变式却要求完全正确性**：还必须提供会变小的 `VAR`，并用 `vcg_tc` 或 `vcg_tc_simp`。
4. **不变式只记录主等式，漏掉边界信息**：例如幂循环缺少 `i \<le> n` 时，退出条件无法推出 `i = n`。
5. **认为 `vcg` 会自动完成数学证明**：它只按程序结构生成验证条件；列表恒等式、算术和归纳仍要由其他方法完成。
6. **把 `nat` 减法当普通整数减法**：`n - i` 会截断为 0，必须结合循环条件和不变式检查严格下降，不能只看表达式外观。
7. **混淆程序变量和逻辑变量**：`VARS` 列表中的名字属于状态元组；列表外的 `a`、`X` 等名字才适合固定输入值。
8. **把 `INV` 当作运行时检查**：不变式和变式保存在 `'a anno` 中，`Sem` 只执行 `'a com`，注解不会改变程序运行语义。
9. **看到打印出的 `VAR {0}` 以为源码被改写错**：部分正确性的无 `VAR` 循环会补平凡零变式，部分正确性规则不使用它。
10. **构建通过但 `process_theories` 报缺少 `HOL-Hoare`**：`ROOT` 的 `sessions` 只解决会话构建依赖；单理论输出工具的父会话也必须包含 `HOL-Hoare`，否则限定导入无法加载。

---

上一章：[17 · 自动化的边界](17-automation.md) ｜ 下一章：[19 · 代码生成](19-codegen.md) ｜ 返回：[README](../README.md)
