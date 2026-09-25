# 16 · 霍尔逻辑与 wp

对应示例：`../examples/S16_hoare_wp.thy`

## 16.1 内核证明的主语言：霍尔三元组

前面十五章讲内核"是什么"，从这一章起讲"怎么证明它"。
l4v 的主语言是霍尔逻辑在非确定性状态单子上的实例化，那个单子的类型在
`l4v/lib/Monads/nondet/Nondet_Monad.thy` 第 36 行：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_Monad.thy 第 36 行 -->
```text
type_synonym ('s, 'a) nondet_monad = "'s \<Rightarrow> ('a \<times> 's) set \<times> bool"
```

"给定起始状态，返回一组可能的（结果，新状态），外加一个失败位"。
失败位的语义就写在同一文件第 31--34 行的注释里：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_Monad.thy 第 31--34 行 -->
```text
  a failure flag. Each element in the set is a potential result of the
  computation. The flag is @{const True} if there is an execution path
  in the computation that may have failed. Conversely, if the flag is
  @{const False}, none of the computations resulting in the returned
```

也就是说：失败位为真 = **存在**一条会失败的路径；结果集合里的每个元素都要满足后条件。
示例里把五个基本算子重抄了一遍（加 `k` 前缀以免和本章引理撞名），
它们对应 l4v 的 `return`/`bind`/`fail`/`get`/`put`，依次在第 61、73、133、90、93 行：

```text
consts
  kbind ::
    "('s \<Rightarrow> ('a \<times> 's) set \<times> bool)
     \<Rightarrow> ('a \<Rightarrow> 's \<Rightarrow> ('b \<times> 's) set \<times> bool) \<Rightarrow> 's \<Rightarrow> ('b \<times> 's) set \<times> bool"
```

## 16.2 三元组不管失败：`valid` 与 `no_fail` 是两件事

这是本章最容易搞错的一点。`valid`
（定义在 `l4v/lib/Monads/nondet/Nondet_VCG.thy` 第 37 行）里**没有**失败位那一半：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_VCG.thy 第 37--40 行 -->
```text
definition valid ::
  "('s \<Rightarrow> bool) \<Rightarrow> ('s,'a) nondet_monad \<Rightarrow> ('a \<Rightarrow> 's \<Rightarrow> bool) \<Rightarrow> bool"
  ("\<lbrace>_\<rbrace>/ _ /\<lbrace>_\<rbrace>") where
  "\<lbrace>P\<rbrace> f \<lbrace>Q\<rbrace> \<equiv> \<forall>s. P s \<longrightarrow> (\<forall>(r,s') \<in> fst (f s). Q r s')"
```

非失败是**另一个文件里的另一个谓词**：
`l4v/lib/Monads/nondet/Nondet_No_Fail.thy` 第 24 行的 `no_fail`。

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_No_Fail.thy 第 24--25 行 -->
```text
definition no_fail :: "('s \<Rightarrow> bool) \<Rightarrow> ('s,'a) nondet_monad \<Rightarrow> bool" where
  "no_fail P m \<equiv> \<forall>s. P s \<longrightarrow> \<not>snd (m s)"
```

定义前面那段注释（`l4v/lib/Monads/nondet/Nondet_VCG.thy` 第 32--36 行）
把后果说得非常直白：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_VCG.thy 第 32--36 行 -->
```text
  the monad satisfy the postcondition. Note that if the computation returns
  the empty set, the triple is trivially valid. This means @{term "assert P"}
  does not require us to prove that @{term P} holds, but rather allows us
  to assume @{term P}! Proving non-failure is done via a separate predicate and
  calculus (see theory @{text Nondet_No_Fail}).\<close>
```

于是本章的第一条定理是反直觉的那条（实测）：

```text
theorem fail_satisfies_every_triple: valid ?P kfail ?Q
```

```text
theorem fail_is_not_no_fail: ?P ?s \<Longrightarrow> \<not> no_fail ?P kfail
```

两条合起来才是日常要证的东西：
"跑得到的状态都满足后条件"**并且**"这些输入上不会失败"。
`return` 那一半两边都白送（实测）：

```text
theorem no_fail_top_of_return: no_fail ?P (kreturn ?x)
```

