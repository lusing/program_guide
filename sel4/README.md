# seL4 教程（Isabelle/HOL 上的形式化验证）

面向**已经会写程序、想看懂 seL4 证明**的读者：从"能力是什么"讲到
内核的每一步行为、非确定性单子、霍尔逻辑与精化链，再到
**完整性**与**非干扰**两个安全定理，最后用 capDL 与一个分区隔离案例收束。

**章号 = 示例编号**——01–24 章每章对应 `examples/` 里一个经
`isabelle build` 构建通过、且两遍输出逐字节一致的 `.thy` 文件。

> 核心理念：**本教程不改动 seL4 的一行代码，只是把真实代码里的结构
> 抽成可运行的小模型，并把每一条结论都交给机器检查。**
> 正文里出现的每一段输出都从 `build/` 产物里抽出，不是想象中的样子；
> 正文里出现的每个 `l4v/…`、`seL4/…` 路径都由 `run-all.sh` 校验存在，
> 标了 `<!-- 源码块：路径:起-止 -->` 的更狠——那 284 处行号声明也当断言核：
> 块行数必须等于区间长度、逐行与那份文件相等，省略或改写都会被判失败。
> 详见 [01 章](docs/01-overview.md)。

## 目录结构

```text
sel4/
├── README.md        本文件
├── CHEATSheet.md    语法速查 + 实测坑位索引（344 条）
├── run-all.sh       验证脚本（bash，六关）
├── docs/            24 章教程（01 → 24 顺序阅读）
├── examples/        24 个 .thy 示例 + ROOT（章号 = 示例编号）
└── build/           验证产物（build.log + 两遍输出，可删）
```

真实代码不在本目录里。默认根按平台取（`run-all.sh` 第 68--74 行）：
Linux `/home/admin/hol/seL4`、macOS `/Volumes/mac004/lang/seL4`，
`SE4SRC=…` 可覆盖。下有两个仓库：

| 路径 | 内容 |
|---|---|
| `l4v/spec/abstract/` | 抽象规范（对象、能力、CSpace、IPC、调度…） |
| `l4v/spec/cspec/` | 由 C 源码翻译出的 C 规范 |
| `l4v/spec/capDL/` | capDL：能力分布图（类型层是 `Types_D.thy`，不是 `Structures_D.thy`）；**图上没有 `well_formed`** |
| `l4v/sys-init/` | 系统初始化器：`WellFormed_SI.thy` 才是定义"一张图是否合法"的地方 |
| `l4v/lib/Monads/` | 非确定性单子（`nondet/`）与 wp 方法（`wp/`） |
| `l4v/proof/invariant-abstract/` | 不变式 |
| `l4v/proof/access-control/` | 完整性 |
| `l4v/proof/infoflow/` | 非干扰 |
| `l4v/proof/refine/`、`crefine/`、`asmrefine/` | 精化链的三段 |
| `l4v/lib/Simulation.thy` | 精化代数本体（第 20 章逐条抄它，321 行） |
| `seL4/src/` | C 内核（`object/`、`api/`、`kernel/`） |
| `seL4/libsel4/include/sel4/` | 用户 API 与错误码 |
| `l4v/docs/` | l4v 自己的约定文档：`conventions.md`、`arch-split.md`、`haskell-assertions.md`、`plans/the-matrix.md` |
| `seL4/CAVEATS.md` | **未验证假设清单**（读定理必须先读它） |

还有**第二个根**：官方文档站的本地镜像，默认 Linux `/home/admin/github/seL4`
（`SE4DOC=…` 覆盖）。教程里凡是写 `docs/…`、`capdl/…`、`microkit/…` 的引用
都落在这里，`docs/` 下只放行 `Tutorials`、`projects`、`Hardware`、`processes`、
`content_collections` 五个子目录——这样本教程自己的 `docs/NN-*.md` 不会被当成引用。
它和 `SE4SRC` 一样由第 5、6 关核对；镜像缺失时那批引用**计入"未核"并报出条数**，
不静默放行。

## 真实代码对齐哪一版

本教程的每条 C 侧断言都是在这一版上核对的，换版本要重新核对：

| 仓库 | 版本 | 核对日期 |
|---|---|---|
| `seL4/`（C 内核 + libsel4） | `16.0.0-49-g0f1082911`（最后提交 2026-09-22） | 2026-09-25 |
| `l4v/`（Isabelle 规范与证明） | 同一目录下的独立 git 仓库 | 2026-09-25 |

三条会咬人的版本事实：

1. **libsel4 的大部分 C 原型不在树里**。`seL4/libsel4/tools/syscall_stub_gen.py` 和
   `seL4/libsel4/tools/bitfield_gen.py` 在构建时才生成它们。所以在这个仓库里
   `grep -rn "seL4_CNode_Copy(" libsel4/` 是搜不到的——要读签名就得去
   `seL4/libsel4/include/interfaces/object-api.xml`（方法名 + 参数顺序），
   要读位域布局就去 `seL4/libsel4/mode_include/32/sel4/shared_types.bf`。
