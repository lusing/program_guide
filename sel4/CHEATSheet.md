# seL4 速查表

Isabelle2025-2 / HOL，配套 `docs/01..24` 与 `examples/S01..S24`。
本页七节：**术语**、**代码形状**、**证明方法**、**真实代码地图**（按"想看什么"排）、
**实测坑位索引**（按症状排列，指向章号）、**验证脚本用法**、**C 侧 API 速查**。
坑位总数实测 **344 条**
（每章 10--20 条，最多的是 20、21、23、24 章各那 20 条；`docs/*.md` 末尾的"本章坑位清单"），
每条都在本机跑出来过。
**24 章每章末尾都有一节"官方教程对照"**：01--15、21--24 钉的是 docs.sel4.systems 的
kernel tutorials 与规范树/证明树的落点；07--08、16--20 钉的是 `l4v/docs/` 那几篇
（`conventions.md`、`arch-split.md`、`haskell-assertions.md`、`plans/the-matrix.md`）
与 `l4v/lib/Monads/README.md`；05 与 08 另加本地文档镜像里的 `capdl/`、`microkit/`、
`docs/Tutorials/how-to-seL4.md` 和 12.0.0 发布说明。
页名与本教程章节的对应表在 `README.md` 的"官方教程对照"一节，
逐条差异写在各自章末。

---

## 一、能力与对象（术语速查）

| 术语 | 含义 | 真实定义 |
|---|---|---|
| capability（能力） | 指向对象的钥匙，带权利 | `l4v/spec/abstract/Structures_A.thy` |
| rights（权利） | `AllowRead / AllowWrite / AllowGrant / AllowGrantReply` | `l4v/spec/abstract/CapRights_A.thy` |
| `mask_cap` | 权利取交集，只削不增 | `l4v/spec/abstract/Structures_A.thy` |
| CSpace | 能力地址空间，一棵 CNode 树 | `l4v/spec/abstract/CSpaceAcc_A.thy` |
| `cslot_ptr` | 槽位 = `obj_ref × cnode_index`（后者是 `bool list`） | `l4v/spec/abstract/Structures_A.thy` |
| CDT | 能力派生树，记"谁从谁派生" | `l4v/spec/abstract/CSpaceAcc_A.thy` |
| `descendants_of` | 父边关系的**传递闭包**（不是直接儿子） | `l4v/spec/abstract/CSpaceAcc_A.thy` |
| revoke / delete | 清整棵子树 / 清一个槽 | `l4v/spec/abstract/CSpace_A.thy` |
| Zombie | 长删除的中间态，不可被覆盖 | `l4v/spec/abstract/Structures_A.thy` |
| Untyped | 未类型化内存，`freeIndex` 是**已分配水位** | `l4v/spec/abstract/Retype_A.thy` |

**权利系统的三条铁律**（第 03、05、21 章反复证明）：

```text
mask_never_grows      : mask R R' ⊆ R              -- 掩码只缩不放
mint_never_grows      : 派生得到的权利 ⊆ 原有权利   -- 派生不增权
mint_cannot_escalate  : 没有写权 ⟹ 派生不出写权     -- 不能提权
```

## 二、内核代码的"形状"

```text
('s,'a) nondet_monad = 's ⇒ ('a × 's) set × bool
                              │         │      └─ 失败标志
                              │         └─ 非确定性：结果是个集合
                              └─ 新状态
```

| 组合子 | 作用 |
|---|---|
| `return x` / `kreturn` | 返回 x，不改状态 |
| `bind` (`>>=`) | 串联；失败沿链传播 |
| `fail` / `kfail` | 失败标志置位（**结果集可以非空**） |
| `assert P` | `P` 假则等价于 `fail` |
| `assert_opt` | `option` 版，`None` 则失败 |
| `get` / `put` / `gets` / `modify` | 读写状态 |
| `select A` | 从集合 `A` 里**非确定地**选一个 |
| `returnOk` / `throwError` / `bindE` | 错误单子（`Inr` 成功 / `Inl` 出错） |
| `liftE` / `whenE` / `unlessE` | 抬升与条件执行 |

**三个最容易搞错的概念**（第 07、16 章实测）：

