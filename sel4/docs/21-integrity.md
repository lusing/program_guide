# 21 · 完整性

对应示例：`../examples/S21_integrity.thy`

## 21.1 一个目录里其实有两条定理

`l4v/proof/access-control/README.md` 开头就把话说清了：这一带证的是**两条**性质，
`integrity`（完整性）与 `authority confinement`（权威约束），
后者"权威只按能力传播"，前者"没有写能力就改不了数据"
（`l4v/proof/access-control/README.md:11`）。两条都发表在 ITP 2011 的一篇论文里
（`paper`，`l4v/proof/access-control/README.md:16`）。

目录里的分工（`Syscall_AC`，`l4v/proof/access-control/README.md:35`）：

| 文件 | 行数 | 干什么 |
|---|---|---|
| `Types.thy` | 162 | 策略长什么样：`auth`、`PAS` 记录 |
| `Access.thy` | 953 | **两条性质的定义** |
| `Access_AC.thy` | 1761 | 逐条系统调用的"保持"证明的主体 |
| `Syscall_AC.thy` | 1347 | **总定理** |
| `CNode_AC.thy`、`Ipc_AC.thy`、`Tcb_AC.thy`、`Retype_AC.thy`、`Finalise_AC.thy`、`Interrupt_AC.thy` | — | 每类调用各自一块 |
| `DomainSepInv.thy`、`Deterministic_AC.thy`、`ADT_AC.thy`、`Arch_AC.thy` | — | 域分离不变式、确定性、ADT 精化 |
| `ARM/`、`AARCH64/`、`RISCV64/` | — | 每套架构一套 `ArchAccess.thy` 等 |

会话挂在 `AInvs` 上（`Access`，`l4v/proof/ROOT:135`），
构建命令在 `l4v/` 下 `L4V_ARCH=ARM ./run_tests Access`
（`run_tests`，`l4v/proof/access-control/README.md:29`）。
往上有两个会话**依赖**它：`InfoFlow` 直接 `= Access`（`InfoFlow`，
`l4v/proof/ROOT:142`），`DPolicy` 在 `sessions` 里列了 `Access`
（`DPolicy`，`l4v/proof/ROOT:125`）。也就是说：信息流那条链是**骑在完整性结果上的**。

本章全部围绕 `Access.thy`（定义）与 `Syscall_AC.thy`（总定理）。

## 21.2 PAS：先给每个对象贴一个"谁的"标签

策略不是内核状态的一部分，而是**外部给的一张表**。
`'a PAS` 这个记录就是这张表（`PAS`，`l4v/proof/access-control/Types.thy:100`）：

<!-- 源码块：l4v/proof/access-control/Types.thy:100-109 -->
```text
record 'a PAS =
  pasObjectAbs :: "'a agent_map"
  pasASIDAbs :: "'a agent_asid_map"
  pasIRQAbs :: "'a agent_irq_map"
  pasPolicy :: "'a auth_graph"
  pasSubject :: "'a"                \<comment> \<open>The active label\<close>
  pasMayActivate :: "bool"
  pasMayEditReadyQueues :: "bool"
  pasMaySendIrqs :: "bool"
  pasDomainAbs :: "'a agent_domain_map"
```

前三个是"命名函数"：把对象引用、ASID、IRQ 各自映到一个标号上；
`pasPolicy` 才是那张边表，边的标签是 `auth`：
`('a × auth × 'a) set`（`auth_graph`，
`l4v/proof/access-control/Types.thy:73`）。
`pasSubject` 是**当前在跑的那个标号**，于是"这是他的东西"就是
`pasObjectAbs aag ptr = pasSubject aag`（`is_subject`，
`l4v/proof/access-control/Types.thy:118`）。

最后三个布尔量是**故意留的口子**。规范里写得明白
（`pasMayActivate`，`l4v/proof/access-control/Types.thy:85`）：
把 `pasMayActivate` 设为真，完整性就允许"把新线程调度起来"；
把 `pasMayEditReadyQueues` 设为真，就允许"从就绪队列里摘线程"——
换调度域时必然要做这两件事。
两个都设成假，得到一条**更紧**的完整性，
`handle_event` 那批信息流证明义务用的正是紧的那条。

## 21.3 `auth` 有 12 个构造器，唯独没有 `Send`

<!-- 源码块：l4v/proof/access-control/Types.thy:51-52 -->
```text
datatype auth = Control | Receive | SyncSend | Notify | Reset | Grant | Call
                        | Reply | Write | Read | DeleteDerived | AAuth arch_auth
```

上面这一坨在 `auth`（`l4v/proof/access-control/Types.thy:51`）。
最后一项 `AAuth arch_auth` 是架构扩展点，所以**通用的有 11 个**。
值得注意的两件事：

1. **没有 `Send`**。异步发送在这个模型里不存在，能发的叫 `SyncSend`，
   通知另算一个 `Notify`。而 `Call` 与 `SyncSend` 的蕴含关系是**写进良构性**的
   （第 71 行）；
2. **`Control` 是"万能钥匙"**。注释直说：它意味着几乎什么都能做，
   包括拿到别的权利、创建、删除（`Control`，
   `l4v/proof/access-control/Types.thy:45`）。

跨信任边界的端点是这张表最好用的示例（`Receive`，
`l4v/proof/access-control/Types.thy:65` 那一行的原文是）：

<!-- 源码块：l4v/proof/access-control/Types.thy:65-65 -->
```text
T -Receive-> EP <-Send- UT
```

