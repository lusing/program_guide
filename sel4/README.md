# seL4 教程（Isabelle/HOL 上的形式化验证）

面向**已经会写程序、想看懂 seL4 证明**的读者：从"能力是什么"讲到
内核的每一步行为、非确定性单子、霍尔逻辑与精化链，再到
**完整性**与**非干扰**两个安全定理，最后用 capDL 与一个分区隔离案例收束。

**章号 = 示例编号**——01–24 章每章对应 `examples/` 里一个经
`isabelle build` 构建通过、且两遍输出逐字节一致的 `.thy` 文件。

> 核心理念：**本教程不改动 seL4 的一行代码，只是把真实代码里的结构
> 抽成可运行的小模型，并把每一条结论都交给机器检查。**
> 正文里出现的每一段输出都从 `build/` 产物里抽出，不是想象中的样子；
> 正文里出现的每个 `l4v/…`、`seL4/…` 路径都由 `run-all.sh` 校验存在。
> 详见 [01 章](docs/01-overview.md)。

## 目录结构

```text
sel4/
├── README.md        本文件
├── CHEATSheet.md    语法速查 + 实测坑位索引（240 条）
├── run-all.sh       验证脚本（bash，五关）
├── docs/            24 章教程（01 → 24 顺序阅读）
├── examples/        24 个 .thy 示例 + ROOT（章号 = 示例编号）
└── build/           验证产物（build.log + 两遍输出，可删）
```

真实代码不在本目录里，默认根是 `/Volumes/mac004/lang/seL4`
（`SE4SRC=…` 可覆盖），下有两个仓库：

| 路径 | 内容 |
|---|---|
| `l4v/spec/abstract/` | 抽象规范（对象、能力、CSpace、IPC、调度…） |
| `l4v/spec/cspec/` | 由 C 源码翻译出的 C 规范 |
| `l4v/spec/capDL/` | capDL：能力分布语言与图上的可达性 |
| `l4v/lib/Monads/` | 非确定性单子（`nondet/`）与 wp 方法（`wp/`） |
| `l4v/proof/invariant-abstract/` | 不变式 |
| `l4v/proof/access-control/` | 完整性 |
| `l4v/proof/infoflow/` | 非干扰 |
| `l4v/proof/refine/`、`crefine/`、`asmrefine/` | 精化链的三段 |
| `seL4/src/` | C 内核（`object/`、`api/`、`kernel/`） |
| `seL4/libsel4/include/sel4/` | 用户 API 与错误码 |
| `seL4/CAVEATS.md` | **未验证假设清单**（读定理必须先读它） |

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 开场：为什么要被证明](docs/01-overview.md) | 两份真实代码、权利掩码、验证纪律 | `S01_overview.thy` |
| [02 内核对象与能力](docs/02-kernel-objects.md) | 门与钥匙、默认权利、对象大小 | `S02_kernel_objects.thy` |
| [03 权利与掩码](docs/03-rights.md) | 权利集合、交集语义、VM 权利 | `S03_rights.thy` |
| [04 CSpace 与地址解析](docs/04-cspace.md) | guard/bits、路径拆分、有界递归 | `S04_cspace.thy` |
| [05 能力派生树](docs/05-cdt.md) | CDT、`descendants_of`、派生不增权 | `S05_cdt.thy` |
| [06 回收与删除](docs/06-revoke-delete.md) | delete/revoke、Zombie | `S06_revoke_delete.thy` |
| [07 非确定性状态单子](docs/07-nondet-monad.md) | 结果集+失败标志、do 记号、`no_fail` | `S07_nondet_monad.thy` |
| [08 错误单子与解码](docs/08-error-monad.md) | `bindE` 短路、解码顺序、error/fault | `S08_error_monad.thy` |
| [09 系统调用入口](docs/09-syscall-entry.md) | fault > error > 执行、事件分派 | `S09_syscall_entry.thy` |
| [10 解码器](docs/10-decode.md) | 标签、参数个数、掩码、额外能力 | `S10_decode.thy` |
| [11 IPC](docs/11-ipc.md) | 端点状态机、良构性、badge | `S11_ipc.thy` |
| [12 通知与 Reply](docs/12-notification.md) | 位集合语义、绑定一次性、一次性 reply | `S12_notification.thy` |
| [13 线程控制块](docs/13-tcb.md) | `runnable`、挂起/恢复、ctable 0 号槽 | `S13_tcb.thy` |
| [14 调度](docs/14-schedule.md) | 优先级队列、域轮转 | `S14_schedule.thy` |
| [15 内存再类型化](docs/15-retype.md) | Untyped 水位、不重叠、无子孙前提 | `S15_retype.thy` |
| [16 霍尔逻辑与 wp](docs/16-hoare-wp.md) | `valid`、失败即不 `valid`、强弱调整 | `S16_hoare_wp.thy` |
| [17 不变式](docs/17-invariants.md) | `valid_objs`、`valid_mdb`、`invs` | `S17_invariants.thy` |
| [18 精化关系](docs/18-corres.md) | 状态关系、`corres`、抽象失败即任意 | `S18_corres.thy` |
| [19 C 规范与堆](docs/19-cspec.md) | 字节堆、结构体字段、C↔D 对应 | `S19_cspec.thy` |
| [20 精化链与信任基](docs/20-refine-chain.md) | 传递性、性质转移、未验证假设 | `S20_refine_chain.thy` |
| [21 完整性](docs/21-integrity.md) | authority、删除只减权、派生不越权 | `S21_integrity.thy` |
| [22 非干扰](docs/22-infoflow.md) | 擦除、`uwr`、单步 ⟹ 序列 | `S22_infoflow.thy` |
| [23 capDL](docs/23-capdl.md) | 良构图、可达性、两分区互不可达 | `S23_capdl.thy` |
| [24 综合案例：分区隔离](docs/24-capstone.md) | 合法操作、单步 ⟹ 任意序列 | `S24_capstone.thy` |