```text
no_fail m        -- 只是"不会置失败标志"
nonempty m       -- 只是"结果集非空"
valid P m Q      -- 所有结果满足 Q，且不失败（失败 ⟹ 任何 valid 都不成立）
```

`kselect {}` 是 `no_fail` 且结果为空的活例子——**两者独立**。

## 三、证明方法（代价从低到高）

```text
simp → auto → force → blast → linarith → metis
```

| 场景 | 用什么 |
|---|---|
| 记录/单子的字段更新 | `simp`（配 `fun_upd`、`record` 的 simp 规则） |
| 集合包含 + 逻辑分解 | `auto` |
| 地址算术（`p + n ≤ q`） | `linarith`（`simp` 推不动） |
| 传递闭包（`⁺` / `*`） | 具体引入规则（`r_into_trancl` 等），**不要展开** |
| 函数相等 | `rule ext` 或 `simp add: fun_eq_iff` |
| **记录相等** | `cases s` 拆字段（**`ext` 对记录无效**） |
| 单子相等 | 拆 `fst`/`snd` 两个分量，再用 `prod_eqI` |
| `case … of` 不分裂 | `split: sum.split` / `cap.splits` |
| `fun_upd` 的 `if` 判不了 | `case_tac "p = k"` 显式分情况 |

## 四、真实代码地图（想看什么去哪儿）