即：可信方 T 只对端点有 `Receive` 边，不可信的 UT 有发送边。
于是"UT 在 T 没在跑的时候动了这个端点、以及所有阻塞在它上面的 T 线程"
**是被允许的**——但 T 内部其它端点上阻塞的线程不受影响。
这就是为什么完整性必须带上"哪条边存在"这件事，而不能只说"没授权就不许改"。

模型（`../examples/S21_integrity.thy`）里搬了 11 个通用构造器，
并给出边的读写与三条良构条件：

```text
consts
  auth_to :: "(nat \<times> auth \<times> nat) set \<Rightarrow> nat set \<Rightarrow> auth \<Rightarrow> nat \<Rightarrow> bool"
```

```text
consts
  wf_policy :: "nat \<Rightarrow> (nat \<times> auth \<times> nat) set \<Rightarrow> bool"
```

```text
theorem
  self_has_all_authority:
    wf_policy ?agent ?P \<Longrightarrow> auth_to ?P {?agent} Write ?agent
```

```text
theorem
  call_edge_brings_a_syncsend_edge:
    \<lbrakk>wf_policy ?agent ?P; auth_to ?P ?subs Call ?l\<rbrakk>
    \<Longrightarrow> auth_to ?P ?subs SyncSend ?l
```

```text
theorem
  grant_and_receive_make_peers:
    \<lbrakk>wf_policy ?agent ?P; auth_to ?P ?subs Grant ?ep;
     auth_to ?P ?subs' Receive ?ep\<rbrakk>
    \<Longrightarrow> \<exists>s\<in>?subs. \<exists>r\<in>?subs'. (s, Control, r) \<in> ?P \<and> (r, Control, s) \<in> ?P
```

第一条对应良构性里的"人人都对自己拥有全部权威"这一条（第 66 行）——
别小看它，第 21.9 节那条 `trm_lrefl` 规则之所以敢说"自己的东西随便改"，
靠的就是这一句兜底。第三条最狠：**Grant 与 Receive 撞在同一个端点上，
两边就互为 `Control`**，也就是"从此对等"。这条是第 67--68 行的原文，
也是"给一个端点开 grant 等于把信任边界抹掉"的形式化说法。

完整的 `policy_wellformed` 有九个合取（`policy_wellformed`，
`l4v/proof/access-control/Access.thy:63`），
逐条读的话是：`Control` 只指向自己、自反全权、Grant+Receive 对等、
`maySendIrqs` 开着的 IRQ 通知边要归当前主体、Call⟹SyncSend、
Call+Receive 产生 Reply 边、Reply 产生 DeleteDerived 边、
DeleteDerived 传递、最后再来一遍 Grant+Receive 对等。
`pas_wellformed` 就是把它对着 `pasPolicy` 代入（`pas_wellformed`，
`l4v/proof/access-control/Access.thy:79`）。

## 21.4 权利到权威：`cap_rights_to_auth`

这是全书第 03 章那张权利表**第二次**出现，但这次不是集合而是边：

<!-- 源码块：l4v/proof/access-control/Access.thy:107-113 -->
```text
definition cap_rights_to_auth :: "cap_rights \<Rightarrow> bool \<Rightarrow> auth set" where
  "cap_rights_to_auth r sync \<equiv>
     {Reset}
   \<union> (if AllowRead \<in> r then {Receive} else {})
   \<union> (if AllowWrite \<in> r then (if sync then {SyncSend} else {Notify}) else {})
   \<union> (if AllowGrant \<in> r then UNIV else {})
   \<union> (if AllowGrantReply \<in> r \<and> AllowWrite \<in> r then {Call} else {})"
```

第 107--113 行，`l4v/proof/access-control/Access.thy`。四个要点：

* **`Reset` 无条件给**。任何一张非空能力都能被撤，所以 `Reset` 边永远在；
* **`AllowWrite` 在端点上给的是 `SyncSend`/`Notify`，不是 `Write`**。
  `sync` 这个布尔参数就是"端点还是通知"；
* **`AllowGrant` 直接给 `UNIV`**——不是给一条 `Grant` 边，
  而是把**全部 12 种权威**都算上；
* `Call` 要 `AllowGrantReply` **并且** `AllowWrite`。

模型里原样搬了这张表，于是上面那三条都是可证的定理
（第 112 行的 `UNIV` 是关键，见坑位 3）：

```text
theorem reset_conferred_alone: Reset \<in> rights_to_auth ?R ?sync
```

```text
theorem
  grant_confers_everything:
    AllowGrant \<in> ?R \<Longrightarrow> rights_to_auth ?R ?sync = UNIV
```

```text
theorem
  write_auth_only_via_grant:
    Write \<in> rights_to_auth ?R ?sync \<Longrightarrow> AllowGrant \<in> ?R
```

```text
theorem
  control_auth_only_via_grant:
    Control \<in> rights_to_auth ?R ?sync \<Longrightarrow> AllowGrant \<in> ?R
```

```text
theorem
  write_right_gives_syncsend:
    AllowWrite \<in> ?R \<Longrightarrow> SyncSend \<in> rights_to_auth ?R True
```

```text
theorem
  write_right_gives_notify:
    AllowWrite \<in> ?R \<Longrightarrow> Notify \<in> rights_to_auth ?R False
```

```text
theorem
  call_needs_grantreply_and_write:
    Call \<in> rights_to_auth ?R ?sync \<Longrightarrow>
    AllowGrant \<in> ?R \<or> AllowGrantReply \<in> ?R \<and> AllowWrite \<in> ?R
```

