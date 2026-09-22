# SIMD 进阶：AVX / AVX2 / FMA

本指南第 10 类（`10_sse_simd/`）原有的 SIMD 示例全部停在 SSE（128 位、`xmm`）。
这一章补上 2011 年之后的三个世代：**AVX**（256 位 + 三操作数）、
**AVX2**（整数也到 256 位）、**FMA**（乘加融合，只舍入一次）。

配套三个示例，三个平台各一份，都在 `10_sse_simd/` 下：

| 示例 | 讲什么 | 最低要求 |
|------|--------|----------|
| `avx_basics.asm` | VEX 三操作数、YMM、`vzeroupper` | AVX（Sandy Bridge，2011） |
| `avx2_int.asm` | 256 位整数乘、每通道变量移位、跨 lane 置换 | AVX2（Haswell，2013） |
| `avx2_fma.asm` | `vfmadd231ps` 与 SSE 两指令版的数值差异 | FMA3（Haswell，2013） |

> 这三个示例都**内置 CPUID + XGETBV 运行时探测**：机器不具备对应能力时，
> 会打印一行「本机不支持…，跳过」并正常退出 0，不会抛 #UD 崩掉。

---

## 1. 世代表

| 世代 | 年份 | 向量宽度 | 浮点 | 整数 | 指令编码 |
|------|------|----------|------|------|----------|
| SSE–SSE4 | 1999–2008 | 128 位（`xmm`） | 4 × float | 128 位整数 | 传统前缀 |
| **AVX** | 2011 | **256 位（`ymm`）** | **8 × float** | 仍是 128 位 | **VEX** |
| **AVX2** | 2013 | 256 位 | 8 × float | **256 位整数** | VEX |
| AVX-512 | 2017 | 512 位（`zmm`） | 16 × float | 512 位整数 | EVEX |

一句话记住分界：**AVX 只扩浮点，AVX2 才扩整数**。2011–2013 那两年，
编译器没法把整数循环向量化到 256 位，原因就在这里。

## 2. AVX 改了什么：VEX 编码与三操作数

宽度翻倍只是表面，真正影响写法的是**指令编码换了**。AVX 引入 VEX 前缀，
把两操作数指令改成三操作数，源寄存器不再被破坏：

```nasm
; SSE：目标兼作第一个源，算完 xmm0 的原值就没了
    movaps xmm0, [a]
    movaps xmm1, [b]
    addps  xmm0, xmm1          ; xmm0 = xmm0 + xmm1

; AVX：目标独立，两个源原样保留
    vmovaps ymm1, [a]
    vmovaps ymm2, [b]
    vaddps  ymm0, ymm1, ymm2   ; ymm0 = ymm1 + ymm2，ymm1/ymm2 没动
    vmulps  ymm3, ymm1, ymm2   ; 直接复用，不需要任何备份
```

`avx_basics.asm` 第 2 段就是靠这一点，用**同一对源寄存器**连算出「和」与「积」两组结果。
换成 SSE 写法，中间必须插一条 `movaps` 备份。

两个容易混的点：

- **「有 v 前缀」是 VEX 编码的标志，与宽度无关。**`vaddps xmm0, xmm1, xmm2` 是 128 位的
  VEX 编码，照样三操作数。VEX 编码的 128 位指令同样能消除破坏性写入，
  所以即使不用 256 位，`-mavx` 编译出的代码也常比 SSE 版短。
- **不是所有三操作数形式都合法**。VEX 编码里最多一个内存操作数，所以
  `vaddps ymm0, [a], [b]` 编不过 —— 内存操作数只能出现在最后一个源上。

## 3. YMM 归操作系统管：OSXSAVE / XCR0 / vzeroupper

这是 AVX 与 SSE 最大的**工程**差别。SSE 的 `xmm` 是 CPU 一直保存的；
`ymm` 的上半 128 位属于「扩展状态」，**必须由操作系统显式打开**，
否则执行任何 ymm 指令直接 `#UD`（非法指令）。

于是探测分成两层：

| 层次 | 问谁 | 怎么问 |
|------|------|--------|
| CPU 有没有这个指令 | CPUID | 页 1 `ECX[28]` = AVX；页 7 `EBX[5]` = AVX2 |
| 操作系统放没放开 YMM | CPUID + XGETBV | 页 1 `ECX[27]` = OSXSAVE，再读 `XCR0[2:1]` 必须都是 1 |

