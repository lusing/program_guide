# 5. 核心概念：七类对象、生命周期与本机实测的坑

[04 篇](./04-programming-model.md) 讲的是**执行模型**——一个内核被怎样切成工作组和工作项。这一篇讲的是**对象模型**：`Platform / Device / Context / Queue / Buffer / Image / Event` 七类句柄各自是什么、谁拥有谁、什么时候必须释放，以及每一类在本机三个设备上实测到的限制。

这七类对象是 OpenCL 全部的宿主侧 API 表面。把它们的所有权关系记住，后面每一章的代码都不需要重新解释。

> **验证方式说明**：本篇的数字全部来自本机实测，按证据强度分三类——
> - **设备元数据级**：`tools/clinfo-probe/clinfo-probe.exe` 直接查询 `clGetDeviceInfo` / `clGetPlatformInfo` 打印，5.1、5.2、5.4、5.6 的表格属此类。
> - **主机编译级**：`cl.h` 里声明是否还在、预处理后展开成什么、`cl.exe` 退出码是几。5.2 的宏名纠正与 5.4 的"弃用不是移除"属此类。
> - **运行时数值级**：真的调用 API 并检查返回值。5.5 的子缓冲区权限矩阵（3×3 九种组合逐个跑）与 5.6 的图像格式列表（60 个格式逐个枚举）属此类。
>
> 5.3 关于引用计数与释放时机的说明是**规范级**——本机没有构造出能区分"立即释放"与"引用归零后释放"的实验，那一段不带实测数字。

## 5.0 所有权关系

```text
                    ┌──────────────────────────┐
                    │  Platform（厂商 ICD 提供）  │  ← 不是你的，不创建也不释放
                    └────────────┬─────────────┘
                                 │ clGetDeviceIDs
                                 ▼
                    ┌──────────────────────────┐
                    │  Device（硬件句柄）        │  ← 不是你的，不创建也不释放
                    └────────────┬─────────────┘
                                 │ clCreateContext
                                 ▼
              ┌──────────────────────────────────────┐
              │  Context ★ 唯一真正的"根所有者"         │
              │                                      │
              │   ┌────────────┐   ┌──────────────┐  │
              │   │ Queue(s)   │   │ Program      │  │
              │   └─────┬──────┘   └──────┬───────┘  │
              │         │                 │          │
              │         │          ┌──────┴───────┐  │
              │   ┌─────┴──────┐   │ Kernel(s)    │  │
              │   │ Event(s)   │   └──────────────┘  │
              │   └────────────┘                     │
              │   ┌────────────┐   ┌──────────────┐  │
              │   │ Buffer     │   │ Image        │  │
              │   │  └ SubBuf  │   │  └ Sampler   │  │
              │   └────────────┘   └──────────────┘  │
              └──────────────────────────────────────┘
```

两点必须先说清楚，否则后面所有 `clRelease*` 都像是仪式：

| 类别 | 句柄 | 你要 `clCreate*` 吗 | 你要 `clRelease*` 吗 |
|---|---|:---:|:---:|
| 平台 / 设备 | `cl_platform_id`、`cl_device_id` | ❌ 只是查询结果 | ❌ 释放是未定义行为 |
| 上下文 | `cl_context` | ✅ | ✅ |
| 队列 | `cl_command_queue` | ✅ | ✅ |
| 内存对象 | `cl_mem`（buffer / image / sub-buffer） | ✅ | ✅ |
| 采样器 | `cl_sampler` | ✅ | ✅ |
| 程序与内核 | `cl_program`、`cl_kernel` | ✅ | ✅ |
| 事件 | `cl_event` | ✅（由 `clEnqueue*` 产出） | ✅ |

**`cl_platform_id` 和 `cl_device_id` 不是资源，是标识符。** 它们由 ICD 加载器在进程启动时枚举得到，没有引用计数，调用 `clRelease*` 无从下手。初学者最常见的"清理代码"错误就是给它们也配上释放。

## 5.1 平台 Platform

_platform_ 就是**一个厂商的 OpenCL 实现**。Windows 上它对应一个 ICD（Installable Client Driver）DLL，由 Khronos 的 `OpenCL.dll` 加载器统一发现。ICD 机制的细节见 [02 篇 §2.1.1](./02-environment-setup.md)。

### 5.1.1 两次调用的查询惯例

所有"返回一个列表"的 OpenCL 查询都是同一个形状：先用 `0` 问数量，再分配、再取。

```c
cl_uint numPlatforms = 0;
cl_int err = clGetPlatformIDs(0, NULL, &numPlatforms);   // 第一次：只要数量
if (err != CL_SUCCESS || numPlatforms == 0) { /* 处理 */ }

cl_platform_id* platforms = malloc(numPlatforms * sizeof(cl_platform_id));
clGetPlatformIDs(numPlatforms, platforms, NULL);         // 第二次：填数组
```

`examples/01-device-query/main.c:63-74` 就是这个写法，可以直接对照。

### 5.1.2 原始版本的写法在本机会选错厂商

原教程给的是：

```c
// 原教程（错误）
cl_platform_id platform;
clGetPlatformIDs(1, &platform, NULL);
```

这行代码**在本机会静默选中 NVIDIA**，而不是教程要讲的 Intel 核显。本机实测：

```text
platforms found: 3

=== Platform 0: NVIDIA CUDA ===
    NOTE    : platforms[0] here is "NVIDIA CUDA". Sample code that blindly takes
              platforms[0] would run on this vendor, not necessarily the one
              you meant. That is why every example selects by device name.
```

（以上取自 `01-device-query.exe` 实际输出。）

它错在两层：

1. **没有检查返回值。** `numPlatforms` 未初始化，如果 `clGetPlatformIDs` 失败，`platform` 里是栈上的垃圾。
2. **假设了枚举顺序。** 平台顺序由 ICD 加载器决定，取决于注册表与 DriverStore 的扫描次序，**不是你能依赖的契约**。同一台机器换个驱动版本就可能换序。

正确做法是**遍历所有平台、按设备名匹配**，也就是 `examples/common/ocl_util.h:97-132` 的 `ocl_pick_device()`。它在 [01 篇 §1.4.1](./01-opencl-overview.md) 已逐行讲过，这里不重复。

### 5.1.3 `&platformName` 还是 `platformName`

原教程写：

```c
char platformName[256];
clGetPlatformInfo(platform, CL_PLATFORM_NAME, sizeof(platformName), &platformName, NULL);
```

`&platformName` 的类型是 `char (*)[256]`，形参要的是 `void*`。**它能跑**，因为数组首地址和指向数组的指针值相同——但这是巧合，不是写法。MSVC 在 `/W3` 下不报，换成更严格的检查器就会报指针类型不符。统一写成 `platformName`（数组名自动退化），本教程所有代码都是这个形式。

顺带一个真问题：`char platformName[256];` **没有初始化**。如果查询失败，你打印的是栈上的残留字节，可能不是以 `\0` 结尾的字符串——那就是越界读。本教程一律写 `char name[256] = {0};`。

### 5.1.4 本机三平台实测

