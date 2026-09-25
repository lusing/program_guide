# 01 · 开场：seL4 是"被证明过的内核"

对应示例：`../examples/S01_overview.thy`

## 1.1 seL4 是"被证明过的内核"

seL4 是这个教程里唯一一个"结论不由作者宣布、而由机器检查出来"的对象。
真实代码分两个仓库（本教程所有引用都指向它们，`run-all.sh` 第 5 关会逐个校验路径存在）：

| 仓库 | 内容 |
|---|---|
| `l4v/` | Isabelle/HOL 写的规范与证明：抽象规范、设计规范、C 规范、安全定理 |
| `seL4/` | 真正跑在机器上的 C 内核、`libsel4` 头文件、manual |

本教程校对的是 `seL4/VERSION` 里的 **16.0.0-dev** 与 `l4v/` 的当前 master。
seL4 的 API 在这一版上有过实质变动（MCS 的 Reply 能力、`seL4_SchedContext` 等），
所以正文里凡是"真实代码是这么写的"的句子都带路径引用，第 5 关会逐个核对；
换一个大版本，这些引用会成片失效——那是特性，不是 bug。

它们的关系是**精化**：抽象规范说"内核该做什么"，设计规范是可执行原型，
C 规范由 `seL4/` 的 C 源码翻译而来，最后还有汇编层。
每一层都要证明"我这一层的每一步，都对应上一层的某一步"。

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
l4v/spec/abstract/   ← 抽象规范（Structures_A.thy、CSpace_A.thy …）
l4v/spec/cspec/      ← 由 seL4/ 的 C 翻译出的规范
l4v/proof/           ← 不变式、精化、访问控制、信息流、汇编精化
seL4/src/            ← C 内核实现（object/、api/、kernel/）
seL4/libsel4/include/sel4/  ← 用户可见的 API 与错误码
```

## 1.2 环境自检

示例先确认自己在哪个 Isabelle 里跑（实测输出）：

```text
Isabelle 版本标识: Isabelle2025-2
```

| 项 | 值 |
|---|---|
| 发行版 | Isabelle2025-2 |
| 可执行文件（Linux） | `/home/admin/hol/Isabelle2025-2/bin/isabelle` |
| 可执行文件（macOS） | `/Applications/Isabelle2025-2.app/bin/isabelle` |
| 会话 | `SeL4Tut`（见 `../examples/ROOT`，父会话 **`HOL-Library`**） |
| 真实代码根 | Linux `/home/admin/hol/seL4`，macOS `/Volumes/mac004/lang/seL4`（`SE4SRC=…` 可覆盖） |

`run-all.sh` 按 `uname -s` 自动选这两条路径，找不到才要求显式设 `ISABELLE=` / `SE4SRC=`。

父会话为什么是 `HOL-Library` 而不是 `HOL`：第 07、08 章要用 do 记号，
得 import `HOL-Library.Monad_Syntax`。这一处改动会一路影响到验证脚本（见坑位 6）。

## 1.3 最小的能力模型：权利的集合

seL4 的全部访问控制归结到一个动作：**取交集**。
给能力派生出去时，新能力的权利 = 老权利 ∩ 请求的权利。
所以"越权"在数学上不可能——交集不会比两边大。

真实定义见 `l4v/spec/abstract/Structures_A.thy:242` 的 `mask_cap`；
权利全集那个常量叫 `all_rights`，定义在
`l4v/spec/abstract/CapRights_A.thy:32`。
`mask_cap` 的完整形状是 `cap_rights_update (cap_rights cap ∩ rights) cap`，
而 `cap_rights_update` 在交集之外还按对象类型加了两条**只往下压**的补丁
（`Structures_A.thy:222`）：通知能力抹掉 `AllowGrant` 与 `AllowGrantReply`，
Reply 能力强制留下 `AllowWrite`（回信要能写调用者的缓冲）。
本教程的模型只建到"权利集合取交集"这一层，这两条特例在第 03 章会单独说明。

## 1.4 第一条定理：掩码不会让权利变多

```text
theorem mask_subset: S01_overview.mask ?R ?R' \<subseteq> ?R
```

```text
theorem mask_all_rights: S01_overview.mask ?R all_rights = ?R
```

两条分别是：掩码只会缩小；拿"全部权利"去掩码等于没掩码。
这条"只减不增"的性质，会在第 03 章（掩码）、第 05 章（派生）、
第 21 章（完整性）以不同抽象层次被重复证明三次。

求值器还会把结果与类型一起打印（实测）：

```text
"4"
  :: "nat"
