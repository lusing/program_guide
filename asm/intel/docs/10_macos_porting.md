# macOS 平台：工具链、调用约定与移植指南

本指南原本只面向 Windows（`-f win64` + MSVC `link.exe`）。这一章说明**同一份汇编知识在 macOS 上怎么落地**，以及把现有示例搬到 macOS 需要改哪些地方、会踩哪些坑。

所有 `examples-macos/` 下的示例都已在本机（macOS 13.1 / Intel i7-3520M Ivy Bridge / NASM 3.02 / clang 14.0.0 / ld64-820.1）**实际汇编、链接、运行通过**，共 56 个，见 [examples-macos/README.md](../examples-macos/README.md)。

---

## 1. 工具链

| 组件 | macOS | Windows（对照） |
|------|-------|----------------|
| 汇编器 | `nasm -f macho64` | `nasm -f win64` |
| 目标文件 | `.o`（Mach-O 64 位） | `.obj`（COFF） |
| 链接器 | `ld` / `clang`（驱动） | `link.exe` |
| C 运行时 | **libSystem**（统一了 libc / libm / libpthread…） | msvcrt.lib + legacy_stdio_definitions.lib |
| 进程退出 | `ret` 返回 libSystem 的启动代码 | `call ExitProcess` |
| 动态库 | `.dylib` | `.dll` |
| 段名 | `__TEXT` / `__DATA` / `__RODATA` | `.text` / `.data` / `.rdata` |
| 符号前缀 | **全部带下划线**：`_printf`、`_main` | 无前缀：`printf`、`main` |
| 调试器 | `lldb` | x64dbg / WinDbg |
| 数学库 | **Accelerate.framework**（vForce / vDSP / BLAS） | Intel MKL |

> NASM 的 `section .rodata` / `section .data` / `section .bss` 写法在 `-f macho64` 下**照旧可用**，NASM 会自动映射到 Mach-O 的 `__TEXT,__const` / `__DATA,__data` / `__DATA,__bss`。所以大多数示例的段声明一行都不用改。

---

## 2. 快速开始

单文件的最小流程：

```bash
# 1. 汇编（-I 指向辅助库目录，见下）
/opt/local/bin/nasm -I lib -f macho64 examples-macos/01_data_movement/mov_basic.asm -o build/mov_basic.o

# 2. 链接（clang 驱动会自动带上 libSystem）
clang -arch x86_64 build/mov_basic.o -o build/mov_basic

# 3. 运行
./build/mov_basic
```

用 `clang` 而不是直接 `ld`，是因为它会自动补上 `-lSystem` 和 SDK 搜索路径。如果你坚持手写 `ld`：

```bash
SDK="$(xcrun --show-sdk-path)"
ld -arch x86_64 -macosx_version_min 11.0 -e _main build/mov_basic.o -o build/mov_basic \
   -lSystem -syslibroot "$SDK" -L"$SDK/usr/lib"
```

**注意 `-lSystem` 不是可选的**：macOS 的可执行文件必须是动态链接的，哪怕你一个库函数都不调（纯系统调用），少了它 `ld` 会直接报
`dynamic executables or dylibs must link with libSystem.dylib`。

需要 Accelerate.framework 的示例，在链接行加 `-framework Accelerate`（见第 6 节）。

### build-mac.sh

```bash
./build-mac.sh -All                              # 汇编 + 链接 + 运行全部 macOS 示例
./build-mac.sh -Category 01_data_movement        # 只做某个类别
./build-mac.sh -File 01_data_movement/lea.asm    # 只做单个文件
./build-mac.sh -BuildOnly -All                   # 只构建不运行
./build-mac.sh -Clean                            # 清理 build/mac
```

判定标准是三条同时满足：nasm 退出码 0、链接退出码 0、运行退出码 0 且 stderr 为空。