顺序组合的非失败要**借一次三元组**才推得过去，只有 `no_fail` 是推不出 `no_fail` 的。
l4v 里这条是 `l4v/lib/Monads/nondet/Nondet_No_Fail.thy` 第 61 行的规则：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_No_Fail.thy 第 61--64 行 -->
```text
lemma no_fail_bind[wp]:
  "\<lbrakk> \<And>rv. no_fail (R rv) (g rv); \<lbrace>Q\<rbrace> f \<lbrace>R\<rbrace>; no_fail P f \<rbrakk> \<Longrightarrow> no_fail (P and Q) (f >>= (\<lambda>rv. g rv))"
  unfolding no_fail_def bind_def
  using post_by_hoare by fastforce
```

示例里的同形版本（实测），注意结论的前条件是**两个前条件的合取**：

```text
theorem
  no_fail_bind:
    \<lbrakk>no_fail ?P ?m; valid ?Q ?m ?R; \<And>r. no_fail (?R r) (?f r)\<rbrakk>
    \<Longrightarrow> no_fail (\<lambda>s. ?P s \<and> ?Q s) (kbind ?m ?f)
```

## 16.3 最弱前置条件：`wp` 是规则集，不是函数

把 `valid` 对前置条件求"最弱解"就是 `wp`，它同样**不看**失败位；
失败位有自己的 `wpnf`。三组关系（实测）：

```text
theorem valid_iff_wp: valid ?P ?m ?Q = (\<forall>s. ?P s \<longrightarrow> wp ?m ?Q s)
```

```text
theorem wp_is_valid: valid (wp ?m ?Q) ?m ?Q
```

```text
theorem wp_is_the_weakest: \<lbrakk>valid ?P ?m ?Q; ?P ?s\<rbrakk> \<Longrightarrow> wp ?m ?Q ?s
```

前后两条合起来正是"最弱"的定义：它自己够用，且任何别的前置条件都比它强。
下面这对把 16.2 的教训搬到了逐点层面——空返回时 `wp` 真、`wpnf` 假：

```text
theorem wp_fail_is_true: wp kfail ?Q ?s
```

```text
theorem wpnf_of_fail_is_false: \<not> wpnf kfail ?Q ?s
```

```text
theorem
  valid_no_fail_iff_wpnf:
    (valid ?P ?m ?Q \<and> no_fail ?P ?m) = (\<forall>s. ?P s \<longrightarrow> wpnf ?m ?Q s)
```

**但是**：内核 `.thy` 里满天飞的 `apply wp` 不是这里这个 `wp`。
 Isabelle 层面 `wp` 是一个**方法**，本体在
`l4v/lib/Monads/wp/WP-method.ML`，行为完全由三族规则决定
（`l4v/lib/Monads/wp/WP_README.thy` 第 19--23 行讲的正是这套流程）：

<!-- 源码块：l4v/lib/Monads/wp/WP_README.thy 第 19--23 行 -->
```text
The usual strategy for proving a Hoare triple is via backward propagation from
the postcondition. The initial step is to replace the current precondition with
an Isabelle schematic variable using a precondition weakening rule such as
@{thm hoare_pre}. This schematic variable is progressively instantiated by applying
weakest precondition rules as introduction rules. The implication between the
```

规则分三档：`[wp]`（目标规则）、`[wp_comb]`（组合子，比如后条件是合取时先拆一半）、
`[wp_split]`（分情况）。选规则是**后加入的优先**（第 40--42 行）：

<!-- 源码块：l4v/lib/Monads/wp/WP_README.thy 第 40--42 行 -->
```text
Selection from a set of rules ('wp' and 'wp_split') or combinators ('wp_comb')
occurs in last-to-first order, i.e. always preferring to apply the theorem most
recently added to a set.
```

这就是"为什么加了条 `[wp]` 引理之后别的证明突然变了"的官方解释。
兄弟方法 `wpc` 自己造 case split 规则（第 71--72 行），
`wpfix` 处理特征变元统一失败的四种常见形状（第 74--75 行），
`wpsimp` 是把它们和化简交替跑的现成组合
（`l4v/lib/Monads/wp/WP_README.thy` 第 104--105 行把它概括成
`'(wpfix|wp|wpc|clarsimp)+'`，本体在
`l4v/lib/Monads/wp/WPSimp.thy` 第 16--19 行）：

