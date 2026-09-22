# Intel x86-64 汇编编程指南

一份面向 **Windows、macOS 和 Linux** 三平台的 Intel x86-64 汇编语言学习指南。使用 **NASM** 作为汇编器，通过 11 个类别、大量可运行示例，帮助你从零掌握 64 位汇编编程。

- Windows：`-f win64` + MSVC `link.exe`，示例在 [`examples/`](examples/)
- macOS：`-f macho64` + `clang`（自动带 libSystem），示例在 [`examples-macos/`](examples-macos/)
- Linux：`-f elf64` + `gcc -no-pie`（自动带 glibc 启动文件），示例在 [`examples-linux/`](examples-linux/)
- 跨平台差异与移植规则：[macOS 平台移植指南](docs/10_macos_porting.md) · [Linux 平台移植指南](docs/11_linux.md)

> **验证状态**：`examples-macos/` 下 **59 个示例在 macOS 全部实际汇编、链接、运行通过（59/59）**。
> 本机配置如下，另外当年在 Ivy Bridge 那台上也跑过（当时示例总数 56，56/56）：
>
> | 机器 | 系统 | CPU | NASM | clang | ld64 | 结果 |
> |------|------|-----|------|-------|------|------|
> | MacBook Pro（本机复核） | macOS 14.8.9 (23.6.0) | Intel i7-4770HQ（Haswell，有 AVX2/FMA/BMI） | 3.02 | 16.0.0 (clang-1600.0.26.6) | 1115.7.3 | 59/59 |
> | MacBook Air（当年） | macOS 13.1 | Intel i7-3520M（Ivy Bridge，无 AVX2/FMA） | 3.02 | 14.0.0 | 820.1 | 56/56（当时就是 56 个） |
>
> `examples-linux/` 下 59 个示例：其中 56 个在 Linux 实际汇编、链接、运行通过（Arch Linux / WSL2 / NASM 3.02 / GCC 16.2.1 / GNU ld 2.47 / glibc 2.44）；
> **新增的 3 个 AVX/AVX2 示例（`10_sse_simd/avx_*.asm`、`avx2_*.asm`）在本机只做到 `nasm -f elf64` 汇编通过，链接与运行未实测**（本机是 macOS，无 Linux 环境）。
> `examples/`（Windows）下 61 个示例：**2026-09 在 Windows 11（i7-12700F，Alder Lake，P/E 混合架构 / NASM 3.02 / MSVC 14.52 `link.exe`）全部实际汇编、链接、运行通过（61/61）**，包括此前「只做到汇编通过」的 3 个 AVX/AVX2 示例——逐通道数值与 macOS 版一致，Windows 侧实测输出见 [SIMD 进阶](docs/12_simd_avx.md) 第 8 节；`cpuid_hybrid` 在该机上的逐逻辑处理器（P核/E核）实测见 [混合架构](docs/09_hybrid_architecture.md)。
>
> 本机复核时修掉的三个 macOS 专属问题见 [macOS 平台移植指南](docs/10_macos_porting.md) 的
> 「10. 本机复核纪要（macOS 14 / Xcode 16 CLT）」一节：
> ① `mov rsi, label` 这种绝对地址立即数在 PIE 下会 `illegal text-relocation`；
> ② 构建脚本里 `grep '^\s*extern _'` 在 BSD grep 上永不命中，导致 55 个示例走错链接分支；
> ③ ld64-1115 把 `-macosx_version_min` 改名为 `-macos_version_min`。
>
> AVX / AVX2 / FMA 的原理与三个新示例见 [SIMD 进阶：AVX / AVX2 / FMA](docs/12_simd_avx.md)。
> 这三支示例都内置 `cpuid` + `xgetbv` 运行时探测，缺能力时打印提示并正常退出 0，
> 所以放在缺少 AVX2/FMA 的老机器上也不会崩。

## 工具链说明

| 组件 | Windows | macOS | Linux |
|------|---------|-------|-------|
| 汇编器 | NASM 3.02+ → `nasm -f win64` | NASM 3.02+ → `nasm -f macho64` | NASM 3.02+ → `nasm -f elf64` |
| 目标文件 | `.obj`（COFF） | `.o`（Mach-O） | `.o`（ELF） |
| 链接器 | MSVC `link.exe` | `clang`（驱动）或 `ld` | `gcc -no-pie`（驱动）或 `ld` |
| C 运行库 | `msvcrt.lib` + `legacy_stdio_definitions.lib` | **libSystem**（统一提供 `printf` 等） | glibc（crt1.o + libc，gcc 自动带上） |
| 系统库 | `kernel32.lib`（`ExitProcess`） | 无（`_main` 用 `ret` 返回） | 无（`main` 用 `ret` 返回；纯 syscall 程序可 `ld` 直连静态链接） |
| 符号名 | `printf`、`main` | `_printf`、`_main`（带下划线） | `printf`、`main` |
| 调试器 | x64dbg / WinDbg | `lldb` | `gdb` |
| 数学库 | Intel MKL | **Accelerate.framework**（vForce / vDSP） | **libmvec**（glibc 自带，`_ZGVbN4v_*`） |