学习路线：01–03 能力模型（全教程的地基）→ 04–06 CSpace 与派生树 →
07–10 内核代码的"形状"（单子、错误、入口、解码）→ 11–15 各类对象与调度 →
16–17 证明工具（wp 与不变式）→ 18–20 精化链 → 21–22 两个安全定理 →
23–24 配置层与综合收束。

## 工具链

| 组件 | 值 |
|---|---|
| 发行版 | Isabelle2025-2 |
| 可执行文件（macOS） | `/Applications/Isabelle2025-2.app/bin/isabelle` |
| 会话 | `SeL4Tut`（见 `examples/ROOT`，父会话 **`HOL-Library`**） |
| import | `Main`；第 07/08 章另加 `"HOL-Library.Monad_Syntax"` |
| 真实代码根 | `SE4SRC=/Volumes/mac004/lang/seL4` |

父会话为什么是 `HOL-Library`：do 记号需要 `Monad_Syntax`。
这一处会一路影响验证脚本（见下面"环境注意事项"第 2 条）。

## 验证

```bash
./run-all.sh              # 全量：build + 两遍 process_theories + 逐字节比对 + 引用检查
./run-all.sh S07_nondet_monad   # 只报告一个 theory（build/抽取仍全量）
./run-all.sh clean        # 清 build/ 下本脚本产物
```

五关：

1. `isabelle build -D examples` 退出码 0，且日志无溃逃痕迹
   （Isabelle/Scala 工具失败不一定让进程退出码非 0，必须查日志）；
2. `process_theories -O` 捕获每个示例的 `==== NN 开始 ====` / `==== NN 结束 ====` 区间，
   要求标记齐、区间非空、无控制字符、无溃逃痕迹；
3. 同一命令连跑两遍；
4. **逐字节比对两遍输出**——Isabelle 只有一个引擎，没有跨通道可比，
   于是用"运行间确定性"替代；输出漂移说明示例依赖了并行调度或环境状态，那本身就是 bug；
5. 检查 `docs/` 与 `README.md` 里出现的每个 `seL4/…`、`l4v/…` 路径真实存在
   （教程不写想象中的引用）。

## 环境注意事项（本机实测，换环境要重新确认）

1. **SQLite / `USER_HOME`**：构建库是 SQLite，写库时要 `unlink` 掉 `-journal`。
   macOS 上对 `~/` 下未签名二进制的 `unlink` 返回 EPERM，于是报
   `[SQLITE_ERROR] cannot commit` / `[SQLITE_IOERR_DELETE]`。
   `ISABELLE_HOME_USER` / `ISABELLE_HEAPS` 在 `etc/settings` 里是**无条件赋值**，
   直接设环境变量无效；它们都由 `USER_HOME` 派生，而 `USER_HOME` 只在为空时才被赋值。
   脚本因此 `export USER_HOME=/tmp/isb-sel4-user`。
2. **`process_theories` 的基线会话必须是 `-l HOL-Library`**：写 `-l HOL` 时，
   S07/S08 的 `imports "HOL-Library.Monad_Syntax"` 会报
   `Bad import … need to include sessions "HOL-Library" in ROOT`，
   而且 **run.log 是空的、错误只进 stderr**——表现是 24/24 "区间为空"，极易误判。
3. **两遍可比要关三个开关**：`parallel_print=false`、`parallel_proofs=0`、`threads=1`。
   缺任何一个，消息就会在两遍之间落到不同位置。
4. **控制字符检查用 `[[:cntrl:]]`**：本教程的标记是中文，
   写成 `[^[:print:][:space:]]` 时 `LC_ALL=C` 下 CJK 的 UTF-8 字节会被判成控制字符，24/24 误报。
5. **溃逃判据必须锚定横幅**：裸搜 `Error` 会把 `throwError` / `DError` / `seL4_Error`
   这些正常标识符算进去，S08、S10 恒误报。用 `^\*\*\*`、`^Error`、`FAILED`、`Unfinished`、`Uncaught`。
6. **示例只 import `Main` / `HOL-Library`**，不依赖 l4v 会话，
   所以全量验证能在两分钟内跑完（真实 l4v 全量构建要几小时）。

## 与其他教程的关系

本教程按 [Isabelle/HOL 教程](../isabelle/README.md) 的体例搭建
（24 章 + 示例 + 验证脚本 + 速查表），先读它第 01–08 章会顺畅很多；
反过来，本教程第 07、16 章也是单子与霍尔逻辑的一份实战材料。

---

**免责**：本教程的模型是为了讲清结构而写的**简化模型**，
不等于 seL4 的真实规范；所有真实结论请以
`l4v/` 里的证明与 `seL4/CAVEATS.md` 的假设清单为准。