脚本会自动选择链接方式：源文件里有 `extern _` 就用 `clang` 驱动（自动带 libSystem），否则用 `ld` 直连。示例还可以在注释里写一行 `; LINK: -framework Accelerate` 给链接器附加参数。

### lib/mac_io.inc —— 辅助输出库

Windows 版每个示例都手写 `mov rdx, ... / mov r8, ...` 那一套 CRT 传参。为了让 macOS 示例的输出代码保持可读，`lib/mac_io.inc` 提供了一组例程：

```asm
%include "mac_io.inc"       ; 写在文件末尾（顶层）

; 可用例程：
;   m_nl          输出换行
;   m_puts        rdi = 以 0 结尾的字符串
;   m_putchar     dil = 字符
;   m_putint      rdi = 有符号整数
;   m_putuint     rdi = 无符号整数
;   m_putbool     rdi = 0/1 → false/true
;   m_puthex      rdi = 值, rsi = 最少位数
;   m_putd / m_putg / m_putf   xmm0 = 浮点值
;   m_putflags    rdi = pushfq 取到的值 → 一行打出 CF PF AF ZF SF OF
;   m_putsep      输出空格
```

它是纯可选的，不用也完全没问题（`examples-macos` 里大多数示例就直接调 `_printf`）。

---

## 3. 平台差异全景对照

### 3.1 调用约定

| 项目 | System V AMD64（macOS / Linux） | Windows x64 |
|------|-------------------------------|-------------|
| 整数/指针参数 | `rdi rsi rdx rcx r8 r9`，第 7 个起走栈 | `rcx rdx r8 r9`，第 5 个起走栈 |
| 浮点参数 | `xmm0 … xmm7`，**编号独立于整数参数** | `xmm0 … xmm3`，**与整数参数共享位置序号** |
| 可变参数 | `al` = 用到的 xmm 寄存器个数 | 同上，但浮点参数还要在对应通用寄存器里放一份 |
| 影子空间 | **没有** | 调用者预留 32 字节 |
| 返回值 | 整数 `rax/rdx`，浮点 `xmm0/xmm1` | 相同 |
| 栈对齐 | `call` 时 `rsp` 必须是 16 的整数倍 | 相同 |
| 被调用者保存 | `rbx rbp r12 r13 r14 r15` | 相同 |
| 方向标志 | 进出函数时 DF 必须为 0 | 相同 |

最直观的例子是「打印一个 `"%d %f"`」：

```asm
; ---- Windows x64 ----
lea rcx, [fmt]              ; 第 1 个参数走 RCX
mov edx, 42                 ; 第 2 个参数（整数）走 RDX
movsd xmm1, [value]         ; 同一个位置还得在 XMM1 里放一份浮点
mov rdx, [value]            ; 而且 RDX 里也要放位模式，双写！
call printf

; ---- macOS（SysV）----
lea rdi, [fmt]              ; 第 1 个参数走 RDI
mov esi, 42                 ; 整数参数照常排
movsd xmm0, [value]         ; 浮点参数从 xmm0 开始，互不干扰
mov eax, 1                  ; 用了 1 个向量寄存器
call _printf
```

另一个典型是「5 个寄存器的 printf」：

```asm
; ---- Windows：第 5 个参数以上只能走栈，还得自己算偏移 ----
sub rsp, 48                        ; 32 影子 + 8 第 5 参数 + 8 对齐
mov dword [rsp+32], r9d
call printf

; ---- macOS：rdi rsi rdx rcx r8 刚好装下 5 个 ----
mov r8d, ...
call _printf                       ; 一个字节栈都不用碰
```

### 3.2 指令层面

绝大多数指令在两平台**完全一致**（它们是 CPU 指令，不是操作系统 API）。真正不同的是这几处：