| 想看什么 | 路径 |
|---|---|
| 能力/对象/状态码的数据类型 | `l4v/spec/abstract/Structures_A.thy` |
| 权利掩码 | `l4v/spec/abstract/CapRights_A.thy` |
| 页表映射权利 | `l4v/spec/abstract/VMRights_A.thy` |
| CSpace 解析与访问 | `l4v/spec/abstract/CSpace_A.thy`、`CSpaceAcc_A.thy` |
| 解码器 | `l4v/spec/abstract/Decode_A.thy` |
| 调用标签 | `l4v/spec/abstract/InvocationLabels_A.thy` |
| 再类型化 | `l4v/spec/abstract/Retype_A.thy` |
| IPC | `l4v/spec/abstract/Ipc_A.thy`（取消在 `IpcCancel_A.thy`） |
| TCB | `l4v/spec/abstract/Tcb_A.thy`、`TcbAcc_A.thy` |
| 调度 | `l4v/spec/abstract/Schedule_A.thy` |
| 系统调用入口 | `l4v/spec/abstract/Syscall_A.thy` |
| 五层单子（`se_monad` 在第 32 行）与 `*_on_failure` | `l4v/spec/abstract/Exceptions_A.thy` |
| 单子的实现、`catch`/`handleE'`、`no_throw` | `l4v/lib/Monads/nondet/`，说明书是上一级的 `README.md` |
| 错误与故障类型 | `l4v/spec/abstract/ExceptionTypes_A.thy` |
| 错误与故障类型 | `l4v/spec/abstract/ExceptionTypes_A.thy` |
| 非确定性单子 | `l4v/lib/Monads/nondet/Nondet_Monad.thy` |
| VCG / wp | `l4v/lib/Monads/nondet/Nondet_VCG.thy`、`l4v/lib/Monads/wp/WP.thy` |
| `no_fail` 与"空结果" | `l4v/lib/Monads/nondet/Nondet_No_Fail.thy`、`Nondet_Empty_Fail.thy` |
| 精化关系 | `l4v/lib/Corres_UL.thy`、`l4v/proof/refine/Corres.thy` |
| 不变式 | `l4v/proof/invariant-abstract/AInvs.thy` |
| 完整性（顶层定理） | `l4v/proof/access-control/Syscall_AC.thy`、`CNode_AC.thy`、`Ipc_AC.thy`、`Tcb_AC.thy`、`Retype_AC.thy`、`Finalise_AC.thy`、`Interrupt_AC.thy`（共 14 个 theory 加三个架构子目录） |
| 完整性（底层规则集） | `l4v/proof/access-control/Access.thy`（`integrity_obj_atomic`、`integrity_mem`、`integrity_cdt`、`integrity_subjects`） |
| 策略类型（`auth`、`PAS`、`auth_graph`） | `l4v/proof/access-control/Types.thy` |
| 权利→权威的架构分支 | `l4v/proof/access-control/ARM/ArchAccess.thy`，另有 AARCH64、RISCV64 两份同名兄弟 |
| 权威限定（take-grant 抽象模型） | `l4v/spec/take-grant/System_S.thy`、`Confine_S.thy`、`Islands_S.thy`；信息流那层在 `Isolation_S.thy`，两个可算系统在 `Example.thy` 与 `Example2.thy` |
| 会话名与依赖 | `l4v/proof/ROOT`（`Access`、`InfoFlow`）、`l4v/spec/ROOT`（`TakeGrant`） |
| 非干扰 | `l4v/proof/infoflow/Noninterference.thy`、`Noninterference_Base.thy` |
| capDL | `l4v/spec/capDL/Structures_D.thy`、`CSpace_D.thy`、`CNode_D.thy` |
| C 规范 | `l4v/spec/cspec/KernelState_C.thy`、`KernelInc_C.thy` |
| C 源码（对象） | `seL4/src/object/cnode.c`、`endpoint.c`、`notification.c`、`tcb.c`、`untyped.c`、`objecttype.c`、`interrupt.c`、`reply.c`、`schedcontext.c`、`schedcontrol.c`、`domain.c` |
| C 源码（入口/调度） | `seL4/src/api/syscall.c`、`seL4/src/kernel/thread.c`、`seL4/src/kernel/sporadic.c`、`seL4/src/kernel/cspace.c` |
| 错误如何返回用户（label + extra MR） | `seL4/src/object/tcb.c` 的 `setMRs_syscall_error`、`seL4/src/object/endpoint.c` 的 `replyFromKernel_error` |
| 故障的 MR 编码与编译期对表 | `seL4/src/api/faults.c`（开头四条 `compile_assert`） |
| 内核侧异常类型与全局 | `seL4/include/api/failures.h` |
| 内核自己的诊断打印 | `seL4/include/api/types.h` 的 `userError`（不是返回码） |
| 调度器的数据结构与位图 | `seL4/include/kernel/thread.h`、`seL4/include/kernel/sporadic.h` |
| CSpace 解析的公共头 | `seL4/include/kernel/cspace.h` |
| 能力位域（内核侧） | `seL4/include/object/structures.h`、`structures_32.bf`、`structures_64.bf` |
| untyped 水位宏 | `seL4/include/object/untyped.h` |
| 用户 API：系统调用原型 | `seL4/libsel4/include/sel4/syscalls_master.h`、`syscalls_mcs.h`（`syscalls.h` 二选一） |
| 用户 API：对象方法签名 | `seL4/libsel4/include/interfaces/object-api.xml`、`seL4/libsel4/include/api/syscall.xml` |
| 用户 API：常量与错误码 | `seL4/libsel4/include/sel4/constants.h`、`errors.h`、`objecttype.h`、`shared_types.h`、`bootinfo_types.h`、`types.h` |
| 每 sel4_arch 的尺寸宏 | `seL4/libsel4/sel4_arch_include/<arch>/sel4/sel4_arch/constants.h` |
| 用户侧位域布局 | `seL4/libsel4/mode_include/32/sel4/shared_types.bf`（目录名换成 64 即 64 位版） |
| 原型的**生成器**（树里没有原型本体） | `seL4/libsel4/tools/syscall_stub_gen.py`、`bitfield_gen.py` |
| 内核调试出口 | `seL4/libsel4/include/sel4/syscalls.h`（`CONFIG_PRINTING` 那一组） |
| **未验证假设清单** | `seL4/CAVEATS.md` |

## 五、实测坑位索引（按症状）

### 语法 / 定义类