```

注意类型总是跟着结果一起出现——seL4 的证明里大量使用机器字，
"这个数字是什么类型"几乎每次都要明确。

## 1.5 本教程的验证方式

根目录 `run-all.sh` 做六件事：

1. `isabelle build -D examples` 全量构建，退出码 0 且日志无溃逃痕迹；
2. `isabelle process_theories -O` 捕获每个示例的标记区间（示例里用 `ML` 打印 `==== NN 开始 ====` / `==== NN 结束 ====`）；
3. 同一命令连跑两遍；
4. 逐字节比对两遍输出；
5. 检查文档与示例里出现的每个 `seL4/…`、`l4v/…` 路径在真实代码根下存在；
   带行号的引用还要"被引行上下 8 行内确实有那个名字"（`tools/check-refs.py`）；
6. 检查正文里每个 ```` ```text ```` 块**逐行**能在第 2 步的产物里找到——
   不是实测输出的块必须显式标 `<!-- 示意块 -->` 或 `<!-- 源码块：路径 -->`。

第 4 步的理由：Isabelle 只有一个引擎，没有"跨通道一致性"可比，
于是用"运行间确定性"替代。如果两遍输出不一样，说明示例偷偷依赖了并行调度或环境状态——那本身就是 bug。

第 5、6 步是本教程特有的：正文里既引用真实代码，也引用真实输出，
两类断言都不该凭作者记忆，所以全部交给脚本核对。

---

## 官方教程对照

