# FreeBASIC 编程指南（fbc 1.10.1）

面向**会编程（C/QBASIC 背景皆可）、初学 FreeBASIC** 的读者：以现代 **`-lang fb` 方言**为主线，从零教到能写出带图形、多线程、直调 Win32 API 的完整程序。**FB 特色全部独立成章细讲**：内置 GFX 图形库（18）、多线程（19）、C 互操作（20）、三方言模式与 QB 迁移（22）。每章"读讲解 → 跑示例 → 改代码再跑"，全部示例在本机**双层验证**通过（`-exx` 断言+边界检查通道 + 发布形态通道，各加四条判定）。

> ⚠️ 网上 FreeBASIC 教程多为 0.2x 时代（2008 前后）或 QB 教程直接改写：OOP 语法（2004 年 0.90 才引入 `Extends`/`Virtual`）、`Open` 返回值式错误检查、win64 下的类型尺寸都与老说法不同。本教程所有代码在 **fbc 1.10.1（win64 standalone，Windows 11 x64）** 实测，每章末"坑位清单"收录版本差异——包括 BOM 导致的 GBK 转码大坑、`Integer` 在 win64 是 8 字节等 20 余条。

## 目录结构

```text
freebasic/
├── README.md       本文件
├── docs/           24 章教程（01 → 24 顺序阅读）
├── examples/       23 个示例目录（章号 = 目录号；11 为多文件工程）
├── build.ps1       统一验证脚本（须 PowerShell 7 / pwsh 运行）
├── run-all.sh      等价的 Git Bash 验证入口
└── CHEATSheet.md   语法速查 + 1.10.1 坑位索引
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景](docs/01-overview.md) | 历史与定位、三方言、工具链、FB vs C/QBASIC | — |
| [02 第一个程序](docs/02-hello.md) | fbc 命令行、Print、编码纪律（无 BOM） | `02_hello` |
| [03 类型与变量](docs/03-types.md) | ⭐win64 尺寸表（Integer=8）、Var、Const、Cast | `03_types` |
| [04 运算符与控制流](docs/04-control.md) | AndAlso/OrElse、Select Case、Iif 陷阱 | `04_control` |
| [05 过程](docs/05-procedures.md) | Sub/Function、⭐ByRef 默认、Optional、递归 | `05_procedures` |
| [06 数组](docs/06-arrays.md) | Dim/Redim Preserve、多维、参数传递 | `06_arrays` |
| [07 字符串](docs/07-strings.md) | ⭐String/ZString/WString、编码坑、手写 Split | `07_strings` |
| [08 用户定义类型](docs/08-udt.md) | Type/Union/Enum/With、Type 初始化器 | `08_udt` |
| [09 指针与内存](docs/09-pointers.md) | @/Byref、Allocate 家族、Peek/Poke | `09_pointers` |
| [10 预处理器与宏](docs/10-preprocessor.md) | #define 函数宏、⭐#macro 多行宏、条件编译 | `10_preprocessor` |
| [11 模块化与命名空间](docs/11-modules.md) | .bi/.bas 工程惯例、Namespace、多文件编译 | `11_modules`（工程） |
| [12 OOP I](docs/12-oop1.md) | 构造/析构函数、Property、静态成员 | `12_oop1` |
| [13 OOP II](docs/13-oop2.md) | ⭐Extends 继承、Virtual/Abstract 多态 | `13_oop2` |
| [14 运算符重载](docs/14-operators.md) | 成员/全局 Operator、Cast、⭐+= 必须成员 | `14_operators` |
| [15 错误处理](docs/15-errors.md) | ⭐Open 返回值、Err、Assert、On Error 的真相 | `15_errors` |
| [16 文件 IO](docs/16-files.md) | 顺序/随机/二进制三模式、Open Cons | `16_files` |
| [17 时间与随机](docs/17-time-random.md) | Timer、日期函数、Randomize 确定性种子 | `17_time_random` |
| [18 ⭐GFX 图形库](docs/18-gfx.md) | ScreenRes、绘图原语、离屏 Image、像素校验 | `18_gfx` |
| [19 ⭐多线程](docs/19-threads.md) | ThreadCreate/Mutex/Cond、数据竞争演示 | `19_threads` |
| [20 ⭐C 互操作](docs/20-cinterop.md) | windows.bi 直调 Win32、Extern "C"、Declare Lib | `20_cinterop` |
| [21 命令行程序](docs/21-cli.md) | Command/ArgV、Environ、Dir、自制 getopt | `21_cli` |
| [22 ⭐方言模式](docs/22-dialects.md) | -lang fb/fblite/qb 对照、Gosub、QB 代码迁移 | `22_langs`（含 qb 通道） |
| [23 工具链与测试](docs/23-tooling.md) | -exx/-w all、-pp、自制测试框架、编译选项 | `23_tooling` |
| [24 实战：贪吃蛇](docs/24-snake.md) | GFX + 线程输入 + 确定性回放 + 最高分文件 | `24_snake`（工程） |

## 构建工具链

- fbc **1.10.1**（2023-12-24，win64 standalone）：`G:\scoop\apps\freebasic\current\fbc.exe`（scoop 安装，自带 MinGW-w64 后端与 `inc/` 头文件库，含 `windows.bi`）。
- 源码一律 **UTF-8 无 BOM**（带 BOM 时 fbc 会把字面量转成系统 GBK 并用宽字符 API 输出，管道验证全乱——见 02 章实测）。
- 中文控制台先 `chcp 65001`（build.ps1 / run-all.sh 已代设）。

## 验证命令

```powershell
cd G:\code\guide\freebasic
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                # 全部 23 个示例：双层 × 四条判定
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 18_gfx     # 单个示例
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean              # 清理 build 目录
```

单跑某个示例（每章标准学法）——改代码后重跑：

```bash
cd freebasic/examples/18_gfx
G:/scoop/apps/freebasic/current/fbc.exe -w all -exx 18_gfx.bas -x 18_gfx.exe   # 开断言+边界检查
./18_gfx.exe
```

判定标准（每个示例 × 每层）：退出码 0、stderr 为空、stdout 非空、含 `[OK]` 结束标记。22 章示例额外通过 `-lang qb` 第三通道。

## 相关教程

系统语言对照：[dlang](../dlang/README.md)、[freepascal](../freepascal/README.md)、[cpp20](../cpp20/README.md)、[zig](../zig/README.md)；速查见 [CHEATSheet.md](CHEATSheet.md)。
