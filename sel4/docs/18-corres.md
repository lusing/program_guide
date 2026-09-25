# 18 · 精化关系

对应示例：`../examples/S18_corres.thy`

## 18.1 从抽象规范到设计规范

第 16、17 章证的都是抽象规范（A）内部的定理："这个操作如果在前置条件
成立的状态上跑，后置条件成立、不变式保住"。可是交付的代码是 C，
中间还有一层设计规范（D）——数据类型与 C 更接近（`word`、显式位运算、
确定的实现选择），抽象层那些"随便挑一个"的非确定步骤在这里必须落地。
于是"A 的那一步被 D 的这一步实现"必须有一个可证的说法，
这就是本章的 `corres`。

三份文件的分工要记清：

* `l4v/lib/Corres_UL.thy` —— 定义与全部通用引理（不关心是 seL4 的状态）；
* `l4v/proof/refine/Corres.thy` —— 把状态关系实例化成 seL4 的那一座桥；
* `l4v/lib/Corres_Method.thy` —— 把上面两条规则包成一个证明方法（18.7）。

## 18.2 状态关系是一座桥，不是函数

真实那座桥长这样（节选）：

<!-- 源码块：l4v/proof/refine/StateRelation.thy 第 291--297 行 -->
```text
definition state_relation :: "(det_state \<times> kernel_state) set" where
  "state_relation \<equiv> {(s, s').
         pspace_relation (kheap s) (ksPSpace s')
       \<and> sched_act_relation (scheduler_action s) (ksSchedulerAction s')
       \<and> ready_queues_relation s s'
       \<and> ghost_relation_wrapper s s'
       \<and> cdt_relation (swp cte_at s) (cdt s) (ctes_of s')
```

两点值得看：它的类型是**一对状态的集合**（`(det_state × kernel_state) set`），
不是 `det_state ⇒ kernel_state ⇒ bool`；而且它是十来条子关系的合取，
每一条管一块状态（堆、调度器、就绪队列、CDT、中断状态、当前线程……）。
第 17 章末尾说 `pspace_aligned`/`pspace_distinct` 是"对齐结论在系统层面的形态"，
那两条在这里的 `pspace_relation` 里面。
第一条 `cdt_relation` 用到的 `swp`、`cte_at` 与 17.4 那次一样不在这份代码树里
（AbsSpec 会话），所以本章对这一支只读到"CDT 得对上"为止。

示例里的桥只有两个字段，形状完全一样：抽象层记"这个地址有没有对象"，
具体层记"这个地址上存了什么"，关系把后者投影成前者。

```text
consts
  state_relation :: "astate \<Rightarrow> cstate \<Rightarrow> bool"
```

一条必要的性质：**同一个抽象状态对应的两个具体状态，在"哪些对象存在"上必须一致**，
否则"抽象层说有对象"翻译不成"具体层某个位置上有东西"。

```text
theorem
  relation_is_functional:
    \<lbrakk>state_relation ?as ?cs; state_relation ?as ?cs'\<rbrakk>
    \<Longrightarrow> \<forall>p. (c_objs ?cs p \<noteq> None) = (c_objs ?cs' p \<noteq> None)
```

"抽象是具体的函数"这句话在这里的准确含义是**投影是函数**，
关系本身不是函数：一个具体状态可以对应多个抽象状态吗？
这座桥上是不能（投影唯一）；反过来，一个抽象状态对应许多具体状态（内容随便）。
精化要证的东西全在后一个方向里。

## 18.3 先用一个确定性模型认识形状

示例 18.3 那份定义是教学模型：两边都是确定函数，没有失败位，
`corres` 退化成"在相关状态下输出相关、跑完仍然相关"。

```text
consts
  corres ::
    "(astate \<Rightarrow> cstate \<Rightarrow> bool)
     \<Rightarrow> ('a \<Rightarrow> 'b \<Rightarrow> bool)
       \<Rightarrow> (astate \<Rightarrow> 'a \<times> astate) \<Rightarrow> (cstate \<Rightarrow> 'b \<times> cstate) \<Rightarrow> bool"
```

结果关系 `M` 是"这一层允许多少信息损失"的旋钮：查询类操作两边返回值必须相等，
用 `(=)`；创建/删除类操作的值本身没意义，用 `(\<lambda>_ _. True)`，只看状态。

```text
theorem
  corres_object_at:
    corres state_relation (=) (a_object_at ?p) (c_object_at ?p)
```

```text
theorem
  corres_create:
    corres state_relation (\<lambda>_ _. True) (a_create ?p) (c_create ?p ?v)
```