<!-- 源码块：l4v/lib/Monads/wp/WP_README.thy 第 71--72 行 -->
```text
The @{method wpc} tool synthesises the needed case split rules for datatype case
statements in the function bodies in the Hoare triples.
```

<!-- 源码块：l4v/lib/Monads/wp/WPSimp.thy 第 16--19 行 -->
```text
method wpsimp uses wp wp_del simp simp_del split split_del cong comb comb_del =
  ((determ \<open>wpfix | wp add: wp del: wp_del comb: comb comb del: comb_del | wpc |
            clarsimp_no_cond simp: simp simp del: simp_del split: split split del: split_del cong: cong |
            clarsimp simp: simp simp del: simp_del split: split split del: split_del cong: cong\<close>)+)[1]
```

## 16.4 基本规则与"保住不变式"

日常用的就是这几条（实测）：

```text
theorem valid_return: valid ?P (kreturn ?x) ?Q = (\<forall>s. ?P s \<longrightarrow> ?Q ?x s)
```

```text
theorem
  valid_bind:
    \<lbrakk>valid ?P ?m ?Q; \<forall>r. valid (?Q r) (?f r) ?R\<rbrakk>
    \<Longrightarrow> valid ?P (kbind ?m ?f) ?R
```

```text
theorem
  strengthen_pre: \<lbrakk>\<forall>s. ?P' s \<longrightarrow> ?P s; valid ?P ?m ?Q\<rbrakk> \<Longrightarrow> valid ?P' ?m ?Q
```

```text
theorem
  weaken_post: \<lbrakk>\<forall>r s. ?Q r s \<longrightarrow> ?R r s; valid ?P ?m ?Q\<rbrakk> \<Longrightarrow> valid ?P ?m ?R
```

`strengthen_pre` 的方向要盯住：它说的是"`P'` 更小时也能用"，
也就是**允许你多加假设**。l4v 的对应物在
`l4v/lib/Monads/nondet/Nondet_VCG.thy` 第 93 行，第 97 行是它的旋转形式：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_VCG.thy 第 93--97 行 -->
```text
lemma hoare_pre_imp:
  "\<lbrakk> \<And>s. P s \<Longrightarrow> P' s; \<lbrace>P'\<rbrace> f \<lbrace>Q\<rbrace> \<rbrakk> \<Longrightarrow> \<lbrace>P\<rbrace> f \<lbrace>Q\<rbrace>"
  by (fastforce simp: valid_def)

lemmas hoare_weaken_pre = hoare_pre_imp[rotated]
```

第 112 行那组 `lemmas hoare_pre [wp_pre]` 就是 16.3 说的
"先把前置条件换成一个特征变元"那一步。

"后条件与前条件相同"这种三元组在 l4v 里有缩写，
`l4v/lib/Monads/nondet/Nondet_VCG.thy` 第 45--48 行：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_VCG.thy 第 45--48 行 -->
```text
abbreviation invariant ::
  "('s,'a) nondet_monad \<Rightarrow> ('s \<Rightarrow> bool) \<Rightarrow> bool"
  ("_ \<lbrace>_\<rbrace>" [59,0] 60) where
  "invariant f P \<equiv> \<lbrace>P\<rbrace> f \<lbrace>\<lambda>_. P\<rbrace>"
```

示例里叫 `invariant_on`，三条规则（实测）：

```text
theorem invariant_on_return: invariant_on (kreturn ?x) ?P
```

```text
theorem invariant_on_put: ?P ?s' \<Longrightarrow> invariant_on (kput ?s') ?P
```

```text
theorem invariant_on_bind:
 \<lbrakk>invariant_on ?m ?P; \<And>r. invariant_on (?f r) ?P\<rbrakk>
 \<Longrightarrow> invariant_on (kbind ?m ?f) ?P
```

第 17 章那一大堆不变式，证的全是这个形状。

## 16.5 `assert`：它给的是假设，不是义务

