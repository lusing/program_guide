# 24 · 综合案例：take-grant 模型里，两个孤岛永远隔不开

对应示例：`../examples/S24_capstone.thy`（10 节、2880 行、零警告零失败，
`isabelle build` 实测 15.4 秒）

前 23 章都在证"内核的某一步/某一层是对的"。最后一章回答一个整体问题：

> **从两个互不可达的分区出发，任意多次合法操作之后，它们仍然互不可达。**

这个问题在 l4v 里不是没有答案，而是答案就躺在规范树里：
`l4v/spec/take-grant/` —— 六个理论、3077 行 Isabelle 源码，
一个抽象的 take/grant 安全模型。本章把它整条链条走一遍，
每一步都在自己的机器上编过。

## 24.1 先摆清仓库里到底有什么

`l4v/spec/take-grant/README.md` 的分工表与免责条款，一个字都没改：

<!-- 源码块：l4v/spec/take-grant/README.md:20-26 -->
```text
 * `System_S` contains the operations and state space of the model.
 * `Confine_S` shows authority confinement
 * `Islands_S` explicitly defines the concept of authority-isolated islands
   and authority confinement on this concept.
 * `Isolations_S` defines a notion of high-level information flow on
   take-grant authority and shows that islands stay isolated.
 * `Example` and `Example2` are two example systems in this model.
```

<!-- 源码块：l4v/spec/take-grant/README.md:41-43 -->
```text
 * This specification is *not* connected with the seL4 code and does *not*
   completely describe seL4 behaviour. Instead, it is a more abstract study
   of the underlying concepts.
```

第二段决定本章的口吻：**这不是精化，是概念层的研究**。
它上面没有任何通向 C 的定理，第 17–22 章那条链才是内核的证明。

六个理论的真实行数与角色：

| 文件 | 行数 | 角色 | 本章对应节 |
|---|---|---|---|
| `System_S.thy` | 539 | 状态空间、六个权利、八个操作、`legal` | 24.2–24.5 |
| `Confine_S.thy` | 1070 | `leak`、`tgs_connected`、`authority_confinement` | 24.6–24.7 |
| `Islands_S.thy` | 58 | `island`、`island_caps`、孤岛版不变式 | 24.8 |
| `Isolation_S.thy` | 106 | `set_flow`、`flow`、`information_flow` | 24.9 |
| `Example.thy` | 92 | 三实体最小可算系统 | 24.3、24.10 |
| `Example2.thy` | 1212 | 十一个操作的模拟 + 终态隔离结论 | 24.10 |

## 24.2 状态空间：六个权利、一条能力、一个实体

`entity_id` 在真实文件（`l4v/spec/take-grant/System_S.thy` 第 25 行）是
`word32`，注释原话是 "kernel objects - identified by a UID"。
本章换成 `nat`——所有引理都不涉位宽，换掉只让打印更短。
三样东西的型打印出来就是这样：

```text
"cap"

"entity"

"nat \<Rightarrow> entity option"
```

第三行是本章最容易看错的地方：**状态就是一个从实体到实体的部分函数**，
没有堆、没有槽、没有地址。权利也不是第 3 章那套
`AllowRead/AllowWrite/AllowGrant`，而是六个：

| 权利 | 含义 | 是不是权威 |
|---|---|---|
| `Read` | 读目标承载的信息 | 否，数据权利 |
| `Write` | 写目标承载的信息 | 否，数据权利 |
| `Take` | 把别人手里的能力拿走 | 是 |
| `Grant` | 把能力传给别人 | 是 |
| `Create` | 造新对象 | 是 |
| `Store` | 往目标里存能力（注释写着 "Simulates CNodeCap"） | 是 |

"后四个是权威、前两个不是"这个区分是整章的枢纽：
隔离定理管权威，信息流定理管的才是数据。

`entity` 只有一个构造子，但简化器不会自动把
`case x of Entity caps ⇒ f caps` 摊开——`System_S.thy`
第 40 行为此写了一行 `declare entity.splits [split]`。
少了它，本章 24.4 之后的化简全会卡在 `case` 上。
这是"仓库里的规范能编过、自己重打一遍编不过"最典型的出处之一。

`all_rights` 那两条也在真实文件里：

```text
theorem
  all_rights_def2: all_rights = {Read, Write, Take, Grant, Create, Store}
```

本章这份证明最后一步是 `cases x`，本质是穷举一个有限类型——第 17 章见过的手法。
仓库里的 `all_rights_def2`（`l4v/spec/take-grant/System_S.thy` 第 56 行）
走的是 `metis right.exhaust`，同一个穷举、两种入口。

## 24.3 一个算得出来的系统：三条边、两个孤岛

`Example.thy` 用三个实体演示 `caps_of` 怎么算。本章要演示的东西更多，
自己造了个五实体系统，故意让四条能力各代表一类：

| 名字 | 目标 | 权利 | 造出什么 |
|---|---|---|---|
| `cA` | 1 | `{Store}` | 一条真正的存能力边 0→1 |
| `cB` | 2 | `{Take, Grant}` | 权威，但不是 Store，**没有边** |
| `cC` | 5 | `{Create}` | 5 **根本不存在**，悬空 |
| `cD` | 3 | `{Read, Write}` | 纯数据权利，也没有边 |

于是整个 `store_connected_direct` 恰好一条边：

```text
theorem
  scd_sample:
    ((?x, ?z) \<in> store_connected_direct sample_state) = (?x = 0 \<and> ?z = 1)

theorem scd_sample_1_2: (1, 2) \<notin> store_connected_direct sample_state

theorem scd_sample_3_5: (3, 5) \<notin> store_connected_direct sample_state

theorem scd_sample_4_3: (4, 3) \<notin> store_connected_direct sample_state
```

闭包这一步必须归纳，`simp` 算不出 `rtrancl`：

```text
theorem
  sc_sample:
    ((?x, ?z) \<in> store_connected sample_state) = (?x = ?z \<or> ?x = 0 \<and> ?z = 1)
```

`caps_of` 因此几乎不扩张，只有 0 多看见一条：