```text
theorem
  corres_delete:
    corres state_relation (\<lambda>_ _. True) (a_delete ?p) (c_delete ?p)
```

`c_create` 比 `a_create` 多一个参数 `v`：抽象层不关心新建对象的初值，
具体层必须选一个。这类"具体层多出来的自由度"不需要额外机制，
18.5 那条主句本来就允许。

## 18.4 真实定义

<!-- 源码块：l4v/lib/Corres_UL.thy 第 17--26 行 -->
```text
definition
  corres_underlying :: "(('s \<times> 't) set) \<Rightarrow> bool \<Rightarrow> bool \<Rightarrow>
                        ('a \<Rightarrow> 'b \<Rightarrow> bool) \<Rightarrow> ('s \<Rightarrow> bool) \<Rightarrow> ('t \<Rightarrow> bool)
           \<Rightarrow> ('s, 'a) nondet_monad \<Rightarrow> ('t, 'b) nondet_monad \<Rightarrow> bool"
where
 "corres_underlying srel nf nf' rrel G G' \<equiv> \<lambda>m m'.
      \<forall>(s, s') \<in> srel. G s \<and> G' s' \<longrightarrow>
           (nf \<longrightarrow> \<not> snd (m s)) \<longrightarrow>
           (\<forall>(r', t') \<in> fst (m' s'). \<exists>(r, t) \<in> fst (m s). (t, t') \<in> srel \<and> rrel r r') \<and>
           (nf' \<longrightarrow> \<not> snd (m' s'))"
```

seL4 只用它的一个实例，两个开关在实例化时就写死了：

<!-- 源码块：l4v/proof/refine/Corres.thy:12-13 -->
```text
abbreviation
 "corres \<equiv> corres_underlying state_relation False True"
```

示例把第 7 章那个单子的类型和这份定义搬了一份，唯一改动是把那对状态
先拆好再量词（`∀s s'. (s, s') ∈ srel ⟶ …`），语义一字不差。
这个改动是**被迫**的，而且本身就是本章的一条教训：化简器碰到
`∀(s, s') ∈ srel` 会在假设里留下一个 `case` 不肯拆，
`blast`/`auto` 于是推不动"从 `corres` 取一个扁平结论"这类事情。
实测过、失败的写法（`fastforce split: prod.splits`、`auto simp: split_def`）
都停在同一条目标上；换成就人量词形状之后全部 `by blast` 过。

```text
theorem corres_underlyingI':
 \<lbrakk>\<And>s s' r' t'.
     \<lbrakk>(s, s') \<in> ?srel; ?G s; ?G' s'; (r', t') \<in> fst (?m' s')\<rbrakk>
     \<Longrightarrow> \<exists>(r, t)\<in>fst (?m s). (t, t') \<in> ?srel \<and> ?rrel r r';
  \<And>s s'. \<lbrakk>?nf; (s, s') \<in> ?srel; ?G s; ?G' s'\<rbrakk> \<Longrightarrow> \<not> snd (?m s);
  \<And>s s'. \<lbrakk>?nf'; (s, s') \<in> ?srel; ?G s; ?G' s'\<rbrakk> \<Longrightarrow> \<not> snd (?m' s')\<rbrakk>
 \<Longrightarrow> corres_underlying ?srel ?nf ?nf' ?rrel ?G ?G' ?m ?m'
```

引理名带 `'` 是因为真实库里第 33 行已经有一条 `corres_underlyingI`，
形状与这条一样（它把两条 `no_fail` 义务合并写法不同）。

## 18.5 量化方向：具体层可以少给，不能多给

主句的量词是"**每个具体结果都得有一个抽象结果来解释**"
（外层跑 `m'`、内层跑 `m`）。消去规则把它原样取出来：

```text
theorem corres_underlyingD:
 \<lbrakk>corres_underlying ?srel ?nf ?nf' ?rrel ?G ?G' ?m ?m'; (?s, ?s') \<in> ?srel;
  ?G ?s; ?G' ?s'; (?r', ?t') \<in> fst (?m' ?s'); ?nf \<Longrightarrow> \<not> snd (?m ?s)\<rbrakk>
 \<Longrightarrow> \<exists>(r, t)\<in>fst (?m ?s). (t, ?t') \<in> ?srel \<and> ?rrel r ?r'
```

反面这条是全章最有用的\**证伪*工具：找出一个具体结果在抽象层没有解释，
`corres` 就被推翻。

