# 70 · CCL（二）：无类型 λ 演算与行为等价

对应示例：`../examples/ccl/T70_ccl_lambda.thy`（IsaTutCCLex 会话，父堆
`IsaTutCCL`）

> 参考：[Isabelle/CCL 库索引](https://dist.isabelle.cit.tum.de/dist/library/FOL/CCL/index.html?token=Isabelle)

## 70.1 一个「无类型但可证」的函数语言

第 69 章在 FOL 上造了集合论；`CCL` 理论则往前一步：造一个**无类型
λ 演算**，并给出它的指称语义。库开篇（源码 `src/CCL/CCL.thy`
第 13–17 行）把动机说得很直白——HOL 太强：描述算子让任何类型都能
塞进"不可执行"的项，一个只含可执行项的程序类型就定义不出来了；
CCL 的对策是**不要类型**——所有程序项只有一个类型 `i`，函数
也是项（`lam x. b(x) : i`），用 `bot` 表示发散。代价是全部性质都要
从公理出发；收益是第 69 章的 lfp/gfp/余归纳机器可以直接用来证行为
等价。

本章把这条路线完整走一遍：类型技巧 → 操作语义公理 → β 规则 →
构造子内射性 → 行为等价（`[=` 与 `=`）→ 两场余归纳实战 → Term
标准库。

## 70.2 类型类 `prog`：让「万物皆项」类型安全

库源码第 13–25 行。开头的 `text` 块是库作者的自白——为什么不用 HOL：

```isabelle
text \<open>
  Based on FOL extended with set collection, a primitive higher-order
  logic.  HOL is too strong - descriptions prevent a type of programs
  being defined which contains only executable terms.
\<close>

class prog = "term"
default_sort prog

instance "fun" :: (prog, prog) prog ..

typedecl i
instance i :: prog ..
```

`i` 是一个新类型（`typedecl`，第 47 章同款），归属于类型类 `prog`；
再宣布函数空间保持 `prog`。于是 `i⇒i` 也是程序类型，
`lambda ::(i⇒i)⇒i` 就能把函数变成项——这是"无类型"的技术核心：
**不是没有类型，而是把所有东西压进同一个类型**。
`default_sort prog` 让裸类型变量默认取 `prog` 排序，所以 `fix` /
`SIM` 这些多态常量不用写排序注解。

自应用 `lam x. x`x`（Ω 的前半身）因此良型（`examples/ccl/T70_ccl_lambda.thy`
第 44 行 `term` 命令实测）：

```text

"lam x. x ` x"
  :: "i"
```

打印确认它就是一个普通的 `i` 项。注意 `` ` `` 是应用的中缀写法
（源码第 41 行，`infixl` 优先级 56），**必须写括号**的旧应用语法
在 FOL 里同样有效，两者混用即可。

## 70.3 Eval：操作语义的九条公理

求值判断 `t ⟶ c` 在 `consts` 块里声明（源码第 28–45 行，`Eval`
中缀在第 30 行，优先级 20），九条公理在第 50–59 行整个**公理化**：
五个构造子各自求值成自身，`case` 按构造子分派：

```isabelle
axiomatization where
  trueV:       "true \<longlongrightarrow> true" and
  falseV:      "false \<longlongrightarrow> false" and
  pairV:       "<a,b> \<longlongrightarrow> <a,b>" and
  lamV:        "\<And>b. lam x. b(x) \<longlongrightarrow> lam x. b(x)" and

  caseVtrue:   "\<lbrakk>t \<longlongrightarrow> true; d \<longlongrightarrow> c\<rbrakk> \<Longrightarrow> case(t,d,e,f,g) \<longlongrightarrow> c" and
  caseVfalse:  "\<lbrakk>t \<longlongrightarrow> false; e \<longlongrightarrow> c\<rbrakk> \<Longrightarrow> case(t,d,e,f,g) \<longlongrightarrow> c" and
  caseVpair:   "\<lbrakk>t \<longlongrightarrow> <a,b>; f(a,b) \<longlongrightarrow> c\<rbrakk> \<Longrightarrow> case(t,d,e,f,g) \<longlongrightarrow> c" and
  caseVlam:    "\<And>b. \<lbrakk>t \<longlongrightarrow> lam x. b(x); g(b) \<longlongrightarrow> c\<rbrakk> \<Longrightarrow> case(t,d,e,f,g) \<longlongrightarrow> c"
```

外加两条"元"性质：`canonical`（源第 63–68 行）说 `t ⟶ c` 里的 `c`
必是构造子形态；`substitute`（源第 71–72 行，库注释自嘲
`Should be derivable - but probably a bitch!`）说等量可代换。

实测打印（`examples/ccl/T70_ccl_lambda.thy` 第 74–76 行）——前四条是
构造子求值，后两组是 `case` 的分派与替换：

```text

  true \<longlongrightarrow> true
  false \<longlongrightarrow> false
  <?a,?b> \<longlongrightarrow> <?a,?b>
  lam x. ?b(x) \<longlongrightarrow> lam x. ?b(x)
```

```text

  \<lbrakk>?t \<longlongrightarrow> true; ?d \<longlongrightarrow> ?c\<rbrakk> \<Longrightarrow> case(?t, ?d, ?e, ?f, ?g) \<longlongrightarrow> ?c
  \<lbrakk>?t \<longlongrightarrow> false; ?e \<longlongrightarrow> ?c\<rbrakk> \<Longrightarrow> case(?t, ?d, ?e, ?f, ?g) \<longlongrightarrow> ?c
  \<lbrakk>?t \<longlongrightarrow> <?a,?b>; ?f(?a, ?b) \<longlongrightarrow> ?c\<rbrakk> \<Longrightarrow> case(?t, ?d, ?e, ?f, ?g) \<longlongrightarrow> ?c
  \<lbrakk>?t \<longlongrightarrow> lam x. ?b(x); ?g(?b) \<longlongrightarrow> ?c\<rbrakk> \<Longrightarrow> case(?t, ?d, ?e, ?f, ?g) \<longlongrightarrow> ?c
```

```text

  \<lbrakk>?t \<longlongrightarrow> ?c; ?c \<equiv> true \<Longrightarrow> ?u \<longlongrightarrow> ?v; ?c \<equiv> false \<Longrightarrow> ?u \<longlongrightarrow> ?v;
   \<And>a b. ?c \<equiv> <a,b> \<Longrightarrow> ?u \<longlongrightarrow> ?v; \<And>f. ?c \<equiv> lam x. f(x) \<Longrightarrow> ?u \<longlongrightarrow> ?v\<rbrakk>
  \<Longrightarrow> ?u \<longlongrightarrow> ?v
  \<lbrakk>?a \<equiv> ?a'; ?t(?a) \<longlongrightarrow> ?c(?a)\<rbrakk> \<Longrightarrow> ?t(?a') \<longlongrightarrow> ?c(?a')
```

这九条公理有一个重要特点：**它们只用来"读"语义，后面的推理一条
也不用**。库的全部引理都从 `caseB` 那组 β 规则出发。这是 Martin Coen
的明确设计——把操作语义（`⟶`）与指称语义（`=`）彻底分开，
`⟶` 负责"怎么算"，`=` 负责"算出什么"，两者之间的联系（soundness）
在本库里并没有被形式化，留给读者当作练习。

## 70.4 bot 与 apply：Ω 组合子与「应用即 case」

库源码第 78–83 行。`bot` 就是 λ 演算里最著名的发散项：

```isabelle
axiomatization where
  bot_def:         "bot == (lam x. x`x)`(lam x. x`x)" and
  apply_def:     "f ` t == case(f, bot, bot, \<lambda>x y. bot, \<lambda>u. u(t))"
