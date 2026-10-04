# 4. 编程模型：主机-设备、NDRange、计算单元层次

[03 篇](./03-first-program.md) 把程序写出来了，但只用到了一维、`global=1024 local=64` 这一种最简单的形状。这一篇把执行模型讲透：**NDRange 是什么、`global` 和 `local` 两个尺寸各受什么约束、索引怎么算、以及为什么这两个约束都只报一个 `-54`。**

本机 Intel UHD 630 的 `max_work_group_size` 是 **256**——不是 1024，不是 512。这一个数字决定了 4.5 节整张实测表。

> **验证方式说明**：本篇的约束不是从规范抄的，是 `examples/04-matmul-tiled/` 在 Intel UHD Graphics 630 上**逐条撞出来**的：五个 case 分别覆盖"工作组超限"、"两种合法尺寸"、"全局尺寸没对齐"、"对齐后通过"，每一个都把 `-54` 或数值结果当成**预期输出**打印出来，属于**运行时数值级**证据。4.6 节 `CL_KERNEL_WORK_GROUP_SIZE` 与 `CL_DEVICE_MAX_WORK_GROUP_SIZE` 的区别由 `tools/cl-build-probe/` 打印，属于**内核编译级**。

## 4.1 主机-设备模型

```text
┌────────────────────────┐          ┌────────────────────────┐
│   主机 Host（CPU）      │          │   设备 Device（GPU）    │
│                        │          │                        │
│  · 你的 C/C++ 程序      │  命令     │  · 命令队列             │
│  · 决定"做什么、做几次"  │ ───────► │  · 内核执行             │
│  · 分配、搬运、验证      │  缓冲区   │  · 全局/本地/常量内存    │
│                        │ ◄──────► │  · N 个工作项并行        │
└────────────────────────┘          └────────────────────────┘
        顺序执行                            大规模并行
```

分工是清晰的，而且**不能混**：

| 职责 | 在主机 | 在设备 |
|------|:---:|:---:|
| 发现硬件、创建对象 | ✅ | ❌ |
| 决定并行度（开多少工作项） | ✅ | ❌ |
| 内存分配与数据搬运的**发起** | ✅ | ❌ |
| 实际的算术运算 | ❌ | ✅ |
| 工作项之间的同步 | ❌ | ✅（`barrier`，仅限工作组内） |

"决定并行度在主机"这一点很反直觉：**内核代码里看不到循环次数**。`vector_add` 只写了"我处理第 `i` 个元素"，而"一共有多少个 `i`"是主机在 `clEnqueueNDRangeKernel` 里说的。同一份内核，主机可以开 1024 个工作项，也可以开 100 万个。

这也解释了为什么 4.5 节那两条约束**只能在运行时暴露**：内核编译时根本不知道你打算开多少个工作项。

## 4.2 十步流程（顺序修正版）

```text
 1. 发现平台和设备      clGetPlatformIDs / clGetDeviceIDs
 2. 创建上下文          clCreateContext
 3. 创建命令队列        clCreateCommandQueueWithProperties
 4. 编写内核源码        kernels/*.cl
 5. 编译程序            clCreateProgramWithSource + clBuildProgram
 6. 创建内核对象        clCreateKernel
 7. 设置内核参数        clSetKernelArg
 8. 传入数据            clEnqueueWriteBuffer        ◄── 在"执行内核"之前
 9. 执行内核            clEnqueueNDRangeKernel
10. 取回结果            clEnqueueReadBuffer + clFinish
11. 释放资源            clRelease*（按建立的逆序）
```

原始资料把"数据传输"排在"执行内核"**之后**（第 9 步在第 8 步后面）。对**输出**数据这是对的，对**输入**数据这是错的——输入必须在内核跑之前到位。把它拆成 8 和 10 两步，流程才不误导。

第 4 步单列出来是有意的：**内核源码不是主机程序的一部分**。它由设备侧的运行时编译器（或离线的 clang）编译，语法是 OpenCL C 而不是 C99，出错时的诊断在 `CL_PROGRAM_BUILD_LOG` 里而不是在你的终端里。把这两半当成一件事，是新手排查问题时最常见的方向错误。

## 4.3 计算单元层次

