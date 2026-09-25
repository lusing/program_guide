# 14 · 调度

对应示例：`../examples/S14_schedule.thy`

## 14.1 调度：优先级 + 轮转 + 域

第 07 章说"结果集合"是因为有非确定性，而非确定性的最大来源就是**调度器**：
下一个跑谁，由优先级、域（domain）、时间片共同决定。

规范侧全部在 `l4v/spec/abstract/Schedule_A.thy`：
`max_non_empty_queue`（第 71 行）、`choose_thread`（第 74 行）、
`switch_to_thread`（第 23 行）、`guarded_switch_to`（第 33 行）、
`switch_to_idle_thread`（第 42 行）、`next_domain`（第 53 行）。
这些字段都在 `l4v/spec/abstract/Structures_A.thy` 的 `abstract_state` 里
（第 570--582 行）：`scheduler_action`、`domain_list`、`domain_index`、
`domain_start_index`、`cur_domain`、`domain_time`、`ready_queues`。
最后那个的类型是 `domain \<Rightarrow> priority \<Rightarrow> ready_queue`
——**每个域一套队列**。

C 侧的对应物是 `seL4/src/kernel/thread.c` 里的 `schedule`（第 372 行）；
MCS 配置多出来的预算与调度上下文在 `seL4/src/object/schedcontext.c`
与 `seL4/src/kernel/sporadic.c`，本章末节"官方教程对照"有它们的数字。

## 14.2 入队与出队

```text
theorem enqueue_adds: ?t \<in> set (enqueue ?p ?t ?qs ?p)
```

```text
theorem dequeue_removes: ?t \<notin> set (dequeue ?p ?t ?qs ?p)
```

```text
theorem
  dequeue_then_enqueue:
    ?t \<notin> set (?qs ?p) \<Longrightarrow> enqueue ?p ?t ?qs ?p = ?qs ?p @ [?t]
```

队列就是"优先级 → 线程号列表"的函数。入队从尾部加，
`dequeue` 用 `filter` 把该线程从那一格里删掉。
`dequeue_removes` 是内核"一个线程不能同时在两条队列里"那条不变式的模型版。

## 14.3 选线程：`Max` 加 `hd`，外面必须套一层守卫

<!-- 源码块：l4v/spec/abstract/Schedule_A.thy:71-81 -->
```text
definition max_non_empty_queue :: "(priority \<Rightarrow> ready_queue) \<Rightarrow> ready_queue" where
  "max_non_empty_queue queues \<equiv> queues (Max {prio. queues prio \<noteq> []})"

definition choose_thread :: "(unit, 'z::state_ext) s_monad" where
  "choose_thread \<equiv> do
     d \<leftarrow> gets cur_domain;
     queues \<leftarrow> gets (\<lambda>s. ready_queues s d);
     if \<forall>prio. queues prio = []
     then switch_to_idle_thread
     else guarded_switch_to (hd (max_non_empty_queue queues))
   od"
```

`max_non_empty_queue` 只有一行，它**不**处理"全空"；
处理的是调用方那句 `if \<forall>prio. queues prio = []`。这一节算的就是这道守卫为什么不能省。

```text
theorem max_on_singleton_is_the_element: Max {?p} = ?p
```

```text
theorem max_on_two_takes_the_larger: ?p \<le> ?q \<Longrightarrow> Max {?p, ?q} = ?q
```

这两条就是 HOL 里 `Max` 的全部可用等式（Isabelle 标准库的
`Lattices_Big.thy` 第 41 行 `singleton` 与第 67 行 `insert`，
两条的前提里都明写着集合非空）。
**空集上的 `Max` 没有任何等式**——连"`Max` 空集等于 0"都证不出来，
它就是定义式里那个 `the None`，一个彻底任意的自然数。
而每个自然数都是一个合法线程号，所以那句守卫不是防御性编程，
而是让 `hd` 有意义的唯一前提。`hd []` 同样没有任何等式。