只判 CPUID 的代码在「CPU 支持、但 OS 没开」的机器上会当场崩 —— 虚拟机和老系统上这种组合很常见。
`avx2_fma.asm` 里会把这两层的结果分开打印。

另一半是性能：**用了 ymm 之后要 `vzeroupper`**。`ymm` 上半部没清零时是「脏」的，
后续的 SSE 指令在 Haswell 上会让 CPU 保存/恢复整个上半部，每次付出几十个周期的
AVX↔SSE 转换惩罚。而 `printf` 内部全是 SSE 指令，所以三个示例都遵循同一个顺序：

```nasm
    vaddps  ymm0, ymm1, ymm2
    vmovaps [buf], ymm0        ; 1. 结果先落内存（vzeroupper 会清零上半部！）
    vzeroupper                 ; 2. 清掉上半部
    call    _printf            ; 3. 这时再调 libc
```

## 4. AVX2：整数终于也有 256 位

AVX2 在整数侧加了三件 SSE 根本做不到的事，`avx2_int.asm` 逐个演示：

| 指令 | 能力 | SSE 侧为什么做不到 |
|------|------|--------------------|
| `vpmulld ymm` | 8 路 32 位有符号乘 | SSE4.1 的 `pmulld` 只有 128 位，4 路 |
| `vpsllvd ymm, ymm, ymm` | **每通道独立**的移位量 | `pslld` 只能给立即数，全体移同样的位数 |
| `vpermd ymm, ymm, ymm` | **跨 128 位 lane** 的任意置换 | AVX1 的 `vpermilps` 只能在 lane 内换 |

第三点最容易翻车：256 位向量在大多数 shuffle 指令眼里是**两个独立的 128 位 lane**，
中间那堵墙过不去。想「整体反转 8 个元素」，用 AVX1 的 `vpermilps` 只会得到
前后两半各自反转（示例输出里专门打了这一行对照）。
要跨 lane，就得用 AVX2 的 `vpermd` / `vpermps`。

顺手还有个 `vpbroadcastd`：把内存里的一个数铺满 8 个通道。
SSE 时代要 `movss` + `shufps` 两条，现在一条。

## 5. FMA：一条顶两条，而且只舍入一次

```nasm
; SSE：两次舍入
    mulps xmm0, xmm1           ; t = a * b   ← 舍入
    addps xmm0, xmm2           ; t = t + c   ← 再舍入

; FMA：一次舍入
    vfmadd231ps ymm0, ymm1, ymm2   ; ymm0 = ymm1*ymm2 + ymm0
```

省一条指令是附带的，值钱的是**中间乘积不做舍入** —— `a*b` 的完整精度一直带进最后的加法。

`avx2_fma.asm` 用一个能放大的例子把差别摆出来：取 `a = 1+2⁻²³`、`b = 1−2⁻²³`、`c = −1`。
精确值 `a*b + c = −2⁻⁴⁶`，但 SSE 路径先算 `a*b`，它的真值 `1−2⁻⁴⁶` 塞不进 float
（只有 24 位有效位），被舍入成 `1.0`；接着 `1.0 + (−1.0) = 0`，有效数字全被抵消。
FMA 路径一步算完，得到 `−1.4210854715202004e-14`。

实测输出（macOS / i7-4770HQ，Haswell）：

```text
FMA：一条顶两条，而且只舍入一次
探测：AVX2 = YES，FMA = YES
1. 一个能看出差别的小例子
   a = 1 + 2^-23（float 里比 1.0 大的最小数，位型 0x3F800001）
   b = 1 - 2^-23（位型 0x3F7FFFFE）
   （坑：1.0 以下的 ulp 只有 2^-24，所以 0x3F7FFFFF 是 1-2^-24，不是 1-2^-23）
   c = -1.0
   精确值 a*b + c = -2^-46 = -1.4210854715202004e-14
2. SSE 路径：mulps + addps，中间乘积被舍入两次
   a*b 的真值 1-2^-46 塞不进 float（只有 24 位有效位），先被舍入成 1.0
   然后 1.0 + (-1.0) = 0 —— 有效数字全被抵消了
   mulps+addps 结果 = 0
3. FMA 路径：vfmadd231ps，只有最后一次舍入
   vfmadd231ps 结果 = -1.4210854715202004e-14
4. 换一组普通常数（a=2, b=3, c=4），两条路径结果一样
   —— FMA 不是另一种算法，只是少了中间那一次舍入
   mulps+addps 结果 = 10
   vfmadd231ps 结果 = 10
FMA demo completed.
```

