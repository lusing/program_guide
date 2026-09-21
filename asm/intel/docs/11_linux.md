# Linux 平台：工具链、调用约定与移植指南

本指南原本面向 Windows（`-f win64` + MSVC `link.exe`），后来加了 macOS（`-f macho64` + `clang`）。这一章说明**同一份汇编知识在 Linux 上怎么落地**，以及把现有示例搬到 Linux 需要改哪些地方、会踩哪些坑。

所有 `examples-linux/` 下的示例都已在本机（Arch Linux / WSL2 x86-64 / NASM 3.02 / GCC 16.2.1 / GNU ld 2.47 / glibc 2.44）**实际汇编、链接、运行通过**，共 56 个，见 [examples-linux/README.md](../examples-linux/README.md)。

---

## 1. 工具链

| 组件 | Linux | Windows（对照） | macOS（对照） |
|------|-------|----------------|---------------|
| 汇编器 | `nasm -f elf64` | `nasm -f win64` | `nasm -f macho64` |
| 目标文件 | `.o`（ELF 64 位） | `.obj`（COFF） | `.o`（Mach-O） |
| 链接器 | `ld` / `gcc`（驱动） | `link.exe` | `ld` / `clang`（驱动） |
| C 运行时 | **glibc**（crt1.o + libc.so） | msvcrt.lib + legacy_stdio_definitions.lib | libSystem |
| 符号前缀 | **无前缀**：`printf`、`main` | 无前缀 | **带下划线**：`_printf`、`_main` |
| 进程退出 | `ret` 返回 libc 启动代码（经 gcc 链接时） | `call ExitProcess` | `ret` 返回 libSystem 启动代码 |
| 直接系统调用 | `syscall`，**原生编号**（write=1、exit=60） | 一般不用 | `syscall`，`0x2000000 + N`（BSD 类） |
| 调试器 | `gdb` | x64dbg / WinDbg | `lldb` |
| 向量数学库 | **libmvec**（glibc ≥ 2.22，随 libm 发布） | Intel MKL | Accelerate.framework |
| 动态库 | `.so` | `.dll` | `.dylib` |

> Linux 和 macOS **共用 System V AMD64 调用约定**，所以第 6 章的传参规则、栈对齐、被调用者保存寄存器清单在 Linux 上原样适用。真正的差别集中在「链接方式、符号名、系统调用号」这三处。

---

## 2. 快速开始

单文件的最小流程：

```bash
# 1. 汇编（-I 指向辅助库目录，见下）
nasm -I lib -f elf64 examples-linux/01_data_movement/mov_basic.asm -o build/mov_basic.o

# 2. 链接（必须 -no-pie，见第 3 节）
gcc -no-pie build/mov_basic.o -o build/mov_basic

# 3. 运行
./build/mov_basic
```

用 `gcc` 而不是直接 `ld`，是因为它会自动补上 crt1.o（C 运行库启动代码）和 libc 搜索路径，并且 `main` 是被启动代码 `call` 进来的普通函数，结束时 `leave / ret` 即可（返回值在 `eax` 里就是进程退出码）。

纯系统调用程序（不碰 libc）可以直接用 `ld`，入口默认就是 `_start`：

```bash
nasm -f elf64 examples-linux/01_data_movement/test_link.asm -o build/test_link.o
ld build/test_link.o -o build/test_link        # 静态可执行文件，无任何库依赖
```

这一点比 macOS 省心：那边即使纯 syscall 程序也必须动态链接、必须 `-lSystem`，Linux 没有这个限制。

需要 libmvec 的示例，在链接行加 `-lm -lmvec`（见第 6 节）。

### build-linux.sh

```bash
./build-linux.sh -All                              # 汇编 + 链接 + 运行全部 Linux 示例
./build-linux.sh -Category 01_data_movement        # 只做某个类别
./build-linux.sh -File 01_data_movement/lea.asm    # 只做单个文件
./build-linux.sh -BuildOnly -All                   # 只构建不运行
./build-linux.sh -Clean                            # 清理 build/linux
```

判定标准是三条同时满足：nasm 退出码 0、链接退出码 0、运行退出码 0 且 stderr 为空。

脚本会自动选择链接方式：源文件里有 `extern ` 就用 `gcc -no-pie` 驱动（自动带 glibc 启动文件），否则用 `ld` 直连。示例还可以在注释里写一行 `; LINK: -lm -lmvec` 给链接器附加参数。

### lib/linux_io.inc —— 辅助输出库

