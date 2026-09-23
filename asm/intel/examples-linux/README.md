# Linux 示例集

`examples/` 是 Windows 版（`-f win64` + MSVC `link.exe`），本目录是**同样 11 个类别的 Linux 版**：`-f elf64` + `gcc -no-pie`（自动带 glibc 启动文件）。

**56 个示例在 Arch Linux（WSL2，NASM 3.02 / gcc 16.2.1 / glibc 2.44）上实际汇编、链接、运行通过（56/56）。**

**后补的 4 个示例（`10_sse_simd/` 下的 `avx_basics` / `avx2_int` / `avx2_fma` / `avx512_basics`）已在另一台 Linux 机器（Ubuntu 22.04 / KVM / Intel Xeon Platinum，Skylake-SP）上实际汇编、链接、运行通过** —— 逐通道数值与 macOS / Windows 版一致，`avx512_basics` 走的是完整演示路径（AVX-512F 与 `XCR0[7:5]` 都成立）。至此 **60/60 全部实测通过**。

> 这四支都内置 `cpuid` + `xgetbv` 运行时探测：机器缺少 AVX / AVX2 / FMA 时打印一行
> 「本机不支持 …，跳过」并**正常退出 0**，不会崩（`avx512_basics` 缺 AVX-512F 或
> `XCR0[7:5]` 未全开时同理）。所以它们能安全地放进全量脚本。

```bash
../build-linux.sh -All                              # 全部构建并运行
../build-linux.sh -Category 05_control_flow         # 单个类别
../build-linux.sh -File 05_control_flow/cmov.asm    # 单个文件
```

