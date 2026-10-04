# 6. 内核编程：语言基础、内建函数、内存空间与分块上限

[05 篇](./05-core-concepts.md) 讲的是宿主侧的七类对象。这一篇越过 `clBuildProgram` 那道边界，讲**设备侧**：OpenCL C 到底是什么语言的子集、有哪些内建函数、四个内存空间各是什么，以及本机上 `max_work_group_size = 256` 和 `local_mem = 64 KiB` 这两个数字如何共同决定分块矩阵乘法的 `TILE` 能开多大。

这一篇有一条**贯穿全篇的实测结论**，先摆在这里，后面每一节都会回到它：

> **`CL_DEVICE_OPENCL_C_VERSION` 不能预测一个内建函数能不能编译，而 `__OPENCL_VERSION__` 更不能。** 真正决定内核语言等级的是另一个宏 `__OPENCL_C_VERSION__`，而它的**默认值由厂商决定**：本机两个 Intel 设备默认是 `120`，NVIDIA 默认是 `300`。这就是为什么同一个 `work_group_barrier` 在 Intel 上不加 `-cl-std` 就编译失败（`-11`），在 NVIDIA 上连显式 `-cl-std=CL1.2` 都能过。

> **验证方式说明**：本篇的主要证据通道是**内核编译级**——`tools/cl-build-probe/cl-build-probe.exe` 把 `fixtures/*.cl` 真交给驱动的在线编译器，打印真实 build log 与 `clGetKernelWorkGroupInfo` 的三个资源数字。6.2、6.3、6.7 的表格全部由此产生，每条都注明了设备与构建选项。其中 6.2.2 的语言等级表来自 `fixtures/default_level.cl`：它只在预定义宏等于命令行传入的值时才编译通过，于是"扫一遍取值看哪个过"就把宏的真实值测了出来。设备侧的版本数组来自 `tools/clinfo-probe` 新增的 `CL_DEVICE_OPENCL_C_ALL_VERSIONS` 与 `CL_DEVICE_OPENCL_C_FEATURES` 两个查询。6.5 关于 `barrier` 弃用的说法是**规范级**（`cl.h` 是宿主头文件，不含内核语言的内建函数声明，无法从头文件验证）。6.4 的 `float3` 对齐大小同样是**规范级**，本机没有构造能观测它的实验。

## 6.1 OpenCL C 是什么语言的子集

原教程写：

> OpenCL C 是基于 ANSI C 的子集，增加了并行编程特性。

**"ANSI C"这个说法不准确**，而且会导致具体的编码错误。ANSI C 通常指 C89/C90，而 OpenCL C 以 **C99** 为基础——这意味着 `//` 注释、`for` 循环内声明变量、`stdbool.h`、可变长数组（部分）、`restrict`、指定初始化器这些都是**语言本身的一部分**，不需要"当作扩展"。OpenCL C 3.0 进一步可选地对齐 **C17**。

写成 C89 风格的直接后果是：你会以为 `for (int i = 0; ...)` 不能用，或者在结构体初始化时避开指定初始化器——而 [05 篇 §5.6.1](./05-core-concepts.md) 刚刚论证过，`cl_image_desc` 恰恰**应该**用具名字段。

### 6.1.1 拿掉了什么

| C99 特性 | OpenCL C 1.2 | 说明 |
|---|:---:|---|
| 递归 | ❌ | 内核函数不能递归 |
| 函数指针 | ❌ | 无函数指针，也无虚表 |
| 可变参数函数 | ❌ | 内核不能有 `...`；内建的 `printf` 是唯一例外 |
| `malloc` / `free` | ❌ | OpenCL C 2.0 起设备侧才有动态分配，本机不涉及 |
| 标准库（`stdio`/`string`/`math` 的 C 版本） | ❌ | 换成 OpenCL 自己的一套同名内建函数 |
| `long double` | ❌ | 不存在 |
| 位域、`union` 的某些用法 | 部分 | 见规范 |

**`printf` 是有的**，而且是调试内核最有效的手段——它从设备侧输出到宿主的标准输出。代价是慢，且缓冲区有限（`CL_DEVICE_PRINTF_BUFFER_SIZE`）。

### 6.1.2 加了什么

| 类别 | 内容 |
|---|---|
| 函数限定符 | `__kernel` / `kernel`、`__attribute__((reqd_work_group_size(x,y,z)))` 等 |
| 地址空间限定符 | `__global`、`__local`、`__constant`、`__private`（见 6.6） |
| 向量类型 | `float2/3/4/8/16`、`int4`、`uchar16` …（见 6.4） |
| 工作项函数 | `get_global_id`、`get_local_size`、`get_group_id` …（见 6.5.1） |
| 同步原语 | `barrier`、`work_group_barrier`、`mem_fence`、`atomic_*`（见 6.5.2） |
| 图像读写 | `read_imagef`、`write_imagef` + `sampler_t` |
| 数学内建 | 全套 `sin/cos/exp/sqrt/mad/fma/clamp/mix/select` … |

## 6.2 `-cl-std`、版本字符串、与实际能编译什么

### 6.2.1 三设备实测

测试内核（`tools/cl-build-probe/fixtures/sync_barrier.cl`）在同一个文件里放了两个内核，一个用 `barrier`，一个用 `work_group_barrier`：

```c
__kernel void uses_old_barrier(__global float* out) {
    __local float tile[256];
    int lid = get_local_id(0);
    tile[lid] = (float)lid;
    barrier(CLK_LOCAL_MEM_FENCE);
    out[get_global_id(0)] = tile[255 - lid];
}

__kernel void uses_work_group_barrier(__global float* out) {
    __local float tile[256];
    int lid = get_local_id(0);
    tile[lid] = (float)lid;
    work_group_barrier(CLK_LOCAL_MEM_FENCE);
    out[get_global_id(0)] = tile[255 - lid];
}
```

`clBuildProgram` 编译**整个源文件**，所以不管请求哪个内核名，两个内核都会被编译——这一点本身就是个有用的事实：**一个内核的语法错误会让整个 program 不可用**。

用 `cl-build-probe` 在三个设备上、四种构建选项下各跑一遍，结果：

| 设备 | `CL_DEVICE_OPENCL_C_VERSION` | 不带 `-cl-std` | `-cl-std=CL1.2` | `-cl-std=CL2.0` | `-cl-std=CL3.0` |
|---|---|:---:|:---:|:---:|:---:|
| Intel UHD 630 | OpenCL C 1.2 | ❌ `-11` | ❌ `-11` | ✅ | ✅ |
| Intel i7-9700 CPU | **OpenCL C 3.0** | ❌ `-11` | ❌ `-11` | ✅ | ✅ |
| NVIDIA RTX 2060 | OpenCL C 1.2 | ✅ | ✅ | ✅ | ✅ |

（`-11` = `CL_BUILD_PROGRAM_FAILURE`，`cl.h:208`。）

Intel 设备上失败时的真实 build log：

```text
clBuildProgram -> -11 (CL_BUILD_PROGRAM_FAILURE)
--- build log ---
1:18:5: error: implicit declaration of function 'work_group_barrier' is invalid in OpenCL
    work_group_barrier(CLK_LOCAL_MEM_FENCE);
    ^
1:18:5: note: did you mean 'sub_group_barrier'?
./CTHeader.h:5840:39: note: 'sub_group_barrier' declared here
void    __attribute__((overloadable)) sub_group_barrier( cl_mem_fence_flags flags );
```

Intel CPU 设备（默认语言等级名义上是 3.0）的 log 措辞不同，但结论一样：

```text
Compilation started
1:18:5: error: use of undeclared identifier 'work_group_barrier'; did you mean 'sub_group_barrier'?
   18 |     work_group_barrier(CLK_LOCAL_MEM_FENCE);
      |     ^~~~~~~~~~~~~~~~~~
      |     sub_group_barrier
.\OPENCL_CTH_PRE_RELEASE_H:98:36: note: 'sub_group_barrier' declared here
   98 | void __attribute__((overloadable)) sub_group_barrier(cl_mem_fence_flags flags);
Compilation failed
```

### 6.2.2 为什么：两个版本宏，只有一个说了算

build log 说的是 `implicit declaration ... is invalid in OpenCL`——编译器**没有这个函数的声明**，不是找不到符号、也不是缺扩展。这说明被卡住的是**语言等级**。那就把等级直接测出来。

