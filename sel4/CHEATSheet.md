# seL4 速查表

Isabelle2025-2 / HOL，配套 `docs/01..24` 与 `examples/S01..S24`。
本页分三部分：**术语与代码形状速查**、**真实代码地图**（按"想看什么"排），
以及**实测坑位索引**（按症状排列，指向章号）。坑位总数是 240 条
（24 章 × 10 条），每条都在本机跑出来过。

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
| 错误与故障类型 | `l4v/spec/abstract/ExceptionTypes_A.thy` |
| 非确定性单子 | `l4v/lib/Monads/nondet/Nondet_Monad.thy` |
| VCG / wp | `l4v/lib/Monads/nondet/Nondet_VCG.thy`、`l4v/lib/Monads/wp/WP.thy` |
| `no_fail` 与"空结果" | `l4v/lib/Monads/nondet/Nondet_No_Fail.thy`、`Nondet_Empty_Fail.thy` |
| 精化关系 | `l4v/lib/Corres_UL.thy`、`l4v/proof/refine/Corres.thy` |
| 不变式 | `l4v/proof/invariant-abstract/AInvs.thy` |
| 完整性 | `l4v/proof/access-control/Syscall_AC.thy`、`CNode_AC.thy`、`Ipc_AC.thy` |
| 非干扰 | `l4v/proof/infoflow/Noninterference.thy`、`Noninterference_Base.thy` |
| capDL | `l4v/spec/capDL/Structures_D.thy`、`CSpace_D.thy`、`CNode_D.thy` |
| C 规范 | `l4v/spec/cspec/KernelState_C.thy`、`KernelInc_C.thy` |
| C 源码（对象） | `seL4/src/object/cnode.c`、`endpoint.c`、`notification.c`、`tcb.c`、`untyped.c` |
| C 源码（入口/调度） | `seL4/src/api/syscall.c`、`seL4/src/kernel/thread.c` |
| 用户 API 与错误码 | `seL4/libsel4/include/sel4/errors.h`、`objecttype.h`、`shared_types.h` |
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

### 类型 / 证明类

| 症状 | 真凶 | 章 |
|---|---|---|
| `rule ext` 用不上 | 目标是**记录**相等而非函数相等；用 `cases` 拆字段 | 22 |
| `simp` 把目标拆成"相等⟹… ∧ 不等⟹…" | `fun_upd` 的 `if` 判不了；显式 `case_tac` | 22 |
| 等式假设"没生效" | `simp` 对等式的重写方向不确定；把公共部分提成参数 | 22 |
| 单子等式证不动 | 要拆 `fst`/`snd` 两个分量再 `prod_eqI` | 08 |
| `case … of` 不分裂 | 缺 `split: sum.split` / `cap.splits` | 08 |
| 递归的 `termination` 挂死 | 长度/大小的算术自动化看不出；加燃料参数做结构递归 | 04 |
| `Ignoring duplicate unsafe introduction` 告警 | `r⁺`/`r*` 的引入规则重复；换成 `r_into_trancl` 等具体规则 | 06 / 23 |
| 全称量化的事实实例化不上 | 有变量遮蔽；改名或用显式 `fix`/`obtain` | 17 |
| 归纳假设不够用 | 忘了 `arbitrary:` | 22 / 24 |
| `Suc.IH` 用不上 | 要显式 `Suc.IH[OF Suc.prems(1) step_u]` | 22 |

### 语义 / 建模类

| 症状 | 真凶 | 章 |
|---|---|---|
| 以为非阻塞发送会报错 | 是 `Dropped`，消息被丢弃 | 11 |
| 以为 `SendEP []` 合法 | 良构性排除空队列（空了应是 `IdleEP`） | 11 |
| 以为挂起再恢复是 `Running` | 实测是 `Restart` | 13 |
| 以为 `descendants_of` 是直接儿子 | 是传递闭包 | 05 |
| 以为 `no_fail` ⟹ 结果非空 | 两者独立（`kselect {}`） | 07 |
| 以为失败的程序仍可 `valid` | 失败 ⟹ 任何 `valid` 都不成立 | 16 |
| 以为 `Zombie` 槽可覆盖 | `can_be_replaced` 为假 | 06 |
| 以为通知可以重绑定 | 已绑定再绑返回 `None` | 12 |
| 以为 reply 可复用 | 一次性（`reply_is_one_shot`） | 12 |
| 以为 `{AllowWrite}` 是合法 VM 权利 | 不合法，且是**静默降级**不是报错 | 03 |
| 以为只读就无害、不破坏隔离 | 隔离是连通性性质，与权利大小无关 | 24 |
| 以为改 CNode 大小等于请求位数 | CNode 多一个 slot（`cnode_needs_more_than_asked`） | 02 |
| 以为抽象层失败时具体层也要对应 | 抽象失败 ⟹ 具体任意 | 18 |

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

---

## 六、验证脚本怎么用

```bash
./run-all.sh                     # 全量：build + 两遍 + 比对 + 引用检查
./run-all.sh S22_infoflow        # 只报告一个 theory
./run-all.sh clean               # 清 build/ 下本脚本产物
SE4SRC=/path/to/seL4 ./run-all.sh   # 真实代码不在默认位置时
```

产物：`build/build.log`、`build/first/out/SNN_*.txt`、`build/second/out/SNN_*.txt`。
正文里的每段 `text` 输出都能在这些 `.txt` 里逐字节找到。