```text
theorem all_empty_queues_gives_nil: max_non_empty_queue empty_queues = []
```

```text
theorem no_queues_means_idle: choose_thread empty_queues = None
```

```text
theorem
  single_queue_picks_head:
    choose_thread (empty_queues(5 := [?t1.0, ?t2.0])) = Some ?t1.0
```

```text
theorem
  higher_priority_wins:
    choose_thread (empty_queues(1 := [?lo], 9 := [?hi])) = Some ?hi
```

优先级数大者赢。实测里 `higher_priority_wins` 不能一步 `simp`：
简化器会把支撑集写成 `{prio. prio \<noteq> Suc 0 \<longrightarrow> prio \<noteq> 9 \<longrightarrow> ...}`
这种它自己算不动的形状，必须先把"支撑集就是 `{1, 9}`"单独引出来再 `unfolding`。

## 14.4 同优先级：轮转

```text
theorem
  rotate_moves_head:
    ?qs ?p = ?t # ?rest \<Longrightarrow>
    hd (S14_schedule.rotate ?p ?qs ?p) =
    (if ?rest = [] then ?t else hd ?rest)
```

```text
theorem
  rotate_keeps_queue_contents:
    ?qs ?p \<noteq> [] \<Longrightarrow> set (S14_schedule.rotate ?p ?qs ?p) = set (?qs ?p)
```

跑完一个线程就把它排到队尾，下次 `hd` 就是原来的第二个——同优先级靠这个轮转，
不靠抢占。注意两条都要先把 `qs p` 是 cons（或至少非空）这件事说出来：
`tl []` 与 `hd []` 在 HOL 里同样没有等式。

## 14.5 域：轮转靠列表末尾的标记，不靠取模

先把那个"末尾标记"本身立起来：`Schedule_A.thy` 里的 `domain_end_marker` 就是一对 `(0, 0)`。

<!-- 源码块：l4v/spec/abstract/Schedule_A.thy:49-50 -->
```text
definition domain_end_marker :: "domain \<times> domain_duration" where
  "domain_end_marker = (0, 0)"
```

`next_domain` 本体（同文件第 52--65 行，完整抄下来才看得出结构）：

<!-- 源码块：l4v/spec/abstract/Schedule_A.thy:52-65 -->
```text
definition
  next_domain :: "(unit, 'z::state_ext) s_monad" where
  "next_domain \<equiv> do
    modify (\<lambda>s.
      let index_inc = domain_index s + 1;
          index' = if domain_list s ! index_inc = domain_end_marker
                   then domain_start_index s
                   else index_inc;
          dom_entry = domain_list s ! index'
      in s\<lparr> domain_index := index',
            cur_domain := fst dom_entry,
            domain_time := ucast (snd dom_entry)\<rparr>);
    do_extended_op $ modify (\<lambda>s. s \<lparr>work_units_completed := 0\<rparr>)
  od"
```

`next_domain`（第 53 行）**不是** `(index + 1) mod length list`：
它看下一个表项是否等于 `domain_end_marker`，是的话回到 `domain_start_index`。

```text
theorem
  marker_example_wraps_to_start_not_zero:
    ds_index (next_domain (mk_sched [(2, 10), (0, 0)] 0 1)) = 1
```

回到的是 `domain_start_index`（这里是 1），不是 0。

```text
theorem
  marker_wrap_and_modulo_disagree:
    ds_index
     (next_domain (mk_sched [(2, 10), (3, 20), (4, 30), (0, 0)] 2 0)) =
    0
```

```text
theorem modulo_would_have_gone_on: (2 + 1) mod length [2, 3, 4, 0] = 3
```

同一张表、同一个索引：标记法回到 0，取模法走到 3——而 3 号位**就是那个标记**，
下一次 `choose_thread` 就会对着一个不存在的域挑线程。