```text
theorem corres_no_match_refuted:
 \<lbrakk>(?s, ?s') \<in> ?srel; ?G ?s; ?G' ?s'; (?r', ?t') \<in> fst (?m' ?s');
  \<And>r t. \<lbrakk>(r, t) \<in> fst (?m ?s); (t, ?t') \<in> ?srel\<rbrakk> \<Longrightarrow> \<not> ?rrel r ?r';
  ?nf \<longrightarrow> \<not> snd (?m ?s)\<rbrakk>
 \<Longrightarrow> \<not> corres_underlying ?srel ?nf ?nf' ?rrel ?G ?G' ?m ?m'
```

有了这两条，"精化可以减少非确定性"就不再是口头话，而是两条定理。
抽象层给两个结果、具体层固定给其中一个：合法。

```text
theorem
  concrete_may_pick_one_abstract_result:
    corres_underlying sreln False True (=) (\<lambda>_. True) (\<lambda>_. True) a_select2
     (c_pick 1)
```

抽象层给两个结果、具体层给出第三个：不合法。

```text
theorem
  concrete_cannot_invent_a_result:
    \<not> corres_underlying sreln False True (=) (\<lambda>_. True) (\<lambda>_. True) a_select2
       (c_pick 7)
```

这两条合起来是"精化不是等价"的定理形式：具体层可以**更确定**，
不可以**更自由**。第 20 章整条精化链就架在这个方向上。

## 18.6 失败位到底管住了什么

两个开关不对称：`corres` 取 `nf = False`（抽象层"不许失败"这条义务**没有**）、
`nf' = True`（具体层**必须**不失败）。所以义务全落在具体层：

```text
theorem corres_concrete_no_fail:
 \<lbrakk>corres_underlying ?srel False True ?rrel ?G ?G' ?m ?m'; (?s, ?s') \<in> ?srel;
  ?G ?s; ?G' ?s'\<rbrakk>
 \<Longrightarrow> \<not> snd (?m' ?s')
```

另一个方向是本章原来讲错的一处，值得单独纠一遍：**抽象层交不出结果时，
具体层不是随便**。主句整个挂在 `(nf ⟶ ¬ snd (m s)) ⟶` 下面，
抽象层在这个状态上确实失败时（`nf` 为真）这条对应关系对具体层什么都不要求；
可是真实 `corres` 的 `nf` 是 `False`，那个前件恒真，于是
"抽象层在这对状态上交不出结果 ⟹ 具体层也交不出"就成立：

```text
theorem corres_abstract_empty:
 \<lbrakk>corres_underlying ?srel False ?nf' ?rrel ?G ?G' ?m ?m'; (?s, ?s') \<in> ?srel;
  ?G ?s; ?G' ?s'; fst (?m ?s) = {}\<rbrakk>
 \<Longrightarrow> fst (?m' ?s') = {}
```

```text
theorem corres_forces_concrete_silent_when_abstract_fails:
 \<lbrakk>corres_underlying sreln False True ?rrel (\<lambda>_. True) (\<lambda>_. True) nfail ?m';
  (?as, ?cs) \<in> sreln\<rbrakk>
 \<Longrightarrow> fst (?m' ?cs) = {}
```

注意两条都把抽象层那个开关写成 `False` 而不是变量 `nf`——不是偷懒，
是这两条**只在 `nf = False` 时才成立**，写成变量就证不出来。

那"抽象层允许失败的那些状态"怎么办？答案是**不在前件覆盖的状态里谈它**。
两边同时 `assert` 是可以对应的，条件是把那两条假设写进 `G`/`G'`
（真实规则里写成 `(%_. P)` 与 `(%_. Q)`）：

```text
theorem
  corres_nassert_both:
    corres_underlying sreln ?nf ?nf' (\<lambda>_ _. True) (\<lambda>_. ?P) (\<lambda>_. ?Q)
     (nassert ?P) (nassert ?Q)
```

这条能过的原因很实在：`nassert False` 的结果集是空的，
可 18.5 的引介规则要求的是"对每个具体结果找抽象结果"，
而 `G' s' = Q = False` 时前提本身就矛盾——**假设挡住了失败分支，
不是靠证明它怎么对应**。这就是 `l4v/lib/Corres_UL.thy` 第 831 行
`corres_assert` 的形状：

<!-- 源码块：l4v/lib/Corres_UL.thy 第 831--832 行 -->
```text
lemma corres_assert:
  "corres_underlying sr nf nf' dc (%_. P) (%_. Q) (assert P) (assert Q)"
```

## 18.7 组合：真实证明里的两步