和 `lib/mac_io.inc` 对应，`lib/linux_io.inc` 提供了一组例程（例程名用 `l_` 前缀，和 macOS 版的 `m_` 前缀区分）：

```asm
%include "linux_io.inc"     ; 写在文件末尾（顶层）

; 可用例程：
;   l_nl          输出换行
;   l_puts        rdi = 以 0 结尾的字符串
;   l_putchar     dil = 字符
;   l_putint      rdi = 有符号整数
;   l_putuint     rdi = 无符号整数
;   l_putbool     rdi = 0/1 → false/true
;   l_puthex      rdi = 值, rsi = 最少位数
;   l_putd / l_putg / l_putf   xmm0 = 浮点值
;   l_putflags    rdi = pushfq 取到的值 → 一行打出 CF PF AF ZF SF OF
;   l_putsep      输出空格
```

它是纯可选的，不用也完全没问题（`examples-linux` 里大多数示例就直接调 `printf`）。

---

## 3. 平台差异全景对照

### 3.1 调用约定

与 macOS 完全一致，详见 [调用约定](06_calling_convention.md) 的 System V 章节：`rdi rsi rdx rcx r8 r9` + `xmm0..7`、没有影子空间、`al` 记向量寄存器个数、`call` 时 `rsp` 16 字节对齐、`rbx rbp r12-r15` 被调用者保存。

### 3.2 指令与系统层面

| 主题 | Windows | macOS | Linux |
|------|---------|-------|-------|
| 入口点 | `global main` + `link /entry:main` | `global _main`（libSystem call 进来） | `global main`（gcc 链接，crt1.o call 进来）**或** `global _start`（ld 直连） |
| C 库符号 | `printf` | `_printf`（带下划线） | `printf` |
| 直接系统调用 | 一般不用 | `0x2000000 + N`（BSD 类） | **原生编号**：`write=1`、`exit=60`、`read=0`… |
| `main` 里能不能 `ret` | **不能**（栈上没返回地址） | **能** | **能**（经 gcc 链接时） |
| 可执行文件 | 静态链接也可 | **必须动态链接**（哪怕纯 syscall） | 两者皆可，纯 syscall 程序可以静态链接 |

Linux 上用 `syscall` 的例子（`01_data_movement/test_link.asm`）：

```asm
%define SYS_write 1
%define SYS_exit  60

    mov rax, SYS_write
    mov rdi, 1                  ; fd = stdout
    lea rsi, [msg]
    mov rdx, msglen
    syscall

    mov rax, SYS_exit
    xor rdi, rdi
    syscall
```

三个要点：

1. 编号是 x86-64 架构专用的（和 32 位 int 0x80 那套完全不同），完整的表在 `unistd_64.h` 或 `man 2 syscall` 里。
2. `syscall` 指令本身会**踩掉 `rcx` 和 `r11`**（分别存返回地址和标志位），循环里别把计数器放这两个寄存器。
3. 不同于 macOS 的 `0x2000000` 前缀 —— 两家编号互不兼容，这是系统调用代码不可移植的主因。

### 3.3 PIE：Linux 独有的最大坑

现代发行版的 `gcc` **默认生成 PIE**（位置无关可执行文件），而 NASM 源码里常见的绝对重定位（如 `mov rsi, msg`、NASM 在 `-f elf64` 下为非 `default rel` 代码生成的绝对地址）在 PIE 下编不过：

