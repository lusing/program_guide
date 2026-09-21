# GNU COBOL 开发指南（GnuCOBOL 3.2.0 / cobc 实测）

面向**会编程（C/C++/任意现代语言背景皆可）、初学 COBOL** 的读者：从零教到能写出结构化的
文件处理与批处理程序。20 章打透 GnuCOBOL——从固定格式列位、PIC 数据模型、`PERFORM` 循环、
表与 `SEARCH`、子程序与 C 互操作，到顺序/索引/相对三类文件、状态码与异常、`SCREEN SECTION`
终端界面、控制break 报表、测试方法论，第 19 章实战**库存管理系统**（索引文件建档 → 过账 →
按类别控制break 估值报表 → 低库存预警 → 全程断言）。每章"读讲解 → 跑示例 → 改代码再跑"，
全部 18 个示例在本机**双通道验证**通过（macOS 与 Windows 双平台）。

> ⚠️ COBOL 是"看起来像英语、实则处处反直觉"的语言：`DIVIDE A INTO B` 是 `B / A`、下标从
> 1 开始、无符号字段悄悄吞掉负号、溢出默认静默截断、`SEARCH ALL` 对乱序表给错结果还不吭声。
> 网上教程多停留在 IBM 大型机方言或几十年前的标准。本教程所有代码在 **GnuCOBOL 3.2.0**
> 双平台实测——**macOS（MacPorts + clang 后端）** 与 **Windows（MSYS2 UCRT64 + gcc 后端）**，
> 每章末"坑位清单"收录版本差异与实测陷阱——
> [CHEATSheet.md](CHEATSheet.md) 汇总 **110 条实测坑位**，[docs/20-pitfalls.md](docs/20-pitfalls.md)
> 是完整分类索引。

## 目录结构