```text
theorem
  set_start_moves_index_to_last_but_one:
    length (ds_list ?s) = 5 \<Longrightarrow> ds_index (domain_set_start 0 ?s) = 3
```

`domain_set_start`（第 167 行）把索引写成 `length - 2`，因为表的最后一项
**预留**作结束标记：这样下一次 `next_domain` 的"加一"刚好落到标记上，
从而绕回新的起点。

## 14.6 三条 assert：切线程的三道闸

<!-- 源码块：l4v/spec/abstract/Schedule_A.thy:25-26 -->
```text
     state \<leftarrow> get;
     assert (get_tcb t state \<noteq> None);
```

<!-- 源码块：l4v/spec/abstract/Schedule_A.thy:35-36 -->
```text
     ts \<leftarrow> get_thread_state thread;
     assert (runnable ts);
```

<!-- 源码块：l4v/spec/abstract/Schedule_A.thy:116-117 -->
```text
            id \<leftarrow> gets idle_thread;
            assert (ct_runnable \<or> ct = id);
```

三道闸分别是：要切的线程存在（第 26 行）、它可运行（第 36 行，
`runnable` 的定义在 `l4v/spec/abstract/Structures_A.thy` 第 409 行，
八个线程状态里只有 `Running` 与 `Restart` 返回 `True`，见第 13 章）、
当前线程不可运行时无非它就是 idle（第 117 行）。

```text
theorem switch_requires_existence: \<not> switch_allowed {} ?st ?t
```

```text
theorem switch_requires_runnable: \<not> switch_allowed ?ks (\<lambda>_. Inactive) ?t
```

```text
theorem idle_needs_no_permission: resume_allowed False ?i ?i
```

```text
theorem
  nonidle_needs_runnable:
    \<not> ?ct_runnable \<Longrightarrow> resume_allowed ?ct_runnable ?ct ?idle = (?ct = ?idle)
```

第三条闸的形状值得记：`ct_runnable \<or> ct = idle_thread`。
当前线程不可运行还合法的唯一理由，就是它本来就是 idle 线程——
它从来不在就绪队列里。

## 14.7 scheduler\_action：下一步该干什么

内核不直接切线程，先在状态字段里记下"打算干什么"：
`l4v/spec/abstract/Structures_A.thy` 第 541 行的
`datatype scheduler_action = resume_cur_thread | switch_thread (sch_act_target : obj_ref) | choose_new_thread`。

```text
theorem resume_has_no_target: action_picks_a_target resume_cur_thread = None
```

```text
theorem
  choose_new_has_no_target: action_picks_a_target choose_new_thread = None
```

```text
theorem
  switch_carries_its_target:
    action_picks_a_target (switch_thread ?t) = Some ?t
```

只有 `switch_thread` 这一支带着线程号，另外两支都得让调度器自己算。
`choose_new_thread` 走 `schedule_choose_new_thread`（第 97 行），
先 `when (domain_time = 0)` 再 `next_domain`，最后 `choose_thread`。

## 14.8 抢占用的是一条严格不等式

<!-- 源码块：l4v/spec/abstract/Schedule_A.thy:87-91 -->
```text
  is_highest_prio :: "domain \<Rightarrow> priority \<Rightarrow> 'z::state_ext state \<Rightarrow> bool"
where
  "is_highest_prio d p s \<equiv>
    (\<forall>prio. ready_queues s d prio = [])
    \<or> p \<ge> Max {prio. ready_queues s d prio \<noteq> []}"
```

`is_highest_prio`（第 87 行）把 14.3 那道守卫写成了正确姿势：
"全空"是一个**析取支**，而不是让 `Max` 去碰空集。

<!-- 源码块：seL4/src/kernel/thread.c:393-399 -->
```text
            /* Avoid checking bitmap when ksCurThread is higher prio, to
             * match fast path.
             * Don't look at ksCurThread prio when it's idle, to respect
             * information flow in non-fastpath cases. */
            bool_t fastfail =
                NODE_STATE(ksCurThread) == NODE_STATE(ksIdleThread)
                || (candidate->tcbPriority < NODE_STATE(ksCurThread)->tcbPriority);
```