官方 [hello-world](https://docs.sel4.systems/Tutorials/hello-world.html) 一页
（抓取日期 2026-09-25）是整个教程站的第一课：拷一份应用、`printf` 一句话、跑起来。
本章跟它对照三件事——版本号怎么写、那句话从哪儿出去、以及"官方页能跑"依赖了哪些内核配置。

**1. 版本号有两个，别混着引。** `seL4/VERSION` 文件里是 `16.0.0-dev`（一整行，无换行符），
而 `git describe` 给的是 `16.0.0-49-g0f1082911`——差 49 个提交。
本仓库的引用一律以**工作树内容**为准，README 的"真实代码对齐哪一版"那张表里两个都记着。
写文章时如果说"16.0.0 是这样"，得先说清你说的是文件还是提交。

**2. `printf` 在最小系统里走的是内核串口。** 官方页那个 `printf` 最终落到
`seL4_DebugPutChar`（`seL4/libsel4/include/sel4/syscalls.h:44`），
而它的**声明**整个被包在 `CONFIG_PRINTING`（`seL4/libsel4/include/sel4/syscalls.h:32`）里。
同文件第 26--28 行的那段组注释把这层依赖说得很清楚：
这一组调用要 `DEBUG_BUILD`，其中碰串口的还要 `PRINTING`。
也就是说：关掉这两个配置，"hello world" 那行代码**连声明都拿不到**——
它是调试设施，不是 API。

**3. 这些调用不在正常的标签表上。** `seL4/libsel4/include/api/syscall.xml` 里那句
"Syscalls on the unknown syscall path" 的注释之后，紧跟 `debug`
（`seL4/libsel4/include/api/syscall.xml:39`）这一段，
里面才列 `DebugPutChar`（`seL4/libsel4/include/api/syscall.xml:42`）。
内核侧接住它的是 `handleUnknownSyscall`（`seL4/src/api/syscall.c:97`）：
一个 `if` 接一个 `if`，`SysDebugPutChar`（`seL4/src/api/syscall.c:100`）就在最前面。
第 09/10 章那套"标签 → 解码 → 分派"对这条路径**不成立**——
它落在"这个调用号我不认识"的分支上，因此也不在那份被证明的分派覆盖范围内。

**4. 一个字符装在哪个寄存器里？** `kernel_putchar`
（`seL4/src/api/syscall.c:101`）取的是 `capRegister`——能力指针那个寄存器。
第 10 章说"参数在总线上就是字"，这里是极限例：一个字节借用一个指针位。

**5. 同一条路径上还挂着后面几章的东西。** `SysDebugCapIdentify`
（`seL4/src/api/syscall.c:124`）的实现对用户"报出"某个槽里的类型，
靠的是 `lookupCapAndSlot`（`seL4/src/api/syscall.c:126`）——第 04 章的解析函数；
`SysDebugSnapshot`（`seL4/src/api/syscall.c:117`）直接调 `debug_capDL`
（`seL4/src/api/syscall.c:121`）——第 23 章的 capDL 快照在 C 里就住在这条 debug 调用后面。
它们的宏门是 `CONFIG_DEBUG_BUILD`（`seL4/libsel4/include/api/syscall.xml:46`），
**与串口那组不是同一个**。

**6. debug 路径上允许"出事就停"。** `SysDebugNameThread`
（`seL4/src/api/syscall.c:132`）上面的注释写着：这条调用只用于调试，
一旦出错就认为系统"completely misconfigured"并 `halt`。
用户输入能让内核停下来——这件事在正常路径上是不可想象的（第 09/10 章的
"越界一律 fault"），它成立的唯一理由就是那条调用只存在于 debug 构建里。
读 `seL4/CAVEATS.md` 时记住这一类：**未验证的东西很多是通过配置关掉的**。

---

## 本章坑位清单（实测）

1. **字面写 Unicode**：源文件里出现 `‹ › ∀ ∧ →`，报 `Malformed command syntax` 或 `Inner lexical error`。一律写 `\<open>` `\<close>` `\<forall>` `\<and>` `\<longrightarrow>`。
2. **`@{verbatim xxx}` 忘了加引号**：报 `Bad arguments for document antiquotation`。必须写 `@{verbatim "xxx"}`。
3. **常量名不能用 `ALL EX SUM PROD INT UN INF SUP`**：这 8 个全大写词会被整词替换成符号。
4. **build 报 `[SQLITE_ERROR] cannot commit` / `[SQLITE_IOERR_DELETE]`**：构建库是 SQLite，写库时要 `unlink` 掉 `-journal`。macOS 上对 `~/` 下未签名二进制的 `unlink` 返回 EPERM，删不掉就崩；Linux 普通权限没有这个问题。脚本统一把 `USER_HOME` 指到 `/tmp` 下，既绕开 macOS 的坑，也让 heaps 与用户 `~/.isabelle` 隔离、重跑互不污染。
5. **直接改 `ISABELLE_HOME_USER` / `ISABELLE_HEAPS` 无效**：`etc/settings` 里是无条件赋值；唯一能改的是 `USER_HOME`（只在为空时才被赋值）。
6. **`process_theories -l HOL` 会因 import `HOL-Library` 失败**：报 `Bad import … need to include sessions "HOL-Library" in ROOT`，而且 **run.log 是空的、错误只进 stderr**——表现为"每个示例的区间都为空"，很容易误判成示例没输出。基线会话必须写 `-l HOL-Library`。
7. **两遍比对必须关并行**：`parallel_print=false`、`parallel_proofs=0`、`threads=1` 三个 `-o` 缺一个，消息就会在两遍里落到不同位置。
8. **控制字符检查要用 `[[:cntrl:]]`**：写成 `[^[:print:][:space:]]` 时，`LC_ALL=C` 下中文标记的 UTF-8 字节（≥0x80）不在 `[:print:]` 里，24/24 全误报。
9. **溃逃判据裸搜 `Error` 会误报**：seL4 的词汇里 `throwError` / `seL4_Error` 是正常标识符，S08 与 S10 会被恒判为"含溃逃痕迹"。必须锚定横幅形状（`^\*\*\*`、`^Error`、`FAILED`、`Unfinished`、`Uncaught`）。
10. **抽取函数少传一个参数，第 4 关全线"不一致"**：`extract <run目录> <theory> <输出文件>` 三参缺一不可；只给两个时 `set -u` 直接报 `$3: unbound variable`，第二遍产物根本没写出来，24 个 theory 全被判"两遍输出不一致"。这是本仓库真实踩到过的坑（第一版脚本就漏了第三参）。
11. **引用真实代码不能凭记忆**：路径要 `test -e`，行号要"那个名字真的在那一行附近"（第 5 关自动做）。实测一次规范重构就能让十几个 `第 N 行` 集体失效。
12. **正文里的"实测输出"会腐烂**：示例改一行，输出的行号、警告文本、定理名全变。第 6 关把每个 ` ```text ` 块逐行拿去和第 2 步产物比对，改示例忘了改正文会立刻被抓。

---

下一章：[02 · 内核对象与能力](02-kernel-objects.md) ｜ 返回：[README](../README.md)