`l4v/lib/Monads/nondet/Nondet_Monad.thy` 第 133--146 行连着给了四个定义：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_Monad.thy:133-146 -->
```text
definition fail :: "('s, 'a) nondet_monad" where
  "fail \<equiv> \<lambda>s. ({}, True)"

text \<open>Assertions: fail if the property @{text P} is not true\<close>
definition assert :: "bool \<Rightarrow> ('a, unit) nondet_monad" where
  "assert P \<equiv> if P then return () else fail"

text \<open>Fail if the value is @{const None}, return result @{text v} for @{term "Some v"}\<close>
definition assert_opt :: "'a option \<Rightarrow> ('b, 'a) nondet_monad" where
  "assert_opt v \<equiv> case v of None \<Rightarrow> fail | Some v \<Rightarrow> return v"

text \<open>An assertion that also can introspect the current state.\<close>
definition state_assert :: "('s \<Rightarrow> bool) \<Rightarrow> ('s, unit) nondet_monad" where
  "state_assert P \<equiv> get >>= (\<lambda>s. assert (P s))"
```

三元组那一半和非失败那一半是一对镜子（实测）——
`P` 在前者出现在**假设**的位置，在后者才出现在**义务**的位置：

```text
theorem
  valid_kassert: valid ?Q (kassert ?P) ?R = (\<forall>s. ?Q s \<longrightarrow> ?P \<longrightarrow> ?R () s)
```

```text
theorem no_fail_kassert: no_fail ?Q (kassert ?P) = (\<forall>s. ?Q s \<longrightarrow> ?P)
```

l4v 把后一条直接登记成了 `[wp]` 规则，
`l4v/lib/Monads/nondet/Nondet_No_Fail.thy` 第 106--108 行：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_No_Fail.thy 第 106--108 行 -->
```text
lemma no_fail_assert[simp, wp]:
  "no_fail (\<lambda>_. P) (assert P)"
  by (simp add: assert_def)
```

示例里的同形版本是 `no_fail_kassert_trivial`。
`assert_opt` 的两条化简（实测）说明它就是"取空则失败"：

```text
theorem kassert_opt_Some: kassert_opt (Some ?v) = kreturn ?v
```

```text
theorem kassert_opt_None_is_fail: kassert_opt None = kfail
```

第 08 章说"错误路径也要证"，具体就是指 `no_fail` 这一半：
只交三元组的话，`assert` 一条都没被检查过。

## 16.6 一个内核风格的例子：取一个非空能力

真实代码是 `l4v/spec/abstract/CSpaceAcc_A.thy` 第 28 行的 `get_cap`，
那串 `case obj of` 里认不出的对象类型走第 39 行的 `fail`，
最后一句是第 40 行的 `assert_opt (caps cref)`：

<!-- 源码块：l4v/spec/abstract/CSpaceAcc_A.thy 第 28--41 行 -->
```text
definition
  get_cap :: "cslot_ptr \<Rightarrow> (cap,'z::state_ext) s_monad"
where
  "get_cap \<equiv> \<lambda>(oref, cref). do
     obj \<leftarrow> get_object oref;
     caps \<leftarrow> case obj of
             CNode sz cnode \<Rightarrow> do
                                assert (well_formed_cnode_n sz cnode);
                                return cnode
                              od
           | TCB tcb     \<Rightarrow> return (tcb_cnode_map tcb)
           | _ \<Rightarrow> fail;
     assert_opt (caps cref)
   od"
```

示例把"取槽位 + 要求非空"抽象成 `get_cap_nonnull`，正常路径的完整一对（实测）：

```text
theorem
  get_cap_nonnull_ok:
    valid (\<lambda>s. ks_caps s ?sl \<noteq> NullCap) (get_cap_nonnull ?sl)
     (\<lambda>c s. c = ks_caps s ?sl)
```

```text
theorem
  get_cap_nonnull_no_fail:
    no_fail (\<lambda>s. ks_caps s ?sl \<noteq> NullCap) (get_cap_nonnull ?sl)
```

下面是那对**陷阱**定理。槽位为空时，这段计算返回空集，
于是三元组照样成立——哪怕后条件写成 `False`：

```text
theorem
  null_slot_triple_still_holds:
    valid (\<lambda>s. ks_caps s ?sl = NullCap) (get_cap_nonnull ?sl) (\<lambda>_ _. False)
```

真正拒绝这条路径的只有非失败：

```text
theorem
  null_slot_does_fail:
    \<not> no_fail (\<lambda>s. ks_caps s ?sl = NullCap) (get_cap_nonnull ?sl)
```

把这两条并排放在一起看就是本章全部教训：**三元组不会替你排除失败路径**。