```text
theorem caps_of_sample_0: caps_of sample_state 0 = {cA, cB}

theorem caps_of_sample_1: caps_of sample_state 1 = {cB}

theorem caps_of_sample_5: caps_of sample_state 5 = {}
```

`caps_of_sample_5` 那一行值得停一下：5 不存在，`caps_of` 却是**总函数**，
返回空集而不是"没有这一项"。整个模型的实体表就是一个
`nat ⇒ entity option`，不存在与"存在但手里没能力"在 24.7 会分开起作用。

这里刻意把 `caps_of sample_state n` 的结论写成一条带 `n` 的等式
（`[simp]` 挂上），而不是六条带数字的等式：`nat` 的字面量在项里会以
`Suc` 的形式出现，只有带模式变量的规则能 rewrite 掉任何写法。

## 24.4 八个系统调用，以及"合法"到底查什么

`legal` 是 `System_S.thy` 第 156 行起的一个 `primrec`（157 行是它的型），
八个分支各有前提。
在这台样本系统上跑一遍，三条不合法、一条合法：

```text
theorem illegal_take_sample: \<not> legal (SysTake 1 cB cA {Take}) sample_state

theorem illegal_revoke_of_none: \<not> legal (SysRevoke 5 cC) sample_state

theorem illegal_create_sample: \<not> legal (SysCreate 3 cC cC) sample_state

theorem legal_destroy_sample: legal (SysDestroy 3 cC) sample_state
```

`SysDestroy` 那条"全局唯一引用"的检查在这里真的起作用了：
`cC` 指向 5，而 `only_cC_targets_5` 说全系统只有它一条指着 5，两条检查都过。
换成 4 手里那条 `cD` 就立刻不合法——不过挡住它的**不是**"别人还指着 3"：
第二条判据把 `c` 自己从 `all_caps_of s` 里减掉再看目标集，
剩下 `cA`/`cB`/`cC` 的目标是 `{1, 2, 5}`，3 不在里面，这一半其实成立；
过不去的是 `{Create} = rights c`（`cD` 只有 `{Read, Write}`）。
**两条检查是合取关系**，任一不过整体就不过。
这台样本有个盲区值得说明：`Create` 只出现在 `cC` 一条上，
所以"权利够、但目标被别人也指着"那一格在这里演不出来——
再加一条带 `Create` 的能力，就会同时破坏 `only_cC_targets_5`，
把上面这条合法销毁一起改掉。

单步语义有两条形状必须记住：

```text
theorem step_illegal_is_skip: \<not> legal ?cmd ?s \<Longrightarrow> step ?cmd ?s = {?s}

theorem self_in_step: legal ?cmd ?s \<Longrightarrow> ?s \<in> step ?cmd ?s
```

第二条常被忽略：`step cmd s` 是一个**集合**，
定义是 `step' cmd s ∪ {s}` 那一路，所以合法调用的结果集里
**永远还带着调用前的状态本身**。24.7 的"单步不产生新连接"因此
不必区分"变了"与"没变"两种情况。

序列语义 `execute` 在 `System_S.thy` 第 325 行，是**倒着执行**的：

```text
theorem
  execute_two_back_to_front:
    execute [?cmd\<^sub>1, ?cmd\<^sub>2] ?s = \<Union> (step ?cmd\<^sub>1 ` step ?cmd\<^sub>2 ?s)
```

于是"全部非法的调用序列"就是原地不动，而且这个结论能用一条具体序列验证：

```text
theorem
  execute_two_illegal_calls_do_nothing:
    execute [SysTake 1 cB cA {Take}, SysRevoke 5 cC] sample_state =
    {sample_state}
```

## 24.5 权威序：把 Create 读成"全部权利"

全章唯一一处"模型比实现更狠"的地方是 `extra_rights`
（`l4v/spec/take-grant/Confine_S.thy` 第 17 行就有定义，本章照抄）：
一条能力若带 `Create`，比较时先摊平成全部六个权利。

```text
theorem extra_rights_idem: extra_rights (extra_rights ?c) = extra_rights ?c

theorem target_extra_rights: target (extra_rights ?c) = target ?c

theorem
  rights_extra_rights:
    rights (extra_rights ?c) =
    (if Create \<in> rights ?c then all_rights else rights ?c)

theorem extra_rights_no_create: Create \<notin> rights ?c \<Longrightarrow> extra_rights ?c = ?c
```

在样本系统上，摊平只发生在 `cC` 那一支：

```text
theorem extra_rights_cA: extra_rights cA = cA

theorem extra_rights_cC: rights (extra_rights cC) = all_rights

theorem cC_incap_full5: cC \<in>cap {full_cap 5}

theorem full5_incap_cC: full_cap 5 \<in>cap {cC}
```

后两条一起说明：带 `Create` 的能力与指向同一目标的全权利能力
在 `∈cap` 这个序下**互相等价**。也就是说这个模型认为
"能造 5 这个对象"≈"对 5 有全部权利"——24.10 会看到这一步在实现里并不成立。

不摊平的那些权利则一分证据都通不过：

```text
theorem take_cap_not_incap_cD: \<not> take_cap 3 \<in>cap {cD}

theorem grant_cap_not_incap_cD: \<not> grant_cap 3 \<in>cap {cD}
```

`cD` 只有 `{Read, Write}`，所以任何权威权利都不被它支配。

> **实测坑（本章最贵的一条）**：`extra_rights_no_create` 是**本章自己写的**
> 一条带假设的等式（仓库里只有 `extra_rights_idem` 那种无假设的重写，
> 见 `l4v/spec/take-grant/Confine_S.thy` 第 24 行）。
> 本章第一次给它挂上 `[simp]`，`by simp` 从 3.3 秒涨到 100 秒以上还没结束——
> 简化器会反复把它往 `extra_rights` 上套，每套一次都要再跑一遍子简化去证
> 那个 `Create \<notin> rights c` 前提。改成不带 `[simp]` 的同名引理后
> 全章回到 15 秒。**带假设的重写规则进 simp 集之前，先量一次时间。**

## 24.6 "连着"：一条泄漏就是一条边

`leak`（`l4v/spec/take-grant/Confine_S.thy` 第 82 行）说：
x 对 y 有泄漏，当且仅当 y 能拿走 x 的 Take 能力、
或 x 手里有指向 y 的 Grant 能力、或两人**共享**某个对象
（同一目标的 `Store` 能力两边都有）。连接关系就是
`leak` 与其反向之并，再取自反传递闭包：

```text
theorem sample_tgs_store: sample_state \<turnstile> 0 \<leftrightarrow> 1

