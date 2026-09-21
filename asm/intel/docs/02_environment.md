# 环境配置

本指南同时覆盖 **Windows** 和 **macOS**：Windows 用 **NASM** + **MSVC link.exe**，macOS 用 **NASM** + **clang/ld**。本章介绍两套工具链的安装配置及编译链接流程。

- Windows 部分：从「NASM 安装和使用」到「编译链接流程详解」
- macOS 部分：见 [macOS 环境配置](#macos-环境配置)
- 跨平台差异的完整讨论：见 [macOS 平台移植指南](10_macos_porting.md)

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

## macOS 环境配置

### 安装 NASM

```bash
# Homebrew
brew install nasm

# 或者 MacPorts
sudo port install nasm        # 装到 /opt/local/bin/nasm

# 验证
nasm -v
# 预期输出: NASM version 3.02 (or newer) compiled on ...
```

### 链接器与调试器

macOS 不需要单独装链接器：`clang`、`ld`、`lldb` 都随 **Xcode Command Line Tools** 提供。

```bash
xcode-select --install        # 若尚未安装

# 验证
clang --version               # Apple clang version 14.x
ld -v                         # @(#)PROGRAM:ld  PROJECT:ld64-820.1
lldb --version
xcrun --show-sdk-path         # /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
```

### 和目标格式

```bash
nasm -f macho64 example.asm -o example.o
```

| 参数 | 说明 |
|------|------|
| `-f macho64` | 输出 64 位 Mach-O 目标文件（`.o`）——这是与 Windows 最核心的差别 |
| `-I <dir>` | 追加 `%include` 的搜索路径（本项目用它找到 `lib/mac_io.inc`） |
| `-g` | 生成 DWARF 调试信息，供 `lldb` 使用 |
| `-l <file>` | 生成列表文件 |
| `-d <name>=<value>` | 定义宏 |

### 链接

**推荐用 `clang` 驱动**，它会自动补上 `-lSystem` 和 SDK 的搜索路径：

```bash
clang -arch x86_64 example.o -o example
./example
```

如果需要额外的框架（例如第 11 类的 Accelerate）：

```bash
clang -arch x86_64 example.o -o example -framework Accelerate
```

**也可以直接用 `ld`**，但必须自己指定 `-lSystem`：

```bash
SDK="$(xcrun --show-sdk-path)"
ld -arch x86_64 -macosx_version_min 11.0 -e _main example.o -o example \
   -lSystem -syslibroot "$SDK" -L"$SDK/usr/lib"
```

> **为什么纯系统调用程序也要 `-lSystem`？** macOS 的可执行文件必须是动态链接的。哪怕一个 libc 函数都不调，链接器仍需要 libSystem 来写入动态加载信息，否则报
> `ld: dynamic executables or dylibs must link with libSystem.dylib`。

### 和 Windows 版的三处写法差异

```asm
; 1) 符号带下划线，入口叫 _main
    global _main
    extern _printf

; 2) 参数寄存器：rdi rsi rdx rcx r8 r9（不是 rcx rdx r8 r9）
    lea rdi, [fmt]
    mov esi, 42
    xor eax, eax
    call _printf

; 3) 收场用 leave / ret（不是 call ExitProcess）
    xor eax, eax
    leave
    ret
```

### 项目自带的 macOS 构建脚本

```bash
./build-mac.sh -All                              # 构建并运行全部
./build-mac.sh -Category 01_data_movement        # 指定类别
./build-mac.sh -File 01_data_movement/lea.asm    # 单个文件
./build-mac.sh -BuildOnly -All                   # 只构建不运行
./build-mac.sh -Clean                            # 清理 build/mac
```

脚本会自动判断链接方式：源文件里有 `extern _` 就用 `clang` 驱动，否则用 `ld` 直连。示例里写一行 `; LINK: -framework Accelerate` 就能给链接器追加参数。

### 辅助库 lib/mac_io.inc

macOS 版示例的输出代码可以复用一组现成例程，避免每个例子都手写 `_printf` 传参：

```asm
; 在文件末尾（顶层）写一行
%include "mac_io.inc"

; 可用：m_nl、m_puts、m_putchar、m_putint、m_putuint、m_putbool、
;       m_puthex、m_putd、m_putg、m_putf、m_putflags、m_putsep
```

汇编时要带上 `-I lib`。它是可选依赖，不用也完全没问题。

## Linux 环境配置

### 安装工具链

```bash
# Arch
sudo pacman -S nasm gcc gdb

# Debian / Ubuntu
sudo apt install nasm gcc gdb

# Fedora
sudo dnf install nasm gcc gdb

# 验证
nasm -v        # 预期输出: NASM version 3.02 (or newer) compiled on ...
gcc --version
ld --version   # GNU ld（binutils）
```

`gcc`（含 GNU ld）、`gdb` 都由发行版包管理器提供；如果系统里没有独立的 `ld`，它在 `binutils` 包里。

### 目标格式

```bash
nasm -f elf64 example.asm -o example.o
```

| 参数 | 说明 |
|------|------|
| `-f elf64` | 输出 64 位 ELF 目标文件（`.o`） |
| `-I <dir>` | 追加 `%include` 的搜索路径（本项目用它找到 `lib/linux_io.inc`） |
| `-g -F dwarf` | 生成 DWARF 调试信息，供 `gdb` 使用 |
| `-l <file>` | 生成列表文件 |
| `-d <name>=<value>` | 定义宏 |

### 链接

**推荐用 `gcc` 驱动**，它会自动补上 crt1.o（C 运行库启动代码）和 libc 搜索路径。**注意必须加 `-no-pie`**：发行版 gcc 默认生成 PIE，而 NASM 源码里的绝对重定位在 PIE 下编不过（报 `relocation R_X86_64_32S ... recompile with -fPIC`）。

```bash
gcc -no-pie example.o -o example
./example
```

需要额外的库（例如第 11 类的 libmvec）直接跟在后面：

```bash
gcc -no-pie example.o -o example -lm -lmvec
```

**纯系统调用程序可以不用 gcc，直接 `ld`**：入口默认就是 `_start`，生成完全静态的可执行文件（这一点比 macOS 必须动态链接省心）：

```bash
nasm -f elf64 example.asm -o example.o
ld example.o -o example
./example
```

### 和 Windows 版的三处写法差异

```asm
; 1) 符号不带下划线，入口叫 main（和 Windows 一样，和 macOS 不同）
    global main
    extern printf

; 2) 参数寄存器：rdi rsi rdx rcx r8 r9（不是 rcx rdx r8 r9）
    lea rdi, [fmt]
    mov esi, 42
    xor eax, eax
    call printf

; 3) 收场用 leave / ret（不是 call ExitProcess）
    xor eax, eax
    leave
    ret
```

### 项目自带的 Linux 构建脚本

```bash
./build-linux.sh -All                              # 构建并运行全部
./build-linux.sh -Category 01_data_movement        # 指定类别
./build-linux.sh -File 01_data_movement/lea.asm    # 单个文件
./build-linux.sh -BuildOnly -All                   # 只构建不运行
./build-linux.sh -Clean                            # 清理 build/linux
```

脚本会自动判断链接方式：源文件里有 `extern ` 就用 `gcc -no-pie` 驱动，否则用 `ld` 直连。示例里写一行 `; LINK: -lm -lmvec` 就能给链接器追加参数。

### 辅助库 lib/linux_io.inc

Linux 版示例的输出代码可以复用一组现成例程（与 `lib/mac_io.inc` 一一对应，前缀 `l_`）：

```asm
; 在文件末尾（顶层）写一行
%include "linux_io.inc"

; 可用：l_nl、l_puts、l_putchar、l_putint、l_putuint、l_putbool、
;       l_puthex、l_putd、l_putg、l_putf、l_putflags、l_putsep
```

汇编时要带上 `-I lib`。它是可选依赖，不用也完全没问题。

## 常用命令速查

| 操作 | Windows | macOS | Linux |
|------|---------|-------|-------|
| 汇编 | `nasm -f win64 example.asm -o example.obj` | `nasm -I lib -f macho64 example.asm -o example.o` | `nasm -I lib -f elf64 example.asm -o example.o` |
| 带调试信息汇编 | `nasm -f win64 -g example.asm -o example.obj` | `nasm -f macho64 -g example.asm -o example.o` | `nasm -f elf64 -g -F dwarf example.asm -o example.o` |
| 生成列表文件 | `nasm -f win64 -l example.lst example.asm` | `nasm -f macho64 -l example.lst example.asm` | `nasm -f elf64 -l example.lst example.asm` |
| 链接 | `link /subsystem:console /entry:main example.obj msvcrt.lib legacy_stdio_definitions.lib kernel32.lib` | `clang -arch x86_64 example.o -o example` | `gcc -no-pie example.o -o example` |
| 带调试信息链接 | 加 `/debug` | 加 `-g` | 加 `-g` |
| 带数学库链接 | — | `clang -arch x86_64 example.o -o example -framework Accelerate` | `gcc -no-pie example.o -o example -lm -lmvec` |
| 构建全部示例 | `.\build.ps1 -All` | `./build-mac.sh -All` | `./build-linux.sh -All` |
| 构建单个类别 | `.\build.ps1 -Category 01_data_movement` | `./build-mac.sh -Category 01_data_movement` | `./build-linux.sh -Category 01_data_movement` |
| 清理构建产物 | `.\build.ps1 -Clean` | `./build-mac.sh -Clean` | `./build-linux.sh -Clean` |
| 调试 | `x64dbg example.exe` | `lldb ./build/mac/example` | `gdb ./build/linux/example` |

---

> 上一章：[x86-64 汇编简介](01_introduction.md) ｜ 下一章：[寄存器详解](03_registers.md) ｜ 返回：[README](../README.md)