一个系统调用是几十步单子绑定串起来的，所以"一步的对应"必须有拆开规则。
`corres_split`（`l4v/lib/Corres_UL.thy` 第 290 行）是全树用得最多的一条：

<!-- 源码块：l4v/lib/Corres_UL.thy 第 290--294 行 -->
```text
lemma corres_split:
  assumes x: "corres_underlying sr nf nf' r' P P' a c"
  assumes y: "\<And>rv rv'. r' rv rv' \<Longrightarrow> corres_underlying sr nf nf' r (R rv) (R' rv') (b rv) (d rv')"
  assumes    "\<lbrace>Q\<rbrace> a \<lbrace>R\<rbrace>" "\<lbrace>Q'\<rbrace> c \<lbrace>R'\<rbrace>"
  shows      "corres_underlying sr nf nf' r (P and Q) (P' and Q') (a >>= (\<lambda>rv. b rv)) (c >>= (\<lambda>rv'. d rv'))"
```

它多出来的两条 `wp` 前件不是装饰：后半段的前件 `R rv` 要靠
"`a` 跑完之后 `R` 成立"来保。第 17 章那个谓词上的 `and`
（`P and Q`）就出现在结论里。示例不搬 `wp`，只搬两个不需要它的特例。
先照抄 `bind`：

```text
theorem
  nbind_nassert: nassert ?P \<bind>\<^sub>n ?f = (\<lambda>s. if ?P then ?f () s else ({}, True))
```

第一个特例是 `corres_return`（同文件第 93 行）的形状：两个 `return` 的对应
**不是一个定理，而是一个等价式**。

<!-- 源码块：l4v/lib/Corres_UL.thy 第 93--95 行 -->
```text
lemma corres_return[simp, corres_no_simp]:
  "corres_underlying sr nf nf' r P P' (return a) (return b) =
   ((\<exists>s s'. P s \<and> P' s' \<and> (s, s') \<in> sr) \<longrightarrow> r a b)"
```

模型版本一模一样，那个奇怪的存在量词也在：

```text
theorem
  corres_nreturn:
    corres_underlying ?srel ?nf ?nf' ?rrel (\<lambda>_. ?P) (\<lambda>_. ?Q) (nreturn ?x)
     (nreturn ?y) =
    (?P \<and> ?Q \<and> (\<exists>s s'. (s, s') \<in> ?srel) \<longrightarrow> ?rrel ?x ?y)
```

`∃s s'. (s, s') ∈ sr` 说的是"这座桥得真的有人走过"。少了它，
`corres` 在一座**空桥**上对任何返回值关系都成立——这就是把状态关系写成
集合（18.2）而不是写成函数的直接副作用，也是那条存在前件存在的全部理由：

```text
theorem
  corres_empty_srel_trivial:
    corres_underlying {} ?nf ?nf' ?rrel (\<lambda>_. True) (\<lambda>_. True) (nreturn ?x)
     (nreturn ?y)
```

第二个特例是 `corres_assert_assume_l`（同文件第 766 行）：
在一边加 `assert` 不必证失败分支怎么对应，只是把那条假设搬进前置条件。

<!-- 源码块：l4v/lib/Corres_UL.thy 第 766--768 行 -->
```text
lemma corres_assert_assume_l:
  "corres_underlying sr nf nf' rrel P Q (f ()) g
  \<Longrightarrow> corres_underlying sr nf nf' rrel (P and (\<lambda>s. P')) Q (assert P' >>= f) g"
```

模型版本（真实那条的 `P and (\<lambda>s. P')` 在这里展开写成 `\<lambda>s. P s \<and> A`，
因为示例没引 `Fun_Pred_Syntax`）：

```text
theorem corres_assert_assume_l_model:
 corres_underlying ?srel ?nf ?nf' ?rrel ?P ?Q (?f ()) ?g \<Longrightarrow>
 corres_underlying ?srel ?nf ?nf' ?rrel (\<lambda>s. ?P s \<and> ?A) ?Q
  (nassert ?A \<bind>\<^sub>n ?f) ?g
```

上面这些规则手工组合很累，`l4v/lib/Corres_Method.thy` 就是把它们包成方法：
第 50--51 行注册 `corres_splits` 这条属性并定义 `method corres_split`，
第 164 行的 `method corres` 是主入口。文件开头第 14--22 行那段注释
把设计目标说得很清楚：不追求完全自动化，只求"消掉样板、
把证明状态留在用户能继续推进的地方"。

## 18.8 两套框架、`empty_fail` 的方向，和"把证明压回去"