`write_auth_only_via_grant` 这条读起来别扭但很重要：
**在这张表里 `Write` 权威根本不来自 `AllowWrite` 权利**，
只能从 `AllowGrant` 那个 `UNIV` 里掉出来。

## 21.5 通知能力先被削掉两条权利，reply 能力不看权利

`cap_auth_conferred` 的分派里，通知那一支不是直接把权利传下去，
而是先做减法（`NotificationCap`，`Access.thy` 第 123 行）：

<!-- 源码块：l4v/proof/access-control/Access.thy:123-123 -->
```text
  | NotificationCap oref badge r \<Rightarrow> cap_rights_to_auth (r - {AllowGrant, AllowGrantReply}) False
```

这正是第 03 章 `cap_rights_update` 在掩码之外干的那件"通知抹掉 grant"的事
（`cap_rights_update`，`l4v/spec/abstract/Structures_A.thy:222`）在这里的**二次保险**：
实现层已经抹过，规范层查表前再抹一次。

Reply 能力走另一条路（`reply_cap_rights_to_auth`，
`l4v/proof/access-control/Access.thy:115`）：

<!-- 源码块：l4v/proof/access-control/Access.thy:115-116 -->
```text
definition reply_cap_rights_to_auth :: "bool \<Rightarrow> cap_rights \<Rightarrow> auth set" where
  "reply_cap_rights_to_auth master r \<equiv> if AllowGrant \<in> r \<or> master then UNIV else {Reply}"
```

**master 那一条完全不看权利**，直接 `UNIV`。

模型里三张表都在，配套的可判结论：

```text
consts
  ntfn_rights_to_auth :: "rights set \<Rightarrow> auth set"
```

```text
theorem ntfn_never_gives_call: Call \<notin> ntfn_rights_to_auth ?R
```

```text
theorem ntfn_bounded: ntfn_rights_to_auth ?R \<subseteq> {Reset, Receive, Notify}
```

```text
consts
  reply_rights_to_auth :: "bool \<Rightarrow> rights set \<Rightarrow> auth set"
```

```text
theorem master_reply_confers_everything: reply_rights_to_auth True ?R = UNIV
```

```text
theorem
  non_master_reply_confers_only_reply:
    AllowGrant \<notin> ?R \<Longrightarrow> reply_rights_to_auth False ?R = {Reply}
```

`ntfn_bounded` 说的是：一张通知能力最多给出 `Reset`/`Receive`/`Notify` 三种边——
`Call`、`SyncSend`、`Control`、`Write` 一概拿不到。

## 21.6 一类能力一个权威集合

<!-- 源码块：l4v/proof/access-control/Access.thy:118-131 -->
```text
definition cap_auth_conferred :: "cap \<Rightarrow> auth set" where
 "cap_auth_conferred cap \<equiv> case cap of
    NullCap \<Rightarrow> {}
  | UntypedCap isdev oref bits freeIndex \<Rightarrow> {Control}
  | EndpointCap oref badge r \<Rightarrow> cap_rights_to_auth r True
  | NotificationCap oref badge r \<Rightarrow> cap_rights_to_auth (r - {AllowGrant, AllowGrantReply}) False
  | ReplyCap oref m r \<Rightarrow> reply_cap_rights_to_auth m r
  | CNodeCap oref bits guard \<Rightarrow> {Control}
  | ThreadCap obj_ref \<Rightarrow> {Control}
  | DomainCap \<Rightarrow> {Control}
  | IRQControlCap \<Rightarrow> {Control}
  | IRQHandlerCap irq \<Rightarrow> {Control}
  | Zombie ptr b n \<Rightarrow> {Control}
  | ArchObjectCap arch_cap \<Rightarrow> arch_cap_auth_conferred arch_cap"
```

第 118--131 行。**十一个构造器里有六个直接给 `{Control}`**：
untyped、CNode、线程、域、IRQ control、IRQ handler，加上 `Zombie` 共七个。
`NullCap` 给空集。
换句话说，"非端点非通知非 reply"的能力一律是万能钥匙。

最后一支是架构扩展。`Write` 权威就是从这儿进来的
（`vspace_cap_rights_to_auth`，
`l4v/proof/access-control/AARCH64/ArchAccess.thy:15`）：

<!-- 源码块：l4v/proof/access-control/AARCH64/ArchAccess.thy:15-18 -->
```text
definition vspace_cap_rights_to_auth :: "cap_rights \<Rightarrow> bool \<Rightarrow> auth set" where
  "vspace_cap_rights_to_auth r exec \<equiv>
     (if AllowWrite \<in> r then {Write} else {})
   \<union> (if AllowRead \<in> r \<or> exec then {Read} else {})"
```

**页表能力**的 `AllowWrite` 才给出 `Write`；`exec`（页可执行）在这里还顺手给出 `Read`。
ARM 那一份少这半句，而且文件里写了原因
（`Execute`，`l4v/proof/access-control/ARM/ArchAccess.thy:14`）：

<!-- 源码块：l4v/proof/access-control/ARM/ArchAccess.thy:15-19 -->
```text
\<comment> \<open>Execute does not confer Read authority on this architecture and is ignored.\<close>
definition vspace_cap_rights_to_auth :: "cap_rights \<Rightarrow> bool \<Rightarrow> auth set" where
  "vspace_cap_rights_to_auth r exec \<equiv>
     (if AllowWrite \<in> r then {Write} else {})
   \<union> (if AllowRead \<in> r then {Read} else {})"
```

同一份完整性定理在两套架构上是**两张不同的策略表**——
`arch_integrity_obj_atomic`（`troa_arch`，
`l4v/proof/access-control/Access.thy:527`）那条规则就是留给它们的口子。