```
/usr/bin/ld: mov_basic.o: relocation R_X86_64_32S against `.data' can not be used
when making a PIE object; recompile with -fPIC
```

**修法：链接时一律加 `-no-pie`**：

```bash
gcc -no-pie foo.o -o foo
```

本指南的 Linux 示例统一用 `default rel` + `lea rdi,[标签]` 的 RIP 相对写法，配合 `-no-pie` 行为完全确定。想编真正的 PIE 也可以（`-fPIC` 风格的代码 + 正常 gcc 链接），但那要改写法，不属于本指南范围。

---

## 4. 移植规则

### 从 macOS 版到 Linux 版（本目录的实际做法）

`examples-linux/` 就是从 `examples-macos/` 系统改写来的，规则只有六条：

| # | 改写 | 例子 |
|---|------|------|
| 1 | 汇编格式 `macho64` → `elf64` | `nasm -f elf64` |
| 2 | 符号去掉下划线 | `extern _printf` → `extern printf`，`global _main` → `global main`，`call _printf` → `call printf` |
| 3 | 辅助库换名换前缀 | `%include "mac_io.inc"` → `%include "linux_io.inc"`，`m_puts` → `l_puts` |
| 4 | 链接驱动换参数 | `clang -arch x86_64` → `gcc -no-pie` |
| 5 | 系统调用号换成 Linux 原生 | `0x2000004` → `1`，`0x2000001` → `60` |
| 6 | 注释里的平台名同步 | `[macOS 版]` → `[Linux 版]` 等 |

由于 System V 调用约定两边相同，**指令主体一个字都不用改**。

### 从 Windows 版直接移植

第 10 章 [macOS 移植指南](10_macos_porting.md) 的「四条铁律」全部适用（参数寄存器、保护 `rbx`/`r12`–`r15`、无影子空间、浮点从 `xmm0` 重新数），只是把「符号加下划线」那条**反过来**：Linux 和 Windows 一样**不加**下划线。

---

## 5. 各类别的移植要点

| 类别 | 改动量 | 要点 |
|------|--------|------|
| 01 数据传送 | 极小 | 符号去下划线；`test_link.asm` 的 syscall 号换成 `1`/`60`，入口改 `_start` |
| 02 算术运算 | 极小 | 同上，纯寄存器操作 |
| 03 逻辑位运算 | 极小 | 同上 |
| 04 比较测试 | 极小 | 同上 |
| 05 控制流 | 极小 | `call_ret.asm` 的参数寄存器同样从 `rcx rdx r8 r9` 换成 `rdi rsi rdx rcx` |
| 06 字符串操作 | 小 | RSI/RDI/RCX 在 SysV 是调用者保存，字符串指令后 printf 参数重装即可 |
| 07 栈操作 | 小 | `ENTER/LEAVE` 一样；`pushfq/popfq` 例子更简单（5 个参数全在寄存器） |
| 08 系统杂项 | 小 | `CPUID` 会踩 `EBX` —— 取完必须还原，否则 `main` 返回时 `__libc_start_main` 崩 |
| 09 浮点 FPU | 小 | x87 指令完全一样 |
| 10 SSE/SIMD | 小 | 指令一样，内存操作数 16 字节对齐的要求一样 |
| 11 高等数学 | **中** | MKL → **libmvec**（见第 6 节），SSE 手写版原样保留 |

---

## 6. 第 11 类：MKL 在 Linux 上换成 libmvec

| 用途 | Windows | Linux |
|------|---------|-------|
| 批量 sin/cos/exp | MKL VML：`vsSin(n, a, y)` | libmvec：`_ZGVbN4v_sinf` 等 |
| 向量规约 | MKL VSL / 手写 | **没有归约函数**，SSE 手写 |
| 线性代数 | MKL BLAS / LAPACK | OpenBLAS / LAPACK（本指南未用） |
| 样条（Data Fitting） | MKL DF：`dfdConstruct1D` 等 | **没有对应 API**，照旧手写（`spline_integrate.asm`） |

**坑一：libmvec 不传指针，传 xmm0。** 和 MKL（`n, 输入, 输出` 三个参数）、vForce（`输出, 输入, &n`）都不同，glibc 的向量函数按 Intel Vector ABI 把**向量参数按值放在向量寄存器里**：

```
_ZGVbN4v_sinf:  xmm0 = 4 个 float（打包输入）→  xmm0 = 4 个结果
```

一次调用只处理一个向量寄存器的宽度，1024 个点的数组要自己写循环：

```asm
.vloop:
    movups xmm0, [rbx + r13*4]      ; 装 4 个输入
    call _ZGVbN4v_sinf              ; 结果在 xmm0 里回来
    movups [r12 + r13*4], xmm0      ; 存回 4 个结果
    add r13d, 4
    cmp r13d, N
    jb .vloop
