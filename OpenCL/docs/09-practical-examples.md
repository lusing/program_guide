# 9. 实战篇：六个原始示例的实测归属，与两个新工程

前八篇拆的是构件：平台、设备、上下文、队列、缓冲区、图像、事件、内核语言、C++ 绑定、SPIR-V。这一篇把它们装回完整程序，回答一个具体问题——**原始资料给的那六个"实用示例"，在本机三台设备上分别跑成什么样？**

答案是：六个里有 **两个从未编译通过**，另外四个各有一处会让结果错误但**不报错**的缺陷。这一篇逐个给出归属、实测结论与设备，然后把两个原始资料没有、但本机恰好能演示的工程讲透：

- **`examples/10-multi-device`**：跨平台多设备并行。它同时是一堂**计时方法论**课——本机同一份未改动的二进制，串行基线在 1.36 ms 到 6.70 ms 之间摆动，所以"分片有没有加速"这个问题，用一个样本问是问不出来的。
- **`examples/11-ocl3-features`**：2.x/3.x 特性的**能力门控**。它证明版本字符串在本机三台设备上**都不预测任何事**，并且抓到了一台设备广告了却交付不了的特性。

> **验证方式说明**：本篇全部结论来自**运行时数值级**通道，即 `examples/` 下 11 个工程在本机实跑的输出。复现方式统一是仓库根目录的 `.\build.ps1`（编译 + 运行 + 判定 `[RESULT] PASS`），或 `.\build.ps1 -Examples 10-multi-device` 单跑一个。凡引用设备元数据处来自 `tools\clinfo-probe\`；凡引用规范措辞处标为**规范级**；本机无法验证的一律进 9.8 与"诚实边界"。**本篇不含任何未实跑的代码。**

## 9.1 六个原始示例 → 六个工程

原始资料的"OpenCL 实用示例"一节给了六段代码。下表是它们的归属与实测结论，逐项在 9.2–9.6 展开：

| 原示例 | 落到哪个工程 | 原文的问题 | 本机实测结论 |
|---|---|---|---|
| 示例 1：矩阵乘法 | `examples/03-matmul-naive` | `__const float*` —— **不是 OpenCL C**，任何设备都编不过 | 改成 `__global const float*` 后 256×256 与 CPU 参考逐项相同（UHD 630） |
| 示例 2：本地内存优化矩阵乘法 | `examples/04-matmul-tiled` | ①`__const` 同上；②`tileA[32][32]` 写死，核显工作组上限 256 → `-54`；③加载无边界保护；④`global` 未向上取整 | `TILE=32` 在 UHD 630 上 `-54 CL_INVALID_WORK_GROUP_SIZE`；`TILE=16`/`8` 结果精确 |
| 示例 3：归约求和 | `examples/05-reduce-sum` | ①stride 折半在非 2 次幂组大小下**丢值且不报错**；②只写了每组一个输出，缺第二轮跨组归约 | `localSize=100` 时 100 个值里 **36 个被丢下**，总和 2559 对精确值 3997；`localSize=64` 时同一内核完全正确 |
| 示例 4：图像亮度调整 | `examples/06-image-brightness` | 采样器本身没问题，但原文没有说明 `CLK_NORMALIZED_COORDS_*` 的含义 | 用 `CLK_NORMALIZED_COORDS_TRUE` 配整数像素坐标，64×64 渐变图**塌成 4 种颜色**，而 1089/4096 个像素**碰巧仍是对的**，没有任何 API 报错 |
| 示例 5：异步数据传输 | `examples/07-async-events` | 代码本身正确，但原文没说"漏 wait-list 会怎样" | 乱序队列上漏掉 wait-list，20 次里 **10 次** combine 内核在 producer 完成前就启动，而输出 **20/20 数值正确** |
| 示例 6：多设备并行 | `examples/10-multi-device` | ①`clSetKernelArg(kernel, ...)` 里那个 `kernel` **不属于 `contexts[i]`**；②按 `totalCount / numDevices` 均分，最后一个设备拿余数，但没有向上取整到 `local` 的倍数；③假设一个平台有多个设备 | 跨 context 用 kernel：`-38` 与 `-48`（9.6.2）。跨平台单 context：**直接段错误 `0xC0000005`**，不给错误码（9.6.3）。均分反而更慢：0.39x（9.6.5） |

有一处需要说清楚：**上表第 3 列的"问题"不是笔误级别的**。示例 1 和示例 2 的内核在本机三台设备上**一台都编不过**，报错是：

```
error: pointer arguments to kernel functions must reside in '__global', '__constant' or '__local' address space
```

`__const` 不是 OpenCL C 的关键字。编译器把它读成"这个指针没有地址空间"，而内核参数必须有。正确写法是 `__global const float*`——`__global` 是地址空间，`const` 是 C 的限定符，两者不是同一个维度的东西，不能互相替代。所以原始资料那六个"实用示例"里，有 **两个从未在任何设备上编译成功过**。

> 示例 3、4、5 的缺陷更危险，因为它们**编译通过、运行成功、返回 `CL_SUCCESS`，只是结果是错的**（示例 5 甚至结果是对的，只是同步是坏的）。这三条的详细拆解分别在 [05 篇 §5.6](./05-core-concepts.md)、[06 篇 §6.8](./06-kernel-programming.md) 与 `examples/05`、`examples/06`、`examples/07` 的文件头注释里。本篇不重复，只把结论归位。

## 9.2 一个工程该长什么样：统一的验证契约

11 个工程共用一套约定，这套约定本身就是本篇要讲的东西之一——因为它决定了"跑过了"这句话有没有含义。

**目录形状**：每个 `examples/<name>/` 下只有一个 `main.c` 或 `main.cpp`，需要内核时配一个 `kernels/*.cl`。没有 CMakeLists、没有 `.sln`、没有多文件拆分。`build.ps1` 遍历目录，见到 `main.c`/`main.cpp` 就编译。

**判定契约**：

```
退出码 0  且  stdout 含 "[RESULT] PASS"   -> PASS
stdout 含 "[RESULT] FAIL"                -> FAIL
stdout 含 "[RESULT] SKIP" 且退出码 0      -> SKIP（前置条件确实不存在）
没有 [RESULT] 行                         -> FAIL（崩溃或输出被截断都不许蒙混）
```

最后一条是 `build.ps1` 里写死的兜底：把"没有结论"当成 FAIL 而不是 PASS，否则一个段错误的示例会以"脚本没报错"的形式混过去。`examples/09-spirv-il` 在还没有 `.spv` 时走 SKIP 分支，这是诚实的跳过，不是失败。

**设备选择**：全部按**设备名匹配**，默认 `"UHD"`，绝不用 `platforms[0]`。本机 `platforms[0]` 是 NVIDIA CUDA，不是 Intel——[01 篇 §1.3](./01-opencl-overview.md) 有实测表。

**输出纪律**：每一个打印出来的值都**带着它的错误码**。这条不是洁癖，是被逼出来的：`examples/11` 第一版把 `clSetKernelArg` 的 `-38` 打印成"元素不对"，于是三台设备看起来都像违背了自己广告的 SVM 能力（9.7.3）。

**共享工具**：`examples/common/ocl_util.h` 提供 `ocl_pick_device`、`ocl_err_name`、`ocl_read_file`、`ocl_round_up`、`ocl_report`、`ocl_report_skip`。它在包含 `<CL/cl.h>` **之前**定义 `CL_TARGET_OPENCL_VERSION 300`——这个值不能降到 120，[02 篇 §2.5](./02-environment-setup.md) 有实测：降到 120 后头文件会把所有 2.x 入口点藏起来，`clCreateCommandQueueWithProperties` 直接编不过。

## 9.3 `examples/04`：分块矩阵乘法与两个工作组上限

这是六个原示例里改动最多的一个，值得单独说，因为它的失败模式**跨厂商不一致**。

原文写死 `__local float tileA[32][32]`，即 `local = {32, 32}` = **1024 个工作项**。本机实测：

| 设备 | `CL_DEVICE_MAX_WORK_GROUP_SIZE` | `CL_KERNEL_WORK_GROUP_SIZE`（`matmul_tiled`） | `TILE=32`（local 1024） |
|---|---|---|---|
| Intel UHD 630 | **256** | 256 | `-54 CL_INVALID_WORK_GROUP_SIZE` |
| Intel i7-9700 CPU | 8192 | 8192 | 通过 |
| NVIDIA RTX 2060 | **1024** | **256** | 通过（但只有 4 倍余量，不是 32 倍） |

第二列和第三列在 NVIDIA 上**不相等**，这是本篇最重要的一条可移植性结论：

> **算分块上限要用 `CL_KERNEL_WORK_GROUP_SIZE`，不是 `CL_DEVICE_MAX_WORK_GROUP_SIZE`。** RTX 2060 的设备级上限报 1024，而它上面**每一个**内核都报 256——包括完全不使用 `__local` 内存的 `level_probe`，所以"寄存器压力把它压低了"这个常见解释在这里不成立。用设备级数字去算，会得到 `TILE ≤ 32`；真实答案是 `TILE ≤ 16`。**差 2 倍，而且差在"代码启动不了"的那个方向。** 两台 Intel 设备在内核级与设备级报同一个值（256 / 8192），所以这个分歧**只有在 NVIDIA 上测才会暴露**。

`examples/04` 因此把三个 `TILE` 都跑一遍（32 / 16 / 8），让 `-54` 出现在输出里而不是被"我这儿能跑"掩盖掉。它还单独跑一次 `width=100`，演示另一条独立约束：

> **`global_work_size` 必须是 `local_work_size` 的整数倍。** 100×100 的矩阵配 `local=16×16`，即便内核**已经**做了边界保护，仍然 `-54`。宿主端要把 global 尺寸**向上取整**，内核端要保护**写入**——这是两件事，原文一件都没做。

`CL_KERNEL_LOCAL_MEM_SIZE` 也不能手算：`matmul_tiled` 在 `TILE=8/16/32` 下两台 Intel 设备报的正是手算值 512/2048/8192，而 NVIDIA 报 **516/2052/8196**——恒定 **+4 字节**，与 `TILE` 无关；不用本地内存的内核在 Intel 上报 `0`，在 NVIDIA 上报 `1`。**编译后查询，永远不要手算。**

> **诚实边界**：本地内存分块在 **Intel CPU 设备上没有收益可言**——它报 `CL_DEVICE_LOCAL_MEM_TYPE = CL_GLOBAL`，即它的 `__local` 就是全局内存背书的。所以"分块加速"是一个**iGPU 课题**，不要在 CPU 设备上跑基准然后期待加速。

## 9.4 `examples/05`：归约，与一个能通过 code review 的缺陷

原文的树形归约：

```c
for (int stride = groupSize / 2; stride > 0; stride >>= 1) {
    if (localId < stride) {
        temp[localId] += temp[localId + stride];
    }
    barrier(CLK_LOCAL_MEM_FENCE);
}
```

这段代码在 `groupSize` 是 2 的幂时**完全正确**，这也是它能活过 review 的原因。`localSize=64` 时本机实测逐项精确。

`localSize=100` 时它**静默丢值**。实测：stride 依次是 50、25、12、6、3、1，把 64 个值折进 `temp[0]`；**32 个留在 `temp[2]`，4 个留在 `temp[24]`**。`temp[24]` 之所以够不着，是因为 stride=12 那一轮需要 `localId=12`，而守卫是 `localId < 12`。总和 **2559**，精确值 **3997**。

修法不是"把组大小限制成 2 的幂"，而是**顺序寻址**：

```c
for (int stride = 1; stride < groupSize; stride *= 2) {
    int index = 2 * stride * localId;
    if (index < groupSize) {
        temp[index] += temp[index + stride];
    }
    barrier(CLK_LOCAL_MEM_FENCE);
}
```

`examples/05` 两个版本都跑，并且额外跑 `N=1000` 与非 2 次幂组大小，让缺陷**出现在输出里**。它还有第二轮**跨组归约**——原文只写了每组一个输出，没有人把它们加起来，那不是一个求和，是一个部分和数组。

> 测试数据要**全为正**。零均值的测试模式会让一个错误的总和落在正确答案附近，断言因为错误的原因通过。这条是从 `examples/05` 的开发过程里来的，不是理论顾虑。

## 9.5 `examples/06`：图像，与一个不报错的采样器陷阱

原文的采样器定义本身是对的：

```c
const sampler_t smpSampler = CLK_NORMALIZED_COORDS_FALSE |
                             CLK_ADDRESS_CLAMP_TO_EDGE |
                             CLK_FILTER_NEAREST;
```

但原文没有解释 `CLK_NORMALIZED_COORDS_*` 是什么，而这正是会出错的地方：

> **`CLK_NORMALIZED_COORDS_TRUE` 会把坐标乘以图像尺寸。** 把整数像素索引喂给归一化采样器，得到的是 `s = x * width`，于是每个 `x >= 1` 都撞在 `CLAMP_TO_EDGE` 上饱和，只有 `x == 0` 逃出来。

本机实测：64×64 渐变图，用 `TRUE` 之后**塌成恰好 4 种颜色**——texel `(0,0)`、`(0,63)`、`(63,0)`、`(63,63)`。而 **1089/4096 个像素碰巧仍然是对的**。没有任何 API 调用报告任何事。

这个"碰巧对了 27%"才是真正危险的部分：一个粗略的目视检查或小规模测试会放过它。`examples/06` 因此逐像素做 epsilon 比对，并且**统计不同颜色的数量**，让塌缩变成可断言的信号。

> **诚实边界**：图像格式支持列表只在 **Intel UHD 630** 上测过。`CL_ARGB` 在别的设备上可能受支持也可能不受支持。所以那段打印格式的代码不是"打印信息"，而是**每个程序启动时都该跑一遍的前置检查**。

## 9.6 `examples/10`：多设备并行，与"我怎么知道它真的并行了"

原文示例 6 的意图是对的——多设备分片、各自独立的 context/program/kernel。它有三处会让代码跑不起来或者跑出错误结论，`examples/10` 把三处都变成了**正面演示**。

### 9.6.1 工程形状

三台设备，各自一个 slot：

```
=== step 3: a separate context, program and kernel per device ===
[setup] NVIDIA GeForce RTX 2060 [GPU] local=256 (kernel 256 / device 1024)
[setup] Intel(R) UHD Graphics 630 [GPU] local=256 (kernel 256 / device 256)
[setup] Intel(R) Core(TM) i7-9700 CPU @ 3.00GHz [CPU] local=8192 (kernel 8192 / device 8192)
```

注意 `local` 的括号里同时印了内核级与设备级——NVIDIA 那行 `256 / 1024` 就是 9.3 那条结论的现场证据。

工作量是 `N = 2097152`（每缓冲 8 MiB），内核做 32 轮哈希混合，目的是让内核耗时**远大于**启动开销，否则测的全是驱动开销。

### 9.6.2 一个 `cl_kernel` 不能跨 context

原文示例 6 在最内层循环里写：

```c
cl_mem buffer = clCreateBuffer(contexts[i], CL_MEM_READ_WRITE, ...);
clSetKernelArg(kernel, 0, sizeof(cl_mem), &buffer);
```

那个 `kernel` 是在循环**外面**建的，属于某一个 context；`buffer` 属于 `contexts[i]`。两者不匹配。本机实测两个失败方向，**错误码不同**：

```
=== step 4: use slot 0's kernel with slot 1's resources (must fail) ===
  clSetKernelArg(kernel[0], buffer[1])      -> -38 CL_INVALID_MEM_OBJECT
  clEnqueueNDRangeKernel(queue[1], kern[0]) -> -48 CL_INVALID_KERNEL
  assert both rejected: OK
```

`-38` 说的是"你给我的不是一个属于这个 context 的内存对象"，`-48` 说的是"你给我的不是一个属于这个队列的 context 的内核"。**同一个根本原因，两个不同的错误码，取决于你先撞上哪一道检查。** 这也解释了 9.7.3 里那个 `-38` 为什么容易误读——它不总是"你选错了 context"。

`examples/10` 把这两次调用作为**断言**保留：它们必须失败。一个"必须失败"的断言和"必须成功"的断言同等重要，因为它锁住的是 API 的边界。

### 9.6.3 跨平台单 context：不给错误码，直接崩

```
=== step 5: attempt ONE context holding all 3 devices (in a child process) ===
  -- probe A: no properties --
  [child] clCreateContext(3 devices, no properties) -- if this line is the last one, the call faulted
  [parent] child exit code -1073741819 (0xC0000005)
  -- probe B: CL_CONTEXT_PLATFORM = devices[0]'s platform --
  [child] clCreateContext(3 devices, CL_CONTEXT_PLATFORM = devices[0]'s platform) -- if this line is the last one, the call faulted
  [parent] child exit code -1073741819 (0xC0000005)
```

`clCreateContext` **没有返回 `CL_INVALID_DEVICE`**，它段错误了。两次都是，带不带 `CL_CONTEXT_PLATFORM` 都一样。

因为没有错误码可查，**唯一安全的问法是从一个你输得起的进程里去问**。`examples/10` 用 `CreateProcess` 重新执行自己（带一个只在子进程里生效的命令行开关），父进程读退出码。这也是为什么这个示例的 `main.c` 里有 `setvbuf(stdout, NULL, _IONBF, 0)`——**未刷新的 stdio 缓冲会跟着崩溃的进程一起消失**，而崩溃前打印的最后一行往往正是解释崩溃的那一行。

> **诚实边界**：本机**每个平台恰好只有一个设备**，所以"同一个平台内的多设备 context"这件事在本机**根本无法测试**。上面两个探针都是关于**跨平台**的。要测同平台多设备，需要一台暴露多个设备的机器（比如双卡，或者 Intel CPU 运行时同时暴露多个 CPU 设备的配置）。

### 9.6.4 跨设备的 profiling 时间戳不可比

```
=== step 8: are cross-device profiling timestamps comparable? ===
  NVIDIA GeForce RTX 2060      QUEUED = 1789727631135164384    (1789727631 s)
  Intel(R) UHD Graphics 630    QUEUED = 182543065272500        (182543 s)
  Intel(R) Core(TM) i7-9700 CPU @ 3.00GHz QUEUED = 182543065398200        (182543 s)
  spread across devices: 1789545088069891884 ns (1789545088.070 s)
```

NVIDIA 的纪元是**自 1970 年起的纳秒**（17.9 亿秒 ≈ 56.7 年，对得上），两台 Intel 设备是**自开机起的纳秒**（18.2 万秒 ≈ 2.1 天，也对得上）。跨度 1.79e9 秒。

结论：

> **同一设备上的差值（`END - START`）有效；跨设备的差值没有意义。** 多设备程序里所有的墙钟时间都必须来自宿主的 `QueryPerformanceCounter`。

`examples/10` 的所有毫秒数都来自 QPC，profiling 时间戳只用于**单设备内**的内核耗时，以及这一步的纪元对照。

### 9.6.5 时序：一个样本什么都证明不了

这是本篇最长的一节，因为它踩过的坑最多。先看最终输出：

```
=== step 9: timings ===
  each mode ran 3 times; the figure quoted is its FASTEST round and the bracket
  its slowest. The transcripts above are the last rounds, so they need not match.
                          upload     fastest      slowest     ratio (fastest)
  serial on slot 0        1.383 ms       1.628 ms       2.602 ms  (baseline)
  equal split x 3         1.446 ms       4.208 ms       4.651 ms  0.39x vs serial
  calibrated split x 3    1.439 ms       2.065 ms       2.203 ms  0.79x vs serial, 2.04x vs equal
  same plan, drained      1.468 ms       2.514 ms       2.712 ms  1.22x vs calibrated
```

四条方法论结论，每一条都是被一次错误的结论逼出来的：

**① "设备耗时之和 vs 墙钟"不能判断有没有并行。**

直觉做法是：把三台设备的内核耗时加起来，如果和小于墙钟时间，说明它们重叠了。本机数据：`sum of kernel times 1.119 ms vs wall 2.184 ms`。**这个比较什么也证明不了**，因为墙钟里还包含读回、宿主开销、分片调度——这些东西**落在同一个数字里**，你无法把"重叠省下的时间"和"宿主多花的时间"分开。

唯一决定性的做法是 **A/B 对照**：把**完全相同的分片方案**再跑一遍，唯一的区别是在提交循环里多一个 `clFinish`，让每台设备在下一台提交前排空。这就是 `step 7b` 的 "drained control"：

```
  overlap, measured (identical plan: concurrent round vs drained control):
    concurrent  fastest   2.065 ms   slowest   2.203 ms
    drained     fastest   2.514 ms   slowest   2.712 ms
    -> 1.22x at the fastest samples
       every concurrent sample beat every drained one, so the shards DID run
       concurrently and that ratio is outside run-to-run noise.
```

两个区间**完全不重叠**（并发最慢 2.203 < 排空最快 2.514），所以 1.22x 不是噪声。**这才是"它们真的并行了"的证据。**

**② 一个样本没有价值。**

同一个**未改动**的二进制，串行基线在不同次启动里测到：1.36、1.53、1.63、2.17、2.65、3.63、6.70 ms，其中一次启动内部最慢的单个样本是 18.2 ms。`examples/10` 早先的版本引用"最后一轮"的数字，结果是**结论在两次启动之间翻符号**——一次说"分片赢了 1.46x"，下一次说"分片输了"。

修法：每种模式跑 `WARMUP 2` 轮静默轮 + 1 轮打印轮，报告 **best/worst 区间**，判定用 **best 对 best**。静默轮仍然会**验证数值**——只压制成功的转录，不压制错误的结果，否则一次静默轮里的错答案就被吞了。

**③ "区间严格分离"作为通过条件太脆。**

因为每种模式都要付一次冷启动，最慢样本天然偏高。所以判定用 **best-vs-best 加 10% 死区**，而把区间分离**降级为一行事实性的 caveat**：

```
  range check: split 2.065-2.203 ms vs serial 1.628-2.602 ms -> OVERLAP, so treat the ratio below as indicative only
```

这一行明确告诉读者：串行区间和分片区间**重叠**，所以下面那个 0.79x 只能当指示性的看。早先的版本在这里直接判 INCONCLUSIVE，结果两次最快样本差 40% 就把整个结论抹掉了——那是把诚实做成了无用。

**④ 绝对的 Melem/s 数字不能跨轮比较，轮内比值可以。**

```
  relative throughput (control round, devices taking turns):
    NVIDIA GeForce RTX 2060       6619.75 Melem/s      1.0x slower than the fastest
    Intel(R) UHD Graphics 630      529.60 Melem/s     12.5x slower than the fastest
    Intel(R) Core(TM) i7-9700 CPU @ 3.00GHz   153.62 Melem/s     43.1x slower than the fastest
    NVIDIA GeForce RTX 2060       7529.41 Melem/s   <- same device, alone, in the serial round
    [NOTE] those two agree to within 14% on this run. They have not always:
           other runs of this example have shown them several times apart, in
           both directions. Compare devices WITHIN a round, not across them.
```

同一台 NVIDIA，单独跑时 7529 Melem/s；在多设备轮里，本机观测到过 1489、3989、7157、7219、7500——**偏差两个方向都出现过**。所以那个 NOTE 是**分支写出来的**，不是固定文案：差距大于 1.25 倍时说一套话，否则说另一套。两套都必须存在，因为两种情况都真的发生过。

**最终裁决**：

```
  verdict: splitting did NOT beat running everything on the fastest device
           (2.065 ms against 1.628 ms at the fastest samples, i.e. 0.79x). A shard
           handed to a device 43x slower delays the join by more than it
           relieves the fast one, whether or not the three actually overlapped
```

两次运行分别测到 **0.63x** 和 **0.79x**，重叠增益分别是 **1.16x** 和 **1.22x**，设备间比值分别是 15.7x/42.0x 和 12.5x/43.1x。

> **所以：并行是真的，加速是假的。** 三台设备确实同时在算，但因为另外两台分别慢 12–16 倍和 42–43 倍，交给它们的那一片**拖后腿的时间超过它 relieved 的时间**。分片在两种情况下才划算：设备能力相当，或者最快的那台被别的东西卡住（内存总线、队列已满）。
>
> `examples/10` **不断言任何方向的加速**。数字本身就是测量结果，本篇只负责报告它们出来是多少、以及为什么。

## 9.7 `examples/11`：能力门控，与一台说了做不到的设备

原始资料没有这一节。它对应你在计划里选的"在 Intel CPU 设备上实测 2.x/3.x 特性"，而实测结果**推翻了那个计划里的一句话**：

> 计划原文写 `11-ocl3-features` 的目标设备是 **i7-9700 CPU**，验证方式是"正文明确标注**仅在 OpenCL C 3.0 的 CPU 设备上成立，两块 GPU 均为 1.2**"。
>
> **这句话是错的，而且错得很有教育意义。** Intel UHD 630 广告 `OpenCL C 1.2`，却在显式传入 `-cl-std=CL2.0` 之后**把三项特性全部跑通并逐项验证正确**。本节就是围绕这个发现写的。

### 9.7.1 版本字符串在本机不预测任何事

三台设备的 `CL_DEVICE_VERSION` **都是 `OpenCL 3.0`**。`CL_DEVICE_OPENCL_C_VERSION` 在两块 GPU 上是 `OpenCL C 1.2`，在 CPU 设备上是 `OpenCL C 3.0`。而这个字符串**两个方向都不可靠**：

| | 广告 | 默认 `__OPENCL_C_VERSION__` | 上限 | 实测 |
|---|---|---|---|---|
| i7-9700 CPU | OpenCL C **3.0** | **120** | 3.0 | 广告值是**上限，不是默认值**。省略 `-cl-std` 时连 `work_group_barrier` 都编不过 |
| Intel UHD 630 | OpenCL C **1.2** | 120 | **3.0** | 广告值**连上限都不是**。`-cl-std=CL3.0` 编译通过，构建日志为空 |
| RTX 2060 | OpenCL C **1.2** | **300** | 3.0 | 默认就是 300，与两块 Intel 设备相反 |

最后一列的反向不一致最阴险：`__OPENCL_VERSION__`（注意不是 `__OPENCL_C_VERSION__`）在两块 Intel 设备上**四种选项组合下都固定是 300**，所以 `#if __OPENCL_VERSION__ >= 200` 在那里**恒为真**，会在 1.2 的语言级别上放行 2.0 的代码路径。NVIDIA 让两个宏一起动，所以**只在 NVIDIA 上测过的代码永远暴露不出这个问题**。

正确的查询只有两个：

```
CL_DEVICE_OPENCL_C_ALL_VERSIONS    UHD: 1.0 1.1 1.2 3.0    i7: 3.0 2.0 1.2 1.1 1.0
CL_DEVICE_OPENCL_C_FEATURES        UHD: 14 项               i7: 17 项    NVIDIA: 只有 4 项
```

### 9.7.2 工程的做法：先查、再试、然后对账

`examples/11` 的结构就是这个顺序，而且**顺序是有意义的**——能力表在任何尝试**之前**打印，这样它不可能是照着结果写出来的：

```
=== step 2: what each device advertises (queried before any attempt) ===
  [0] NVIDIA GeForce RTX 2060
      CL_DEVICE_SVM_CAPABILITIES     0x1 (coarse=1 fine=0 fine_system=0 atomics=0)
      CL_DEVICE_OPENCL_C_FEATURES    4 entries; __opencl_c_generic_address_space=no, __opencl_c_subgroups=no
      extensions                     cl_khr_subgroups=no, cl_intel_subgroups=no
  [1] Intel(R) UHD Graphics 630
      CL_DEVICE_SVM_CAPABILITIES     0xB (coarse=1 fine=1 fine_system=0 atomics=1)
      CL_DEVICE_OPENCL_C_FEATURES    14 entries; __opencl_c_generic_address_space=yes, __opencl_c_subgroups=yes
      extensions                     cl_khr_subgroups=yes, cl_intel_subgroups=yes
  [2] Intel(R) Core(TM) i7-9700 CPU @ 3.00GHz
      CL_DEVICE_SVM_CAPABILITIES     0xF (coarse=1 fine=1 fine_system=1 atomics=1)
      CL_DEVICE_OPENCL_C_FEATURES    17 entries; __opencl_c_generic_address_space=yes, __opencl_c_subgroups=yes
      extensions                     cl_khr_subgroups=no, cl_intel_subgroups=yes
```

然后 step 4 **不管广告说什么，四项特性在三台设备上全试一遍**，step 5 对账。每个 (设备, 特性) 有**五种**可能结局，本机五种全部出现：

| 结局 | 含义 | 本机实例 |
|---|---|---|
| 广告了，做到了 | 查询说了实话 | UHD 630 与 i7 CPU 的全部四项 |
| 广告了，做不到 | **违背承诺**，唯一会让本示例 FAIL 的结局 | （修完自己的 bug 之后：无） |
| 广告了，做不到，但诊断证明内核跑了而数据丢了 | **DEFECT**，驱动缺陷，单独计数、不算失败 | RTX 2060 的粗粒度 SVM（9.7.3） |
| 没广告，做不到 | 如广告所说不可用 | RTX 2060 的细粒度 SVM 与子组 |
| 没广告，做到了 | 查询**少报了** | RTX 2060 的 `to_global()` |

最后一行是**发现，不是 bug**。`CL_DEVICE_OPENCL_C_FEATURES` 是一份**承诺清单**，设备可以做得比承诺的多。门控在它上面的代码保持可移植；门控在版本字符串上的代码，既拿不到那份多余的能力，也没有可用的回退路径。

实测矩阵：

```
  device                                  feature               advertised actual
  NVIDIA GeForce RTX 2060                 SVM coarse-grained    yes        DEFECT: advertised, ran, data lost
  NVIDIA GeForce RTX 2060                 SVM fine-grain buffer no         unavailable, as advertised
  NVIDIA GeForce RTX 2060                 to_global()           no         works, but was NOT advertised
  NVIDIA GeForce RTX 2060                 sub_group_broadcast() no         unavailable, as advertised
  Intel(R) UHD Graphics 630               SVM coarse-grained    yes        OK: promised and delivered
  Intel(R) UHD Graphics 630               SVM fine-grain buffer yes        OK: promised and delivered
  Intel(R) UHD Graphics 630               to_global()           yes        OK: promised and delivered
  Intel(R) UHD Graphics 630               sub_group_broadcast() yes        OK: promised and delivered
  Intel(R) Core(TM) i7-9700 CPU @ 3.00GHz SVM coarse-grained    yes        OK: promised and delivered
  Intel(R) Core(TM) i7-9700 CPU @ 3.00GHz SVM fine-grain buffer yes        OK: promised and delivered
  Intel(R) Core(TM) i7-9700 CPU @ 3.00GHz to_global()           yes        OK: promised and delivered
  Intel(R) Core(TM) i7-9700 CPU @ 3.00GHz sub_group_broadcast() yes        OK: promised and delivered
```

**核显四项全过**，这就是推翻计划那句话的证据。子组大小：UHD 630 是 **16**，i7 CPU 是 **8**，local 分别是 256 与 4096。

### 9.7.3 一个被确认的驱动缺陷，以及"确认"这个词的分量

RTX 2060 的 `CL_DEVICE_SVM_CAPABILITIES` 报 `0x1`，即广告 `CL_DEVICE_SVM_COARSE_GRAIN_BUFFER`。实测：`clSVMAlloc` 成功，`clEnqueueSVMMap` 成功，宿主写入的 poison 值**成功落地**，`clSetKernelArgSVMPointer` 成功，`clEnqueueNDRangeKernel` 成功，`clFinish` 成功——然后 1024 个元素**全部还是 poison**。

在没有对照的情况下，这个现象**无法区分**两种原因：驱动忽略了 SVM 存储，或者我的内核根本没跑。所以 `examples/11` 加了一个诊断内核，**一次启动、两个目的地**：

```c
__kernel void svm_cross_check(__global unsigned int* svm, __global unsigned int* regular, unsigned int n)
{
    unsigned int i = get_global_id(0);
    if (i >= n) return;
    regular[i] = 0xC0DE0000u + i;
    svm[i]     = 0xBEEF0000u + i;
}
```

`regular` 是普通 `cl_mem`，`svm` 是 SVM 指针，同一个工作项、同一个下标。实测输出：

```
    SVM coarse-grained (advertised: yes)
      [diagnostic: the ordinary buffer landed 1024/1024, the SVM store did not (1024/1024 wrong)]
      -> 1024/1024 elements wrong, first at i=0 got 4294967295 want 1; kernel ran, SVM store never became visible
```

普通缓冲区 1024/1024 正确，SVM 那半 1024/1024 全错。**工作项确实执行了，丢失的偏偏是 SVM 存储。** 这才叫"确认的驱动缺陷"。

它被分类成 `DEFECT` 而不是 `BROKEN PROMISE`，**不计入失败**，理由是：本示例教的是**怎么门控能力**，不是某个厂商是否合规；一条永久发红的 `build.ps1` 会训练读者忽略红色。但它的计数**永远打印**，不会被 PASS 悄悄吸收：

```
assert no device failed a feature it advertised        : OK (0 broken)
assert at least one feature was numerically verified   : OK (9 verified)
info   features that worked without being advertised   : 1
info   driver defects confirmed by diagnostic          : 1
[RESULT] PASS
```

对读者的实际结论是那条**双重纪律**：**门控在查询上，并且验证第一次结果。** 广告一个能力和交付一个能力不是一回事。

### 9.7.4 `to_global()` 的分歧：断言任何一种答案都是 bug

```
=== step 5b: to_global() given a pointer that is NOT global ===
  device                                  private pointer    local pointer
  NVIDIA GeForce RTX 2060                 NULL               NULL
  Intel(R) UHD Graphics 630               NULL               NULL
  Intel(R) Core(TM) i7-9700 CPU @ 3.00GHz same pointer       same pointer
```

同一个内核，两块 GPU 返回 NULL，CPU 设备**把指针原样还回来**。三台设备上唯一一致的是**有定义的那一种情况**：传一个真指向全局内存的通用指针，拿回同一个指针。这一条三台都过，也是 step 4 唯一断言的部分。

`examples/11` 的第一版**断言了 NULL**，于是对一台什么都没做错的 CPU 设备打印了一个理直气壮的 `BROKEN PROMISE`。这是"假设一个答案"和"测量一个答案"的区别，也是本示例最该被记住的一课。

> **诚实边界**：Khronos 规范对"传入的通用指针不指向对应地址空间时 `to_global` 该做什么"的**原文措辞，本机取不到证**。三条路径都试过：`registry.khronos.org` 的 unified 单页在到达该节前就被截断；bash 里 `curl` 原始 `.adoc` 退出码 56（本机 bash 无外网）；镜像页面被工具策略拦下。所以上面这条**只能作为实测行为陈述，不能作为规范引用**。可确定的本地事实是：clang 的 `opencl-c.h` 把 `to_global`/`to_local`/`to_private`/`get_fence` 声明在 `#if defined(__opencl_c_generic_address_space)` 之下（"OpenCL v2.0 s6.13.9 - Address Space Qualifier Functions"），而 **NVIDIA 并不广告这个特性，却照样编译并正确运行了 `to_global`**——连可用性门控本身也不是被普遍遵守的。
>
> **实用结论**：`to_global` 只用在你确定指向全局内存的指针上。别的地方不要依赖。

### 9.7.5 五个 API 陷阱，全部在 `cl.h` 上核对过

这一节是 `examples/11` 的开发代价，逐条对着本机 `D:\cuda\13.3\include\CL\cl.h` 核对：

**① SVM 指针走 `clSetKernelArgSVMPointer`，不是 `clSetKernelArg`。**

```c
err = firstErr(err, clSetKernelArgSVMPointer(k, 0, p));   // 对
err = firstErr(err, clSetKernelArg(k, 0, sizeof(void*), &p));  // 错：-38 CL_INVALID_MEM_OBJECT
```

`clSetKernelArg` 把它的值当 `cl_mem` **句柄**读，于是回答 `-38`——**一个在从未创建过内存对象的代码里，指名道姓说"内存对象无效"的错误码**。写错这一处，三台设备**全部**看起来像违背了它们的 SVM 承诺：一次跑出 6 个假的 `BROKEN PROMISE`。这也是 9.2 那条"每个值都带错误码"纪律的回报——如果只打印"元素不对"，我会去查驱动。

**② `clEnqueueSVMUnmap` 没有 `blocking_map` 参数。**

`cl.h:1807-1821`：

```c
clEnqueueSVMMap(queue, blocking_map, flags, svm_ptr, size, num_events, wait_list, event)   // 8 个
clEnqueueSVMUnmap(queue, svm_ptr, num_events, wait_list, event)                            // 5 个
```

把这对调用写成对称的（给 Unmap 也传一个 `CL_TRUE`）会**把所有后续参数错位**，报 `C2197: 函数调用中的实际参数太多`。

**③ CUDA 的 `cl.h` 用的是 `clEnqueueSVMMap` / `clEnqueueSVMUnmap`**，不是 OpenCL 2.0 核心名 `clEnqueueMapSVMBuffer` / `clEnqueueUnmapSVMBuffer`。用核心名是 `LNK2019` 对 `OpenCL.lib`。

**④ 特性宏的名字是 `__opencl_c_generic_address_space`**，不是 `__opencl_c_generic_addressing`。拼错的话查询永远返回"无"，而代码看起来完全合理。

**⑤ 扩展字符串必须按 token 匹配，不能 `strstr`。** `cl_intel_subgroups` 是 `cl_intel_subgroups_short` 的**前缀**，而 UHD 630 两个都列。用 `strstr` 会在只有派生扩展的设备上报告基础扩展存在。

顺带一条同族的：两台 Intel 设备在 `__opencl_c_subgroups` 上**一致**（都有），在扩展字符串上**不一致**——只有核显列 `cl_khr_subgroups`，CPU 设备只列 `cl_intel_subgroups`。**同厂商、不同答案**，所以门控要读 FEATURES 数组，不要读扩展列表。

## 9.8 本机不支持、因此**不提供**可运行代码的特性

这一节对应 [01 篇 §1.5](./01-opencl-overview.md) 能力矩阵的最后三行。它们**没有**对应工程，原因不是遗漏，是**硬写一个跑不了的示例比不写更糟**。

| 特性 | 卡在哪一步 | 本机证据 |
|---|---|---|
| **设备端队列**（device enqueue，OpenCL 2.0） | `CL_DEVICE_OPENCL_C_FEATURES` 里没有 `__opencl_c_device_enqueue`；三台设备都没有 | `tools\clinfo-probe\` 的 FEATURES 数组：NVIDIA 4 项、UHD 14 项、i7 17 项，**均无该项** |
| **pipe**（OpenCL 2.0） | 同上，没有 `__opencl_c_pipes`；`clCreatePipe` 无从谈起 | 同上 |
| **C++ for OpenCL 内核语言** | 需要设备前端接受 `-cl-std=CLC++`。NEO **拒绝** `vector_add_cpp.cl`，报 `-11` / `unknown type name 'template'` | `tools\cl-build-probe\build.ps1` 第 9–10 行 |
| **SVM 细粒度系统** / **SVM 原子** | 只有 i7 CPU 广告 `fine_system` 与 `atomics`（`0xF`）；UHD 是 `0xB`（无 fine_system），NVIDIA 是 `0x1`（两者都无） | `examples/11` step 2 |
| **SPIR-V 1.5 / 1.6** | 本机工具链**产不出**（backend 固定 1.4，translator 的 `--spirv-max-version` 是上限不是目标），本机设备也**没有一台广告** | [08 篇 §8.13](./08-spirv.md) 诚实边界 3 |

第三行有一个值得单独说的转折：**NEO 自己的前端拒绝 C++ 内核，不等于 NEO 不能运行 C++ 内核编译出的模块。** 用离线 clang 从**同一份** `vector_add_cpp.cl` 编出的 SPIR-V，在**同一台**拒绝过它的核显上跑到了 **1024/1024 正确**——`clCreateProgramWithIL` 不给驱动留前端。

> **"这个设备编不了 X"和"X 不能在这个设备上跑"是两个不同的主张。** 这两半都是 `tools\cl-build-probe\build.ps1` 第 9–10 行的**常驻硬断言**，而且那两行刻意指向 `..\..\..\examples\09-spirv-il\kernels\`，**不复制文件**——复制会让两边悄悄分叉，主张就变成不可否证的了。完整拆解见 [08 篇 §8.6](./08-spirv.md)。

## 9.9 逐例实测结论与设备归属总表

11 个工程，`.\build.ps1` 一次跑完：**11 passed, 0 failed, 0 skipped**。

| 工程 | 目标设备 | 运行时校验 | 本篇/他篇归属 |
|---|---|---|---|
| `01-device-query` | 三台全部 | 打印基线表，断言平台数 ≥ 1 | [01 篇](./01-opencl-overview.md) |
| `02-vector-add` | UHD 630 | 1024 元素逐一比对 CPU；profiling 时间戳单调 | [03 篇](./03-first-program.md) |
| `03-matmul-naive` | UHD 630 | 256×256 与 CPU 参考比对 | 9.1 |
| `04-matmul-tiled` | UHD 630 | `TILE=32` 触发 `-54`，`16`/`8` 精确；`width=100` 演示 gws 对齐 | 9.3、[06 篇 §6.7](./06-kernel-programming.md) |
| `05-reduce-sum` | UHD 630 | 与 `double` 累加比对；`N=1000` 与非 2 次幂组大小证明原写法会错 | 9.4 |
| `06-image-brightness` | UHD 630 | 64×64 亮度 +0.5 逐像素 epsilon 比对；统计不同颜色数 | 9.5 |
| `07-async-events` | UHD 630 | 链路完成后数值比对；乱序队列上漏 wait-list 的时间戳证据 | [05 篇 §5.7](./05-core-concepts.md) |
| `08-cpp-bindings` | UHD 630 | 与 `02` 同样的校验，走 `cl.hpp` | [07 篇](./07-cpp-bindings.md) |
| `09-spirv-il` | UHD 630 | 数值比对；`.spv` 缺失时 SKIP；在 NVIDIA 上按预期 `-59` 而非崩溃 | [08 篇](./08-spirv.md) |
| `10-multi-device` | **三台并用** | 6 条断言全 OK：跨 context 被拒（`-38`/`-48`）、三种分片方案精确铺满 N、四种轮次全部与 CPU 参考一致 | 9.6 |
| `11-ocl3-features` | **三台并用** | `0 broken`、`9 verified`、`1 unpromised`、`1 defect` | 9.7 |

`examples/11` 的目标设备在计划里写的是"i7-9700 CPU"，实际是**三台并用**——因为把特性只在一台设备上试，就得不到 9.7.2 那张对账表，而对账表才是这个示例的主题。

## 9.10 本章要点

1. **原始资料六个"实用示例"里，两个从未编译通过**（`__const` 不是 OpenCL C），另外四个各有一处**不报错**的缺陷：分块上限写死、归约在非 2 次幂下丢值、采样器归一化坐标、异步链路的 wait-list。
2. **算分块上限用 `CL_KERNEL_WORK_GROUP_SIZE`，不是设备级的那个。** NVIDIA 上两者是 256 与 1024，用错的会得到启动不了的代码。本地内存用量用 `CL_KERNEL_LOCAL_MEM_SIZE`，**编译后查询，永不手算**（NVIDIA 恒定 +4 字节）。
3. **`global` 必须是 `local` 的整数倍**，这是一条独立于边界检查的约束：100×100 配 16×16，即便内核已经保护了加载，仍然 `-54`。
4. **一个 `cl_kernel` 不能跨 context**，两个方向两个错误码：`-38 CL_INVALID_MEM_OBJECT`（参数）与 `-48 CL_INVALID_KERNEL`（下发）。
5. **跨平台 `clCreateContext` 在本机段错误（`0xC0000005`），不给错误码。** 唯一安全的问法是从一个子进程里问。因此 `setvbuf(stdout, NULL, _IONBF, 0)` 不是可选项。
6. **跨设备的 profiling 时间戳不共享纪元**（NVIDIA 自 1970，Intel 自开机）。单设备差值有效，跨设备差值无意义，多设备程序的墙钟一律用 QPC。
7. **"设备耗时之和 < 墙钟"不能证明并行**，因为宿主开销落在同一个数字里。唯一的决定性测试是**相同方案的 A/B**：并发轮 vs 排空轮，本机 1.16–1.22x 且区间不重叠。
8. **本机单次计时样本毫无价值**：同一未改动二进制的串行基线在 1.36–6.70 ms 之间摆。报 best/worst 区间，判定用 best-vs-best 加死区，区间分离单独作为 caveat 陈述。
9. **并行是真的，加速是假的**（0.63–0.79x）：另外两台设备慢 12–16 倍与 42–43 倍，交给它们的分片拖后腿超过它 relieved 的量。示例**不断言任何方向的加速**。
10. **版本字符串在本机三台设备上都不预测任何事。** i7 广告 OpenCL C 3.0 却默认 `__OPENCL_C_VERSION__=120`；UHD 广告 1.2 却能编 `-cl-std=CL3.0`；`__OPENCL_VERSION__` 在两块 Intel 设备上恒为 300，是个陷阱。要 2.x 特性就**显式传 `-cl-std=CL2.0`**。
11. **门控在 `CL_DEVICE_OPENCL_C_FEATURES` / `CL_DEVICE_SVM_CAPABILITIES` 上，然后仍然验证第一次结果。** RTX 2060 广告粗粒度 SVM 却丢失每一次内核存储——这由一个"同一次启动写两个目的地"的诊断内核确认，而不是由推测确认。
12. **设备可以做得比它承诺的多**：RTX 2060 不广告 `__opencl_c_generic_address_space`，`to_global()` 照样跑通。这不是 bug，是门控要写在能力查询上而不是版本字符串上的理由。
13. **SVM 指针走 `clSetKernelArgSVMPointer`**；`clEnqueueSVMUnmap` 比 `clEnqueueSVMMap` **少三个参数**；扩展名要**按 token 匹配**（`cl_intel_subgroups` 是 `cl_intel_subgroups_short` 的前缀）。
14. **`to_global` 对非全局指针的返回值因设备而异**（GPU 给 NULL，CPU 原样返回）。只断言有定义的那一种情况。
15. **本机没有任何设备支持设备端队列与 pipe**，C++ for OpenCL 内核语言被 NEO 前端拒绝——这三项**不提供**可运行代码，只在 9.8 说明卡在哪一步。

### 本机验证状态

| 结论 | 通道 | 复现方式 |
|---|---|---|
| 六个原示例的问题清单与归属 | 内核编译级 + 运行时数值级 | `.\build.ps1`，对应 `examples/03`–`07`、`examples/10` |
| `__const` 被拒的原文报错 | 内核编译级 | `tools\cl-build-probe\build.ps1` |
| `TILE=32` → `-54`；`16`/`8` 精确 | 运行时数值级 | `.\build.ps1 -Examples 04-matmul-tiled` |
| NVIDIA 上 kernel 256 / device 1024 | 设备元数据级 | `tools\clinfo-probe\build.ps1`；`examples\10` step 3 的 `local=` 括号 |
| `CL_KERNEL_LOCAL_MEM_SIZE` 恒定 +4 字节（NVIDIA） | 设备元数据级 | `examples\04` 的三个 `TILE` 各查询一次 |
| 归约在 `localSize=100` 丢 36 个值（2559 对 3997） | 运行时数值级 | `.\build.ps1 -Examples 05-reduce-sum` |
| 归一化坐标使 64×64 塌成 4 色、1089/4096 碰巧正确 | 运行时数值级 | `.\build.ps1 -Examples 06-image-brightness` |
| 漏 wait-list：10/20 次重叠而 20/20 数值正确 | 运行时数值级 | `.\build.ps1 -Examples 07-async-events` |
| 跨 context：`-38` 与 `-48` | 运行时数值级 | `examples\10` step 4（**常驻断言**） |
| 跨平台 `clCreateContext` → `0xC0000005`，两次探针 | 运行时数值级 | `examples\10` step 5（子进程内，父进程读退出码） |
| profiling 纪元：NVIDIA 自 1970 / Intel 自开机 | 运行时数值级 | `examples\10` step 8 |
| 并发 A/B：1.16–1.22x，区间不重叠 | 运行时数值级 | `examples\10` step 7 vs step 7b |
| 串行基线跨启动 1.36–6.70 ms | 运行时数值级 | 反复启动 `build\10-multi-device.exe`（**不在常驻断言里**） |
| 分片未跑赢单设备：0.63x / 0.79x 两次运行 | 运行时数值级 | 同上 |
| 三设备能力表（SVM 位、FEATURES 项数、扩展） | 设备元数据级 | `examples\11` step 2；`tools\clinfo-probe\build.ps1` |
| 四种特性 × 三台设备的对账矩阵 | 运行时数值级 | `examples\11` step 5 |
| UHD 630 四项全过；子组大小 16 / 8 | 运行时数值级 | 同上，step 4 |
| RTX 2060 粗粒度 SVM 缺陷由诊断确认 | 运行时数值级 | 同上，`svm_cross_check`（普通缓冲 1024/1024，SVM 0/1024） |
| `to_global` 非全局指针：GPU→NULL，CPU→原样 | 运行时数值级 | 同上，step 5b |
| `clSetKernelArgSVMPointer` 与 `clSetKernelArg` 的 `-38` 之别 | 主机编译级 + 运行时数值级 | `cl.h:1394`；`examples\11` 第一版的 6 个假 BROKEN PROMISE |
| `clEnqueueSVMMap` 8 参 / `clEnqueueSVMUnmap` 5 参 | 主机编译级 | `cl.h:1807-1821`；写错报 `C2197` |
| `__opencl_c_generic_address_space` 拼写与 clang 的 `#if` 门控 | 文档核对 | `D:\oneAPI\compiler\latest\lib\clang\21\include\opencl-c.h` |
| `to_global` 对非全局指针的**规范原文措辞** | **本机不可验证** | 见 9.7.4 诚实边界 |
| 设备端队列、pipe、同平台多设备 context | **本机不可验证** | 见 9.8 与 9.6.3 诚实边界 |

---

上一篇：[08-spirv.md](./08-spirv.md) ｜ 下一篇：[10-debugging-faq.md](./10-debugging-faq.md) —— API 详解、常见问题与调试技巧：本机实测到的每一个错误码长什么样、归属哪一层，以及"数据是 poison"这句话在什么条件下才能变成对驱动的指控。