模型只保留了玩具能力集里有的那几支：

```text
consts
  cap_auth_conferred :: "cap \<Rightarrow> auth set"
```

```text
theorem nullcap_confers_nothing: cap_auth_conferred NullCap = {}
```

```text
theorem
  untyped_cap_confers_control:
    cap_auth_conferred (UntypedCap ?p) = {Control}
```

```text
theorem
  grant_on_endpoint_confers_control:
    AllowGrant \<in> ?R \<Longrightarrow> Control \<in> cap_auth_conferred (EndpointCap ?p ?R)
```

```text
theorem
  ntfn_cap_never_confers_control:
    Control \<notin> cap_auth_conferred (NotificationCap ?p ?R)
```

## 21.7 权威"从状态里长出来"：sbta 与那个 `DomainCap` 的 hack

策略是外部给的，但**证明要求它至少覆盖状态里真实存在的能力**。
这件事由两条关系负责。第一条把能力摊成引用集合
（`obj_refs_ac`，`l4v/proof/access-control/Access.thy:186`），
最后一条写着 `DomainCap = UNIV`，注释是 `(* hack, see above *)`（第 198 行）；
上面那段注释（第 175--178 行）解释了这个 hack：
域能力直觉上给了它对一切的控制，就让它"引用一切"。

第二条把状态摊成边集：`state_bits_to_policy`（`sbta_caps`，
`l4v/proof/access-control/Access.thy:226`）三条前提
"槽里有能力、引用在这张能力里、权威在这张能力的映射表里"，
生成一条边；`state_objs_to_policy`（`l4v/proof/access-control/Access.thy:251`）
把它按标号抽象一遍。"策略覆盖状态"就是
`auth_graph_map (pasObjectAbs aag) (state_objs_to_policy s) \<subseteq> pasPolicy aag`
（`state_objs_in_policy`，`l4v/proof/access-control/Access.thy:304`）——
注意方向：**标号化之后的边集是策略的子集**。

阻塞状态同样会长出边来（`tcb_st_to_auth`，
`l4v/proof/access-control/Access.thy:133`）：
一个线程阻塞在通知上，就给那条通知一条 `Receive` 边；
阻塞在同步发送上、而且带 grant，就给出 `Grant` 与 `Call`。
所以"谁阻塞在哪儿"本身就是策略的一部分。

## 21.8 能跨主体流动的只有三种槽内容

<!-- 源码块：l4v/proof/access-control/Access.thy:150-155 -->
```text
(* FIXME is_transferable should guarantee directly that a non-NullCap cap is owned by its CDT
   parents without using directly the CDT so that we can use it in integrity *)
inductive is_transferable for opt_cap where
  it_None: "opt_cap = None \<Longrightarrow> is_transferable opt_cap" |
  it_Null: "opt_cap = Some NullCap \<Longrightarrow> is_transferable opt_cap" |
  it_Reply: "opt_cap = Some (ReplyCap t False R) \<Longrightarrow> is_transferable opt_cap"
```

第 150--155 行，注释和定义一起搬过来。三条引入规则意味着：
除了空槽与 `NullCap`，**只有非 master 的 reply 能力**可以不经 grant
就出现在别的主体手里（第 21.10 节会看到 CDT 那边有同一个例外）。

模型里把这条搬成了一个可判的性质：

```text
theorem
  transferable_non_master_reply: transferable (Some (ReplyCap ?t False ?R))
```

```text
theorem
  master_reply_not_transferable: \<not> transferable (Some (ReplyCap ?t True ?R))
```

```text
theorem endpoint_not_transferable: \<not> transferable (Some (EndpointCap ?p ?R))
```

```text
theorem
  transferable_exhausted:
    transferable ?opt \<Longrightarrow>
    ?opt = None \<or>
    ?opt = Some NullCap \<or> (\<exists>t R. ?opt = Some (ReplyCap t False R))
```

最后那条是"只有三种"的正向说法：`transferable` 成立当且仅当它是这三种之一。

## 21.9 对象只能"原子地"这样变：16 条规则

`integrity_obj_atomic` 是整条证明里最忙的一条归纳定义
（`integrity_obj_atomic`，`l4v/proof/access-control/Access.thy:418`），
16 条引入规则，逐条是：

| 规则 | 允许什么 | 行 |
|---|---|---|
| `troa_lrefl` | 自己的对象随便改 | 420 |
| `troa_ntfn` | 有 `Receive`/`Notify`/`Reset` 边时可动通知对象 | 423 |
| `troa_ep` | 有 `Receive`/`SyncSend`/`Reset` 边时可动端点 | 428 |
| `troa_ep_unblock` | 能 Notify 某通知，就能动"阻塞在与它绑定的端点上"的队列 | 434 |
| `troa_tcb_send` | 能发，就能把收信线程置为 `Running` 并写它的寄存器 | 442 |
| `troa_tcb_call` | 能 Call，还能顺手往被叫者的 caller 槽塞一个 reply 能力 | 450 |
| `troa_tcb_reply` | 有 `Reply` 边就能回信；出错时新状态可以是 `Restart` 或 `Inactive` | 460 |
| `troa_tcb_receive` | 能 Receive，就能把发送方置成 `Running`/`Inactive`/`BlockedOnReply` | 470 |
| `troa_tcb_restart` | 能 `Reset` 一个端点/通知，就能把它上面所有阻塞线程改成 `Restart` | 481 |
| `troa_tcb_unbind` | 能 Reset 绑定的通知，就能解绑 | 488 |
| `troa_tcb_empty_ctable` | 能删别人线程 `tcb_ctable` 里自己的 reply 能力 | 497 |
| `troa_tcb_empty_caller` | 同上，`tcb_caller` 槽 | 502 |
| `troa_tcb_activate` | `activate` 开着时，谁都能把 `Restart` 的线程唤醒（注释写着 `Anyone can do this`） | 508 |
| `troa_tcb_fpu` | FPU 状态随便动，约束在 `integrity_fpu` 里另给 | 515 |
| `troa_cnode` | CNode 内容只许按 `cnode_integrity` 变 | 522 |
| `troa_arch` | 架构对象交给 `arch_integrity_obj_atomic` | 527 |