theorem sample_tgs_take: sample_state \<turnstile> 1 \<leftrightarrow> 2

theorem sample_tgs_create: sample_state \<turnstile> 3 \<leftrightarrow> 5

theorem sample_tgs_data: (4, 3) \<notin> directly_tgs_connected sample_state

theorem sample_not_tgs_0_3: (0, 3) \<notin> tgs_connected sample_state

theorem sample_tgs_4: sample_state \<turnstile> 4 \<leftrightarrow>* ?z = (?z = 4)
```

三条边各自说明一件事：Take/Grant/Create **直接**造边，
因为它们都靠 `caps_of` 判定，而 `caps_of` 已经是
`Store` 闭包之后的东西；`cD` 那种纯数据权利**一条边都不造**。
于是 4 是一个只有自己一个人的孤岛——
最后一行 `sample_tgs_4` 说它的闭包就是 `{4}`。

样本系统的闭包算得完全干净，一条等式说完：

```text
theorem
  sample_tgs_exhaust:
    sample_state \<turnstile> ?a \<leftrightarrow>* ?b =
    (?a = ?b \<or> ?a \<in> {0, 1, 2} \<and> ?b \<in> {0, 1, 2} \<or> ?a \<in> {3, 5} \<and> ?b \<in> {3, 5})
```

`{0,1,2}` 与 `{3,5}` 就是 24.8 的两个孤岛。注意 5 明明不存在，
却被 3 的 `Create` 能力拽进了 3 的孤岛——这就是 24.5 那次摊平的直接后果。

## 24.7 单步不产生新连接：全章最长的一节

`Confine_S.thy` 用 1070 行只证一句话：**任何一步都不会凭空造出连接**。
它的骨架是把八个操作（外加 `generalOperation` 那个模板）逐个证明
"操作后存在的边，操作前在闭包里已经连通"，然后一次 case 分发收尾：

```text
theorem
  connected_tgs_connected:
    \<lbrakk>?s' \<in> step ?cmd ?s; ?s' \<turnstile> ?e\<^sub>x \<leftrightarrow> ?e\<^sub>y\<rbrakk> \<Longrightarrow> ?s \<turnstile> ?e\<^sub>x \<leftrightarrow>* ?e\<^sub>y

theorem
  tgs_connected_preserved_step:
    \<lbrakk>?s' \<in> step ?cmd ?s; ?s' \<turnstile> ?x \<leftrightarrow>* ?z\<rbrakk> \<Longrightarrow> ?s \<turnstile> ?x \<leftrightarrow>* ?z

theorem
  tgs_connected_preserved:
    \<lbrakk>?s' \<in> execute ?cmds ?s; ?s' \<turnstile> ?x \<leftrightarrow>* ?y\<rbrakk> \<Longrightarrow> ?s \<turnstile> ?x \<leftrightarrow>* ?y
```

第一条到第二条之间是 `rtrancl_induct`，第二条到第三条之间是对 `cmds` 归纳。
链子**必须**停在 `directly_tgs_connected` 这一层，
归纳规则本身在这里有三处会咬人，本章逐条试过：

1. 裸写 `apply (erule rtrancl_induct, simp)` 直接**方法失配**——目标里的闭包
   是 `tgs_connected_def` 那串并起来的写法，规则要求先跟一个具体关系合一，
   所以 `r` 必须显式实例化。
2. `r` 实例化之后，归纳步的目标长这样（同一次试验的实测打印）：

<!-- 示意块：一次试验里 apply 失败时打印的目标，不是抽取区间的产物 -->
```text
⋀y z. ⟦s' ∈ step cmd s; s' ⊢ x ↔* y; s' ⊢ y ↔ z; s ⊢ x ↔* y⟧
      ⟹ s ⊢ x ↔* z
```

   中间点 `y` 与**被重新引入的同名 `z`** 一块出现：假设说的是 `x` 到 `y`
   已连通，目标却要 `x` 到新的 `z`，`erule tgs_connected_trans` 在这种目标上
   同样失配。必须先 `case_tac "s ⊢ y ↔* z"` 把新边分成"后半段早就连通"与
   "新走的这条是 `s'` 的直接边"两支。
3. 仓库里
`tgs_connected_preserved_step`（`l4v/spec/take-grant/Confine_S.thy` 第 964 行）
就在 apply 之前留了一行 `thm`（同文件第 966 行），把实例化后的规则先打印出来
再照抄——上面那三处，正是那行 `thm` 要替作者回答的问题。本章的写法与它逐字相同：

<!-- 源码块：l4v/spec/take-grant/Confine_S.thy:968-969 -->
```text
  apply(erule rtrancl_induct [where r="directly_tgs_connected s'",
                              simplified tgs_connected_def [symmetric]], simp)
```

顺带一条反向实测：`where r=… and b=…`（甚至再带 `and P=…`）**并不会**失败，
本章试过，照样 100% 编过。真正过不去的是"连 `r` 都不实例化"，
不是"实例化了 `b`"。

有了不变式，`leak` 与权威序的结论都是它的推论：