```text
Platform（平台）── 一个厂商的一套 OpenCL 实现。本机有 3 个
  │
  ├── Device（设备）── 一个具体的计算设备。本机每个平台 1 个
  │     │
  │     ├── Compute Unit（计算单元）── UHD 630 有 24 个
  │     │     │                       NVIDIA 叫 SM，AMD 叫 CU
  │     │     ├── work-group 0  ── 一组能互相协作的工作项
  │     │     ├── work-group 1      能共享 __local 内存、能用 barrier
  │     │     └── ...               一个工作组整体被调度到一个 CU 上
  │     │
  │     └── Compute Unit N
  │
  └── Device M
```

四个层级各自的边界，以及"越过边界会怎样"：

| 层级 | 数量由谁决定 | 组内能做什么 | 组间能做什么 |
|------|------------|------------|------------|
| **work-item** | `global_work_size` | 只能访问自己的 `__private` 变量 | **什么都不能**。没有跨工作项同步，没有共享内存 |
| **work-group** | `local_work_size` | 共享 `__local` 内存、`barrier()` 同步、`get_local_id()` 互相寻址 | **什么都不能**。工作组之间没有任何同步原语 |
| **Compute Unit** | 硬件 | — | 由驱动调度，你无法指定 |
| **Device** | 硬件 | — | 只能通过主机侧的多队列/多 context 协调，见 `examples/10-multi-device/` |

**"工作组之间无法同步"是本篇最重要的一句话。** 它直接决定了归约算法必须分两轮：第一轮每个工作组算出一个部分和，第二轮再归约这些部分和。`examples/05-reduce-sum/` 就是围绕这一点写的——原始资料的归约示例只有第一轮，所以它在组数大于 1 时返回的是**某一个组的和**，看起来像个合理的数，但就是错的。

```text
第一轮（组内，能用 barrier）           第二轮（跨组，组内再做一次）
group0: 100 个值 → partials[0]  ─┐
group1: 100 个值 → partials[1]  ─┤
group2: 100 个值 → partials[2]  ─┼──►  partials[0..9] → 最终和
...                             ─┤
group9: 100 个值 → partials[9]  ─┘
       ↑ 组间没有 barrier，只能靠"内核结束"这个隐式全局同步点
```

## 4.4 NDRange：把 `global=1024 local=64` 讲透

`clEnqueueNDRangeKernel` 的签名：

```c
cl_int clEnqueueNDRangeKernel(cl_command_queue queue,
                              cl_kernel        kernel,
                              cl_uint          work_dim,          // 1、2 或 3
                              const size_t*    global_work_offset,// 通常为 NULL
                              const size_t*    global_work_size,  // 每维的工作项总数
                              const size_t*    local_work_size,   // 每维的工作组尺寸，可为 NULL
                              cl_uint          num_events_in_wait_list,
                              const cl_event*  event_wait_list,
                              cl_event*        event);
```

`work_dim` 决定后面两个数组的长度。一维时 `global_work_size` 是一个元素，二维时是两个。

### 4.4.1 一维：1024 个工作项分成 16 组

`examples/02-vector-add/` 的 `global=1024 local=64`：

```text
global_work_size = 1024     local_work_size = 64
                            → num_groups = 1024 / 64 = 16

group 0        group 1        group 2                    group 15
┌────────────┐┌────────────┐┌────────────┐              ┌────────────┐
│ 0 .. 63    ││ 64 .. 127  ││ 128 .. 191 │    ......    │ 960 .. 1023│
└────────────┘└────────────┘└────────────┘              └────────────┘
  local_id 0-63  local_id 0-63
```

索引算术（这是唯一需要背下来的公式）：

```c
get_global_id(0)  ==  get_group_id(0) * get_local_size(0) + get_local_id(0)
get_num_groups(0) ==  get_global_size(0) / get_local_size(0)
```

对本例：`get_global_size(0) = 1024`、`get_local_size(0) = 64`、`get_num_groups(0) = 16`。

### 4.4.2 二维：256×256 矩阵分成 16×16 的组

`examples/03-matmul-naive/` 的实测启动参数：

```text
[launch] global={256,256} local={16,16} for a 256x256 matrix
[launch] CL_KERNEL_WORK_GROUP_SIZE=256 (local product=256)
[verify] 65536/65536 elements within tolerance, max abs err 0.000e+00
```