OpenCL C 预定义了两个版本宏，`fixtures/default_level.cl` 的办法是：**只在宏等于命令行传入的值时才编译通过**，然后扫一遍取值，哪个过了哪个就是真值。

```c
#if __OPENCL_VERSION__ != EXPECT
#error "__OPENCL_VERSION__ does not match EXPECT"
#endif

#if !defined(__OPENCL_C_VERSION__)
#if EXPECT_C != EXPECT_C_UNDEFINED
#error "__OPENCL_C_VERSION__ is undefined but a value was expected"
#endif
#elif __OPENCL_C_VERSION__ != EXPECT_C
#error "__OPENCL_C_VERSION__ does not match EXPECT_C"
#endif
```

扫描结果（每格是"编译通过"的那个取值，格式为 `__OPENCL_VERSION__` / `__OPENCL_C_VERSION__`）。没有一格是"宏未定义"——三个驱动在**所有等级下都定义了 `__OPENCL_C_VERSION__`**，包括 1.2（值为 `120`），尽管规范是 2.0 才引入它的：

| 构建选项 | UHD 630 `__OPENCL_VERSION__` / `__OPENCL_C_VERSION__` | i7 CPU 同 | RTX 2060 同 |
|---|:---:|:---:|:---:|
| 不带 `-cl-std` | **300 / 120** | **300 / 120** | **300 / 300** |
| `-cl-std=CL1.2` | 300 / 120 | 300 / 120 | 120 / 120 |
| `-cl-std=CL2.0` | 300 / 200 | 300 / 200 | 200 / 200 |
| `-cl-std=CL3.0` | 300 / 300 | 300 / 300 | 300 / 300 |

这张表把 6.2.1 的现象解释干净了，同时埋着两个坑。

**坑一：`__OPENCL_VERSION__` 不是语言等级。**

Intel 两个设备在**四种选项下都报 300**，包括显式 `-cl-std=CL1.2`。它报的是**设备的 OpenCL 版本**，不是这次编译用的语言等级。真正跟着 `-cl-std` 动的是 `__OPENCL_C_VERSION__`。

NVIDIA 反而是两个宏一起动。所以"用 `__OPENCL_VERSION__` 判断当前语言等级"这段代码**在 Intel 上永远得到 300**，你会以为 2.0/3.0 的内建函数都在，然后 `work_group_barrier` 给你一个 `-11`。

> 写这一节的时候我自己先踩了这个坑：第一轮只测了 `__OPENCL_VERSION__`，三个设备全是 300，于是得出"默认等级都是 3.0，那 `work_group_barrier` 失败一定是别的原因"的结论——**和 6.2.1 的实测直接矛盾**。补测第二个宏才对上。这就是"扫一遍取值"比"读一个数字"可靠的地方。

**坑二：`#error` 里没法把宏的值打印出来。**

本来想写成自报家门的诊断：

```c
#define STR2(x) #x
#define STR(x) STR2(x)
#error "__OPENCL_VERSION__ is " STR(__OPENCL_VERSION__)
```

三个驱动**都不展开**，build log 里原样出现 `STR(__OPENCL_VERSION__)` 这串 token：

```text
1:27:2: error: "__OPENCL_VERSION__ is " STR(__OPENCL_VERSION__) ", expected " STR(EXPECT)
```

所以只能用"编译成功与否"当输出通道，也就是上面的扫描。顺带记一条：`#if` 里**未定义的宏按 0 处理**，所以判断"宏没定义"必须用 `defined()`，不能拿它和 0 比——那样会得到一个假通过。fixture 里 `EXPECT_C_UNDEFINED` 那个分支就是为了这个。

**设备侧的权威查询**

`CL_DEVICE_OPENCL_C_VERSION` 是 OpenCL 1.x 时代的字符串查询。3.0 补了两个数组查询，`clinfo-probe` 现在把它们和旧字符串并排打印：

```text
--- Platform 1 Device 0: Intel(R) UHD Graphics 630 [GPU] ---
    CL_DEVICE_OPENCL_C_VERSION         OpenCL C 1.2
    opencl_c_all_versions              OpenCL C: 1.0 1.1 1.2 3.0  (4 entries)
    opencl_c_features                  (14 entries)
      __opencl_c_int64                       3.0
      __opencl_c_3d_image_writes             3.0
      __opencl_c_images                      3.0
      __opencl_c_read_write_images           3.0
      __opencl_c_atomic_order_acq_rel        3.0
      __opencl_c_atomic_order_seq_cst        3.0
      __opencl_c_atomic_scope_all_devices    3.0
      __opencl_c_atomic_scope_device         3.0
      __opencl_c_generic_address_space       3.0
      __opencl_c_program_scope_global_variables 3.0
      __opencl_c_work_group_collective_functions 3.0
      __opencl_c_subgroups                   3.0
      __opencl_c_pipes                       3.0
      __opencl_c_fp64                        3.0
```

三个设备的对比：

| 设备 | `CL_DEVICE_OPENCL_C_VERSION` | `opencl_c_all_versions` | `features` 条目数 | 默认 `__OPENCL_C_VERSION__` |
|---|---|---|---|---|
| Intel UHD 630 | OpenCL C 1.2 | 1.0 1.1 1.2 **3.0** | 14 | 120 |
| Intel i7-9700 CPU | **OpenCL C 3.0** | **3.0 2.0** 1.2 1.1 1.0 | 17 | 120 |
| NVIDIA RTX 2060 | OpenCL C 1.2 | 1.0 1.1 1.2 **3.0** | **4** | **300** |

`opencl_c_all_versions` 解释了两个 GPU 的"矛盾"：**它们的列表里没有 2.0**。这不是 bug——OpenCL 3.0 把原来的"OpenCL C 2.0"拆成了一组**可选特性**，设备不再需要整体宣称支持 2.0 这个语言版本，而是逐项宣称 `__opencl_c_subgroups`、`__opencl_c_generic_address_space` 等等。UHD 630 的 14 项里就有 `__opencl_c_work_group_collective_functions`，所以传了 `-cl-std=CL2.0` 之后 `work_group_barrier` 能编译，是自洽的。

NVIDIA 那一行才是真正的问题：它只宣称 **4** 项可选特性——`fp64`、`images`、`int64`、`3d_image_writes`，**没有** `work_group_collective_functions`，**没有** `subgroups`——却把默认 `__OPENCL_C_VERSION__` 设成 **300**，于是 `work_group_barrier` 在默认选项、甚至在显式 `-cl-std=CL1.2` 下都能编译通过。

> **它接受了一个自己并未宣称支持的特性。** 这比"编译器宽松"更具体：宽松不是"多认几个函数名"，而是**宣称的能力集合与实际接受的语言不一致**。你没法用扩展列表、没法用特性数组、也没法用版本字符串预测它——只能编一次。

> **诚实边界**：为什么 Intel 两个设备的默认 `__OPENCL_C_VERSION__` 是 120、NVIDIA 是 300，规范里对"省略 `-cl-std` 时该用哪一级"的具体措辞我没有在本机取证到原文。上面全部是**实测行为**，不是规范推导。要引用规范措辞请自行核对 OpenCL 3.0 规范里 `-cl-std` 那一节。

### 6.2.3 四条结论，每条都能咬人

**① 版本字符串既不是默认等级，也不是可靠上限。**

Intel CPU 设备报 `OpenCL C 3.0`，而默认 `__OPENCL_C_VERSION__` 实测是 `120`——**字符串是上限，不是默认**。这半边好理解。

反方向才是意外的：UHD 630 报 `OpenCL C 1.2`，却在 `-cl-std=CL3.0` 下**编译成功**，连 build log 都是空的。也就是说这个字符串**连上限都不是**。

想知道真实上限，查 `CL_DEVICE_OPENCL_C_ALL_VERSIONS`（6.2.2 的表）：UHD 630 列的是 `1.0 1.1 1.2 3.0`，比旧字符串诚实得多。**旧字符串在 OpenCL 3.0 设备上已经没有可靠语义了**，两个方向都会骗你。

**② NVIDIA 不只是"宽松"，是宣称与接受不一致。**

