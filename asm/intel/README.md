# Intel x86-64 汇编编程指南

一份面向 **Windows 和 macOS** 双平台的 Intel x86-64 汇编语言学习指南。使用 **NASM** 作为汇编器，通过 11 个类别、大量可运行示例，帮助你从零掌握 64 位汇编编程。

- Windows：`-f win64` + MSVC `link.exe`，示例在 [`examples/`](examples/)
- macOS：`-f macho64` + `clang`（自动带 libSystem），示例在 [`examples-macos/`](examples-macos/)
- 跨平台差异与移植规则：[macOS 平台移植指南](docs/10_macos_porting.md)

> **验证状态**：`examples-macos/` 下 **56 个示例全部在本机实际汇编、链接、运行通过**（macOS 13.1 / Intel i7-3520M / NASM 3.02 / clang 14.0.0 / ld64-820.1）。

## 工具链说明

| 组件 | Windows | macOS |
|------|---------|-------|
| 汇编器 | NASM 3.02+ → `nasm -f win64` | NASM 3.02+ → `nasm -f macho64` |
| 目标文件 | `.obj`（COFF） | `.o`（Mach-O） |
| 链接器 | MSVC `link.exe` | `clang`（驱动）或 `ld` |
| C 运行库 | `msvcrt.lib` + `legacy_stdio_definitions.lib` | **libSystem**（统一提供 `printf` 等） |
| 系统库 | `kernel32.lib`（`ExitProcess`） | 无（`_main` 用 `ret` 返回） |
| 调试器 | x64dbg / WinDbg | `lldb` |
| 数学库 | Intel MKL | **Accelerate.framework**（vForce / vDSP） |

> **Windows 安装**：NASM 可用 `scoop install nasm`；`link.exe` 需装 Visual Studio（含 C++ 桌面开发工作负载），并在 *x64 Native Tools Command Prompt* 里使用。
> **macOS 安装**：`brew install nasm` 或 MacPorts 的 `port install nasm`；`clang` / `ld` / `lldb` 随 Xcode Command Line Tools 提供（`xcode-select --install`）。
> 详见 [环境配置](docs/02_environment.md)。

## 快速开始

### Windows

```powershell
# 1. 汇编
nasm -f win64 example.asm -o example.obj

# 2. 链接
link /subsystem:console /entry:main example.obj msvcrt.lib legacy_stdio_definitions.lib kernel32.lib

# 3. 运行
.\example.exe
```

### macOS

```bash
# 1. 汇编（-I 指向辅助库目录 lib/）
/opt/local/bin/nasm -I lib -f macho64 examples-macos/01_data_movement/mov_basic.asm -o build/mov_basic.o

# 2. 链接（clang 会自动补上 -lSystem 和 SDK 路径）
clang -arch x86_64 build/mov_basic.o -o build/mov_basic

# 3. 运行
./build/mov_basic
```

### 用构建脚本

```powershell
# ---- Windows ----
.\build.ps1 -Category 01_data_movement    # 构建并运行某一类别
.\build.ps1 -All                          # 构建并运行全部
```

```bash
# ---- macOS ----
./build-mac.sh -Category 01_data_movement  # 构建并运行某一类别
./build-mac.sh -File 01_data_movement/lea.asm
./build-mac.sh -All                        # 构建并运行全部（56 个）
./build-mac.sh -BuildOnly -All             # 只构建不运行
./build-mac.sh -Clean
```

`build-mac.sh` 会按需自动选择链接方式（引用了 libc 符号就用 `clang`，纯系统调用程序可以用 `ld` 直连），并支持在示例里用 `; LINK: -framework Accelerate` 声明额外的链接参数。

## 指令类别一览

项目将 x86-64 指令划分为 11 个类别，每个类别对应一个子目录：

| # | 类别 | 指令数 | 目录 | 说明 |
|---|------|--------|------|------|
| 1 | 数据传送（Data Movement） | 9 | `01_data_movement` | MOV、LEA、XCHG、PUSH/POP、CMOVcc 等数据移动指令 |
| 2 | 算术运算（Arithmetic） | 9 | `02_arithmetic` | ADD、SUB、MUL、DIV、INC、DEC、NEG 等算术运算 |
| 3 | 逻辑与位运算（Logic & Bitwise） | 13 | `03_logic_bitwise` | AND、OR、XOR、NOT、SHL、SHR、ROL、BT 等位操作 |
| 4 | 比较与测试（Comparison） | 5 | `04_comparison` | CMP、TEST、SETcc 等比较与条件设置指令 |
| 5 | 控制流（Control Flow） | 8 | `05_control_flow` | JMP、Jcc、CALL、RET、LOOP 等跳转与循环指令 |
| 6 | 字符串操作（String Operations） | 8 | `06_string_ops` | MOVS、STOS、LODS、CMPS、SCAS 及 REP 前缀 |
| 7 | 栈操作（Stack Operations） | 6 | `07_stack_ops` | PUSH、POP、ENTER、LEAVE 等栈管理指令 |
| 8 | 系统与杂项（System & Misc） | 6 | `08_system_misc` | SYSCALL、CPUID、RDTSC、NOP、HLT 等 |
| 9 | 浮点运算（FPU） | 8 | `09_fpu` | FLD、FST、FADD、FMUL、FDIV、FCOM 等 x87 指令 |
| 10 | SSE/SIMD（SIMD） | 10 | `10_sse_simd` | MOVAPS、ADDPS、MULPS、CVT* 等 SIMD 指令 |
| 11 | 高等数学与数学库（Calculus） | 7 | `11_calculus_mkl` | 数值微分/积分（梯形、辛普森、样条）与厂商数学库调用 |