### 1. `corres` 只是两套框架里的一套

前面七节讲的都是 `corres`。官方约定页里有一节专门交代这件事：

<!-- 源码块：l4v/docs/conventions.md:168-173 -->
```text
There are two refinement/correspondence frameworks in `l4v`, one for proofs
between monadic functions, and one for proofs between monadic functions and C
(or Simpl functions, to be precise). The former are called `corres`, the latter
`ccorres`. Both frameworks have `corres_underlying` / `ccorres_underlying`
definition that is instantiated to a `corres` / `ccorres` predicate by
abbreviation.
```

两套的差别不在"关系"这个想法，而在具体侧是什么东西：`corres` 的具体侧还是一
个单子，`ccorres` 的具体侧是一段 Simpl 命令。于是那份定义多了三类参数——
环境 `Γ`、把 C 状态摘成抽象值的 `xf`、异常侧的关系与摘取 `arrel`/`axf`，
以及"进入这段语句之前手上已经攒下的语句栈" `hs`。

它的前件形状也不同，值得整段看：

<!-- 源码块：l4v/lib/clib/Corres_UL_C.thy:92-98 -->
```text
  "ccorres_underlying srel \<Gamma> rrel xf arrel axf G G' hs \<equiv>
   \<lambda>m c. \<forall>(s, s') \<in> srel. G s \<and> s' \<in> G' \<and> \<not> snd (m s) \<longrightarrow>
  (\<forall>n t. \<Gamma> \<turnstile>\<^sub>h \<langle>c # hs, s'\<rangle> \<Rightarrow> (n, t) \<longrightarrow>
   (case t of
         Normal s'' \<Rightarrow> (\<exists>(r, t) \<in> fst (m s). (t, s'') \<in> srel
                            \<and> unif_rrel (n = length hs) rrel xf arrel axf r s'')
       | _ \<Rightarrow> False))"
```

对着 18.4 那条定义读，三处差异都是**故意**的：

- 这里**没有** `nf`/`nf'` 两个开关。抽象侧"不许失败"被直接写进前件
  （`¬ snd (m s)`），C 侧则不是一条独立义务，而是塞进了 `unif_rrel` 的
  第一个参数 `n = length hs`。
- `G'` 的类型是集合不是谓词，所以前件里写 `s' ∈ G'`，18.4 那边写的是 `G' s'`。
- 结论量的是"小步语义能走出的每一步转移"，因此多出一个跳数变元 `n`。

那个 `unif_rrel` 只是把两条关系合成一条，定义比它的名声短得多：

<!-- 源码块：l4v/lib/clib/Corres_UL_C.thy:75-77 -->
```text
where
 "unif_rrel f rrel xf arrel axf \<equiv> \<lambda>x s.
    if f then rrel x (xf s) else arrel x (axf s)"
```

布尔为真走正常返回的关系 `rrel`/`xf`，为假走异常那侧的 `arrel`/`axf`。
传进去的是 `n = length hs`，意思是"手上那截 handler 栈刚好走完、
没有异常往外冒"——同文件第 42 行那条引理的名字就叫
`exec_handlers_use_hoare_nothrow`，结论的最后一项正是这个等式。
还有一处容易看漏：`case t of` 的分支里，出口不是 `Normal` 时结论直接是 `False`。
所以**这条 `ccorres_underlying` 只允许正常出口**，异常路径要靠
`crefine-notes.md` 那套 `nothrow` 引理另说（第 19 章）。

和 `corres` 一样，`ccorres_underlying` 也不直接用，靠 abbreviation 收参数：

<!-- 源码块：l4v/lib/clib/Corres_UL_C.thy:100-101 -->
```text
abbreviation
  "ccorresG rf_sr \<Gamma> r xf \<equiv> ccorres_underlying rf_sr \<Gamma> r xf r xf"
```

<!-- 源码块：l4v/proof/crefine/lib/Corres_C.thy:354-355 -->
```text
abbreviation
  "ccorres r xf \<equiv> ccorres_underlying rf_sr \<Gamma> r xf r xf"
```

差别只有一句话：`ccorresG` 还让你自己交状态关系和环境，
`ccorres` 把 `rf_sr` 与 `Γ` 都钉死了——而它写在 `context kernel` 里面，
所以**出了那个 locale 就没有 `ccorres` 可用**，只能退回 `ccorresG`。
第 19 章读 `cspec` 侧的证明时会反复撞上这件事。

### 2. 引理叫什么名字，官方是有表的