```

**坑二：函数名是改编（mangled）的。** `_ZGV<isa>N<lanes><参数串>_<函数名>`：

| 名字 | isa | 宽度 | 含义 |
|------|-----|------|------|
| `_ZGVbN4v_sinf` | b = SSE4 基线 | 4 个 float | `v` = 一个向量参数（按值，走 xmm0） |
| `_ZGVdN8v_sinf` | d = AVX2 | 8 个 float | ymm0 |
| `_ZGVe16v_sinf` | e = AVX-512 | 16 个 float | zmm0 |

本指南的 SIMD 章节用 SSE，示例固定调 `_ZGVbN4v_*`（任何 x86-64 都能跑；AVX2 版把 `xmm` 写宽成 `ymm`、N4 换成 N8 即可）。这些符号是 IFUNC（按 CPU 特性在加载时选实现），**声明成普通 extern 直接 call 就行**，加载器会自动解析。

**坑三：链接要带 `-lmvec`。** libmvec 是独立于 libc/libm 的库，示例用 `; LINK: -lm -lmvec` 声明（`build-linux.sh` 读到后附在 gcc 命令行末尾）。

**坑四：没有归约函数。** vDSP_maxv 那种「求数组最大值」，libmvec 没有对应物 —— `accelerate_vforce.asm` 第 5 节用 SSE 手工归约（maxps 扫一遍 + shufps 水平归约），和恒等式校验那段是同一个套路。

完整可运行的 libmvec 调用见 `examples-linux/11_calculus_mkl/accelerate_vforce.asm`。

---

## 7. 踩坑清单（都是真踩过的）

| 症状 | 原因 | 修法 |
|------|------|------|
| `relocation R_X86_64_32S ... recompile with -fPIC` | 发行版 gcc 默认 PIE，NASM 的绝对重定位编不进 PIE | 链接加 `-no-pie` |
| 段错误 139，崩溃点在 `__libc_start_main` 里 | 破坏了 `rbx`/`r12`–`r15`，`main` 返回后 libc 启动代码用到坏值 | 进函数先备份、退场还原 |
| 调 libmvec 的循环死转 / 结果全 0 | 循环计数器放在 `rcx`，被 `_ZGVbN4v_*` 踩掉 | 计数器用 `r13` 等被调用者保存寄存器 |
| libmvec 调用后内存纹丝不动 | 误以为参数是 (out, in) 指针 | 输入走 xmm0、输出也在 xmm0（见第 6 节） |
| 输出一个莫名其妙的巨大数字 | `printf` 的返回值（`eax`）把 `rax` 冲掉了 | 用之前重新装 `rax` |
| 打出来的浮点全是 0 或互相串味 | 想用 `xmm4`–`xmm7` 跨 `printf` 保存浮点值 | 落栈（xmm 全是调用者保存） |
| 段错误落在 `andps`/`movaps`/`maxps` 上 | SSE 的内存操作数没 16 字节对齐 | 常量前面写 `align 16` |
| `symbol ... not defined` | 从 macOS 抄代码忘了去下划线 | `extern printf`、`global main` |

---

## 8. 在 Linux 上调试汇编

用 `gdb`（发行版包管理器安装，如 `pacman -S gdb`）。

```bash
# 汇编时带 DWARF 调试信息（-g -F dwarf）
nasm -I lib -f elf64 -g -F dwarf examples-linux/05_control_flow/cmov.asm -o build/cmov.o
gcc -no-pie -g build/cmov.o -o build/cmov

# 非交互式：跑一遍、看回溯
gdb -batch -ex run -ex bt -ex quit ./build/cmov

# 交互式
gdb ./build/cmov
```

gdb 里最常用的命令：

| 命令 | 作用 |
|------|------|
| `run` / `r` | 运行 |
| `bt` | 打印调用栈（判断崩溃是否发生在 `__libc_start_main` 里特别有用） |
| `info registers rax rbx rcx rip rsp rbp` | 看寄存器 |
| `x/8gx $rsp` | 看栈内容 |
| `disas` | 反汇编当前函数 |
| `stepi` / `si`、`nexti` / `ni` | 单步进入 / 单步越过（逐指令） |
| `b *0x401000`、`b main` | 下断点 |
| `p/x $rax` | 打印寄存器值（十六进制） |
| `c` | 继续 |

崩溃时的典型诊断流程：

```
(gdb) run
Program received signal SIGSEGV, Segmentation fault.
0x00007ffff7e3a2b4 in __libc_start_main () from /usr/lib/libc.so.6
(gdb) bt
(gdb) info registers rbx r12 r13
```

如果栈顶是 `__libc_start_main`，基本可以直接断定是「被调用者保存寄存器没还原」；如果落在 `strlen` 之类的 libc 函数里，基本是「printf 参数与格式串错位，数字被当成指针」。

---

## 9. 验证记录

```
$ ./build-linux.sh -All
...
==========================================
  构建汇总: 总计 56 个, 通过 56 个, 失败 0 个
==========================================
```

环境：

| 项目 | 值 |
|------|-----|
| OS | Arch Linux（WSL2，内核 6.18.33，x86_64） |
| NASM | 3.02 |
| gcc | 16.2.1 |
| ld | GNU ld（binutils 2.47） |
| glibc | 2.44（含 libmvec 2.44） |
| CPU | 支持 SSE4.2 / AVX2 / FMA（本指南示例只用 SSE，任何 x86-64 可跑） |

---

> 上一篇：[macOS 平台移植指南](10_macos_porting.md) ｜ 返回 [首页](../README.md)