| 主题 | Windows | macOS |
|------|---------|-------|
| 进程退出 | `xor ecx,ecx` / `call ExitProcess` | `xor eax,eax` / `leave` / `ret` |
| 入口点 | `global main` + `link /entry:main` | `global _main`（由 libSystem 启动代码 call 进来） |
| 直接系统调用 | 一般不用（走 ntdll/kernel32） | `syscall`，号是 `0x2000000 + N`（BSD 约定） |
| 字符串函数 | `strlen` / `printf` | `_strlen` / `_printf` |
| `main` 里能不能 `ret` | **不能**（栈上没返回地址） | **能**（栈上真有返回地址） |

macOS 上用 `syscall` 的例子（`01_data_movement/test_link.asm`）：

```asm
%define SYS_write 0x2000004
%define SYS_exit  0x2000001

    mov rax, SYS_write
    mov rdi, 1                  ; fd = stdout
    lea rsi, [msg]
    mov rdx, msglen
    syscall

    mov rax, SYS_exit
    xor rdi, rdi
    syscall
```

`0x2000000` 这个高位前缀是 XNU 内核用来区分「BSD 系统调用」和「Mach 陷阱」的。

---

## 4. 移植四条铁律（外加两条）

把 Windows 示例搬到 macOS，出错几乎总是下面这几条之一。

### 铁律 1：参数寄存器换成 `rdi rsi rdx rcx r8 r9`

不只是改寄存器名。`printf` 的格式串字段顺序必须**严格对应**参数寄存器顺序 —— 一旦错位，轻则打错值，重则 `_platform_strlen` 拿着一个数字当指针去解引用，直接 `EXC_BAD_ACCESS`。

### 铁律 2：绝对不能破坏 `rbx` / `r12`–`r15`

这条是 macOS 上最容易踩的。原因：

- Windows 版用 `/entry:main` 把 `main` 当作**进程真正的入口**，所以 `main` 里**不能用 `ret`**，必须 `call ExitProcess` 收场 —— 于是破坏 `rbx` 也看不出问题（进程直接退了）。
- macOS 版 `_main` 是**被 libSystem 的启动代码 call 进来的**，所以老老实实 `leave / ret`。一旦 `rbx`/`r12`–`r15` 被改坏，`ret` 之后 dyld 立刻用坏掉的 `rbx` 去访存并崩溃，报错长这样：

```
dyld`dyld4::start(...) + 465: movq 0x8(%rbx), %rax
EXC_BAD_ACCESS (SIGSEGV)
```

对应的写法（几乎所有 `examples-macos` 示例都有这段）：

```asm
_main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-8],  rbx          ; 打算借用的被调用者保存寄存器，
    mov [rbp-16], r12          ; 一律先进栈备份，
    mov [rbp-24], r13          ; 退场前原样还原
    ...
    mov rbx, [rbp-8]
    mov r12, [rbp-16]
    mov r13, [rbp-24]
    xor eax, eax
    leave
    ret
```

`leave`（= `mov rsp,rbp` + `pop rbp`）会先把 `rsp` 恢复，所以在 `leave` 之前从帧里取回数据是安全的。

### 铁律 3：C 库符号全部加下划线，入口是 `_main`

```asm
global _main
extern _printf
extern _malloc
```

Mach-O 的符号表约定：C 函数名前面统一有个 `_`。所以源码里的 `printf` 在目标文件里叫 `_printf`。

### 铁律 4：`printf` 会破坏 `rax` 和所有调用者保存寄存器

`printf` **返回打印的字符数，就放在 `eax` 里**，同时会随手踩掉 `rcx rdx rsi rdi r8-r11` 和**所有 xmm 寄存器**。所以：

- 跨 `printf` 要活下来的整数放 `rbx`/`r12`–`r15`（并记得备份还原），或直接落栈；
- 跨 `printf` 要活下来的浮点值**必须落栈** —— 没有「被调用者保存的 xmm 寄存器」这回事。

一个真实翻车案例（`01_data_movement/bswap.asm`）：

```asm
    mov rax, 0x123456789ABCDEF0
    bswap rax
    ; 打印...
    call _printf                ; ← eax 变成「打印了几个字符」
    bswap rax                   ; ← 于是这次 bswap 转的是垃圾