`Refine` 会话里几千条 `_corres` 引理不是随手起的名。约定页接着规定：

<!-- 源码块：l4v/docs/conventions.md:175-182 -->
```text
* General lemmas about `corres_underlying` that are directly used in program
  proofs are called `_corres` despite their more general nature. Exceptions are
  lemmas that are only used to build up the library internally, but are not used
  for program proofs.

* `corres_op` is for "built-in" operators and functions of the state monad such
  as `return`, `get`, `bind`, `when`, etc. Examples are `corres_get`,
  `corres_return`.
```

<!-- 源码块：l4v/docs/conventions.md:184-188 -->
```text
* `function_corres` is for correspondence proofs between an abstract and a
  concrete function. Often these functions have the same name, the abstract in
  `underscore_style` the concrete in `CamelCase`. The lemma should use the
  concrete name for function (this is currently too random and should converge
  more).
```

也就是说：看到 `corres_get`、`corres_return` 就该知道它是"单子原语"那一档，
`l4v/lib/Corres_UL.thy` 从第 93 行起成串定义；看到
`arch_deriveCap_corres` 就该知道它是某个函数的对应性证明——
抽象侧那个函数写作 `arch_derive_cap`，具体侧写作 `arch_deriveCap`，
引理用后者的名字，正是表里那条规定的样子。这类引理通常还挂一个 `[corres]` 属性，
那是 `l4v/lib/Corres_UL.thy` 里声明的一条规则集，`corres_split` 会自动取用它。
最后一条"函数名可以用缩写"还配了一份表：

<!-- 源码块：l4v/docs/conventions.md:158-160 -->
```text
* `sts` for `set_thread_state`
* `sts'` for `setThreadState`
* there are many more, please raise pull requests to make this a more comprehensive list
```

`sts` 与 `sts'` 一对，正好是 17.8 说的"撇号代表设计层"这件事在函数名上的版本。
这张表目前就三行，官方那行说明也直白："please raise pull requests to make
this a more comprehensive list"——遇到没见过的缩写别硬猜，回引理定义处看。
命名规范值不值这么多嘴，看规模就知道：只在 `l4v/proof/refine/` 下面，
以 `_corres` 结尾的引理就有 841 条（`grep -c` 数这一棵树的结果）。

### 3. `nf = False` 不是白送：`empty_fail` 把账要回来

18.6 的结论（真实 `corres` 把"不许失败"这条义务全压在具体层）不是本教程的
推断，官方文档写得更直：

<!-- 源码块：l4v/docs/haskell-assertions.md:42-46 -->
```text
So, now we can look again at `corres_underlying`, and we can see that for `corres`, `nf'` is `True`, so we have to prove that the concrete side does not set the failure flag, and therefore produces a result (assuming `empty_fail` on the concrete side).

The *forall* part of `corres_underlying` then requires that there is a result on the abstract side. Again, assuming `empty_fail` on the abstract side, the failure flag must not be set on the abstract side.

So, even though `nf` is `False` for `corres`, we effectively have to prove that the failure flag is not set on the abstract side, thanks to `empty_fail`.
```

这套论证完全吊在 `empty_fail` 上，而它的方向必须看清：真实定义是
"**结果集空 ⟹ 失败标志置起**"。

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_Empty_Fail.thy:16-20 -->
```text
text \<open>
  Usually, well-formed monads constructed from the primitives in @{text Nondet_Monad} will have the following
  property: if they return an empty set of results, they will have the failure flag set.\<close>
definition empty_fail :: "('s,'a) nondet_monad \<Rightarrow> bool" where
  "empty_fail m \<equiv> \<forall>s. fst (m s) = {} \<longrightarrow> snd (m s)"
```

同一份官方文档里有一句把方向说反了（`l4v/docs/haskell-assertions.md` 第 40 行）：
那里的英文写的是"失败标志置起 ⟹ 结果集为空"。**那句英文写的是这条性质的逆命题，
而它后面真正的推理用的是定义的方向**——照抄那句话的人会在 `corres`
里推出反的结论。18.6 那条 `corres_abstract_empty` 值得和这份定义并排记：
"抽象层交不出结果 ⟹ 具体层交不出结果"要成立，靠的正是主句对每个具体结果
都要在抽象层找到解释，而不是靠失败标志。

同一棵树的 `l4v/lib/Monads/nondet/Nondet_README.thy` 第 128--129 行把 `empty_fail` 解释成
"返回空结果集就必然置起失败标志"——和定义同向，可见文档那句是笔误，不是另一种约定。
顺带一提，这份 README 同一段还点名了另外三条常在用的性质（`no_fail`、`no_throw`、`det`），
第 8、17、22 章反复用到的就是它们：

<!-- 源码块：l4v/lib/Monads/nondet/Nondet_README.thy:123-132 -->
```text
text \<open>
There are additional properties of nondeterministic monadic functions that are often
useful. These include:
  @{const no_fail} - a monad does not fail when starting in a state that satisfies a
    given precondition.
  @{const empty_fail} - if a monad returns an empty set of results then it must also have
    the failure flag set.
  @{const no_throw} - an exception monad does not throw an exception when starting in a
    state that satisfies a given precondition.
  @{const det} - a monad is deterministic and returns exactly one non-failing state.\<close>
