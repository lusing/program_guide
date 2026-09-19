# 01 · 全景与工具链

> 面向**会编程（任意语言背景）、初学 COBOL** 的读者。本章不带示例，先把"COBOL 是什么、
> GnuCOBOL 怎么编译、本教程怎么验证"讲透——后面每章都建立在這裡的约定上。

## 1. COBOL 家族简史（五分钟版）

| 年代 | 事件 | 意义 |
|---|---|---|
| 1959 | 美国国防部牵头设计 COBOL | "Common Business-Oriented Language"：为商业数据处理而生，目标之一是让程序能跨机型移植 |
| 1968/1974/1985 | ANSI/ISO 标准 COBOL-68/74/85 | 语言标准化；1985 版引入结构化、内嵌 SQL 约定，影响最深远 |
| 2002 | COBOL 2002 | 面向对象（类/方法/继承）、布尔类型等现代化尝试 |
| 2014 | COBOL 2014 | 内嵌/接口标准化，多数厂商支持有限 |
| 2023 | COBOL 2023 | 最新 ISO 标准；GnuCOBOL 3.x 覆盖到 2014 的大部分特性 |
| 今天 | **GnuCOBOL 3.2** | 开源实现：把 COBOL 翻译成 C，再交给系统 C 编译器链接成原生程序 |

**为什么 2026 年还该碰它**：全球银行、保险、社保、税务、航空订座的核心批处理系统里，
COBOL 存量代码以**亿行**计，每天处理着世界上绝大多数金融交易。维护、迁移、读懂这些系统，
是 COBOL 今天最现实的价值。它不是新潮语言，但它"还在干活"，而且干的是最不能出错的活。

**它的脾气**：面向记录与文件的批处理思维、英语化的冗长语法（`ADD A TO B GIVING C`）、
强约定（列位、PIC 子句）、几乎没有现代生态（无包管理器、无异步、无丰富标准库）。
学它的目的是**读懂和维护存量、理解商业数据处理的范式**，不是用它写新项目。

## 2. GnuCOBOL：把 COBOL 翻译成 C

GnuCOBOL（旧名 OpenCOBOL）是本教程使用的开源实现，特点：

- **翻译式编译**：`cobc` 先把 `.cob` 翻译成等价的 C 代码，再调用系统 C 编译器
  （本机是 `clang`）编译链接成原生可执行文件。**没有解释器、没有虚拟机**，跑起来就是机器码。
- **运行时库 libcob**：所有 COBOL 动词（MOVE/DISPLAY/文件 I/O…）由 `libcob` 提供，
  链接进可执行文件。
- **标准覆盖**：默认贴近 COBOL 85 + 部分 2002/2014；通过 `-std=` 切换方言。
- **跨平台**：Linux / macOS / Windows 都能装。本机实测 **GnuCOBOL 3.2.0**（macOS，
  MacPorts 安装，clang 15 后端）。

```text
.cob 源码 ──cobc──▶ 临时 .c ──clang──▶ 可执行文件 / 共享模块
                       │
                       └─ 链接 libcob（提供 COBOL 运行时）
```

## 3. 方言：一份编译器，十几种脾气（`-std=`）

GnuCOBOL 用 `-std=<dialect>` 决定"按哪家厂商/哪个标准"来解释语法与告警。本机
`cobc --info` 列出的配置（`/opt/local/share/gnucobol/config/*.conf`）：

| 方言 | 含义 | 何时用 |
|---|---|---|
| `default`（本教程） | GnuCOBOL 默认，宽松、贴近 COBOL 85 + 常用扩展 | 学习与新写 |
| `cobol85` / `cobol2002` / `cobol2014` | 对应 ISO 标准版本 | 想严格贴合某版标准 |
| `xopen` | X/Open 最小公共子集 | 最大可移植性 |
| `ibm` | IBM 企业 COBOL（z/OS、大机） | 维护大机代码 |
| `mf` | Micro Focus COBOL | 维护 MF 存量 |
| `acu` | Acucobol-GT | — |
| `bs2000` / `mvs` / `realia` / `rm` / `gcos` | 各家历史厂商方言 | 特定存量系统 |