NVIDIA 报 `OpenCL C 1.2`，`opencl_c_all_versions` 里也没有 2.0，`opencl_c_features` 只有 4 项、不含 `__opencl_c_work_group_collective_functions`。按它自己的宣称，`work_group_barrier` 不该存在。

但实测：它默认就把 `__OPENCL_C_VERSION__` 设成 `300`，于是 `work_group_barrier` 在**默认选项下能编译**，在**显式 `-cl-std=CL1.2` 下也能编译**（此时 `__OPENCL_C_VERSION__` 确实是 `120`）。

宽松不是好事。它意味着：

> 在 NVIDIA 上编译通过 ≠ 这段代码是 OpenCL C 1.2，也 ≠ 这段代码在别处能编译。

**③ 本机 `platforms[0]` 恰好就是那个宽松的。**

把 ① 和 ② 与 [05 篇 §5.1.2](./05-core-concepts.md) 合起来看，得到一个相当恶毒的组合：

```text
原教程写法：clGetPlatformIDs(1, &platform, NULL)
              ↓
本机 platforms[0] = NVIDIA CUDA
              ↓
NVIDIA 的编译器对语言等级最宽松
              ↓
代码"测通了"，但用的是 2.0 的特性、跑在自称 1.2 的设备上
              ↓
换到教程真正要讲的 Intel 核显 → -11，build log 说
"implicit declaration ... is invalid in OpenCL"
              ↓
你会以为是自己写错了函数名
```

**这是"选错设备"和"编译器宽松"两个坑叠在一起的样子。** 单独一个都不致命，合起来会让你在错误的设备上得到错误的信心。

**④ 内核里判断语言等级，用 `__OPENCL_C_VERSION__`，不要用 `__OPENCL_VERSION__`。**

实测：Intel 两个设备在四种构建选项下 `__OPENCL_VERSION__` **恒为 300**，包括显式 `-cl-std=CL1.2`；跟着选项动的是 `__OPENCL_C_VERSION__`。NVIDIA 则两个宏一起动。

后果是：任何 `#if __OPENCL_VERSION__ >= 200` 形式的条件编译，**在 Intel 上永远为真**，于是你会在 1.2 等级下启用 2.0 的代码路径，拿到 `-11`；而同一段代码**在 NVIDIA 上表现"正常"**，因为它两个宏一致——你测不出来。

**实践规则**：

1. 想用哪个语言等级，就**显式传 `-cl-std=CLx.y`**，不要依赖默认。传法见 [03 篇 §3.3](./03-first-program.md) 的 `clBuildProgram(program, 1, &device, "-cl-std=CL2.0", NULL, NULL)`。
2. **不要用 `-cl-std` 去"解锁"你其实不需要的高版本特性**。默认（1.2）能编译的内核可移植性最好。这一条现在是**实测的**：`examples/` 七个示例里有六个带内核文件（`01-device-query` 没有内核），六个都在 UHD 630 上用默认选项（即 `__OPENCL_C_VERSION__ = 120`）编译，全部 `BUILD OK`。
3. 想知道某个内建函数在某设备上能不能用，**用 `cl-build-probe` 编一次**，不要读版本字符串、不要查扩展列表、不要凭印象：

```powershell
.\tools\cl-build-probe\cl-build-probe.exe `
    .\tools\cl-build-probe\fixtures\sync_barrier.cl `
    uses_work_group_barrier UHD "-cl-std=CL2.0"
```

## 6.3 数据类型

### 6.3.1 标量

| OpenCL C 类型 | 宽度 | 对应宿主类型 | 备注 |
|---|---|---|---|
| `char` / `uchar` | 8 位 | `cl_char` / `cl_uchar` | 有符号 / 无符号 |
| `short` / `ushort` | 16 位 | `cl_short` / `cl_ushort` | |
| `int` / `uint` | 32 位 | `cl_int` / `cl_uint` | |
| `long` / `ulong` | 64 位 | `cl_long` / `cl_ulong` | |
| `float` | 32 位 | `cl_float` | 始终可用 |
| `double` | 64 位 | `cl_double` | 需 `cl_khr_fp64`，见 6.3.2 |
| `half` | 16 位 | `cl_half` | 需 `cl_khr_fp16`，见 6.3.3 |
| `size_t` / `ptrdiff_t` / `intptr_t` | 平台相关 | — | 本机 64 位 |

**`bool` 不是内置类型**，要 `#include <stdbool.h>`（OpenCL C 支持）。整数类型的宽度是**固定的**，不像 C 里 `long` 那样随平台变——这是并行代码必须的确定性。

**宿主侧永远用 `cl_*` 别名，不要用裸 `int`/`float`。** 内核侧两者等价，但宿主侧的 `cl_int` 是 ABI 契约的一部分：`clSetKernelArg(k, i, sizeof(cl_int), &v)` 里 `sizeof` 必须和内核签名的宽度一致，写 `sizeof(int)` 在 `int` 不是 32 位的平台上会静默传错字节数。

### 6.3.2 `double` 与 `cl_khr_fp64`

原教程只写了一句：

> `double` | 64 位浮点数（需扩展支持）

没给扩展名，也没给启用方式。补全：

- 扩展名是 **`cl_khr_fp64`**。
- OpenCL C 1.2 下使用 `double` 需要先启用：

```c
#pragma OPENCL EXTENSION cl_khr_fp64 : enable

__kernel void double_dot(__global const double* a,
                         __global const double* b,
                         __global double* c,
                         const int n) {
    int i = get_global_id(0);
    if (i < n) c[i] = a[i] * b[i];
}
```

**本机三个设备都在扩展列表里报告 `cl_khr_fp64`**（`clinfo-probe` 实测）：

```text
NVIDIA GeForce RTX 2060        + cl_khr_fp64
Intel(R) UHD Graphics 630      + cl_khr_fp64
Intel(R) Core(TM) i7-9700 CPU  + cl_khr_fp64
```

上面那段内核被做成了两个 fixture——`fp64_double.cl`（**不带** pragma）和 `fp64_double_pragma.cl`（**带** pragma）。实测：

| fixture | UHD 630 | RTX 2060 | i7 CPU |
|---|:---:|:---:|:---:|
| 不带 pragma | ✅ `CL_SUCCESS` | ✅ `CL_SUCCESS` | ✅ `CL_SUCCESS` |
| 带 pragma | ✅ `CL_SUCCESS` | ✅ `CL_SUCCESS` | ✅ `CL_SUCCESS` |

**六格全过。** 也就是说本机这三个驱动在默认语言等级下都不强制要求这个 pragma。

`cl_khr_fp64` 是扩展字符串，OpenCL 3.0 还有一个更权威的查询——`CL_DEVICE_OPENCL_C_FEATURES` 数组里有没有 `__opencl_c_fp64`。6.2.2 的实测里**三个设备都有这一项**（NVIDIA 的 4 项特性里就有它）。两条独立证据一致。

> **诚实边界**：这张表**不能**得出"pragma 是多余的"。它只能说明"本机这三个驱动不检查"。规范上 OpenCL C 1.2 的 `double` 依赖 `cl_khr_fp64`，而扩展默认是关闭的；换一个更严格的驱动（或换一个不报告 `cl_khr_fp64` 的设备）就会失败。**结论是：pragma 照写**，它零成本，而"我这儿能编译"不是可移植性的证据。这正是 6.2.3 结论 ② 的同一个道理，只是这次宽松的方向对我们有利，所以更容易被忽略。

顺带一个 `double` 的性能事实：消费级 GPU 的双精度吞吐通常是单精度的 **1/32 到 1/64**。`double` 能用不代表该用。

### 6.3.3 `half` 与 `cl_khr_fp16`——本机有一个设备不支持

`half` 依赖 **`cl_khr_fp16`**。这个扩展在本机**不是三个设备都有**：

| 设备 | `cl_khr_fp16` |
|---|:---:|
| Intel UHD 630 | ✅ |
| Intel i7-9700 CPU | ✅ |
| **NVIDIA RTX 2060** | ❌ **不在扩展列表里** |

（`clinfo-probe` 过滤后的输出：NVIDIA 那一栏只有 `cl_khr_fp64`、`cl_khr_int64_base_atomics`、`cl_khr_3d_image_writes`、`cl_khr_byte_addressable_store`、`cl_khr_external_memory`，共 26 个扩展，无 `fp16`。）

