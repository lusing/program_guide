# Intel x86-64 汇编编程指南

一份面向 Windows 平台的 Intel x86-64 汇编语言学习指南。使用 **NASM** 作为汇编器、**MSVC link.exe** 作为链接器，通过大量可运行示例帮助你从零掌握 64 位汇编编程。

## 工具链说明

| 组件 | 版本 | 说明 |
|------|------|------|
| NASM | 3.02+ | Netwide Assembler，将 `.asm` 源码汇编为 `win64` 格式目标文件（`.obj`） |
| MSVC link.exe | 随 Visual Studio 提供 | 微软增量链接器，将目标文件与库链接为 Windows 可执行程序（`.exe`） |
| msvcrt.lib | 系统库 | C 运行时库，提供 `printf`、`malloc` 等函数 |
| legacy_stdio_definitions.lib | 系统库 | 旧版标准 I/O 定义库，补充 `printf` 等 CRT 符号声明 |
| kernel32.lib | 系统库 | Windows API 基础库，提供 `ExitProcess` 等函数 |

> 安装方式：NASM 可通过 `scoop install nasm` 安装；link.exe 需安装 Visual Studio（含 C++ 桌面开发工作负载），并使用 *x64 Native Tools Command Prompt* 初始化环境变量。详见 [环境配置](docs/02_environment.md)。

## 快速开始

进入任意示例目录，执行以下两步即可编译运行单个示例：

```powershell
# 1. 汇编：生成目标文件
nasm -f win64 example.asm -o example.obj

# 2. 链接：生成可执行文件
link /subsystem:console /entry:main example.obj msvcrt.lib legacy_stdio_definitions.lib kernel32.lib
```

也可以使用项目自带的构建脚本一键编译并运行：

```powershell
# 构建并运行某一类别下的所有示例
.\build.ps1 -Category 01_data_movement

# 构建并运行全部示例
.\build.ps1 -All
```

## 指令类别一览

本项目将 x86-64 指令划分为 11 个类别，每个类别对应 `examples/` 下的一个子目录：

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
| 11 | 高等数学与 MKL（Calculus & MKL） | 7 | `11_calculus_mkl` | AVX2 数值微分/积分（梯形/辛普森法则）与 Intel MKL 数学库调用 |

## 学习路径

### 初级

1. 阅读 [x86-64 汇编简介](docs/01_introduction.md)，建立整体认识
2. 按 [环境配置](docs/02_environment.md) 搭建开发环境
3. 学习 [寄存器详解](docs/03_registers.md) 与 [内存寻址模式](docs/04_memory_addressing.md)
4. 实践 `01_data_movement` 与 `02_arithmetic` 类别示例

### 中级

1. 掌握 [标志寄存器](docs/05_flags.md) 与条件判断
2. 学习 [Windows x64 调用约定](docs/06_calling_convention.md)
3. 深入 [栈和栈帧](docs/07_stack_frames.md)，理解函数调用机制
4. 实践 `03_logic_bitwise`、`04_comparison`、`05_control_flow` 类别示例

### 高级

1. 学习 [调试方法](docs/08_debugging.md)，掌握 x64dbg/WinDbg
2. 实践 `06_string_ops`、`07_stack_ops`、`08_system_misc` 类别示例
3. 探索 `09_fpu` 浮点运算与 `10_sse_simd` 向量化编程
4. 尝试混合 C 与汇编编程，优化关键路径代码

## 目录结构

```
intel/
├── README.md                 # 项目说明（本文件）
├── build.ps1                 # 构建入口脚本
├── docs/                     # 概念文档
│   ├── 01_introduction.md    # x86-64 汇编简介
│   ├── 02_environment.md     # 环境配置
│   ├── 03_registers.md       # 寄存器详解
│   ├── 04_memory_addressing.md  # 内存寻址模式
│   ├── 05_flags.md           # 标志寄存器
│   ├── 06_calling_convention.md # Windows x64 调用约定
│   ├── 07_stack_frames.md    # 栈和栈帧
│   ├── 08_debugging.md       # 调试方法
│   └── 09_hybrid_architecture.md # Intel 混合架构（P核/E核）
├── examples/                 # 可运行示例（按指令类别组织）
│   ├── 01_data_movement/
│   ├── 02_arithmetic/
│   ├── ...
│   └── 11_calculus_mkl/
├── scripts/                  # 构建辅助脚本
│   ├── common.ps1            # 共享构建逻辑
│   ├── build_all.ps1         # 构建全部示例
│   ├── build_category.ps1    # 构建指定类别
│   └── clean.ps1             # 清理构建产物
└── build/                    # 构建产物输出目录（.obj / .exe）
```

## 构建命令

所有构建操作通过 `build.ps1` 入口脚本完成：

```powershell
# 构建全部示例并运行
.\build.ps1 -All

# 构建指定类别的示例
.\build.ps1 -Category 01_data_movement

# 清理 build 目录下的所有编译产物
.\build.ps1 -Clean

# 查看用法帮助
.\build.ps1
```

可用的类别名称：`01_data_movement`、`02_arithmetic`、`03_logic_bitwise`、`04_comparison`、`05_control_flow`、`06_string_ops`、`07_stack_ops`、`08_system_misc`、`09_fpu`、`10_sse_simd`、`11_calculus_mkl`。

---

祝学习愉快！如遇问题，请先查阅 [调试方法](docs/08_debugging.md)。