| # | `CL_PLATFORM_NAME` | `CL_PLATFORM_VENDOR` | `CL_PLATFORM_VERSION` | `CL_PLATFORM_PROFILE` |
|---|---|---|---|---|
| 0 | NVIDIA CUDA | NVIDIA Corporation | OpenCL 3.0 CUDA 13.3.103 | **FULL_PROFILE** |
| 1 | Intel(R) OpenCL | Intel(R) Corporation | OpenCL 3.0 | **FULL_PROFILE** |
| 2 | Intel(R) OpenCL HD Graphics | Intel(R) Corporation | OpenCL 3.0 | **FULL_PROFILE** |

`CL_PLATFORM_PROFILE` 只有两个合法取值：`FULL_PROFILE` 和 `EMBEDDED_PROFILE`。**不存在 "OpenCL ES"**——那是把 Android 上的 OpenGL ES 类比过来的想象。三个平台全是 `FULL_PROFILE`，这条实测记录在 [01 篇 §1.3.2](./01-opencl-overview.md)。

常用平台属性：

| 属性 | 类型 | 说明 |
|---|---|---|
| `CL_PLATFORM_NAME` | 字符串 | 平台名，**不要用它选设备**（见 5.1.2） |
| `CL_PLATFORM_VENDOR` | 字符串 | 厂商 |
| `CL_PLATFORM_VERSION` | 字符串 | 形如 `OpenCL 3.0 <驱动附加信息>`，是**平台**的规范一致性等级 |
| `CL_PLATFORM_PROFILE` | 字符串 | `FULL_PROFILE` / `EMBEDDED_PROFILE` |
| `CL_PLATFORM_EXTENSIONS` | 字符串 | 平台级扩展，空格分隔 |
| `CL_PLATFORM_HOST_TIMER_RESOLUTION` | `cl_ulong` | 纳秒，主机计时器分辨率 |

> `CL_PLATFORM_VERSION` 和 `CL_DEVICE_VERSION`、`CL_DEVICE_OPENCL_C_VERSION` 是**三个不同的问题**。本机两个 GPU 的平台和设备都说 "OpenCL 3.0"，但内核语言只有 "OpenCL C 1.2"。这三个字符串的区分是整个教程最重要的一条，见 [01 篇 §1.4](./01-opencl-overview.md)。

## 5.2 设备 Device

_device_ 是一个可以执行内核的计算单元集合。**设备句柄属于平台**，所以查询设备必须先有平台。

```c
cl_uint numDev = 0;
clGetDeviceIDs(platform, CL_DEVICE_TYPE_ALL, 0, NULL, &numDev);
cl_device_id* devs = malloc(numDev * sizeof(cl_device_id));
clGetDeviceIDs(platform, CL_DEVICE_TYPE_ALL, numDev, devs, NULL);
```

设备类型过滤值：

| 值 | 含义 | 备注 |
|---|---|---|
| `CL_DEVICE_TYPE_CPU` | CPU | 本机 Intel i7-9700 走这条 |
| `CL_DEVICE_TYPE_GPU` | GPU | 本机 RTX 2060 与 UHD 630 |
| `CL_DEVICE_TYPE_ACCELERATOR` | 加速器 / FPGA | 本机无 |
| `CL_DEVICE_TYPE_CUSTOM` | 不匹配上面任何一类的专用设备 | 不能用 `CL_DEVICE_TYPE_ALL` 枚举到 |
| `CL_DEVICE_TYPE_DEFAULT` | 厂商默认设备 | **随实现而变，不要依赖** |
| `CL_DEVICE_TYPE_ALL` | 除 `CUSTOM` 外全部 | 探测时用这个 |

### 5.2.1 一个不存在宏名——原教程这行编译不过

原教程的设备属性清单里有一条：

```c
CL_DEVICE_CONSTANT_BUFFER_SIZE   // 原教程写法
```

**这个宏不存在。** 在 `D:\cuda\13.3\include\CL\cl.h` 里搜索 `CONSTANT_BUFFER_SIZE` 只有一处命中：

```c
// cl.h:340
#define CL_DEVICE_MAX_CONSTANT_BUFFER_SIZE               0x1020
```

正确名字多了 `MAX_`。这不是"运行时返回错误码"级别的问题，是**主机编译期直接报未声明标识符**。凡是照抄原教程那一行的人，代码从来没编译通过过。

### 5.2.2 本机三设备实测属性

`tools/clinfo-probe/clinfo-probe.exe` 的实际输出，整理成表：

| 属性 | NVIDIA RTX 2060 | Intel UHD 630（本教程目标） | Intel i7-9700 CPU |
|---|---|---|---|
| `CL_DEVICE_VERSION` | OpenCL 3.0 CUDA | OpenCL 3.0 NEO | OpenCL 3.0 (Build 0) |
| `CL_DEVICE_OPENCL_C_VERSION` | OpenCL C 1.2 | OpenCL C 1.2 | **OpenCL C 3.0** |
| `max_compute_units` | 30 | 24 | 8 |
| `max_work_group_size` | 1024 | **256** | 8192 |
| `max_work_item_sizes` | 1024×1024×64 | 256×256×256 | 8192×8192×8192 |
| `global_mem_size` | 6143.7 MiB | 6488.4 MiB | 16221.1 MiB |
| `local_mem_size` | 48 KiB | 64 KiB | 256 KiB |
| `local_mem_type` | `CL_LOCAL` | `CL_LOCAL` | **`CL_GLOBAL`** |
| `max_mem_alloc_size` | 1535.9 MiB | 3244.2 MiB | 8110.5 MiB |
| `max_constant_buffer_size` | 64 KiB | **3244.2 MiB** | 128 KiB |
| `max_constant_args` | 9 | 8 | **480** |
| `mem_base_addr_align_bits` | 4096 | 1024 | 1024 |
| `queue_properties` | 0x3 | 0x3 | 0x3 |
| `image_support` | CL_TRUE | CL_TRUE | CL_TRUE |
| `il_version`（SPIR-V） | *(空)* | SPIR-V_1.2 | SPIR-V_1.2 |
| `svm_capabilities` | 0x0 | 0xB | 0xF |
| 扩展总数 | 26 | 63 | 45 |

从这张表能直接读出四条结论，每一条都会在后面某章变成硬约束：

1. **`max_work_group_size` 三个设备差 32 倍**（256 / 1024 / 8192）。任何硬编码的 `local[3] = {256,1,1}` 都只在其中一个上成立。这是 [04 篇 §4.5](./04-programming-model.md) 那张 `-54` 实测表的根源。
2. **CPU 设备的 `local_mem_type` 是 `CL_GLOBAL`**——它的"本地内存"就是全局内存的一块缓存视图，不是独立的片上 SRAM。在 CPU 设备上做 `__local` 分块矩阵乘法**没有带宽收益**，只有同步开销。[04 篇 §4.8.1](./04-programming-model.md) 展开讲。
3. **`max_constant_args` 相差 60 倍**（8 / 9 / 480）。内核签名里 `__constant` 参数的个数上限是设备属性，不是语言属性。
4. **`mem_base_addr_align_bits` 单位是位不是字节**。NVIDIA 是 4096 位 = 512 字节，Intel 是 1024 位 = 128 字节。子缓冲区起点必须对齐到这个值（见 5.5.3），忘了除以 8 是最常见的踩法。

### 5.2.3 `max_constant_buffer_size` 在核显上为什么是 3.2 GiB

注意 Intel UHD 630 那一列：

```text
max_mem_alloc_size                 3401799680 (3244.2 MiB)
max_constant_buffer_size           3401799680 (3244.2 MiB)
```