> 选对方言能少踩坑：不同方言对"保留字、是否允许某些扩展、默认 USAGE"的处理不一样。
> 维护存量代码时，**第一件事就是搞清它原本是哪家方言**，再用对应 `-std=` 编译。
> 本教程统一 `default`，遇到方言差异会在"坑位清单"里点名。

## 4. 编译模型：一条命令到底

```bash
cobc -x hello.cob        # -x：编译+链接成【独立可执行文件】（最常用）
cobc -m hello.cob        # -m：编译成【共享模块】(.so/.dylib/.dll)，供 cobcrun 或其他程序 CALL
cobc -c hello.cob        # -c：只编译成目标文件 .o，不链接（多文件工程分步用）
cobc -C hello.cob        # -C：只生成中间 C 代码，不编译（想看翻译结果/调试用）
```

运行：

```bash
./hello                  # -x 产出的可执行文件直接跑
cobcrun hello            # 运行 -m 产出的模块（模块名 = PROGRAM-ID）
```

**几个关键点**：

- **PROGRAM-ID 决定模块名**，与文件名无关。`cobcrun` 按 PROGRAM-ID 找模块。
- **多程序静态链接**：一个可执行文件可由多个 `.cob`（多个 PROGRAM-ID）链接而成，
  彼此用 `CALL "程序名"` 调用，cobc 会把它们编进同一个 exe（第 09 章详解）。
- **无需链接仪式**：`cobc -x` 一条命令完成"翻译→编译→链接"，对标 `gcc a.c -o a`。

## 5. 源码格式：固定格式 vs 自由格式

COBOL 最"考古"的特征是**固定格式（fixed format）**的列位约定——它直接源于 1959 年的
80 列打孔卡片：

```text
列号:  1         2         3         4         5         6         7
       1234567890123456789012345678901234567890123456789012345678901234567890
       ┌──────┬─┬────┬────────────────────────────────────────────────────┬───┐
       │ 1-6  │7│8-11│                    12-72                           │73+│
       │序号区│指│A区 │                    B 区                            │忽略│
       │(可空)│示│    │                                                    │   │
       └──────┴─┴────┴────────────────────────────────────────────────────┴───┘
              │  └── 部/节/段名、01 与 77 层数据描述 写在 A 区
              │      （A 区从第 8 列开始）
              │      过程语句、从属层数据描述 写在 B 区（第 12 列起）
              └──── 第 7 列是"指示符"：
                    空格=普通行  *或/=整行注释  - =续行  D=调试行
```

- **A 区（第 8 列起）**：DIVISION/SECTION 头、段名（paragraph）、`01`/`77` 层数据项。
- **B 区（第 12 列起）**：所有过程语句、`02`–`49` 等从属层数据项。
- **第 7 列指示符**：`*` 或 `/` 开头 = 整行注释；`-` = 上一行的续行；空格 = 正常代码。
- **第 1–6 列**：序号区，今天基本留空（早期用于卡片排序）。
- **第 73 列及以后**：被忽略（卡片时代放账号/备注）。

**自由格式（free format）** 用 `cobc -ffree` 开启（或文件扩展名约定），没有列位限制，
像普通语言一样缩进即可。**本教程统一用固定格式**——因为：

1. 存量 COBOL 代码绝大多数是固定格式，你必须看得懂列位；
2. 它逼你养成"区"的概念，这是理解 COBOL 数据部层级的前提。

> **实测坑（本教程踩过，第 02 章详述）**：固定格式按 **字节** 数列，不是按字符！
> 一行中文（UTF-8 每字 3 字节）很容易在第 72 列前就"超字节"，编译器报
> `continuation character expected`。所以**含中文的行要短**，或用第 7 列 `-` 续行。