所以"用 `half` 省带宽"这个优化，在本机的 NVIDIA 卡上根本不可用——而在 Intel 两个设备上可用。**这是 6.2.3 结论 ② 的镜像**：那一条说 NVIDIA 更宽松，这一条说 NVIDIA 更严格。同一个设备在不同维度上偏差方向相反，所以任何"某台机器上测过"的结论都不能直接外推。

## 6.4 向量类型

向量类型是 OpenCL C 的一等公民，不是语法糖：

```c
float4 v1 = (float4)(1.0f, 2.0f, 3.0f, 4.0f);
float2 v2 = (float2)(5.0f, 6.0f);

float4 result = v1 * 2.0f + v2.xyxy;    // 原教程这行是对的
```

`v2.xyxy` 是 **swizzle**：把 2 分量向量重排成 4 分量 `(5,6,5,6)`。标量 `2.0f` 会被自动提升成 `(float4)(2,2,2,2)`。整个表达式**逐分量**运算，没有隐式循环。

分量访问有三套写法：

| 写法 | 例子 | 适用 |
|---|---|---|
| 颜色/坐标名 | `.xyzw`、`.rgba`、`.stpq` | 最常用，四者等价 |
| 序号 | `.s0` … `.sf` | 超过 4 分量时必须用（`.s0123` 可组合） |
| 高低半 | `.lo` / `.hi` / `.even` / `.odd` | `float8` 拆成两个 `float4` |

```c
float8  big = vload8(0, ptr);
float4  lo  = big.lo;        // 前 4 个
float4  hi  = big.hi;        // 后 4 个
float4  sel = big.s0246;     // 偶数位
```

### 6.4.1 什么时候真有用

1. **匹配硬件 SIMD 宽度。** Intel 核显的一个 EU 线程通常一次处理 8 或 16 个通道，`float4`/`float8` 让编译器更容易映射上去。
2. **减少指令条数。** 4 个分量的加法是一条向量指令，不是四条标量指令。
3. **图像天然对齐。** `read_imagef` 返回的就是 `float4`，见 [05 篇 §5.6](./05-core-concepts.md)。

**什么时候没用甚至有害**：如果你的访存本来就不连续，向量化不会让它变连续；而 `float16` 会显著增加寄存器压力，可能降低占用率（occupancy）。**要测，不要假设。**

### 6.4.2 `float3` 的大小是 16 字节（规范级）

```c
sizeof(float3) == 16    // 不是 12
```

`float3` 按 `float4` 对齐。后果是：**一个 `float3` 数组的步长是 16 字节**，`vload3(i, p)` 读的是 `p + i*16` 而不是 `p + i*12`。如果你把宿主侧一个紧凑的 RGB 数组（每像素 12 字节）直接传给内核再按 `float3` 读，会**整体错位**。

正确做法：宿主侧就按 16 字节对齐填充，或者干脆用 `float4`（RGBA），或者用 `vload3` 配合明确的 `__attribute__((packed))`。

> **诚实边界**：`sizeof(float3) == 16` 是规范级结论，来自 OpenCL C 的对齐规则。本机没有构造实验去观测它——`cl-build-probe` 只编译不执行，而要观测 `sizeof` 需要一个能 `printf` 的运行内核。当作规范级使用；如果要依赖它，写个内核 `printf("%d", (int)sizeof(float3));` 自己确认一次。

## 6.5 内建函数

### 6.5.1 工作项函数

原教程这张表是对的，补上返回类型和一个常见误解：

| 函数 | 返回 | 含义 |
|---|---|---|
| `get_global_id(dim)` | `size_t` | 全局工作项 ID |
| `get_local_id(dim)` | `size_t` | 组内 ID |
| `get_group_id(dim)` | `size_t` | 工作组 ID |
| `get_global_size(dim)` | `size_t` | 全局工作项总数 |
| `get_local_size(dim)` | `size_t` | 工作组大小 |
| `get_num_groups(dim)` | `size_t` | 工作组数量 |
| `get_global_offset(dim)` | `size_t` | 全局偏移，通常为 0 |
| `get_work_dim()` | `uint` | NDRange 的维数 |

**它们都返回 `size_t`（本机 64 位无符号），不是 `int`。** 所以

```c
int idx = get_global_id(0);          // 常见写法，隐式收窄
```

在 `n` 小于 2³¹ 时无害，但会引入**有符号/无符号比较警告**，并且在 `idx < n` 里如果 `n` 是 `int`，比较会按有符号进行。本教程的内核统一写：

```c
int i = (int)get_global_id(0);
if (i < n) { ... }                   // 显式收窄 + 越界保护
```

显式的 `(int)` 转换让"我知道这里在收窄"这件事写在代码里，而不是留给读者猜。

索引公式只有一条，逐维独立（详见 [04 篇 §4.3](./04-programming-model.md)）：

```text
global_id[d] = global_offset[d] + group_id[d] * local_size[d] + local_id[d]
```

### 6.5.2 同步原语——原教程漏了一半

原教程只列了两个：

| 函数 | 描述 |
|---|---|
| `barrier(flags)` | 同步工作组内所有工作项 |
| `mem_fence(flags)` | 内存栅栏，确保内存访问顺序 |

补全后的实际情况：

| 函数 | 语言等级 | 范围 | 说明 |
|---|:---:|---|---|
| `barrier(flags)` | 1.x | 工作组 | **OpenCL C 2.0 起弃用**，但仍普遍可用；本机三设备默认选项下都能编译（实测：`matmul_tiled` 在 `-DTILE=8/16/32` 下三设备全部 `BUILD OK`） |
| `work_group_barrier(flags)` | 2.0+ | 工作组 | `barrier` 的正规替代；本机 Intel 需 `-cl-std=CL2.0`（6.2.1 实测） |
| `work_group_barrier(flags, scope)` | 2.0+ | 工作组 | 带内存作用域的重载 |
| `sub_group_barrier(flags)` | 2.0+ | 子组 | 只同步一个子组，比工作组屏障便宜得多。注意 Intel 在**默认 1.2 等级**下就把它当候选建议出来（6.2.1 的 build log 指向 `CTHeader.h:5840`），因为 `cl_intel_subgroups` 提前暴露了它——"2.0+" 是规范等级，不等于实际可用起点 |
| `mem_fence(flags)` | 1.x | 工作项 | **只保证内存顺序，不保证所有工作项都到达** |
| `work_group_fence(flags)` | 2.0+ | 工作组 | `mem_fence` 的正规替代 |
| `atomic_*` / `atom_*` | 1.x 起部分，2.0 大扩 | 工作组 / 全局 | **原教程完全没提**，见下 |

`flags` 的取值：`CLK_LOCAL_MEM_FENCE`、`CLK_GLOBAL_MEM_FENCE`，可按位或。

**`barrier` 与 `mem_fence` 的区别是这一节最容易错的地方**：

```text
barrier(CLK_LOCAL_MEM_FENCE)
  ├─ 内存栅栏：此前的本地内存写对所有工作项可见
  └─ 执行屏障：所有工作项都到达这一点后才继续      ← 关键

mem_fence(CLK_LOCAL_MEM_FENCE)
  └─ 只有内存栅栏，没有执行屏障
     同一个工作项内的读写被排序，但别的工作项可能还没写
```

**在协作式分块算法里（矩阵分块、归约），你要的几乎总是 `barrier`。** 用 `mem_fence` 会得到间歇性的错误结果，而且极难复现。

`examples/04-matmul-tiled/kernels/matmul_tiled.cl` 里两次 `barrier` 的位置和理由都写在注释里，其中第二次是很多人会漏的：

```c
        // Every work-item must finish filling the tile before any of them reads it.
        barrier(CLK_LOCAL_MEM_FENCE);

        for (int i = 0; i < TILE; i++) {
            sum += tileA[localRow][i] * tileB[i][localCol];
        }

        // And nobody may start overwriting the tile with the next block until every
        // work-item has finished reading the current one. Omitting this second
        // barrier is a classic race that fails intermittently.
        barrier(CLK_LOCAL_MEM_FENCE);
```

**原子操作**（原教程缺失）：

