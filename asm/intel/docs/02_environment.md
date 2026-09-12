# 环境配置

本指南基于 Windows 平台，使用 **NASM** 汇编器与 **MSVC link.exe** 链接器组成工具链。本章介绍两者的安装配置及编译链接流程。

## NASM 安装和使用

[NASM](https://www.nasm.us/)（Netwide Assembler）是一款开源、可移植的 x86 汇编器，语法简洁，广泛用于社区项目。

### 安装

推荐使用 [Scoop](https://scoop.sh/) 包管理器一键安装：

```powershell
scoop install nasm
```

安装完成后验证版本：

```powershell
nasm -v
# 预期输出: NASM version 3.02 (or newer) compiled on ...
```

> 也可从 [nasm.us](https://www.nasm.us/) 下载安装包，手动将可执行文件目录加入 `PATH` 环境变量。

### 基本用法

```powershell
nasm -f win64 example.asm -o example.obj
```

| 参数 | 说明 |
|------|------|
| `-f win64` | 指定输出格式为 64 位 Windows COFF 目标文件（`.obj`） |
| `-o <file>` | 指定输出文件名 |
| `-l <file>` | 生成列表文件（Listing File），便于查看指令编码与地址 |
| `-g` | 生成调试信息（CV8 格式），供调试器使用 |
| `-d <name>=<value>` | 定义宏，例如 `-d DEBUG=1` |

## MSVC link.exe 配置

`link.exe` 是 Visual Studio 自带的增量链接器，随 MSVC（Microsoft Visual C++）工具链分发。

### 前置条件

安装 [Visual Studio](https://visualstudio.microsoft.com/)，勾选 **"使用 C++ 的桌面开发"** 工作负载。安装完成后，`link.exe` 及相关库文件位于：

```
<VS安装目录>\VC\Tools\MSVC\<版本号>\bin\Hostx64\x64\link.exe
```

### 初始化环境变量

`link.exe` 依赖 MSVC 与 Windows SDK 的头文件/库路径。最简单的方式是使用 **x64 Native Tools Command Prompt for VS**（开始菜单搜索），它会自动配置好所有环境变量。

也可以在 PowerShell 中手动初始化：

```powershell
# 加载 vcvarsall 并设置 x64 环境（路径根据实际安装位置调整）
& "G:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
```

验证 link.exe 是否可用：

```powershell
link
# 预期输出: Microsoft (R) Incremental Linker Version ...
```

### 常用链接参数

| 参数 | 说明 |
|------|------|
| `/subsystem:console` | 生成控制台子系统程序（默认有控制台窗口） |
| `/entry:<name>` | 指定程序入口点（默认 main / mainCRTStartup） |
| `/debug` | 生成调试信息（PDB 文件） |
| `/libpath:<dir>` | 添加库搜索路径 |
| `/out:<file>` | 指定输出可执行文件名 |

## 编译链接流程详解

从源码到可执行程序分为两个阶段：

```
example.asm  ──[nasm -f win64]──>  example.obj  ──[link]──>  example.exe
   汇编源码         汇编阶段          目标文件        链接阶段      可执行程序
```

### 阶段一：汇编（Assembling）

NASM 读取 `.asm` 源文件，将助记符翻译为机器码，输出 COFF 格式的目标文件（Object File）。目标文件包含机器码、数据以及符号表（Symbol Table），但外部引用（如 `printf`）尚未解析。

```powershell
nasm -f win64 example.asm -o example.obj
```

### 阶段二：链接（Linking）

link.exe 将目标文件与所需库文件合并，解析所有外部符号引用，生成最终可执行程序。

```powershell
link /subsystem:console /entry:main example.obj msvcrt.lib legacy_stdio_definitions.lib kernel32.lib
```

- `msvcrt.lib`：C 运行时库，提供 `malloc`、`exit` 等函数
- `legacy_stdio_definitions.lib`：旧版标准 I/O 定义库，提供 `printf`、`scanf` 等 CRT 符号声明
- `kernel32.lib`：Windows API 库，提供 `ExitProcess`、`GetStdHandle` 等函数

### 完整示例

下面是一个调用 `printf` 输出字符串的完整示例：

```nasm
; hello.asm — 在控制台打印 "Hello, x86-64!"
extern printf                       ; 声明外部 C 函数
extern ExitProcess                  ; 声明 Windows API 退出函数

section .data
    fmt     db  'Hello, x86-64!', 10, 0   ; 格式字符串 + 换行 + 空终止
    msg     db  '%s', 0

section .text
global main
main:
    sub     rsp, 40                 ; 32字节影子空间 + 8字节栈对齐
    lea     rcx, [rel msg]          ; 第1个参数: 格式串
    lea     rdx, [rel fmt]          ; 第2个参数: 字符串
    call    printf
    xor     ecx, ecx                ; 退出码 0
    call    ExitProcess             ; 退出进程（/entry:main 必须用 ExitProcess）
```

编译运行：

```powershell
nasm -f win64 hello.asm -o hello.obj
link /subsystem:console /entry:main hello.obj msvcrt.lib legacy_stdio_definitions.lib kernel32.lib
.\hello.exe
# 输出: Hello, x86-64!
```

## 常用命令速查

| 操作 | 命令 |
|------|------|
| 汇编 | `nasm -f win64 example.asm -o example.obj` |
| 带调试信息汇编 | `nasm -f win64 -g example.asm -o example.obj` |
| 生成列表文件 | `nasm -f win64 -l example.lst example.asm` |
| 链接 | `link /subsystem:console /entry:main example.obj msvcrt.lib legacy_stdio_definitions.lib kernel32.lib` |
| 带调试信息链接 | `link /subsystem:console /entry:main /debug example.obj msvcrt.lib legacy_stdio_definitions.lib kernel32.lib` |
| 构建全部示例 | `.\build.ps1 -All` |
| 构建单个类别 | `.\build.ps1 -Category 01_data_movement` |
| 清理构建产物 | `.\build.ps1 -Clean` |

---

> 上一篇：[x86-64 汇编简介](01_introduction.md) ｜ 下一篇：[寄存器详解](03_registers.md)