```text
theorem
  leakage_rule:
    \<lbrakk>?s' \<in> execute ?cmds ?s; (?x, ?y) \<notin> tgs_connected ?s\<rbrakk> \<Longrightarrow> \<not> ?s' \<turnstile> ?x \<rightarrow> ?y

theorem
  caps_of_op:
    \<lbrakk>?s' \<in> step ?cmd ?s; ?c' \<in> caps_of ?s' ?x\<rbrakk>
    \<Longrightarrow> \<exists>z. ?s \<turnstile> ?x \<leftrightarrow>* z \<and> ?c' \<in>cap caps_of ?s z

theorem
  authority_confinement:
    \<lbrakk>?s' \<in> execute ?cmds ?s; \<forall>e\<^sub>i. ?s \<turnstile> ?e\<^sub>x \<leftrightarrow>* e\<^sub>i \<longrightarrow> caps_of ?s e\<^sub>i \<le>cap ?c\<rbrakk> \<Longrightarrow>
    caps_of ?s' ?e\<^sub>x \<le>cap ?c
```

`authority_confinement` 就是"权威约束"四个字的定义：
只要**出发之前** x 的整个连通闭包都被 `c` 支配，
运行任意长一段之后 x 能看到的仍然被 `c` 支配。
归纳那部分压在 `authority_confinement_helper` 上——
`Confine_S.thy` 第 1045 行起的 `proof (induct cmds arbitrary: s')`，
Cons 分支里靠 `tgs_connected_preserved_step` 把闭包搬回操作前（第 1059 行）；
到了第 1064 行，`authority_confinement` 自己只剩一句 `erule … [rule_format]`。

## 24.8 Island：把不变式改写成一句话

`Islands_S.thy` 全文 58 行，唯一的新概念是把 24.7 的闭包起个名字：

```text
theorem island_sample_0: island sample_state 0 = {0, 1, 2}

theorem island_sample_3: island sample_state 3 = {3, 5}

theorem island_sample_4: island sample_state 4 = {4}

theorem island_sample_5: island sample_state 5 = {3, 5}
```

前三个就是 24.6 那条 `sample_tgs_exhaust` 的三个等价类；
第四个是本章唯一一处"反向连通"：5 不存在，但它的孤岛是 `{3,5}`，
因为 3 与 5 之间的边是**对称**的（`directly_tgs_connected` 取 `leak` 与其反向之并）。

`island_caps` 是岛内所有人能力的并，而 `island_caps_dom`
把"这个并被一条能力支配"翻译成逐点条件，于是不变式只剩一句话：

```text
theorem
  authority_confinement_islands:
    \<lbrakk>?s' \<in> execute ?cmds ?s; island_caps ?s ?x \<le>cap ?c\<rbrakk>
    \<Longrightarrow> island_caps ?s' ?x \<le>cap ?c
```

这一条与 24.7 最后那条的差别只是措辞——`authority_confinement_islands`
（`l4v/spec/take-grant/Islands_S.thy` 第 42 行）的证明只有 46–56 那 11 行，
全在调用 24.7 的东西。

## 24.9 从权威流到信息流

最后一步换的是**看的角度**。`Isolation_S.thy` 全文 106 行只加了三个定义：
`set_flow`（`l4v/spec/take-grant/Isolation_S.thy` 第 12 行）
把"两组实体之间有数据流"定义为"其中某人手里有指向另一人的读能力，
或那人手里有指向对方的写能力"；
第 23 行的 `flow` 把点提升到整座岛，第 37 行的 `flow_trans` 再取闭包。
它用的只有 `Read` 与 `Write` 两个权利——24.7 那套权威结论它一条都不新证，
全靠 `caps_of` 与 `island` 已经在手。

```text
theorem set_flow_B_C: ({3, 5}, {4}) \<in> set_flow sample_state

theorem set_flow_C_B: ({4}, {3, 5}) \<in> set_flow sample_state

theorem set_flow_B_B: ({3, 5}, {3, 5}) \<in> set_flow sample_state

theorem flow_3_4: sample_state \<turnstile> 3 \<leadsto> 4

theorem no_flow_0_4: (0, 4) \<notin> flow sample_state

theorem no_flow_trans_0_4: (0, 4) \<notin> flow\<^sup>* sample_state
```

前两条是同一条 `cD` 的两个半边——它同时带 `Read` 与 `Write`，
而 `set_flow` 的两个方向各问一半：`X→Y` 问 `read_cap x` 在不在 y 的能力集，
`Y→X` 问 `write_cap y` 在不在 x 的能力集。
第三条 `set_flow_B_B` 才是这套定义真正粗的地方：
它靠的是 3 手里那条带 `Create` 的 `cC` 被 `extra_rights` 摊平成全部权利，
于是"岛 `{3,5}` 内部"自己就有一条流——24.5 那一次摊平的账，
在这里第一次以**数据流**的形式出现。
而 0 与 4 之间连一步都走不通——最后两行就是它的机器实测。

闭包那一行不是"没试出来"，是 `rule` 级的事实：
`flow sample_state` 的两端都被关在 `{3,4,5}` 里——

```text
theorem
  flow_within_345: sample_state \<turnstile> ?x \<leadsto> ?y \<Longrightarrow> ?x \<in> {3, 4, 5} \<and> ?y \<in> {3, 4, 5}

theorem flow_trans_from_0: (0, ?z) \<in> (flow sample_state)\<^sup>* \<Longrightarrow> ?z = 0
```

于是从 0 出发的任何闭包路径一步也迈不出去。这正是
`Example2.thy` 用的招：把整条 `flow_trans s` 折进一个 `inv_image`，
`flow_in_inv_image`（`l4v/spec/take-grant/Example2.thy` 第 1174 行）
就是那一步，谓词成立与否一分类就完事。

最后是全章的终点，也是 `information_flow`
（`l4v/spec/take-grant/Isolation_S.thy` 第 100 行）的原文形状：

```text
theorem
  information_flow:
    \<lbrakk>?s' \<in> execute ?cmds ?s; (?x, ?y) \<notin> flow\<^sup>* ?s\<rbrakk> \<Longrightarrow> (?x, ?y) \<notin> flow\<^sup>* ?s'
```

读法：**出发时没有信息流，运行之后仍然没有**。
它的证明全程在 `tgs` 闭包上走，因为 `set_flow` 用的是 `caps_of`，
而 `caps_of` 是沿 `tgs` 的 `Store` 闭包并出来的——
权威是信息流的粗粒度上界，这正是第 22 章
`sources`（22.7，"这条 trace 里谁会影响到 u"）那一层要表达的意思。

