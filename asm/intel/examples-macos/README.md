# macOS 示例集

`examples/` 是 Windows 版（`-f win64` + MSVC `link.exe`），本目录是**同样 11 个类别的 macOS 版**：`-f macho64` + `clang`（自动带 libSystem）。

**56 个示例全部在本机实际汇编、链接、运行通过**（macOS 13.1/clang 14 与 macOS 14.8.9/clang 16 两套 Intel 配置各跑一遍，都是 56/56）。

> 移植到本目录时最容易翻车的一条：**取数据地址必须写 `lea rsi, [label]`，不能写 `mov rsi, label`**。
> macOS 可执行文件默认 PIE，后者会编出绝对重定位，链接阶段报
> `ld: illegal text-relocation in '_main'+0xNN to 'label'`；而同样的写法在 Windows（非 PIE）
> 和 Linux（脚本用 `gcc -no-pie`）都能过。详见 [docs/10_macos_porting.md](../docs/10_macos_porting.md) 的铁律 5。

```bash
../build-mac.sh -All                              # 全部构建并运行
../build-mac.sh -Category 05_control_flow         # 单个类别
../build-mac.sh -File 05_control_flow/cmov.asm    # 单个文件
```

平台差异、移植规则和踩坑清单见 **[docs/10_macos_porting.md](../docs/10_macos_porting.md)**。

---

## 与 Windows 版的对应关系