**两个数字完全相同**，都是 3401799680。这不是巧合：核显没有独立的常量内存硬件，`__constant` 在这类设备上就是**带缓存提示的全局内存**，所以它的上限直接塌缩成"单次分配上限"。

对比 NVIDIA RTX 2060：`max_constant_buffer_size = 64 KiB`，这才是有专用常量缓存时的典型值——64 KiB 是常量缓存的物理容量。

**教训**：不要从"常量内存很小、要省着用"这条经验出发去写代码，那条经验只在有专用常量缓存的设备上成立。要么查询，要么按最保守的 64 KiB 设计。

### 5.2.4 `size_t` 不是 `cl_uint`

`CL_DEVICE_MAX_WORK_GROUP_SIZE` 返回 **`size_t`**（本机 64 位 = 8 字节）。用 4 字节的 `cl_uint` 去接：

```c
cl_uint maxWG = 0;                                                    // 错
clGetDeviceInfo(dev, CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(maxWG), &maxWG, NULL);
// → 返回 -30 CL_INVALID_VALUE，maxWG 保持 0
printf("max work group: %u\n", maxWG);                                // 打印 "0"，纯虚构
```

驱动**检查 `param_value_size` 是否匹配**，不匹配就拒绝并返回 `-30`。变量停在初始值 0，而你打印出一个自信的、完全错误的 "0"。

`examples/common/ocl_util.h:143-148` 的注释记录了这个坑，`examples/01-device-query/main.c:111-113` 是正确写法：

```c
// size_t, not cl_uint - see the note in ocl_util.h.
size_t maxWG = 0;
clGetDeviceInfo(devs[i], CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(maxWG), &maxWG, NULL);
```

**规律**：所有"尺寸/数量"类设备属性（`MAX_WORK_GROUP_SIZE`、`MAX_WORK_ITEM_SIZES`、`IMAGE2D_MAX_WIDTH`、`PROFILING_TIMER_RESOLUTION` 除外）都要先查 `cl.h` 里的返回类型，不要凭直觉。

## 5.3 上下文 Context

_context_ 是**宿主侧的根所有者**。它持有设备集合，所有内存对象、命令队列、程序都挂在某个上下文下面。跨上下文的对象不能混用——把一个上下文的 `cl_mem` 传给另一个上下文的队列，返回 `-34 CL_INVALID_CONTEXT`。

```c
cl_int err = CL_SUCCESS;
cl_context context = clCreateContext(NULL, 1, &device, NULL, NULL, &err);
if (!context) { /* err 里有原因 */ }
...
clReleaseContext(context);
```

五个参数依次是：属性列表、设备数、设备数组、错误回调、回调用户数据、返回码。

带属性的形式：

```c
cl_context_properties props[] = {
    CL_CONTEXT_PLATFORM, (cl_context_properties)platform,
    0                                    // 属性列表必须以 0 结尾
};
cl_context context = clCreateContext(props, 1, &device, NULL, NULL, &err);
```

`CL_CONTEXT_PLATFORM` 在**多平台共存**时才有意义：它明确告诉加载器这个设备属于哪个 ICD。本机有三个平台，所以本教程的示例都带上它更稳妥；不过 `clCreateContext` 也能从 `cl_device_id` 反查平台，传 `NULL` 同样工作——`examples/` 里七个示例都传 `NULL`，实测通过。

### 5.3.1 一个上下文覆盖所有设备，是好主意吗

原教程倾向于"建一个包含全部设备的上下文"。本教程不这么做，`examples/02-vector-add/main.c` 建的是**单设备上下文**：

```c
cl_context context = clCreateContext(NULL, 1, &device, NULL, NULL, &err);
```

理由很实际：多设备上下文里，`clBuildProgram` 会**为每个设备各编译一次**，任何一个设备编译失败整个 program 就不可用；而错误日志是**按设备分开**的，你得循环 `clGetProgramBuildInfo` 才能看到到底谁失败了。本机的 NVIDIA 设备不支持 SPIR-V，一个跨三设备的上下文会立刻把这个问题变成噪音。多设备协作是 [10 篇](./09-practical-examples.md) 的主题，那时才值得付这个复杂度。

### 5.3.2 生命周期（规范级）

`cl_context` 是**引用计数**的。`clReleaseContext` 只是把计数减一，减到 0 才真正销毁；而且销毁会等到挂在其上的所有命令完成。实际影响：

- `clCreateBuffer` 会让内部持有的上下文引用加一，所以**先释放上下文、再释放 buffer 是合法的**，但反过来更清晰。
- 程序退出前不释放不会导致数据丢失，但会掩盖真正的泄漏。本教程所有示例都在 `main` 末尾显式释放，`examples/07-async-events/main.c:539-547` 是完整的释放序列，可作模板。

> **诚实边界**：上面关于"释放会等待命令完成"的描述来自规范，本机没有构造能观测到该行为的实验（要观测需要一个耗时足够长、且在释放后才结束的内核）。当作规范级结论使用。

## 5.4 命令队列 Command Queue

_queue_ 是**提交命令的通道**。所有 `clEnqueue*` 都要一个队列。命令进队之后何时执行由设备和驱动决定。

### 5.4.1 `clCreateCommandQueue` 没有被移除，只是弃用

原教程写：

> **注意**：在 OpenCL 3.0 中，`clCreateCommandQueue` 已被移除，必须使用 `clCreateCommandQueueWithProperties`。

**"已被移除"是错的。** 三条独立证据：

**① 头文件里声明还在。** `D:\cuda\13.3\include\CL\cl.h:1914-1918`：

```c
/* Deprecated OpenCL 2.0 APIs */
extern CL_API_ENTRY CL_API_PREFIX__VERSION_1_2_DEPRECATED cl_command_queue CL_API_CALL
clCreateCommandQueue(cl_context                     context,
                     cl_device_id                   device,
                     cl_command_queue_properties    properties,
                     cl_int *                       errcode_ret) CL_API_SUFFIX__VERSION_1_2_DEPRECATED;
```

注意分组注释写的是 **"Deprecated OpenCL 2.0 APIs"**——弃用于 **2.0**，不是 3.0。

**② 预处理后确实带弃用标记，但函数仍在。** 用 `cl /P /DCL_TARGET_OPENCL_VERSION=300` 展开一个调用它的测试文件，得到：

```c
extern   __declspec(deprecated) cl_command_queue __stdcall
clCreateCommandQueue(cl_context                     context,
                     cl_device_id                   device,
                     cl_command_queue_properties    properties,
                     cl_int *                       errcode_ret)  ;
```

`__declspec(deprecated)` 是 MSVC 的弃用标记（`cl_platform.h:81-82`）。**存在，且被标记**——这正是"弃用"而非"移除"的机器可检验定义。

**③ 编译通过。** 同一个测试文件在 `CL_TARGET_OPENCL_VERSION=120` 和 `=300` 下都是 `cl.exe exit = 0`。

弃用标记是否生效由 `CL_TARGET_OPENCL_VERSION` 控制，机制在 `cl_version.h:71-73`：

```c
#if CL_TARGET_OPENCL_VERSION <= 120 && !defined(CL_USE_DEPRECATED_OPENCL_1_2_APIS)
#define CL_USE_DEPRECATED_OPENCL_1_2_APIS
#endif
```