两点值得单独说。第一，`troa_tcb_activate` 是**唯一一个不需要任何边**的规则，
它的门票就是 `activate` 这个布尔——也就是第 21.2 节那个 `pasMayActivate`。
第二，`troa_cnode` 依赖的 `cnode_integrity`（`cnode_integrity`，
`l4v/proof/access-control/Access.thy:396`）只放行一种变化：
把一个 `ReplyCap caller False R` 变成 `NullCap`，而且 caller 必须是主体。
它上面那行注释是写给改代码的人的
（`WARNING`，`l4v/proof/access-control/Access.thy:395`）：
*"如果有人往 `is_transferable` 里加一种能力，这里必须同步出现"*。
——第 21.8 节那三条规则与这里是**成对维护**的。

`integrity_obj` 就是把这 16 条**取自反传递闭包**
（`integrity_obj`，`l4v/proof/access-control/Access.thy:532`）：
一次系统调用可以动一串对象。同一件事还有一份"带标签"的等价写法
`integrity_obj_alt`（`l4v/proof/access-control/Access.thy:584`），
标签来自 14 个构造器的 `Tro_rules`（`Tro_rules`，
`l4v/proof/access-control/Access.thy:542`）——
那是给证明用的"这一步用了哪条规则"的回执。

## 21.10 内存可以被改动的五种理由

<!-- 源码块：l4v/proof/access-control/Access.thy:831-844 -->
```text
inductive integrity_mem for aag subjects p ts ts' ipcbufs globals w w' where
  trm_lrefl:
    "pasObjectAbs aag p \<in> subjects \<Longrightarrow> integrity_mem aag subjects p ts ts' ipcbufs globals w w'"
| trm_orefl:
    "w = w' \<Longrightarrow> integrity_mem aag subjects p ts ts' ipcbufs globals w w'"
| trm_write:
    "aag_subjects_have_auth_to subjects aag Write p
     \<Longrightarrow> integrity_mem aag subjects p ts ts' ipcbufs globals w w'"
| trm_globals:
    "p \<in> globals \<Longrightarrow> integrity_mem aag subjects p ts ts' ipcbufs globals w w'"
| trm_ipc:
    "\<lbrakk> case_option False can_receive_ipc (ts p');
       ts' p' = Some Running; p \<in> ipcbufs p'; pasObjectAbs aag p' \<notin> subjects \<rbrakk>
       \<Longrightarrow> integrity_mem aag subjects p ts ts' ipcbufs globals w w'"
```

第 831--844 行。定义上面那段注释列了四条理由，并把 `globals`
标成"一个废弃概念，最好有人让它消失"（`globals`，
`l4v/proof/access-control/Access.thy:815`）。
第五条 `trm_ipc` 是最容易看漏的：**给一个正在收信的线程写 IPC 缓冲是合法的**，
哪怕写的人对那块内存既没有所有权也没有 `Write` 边。
它的四个前提里 `can_receive_ipc` 也值得翻一下原文
（`can_receive_ipc`，`l4v/proof/access-control/Types.thy:154`）：
阻塞在 receive 上、阻塞在**call** 上且带 grant、阻塞在通知上、阻塞在 reply 上——
四种都算"在等消息"。

模型把这条关系搬成 `mem_ok`，于是五条规则、以及一个**不单调**的事实都成了定理：

```text
theorem
  mem_ok_ipc_buffer:
    \<lbrakk>?can_recv ?p'; ?running ?p'; ?p \<in> ?ipcbufs ?p'; ?lab ?p' \<notin> ?subs\<rbrakk>
    \<Longrightarrow> mem_ok ?lab ?has ?subs ?can_recv ?running ?ipcbufs ?globals ?p ?p' ?w
        ?w'
```

```text
theorem
  mem_ok_only_five_reasons:
    mem_ok ?lab ?has ?subs ?can_recv ?running ?ipcbufs ?globals ?p ?p' ?w
     ?w' \<Longrightarrow>
    ?lab ?p \<in> ?subs \<or>
    ?w = ?w' \<or>
    (\<exists>s\<in>?subs. ?has s ?p) \<or>
    ?p \<in> ?globals \<or>
    ?can_recv ?p' \<and> ?running ?p' \<and> ?p \<in> ?ipcbufs ?p' \<and> ?lab ?p' \<notin> ?subs
```

```text
theorem
  mem_ok4_monotone_in_subjects:
    \<lbrakk>?subs \<subseteq> ?subs';
     mem_ok4 ?lab ?has ?subs ?can_recv ?running ?ipcbufs ?globals ?p ?p' ?w
      ?w'\<rbrakk>
    \<Longrightarrow> mem_ok4 ?lab ?has ?subs' ?can_recv ?running ?ipcbufs ?globals ?p ?p'
        ?w ?w'
```

```text
theorem
  mem_ok_by_the_ipc_rule_with_no_subjects:
    mem_ok lab3 has0 {} recv3 recv3 ipc3 {} 7 3 0 1
```