2. **16.x 删掉了旧教程里的三个类型**：`CSpaceData`、`seL4_CapReply`、
   `seL4_BootInfo.extraBadges` 在本树全文 grep **0 命中**。官方
   kernel tutorials 的示例代码仍按旧签名写（`seL4_CNode_Copy` 收一个
   `CSpaceData` 结构体），照抄会编译不过；现在的签名把这些字段摊平成
   `dest_index, dest_depth, src_root, src_index, src_depth, rights` 六个参数。
3. **master 与 MCS 是两套系统调用头**，`seL4/libsel4/include/sel4/syscalls.h:18--22`
   按 `CONFIG_KERNEL_MCS` 二选一，差异不只是多个 reply 参数——
   `seL4_Reply` 只在 master 侧存在，`seL4_Wait` 在 master 侧返回 `void`、
   在 MCS 侧返回 `seL4_MessageInfo_t`。

## 官方教程对照

docs.sel4.systems 的 Kernel Tutorials 是本仓库之外的另一套教材，
讲的是"怎么写用户态 seL4 程序"（本教程讲"内核为什么是对的"）。
**24 章末尾各有一节"官方教程对照"**：把官方页的说法逐条钉到真实代码上，
并记下对不上的地方。页名与本教程章节的对应关系：

| 官方页 | 本教程章节 |
|---|---|
| `hello-world` | [01](docs/01-overview.md) |
| `capabilities` | [02](docs/02-kernel-objects.md)、[03](docs/03-rights.md)、[04](docs/04-cspace.md)、[06](docs/06-revoke-delete.md) |
| `mapping` | [02](docs/02-kernel-objects.md) |
| `untyped` | [02](docs/02-kernel-objects.md)、[15](docs/15-retype.md) |
| `threads` | [13](docs/13-tcb.md) |
| `ipc` | [09](docs/09-syscall-entry.md)、[10](docs/10-decode.md)、[11](docs/11-ipc.md) |
| `notifications` | [12](docs/12-notification.md) |
| `interrupts` | [12](docs/12-notification.md) |
| `fault-handlers` | [08](docs/08-error-monad.md)、[09](docs/09-syscall-entry.md)、[10](docs/10-decode.md) |
| `mcs` | [14](docs/14-schedule.md) |

**但镜像里的教程页大多是"壳"。** `docs/Tutorials/` 下 28 个页面里有 20 个只有
front matter 加一行 `{% include tutorial.md %}`，正文由 `docs/Makefile`
在构建时从官方教程仓库克隆到 `_repos/` 再渲染到 `_processed/tutes/`；
本地镜像没有 `_repos/`，所以这 20 篇的正文离线取不到。
镜像里**真有内容**的那 8 篇（`index.md`、`setting-up.md`、`get-the-tutorials.md`、
四个 how-to/end 页、`pathways.md`）反倒最有用：`how-to-seL4.md` 是全部教程解答的
锚点索引，`setting-up.md` 与 `get-the-tutorials.md` 说明了官方那套
`repo init` / `repo sync` 的取码方式——和本教程这种"两个手工并排的仓库"不同，
这两篇从头到尾没有一处教你怎么取 `l4v/` 证明树：它们取的是跑 CAmkES/L4v 那一堆
docker 与教程示例用的 manifest，Isabelle 侧压根不在里面。

至于证明那一侧，官方口径不在教程站，而在仓库里：
`l4v/README.md`、`l4v/docs/` 那几篇、`l4v/proof/ROOT` 与 `l4v/spec/ROOT`、
`docs/projects/sel4/verified-configurations.md`。第 16--20 章的对照一节引的就是这些。

URL 规则：`https://docs.sel4.systems/Tutorials/<页名>.html`（抓取日期 2026-09-25）。
这些链接由人工核对，`run-all.sh` 不检查外部 URL——**它检查的是每一章里
那句"官方页这么说"所对应的 C 侧事实**，即紧跟链接的那些 `seL4/…` 路径与行号。

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 开场：为什么要被证明](docs/01-overview.md) | 两份真实代码、权利掩码、验证纪律 | `S01_overview.thy` |
| [02 内核对象与能力](docs/02-kernel-objects.md) | 门与钥匙、默认权利、对象大小 | `S02_kernel_objects.thy` |
| [03 权利与掩码](docs/03-rights.md) | 权利集合、交集语义、VM 权利 | `S03_rights.thy` |
| [04 CSpace 与地址解析](docs/04-cspace.md) | guard/bits、路径拆分、有界递归 | `S04_cspace.thy` |
| [05 能力派生树](docs/05-cdt.md) | CDT、`descendants_of`、派生不增权、同一个概念的三份实现 | `S05_cdt.thy` |
| [06 回收与删除](docs/06-revoke-delete.md) | delete/revoke、Zombie | `S06_revoke_delete.thy` |
| [07 非确定性状态单子](docs/07-nondet-monad.md) | 结果集+失败标志、do 记号、`no_fail`、库里那份说明书 | `S07_nondet_monad.thy` |
| [08 错误单子与解码](docs/08-error-monad.md) | `bindE` 短路、解码顺序、五层单子、错误码怎么回到用户 | `S08_error_monad.thy` |
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
| [20 精化链与信任基](docs/20-refine-chain.md) | 传递性、性质转移、会话链与每配置验到什么 | `S20_refine_chain.thy` |
| [21 完整性](docs/21-integrity.md) | authority、删除只减权、派生不越权 | `S21_integrity.thy` |
| [22 非干扰](docs/22-infoflow.md) | 擦除、`uwr`、单步 ⟹ 序列 | `S22_infoflow.thy` |
| [23 capDL](docs/23-capdl.md) | 类型层、CDT 与撤销、非确定调度、井形性在 sys-init | `S23_capdl.thy` |
| [24 综合案例：take-grant 与孤岛](docs/24-capstone.md) | 六个权利、`extra_rights` 摊平、单步 ⟹ 任意序列 ⟹ 信息流 | `S24_capstone.thy` |

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
| 真实代码根 | Linux `SE4SRC=/home/admin/hol/seL4`；macOS `/Volumes/mac004/lang/seL4` |
| 官方文档镜像根 | Linux `SE4DOC=/home/admin/github/seL4`（下含 `docs/`、`capdl/`、`microkit/`） |

