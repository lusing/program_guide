# SBCL / Common Lisp 教程示例集

本目录包含 Common Lisp（SBCL 实现）的教程文档与**可运行**示例代码。
每个示例都在 macOS 上实际运行过，并按下面的四条标准判定。

## 目录结构

```text
sbcl/
├── README.md                       本文件
├── common-lisp-guide.md            教程正文（18 章 + 2 附录）
├── verify-guide.py                 核查指南里 `; =>` 断言的脚本
├── build.ps1                       PowerShell 入口（Windows / macOS / Linux）
├── run-all.sh                      shell 入口（macOS / Linux）
├── 01-hello-world.lisp             示例：NN-主题.lisp
├── ...
├── 17-testing-and-deployment.lisp
└── build/                          运行产物（stdout.txt / stderr.txt，不入库）
```

## 工具链

| 平台 | SBCL | 安装方式 |
|---|---|---|
| macOS | `/opt/local/bin/sbcl`（2.6.7） | `sudo port install sbcl` |
| Windows | `sbcl.exe`（scoop 安装） | `scoop install sbcl` |

两个入口都会按「环境变量 `SBCL` → 各平台常见安装位置 → `PATH`」三级回退查找，
也可以直接指定：

```bash
SBCL=/path/to/sbcl ./run-all.sh
```

```powershell
$env:SBCL = '/opt/local/bin/sbcl'; pwsh ./build.ps1 -All
```

## 运行与验证

```bash
./run-all.sh                 # 跑全部 17 个示例
./run-all.sh 09 10           # 只跑编号 09、10
```

```powershell
pwsh ./build.ps1 -All                  # 跑全部
pwsh ./build.ps1 -File 09-file-io.lisp # 跑单个
pwsh ./build.ps1 -Clean                # 清理产物
```

两个入口的输出格式与判定逻辑完全一致，最终给出一句话结论：

```text
通过 17   失败 0   共 17
```

实测（macOS 15 / SBCL 2.6.7）：`./run-all.sh` 与 `pwsh ./build.ps1 -All` 均为 **通过 17   失败 0**。

### 判定标准（四条，缺一不可）

1. **退出码为 0**
2. **stderr 为空**
3. **stdout 里没有多余控制字符**（字节 0..31，TAB/LF/CR 除外）
4. **stdout 里有结束标记** `==== NN 结束 ====`

第 3 条不是摆设。本目录的两个示例**真的**踩过：

- `09-file-io.lisp`：`(file-length in)` 返回**字节数**而 `make-string` 要字符数，
  文件里的中文（UTF-8 三字节）让字符串分配过大，多出的位置被 `#\Nul` 填充 →
  **42 个 NUL 字节漏进 stdout**，而退出码 0、stderr 干净、结束标记也在。
- `10-format.lisp`：`~|` 是 CL 的**换页指令**（输出 `#\Page`），被当成表格竖线用 →
  9 个 `0x0C` 混进 stdout。

**没有第 5 条（stdout 不得含编译器诊断）。** `08-conditions.lisp` 会**故意**发出一个
warning 并把 `WARNING:` 打到 stdout，那是它的演示内容；若照搬 sml/ 的诊断检查会误判。
这条差异是刻意的，两个入口都做了注释说明。

两个入口都做过「故意造坏样例」的反向验证：缺标记 / 写 stderr / 混控制字符 / 非零退出码
四种情况均被正确判失败且脚本返回 1。改动判定函数后**重新跑过一遍**（见下文 D 节）。
另外用同一份输入比较过 `has_marker` 修复前后的行为，确认新版本不再因非法 UTF-8 误报。

### 已知的、不影响判定的现象

- `14-performance.lisp` 的 `sb-profile:report` 会先打印一行
  `measuring PROFILE overhead..done`，这一行**绕过 Lisp 的 stdout/stderr 流直接写控制终端**：
  用 `--load` 运行时两个重定向文件里都没有它（只在终端上看得见，所以判定不受影响）；
  但用 `--script` 运行时它**会落到 stderr**，撞上「stderr 必须为空」这条判定。
  实测把 `*trace-output*` / `*error-output*` 绑成广播流都压不掉，所以本目录统一用 `--load`。
  该示例的文件头也写了这个说明。
- `12-threads.lisp` 涉及线程调度、`14-performance.lisp` 有墙钟计时，输出**不保证每次逐字节相同**，
  因此这里**不做**黄金输出比对，只做上面的四条判定。`12-threads.lisp` 的文件头列出了
  「每次运行都可能不同的行」清单（各线程打印的先后顺序、无锁计数的值、信号量观测到的峰值、
  哪个 worker 抢到哪个任务）；除此之外的内容都是确定的。