| 症状 | 真凶 | 章 |
|---|---|---|
| `Malformed command syntax` / `Inner lexical error` | 字面写了 Unicode（`‹ › ∀`），要写 `\<open>` `\<close>` `\<forall>` | 01 |
| `Bad arguments for document antiquotation` | `@{verbatim xxx}` 参数没加引号 | 01 |
| 常量名神秘失效 | 用了 `ALL EX SUM PROD INT UN INF SUP`（会被整词替换成符号） | 01 |
| `Outer syntax error: command expected, but keyword \|` | `record` 字段之间写了 `\|`（`\|` 只属于 `datatype`） | 22 |
| 类型冲突 `nat × 'a` vs `nat` | `type_synonym cslot = nat` 却按 `(x,0)` 用；应是二元组 | 21 |
| `Bad import … need to include sessions "HOL-Library"` | ROOT 父会话写 `HOL`；要写 `"HOL-Library"`（带引号） | 07 |
| `adhoc_overloading` 报错 | 写成了 `bind = kbind`；必须是 `bind == kbind` | 07 |
| 定理名带 `local.` 前缀 | 重载 `bind` 后的正常现象，不是错误 | 07 |
| 引文里有空格/转义，行号却"对不上" | `` `tcb_cnode_index 3` ``、`` `K (a \<and> b)` `` 不构成标识符锚点，检查器往旁边抓了个模型定理名 | 21 |
| 搜 `theorem` 找不到总定理 | `Syscall_AC.thy` 里顶层结果记作 `lemma`（全文 0 个 `theorem`） | 21 |
| `command expected, but keyword = was found` | `lemma foo: x = UNIV` 没加引号，外层 `=` 被当成命令分隔符 | 23 |
| `Bad number of arguments for type constructor: "Set.set"` | `datatype` 构造子的参数类型没进引号（`right set` 被读成两个类型）；写 `"cdl_right set"` | 23 |
| `Outer lexical error: bad input`（位置在文件末尾附近） | 有 `@{verbatim "…}` 没闭合引号；本章一次修了 13 处 | 23 |
| 同上，且报错行里能看到 `"@{verbatim` | 引号里再套卡通（嵌套 antiquotation）本来就是词法错误 | 23 |
| `Inner syntax error at "↦ obj )"` | 用 `f (x ↦ v)` 更新 record 的函数字段；老式括号只认字段名，改成显式 `\<lparr>fld := (\<lambda>x. if …)\<rparr>` | 23 |
| `Ambiguous input … produces 2 parse trees`（编译仍过，抽取输出多 40 行噪声） | `case` 里套 `case` 没加括号 | 23 |
| `Clash of types "_ ⇒ _" and "_ cdl_state_scheme"` | 把 `f \ {…}` 的部分应用当集合的象；写 `(\<lambda>t. f t s) \ {…}`，数字带 `(1::nat)` | 23 |
| `Clash of types "_ ⇒ _" and "cdl_invocation"` | 绑定变量取名 `inv`——它是 HOL 的逆函数常量 | 23 |
| `Undefined constant … "card_insert"` | Isabelle 2025 里它是 `card.insert`；而且对嵌套 insert 只匹配一次 | 23 |
| `Inner syntax error` / `Failed to parse type` | 拿 `typ` 去打印项（`typ "caps_of s 0"`）；项要用 `term`，它连类型一起打 | 24 |
| `@{"X"}` 处报 `Bad arguments`／`Outer lexical error` | 不是合法 antiquotation，全是 `@{verbatim "X"}` 少打了 `verbatim` 或引号 | 24 |

### 类型 / 证明类

