# 22 · 非干扰（机密性）

对应示例：`../examples/S22_infoflow.thy`（13 节，59 条实测结论，编译零警告）

第 21 章说"不能乱改"，本章说"不能偷看"。听起来是一对，实际证明的难易程度差得远：
完整性是**逐条规则查表**（第 21 章那 16 条对象规则 + 5 类内存理由），
机密性要在**任意长的执行 trace** 上归纳，还要先有一个"谁会影响到谁"的
信息流图。这一章把 seL4 到底证了哪条、哪条同名性质恰恰**没被证**讲清楚。

## 22.1 目录、会话，以及那条没被证明的定理

机密性证明在 `l4v/proof/infoflow/`。同一目录的 `README.md` 第 7 行标题是
"Confidentiality Proof"，第 12 行给出定义口径——
"Information flow security is defined in terms of (intransitive) noninterference"，
**非传递**的非干扰；第 14 行写明它出自 2013 年 IEEE S&P 那篇论文，
并且整份证明先建立在第 21 章的 Access Control Proof 之上，
再经 `refine/` 与 `crefine/` 传到 C 实现。

会话表里的 `InfoFlow`（`l4v/proof/ROOT` 第 142 行）是这么挂的：

<!-- 源码块：l4v/proof/ROOT:142 -->
```text
session InfoFlow in "infoflow" = Access +
```

`InfoFlow` 的父会话就是 `Access`——"机密性站在完整性证明之上"的机械证据。
同文件第 146 行列的顶层理论是 `InfoFlow_Image_Toplevel`；
往下 `InfoFlowCBase`（第 148 行）与 `InfoFlowC`（第 158 行）是 C 侧的两段。

关键事实要先说：**文件名叫 `Noninterference.thy`，而 Noninterference 恰恰是没被证明的那条**。
自述就在该文件开头："The Noninterference property does not hold on the kernel and is
not proven despite the name of the file, but a partial integrity result holds in
integrity_part"。真正证到的是 Nonleakage，顶层结果记作
`nonleakage`（同文件第 4186 行），结论是 `ni.Nonleakage_gen`。

本章在一个人手可测的小模型里把这套层次逐条复现——包括这条反证：

```text
theorem noninterference_fails: \<not> Noninterference
```

模型只有三个域、一种事件，每一步都是函数，于是每条性质都能真的算出真假。

## 22.2 擦除：把高安全级的东西换成默认值

经典非干扰爱用"擦除"来讲：把高安全级的输入换成默认值再跑一遍。
seL4 走的是另一条路（`sources` + `ipurge`，见 22.7/22.8），
但擦除这一直觉值得先跑通，它就是"低观察者看不出差别"的朴素版本。

```text
theorem
  erase_touches_only_high:
    level_of ?p = Low \<Longrightarrow> ks_msgs (erase_high ?s) ?p = ks_msgs ?s ?p

theorem
  erase_zeroes_high: level_of ?p = High \<Longrightarrow> ks_msgs (erase_high ?s) ?p = 0

theorem erase_is_idempotent: erase_high (erase_high ?s) = erase_high ?s
```

高的清零、低的一动不动、擦两次等于擦一次。

这里藏着一个 Isabelle 层面的坑：`erase_is_idempotent` 比的是**记录**相等，
`rule ext` 只把函数相等拆开，记录得先 `cases s` 再逐字段比，
两个字段各自还要 `fun_eq_iff` 才能处理 `ks_msgs` 这种函数取值字段。

## 22.3 域：分区，外加一个"调度器分区"

真实的域类型是 `partition`（`Noninterference.thy` 第 36 行）：

<!-- 源码块：l4v/proof/infoflow/Noninterference.thy:36 -->
```text
datatype 'a partition = Partition 'a | PSched
```

观察者要么是某个分区，要么**就是调度器本身**。调度器必须单列，
因为它是"人人都看得见"的那部分状态（现在轮到谁、空闲线程是谁、调度器看到的全局量），
而这也正是 22.10 里 `integrity_u` 证不出来的地方。

策略就是 `noninterference_policy` 那个 locale 里的
`policy`（`Noninterference_Base.thy` 第 411 行）——那行的注释原话是 "who can send info to whom"。
模型里把它写成一个三域的可判定关系 `flows`，记 `u \<leadsto> v`，
两条关于调度器的公理照抄真实 locale 假设：

