# Intel x86-64 汇编编程指南

一份面向 **Windows、macOS 和 Linux** 三平台、覆盖 **NASM / MASM / AT&T 三套语法** 的 Intel x86-64 汇编学习指南：14 个类别、78 个 Windows 示例（NASM 版），同批示例的 **MASM 全量镜像（78 支）**与 **AT&T/Linux 镜像（54 支）**，外加一条 **QEMU 实跑的 16→32→64 位引导链**。

- Windows·NASM：`-f win64` + MSVC `link.exe`，示例在 [`examples/`](examples/)
- Windows·MASM：`ml64.exe` + 同一套 link，镜像在 [`examples-masm/`](examples-masm/)（语法对照见[第 20 章](docs/20_masm_nasm.md)）
- Linux·NASM：`-f elf64` + `gcc -no-pie`，示例在 [`examples-linux/`](examples-linux/)
- Linux·AT&T：GNU `as` + gcc，镜像在 [`examples-att/`](examples-att/)（GNU as 语法练习场）
- macOS：`-f macho64` + `clang`，示例在 [`examples-macos/`](examples-macos/)
- 引导链（实模式/保护模式/分页/长模式）：`boot/` 目录 + QEMU，见[第 15-17 章](docs/15_real_protected_mode.md)
- 跨平台差异与移植规则：[macOS 平台移植指南](docs/10_macos_porting.md) · [Linux 平台移植指南](docs/11_linux.md)

> **验证状态**：`examples-macos/` 下 **59 个示例在 macOS 全部实际汇编、链接、运行通过（59/59）**。
> 本机配置如下，另外当年在 Ivy Bridge 那台上也跑过（当时示例总数 56，56/56）：
>
> | 机器 | 系统 | CPU | NASM | clang | ld64 | 结果 |
> |------|------|-----|------|-------|------|------|
> | MacBook Pro（本机复核） | macOS 14.8.9 (23.6.0) | Intel i7-4770HQ（Haswell，有 AVX2/FMA/BMI） | 3.02 | 16.0.0 (clang-1600.0.26.6) | 1115.7.3 | 59/59 |
> | MacBook Air（当年） | macOS 13.1 | Intel i7-3520M（Ivy Bridge，无 AVX2/FMA） | 3.02 | 14.0.0 | 820.1 | 56/56（当时就是 56 个） |
>
> `examples-linux/` 下 60 个示例：
> - 56 个在 Arch Linux / WSL2（NASM 3.02 / GCC 16.2.1 / GNU ld 2.47 / glibc 2.44）实际汇编、链接、运行通过；
> - **3 个 AVX/AVX2/FMA 示例（`10_sse_simd/avx_basics.asm`、`avx2_int.asm`、`avx2_fma.asm`）现已在本机（Ubuntu 22.04 / KVM / Intel Xeon Platinum，Skylake-SP）实际汇编、链接、运行通过**——逐通道数值与 macOS/Windows 版一致；
> - **1 个 AVX-512 示例（`10_sse_simd/avx512_basics.asm`，当时只有 Linux 版，2026-09 已补齐 Windows 版）在本机实测通过**——演示 ZMM 16 路整数加、opmask 合并掩码 `{k1}` 与归零掩码 `{k1}{z}`，本机支持 AVX-512F/DQ/CD/BW/VL 且 XCR0[7:5] 全开，逐通道输出与预期完全吻合（见 [SIMD 进阶](docs/12_simd_avx.md) 第 9 节）；
> - 至此 `examples-linux/` **60/60** 全部实测通过。
>   - 本机用的是 apt 自带的 **NASM 2.15.05**（指南标注的 3.02+ 是推荐版本，2.15 汇编这 60 个示例完全没问题，包括 AVX-512 指令与 `{k1}`/`{k1}{z}` 掩码语法）。
> `examples/`（Windows）下 75 个示例：**全部实际汇编、链接、运行通过（75/75）**，已在两台 Windows 机器上各完整跑过一遍（2026-09 教材大扩充新增 13 支：`09_fpu` 追加控制字/BCD/栈溢出 3 支，新增 `12_data_repr`、`13_exceptions`、`14_threads_sync` 三类——扩充后全量在 i7-12700F 复测 75/75）：
>
> | 机器 | 系统 | CPU | NASM | link.exe | 结果 |
> |------|------|-----|------|----------|------|
> | i7-12700F（2026-09 首测） | Windows 11 | Intel i7-12700F（Alder Lake，P/E 混合架构） | 3.02 | MSVC 14.52 | 61/61（当时示例 61 个）；扩充后 **75/75** |
> | Xeon Platinum（本机复核） | Windows 11 企业版 23H2（10.0.22631） | Intel Xeon Platinum 8378C（Ice Lake-SP，KVM 虚拟机，4 核 8 线程） | 3.02 | MSVC 14.51（VS 2026 18.8） | 62/62（当时示例 62 个） |
>
> 另有 `boot/` 下 4 支**引导链示例**（实模式 MBR、进保护模式、32 位分页、
> 64 位长模式）在本机 QEMU 无头模式下实跑验证通过（4/4，`./build-boot.sh all`
> 自动校验串口输出；QEMU 8.x / Windows 11）。`12_data_repr`、`13_exceptions`、
> `14_threads_sync` 三类为 Windows 专属（SEH/线程 API），macOS/Linux 镜像暂缺，
> 概念与可移植部分见各章说明。