```

顺带一提，`_inv`/`_wp` 之外这里还有一个规则集：`[empty_fail_cond]`
（同文件从第 81 行开始成串挂上去），`wp` 推不动失败位时它是第二条路。

### 4. 展开硬啃之后，还要把证明压回去

18.4 说手工展开 `corres`/`ccorres` 定义会得到 `case`、量词方向、`no_fail`
三样同时出现。官方对这件事的态度不是"证出来就行"，而是**证完要回头压缩**：

<!-- 源码块：l4v/docs/compacting-proofs.md:9-13 -->
```text
Not all proofs are equal. After finishing a proof (especially a long, tricky
one), look over the proof and try to *compact* it. This includes

- removing or refactoring redundant steps; and
- replacing fragile methods by more robust methods.
```

它给的例子恰好就是 `ccorres` 与 `corres` 之间的一条转换。先是一段十一行的
`apply` 脚本：

<!-- 源码块：l4v/docs/compacting-proofs.md:18-28 -->
```text
apply (drule ac_corres_ccorres_underlying)
apply (clarsimp simp: ccorres_underlying_def corres_underlying_def rf_sr_def Ball_def liftE_def)
apply (erule allE, erule allE, erule_tac P="cstate_relation _ _" in impE, assumption)
apply clarsimp
apply (erule allE, erule impE, rule_tac P="arg_rel _" and Q="¬snd _" in conjI, assumption, assumption)
apply (erule allE, erule allE, erule_tac P="Γ⊢⇩h ⟨_, _⟩ ⇒ _" in impE, assumption)
apply (rename_tac s s' n ret)
apply (case_tac ret; (simp; fail)?)
apply (clarsimp simp: in_liftE[simplified liftE_def])
apply (erule allE, erule allE, erule_tac P="_ ∈ fst _" in impE, assumption)
apply (auto simp: unif_rrel_def)
```

它原文接着写"could be better written as"，下面是那三行：

<!-- 源码块：l4v/docs/compacting-proofs.md:34-36 -->
```text
by (fastforce simp: ccorres_underlying_def corres_underlying_def rf_sr_def Ball_def liftE_def
                       unif_rrel_def in_liftE[simplified liftE_def]
              split: xstate.splits dest!: ac_corres_ccorres_underlying)
```

差别不是行数，是**脆弱点**：上面那段把 `erule allE` 的个数、
`rename_tac` 的变量名、`case_tac ret` 的位置全写死了；
下面那段把这些交给 `fastforce` 自己找，改 `rf_sr_def` 时它更可能还活着。
18.7 结尾引的那段"方法只消样板、不追求全自动"，与这里的取向是同一件事：
**能命名的推理交给方法，剩下的展开式证明要压到一行**。

---

## 官方教程对照

| 官方文档 | 覆盖本章哪一段 | 本教程的处理 |
|---|---|---|
| `l4v/docs/conventions.md` | 两套框架、`_corres` 命名、`sts`/`sts'` 缩写 | 18.8 第 1、2 条 |
| `l4v/docs/haskell-assertions.md` | `nf`/`nf'` 与 `empty_fail` 的关系 | 18.8 第 3 条，坑位 5、6 |
| `l4v/docs/compacting-proofs.md` | 展开式证明要回头压缩 | 18.8 第 4 条，坑位 9 |
| `l4v/docs/crefine-notes.md` | `ccorres` 在 C 层怎么拆 | 第 19 章 |
| `l4v/docs/de-duplicating-proofs.md` | 规则再生、重复子目标 | 第 17 章 17.8 |

**1. `corres` 的两个开关取值有官方定名。** 文档里说得很重：
`l4v/docs/haskell-assertions.md` 第 32 行的原话是"For `corres`, we take the
strongest combination"——18.6 那句"义务全落在具体层"就是这句话的形式化。

**2. `ccorres` 那一套的用法官方另有专页。** `l4v/docs/crefine-notes.md` 从
符号执行、异常拆分到 `ccorres_split_nothrow` 的五条形都写了，
那是第 19 章的地图；本章只负责把两份定义并排放好。

**3. `empty_fail` 的方向，官方两处文字不一致。** 文档 `l4v/docs/haskell-assertions.md`
第 40 行那句写的是"失败标志置起 ⟹ 结果集为空"，
而同一棵树里 `l4v/lib/Monads/nondet/Nondet_README.thy` 第 128--129 行的释义、
以及 `Nondet_Empty_Fail.thy` 的定义本体给的都是反方向。
本教程按定义走，并把那句笔误标出来——它后面紧接着的推理用的也正是定义的方向。

**4. 本教程与官方口径不一致的地方仍然只有一类**：镜像里 `docs/Tutorials/`
下这几篇是占位文件，精化侧的官方内容全在 l4v 仓库自己的 `docs/` 里，
所以本节的引用全部落在 `l4v/docs/`。

---

## 本章坑位清单（实测）

1. **把 `corres` 定义成同类型的关系**：两个状态类型不同，写同类型直接类型冲突。
2. **以为状态关系是函数**：它是 `(抽象 × 具体) set`；需要"投影唯一"时单独证
   （`relation_is_functional`），需要"非空"时得写进前件（`corres_nreturn`）。
3. **结果关系一律写 `(=)`**：创建/删除类操作的值没意义，要用 `(\<lambda>_ _. True)`。
4. **把对应关系当成等价**：具体层可以在抽象层的两个结果里挑一个
   （`concrete_may_pick_one_abstract_result`），不可以凭空造第三个
   （`concrete_cannot_invent_a_result`）。
5. **以为"抽象失败 ⟹ 具体随便"是普遍事实**：只有当主句前件
   `nf ⟶ ¬ snd (m s)` 可为假时才随便；真实 `corres` 里 `nf = False`，
   前件恒真，于是 `corres_abstract_empty` 这类"抽象交不出、具体也交不出"成立。
6. **`nf`/`nf'` 当成对称开关**：`corres` 是 `False`/`True`，
   "不许失败"这条义务只落在具体层。
7. **把 `assert` 的失败分支拿出来证对应**：它进不了前件覆盖的状态；
   正确写法是把假设搬进 `G`/`G'`（`corres_nassert_both`、
   `corres_assert_assume_l`）。
8. **忘了 `corres_split` 那两条 `wp` 前件**：结论里后半段的前件是 `R rv`，
   没有 "`a` 跑完保住 `R`" 就换不过来。
9. **手工展开 `corres` 硬啃**：展开后 `case`、量词方向、`no_fail` 三样同时出现，
   18.4 那条"量词形状一改就推不动"就是同一件事的证据；用
   `Corres_Method.thy` 第 164 行的方法。
10. **在空关系上得到一条 `corres` 就以为有内容**：`corres_underlying {} …`
    对任何返回值关系都成立（`corres_empty_srel_trivial`），桥空着等于没说话。
11. **对 `swp`/`cte_at`/`cdt_relation` 的字段想当然**：`swp`、`cte_at` 不在这份代码树里
    （AbsSpec 会话），`l4v/proof/refine/StateRelation.thy` 第 291 行只是用它们。
12. **找错文件**：定义与通用引理在 `l4v/lib/Corres_UL.thy`，
    seL4 实例在 `l4v/proof/refine/Corres.thy`，方法在 `l4v/lib/Corres_Method.thy`，
    K 单子的对应另有一套 `corres_underlyingK`。
13. **把 `corres` 当成唯一一套框架**：C 侧那套叫 `ccorres`，参数多三类、没有失败位开关，
    而且它的 `case` 里非 `Normal` 出口直接要求 `False`（定义在 `l4v/lib/clib/Corres_UL_C.thy`）。
14. **出了 `context kernel` 还想用 `ccorres`**：那条 abbreviation 把状态关系和环境都钉死了，
    外面只能写 `ccorresG` 自己把 `rf_sr` 与 `Γ` 交出来。
15. **照抄官方文档里那句 `empty_fail` 的英文复述**：它写的是逆命题；
    定义是"结果集空 ⟹ 失败标志置起"，18.8 第 3 条那套论证用的也是这个方向。

---

上一章：[17 · 不变式](17-invariants.md) ｜ 下一章：[19 · C 规范与堆](19-cspec.md) ｜ 返回：[README](../README.md)