而 `cl_platform.h:103-110` 据此决定 `CL_API_PREFIX__VERSION_1_2_DEPRECATED` 是空还是 `__declspec(deprecated)`。所以：

| `CL_TARGET_OPENCL_VERSION` | `CL_USE_DEPRECATED_OPENCL_1_2_APIS` | 弃用标记 | 能用吗 |
|:---:|:---:|:---:|:---:|
| 120 | 自动定义 | 无 | ✅ 完全静默 |
| 300 | 不定义 | `__declspec(deprecated)` | ✅ 能编译，理论上会 C4996 |

同样被弃用的还有 `clCreateSampler`（`cl.h:1920-1925`）、`clEnqueueTask`、`clUnloadCompiler`、`clGetExtensionFunctionAddress`。

本教程的 `examples/06-image-brightness/main.c:99-110` 就调用了 `clCreateSampler`，并**显式压掉警告**，把理由写在注释里：

```c
    // clCreateSampler is DEPRECATED in OpenCL 3.0 in favour of
    // clCreateSamplerWithProperties, but it is still present and still the clearest
    // way to show the three settings; the replacement takes the same three values as
    // a property list.
    cl_sampler sampler = NULL;
    if (useHostSampler) {
        // Suppressed on purpose: the deprecation is acknowledged above, and the build
        // output should stay readable.
#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable : 4996)
#endif
        sampler = clCreateSampler(context, CL_FALSE, CL_ADDRESS_CLAMP_TO_EDGE,
                                  CL_FILTER_NEAREST, &err);
#if defined(_MSC_VER)
```

**实用结论**：新代码用 `clCreateCommandQueueWithProperties`（`cl.h:1067`）；但看到旧代码里的 `clCreateCommandQueue` 不要以为它跑不起来——本机三个平台全都还支持。

### 5.4.2 正确的两种创建方式

```c
// 方式一：新代码，OpenCL 2.0+ 的正规写法，OpenCL 3.0 下唯一非弃用的选择
cl_queue_properties props[] = {
    CL_QUEUE_PROPERTIES, (cl_queue_properties)CL_QUEUE_PROFILING_ENABLE,
    0                                        // 属性列表必须以 0 结尾
};
cl_command_queue queue =
    clCreateCommandQueueWithProperties(context, device, props, &err);

// 方式二：什么属性都不要，直接传 NULL
cl_command_queue queue =
    clCreateCommandQueueWithProperties(context, device, NULL, &err);
```

原教程写的是：

```c
cl_queue_properties props[] = { CL_QUEUE_PROPERTIES, 0, 0 };   // 原教程
```

`CL_QUEUE_PROPERTIES` 的值是 `0`——**一个值为 0 的属性等于什么都没要求**，那还不如直接传 `NULL`。这行代码不报错，但它掩盖了作者其实想要什么。属性列表的语义是"键, 值, 键, 值, …, 0"，中间的 `0` 是**值**，不是结束符。

队列属性只有三个合法值：

| 属性 | 值 | 作用 |
|---|---|---|
| `CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE` | `1 << 0` | 允许乱序执行 |
| `CL_QUEUE_PROFILING_ENABLE` | `1 << 1` | 允许读取事件的四个时间戳 |
| `CL_QUEUE_ON_DEVICE` \| `CL_QUEUE_ON_DEVICE_DEFAULT` | — | OpenCL 2.0 设备端队列，本机不涉及 |

### 5.4.3 原教程的一处自相矛盾：建队列不开 profiling，第 7 节却做 profiling

原教程 §4 创建队列时属性是 `0`（不带 `CL_QUEUE_PROFILING_ENABLE`），到 §7「事件」又写：

```c
clGetEventProfilingInfo(event, CL_PROFILING_COMMAND_START, sizeof(startTime), &startTime, NULL);
```

**这两段拼在一起是跑不通的。** 队列没开 profiling，事件就不带时间戳，`clGetEventProfilingInfo` 返回 **`-7 CL_PROFILING_INFO_NOT_AVAILABLE`**，而原教程没有检查这个返回值——于是 `startTime` / `endTime` 保持未初始化，算出来的"耗时"是栈垃圾。

`examples/07-async-events/main.c:397-402` 是正确写法，也是本机跑通的那一份：

```c
    cl_queue_properties inOrderProps[] = {
        CL_QUEUE_PROPERTIES, (cl_queue_properties)CL_QUEUE_PROFILING_ENABLE,
        0
    };
    cl_command_queue qInOrder = clCreateCommandQueueWithProperties(context, device, inOrderProps, &err);
    if (!qInOrder) { printf("[FAIL] in-order queue -> %s\n", ocl_err_name(err)); return ocl_report(0); }
```

**规律**：只要打算读任何 `CL_PROFILING_*`，建队列时就必须带 `CL_QUEUE_PROFILING_ENABLE`。这是"创建时的一个 bit"决定"运行时能不能查"的典型例子，事后无法补。

### 5.4.4 本机实测：三个设备都支持乱序与 profiling

`CL_DEVICE_QUEUE_PROPERTIES` 报告**设备允许**的队列属性上限（能不能，不是你有没有开）：

```text
NVIDIA GeForce RTX 2060        queue_properties  0x3 (out_of_order=1 profiling=1)
Intel(R) UHD Graphics 630      queue_properties  0x3 (out_of_order=1 profiling=1)
Intel(R) Core(TM) i7-9700 CPU  queue_properties  0x3 (out_of_order=1 profiling=1)
```

`0x3 = (1<<0) | (1<<1)`，三个设备都全支持。所以 `examples/07` 的 C、D 两个乱序用例在本机**永不跳过**。

`examples/07-async-events/main.c:325-332` 就是在运行时查这个值并据此决定要不要建乱序队列：

```c
    cl_command_queue_properties devQueueProps = 0;
    clGetDeviceInfo(device, CL_DEVICE_QUEUE_PROPERTIES,
                    sizeof(devQueueProps), &devQueueProps, NULL);
    int outOfOrderOk = (devQueueProps & CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE) != 0;
```

实测输出：

```text
[queue]  CL_DEVICE_QUEUE_PROPERTIES = 0x3 -> out-of-order supported, profiling supported
```

### 5.4.5 顺序队列 vs 乱序队列：事件的角色完全不同

这是最容易搞混的一点，`examples/07` 用四个 case 把它拆开：

```text
顺序队列（in-order，默认）
  ┌──────────────────────────────────────────────────┐
  │ write A → scale → read C   严格按提交顺序执行      │
  └──────────────────────────────────────────────────┘
  ⇒ 设备侧不需要事件来保证 write 先于 scale。
  ⇒ 你仍然需要事件或 clFinish，但那是为了知道
    "主机什么时候可以碰自己那块内存"，不是为了让设备排队。

乱序队列（out-of-order）
  ┌──────────────────────────────────────────────────┐
  │ write A ─┐                                        │
  │          ├─► 驱动可以任意重排、并行                 │
  │ scale   ─┘                                        │
  └──────────────────────────────────────────────────┘
  ⇒ wait-list 是唯一的排序手段。
  ⇒ 漏掉它不报错，只产生竞争。
```

`examples/07` 的 case D 把这个竞争**量化**了：去掉 wait-list 后重复跑 20 次，用毒化值（`-1e30`）预先写入中间缓冲区，否则上一轮的正确结果会把竞争掩盖掉。实测结论写在该文件 `main.c:16-19` 的头注释里：