第 4 段是必要的对照：**FMA 不是另一种浮点模型**，只是少了一次舍入。
绝大多数输入下两条路径结果完全相同，差异只在像上面这样精心构造的边界上显现。

### 后缀 132 / 213 / 231 怎么记

| 写法 | 含义 |
|------|------|
| `vfmadd132ps d, s2, s3` | `d = d*s3 + s2` |
| `vfmadd213ps d, s2, s3` | `d = s2*d + s3` |
| `vfmadd231ps d, s2, s3` | `d = s2*s3 + d` ← 最常用 |

数字是「三个操作数在乘法里从左到右的顺序」，而 `d` 永远同时出现在加法里。
编译器生成的 FMA 大多是 **231**，因为 `sum += a*b` 这种写法最自然 —— 累加器正好放 `d`。

## 6. 运行时探测与降级

三个平台探测代码**完全一样**（CPUID / XGETBV 是 CPU 给的，与操作系统无关），
都收在一个 `cpu_features` 里，返回位图：

```nasm
;   bit0 = AVX    页1 ECX[28]，且 ECX[27] OSXSAVE，且 XCR0[2:1] = 11
;   bit1 = AVX2   页7 EBX[5]
;   bit2 = FMA    页1 ECX[12]      ← FMA 在页 1，不在页 7
;   bit3 = 操作系统已放开 YMM 状态保存
cpu_features:
    mov  eax, 0
    cpuid
    mov  r9d, eax                    ; 最大页号，后面要用
    cmp  r9d, 1
    jb   .done                       ; 连页 1 都没有，什么都别问

    mov  eax, 1
    xor  ecx, ecx
    cpuid
    mov  r8d, ecx
    bt   r8d, 12                     ; FMA
    bt   r8d, 28                     ; AVX
    bt   r8d, 27                     ; OSXSAVE
    ; ……（完整代码见示例）

    xor  ecx, ecx
    xgetbv                           ; XCR0 -> EDX:EAX
    and  eax, 6
    cmp  eax, 6                      ; [2:1] 都要置位
    jne  .done
```

降级策略是「如实报告 + 跳过」：不具备能力时打印一行说明，然后正常退出。
这样三个平台的构建脚本在任何机器上都是绿的，输出不会骗人。

## 7. 三个平台的差异

探测与计算部分三平台一字不差，**只有打印和退场不同**：

| | 汇编 | 链接 | printf 参数 | 退场 |
|---|------|------|-------------|------|
| Windows | `-f win64` | `link /entry:main` | `rcx rdx r8`；**浮点参数要同时写 xmm 和整数槽** | `call ExitProcess` |
| macOS | `-f macho64` | `clang -arch x86_64` | `rdi rsi rdx`，浮点走 `xmm0..`，`al` = 用到的 xmm 个数 | `leave` / `ret` |
| Linux | `-f elf64` | `gcc -no-pie` | 同 macOS | `leave` / `ret` |

Windows 那一列是本文档三个示例里唯一「写法不同」的地方，初稿写作时没条件在本机验证
（当时用的 macOS）。2026-09 已在 Windows 11（i7-12700F，nasm + MSVC link.exe + UCRT）
上补测：三个示例全部构建、运行通过，逐通道数值与 macOS 版完全一致（见第 8 节），
「双写」技巧实测有效。三份源码放在一起 diff，差异确实只出现在这些行上。

## 8. 实测输出（i7-4770HQ / Haswell；末小节为 i7-12700F / Windows 补测）

`avx_basics.asm`：

```text
AVX 基础：VEX 三操作数 + 256 位 YMM
1. SSE 基线（128 位，破坏性操作数）
   addps xmm0,xmm1 算完 xmm0 原值就没了；想复用必须先 movaps 备份
     [0] = 11
     [1] = 12
     [2] = 13
     [3] = 14
2. AVX：同一对源寄存器，连算两组结果（源没被破坏）
   和： [1..8] + [10 x 8]
     [0] = 11
     …（中间省略 6 行逐通道结果）
     [7] = 18
   积： [1..8] * [10 x 8]
     [0] = 10
     …（中间省略 6 行逐通道结果）
     [7] = 80
3. vzeroupper：ymm 上半部已清零，现在可以安全调 printf 了
AVX basics demo completed.
```