| 症状 | 真凶 | 章 |
|---|---|---|
| `rule ext` 用不上 | 目标是**记录**相等而非函数相等；用 `cases` 拆字段 | 22 |
| `simp` 把目标拆成"相等⟹… ∧ 不等⟹…" | `fun_upd` 的 `if` 判不了；显式 `case_tac` | 22 |
| 等式假设"没生效" | `simp` 对等式的重写方向不确定；把公共部分提成参数 | 22 |
| 单子等式证不动 | 要拆 `fst`/`snd` 两个分量再 `prod_eqI` | 08 |
| `case … of` 不分裂 | 缺 `split: sum.split` / `cap.splits` | 08 |
| 递归的 `termination` 挂死 | 长度/大小的算术自动化看不出；加燃料参数做结构递归 | 04 |
| `adhoc_overloading` 那行改了没生效，报错位置还在别处 | 写成了 `=`；必须是 `bind == kbind` | 07 |
| `Nondet_README.thy` 里的引理找不到 | 那份说明书没列进 `lib/Monads/ROOT`，它的示例不经构建 | 07 |
| `Ignoring duplicate unsafe introduction` 告警 | `r⁺`/`r*` 的引入规则重复；换成 `r_into_trancl` 等具体规则 | 06 |
| 全称量化的事实实例化不上 | 有变量遮蔽；改名或用显式 `fix`/`obtain` | 17 |
| 归纳假设不够用 | 忘了 `arbitrary:` | 22 / 24 |
| `Suc.IH` 用不上 | 要显式 `Suc.IH[OF Suc.prems(1) step_u]` | 22 |
| `auto` 判不出"属于 `if P then UNIV else {}`" | 一简化就把 `P` 的线索丢了；补 `split: if_split_asm` 才拿得到 `AllowGrant ∈ R` | 21 |
| `inductive` 的引入规则 `rule` 不动 | 留下 `None = None` 这类侧条件；改 `auto simp: rel.simps` 一次解决双向 | 21 |
| 两个 record 值的不等式 `simp` 完全没办法 | 三元素集合的 `card` 因此也算不出；改证选择器方向的注入引理，再 `auto dest: …_inj` | 23 |
| `auto` 留下 `∃a b. cdl_cdt s (a,b) = Some p` 做不出来 | 四层嵌套的 `∃` 它不会实例化；`proof (rule notI)` + `have W: "⋀x. …"`，witness 用 `by (rule exI [of _ x], assumption)` | 23 |
| `simp` 留下 `(f' = f) = (f = f')` | `eq_comm` 把结论翻了；把引理陈述改成与 `simp` 规范形同侧 | 23 |
| `Type unification failed` 出现在五段模板那类高阶定义上 | 两个错误处理器的返回类型不一致；必须同为 `'e ⇒ ('e, 'd) cres` | 23 |
| `Failed to apply proof method` 落在 `erule rtrancl_induct` 上 | 目标里的闭包是定义展开后的写法，规则的关系参数合不上；必须 `where r="…"` 显式实例化 | 24 |
| 归纳步目标变成 `⋀y z.`，假设关于 `y`、结论关于 `z` | `rtrancl_induct` 引入中间点并把 `z` 重名遮蔽；先 `case_tac` 中间点那一刀再 `erule` | 24 |
| `by simp` 从 3 秒涨到 100 秒以上不收 | 带假设的等式进了 `[simp]`（`A ∈ rights c ⟹ …` 那类），每次都跑子简化证前提 | 24 |
| 抽取产物里混进 `Warning (…): ### Ignoring duplicate rewrite rule` | 已是 `[simp]` 的规则又被 `simp add:` 塞一遍；本章清掉 68 条 | 24 |

### 语义 / 建模类