> **Windows 安装**：NASM 可用 `scoop install nasm`；`link.exe` 需装 Visual Studio（含 C++ 桌面开发工作负载），并在 *x64 Native Tools Command Prompt* 里使用。
> **macOS 安装**：`brew install nasm` 或 MacPorts 的 `port install nasm`；`clang` / `ld` / `lldb` 随 Xcode Command Line Tools 提供（`xcode-select --install`）。
> **Linux 安装**：`sudo pacman -S nasm gcc gdb`（Arch）/ `sudo apt install nasm gcc gdb`（Debian/Ubuntu）/ `sudo dnf install nasm gcc gdb`（Fedora）。
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

### Linux

```bash
# 1. 汇编（-I 指向辅助库目录 lib/）
nasm -I lib -f elf64 examples-linux/01_data_movement/mov_basic.asm -o build/mov_basic.o

# 2. 链接（必须 -no-pie：发行版 gcc 默认 PIE，NASM 的绝对重定位编不过）
gcc -no-pie build/mov_basic.o -o build/mov_basic

# 3. 运行
./build/mov_basic
```

纯系统调用程序（不碰 libc）可以不用 gcc，直接 `ld build/test_link.o -o build/test_link`，入口默认就是 `_start`。

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
./build-mac.sh -All                        # 构建并运行全部（59 个）
./build-mac.sh -BuildOnly -All             # 只构建不运行
./build-mac.sh -Clean
```

```bash
# ---- Linux ----
./build-linux.sh -Category 01_data_movement  # 构建并运行某一类别
./build-linux.sh -File 01_data_movement/lea.asm
./build-linux.sh -All                        # 构建并运行全部（59 个）
./build-linux.sh -BuildOnly -All             # 只构建不运行
./build-linux.sh -Clean
```

`build-mac.sh` 会按需自动选择链接方式（引用了 libc 符号就用 `clang`，纯系统调用程序可以用 `ld` 直连），并支持在示例里用 `; LINK: -framework Accelerate` 声明额外的链接参数。`build-linux.sh` 同理（引用 libc 符号用 `gcc -no-pie`，纯系统调用程序 `ld` 直连，`; LINK: -lm -lmvec` 声明额外参数）。

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
| 10 | SSE/SIMD（SIMD） | 10 | `10_sse_simd` | MOVAPS、ADDPS、MULPS、CVT* 等 SSE 指令，以及 VADDPS / VPMULLD / VFMADD231PS 等 **AVX / AVX2 / FMA** 指令 |
| 11 | 高等数学与数学库（Calculus） | 7 | `11_calculus_mkl` | 数值微分/积分（梯形、辛普森、样条）与厂商数学库调用 |

三侧的示例数量对照：

| 类别 | `examples/`（Windows） | `examples-macos/`（macOS） | `examples-linux/`（Linux） |
|------|----------------------|--------------------------|---------------------------|
| 01_data_movement | 7 | 7 | 7 |
| 02_arithmetic | 7 | 7 | 7 |
| 03_logic_bitwise | 4 | 4 | 4 |
| 04_comparison | 2 | 2 | 2 |
| 05_control_flow | 9 | 9 | 9 |
| 06_string_ops | 5 | 5 | 5 |
| 07_stack_ops | 3 | 3 | 3 |
| 08_system_misc | 4 | 4 | 4 |
| 09_fpu | 5 | 5 | 5 |
| 10_sse_simd | 8 | 8 | 8 |
| 11_calculus_mkl | 7（5 + 2 个排查脚手架） | 5 | 5 |
| **合计** | **61** | **59** | **59** |

## 章节索引

| 章 | 主题 | 建议实践 |
|---|---|---|
| [01 x86-64 汇编简介](docs/01_introduction.md) | 汇编语言是什么、为什么要学 | — |
| [02 环境配置](docs/02_environment.md) | Windows / macOS / Linux 三平台工具链安装 | — |
| [03 寄存器详解](docs/03_registers.md) | 通用 / 特殊 / 段 / SIMD 寄存器与使用约定 | `01_data_movement` |
| [04 内存寻址模式](docs/04_memory_addressing.md) | 从立即数到 SIB 的寻址模式与速查表 | `01_data_movement` |
| [05 标志寄存器](docs/05_flags.md) | RFLAGS 结构、六个状态标志位详解 | `02_arithmetic` `04_comparison` |
| [06 调用约定（Win64 与 System V AMD64）](docs/06_calling_convention.md) | 两套约定的参数传递与对照总表 | `05_control_flow` |
| [07 栈和栈帧](docs/07_stack_frames.md) | 栈帧结构、RBP 帧指针、栈帧图示 | `07_stack_ops` |
| [08 调试方法](docs/08_debugging.md) | x64dbg / WinDbg / lldb / gdb 与常见错误排查 | `06_string_ops` `07_stack_ops` `08_system_misc` |
| [09 Intel 混合架构（P核/E核）](docs/09_hybrid_architecture.md) | CPUID 检测核心类型、指令集差异、Thread Director | — |
| [10 macOS 平台移植指南](docs/10_macos_porting.md) | macho64 工具链、平台差异对照、移植铁律与踩坑清单 | `examples-macos/` |
| [11 Linux 平台移植指南](docs/11_linux.md) | elf64 工具链、libmvec、移植规则与踩坑清单 | `examples-linux/` |
| [12 SIMD 进阶：AVX / AVX2 / FMA](docs/12_simd_avx.md) | VEX 三操作数、YMM 与 XCR0、vzeroupper、AVX2 整数质变、FMA 单次舍入、运行时降级 | `10_sse_simd/avx_*` `avx2_*` |

学习路线：01–04 语言与内存模型 → 05–07 标志 / 调用约定 / 栈帧（核心硬骨头）→
08–09 调试与混合架构 → 10–11 跨平台移植 → 12 SIMD 进阶收束；`09_fpu`
与 `10_sse_simd` 类别可在中级后随时穿插实践。

## 目录结构

```
intel/
├── README.md                     # 项目说明（本文件）
├── build.ps1                     # Windows 构建入口
├── build-mac.sh                  # macOS 构建入口
├── build-linux.sh                # Linux 构建入口
├── docs/                         # 概念文档
│   ├── 01_introduction.md        # x86-64 汇编简介
│   ├── 02_environment.md         # 环境配置（Windows + macOS + Linux）
│   ├── 03_registers.md           # 寄存器详解
│   ├── 04_memory_addressing.md   # 内存寻址模式
│   ├── 05_flags.md               # 标志寄存器
│   ├── 06_calling_convention.md  # 调用约定（Win64 + System V）
│   ├── 07_stack_frames.md        # 栈和栈帧
│   ├── 08_debugging.md           # 调试方法（x64dbg / WinDbg / lldb / gdb）
│   ├── 09_hybrid_architecture.md # Intel 混合架构（P核/E核）
│   ├── 10_macos_porting.md       # macOS 工具链与移植指南
│   ├── 11_linux.md               # Linux 工具链与移植指南
│   └── 12_simd_avx.md            # SIMD 进阶：AVX / AVX2 / FMA
├── lib/
│   ├── mac_io.inc                # macOS 输出辅助例程（%include 用）
│   └── linux_io.inc              # Linux 输出辅助例程（%include 用）
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
├── examples-linux/               # Linux 示例（-f elf64）
│   ├── README.md                 # Linux 示例索引与对照表
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
    ├── mac/*.o / mac/*           #   macOS
    └── linux/*.o / linux/*       #   Linux
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

### Linux

```bash
./build-linux.sh -All                              # 构建全部示例并运行
./build-linux.sh -Category 01_data_movement        # 构建指定类别
./build-linux.sh -File 01_data_movement/lea.asm    # 构建单个文件
./build-linux.sh -BuildOnly -All                   # 只构建不运行
./build-linux.sh -Clean                            # 清理 build/linux
./build-linux.sh                                   # 查看帮助
```

可用的类别名称：`01_data_movement`、`02_arithmetic`、`03_logic_bitwise`、`04_comparison`、`05_control_flow`、`06_string_ops`、`07_stack_ops`、`08_system_misc`、`09_fpu`、`10_sse_simd`、`11_calculus_mkl`。

---

祝学习愉快！如遇问题，请先查阅 [调试方法](docs/08_debugging.md)；跨平台相关的问题看 [macOS 平台移植指南](docs/10_macos_porting.md) 和 [Linux 平台移植指南](docs/11_linux.md)。