- `09-file-io.lisp` 会打印当前目录的绝对路径，天然随机器变化，同样不做输出比对。
- **两个入口不要并行跑**：`run-all.sh` 与 `build.ps1` 都把产物写到同一个 `build/<示例名>/`
  目录（`stdout.txt` / `stderr.txt`）。同时开两份会互相覆盖，表现为**stdout 被写一半、
  结束标记丢失**，于是误报「缺少结束标记」。
  实测：两轮全量并行跑时第二轮失败 3 个（`11-sbcl-extensions` / `12-threads` /
  `14-performance` —— 恰好是输出量较大的那几个），串行跑则稳定 17/17。
  这不是示例的问题，是**共用产物目录**导致的。写自动化脚本时请串行调用。

## 本次 macOS 兼容性核查结论

核查时间：2026-09-16，环境 macOS + SBCL 2.6.7。

初次运行时有 **8/17 个示例在 macOS 上直接崩溃**。逐条实测后，问题分三类：

### A. 只与平台有关（Windows 专有写法，macOS 必挂）

| 示例 | 现象 | 原因 | 修法 |
|---|---|---|---|
| `11-sbcl-extensions.lisp` | `Couldn't execute "cmd"` | 硬编码 `cmd /c`，POSIX 上没有 `cmd` | 用 `#+win32` / `#-win32` 分发到 `/bin/sh -c` |
| `11-sbcl-extensions.lisp` | `USERPROFILE` / `OS` 打印 NIL | 这两个是 Windows 专有环境变量 | 改取 `HOME` / `SHELL`，并把 Windows 专有项标注出来 |
| `13-ffi.lisp` | `The alien function "strupr" is undefined` | `strupr` 是 MSVC 专有函数，libSystem 里没有（也不是标准 C） | 换成两边都有的 `toupper`、`strcasecmp` |
| `01` / `17` | 只是注释与文案里的 `hello.exe` / `myapp.exe` | 产物扩展名的平台习惯 | 改成 `hello-app` / `myapp` 并注明 Windows 才加 `.exe` |

### B. 与 SBCL 版本有关（与操作系统无关，Windows 上一样会挂）

| 示例 | 现象 | 原因 | 修法 |
|---|---|---|---|
| `14-performance.lisp` | `Don't know how to REQUIRE :SB-PROFILE` | `SB-PROFILE` 已在**核心里**（还被 CL-USER 默认 use-package），没有同名 contrib 模块可 require | 删掉 `(require :sb-profile)`；（对比：`SB-SPROF` 确实是 contrib，必须 require） |

### C. 示例本身的 bug（跨平台通病，实测确认）

| 示例 | 现象 | 原因 | 修法 |
|---|---|---|---|
| `06-clos.lisp` | `DESCRIBE already names an ordinary function or a macro.` | 用 `defgeneric` 重定义了 CL 标准函数 `describe` | 改名 `describe-thing` |
| `09-file-io.lisp` | `couldn't rename ... test-dir/test-dir/renamed.txt` | `rename-file` 第二参数是**目标路径的默认值**，带相对目录会被再拼一次 | `(merge-pathnames "renamed.txt" (truename "test-dir/"))` |
| `09-file-io.lisp` | stdout 混进 42 个 NUL | 见上文第 3 条 | 接住 `read-sequence` 返回值再 `subseq` 截断 |
| `10-format.lisp` | `The value of mincol is -10, should be a non-negative integer` | `~-10D` 不是左对齐写法，`mincol` 必须非负 | 用 `~10A`（`~A` 右补空格，`~D` 左补空格，方向相反） |
| `10-format.lisp` | stdout 混进 9 个换页符 | `~|` 是换页指令不是表格竖线 | 改用宽度参数 `~20A` |
| `12-threads.lisp` | `Recursive lock attempt` | `grab-mutex` 不可重入，同线程再锁（哪怕 `:waitp nil`）是**报错**不是返回 NIL | 用 `holding-mutex-p` / `mutex-owner` 判断持有情况 |
| `08-conditions.lisp` | stderr 非空 | `warn` 输出到 `*error-output*`（stderr） | 演示处临时把 `*error-output*` 绑到标准输出 |
| `12-threads.lisp` | stdout 出现**非法 UTF-8**、同一行内容互相穿插 | 一次 `format` 会按指令拆成多次写，别的线程能插在中间；汉字被两个线程各写走一半 | 定义全局打印锁 + `say`，**所有**输出（含主线程）都走它，并 `finish-output` |
| `12-threads.lisp` | 线程池「实际执行」可能少于提交数 | worker 只看 `shutdown` 就 `return`，没先把队列排空；原版靠 `(sleep 1)` 赌它跑完 | 改成「取不到任务才退出」，`shutdown` 里直接 `join`，不再靠 sleep |
| `12-threads.lisp` | 屏障一节主线程 `(sleep 2)` 就往下走 | 那 3 个线程压根没被 `join`，结束时可能仍在打印 | 收集句柄后 `join`，结果由主线程统一打印 |
| `12-threads.lisp` | `The variable ID is defined but never used.`（STYLE-WARNING） | 改成确定性输出时删掉了打印，参数就没人用了 | 把完成的编号收集起来排序后打印 |