## 16.7 `validE`：带错误码的那一半

第 08 章的 `se_monad` 把结果装成和类型：错误码在 `Inl`、正常值在 `Inr`，
所以它的三元组有**两个**后条件。`l4v/lib/Monads/nondet/Nondet_VCG.thy`
第 54 行的 `validE` 就是把两半拼进普通 `valid`：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_VCG.thy 第 54--57 行 -->
```text
definition validE ::
  "('s \<Rightarrow> bool) \<Rightarrow> ('s, 'a + 'b) nondet_monad \<Rightarrow> ('b \<Rightarrow> 's \<Rightarrow> bool) \<Rightarrow> ('a \<Rightarrow> 's \<Rightarrow> bool) \<Rightarrow> bool"
  ("\<lbrace>_\<rbrace>/ _ /(\<lbrace>_\<rbrace>,/ \<lbrace>_\<rbrace>)") where
  "\<lbrace>P\<rbrace> f \<lbrace>Q\<rbrace>,\<lbrace>E\<rbrace> \<equiv> \<lbrace>P\<rbrace> f \<lbrace> \<lambda>v s. case v of Inr r \<Rightarrow> Q r s | Inl e \<Rightarrow> E e s \<rbrace>"
```

注意 `Q` 吃的是 `Inr`（正常值），`E` 吃 `Inl`（错误码），
和第 16.6 节示例里的类型顺序一致（实测）：

```text
theorem
  validE_valid:
    validE ?P ?m ?Q ?E =
    (\<forall>s. ?P s \<longrightarrow>
         (\<forall>(v, s')\<in>fst (?m s). case v of Inl e \<Rightarrow> ?E e s' | Inr r \<Rightarrow> ?Q r s'))
```

```text
theorem
  validE_split:
    valid ?P ?m (\<lambda>v s. case v of Inl e \<Rightarrow> ?E e s | Inr r \<Rightarrow> ?Q r s) \<Longrightarrow>
    validE ?P ?m ?Q ?E
```

`validE` 里**也没有**失败位。`throwError` 是把错误码当**结果**交出去
（走 `E` 那一支，失败位仍然是假的），
它和 `fail`（返回集合为空、失败位置真）是两回事——
"会返回 `seL4_InvalidCapability`" 与 "这段代码可能失败" 是两个不同的证明目标。

## 16.8 名字即证据：约定、排版与规则再生

前面几节把 `valid` / `no_fail` / `validE` 三个形状讲完了。真去翻
`invariant-abstract` 会话会立刻撞上一件事：几千条三元组长得很像，
但名字各有各的规矩，而规矩本身是官方文档的一部分——
写在 `l4v/docs/conventions.md` 第 103 行那一节（"General Hoare triple conventions"）。
它不是审美条款：**名字直接告诉你这条引理能不能挂 `[wp]`**。

**三种形状，三种 `[wp]` 安全性**（逐字摘自 `l4v/docs/conventions.md:105-107`）：

<!-- 源码块：l4v/docs/conventions.md:105-107 -->
```text
* `function_wp` indicates a weakest precondition triple about `function` with a
  generic postcondition and the real weakest precondition that ensures the
  postcondition. Usually safe to declare `[wp]`.
```

（逐字摘自 `l4v/docs/conventions.md:109-112`）：

<!-- 源码块：l4v/docs/conventions.md:109-112 -->
```text
* `function_inv` indicates invariance, e.g. along the lines of
  `⦃P⦄ function ⦃λ_. P⦄`. Usually **not** safe for `[wp]`. Do not confuse with
  `function_invs`, which is an instance of the pattern below for the property
  `invs`.
```

（逐字摘自 `l4v/docs/conventions.md:114-118`）：

<!-- 源码块：l4v/docs/conventions.md:114-118 -->
```text
* `function_prop` indicates a triple with a reasonably weak precondition for a
  postcondition `prop`. Doesn't have to be the weakest, just the weak enough to
  be useful. Often safe for `[wp]`, use discretion.
  Example:
  `⦃valid_objs and valid_ep ep⦄ set_endpoint p ep ⦃λ_. valid_objs⦄`
```

再加第四条（`l4v/docs/conventions.md:120-121`）：