> with the wait-lists removed, the combine kernel started before its producers finished in roughly half of twenty runs, and the output was still numerically correct in all twenty. The overlap is real and the damage is not yet visible. That is the worst possible feedback.

**"结果对"不能证明"依赖对"。** 这是本教程反复强调的一条，case D 存在的意义就是让读者亲眼看到一次"跑对了的竞争"。

### 5.4.6 释放

```c
clReleaseCommandQueue(queue);
```

释放是引用计数减一；队列里还没执行完的命令会继续执行完。所以"释放队列"不等于"取消命令"——取消要用 `clFlush` / `clFinish` 配合，或 OpenCL 2.0 的 `clEnqueueBarrierWithWaitList`。

## 5.5 缓冲区 Buffer

_buffer_ 是一段**设备可见的线性内存**。它是 `cl_mem` 的一种（`cl_mem` 是 buffer、image、sub-buffer 的共同句柄类型）。

```c
cl_mem bufA = clCreateBuffer(context, CL_MEM_READ_ONLY,  N * sizeof(float), NULL, &err);
cl_mem bufC = clCreateBuffer(context, CL_MEM_WRITE_ONLY, N * sizeof(float), NULL, &err);
```

以上两行逐字取自 `examples/02-vector-add/main.c:124-126`，本机跑通。

### 5.5.1 内存标志

| 标志 | 含义 | 谁在读写 |
|---|---|---|
| `CL_MEM_READ_WRITE` | 默认，内核可读可写 | 内核 |
| `CL_MEM_READ_ONLY` | 内核**只读** | 内核 |
| `CL_MEM_WRITE_ONLY` | 内核**只写** | 内核 |
| `CL_MEM_COPY_HOST_PTR` | 创建时从 `host_ptr` **拷一份**进去 | — |
| `CL_MEM_USE_HOST_PTR` | 直接**用**这块主机内存，不额外分配 | — |
| `CL_MEM_ALLOC_HOST_PTR` | 由驱动分配一块**主机可访问**的内存 | — |
| `CL_MEM_HOST_READ_ONLY` / `_WRITE_ONLY` / `_NO_ACCESS` | 限制**主机侧**的访问方向 | 主机 |

两个高频误解：

**`READ_ONLY` 是站在内核的角度说的，不是主机的。** `CL_MEM_READ_ONLY` 的意思是"内核只读它"，主机照样可以 `clEnqueueWriteBuffer` 往里写。反过来说，一个 `CL_MEM_WRITE_ONLY` 的 buffer，主机用 `clEnqueueReadBuffer` 去读是**允许的**——`examples/02` 就是这么把结果取回来的：

```c
cl_mem bufC = clCreateBuffer(context, CL_MEM_WRITE_ONLY, N * sizeof(float), NULL, &err);
```

`CL_MEM_READ_WRITE` / `READ_ONLY` / `WRITE_ONLY` 三者**互斥**，只能选一个；后四个 `HOST_*` 是另一组，也是互斥的；两组之间可以按位或。

**`USE_HOST_PTR` 不是"零拷贝加速开关"。** 它让驱动直接引用你给的指针，但在独显上驱动往往仍要维护一份设备侧副本，而且从此你的主机内存生命周期被绑进了 OpenCL。除非在 CPU 设备或 APU 上明确测出收益，否则用 `COPY_HOST_PTR`。

### 5.5.2 数据搬运的四个入口

```c
clEnqueueWriteBuffer(queue, buf, blocking, offset, size, hostPtr, nWait, waitList, &ev);
clEnqueueReadBuffer (queue, buf, blocking, offset, size, hostPtr, nWait, waitList, &ev);
clEnqueueCopyBuffer (queue, src, dst, srcOff, dstOff, size, nWait, waitList, &ev);
clEnqueueMapBuffer  (queue, buf, blocking, mapFlags, offset, size, nWait, waitList, &mapPtr, &ev);
```

`blocking` 传 `CL_TRUE` 时，调用**返回即传输完成**；传 `CL_FALSE` 时，调用返回只代表**命令已入队**。这个区别只关乎**主机**，设备侧做的工作一模一样。

`examples/07-async-events` 的 case B 专门演示 `CL_FALSE` 的后果：入队后立刻去读主机缓冲区，实测发现部分元素还没到位，然后 `clFinish` 之后全部正确。它把这次偷看**明确标为仅供参考**，因为在快驱动上它可能合法地读到 0 个错误：

```c
        printf("    peek before clFinish: %d/%d elements not yet correct\n", wrong, n);
        printf("    (this read is INFORMATIONAL - the buffer is not the host's to\n");
        printf("     touch until the command completes, so either outcome is legal)\n");
```

### 5.5.3 子缓冲区：权限不得比父缓冲区更宽

子缓冲区是**父缓冲区的一个视图**，不分配新内存：

```c
cl_buffer_region region;
region.origin = 128;                  // 字节偏移
region.size   = 64 * sizeof(float);   // 字节长度

cl_mem sub = clCreateSubBuffer(parent, flags, CL_BUFFER_CREATE_TYPE_REGION, &region, &err);
```

原教程写的是：父缓冲区 `CL_MEM_READ_ONLY`，子缓冲区 `CL_MEM_READ_WRITE`。**这在本机直接被拒。**

九种组合逐个实测（Intel UHD 630，父缓冲区 4096 字节，子缓冲区 `origin=128, size=256`）：

| 父 ↓ / 子 → | `READ_ONLY` | `WRITE_ONLY` | `READ_WRITE` |
|---|:---:|:---:|:---:|
| **`READ_ONLY`** | ✅ `CL_SUCCESS` | ❌ `-30 CL_INVALID_VALUE` | ❌ `-30 CL_INVALID_VALUE` |
| **`WRITE_ONLY`** | ❌ `-30 CL_INVALID_VALUE` | ✅ `CL_SUCCESS` | ❌ `-30 CL_INVALID_VALUE` |
| **`READ_WRITE`** | ✅ `CL_SUCCESS` | ✅ `CL_SUCCESS` | ✅ `CL_SUCCESS` |

规律一目了然：**子缓冲区的权限集合必须是父缓冲区权限的子集。** 父是只读，子就不能写；父是只写，子就不能读；父是读写，子随你收窄。

原教程那种写法返回 `-30 CL_INVALID_VALUE`——而 `-30` 是 OpenCL 里最泛的错误码，几乎每个参数错误都报它，所以这个 bug 极难定位。

还有一条**对齐**约束，同样实测：

```text
[align]  CL_DEVICE_MEM_BASE_ADDR_ALIGN = 1024 bits = 128 bytes
```

`region.origin` 必须是 `CL_DEVICE_MEM_BASE_ADDR_ALIGN / 8` 的整数倍。本机 Intel 是 **128 字节**，NVIDIA RTX 2060 是 **512 字节**（4096 位）。这个属性单位是**位**，忘记除以 8 会让所有子缓冲区创建都返回 `-30`，而且换台机器就可能突然好了——典型的"在 A 机器上能跑，B 机器上不行"。

所以正确的起点算法是先查再算：

```c
cl_uint alignBits = 0;
clGetDeviceInfo(dev, CL_DEVICE_MEM_BASE_ADDR_ALIGN, sizeof(alignBits), &alignBits, NULL);
size_t alignBytes = alignBits / 8;
region.origin = ((alignBytes + sizeof(float) - 1) / sizeof(float)) * sizeof(float);
```