```text
theorem
  mem_ok_blocked_once_the_receiver_is_a_subject:
    \<not> mem_ok lab3 has0 {3} recv3 recv3 ipc3 {} 7 3 0 1
```

```text
theorem
  mem_ok_is_not_monotone_in_subjects:
    \<exists>subs subs'.
       subs \<subset> subs' \<and>
       mem_ok lab3 has0 subs recv3 recv3 ipc3 {} 7 3 0 1 \<and>
       \<not> mem_ok lab3 has0 subs' recv3 recv3 ipc3 {} 7 3 0 1
```

前四条规则对 `subjects` 单调（`mem_ok4_monotone_in_subjects`），
第五条带一个 `∉`，所以整条关系**不单调**（`mem_ok_is_not_monotone_in_subjects`）。
直觉：`subjects` 是"现在该负责的那批人"；
把收信线程那一头纳进责任范围，"替他写 IPC 缓冲"这条例外就收回来了。
这也是为什么这条规则必须写成 `p' \<notin> subjects` 而不是干脆省掉。

设备内存没有这条例外——`integrity_device` 只有三条规则
（`integrity_device`，`l4v/proof/access-control/Access.thy:849`），
没有 `globals`，也没有 `trm_ipc`。模型里两个方向都验过：

```text
theorem
  the_same_write_is_mem_ok_but_not_dev_ok:
    mem_ok lab3 has0 {} recv3 recv3 ipc3 {} 7 3 0 1 \<and>
    \<not> dev_ok lab3 has0 {} 7 0 1
```

同一笔写，普通内存合法、设备内存非法。中断寄存器不是内核可以"顺手代写"的缓冲。

## 21.11 派生树：槽 3 是那个明写的例外

CDT 那一侧的例外与第 21.8 节成对
（`cdt_direct_change_allowed`，`l4v/proof/access-control/Access.thy:739`）：

<!-- 源码块：l4v/proof/access-control/Access.thy:739-744 -->
```text
inductive cdt_direct_change_allowed for aag subjects tcbsts ptr where
  cdca_owned:
    "pasObjectAbs aag (fst ptr) \<in> subjects \<Longrightarrow> cdt_direct_change_allowed aag subjects tcbsts ptr"
| cdca_reply:
    "\<lbrakk> tcbsts (fst ptr) = Some tcbst; direct_call subjects aag ep tcbst; (snd ptr) = tcb_cnode_index 3 \<rbrakk>
       \<Longrightarrow> cdt_direct_change_allowed aag subjects tcbsts ptr"
```

第二条要求槽号**正好**是 `tcb_cnode_index 3`——
那就是线程的 `tcbCaller` 槽（第 12 章讲过 reply 能力放在哪儿）。
一次 call 会在**别人**的 TCB 里留下一个 reply 能力，
CDT 必须记下这条派生边，完整性不能把它判成非法。
上面那条 `cdca_owned` 只覆盖"直接拥有那个槽所在的对象"，
间接拥有靠 `cdt_change_allowed`（`l4v/proof/access-control/Access.thy:747`）
沿 CDT 的祖先链走：`m ⊨ pptr →* ptr`。

模型简化成"槽号对不对"，于是三条可判事实：

```text
theorem
  cdt_other_slot_needs_ownership:
    \<lbrakk>snd ?sl \<noteq> ?rslot; cdt_direct_ok ?lab ?subs ?called ?rslot ?sl\<rbrakk>
    \<Longrightarrow> ?lab (fst ?sl) \<in> ?subs
```

```text
theorem
  cdt_reply_slot_needs_no_ownership:
    ?called ?p \<Longrightarrow> cdt_direct_ok ?lab ?subs ?called ?rslot (?p, ?rslot)
```

```text
theorem
  cdt_reply_slot_rule_works_for_empty_subjects:
    cdt_direct_ok ?lab {} ?called ?rslot (?p, ?rslot) = ?called ?p
```

最后一条说得很直白：在 reply 槽上，这条规则**连主体集合都不看**，
它化简成 `called p` 一个条件。

就绪队列是另一个"半开放"的地方（`integrity_ready_queues`，
`l4v/proof/access-control/Access.thy:715`）：

<!-- 源码块：l4v/proof/access-control/Access.thy:715-717 -->
```text
definition integrity_ready_queues where
  "integrity_ready_queues aag subjects queue_labels rq rq' \<equiv>
     pasMayEditReadyQueues aag \<or> (queue_labels \<inter> subjects = {} \<longrightarrow> (\<exists>threads. threads @ rq = rq'))"
```

对**不属于当前责任范围**的那些标号，队列只许"在前面加人"，
不许重排、不许删。上面那段注释解释了为什么：
两个人互不相关时 AINVS 已经保证队列不会互相影响；
能通过端点互动时，运行中的人**可以**把另一个人的线程加进就绪队列——
加在**队首**。

## 21.12 合起来：`integrity_subjects` 九合取，与总定理

`integrity_subjects`（`l4v/proof/access-control/Access.thy:898`）
把上面每一块串成九条：

| # | 分量 | 出处 |
|---|---|---|
| 1 | 每个对象引用都满足 `integrity_obj` | 901 |
| 2 | `integrity_cdt_state` | 902 |
| 3 | `integrity_cdt_list_state` | 903 |
| 4 | 中断（`v = v'` 或 IRQ 归主体） | 904，定义在 862 |
| 5 | 就绪队列 | 906 |
| 6 | 普通内存 `integrity_mem` | 908 |
| 7 | 设备内存 `integrity_device` | 912 |
| 8 | ASID／hyp／FPU | 915--917 |