### D. 判定脚本自己的 bug（会**误报**，最难查）

`has_marker()` 里用 `tr -d '\000'` 剔除 NUL 再匹配结束标记。这里**漏了 `LC_ALL=C`**：

在 UTF-8 locale 下，toybox（macOS 上 bash 里的 `tr`/`grep` 都是 toybox）的 `tr`
会做多字节校验，碰到非法 UTF-8 就报

```text
tr: Illegal byte sequence
```

并且**在那里截断输入**。`12-threads.lisp` 并发打印产生的非法 UTF-8 正好落在这条路径上，
于是结束标记被截在输出之外 → 判定为「缺少结束标记」、`run-all.sh` 返回 1。
而 `build.ps1` 用 `UTF8.GetString` 解码后 `.Contains()`，非法字节只变成替换字符、
不影响标记本身，所以**同一个示例它判通过** —— 两个入口给出相反结论。

这就是最初「`run-all.sh` 偶发失败、`build.ps1` 通过」的真凶：它不是线程竞态，
而是**判定函数在特定输入下的脆弱性**。修了两处：

1. `run-all.sh` 的 `has_marker`／`has_ctrl` 一律加 `LC_ALL=C`，让 `tr` 退化成按字节处理；
2. 在**根上**修示例（打印锁），让 stdout 不再出现非法 UTF-8。

只做第 1 条也能过判定，但那样等于把「stdout 里有非法 UTF-8」这种真缺陷放行，所以两条都做了。

**同类隐患已一并加固**：`fortran/`、`sml/`、`freepascal/` 三个入口的 `marker_present`
（以及诊断输出处的 `tr -d '\000'`）此前也没带 `LC_ALL=C`，一并补上了。
`fortran/` 尤其值得补 —— 触发格式重现时落盘的就是原始整数字节，正是非法 UTF-8 的典型来源。

反向验证（同一份输入，取自 `run-all.sh` 里**真实**的 `has_marker` 定义）：

| 版本 | 输入：标记之前含被截断的 `E7 BB` | 结果 |
|---|---|---|
| 旧（无 `LC_ALL=C`） | 36 字节，非法序列在偏移 13 | **找不到标记 → 误报** |
| 新（有 `LC_ALL=C`） | 同上 | 找到标记 → 判定正确 |

### 关于「原来声称验证过」

原 `build.ps1` 只做 `compile-file`，**从不运行**。实测：那 8 个一跑就崩的示例，
`compile-file` 全部返回成功（因为崩溃都发生在**运行期**，如 `format` 指令、
`rename-file`、`run-program` 都要真正执行才暴露）。
也就是说旧的「已验证」结论是空验证——**编译通过 ≠ 能跑**。
现在的两个入口都真跑，并用结束标记兜住「中途崩溃但退出码仍是 0」的情况。

## 教程正文与各章索引

教程正文是 [common-lisp-guide.md](./common-lisp-guide.md)：**18 章 + 2 个附录**，
面向「能看懂 S 表达式，但没写过 Lisp」的读者。每章都讲清「为什么」而不只是罗列 API，
并给出可复现的命令与真实输出。

