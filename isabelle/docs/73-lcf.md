# 73 · LCF：域论与计算的部分正确性逻辑

对应示例：`../examples/lcf/T73_lcf.thy`（IsaTutLCFex 会话，父堆
`IsaTutLCF`——即发行版 `src/LCF/` 的 5 个理论原样拷贝，见
`examples/lcfbase/ROOT`）

> 参考：[Isabelle/LCF 库索引](https://dist.isabelle.cit.tum.de/dist/library/FOL/LCF/index.html)

## 73.1 LCF：Milner 计算逻辑的 Isabelle 再形式化

第 54 章讲过 LCF 的历史：Milner 1972 年的 Edinburgh LCF、Paulson
1987 年的 Cambridge LCF，以及为它而生的 ML。本章把镜头拉近——
Isabelle 发行版自带的 `LCF` 理论（Tobias Nipkow 1992 年从 Paulson
的书 *Logic and Computation* 提炼）就是 **Cambridge LCF 的核心逻辑
在 Isabelle 里的再形式化**。

它回答一个具体问题：一个程序设计语言的语义、加上证明其部分
正确性的推理规则，怎样装进一阶逻辑？答案是**域论（domain
theory）**：

- 每个类型都是**完全偏序**（cpo）：有偏序 `<<`，有最小元 `UU`
  （读作 bottom，表示"不终止"）；
- 程序的指称是 cpo 的元素，递归定义的指称是函数的最小不动点
  `FIX(f)`；
- 等式 `=` 不是原始的——它被**定义**成两个方向的偏序
  （`eq_def`），所以 LCF 的等式推理天然是"双向小于等于"。

与第 69–72 章的 CCL 对比着读最有味道：CCL 用**余归纳**定义行为
等价，LCF 用**不动点归纳**证明部分正确性——同一个"计算逻辑"
命题在 1990 年代初的两条路线。

LCF 会话一共 5 个理论：`LCF` 本体 + 四个书例（`Ex1`–`Ex4`，全部
来自 Paulson 书里的编号：Section 10.4、Example 3.8、加法、
prefixpoint）。本教程把它们原样收进 `examples/lcfbase/`（会话
`IsaTutLCF`），T73 建立其上。本章引用的库代码全部在正文原样贴出，
读者不需要自己去翻源码。

## 73.2 cpo、UU 与 FIX：六条域论公理

库开篇（源码第 16–28 行）用类型类把 cpo 宣告为万物的默认排序：

```isabelle
class cpo = "term"
default_sort cpo
```

然后声明常量（第 30–44 行）——两个类型构造、五个程序算子、一个
谓词：

```isabelle
typedecl tr
typedecl void
typedecl ('a,'b) prod  (infixl "*" 6)
typedecl ('a,'b) sum   (infixl "+" 5)
```

`tr` 是三值逻辑的类型（UU / TT / FF），`void` 是只有一个元素的
类型，`prod`/`sum` 是笛卡尔积与严格和。函数空间、积、和、`tr`、
`void` 全部通过 `instance` 声明为 cpo（第 24–28 行）——于是**万物
有 bottom、万物可比较**。

接着是六条域论公理（第 46–59 行，全部正文引用）：

```isabelle
eq_def:        "x=y == x << y \<and> y << x"

less_trans:    "\<lbrakk>x << y; y << z\<rbrakk> \<Longrightarrow> x << z"
less_ext:      "(\<forall>x. f(x) << g(x)) \<Longrightarrow> f << g"
mono:          "\<lbrakk>f << g; x << y\<rbrakk> \<Longrightarrow> f(x) << g(y)"
minimal:       "UU << x"
FIX_eq:        "\<And>f. f(FIX(f)) = FIX(f)"
```

- `less_trans` 是偏序的传递性；
- `less_ext` 说**函数的序由逐点序决定**（外延性）；
- `mono` 把两层序接起来：函数更大、参数更大，结果就更大；
- `minimal` 说 `UU` 是万物之底——发散项小于一切；
- `FIX_eq` 是整座大厦的拱顶石——**每个连续函数都有不动点，且
  FIX 就是它**。

注意 `FIX_eq` 的形态：它是一条**等式**公理，由 `eq_def` 展开就是
"两个方向的 `<<`"。所以 LCF 从第一行起就是"偏序语义、等式语法"
——读者证任何等式时都要记得背后其实是序。

六条公理实测打印（`examples/lcf/T73_lcf.thy` 第 71 行）：

```text
  ?x = ?y \<equiv> ?x << ?y \<and> ?y << ?x

  \<lbrakk>?x << ?y; ?y << ?z\<rbrakk> \<Longrightarrow> ?x << ?z
  \<forall>x. ?f(x) << ?g(x) \<Longrightarrow> ?f << ?g
  \<lbrakk>?f << ?g; ?x << ?y\<rbrakk> \<Longrightarrow> ?f(?x) << ?g(?y)
  UU << ?x
  ?f(FIX(?f)) = FIX(?f)
```

注意打印形态：源码的 ASCII `==` 打印成 `\<equiv>`（定义等号），
`ALL` 打印成 `∀`——与第 47 章 FOL、第 69 章 CCL 的规律一致：
**写源码用 ASCII，读输出见符号**。

## 73.3 tr 与 COND：三值条件、UU 吞掉一切

布尔值不是两个而是**三个**（源码第 61–73 行）：

```isabelle
tr_cases:      "p=UU \<or> p=TT \<or> p=FF"

not_TT_less_FF: "\<not> TT << FF"
not_FF_less_TT: "\<not> FF << TT"
not_TT_less_UU: "\<not> TT << UU"
not_FF_less_UU: "\<not> FF << UU"

COND_UU:       "UU \<Rightarrow> x | y  =  UU"
COND_TT:       "TT \<Rightarrow> x | y  =  x"
COND_FF:       "FF \<Rightarrow> x | y  =  y"
```

`tr_cases` 是穷举：任何 `tr` 要么未定义、要么真、要么假。四条
`not_*_less_*` 说这三个值**互不重叠**且 TT/FF 严格在 UU 之上——
它们是"已定义的值不能互相吞并"的那一半语义。

条件表达式 `b ⇒ x | y` 的三条计算规则是典型的**严格性
（strictness）**设计：**条件未定义，整个表达式就未定义**——LCF
是部分函数语言的语义，不终止会传染。这与 CCL 的 `caseBbot`
（第 70 章）完全同构。

实测打印（示例第 101–102 行）：

```text
  ?p = UU \<or> ?p = TT \<or> ?p = FF
  \<not> TT << FF
  \<not> TT << UU
```

```text
  UU \<Rightarrow> ?x | ?y = UU
  TT \<Rightarrow> ?x | ?y = ?x
  FF \<Rightarrow> ?x | ?y = ?y
```

第 184–235 行从这几条公理长出第一批工具引理。最有代表性的是
`tr_induct`（三情况穷举归纳）与 `COND_cases_iff`（COND 的完整
刻画）：

```isabelle
lemma tr_induct: "\<lbrakk>P(UU); P(TT); P(FF)\<rbrakk> \<Longrightarrow> \<forall>b. P(b)"
```

```text
  \<lbrakk>?P(UU); ?P(TT); ?P(FF)\<rbrakk> \<Longrightarrow> \<forall>b. ?P(b)
  ?P(?b \<Rightarrow> ?x | ?y) \<longleftrightarrow>
  (?b = UU \<longrightarrow> ?P(UU)) \<and> (?b = TT \<longrightarrow> ?P(?x)) \<and> (?b = FF \<longrightarrow> ?P(?y))
  \<lbrakk>?x = UU \<longrightarrow> ?P(UU); ?x = TT \<longrightarrow> ?P(?xa); ?x = FF \<longrightarrow> ?P(?y)\<rbrakk>
  \<Longrightarrow> ?P(?x \<Rightarrow> ?xa | ?y)
```

`COND_cases_iff` 把"对 COND 的行为做推理"化归成"对三个分支分别
推理"——后面 `Ex1` / `Ex2` 的证明里 `simp split: COND_cases_iff`
一把梭就是靠它（实测打印见示例第 117 行）。

## 73.4 积、严格和与 void：三个数据类型

**积类型**（源码第 75–81、248–293 行）：

```isabelle
surj_pairing:  "<FST(z),SND(z)> = z"

FST:   "FST(<x,y>) = x"
SND:   "SND(<x,y>) = y"
```

这三条说积是"无标签的"：任何序对拆开再装回去不变。关键引理
`UU_is_UU_UU`：**`<UU,UU> = UU`**——积的 bottom 就是 bottom 的
积。第 282–293 行由此推出 `FST(UU) = UU`、`SND(UU) = UU`（投影
也严格）。`PROD_less` 给出积上序的逐分量刻画：

```text
  ?p << ?q \<longleftrightarrow> FST(?p) << FST(?q) \<and> SND(?p) << SND(?q)
  <?a,?b> << <?c,?d> \<longleftrightarrow> ?a << ?c \<and> ?b << ?d
  <?a,?b> = <?c,?d> \<longleftrightarrow> ?a = ?c \<and> ?b = ?d
  <UU,UU> = UU
  FST(UU) = UU
  SND(UU) = UU
```

（实测打印，示例第 160 行。注意 `PAIR_eq`：**积上的相等就是逐
分量相等**——没有 η 问题，比 CCL 的行为等价简单一个量级。）

**严格和**（源码第 83–97 行）：

```isabelle
INL_DEF: "\<not>x=UU \<Longrightarrow> \<not>INL(x)=UU"
INR_DEF: "\<not>x=UU \<Longrightarrow> \<not>INR(x)=UU"

INL_STRICT: "INL(UU) = UU"
INR_STRICT: "INR(UU) = UU"

WHEN_UU:  "WHEN(f,g,UU) = UU"
WHEN_INL: "\<not>x=UU \<Longrightarrow> WHEN(f,g,INL(x)) = f(x)"
WHEN_INR: "\<not>x=UU \<Longrightarrow> WHEN(f,g,INR(x)) = g(x)"

SUM_EXHAUSTION:
  "z = UU \<or> (\<exists>x. \<not>x=UU \<and> z = INL(x)) \<or> (\<exists>y. \<not>y=UU \<and> z = INR(y))"
```

`WHEN` 是和类型上的分派子（CCL 的 `case` 同款角色）：左值走
`f`、右值走 `g`、bottom 吞掉。严格性规则与 CCL 完全同构——第
70 章讲过的"应用即 case"在这里换成"分派即 WHEN"。实测打印：

```text
  INL(UU) = UU
  INR(UU) = UU
  WHEN(?f, ?g, UU) = UU
  ?x \<noteq> UU \<Longrightarrow> WHEN(?f, ?g, INL(?x)) = ?f(?x)
  ?x \<noteq> UU \<Longrightarrow> WHEN(?f, ?g, INR(?x)) = ?g(?x)
  ?z = UU \<or> (\<exists>x. x \<noteq> UU \<and> ?z = INL(x)) \<or> (\<exists>y. y \<noteq> UU \<and> ?z = INR(y))
```

**void 类型**（第 99–102 行）只有一条公理：

```isabelle
void_cases:    "(x::void) = UU"
```

**void 里只有 UU**——它是"空数据类型"的域论化身：一个不产出任
何已定义值的类型（实测打印就是一行 `?x = UU`）。

## 73.5 基础引理流水线：从公理到工具

第 125–235 行是一段密集的引理流水线，全部从六条域论公理 +
`eq_def` 展开出发。几组关键工具。

**等式与序的互译**（第 125–137 行）：

```isabelle
lemma eq_imp_less1: "x = y \<Longrightarrow> x << y"
lemma eq_imp_less2: "x = y \<Longrightarrow> y << x"
lemma less_refl [simp]: "x << x"
lemma less_anti_sym: "\<lbrakk>x << y; y << x\<rbrakk> \<Longrightarrow> x=y"
```

`eq_imp_less1/2` 是 `eq_def` 的两个方向拆开用；`less_anti_sym` 是
反方向的合成。**证等式的标准开局**：拆成两个 `<<`，分别证。

**外延与合同**（第 139–163 行）：

```isabelle
lemma ext: "(\<And>x::'a::cpo. f(x)=(g(x)::'b::cpo)) \<Longrightarrow> (\<lambda>x. f(x))=(\<lambda>x. g(x))"
lemma cong: "\<lbrakk>f = g; x = y\<rbrakk> \<Longrightarrow> f(x)=g(y)"

lemma less_ap_term: "x << y \<Longrightarrow> f(x) << f(y)"
lemma less_ap_thm: "f << g \<Longrightarrow> f(x) << g(x)"
lemma ap_term: "(x::'a::cpo) = y \<Longrightarrow> (f(x)::'b::cpo) = f(y)"
lemma ap_thm: "f = g \<Longrightarrow> f(x) = g(x)"
```

注意名字的来历：`ap_term` / `ap_thm` 是 **Cambridge LCF 的老战术
AP_TERM / AP_THM 的直译**——"函数等于函数（thm）"与"应用到项
（term）"两种合同推理。FOL 里没有高阶合一替你做这些，所以它们
必须显式存在。实测打印（示例第 207–208 行）：

```text
  ?x = ?y \<Longrightarrow> ?x << ?y
  ?x << ?x
  \<lbrakk>?x << ?y; ?y << ?x\<rbrakk> \<Longrightarrow> ?x = ?y
  (\<And>x. ?f(x) = ?g(x)) \<Longrightarrow> ?f = ?g
  \<lbrakk>?f = ?g; ?x = ?y\<rbrakk> \<Longrightarrow> ?f(?x) = ?g(?y)
```

```text
  ?x << ?y \<Longrightarrow> ?f(?x) << ?f(?y)
  ?f << ?g \<Longrightarrow> ?f(?x) << ?g(?x)
  ?x = ?y \<Longrightarrow> ?f(?x) = ?f(?y)
  ?f = ?g \<Longrightarrow> ?f(?x) = ?g(?x)
```

**UU 的专属事实**（第 166–182 行）：

```isabelle
lemma UU_abs: "(\<lambda>x::'a::cpo. UU) = UU"
lemma UU_app: "UU(x) = UU"
lemma less_UU: "x << UU \<Longrightarrow> x=UU"
```

`UU_abs` 说**常函数 UU 就是 UU 本身**（函数空间的 bottom 是
bottom 的常函数）；`less_UU` 说"小于等于 bottom 的只有 bottom"。
第 237–245 行把这些全部挂成 simp 规则，于是"UU 吞掉一切"在
simp 里免费：

```text
  (\<lambda>x. UU) = UU
  UU(?x) = UU
  ?x << UU \<Longrightarrow> ?x = UU
```

**tr 的六个不相等**（第 204–215 行）：由四条 `not_*_less_*` 公理
经 `Contrapos`（逆否）逐一推出：

```text
  UU \<noteq> TT
  TT \<noteq> FF
  FF \<noteq> UU
```

（只列三条，另外三条对称；实测打印见示例第 210 行。）

两条小演示——严格性在 simp 里的样子（示例第 214–218 行）：

```isabelle
lemma cond_tt_demo: "TT \<Rightarrow> a | b = (a::'a::cpo)"
  by simp

lemma fst_uu_demo: "FST(UU) = UU"
  by simp
```

```text
theorem cond_tt_demo: TT \<Rightarrow> ?a | ?b = ?a

theorem fst_uu_demo: FST(UU) = UU
```

两条都是一步 `simp`——`COND_TT` 与 `FST_STRICT` 已经在默认
simp 集里。

## 73.6 可采纳性：不动点归纳的门票

第 106–122 行是全库的**方法论核心**。不动点归纳公理：

```isabelle
induct: "\<lbrakk>adm(P); P(UU); \<forall>x. P(x) \<longrightarrow> P(f(x))\<rbrakk> \<Longrightarrow> P(FIX(f))"
```

```text
\<lbrakk>adm(?P); ?P(UU); \<forall>x. ?P(x) \<longrightarrow> ?P(?f(x))\<rbrakk> \<Longrightarrow> ?P(FIX(?f))
```

读法：要证性质 P 对 `FIX(f)` 的展开极限成立，需要三样东西：

1. **`adm(P)`——P 是可采纳的（admissible）**；
2. P 从 UU 起步（`P(UU)`）；
3. 每一步迭代保持（`P(x) ⟹ P(f(x))`）。

可采纳性是域论的拓扑直觉：**P 对链的极限封闭**——一列越来越定
义的近似若每个都满足 P，极限也满足。没有它，不动点归纳就是
**错的**：比如 `x = UU` 对每步迭代 `UU, f(UU), f(f(UU))…` 都成立
（每项都是有限展开），但对极限 `FIX(f)` 一般不成立。adm 就是
为排除这类"只在有限层成立"的性质而生。

八条 adm 公理（第 115–122 行，Paulson 书第 199–200 页的规则表）：

```isabelle
adm_less:      "\<And>t u. adm(\<lambda>x. t(x) << u(x))"
adm_not_less:  "\<And>t u. adm(\<lambda>x.\<not> t(x) << u)"
adm_not_free:  "\<And>A. adm(\<lambda>x. A)"
adm_subst:     "\<And>P t. adm(P) \<Longrightarrow> adm(\<lambda>x. P(t(x)))"
adm_conj:      "\<And>P Q. \<lbrakk>adm(P); adm(Q)\<rbrakk> \<Longrightarrow> adm(\<lambda>x. P(x)\<and>Q(x))"
adm_disj:      "\<And>P Q. \<lbrakk>adm(P); adm(Q)\<rbrakk> \<Longrightarrow> adm(\<lambda>x. P(x)\<or>Q(x))"
adm_imp:       "\<And>P Q. \<lbrakk>adm(\<lambda>x.\<not>P(x)); adm(Q)\<rbrakk> \<Longrightarrow> adm(\<lambda>x. P(x)\<longrightarrow>Q(x))"
adm_all:       "\<And>P. (\<And>y. adm(P(y))) \<Longrightarrow> adm(\<lambda>x. \<forall>y. P(y,x))"
```

实测打印（示例第 258–261 行）：

```text
\<lbrakk>adm(?P); ?P(UU); \<forall>x. ?P(x) \<longrightarrow> ?P(?f(x))\<rbrakk> \<Longrightarrow> ?P(FIX(?f))
```

```text
  adm(\<lambda>x. ?t(x) << ?u(x))
  adm(\<lambda>x. \<not> ?t(x) << ?u)
  adm(\<lambda>x. ?A)
  adm(?P) \<Longrightarrow> adm(\<lambda>x. ?P(?t(x)))
```

```text
  \<lbrakk>adm(?P); adm(?Q)\<rbrakk> \<Longrightarrow> adm(\<lambda>x. ?P(x) \<and> ?Q(x))
  \<lbrakk>adm(?P); adm(?Q)\<rbrakk> \<Longrightarrow> adm(\<lambda>x. ?P(x) \<or> ?Q(x))
  \<lbrakk>adm(\<lambda>x. \<not> ?P(x)); adm(?Q)\<rbrakk> \<Longrightarrow> adm(\<lambda>x. ?P(x) \<longrightarrow> ?Q(x))
  (\<And>y. adm(?P(y))) \<Longrightarrow> adm(\<lambda>x. \<forall>y. ?P(y, x))
```

结构是一张"谓词组合保持可采纳"的表：

- `<<` **两侧**都可采纳（`adm_less`）——序的谓词最友好；
- 否定那边**只能否掉左边**（`adm_not_less`：`¬ t(x) << u`，u 不
  含 x）——一般的 `¬P` 不可采纳；
- 命题常量免费（`adm_not_free`）；
- 代入、合取、析取、蕴含（左否定右可采纳）、全称都保持。

第 298–319 行再补两条派生：`adm_eq`（**等式可采纳**——按
`eq_def` 拆成两个 `adm_less`）与 `adm_not_eq_tr`（对三值 bool 的
不等可采纳）：

```text
  adm(\<lambda>x. ?t(x) = ?u(x))
  \<forall>p. adm(\<lambda>x. ?t(x) \<noteq> p)
```

库的总结在 `adm_lemmas`（第 317–319 行）——后面 `induct` 方法
自动拿它当弹药库。**证不动点归纳的第一步永远是**：看目标谓词
能不能被这张表覆盖；能则 adm 自动关，不能则必须把 `adm(Q)` 当
前提给（见 73.7 的演示）。

## 73.7 induct 方法与不动点三件套

第 321–326 行把不动点归纳包成一个方法（正文引用其核心逻辑）：

```isabelle
method_setup induct = \<open>
  Scan.lift Parse.embedded_inner_syntax >> (fn v => fn ctxt =>
    SIMPLE_METHOD' (fn i =>
      Rule_Insts.res_inst_tac ctxt [((("f", 0), Position.none), v)] [] @{thm induct} i THEN
      REPEAT (resolve_tac ctxt @{thms adm_lemmas} i)))
\<close>
```

用法：`apply (induct f)`——实例化函数 `f`，然后**自动尝试用
`adm_lemmas` 关掉可采纳性子目标**。谓词是公理表里没有的组合时
（比如任意的 `Q`），adm 义务关不掉，必须自己作为前提提供。实测
一条（示例第 268–284 行）——注意 `induct` 留下**三个子目标**、
顺序固定（adm / P(UU) / 逐步保持），示例证明里逐个用前提关：

```isabelle
lemma fix_induct_demo:
  fixes Q :: "'a::cpo \<Rightarrow> o" and s :: "'a::cpo \<Rightarrow> 'a::cpo"
  assumes admQ: "adm(Q)" and base: "Q(UU)"
    and step: "\<And>x. Q(x) \<Longrightarrow> Q(s(x))"
  shows "Q(FIX(s))"
  apply (induct s)
    apply (rule admQ)
   apply (rule base)
  apply (intro strip)
  apply (rule step)
  apply assumption
  done
```

```text
theorem fix_induct_demo:
 \<lbrakk>adm(?Q); ?Q(UU); \<And>x. ?Q(x) \<Longrightarrow> ?Q(?s(x))\<rbrakk> \<Longrightarrow> ?Q(FIX(?s))
```

第三个子目标 `∀x. Q(x) ⟶ Q(s(x))` 是 **strip 形态**——直接
`assumption` 关不掉，先 `intro strip` 把全称和蕴含剥开，再用
`step` 与 `assumption` 收尾。

不动点理论的定理（第 328–379 行）：

```isabelle
lemma least_FIX: "f(p) = p \<Longrightarrow> FIX(f) << p"
```

```text
  ?f(?p) = ?p \<Longrightarrow> FIX(?f) << ?p
  \<lbrakk>?f(?p) = ?p; \<forall>q. ?f(q) = q \<longrightarrow> ?p << q\<rbrakk> \<Longrightarrow> ?p = FIX(?f)
  <FIX(?f),FIX(?g)> = FIX(\<lambda>p. <?f(FST(p)),?g(SND(p))>)
  FIX(?f) = FST(FIX(\<lambda>p. <?f(FST(p)),?g(SND(p))>))
  FIX(?g) = SND(FIX(\<lambda>p. <?f(FST(p)),?g(SND(p))>))
  \<lbrakk>adm(\<lambda>p. ?P(FST(p), SND(p))); ?P(UU, UU);
   \<forall>x y. ?P(x, y) \<longrightarrow> ?P(?f(x), ?g(y))\<rbrakk>
  \<Longrightarrow> ?P(FIX(?f), FIX(?g))
```

（实测打印，示例第 304 行。依次是 `least_FIX` / `lfp_is_FIX` /
`FIX_pair` / `FIX1` / `FIX2` / `induct2`。）

- `least_FIX` 说 FIX 是**最小**不动点：任何不动点 p 都在它之上；
- `lfp_is_FIX` 是刻画：**既是不动点又最小，就是 FIX**——证
  `p = FIX(f)` 的标准模板；
- `FIX_pair` 把**两个**不动点打包成**一个**：并行不动点。然后
  `FIX1` / `FIX2` 用 FST/SND 拆回来；
- `induct2` 是**双函数版不动点归纳**：证"两个递归定义相互合作
  满足 P"的利器（73.10 节讨论它的用武之地）。

## 73.8 Ex1：幂等函数（Paulson 书 Section 10.4）

四个书例登场。`Ex1`（源码 `ex/Ex1.thy`，全文 45 行）形式化
Paulson 书第 10.4 节的例子：**一个"重复直到谓词满足"的循环函数
是幂等的**。先公理化语法（第 8–20 行）：

```isabelle
axiomatization
  P     :: "'a \<Rightarrow> tr" and
  G     :: "'a \<Rightarrow> 'a" and
  H     :: "'a \<Rightarrow> 'a" and
  K     :: "('a \<Rightarrow> 'a) \<Rightarrow> ('a \<Rightarrow> 'a)"
where
  P_strict:     "P(UU) = UU" and
  K:            "K = (\<lambda>h x. P(x) \<Rightarrow> x | h(h(G(x))))" and
  H:            "H = FIX(K)"
```

`K` 是循环体：谓词 `P` 满足就返回 `x`，否则做两次 `G` 再递归。
`H` 是它的不动点——`while P do G` 的指称语义。要证的最终目标：

```isabelle
lemma H_idemp: "\<forall>x. H(H(x)) = H(x)"
```

**跑两遍等于跑一遍（幂等）**。库的证明分四步（第 24–40 行）。

第一步，展开：

```isabelle
lemma H_unfold: "H = K(H)"
  apply (simplesubst H)
  apply (rule FIX_eq [symmetric])
  done
```

这就是 `FIX_eq` 换个名字（`simplesubst` 先用 `H` 的定义替换目标
里的 `H`，再用 `FIX_eq` 的对称形式收尾）。

第二步，严格性：

```isabelle
lemma H_strict [simp]: "H(UU)=UU"
  apply (simplesubst H_unfold)
  apply simp
  done
```

展开 + `P(UU) = UU` 即得。

第三步是全证明的心脏：

```isabelle
lemma H_idemp_lemma: "\<forall>x. H(FIX(K,x)) = FIX(K,x)"
  apply (induct K)
  apply simp
  apply (simp split: COND_cases_iff)
  apply (intro strip)
  apply (subst H_unfold)
  apply simp
  done
```

注意目标里 `FIX(K,x)` 是把 FIX 应用到**双参数函数的部分应用**
——不动点归纳的对象不再是 `H` 而是 `FIX(K)` 的一般展开。证明是
标准三段式：`apply (induct K)` 自动关 adm（谓词是等式，`adm_eq`
管）、UU 起步靠 simp（严格性）、归纳步 `simp split:
COND_cases_iff` 把 COND 拆成三分支 + `H_unfold` 改写内层调用。

第四步收口：

```isabelle
lemma H_idemp: "\<forall>x. H(H(x)) = H(x)"
  apply (rule H_idemp_lemma [folded H])
  done
```

由引理按 `H` 的定义折叠（`[folded H]` 把引理里的 `FIX(K,x)` 换
回 `H(x)`）。全部四条实测打印（示例第 347 行）：

```text
  H = K(H)
  H(UU) = UU
  \<forall>x. H(FIX(K, x)) = FIX(K, x)
  \<forall>x. H(H(x)) = H(x)
```

## 73.9 Ex3 与 Ex4：加法与前缀点

`Ex3`（源码 `ex/Ex3.thy`，24 行）是书上"后继的不动点是无穷大"
的例子：

```isabelle
axiomatization
  s     :: "'a \<Rightarrow> 'a" and
  p     :: "'a \<Rightarrow> 'a \<Rightarrow> 'a"
where
  p_strict:     "p(UU) = UU" and
  p_s:          "p(s(x),y) = s(p(x,y))"

declare p_strict [simp] p_s [simp]

lemma example: "p(FIX(s),y) = FIX(s)"
  apply (induct s)
  apply simp
  apply simp
  done
```

`s` 是后继，`p` 是加法（对第一参数递归）。定理实测打印：

```text
p(FIX(s), ?y) = FIX(s)
```

**无穷大加任何数还是无穷大**。证明只有两行：`apply (induct s)`
对第一参数做不动点归纳，simp 用两条公理化规则直接收——adm 由
`adm_lemmas` 自动关（又是等式谓词）。

`Ex4`（源码 `ex/Ex4.thy`，24 行）是前缀点（prefixpoint）刻画：

```isabelle
lemma example:
  assumes asms: "f(p) << p"  "\<And>q. f(q) << q \<Longrightarrow> p << q"
  shows "FIX(f)=p"
  apply (unfold eq_def)
  apply (rule conjI)
  apply (induct f)
  apply (rule minimal)
  apply (intro strip)
  apply (rule less_trans)
  prefer 2
  apply (rule asms)
  apply (erule less_ap_term)
  apply (rule asms)
  apply (rule FIX_eq [THEN eq_imp_less1])
  done
```

```text
\<lbrakk>?f(?p) << ?p; \<And>q. ?f(q) << q \<Longrightarrow> ?p << q\<rbrakk> \<Longrightarrow> FIX(?f) = ?p
```

**p 是所有前缀点里最大的那个，当且仅当 p 就是 FIX(f)**。这是
`lfp_is_FIX` 的偏序版：不动点条件 `f(p) = p` 弱化成前缀点
`f(p) << p`，最小性条件相应变成"比一切前缀点都大"。证明开局
`unfold eq_def` 把等式拆成两个 `<<`（坑位 5 的标准应用），一个
方向不动点归纳、一个方向用 `FIX_eq` 的等式一半。

一个小复刻——`Ex3` 型的推理直接上手做一遍（示例第 386–399 行）。
先公理化自己的后继与加法：

```isabelle
axiomatization
  my_s :: "'a::cpo \<Rightarrow> 'a" and
  my_p :: "'a::cpo \<Rightarrow> 'a::cpo \<Rightarrow> 'a"
where
  my_p_strict: "my_p(UU) = UU" and
  my_p_s: "my_p(my_s(x),y) = my_s(my_p(x,y))"

declare my_p_strict [simp] my_p_s [simp]

lemma my_ex3: "my_p(FIX(my_s),y) = FIX(my_s)"
  apply (induct my_s)
  apply simp
  apply simp
  done
```

```text
theorem my_ex3: my_p(FIX(my_s), ?y) = FIX(my_s)
```

两行收——与库的 `Ex3` 逐字同构，只是换了名字。

## 73.10 Ex2：双不动点（Example 3.8）

`Ex2`（源码 `ex/Ex2.thy`，书 Example 3.8，全文 28 行）是四个例
子里唯一用**双参数不动点归纳**的。它的公理化与 `Ex1` 共享名字
`P`（都声明 `P :: 'a \<Rightarrow> tr`），所以**不能与 `Ex1` 同
imports**（类型冲突实测：报 `Clash of types` 的近亲错误）——本教
程的 imports 行因此只带 Ex1/Ex3/Ex4。要看它的定理打印，单独开一
个只导 `IsaTutLCF.Ex2` 的会话即可；这里把源码全文贴出讲解：

```isabelle
theory Ex2
imports "../LCF"
begin

axiomatization
  P     :: "'a \<Rightarrow> tr" and
  F     :: "'b \<Rightarrow> 'b" and
  G     :: "'a \<Rightarrow> 'a" and
  H     :: "'a \<Rightarrow> 'b \<Rightarrow> 'b" and
  K     :: "('a \<Rightarrow> 'b \<Rightarrow> 'b) \<Rightarrow> ('a \<Rightarrow> 'b \<Rightarrow> 'b)"
where
  F_strict:     "F(UU) = UU" and
  K:            "K = (\<lambda>h x y. P(x) \<Rightarrow> y | F(h(G(x),y)))" and
  H:            "H = FIX(K)"

declare F_strict [simp] K [simp]

lemma example: "\<forall>x. F(H(x::'a,y::'b)) = H(x,F(y))"
  apply (simplesubst H)
  apply (induct "K:: ('a\<Rightarrow>'b\<Rightarrow>'b) \<Rightarrow> ('a\<Rightarrow>'b\<Rightarrow>'b)")
  apply simp
  apply (simp split: COND_cases_iff)
  done

end
```

设定：`H` 是双参数递归函数（对 `x` 递归，`y` 是累积参数），
`F` 是另一个对第二参数位置严格单调的操作。定理

<!-- 示意块：Ex2 未与本教程同会话运行（见坑位 2），此为其定理文本 -->
```text
\<forall>x. F(H(x, y)) = H(x, F(y))
```

说 **F 穿过 H**——把 F 塞进循环体等于把 F 套在结果外面。这类
"fusion / 穿透"定律是证明编译器优化正确的原型。

证明三行：

1. 先把 `H` 展开成 `FIX(K)` 的迭代形态（`simplesubst H`）；
2. 然后对 `K` 做不动点归纳。UU 步 simp 收（`F(UU) = UU` 两头都
   是 UU）；
3. 归纳步 `simp split: COND_cases_iff` 把 `P(x) ⇒ … | …` 拆三
   支，TT/FF 支直接对上归纳假设。

adm 义务由 `induct` 方法从 `adm_lemmas` 自动关闭——`adm_less`
管 `F(..) << H(..)` 形状的子公式（经 `eq_def` 拆开）。

`induct2`（第 73.7 节）在这里没用上——目标只有一个 FIX；但当两
个递归定义**互相依赖**时（`FIX_pair` 的场景），`induct2` 就是唯
一入口。它是"并行递归正确性"的标准武器，Paulson 书里 WHILE
规则的证明就是它的变体。

## 73.11 坑位清单（实测）

1. **`imports "IsaTutLCF.ex.Ex1"` 解析不到**：理论注册名是
   `IsaTutLCF.Ex1`（`directories "ex"` 不进限定名）。写带 `ex.`
   的全名反而报 `need to include sessions IsaTutLCF.ex`。
2. **Ex1 与 Ex2 不能同 imports**：两者都公理化 `P :: 'a ⇒ tr`，
   合并即类型冲突（`Clash of types`）。要同时讲，只能串场或贴
   源码。
3. **`induct` 方法的 adm 不是万能关**：谓词是 `adm_lemmas` 表内
   形状（`<<` 组合、等、tr 不等）才自动；任意谓词 `Q` 必须把
   `adm(Q)` 当前提给。
4. **`apply (induct f)` 出三个子目标、顺序固定**：adm / P(UU) /
   `∀x. P(x) ⟶ P(f(x))`。第三个是 strip 形态，直接 assumption
   关不掉，先 `intro strip`。
5. **`eq_def` 是定义不是公理**：证等式最常用的开局是
   `apply (unfold eq_def)` 拆成两个 `<<`（`Ex4` 的证明就是）。
   反过来 `simp add: eq_def` 也能把等式重写成序。
6. **`ap_term` / `ap_thm` 的方向**：term 是"项相同函数作用"
   （x=y 推 f(x)=f(y)），thm 是"函数相同作用到项"（f=g 推
   f(x)=g(x)）。与老 LCF 战术名对应，别记反。
7. **`simp split: COND_cases_iff` 是处理 COND 的标准姿势**：直接
   simp 只会按 COND_TT/FF/UU 三条重写头部，要对条件分情况推理
   必须 split。
8. **`FIX_eq` 给的是等式、`least_FIX` 给的是序**：证 `FIX(f) = p`
   要两个方向（`lfp_is_FIX` 模板），只证一边会卡在另一半。
9. **`UU_abs`：`(λx. UU) = UU`**——常函数 UU 就是 UU 本身（函数
   空间的 bottom）。simp 已挂；手写证明时别绕路。
10. **LCF 没有 `induct_tac` 也没有结构归纳**：唯一的归纳就是不动
    点归纳（`induct` / `induct2`）；数据上的推理靠穷举公理
    （`tr_cases` / `SUM_EXHAUSTION` / `void_cases`）。

## 73.12 与其他章的接口

- 第 54 章讲 LCF 的历史（Milner/Paulson/ML 的诞生），本章是它的
  逻辑本体；
- 第 47 章 FOL 是本章的逻辑底座（LCF = FOL + 域论公理）；
- 第 69 章 lfp/gfp 是同一套不动点思想的集合论化身，第 71 章 CCL
  的 Wfd/Fix 则是另一个计算逻辑家族的对照；
- `Ex1` / `Ex3` / `Ex4` 的证明模式（induct + simp split）与第
  70 章 CCL 的余归纳模式（eq_coinduct3 + EQgen）恰成镜像：一边
  自底向上逼近，一边自顶向下兜底。

上一章：[72 · CCL（四）：四个可执行例子](72-ccl-programs.md) ｜
下一章：[README](../README.md) ｜ 返回：[README](../README.md)