```

修法是**重新装一遍**再转：

```asm
    mov rax, 0x123456789ABCDEF0
    bswap rax
```

### 附加 1：没有影子空间，别多预留

Windows 示例里 `sub rsp, 32` 往往一半是为了影子空间。SysV 不需要，同样的 `sub rsp, 32` 就纯粹是局部变量空间了 —— 留着无害，但理解它「为什么在」很重要。

### 附加 2：浮点参数从 `xmm0` 重新数

SysV 里整数和浮点的寄存器编号**各自独立**。`printf("%f %f", a, b)` 是 `xmm0 = a`、`xmm1 = b`，而不是像 Windows 那样要按参数位置算成 `xmm1`、`xmm2`。

---

## 5. 各类别的移植要点

| 类别 | 改动量 | 要点 |
|------|--------|------|
| 01 数据传送 | 小 | 只需保护 `rbx`/`r12`–`r15`；`push_pop.asm` 里 `r10/r11` 会被 `printf` 破坏，差值要立刻落栈 |
| 02 算术运算 | 小 | `DIV`/`IDIV` 的余数固定在 `RDX` —— 而这正是 SysV 第 3 个参数寄存器，装参数时注意顺序 |
| 03 逻辑位运算 | 小 | `ROL/ROR` 在**操作数宽度内**转圈：注释按 32 位写就得用 `rol eax,4`，用 `rol rax,4` 不回绕 |
| 04 比较测试 | 极小 | 纯寄存器操作 |
| 05 控制流 | 小 | `call_ret.asm` 里自定义函数的参数从 `rcx rdx r8 r9` 换成 `rdi rsi rdx rcx`；`_main` 用 `ret` |
| 06 字符串操作 | 中 | `RSI`/`RDI`/`RCX` 既是字符串指令操作数又是参数寄存器 → **每条字符串指令后 printf 参数必须重装**；好消息是 SysV 里 RSI/RDI 是调用者保存，不必像 Windows 那样 push 保护 |
| 07 栈操作 | 中 | `ENTER/LEAVE` 指令本身两平台一样；`pushfq/popfq` 例子在 macOS 上反而更简单（5 个参数全在寄存器里，`popfq` 之后还能用 `jc` 真跳一次做验证） |
| 08 系统杂项 | 小 | `CPUID` 会踩 `EBX`，而 EBX 是被调用者保存寄存器 —— 取完所有 CPUID 必须还原，否则 `_main` 返回时 dyld 崩溃 |
| 09 浮点 FPU | 小 | x87 指令完全一样，只是传参要改成 `movsd xmm0, [mem]` + `mov eax,1` |
| 10 SSE/SIMD | 小 | 指令一样。注意 `andps/maxps/subps` 等**内存操作数必须 16 字节对齐** |
| 11 高等数学 | **大** | 见第 6 节 |

---

## 6. 第 11 类的两个特殊问题

### 6.1 AVX2 / FMA 不是所有机器都有

原版第 11 类用 AVX2（`ymm`，一次 8 个 float）和 FMA（`vfmadd231ps`）。这两样是 **Haswell（2013）之后**才有的：

- Intel：Haswell 及以后支持 AVX2 + FMA3
- AMD：Excavator / Zen 及以后

判断方法就是第 8 类的 `CPUID`（`08_system_misc/cpuid_hybrid.asm` 已经演示了）：

```asm
    mov eax, 0
    cpuid                       ; EAX = 最大页号
    cmp eax, 7
    jb  .no_avx2                ; 没有页 7，肯定没有 AVX2

    mov eax, 7
    xor ecx, ecx
    cpuid                       ; EBX 位图
    bt  ebx, 5                  ; bit 5 = AVX2
    jnc .no_avx2