## 24.10 这个模型没有证明什么

**会话长什么样。** `TakeGrant`（`l4v/spec/ROOT` 第 124 行）只列四个叶子：

<!-- 源码块：l4v/spec/ROOT:124-129 -->
```text
session TakeGrant in "take-grant" = Word_Lib +
  theories
    "System_S"
    "Isolation_S"
    "Example"
    "Example2"
```

`Confine_S` 与 `Islands_S` 都在 import 链上被顺带构建。
所以"目录里有六个理论"和"会话清单里只有四个"同时成立，
看 ROOT 别按清单数文件。构建命令是 README 第 35 行的
`L4V_ARCH=ARM ./run_tests TakeGrant`，而 `l4v/run_tests`
第 14 行的 `L4V_ARCH_DEFAULT` 本来就是 `ARM`。
另一路 `Refine`（`l4v/proof/ROOT` 第 29 行）从头到尾
没有 import 过 take-grant 的任何理论：两边互不相干。

**示例算到哪里就停了。** `Example.thy` 只 import `System_S`（第 8 行），
连 `leak` 都不用；它的全部价值是把 `direct_caps_of` 与 `caps_of` 的落差
算成具体集合——`de0`（第 25 行）给 0 直接那一条 `Store` 能力，
`ce0`（第 71 行）给 0 看得见的两条，多出来的 `Grant` 是顺着 `Store` 边
从 1 那里并过来的。能力本身不传播，传播的是"能看见哪些直接能力表"。

`Example2.thy` 才是手动模拟：`e0_caps`（第 31 行）是
`range create_cap` 加上对自己的全权利；`op0` 到 `op10` 十一条操作定义齐全，
但真正跑的那条序列 `ops`（第 136 行）只有八项
`[op10, op9, op8, op7, op3, op2, op1, op0]`，从后往前逐个推进。
每个操作三条引理
（`legal` / `safe` / `live`）合成一条等式，比如第 373 行的
`step op0 s0 = {s0, s1}`。为什么拆两半？因为 `step` 是分支和，
直接证等式要同时管"合法时得到什么"与"非法时什么都不变"。

**这一节最值得抄的是它停下来的地方。** 全文件有五个 `oops`：

* `ops` 上一行的注释（第 133 行）写着 "since the CDT isn't defined,
  op6 is skipped"——`op6` 是唯一那条 `SysRevoke`（第 118 行），
  revoke 的正确语义要依赖 capability derivation tree 的删除顺序，
  模型里没有 CDT。于是 `execute_op6_safe`（第 537 行）、两条**同名**的
  `execute_op6_live`（第 544 与 552 行）、合成式 `execute_op6`（第 556 行）
  一共留了四个 `oops`。
* 第 532 行的注释写 `SysRevoke 0 (read_cap 2)`，
  第 118 行的定义却是 `write_cap`。注释与定义不一致，
  而**定义才是被证明引用的那一份**。
* `into_rtrancl2`（第 749 行）也停在一个 `oops`，
  它前面第 751 行还留着一条 `thm` 调试命令——作者卡住时打印过规则。

这五处都不影响结论，因为结论不需要它们：终态 `s` 到得了，
靠的是 `s7`（第 73 行）与 `s10`（第 90 行）都被定义成 `s4`，
所以 `ops` 里跳过 op4/op5/op6 之后链条仍然接得上，
`execute_ops`（第 689 行）证明里那句 `simp add: s7_def`
干的就是把 `s7` 折回 `s4`。

有了终态，三步就走到本章的结论：`island_e0`
（`l4v/spec/take-grant/Example2.thy` 第 1071 行）算出
0 的孤岛是 `{i. i ≠ 1 ∧ i ≠ 2}`（**连不存在的实体都在里面**，
因为空实体的 `caps_of` 是空的）；`flow_in_inv_image`（第 1174 行）
把 `flow s` 压进 `inv_image Id (λx. x = 1 ∨ x = 2)`；
`e0_e1_isolated`（同文件 1203 行）套本章 24.9 那条 `information_flow`，
对任意调用序列同时关掉两个方向。中间还夹了一条 `e0_e1_leakage`（第 1058 行），
它用的是 24.7 的 `leakage_rule`：0 与 1 之间连一次 `leak` 都没有，
比"没有数据流"更强。

**回到 C。** 抽象模型的六个权利在实现里不是一个通用位段，
而是每种能力各自决定要不要留位：

| 模型 | 实现锚点 | 实测事实 |
|---|---|---|
| `Read`/`Write` | `endpoint_cap`（`seL4/include/object/structures_64.bf` 第 24 行） | 四个 1 位字段：`capCanReceive`、`capCanSend`、`capCanGrant`、`capCanGrantReply` |
| `Grant`/`Take` | 同一条 `endpoint_cap` | `maskCapRights` 只把 `capAllowGrant(Reply)` 与两个 `CanGrant*` 相与 |
| `Store` | `cnode_cap`（`seL4/include/object/structures_64.bf` 第 71 行） | **一个权利位都没有**，只有 radix、guard、guard size、指针 |
| `Create` | `maskCapRights`（`seL4/src/object/objecttype.c` 第 441 行） | `cap_untyped_cap` 那一串 case 直接 `return cap`，掩不掉 |

被复制的能力先过一遍 `rightsFromWord`
（`seL4/src/object/cnode.c` 第 124 行），
紧接着第 125 行的那句 `maskCapRights` 才落下掩码——
`CNodeCopy` 那一条分支里，掩码只作用在源能力上；
用户传进来的那个字由 `rightsFromWord`
（`seL4/include/api/types.h` 第 52 行）包成 `seL4_CapRights`，
四个允许位在 `capAllowWrite`
（`seL4/libsel4/mode_include/64/sel4/shared_types.bf` 第 25 行）那一族，
而同文件 `seL4_CapRights_t`（`seL4/include/api/types.h` 第 20 行）
那句注释写的 `mode/api/shared_types.bf` 是历史遗留路径。