`avx2_int.asm`：

```text
AVX2 整数：SSE 做不到的三件事
1. VPMULLD —— 8 路 32 位有符号乘（SSE 只有 128 位版）
   [100000 ... 800000] * [3,-3,3,-3,3,-3,3,-3]
     [0] = 300000
     [1] = -600000
     …（中间省略 6 行逐通道结果）
     [7] = -2400000
2. VPSLLVD —— 每个通道各自移自己的位数（SSE 只能全体同移）
   [1 x 8] 左移 [0,1,2,3,4,5,6,7] 位
     [0] = 1
     [1] = 2
     …（中间省略 6 行逐通道结果）
     [7] = 128
3. VPERMD  —— 跨 128 位 lane 的任意置换（AVX1 只能在 lane 内换）
   [10..80] 按索引 [7,6,5,4,3,2,1,0] 重排 = 整体反转
   （若改用 AVX1 的 vpermilps，只会得到 40 30 20 10 80 70 60 50）
     [0] = 80
     [1] = 70
     …（中间省略 6 行逐通道结果）
     [7] = 10
4. VPBROADCASTD —— 内存里的一个数铺满 8 个通道
   [7] 广播
     [0] = 7
     [1] = 7
     …（中间省略 6 行逐通道结果）
     [7] = 7
AVX2 integer demo completed.
```

> 上面两段里的「中间省略」是**本文档的缩写**，不是程序输出；
> 逐通道完整结果见 `../build/mac/avx_basics` 与 `../build/mac/avx2_int` 的直接运行输出。
> `avx2_fma.asm` 的行数少，完整输出已经贴在第 5 节，这里不再重复。

`build-mac.sh -All` 的汇总（含本章三个示例，总计 59 个）：

```text
==========================================
  构建汇总: 总计 59 个, 通过 59 个, 失败 0 个
==========================================
```

在不支持 AVX2 的机器上（例如 Ivy Bridge 的 i7-3520M），三支示例会走
`cpu_features` 的跳过分支 —— 因为三个平台共用同一份探测代码，
按源码应当输出下面这种提示而不是崩溃（`avx_basics` 在 Ivy Bridge 上其实有 AVX 1.0，
会跑完整；只有 `avx2_int` / `avx2_fma` 走跳过）：

```text
本机不支持 AVX2（CPUID 页 7 EBX[5] / XCR0 已确认），本示例无可演示内容。
AVX2 integer demo completed.
```

> **这段是照源码推的，不是在 Ivy Bridge 上实测的** —— 手边只有 Haswell 一台能跑。
> 本机验证到的只是「Haswell 上走的是完整路径」。等真有老机器时，这是首要复核项。

### Windows 侧补测（i7-12700F / Alder Lake，2026-09）

教程初稿的实测全在 macOS 上完成，Windows 列当时只做了源码推演。在
Windows 11（nasm + MSVC link.exe + UCRT）上补测：三个示例全部构建、运行通过，
**逐通道数值与 macOS 版完全一致**——包括 `vfmadd231ps = -1.4210854715202004e-14`
这个只在边界输入下才显形的值，说明 FMA 的语义与平台无关。输出文案唯一的差别在
`avx_basics` 的逐通道行：Windows 版格式串是 `[%d] = %f`（`[0] = 11.000000`），
macOS 版是 `[%d] = ` 接独立打印（`[0] = 11`）——排版差异，不是数值差异。

Windows 版 `avx2_fma` 的探测行与关键结果：

```text
探测：AVX2 = YES，FMA = YES
mulps+addps 结果 = 0
vfmadd231ps 结果 = -1.4210854715202004e-14
（第 4 段普通常数两条路径同为 10，与第 5 节 macOS 输出一致）
```

这次补测还顺带验证了第 7 节的「双写」：`avx2_fma.asm` 的 `put_g17` 把浮点参数放在
`xmm1`（**并非**位置对应的 `xmm2`）仍能打印出正确值——反证 UCRT 的 printf 读的是
整数槽 `r8`，与踩坑清单第 10 条的说法一致。