C 侧的同一件事写在 `seL4/src/kernel/thread.c` 的 `schedule` 里，
那个 `fastfail` 在 393 行往上还有两行注释说明为什么不能问 idle 的优先级。
规范侧对应的是 `l4v/spec/abstract/Schedule_A.thy` 第 92 行的
`schedule_switch_thread_fastfail`：
`return $ ct \<noteq> it \<longrightarrow> target_prio < ct_prio`。
那个 `<` 是严格的：候选线程必须**严格**更高优先级；
idle 例外——因为问 idle 的优先级本身就是一个信息流通道。

```text
theorem
  preemption_is_strict:
    \<lbrakk>?ct \<noteq> ?it; ?ct_prio \<le> ?target_prio\<rbrakk>
    \<Longrightarrow> \<not> target_is_better ?ct ?it ?ct_prio ?target_prio
```

```text
theorem
  same_priority_does_not_preempt:
    ?ct \<noteq> ?it \<Longrightarrow> \<not> target_is_better ?ct ?it 7 7
```

```text
theorem idle_is_preempted_by_anything: target_is_better ?it ?it ?p ?q
```

```text
theorem
  highest_prio_asks_for_nine:
    is_highest_prio (empty_queues(1 := [?lo], 9 := [?hi])) ?p = (9 \<le> ?p)
```

```text
theorem
  nine_is_highest: is_highest_prio (empty_queues(1 := [?lo], 9 := [?hi])) 9
```

```text
theorem
  eight_is_not_highest:
    \<not> is_highest_prio (empty_queues(1 := [?lo], 9 := [?hi])) 8
```

同优先级不抢占，只能靠 14.4 的轮转排队——"优先级数大者先跑"这句话的另一半就是这个等号。

---

## 官方教程对照