```text
global = {256, 256}          local = {16, 16}
                             → num_groups = {256/16, 256/16} = {16, 16} = 256 个组
                             → 每组 16*16 = 256 个工作项

        col →
      ┌────┬────┬────┬─────
   row│ G  │ G  │ G  │         G(0,0) 覆盖 row 0..15, col 0..15
   ↓  │0,0 │0,1 │0,2 │         每个 G 是一个 16×16 的工作组
      ├────┼────┼────┼─────
      │ G  │ G  │ G  │         工作项 (row, col) 属于
      │1,0 │1,1 │1,2 │           group  = (row/16, col/16)
      ├────┼────┼────┼─────     local  = (row%16, col%16)
      │ ...│    │    │
```

二维时的索引算术是**逐维独立**的：

```c
int col = get_global_id(0);   // = get_group_id(0) * get_local_size(0) + get_local_id(0)
int row = get_global_id(1);   // = get_group_id(1) * get_local_size(1) + get_local_id(1)
```

**维度的顺序是约定，不是规定。** `matmul_naive.cl` 里 `get_global_id(0)` 是 **col**、`get_global_id(1)` 是 **row**，所以矩阵按 `A[row * width + col]` 行主序索引时，同一个工作组内的相邻工作项访问 `A` 的同一行——即 `col` 连续。这让 `A` 的读取是**合并的**（coalesced）。反过来写（`id(0)` 当 row）会得到一个能跑出正确结果但慢得多的内核，而且**没有任何报错**。

```c
// examples/03-matmul-naive/kernels/matmul_naive.cl
__kernel void matmul_naive(__global const float* A,
                           __global const float* B,
                           __global float* C,
                           const int width) {
    int col = get_global_id(0);
    int row = get_global_id(1);

    if (row < width && col < width) {
        float sum = 0.0f;
        for (int k = 0; k < width; k++) {
            sum += A[row * width + k] * B[k * width + col];
        }
        C[row * width + col] = sum;
    }
}
```

### 4.4.3 为什么必须做越界保护

主机把全局尺寸**向上取整**到本地尺寸的整数倍（4.5.2 会解释为什么必须取整），取整就意味着**会开出多余的工作项**。`examples/04-matmul-tiled/` 的 case E 把 100×100 取整到 112×112：

```text
=== case E: width=100 TILE=16, global size rounded up to 112 (expect pass) ===
    This is case D with the host-side fix applied. It only works because the
    kernel also guards its loads and stores - the padding work-items share
    local memory with real ones.
    -DTILE=16 global={112,112} local={16,16}=256 work-items, CL_KERNEL_WORK_GROUP_SIZE=256
    ran: 10000/10000 within tolerance, max abs err 0.000e+00
```

112×112 = 12544 个工作项，其中只有 10000 个是有用的。多出的 2544 个：

- 如果内核**读**了越界地址 → 读到别的缓冲区的内容或垃圾
- 如果内核**写**了越界地址 → 写穿缓冲区，可能损坏相邻的内存对象
- 在分块内核里，如果越界的工作项把垃圾写进了 `__local` 共享 tile → **同组所有工作项的结果都被污染**，不只是它自己

所以 `matmul_tiled.cl` 里那段注释不是可有可无的说明，它是这段代码**能算对的原因**：

```c
        // Boundary guard, and it is load-bearing. The host rounds the global size up
        // to a multiple of TILE, so some work-items have row or col past the matrix.
        // Without this guard those work-items read out of bounds and write garbage
        // INTO THE SHARED TILE - which then corrupts every other work-item in the
        // group, not just themselves. A missing guard here produces wrong numbers
        // across a whole tile, which is much harder to diagnose than a crash.
        tileA[localRow][localCol] = (row < width && aCol < width) ? A[row * width + aCol] : 0.0f;
        tileB[localRow][localCol] = (bRow < width && col < width) ? B[bRow * width + col] : 0.0f;
```

注意它填的是 `0.0f` 而不是跳过赋值。填 0 让乘法项变成 0，累加结果不受影响；跳过赋值则让 `__local` 里留着上一轮 tile 的旧数据，结果就错了。

## 4.5 两条硬约束，一个错误码

本机 OpenCL 1.2 设备上，`clEnqueueNDRangeKernel` 只有两条几何约束，违反**任何一条**都返回同一个 `-54 CL_INVALID_WORK_GROUP_SIZE`。这个错误码起得很糟——它听起来像资源不足，实际是参数不合法。