另外两条容易漏的：

- `region.origin + region.size` 不得超过父缓冲区大小。
- 子缓冲区有自己的引用计数，`clReleaseMemObject(sub)` 只释放视图；父缓冲区必须单独释放，且**释放父不会自动释放子**。

### 5.5.4 单次分配上限

`CL_DEVICE_MAX_MEM_ALLOC_SIZE` 是**单个** `cl_mem` 的上限，不是总量。本机：

| 设备 | `max_mem_alloc_size` | `global_mem_size` | 比例 |
|---|---|---|---|
| NVIDIA RTX 2060 | 1535.9 MiB | 6143.7 MiB | 1 : 4 |
| Intel UHD 630 | 3244.2 MiB | 6488.4 MiB | 1 : 2 |
| Intel i7-9700 CPU | 8110.5 MiB | 16221.1 MiB | 1 : 2 |

超了返回 `-61 CL_INVALID_BUFFER_SIZE`。**决定单个缓冲区上限的是 `max_mem_alloc_size`，不是 `global_mem_size`**——本机 NVIDIA 上这两个数差 4 倍，按显存总量去分配会直接失败。

注意核显与 CPU 设备的 `global_mem_size` 都是**系统内存的一部分**（UHD 630 报 6488.4 MiB，i7-9700 报 16221.1 MiB，都不是独立显存），这也是为什么核显的 `max_constant_buffer_size` 会和它的 `max_mem_alloc_size` 数值完全相同（见 5.2.3）。

## 5.6 图像 Image

_image_ 也是 `cl_mem`，但它不是"一段线性内存"。它是**带格式的二维/三维纹理对象**，访问它必须经过采样器，硬件会给三样东西：

1. **边界处理**——`CL_ADDRESS_CLAMP` / `CLAMP_TO_EDGE` / `REPEAT`，越界读不崩，返回确定的值。
2. **过滤**——`CL_FILTER_NEAREST` / `CL_FILTER_LINEAR`，线性插值由硬件做。
3. **二维局部性**——图像内存按 tile 布局，2D 邻域访问比在 buffer 里手算 `y*width+x` 快得多。

代价是：**你不能对图像做指针算术，只能用 `read_imagef` / `write_imagef`**，而且坐标语义要自己搞清楚。

### 5.6.1 两个结构体，以及原教程那种初始化为什么危险

```c
cl_image_format fmt;
fmt.image_channel_order     = CL_RGBA;
fmt.image_channel_data_type = CL_FLOAT;

cl_image_desc desc;
memset(&desc, 0, sizeof(desc));
desc.image_type      = CL_MEM_OBJECT_IMAGE2D;
desc.image_width     = (size_t)w;
desc.image_height    = (size_t)h;
desc.image_row_pitch = 0;

cl_mem img = clCreateImage(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                           &fmt, &desc, hostPixels, &err);
```

以上逐字取自 `examples/06-image-brightness/main.c:67-81`，本机跑通。

原教程写的是位置聚合初始化：

```c
cl_image_desc desc = { CL_MEM_OBJECT_IMAGE2D, width, height, 0, 0, 0, 0, 0, 0 };   // 原教程
```

`cl_image_desc` 有 **10 个字段**（`image_type`、`image_width`、`image_height`、`image_depth`、`image_array_size`、`image_row_pitch`、`image_slice_pitch`、`num_mip_levels`、`num_samples`、`buffer`），而这里只给了 **9 个值**。最后一个字段被隐式补 0，碰巧是对的——但这是**运气**：

- 字段顺序记错一个，编译器一句话都不说，运行时得到 `-30` 或一张形状完全不对的图像。
- 哪天头文件加了字段，这段代码的意思会静默改变。
- 读代码的人无法从 `0, 0, 0, 0, 0, 0` 看出哪个 0 是 `row_pitch`。

**`memset` + 具名字段赋值**多打几行字，换来的是"每一个 0 都知道自己是谁"。本教程一律用后者。

`image_row_pitch = 0` 有具体含义：**请驱动自己决定行跨度**。正因如此，`CL_MEM_COPY_HOST_PTR` 才接受一个紧凑的 `w*h*4` float 数组。如果你自己传了 `row_pitch`，主机数据的每一行也必须按那个跨度对齐，否则图像会**斜着错位**——这是图像编程最经典的视觉症状。

### 5.6.2 本机实测：支持哪些格式，只能问驱动

原教程列了"常用图像格式：`CL_RGBA`, `CL_ARGB`, `CL_BGRA` 等通道顺序"，像是随便挑一个都能用。**不是。** 哪个通道顺序可用是设备相关的，唯一的权威来源是 `clGetSupportedImageFormats`。

`examples/06-image-brightness` 在启动时就把这张表打出来。本机 Intel UHD 630 的实测输出：

```text
[images] CL_DEVICE_IMAGE_SUPPORT      = CL_TRUE
[images] max image2d                  = 16384 x 16384
[images] max samplers / read / write  = 16 / 128 / 128
[images] supported 2D read formats    = 60 total, 12 of them CL_RGBA
[images] channel orders supported     : RGBA(12) BGRA(1) R(12) A(4) RG(12) LUMINANCE(4) INTENSITY(4) sRGBA(1) sBGRA(1) 0x410E(1) DEPTH(2) 0x10BE(2) 0x4076(1) 0x4077(1) 0x4078(1) 0x4079(1)
[images] CL_RGBA channel data types   : UNORM_INT8 UNORM_INT16 SIGNED_INT8 SIGNED_INT16 SIGNED_INT32 UNSIGNED_INT8 UNSIGNED_INT16 UNSIGNED_INT32 HALF_FLOAT FLOAT SNORM_INT8 SNORM_INT16
[images] RGBA/CL_FLOAT supported      = yes
[images] CL_ARGB supported            = NO
```

**`CL_ARGB supported = NO`。** 原教程点名的三个通道顺序里，有一个在本机目标设备上根本不存在。如果照着写 `fmt.image_channel_order = CL_ARGB;`，`clCreateImage` 返回 **`-39 CL_INVALID_IMAGE_FORMAT_DESCRIPTOR`**。

> 本篇引用的错误码数值（`-7`、`-30`、`-34`、`-39`、`-54`、`-61`）全部逐条对照 `cl.h:197-255` 核过。其中 `-34 CL_INVALID_CONTEXT` 与 `-39 CL_INVALID_IMAGE_FORMAT_DESCRIPTOR` 初稿分别写成了 `-38`（那是 `CL_INVALID_MEM_OBJECT`）和 `-40`——两处都不是运行时暴露的，是查表查出来的。**错误码数值不要凭记忆写**，这是 [03 篇 §3.7](./03-first-program.md) 已经栽过一次的同一个坑。

`clGetSupportedImageFormats` 的用法也是两次调用惯例，注意它要的是**上下文**而不是设备，还要指明用途（读写方向会影响可用格式集合）：

```c
cl_uint numFmt = 0;
clGetSupportedImageFormats(context, CL_MEM_READ_ONLY, CL_MEM_OBJECT_IMAGE2D, 0, NULL, &numFmt);
cl_image_format* fmts = malloc(numFmt * sizeof(cl_image_format));
clGetSupportedImageFormats(context, CL_MEM_READ_ONLY, CL_MEM_OBJECT_IMAGE2D, numFmt, fmts, NULL);
```