```text
theorem schedFlowsToAll: SchedD \<leadsto> ?v

theorem schedNotGlobalChannel: ?x \<leadsto> SchedD \<Longrightarrow> ?x = SchedD

theorem flows_Low: (LowD \<leadsto> ?v) = (?v \<noteq> SchedD)

theorem flows_High: (HighD \<leadsto> ?v) = (?v = HighD)

theorem flows_Sched: (SchedD \<leadsto> ?v) = True

theorem high_does_not_flow_low: \<not> HighD \<leadsto> LowD

theorem flows_refl: ?u \<leadsto> ?u
```

读法：调度器流向所有人（`schedFlowsToAll`），但**没人能流向调度器**
（`schedNotGlobalChannel`——只有调度器自己可以）；低分区流向除调度器外的一切；
高分区只流向自己。`flows_High` 与 `flows_Sched` 在模型里被 `\<leadsto>` 的
`case` 定义直接算成等式，这是"策略可判定"的标志——真实策略是一张 PAS 授权图，
`policyFlows` 要靠图可达性算。

真实的授权图长什么样，仓库里就有例子：`PolicyExample.thy` 第 581 行的注释
说第二个例子是教科书式的 "classic 'one way information flow' example"，
第 586 行给出四个标签：

<!-- 源码块：l4v/proof/infoflow/PolicyExample.thy:586 -->
```text
datatype auth_graph_label2 = High | Low | SharedPage | NTFN
```

配套的策略里最后还并了一条 `\<union> {(x,a,y). x = y}`——主体对自己的标签永远有权威。
同文件第 12 行那句 "Endpoints tend to spray information in all directions,
while notifications are unidirectional" 是端点与通知的区别在信息流口径下的说法（第 19、21 章）。

## 22.4 不可区分关系 uwr

真实的 `uwr` 在 `Noninterference.thy` 第 1498 行，定义只有一行：

<!-- 源码块：l4v/proof/infoflow/Noninterference.thy:1499 -->
```text
  "uwr \<equiv> same_for initial_aag"
```

也就是"把 PAS 固定成初始那份授权图之后的 `sameFor`"。
而 `sameFor`（第 91 行那个 `case d of`）分两支：
分区那支是 `sameFor_subject`（第 49 行定义、第 53 行开始展开），
调度器那支是 `sameFor_scheduler`。`sameFor_subject` 逐项列出
"这个分区看不看得到差别"：`cur_domain`、`globals_equiv`、`scheduler_action`、
`work_units_completed`、`irq_state`，以及只在 `user_modes` 成立时才比的
用户上下文——而且整串比较被一个前提门住着：
只有当该分区能读到当前运行域的标签时才开始比。

模型按同一副骨架简化成"当前域 + 自己那批信箱"：

```text
theorem uwr_refl: ?s \<sim>?u\<sim> ?s

theorem uwr_sym: ?s \<sim>?u\<sim> ?t \<Longrightarrow> ?t \<sim>?u\<sim> ?s

theorem uwr_trans: \<lbrakk>?s \<sim>?u\<sim> ?t; ?t \<sim>?u\<sim> ?v\<rbrakk> \<Longrightarrow> ?s \<sim>?u\<sim> ?v

theorem uwr_equiv_rel: equiv UNIV {(s, t). s \<sim>?u\<sim> t}

theorem schedIncludesCurrentDom: ?s \<sim>SchedD\<sim> ?t \<Longrightarrow> cur_dom ?s = cur_dom ?t
```

`uwr_equiv_rel` 对应真实的 locale 假设
`uwr_equiv`（`Noninterference_Base.thy` 第 494 行往上的那段）：
不可区分关系**必须**是等价关系，否则"分不出"没法传递地用。
注意它是"擦除后相等"，比状态相等弱得多——
`s \<sim>SchedD\<sim> t` 只要求 `ks_cur` 相同，别的字段随便差。

多域同时不可区分叫 `sameFor_dom`，记 `s \<approx>D\<approx> t`，
天然对 `D` 单调递减：

```text
theorem sameFor_subset_dom: \<lbrakk>?s \<approx>?x\<approx> ?t; ?y \<subseteq> ?x\<rbrakk> \<Longrightarrow> ?s \<approx>?y\<approx> ?t

theorem sameFor_sym_dom: ?s \<approx>?S\<approx> ?t \<Longrightarrow> ?t \<approx>?S\<approx> ?s
```

22.11 的归纳里 `sources` 只会越算越小，靠的就是这一条。

## 22.5 观察函数 out：真实那份实例化成了 undefined