<!-- 源码块：l4v/docs/conventions.md:120-121 -->
```text
* `prop_lift` indicates a lifting lemma for proving a property about (usually)
  an arbitrary `f` by showing simpler properties about `f`.
```

分界线就落在**谁把什么交给谁**。`_wp` 那条说"我给的是真正保证后置的最弱前置"，
所以后条件是任意的、前置是现成的，`wp` 拿去倒推永远不会多要假设；
`_inv` 那条的后条件是 `λ_. P`——一个**已经写死的谓词**。把它挂进 `[wp]`，
`wp` 会用它替换目标的后条件，于是原本只要证"某个弱一点的东西"的义务
变成"要保住你手上这条具体的 `P`"，通常证不动，留下打不开的子目标。
这就是第 17 章 crunch 出来的那一族规则的用途：它们靠 `invs` 的 `and` 链**组合**，
不当 wp 规则。第 16.2 节坑位 1 与这条约定是同一件事的两面。

`function_prop` 的例句内行一看就懂：`set_endpoint` 只改 kheap 里那个 endpoint
对象的字段，于是它保住 `valid_objs`，代价是自带一条"这个端点本身合法"的小假设。
两个常量都在真实规范里：`set_endpoint`（`l4v/spec/abstract/KHeap_A.thy:162`）、
`valid_ep`（`l4v/proof/invariant-abstract/Invariants_AI.thy:537`）。

**排版也有官方规定。** 官方那份样式指南的章标题就写着
《An Isabelle Syntax Style Guide》（`l4v/docs/Style.thy`），
里面专门给了三元组的折行样式，范本是第 119 行的 `my_hoare_triple_lemma`：

<!-- 源码块：l4v/docs/Style.thy:119-124 -->
```text
lemma my_hoare_triple_lemma:
  "\<lbrace>precondition_one and precondition_two and
    precondition three\<rbrace>
   my_function param_a param_b
   \<lbrace>post_condition\<rbrace>"
  oops
```

同一文件接着给了第二种折法（把 `and` 挪到下一行行首），
然后一句限定："do not mix them in the same lemma"（第 290 行）。
三元组的前条件是一条很长的 `and` 链，折行位置就是可读性的位置——
这条规定的理由是 diff：pull request 里读的都是 diff。

**规则不是手抄的，是再生出来的。** `l4v/docs/de-duplicating-proofs.md`
第 126--130 行给的是本章最实用的一招：一条同时证明两个后条件的引理，
用 `hoare_conjD1` / `hoare_conjD2` 变换成两条，不重写任何证明：

<!-- 源码块：l4v/docs/de-duplicating-proofs.md:126-130 -->
```text
thm hoare_conjD1 -- "⦃?P⦄ ?f ⦃λrv. ?Q rv and ?R rv⦄ ⟹ ⦃?P⦄ ?f ⦃?Q⦄"
thm hoare_conjD2 -- "⦃?P⦄ ?f ⦃λrv. ?Q rv and ?R rv⦄ ⟹ ⦃?P⦄ ?f ⦃?R⦄"

lemmas f_A = f_AB[THEN hoare_conjD1] -- "⦃P⦄ f ⦃λ_. A⦄"
lemmas f_B = f_AB[THEN hoare_conjD2] -- "⦃P⦄ f ⦃λ_. B⦄"
```

两条 `lemmas` 的行数比手写证明少一个数量级，而且理由写在紧接着的一段里：
如果哪天前置条件 `P` 加强成 `P ∧ P'`，`f_A`、`f_B` 不用改一个字的证明就跟着变。
`hoare_conjD1` 本体在 `l4v/lib/Monads/nondet/Nondet_VCG.thy:289`。

**`wpfix`：坑位 8 那个方法的本体。** 16.3 说过官方 wp 手册只交代了一句
"四种最常见的统一失败形状"（`l4v/lib/Monads/wp/WP_README.thy:75`），
细节指向 `Monads.WPFix`。那个文件声明在
`l4v/lib/Monads/wp/WPFix.thy` 第 218 行的 `method_setup`，
而第 232--236 行那段示例注释才是真正说清"它做了什么"的地方：

<!-- 源码块：l4v/lib/Monads/wp/WPFix.thy:232-236 -->
```text
   (* apply assumption+ won't work here, since it will pick Id
      incorrectly. the presence of the goal ?Ra is also dangerous.
      wpfix handles this by setting Ra to True and splitting
      Id into a conjunction. *)
  apply (wpfix | assumption)+
```