### 4.5.1 约束一：工作组的总工作项数 ≤ `CL_DEVICE_MAX_WORK_GROUP_SIZE`

多维时算的是**乘积**。UHD 630 的上限是 256，所以：

| `local_work_size` | 乘积 | 结果 |
|---|---|---|
| `{8, 8}` | 64 | ✅ |
| `{16, 16}` | 256 | ✅ 刚好等于上限 |
| `{32, 32}` | 1024 | ❌ `-54` |
| `{256}` | 256 | ✅ |
| `{512}` | 512 | ❌ `-54` |

`examples/04-matmul-tiled/` 的 case A 就是那个失败：

```text
=== case A: width=256 TILE=32, global size rounded (expect launch rejection) ===
    32*32 = 1024 work-items per group; this device caps groups at 256.
    Local memory is NOT the constraint: two 32x32 float tiles are 8192 B.
    -DTILE=32 global={256,256} local={32,32}=1024 work-items, CL_KERNEL_WORK_GROUP_SIZE=256
    launch rejected -> -54 CL_INVALID_WORK_GROUP_SIZE
    as documented: rejected with -54 CL_INVALID_WORK_GROUP_SIZE
```

**注意它明确排除了另一个嫌疑：本地内存不是瓶颈。** 两个 32×32 的 float tile 是 8192 字节，iGPU 有 65536 字节，绰绰有余。超限的纯粹是工作项个数。这个区分很重要，因为它决定了你该往哪个方向调：如果是内存超限，减小 tile 的**数据量**（比如改用 `float` 之外的类型或减少 tile 个数）；如果是工作项超限，只能减小 tile 的**边长**。

case B 和 case C 是同一份内核源码、同一个矩阵、只换 `-DTILE`：

```text
=== case B: width=256 TILE=16, global size rounded (expect pass) ===
    -DTILE=16 global={256,256} local={16,16}=256 work-items, CL_KERNEL_WORK_GROUP_SIZE=256
    ran: 65536/65536 within tolerance, max abs err 0.000e+00

=== case C: width=256 TILE=8, global size rounded (expect pass) ===
    -DTILE=8 global={256,256} local={8,8}=64 work-items, CL_KERNEL_WORK_GROUP_SIZE=256
    ran: 65536/65536 within tolerance, max abs err 0.000e+00
```

**max abs err 都是 `0.000e+00`** ——不是"在容差内"，是逐位相同。所以 TILE=32 的失败与数值精度、与算法都无关，纯粹是几何约束。

### 4.5.2 约束二：全局尺寸必须是本地尺寸的整数倍（逐维）

这是本次验证中查出来、**原始资料完全没提**的一条。在 OpenCL 1.2 设备上：

```text
global_work_size[d] % local_work_size[d] == 0    对每一维 d 都成立
```

不满足就 `-54`，**即使内核对每一次访存都做了越界保护**。case D 就是专门证明"内核没问题、几何有问题"：

```text
=== case D: width=100 TILE=16, global size NOT rounded (expect launch rejection) ===
    100 % 16 = 4, so the geometry is not divisible even though the kernel
    guards every load and store. The kernel is not the problem.
    -DTILE=16 global={100,100} local={16,16}=256 work-items, CL_KERNEL_WORK_GROUP_SIZE=256
    launch rejected -> -54 CL_INVALID_WORK_GROUP_SIZE
    as documented: rejected with -54 for a divisibility reason
```

修正方法是**主机向上取整 + 内核越界保护**，两半缺一不可：

```c
// examples/common/ocl_util.h
static size_t ocl_round_up(size_t n, size_t multiple) {
    if (multiple == 0) return n;
    return ((n + multiple - 1) / multiple) * multiple;
}
```

```c
// 主机侧：逐维取整
size_t global[2] = { ocl_round_up((size_t)width, TILE),
                     ocl_round_up((size_t)width, TILE) };
size_t local[2]  = { TILE, TILE };
```

```c
// 内核侧：读和写都要保护
tileA[localRow][localCol] = (row < width && aCol < width) ? A[row * width + aCol] : 0.0f;
...
if (row < width && col < width) {
    C[row * width + col] = sum;
}
```

**只取整不保护**：多余的工作项写穿输出缓冲区。
**只保护不取整**：`-54`，内核根本没机会跑。
**两者都做**：case E，10000/10000 全对，max abs err 0.000e+00。