所以 24.5 那次"把 `Create` 摊成全部权利"在实现里并不成立：
untyped 与 CNode 两类能力**根本不接受掩码**。
这不是精化，是比喻——模型抓的是"权威能不能传"，
实现管的是"这一位能不能清"。

**四条没有证明，说清楚：**

1. README 第 41 行的免责声明：与 seL4 代码**没有连接**，也**不完全描述**
   seL4 行为；它上面没有任何精化定理，
   `l4v/proof/ROOT` 里 `Refine` 那一路也不 import 它。
2. README 第 24 行把文件名写成了 `Isolations_S`，磁盘上是单数的
   `Isolation_S.thy`——照着 import 会直接失败。
3. 实体是扁平的 `cap set`，没有 CNode 深度、guard、index，
   所以"能不能构造出某条能力"这类实现层攻击面本章完全没有建模。
4. `Example2` 只算了 `ops` 那条固定序列到达的终态，
   外加一条关于任意 `cmds` 的 `execute` 结论；
   它不是"任何策略都隔离"，而是"从这个起点出发、任何后续调用串都隔离"。
   **起点本身是否可达，模型不管。**

这四条不是本章的缺点。take-grant 证的是权威约束这一层**概念**为什么站得住，
第 17–22 章那条精化链证的才是这台内核。两件事，别混着说。

---

## 24.11 对拍：Microkit 把这张图编译进镜像

24.10 说这台样本系统什么也没证明。那"分区隔离"在真实系统里到底长什么样？
官方给的答案是 Microkit，手册在 `microkit/docs/manual.md`（v2.3.1，2098 行），
它的第一段就把立场摆明了：

<!-- 源码块：microkit/docs/manual.md:33-35 -->
```text
The seL4 Microkit is a small and simple operating system (OS) built on the seL4 microkernel.
Microkit is designed for building system with a *static architecture*.
A static architecture is one where system resources are assigned up-front at system initialisation time.
```

和第 24 章的关系可以一句话说清：**take-grant 那张图是分析的输入，
Microkit 那张图是构建的输出。** 两边看的都是"谁手里有什么、能传给谁"，
区别在谁在什么时候检查它。

### 实体：一个 PD 就是一个顶点

<!-- 源码块：microkit/docs/manual.md:127-134 -->
```text

A PD provides a thread of control that executes within a fixed virtual address space.
The isolation provided by the virtual address space is enforced by the underlying hardware MMU.

The virtual address space for a PD has mappings for the PD's *program image* along with any memory regions that the PD can access.
The program image is an ELF file containing the code and data which implements the isolated component.

Microkit supports a maximum of 63 protection domains.
```

`fixed` 这个词是全章的枢纽。我们这边，实体 0/3/4/5 持有的能力集由
`caps_of` 算出来，随 `execute` 一步步变；Microkit 那边，每个 PD 的地址空间、
能力空间、句柄编号在**建图期**就定死了，运行时没人有权改。
手册另外给了两个上限：PD 最多 63 个（`microkit/docs/manual.md` 第 134 行的 `protection`），
每个 PD 的 channel + interrupt 最多 63 条（`microkit/docs/manual.md` 第 294 行的 `interrupts`）——
图的顶点数和出边数都是编译期常量。这一条 24.10 的"模型没有资源上限"
在真实系统里根本不成立。

### 边：只有代理标识，没有对方的名字

<!-- 源码块：microkit/docs/manual.md:288-292 -->
```text
**Note:** There is no way for a PD to directly refer to another PD in the system.
PDs can only refer to other PDs indirectly if there is a channel between them.
In this case, the channel identifier is effectively a proxy identifier for the other PD.
So, to extend the prior example, **A** can indirectly refer to **B** via the channel identifier **37**.
Similarly, **B** can refer to **A** via the channel identifier **42**.
```

这正是 24.2 那句"authority 只存在于边上"的实现版：PD 拿不到另一个 PD 的
全局名字，能拿到的只是一个**代理号**，而代理号存在的条件就是那条边存在。
边本身也是二元的（`microkit/docs/manual.md` 第 280 行的 `channel`：
一条 channel 恰好连两个 PD，没有多方 channel），和 `cap` 记录只有 `source`/`target` 两个字段一样。

### 这张图必须无环

<!-- 源码块：microkit/docs/manual.md:304-308 -->
```text
A protected call is only possible if the callee has strictly higher priority than the caller.
Transitive calls are possible, and as such a PD may call a *protected procedure* in another PD from a `protected` entry point.
However the overall call graph between PDs must form a directed, acyclic graph.
It follows that a PD can not call itself, even indirectly.
For example, `A calls B calls C` is valid (subject to the priority constraint), while `A calls B calls A` is not valid.
```

为什么要禁环？用本章的语言回答：一旦 `A calls B calls A` 允许成立，
"A 能影响 B"和"B 能影响 A"同时为真，`tgs_connected` 的闭包就把两个 PD
并进同一个孤岛——24.6 那张"一条泄漏就是一条边"的图会当场塌成一块。
优先级严格递增是工程上保证无环的最省事的做法。

有界时间这一条要如实说：

<!-- 源码块：microkit/docs/manual.md:313-316 -->
```text
The caller is blocked until the callee returns.
Protected procedures must execute in bounded time.
It is intended that a future version of Microkit will enforce this condition through static analysis.
In the present version the caller must trust the callee to conform.
```

也就是说 PPC 的终止性目前是**约定**，不是检查。本章模型里 `step` 每一步
都定义在合法调用上，也谈不上终止性——两边都欠着同一笔账，只是欠法不同。

### 内存：被禁的是运行时映射，不是共享

"Microkit 禁止共享内存"是一句流传很广的话。手册的实际说法是：

<!-- 源码块：microkit/docs/manual.md:254-255 -->
```text
**Note:** When a memory region is mapped into multiple protection
domains, the attributes used for different mappings may vary.
```