| 症状 | 真凶 | 章 |
|---|---|---|
| 以为非阻塞发送会报错 | 是 `Dropped`，消息被丢弃 | 11 |
| 以为 `SendEP []` 合法 | 良构性排除空队列（空了应是 `IdleEP`） | 11 |
| 以为挂起再恢复是 `Running` | 实测是 `Restart` | 13 |
| 以为 `descendants_of` 是直接儿子 | 是传递闭包 | 05 |
| 以为 Untyped 有子孙就不能 retype | 限制只在复制/转授那条路（`ensure_no_children`） | 05 |
| 以为 `without_preemption` 有运行时内容 | 它的定义式就是 `liftE`，只是类型约束 | 08 |
| 看到打印出的 `('a × state) ⇒ bool` 以为结果集合换成了谓词 | 那是一段 `translations`；`'a set` 本来就是 `'a ⇒ bool` 的记法 | 08 |
| 把 `msg_from_syscall_error` 的第一个分量当返回值 | 它是 MessageInfo 的 label，列表才是 extra MR | 08 |
| 以为 C 与规范的错误码有编译期同步 | `compile_assert` 只钉住了 `lookup_failure` 那 1..4 | 08 |
| 把内核里的 `userError(...)` 当成返回给调用者的错误 | 它是串口打印，关掉打印开关整个宏消失 | 08 |
| 以为每个已验配置都有完整性与保密性 | 官方那张性质表里只有 `ARM`、`AARCH64`、`RISCV64` 三列有 | 20 |
| 以为 `no_fail` ⟹ 结果非空 | 两者独立（`kselect {}`） | 07 |
| 以为失败的程序仍可 `valid` | 失败 ⟹ 任何 `valid` 都不成立 | 16 |
| 以为 `Zombie` 槽可覆盖 | `can_be_replaced` 为假 | 06 |
| 以为通知可以重绑定 | 已绑定再绑返回 `None` | 12 |
| 以为 reply 可复用 | 一次性（`reply_is_one_shot`） | 12 |
| 以为 `{AllowWrite}` 是合法 VM 权利 | 不合法，且是**静默降级**不是报错 | 03 |
| 以为只读就无害、不破坏隔离 | 隔离是连通性性质，与权利大小无关 | 24 |
| 以为 `Read`/`Write` 也算权威边 | 它们一条 `tgs` 边都不造，但在 `set_flow` 里恰好是数据流的根据 | 24 |
| 以为"带 `Create` 摊平成全部权利"能落到实现 | `maskCapRights` 对 untyped 与 CNode 两类能力原样返回，压根不接受掩码 | 24 |
| 以为 `caps_of` 是"手里有哪些能力"的直接表 | 它是沿 `Store` 闭包并起来的**可见**直接能力表；不存在的实体也返回空集而非缺项 | 24 |
| 以为 `step cmd s` 只给结果态 | 定义是 `step' cmd s ∪ {s}`，合法调用的结果集里带着调用前的状态本身 | 24 |
| 以为改 CNode 大小等于请求位数 | CNode 多一个 slot（`cnode_needs_more_than_asked`） | 02 |
| 以为抽象层失败时具体层也要对应 | 抽象失败 ⟹ 具体任意 | 18 |
| 在 `auth` 里找 `Send` | 只有 `SyncSend` 与 `Notify`，异步那支在策略层根本不存在 | 21 |
| 以为端点上的 `AllowWrite` 给出 `Write` 权威 | 那是 `SyncSend`/`Notify`；`Write` 只从**页表**能力来 | 21 |
| 以为两条 `ArchAccess.thy` 内容相同 | ARM 明说 exec 不授予 Read，AARCH64 把 exec 并进了 Read | 21 |
| 低估 `AllowGrant` | 那一支直接给 `UNIV`，一条 grant 边 = 全部权威 | 21 |
| 以为 `integrity_mem` 对主体集合单调 | `trm_ipc` 带一个 `∉`，把接收方变成主体反而关掉例外 | 21 |
| 以为 capDL 的类型层在 `Structures_D.thy` | 那文件全文 18 行，只有 import 加 `arch_requalify_consts`；类型都在 `Types_D.thy` | 23 |
| 以为 `spec/capDL/` 里有 `well_formed` | 27 个理论文件全 grep 不到 `well_formed`/`reachable`/`island`；井形性在 `l4v/sys-init/WellFormed_SI.thy` | 23 |
| 把"边指向存在的对象"当"边类型匹配" | `mismatched_state` 两句话：`no_dangling` 成立、`types_ok` 不成立；真实那份也是两条独立判据 | 23 |
| 以为 capDL 的调度是确定的 | `Schedule_D.thy` 第 36 行是两支 `\<sqinter>`，其中一支 `switch_to_thread None`；抽象步只是值集里一个元素（精化用 `∈`） | 23 |
| 以为 `NullCap` 没有权利 | 真实 `cap_rights` 的兜底分支给它 `all_cdl_rights`（全集）；削权函数靠同一条兜底"原样返回" | 23 |
| 把 CDT 当 CSpace 树 | `cdl_cdt` 记的是**派生**关系，一条能力只有一个父亲，与它在哪个 CNode 里无关 | 23 |
| 以为"完整性 = 状态没变" | 16 条规则明着列合法变化；比的是"变化被策略允许" | 21 |
| 以为 authority confinement 也在 `access-control/` | 抽象模型那份在 `l4v/spec/take-grant/`，且自述不与内核代码相连 | 21 |

### 环境类