`Ra` 是那条卡住的 schematic 前置，`Id` 是被它牵连的那个。
"设成 `True` 再把 `Id` 拆成合取"就是 16.3 那句"处理统一失败"的具体动作。
第 19 章的 VCG 故障清单里，同一个毛病还有一条退路（`wpfix` 不行就回到
schematic 引入处改参数），两处配合着记。

**最后是找规则。** 这一章的坑几乎全是"规则太多、不知道哪条在起作用"，
官方给 `find_theorems` 单独写了一页（`l4v/docs/find-theorems.md`），
第 22--28 行那张表是最低要求：

<!-- 源码块：l4v/docs/find-theorems.md:22-28 -->
```text
| syntax | matches |
| ------------------- | ------------
| `"pattern"`       | only theorems that match this pattern
| `name: "string"`    | only theorems whose names contain this string
| `simp: "pattern"` | equations that can rewrite this pattern
| `intro`, `elim`, `dest`, `solves` | theorems that are intro/elim/dest rules for the current proof goal, or solve the goal
| `- <criterion>`   | only theorems that do **not** match the criterion
```

对本章最常用的两条：`simp: "pattern"` 用来问"哪条 simp 规则会重写这个式子"
（怀疑某条 `[wp]` 规则改了别处的证明时就用它），
`intro` / `dest` / `elim` 是"对当前目标可用"的规则，比按名字猜可靠。
同一页靠后还有一招省时间的：把 datatype 自动生成的 simp 规则
用 `-name:".simp"` 排除掉。
`l4v/docs/find-consts.md` 是它的姊妹页，按**类型**查常量，
`strict:` 那条限定（第 37 行）在 l4v 这种体量的仓库里几乎是必需——
不加 `strict` 的结果集大到没法看。

---

## 官方教程对照

这一章没有对应的官方 kernel tutorial 页：docs.sel4.systems 的 Tutorials 讲的
是"怎么写用户态 seL4 程序"，霍尔逻辑在那里不出现。规范侧的官方对应材料
是 l4v 仓库自己那份证明工程文档（`l4v/docs/`，12 篇 + 一份 `plans/`）。
对应关系如下，本教程的取舍写在右边。

| 官方文档 | 覆盖本章哪一段 | 本教程的处理 |
|---|---|---|
| `l4v/docs/conventions.md` | 三元组引理的命名与 `[wp]` 安全性 | 16.8，坑位 13 |
| `l4v/docs/Style.thy` | 三元组折行、apply 缩进、100 列上限 | 16.8 |
| `l4v/docs/de-duplicating-proofs.md` | 规则属性再生引理、重复子目标 | 16.8，17.8 |
| `l4v/docs/find-theorems.md`、`l4v/docs/find-consts.md` | 在几千条引理里查规则 | 16.8 |
| `l4v/docs/haskell-assertions.md` | `assert` 在三条会话里的不同后果 | 16.5 与下面第 2 条 |
| `l4v/docs/compacting-proofs.md` | 把 erule 瀑布压成一条 `fastforce` | 18.8 |
| `l4v/docs/vcg-debugging.md` | `vcg` 的两类故障 | 19.7 |
| `l4v/docs/crefine-notes.md` | CRefine 的证明骨架 | 19.7 |

**1. "三元组不管失败"这句话有官方版本。** 16.2 与 16.6 反复强调
`valid` 里不含失败位。官方 `l4v/docs/haskell-assertions.md` 第 52 行讲的是同一件事，
但给出了它为什么被接受：

<!-- 源码块：l4v/docs/haskell-assertions.md:52-52 -->
```text
In `AInvs`, the `valid` predicate we use doesn't insist on getting a result. This effectively means we can assume assertions are satisfied in proofs of invariant Hoare triples. So in `AInvs`, we can use `assert` to defer a proof obligation. Sometimes this allows us to write simpler Hoare triples, since we can elide a precondition if an `assert` gives us the information we need. Simpler Hoare triples can mean simpler proofs elsewhere. So that can be useful, but it can also be dangerous.
```

关键词是 "defer a proof obligation"：`assert` 与"不要求拿到结果"是一套设计，
把义务**推迟**到别的会话去还，而不是取消。