同一块 MR 可以映射进多个 PD，两边的权限还可以不一样。所以真正被静态化的是
**"谁能映射"这件事本身**：PD 在运行时拿不到 untyped/frame 能力——
SDF 的 `cspace` 元素是唯一的"越狱"入口，而它只支持三种能力
（`cap_tcb`/`cap_sc`/`cap_vspace`，见 `microkit/docs/manual.md` 第 1128 行的 `cap_tcb`）。
对照本章：没有 `Create` 权利的能力集，`SysCreate` 与 `SysMap` 就无从下手。

### 权利：一次真实的最小化事故

2.3.1 的更新日志记了一次权限收紧：

<!-- 源码块：microkit/CHANGES.md:9-12 -->
```text
* Endpoint and Notification capabilities now only get the rights they need.
  Previously the tool gave all rights, which let a let a PD do more than
  intended. For example, a client PD with a PPC to a server PD can receive
  on the server's Endpoint and consume all the messages meant for the server.
```

工具侧的注释写得更直白——发送端点只需要 `write`，因为
不允许能力传递（`microkit/tool/microkit/src/capdl/builder.rs` 第 108 行的 `capCanSend`）：

<!-- 源码块：microkit/tool/microkit/src/capdl/builder.rs:108-110 -->
```text
/// Sending on a endpoint only needs the 'write'/'capCanSend' right, as we don't
/// allow capability transfer. We set grant_reply to allow the assignment to
/// the reply capability held by the server.
```

把这两段和 24.5 放在一起看会很舒服：我们那边 `extra_rights` 把 `Create`
摊平成"该实体全部权利"，是**模型为了归纳证明顺手做的放大**；
这边同样的"顺手给满 rights"在真实代码里造成过一个可利用的行为偏差
（客户端能在 server 的 endpoint 上 receive，把发给 server 的消息全吃掉）。
同名不同物的一处提醒：Microkit 的通道干脆**不传能力**，
所以本章的 `Take`/`Grant` 两种权利在这套系统里没有对应物——
它实现的是 authority 图的**静态闭包**，不是动态传播。

### 故障：父对子真的握着 destroy

<!-- 源码块：microkit/docs/manual.md:361-369 -->
```text
Faults such as an invalid memory access or illegal instruction are delivered to the seL4 kernel which then forwards them to
a designated 'fault handler'. By default, all faults caused by protection domains go to the system fault handler which
simply prints out details about the fault in a debug configuration.

When a protection domain is a child of another protection domain, the designated fault handler for the child is the parent
protection domain. The same applies for a virtual machine.

This means that whenever a fault is caused by a child, it will be delivered to the parent PD instead of the system fault
handler via the `fault` entry point. It is then up to the parent to decide how the fault is handled.
```

父 PD 收到子的故障后，`microkit_pd_restart`、`microkit_pd_stop`、
`microkit_pd_resume` 三个入口随便挑。这正是 24.4 那条
`legal (SysDestroy e c)` 想表达的东西：销毁权来自"只有我这条边指着他"。
区别在检查时机——本章每条 `SysDestroy` 都要现场查 `all_caps_of`，
Microkit 在建图期就把父子关系钉住了。

### 时间：模型里根本没有这一维

<!-- 源码块：microkit/docs/manual.md:178-181 -->
```text
The budget and period bound the fraction of CPU time that a PD can consume.
Specifically, the **budget** specifies the amount of time for which the PD is allowed to execute.
Once the PD has consumed its budget, it is no longer runnable until the budget is replenished; replenishment happens once every **period** and resets the budget to its initial value.
This means that the maximum fraction of CPU time the PD can consume is $\frac{budget}{period}$.
```

本章的状态里没有任何数字与时间有关，`step` 也没有"跑了多久"的概念。
所以 24.8 的孤岛不变式对时序信道**完全失明**：两个 PD 只要互相拿不到能力，
在本章就是隔离的，哪怕它们共用一个调度域、被同一个周期轮转。

### 边界：这一层同样没被证明

<!-- 源码块：microkit/docs/manual.md:468-473 -->
```text
The formal verification of seL4 applies to a specific set of seL4 configuration only. This means that making a *release* build
of a Microkit system does not imply that the seL4 kernel being used is verified.

Currently Microkit always uses the MCS configuration of seL4 which is still undergoing verification, scheduled to complete
for RISC-V in 2026 and AArch64 in 2027. The design proofs for MCS are done but the work to show that the kernel code conforms
to the design is still undergoing.
```

手册在 Purpose 一节也更早就说过，系统级的形式分析
"such analysis is beyond the initial scope"（`microkit/docs/manual.md` 第 46 行的 `formal`）。
把这三段和 24.10 并排读，结论是同一个：
**take-grant 那套证明的是"authority 闭包不越孤岛"，
Microkit 证明的是（并且只声称）它脚下那层 seL4 的定理，
中间那一层——SDF 到镜像的翻译——两边都还没有人证。**

### 一张对照表收尾

| 本章（`System_S`/`Islands_S`） | Microkit（`manual.md`） | 强制时机 |
| --- | --- | --- |
| 实体 `e`，`caps_of s e` | protection domain + 它的 CSpace | 本章：每步；Microkit：建图期 |
| 边 `(e, c, e')` | channel（恰好两个 PD） | 两边都是静态声明 |
| `Take`/`Grant` 传播 | 无对应物（不传能力） | —— |
| `Create` 摊平成 `extra_rights` | 2.3.1 之前给满 rights 的事故 | 事后修 |
| `SysDestroy` 的合法性检查 | `fault` 入口 + `microkit_pd_stop` | 本章：运行中；Microkit：故障时 |
| `tgs_connected` 闭包 = 孤岛 | 优先级严格递增 ⟹ 调用图无环 | 构建期报错 |
| 信息流 `set_flow` | 域调度 + MMU/IOMMU 强制的可见性 | 硬件与调度器 |
| "这个模型什么都没证明" | "beyond the initial scope" | 两边同一句实话 |

---

## 本章坑位清单（实测）