`integrity aag` 只是把 `subjects` 特化成 `{pasSubject aag}`
（`integrity`，`l4v/proof/access-control/Access.thy:919`）——
**单主体**。上面那段注释还提醒：这只是"一半"，
另一半是 `aag` 与状态相容，即 `pas_refined`（`l4v/proof/access-control/Access.thy:312`）。

总定理在 `Syscall_AC.thy` 末尾（`call_kernel_integrity`，
`l4v/proof/access-control/Syscall_AC.thy:1311`）：

<!-- 源码块：l4v/proof/access-control/Syscall_AC.thy:1311-1318 -->
```text
lemma call_kernel_integrity:
  "\<lbrace>pas_refined aag and einvs and valid_cur_hyp
                    and (\<lambda>s. ev \<noteq> Interrupt \<longrightarrow> ct_active s) and (ct_active or ct_idle)
                    and domain_sep_inv (pasMaySendIrqs aag) st' and schact_is_rct
                    and guarded_pas_domain aag and (\<lambda>s. ct_active s \<longrightarrow> is_subject aag (cur_thread s))
                    and K (pasMayActivate aag \<and> pasMayEditReadyQueues aag) and (\<lambda>s. s = st)\<rbrace>
   call_kernel ev
   \<lbrace>\<lambda>_. integrity aag X st\<rbrace>"
```

读它的四个注意点：

1. 它是 `lemma`，不是 `theorem`（同一个文件里 0 个 `theorem` 命令）；
2. 结论里的 `X` 是**自由变量**——它就是 `integrity_mem` 那个 `globals` 参数，
   在这条总定理里没有被约束（所以坑位 9 说的"废弃旁路"在这里还活着）；
3. 前提里有 `K (pasMayActivate aag \<and> pasMayEditReadyQueues aag)`：
   这条总定理证的是**两个口子都开着的宽版**；紧版走的是
   `handle_event_integrity`（`l4v/proof/access-control/Syscall_AC.thy:762`）那一路；
4. 紧挨着它的是 `call_kernel_pas_refined`（同文件第 1326 行）——
   "策略与状态相容"这件事也必须在一次 `call_kernel` 后保持，
   否则下一次调用的前提就断了。这两条合起来才是这个目录的收尾。

## 21.13 另一半在别处：take-grant 模型

`authority confinement` 在抽象层有另一份独立开发：
`l4v/spec/take-grant/`。它的六条概览写着
`Confine_S` 证权威约束、`Islands_S` 用"岛"重述、
`Isolation_S` 在权威上定义高位信息流（`Isolations_S`，
`l4v/spec/take-grant/README.md:24`），会话叫 `TakeGrant`
（`TakeGrant`，`l4v/spec/ROOT:124`）。

这个模型的权利**不是**内核那四种：

<!-- 源码块：l4v/spec/take-grant/System_S.thy:27-33 -->
```text
datatype
  right = Read      (* Authorise reading of information *)
         | Write    (* Authorise writing of information *)
         | Take     (* Having sufficient authority to take a capability from another entity *)
         | Grant    (* Having sufficient authority to propagate a capability to another entity *)
         | Create   (* Confers the authority to create new entities *)
         | Store    (* Simulates CNodeCap - get caps of said entity *)
```

第 27--33 行：`Take`/`Store`/`Create` 是内核 API 里没有的概念
（`Store` 明确说"模拟 CNodeCap"）。系统操作是八个
（`sysOPs`，`l4v/spec/take-grant/System_S.thy:144`）。

定理的形状很干净。先定义"泄漏"：`e\<^sub>x` 与 `e\<^sub>i` 之间存在
take/grant/share 关系（`leak`，`l4v/spec/take-grant/Confine_S.thy:82`），
把它对称化再取传递闭包就是 `tgs_connected`（同文件第 99 行）。
于是 `authority_confinement`（同文件第 1064 行）：

<!-- 源码块：l4v/spec/take-grant/Confine_S.thy:1064-1067 -->
```text
lemma authority_confinement:
  "\<lbrakk>s' \<in> execute cmds s;
    \<forall>e\<^sub>i. s \<turnstile> e\<^sub>x \<leftrightarrow>* e\<^sub>i \<longrightarrow> caps_of s e\<^sub>i \<le>cap c\<rbrakk>
  \<Longrightarrow> caps_of s' e\<^sub>x \<le>cap c"
```

一句话：**执行任意一串命令，某个实体的"岛"内的能力集不会超出它一开始被支配的那个界**。
旁边还有一条等价的反面写法 `leakage_rule`（同文件第 1000 行）：
现在连不通，跑一串命令之后也不会连上。
"岛"这个说法在 `Islands_S.thy` 第 15 行就叫 `island`。

这一份与内核代码的关系，README 里写得比什么都清楚
（`seL4`，`l4v/spec/take-grant/README.md:41`）：
*"这个规范**不与 seL4 代码相连**，也**不完全描述 seL4 行为**"*。
它是一张概念图，不是那条被精化链接住的定理。

---

## 本章坑位清单（实测）

1. **在 `auth` 里找 `Send`**：只有 `SyncSend` 和 `Notify`（`Types.thy` 第 51 行）。
   异步那支在策略层根本不存在。
2. **以为 `AllowWrite` 给出 `Write` 权威**：端点上给的是 `SyncSend`/`Notify`
   （`Access.thy` 第 111 行）。`Write` 只从**页表能力**来
   （`AARCH64/ArchAccess.thy` 第 17 行）。实测：`write_auth_only_via_grant`。