`Noninterference_Base.thy` 的策略 locale 里有
`out :: 'd ⇒ 's ⇒ 'p`——每个域看得见的那部分状态。
而它的实例化结果是 `undefined`（`l4v/proof/infoflow/Noninterference.thy` 第 1517 行）：

<!-- 源码块：l4v/proof/infoflow/Noninterference.thy:1517 -->
```text
                             undefined               (* out -- unused *)
```

**这一行决定了整章的形状。** 模型里刻意保留 `out`：

```text
consts
  out :: "dom2 \<Rightarrow> kstate \<Rightarrow> dom2 \<times> (nat \<Rightarrow> nat) \<times> nat"

theorem output_consistent_holds: output_consistent
```

为的是把两族性质的分工显示出来：带 `out` 的那一族
（`obs_equiv` 第 490 行、`Noninterference` 第 564 行）要多一条
`output_consistent`（第 661 行）才推得动；
只带 uwr 的那一族（`uwr_equiv` 第 494 行、`Nonleakage_gen` 第 508 行）不要。
`out` 既然被实例化成 `undefined`，第一族就没有可用的入口——所以 seL4 证的是后者。

## 22.6 事件、Step 与可达状态

真实的"一步"是内核的**大阶**：`ADT_IF.thy` 把内核包装成
`big_step_ADT_A_if`（`l4v/proof/infoflow/ADT_IF.thy` 第 1581 行），第 1582 行写出的类型是
`(observable_if, observable_if, unit) data_type`——事件类型就是 `unit`，
一次"从用户态进内核再回用户态"。模型里一步做两件事：当前线程给自己信箱加一，
然后换下一个线程。

`Step`（`Noninterference_Base.thy` 第 96 行）是**关系**而不是函数，
定义是 `Step a ≡ {(s,s'). s' ∈ execution A s [a]}`：内核非确定，
什么时候被抢占、调度谁由环境决定。模型让它退化成函数，于是
`obs_det`（可观察部分确定，第 101 行）恒成立：

```text
theorem Step_iff: ((?s, ?s') \<in> Step ?a) = (?s' = advance ?s)

theorem exec_one: exec ?s [?a] = {advance ?s}

theorem obs_det_model: \<exists>s'. exec ?s ?as = {s'}
```

可达性 `reachable s ≡ ∃js. s ∈ execution A s0 js` 在模型里就是"是某步 `run n`"：

```text
theorem reachable_s0: reachable s0

theorem reachable_run: reachable (run ?n)

theorem reachable_advance: reachable ?s \<Longrightarrow> reachable (advance ?s)

theorem ks_cur_run: ks_cur (run ?n) = ?n
```

`run` 与 `exec` 都是 `fun`，终止性信息由工具自己算出来并打进输出，
实测两行都在这儿：

```text
Found termination order: "(\<lambda>p. size_list size (snd p)) <*mlex*> {}"

Found termination order: "size <*mlex*> {}"
```

`enabled_system`（第 126 行）那条假设看着平平无奇——
`enabled`（第 127 行）说"从可达状态出发，任何 trace 都走得出下一步"，
它的推论 `enabled_Step`（第 136 行）说"从可达状态出发 `Step a` 非空"。
但没有它，`sources_Cons`（第 483 行）里那个并集会在一对 `Step a = {}` 上塌成空集，
整条 purge 就把一切都删光：