平台差异、移植规则和踩坑清单见 **[docs/11_linux.md](../docs/11_linux.md)**。

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
| [10_sse_simd](#10_sse_simd) | 9 | 同名 | 常量要 `align 16`；`ymm` 要 `align 32`；`zmm` 要 `align 64` |
| [11_calculus_mkl](#11_calculus_mkl) | 5 | `avx2_*` / `mkl_*` | AVX2→SSE，MKL→libmvec |

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
| `test_link.asm` | 纯 `syscall` 版本（write=1、exit=60），`ld` 直连生成**静态**可执行文件 —— Linux 上纯系统调用程序不需要 libc，这比 macOS 必须 `-lSystem` 省心 |

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
| `call_ret.asm` | 自定义函数；参数改 `rdi/rsi/rdx/rcx`，`main` 用 `ret` 返回 |

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

SSE / SIMD：MOVAPS/MOVUPS/MOVSS/MOVSD、标量与打包算术、比较、类型转换；后半段是 AVX / AVX2 / FMA / AVX-512。

| 文件 | 内容 |
|------|------|
| `sse_mov.asm` | 对齐（`movaps`）与不对齐（`movups`）的价格差；`movss`/`movsd` 只动低位 |
| `sse_scalar.asm` | `ADDSS`/`SUBSS`/`MULSS`/`ADDSD`/`MULSD` —— 现代编译器的浮点主战场 |
| `sse_arithmetic.asm` | `ADDPS`/`SUBPS`/`MULPS`/`DIVPS` 一次算四个 |
| `sse_compare.asm` | `COMISS`/`COMISD` 出标志位；`CMPPS` 出掩码（0xFFFFFFFF / 0） |
| `sse_convert.asm` | `CVT*` 全家族；`cvtss2si` 就近舍入 vs `cvttss2si` 向零截断 |
| `avx_basics.asm` | VEX 三操作数 + 256 位 `ymm`：同一对源寄存器连算和与积，SSE 版必须先备份；末尾 `vzeroupper` |
| `avx2_int.asm` | `vpmulld` / `vpsllvd` / `vpermd` / `vpbroadcastd` —— SSE 做不到的三件事（含跨 lane 置换） |
| `avx2_fma.asm` | `vfmadd231ps` vs `mulps`+`addps`：中间乘积少舍入一次，边界输入上 SSE 得 0、FMA 得 -1.4210854715202004e-14 |
| `avx512_basics.asm` | 512 位 `zmm` 一次 16 路整数加，加 opmask `k1` 的合并掩码 `{k1}` 与归零掩码 `{k1}{z}` |

> `andps` / `maxps` / `subps` 这些指令的**内存操作数必须 16 字节对齐**，常量前面记得写 `align 16`；错位加载一律用 `movups`。
> AVX 同理升到 32 字节：`vmovaps ymm` 的内存操作数要 `align 32`，拿不准就用 `vmovups`。

> 注意 `avx2_int.asm` 里 **32 字节对齐是靠 NASM 的 `align 32` 拿到、不是靠链接脚本**：
> `-f elf64` 下实测 NASM 会把 `.data` 段的 `sh_addralign` 直接写成 **32**
> （`llvm-readelf -S <obj> | grep .data` 可见 `Al` 列是 32），
> 而 ELF 规范要求链接器按输入段的对齐布置输出段，GNU ld 与 `gcc -no-pie` 都遵守，
> 所以链接后这些常量的地址仍是 32 的倍数。
> **这一条后来在真 Linux 上兑现了** —— Ubuntu 22.04 / Xeon Platinum（Skylake-SP）那台跑
> `avx2_int` 走的是完整路径，`vmovaps ymm` 没出事，说明链接后这些常量确实落在 32 的倍数上。
> 真出问题（`vmovaps` 直接 `#GP` 崩掉）就把这几条改成 `vmovups`。

> AVX-512 再升一级：`vmovdqa32 zmm` 要求 **64 字节**对齐，所以 `avx512_basics.asm` 的数据段
> 一律 `align 64`；同理掩码寄存器 `k1` 是**调用者保存**的，`printf` 之后要重新 `kmovw`。

AVX / AVX2 / FMA / AVX-512 的完整讲解（世代表、VEX 与 EVEX 编码、三操作数为什么省一次 `movaps`、
YMM 与 `vzeroupper` 的代价、opmask 的合并 / 归零两种语义、运行时降级探测）见
**[docs/12_simd_avx.md](../docs/12_simd_avx.md)** —— 上面四个示例就是那一章的实测代码，
macOS / Windows / Linux 三侧都有实测记录（见章内说明）。

## 11_calculus_mkl

高等数学：SIMD 数值微分/积分，以及调用厂商数学库。

| 文件 | 内容 | 对应 Windows 原版 |
|------|------|------------------|
| `simd_derivative.asm` | 中心差分求 `d/dx sin(x)`；错位加载实现有限差分，最大误差 8.6e-6 vs 理论界 h²/6 = 6.3e-6 | `avx2_derivative.asm` |
| `simd_trapezoid.asm` | 梯形法 `∫₀^π sin(x)dx`；标量 vs SIMD 都用 NASM 宏内联展开，RDTSC 实测加速比 **≈4.12×** | `avx2_trapezoid.asm` |
| `simd_simpson.asm` | 辛普森法则 `∫₀¹ 4/(1+x²)dx = π`；交错权重向量 `[4,2,4,2]` 干掉所有奇偶分支 | `avx2_simpson.asm` |
| `accelerate_vforce.asm` | 从汇编调 glibc 的 libmvec（`_ZGVbN4v_sinf`/`_ZGVbN4v_cosf`/`_ZGVbN4v_expf`），SSE 手工归约求最大值 | `mkl_vml_math.asm` |
| `spline_integrate.asm` | 手写自然三次样条（Thomas 算法）+ 梯形积分；节点偏差 2.2e-16，积分 1.999996649 | `mkl_df_integrate.asm` |

三个「必须说明」的移植决定：

1. **AVX2 → SSE**：SIMD 示例沿用 SSE 的 4 路（和 macOS 版一致，任何 x86-64 都能跑）。算法、数据布局、结论一致，只是通道变窄；本机（支持 AVX2）RDTSC 实测加速比仍在 4× 上下。**AVX2 / FMA / AVX-512 本身并没有丢** —— 后来在 `10_sse_simd/` 下补齐了 `avx_basics` / `avx2_int` / `avx2_fma` / `avx512_basics` 四个示例，讲解见 [docs/12_simd_avx.md](../docs/12_simd_avx.md)。
2. **MKL → libmvec**：`mkl_vml_math.asm` 换成 glibc 的 `_ZGVbN4v_*` 系列。和 MKL（`n,in,out`）、vForce（`out,in,&n`）都不同，libmvec **不传指针**：4 个 float 打包进 `xmm0` 传入，结果同样在 `xmm0` 里回来，一次只算一个向量，数组要自己写循环。
3. **MKL DF → 手写样条**：libmvec **没有** pp-form 样条 API（也没有 vDSP_maxv 那样的归约函数），所以样条和最大值归约都手写。这反而更能看清那条 API 背后在算什么，而且这份代码在哪个平台上都原样可编译。

`accelerate_vforce.asm` 需要 `-lm -lmvec`，构建脚本通过源文件里的 `; LINK: -lm -lmvec` 一行自动加上。

---

## 构建产物

全部输出到 `../build/linux/`，用 `../build-linux.sh -Clean` 清理。