```

本机（Ivy Bridge）的探测结果就是：最大页号 `0xD`、无页 `0x1A`、`AVX2: NO`、`AVX-512: NO`。

所以 `examples-macos/11_calculus_mkl/` 里的 SIMD 示例**改用 SSE 4 路**，算法、数据布局、结论完全一致。真正的差别只有两处：

| 写法 | AVX2 | SSE |
|------|------|-----|
| 广播常数到所有通道 | `vbroadcastss ymm0, [mem]` 一条 | `movss xmm0,[mem]` + `shufps xmm0,xmm0,0` |
| 4×float 水平求和 | `vextractf128` + `vhadde`/`vhaddps` | 两次 `shufps` + `addps` |
| 错位加载做差分 | `vmovups ymm` | `movups xmm` |

把 `xmm` 写宽成 `ymm`、加上 `v` 前缀，就是 AVX2 版本。

### 6.2 MKL 在 macOS 上换成 Accelerate

| 用途 | Windows | macOS |
|------|---------|-------|
| 批量 sin/cos/exp | MKL VML：`vsSin(n, a, y)` | vForce：`vvsinf(y, x, &n)` |
| 向量规约 | MKL VSL / 手写 | vDSP：`vDSP_maxv(A, stride, C, n)` |
| 线性代数 | MKL BLAS / LAPACK | vecLib 的 BLAS / LAPACK |
| 样条（Data Fitting） | MKL DF：`dfdConstruct1D` 等 | **没有对应 API** |

**坑一：参数顺序三家三样。** 都在 Accelerate 里边，风格却完全不统一：

```
MKL      vsSin(n, in, out)                  长度在前，输出在后
vForce   vvsinf(out, in, &n)                输出在前，长度用**指针**传
vDSP     vDSP_maxv(in, stride, out, n)      输入、步长、输出、长度 —— 输出夹在第三个
```

只能逐个查头文件。头文件位置：

```bash
SDK="$(xcrun --show-sdk-path)"
$SDK/System/Library/Frameworks/Accelerate.framework/Frameworks/vecLib.framework/Headers/vForce.h
$SDK/System/Library/Frameworks/Accelerate.framework/Frameworks/vecLib.framework/Headers/vDSP.h
```

**坑二：`n` 是按值还是按指针。** vForce 要 `const int *n`，所以是 `lea rdx,[n]`；vDSP 的 `vDSP_Length` 是 `unsigned long`，直接 `mov ecx, n`。

**坑三：没有样条 API。** vecLib 里有 vDSP 的二次插值 `vDSP_vqint`、有 Quadrature 的自适应积分 `quadrature_integrate`，但没有 MKL DF 那种 pp-form 样条构造。`examples-macos/11_calculus_mkl/spline_integrate.asm` 的做法是**把它手写出来**：组装三对角方程组 → Thomas 算法解 `M_i = S''(x_i)` → 分段求值。手写反而更能看清那条 API 背后在算什么，而且这份代码在 Windows 上原样可编译。

完整可运行的 vForce/vDSP 调用见 `examples-macos/11_calculus_mkl/accelerate_vforce.asm`。

---

## 7. 踩坑清单（都是真踩过的）

| 症状 | 原因 | 修法 |
|------|------|------|
| 段错误 139，崩溃点在 `dyld` 里 | 破坏了 `rbx`/`r12`–`r15`，`_main` 返回后 dyld 用到坏值 | 进函数先备份、退场还原 |
| `ld: dynamic executables or dylibs must link with libSystem.dylib` | 纯 `syscall` 程序也想绕过 libSystem | 照样加 `-lSystem` |
| 输出一个莫名其妙的巨大数字 | `printf` 的返回值（`eax`）把 `rax` 冲掉了 | 用之前重新装 `rax` |
| `EXC_BAD_ACCESS address=0x60`，栈里有 `_platform_strlen` | printf 参数与格式串字段错位，数字被当成指针 | 严格按 `rdi rsi rdx rcx` 顺序对字段 |
| 打出来的值全是 0 或互相串味 | 想用 `xmm4`–`xmm7` 跨 `printf` 保存浮点值 | 落栈（xmm 全是调用者保存） |
| `EXC_BAD_ACCESS` 落在 `andps`/`movaps`/`maxps` 上 | SSE 的内存操作数没 16 字节对齐 | 常量前面写 `align 16` |
| `movaps` 崩在数组上 | 用 `movaps` 读了 4 字节偏移（不可能对齐）的地址 | 错位加载一律用 `movups` |
| `ROL/ROL` 结果和注释对不上 | 循环移位在操作数宽度内回绕，32 位注释配了 64 位指令 | 改成 `rol eax,4` 或把位宽写对 |
| `%warning: byte data exceeds bounds` | 数据定义超出预期 | 检查 `dd`/`dq`/`times` 的宽度 |
| `symbol ... not defined` | 忘了下划线 | `extern _printf` |

---

## 8. 在 macOS 上调试汇编

用 `lldb`（Xcode Command Line Tools 自带，`/usr/bin/lldb`）。

```bash
# 汇编时带调试信息
nasm -I lib -f macho64 -g examples-macos/05_control_flow/cmov.asm -o build/cmov.o
clang -arch x86_64 -g build/cmov.o -o build/cmov