## 6. 工具链安装（本机布局）

本教程实测机器（macOS，MacPorts）：

| 组件 | 路径 | 说明 |
|---|---|---|
| cobc 3.2.0 | `/opt/local/bin/cobc` | GnuCOBOL 编译器驱动 |
| libcob | `/opt/local/lib/libcob.dylib` | 运行时库 |
| 方言配置 | `/opt/local/share/gnucobol/config/*.conf` | `-std=` 用 |
| COPY 库 | `/opt/local/share/gnucobol/copy/*.cpy` | 含 `screenio.cpy`（屏幕 I/O） |
| C 后端 | `/usr/bin/clang`（Apple LLVM 15） | 翻译出的 C 由它编译 |

新机器安装：

- **macOS**：`sudo port install gnucobol`（MacPorts）或 `brew install gnucobol`（Homebrew）。
- **Linux**：`sudo apt install gnucobol4`（Debian/Ubuntu）/ `sudo dnf install gnucobol`。
- **Windows**：从 GnuCOBOL 官网下压缩包解压，把 `bin` 加进 PATH（自带 MinGW，无需另装 C 编译器）。

验证安装：

```bash
cobc --version       # 应显示 cobc (GnuCOBOL) 3.2.0
cobc --info          # 查看后端 C 编译器、配置目录、COPY 目录等
```

## 7. cobc 常用开关总览

```text
产物形态
  -x            编译成独立可执行文件
  -m            编译成共享模块（cobcrun 运行）
  -c            只编译成 .o（不链接）
  -C            只翻译成中间 C 代码（不编译）
  -o <file>     指定输出文件名
方言与标准
  -std=<dialect>   方言（default/cobol2014/ibm/mf/...，本教程 default）
  -ffixed / -ffree 固定格式 / 自由格式（默认按扩展名，.cob=固定）
  -frelax-syntax    放宽语法（容忍一些非标准写法）
告警（本教程 check 通道全开）
  -Wall         打开全部 COBOL 层告警（不是 C 层的 -Wall）
  -Wno-<name>   关闭某条具体告警
优化
  -O2 / -O3     优化（本教程 release 通道）
  -g            调试信息
路径与库
  -I <dir>      COPY 语句的搜索路径
  -L <dir>      链接库路径
  -l<name>      链接库（如 -lc 调 C 函数）
环境变量（不是开关，但很重要）
  COB_CFLAGS    追加/覆盖给 C 后端的编译标志（见下方 macOS 坑）
  COB_LIBRARY_PATH  cobcrun 找模块的目录
```

本教程的两个验证通道：

```text
check 通道：  cobc -x -Wall -std=default     （全部 COBOL 告警，零告警是纪律）
release 通道：cobc -x -O2                    （真实出货形态）
两通道输出必须逐字节一致——任何差异都是"优化改变了语义"的味道，要查
```

## 8. 本教程的验证方法论（贯穿全部示例）

| 层 | 手段 | 覆盖 |
|---|---|---|
| 编译 | cobc 双通道（`-Wall` / `-O2`） | 语法正确 + 告警零容忍 |
| 运行 | exit 0 + stderr 空 + stdout 无控制字符 + 含结束标记 | 程序真跑通了 |
| 断言 | `STOP RUN RETURNING WS-FAILS`：失败计数当退出码 | 关键数值/行为正确 |
| 一致性 | check 与 release 两通道 stdout 逐字节 `cmp` | 优化开关不影响语义 |

**断言习惯（全书一致）**：COBOL 没有 `assert`，本教程统一用——

```cobol
       01 WS-FAILS  PIC 9(2) VALUE 0.        *> 失败计数
           ...
           IF <某性质不成立>
               DISPLAY "FAIL: <说明>"
               ADD 1 TO WS-FAILS
           END-IF.
           ...
           DISPLAY "==== NN 结束 ====".       *> 结束标记，供脚本 grep
           STOP RUN RETURNING WS-FAILS.       *> 计数当退出码：0=全过
```