官方 [mcs](https://docs.sel4.systems/Tutorials/mcs.html) 一页
（抓取日期 2026-09-25）把"实时"讲成三件事：调度上下文、预算与补充（refill）、
超时端点。下面先给 C 侧对应的数据结构与数字，再回头说 14.3 与 14.8 那两道守卫
在 C 里长什么样——它们比想象中更像。

**1. 优先级队列在 C 里是两层位图，`Max` 是一条 CPU 指令。** `prio_to_l1index`
（`seL4/include/kernel/thread.h:29--32`）把优先级按 `wordRadix` 拆两半，
高位进 L1、低位进 L2；`wordRadix`（`seL4/include/arch/x86/arch/64/mode/types.h:13`）
在 64 位机是 6、32 位机是 5，L2 位图的长度由 `L2_BITMAP_SIZE`
（`seL4/include/model/statedata.h:56`）算出。
挑最高优先级靠连用两次 `clzl`（`seL4/include/kernel/thread.h:70`），
而这条指令对 0 是未定义的，所以函数第一件事是个 `assert`
（`seL4/include/kernel/thread.h:68`），注释原话是
"it's undefined to call clzl on 0"。
这和 14.3 的结论是同一件事的两种写法：HOL 里"空集上的 `Max` 没有等式"，
C 里"空位图上的 `clzl` 没有定义"——一个靠简化器无事可做，一个靠断言挡住。

**2. `is_highest_prio` 的形状在 C 里一字不差。** `isHighestPrio`
（`seL4/include/kernel/thread.h:77--80`）就两行：L1 位图为空，**或**
`getHighestPrio`（`seL4/include/kernel/thread.h:61`）不高于给定优先级。
"全空"照样是析取支，不是让指令去碰未定义。

**3. `runnable` 在 C 里也只是一个 switch。** `isRunnable`
（`seL4/include/kernel/thread.h:39`）为真的分支是 `ThreadState_Running` 与
`ThreadState_Restart`（`seL4/include/kernel/thread.h:43`），
外加 `CONFIG_VTX`（`seL4/include/kernel/thread.h:44`）才有的 `ThreadState_RunningVM`
（`seL4/include/kernel/thread.h:45`）。规范那张八行表（第 13 章）与这段 switch
的差别只有 VTX 那一支。

**4. 调度上下文的大小**就是 **refill 条数**。`refill_index`
（`seL4/include/kernel/sporadic.h:53--55`）说得最直白：refill 数组住在
SC 结构体**后面**的同一块内存里。于是 `refill_absolute_max`
（`seL4/include/kernel/sporadic.h:74--77`）=
`(2^size_bits − sizeof(sched_context_t)) / sizeof(refill_t)`，
而 `SchedControl_ConfigureFlags` 检查 `extra_refills`
（`seL4/src/object/schedcontrol.c:150--153`）拿的就是这个数减
`MIN_REFILLS`（`seL4/include/object/structures.h:344`）。
一条 refill 16 字节：`seL4_RefillSizeBytes`
（`seL4/libsel4/include/sel4/constants.h:94`），`compile_assert`
（`seL4/include/object/structures.h:425`）把 C 的 `refill_t` 钉成同宽。
下限是 `seL4_MinSchedContextBits` = 7，即 128 字节
（`seL4/libsel4/include/sel4/constants.h:88`），整段在
`CONFIG_KERNEL_MCS`（`seL4/libsel4/include/sel4/constants.h:86`）里面，
紧跟着的 `SEL4_COMPILE_ASSERT`（`seL4/libsel4/include/sel4/constants.h:95--99`）
保证"核心 SC 刚好塞进这个下限"。**结论：给 SC 传 `size_bits` 不是形式，
它直接决定你能开几条 refill。**

**5. `ConfigureFlags` 的校验顺序是为了不溢出。** 先看 `budget_us`
（`seL4/src/object/schedcontrol.c:94`）与上限的比较，再换算成 `usToTicks`
（`seL4/src/object/schedcontrol.c:104`）——反过来就可能在乘法里溢出。
上限 `MAX_PERIOD_US`（`seL4/include/kernel/sporadic.h:37`）要么取静态配置，
要么取 `getMaxUsToTicks` 的八分之一（`seL4/include/kernel/sporadic.h:47`），
那个 8 的理由写在旁边注释里：`MAX_RELEASE_TIME`
（`seL4/include/kernel/sporadic.h:50`）要留出 `5 * MAX_PERIOD_TICKS`。
下限是 `MIN_BUDGET`（`seL4/include/kernel/sporadic.h:35`）=
2 × 内核 WCET × `CONFIG_KERNEL_WCET_SCALE`——"预算至少够跑一次内核操作"。
`budget == period` 是合法的，只有严格大于才报 `seL4_RangeError`
（`seL4/src/object/schedcontrol.c:134--140`）。
字数门槛写成 `TIME_ARG_SIZE`（`seL4/include/api/syscall.h:17`）而不是常量，
因为 `ticks_t` 是 `uint64_t`（`seL4/include/api/types.h:28`）：
64 位机上两个时间参数各占一个字、门槛 5，32 位机上各占两个字、门槛 7。
**一处对不上**：XML 的 `description`
（`seL4/libsel4/include/interfaces/object-api.xml:1452`）承诺参数越界返回
"seL4 Invalid Argument"，可 `src/object/schedcontrol.c` 里
`seL4_InvalidArgument` 出现 0 次（全内核 54 处，`seL4/src/object/domain.c:38`
是其中一处），它实际返回的是 `seL4_RangeError` 和 `seL4_InvalidCapability`。

**6. period 为 0 不是"没有周期"，是轮转。** `isRoundRobin`
（`seL4/include/kernel/thread.h:113--116`）返回 `scPeriod == 0`。
于是 `commitTime`（`seL4/include/kernel/thread.h:124`）单开一支：
轮转线程只有两条 refill，head 是"正在花的"、tail 是"已经花完的"。
14.4 的模型轮转（跑完排队尾）在 MCS 里就是这么表达的。

**7. 域超时用的同样是"等于 0"。** `isCurDomainExpired`
（`seL4/include/kernel/thread.h:118--122`）是
`numDomains > 1 && ksDomainTime == 0`——
和 14.7 那句 `when (domain_time = 0)` 一样，**不看**剩余时间够不够这个线程跑完。
域切换点因此可能落在一次系统调用中间。

**8. 内核里存着一份可执行的"预算守恒"。** `refill_sum`
（`seL4/src/kernel/sporadic.c:105`）把整条队列加总，`refill_ordered`
（`seL4/src/kernel/sporadic.c:65`）检查队列按时间递增，两个都标着 `UNUSED`、
都关在 `CONFIG_DEBUG_BUILD`（`seL4/src/kernel/sporadic.c:63`）里，
release 编译时整段消失。夹在中间的宏 `REFILL_SANITY_START`
（`seL4/src/kernel/sporadic.c:88`）先把总和记进局部变量，
`REFILL_SANITY_END`（`seL4/src/kernel/sporadic.c:94--97`）再要求操作前后总和相等。
"一次操作不得凭空造出或吞掉预算"这条不变式在 C 里确实有代码，
只是**没人证明它**——被证明的那一份在第 17 章，在 `l4v/proof/invariant-abstract/`。

---

## 本章坑位清单（实测）

1. **把 `Max` 当"总能算出最高优先级"**：空集上的 `Max` 没有任何等式，值彻底任意。
2. **以为 `choose_thread` 里那句"全空就切 idle"是防御性编程**：它是 `hd` 有定义的前提。
3. **一步 `simp` 证调度**：支撑集必须先单独引出来（`{1, 9}`），再 `unfolding`。
4. **把域轮转写成 `(i + 1) mod length`**：实测 `marker_wrap_and_modulo_disagree` 与 `modulo_would_have_gone_on` 给的是两个不同索引。
5. **以为回到 0 号**：回到的是 `domain_start_index`（`marker_example_wraps_to_start_not_zero` 里是 1）。
6. **忘了 `domain_list` 最后一项是结束标记**：`domain_set_start` 因此设索引为 `length - 2`。
7. **以为同优先级会抢占**：`same_priority_does_not_preempt`，同优先级靠轮转。
8. **以为 idle 线程也要过优先级比较**：`idle_is_preempted_by_anything`，它被任何线程抢。
9. **把 `hd []` / `tl []` 当有定义**：`rotate_keeps_queue_contents` 必须带 `qs p \<noteq> []` 前提。
10. **以为调度是确定性的**：抽象规范里是"任选合法选择"，证明要对所有选择成立；
    专门处理这条的目录是 `l4v/proof/invariant-abstract/`（`DetSchedInvs_AI.thy`、`DetSchedSchedule_AI.thy`、`DetSchedDomainTime_AI.thy`）。
11. **把域与优先级混为一谈**：域先于优先级——时间片用完就换域，不管那边优先级多低。
12. **找 C 侧调度实现找错文件**：入口是 `seL4/src/kernel/thread.c` 第 372 行的 `schedule`，不在 `src/object/`；`src/object/schedcontext.c` 只管 MCS 预算。
13. **以为给调度上下文传 `size_bits` 是走形式**：它直接就是 refill 条数（对照第 4 条）。
14. **以为 period 传 0 是"没有周期"**：在 MCS 里那是轮转（对照第 6 条）。
15. **以为 `budget` 必须严格小于 `period`**：相等合法，只有大于才报错。
16. **相信 XML 里"参数太大会返回 Invalid Argument"**：这条调用返回的是 RangeError。

---

上一章：[13 · 线程控制块](13-tcb.md) ｜ 下一章：[15 · 内存再类型化](15-retype.md) ｜ 返回：[README](../README.md)