```text
theorem sources_empty_without_Step: \<Union> (?P ` {}) = {}
```

模型里 `Step` 是函数，这条免费——但知道它为什么存在，比用上它更要紧。

## 22.7 sources：这条 trace 里谁会影响到 u

这就是 `sources`（`Noninterference_Base.thy` 第 481 行）那份 `primrec` 的形状。
非传递性的全部机关都在 `sources_Cons` 这一条递归里：事件**此刻**的域
`dom a s` 只有能流向"后面某个还会影响 `u` 的域"时，才算 `u` 的信息来源。
真实那份还紧跟着两句 `declare sources_Nil [simp del]`、
`declare sources_Cons [simp del]`（第 487、488 行）——默认 simp 集会把这条递归
到处展开，把证明炸开。模型照抄：

```text
theorem
  sources_Un:
    sources (?a # ?as) ?s ?u =
    sources ?as (advance ?s) ?u \<union>
    (if \<exists>v\<in>sources ?as (advance ?s) ?u. cur_dom ?s \<leadsto> v then {cur_dom ?s}
     else {})

theorem
  sources_tail_subset:
    sources ?as (advance ?s) ?u \<subseteq> sources (?a # ?as) ?s ?u

theorem sources_refl: ?u \<in> sources ?as ?s ?u
```

`sources_Un` 是把那个并集塌成一项之后的形状（模型里 `Step` 是函数），
`sources_tail_subset` 是归纳的全部负担，`sources_refl` 说"自己永远是自己来源"——
真实那份叫 `sources_refl`，同一个 locale 里。

下面两条就是真实的第 1179 与第 1184 行那对引理：

```text
theorem sources_Step: \<not> cur_dom ?s \<leadsto> ?u \<Longrightarrow> sources [?a] ?s ?u = {?u}

theorem
  sources_Step_2: cur_dom ?s \<leadsto> ?u \<Longrightarrow> sources [?a] ?s ?u = {cur_dom ?s, ?u}
```

真实版本多一个 `reachable s` 前提——那是为了用 `enabled_Step`（22.6），
模型里 `Step` 全定义，前提自然消失。这两条是 `Nonleakage_gen_confidentiality_u`
（第 1211 行）证明里唯一的展开工具。

再往下是"策略真的起作用"的地方：

```text
theorem sources_sched_is_sched: sources ?as ?s SchedD = {SchedD}

theorem low_sources_bounded: sources ?as ?s LowD \<subseteq> {LowD, SchedD}

theorem high_not_a_source_for_low: HighD \<notin> sources ?as ?s LowD
```

`sources_sched_is_sched` 是 `schedNotGlobalChannel` 的直接投影：
没人能流向调度器，所以调度器的来源集合永远只有它自己。
`high_not_a_source_for_low` 则是无论 trace 多长、非确定分支怎么走，
`HighD` 永远进不了 `LowD` 的信息来源集合——机密性的全部内容就是这一行。

## 22.8 ipurge：把与 u 无关的事件删掉

真实的 purge 分两层：`gen_purge`（第 529 行）把"来源判定"当参数，
`ipurge`（第 536 行）是 `ipurge = gen_purge sources` 的实例化。
模型照抄判定口径——注意用的是 `∃s∈ss`：只要 `ss` 里**有**一个状态
认为这个事件相关，就把它留下：

```text
theorem ipurge_shortens: set (ipurge ?u ?as ?ss) \<subseteq> set ?as

theorem
  ipurge_one_Sched:
    ipurge SchedD [?a] {?s} = (if cur_dom ?s = SchedD then [?a] else [])

theorem ipurge_two_Sched_from_s0: ipurge SchedD [Big, Big] {s0} = [Big]
```

`ipurge_one_Sched` 是 `sources_sched_is_sched` 的一事件版本；
`ipurge_two_Sched_from_s0` 是 22.11 那条反证的关键件——
从初始状态跑两个事件，purge 给调度器看的那条 trace 只剩一个，
**因为第二步换到了低分区，而低分区不许流向调度器**。

对低观察者来说，高分区世界里的每一步都可删：

```text
theorem ipurge_drops_high_world:
 (\<And>s. s \<in> ?ss \<Longrightarrow> cur_dom s = HighD) \<Longrightarrow>
 ipurge LowD (?a # ?as) ?ss = ipurge LowD ?as ?ss
```

证明里有一行值得留着，因为它解释了"事件类型是 `unit`"这件事在模型里怎么走：

```text
have a = Big
```

`datatype ev = Big` 是单构造子，`cases a` 之后手里就多一条 `a = Big`，
`simp add: ipurge_Cons` 才能把 `if` 判掉。

## 22.9 三条安全性质：obs、uwr、以及带 purge 的那条

三兄弟只差在**结论**，定义逐字对着真实文件的第 490、494、500、508、564 行抄：
`obs_equiv` 比观察值（`out d s' = out d t'`），`uwr_equiv` 比 uwr
（`s' \<sim>d\<sim> t'`），`Nonleakage` 用前者、`Nonleakage_gen` 用后者，
`Noninterference` 用前者且把第二条 trace 换成 `ipurge u as {s}`。
真实 `Nonleakage` 的第二条前提写的是 `s \<sim>schedDomain\<sim> t`，
模型里 `schedDomain` 就是 `SchedD`。

它们之间唯一的桥是 `obs_equivI`（第 742 行）：

```text
theorem uwr_equiv_imp_obs_equiv:
 \<lbrakk>output_consistent; uwr_equiv ?s ?as ?t ?bs ?d\<rbrakk>
 \<Longrightarrow> obs_equiv ?s ?as ?t ?bs ?d
```

`output_consistent` 一给上，uwr 版立刻推出 obs 版。
这条桥在 seL4 里**架不起来**——因为 `out` 是 `undefined`（22.5）。

## 22.10 两条 unwinding 条件：一条成立，一条不成立

整个机密性证明压在两条"只看一步"的条件上：
`confidentiality_u`（第 664 行）与 `integrity_u`（第 678 行）。
真实 `integrity_u` 的前提写的是 `(dom a s, u) ∉ policy`，
也就是"这一步的执行者不许流向 `u`"；模型里每个事件都由当前线程跑，
所以那就是 `\<not> (cur_dom s \<leadsto> u)`。

```text
theorem
  advance_preserves_uwr:
    \<lbrakk>?s \<sim>SchedD\<sim> ?t; ?s \<sim>?u\<sim> ?t\<rbrakk> \<Longrightarrow> advance ?s \<sim>?u\<sim> advance ?t

theorem confidentiality_u_holds: confidentiality_u
```

`confidentiality_u` 的四个前提在模型里刚好被 `advance_preserves_uwr` 吃下，
一条 `auto intro:` 就完事。

`integrity_u` 不成。反例落在分区边界上：

```text
theorem run_9_cur: cur_dom (run 9) = LowD

theorem not_self_uwr_SchedD_after_advance: (?s, advance ?s) \<notin> UWR SchedD

theorem
  integrity_witness:
    reachable (run 9) \<and>
    \<not> cur_dom (run 9) \<leadsto> SchedD \<and>
    (run 9, advance (run 9)) \<in> Step Big \<and>
    (run 9, advance (run 9)) \<notin> UWR SchedD

theorem integrity_u_fails: \<not> integrity_u

theorem
  run_9_switches_partition:
    cur_dom (run 9) = LowD \<and> cur_dom (run 10) = HighD
```

坏在哪一步：`run 9` 的当前线程是 9 号（`LowD`），走一步之后是 10 号（`HighD`）——
**换分区了**。对 `SchedD` 这个观察者来说"现在轮到谁"恰是它看得见的那部分
（`UWR SchedD` 就定义为 `ks_cur` 相等），
而"低分区不许流向调度器"（`schedNotGlobalChannel`）是策略硬要求的。
于是一步之后调度器就分出来了，`integrity_u` 在分区边界上必然失败。

这正是真实的 `integrity_part`（`Noninterference.thy` 第 1976 行）
为什么要在前提里写死 `u ≠ PSched` 与 `part s ≠ PSched`：
真实的完整性结果本来就只覆盖"非调度器"那一段。
同一个文件第 305 行还有一个更紧的版本
`partitionIntegrity`（`l4v/proof/infoflow/Noninterference.thy` 第 305 行），
它把 `pasMayActivate` 与 `pasMayEditReadyQueues` 两个开关显式置 `False`
之后再调用第 21 章的 `integrity`——这就是本章 uwr 所用的那份完整性关系。

## 22.11 主定理：Nonleakage_gen 成立，Noninterference 不成立

先证成立的那条。归纳负担全在"`sources` 随状态前进只会变小"：

```text
theorem advance_preserves_sameFor:
 \<lbrakk>?s \<sim>SchedD\<sim> ?t; ?s \<approx>?D\<approx> ?t\<rbrakk> \<Longrightarrow> advance ?s \<approx>?D\<approx> advance ?t

theorem
  nonleakage_gen_aux:
    \<lbrakk>reachable ?s; reachable ?t; ?s \<sim>SchedD\<sim> ?t; ?s \<approx>sources ?as ?s ?u\<approx> ?t\<rbrakk>
    \<Longrightarrow> uwr_equiv ?s ?as ?t ?as ?u

theorem nonleakage_gen: Nonleakage_gen
```

`nonleakage_gen_aux` 的归纳步实测就四刀，中间态全部打印在输出里：

```text
have sch: advance s \<sim>SchedD\<sim> advance t

have sf0: s \<approx>sources as (advance s) u\<approx> t

have sf: advance s \<approx>sources as (advance s) u\<approx> advance t

show uwr_equiv s (a # as) t (a # as) u
```

这里有个 Isabelle 层的实质教训：**归纳命题要写成 meta 形式
`\<lbrakk>…\<rbrakk> \<Longrightarrow> …`，不要写成对象层的 `… ⟶ …`**。
写成对象 `⟶` 时 `Cons.prems` 长度是 0，`local.Cons.prems(2)` 直接报
`Bad fact selection`；而且 `blast`/`simp` 都拆不掉开头那个 `∧` 去够里面的
curried `⟶`。另外这条引理的假设里 `s t` 必须用 `arbitrary: s t` 泛化，
否则归纳假设对不上 `advance s`。

真实的证明顺序与这里**相反**：第 1112 行那条 `Nonleakage_gen`
是 `confidentiality_u ⟹ Nonleakage_gen`（先有 unwinding 条件，再抬到无泄漏），
第 1211 行 `Nonleakage_gen_confidentiality_u` 是反方向——把 trace 取成长度一
就还原出 `confidentiality_u`：

```text
theorem one_step_uwr:
 \<lbrakk>Nonleakage_gen; reachable ?s; reachable ?t; ?s \<sim>SchedD\<sim> ?t;
  cur_dom ?s \<leadsto> ?u \<longrightarrow> ?s \<sim>cur_dom ?s\<sim> ?t; ?s \<sim>?u\<sim> ?t\<rbrakk>
 \<Longrightarrow> advance ?s \<sim>?u\<sim> advance ?t

theorem nonleakage_gen_confidentiality_u:
 Nonleakage_gen \<Longrightarrow> confidentiality_u
```

模型里 `confidentiality_u` 由 `confidentiality_u_holds` 直接成立，
两条方向合起来就是第 1221 行那条
`Nonleakage_gen_equiv_confidentiality_u`，内容是
`Nonleakage_gen = confidentiality_u`——
这条 unwinding 条件对 `Nonleakage_gen` 既**可靠**又**充分**。

然后是那条不成立的。反例正好落在调度器分区上：
策略禁止任何东西流向 `PSched`，于是 `ipurge` 把低分区的事件删了——
可"轮到谁"本身就是 `PSched` 的观察对象。

```text
theorem
  obs_equiv_two_vs_one: \<not> obs_equiv (run 0) [Big, Big] (run 0) [Big] SchedD

theorem obs_equiv_two_vs_one_s0: \<not> obs_equiv s0 [Big, Big] s0 [Big] SchedD

theorem noninterference_fails: \<not> Noninterference
```

`obs_equiv_two_vs_one` 说的是同一初态下，
"跑两步"与"跑一步"对调度器而言观察值不同（`ks_cur` 一个是 0、一个是 1），
而 `ipurge SchedD [Big, Big] {s0} = [Big]`（22.8）恰好把两步删成一步——
所以 `Noninterference` 逐字地在这里翻车。
证明里用了反证法：先假设 `Noninterference` 成立，实例化到 `s0`、`[Big, Big]`、
`SchedD`，再用那条 `ipurge` 等式把结论改成已被否证的形式。

反过来，`Nonleakage_gen` 加一条 `output_consistent` 就抬到 `Nonleakage`——
模型里 `out` 是真的，所以这座桥走得通；seL4 那边 `out := undefined`，走不通，
于是论文与代码给出的都是 `Nonleakage_gen`：

```text
theorem nonleakage: Nonleakage
```

## 22.12 Noninfluence：要两条条件一起才够

`Noninfluence_gen`（`Noninterference_Base.thy` 第 642 行定义、
第 643 行是那条 `∃s∈ts` 式的量化体）比 `Nonleakage_gen` 强，
因为它把 `ipurge` 掺进了第二条 trace。
它自己那段注释（第 636—638 行）说得很直白：
"to make the induction proof work for Noninterference"——
它是为了让 `Noninterference` 的归纳走得通而加的强版本。

真实文件第 1283 行那条 `Noninfluence_gen_integrity_u` 说的是
"它**蕴含**完整性条件"——前提还挂着 `complete_unwinding_system`
那个 locale 的 `policy_refl`（第 1280 行）：

```text
theorem Noninfluence_gen_integrity_u:
 Noninfluence_gen \<Longrightarrow> integrity_u

theorem noninfluence_gen_fails: \<not> Noninfluence_gen
```

模型里这条蕴含是手工走出来的，中间六刀全在输出里：

```text
have niu: \<forall>u as s ts.

have sf: s \<approx>sources [a] s u\<approx> s

have P: uwr_equiv s [a] s (ipurge u [a] {s}) u

have ne: cur_dom s \<noteq> u

have ip: ipurge u [a] {s} = []

have advance s \<sim>u\<sim> s

show integrity_u
```

`have ne` 那一刀用的是 `flows_refl`：既然 `u` 是自己的来源，
`¬(cur_dom s ↝ u)` 就必然推出 `cur_dom s ≠ u`——少了这一步，
`ipurge_Cons` 里那个 `∃s∈ss` 判不掉。

配上 22.10 的 `integrity_u_fails` 立刻得到 `noninfluence_gen_fails`。
这就解释了整件事：seL4 只证了**无泄漏**，没证**无影响**，
差的就是那条在调度器分区上失败的完整性条件。

## 22.13 xources：换成"所有分支"也一样的那版

`Noninterference_Base_Alternatives.thy` 第 14—16 行的自述是
"试探 `sources` 与 `ipurge` 的一堆替身定义，结果它们**全都等价**"。
最要紧的那个替身把 `sources_Cons` 里的 `\<Union>` 换成 `\<Inter>`，
判定条件从 `∃s∈ss` 换成 `∀s∈ss`——也就是"只要有一条分支认为相关就留"
改成"所有分支都认为相关才留"。非确定系统上这两者直觉差很远，
但在 `Step` 可观察确定的前提下会得到**同样**的安全性质
（同文件第 96 行的 `xNonleakage_gen`、第 441 行的
`Nonleakage_gen_xNonleakage_gen`）。

```text
theorem
  xources_Un:
    xources (?a # ?as) ?s ?u =
    xources ?as (advance ?s) ?u \<union>
    (if \<exists>v\<in>xources ?as (advance ?s) ?u. cur_dom ?s \<leadsto> v then {cur_dom ?s}
     else {})

theorem sources_eq_xources: sources ?as ?s ?u = xources ?as ?s ?u
```

不过真实那份 `xources_sources`（同文件第 108 行）是
`confidentiality_u ⟹ reachable s ⟹ xources as s u = sources as s u`——
等价要挂两条前提。模型里 `Step` 是函数，前提全用不上，
所以那条 `sources_eq_xources` 是裸的等式。
证明里 `Nil` 那支不要 `simp add: xources_Nil`：`primrec` 的方程默认就在 simp 集里，
再 `add` 一次会报 `Ignoring duplicate rewrite rule`。

本章最后由 ML 打印出八条结论，第 6 关就是拿它们跟正文逐行比：

```text
"HighD \<notin> sources ?as ?s LowD"

"\<not> integrity_u"

"\<not> Noninterference"

"Nonleakage_gen"

"Nonleakage"

"Noninfluence_gen \<Longrightarrow> integrity_u"

"\<not> Noninfluence_gen"

"sources ?as ?s ?u = xources ?as ?s ?u"
```

---

## 本章坑位清单（实测）

1. **以为文件名就是定理名**：`Noninterference.thy` 里 Noninterference 是**没被证明**的那条，
   顶层结果是 `nonleakage`（同文件第 4186 行），结论是 `Nonleakage_gen`。
2. **想找 `out` 的定义**：`Noninterference.thy` 第 1517 行那份是
   `undefined`，注释写着 "out -- unused"——`obs_equivI`（第 742 行）那座桥因此架不起来。
3. **把 `Noninfluence*` 当可得**：`Noninfluence_gen_integrity_u`（`Noninterference_Base.thy` 第 1284 行）说它蕴含
   `integrity_u`，而 `integrity_u` 只在 `integrity_part`
   （`Noninterference.thy` 第 1976 行，前提写死 `u ≠ PSched`）里成立。
4. **漏了调度器这个域**：`PSched`（`Noninterference.thy` 第 36 行那个
   `datatype 'a partition = Partition 'a | PSched`）既是观察者又是被观察者，
   22.10 的反例就长在它身上。
5. **`primrec` 方程又 `simp add` 一遍**：`xources_Nil` 之类默认就在 simp 集里，
   重复添加报 `Ignoring duplicate rewrite rule`（实测：加回来就是一条警告）。
6. **`sources` 的递归方程留在 simp 集里**：真实文件用两行 `declare`
   把它们删掉（`Noninterference_Base.thy` 第 487、488 行），
   否则 `sources_Cons` 会在任何含 `sources` 的目标上无限展开。
7. **归纳命题用对象层 `⟶`**：`Cons.prems` 长度是 0，
   `local.Cons.prems(2)` 报 `Bad fact selection`；`blast` 也拆不开开头那个 `∧`。
   写成 `⟦…⟧ ⟹` 才有 meta 前提可用。
8. **自由变量取名 `Cons`**：`Cons.IH` 报 `Undefined fact`（还附送一条
   "'Cons' shadows free bind" 警告）；改用 `Cons(1)`。
   想给 case 换名也不行——`case (Cns a as)` 报 `Undefined case: Cns`，case 名是固定的。
9. **`auto` 会先把事实展开再匹配**：`UWR_def` 被摊成 `case` 表达式、
   `ipurge`/`exec` 的 simp 规则被推进假设里，intro/dest 反而匹不上。
   该用 `blast` 或用 `fix v` 的结构化块时别硬撑 `auto`。
10. **`intro:` 推不动"还要先重写的前提"**：22.11 那条
    `nonleakage_gen_confidentiality_u` 要写 `auto dest: one_step_uwr [OF nl]`；
    换成 `intro:` 报 `Failed to refine any pending goal`。
11. **`by (rule <形如 ¬P 的引理>)`**：不 refine。反证一律
    `with <lemma> show False by blast`。
12. **定义常量不会在事实里自动展开**：`Noninfluence_gen_def` 要用
    `using ni by (auto simp: Noninfluence_gen_def)` 把事实放进目标里再展开；
    `iffD1` 直接对 `definition` 的 `≡` 用会报 `RSN: no unifiers`。
13. **三元 mixfix 两侧都是复合项**：`s \<sim>SchedD\<sim> advance s` 这种写法报
    `Ambiguous input … 4 parse trees`，给 `advance s` 加括号。
14. **集合等式里那个共享的 `if`**：`sources as (advance s) u ∪ …` 与
    `xources as (advance s) u ∪ …` 要合成一条等式，得先对条件
    `cases "(∃v∈… . cur_dom s \<leadsto> v)"`，还要 `sources_refl` 提供非空。
15. **对 `n` 归纳忘了 `arbitrary:`**：`run`/`sources`/`nonleakage_gen_aux`
    都要把状态泛化，否则归纳假设只能对固定的 `s` 用。
16. **裸调 `Suc.IH`**：要 `Suc.IH[OF Suc.prems(1) step_u]` 显式实例化。
17. **找证明找错目录**：机密性在 `l4v/proof/infoflow/`
    （会话 `InfoFlow` 挂在 `l4v/proof/ROOT` 第 142 行，父会话是 `Access`），
    完整性那边是 `l4v/proof/access-control/`，见第 21 章。

---

## 官方教程对照

[README](../README.md) 里那张"官方页 → 本章"映射表核对过十个页面
（`hello-world` 到 `mcs`，抓取日期 2026-09-25），**其中没有一页讲机密性证明**：
那套 kernel tutorials 面向用户态编程，讲到"seL4 是被验证的"时只给结论。
所以本章没有逐条对照表，只有三处**同名陷阱**要登记：

* 官方材料与论文标题上的 "noninterference" 是 `l4v/proof/infoflow/README.md`
  第 12 行那句 "(intransitive) noninterference"，它在代码里落实为
  `Nonleakage_gen`（`Noninterference_Base.thy` 第 508 行）；
  而同名定义 `Noninterference`（同文件第 564 行）**没有**被证明。
  口头说"seL4 证明了非干扰"指前者，读 `Noninterference.thy` 时按后者理解。
* 官方 MCS/调度教程里的 "domain" 是**调度单位**：能力是 `seL4_DomainSet`
  （`seL4/libsel4/include/interfaces/object-api.xml` 第 1336 行），
  内核侧的入口是 `invokeDomainSetSet`（`seL4/src/object/domain.c` 第 18 行）。
  本章的"域"（`'a partition`、`dom2`）是**信息流观察者**，由 PAS 的
  `pasDomainAbs` 给出标签，两者同名不同物。
* 官方文档里 "island" 是部署概念（一组共享策略的域，第 23 章），
  与信息流证明里的分区观察者 `PSched`（`Noninterference.thy` 第 36 行那个
  `datatype 'a partition = Partition 'a | PSched`）不是一回事。

外部 URL 本身不在第 5 关的校验范围内；本章凡说"真实代码是这么写的"，
后面都跟着一个被机器核对过的 `l4v/…` 路径与行号。

---

上一章：[21 · 完整性](21-integrity.md) ｜ 下一章：[23 · capDL](23-capdl.md) ｜ 返回：[README](../README.md)