| 类别 | 个数 | 对应 `examples/` | 移植要点 |
|------|------|-----------------|---------|
| [01_data_movement](#01_data_movement) | 7 | 同名 | 保护 `rbx`/`r12`–`r15` |
| [02_arithmetic](#02_arithmetic) | 7 | 同名 | `RDX` 被 `DIV` 占用 |
| [03_logic_bitwise](#03_logic_bitwise) | 4 | 同名 | 循环移位的位宽 |
| [04_comparison](#04_comparison) | 2 | 同名 | — |
| [05_control_flow](#05_control_flow) | 9 | 同名 | 自定义函数参数改寄存器 |
| [06_string_ops](#06_string_ops) | 5 | 同名 | 字符串指令后重装参数 |
| [07_stack_ops](#07_stack_ops) | 3 | 同名 | `ENTER`/`LEAVE` 指令一样 |
| [08_system_misc](#08_system_misc) | 4 | 同名 | `CPUID` 会踩 `EBX` |
| [09_fpu](#09_fpu) | 5 | 同名 | x87 指令完全一样 |
| [10_sse_simd](#10_sse_simd) | 5 | 同名 | 常量要 `align 16` |
| [11_calculus_mkl](#11_calculus_mkl) | 5 | `avx2_*` / `mkl_*` | AVX2→SSE，MKL→Accelerate |

`examples/11_calculus_mkl/` 里的 `test_align.asm`、`test_simpson_min.asm` 是 Windows 版的排查脚手架（当时用来定位对齐问题），不是教学内容，所以没有移植。

---

## 01_data_movement

数据传送指令：MOV、MOVZX/MOVSX、LEA、XCHG、BSWAP、PUSH/POP。

| 文件 | 内容 |
|------|------|
| `mov_basic.asm` | MOV 的基本形态与寄存器备份的必要性 |
| `mov_extend.asm` | MOVZX / MOVSX，零扩展与符号扩展 |
| `lea.asm` | LEA 当「不算内存的加法」用 |
| `xchg.asm` | XCHG 交换，以及它隐含的锁语义 |
| `bswap.asm` | 字节序翻转；顺带演示 `printf` 返回值破坏 `rax` 的坑 |
| `push_pop.asm` | PUSH/POP 交换寄存器；`r10`/`r11` 会被 `printf` 冲掉 |
| `test_link.asm` | 纯 `syscall` 版本（`0x2000004` = write），验证「即使不调 libc 也要 `-lSystem`」 |

## 02_arithmetic

算术运算：ADD/SUB/ADC/SBB/INC/DEC/NEG/MUL/IMUL/DIV/IDIV。

| 文件 | 内容 |
|------|------|
| `add_sub.asm` | 加减与 OF 溢出标志，带 `pushfq` 标志快照 |
| `adc_sbb.asm` | ADC/SBB 做 128 位加减 |
| `inc_dec_neg.asm` | `INC`/`DEC` **不影响 CF** 这件事 |
| `mul.asm` | 无符号乘法，结果进 `RDX:RAX`（`RDX` 是参数寄存器，装参顺序有讲究） |
| `imul.asm` | 有符号乘法的三种形态 |
| `div.asm` | 无符号除法，余数固定在 `RDX` |
| `idiv.asm` | 有符号除法与除零陷阱 |

## 03_logic_bitwise

逻辑与位运算：AND/OR/XOR/NOT/SHL/SHR/SAR/ROL/ROR/BT/BTS/BTR/BTC/BSF/BSR。

| 文件 | 内容 |
|------|------|
| `and_or_xor_not.asm` | 四个基本位运算，含 XOR 清零寄存器 |
| `shifts.asm` | 各种移位；**重点**：`ROL/ROR` 只在操作数宽度内回绕 |
| `bit_test.asm` | `BT` 系列位测试/置位/清位/取反 |
| `bit_scan.asm` | `BSF` / `BSR` 找最低/最高置位 |

## 04_comparison

比较与测试：CMP、TEST。

| 文件 | 内容 |
|------|------|
| `cmp.asm` | CMP 做减法只设标志（与 SUB 的唯一区别） |
| `test.asm` | TEST 做 AND 只设标志（与 AND 的唯一区别） |

## 05_control_flow

控制流：JMP、Jcc、LOOP、CMOVcc、SETcc、CALL/RET。

| 文件 | 内容 |
|------|------|
| `jmp.asm` | 无条件跳转与标签 |
| `je_jne.asm` | 相等/不等跳转 |
| `jg_jl_signed.asm` | 有符号比较跳转 |
| `ja_jb_unsigned.asm` | 无符号比较跳转，带标志位快照对照 |
| `loop.asm` | `LOOP` 指令（隐含 `DEC rcx`） |
| `cmov.asm` | 条件传送，无分支编程的起点 |
| `setcc.asm` | 条件置位，把标志位变成 0/1 |
| `jo_js_flags.asm` | 溢出/符号标志驱动的跳转 |
| `call_ret.asm` | 自定义函数；参数改 `rdi/rsi/rdx/rcx`，`_main` 用 `ret` 返回 |

## 06_string_ops

字符串指令与 REP 前缀：MOVS、STOS、SCAS、CMPS。

| 文件 | 内容 |
|------|------|
| `movsb.asm` | `MOVSB` / `REP MOVSB` —— memcpy 的内核 |
| `stosb.asm` | `REP STOSB` —— memset |
| `scasb.asm` | `SCASB` / `REPNE SCASB` —— 找字符 |
| `cmpsb.asm` | `REPE CMPSB` —— memcmp，首个差异位置 = 长度 − 剩余 RCX − 1 |
| `rep_prefix.asm` | REP / REPE / REPNE 三种前缀综合，含 `repne scasb` 求 strlen 的经典技巧 |

> 这一类的坑最集中：`RSI`/`RDI`/`RCX` **既是字符串指令的操作数，又是 SysV 的参数寄存器**，所以每条字符串指令之后，`printf` 的参数必须从头再装一遍；格式串字段顺序也必须严格对上。

## 07_stack_ops

栈操作：PUSH/POP、ENTER/LEAVE、PUSHFQ/POPFQ。

| 文件 | 内容 |
|------|------|
| `enter_leave.asm` | `ENTER 64,0` 与 `push rbp / mov rbp,rsp / sub rsp,64` 完全等价 |
| `push_pop_regs.asm` | 栈的 LIFO 特性 |
| `pushf_popf.asm` | 整个 RFLAGS 存档/恢复；`popfq` 之后用 `jc` 真跳一次做验证 |

## 08_system_misc

系统与杂项：SYSCALL、CPUID、RDTSC/RDTSCP、NOP/ALIGN。

| 文件 | 内容 |
|------|------|
| `cpuid.asm` | 厂商串、Family/Model/Stepping、特性位图（含 NASM 宏 + `bt` 解码特性名） |
| `cpuid_hybrid.asm` | 检测大小核（页 0x1A）与 AVX2 / AVX-512（页 7）—— 本机如实报 NO，本身就是一次正确的能力探测 |
| `nop_align.asm` | 单字节/多字节 NOP 与 `ALIGN 16` |
| `rdtsc.asm` | 时间戳计数器；用 1000 次 NOP 循环量周期数 |

## 09_fpu

x87 浮点：FLD/FST/FSTP/FILD、FADD/FSUB/FMUL/FDIV、FCOM/FCOMI、FSIN/FCOS/FPTAN。

| 文件 | 内容 |
|------|------|
| `fpu_add_sub.asm` | `FADDP` 的栈语义；`FSUBP` 方向是「ST1 − ST0」 |
| `fpu_mul_div.asm` | `FMULP` / `FDIVP`；22/7 演一次圆周率近似 |
| `fpu_load_store.asm` | `FST` 与 `FSTP` 只差一个 `p`（存完弹不弹栈） |
| `fpu_compare.asm` | `FCOMI` 直通 EFLAGS vs `FCOM` + `FNSTSW` + `SAHF` 绕状态字 |
| `fpu_trig.asm` | `FLDPI` / `FSIN` / `FCOS` / `FPTAN`；`FPTAN` 那个 1.0 历史包袱 |

> x87 指令两平台完全一样，这里唯一要改的是浮点传参：`movsd xmm0, [mem]` + `mov eax, 1`。

## 10_sse_simd

SSE / SIMD：MOVAPS/MOVUPS/MOVSS/MOVSD、标量与打包算术、比较、类型转换。

| 文件 | 内容 |
|------|------|
| `sse_mov.asm` | 对齐（`movaps`）与不对齐（`movups`）的价格差；`movss`/`movsd` 只动低位 |
| `sse_scalar.asm` | `ADDSS`/`SUBSS`/`MULSS`/`ADDSD`/`MULSD` —— 现代编译器的浮点主战场 |
| `sse_arithmetic.asm` | `ADDPS`/`SUBPS`/`MULPS`/`DIVPS` 一次算四个 |
| `sse_compare.asm` | `COMISS`/`COMISD` 出标志位；`CMPPS` 出掩码（0xFFFFFFFF / 0） |
| `sse_convert.asm` | `CVT*` 全家族；`cvtss2si` 就近舍入 vs `cvttss2si` 向零截断 |

> `andps` / `maxps` / `subps` 这些指令的**内存操作数必须 16 字节对齐**，常量前面记得写 `align 16`；错位加载一律用 `movups`。

## 11_calculus_mkl

高等数学：SIMD 数值微分/积分，以及调用厂商数学库。

| 文件 | 内容 | 对应 Windows 原版 |
|------|------|------------------|
| `simd_derivative.asm` | 中心差分求 `d/dx sin(x)`；错位加载实现有限差分，最大误差 8.6e-6 vs 理论界 h²/6 = 6.3e-6 | `avx2_derivative.asm` |
| `simd_trapezoid.asm` | 梯形法 `∫₀^π sin(x)dx`；标量 vs SIMD 都用 NASM 宏内联展开，RDTSC 实测加速比 **≈4.15×** | `avx2_trapezoid.asm` |
| `simd_simpson.asm` | 辛普森法则 `∫₀¹ 4/(1+x²)dx = π`；交错权重向量 `[4,2,4,2]` 干掉所有奇偶分支 | `avx2_simpson.asm` |
| `accelerate_vforce.asm` | 从汇编调 Accelerate 的 vForce / vDSP（`vvsinf`/`vvcosf`/`vvexpf`/`vDSP_maxv`） | `mkl_vml_math.asm` |
| `spline_integrate.asm` | 手写自然三次样条（Thomas 算法）+ 梯形积分；节点偏差 2.2e-16，积分 1.999996649 | `mkl_df_integrate.asm` |

三个「必须说明」的移植决定：

1. **AVX2 → SSE**：本机（Ivy Bridge）不支持 AVX2 / FMA，SIMD 示例改用 SSE 的 4 路。算法、数据布局、结论一致，只是通道变窄。
2. **MKL → Accelerate**：`mkl_vml_math.asm` 换成 vForce/vDSP。注意三家参数顺序互不相同（`MKL(n,in,out)` / `vForce(out,in,&n)` / `vDSP(in,stride,out,n)`）。
3. **MKL DF → 手写样条**：Accelerate **没有** pp-form 样条 API，所以把样条手写出来。这反而更能看清那条 API 背后在算什么，而且这份代码在 Windows 上原样可编译。

`accelerate_vforce.asm` 需要 `-framework Accelerate`，构建脚本通过源文件里的 `; LINK: -framework Accelerate` 一行自动加上。

---

## 构建产物

全部输出到 `../build/mac/`，用 `../build-mac.sh -Clean` 清理。