| 章 | 主题 | 配套示例 |
|---|---|---|
| 0 | 环境、两种运行方式与四个判定标准 | — |
| 1 | 求值模型：Lisp 怎么读你的代码 | `01-hello-world.lisp` |
| 2 | 数字：整数不溢出、有理数精确、浮点**默认单精度** | `02-data-types.lisp` |
| 3 | 字符、字符串、符号 | `02-data-types.lisp` |
| 4 | 列表与 cons 结构、五种相等 | `02-data-types.lisp` |
| 5 | 变量与作用域（词法 vs 动态） | `04-functions.lisp` |
| 6 | 函数、参数模型、多值、尾调用实测 | `04-functions.lisp` |
| 7 | 控制流与迭代（含 `loop` 全姿势） | `03-control-structures.lisp` |
| 8 | 序列与高阶函数 | `16-sequences-hash-tables.lisp` |
| 9 | 哈希表与结构体 | `16-sequences-hash-tables.lisp` |
| 10 | 条件系统与重启（CL 最独特的部分） | `08-conditions.lisp` |
| 11 | CLOS：类、方法、多分派、方法组合 | `06-clos.lisp` |
| 12 | 包与命名隔离 | `07-packages.lisp` |
| 13 | 宏与元编程（含变量捕获与 `gensym`） | `05-macros.lisp` |
| 14 | `format` 格式化输出 | `10-format.lisp` |
| 15 | 文件与流 I/O | `09-file-io.lisp` |
| 16 | SBCL 专用：线程、FFI、优化、部署 | `11` / `12` / `13` / `14` / `17` |
| 17 | 工程化：ASDF、测试与工具链 | `15-asdf-quicklisp.lisp` |
| 附录 A | 常见坑速查（症状 → 原因 → 解法，8 张表） | — |
| 附录 B | 报错信息对照表（20 条 SBCL 报错原文） | — |

## 指南断言核查脚本（`verify-guide.py`）

指南开头声明「每一段带 `; =>` 的结果都是在 SBCL 上实际跑出来的」。这句话是**可核查**的：

```bash
python3 verify-guide.py                  # 默认核查 ./common-lisp-guide.md
SBCL=/path/to/sbcl python3 verify-guide.py
```

它把指南里每个 ` ```lisp ` 块还原成 `.lisp` 文件、把断言行改写成检查，
再按顺序 `--load`（所以前面块里的 `defvar` / `defun` / `defpackage` 对后面可见），
最后逐条比对打印结果。

实测（macOS + SBCL 2.6.7）：

```text
blocks : 共 271 个 lisp 代码块，其中 269 个有可执行内容；断言行 522 条
==== blocks 269, claims 521, mismatch 0, broken 18 ====
```

- **`mismatch 0`** 是所有**数值类**断言逐条对上了；对象地址、`gensym` 编号、
  哈希表遍历顺序、线程调度顺序这几类必然随运行而变，脚本里做了归一化
  （`#<TRACED {1202A6C183}>` → `#<TRACED {…}>`、`#:G264` → `#:G`），指南里也都显式标注了。
- **`broken 18`** 不是错误：那 18 个块是**故意演示报错**的（`ecase` 没匹配上、
  包锁冲突、`format` 参数不够……）、或者是从完整项目里摘出来的**片段**
  （`.asd` 文件内容、`my-function` 之类的占位符），本来就不该独立跑通。

顺带记一条踩到的坑：**`*print-pretty*` 关掉会让 `'x` 变成 `(QUOTE X)`**
（SBCL 只在 pretty 打开时才用引号缩写）。核查脚本因此保持 pretty 默认 `T`、
只放宽 `*print-right-margin*` —— 否则一个值会因为打印设置不同而前后不一致，
把「打印设置差异」误判成「指南写错了」。这一条也写进了指南 14.6 节。

## 各示例主题

| 示例 | 主题 |
|---|---|
| `01-hello-world.lisp` | 基础输出、命令行参数、脚本入口、save-lisp-and-die |
| `02-data-types.lisp` | 数字、字符与字符串、符号、cons、数组、哈希表、结构体 |
| `03-control-structures.lisp` | 分支、循环、多值、块与跳转、catch/throw |
| `04-functions.lisp` | 参数模型、闭包、高阶函数、递归、flet/labels |
| `05-macros.lisp` | defmacro、反引号、macroexpand、gensym、符号宏 |
| `06-clos.lisp` | 类、泛型函数与方法、继承、方法组合 |
| `07-packages.lisp` | defpackage、导出与导入、符号可见性、包锁 |
| `08-conditions.lisp` | handler-case、handler-bind、自定义条件、重启 |
| `09-file-io.lisp` | 文本/二进制读写、字符串流、路径名、目录操作 |
| `10-format.lisp` | format 指令详解、对齐与填充、自定义指令 |
| `11-sbcl-extensions.lisp` | run-program、环境变量、GC、编译器控制 |
| `12-threads.lisp` | 线程、互斥锁、条件变量、信号量、原子操作 |
| `13-ffi.lisp` | sb-alien：加载共享库、调用 C 函数、类型映射 |
| `14-performance.lisp` | 类型声明、优化级别、内联、sb-profile 与 sb-sprof |
| `15-asdf-quicklisp.lisp` | ASDF 系统定义、Quicklisp、项目结构 |
| `16-sequences-hash-tables.lisp` | 序列筛选与映射、哈希表、词频统计 |
| `17-testing-and-deployment.lisp` | assert 测试、错误捕获、发布入口模式 |