```text
cobol/
├── README.md       本文件
├── docs/           20 章教程（01 → 20 顺序阅读；⭐ 为特色重点章）
├── examples/       18 个示例目录（章号 = 目录号，02–19；01 为全景无示例，20 为坑位索引无示例）
├── build.ps1       统一验证脚本（pwsh 7 运行，Windows 入口）
├── run-all.sh      等价的 bash 验证入口（macOS / Linux / Git Bash）
├── CHEATSheet.md   语法速查 + 110 条实测坑位索引
└── build/          编译产物（check/ 与 release/ 两通道，gitignore）
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景与工具链](docs/01-overview.md) | COBOL 家族史、GnuCOBOL 定位、固定格式列位、编译模型、验证方法论 | — |
| [02 第一个程序与四大部](docs/02-hello.md) | 四大部结构、句点纪律、区（Area A/B）、DISPLAY、结束标记 + 退出码 | `02_hello` |
| [03 数据部与 PICTURE 子句](docs/03-data-pic.md) ⭐ | PIC 全按字节、隐含小数点 V、USAGE 决定字节数、带符号 S、编辑项 | `03_data` |
| [04 数值与运算](docs/04-numeric.md) | ADD/SUBTRACT/MULTIPLY/DIVIDE 语序陷阱、GIVING、ROUNDED、ON SIZE ERROR | `04_numeric` |
| [05 字符串处理](docs/05-strings.md) ⭐ | 定长字节数组、STRING/UNSTRING/INSPECT、引用修改、FUNCTION TRIM | `05_strings` |
| [06 条件与控制流](docs/06-control.md) | IF/ELSE 悬挂、EVALUATE 不贯穿、关系运算符、AND/OR 优先级 | `06_control` |
| [07 循环：PERFORM 全形态](docs/07-perform.md) | TIMES/UNTIL/VARYING/TEST AFTER、内联 vs 段调用、EXIT PERFORM | `07_perform` |
| [08 表（OCCURS）与 SEARCH](docs/08-tables.md) ⭐ | 下标 vs 索引、SEARCH/SEARCH ALL、OCCURS DEPENDING ON、多维表 | `08_tables` |
| [09 子程序与 CALL](docs/09-subprograms.md) | LINKAGE SECTION、BY REFERENCE/CONTENT/VALUE、GOBACK、LOCAL-STORAGE 递归 | `09_subprograms` |
| [10 内部函数（FUNCTION）](docs/10-functions.md) | 数值/字符/日期各类、ORD/CHAR 1 基、REM vs MOD、CURRENT-DATE 纪律 | `10_functions` |
| [11 文件 I：顺序文件](docs/11-files-seq.md) | LINE SEQUENTIAL、OPEN/READ/WRITE/CLOSE、AT END、status 71 陷阱 | `11_sequential` |
| [12 文件 II：相对与索引文件](docs/12-files-isam.md) | RELATIVE/INDEXED、先建后改、随机读、START+READ NEXT、REWRITE/DELETE | `12_isam` |
| [13 状态码、异常与调试](docs/13-status-debug.md) | FILE STATUS 解码、DECLARATIVES、ON SIZE ERROR、D 调试行 | `13_status` |
| [14 结构化编程与文本复用](docs/14-structured.md) | SECTION 分层、COPY copybook、REPLACE、预处理器 >>DEFINE/>>IF | `14_structured` |
| [15 终端界面：SCREEN SECTION](docs/15-screen.md) ⭐ | LINE/COLUMN、FROM/TO 绑定、属性、curses 后端、环境变量自测路径 | `15_screen` |
| [16 与 C 互操作](docs/16-c-interop.md) ⭐ | CALL "c_func"、COMP-5 数值桥、PIC X 无 NUL、混编 .cob + .c | `16_c_interop` |
| [17 报表与批处理：控制break](docs/17-report.md) | 排序前提、break 检测、组小计、尾break、分页 | `17_report` |
| [18 测试方法论](docs/18-testing.md) | 断言 + 退出码纪律、表驱动迷你框架、双通道验证、六条判定 | `18_testing` |
| [19 综合实战：库存管理](docs/19-capstone.md) ⭐ | 索引文件 + 过账 + 控制break 报表 + 低库存预警；无符号吞负号坑 | `19_capstone` |
| [20 坑位总清单](docs/20-pitfalls.md) | 全书 110 条实测坑的分类索引 + 三个"静默算错"警示 + 防御清单 | — |

## 构建工具链

- **GnuCOBOL 3.2.0**（`cobc`）：macOS 走 MacPorts `/opt/local/bin/cobc`，clang 后端
  （COBOL → C → 原生可执行）；Windows 实测走 **MSYS2 UCRT64**
  （`pacman -S mingw-w64-ucrt-x86_64-gnucobol`，gcc 后端，同 3.2.0）；Linux 用发行版包。
- 源码一律 **UTF-8、固定格式**（列位见 [docs/01](docs/01-overview.md)）；含中文的行须 ≤ 72 **字节**。
- 脚本按 **环境变量 `COBC` → 固定路径 → PATH** 顺序探测编译器，不硬编码。
- macOS/clang 专属：中文字面量会触发 `-Winvalid-source-encoding` 告警污染 stderr，脚本自动导出
  `COB_CFLAGS="-pipe ${默认CPPFLAGS} -Wno-invalid-source-encoding"`——**`COB_CFLAGS` 是覆盖不是
  追加**，必须带上 `cobc --info` 里的默认 include 路径，否则 `gmp.h not found`（实测坑）。
- Windows/MSYS2 专属：该包的 `cobc.exe` 编译期写死 MSYS 风格前缀 `/ucrt64/...`，原生进程解析
  不了 → **必须导出 Windows 形式的 `COB_CONFIG_DIR`**，且 PATH 要含 `ucrt64\bin`（编译找 gcc、
  运行找 `libcob-4.dll`）。两个脚本按 `cobc` 所在目录**自动探测配置**，无需手工设（实测坑，
  详见 [CHEATSheet §19](CHEATSheet.md)）。

## 验证命令

```bash
cd /Volumes/mac004/code/programming/cobol
./run-all.sh                 # 全部 18 示例：check + release 双通道
./run-all.sh 19              # 单个示例（编号或目录名）
./run-all.sh 02 08 19        # 多个
./run-all.sh -v              # 附带每个示例的完整输出
./run-all.sh --clean         # 清理 build/ 产物
```

```powershell
pwsh -File build.ps1                 # Windows 等价入口（与 run-all.sh 同判定）
pwsh -File build.ps1 -Example 19_capstone
pwsh -File build.ps1 -Clean
```

Windows 上脚本自动探测官方 GnuCOBOL 与 MSYS2 UCRT64 两种安装（含 scoop 布局），
MSYS2 构建自动配置 `COB_CONFIG_DIR` 与 PATH；装在别处时设 `COBC=C:\path\to\cobc.exe`
指向即可。

**判定标准**：每个示例编两遍、跑两遍——

```text
检查通道：cobc -x -Wall -std=default   全告警 + 默认方言
发布通道：cobc -x -O2                   优化，真实出货形态
```

每通道六条判定：① 编译退出码 0 ② 编译 stderr 空（`-Wall` 零告警）③ 运行退出码 0
（= `WS-FAILS` 断言失败数）④ 运行 stderr 空 ⑤ stdout 无控制字符（TAB/LF/CR 除外，挡 curses
转义/乱码）⑥ 含结束标记 `==== NN 结束 ====`（证明跑到了尾而非中途崩溃）；外加**跨通道**：
check/release 两通道 stdout **逐字节一致**（排除依赖未定义行为的"碰巧对"）。七道关卡全绿才算通过。

## 学习路线

- **基础篇（02–08）**：顺序读。03（PIC 数据模型）、05（字符串）、08（表）是 COBOL 特有的
  深水区，值得两遍——COBOL 的一切"反直觉"几乎都源于"定长字节 + 按字节计数"这一条。
- **进阶篇（09–14）**：子程序/内部函数/三类文件/状态异常/结构化。12（索引文件）是批处理的核心。
- **专题篇（15–18）**：终端界面、C 互操作、控制break 报表、测试方法论。17（报表）是 COBOL
  的看家本领，18（测试）解释了本仓库每个示例"凭什么可信"。
- **实战（19）**：跟着源码读，`FINAL-CHECKS` 的断言就是功能清单；§5 的"无符号吞负号"是全书
  最有价值的一课。
- **速查**：[CHEATSheet.md](CHEATSheet.md)（语法 + 110 条坑位）；[docs/20-pitfalls.md](docs/20-pitfalls.md)（坑位分类索引）。

## 相关教程

- [FreeBASIC](../freebasic/README.md)、[FreePascal](../freepascal/README.md)——同为"经典语言 +
  现代编译器"视角，验证方法论同源（双通道 + 逐字节比对）。
- [forth](../forth/README.md)、[prolog](../prolog/README.md)——另两门范式迥异的经典语言，
  可与 COBOL 的"批处理/文件导向"对照。
- [C 语言相关](../cpp20/README.md)——第 16 章 C 互操作的对面：COBOL 如何被 C 世界调用/调用 C。