父会话为什么是 `HOL-Library`：do 记号需要 `Monad_Syntax`。
这一处会一路影响验证脚本（见下面"环境注意事项"第 2 条）。

## 验证

```bash
./run-all.sh              # 全量：build + 两遍 process_theories + 逐字节比对 + 引用检查
./run-all.sh refs         # 只跑第 5、6 关，沿用 build/first/out —— 改文档时用这个
./run-all.sh S07_nondet_monad   # 只报告一个 theory（build/抽取仍全量）
./run-all.sh clean        # 清 build/ 下本脚本产物
```

`refs` 模式复用 `build/first/out/` 里的既有产物，几秒钟就能判绿；
**只有动过 `examples/*.thy` 才必须跑全量**（第 1--4 关会重新构建并重跑输出）。

六关（`run-all.sh` 里编号 `[1/6]…[6/6]`）：

1. `isabelle build -D examples` 退出码 0，且日志无溃逃痕迹
   （Isabelle/Scala 工具失败不一定让进程退出码非 0，必须查日志）；
2. `process_theories -O` 捕获每个示例的 `==== NN 开始 ====` / `==== NN 结束 ====` 区间，
   要求标记齐、区间非空、无控制字符、无溃逃痕迹；
3. 同一命令连跑两遍；
4. **逐字节比对两遍输出**——Isabelle 只有一个引擎，没有跨通道可比，
   于是用"运行间确定性"替代；输出漂移说明示例依赖了并行调度或环境状态，那本身就是 bug；
5. 检查 `docs/`、`README.md`、`CHEATSheet.md`、`examples/*.thy` 里出现的每个
   `seL4/…`、`l4v/…` 路径真实存在（`docs/…`、`capdl/…`、`microkit/…` 那一路走文档
   镜像根）；带行号的还要求"被引行上下 8 行内确实出现离它最近的那个标识名"
   ——专抓"名字对、位置错"（教程不写想象中的引用）；
6. **正文的每个 ```text 块必须逐行来自实测**：默认按"实测块"处理，
   即空白折叠后要是第 2 关抽取产物的子串；手写示意要标 `<!-- 示意块：… -->`，
   摘自真实源码的要标 `<!-- 源码块：路径:起-止 -->`（两个根都支持）。
   带了行号（`:起-止`、`:N`、`第 起--止 行`、`第 N 行`）就是**严格对齐**：块行数必须等于
   区间长度且逐行相等（只折叠空白），省略、改写、挪位置一律判失败；只写路径不带行号才
   退化成"每行在该文件里找得到"——现在 284 处源码块标记**全部带区间**，
   行号不再只是给人看的注释。

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
   所以全量验证是分钟级：整棵 `l4v` 树有 1883 个 `.thy` 文件（`l4v/spec` 加 `l4v/proof`
   就占 1207 个），本教程的 24 个示例一个都不 import 它们。
   本机两轮实测 `real 4m42s` / `4m49s`（`threads=1`）：第 1 关在堆缓存已热时只花 6 秒
   （`ISABELLE_HEAPS` 派生自 `/tmp/isb-sel4-user`，清掉它就得真正重 build，
   那一次的耗时本教程没测过——别再拿"几秒"当第 1 关的成本）；
   时间全在第 2、3 关——两遍 `process_theories` 各约 2m15s，
   是 24 个理论逐个启动 PolyML 的固定开销，与检查逻辑无关。
   **改文档别跑全量，用 `./run-all.sh refs`（实测不到 1 秒）。**

## 与其他教程的关系

本教程按 [Isabelle/HOL 教程](../isabelle/README.md) 的体例搭建
（24 章 + 示例 + 验证脚本 + 速查表），先读它第 01–08 章会顺畅很多；
反过来，本教程第 07、16 章也是单子与霍尔逻辑的一份实战材料。

---

**免责**：本教程的模型是为了讲清结构而写的**简化模型**，
不等于 seL4 的真实规范；所有真实结论请以
`l4v/` 里的证明与 `seL4/CAVEATS.md` 的假设清单为准。