3. **低估 `AllowGrant`**：那一项写的是 `UNIV`（`Access.thy` 第 112 行），
   一条 grant 边等于 12 种权威全给。实测：`grant_confers_everything`。
4. **以为通知能力能带 grant**：查表前先 `r - {AllowGrant, AllowGrantReply}`
   `NotificationCap` 那一支（`Access.thy` 第 123 行）。实测：`ntfn_bounded` 把它压到三条边以内。
5. **以为 master reply 能力"权利多一点"**：`master` 那支**不看权利**直接 `UNIV`
   （`Access.thy` 第 116 行）。实测：`master_reply_confers_everything`。
6. **往 `is_transferable` 里加能力却不改 `cnode_integrity`**：
   两处是成对维护的，`Access.thy` 第 395 行有 `WARNING` 注释点名这件事。
7. **把 `integrity_mem` 当成对 `subjects` 单调**：`trm_ipc` 带一个 `∉`
   （`Access.thy` 第 843 行）。实测：`mem_ok_is_not_monotone_in_subjects`。
8. **以为设备内存也能被"代写" IPC 缓冲**：`integrity_device` 只有三条规则，
   没有 `trm_ipc`，也没有 `globals`（`Access.thy` 第 849--855 行）。
   实测：`the_same_write_is_mem_ok_but_not_dev_ok`。
9. **忘了 `globals` 那条旁路**：`integrity_mem` 里那条不需要任何授权的分支
   （`trm_globals`，`Access.thy` 第 839 行），定义上面就写着它是个废弃概念；
   总定理的结论里它仍是自由变量 `X`（`Syscall_AC.thy` 第 1318 行）。
10. **在 CDT 例外里找错槽号**：写死的是 `tcb_cnode_index` 的第 3 号，
    那条规则叫 `cdca_reply`（`Access.thy` 第 743 行）。
    实测：`cdt_reply_slot_rule_works_for_empty_subjects` 说这条规则连主体集合都不看。
11. **以为完整性 = 状态不变**：就绪队列那条允许"往队首加人"
    （`Access.thy` 第 717 行）；对象那 16 条更是明着列了合法变化。
    比的是"变化被策略允许"，不是相等。
12. **忽略 `pasMayActivate` / `pasMayEditReadyQueues`**：总定理把两个开关都取真
    （`pasMayActivate`，`Syscall_AC.thy` 第 1316 行）——宽版。信息流要用的紧版在
    `handle_event_integrity`（同文件第 762 行），另外
    `partitionIntegrity`（`l4v/proof/infoflow/Noninterference.thy` 第 305 行）
    把两个开关显式 `:= False` 后重新调用 `integrity`（第 308 行），
    这就是第 22 章 uwr 所用的那份完整性关系。抄定理时把开关当常量会出错。
13. **找总定理时搜 `theorem`**：`Syscall_AC.thy` 里顶层结果记作 `lemma`
    （第 1311 行）。
14. **以为 authority confinement 也在 `access-control/` 里**：抽象模型那份在
    `l4v/spec/take-grant/`，而且它自己声明"不与 seL4 代码相连"
    （`README.md` 第 41 行）。
15. **把 take-grant 的权利当内核权利**：那边是 `Read/Write/Take/Grant/Create/Store`
    六种（`System_S.thy` 第 27--33 行），`Store` 注释明说"模拟 CNodeCap"。
16. **`auto` 判不动 `x \<in> (if P then UNIV else {})`**：证 `Write ∈ rights_to_auth R sync`
    这类目标时，`UNIV` 那支一被简化就丢掉了 `P` 的线索；
    加 `split: if_split_asm` 才有 `AllowGrant ∈ R`。本章示例里 12 处这么写。
17. **`inductive` 的引入规则不能直接 `rule`**：`by (rule tf_None)` 会留下
    `None = None` 这样的侧条件；写 `by (auto simp: transferable.simps)`
    一次解决正反两个方向（实测）。
18. **以为两套架构的策略表一样**：ARM 那份明写"Execute 不授予 Read 权威"，
    AARCH64 那份把 `exec` 并进了 `Read`（两个 `ArchAccess.thy` 的第 14 与 18 行）。

---

## 官方教程对照

[README](../README.md) 里那张"官方页 → 本章"映射表核对过十个页面
（`hello-world` 到 `mcs`，抓取日期 2026-09-25），**其中没有一页讲完整性证明**：
那套 kernel tutorials 面向用户态编程，讲到"seL4 是被验证的"时只给结论，
不给 `l4v/proof/` 里的定义。所以本章没有逐条对照表，只有两处**同名陷阱**要登记：

* 官方材料与 capDL 文档里的 "island" 是**部署概念**（一组共享策略的域，见第 23 章），
  与 `l4v/spec/take-grant/Islands_S.thy` 第 15 行那个 `island`
  （"从某实体出发 `tgs_connected` 可达的实体集"）**同名不同物**；
* 口头与文档里的 "integrity" 多半指第 21.10 节那个内存分量，
  而本章写证明时 `integrity aag`（`l4v/proof/access-control/Access.thy:919`）
  是第 21.12 节的九合取。讨论 API 用前者，读 `Access.thy` 用后者。

外部 URL 本身不在第 5 关的校验范围内；本章凡说"真实代码是这么写的"，
后面都跟着一个被机器核对过的 `l4v/…` 路径与行号。

---

上一章：[20 · 精化链与信任基](20-refine-chain.md) ｜ 下一章：[22 · 非干扰](22-infoflow.md) ｜ 返回：[README](../README.md)