| 症状 | 真凶 | 章 |
|---|---|---|
| `[SQLITE_ERROR] cannot commit` / `[SQLITE_IOERR_DELETE]` | 构建库在 `~/` 且未签名二进制 `unlink` 被 EPERM；`USER_HOME` 指到 `/tmp` | 01 |
| 设 `ISABELLE_HEAPS` / `ISABELLE_HOME_USER` 无效 | `etc/settings` 无条件赋值；只有 `USER_HOME` 能改 | 01 |
| `process_theories` 后**所有区间为空** | `-l HOL` 装不下 `HOL-Library` 的 import，错误只进 stderr | 01 |
| 两遍输出不一致 | `parallel_print` / `parallel_proofs` / `threads` 没关 | 01 |
| 每个示例都报"含控制字符" | 用了 `[^[:print:]]`；中文标记的 CJK 字节被误判，要用 `[[:cntrl:]]` | 01 |
| S08 / S10 恒报"含溃逃痕迹" | 裸搜 `Error`；`throwError`/`DError` 是正常标识符 | 08 / 10 |
| 文档引用路径报"不存在" | 把仓库根目录名也写进了路径（多套了一层 `seL4/`）；脚本只认相对 `SE4SRC` 的 `l4v/…` 与 `seL4/…` | 01 |
| `docs/…`、`capdl/…`、`microkit/…` 那批引用被跳过并报"N 条没核" | 文档镜像根 `SE4DOC` 下找不到那个目录；不是引用写错了 | 01 |
| 抽取产物只剩前半章 | 章节内多写了一个"结束"字样：第 4 关按 `^==== …开始 ====` / `^==== …结束 ====` 配对，中间标记要避开这两个词 | 24 |
| `build -v` 打了 `theory … 100%` 却又 `FAILED` | `100%` 只说明theory跑到过某处；判绿只看有没有 `FAILED`/`Unfinished`/行首 `***` | 24 |

---

## 六、验证脚本怎么用

```bash
./run-all.sh                     # 全量：build + 两遍 + 比对 + 引用检查
./run-all.sh refs                # 只跑第 5、6 关（沿用 build/first/out，改文档时用这个）
./run-all.sh S22_infoflow        # 只报告一个 theory
./run-all.sh clean               # 清 build/ 下本脚本产物
SE4SRC=/path/to/seL4 ./run-all.sh   # 真实代码不在默认位置时
SE4DOC=/path/to/docs ./run-all.sh   # 官方文档镜像（docs/、capdl/、microkit/）不在默认位置时
```

产物：`build/build.log`、`build/first/out/SNN_*.txt`、`build/second/out/SNN_*.txt`。
正文里的每段 `text` 输出都能在这些 `.txt` 里逐字节找到；
标了 `<!-- 源码块：路径:起-止 -->` 的那些则改与**镜像里那份文件本身**比对，
而且**行号是断言**：块行数必须等于区间长度、逐行相等（只折叠空白），
少一行、多一行、改一个字都判失败——284 处标记现在全部带区间，没有"只写路径"的退化写法。
所以只动文档时用 `refs` 模式就能判绿，不必重跑 Isabelle。

---

## 七、C 侧 API 速查（对齐 16.0.0）

**签名不在 `.h` 里。** `libsel4` 的对象方法原型是构建时由
`seL4/libsel4/tools/syscall_stub_gen.py` 从
`seL4/libsel4/include/interfaces/object-api.xml` 生成的；
位域访问器由 `bitfield_gen.py` 从 `*.bf` 生成。
所以在树里 `grep "seL4_CNode_Copy("` 只能搜到声明都找不到的东西——
**要签名读 XML，要位域读 `.bf`**。

**XML 的参数表 ≠ 总线上的字数。** 能力类参数走 extra caps，不占消息寄存器；
`seL4_TCB_Configure` 的七（master）/六（MCS）个参数在内核里是
四/三个字 + 三份 `current_extra_caps`（第 13 章对照第 2 条）。

**16.x 删掉了旧教程里的三个名字**（本树全文 grep 0 命中）：
`CSpaceData`、`seL4_CapReply`、`seL4_BootInfo.extraBadges`。
`seL4_CNode_*` 现在收摊平后的 `dest_index, dest_depth, src_root, src_index, src_depth, rights`。

**master 与 MCS 是两套头文件**，`seL4/libsel4/include/sel4/syscalls.h:18--22`
按 `CONFIG_KERNEL_MCS` 二选一。差异不止"多一个 reply 参数"：