（取自 `examples/06-image-brightness/main.c:292-298`。）

### 5.6.3 那六个匿名通道顺序是什么

上面的直方图里有六个 `cl.h` 里没有名字的值。逐个查出来（`cl_ext.h` 与 `cl_gl.h`）：

| 值 | 宏名 | 定义位置 | 所属扩展 |
|---|---|---|---|
| `0x4076` | `CL_YUYV_INTEL` | `cl_ext.h:2967` | `cl_intel_packed_yuv` |
| `0x4077` | `CL_UYVY_INTEL` | `cl_ext.h:2968` | `cl_intel_packed_yuv` |
| `0x4078` | `CL_YVYU_INTEL` | `cl_ext.h:2969` | `cl_intel_packed_yuv` |
| `0x4079` | `CL_VYUY_INTEL` | `cl_ext.h:2970` | `cl_intel_packed_yuv` |
| `0x410E` | `CL_NV12_INTEL` | `cl_ext.h:3023` | `cl_intel_planar_yuv` |
| `0x10BE` | `CL_DEPTH_STENCIL` | **`cl_gl.h:362`** | `cl_khr_gl_depth_images` |

而这三个扩展，UHD 630 **确实都在扩展列表里**（`clinfo-probe` 过滤后的输出）：

```text
      + cl_khr_gl_depth_images
      + cl_intel_packed_yuv
      + cl_intel_planar_yuv
```

两条值得记住的：

1. **五个 packed/planar YUV 格式是 Intel 的视频共享扩展**，为 D3D11 / VA-API 零拷贝视频处理准备。在 NVIDIA 上不会出现。它们出现在格式列表里，是"扩展真的生效了"的直接证据——比读扩展字符串更硬。
2. **`CL_DEPTH_STENCIL` 定义在 `cl_gl.h` 而不是 `cl.h`。** 只 `#include <CL/cl.h>` 的程序拿不到这个宏，即使设备支持这个格式。这类"能力在、名字不在"的情况，只有 `clGetSupportedImageFormats` 返回的裸数值能告诉你。

### 5.6.4 采样器：常量式与宿主式两条路

`examples/06` 把同一个亮度调整内核跑了六个 case，其中三个专门对比采样器的来源：

| case | 采样器来源 | 结果 |
|---|---|---|
| A | 内核里的 `const sampler_t`，`COORDS_FALSE` | ✅ 通过，**推荐形式** |
| B | 内核里的 `const sampler_t`，`COORDS_TRUE`，但传整数像素坐标 | 4096 像素里 **3007 个错**，渐变图塌成 **4 种颜色** |
| C | `const sampler_t`，`COORDS_TRUE`，传 `(x+0.5)/w` | ✅ 通过 |
| D | 宿主 `clCreateSampler` + `clSetKernelArg` | ✅ 通过 |
| E | 100×37 图像，`global={100,37}` 未对齐 | 拒绝，`-54` |
| F | 同上但对齐到 `{112,48}` | ✅ 通过 |

case B 是本篇最值得看的失败：

```text
        mismatch at (1,0) ch0: got 1.000000 want 0.515873
        mismatch at (2,0) ch0: got 1.000000 want 0.531746
        mismatch at (3,0) ch0: got 1.000000 want 0.547619
        1089/4096 pixels correct, max abs err 4.841e-01, 4 distinct output colors
```

`COORDS_TRUE` 意味着驱动计算 `s = coord * width`。传整数 `x` 就得到 `s = x*64`，被 `CLAMP_TO_EDGE` 钉在第 63 个纹素上——**只有 `x == 0` 幸存**。一张 64×64 的连续渐变因此塌成 4 种颜色。

case E 是 [04 篇 §4.5.2](./04-programming-model.md) 那条"全局尺寸必须逐维整除本地尺寸"的规则在二维图像上的复现：`100 % 16 = 4`、`37 % 16 = 5`，直接 `-54`。case F 把它对齐到 `{112,48}`，多启动 1624 个填充工作项，由内核里的 `get_image_width/height` 越界保护挡住。

> **诚实边界**：以上格式列表只在 **Intel UHD 630** 上测过。NVIDIA 与 Intel CPU 设备的支持集合必然不同——`CL_ARGB` 在别的设备上可能是支持的。所以 5.6.2 那段代码不是"打印信息"，而是**每个程序启动时都该跑一遍的前置检查**。

## 5.7 事件 Event

_event_ 干两件**互相独立**的事，混为一谈是大部分同步 bug 的来源：

| 用途 | 机制 | 谁受益 |
|---|---|---|
| **主机同步** | `clWaitForEvents` / `clFinish` | 主机代码知道何时能碰自己的内存 |
| **设备侧依赖** | `clEnqueue*` 的 `wait_list` 参数 | 乱序队列上的命令排序 |
| **性能分析** | `clGetEventProfilingInfo` | 测量 |

### 5.7.1 四个时间戳

```c
cl_ulong t0 = 0, t1 = 0, t2 = 0, t3 = 0;
clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_QUEUED, sizeof(t0), &t0, NULL);
clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_SUBMIT, sizeof(t1), &t1, NULL);
clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_START,  sizeof(t2), &t2, NULL);
clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_END,    sizeof(t3), &t3, NULL);
```

| 时间戳 | 含义 |
|---|---|
| `QUEUED` | 命令进入队列 |
| `SUBMIT` | 命令提交给设备 |
| `START` | 设备开始执行 |
| `END` | 设备执行完毕 |

三条使用纪律：

1. **单位是纳秒，但纪元未定义。** 不同设备、不同运行的绝对值不可比。**只有差值有意义。**
2. **队列必须带 `CL_QUEUE_PROFILING_ENABLE`**，否则返回 `-7 CL_PROFILING_INFO_NOT_AVAILABLE`（见 5.4.3）。
3. **`SUBMIT → START` 的差是启动延迟，不是执行时间。** 本机 `examples/02-vector-add` 实测：三次运行里 `execute`（`START→END`）稳定在 4166–4499 ns，而 `submit→start` 在 1.21–2.14 ms 之间波动。也就是说，**小数据量的 OpenCL 程序，开销几乎全在启动**，看总时间会得出完全错误的优化方向。详见 [03 篇 §3.5](./03-first-program.md)。

### 5.7.2 等待最后一个事件就够了

事件构成一张 DAG，等待**汇点**会传递性地等到所有前驱：

```c
    // Waiting on the LAST event is enough: it transitively waits on everything the
    // graph depends on. That is the whole point of building the graph.
    err = clWaitForEvents(1, &evRead);
```

（`examples/07-async-events/main.c:256-258`。）

`examples/07` 的 case C/D 跑的就是这张菱形图：

```text
   evWriteA --> scale_kernel  (C = A*2)     --\
                                               +--> evFan --> add_kernel (E = C+D) --> evRead
   evWriteB --> offset_kernel (D = B+1000)  --/
```

### 5.7.3 marker 的时间戳不是屏障时刻

`clEnqueueMarkerWithWaitList`（OpenCL 1.2 入口）把多个分支汇成一个节点。它**不入队任何设备工作**，纯粹是图上的一个 join。

后果是：**它自己的 `START`/`END` 不代表"所有前驱已完成的那一刻"**。`examples/07` 实测到了这一点，并把结论写进头注释：