```c
// OpenCL C 1.2 的整数原子，作用于 __global 或 __local
atomic_add(&counter, 1);
atomic_inc(&counter);
atomic_cmpxchg(&slot, expected, desired);

// OpenCL C 2.0 起改名为 atomic_fetch_add 等，并支持浮点与内存序
atomic_fetch_add(&counter, 1);
atomic_fetch_max(&histogram[bucket], value);
```

`examples/05-reduce-sum` 的两轮归约之所以存在，正是因为**工作组之间无法同步**（[04 篇 §4.3](./04-programming-model.md)），所以跨组聚合要么用原子、要么分两轮。该示例选了两轮，因为原子加在 GPU 上对同一地址高竞争时会串行化，比多一次内核启动更慢。

> **诚实边界**：`barrier` "OpenCL C 2.0 起弃用"这条是**规范级**结论。`cl.h` 是宿主侧头文件，不包含内核语言的内建函数声明，所以没法像 [05 篇 §5.4.1](./05-core-concepts.md) 处理 `clCreateCommandQueue` 那样从头文件取证。本机实测到的只是"`barrier` 在三个设备上都能编译"，这不足以证明它没被弃用。

### 6.5.3 数学内建：三档精度

| 前缀 | 精度 | 速度 | 例子 |
|---|---|---|---|
| 无 | 最严格，符合 IEEE 754 与 C99 的 ulp 要求 | 基准 | `sin(x)`、`divide(x,y)` |
| `native_` | 由实现定义，**无精度保证** | 最快，直接映射硬件指令 | `native_sin(x)`、`native_divide(x,y)` |
| `fast_` | `native_` 加上 `-cl-fast-relaxed-math` 时等价于 `native_` | 快 | `fast_length(v)`、`fast_normalize(v)` |

还有几个值得单独记的：

- **`mad(a,b,c)`** = `a*b+c`，一次舍入；**`fma(a,b,c)`** 同样是融合乘加但精度要求更严。GPU 上 `mad`/`fma` 是原生指令，写成 `a*b+c` 编译器**通常**也会融合，但依赖优化等级。
- **`rsqrt(x)`** = `1/sqrt(x)`，比 `1.0f/sqrt(x)` 快，因为硬件有倒数平方根指令。
- **`select(a, b, cond)`** 是**无分支**选择：`cond` 的符号位决定取 `a` 还是 `b`。在 SIMT 架构上，分支会导致两个分支都执行（divergence），`select` 避免了这一点。
- **`clamp(x, lo, hi)`**、**`mix(a,b,t)`**、**`step`**、**`smoothstep`** 都是硬件加速的。

`examples/06-image-brightness` 的内核用的就是 `clamp` 与向量算术，没有分支。

### 6.5.4 类型转换与位重解释

```c
float f = 1.5f;
int   i = convert_int_rte(f);       // 带舍入模式的显式转换
uchar u = convert_uchar_sat(f);     // 饱和转换，超范围不溢出而是钳制

float4 v = (float4)(1,2,3,4);
int4   b = as_int4(v);              // 位重解释，不做数值转换
```

- `convert_<type>_<round>_<sat>` 是完整形式：`_rte`（就近偶数）、`_rtz`（向零）、`_rtp`（向正无穷）、`_rtn`（向负无穷）、`_sat`（饱和）。
- **`as_<type>` 是位重解释**，等价于 C 的 union 双关，零开销。`(float)1` 是 1.0f，`as_float(1)` 是 1.4e-45。搞混这两个是经典 bug。
- 图像输出常用 `convert_uchar4_sat(normalized * 255.0f)`，`_sat` 保证不会在 255 处回绕成 0。

## 6.6 四个内存空间

```text
                        作用域            生命周期          速度      本机容量（UHD 630）
   ┌──────────────┐
   │  __private   │  单个工作项          工作项存活期       最快      寄存器 + 栈，无固定上限
   └──────────────┘
   ┌──────────────┐
   │  __local     │  一个工作组          工作组存活期       很快      64 KiB / 组
   └──────────────┘
   ┌──────────────┐
   │  __constant  │  全部工作项（只读）    上下文存活期       快（缓存） 3244.2 MiB（见下）
   └──────────────┘
   ┌──────────────┐
   │  __global    │  全部工作项          上下文存活期       慢        6488.4 MiB
   └──────────────┘
```

```c
__global      // 全局内存，所有工作项可访问，容量大但延迟高
__local       // 本地内存，工作组内可访问，速度快
__private     // 私有内存，工作项私有（默认，可省略）
__constant    // 常量内存，只读，对所有工作项可见
```

| 限定符 | 谁能访问 | 谁分配 | 内核里怎么写 |
|---|---|---|---|
| `__global` | 所有工作项 | 宿主 `clCreateBuffer` | 参数必须带 `__global` |
| `__local` | 同一工作组内 | 内核内声明，或宿主动态分配 | 不能在宿主侧创建 |
| `__constant` | 所有工作项，**只读** | 宿主 `clCreateBuffer` + `CL_MEM_READ_ONLY` | 参数带 `__constant` |
| `__private` | 单个工作项 | 编译器 | 局部变量默认就是 |

### 6.6.1 `__private` 是默认，但值得显式写出来

```c
__kernel void k(__global float* out) {
    float sum = 0.0f;        // 这就是 __private，等价于 __private float sum
    ...
}
```

局部变量、函数参数（非指针的标量）都在私有空间。私有内存**通常映射到寄存器**，放不下才溢出到栈（在全局内存里，慢）。`CL_KERNEL_PRIVATE_MEM_SIZE` 就是查这个溢出量的：

```text
fixtures/sync_barrier.cl, uses_work_group_barrier, -cl-std=CL2.0, Intel UHD 630
  CL_KERNEL_PRIVATE_MEM_SIZE = 0
```

**0 表示没有私有内存溢出**——这个内核的所有中间值都在寄存器里。如果这里是个大数字，说明内核用了太多局部变量，会明显变慢。这是 `cl-build-probe` 每个 fixture 都打印这三个数字的原因。

### 6.6.2 `__local` 的两种分配方式

**方式一：内核内静态声明**（`examples/04`、`examples/05` 用的都是这种）

```c
__kernel void matmul_tiled(...) {
    __local float tileA[TILE][TILE];
    __local float tileB[TILE][TILE];
    ...
}
```

大小在编译期确定，`TILE` 是编译期宏。

**方式二：宿主动态分配**（原教程完全没提，但更灵活）

内核里声明一个**没有大小**的 `__local` 数组：

```c
__kernel void reduce(__global const float* in, __global float* out,
                     __local float* scratch,      // 无大小
                     const int n) {
    int lid = get_local_id(0);
    scratch[lid] = in[get_global_id(0)];
    barrier(CLK_LOCAL_MEM_FENCE);
    ...
}
```

宿主侧用 `clSetKernelArg` 传**大小**、指针传 `NULL`：

```c
size_t localBytes = localSize * sizeof(float);
clSetKernelArg(kernel, 2, localBytes, NULL);     // 第三个参数是大小，第四个是 NULL
```

这样同一个内核可以在**不同工作组大小**下运行，而 `localBytes` 由宿主在运行时按查询到的 `CL_DEVICE_LOCAL_MEM_SIZE` 决定。想写"查询上限、然后取最大可行工作组"的代码，必须用方式二——方式一的大小是编译期钉死的。

### 6.6.3 `__constant` 在核显上不是独立硬件

[05 篇 §5.2.3](./05-core-concepts.md) 实测到：

```text
Intel UHD 630
    max_mem_alloc_size                 3401799680 (3244.2 MiB)
    max_constant_buffer_size           3401799680 (3244.2 MiB)
```

两个数字**完全相同**。核显没有专用常量缓存，`__constant` 就是带缓存提示的全局内存，上限直接塌缩成单次分配上限。

对比 NVIDIA RTX 2060：`max_constant_buffer_size = 64 KiB`，那才是有物理常量缓存时的典型值。

所以"`__constant` 又小又快，要省着用"这条经验**只在有专用常量缓存的设备上成立**。它的真正语义是：

- **只读**，编译器可以据此优化（不用假设会被别的线程改）。
- **广播友好**：一个工作组内所有工作项读同一个地址时，常量缓存一次供给全部；读**不同**地址则会串行化，反而比 `__global` 慢。

第二点是关键：`__constant` 适合**所有工作项共享的同一份小数据**（系数表、变换矩阵、查找表的单个条目），不适合"每个工作项读不同元素"的数组。