两侧的示例数量对照：

| 类别 | `examples/`（Windows） | `examples-macos/`（macOS） |
|------|----------------------|--------------------------|
| 01_data_movement | 7 | 7 |
| 02_arithmetic | 7 | 7 |
| 03_logic_bitwise | 4 | 4 |
| 04_comparison | 2 | 2 |
| 05_control_flow | 9 | 9 |
| 06_string_ops | 5 | 5 |
| 07_stack_ops | 3 | 3 |
| 08_system_misc | 4 | 4 |
| 09_fpu | 5 | 5 |
| 10_sse_simd | 5 | 5 |
| 11_calculus_mkl | 7（5 + 2 个排查脚手架） | 5 |
| **合计** | **58** | **56** |

## 学习路径

### 初级

1. 阅读 [x86-64 汇编简介](docs/01_introduction.md)，建立整体认识
2. 按 [环境配置](docs/02_environment.md) 搭建开发环境（含 macOS 一节）
3. 学习 [寄存器详解](docs/03_registers.md) 与 [内存寻址模式](docs/04_memory_addressing.md)
4. 实践 `01_data_movement` 与 `02_arithmetic` 类别示例

### 中级

1. 掌握 [标志寄存器](docs/05_flags.md) 与条件判断
2. 学习 [调用约定](docs/06_calling_convention.md)（Win64 与 System V 双份对照）
3. 深入 [栈和栈帧](docs/07_stack_frames.md)，理解函数调用机制
4. 实践 `03_logic_bitwise`、`04_comparison`、`05_control_flow` 类别示例

### 高级

1. 学习 [调试方法](docs/08_debugging.md)，Windows 用 x64dbg/WinDbg、macOS 用 lldb
2. 实践 `06_string_ops`、`07_stack_ops`、`08_system_misc` 类别示例
3. 探索 `09_fpu` 浮点运算与 `10_sse_simd` 向量化编程
4. 看 [macOS 平台移植指南](docs/10_macos_porting.md)，把一套代码同时在两个平台上跑通
5. 尝试混合 C 与汇编编程，优化关键路径代码

## 目录结构

```
intel/
├── README.md                     # 项目说明（本文件）
├── build.ps1                     # Windows 构建入口
├── build-mac.sh                  # macOS 构建入口
├── docs/                         # 概念文档
│   ├── 01_introduction.md        # x86-64 汇编简介
│   ├── 02_environment.md         # 环境配置（Windows + macOS）
│   ├── 03_registers.md           # 寄存器详解
│   ├── 04_memory_addressing.md   # 内存寻址模式
│   ├── 05_flags.md               # 标志寄存器
│   ├── 06_calling_convention.md  # 调用约定（Win64 + System V）
│   ├── 07_stack_frames.md        # 栈和栈帧
│   ├── 08_debugging.md           # 调试方法（x64dbg / WinDbg / lldb）
│   ├── 09_hybrid_architecture.md # Intel 混合架构（P核/E核）
│   └── 10_macos_porting.md       # macOS 工具链与移植指南
├── lib/
│   └── mac_io.inc                # macOS 输出辅助例程（%include 用）
├── examples/                     # Windows 示例（-f win64）
│   ├── 01_data_movement/
│   ├── 02_arithmetic/
│   ├── ...
│   └── 11_calculus_mkl/
├── examples-macos/               # macOS 示例（-f macho64）
│   ├── README.md                 # macOS 示例索引与对照表
│   ├── 01_data_movement/
│   ├── 02_arithmetic/
│   ├── ...
│   └── 11_calculus_mkl/
├── scripts/                      # Windows 构建辅助脚本
│   ├── common.ps1
│   ├── build_all.ps1
│   ├── build_category.ps1
│   └── clean.ps1
└── build/                        # 构建产物
    ├── *.obj / *.exe             #   Windows
    └── mac/*.o / mac/*           #   macOS
```

## 构建命令

### Windows

```powershell
.\build.ps1 -All                          # 构建全部示例并运行
.\build.ps1 -Category 01_data_movement    # 构建指定类别
.\build.ps1 -Clean                        # 清理构建产物
.\build.ps1                               # 查看帮助
```

### macOS

```bash
./build-mac.sh -All                              # 构建全部示例并运行
./build-mac.sh -Category 01_data_movement        # 构建指定类别
./build-mac.sh -File 01_data_movement/lea.asm    # 构建单个文件
./build-mac.sh -BuildOnly -All                   # 只构建不运行
./build-mac.sh -Clean                            # 清理 build/mac
./build-mac.sh                                   # 查看帮助
```

可用的类别名称：`01_data_movement`、`02_arithmetic`、`03_logic_bitwise`、`04_comparison`、`05_control_flow`、`06_string_ops`、`07_stack_ops`、`08_system_misc`、`09_fpu`、`10_sse_simd`、`11_calculus_mkl`。

---

祝学习愉快！如遇问题，请先查阅 [调试方法](docs/08_debugging.md)；跨平台相关的问题看 [macOS 平台移植指南](docs/10_macos_porting.md)。