| | master | MCS |
|---|---|---|
| `seL4_Reply` | 有 | **没有** |
| `seL4_Wait` 返回值 | `void` | `seL4_MessageInfo_t` |
| `TCB_Configure` 的 `fault_ep` | 有 | 没有（改走 `SetSpace`） |
| `CNodeSaveCaller` | 有 | **没有** |
| `CNodeCancelBadgedSends` | 没有 | 有 |
| 对象类型 `seL4_SchedContextObject` / `seL4_ReplyObject` | 没有 | 有 |

**类型名全是别名。** `seL4_CNode`、`seL4_TCB`、`seL4_IRQHandler`…
一路 typedef 到 `seL4_CPtr` 再到 `seL4_Word`
（`seL4/libsel4/include/sel4/types.h`、`seL4/libsel4/include/sel4/simple_types.h`）。
签名里的类型只说明"这一格放的是哪种能力"，不说明宽度。

**权利永远在低 4 位。** `seL4_CapRights` 的 32/64 位布局只差 padding
（28 vs 32），四位依次是 grant_reply / grant / read / write
（`seL4/libsel4/mode_include/32/sel4/shared_types.bf`）。

**几个常量的真实出处**（都在 `seL4/libsel4/include/sel4/constants.h`）：
`seL4_MsgMaxLength = 120`（与 `seL4_MsgLengthBits = 7`、`seL4_MsgExtraCapBits = 2`
同一个 enum，第 11 章）、`seL4_MinPrio` / `seL4_MaxPrio`（后者 = `CONFIG_NUM_PRIORITIES - 1`）、
MCS 才有的 `seL4_MinSchedContextBits = 7`（SC 对象最小 128 字节，第 14 章）。

**debug 调用不在被证明的那条路上。** `seL4_DebugPutChar` 一组声明在
`CONFIG_PRINTING` 里，内核侧由 `handleUnknownSyscall`
（`seL4/src/api/syscall.c`）用一串 `if` 接走——第 09/10 章的标签分派表覆盖不到它（第 01 章对照）。

### 引用检查（第 5 关）怎么才过得去

`tools/check-refs.py` 有**两个根**：`seL4/…` / `l4v/…` 在代码根 `SE4SRC` 下核，
`docs/Tutorials|projects|Hardware|processes|content_collections/…`、`capdl/…`、
`microkit/…` 在文档镜像根 `SE4DOC` 下核（镜像不在时这些引用整体跳过并**报出条数**，
不静默放行）；第三条通道是"文件名 + 第 N 行"。带行号的引用会再查一次
**"离路径最近的那个 `` `标识名` `` 是否真的出现在被引行上下 8 行内"**。
七条实测经验：

| 现象 | 原因 | 对策 |
|---|---|---|
| 报了 `` `x` 现在在 path:N `` | 行号漂了，或锚点选错 | 以**当前**行号为准重写，别改代码 |
| 明明行号对，却"静默通过"（没被检查） | 路径附近 40/60 字符内没有**独立的** `` `名字` `` | 写成 `` `ANCHOR`（`真实路径:行号`） ``，锚点紧贴路径 |
| 锚点匹配不上 | `cap_endpoint_cap_get_capCanSend` 这类名字，后缀 `capCanSend` 因**下划线**不算整词 | 引**全称**，别引后缀 |
| 表格行里的行号被上一行的名字判死 | 反查窗口跨了单元格 | 单元格内自带锚点，或去掉编号 |
| 一句大白话被判"行号站不住" | 路径后紧跟括号里的数字（`…bf`（64 位…））被读成行号 | 让数字与路径之间隔个词，或写成"目录名换成 64" |
| 锚点被同一行左侧的名字抢走（表格最常见） | 反查窗口 40 字符先命中左边那个 `` `Read` ``，它当然不在被引行 | 把锚点紧贴到路径左边：`` `endpoint_cap`（`seL4/…` 第 24 行） `` |
| 只想说"某文件有 1212 行"却被查行号 | `Example2.thy` 紧邻"第 1212 行"就构成一次带行号引用 | 写成"有 1212 行"，或把文件名字与数字隔开 |

反引号里必须**只有一个标识符**：`Configure (MCS)`、`flags & BIT(x)`、
`src/object/foo.c` 这种带空格/括号/斜杠的内容不构成锚点。