### 6.6.4 CPU 设备的 `__local` 是假的

```text
Intel(R) Core(TM) i7-9700 CPU @ 3.00GHz
    local_mem_size                     262144 (256 KiB)
    local_mem_type                     CL_GLOBAL
```

`CL_GLOBAL` 意味着这块"本地内存"就是全局内存的一个视图，不是独立 SRAM。在 CPU 设备上做 `__local` 分块，**没有带宽收益，只有 `barrier` 的同步开销**。

这直接解释了 [04 篇 §4.8.1](./04-programming-model.md) 的结论：分块矩阵乘法在核显（`CL_LOCAL`）上值得，在 CPU 设备（`CL_GLOBAL`）上是负优化。

**永远查 `CL_DEVICE_LOCAL_MEM_TYPE` 再决定要不要分块。**

## 6.7 分块上限：`TILE` 到底能开多大

这是本篇的落点，也是 [04 篇 §4.5](./04-programming-model.md) 那张 `-54` 表的正面回答。分块矩阵乘法有**两条互相独立**的上限：

### 6.7.1 两个约束

设 `TILE` 为分块边长，工作组是 `TILE × TILE`，两个 `__local` 瓦片：

**约束 A — 工作项数**

```text
TILE² ≤ CL_KERNEL_WORK_GROUP_SIZE
```

**约束 B — 本地内存**

```text
2 · TILE² · sizeof(float) ≤ CL_DEVICE_LOCAL_MEM_SIZE
```

在 Intel UHD 630 上代入实测值（`CL_KERNEL_WORK_GROUP_SIZE = 256`，`local_mem = 65536 B`）：

| 约束 | 不等式 | 解 |
|---|---|---|
| A 工作项数 | `TILE² ≤ 256` | **`TILE ≤ 16`** |
| B 本地内存 | `8·TILE² ≤ 65536` → `TILE² ≤ 8192` | `TILE ≤ 90` |

**约束 A 先撞上，而且早了 5.6 倍。**

### 6.7.2 实测确认：TILE=32 失败不是因为本地内存

`examples/04-matmul-tiled` 的 case A 就是这个场景，它的输出把原因写死了：

```text
=== case A: width=256 TILE=32, global size rounded (expect launch rejection) ===
    32*32 = 1024 work-items per group; this device caps groups at 256.
    Local memory is NOT the constraint: two 32x32 float tiles are 8192 B.
    -DTILE=32 global={256,256} local={32,32}=1024 work-items, CL_KERNEL_WORK_GROUP_SIZE=256
    launch rejected -> -54 CL_INVALID_WORK_GROUP_SIZE
    as documented: rejected with -54 CL_INVALID_WORK_GROUP_SIZE
```

`8192 B` 远小于 `65536 B`——**本地内存绰绰有余**。失败的原因是 `1024 > 256`。

这个区分很重要，因为**两种失败报的是同一个 `-54`**。如果你只看到错误码就以为"本地内存不够了，把 TILE 调小"，你会一路调到 `TILE=16` 才碰巧成功，而完全不知道真正生效的是哪条约束。下次换一个本地内存更小的设备，你的推理就失效了。

case B / C 的成功也一并记录：

```text
=== case B: width=256 TILE=16, global size rounded (expect pass) ===
    -DTILE=16 global={256,256} local={16,16}=256 work-items, CL_KERNEL_WORK_GROUP_SIZE=256
    ran: 65536/65536 within tolerance, max abs err 0.000e+00
    as documented: accepted and numerically correct

=== case C: width=256 TILE=8, global size rounded (expect pass) ===
    -DTILE=8 global={256,256} local={8,8}=64 work-items, CL_KERNEL_WORK_GROUP_SIZE=256
    ran: 65536/65536 within tolerance, max abs err 0.000e+00
    as documented: accepted and numerically correct
```

`TILE=16` 时工作组正好是 256，**卡在上限上，一点余量都没有**。换一个 `max_work_group_size` 更小的设备就直接失败。

### 6.7.3 约束 A 要用**内核的**那个数，不是设备的那个

6.7.1 把约束 A 写成 `TILE² ≤ CL_KERNEL_WORK_GROUP_SIZE`，而不是 `CL_DEVICE_MAX_WORK_GROUP_SIZE`。这不是抠字眼——本机 NVIDIA 上两者差 4 倍。

用 `cl-build-probe` 把四个不同内核分别在三个设备上编译，查 `CL_KERNEL_WORK_GROUP_SIZE`：

| 内核 | 有 `__local` 吗 | UHD 630 | RTX 2060 | i7 CPU |
|---|:---:|:---:|:---:|:---:|
| `level_probe`（近乎空内核） | ❌ | 256 | **256** | 8192 |
| `double_dot` | ❌ | 256 | **256** | 8192 |
| `uses_old_barrier` | ✅ `float[256]` | 256 | **256** | 8192 |
| `matmul_tiled` `-DTILE=8/16/32` | ✅ 两个瓦片 | 256 | **256** | 8192 |

对照设备级数字：

```text
NVIDIA GeForce RTX 2060   CL_DEVICE_MAX_WORK_GROUP_SIZE = 1024
                          CL_KERNEL_WORK_GROUP_SIZE     = 256   ← 四个内核全都是 256
```

**NVIDIA 上连一个不使用本地内存、几乎什么都不做的内核都只报 256。** 所以"寄存器用得多的内核会被压低"这个常见解释在这里不成立——它是**这个驱动对所有内核的实际上限**，和设备宣称的 1024 无关。

后果很直接：如果你按 `CL_DEVICE_MAX_WORK_GROUP_SIZE = 1024` 算约束 A，会得出"NVIDIA 上 `TILE` 能开到 32"，而实际能跑的是 16。**差 2 倍，而且方向是让你写出跑不起来的代码。**

```c
// 约束 A 的正确取值：两个都查，取较小。
size_t devMax = 0, kernelMax = 0;
clGetDeviceInfo(dev, CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(devMax), &devMax, NULL);
clGetKernelWorkGroupInfo(kernel, dev, CL_KERNEL_WORK_GROUP_SIZE,
                         sizeof(kernelMax), &kernelMax, NULL);
size_t limit = (kernelMax < devMax) ? kernelMax : devMax;
```

注意 `CL_DEVICE_MAX_WORK_GROUP_SIZE` 返回 `size_t`（[05 篇 §5.2.4](./05-core-concepts.md) 那个坑），`CL_KERNEL_WORK_GROUP_SIZE` 同样返回 `size_t`。两个都用 `size_t` 接。

### 6.7.4 换个设备，哪条约束先撞上会变

约束 A 一律用 6.7.3 实测到的**内核级**数字：

| 设备 | 设备级上限 | **内核级上限** | `local_mem_size` | 约束 A 解 | 约束 B 解 | 谁先撞 |
|---|---|---|---|---|---|---|
| Intel UHD 630 | 256 | 256 | 64 KiB | `TILE ≤ 16` | `TILE ≤ 90` | **A** |
| NVIDIA RTX 2060 | 1024 | **256** | 48 KiB | **`TILE ≤ 16`** | `TILE ≤ 78` | **A** |
| Intel i7-9700 CPU | 8192 | 8192 | 256 KiB | `TILE ≤ 90` | `TILE ≤ 181` | **A** |

本机三个设备**都是约束 A 先撞上**。核显和 NVIDIA 一样顶格在 `TILE=16`，CPU 设备能到 90。

> **诚实边界**：NVIDIA 那一行的 `TILE ≤ 16` 来自**内核编译级**证据（`CL_KERNEL_WORK_GROUP_SIZE = 256`），不是**运行时**证据——`examples/04` 的目标设备写死为 `UHD`，我没有在 NVIDIA 上真去启动 `local={32,32}`。按规范 `CL_KERNEL_WORK_GROUP_SIZE` 就是"这个内核在这个设备上允许的最大工作组"，超了应当在 `clEnqueueNDRangeKernel` 得到 `-54`，与核显上实测到的 case A 同型。要在 NVIDIA 上跑到运行时级，把 `OCL_DEFAULT_DEVICE` 改成 `"NVIDIA"` 重编 `examples/04` 即可。