> 顺带一条可移植性提示：OpenCL 2.0 起放宽了这条约束，允许全局尺寸不是本地尺寸的整数倍。但**本机两块 GPU 都只到 OpenCL C 1.2**，而且主机 API 的宽松程度和内核语言级别是两件事（见 [01 篇 1.4](./01-opencl-overview.md#14-三个版本字符串问的根本不是同一件事)），所以按最严格的情况写：永远取整。`ocl_round_up` 在本来就整除时是空操作，没有代价。

### 4.5.3 完整的实测矩阵

`examples/04-matmul-tiled/` 的汇总：

```text
=== summary ===
device Intel(R) UHD Graphics 630, CL_DEVICE_MAX_WORK_GROUP_SIZE=256
case A TILE=32            : launch rejection is the documented outcome
case B TILE=16            : pass
case C TILE=8             : pass
case D width=100 unrounded: launch rejection is the documented outcome
case E width=100 rounded  : pass
unexpected outcomes       : 0
[RESULT] PASS
```

`unexpected outcomes: 0` 是这一节的关键：**两个失败 case 是预期结果，不是错误。** 一个把所有断言都写成"必须通过"的示例证明不了限制真实存在——它只能证明你没撞上限制。要证明限制是真的，就得让程序去撞它，然后断言"撞到了、而且是以文档描述的方式撞到的"。

## 4.6 两个工作组上限，不是一回事

case A 的输出里有一行容易被忽略：

```text
local={32,32}=1024 work-items, CL_KERNEL_WORK_GROUP_SIZE=256
```

请求的是 1024，内核报告的上限是 256。这两个数来自两个不同的查询：

| 查询 | 属于 | 含义 | 本例的值 |
|------|------|------|---------|
| `CL_DEVICE_MAX_WORK_GROUP_SIZE` | `clGetDeviceInfo` | **设备**能接受的工作组上限 | 256 |
| `CL_KERNEL_WORK_GROUP_SIZE` | `clGetKernelWorkGroupInfo` | **这个具体内核**在这个设备上的上限 | 256 |

两者可以不同，而且**本机上就不同**。用 `cl-build-probe` 查四个内核（含一个几乎什么都不做、不用 `__local` 的 `level_probe`）：

| 设备 | `CL_DEVICE_MAX_WORK_GROUP_SIZE` | 四个内核的 `CL_KERNEL_WORK_GROUP_SIZE` |
|---|---|---|
| Intel UHD 630 | 256 | 256 / 256 / 256 / 256 |
| Intel i7-9700 CPU | 8192 | 8192 / 8192 / 8192 / 8192 |
| **NVIDIA RTX 2060** | **1024** | **256 / 256 / 256 / 256** |

NVIDIA 那一行是关键：**连一个不用本地内存、几乎没有计算的内核也只报 256**。所以常见的解释——"寄存器用得多的内核会被驱动压低"——在这里不成立，它是这个驱动对所有内核的实际上限，和设备宣称的 1024 无关。寄存器压力确实可能压低某个具体内核，但**不能指望"我的内核很简单所以内核上限等于设备上限"**。

**规则是取两者中较小的那个。** 设备上限是硬天花板，内核上限是"这个内核在这台设备上的实际情况"。只查设备上限，你会以为能开 1024；只查内核上限，你在换内核后可能超限。

按设备数字算分块尺寸的代价是具体的：`TILE²≤1024` 给出 `TILE≤32`，而实际上限 256 只允许 `TILE≤16`——**差 2 倍，方向是让你写出启动不了的代码**（[06 篇 §6.7.3](./06-kernel-programming.md)）。

`clGetKernelWorkGroupInfo` 还返回另外两个对性能调优有用的值：

| 查询 | 含义 |
|------|------|
| `CL_KERNEL_LOCAL_MEM_SIZE` | 这个内核**静态**用到的 `__local` 字节数（不含主机通过 `clSetKernelArg(..., NULL)` 动态分配的部分） |
| `CL_KERNEL_PRIVATE_MEM_SIZE` | 每个工作项的 `__private` 内存字节数 |

`tools/cl-build-probe/` 每次编译后都会打印这三个值——这也是它作为**内核编译级**通道的价值：不用写主机程序、不用跑内核，就能知道某个内核对资源的要求。

```powershell
cd tools\cl-build-probe
.\build.ps1
.\cl-build-probe.exe fixtures\matmul_good.cl matrix_mul UHD -DTILE=16
```

## 4.7 `local_work_size = NULL` 意味着什么

`clEnqueueNDRangeKernel` 的 `local_work_size` 可以传 `NULL`，让驱动自己选分组。原始资料的向量加法就是这么写的。

| | 传具体值 | 传 `NULL` |
|---|---|---|
| 分组由谁决定 | 你 | 驱动 |
| 会不会撞上 4.5.2 的整除约束 | **会**，必须自己取整 | **不会**，驱动会挑一个整除的 |
| 能不能用 `__local` 内存分块 | 能，且你知道 tile 尺寸 | 危险——`get_local_size(0)` 只有运行时才知道 |
| 能不能做性能调优 | 能 | 不能 |
| 可移植性 | 需要针对设备上限写 | 驱动兜底 |

**这解释了原始资料为什么从来没撞上 `-54`**：它传了 `NULL`，所以驱动自己保证了几何合法。代价是它对执行形状**一无所知**，也就无法做任何依赖工作组结构的优化——分块、归约、子组，全都做不了。

本教程的选择是：**永远显式给 `local_work_size`**，然后自己负责取整和保护。这样：

- 内核里的 `__local` 数组尺寸是编译期常量
- 性能可以调
- 4.5 节的两条约束变成**你知道并主动处理**的事情，而不是某天换台设备就冒出来的意外

`ocl_round_up` 就是为此存在的。

## 4.8 内存层次与执行层次的对应

执行层次（4.3）和内存层次（[06 篇](./06-kernel-programming.md) 详解）是一一对应的，这个对应关系是理解 OpenCL 性能的关键：

```text
执行层次                     内存空间              作用域          本机 UHD 630
─────────────────────────    ──────────────────    ─────────────   ──────────────
Device                  ◄──► __global               全部工作项       6488 MiB
                             __constant             全部工作项（只读）
Compute Unit            ◄──► （无直接对应）
work-group              ◄──► __local                工作组内         64 KiB / 组
work-item               ◄──► __private              单个工作项       寄存器 + 溢出
```

**作用域越窄，越快、越小。** `__local` 是片上存储（`CL_DEVICE_LOCAL_MEM_TYPE == CL_LOCAL`），访问延迟远低于 `__global`；分块优化的全部原理就是"把反复用到的数据从 `__global` 搬进 `__local`，让一个工作组的 256 个工作项共享"。

`examples/04-matmul-tiled/` 的注释里给了具体的字节数：

```c
    // Two tiles live in local memory for the whole work-group. At TILE=16 that is
    // 2 * 16 * 16 * 4 = 2048 bytes; at TILE=32 it is 8192 bytes. Both fit the iGPU's
    // 64 KB, so local memory SIZE is not what breaks TILE=32 - the work-item count
    // is. See the comment in the host program.
    __local float tileA[TILE][TILE];
    __local float tileB[TILE][TILE];
```

### 4.8.1 但 Intel CPU 设备上这个对应关系不成立

本机第三个设备（i7-9700 CPU）的 `CL_DEVICE_LOCAL_MEM_TYPE` 是 **`CL_GLOBAL`**，不是 `CL_LOCAL`：

```text
      local mem        : 262144 B (CL_GLOBAL, backed by global memory - tiling buys nothing here)
```

意思是它的 `__local` 内存**由全局内存充当**，不是片上存储。所以在 CPU 设备上做本地内存分块，**买不到任何带宽优势**——你只是把数据从一个全局缓冲区搬到另一个全局缓冲区。

这条实测结果有一个直接的实践含义：

> **本地内存分块是一堂 GPU 的课，不要在 CPU 设备上做基准测试来验证它的收益。** 你会得到"分块没用"的错误结论，而这个结论只对 `local_mem_type == CL_GLOBAL` 的设备成立。

`examples/01-device-query/` 之所以要打印 `CL_DEVICE_LOCAL_MEM_TYPE`，就是为了让这个区别在日志里看得见。

## 4.9 本机三设备的执行层次对比

| | RTX 2060 | **Intel UHD 630** | i7-9700 CPU |
|---|---|---|---|
| Compute Unit 数 | 30 | **24** | 8 |
| `max_work_group_size` | 1024 | **256** | 8192 |
| `max_work_item_sizes` | 1024×1024×64 | **256×256×256** | 8192×8192×8192 |
| `max_work_item_dimensions` | 3 | 3 | 3 |
| `__local` 每工作组 | 48 KiB | **64 KiB** | 256 KiB（但是 `CL_GLOBAL`） |
| `local_mem_type` | CL_LOCAL | **CL_LOCAL** | **CL_GLOBAL** |

注意 `max_work_item_sizes` 这一行，它管的是**单维**上限，和 `max_work_group_size` 管的**乘积**上限是两个独立的约束：

| 约束 | 查询项 | 违反时的错误码 |
|------|-------|--------------|
| 工作组内工作项**总数**（各维乘积） | `CL_DEVICE_MAX_WORK_GROUP_SIZE` | `-54 CL_INVALID_WORK_GROUP_SIZE` |
| **单独某一维**的工作项数 | `CL_DEVICE_MAX_WORK_ITEM_SIZES[d]` | `-55 CL_INVALID_WORK_ITEM_SIZE` |

在 UHD 630 上这两个数恰好都是 256，所以单维约束很难单独触发——`local = {512, 1}` 的乘积 512 已经先撞了 `-54`。要看清单维约束，得用 NVIDIA 那台设备：它的 `max_work_group_size = 1024`、`max_work_item_sizes = 1024 × 1024 × 64`，于是 `local = {1, 1, 128}` 的乘积只有 128，远低于 1024，但第三维超过了 64 —— 这是**只有单维约束在起作用**的形状。

> 诚实边界：上表里的 `max_work_item_sizes` 数值是 `tools/clinfo-probe/` 实测的设备元数据；`-55` 这个归属来自 OpenCL 规范对 `clEnqueueNDRangeKernel` 的定义，本机**没有**实际下发过这样一个越界的三维启动去撞它。要自己验证，把 `examples/04-matmul-tiled/` 的 `deviceHint` 改成 `NVIDIA`、`local` 改成三维即可。

`CL_DEVICE_MAX_WORK_ITEM_DIMENSIONS = 3` 是 OpenCL 规范要求的下限，三台设备都是 3。

**写可移植代码的方式是查询，不是硬编码：**

```c
// size_t, NOT cl_uint. CL_DEVICE_MAX_WORK_GROUP_SIZE returns size_t; receiving it
// into a 4-byte cl_uint makes the driver reject the query with CL_INVALID_VALUE
// and leave the variable at 0, which then prints as a confident and completely
// fictitious "max work group size: 0".
size_t maxWG = 0;
clGetDeviceInfo(dev, CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(maxWG), &maxWG, NULL);

size_t local = 256;
if (local > maxWG) local = maxWG;
```

这个 `size_t` 的坑在 [01 篇 1.4.2](./01-opencl-overview.md#142-一个查询类型的坑size_t-不是-cl_uint) 讲过；它在这里的后果特别严重，因为查到 0 之后，`if (local > maxWG)` 会把 `local` 也压成 0，然后 `-54`，而你会去怀疑内核。

## 4.10 本篇要点

1. **并行度由主机决定，不在内核里。** 内核只写"我处理第几个"，"一共几个"是 `clEnqueueNDRangeKernel` 说的。
2. **索引算术只有一条公式**：`global_id = group_id * local_size + local_id`，逐维独立。
3. **两条几何约束，一个 `-54`**：工作组乘积 ≤ `CL_DEVICE_MAX_WORK_GROUP_SIZE`；全局尺寸逐维整除本地尺寸。多维时单维还受 `max_work_item_sizes[d]` 限制。
4. **修正 `-54` 的两半**：主机 `ocl_round_up` + 内核越界保护。缺一个都不行。
5. **`CL_KERNEL_WORK_GROUP_SIZE` 和 `CL_DEVICE_MAX_WORK_GROUP_SIZE` 取较小者。**
6. **工作组之间无法同步** → 归约必须两轮。
7. **`local_mem_type == CL_GLOBAL` 的设备上，本地内存分块没有带宽收益。**
8. **永远查询，不要硬编码 256 或 1024**，而且要用 `size_t` 接。

---

上一篇：[03-first-program.md](./03-first-program.md) ｜ 下一篇：[05-core-concepts.md](./05-core-concepts.md) —— Platform / Device / Context / Queue / Buffer / Image / Event 七类对象逐个讲清，含每个对象的生命周期与本机实测的坑。