# 非交互式：跑一遍、看回溯
lldb -b -o "run" -o "bt" -o "quit" ./build/cmov

# 交互式
lldb ./build/cmov
```

lldb 里最常用的命令：

| 命令 | 作用 |
|------|------|
| `run` / `r` | 运行 |
| `bt` | 打印调用栈（判断崩溃是否发生在 dyld 里特别有用） |
| `register read rip rsp rbp rax rbx` | 看寄存器 |
| `register read --all` | 看全部寄存器 |
| `memory read --format x --size 8 --count 4 $rsp` | 看栈内容 |
| `x/8gx $rsp` | `gdb` 风格的看内存（lldb 也认） |
| `disassemble` / `di -f` | 反汇编当前函数 |
| `si` / `ni` | 单步进入 / 单步越过 |
| `b *0x100001234` | 在地址下断点 |
| `b _main` | 在符号上下断点 |
| `p $rax` | 打印寄存器值 |
| `c` | 继续 |
| `thread step-inst` | 逐条指令 |

崩溃时的典型诊断流程：

```
(lldb) run
Process stopped
* thread #1, stop reason = EXC_BAD_ACCESS (code=1, address=0x900065050)
    frame #0: 0x00007ff81523d730 libvDSP.dylib`...
(lldb) bt
(lldb) register read rip rsi rdx rcx
```

如果 `frame #0` 落在 `dyld` 里，基本可以直接断定是「被调用者保存寄存器没还原」；如果落在某个 `_platform_*` 或 `_strlen` 里，基本是「printf 参数与格式串错位」。

---

## 9. 验证记录

```
$ ./build-mac.sh -All
...
==========================================
  构建汇总: 总计 56 个, 通过 56 个, 失败 0 个
==========================================
```

环境：

| 项目 | 值 |
|------|-----|
| OS | macOS 13.1 (Darwin x86_64) |
| CPU | Intel Core i7-3520M（Ivy Bridge，Family 6 / Model 58 / Stepping 9） |
| 指令集 | SSE / SSE2 / SSE3 / SSE4.1 / SSE4.2 / AES / AVX1.0；**无 AVX2、无 FMA、无 BMI** |
| NASM | 3.02（`/opt/local/bin/nasm`） |
| clang | 14.0.0 |
| ld | ld64-820.1 |
| SDK | MacOSX.sdk（13.x） |

---

> 上一篇：[调试方法](08_debugging.md) ｜ 返回 [首页](../README.md)