**两个数字都得看，而且看的顺序有讲究。** NVIDIA 的本地内存（48 KiB）比核显（64 KiB）还少，设备级工作组上限却高 4 倍——只看设备数字会以为 NVIDIA 明显更强，只看本地内存会以为 NVIDIA 明显更弱，而实测结论是**两者在 `TILE` 上一模一样，都是 16**。

### 6.7.5 `CL_KERNEL_LOCAL_MEM_SIZE`：不能手算，必须查

上面约束 B 的公式假设"`__local float tile[256]` 占 1024 字节"。同一份源码，三个设备实测：

```text
fixtures/sync_barrier.cl, uses_work_group_barrier, -cl-std=CL2.0

UHD       CL_KERNEL_LOCAL_MEM_SIZE   = 1024
NVIDIA    CL_KERNEL_LOCAL_MEM_SIZE   = 1028
i7        CL_KERNEL_LOCAL_MEM_SIZE   = 1024
```

**NVIDIA 多 4 字节。** 256 个 float 明明是 1024 字节，驱动报了 1028。

这不是 `sync_barrier` 一个内核的偶发。把 `matmul_tiled` 按三个 `TILE` 各编一遍，同样的偏移：

| `-DTILE=` | 手算 `2·TILE²·4` | UHD 630 | i7 CPU | **RTX 2060** |
|---|---|---|---|---|
| 8 | 512 | 512 | 512 | **516** |
| 16 | 2048 | 2048 | 2048 | **2052** |
| 32 | 8192 | 8192 | 8192 | **8196** |

Intel 两个设备**逐字节等于手算值**，NVIDIA **恒定多 4 字节**，与 `TILE` 无关。还有一个更小的偏差：完全不用本地内存的内核（`double_dot`、`level_probe`），Intel 报 `0`，NVIDIA 报 `1`。

多出来的字节是什么由实现决定——对齐、元数据、驱动保留区都有可能，规范没说，本机也测不出来。

后果：**任何"我算一下本地内存够不够"的手算都可能差几字节到几 KB**，而在接近上限时，差几字节就是 `-54`。正确做法是编译一次然后查：

```c
size_t kernelLocal = 0;
clGetKernelWorkGroupInfo(kernel, device, CL_KERNEL_LOCAL_MEM_SIZE,
                         sizeof(kernelLocal), &kernelLocal, NULL);
```

`cl-build-probe` 对每个 fixture 都打印这三个数：

```c
CL_KERNEL_WORK_GROUP_SIZE    // 这个内核在这个设备上允许的最大工作组（见 6.7.3）
CL_KERNEL_LOCAL_MEM_SIZE     // 这个内核静态申请的本地内存字节数
CL_KERNEL_PRIVATE_MEM_SIZE   // 私有内存溢出量，0 表示全在寄存器里
```

约束 A 用第一个、约束 B 用第二个，**两个都从内核查，不要从设备查**（[04 篇 §4.6](./04-programming-model.md)）。

### 6.7.6 动态本地内存也要算进约束 B

方式二（6.6.2）的动态本地内存**不在 `CL_KERNEL_LOCAL_MEM_SIZE` 里**——它编译期不存在。所以：

```text
实际占用 = CL_KERNEL_LOCAL_MEM_SIZE + Σ(每个动态 local 参数的 clSetKernelArg size)
```

超过 `CL_DEVICE_LOCAL_MEM_SIZE` 会在 `clEnqueueNDRangeKernel` 时返回 `-54`，**不是在 `clSetKernelArg` 时**。参数设置那一步不检查总量，因为它不知道你要在多大的工作组上跑。这个延迟报错的位置很反直觉。

## 6.8 原教程那段示例内核的四个问题

原教程「内存空间」一节给的完整示例：

```c
__kernel void example(__global float* input, __global float* output) {
    __local float sharedData[256];  // 本地内存
    int idx = get_global_id(0);

    // 从全局内存读取
    float data = input[idx];

    // 写入本地内存
    sharedData[get_local_id(0)] = data;

    // 同步
    barrier(CLK_LOCAL_MEM_FENCE);

    // 计算
    float result = sharedData[get_local_id(0)] * 2.0f;

    // 写入全局内存
    output[idx] = result;
}
```

它能编译，也"能跑"，但作为教学代码有四个问题，每个都会把读者带偏。

### 问题 1：`[256]` 是硬编码，而且恰好等于本机核显的上限

`__local float sharedData[256]` 假设工作组正好是 256。这个数字**就是本机 Intel UHD 630 的 `CL_DEVICE_MAX_WORK_GROUP_SIZE`**。

- 在 NVIDIA（上限 1024）或 Intel CPU（上限 8192）上，如果宿主用了更大的工作组，`get_local_id(0)` 会超过 255，**写越界到别的本地内存上**——不报错，只是数据错。
- 反过来，如果宿主用了 `local=64`，那 192 个 float 的本地内存白白占着，降低每个计算单元上能并发的工作组数（占用率）。

正确写法是不写死大小，让宿主决定：

```c
// 宿主：clSetKernelArg(kernel, 2, localSize * sizeof(float), NULL);
__kernel void example(__global const float* input, __global float* output,
                      __local float* sharedData, const int n) {
    int gid = (int)get_global_id(0);
    int lid = (int)get_local_id(0);
    ...
}
```

或者，如果一定要静态声明，就用编译期宏并让宿主按同一个宏启动（`examples/04` 的 `TILE` 就是这么做的）。

### 问题 2：没有越界保护

`input[idx]` 和 `output[idx]` 都直接用 `idx`，没有 `if (idx < n)`。

宿主几乎总会把全局尺寸**向上取整**到工作组的整数倍（[04 篇 §4.5.2](./04-programming-model.md)、`ocl_round_up`），所以最后一组里一定有填充工作项，它们的 `idx` 超出 `n`。这个内核会**越界读全局内存、越界写全局内存**。

越界读可能读到垃圾（结果错），越界写可能踩坏相邻的 `cl_mem`（**别的缓冲区的数据被改**，而且症状出现在完全无关的地方）。

`examples/05-reduce-sum` 的 case C 就是这个场景，注释写得很清楚：

```text
    n=1000 rounds up to global=1024, so 16 groups and 24 padding
    work-items. The kernel's bounds check is what makes that safe.
```

**24 个填充工作项。** 没有内核里的越界保护，它们会写 `output[1000..1023]`——而 `output` 只分配了 1000 个 float。

### 问题 3：这个 `barrier` 毫无必要，会教会读者错误的模型

```c
sharedData[get_local_id(0)] = data;    // 每个工作项写自己那一格
barrier(CLK_LOCAL_MEM_FENCE);          // ← 然后同步
float result = sharedData[get_local_id(0)] * 2.0f;   // 又只读自己那一格
```

每个工作项写 `sharedData[lid]`，然后读 `sharedData[lid]`——**同一个下标**。它从来不碰别的工作项的数据，所以根本不需要等别人。这个 `barrier` 是纯开销。

更糟的是它传递了一个错误的心智模型：**"读写本地内存前后要加 barrier"**。真实的规则是：

> **只有当你要读别的（或别的要读你的）本地内存时，才需要 `barrier`。**

`examples/04` 的分块矩阵乘法需要两个 barrier，是因为每个工作项要读**整行整列**瓦片，那些格子是别的工作项填的。`examples/05` 的归约需要 barrier，是因为每一轮折叠都要读**相邻**工作项的值。这两处的 barrier 都有明确的、可指出的数据依赖。

而这段示例里，本地内存的唯一作用是"绕一圈把值放回去再取出来"——它连一次跨工作项的数据交换都没有。**这段代码里的 `__local` 数组是完全多余的**，`float result = data * 2.0f;` 结果一模一样。

### 问题 4：`__global` 指针没有 `const`

```c
__kernel void example(__global float* input, __global float* output)
```

`input` 只被读，应该是 `__global const float*`。这不只是风格：

- 编译器知道它不会被写，可以更激进地缓存和重排。
- 更重要的是**它是一份契约**，写在签名里。少了 `const`，读代码的人无法从签名判断哪个是输入哪个是输出。

本教程所有内核的输入参数都带 `const`，例如 `examples/04-matmul-tiled/kernels/matmul_tiled.cl:15-18`：

```c
__kernel void matmul_tiled(__global const float* A,
                           __global const float* B,
                           __global float* C,
                           const int width) {
```