`build.ps1 -All` 的汇总（Windows 全量 61 个；macOS 侧 `build-mac.sh` 为 59 个。
总数之差来自第 11 类两侧示例集不同：macOS 侧是 `simd_*` 四件 + Accelerate/spline
共五件，Windows 侧是 AVX2 积分三件套 + MKL 两件 + 对齐/最小复现两件共七件）：

```text
==========================================
  构建汇总: 总计 61 个, 成功 61 个, 失败 0 个
==========================================
```

## 9. 与第 11 类的关系

第 11 类（`11_calculus_mkl/`）的 SIMD 示例仍是 **SSE 4 路版**，这是有意保留的：

- 第 11 类讲的是**渐近法与积分/微分**，向量宽度不是重点；SSE 版在任何 x86-64 上都能跑，
  便于把注意力放在算法上。
- Windows 侧的 `examples/11_calculus_mkl/avx2_derivative.asm`、`avx2_simpson.asm`、
  `avx2_trapezoid.asm` 是最初的 AVX2 版本，保留下来当对照。它们的 8 路版本与
  macOS/Linux 侧 `simd_*.asm` 的 4 路版本算法、数据布局、结论完全一致，
  差别就是 `xmm` → `ymm`、助记符加 `v`、水平求和换 `vextractf128`。
- 想知道「同一段积分代码怎么从 SSE 搬到 AVX2」，看本文档第 2、4 节，
  以及 `10_sse_simd/` 里那三个示例 —— 它们的写法就是搬运规则本身。

## 10. 踩坑清单

1. **`ymm` 数据必须 32 字节对齐**。`vmovaps` 内存操作数不对齐直接 `#GP`；
   `.data` 里写 `align 32`。错位加载一律用 `vmovups`。
2. **只用 CPUID 判 AVX 不够**，还要 `OSXSAVE` + `XGETBV` 查 `XCR0[2:1]`。
   虚拟机里「CPU 支持、OS 没开」是常态，漏判就是 `#UD`。
3. **`vzeroupper` 放在落内存之后**。它会清零 ymm 上半部，先 `vzeroupper` 再 `vmovaps [buf], ymm0`
   存下来的就是半个空向量。
4. **忘了 `vzeroupper`** 不会崩，但每次 AVX→SSE 切换都吃转换惩罚，
   在 `printf` 这种 SSE 密集的调用旁边尤其明显。
5. **`vpermilps` 换不过 lane 中线**。256 位是「两个 128 位 lane」，
   想整体反转/跨半区取元素必须上 AVX2 的 `vpermd` / `vpermps`。
6. **FMA 的 CPUID 位在页 1 `ECX[12]`**，不在页 7。页 7 只有 AVX2（`EBX[5]`）。
   二者同年出现，但探测位不同，写错了会误判。
7. **1.0 两侧的 ulp 不一样**：1.0 以上是 2⁻²³，1.0 以下是 2⁻²⁴。
   所以「比 1.0 小的最大数」是 `0x3F7FFFFF` = 1−2⁻²⁴，不是 1−2⁻²³。
   构造浮点边界测试时这一格之差会让预期值全部错位。
8. **`mulps` + `addps` 不等于 `vfmadd231ps`**。前者中间乘积舍入一次，
   遇到「大数相消」（如本文档 `a*b + c` 那个例子）会丢掉全部有效数字。
   反过来说，也不要以为 FMA 会改变所有结果 —— 绝大多数输入下两者完全一致。
9. **VEX 编码最多一个内存操作数**，`vaddps ymm0, [a], [b]` 编不过；
   且内存操作数只能出现在最后一个源的位置。
10. **Windows 的浮点参数要双写**：既写 `xmm`，又写对应的整数槽（`rcx/rdx/r8/r9`），
    MSVC 的 `printf` 才读得到；只写 xmm 会打出 `0`。
    （2026-09 已在 UCRT 上实测佐证：`put_g17` 把 double 放在 `xmm1` 而非位置对应的
    `xmm2`，仍打印出正确值——说明 printf 读的确实是整数槽。）

---

> 上一章：[Linux 平台移植指南](11_linux.md) ｜ 返回：[README](../README.md)