`STOP RUN RETURNING <整数>` 把整数作为进程退出码——`WS-FAILS` 非 0 时进程非 0 退出，
验证脚本据此判 FAIL。每条示例都打印 `==== NN 结束 ====` 作为"真的跑到最后一行"的证据。

## 9. macOS 专属坑：中文字面量与 clang 告警

本机（macOS + clang）实测：只要源码里有 **UTF-8 中文字面量**，cobc 翻译出的 C 代码里
就含原始 UTF-8 字节，clang 在 **`C`（ASCII）locale** 下会喷 `-Winvalid-source-encoding`
告警。告警走 **stderr**，而程序其实**运行完全正确**（输出是合法 UTF-8）——但它会破坏
"stderr 必须为空"的判定。

对策（本教程 `run-all.sh` / `build.ps1` 已内置）：

```bash
# 保留 cobc 默认头文件搜索路径（gmp.h 等），再追加抑制开关
export COB_CFLAGS="-pipe -I/opt/local/include -Wno-invalid-source-encoding"
```

> 坑中坑：直接 `COB_CFLAGS="-Wno-invalid-source-encoding"`（不带 `-I`）会**覆盖**默认
> 的 include 路径，导致 `gmp.h: file not found` 编译失败——必须把 `cobc --info` 里
> `CPPFLAGS` 的 `-I…` 一起带上。`-I/opt/local/include` 这个路径是 MacPorts 的，
> 别的机器要从 `cobc --info` 现取。Linux + gcc 后端没有这个告警，分支不触发。

另外，`run-all.sh` 开头会把 locale 切到某个 UTF-8（`C.UTF-8`/`en_US.UTF-8`）：在 `C`
locale 下，bash 会把紧邻全角标点的 `$变量`（如 `"$why；"`）误分词，触发 `set -u` 报
"未绑定变量"——这是写验证脚本时踩到的真实坑。

## 10. 学习路线

- **语言篇（02–14）**：顺序读，每章"读讲解 → 跑示例 → 改代码再跑"。
  03（PICTURE）、05（字符串）、08（表）、12（索引文件）是 COBOL 特有深水区，值得两遍。
- **应用篇（15–19）**：屏幕 I/O、C 互操作、报表批处理、测试、综合实战。
- **速查**：`CHEATSheet.md`——语法速查 + 全部实测坑位索引（每章"坑位清单"的汇总）。

把 `run-all.sh`（一条命令回归全部示例）搬走，你的下一个 COBOL 项目就有 CI 了。

## 11. 坑位清单（工具链实测）

1. **固定格式按字节数列**：含中文的行极易超第 72 列 → `continuation character expected`。
2. **`DISPLAY` 不求值算术**：`DISPLAY 1 + 2` 是语法错误；算术要先 `COMPUTE` 进数据项。
3. **macOS + clang + 中文字面量** → `-Winvalid-source-encoding` 告警污染 stderr；
   用 `COB_CFLAGS` 追加 `-Wno-invalid-source-encoding`（并保留 `-I` 头文件路径）。
4. **`COB_CFLAGS` 是覆盖不是追加**：只写 `-Wno-…` 会丢默认 include，编译报 `gmp.h not found`。
5. **`C` locale 下的 bash**：紧邻全角标点的 `$var` 会被误分词；脚本开头切 UTF-8 locale。
6. **`-Wall` 是 COBOL 层告警**，与 C 编译器的 `-Wall` 不是一回事；`FUNCTION LENGTH(定长项)`
   等编译期常量直接跟字面量比会触发 `-Wconstant-numlit-expression`——先 `COMPUTE` 进数据项再比。
7. **方言差异**：维护存量代码先用对 `-std=`，否则保留字/扩展/默认 USAGE 的处理可能对不上。

---
下一章：[02 第一个程序与四大部](02-hello.md) ｜ 返回：[README](../README.md)