顺带：`const int width` 里的 `const` 是普通 C 限定符，和地址空间无关。**`__const` 不是任何东西**——原教程的 `matmul_naive` 内核就写了 `__const`，结果在任何设备上都编译不过。这条记录在 [03 篇 §3.2](./03-first-program.md)，build log 也贴在那里。

### 修正版

把四个问题一起改掉：

```c
// 修正版：大小由宿主决定，有越界保护，barrier 有真实的数据依赖，输入带 const。
//
// 这里做的是"每个工作项读相邻工作项的值"——一个最小的、真正需要 barrier 的
// 例子：输出是左邻居的值加自己。原教程那段之所以不需要 barrier，是因为它
// 每个工作项只读自己写的那一格，跨工作项的数据交换一次都没有。
__kernel void shift_right(__global const float* input,
                          __global float*       output,
                          __local float*        scratch,     // 宿主按 local_size 分配
                          const int             n) {
    int gid = (int)get_global_id(0);
    int lid = (int)get_local_id(0);
    int lsz = (int)get_local_size(0);

    // 越界保护。宿主把 global 向上取整到 lsz 的倍数，最后一组一定有填充
    // 工作项；不挡住它们，下面两次内存访问都会越界。
    scratch[lid] = (gid < n) ? input[gid] : 0.0f;

    // 真正需要 barrier 的地方：下一步要读 scratch[lid-1]，那是别的工作项写的。
    barrier(CLK_LOCAL_MEM_FENCE);

    if (gid < n) {
        float left = (lid > 0) ? scratch[lid - 1]
                               : ((gid > 0) ? input[gid - 1] : 0.0f);
        output[gid] = scratch[lid] + left;
    }
}
```

宿主侧配套：

```c
size_t localSize = 256;
size_t globalSize = ocl_round_up((size_t)n, localSize);

// 查这个内核真正允许的上限，取较小者（6.7.3）。
size_t kernelMax = 0;
clGetKernelWorkGroupInfo(kernel, device, CL_KERNEL_WORK_GROUP_SIZE,
                         sizeof(kernelMax), &kernelMax, NULL);
if (localSize > kernelMax) localSize = kernelMax;

// 动态本地内存：第三个参数是字节数，第四个是 NULL。
clSetKernelArg(kernel, 2, localSize * sizeof(float), NULL);

clEnqueueNDRangeKernel(queue, kernel, 1, NULL, &globalSize, &localSize, 0, NULL, NULL);
```

注意 `left` 那一行的三分支：组内不是第一个（读本地）、是组内第一个但不是全局第一个（**跨组，只能回全局内存读**）、是全局第一个（补 0）。**工作组之间无法通过本地内存通信**，这就是 [04 篇 §4.3](./04-programming-model.md) 里"归约必须两轮"的同一个原因在更小尺度上的样子。

## 6.9 本篇要点

1. **OpenCL C 基于 C99，不是 "ANSI C"。** OpenCL C 3.0 可选对齐 C17。写错基础版本会让你避开本来可用的语法。
2. **决定内核语言等级的是 `__OPENCL_C_VERSION__`，不是 `CL_DEVICE_OPENCL_C_VERSION`，更不是 `__OPENCL_VERSION__`。** 实测默认值：两个 Intel 设备都是 `120`，NVIDIA 是 `300`——这就是 `work_group_barrier` 在 Intel 上不加 `-cl-std` 就 `-11`、在 NVIDIA 上连 `-cl-std=CL1.2` 都能过的原因。而 `__OPENCL_VERSION__` 在 Intel 上**四种选项下恒为 300**，用它判断语言等级永远得到错的答案。**要用哪个等级就显式传 `-cl-std`；要确认某个内建函数就用 `cl-build-probe` 编一次。**
3. **旧版本字符串两个方向都会骗你，`platforms[0]` 恰好是最会骗的那个。** Intel CPU 报 `OpenCL C 3.0` 但默认按 1.2 编（字符串是上限不是默认）；UHD 630 报 `OpenCL C 1.2` 却能在 `-cl-std=CL3.0` 下编译成功（字符串连上限都不是）。真实上限查 `CL_DEVICE_OPENCL_C_ALL_VERSIONS`。而 NVIDIA 只宣称 4 项可选特性、不含 `__opencl_c_work_group_collective_functions`，却接受 `work_group_barrier`——**它接受了自己没宣称支持的特性**。本机 `platforms[0]` 正是它，所以"在默认设备上测通了"是最不可靠的一种信心。
4. **`double` 需要 `cl_khr_fp64`，`half` 需要 `cl_khr_fp16`。** 本机三设备都有 `fp64`，但 **NVIDIA 没有 `fp16`**。`double` 的 pragma 在本机三个驱动上都可以省略而仍然编译通过——这**不是**可以省略的证据，照写。
5. **同步原语不止 `barrier` 和 `mem_fence`。** `barrier` 有执行屏障语义，`mem_fence` 只有内存序语义，协作式算法里用错会得到间歇性错误结果。OpenCL C 2.0 起正规拼写是 `work_group_barrier` / `work_group_fence`，另有 `sub_group_barrier` 和一整套 `atomic_*`（原教程完全没提原子）。
6. **`as_<type>` 是位重解释，`convert_<type>` 是数值转换。** `(float)1 == 1.0f`，`as_float(1) == 1.4e-45`。
7. **`__constant` 在核显上不是独立硬件**：UHD 630 的 `max_constant_buffer_size` 与 `max_mem_alloc_size` 完全相同（都是 3401799680 字节）。它真正的价值是"只读"和"工作组内广播同一地址"。
8. **`__local` 有两种分配方式**：内核内静态数组（编译期钉死），或无大小声明 + `clSetKernelArg(k, i, bytes, NULL)` 动态分配（运行时可调）。想按查询到的上限自适应，只能用后者。
9. **`TILE` 有两条独立上限，本机三个设备上都是工作项数那条先撞上，而且约束 A 必须用内核级的数**：`CL_DEVICE_MAX_WORK_GROUP_SIZE` 在 NVIDIA 上是 1024，但它的 `CL_KERNEL_WORK_GROUP_SIZE` 对**每一个**内核（包括一个不用本地内存的空内核）都是 **256**。所以三个设备的实际结论是核显 `TILE ≤ 16`（顶格）、NVIDIA **同样 `TILE ≤ 16`**、CPU `TILE ≤ 90`。按设备数字算会得出"NVIDIA 能到 32"，差 2 倍。`TILE=32` 在核显上失败**不是**本地内存不够（8192 B ≪ 65536 B），而是 1024 > 256——两种失败都报 `-54`。
10. **本地内存占用不能手算。** `__local float tile[256]`：Intel 两个设备报 `CL_KERNEL_LOCAL_MEM_SIZE = 1024`，NVIDIA 报 **1028**。而且这不是偶发——`matmul_tiled` 在 `TILE=8/16/32` 下 Intel 报 512/2048/8192（逐字节等于手算），NVIDIA 报 516/2052/8196（**恒定多 4**）；不用本地内存的内核 Intel 报 0、NVIDIA 报 1。要查，不要算。动态本地内存不计入这个数字，且超限在 `clEnqueueNDRangeKernel` 才报，不在 `clSetKernelArg`。
11. **`CL_KERNEL_PRIVATE_MEM_SIZE = 0` 表示没有寄存器溢出**，是内核健康的信号；数值大说明局部变量太多。
12. **内核里必须做越界保护**，因为宿主会把全局尺寸向上取整，最后一组总有填充工作项。`examples/05` case C 里就有 24 个。
13. **只在有真实跨工作项数据依赖时放 `barrier`。** 原教程那段示例的 `barrier` 和它的整个 `__local` 数组都是多余的——每个工作项只读自己写的那一格，一次交换都没有。这种代码会教出"读写本地内存前后要 barrier"的错误直觉。

---

上一篇：[05-core-concepts.md](./05-core-concepts.md) ｜ 下一篇：[07-cpp-bindings.md](./07-cpp-bindings.md) —— `cl.hpp` 官方 C++ 绑定：与 C API 的逐项对照、`CL_HPP_TARGET_OPENCL_VERSION` 必须与 `CL_TARGET_OPENCL_VERSION` 一致的原因，以及 `examples/08-cpp-bindings` 的完整实现。