## 平台注意（写示例前先看）

- **单实现通道。** 本目录的示例大量使用 `sb-ext` / `sb-alien` / `sb-thread`，
  是**有意**绑定 SBCL 的，不要期待在 CCL/ECL/CLISP 上跑通。
- **`--script` 与 `--non-interactive` 不能连用。** `sbcl --non-interactive --script x.lisp`
  会把 `x.lisp` 当成运行时参数，示例根本不执行（只打一行 banner、退出码 0）。
  两个入口统一用 `--noinform --non-interactive --no-userinit --load <file>`。
- **`sbcl` 不会把编译器回显写到 stderr**，所以「stderr 为空」这条对 SBCL 天然容易满足，
  真正把关的是结束标记与 stdout 内容。
- **`CL-USER` 默认 `use-package` 了 `SB-EXT` / `SB-ALIEN` / `SB-DEBUG` / `SB-GRAY` / `SB-PROFILE`**，
  所以 `report`、`reset`、`profile` 这些名字**不能**拿来当自己的函数名或局部函数名，
  否则报包锁冲突（`Lock on package SB-PROFILE violated`）。
- **`sb-posix` / `sb-bsd-sockets` / `sb-sprof` / `sb-cover` 是 contrib 模块**，用之前必须
  `(require :sb-posix)` 之类的加载；而 `sb-ext` / `sb-alien` / `sb-thread` / `sb-profile` 在核心里。
- **`run-program` 给裸程序名要加 `:search t`**，否则报 `Couldn't execute "echo"`；
  `:output` 不接受 `:string`（想要字符串结果请用 `:stream` 自己读，或改用 UIOP）。
- **多线程打印必须自己加锁。** 多个线程直接 `(format t ...)` 会互相穿插 —— 一次 `format`
  拆成多次写，而且多字节汉字可能被两个线程各写走一半，产出**非法 UTF-8**。
  写示例时定义一个 `say`（全局互斥锁 + `finish-output`），所有输出包括主线程都走它。
  参见 `12-threads.lisp` 开头的说明。
- **线程一定要 `join`。** 主线程跑完就退出，没 join 的线程可能还在打印，
  输出会缺内容甚至缺结束标记。别用 `(sleep N)` 代替 `join`。
- **括号总数平衡 ≠ 嵌套正确。** 少一个 `)` 又多个 `)` 会互相抵消，肉眼和「数括号」都看不出来，
  表现为 `PUSH` 只收到 1 个实参之类的怪错。改完示例跑一次
  `sbcl --noinform --non-interactive --no-userinit --eval '(compile-file "NN-x.lisp" :output-file "/tmp/c.fasl" :print nil :verbose nil)'`
  做静态兜底：它做宏展开，这类结构错位当场就能报出来（真跑时也报，只是信息量不如它集中）。
  **这条是静态检查，不能替代真跑** —— 本目录有 8 个示例编译全过、一跑就崩。

## 当前状态

- 17 个示例在 macOS + SBCL 2.6.7 上全部运行通过（`通过 17   失败 0`）
- 两个入口 `run-all.sh` / `build.ps1` 判定逻辑一致，均做过反向验证
- 稳定性：`run-all.sh` 全量连跑 5 轮 + `build.ps1 -All` 1 轮，均为 17/17；
  并发示例 `12-threads.lisp` 单独再压 25 轮，全部通过（此前它偶发失败的原因见 D 节，
  已定位并修掉，不是线程竞态）
- 教程正文已重写为 18 章 + 2 附录（此前是 2335 行的 API 罗列版，含**编造的 API**
  `make-sequence-indicator`、未加载就使用的 `alexandria:iota`、非法的 `~-10D`、
  把换页指令 `~|` 当表格竖线等一批跑不通的片段 —— 全部已删改）。
  现在文中 521 条 `; =>` 断言由 `verify-guide.py` 逐条回跑，mismatch 0
- Windows 侧：`build.ps1` 已去掉硬编码的 `G:\` 路径并改为跨平台查找 SBCL，
  但**本机没有 Windows 环境，未实测**；`#+win32` 分支的代码路径同样未实测

## 已知的目录结构偏差（待处理）

本仓库其他教程目录都把可运行示例放在 `<topic>/examples/`（见根 `README.md` 的统一约定），
**`sbcl/` 是唯一例外** —— 17 个示例直接放在 `sbcl/` 根下。教程正文按实际布局写
（「本目录的 17 个 `.lisp` 文件」），若要统一，需同时改 `run-all.sh`、`build.ps1`、
本 README 的结构图和指南里的路径引用。