> **三语法验证状态**（2026-09-26 追加）：
>
> | 语法 | 范围 | 验证 | 工具链 |
> |------|------|------|--------|
> | NASM（主版本） | Windows 78 + boot 4 + Linux 60 + macOS 59 | **全部实测** | nasm 3.02 / MSVC / gcc / clang |
> | MASM（`examples-masm/`） | Windows 78 支全量镜像 | **78/78 实测**（`build-masm.ps1 -All`） | ml64 14.52 + link |
> | AT&T（`examples-att/`） | Linux 60 支全量镜像 | **60/60 实测通过**（WSL Ubuntu-26.04：GNU as 2.46 / gcc 15.2 / glibc 2.43；亦曾在 WSL Deepin as 2.41 验证 54 支） | GNU as + gcc |
>
> MASM/AT&T 版由 NASM 版半自动翻译 + 人工修正生成（翻译器淬炼出的语法坑已回填进
> [第 20 章](docs/20_masm_nasm.md)对照表）。`build-att.sh` 在任意 Linux/WSL 上：
> `cd asm/intel && ./build-att.sh`（11 类需 `libmvec`，Ubuntu/Debian 在 glibc 包内）。
>
> 两台都包括此前「只做到汇编通过」的 3 个 AVX/AVX2 示例——逐通道数值与 macOS 版一致，
> Windows 侧实测输出见 [SIMD 进阶](docs/12_simd_avx.md) 第 9 节；本机复核时还补齐了
> **Windows 版 `avx512_basics.asm`**（AVX-512 此前只有 Linux 版），并在本机真跑出完整三段输出：
> 该机 AVX2 = YES、**AVX-512F/DQ/CD/BW/VL = YES**（Windows 已放开 ZMM 状态），ZMM / opmask
> 指令确实能执行，见同节末；`cpuid_hybrid` 在 Alder Lake 那台上的逐逻辑处理器（P核/E核）实测见
> [混合架构](docs/09_hybrid_architecture.md)，本机则因虚拟机把最大基本页号限成 `0xD`
> 而走前置检查跳过——详见同一章的第五台机器一节。
>
> 本机复核时把构建脚本里写死的工具链盘符去掉了（原来固定 `G:\Program Files\Microsoft Visual Studio\18\Community`
> 与 `G:\Intel\OneAPI\mkl\latest`，换机器就编不动）：现在 VS 用 `vswhere` 定位，MKL 依次探测常见安装位置。
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
./build-linux.sh -All                        # 构建并运行全部（60 个）
./build-linux.sh -BuildOnly -All             # 只构建不运行
./build-linux.sh -Clean
```

`build-mac.sh` 会按需自动选择链接方式（引用了 libc 符号就用 `clang`，纯系统调用程序可以用 `ld` 直连），并支持在示例里用 `; LINK: -framework Accelerate` 声明额外的链接参数。`build-linux.sh` 同理（引用 libc 符号用 `gcc -no-pie`，纯系统调用程序 `ld` 直连，`; LINK: -lm -lmvec` 声明额外参数）。

## 指令类别一览

项目将 x86-64 指令划分为 14 个类别，每个类别对应一个子目录（12-14 为 2026-09 教材扩充新增）：

| # | 类别 | 指令数 | 目录 | 说明 |
|---|------|--------|------|------|
| 1 | 数据传送（Data Movement） | 9 | `01_data_movement` | MOV、LEA、XCHG、PUSH/POP、CMOVcc 等数据移动指令 |
| 2 | 算术运算（Arithmetic） | 10 | `02_arithmetic` | ADD、SUB、MUL、DIV、INC、DEC、NEG 等算术运算，以及 128 位多精度（add/adc、sub/sbb、mul 64x64→128） |
| 3 | 逻辑与位运算（Logic & Bitwise） | 14 | `03_logic_bitwise` | AND、OR、XOR、NOT、SHL、SHR、ROL、BT 等位操作，位域打包/解包与 popcount |
| 4 | 比较与测试（Comparison） | 5 | `04_comparison` | CMP、TEST、SETcc 等比较与条件设置指令 |
| 5 | 控制流（Control Flow） | 8 | `05_control_flow` | JMP、Jcc、CALL、RET、LOOP 等跳转与循环指令 |
| 6 | 字符串操作（String Operations） | 8 | `06_string_ops` | MOVS、STOS、LODS、CMPS、SCAS 及 REP 前缀 |
| 7 | 栈操作（Stack Operations） | 6 | `07_stack_ops` | PUSH、POP、ENTER、LEAVE 等栈管理指令 |
| 8 | 系统与杂项（System & Misc） | 7 | `08_system_misc` | SYSCALL、CPUID、RDTSC、NOP、HLT 等，DR0/DR7 硬件断点 |
| 9 | 浮点运算（FPU） | 8 | `09_fpu` | FLD、FST、FADD、FMUL、FDIV、FCOM 等 x87 指令 |
| 10 | SSE/SIMD（SIMD） | 10 | `10_sse_simd` | MOVAPS、ADDPS、MULPS、CVT* 等 SSE 指令，以及 VADDPS / VPMULLD / VFMADD231PS 等 **AVX / AVX2 / FMA** 指令，以及 VPADDD zmm / opmask 等 **AVX-512** 指令（Linux / Windows 版；macOS 机器不支持 AVX-512，未提供） |
| 11 | 高等数学与数学库（Calculus） | 7 | `11_calculus_mkl` | 数值微分/积分（梯形、辛普森、样条）与厂商数学库调用 |
| 12 | 数据表示（Data Representation） | 4 | `12_data_repr` | 补码、OF/CF 双视角溢出、IEEE 754 位级、16.16 定点数 |
| 13 | 异常处理（Exceptions / VEH） | 3 | `13_exceptions` | 除零 / INT3 / 空指针写的向量化异常捕获，CONTEXT 修改 |
| 14 | 多线程与同步（Threads & Sync） | 3 | `14_threads_sync` | CreateThread、LOCK 原子计数、CMPXCHG 自旋锁、伪共享 |

三侧的示例数量对照：

| 类别 | `examples/`（Windows） | `examples-macos/`（macOS） | `examples-linux/`（Linux） |
|------|----------------------|--------------------------|---------------------------|
| 01_data_movement | 7 | 7 | 7 |
| 02_arithmetic | 8 | 7 | 7 |
| 03_logic_bitwise | 5 | 4 | 4 |
| 04_comparison | 2 | 2 | 2 |
| 05_control_flow | 9 | 9 | 9 |
| 06_string_ops | 5 | 5 | 5 |
| 07_stack_ops | 3 | 3 | 3 |
| 08_system_misc | 5 | 4 | 4 |
| 09_fpu | **8**（+3：控制字/BCD/栈溢出） | 5 | 5 |
| 10_sse_simd | 9（含 `avx512_basics.asm`，本机实测） | 8 | 9（含 `avx512_basics.asm`，本机实测） |
| 11_calculus_mkl | 7（5 + 2 个排查脚手架） | 5 | 5 |
| 12_data_repr | 4（Windows 专属） | — | — |
| 13_exceptions | 3（Windows 专属） | — | — |
| 14_threads_sync | 3（Windows 专属） | — | — |
| `boot/`（QEMU 引导链） | 4（平台无关，QEMU 实测） | 同左 | 同左 |
| **合计** | **78 + 4 boot** | **59** | **60**（另有 AT&T 镜像 54，见上表） |

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
| [12 SIMD 进阶：AVX / AVX2 / FMA / AVX-512](docs/12_simd_avx.md) | VEX 三操作数、YMM 与 XCR0、vzeroupper、AVX2 整数质变、FMA 单次舍入、AVX-512 ZMM 与 opmask 掩码、运行时降级 | `10_sse_simd/avx_*` `avx2_*` `avx512_*` |
| [13 x87 FPU 与浮点运算](docs/13_x87_fpu.md) | ST0-ST7 栈机、控制字与四种舍入、fxam 与栈溢出、fbstp BCD | `09_fpu` |
| [14 数据表示与运算基础](docs/14_data_representation.md) | 补码、OF/CF 双视角溢出、IEEE 754 位级、16.16 定点 | `12_data_repr` |
| [15 实模式与保护模式](docs/15_real_protected_mode.md) | 段:偏移、主引导扇区、GDT/选择子/特权级、CR0.PE 切换 | `boot/01` `boot/stage1` `boot/02` |
| [16 分页与虚拟内存](docs/16_paging.md) | 两级页表 10-10-12、PDE/PTE 格式、TLB、#PF 与按需调页 | `boot/03` |
| [17 长模式：进入 64 位](docs/17_long_mode.md) | IA-32e、PAE+4级分页+EFER.LME+PG 切换序列、canonical 地址 | `boot/04` |
| [18 中断与异常](docs/18_interrupts_exceptions.md) | fault/trap/abort、IVT/IDT、8259A→APIC、Windows VEH/SEH | `13_exceptions` |
| [19 多核与原子同步](docs/19_multicore_atomic.md) | 数据竞争、LOCK、cmpxchg 自旋锁与 EAX 陷阱、内存序、伪共享 | `14_threads_sync` |
| [20 MASM ↔ NASM 对照与教材阅读指南](docs/20_masm_nasm.md) | 两大语法逐项对照、invoke 展开、DOS 教材示例现代化路径 | — |

学习路线：01–04 语言与内存模型 → 05–07 标志 / 调用约定 / 栈帧（核心硬骨头）→
08–09 调试与混合架构 → 10–11 跨平台移植 → 12 SIMD 进阶 →
13–14 x87 FPU 与数据表示（数值基础）→ 15–17 实模式/保护模式/分页/长模式
（配合 `boot/` 引导链，参考李忠两本书）→ 18–19 中断与多核同步（内核视角）
→ 20 MASM↔NASM 对照（衔接王爽/罗云彬/大学教材）；`09_fpu` 与 `10_sse_simd`
类别可在中级后随时穿插实践。

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
│   ├── 12_simd_avx.md            # SIMD 进阶：AVX / AVX2 / FMA / AVX-512
│   ├── 13_x87_fpu.md             # x87 FPU 与浮点运算
│   ├── 14_data_representation.md # 数据表示与运算基础
│   ├── 15_real_protected_mode.md # 实模式与保护模式
│   ├── 16_paging.md              # 分页与虚拟内存
│   ├── 17_long_mode.md           # 长模式：进入 64 位
│   ├── 18_interrupts_exceptions.md # 中断与异常
│   ├── 19_multicore_atomic.md    # 多核与原子同步
│   └── 20_masm_nasm.md           # MASM ↔ NASM 对照与教材阅读指南
├── boot/                         # QEMU 引导链（-f bin 裸二进制）
│   ├── build-boot.sh             # 汇编 + 制盘 + QEMU 无头运行 + 串口校验
│   ├── 01_mbr_hello.asm          # 实模式主引导扇区（段:偏移演示）
│   ├── stage1.asm                # 共享加载器（BIOS 扩展读 INT 13h AH=42h）
│   ├── 02_pm32.asm               # 进入 32 位保护模式（GDT / CR0.PE）
│   ├── 03_paging.asm             # 32 位两级分页（恒等 + 高端映射）
│   └── 04_long64.asm             # 完整 16→32→64 引导链（长模式）
├── lib/
│   ├── mac_io.inc                # macOS 输出辅助例程（%include 用）
│   └── linux_io.inc              # Linux 输出辅助例程（%include 用）
├── examples/                     # Windows 示例（-f win64）
│   ├── 01_data_movement/
│   ├── 02_arithmetic/
│   ├── ...
│   ├── 11_calculus_mkl/
│   ├── 12_data_repr/             # 补码 / 溢出 / IEEE 754 / 定点
│   ├── 13_exceptions/            # Windows VEH：除零 / int3 / 空指针写
│   └── 14_threads_sync/          # 原子计数 / cmpxchg 自旋锁 / 伪共享
├── examples-masm/                # MASM 版 Windows 示例（ml64，78 支全量镜像）
├── examples-att/                 # AT&T 版 Linux 示例（GNU as，54 支）
├── lib-att/                      # AT&T 版输出辅助库 att_io.s
├── build-masm.ps1                # MASM 版构建入口（ml64 -> link -> 运行）
├── build-att.sh                  # AT&T 版构建脚本（WSL/Linux 里跑）
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

### MASM 版（Windows）

```powershell
.uild-masm.ps1 -All                      # 全量 78 支：ml64 汇编 -> link -> 运行
.uild-masm.ps1 -Category 01_data_movement
```

### AT&T 版（WSL / Linux）

```bash
./build-att.sh                              # GNU as -> gcc -no-pie -> 运行
./build-att.sh 01                           # 只跑 01 类
```

### 引导链（QEMU）

```bash
cd boot
./build-boot.sh            # 汇编 + 制盘 + QEMU 无头运行 + 串口输出校验（01-04 全部）
./build-boot.sh 02         # 只跑 02_pm32（进保护模式）
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
