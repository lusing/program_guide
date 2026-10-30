# 69 · CCL（一）：Set、Lfp、Gfp、Trancl——FOL 上的集合论与不动点

对应示例：`../examples/ccl/T69_ccl_set.thy`（IsaTutCCLex 会话，父堆
`IsaTutCCL`——即发行版 `src/CCL/` 的 14 个理论原样拷贝，见
`examples/cclbase/ROOT`）

> 参考：[Isabelle/CCL 库索引](https://dist.isabelle.cit.tum.de/dist/library/FOL/CCL/index.html?token=Isabelle)

## 69.1 CCL 库：Isabelle 自带的「计算逻辑」活化石

1993 年，剑桥大学计算机实验室的 Martin Coen 为 Isabelle 写了一整套
**CCL**（Classical Computational Logic，经典可计算逻辑）：在 FOL 之上造
集合论、不动点、传递闭包，最终得到一个**无类型函数语言**的指称语义，
并附带自然数、列表、流、荷兰国旗四个可执行例子。

它不是历史包袱——Isabelle2026 发行版仍然带着它，会话索引
`FOL/CCL` 一共列出 16 个理论：

| 组 | 理论 | 本教程 |
|---|---|---|
| 逻辑层 | `IFOL` / `FOL` | 第 47 章 |
| 集合与不动点 | `Set` / `Lfp` / `Gfp` / `Trancl` | **本章** |
| λ 演算与类型 | `CCL` / `Term` / `Type` / `Hered` / `Wfd` / `Fix` | 第 70、71 章 |
| 计算实例 | `Nat` / `List` / `Stream` / `Flag` | 第 72 章 |

本教程把这 14 个库理论**原样**收进 `examples/cclbase/`（会话
`IsaTutCCL`，内容即发行版 `src/CCL/` 的拷贝），T69–T72 四个示例建立
在该会话之上。本章引用的库代码都在正文原样贴出，读者不需要自己去翻
源码。

```text

val it = (): unit
```

（示例开篇只有一行 `writeln` 标记，见 `examples/ccl/T69_ccl_set.thy`
第 28 行的 `ML \<open>writeln "==== 69 开始 ===="\<close>`——本教程所有
章节都用起止标记圈出可比对区间。）

## 69.2 两条公理造出集合论

FOL 本身没有集合。CCL 的 `Set` 理论只做两件事：用 `typedecl` 造一个新
类型 `'a set`，再用两条公理定义 `Collect` 与 `mem`（库源码
`src/CCL/Set.thy` 第 9–18 行）：

```isabelle
typedecl 'a set
instance set :: ("term") "term" ..


subsection \<open>Set comprehension and membership\<close>

axiomatization Collect :: "['a \<Rightarrow> o] \<Rightarrow> 'a set"
  and mem :: "['a, 'a set] \<Rightarrow> o"  (infixl \<open>:\<close> 50)
where mem_Collect_iff: "(a : Collect(P)) \<longleftrightarrow> P(a)"
  and set_extension: "A = B \<longleftrightarrow> (ALL x. x:A \<longleftrightarrow> x:B)"
```

第 10 行的 `instance set :: ("term") "term" ..` 宣布"项的集合仍是
项"——这是 CCL 全库的地基（第 70 章的类型就是 `i set`）。注意
`mem` 的记号写法是 `(infixl \<open>:\<close> 50)`：1993 年的源码用
`\<open>...\<close>` 把符号包起来，当年的 Isabelle 还不会用裸引号。

注意这是**公理**不是定义：在 FOL 里，集合就是谓词的外延化身。
`set_extension` 说两个集合相等当且仅当元素逐个相同。实测打印两条公理：

```text

?a : Collect(?P) \<longleftrightarrow> ?P(?a)

?A = ?B \<longleftrightarrow> (\<forall>x. x : ?A \<longleftrightarrow> x : ?B)
```

注意第二行的打印形态：**ASCII 的 `ALL` 被打印成 `∀`**。这是 1993 年的
遗产——源码写 ASCII，打印出漂亮符号，两者语义完全相同（第 47.3 节细说）。

概括语法 `{x. P(x)}` 是 `Collect` 的语法糖，靠 `translations` 折叠成
λ 抽象（库源码第 20–25 行）。引入 / 消去是一对规则，示例
`examples/ccl/T69_ccl_set.thy` 第 55–63 行把它们各证一遍：

```isabelle
lemma collect_demo:
  assumes "P(a)"
  shows "a : {x. P(x)}"
  using assms by (rule CollectI)

lemma collectD_demo:
  assumes "a : {x. P(x)}"
  shows "P(a)"
  using assms by (rule CollectD)
```

外延公理的使用形态 `set_ext`（同文件第 68–71 行）——证集合相等，
就是逐点证明成员关系双向成立：

```isabelle
lemma set_ext_demo:
  assumes "\<And>x. x:A \<longleftrightarrow> x:B"
  shows "A = B"
  using assms by (rule set_ext)
```

输出（注意 `thm` 打印的是带原理变元的语句，`lemma ... qed` 打印的是
已证定理）：

```text

theorem collect_demo:
 ?P(?a) \<Longrightarrow> ?a : Collect(?P)

theorem collectD_demo:
 ?a : Collect(?P) \<Longrightarrow> ?P(?a)

theorem set_ext_demo:
 (\<And>x. x : ?A \<longleftrightarrow> x : ?B) \<Longrightarrow> ?A = ?B

{x. x : ?A} = ?A
```

最后一行是 `thm trivial_set`：`{x. x:A} = A` 直接由外延公理得出——
CCL 把它设成 simp 规则（69.9 节）。

## 69.3 有界量词：1993 年的 ASCII 量词还活着

`Set` 理论定义了两个**有界**量词（库源码第 46–60 行）：

```isabelle
definition Ball :: "['a set, 'a \<Rightarrow> o] \<Rightarrow> o"
  where "Ball(A, P) == ALL x. x:A \<longrightarrow> P(x)"
```

注意写法 `ALL x:A. P(x)`：这不是新符号，是 FOL 自带的 ASCII 量词形态
（`Pure_Thy.old_appl_syntax_setup` 的遗产），与 `∀x. P(x)` 完全等价——
CCL 库全文用 ASCII 形态书写。`EX x:A. P(x)`、`INT x:A. B(x)`、
`UN x:A. B(x)` 同款。

实测打印两条定义，**ASCII 全被还原成了符号**：

```text

Ball(?A, ?P) \<equiv> \<forall>x. x : ?A \<longrightarrow> ?P(x)

Bex(?A, ?P) \<equiv> \<exists>x. x : ?A \<and> ?P(x)
```

这带来一个实操结论：**写源码时两种形态等价，读输出时只会看到符号形态**。
若你要在文档里引用库源码原文，请照抄 ASCII（库的真实形态）；若引用
`thm` 打印，请照抄符号。本教程的机器核查（```text 块逐字节比对）要求
两者都不能串。

引入消去（`examples/ccl/T69_ccl_set.thy` 第 92–100 行）：

```isabelle
lemma ball_demo:
  assumes "\<And>x. x:A \<Longrightarrow> P(x)"
  shows "ALL x:A. P(x)"
  using assms by (rule ballI)

lemma bspec_demo:
  assumes "ALL x:A. P(x)" and "a:A"
  shows "P(a)"
  using assms by (rule bspec)
```

```text

theorem ball_demo:
 (\<And>x. x : ?A \<Longrightarrow> ?P(x)) \<Longrightarrow> Ball(?A, ?P)

theorem bspec_demo:
 \<lbrakk>Ball(?A, ?P); ?a : ?A\<rbrakk> \<Longrightarrow> ?P(?a)
```

注意打印形态：`thm` 打定理用的是**折叠**形态 `Ball(?A, ?P)`，
不是源码里的 ASCII 有界量词 `ALL x:?A. ?P(x)`——`Set.thy` 开头
`declare [[eta_contract]]` 之后，η 收缩让 `Ball(?A, λx. ?P(x))`
缩成 point-free 的 `Ball(?A, ?P)`。写源码两种都行，读输出只见
折叠形态。

存在侧的规则对（`thm bexI` / `thm bexE`）也是同款两旋：

```text

\<lbrakk>?P(?x); ?x : ?A\<rbrakk> \<Longrightarrow> Bex(?A, ?P)

\<lbrakk>Bex(?A, ?P); \<And>x. \<lbrakk>x : ?A; ?P(x)\<rbrakk> \<Longrightarrow> ?Q\<rbrakk> \<Longrightarrow> ?Q
```

`bexE` 是**消除规则**（E 后缀）：它把 `Bex(A,P)` 拆成可用的 witnesses，
同时接受一个"任意 witness 都能推出 ?Q"的续体。这就是 Isar 里
`fix x assume "x:A" "P(x)"` 那一招的规则层依据。

## 69.4 基本运算：I/D/E 三件套与「经典」变体

库源码第 99–119 行定义 `subset` / `singleton` / `empty` / `Un` /
`Int` / `Compl`。先看定义全貌（`examples/ccl/T69_ccl_set.thy` 第
114–117 行 `thm`）：

```text

?A <= ?B \<equiv> ALL x:?A. x : ?B

?A Un ?B \<equiv> {x. x : ?A \<or> x : ?B}

?A Int ?B \<equiv> {x. x : ?A \<and> x : ?B}

Compl(?A) \<equiv> {x. \<not> x : ?A}
```

规则命名法三件套，**这是读全部 Isabelle 库的通用钥匙**：

- **I** = introduction（引入）：从成员关系推出集合关系；
- **D** = destruct（消去，Modus Ponens 风格）：`A <= B` 配 `c:A`
  直接给 `c:B`；
- **E** = elimination（消除，分类讨论风格）：配一个续体，把前提
  拆成 Case 分别处理；
- 带 **C** 的是**经典**变体——前提里出现否定，靠排中律兜底，
  IFOL 里不可用（第 47 章）。

七条规则的朝向（`examples/ccl/T69_ccl_set.thy` 第 119–126 行）：

```text

(\<And>x. x : ?A \<Longrightarrow> x : ?B) \<Longrightarrow> ?A <= ?B

\<lbrakk>?A <= ?B; ?c : ?A\<rbrakk> \<Longrightarrow> ?c : ?B

\<lbrakk>?A <= ?B; \<not> ?c : ?A \<Longrightarrow> ?P; ?c : ?B \<Longrightarrow> ?P\<rbrakk> \<Longrightarrow> ?P

?c : ?A \<Longrightarrow> ?c : ?A Un ?B

(\<not> ?c : ?B \<Longrightarrow> ?c : ?A) \<Longrightarrow> ?c : ?A Un ?B

\<lbrakk>?c : ?A; ?c : ?B\<rbrakk> \<Longrightarrow> ?c : ?A Int ?B

?c : Compl(?A) \<Longrightarrow> \<not> ?c : ?A
```

依次是 `subsetI` / `subsetD` / `subsetCE` / `UnI1` / `UnCI` /
`IntI` / `ComplD`。其中两条值得单独说：

- **`subsetCE`**（第三条）是"二难"：知道 `c:A` 时用 `c:B` 那一支，
  知道 `¬c:A` 时用另一支，两支都通向 `?P`。这就是把经典推理压进
  一条消除规则的形态。
- **`UnCI`**（第五条）前提是 `¬c:B ⟹ c:A`——反证法塞进引入规则。
  HOL 用户熟悉的 `UnCI` 在 Isabelle2026 已改名 `Un_insert_left`，
  CCL 里还是 1993 年的老名字。

三个小证明把它们跑通（第 127–140 行）：

```isabelle
lemma subset_demo:
  assumes "A <= B" and "a:A"
  shows "a:B"
  using assms by (rule subsetD)

lemma unci_demo:
  assumes "\<not> a:B \<Longrightarrow> a:A"
  shows "a : A Un B"
  using assms by (rule UnCI)

lemma compl_demo:
  assumes "a : Compl(A)"
  shows "\<not> a:A"
  using assms by (rule ComplD)
```

```text

theorem subset_demo:
 \<lbrakk>?A <= ?B; ?a : ?A\<rbrakk> \<Longrightarrow> ?a : ?B

theorem unci_demo:
 (\<not> ?a : ?B \<Longrightarrow> ?a : ?A) \<Longrightarrow> ?a : ?A Un ?B

theorem compl_demo:
 ?a : Compl(?A) \<Longrightarrow> \<not> ?a : ?A
```

## 69.5 族运算：并交就是上下界

库源码第 123–143 行：`INTER` / `UNION` 吃**函数族**，`Inter` /
`Union` 吃**集合族**。前两条定义的实测（示例第 151–152 行 `thm`）：

```text

INTER(?A, ?B) \<equiv> {y. ALL x:?A. y : ?B(x)}

UNION(?A, ?B) \<equiv> {y. EX x:?A. y : ?B(x)}
```

`A` 里的每个元素 `X` 都是一个集合，`B` 把 `X` 映到一个集合；交/并
就是对"像的集合族"取交/并。

格论视角：`Union` 是一族集合的**最小上界**，`Inter` 是**最大下界**——
这正是库给它们起的规则名（第 153–156 行 `thm`）：

```text

?B : ?A \<Longrightarrow> ?B <= Union(?A)

(\<And>X. X : ?A \<Longrightarrow> X <= ?C) \<Longrightarrow> Union(?A) <= ?C

?B : ?A \<Longrightarrow> Inter(?A) <= ?B

(\<And>X. X : ?A \<Longrightarrow> ?C <= X) \<Longrightarrow> ?C <= Inter(?A)
```

四条规则两两对偶：`Union_upper`（每个成员都是上界）与
`Union_least`（比所有上界都小，即最小）；`Inter_lower` 与
`Inter_greatest` 同理。`Union_least` 单独演示（第 158–161 行）——
它是证"某个构造是族并"的标准入口：

```isabelle
lemma union_least_demo:
  assumes "\<And>X. X:A \<Longrightarrow> X <= C"
  shows "Union(A) <= C"
  using assms by (rule Union_least)
```

```text

theorem union_least_demo:
 (\<And>X. X : ?A \<Longrightarrow> X <= ?C) \<Longrightarrow> Union(?A) <= ?C
```

## 69.6 lfp：最小不动点与 Knaster–Tarski

库源码 `src/CCL/Lfp.thy` 第 12–14 行：

```isabelle
definition
  lfp :: "['a set\<Rightarrow>'a set] \<Rightarrow> 'a set" where \<comment> \<open>least fixed point\<close>
  "lfp(f) == Inter({u. f(u) <= u})"
```

`\<comment> \<open>...\<close>` 是给 PIDE（跳转 / 悬停提示）用的注释锚，对语义
没有任何影响， Isabelle2026 仍然认它。

最小不动点 = 所有**前不动点**（`f(u) <= u`）的交。定义加四条定理
（第 175–179 行）：

```text

lfp(?f) \<equiv> Inter({u. ?f(u) <= u})

?f(?A) <= ?A \<Longrightarrow> lfp(?f) <= ?A

(\<And>u. ?f(u) <= u \<Longrightarrow> ?A <= u) \<Longrightarrow> ?A <= lfp(?f)

mono(?f) \<Longrightarrow> ?f(lfp(?f)) <= lfp(?f)

mono(?f) \<Longrightarrow> lfp(?f) = ?f(lfp(?f))
```

依次是 `lfp_def` / `lfp_lowerbound` / `lfp_greatest` / `lfp_lemma2` /
`lfp_Tarski`。注意分工：

- **`lfp_lowerbound` 与 `lfp_greatest` 不需要 `mono`**——它们只是
  "最小性"的直接后果，对任意 `f` 成立；
- **`lfp_Tarski` 需要 `mono`**——单调性才保证 `f(lfp(f)) <= lfp(f)`
  这个方向，两向夹逼出真正的不动点方程。这与 HOL 的 `lfp_unfold`
  （必须 `mono`）不同，第 51 章用过的那一套在这里拆成了两条。

库用 apply 脚本证 `lfp_lemma2`（源码第 24–25 行）。改写成 Isar，
看两向夹逼怎么走（`examples/ccl/T69_ccl_set.thy` 第 187–196 行）：

```isabelle
lemma lfp_lemma2_demo:
  assumes mono: "mono(f)"
  shows "f(lfp(f)) <= lfp(f)"
proof (rule lfp_greatest)
  fix u
  assume hu: "f(u) <= u"
  from hu have lub: "lfp(f) <= u" by (rule lfp_lowerbound)
  from mono lub have step: "f(lfp(f)) <= f(u)" by (rule monoD)
  from step hu show "f(lfp(f)) <= u" by (rule subset_trans)
qed
```

```text
theorem lfp_lemma2_demo:
 mono(?f) \<Longrightarrow> ?f(lfp(?f)) <= lfp(?f)

have lub: lfp(f) <= u

have step: f(lfp(f)) <= f(u)

show f(lfp(f)) <= u
```

三步链条值得背下来，它是**所有**最小不动点证明的骨架：

1. `proof (rule lfp_greatest)` 把目标 `f(lfp(f)) <= lfp(f)` 转成
   "任取一个前不动点 `u`，证明 `f(lfp(f)) <= u`"；
2. 对每个 `u`，`lfp_lowerbound` 给出 `lfp(f) <= u`（最小性），
   `monoD` 经单调性推出 `f(lfp(f)) <= f(u)`；
3. 与 `f(u) <= u` 传递（`subset_trans`）收口。

配套的 `lfp_lemma3`（源码第 27–28 行）是对偶方向，两条一夹就是
`lfp_Tarski`：

```text

mono(?f) \<Longrightarrow> lfp(?f) <= ?f(lfp(?f))
```

库还给出通用**归纳规则** `induct`（源码第 36–45 行）——要证
`P(a)` 对一切 `a : lfp(f)` 成立，只需证 `P` 对"从 `f(lfp(f) Int Collect(P))`
里能造出的东西"成立：

```text

\<lbrakk>?a : lfp(?f); mono(?f); \<And>x. x : ?f(lfp(?f) Int Collect(?P)) \<Longrightarrow> ?P(x)\<rbrakk>
\<Longrightarrow> ?P(?a)
```

第 71 章讲 Nat/List 归纳时用它。这是 CCL 全部归纳证明的引擎：
类型即项集（`Nat = lfp(...)`），归纳规则就是 `lfp` 的 `induct`。

## 69.7 gfp：最大不动点与三级余归纳

库源码 `src/CCL/Gfp.thy` 第 12–14 行，与 lfp 完全对偶：

```isabelle
definition
  gfp :: "['a set\<Rightarrow>'a set] \<Rightarrow> 'a set" where \<comment> \<open>greatest fixed point\<close>
  "gfp(f) == Union({u. u <= f(u)})"
```

最大不动点 = 所有**后不动点**（`u <= f(u)`）的并。四条定理
（第 216–219 行）：

```text

gfp(?f) \<equiv> Union({u. u <= ?f(u)})

?A <= ?f(?A) \<Longrightarrow> ?A <= gfp(?f)

(\<And>u. u <= ?f(u) \<Longrightarrow> u <= ?A) \<Longrightarrow> gfp(?f) <= ?A

mono(?f) \<Longrightarrow> gfp(?f) = ?f(gfp(?f))
```

依次是 `gfp_def` / `gfp_upperbound` / `gfp_least` / `gfp_Tarski`。
先看一个两理论联合作战的小证明——单调函数的 lfp 永远装在 gfp 里
（`examples/ccl/T69_ccl_set.thy` 第 221–226 行）：

```isabelle
lemma lfp_subset_gfp_demo:
  assumes mono: "mono(f)"
  shows "lfp(f) <= gfp(f)"
proof (rule lfp_lowerbound)
  show "f(gfp(f)) <= gfp(f)" by (rule gfp_lemma3[OF mono])
qed
```

```text
theorem lfp_subset_gfp_demo:
 mono(?f) \<Longrightarrow> lfp(?f) <= gfp(?f)

show f(gfp(f)) <= gfp(f)
```

这一手很巧：**要证 `lfp(f) <= gfp(f)`，不去碰 lfp，而是证明 `gfp(f)`
本身是一个前不动点**（`f(gfp(f)) <= gfp(f)`，这正是 `gfp_lemma3`），
再让 `lfp_lowerbound` 自动把 lfp 塞进去。这是"换一个不动点的身份"
这一技巧的最小标本。

gfp 的真正威力在**余归纳**（coinduction）。要证 `a : gfp(f)`，
找一个集合 A 把 a 装进去，再证 `A <= f(A)` 就行（`coinduct`，
源码第 38–39 行）。Martin Coen 把它强化成三级（源码第 41–90 行）：

```text

\<lbrakk>?a : ?A; ?A <= ?f(?A)\<rbrakk> \<Longrightarrow> ?a : gfp(?f)

\<lbrakk>?a : ?A; ?A <= ?f(?A) Un gfp(?f); mono(?f)\<rbrakk> \<Longrightarrow> ?a : gfp(?f)

\<lbrakk>?a : ?A; ?A <= ?f(lfp(\<lambda>x. ?f(x) Un ?A Un gfp(?f))); mono(?f)\<rbrakk>
\<Longrightarrow> ?a : gfp(?f)
```

三级各自的条件（第一条来自 `thm coinduct`，后两条来自
`coinduct2` / `coinduct3`）：

1. `A <= f(A)`——最朴素：A 在 f 下一步之内；
2. `A <= f(A) Un gfp(f)`——允许把"已经知道在 gfp 里的东西"提前用上；
3. `A <= f(lfp(λx. f(x) Un A Un gfp(f)))`——把 A 和 gfp(f) 一起
   折叠成一个新集合，再走一遍最小不动点。

第三条是 Coen 的原创贡献，也是第 70 章证 λ 演算行为等价
（`eq_coinduct3`）、第 72 章证无限列表等式的主力武器，届时回头
看这三条规则。**余归纳的直觉**：有限归纳自底向上爬（"每一步都能
造出来"），余归纳自顶向下兜（"装得进一个自洽的近似里"）——一个
证"都是好的"，一个证"没有坏的"。

## 69.8 传递闭包：lfp 的第一个用户

库源码 `src/CCL/Trancl.thy` 第 21–25 行：

```isabelle
definition rtrancl :: "i set \<Rightarrow> i set"  (\<open>(\<open>notation=\<open>postfix ^*\<close>\<close>_^*)\<close> [100] 100)
  where "r^* == lfp(\<lambda>s. id Un (r O s))"

definition trancl :: "i set \<Rightarrow> i set"  (\<open>(\<open>notation=\<open>postfix ^+\<close>\<close>_^+)\<close> [100] 100)
  where "r^+ == r O rtrancl(r)"
```

两行末尾的 `(\<open>...notation=postfix ^*...\<close>)` 是**后缀记号声明**
（优先级 100），让 `r^*`、`r^+` 能不加括号书写；这是 1993 年
notation 语法的完整形态，与第 70 章 `napply` 的
`_ ^ _ ` _` 同款。

自反传递闭包是 `λs. id Un (r O s)` 的最小不动点；传递闭包再复合
一步 `r`。注意类型：关系是 **`i set`**——`i` 是 CCL 的项类型
（第 70 章主角），因为 1993 年造传递闭包就是为了服务 λ 演算的
归约关系，不是任意类型的通用库。

四条基本定理（第 257–260 行）：

```text

?r^* \<equiv> lfp(\<lambda>s. id Un (?r O s))

?r^* = id Un (?r O ?r^*)

<?a,?a> : ?r^*

<?a,?b> : ?r \<Longrightarrow> <?a,?b> : ?r^*
```

`rtrancl_unfold`（第二条）是全库的钥匙：它把闭包展开成
"或者相等，或者先走一步 r 再走剩下的 `r^*`"。**所有传递闭包证明
都是拿它当发动机**。库用 unfold + blast 证明"走一步仍在中"
（源码第 91–95 行），这里改用显式规则链重证一遍
（`examples/ccl/T69_ccl_set.thy` 第 266–274 行）——注意 `subst` 是
**展开**（把目标里的 `r^*` 换成不动点方程的右边）：

```isabelle
lemma rtrancl_into_rtrancl_demo:
  assumes h1: "<a,b> : r^*" and h2: "<b,c> : r"
  shows "<a,c> : r^*"
proof (subst rtrancl_unfold)
  show "<a,c> : id Un (r O r^*)"
  proof (rule UnI2)
    show "<a,c> : r O r^*" by (rule compI[OF h1 h2])
  qed
qed
```

```text
theorem rtrancl_into_rtrancl_demo:
 \<lbrakk><?a,?b> : ?r^*; <?b,?c> : ?r\<rbrakk> \<Longrightarrow> <?a,?c> : ?r^*

show <a,c> : r O r^*

show <a,c> : id Un (r O r^*)
```

四步走：`subst rtrancl_unfold` 展开目标 → 目标是并集，用 `UnI2`
选右支 → 右支是复合关系，用 `compI` 把 `<a,b>:r^*` 与 `<b,c>:r`
接起来 → `qed`。这是"不动点方程 + 归纳规则"双引擎的标准用法：
`subst` 负责把抽象方程变成具体目标，规则链负责在具体目标上前进。

从 unfold 方程还能长出**归纳规则**（源码第 106–130 行）：
前向归纳 `rtrancl_full_induct` 与更好用的 `rtrancl_induct`；

```text

\<lbrakk><?a,?b> : ?r^*; \<And>x. ?P(<x,x>);
 \<And>x y z. \<lbrakk>?P(<x,y>); <x,y> : ?r^*; <y,z> : ?r\<rbrakk> \<Longrightarrow> ?P(<x,z>)\<rbrakk>
\<Longrightarrow> ?P(<?a,?b>)
```

传递性 `trans_rtrancl` 就是用它证的（源码第 132–137 行）：

```text

trans(?r^*)
```

`r^+` 与 `r^*` 的互转规则（`trancl_into_rtrancl` 等，源码第
155–205 行）配套齐全：

```text

<?a,?b> : ?r^+ \<Longrightarrow> <?a,?b> : ?r^*

\<lbrakk><?a,?b> : ?r^+; <?a,?b> : ?r \<Longrightarrow> ?P; \<And>y. \<lbrakk><?a,y> : ?r^+; <y,?b> : ?r\<rbrakk> \<Longrightarrow> ?P\<rbrakk>
\<Longrightarrow> ?P
```

第二条是 `tranclE`——"至少走一步"的消除规则：要么恰好一步
（`<a,b> : r`），要么前一段走 `r^+`、最后一步走 `r`。HOL 的
`tranclE` 完全同构，但 HOL 的 `tranclp`/`trancl` 是任意类型
（`('a × 'a) set`），CCL 这里锁死在 `i set` 上。

## 69.9 库怎么喂自动证明器

`Set` 理论的最后一段（源码第 376–391 行）把整库规则按用途挂到
blast / simp 的规则集上：

```isabelle
lemmas [intro!] = ballI subsetI InterI INT_I CollectI ComplI IntI UnCI singletonI
  and [intro] = bexI UnionI UN_I
  and [elim!] = bexE UnionE UN_E CollectE ComplE IntE UnE emptyE singletonE
  and [elim] = ballE InterD InterE INT_D INT_E subsetD subsetCE

lemma mem_rews:
  "(a : A Un B)   \<longleftrightarrow>  (a:A | a:B)"
  "(a : A Int B)  \<longleftrightarrow>  (a:A \<and> a:B)"
  "(a : Compl(B)) \<longleftrightarrow>  (\<not>a:B)"
  "(a : {b})      \<longleftrightarrow>  (a=b)"
  "(a : {})       \<longleftrightarrow>   False"
  "(a : {x. P(x)}) \<longleftrightarrow>  P(a)"
  by blast+

lemmas [simp] = trivial_set empty_eq mem_rews
  and [cong] = ball_cong bex_cong INT_cong UN_cong
```

感叹号是优先级：`intro!` 盖过上下文里可能冲突的引入规则。
`mem_rews` 是一族成员关系重写规则（第 306 行 `thm mem_rews`）——
挂上 `[simp]` 之后，blast 证集合等式基本一步过：

```text

  ?a : ?A Un ?B \<longleftrightarrow> ?a : ?A \<or> ?a : ?B
  ?a : ?A Int ?B \<longleftrightarrow> ?a : ?A \<and> ?a : ?B
  ?a : Compl(?B) \<longleftrightarrow> \<not> ?a : ?B
  ?a : {?b} \<longleftrightarrow> ?a = ?b
  ?a : {} \<longleftrightarrow> False
  ?a : Collect(?P) \<longleftrightarrow> ?P(?a)
```

六条规则就是"集合运算的真理表"：每个集合运算翻译成命题联结词。
blast 拿着它们做命题层重写，所以这些目标**不需要任何集合论推理**：

```isabelle
lemma blast_set_demo:
  "a : (A Un B) Int C \<longleftrightarrow> (a:A | a:B) \<and> a:C"
  by blast
```

```text

theorem
  blast_set_demo: ?a : (?A Un ?B) Int ?C \<longleftrightarrow> (?a : ?A \<or> ?a : ?B) \<and> ?a : ?C
```

注意输出里的 `|` 被打印回 `\<or>`——`|` 是 FOL 旧析取语法
（第 47 章），源码可写、打印归一。

库自身也吃这套配置：整部 `Set` 理论的等式定律（交换律、结合律、
分配律、De Morgan，源码第 394–516 行）几乎全是
`by (blast intro: equalityI)` 一行流。两个示例
（`examples/ccl/T69_ccl_set.thy` 第 316–320 行）：

```isabelle
lemma Int_Un_distrib_demo: "A Int (B Un C) = (A Int B) Un (A Int C)"
  by (blast intro: equalityI)

lemma Compl_Un_demo: "Compl(A Un B) = Compl(A) Int Compl(B)"
  by (blast intro: equalityI)
```

```text

theorem Int_Un_distrib_demo: ?A Int (?B Un ?C) = ?A Int ?B Un ?A Int ?C

theorem Compl_Un_demo: Compl(?A Un ?B) = Compl(?A) Int Compl(?B)
```

`intro: equalityI` 不能省：集合等式在 FOL 里不是命题等式，
`equalityI`（`A <= B ⟹ B <= A ⟹ A = B`，`<=` 反对称 + 自反的包装）
是 blast 需要的最后一块砖——它不在默认 intro 集里。

## 69.10 坑位清单（实测）

1. **Isabelle2026 的 CCL 会话只剩 5 个理论**——发行版
   `src/CCL/ROOT` 只列 `Wfd` / `Fix` / `ex/Nat` / `ex/List` /
   `ex/Stream` / `ex/Flag`；`Set` / `Lfp` / `Gfp` / `CCL` /
   `Trancl` / `Term` / `Type` / `Hered` 是留在树里的遗留文件。
   要用得自建会话（本教程的 `IsaTutCCL`）。
2. **Draft 会话里 `imports Set` 解析不到**——`process_theories`
   的 Draft 会话只在自己的 `-D` 目录里找理论文件。正解是限定导入
   `"IsaTutCCL.Set"`（同第 45 章的 `"HOL-Library.Multiset"` 套路）。
3. **库理论绝不能标 `(global)`**——会把 `Set` / `Nat` / `List` /
   `Stream` 污染成全局名，与 HOL / ZF / HOL-Library 里的同名理论
   相撞，整个构建报 `Bad import of theory ... need to include
   sessions`。
4. **ASCII 量词 `ALL` / `EX` / `INT` / `UN` 在 FOL 里可用**，但常量名
   不能叫它们（词法层整词替换，第 1 章有通用规则）；`SUM` / `PROD` /
   `INF` / `SUP` 在 CCL 里根本不存在。
5. **应用必须写括号**：`P(a)` 不是 `P a`（FOL 旧应用语法，第 47 章
   同款坑）。
6. **Trancl 的关系是 `i set`**（CCL 项类型），不是任意 `'a set`——
   照搬 HOL 的 `trancl` 经验会类型不匹配。
7. **`subst rtrancl_unfold` 是展开不是收拢**：等式左边是 `r^*`，
   subst 把目标里的闭包换成方程右边；想反向走要用
   `subst (asm) ...` 或对称改写。
8. **`lfp_lowerbound` 不需要 `mono`**；`lfp_Tarski` 才需要（与 HOL
   的 `lfp_unfold` 区别，见第 51 章）。
9. **blast 的证明力来自 `[intro!]` / `[elim!]` 分组**——自己写证明时
   `intro:` / `elim:` 要显式给，别指望默认集。
10. **库源码是 1993 年 apply 风格**（`apply ... done`），读的时候
    先还原每条规则的朝向；本章示例一律改写成 Isar。
## 69.11 与其他章的接口

- 第 47 章 FOL：本章的父逻辑，所有公理/规则的故乡。
- 第 70 章 CCL λ 演算：`Set` 的成员关系 `:` 被改造成类型判断，
  `gfp` 的余归纳升级成 `eq_coinduct3`。
- 第 71 章 Term/Type/Fix：`lfp` 的 `induct` 规则在这里变成
  `Nat_ind` / `List_ind`。
- 第 72 章 计算实例：四个 ex/ 理论把本章全部机制跑一遍。


上一章：[68 · 语法糖与调试](68-sugar.md) ｜ 下一章：[70 · CCL（二）：无类型 λ 演算](70-ccl-lambda.md) ｜ 返回：[README](../README.md)