1. **`declare entity.splits [split]` 不能省**（`System_S.thy` 第 40 行）。
   少了它，`removeOperation`、`direct_caps_of` 一类的化简全卡在 `case` 上。
2. **带假设的 `[simp]` 规则要先量时间**：`extra_rights_no_create` 进 simp 集后
   `by simp` 从 3.3 秒涨到 100 秒以上不收。
3. **`step cmd s` 里含 `s` 自己**：`step' cmd s ∪ {s}`，所以合法调用的结果集
   永远带着调用前的状态。24.7 因此不必分"变/没变"两种情况。
4. **`execute` 是倒着执行**：`execute (cmd#cmds) s = ⋃ (step cmd ` execute cmds s)`，
   列表右边先跑。写成"从前到后"的直觉会在 24.4 那两条序列引理上翻车。
5. **`rtrancl_induct` 的 `r` 必须显式实例化**：裸 `erule rtrancl_induct` 在
   `tgs_connected` 那串并起来的闭包上直接方法失配。反倒 `where b=…`、
   `where P=…` 都写得进去（24.7 实测，不会撞绑定名）。真正咬人的是归纳步
   新引入的中间点：目标变成 `⋀y z.`，假设关于 `y`、结论关于 `z`，
   不先 `case_tac` 那一刀，`erule tgs_connected_trans` 也接不上。
6. **`simp` 会把 `∃x∈{3,5}. P x` 展成析取**（`bex_insert`），
   于是手写的 `rule bexI [where x=…]` 在第二步报 "No subgoals!"。
   24.9 那三条 `set_flow_*` 最后是 `by (auto simp: set_flow_def all_rights_def)` 收的。
7. **`Read ∈ all_rights` 这类残留**：`all_rights` 的定义不进 simp 集就化不掉，
   每条用到它的 `auto`/`simp` 都要显式带 `all_rights_def`。
8. **带守卫的 `if` 落在假设里**要 `split: if_split_asm`，
   `if_splits` 不管用（24.7 的 `direct_caps_of_remove` 一族）。
9. **`⊆` 目标交给 `auto`/`fastforce`/`blast`**，不要 `rule subsetD` 后
   把 schematic 左边留着——`by (rule subsetD) (simp …)` 连语法都不合法。
10. **`∈cap` 不是子集**：`cap_in_caps` 要的是"存在一条同目标、
    摊平后权利包含"的现成能力。`{cA,cB} ≤cap cB` 成立而
    `take_cap 3 ∈cap {cD}` 不成立，两件事都得算。
11. **不存在的实体也会进孤岛**：`island s 5 = {3,5}`（24.8），
    因为边是对称的、而空实体的 `caps_of` 是空集。
12. **`Read`/`Write` 一条 tgs 边都不造**（`sample_tgs_data`），
    但它们在 `set_flow` 里正是数据流的根据——这就是"权威"与"信息流"两层。
13. **`Create` 摊平是模型的决定，不是实现的**：24.10 那张表里
    untyped/CNode 能力不接受掩码。
14. **`raw` Unicode 下标会写错**：编辑器容易吐 `⇩`（下标 i），
    Isabelle 里字符串内的数学符号触发 "Inner lexical error"，
    项里要写 `\<^sub>i`。
15. **`@{"X"}` 不是合法 antiquotation**：本章三次踩到，
    全都是 `@{verbatim "X"}` 少打了 `verbatim`。
16. **`@{verbatim "…}` 少一个引号会吞掉后面的引号**，
    报错位置在几百行之外。
17. **中间标记别用"开始/结束"字样**：`run-all.sh` 第 4 关是按
    `^==== .*开始 ====` / `^==== .*结束 ====` 配对抽区间的，
    多一个"结束"就把抽取产物砍成前半章。
18. **`typ` 只吃类型、`term` 才吃项**：`typ "caps_of sample_state 0"`
    直接 "Failed to parse type"，而整条会话照样跑到 100% 再 FAILED——
    只看 `100%` 会漏判。
19. **"Ignoring duplicate rewrite rule" 是警告不是错误**，
    但它说明 `[simp]` 规则又被 `simp add:` 塞了一次；
    本章清掉 68 条之后抽取产物从 1773 行降到 1332 行；
    此后每次改正文它还会微动，所以判据只看 `grep -c "Warning ("` 是不是 0。
20. **别把 `README.md` 的文件名当真**：`Isolations_S` 是笔误（24.10 第 2 条）。

---

## 官方教程对照

官方 `docs.sel4.systems/Tutorials/` 那条链（kernel API、
`capabilities`、`simple_sos`、`undo`、MCS 计时等十三篇）**没有一篇**
讲到 take-grant、authority confinement 或 island——
第 3 章对照过 `capabilities` 页的权利表，第 21、22 章对照过
`proving` 与 `verification` 两页，本章这条线在文档站上是空的。

真正对得上的三份外部材料在 README 末尾自己点了名：
Dhammika Elkaduwe 的博士论文（较早的简化版模型）与
Andrew Boyton 的博士论文（本章这个扩展版）。
也就是说，**这一层内容的权威出处是论文，不是教程页**。

与官方教程页唯一的同名冲突要登记一条：
文档里反复出现的 "isolation" 在官方 `capabilities` 页指
"没有能力就访问不到"，是**保护**意义；本章的 `island` 是
`tgs_connected` 的等价类，是**权威闭包**意义，
`set_flow` 才是**信息流**意义。三者在第 3、6、24 章各指一物，
读官方页面时按章号对号，不要合并。

外部 URL 不在第 5 关的校验范围内。本章的行号分两档：
凡"路径 + 第 N 行"写在一起的（本章 21 条），第 5 关会逐条查那个文件、
那一行上下 8 行里有没有就近的那个标识名；
只在一段连续引用里出现一次的裸"（第 N 行）"，检查器不认，
它们全部对着 `/home/admin/hol/seL4` 里的当前文本逐条 `grep -n` 过——
这一档机器不背书，重跑 `grep` 才背书。

---

上一章：[23 · capDL](23-capdl.md) ｜ 返回：[README](../README.md)