**2. `assert` 的账在三个会话里分别怎么记。** 这是本章最该背下来的一张表，
官方那份 tl;dr（`l4v/docs/haskell-assertions.md:11-20`）逐字如下：

<!-- 源码块：l4v/docs/haskell-assertions.md:11-20 -->
```text
> :mag: **tl;dr**
> * assertions (assert) in Haskell give you:
>   * free assumptions in wp
>   * proof obligations in `corres` in `Refine`
>   * free assumptions in `ccorres` in `CRefine`
> * you can use them to transport information (properties, invariants) from `AInvs` down to Haskell and C:
>   * if you assert `P'` in Haskell
>   * and can derive `[| (s,s') : state_relation; P s |] ==> P' s'`
>   * and can derive `P` in/from AInvs
>   * then you get `P'` for free in wp proofs in Haskell, can prove it from the abstract side in `corres`, and get to assume it in `ccorres` for C
```

对着本章的记号翻：`wp` 那一行说的是"三元组的假设位白拿"（16.5）；
`corres` 那一行是第 18 章的义务清单——抽象层写下的 `assert`，
在精化会话里必须**证**；`ccorres` 那一行是第 19 章，回到 C 层又变成假设。
一份 `assert` 在不同层一会儿是假设、一会儿是义务，
这就是三层的证明为什么必须**串着看**：单看任何一层都会误记谁欠谁。
同页第 56--68 行给的是实操理由：CRefine 需要不变式的知识，
但没人想在 Haskell 层重证一遍，于是在 Haskell 里加 `assert`，
再回 `Refine` 补那一笔。

---

## 本章坑位清单（实测）

1. **以为 `valid` 包含非失败**：定义式里只有那句蕴含，失败位另归 `no_fail`（第 24 行）。
2. **以为失败的程序不满足任何三元组**：`fail_satisfies_every_triple` 恰好相反。
3. **看到 `assert P` 就以为要证 `P`**：三元组里 `P` 在假设位；义务位在 `no_fail_kassert`。
4. **只用 `no_fail` 推 `no_fail`**：`no_fail_bind` 必须搭一条 `valid` 才推得过去。
5. **把 `wp` 当成一个函数**：这里是自造的谓词；工具链里的 `wp` 是方法，行为由 `[wp]`/`[wp_comb]`/`[wp_split]` 三族规则决定。
6. **加了 `[wp]` 引理却没别的证明变**：选规则是"后加入者优先"，全局影响，别处大概率已经变了。
7. **`strengthen_pre` 方向搞反**：它允许**多加**假设（前条件变小）。
8. **在 `wp` 前后乱用 `safe`/`clarsimp`**：它们会隐式 case split 特征变元，把统一堵死——这正是 `wpc`/`wpfix` 存在的原因。
9. **把 `no_fail` 当 `valid`**：`no_fail` 只谈失败位，完全不涉及后条件。
10. **以为 `throwError` 就是失败**：它是正常结果（走 `validE` 的 `E` 支），失败位仍为假。
11. **在非确定性上只验一条路径**：`select` 会放大结果集合，每个元素都要满足后条件。
12. **手写 `valid` 却不去查工具目录**：`l4v/lib/Monads/wp/` 是 wp 方法本体，`l4v/lib/Monads/nondet/` 是单子与 VCG，两者别混。
13. **把不变式引理挂进 wp 规则集**：名字后缀 `_wp` 才是给 `wp` 用的、`_prop` 要逐条判断，而 `function_inv` 那一族官方写明 "Usually not safe for [wp]"（`l4v/docs/conventions.md` 第 110 行）。
14. **一条引理里混用两种三元组折行**：`l4v/docs/Style.thy` 那句 "do not mix them in the same lemma"（第 290--291 行）；改老引理时沿用原有那种。
15. **手抄两条派生三元组**：一条 `⦃P⦄ f ⦃λrv. A rv and B rv⦄` 加 `f_AB[THEN hoare_conjD1]` 就够（`l4v/docs/de-duplicating-proofs.md:129`），前置条件以后变了它自动跟着变。

---

上一章：[15 · 内存再类型化](15-retype.md) ｜ 下一章：[17 · 不变式](17-invariants.md) ｜ 返回：[README](../README.md)