> this driver was observed stamping the marker's END after the kernel waiting on it had already STARTED, while both real data producers had correctly finished first.

一次运行里 marker 的 `END` 比等待它的 add 内核的 `START` 晚了约 **7 µs**。所以该示例的断言策略是：

```c
        // A marker is a join node with no data of its own, so the edges that a
        // correctness argument actually rests on are the producers of the buffers the
        // combine kernel reads: scale writes C, offset writes D, add reads both.
        printf("      -- data edges (who produced what add consumed) --\n");
        checkEdge("scale -> add (C)",  evScale,  evAdd, &out->dataChecked, &out->dataOk, verboseEdges);
        checkEdge("offset -> add (D)", evOffset, evAdd, &out->dataChecked, &out->dataOk, verboseEdges);
```

**在携带数据的边上断言，不要在 join 节点上断言。** marker 那条边只报告、不判定（`out->markerLagged`）。

### 5.7.4 错误码不要用按位或聚合

原教程风格的代码里常见：

```c
err |= clEnqueueWriteBuffer(...);    // 错
err |= clEnqueueNDRangeKernel(...);  // 错
```

`cl_int` 错误码是**负整数**，不是位标志。`-30 | -54` 得到的值不对应任何错误码，之后打印出来的名字是虚构的。

`examples/07-async-events/main.c:69-74` 用的是"保留第一个真错误"：

```c
// Accumulate the FIRST real error. Bitwise-ORing cl_int codes together is a common
// shortcut and it is wrong: the result names no error at all, so the message you
// print afterwards is fiction.
static cl_int keepFirst(cl_int acc, cl_int e) {
    return (acc != CL_SUCCESS) ? acc : e;
}
```

保留**第一个**而不是最后一个，因为后续错误往往是第一个错误的连带后果。

### 5.7.5 释放

每个由 `clEnqueue*` 产出的事件都必须 `clReleaseEvent`，否则长跑程序会稳定泄漏。`examples/07` 用一个宏统一处理，参数个数由 `sizeof` 算出，不会和列表脱节：

```c
#define RELEASE_EVENTS(...)                                                  \
    do {                                                                     \
        cl_event* evs_[] = { __VA_ARGS__ };                                  \
        for (size_t i_ = 0; i_ < sizeof(evs_) / sizeof(evs_[0]); i_++)        \
            if (*evs_[i_]) { clReleaseEvent(*evs_[i_]); *evs_[i_] = NULL; }   \
    } while (0)
```

注意它接受的是**地址**（`&evWriteA`），释放后置 `NULL`，所以在错误分支里重复调用也安全。

## 5.8 释放顺序

一个能直接抄的模板，取自 `examples/07-async-events/main.c:539-547`：

```c
    free(hostA); free(hostB); free(hostOut); free(refC); free(refE);
    clReleaseMemObject(d.A); clReleaseMemObject(d.B); clReleaseMemObject(d.C);
    clReleaseMemObject(d.D); clReleaseMemObject(d.E);
    clReleaseKernel(d.scale); clReleaseKernel(d.offset); clReleaseKernel(d.add);
    clReleaseProgram(program);
    free(source);
    if (qOOO) clReleaseCommandQueue(qOOO);
    clReleaseCommandQueue(qInOrder);
    clReleaseContext(context);
```

顺序是**子先于父**：内存对象和内核 → 程序 → 队列 → 上下文。

严格说，因为一切都是引用计数，**任何顺序都不会出错**——`clReleaseContext` 在还有 buffer 引用它时只是减计数。但按依赖倒序释放有两个实际好处：

1. 出错时能立刻定位是哪一层没释放干净。
2. 用调试器或 Valgrind 类工具检查时，泄漏报告是可读的。

还有一条容易忘的：**主机内存要单独 `free`**。`CL_MEM_COPY_HOST_PTR` 是**拷贝**，驱动不接管你的指针，`clReleaseMemObject` 不会替你 `free(hostA)`。反过来，`CL_MEM_ALLOC_HOST_PTR` 分配的内存必须用 `clEnqueueUnmapMemObject` 归还，也不能 `free`。

## 5.9 本篇要点

1. **`cl_platform_id` 和 `cl_device_id` 不是资源**，不创建也不释放。
2. **平台顺序不是契约。** 本机 `platforms[0]` 是 NVIDIA；`clGetPlatformIDs(1, &platform, NULL)` 这种写法会静默选错厂商。按设备名遍历所有平台。
3. **`CL_DEVICE_CONSTANT_BUFFER_SIZE` 这个宏不存在**，正确名字是 `CL_DEVICE_MAX_CONSTANT_BUFFER_SIZE`（`cl.h:340`）。原教程那一行编译不过。
4. **常量内存的容量高度依赖设备**：NVIDIA 64 KiB，Intel 核显 3244.2 MiB（等于 `max_mem_alloc_size`，因为核显没有专用常量内存），Intel CPU 128 KiB。
5. **`clCreateCommandQueue` 是"弃用于 2.0"，不是"移除于 3.0"。** 头文件里声明还在，带 `__declspec(deprecated)`，本机 `CL_TARGET_OPENCL_VERSION=120` 和 `=300` 都编译通过（exit 0）。
6. **要读 profiling 时间戳，建队列时就必须带 `CL_QUEUE_PROFILING_ENABLE`**，否则 `-7`。原教程建队列不开、第 7 节又去读，两段拼起来跑不通。
7. **子缓冲区的权限必须是父缓冲区的子集。** 本机 3×3 实测：父 `READ_ONLY` + 子 `READ_WRITE` → `-30`。且 `region.origin` 要对齐到 `CL_DEVICE_MEM_BASE_ADDR_ALIGN / 8`（Intel 128 B，NVIDIA 512 B，单位是**位**）。
8. **图像格式只能问驱动。** 本机 UHD 630 支持 60 种 2D 读格式，**`CL_ARGB` 不在其中**——而原教程把它列为常用格式。六个匿名通道顺序分别是 Intel 的五个 YUV 视频格式和 `CL_DEPTH_STENCIL`（后者定义在 `cl_gl.h`，只 include `cl.h` 拿不到名字）。
9. **`cl_image_desc` 用 `memset` + 具名赋值**，不要用位置聚合初始化——原教程那行给 10 个字段的结构体填了 9 个值，靠隐式补零碰对了。
10. **事件有两个独立职责**：主机同步和设备侧依赖。顺序队列上后者是免费的，乱序队列上漏掉 wait-list **不报错，只产生竞争**——本机实测 20 次里约一半发生了重叠，而结果全对。
11. **在携带数据的边上断言，不要在 marker 上断言。** marker 不入队设备工作，它的 `END` 可以晚于等它的内核的 `START`（本机实测约 7 µs）。
12. **`cl_int` 错误码不要按位或**，用"保留第一个"的聚合方式。
13. **释放顺序子先于父**；`CL_MEM_COPY_HOST_PTR` 是拷贝，主机内存要自己 `free`。

---

上一篇：[04-programming-model.md](./04-programming-model.md) ｜ 下一篇：[06-kernel-programming.md](./06-kernel-programming.md) —— 内核语言基础、向量类型、内建函数、四个内存空间，以及本机 `max_work_group_size = 256` / `local_mem = 64 KiB` 这两个数字如何决定分块尺寸的上限。