```

`bot` 定义为 `(lam x. x`x)`(lam x. x`x)`（Ω）；而**应用不是原始
构造子，是用 `case` 定义出来的**：`f ` t` 对 `f` 分类讨论——是函数
就套上去（`λu. u(t)`），是 `bot` 就还是 `bot`（严格性）。这一手让
"应用"继承了 `case` 的全部规则，整部理论的公理数量骤减。`fix`
则循例定义（源第 82–83 行）。

实测三条定义（`examples/ccl/T70_ccl_lambda.thy` 第 94 行）：

```text

  bot \<equiv> (lam x. x ` x) ` (lam x. x ` x)
  ?f ` ?t \<equiv> case(?f, bot, bot, \<lambda>x y. bot, \<lambda>u. u(?t))
  fix(?f) \<equiv> (lam x. ?f(x ` x)) ` (lam x. ?f(x ` x))
```

行为随之而来：函数作用于参数是 β（`applyB`），发散项吞掉一切
（`applyBbot`），而 `fix` 展开成一步自调用（`fixB`，库源码
`src/CCL/Term.thy` 第 191–194 行）：

```text

  (lam x. ?b(x)) ` ?a = ?b(?a)
  bot ` ?a = bot
  fix(?f) = ?f(fix(?f))
```

K 组合子 `lam x. lam y. x` 先吃 `a` 再吃 `b`，两次 β 之后返回第一个
参数——"函数真的在算"（第 106–107 行）：

```isabelle
lemma beta_demo: "((lam x. lam y. x) ` a) ` b = a"
  by simp
```

```text

theorem beta_demo: (lam x y. x) ` ?a ` ?b = ?a
```

注意 `by simp` 一步过：`applyB` 已在 `termBs` 里挂成 simp 规则
（Term 理论第 272–276 行）。`fixB` **故意**没挂——它的右端还含
`fix`，挂上去 simp 会无限展开。要用它就地展开、配 `arg_cong`
（第 114–115 行）：

```isabelle
lemma fix_unfold_demo: "f(fix(f)) = f(f(fix(f)))"
  by (rule arg_cong [OF fixB])
```

```text

theorem fix_unfold_demo: ?f(fix(?f)) = ?f(?f(fix(?f)))
```

`arg_cong [OF fixB]` 的意思是：`fixB` 给出 `fix(f) = f(fix(f))`，
`arg_cong` 把等式两边同衬 `f(·)`。目标 `f(fix(f)) = f(f(fix(f)))`
正好是这个形状。另一个方向：`bot ` a = bot`（严格性）也是一步
（第 119–120 行）：

```isabelle
lemma apply_bot_demo: "bot ` a = bot"
  by simp
```

```text

theorem apply_bot_demo: bot ` ?a = bot
```

## 70.5 构造子的内射性与相异性

库源码第 218–225 行用一段 ML（`inj_rl_tac`）从 `caseB` 规则
**生成**内射律：

```isabelle
lemma ccl_injs:
  "<a,b> = <a',b'> \<longleftrightarrow> (a=a' \<and> b=b')"
  "\<And>b b'. (lam x. b(x) = lam x. b'(x)) \<longleftrightarrow> ((ALL z. b(z)=b'(z)))"
  by (inj_rl caseBs)
```

相异性（源第 233–299 行）更凶：`mk_dstnct_thms` 把
`bot/true/false/pair/lambda` 两两不等**全部机器生成**出来，挂进
`[simp]`。于是"不同构造子永不相等"在 simp 里免费。

实测（第 137–146 行）三条定理加一个副作用——示例里 `declare` 了
内射律的 simp 版本，于是 simp 抱怨重复：

```text

  <?a,?b> = <?a',?b'> \<longleftrightarrow> ?a = ?a' \<and> ?b = ?b'
  lam x. ?b(x) = lam x. ?b'(x) \<longleftrightarrow> (\<forall>z. ?b(z) = ?b'(z))
  \<lbrakk><?a,?b> = <?a',?b'>; \<lbrakk>?a = ?a'; ?b = ?b'\<rbrakk> \<Longrightarrow> ?R\<rbrakk> \<Longrightarrow> ?R
```

```text

Warning (line 140 of "/Volumes/mac004/code/programming/isabelle/examples/ccl/T70_ccl_lambda.thy"):
### Ignoring duplicate rewrite rule:
### <?a1,?b1> = <?a'1,?b'1> \<equiv> ?a1 = ?a'1 \<and> ?b1 = ?b'1
```

三条小证明（第 139–146 行）：

```isabelle
lemma pair_inj_demo: "<a,b> = <a',b'> \<Longrightarrow> a = a' \<and> b = b'"
  by (simp add: ccl_injs)

lemma lam_inj_demo: "lam x. b(x) = lam x. b'(x) \<Longrightarrow> ALL z. b(z) = b'(z)"
  by (simp add: ccl_injs)

lemma dstnct_demo: "<a,b> \<noteq> lam x. f(x)"
  by simp
```

```text
theorem pair_inj_demo: <?a,?b> = <?a',?b'> \<Longrightarrow> ?a = ?a' \<and> ?b = ?b'

theorem lam_inj_demo: lam x. ?b(x) = lam x. ?b'(x) \<Longrightarrow> \<forall>z. ?b(z) = ?b'(z)

theorem dstnct_demo: <?a,?b> \<noteq> lam x. ?f(x)
```

`dstnct_demo` 的 `by simp` 用的是 `mk_dstnct_thms` 生成的相异性
规则——注意它在 FOL 里可证是因为 `case` 公理强制了五个构造子的
自由性（free algebra），HOL 里要靠 `datatype` 的 `distinct` 子句。

配合 `exhaustion`（源第 488–491 行）与 `term_case`（源第 493–495 行），
任何关于"项长什么样"的命题都能五路穷举——`term_case` 就是无类型
世界的 `full_nat_case`：

```text

  ?t = bot \<or>
  ?t = true \<or> ?t = false \<or> (\<exists>a b. ?t = <a,b>) \<or> (\<exists>f. ?t = lam x. f(x))
  \<lbrakk>?P(bot); ?P(true); ?P(false); \<And>x y. ?P(<x,y>); \<And>b. ?P(lam x. b(x))\<rbrakk>
  \<Longrightarrow> ?P(?t)
```

`term_case` 演示（第 155–159 行）——五个前提，五路穷举：

```isabelle
lemma term_case_demo:
  assumes "P(bot)" and "P(true)" and "P(false)"
    and "\<And>x y. P(<x,y>)" and "\<And>b. P(lam x. b(x))"
  shows "P(t)"
  using assms by (rule term_case)
```

```text

theorem term_case_demo:
 \<lbrakk>?P(bot); ?P(true); ?P(false); \<And>x y. ?P(<x,y>); \<And>b. ?P(lam x. b(x))\<rbrakk>
 \<Longrightarrow> ?P(?t)
```

## 70.6 行为等价是最大不动点：SIM / POgen / EQgen

库源码第 89–105 行是全章的理论核心。先定义"两个项在一个关系 `R`
下同构"（`SIM`）：

```isabelle
definition SIM :: "[i,i,i set]\<Rightarrow>o"
  where
  "SIM(t,t',R) ==  (t=true \<and> t'=true) | (t=false \<and> t'=false) |
                  (\<exists>a a' b b'. t=<a,b> \<and> t'=<a',b'> \<and> <a,a'> : R \<and> <b,b'> : R) |
                  (\<exists>f f'. t=lam x. f(x) \<and> t'=lam x. f'(x) \<and> (ALL x.<f(x),f'(x)> : R))"
```

再由它长出两个"生成子"（源第 95–105 行）：`POgen`（预序）容忍
左边是 `bot`——`bot [= 任何东西`；`EQgen`（等价）则要求两边
同时 `bot`：

```isabelle
definition POgen :: "i set \<Rightarrow> i set"
  where "POgen(R) == {p. \<exists>t t'. p=<t,t'> \<and> (t = bot | SIM(t,t',R))}"

definition EQgen :: "i set \<Rightarrow> i set"
  where "EQgen(R) == {p. \<exists>t t'. p=<t,t'> \<and> (t = bot \<and> t' = bot | SIM(t,t',R))}"

definition PO :: "i set"
  where "PO == gfp(POgen)"

definition EQ :: "i set"
  where "EQ == gfp(EQgen)"
```

最后用两条公理把 `[=` / `=` 接回不动点（源第 128–130 行）：
`t [= t' ⟷ <t,t'> : PO`、`t = t' ⟷ <t,t'> : EQ`。也就是说
**行为等价被*定义*成最大不动点里的成员关系**，余归纳因此天然可用。

实测全部定义（第 195–196 行）：

```text

  SIM(?t, ?t', ?R) \<equiv>
  ?t = true \<and> ?t' = true \<or>
  ?t = false \<and> ?t' = false \<or>
  (\<exists>a a' b b'. ?t = <a,b> \<and> ?t' = <a',b'> \<and> <a,a'> : ?R \<and> <b,b'> : ?R) \<or>
  (\<exists>f f'. ?t = lam x. f(x) \<and> ?t' = lam x. f'(x) \<and> (\<forall>x. <f(x),f'(x)> : ?R))
  POgen(?R) \<equiv> {p. \<exists>t t'. p = <t,t'> \<and> (t = bot \<or> SIM(t, t', ?R))}
  EQgen(?R) \<equiv> {p. \<exists>t t'. p = <t,t'> \<and> (t = bot \<and> t' = bot \<or> SIM(t, t', ?R))}
  PO \<equiv> gfp(POgen)
  EQ \<equiv> gfp(EQgen)
```

```text

  ?t [= ?t' \<longleftrightarrow> <?t,?t'> : PO
  ?t = ?t' \<longleftrightarrow> <?t,?t'> : EQ
  ?t = ?t' \<longleftrightarrow> ?t [= ?t' \<and> ?t' [= ?t
```

第三条 `eq_iff` 是经典的"相等 = 互相小于等于"。单调性是余归纳的
门票（第 206 行）：

```text

  mono(POgen)
  mono(EQgen)
```

**为什么选最大不动点**：生成子 `POgen`/`EQgen` 往关系里加东西，
`gfp` 是所有"自洽近似"的并——恰好是"行为相容"的最大外延。
若选 `lfp`，得到的只会是有限深度的近似（`EQgen(EQgen(...{}))`），
永远装不下 `fix` 定义的无穷行为。这是本章与第 69 章 `lfp` 用法
的根本分野：**数据用最小不动点自底向上造，行为用最大不动点自顶
向下兜**。

## 70.7 poXH / eqXH：把不动点方程展开成结构规则

库源码第 323–339 行与第 441–463 行干的是同一件事：借第 69 章的
`def_gfp_Tarski`（`mono(f) ⟹ gfp(f) = f(gfp(f))`）把定义展开成
可直接读的刻画。先证单调性，再让 Tarski 方程穿过 `XHlemma1`：

```text

  mono(POgen)
  mono(EQgen)
```

```text

  <?t,?t'> : POgen(?R) \<longleftrightarrow>
  ?t = bot \<or>
  ?t = true \<and> ?t' = true \<or>
  ?t = false \<and> ?t' = false \<or>
  (\<exists>a a' b b'. ?t = <a,b> \<and> ?t' = <a',b'> \<and> <a,a'> : ?R \<and> <b,b'> : ?R) \<or>
  (\<exists>f f'. ?t = lam x. f(x) \<and> ?t' = lam x. f'(x) \<and> (\<forall>x. <f(x),f'(x)> : ?R))
  <?t,?t'> : EQgen(?R) \<longleftrightarrow>
  ?t = bot \<and> ?t' = bot \<or>
  ?t = true \<and> ?t' = true \<or>
  ?t = false \<and> ?t' = false \<or>
  (\<exists>a a' b b'. ?t = <a,b> \<and> ?t' = <a',b'> \<and> <a,a'> : ?R \<and> <b,b'> : ?R) \<or>
  (\<exists>f f'. ?t = lam x. f(x) \<and> ?t' = lam x. f'(x) \<and> (\<forall>x. <f(x),f'(x)> : ?R))
```

`poXH` 说的是：`t [= t'` 成立，当且仅当 `t = bot`，或两者同为
`true` / `false`，或同为序对且分量同在 `[=` 中，或同为 λ 且逐点
同在。`eqXH` 同构，只把 `bot` 一支改成两边皆 `bot`：

```text

  ?t [= ?t' \<longleftrightarrow>
  ?t = bot \<or>
  ?t = true \<and> ?t' = true \<or>
  ?t = false \<and> ?t' = false \<or>
  (\<exists>a a' b b'. ?t = <a,b> \<and> ?t' = <a',b'> \<and> a [= a' \<and> b [= b') \<or>
  (\<exists>f f'. ?t = lam x. f(x) \<and> ?t' = lam x. f'(x) \<and> (\<forall>x. f(x) [= f'(x)))
  ?t = ?t' \<longleftrightarrow>
  ?t = bot \<and> ?t' = bot \<or>
  ?t = true \<and> ?t' = true \<or>
  ?t = false \<and> ?t' = false \<or>
  (\<exists>a a' b b'. ?t = <a,b> \<and> ?t' = <a',b'> \<and> a = a' \<and> b = b') \<or>
  (\<exists>f f'. ?t = lam x. f(x) \<and> ?t' = lam x. f'(x) \<and> (\<forall>x. f(x) = f'(x)))
```

注意 `t = bot` 在 `poXH` 里**不要求 `t' = bot`**——这正是"发散
模拟一切"的相异性所在。

四条读出的小结论（第 217 行 `thm po_bot bot_poleast po_pair po_lam`）：

```text

  bot [= ?b
  ?a [= bot \<Longrightarrow> ?a = bot
  <?a,?b> [= <?a',?b'> \<longleftrightarrow> ?a [= ?a' \<and> ?b [= ?b'
  lam x. ?f(x) [= lam x. ?f'(x) \<longleftrightarrow> (\<forall>x. ?f(x) [= ?f'(x))
```

`po_bot`（bot 是预序底元）、`bot_poleast`（只有 bot 能 `[= bot`，
即"不比底元更小"）、`po_pair` / `po_lam`（序对与 λ 的规则可当
双向 iff 用）。`=` 一侧对应 `eq_iff`：相等就是互相 `[=`：

```text
  ?t = ?t' \<longleftrightarrow> ?t [= ?t' \<and> ?t' [= ?t
```

最后是两个常用谓词（第 226 行 `thm Trm_iff Dvg_iff`）：
`Trm(t)` 表示"t 会终止"（`t ≠ bot`），`Dvg(t)` 表示发散：

```text

  Trm(?t) \<longleftrightarrow> ?t \<noteq> bot
  Dvg(?t) \<longleftrightarrow> ?t = bot
```

## 70.8 余归纳实战一：`po_coinduct` 与 `bot [= t`

库源码第 427–430 行给出预序的余归纳规则——它正是第 69 章
`coinduct` 的实例：

```isabelle
lemma po_coinduct: "\<lbrakk><t,u> : R; R <= POgen(R)\<rbrakk> \<Longrightarrow> t [= u"
  apply (rule PO_def [THEN def_coinduct, THEN PO_iff [THEN iffD2]])
   apply assumption+
  done
```

用法与 HOL 的 `coinduct` 一式一样：找一个把 `<t,u>` 装进去的关系
`R`，再证 `R` 在 `POgen` 下封闭。下面证 `bot [= t`
（`examples/ccl/T70_ccl_lambda.thy` 第 245–254 行）：取
`R = {<bot,t>}`，第一件事显然；第二件事里 `POgen` 的 `t = bot`
析取支正好兜住：

```isabelle
lemma po_bot_demo: "bot [= t"
proof (rule po_coinduct[of _ _ "{<bot,t>}"])
  show "<bot,t> : {<bot,t>}" by simp
  show "{<bot,t>} <= POgen({<bot,t>})"
  proof (rule subsetI)
    fix p assume hp: "p : {<bot,t>}"
    then have pz: "p = <bot,t>" by simp
    then show "p : POgen({<bot,t>})" by (simp add: POgenXH)
  qed
qed
```

```text
theorem po_bot_demo: bot [= ?t

show <bot,t> : {<bot,t>}

have pz: p = <bot,t>

show p : POgen({<bot,t>})

show {<bot,t>} <= POgen({<bot,t>})
```

四步对应两条义务：**装得进**（`<bot,t> : R`）与**自洽**
（`R <= POgen(R)`）。第二条义务的证明结构是"任取 `p : R` → 用
`POgenXH` 核对五路析取 → 命中 `t = bot` 支"。这个模式在 CCL 的
每一条余归纳证明里重复出现，值得固化成本能。

顺带说明：`POgen` 比 `EQgen` 弱的根源就在 `t = bot` 这一支——它
让 `bot` 单方面模拟任何项，所以 `[=` 只是预序；`=` 要两边同时
发散，才是真正的等价关系。

## 70.9 余归纳实战二：`eq_coinduct3` 证「点等则 lam 等」

库源码第 465–480 行。弱的 `eq_coinduct` 要求 `R <= EQgen(R)`，
可 R 通常装不下"展开一层"才出现的对；Martin Coen 的强化版把 `R`
自己和 `EQ` 一起塞进生成子，再取**最小**不动点：

```isabelle
lemma eq_coinduct3:
  "\<lbrakk><t,u> : R;  R <= EQgen(lfp(\<lambda>x. EQgen(x) Un R Un EQ))\<rbrakk> \<Longrightarrow> t = u"
  apply (rule EQ_def [THEN def_coinduct3, THEN EQ_iff [THEN iffD2]])
  apply (rule EQgen_mono | assumption)+
  done
```

库还把它包成方法（源第 476–480 行），`eq_coinduct3 "{p. ...}"`
一把梭。下面不用方法，把两条义务拆开写清楚。要证的命题：**两个
函数逐点相等，则两个 λ 相等**。余归纳关系必须比目标大一圈——
既要装下两个 λ 本身，也要装下它们展开后出现的每一对
`<f(z),f'(z)>`：

```isabelle
lemma lam_eq_demo:
  assumes h: "\<And>x. f(x) = f'(x)"
  shows "lam x. f(x) = lam x. f'(x)"
proof (eq_coinduct3 "{p. EX z. p = <f(z), f'(z)>} Un {p. p = <lam x. f(x), lam x. f'(x)>}")
  show "<lam x. f(x), lam x. f'(x)> : {p. EX z. p = <f(z), f'(z)>} Un {p. p = <lam x. f(x), lam x. f'(x)>}"
    by simp
next
  let ?R = "{p. EX z. p = <f(z), f'(z)>} Un {p. p = <lam x. f(x), lam x. f'(x)>}"
  let ?L = "lfp(\<lambda>x. EQgen(x) Un ?R Un EQ)"
  have R_le_L: "?R <= ?L"
    by (rule lfp_greatest) blast
  have hL: "\<And>x. <f(x),f'(x)> : ?L"
    using R_le_L by (blast intro: UnI1 CollectI)
  have EQ_le_L: "EQ <= ?L"
    by (rule lfp_greatest) blast
  have refl_L: "\<And>a. <a,a> : ?L"
    using EQ_le_L by (blast dest: subsetD intro: EQ_iff [THEN iffD1])
  have TT: "\<And>t. <t,t> : EQgen(?L)"
  proof -
    fix t show "<t,t> : EQgen(?L)"
    proof (rule term_case[where P = "\<lambda>t. <t,t> : EQgen(?L)"])
      show "<bot,bot> : EQgen(?L)" by (simp add: EQgenXH)
      show "<true,true> : EQgen(?L)" by (simp add: EQgenXH)
      show "<false,false> : EQgen(?L)" by (simp add: EQgenXH)
      fix x y show "<<x,y>,<x,y>> : EQgen(?L)"
        by (simp add: EQgenXH refl_L)
      fix b show "<lam x. b(x), lam x. b(x)> : EQgen(?L)"
        by (auto simp add: EQgenXH intro: refl_L)
    qed
  qed
  show "?R <= EQgen(?L)"
  proof (rule Un_least)
    show "{p. EX z. p = <f(z), f'(z)>} <= EQgen(?L)"
    proof (rule subsetI)
      fix p assume hp: "p : {p. EX z. p = <f(z), f'(z)>}"
      then obtain z where pz: "p = <f(z), f'(z)>" by blast
      with h have "p = <f(z), f(z)>" by simp
      then show "p : EQgen(?L)" by (simp add: TT)
    qed
    show "{p. p = <lam x. f(x), lam x. f'(x)>} <= EQgen(?L)"
    proof (rule subsetI)
      fix p assume hp: "p : {p. p = <lam x. f(x), lam x. f'(x)>}"
      then have pz: "p = <lam x. f(x), lam x. f'(x)>" by blast
      have e: "EX f'' f'''. lam x. f(x) = lam x. f''(x)
            \<and> lam x. f'(x) = lam x. f'''(x) \<and> (ALL x. <f''(x),f'''(x)> : ?L)"
      proof (rule exI[of _ f], rule exI[of _ f'])
        show "lam x. f(x) = lam x. f(x) \<and> lam x. f'(x) = lam x. f'(x)
            \<and> (ALL x. <f(x),f'(x)> : ?L)"
          by (simp add: hL)
      qed
      have key: "<lam x. f(x), lam x. f'(x)> : EQgen(?L)"
      proof (rule EQgenXH [THEN iffD2])
        show "lam x. f(x) = bot \<and> lam x. f'(x) = bot
            | lam x. f(x) = true \<and> lam x. f'(x) = true
            | lam x. f(x) = false \<and> lam x. f'(x) = false
            | (EX a a' b b'. lam x. f(x) = <a,b> \<and> lam x. f'(x) = <a',b'>
                \<and> <a,a'> : ?L \<and> <b,b'> : ?L)
            | (EX f'' f'''. lam x. f(x) = lam x. f''(x) \<and> lam x. f'(x) = lam x. f'''(x)
                \<and> (ALL x. <f''(x),f'''(x)> : ?L))"
          by (rule disjI2 [OF disjI2 [OF disjI2 [OF disjI2 [OF e]]]])
      qed
      from pz key show "p : EQgen(?L)" by simp
    qed
  qed
qed
```

```text
theorem lam_eq_demo:
 (\<And>x. ?f(x) = ?f'(x)) \<Longrightarrow> lam x. ?f(x) = lam x. ?f'(x)

show <lam x. f(x),lam x. f'(x)> :
     {p. \<exists>z. p = <f(z),f'(z)>} Un {p. p = <lam x. f(x),lam x. f'(x)>}

have R_le_L:
       {p. \<exists>z. p = <f(z),f'(z)>} Un {p. p = <lam x. f(x),lam x. f'(x)>} <=
       lfp(\<lambda>x. EQgen(x) Un
               ({p. \<exists>z. p = <f(z),f'(z)>} Un
                {p. p = <lam x. f(x),lam x. f'(x)>}) Un
               EQ)
```

中间还夹着两条 simp 的抱怨（第 293、297 行 `declare` 了 CCL 已
注册过的规则方向）：

```text

Warning (line 293 of "/Volumes/mac004/code/programming/isabelle/examples/ccl/T70_ccl_lambda.thy"):
### Rule already declared as safe introduction (intro!)
### ?P(?a) \<Longrightarrow> ?a : Collect(?P)
```

```text

Warning (line 297 of "/Volumes/mac004/code/programming/isabelle/examples/ccl/T70_ccl_lambda.thy"):
### Rule already declared as unsafe elimination (elim)
### \<lbrakk>?A <= ?B; ?c : ?A\<rbrakk> \<Longrightarrow> ?c : ?B
```

拆开看第二义务做了什么：

- `R_le_L` 与 `EQ_le_L` 都是 `lfp_greatest` 的一行推论——"任何
  前不动点都装得下 `R` 与 `EQ`"，于是最小不动点 `?L` 也装得下；
- 有了 `refl_L`（"任何项与自己相关"，由 `EQ_le_L` + `EQ_iff` 得出）
  和 `hL`（"点对相关"），`R <= EQgen(?L)` 就只是逐构造子核对：
  序对分支用 `refl_L`，λ 分支用 `hL`；
- `TT` 把 `term_case` 用 `where P = "λt. <t,t> : EQgen(?L)"` 显式
  绑定谓词（否则 `rule term_case` 会把高阶变量 `P` 绑到序对
  `<t,t>` 上——见坑位 4）；
- `disjI2` 四连发是把五路析取里的前四路（bot/true/false/序对）
  留给 `simp` 已经证伪的相异性规则，只留 λ 这一路。

这就是第 72 章证无限列表等式的主力武器的完整机械结构。

## 70.10 Term 理论：把常用程序构造搬进 CCL

库源码 `src/CCL/Term.thy` 在第 12–152 行用 `case` 定义了一整套
"标准库"：布尔 `if`、和类型 `inl/inr`、序对投影
`split/fst/snd/thd`、自然数 `zero/succ/ncase/nrec`、列表
`nil/cons/lcase/lrec`、迭代 `napply`，以及 `let1` / `letrec`
（递归！）。定义一律一行，规则一律成组。

三组定义实测（`examples/ccl/T70_ccl_lambda.thy` 第 367–369 行）：

```text

  if ?b then ?t else ?u \<equiv> case(?b, ?t, ?u, \<lambda>x y. bot, \<lambda>v. bot)
  inl(?a) \<equiv> <true,?a>
  inr(?b) \<equiv> <false,?b>
  split(?t, ?f) \<equiv> case(?t, bot, bot, ?f, \<lambda>u. bot)
  when(?t, ?f, ?g) \<equiv> split(?t, \<lambda>b x. if b then ?f(x) else ?g(x))
  fst(?t) \<equiv> split(?t, \<lambda>x y. x)
  snd(?t) \<equiv> split(?t, \<lambda>x y. y)
  thd(?t) \<equiv> split(?t, \<lambda>x p. split(p, \<lambda>y z. z))
```

```text

  zero \<equiv> inl(one)
  succ(?n) \<equiv> inr(?n)
  ncase(?n, ?b, ?c) \<equiv> when(?n, \<lambda>x. ?b, ?c)
  let1(?t, ?f) \<equiv>
  case(?t, ?f(true), ?f(false), \<lambda>x y. ?f(<x,y>), \<lambda>u. ?f(lam x. u(x)))
  letrec(?h, ?b) \<equiv> ?b((`)(fix(\<lambda>f. lam x. ?h(x, (`)(f)))))
  [] \<equiv> inl(one)
  ?h $ ?t \<equiv> inr(<?h,?t>)
```

```text

  lcase(?l, ?b, ?c) \<equiv> when(?l, \<lambda>x. ?b, \<lambda>y. split(y, ?c))
  lrec(?l, ?b, ?c) \<equiv>
  letrec g x be lcase(x, ?b, \<lambda>h t. ?c(h, t, g(t))) in g(?l)
  ?f ^ ?n ` ?a \<equiv> nrec(?n, ?a, \<lambda>x. ?f)
```

三条读法要点：

1. **`zero ≡ inl(one)`**：自然数编码成 `bool + i` 的左注入。
   `succ(n) ≡ inr(n)` 是右注入——所以 `ncase(n,b,c)` 走 `when`
   （和类型的 case），基例 `b`、递归步 `c`。
2. **列表同理**：`[] ≡ inl(one)`，`h $ t ≡ inr(<h,t>>`。注意
   `cons` 的中缀是 `$`，而**应用**的中缀是 `` ` ``——两个符号
   极易看混。
3. **`letrec` 就是 Y 组合子的包装**：
   `b((`)(fix(λf. lam x. h(x, (`)(f)))))`——用第 70.4 节的 `fix`
   把递归函数造出来，这正是无类型 λ 演算处理递归的标准手法。

第 166–276 行给出全套 β 规则（`termBs`），命名规律与第 69 章的
I/D/E 一致：`splitB` 是 β，`splitBbot` 是严格性（`bot` 穿到底）：

```isabelle
lemma splitB: "split(<a,b>,h) = h(a,b)"
  and splitBbot: "split(bot,h) = bot"
  unfolding data_defs by beta_rl+
```

`beta_rl` 是库自带的战术（源第 203–211 行）：在 `rawBs` 上跑
simp，再把 `letrecB`（源第 196–199 行）当**循环规则**喂进去——
递归定义一步展开一层，不会死循环。`fixB` / `letrecB` 的证明本身
就三行，靠的全是 `ssubst` 和 `applyB`。

七组 β 规则实测（第 385–391 行）——每组都是"构造子 + bot"三件套：

```text

  split(<?a,?b>, ?h) = ?h(?a, ?b)
  split(bot, ?h) = bot
  fst(<?a,?b>) = ?a
  snd(<?a,?b>) = ?b
  thd(<?a,<?b,?c>>) = ?c
```

```text

  if true then ?t else ?u = ?t
  if false then ?t else ?u = ?u
  if bot then ?t else ?u = bot
  when(inl(?a), ?t, ?u) = ?t(?a)
  when(inr(?a), ?t, ?u) = ?u(?a)
  when(bot, ?t, ?u) = bot
```

```text

  ncase(zero, ?t, ?u) = ?t
  ncase(succ(?n), ?t, ?u) = ?u(?n)
  ncase(bot, ?t, ?u) = bot
```

```text

  nrec(zero, ?t, ?u) = ?t
  nrec(succ(?n), ?t, ?u) = ?u(?n, nrec(?n, ?t, ?u))
  nrec(bot, ?t, ?u) = bot
```

```text

  lcase([], ?t, ?u) = ?t
  lcase(?x $ ?xs, ?t, ?u) = ?u(?x, ?xs)
  lcase(bot, ?t, ?u) = bot
```

```text

  lrec([], ?t, ?u) = ?t
  lrec(?x $ ?xs, ?t, ?u) = ?u(?x, ?xs, lrec(?xs, ?t, ?u))
  lrec(bot, ?t, ?u) = bot
```

```text

  ?f ^ zero ` ?a = ?a
  ?f ^ succ(?n) ` ?a = ?f(?f ^ ?n ` ?a)
```

外加一组"通用"规则（第 392 行 `thm letB applyB applyBbot fixB
letrecB`）——`letrecB` 的形态值得细看，它就是第 72 章全部
`letrec` 程序的展开引擎：

```text

  ?t \<noteq> bot \<Longrightarrow> let1(?t, ?f) = ?f(?t)
  (lam x. ?b(x)) ` ?a = ?b(?a)
  bot ` ?a = bot
  fix(?f) = ?f(fix(?f))
  letrec g x be ?h(x, g) in g(?a) =
  ?h(?a, \<lambda>y. letrec g x be ?h(x, g) in g(y))
```

这些规则挂成 simp 之后，"执行"就是重写。四条演示三个层次
（第 397–413 行，中间隔着库自己的注释，故分两段贴出）：

```isabelle
lemma fst_demo: "fst(<a,b>) = a"
  by simp

lemma if_demo: "if true then t else u = t"
  by simp
```

```isabelle
lemma nrec_eval_demo: "nrec(succ(succ(zero)), one, \<lambda>x g. succ(g)) = succ(succ(one))"
  by simp

lemma napply_demo: "(\<lambda>x. succ(x)) ^ succ(succ(zero)) ` zero = succ(succ(zero))"
  by simp
```

```text

theorem fst_demo: fst(<?a,?b>) = ?a

theorem if_demo: if true then ?t else ?u = ?t

theorem
  nrec_eval_demo: nrec(succ(succ(zero)), one, \<lambda>x. succ) = succ(succ(one))

theorem napply_demo: succ ^ succ(succ(zero)) ` zero = succ(succ(zero))
```

`nrec(succ(succ(zero)), one, λx g. succ(g))` 读作"以 `one` 为
基例、每步套一层 `succ` 的两层递归"——算出来正是
`succ(succ(one))`，即 CCL 世界里的 `2`。`napply_demo` 的
`succ ^ 2 ` zero` 同理。这就是"计算逻辑"的字面意思：
**定理的陈述就是程序，证明就是求值**。

`term_injs`（源第 281–286 行）与 `ccl_injs` 同款，把
`inl/inr/succ/cons` 的内射性也机器生成出来；`term_porews`
（源第 300–305 行）则把数据构造子的 `[=` 规则配齐，供第 72 章的
流等式证明使用（第 419 行 `thm`）：

```text

  inl(?a) = inl(?a') \<longleftrightarrow> ?a = ?a'
  inr(?a) = inr(?a') \<longleftrightarrow> ?a = ?a'
  succ(?a) = succ(?a') \<longleftrightarrow> ?a = ?a'
  ?a $ ?b = ?a' $ ?b' \<longleftrightarrow> ?a = ?a' \<and> ?b = ?b'
  inl(?a) [= inl(?a') \<longleftrightarrow> ?a [= ?a'
  inr(?b) [= inr(?b') \<longleftrightarrow> ?b [= ?b'
  succ(?n) [= succ(?n') \<longleftrightarrow> ?n [= ?n'
  ?x $ ?xs [= ?x' $ ?xs' \<longleftrightarrow> ?x [= ?x' \<and> ?xs [= ?xs'
```

## 70.11 坑位清单（实测）

1. **CCL 不是 HOL**：没有 `value`、没有 `fun` 高阶数据类型、没有
   `QuickCheck`。所有项只有一个类型 `i`，"多态"靠类型类 `prog`
   的排序约束表达，写 `'a::prog` 才显式。
2. **`` ` `` 应用必须写括号**：`f ` t` 不是 `f t`；
   `lam x. b(x)` 的 `b(x)` 同理（FOL 旧应用语法，第 47/69 章同款坑）。
3. **`fixB` / `letrecB` 不能进 simp 集**：右端仍含 `fix` /
   `letrec`，挂上去无限展开。库的解法是 `beta_rl` 把 `letrecB`
   注册成 simp 的**循环规则**（`set_loop`）。
4. **`rule term_case` 会把高阶变量 `P` 绑错**：目标 `<t,t> : ...`
   与结论 `P(?t)` 合一有两种解，默认那一种是对**序对** `<t,t>`
   做案例分析。必须 `where P = "λt. ..."` 显式给出（本章 `TT` 的证法）。
5. **`eq_coinduct3 "{p. ...}"` 与 `rule eq_coinduct3[of ...]`
   是两回事**：前者是 `method_setup` 注册的方法，直接吃关系项；
   后者是引理，`of` 按变量出现顺序填（第一个是 `t` 不是 `R`），
   填错报类型冲突。`po_coinduct` 没有方法版，只能
   `rule po_coinduct[of _ _ R]`。
6. **`EQgenXH` 的析取支是关于 `t` 与 `t'` 两个分量**，不是关于
   序对 `<t,t'>`：写成 `<lam...,lam...> = bot` 会被 simp 的相异性
   规则直接判假，报 `Failed to finish: False`。
7. **FOL 没有 `disjI3` 以上的析取引入规则**，五路析取只能
   `disjI2 [OF disjI2 [OF ...]]` 叠，或者先 `simp` 把前几路证伪
   再收尾。
8. **`EQ_refl` 在 `Type` 理论里**，不在 `CCL`；在 `CCL` 里要
   `EQ_iff [THEN iffD1]` 配 `refl` 用。
9. **`ccl_dstncts` 是机器生成的 simp 规则**，所以
   `<a,b> = lam x. f(x)` 这类目标 simp 一步证伪；但**生成它们的
   ML 在理论加载时跑**，改库源码要连 ML 一起重放。
10. **`class prog` 与 `default_sort prog` 在 Isabelle2026 仍然
    有效**，但这是 1993 年的类型类用法：排序推断失败时报的是
    `prog` 而非具体类型，读报错要先想"哪个类型变量该有 `prog` 排序"。
## 70.12 与其他章的接口

- 第 69 章：`gfp` + `coinduct3` 是本章行为等价的全部机器；
  `lfp` 在 `eq_coinduct3` 里反转为辅助角色。
- 第 71 章：把 `Nat`/`List` 从"编码"升级为"类型即项集"，
  `ncaseT`/`nrecT` 是本章 `ncase`/`nrec` 的类型化版本。
- 第 72 章：四个 ex/ 理论用本章全部机制写真正的程序，
  并用 `eq_coinduct3` 证流等式。


上一章：[69 · CCL（一）：Set、Lfp、Gfp、Trancl](69-ccl-set.md) ｜ 下一章：[71 · CCL（三）：Term、Type、Hered、Wfd、Fix](71-ccl-type.md) ｜ 返回：[README](../README.md)
