# 1. OpenCL 总览：它是什么，本机到底支持到哪

学 OpenCL 最容易踩的第一个坑，不是 API 写错，而是**把"我的驱动支持 OpenCL 3.0"当成"我可以写 OpenCL 3.0 的代码"**。这两件事在 2020 年以前差不多，在 3.0 之后彻底分家了。这一篇先把版本这件事讲清楚，然后直接给出本机三个平台的实测结果——后面所有章节的能力边界都从这张表推出来。

> **验证方式说明**：本篇所有设备能力数据都来自仓库里的 `tools/clinfo-probe/`，在该目录跑 `.\build.ps1` 会编译并运行探针，输出与本文 1.5 节的表格逐行一致。版本归属（哪个 API 属于哪个 OpenCL 版本）不是从文档抄的，而是从 `D:\cuda\13.3\include\CL\cl.h` 里的 `#ifdef CL_VERSION_x_x` 与 `CL_API_SUFFIX__VERSION_x_x` 直接核对的，属于**主机编译级**证据。"OpenCL ES 不存在"这条由 `CL_PLATFORM_PROFILE` 实测输出证明，属于**设备元数据级**。

## 1.1 OpenCL 是什么

OpenCL（Open Computing Language）是一套为**异构设备**编写并行程序的开放标准，由 Khronos Group 维护。它让同一份代码可以跑在 CPU、GPU、FPGA、DSP 上，而不必为每家厂商学一套私有 API。

它由两半组成，这两半要分开记：

| 部分 | 是什么 | 用什么编译 |
|------|--------|-----------|
| **主机 API** | 一组 C 函数（`clCreateContext`、`clEnqueueNDRangeKernel`……），负责发现设备、分配内存、下发任务 | 你本机的 C/C++ 编译器（这里是 MSVC） |
| **设备内核语言（OpenCL C）** | 一种 C99 方言，加上地址空间限定符和向量类型，描述"一个工作项要做什么" | 驱动里的**运行时**编译器，或离线的 clang → SPIR-V |

三个特点值得展开：

- **跨平台，但"跨平台"指的是跨厂商，不是跨版本。** 同一个 API 在 NVIDIA、Intel、AMD 上都能调，但内核语言能写到哪一级，取决于设备广告的版本，而不是你的驱动版本。见 1.4。
- **数据并行是它的母语。** OpenCL 的基本假设是"同一份代码，成千上万份数据，各自算各自的"。这个假设体现在它的执行模型里（见 [04-programming-model.md](./04-programming-model.md)），也解释了为什么归约这种需要工作项互相通信的算法在 OpenCL 里要格外小心（见 [05-core-concepts.md](./05-core-concepts.md) 与 `examples/05-reduce-sum/`）。
- **它是显式的。** 没有自动的内存搬运、没有隐式的同步、没有帮你选设备。每一件都要写出来。这既是它的缺点，也是它能把 GPU 榨干的原因——[05 篇 §5.7](./05-core-concepts.md) 与 `examples/07-async-events/` 整节都在讲"显式同步"这一件事。

## 1.2 一次 OpenCL 程序运行的形状

先给一个粗略的骨架，细节在 [03-first-program.md](./03-first-program.md) 里逐行走一遍：

```text
主机侧（你的 C/C++ 程序）              设备侧（GPU / CPU）
─────────────────────────              ─────────────────
1. 找平台、找设备
2. 建 context
3. 建 command queue
4. 把内核源码编译成 program    ──────►  运行时编译器编译 .cl
5. 从 program 里取出 kernel
6. 建 buffer，把数据拷进去     ──────►  设备显存 / 共享内存
7. 设内核参数
8. 下发 NDRange                ──────►  N 个工作项并行执行
9. 等事件完成
10. 把结果拷回来               ◄──────
```

第 4 步和第 8 步是两个最容易出问题、而且**出错时都不报编译错误**的地方：第 4 步的运行时编译失败只体现在 `clBuildProgram` 的返回值和构建日志里，第 8 步的工作组尺寸超限只体现在一个 `-54` 里。本教程专门有两个探针工具对着这两步：`tools/cl-build-probe/` 打第 4 步，`examples/04-matmul-tiled/` 打第 8 步。

## 1.3 版本历史：1.0 → 3.0

| 时间 | 版本 | 关键变化 |
|------|------|---------|
| 2008-12 | **1.0** | 初始版本：CPU/GPU 并行、Buffer 与 Image、单命令队列 |
| 2010-06 | **1.1** | 事件回调、用户事件、3D 图像 |
| 2011-11 | **1.2** | **本教程的基准线。** 设备分区、子缓冲区、程序构建缓存、1D/2D 图像数组、DX9/DX11 互操作 |
| 2013-11 | **2.0** | 共享虚拟内存（SVM）、设备端队列、动态并行、管道对象、C11 风格原子 |
| 2015-11 | **2.1** | **SPIR-V 中间语言**、子组（subgroup）、任意尺寸工作组、设备端图像写入 |
| 2017-05 | **2.2** | **OpenCL C++ 内核语言**（C++14 子集）、SPIR-V 1.2、`atomic_flag` |
| 2020-09 | **3.0** | **模块化：2.x 的一切特性全部变成可选**，通过扩展暴露；OpenCL C 3.0 与 C17 对齐 |

```text
OpenCL 1.0 (2008)
      |
      v
OpenCL 1.1 (2010)
      |
      v
OpenCL 1.2 (2011)   ◄── 本机两块 GPU 停在这里
      |
      v
OpenCL 2.0 (2013)   ──► SVM、设备端队列、pipe
      |
      v
OpenCL 2.1 (2015)   ──► SPIR-V、子组
      |
      v
OpenCL 2.2 (2017)   ──► OpenCL C++ 内核语言
      |
      v
OpenCL 3.0 (2020)   ──► 把上面三行全部改成"可选"
```

3.0 的这次转向是理解整张表的钥匙。2.x 时代，一个设备说"我支持 OpenCL 2.0"就意味着 SVM、设备端队列、pipe 都在。3.0 之后，一个设备说"我支持 OpenCL 3.0"只意味着**它支持 1.2 的全部功能**，其余一概要单独查扩展。所以 3.0 不是一个更高的天花板，而是一次"把承诺收回、改成按需申请"的重构。

### 1.3.1 几个必须纠正的版本归属

原始资料里有几处 API 的版本归属是错的。下面每一行都对照 `cl.h` 核过：

| API | 常见误传 | 实际归属 | `cl.h` 里的证据 |
|-----|---------|---------|----------------|
| `clCreateProgramWithIL` | 2.2 | **2.1** | `#ifdef CL_VERSION_2_1` + `CL_API_SUFFIX__VERSION_2_1` |
| `clEnqueueMarkerWithWaitList` | 2.0 | **1.2** | `#ifdef CL_VERSION_1_2` + `CL_API_SUFFIX__VERSION_1_2` |
| `clCreateCommandQueueWithProperties` | — | **2.0** | `#ifdef CL_VERSION_2_0` |
| `clCreateCommandQueue` | "3.0 移除了" | **3.0 里是弃用，不是移除** | 头文件中仍存在，只是被标注为 deprecated |
| `clCreateFromGLTexture2D` / `3D` | 仍可用 | **已弃用**，改用 1.2 的 `clCreateFromGLTexture` | `cl_gl.h` 中标注 `CL_API_SUFFIX__VERSION_1_1_DEPRECATED` |

`clEnqueueMarkerWithWaitList` 那条尤其要紧：它属于 1.2，意味着**本机两块 GPU 都能用它**。`examples/07-async-events/` 正是用它做扇入汇聚点，在 Intel UHD 630 上跑通了。如果按"这是 2.0 API"的误传去写代码，你会以为核显上用不了，白白绕远路。

`clCreateCommandQueue` 与 `clCreateCommandQueueWithProperties` 这对要分清楚：前者是 1.0 的、在 3.0 中被**弃用但仍然可用**；后者是 2.0 的替代品。本机 `cl.h` 里两个都在，所以两个都能编——但工程必须把 `CL_TARGET_OPENCL_VERSION` 设到 200 以上，后者才会被暴露出来。详见 [02-environment-setup.md](./02-environment-setup.md) 的 2.6 节。

### 1.3.2 不存在 "OpenCL ES"

一些资料会把"移动/嵌入式场景"写成 `OpenCL ES`，与 OpenGL ES 类比。**这个产品不存在。** OpenCL 从来没有出过 ES 分支；嵌入式与桌面的区别是**profile**，一个从 `CL_PLATFORM_PROFILE` 查出来的字符串，取值只有两种：

```text
FULL_PROFILE        完整功能集
EMBEDDED_PROFILE    不要求支持图像（image）对象
```

本机探针实测，三个平台全部是 `FULL_PROFILE`：

```text
=== Platform 0: NVIDIA CUDA ===
    CL_PLATFORM_PROFILE                FULL_PROFILE
=== Platform 1: Intel(R) OpenCL HD Graphics ===
    CL_PLATFORM_PROFILE                FULL_PROFILE
=== Platform 2: Intel(R) OpenCL ===
    CL_PLATFORM_PROFILE                FULL_PROFILE
```

顺带一提，3.0 的头文件里已经没有表示这两个取值的数字常量了，只剩 `CL_PLATFORM_PROFILE`（0x0900）这个查询项本身——它返回的是字符串。

## 1.4 三个版本字符串，问的根本不是同一件事

这是本篇最重要的一节。原始资料的示例代码里有一段"如何检查 OpenCL 版本"，它查的是 `CL_PLATFORM_VERSION`，然后宣称这就是设备的 OpenCL 版本。这个写法在本机会得出彻底错误的结论。

`clGetPlatformInfo` / `clGetDeviceInfo` 一共给你三个长得像版本号的字符串，语义完全不同：

| 查询项 | 问的是什么 | 本机 Platform 1 的答案 |
|--------|-----------|----------------------|
| `CL_PLATFORM_VERSION` | **这个平台实现**符合哪一版 OpenCL 规范 | `OpenCL 3.0` |
| `CL_DEVICE_VERSION` | **这个设备**符合哪一版 OpenCL **API** 规范 | `OpenCL 3.0 NEO` |
| `CL_DEVICE_OPENCL_C_VERSION` | **这个设备的内核编译器**默认接受哪一版 OpenCL **C 语言** | `OpenCL C 1.2` |

前两个说的是主机 API，第三个说的是内核语言。写内核时能用什么特性，只由**第三个**决定。

所以本机的真实情况是：

```text
CL_DEVICE_VERSION          = "OpenCL 3.0 NEO"     ← 主机侧可以用 3.0 的 API
CL_DEVICE_OPENCL_C_VERSION = "OpenCL C 1.2"       ← 内核侧默认只到 1.2
```

一个说 3.0、一个说 1.2，两个都是真的。这就是 1.3 节讲的模块化转向在真实设备上的样子：Intel 的 NEO 驱动把**主机 API** 升到了 3.0，但没有把**内核语言**升上去。

### 1.4.1 正确的版本探测写法

原始资料的探测代码还有第二个问题：它写死了 `platforms[0]`。**在本机 `platforms[0]` 是 NVIDIA，不是 Intel。** 平台枚举顺序由 ICD 加载顺序决定，没有任何稳定性保证——改一次驱动安装顺序就可能变。所有示例代码都盲取第一个平台，等于整个教程实际跑在 RTX 2060 上，而它连 SPIR-V 都不支持（见 1.5）。

正确写法是**遍历所有平台、按设备名匹配**，然后查设备级的三个版本字符串：

```c
// 遍历所有平台，按 CL_DEVICE_NAME 的子串匹配挑设备。
// 绝不使用 platforms[0] 或 devices[0]：枚举顺序不由你决定。
static int ocl_pick_device(const char* nameHint, cl_device_type type,
                           cl_device_id* outDev, char* outName, size_t outNameSz) {
    cl_uint numPlat = 0;
    if (clGetPlatformIDs(0, NULL, &numPlat) != CL_SUCCESS || numPlat == 0) return -1;

    cl_platform_id* plats = (cl_platform_id*)malloc(numPlat * sizeof(cl_platform_id));
    if (!plats) return -1;
    clGetPlatformIDs(numPlat, plats, NULL);

    int found = 0;
    for (cl_uint p = 0; p < numPlat && !found; p++) {
        cl_uint numDev = 0;
        if (clGetDeviceIDs(plats[p], type, 0, NULL, &numDev) != CL_SUCCESS || numDev == 0) continue;

        cl_device_id* devs = (cl_device_id*)malloc(numDev * sizeof(cl_device_id));
        if (!devs) continue;
        clGetDeviceIDs(plats[p], type, numDev, devs, NULL);

        for (cl_uint i = 0; i < numDev; i++) {
            char dname[256] = {0};
            clGetDeviceInfo(devs[i], CL_DEVICE_NAME, sizeof(dname), dname, NULL);
            if (!nameHint || !*nameHint || strstr(dname, nameHint)) {
                *outDev = devs[i];
                if (outName && outNameSz > 0) {
                    strncpy(outName, dname, outNameSz - 1);
                    outName[outNameSz - 1] = '\0';
                }
                found = 1;
                break;
            }
        }
        free(devs);
    }
    free(plats);
    return found ? 0 : -1;
}
```

这段代码是 `examples/common/ocl_util.h` 里的原文，十一个示例共用同一份。找不到目标设备时**必须直接失败退出**，绝不能悄悄退回到"随便挑一个"——一个跑错设备的示例什么也证明不了，而且看起来完全正常。

`examples/01-device-query/` 会把它跑一遍并打印出下面这张表；在 `OpenCL/` 目录执行 `.\build.ps1 -Examples 01-device-query` 就能复现。

### 1.4.2 一个查询类型的坑：`size_t` 不是 `cl_uint`

顺手记下另一个探测代码里的常见错误，因为它产出的假数据极具误导性：

```c
cl_uint maxWG = 0;                                                    // 错
clGetDeviceInfo(dev, CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(maxWG), &maxWG, NULL);
printf("max work group size: %u\n", maxWG);                           // 打印出 0
```

`CL_DEVICE_MAX_WORK_GROUP_SIZE` 返回的是 `size_t`（本机 64 位 = 8 字节）。你传了 4 字节的缓冲区，驱动用 `CL_INVALID_VALUE` 拒绝这次查询，**而变量保持它的初值 0**。如果你不检查返回值——绝大多数示例代码都不检查——就会打印出一个自信而彻底虚构的"最大工作组尺寸：0"，然后据此以为设备有毛病。

正确写法：

```c
size_t maxWG = 0;                                                     // 对
clGetDeviceInfo(dev, CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(maxWG), &maxWG, NULL);
printf("max work group size: %zu\n", maxWG);
```

同理，`CL_DEVICE_IL_VERSION` 返回的是**字符串**，不能查进 `cl_bool`。想知道设备支不支持 SPIR-V，要查字符串长度是否非零——本机 NVIDIA 设备这一项是**空字符串**，见 1.5。

## 1.5 本机实测基线

下面这张表是本教程一切结论的出发点，由 `tools/clinfo-probe/clinfo-probe.exe` 实测产出（2026-09-17）。运行级验证结果（全量示例判定、SPIR-V 路由、性能读数）与多机台账见 [VERIFICATION.md](../VERIFICATION.md)。

| | Platform 0 | Platform 1 | Platform 2 |
|---|---|---|---|
| **平台名** | NVIDIA CUDA | Intel(R) OpenCL HD Graphics | Intel(R) OpenCL |
| **平台版本** | OpenCL 3.0 CUDA 13.3.80 | OpenCL 3.0 | OpenCL 3.0 WINDOWS |
| **Profile** | FULL_PROFILE | FULL_PROFILE | FULL_PROFILE |
| **设备** | GeForce RTX 2060 | **Intel UHD Graphics 630** | Intel Core i7-9700 CPU |
| **类型** | GPU | GPU（**本教程主目标**） | CPU |
| `CL_DEVICE_VERSION` | OpenCL 3.0 CUDA | OpenCL 3.0 NEO | OpenCL 3.0 (Build 0) |
| `CL_DEVICE_OPENCL_C_VERSION` | **OpenCL C 1.2** | **OpenCL C 1.2** | **OpenCL C 3.0** |
| `CL_DRIVER_VERSION` | 610.88 | 31.0.101.2140 | 2026.20.1.0.12_160000 |
| 计算单元 | 30 | 24 | 8 |
| **max_work_group_size** | 1024 | **256** | 8192 |
| max_work_item_sizes | 1024×1024×64 | 256×256×256 | 8192×8192×8192 |
| global_mem_size | 6143.7 MiB | 6488.4 MiB | 16221.1 MiB |
| **local_mem_size** | 49152（48 KiB） | **65536（64 KiB）** | 262144（256 KiB） |
| max_mem_alloc_size | 1535.9 MiB | 3244.2 MiB | 8110.5 MiB |
| image_support | CL_TRUE | CL_TRUE | CL_TRUE |
| **local_mem_type** | CL_LOCAL | CL_LOCAL | **CL_GLOBAL** |
| svm_capabilities | 0x1（仅 coarse） | **0xB**（coarse + fine-buffer + atomics） | 0xF（全部） |
| **il_version** | **（空）** | SPIR-V_1.2 | SPIR-V_1.0 ~ 1.4 |
| 扩展总数 | 26 | **63** | 45 |
| 子组扩展 | **无** | cl_khr_subgroups + cl_intel_subgroups | 仅 cl_intel_subgroups |

从这张表能直接读出五条决定教程形态的事实：

1. **`platforms[0]` 是 NVIDIA。** 任何盲取第一个平台的代码，在本机都跑在 RTX 2060 上。
2. **两块 GPU 都只到 OpenCL C 1.2**，尽管它们的 `CL_DEVICE_VERSION` 都写着 3.0。1.4 节讲的那个区分，在这里落地成了一条硬约束。
3. **只有 Intel iGPU 有 IL 支持**（`SPIR-V_1.2`）。NVIDIA 的 `il_version` 是空字符串，意味着 `clCreateProgramWithIL` 在它上面根本没法用——SPIR-V 那一章（[08-spirv.md](./08-spirv.md)）只能跑在 Intel 设备上。
4. **iGPU 的 max_work_group_size 是 256，不是 1024。** 这一条直接判了"32×32 分块矩阵乘法"死刑：32×32 = 1024 个工作项，超限，运行时返回 `-54 CL_INVALID_WORK_GROUP_SIZE`。`examples/04-matmul-tiled/` 会把这个失败**当成预期结果演示出来**。
5. **Intel CPU 设备的 `local_mem_type` 是 `CL_GLOBAL`** ——它的 `__local` 内存是由全局内存充当的。所以在 CPU 设备上做本地内存分块**买不到任何东西**，别拿它去跑分块加速比的基准测试。本地内存分块是一堂 iGPU 的课。

第 5 条里 CPU 的 256 KiB 本地内存看着比 GPU 的 64 KiB 大，但因为 `CL_GLOBAL`，那是同一个池子的另一种说法，不是真的片上存储。

## 1.6 能力矩阵：本机哪些特性真的能验证

有了基线表，就能把"OpenCL 有哪些特性"翻译成"这台机器上哪些特性我说了算"。下面每一行都标了它是被哪条通道证明的：

| 特性 | 最低版本要求 | RTX 2060 | **Intel UHD 630** | i7-9700 CPU | 证据通道 |
|------|------------|----------|-------------------|-------------|---------|
| OpenCL C 1.2 内核 | 1.2 | ✅ | ✅ | ✅ | 内核编译级 + 运行时数值级 |
| Buffer / 事件 / Profiling | 1.0–1.2 | ✅ | ✅ | ✅ | 运行时数值级 |
| Image2D + Sampler | 1.2 | ✅ | ✅ | ✅ | 运行时数值级（`examples/06`） |
| `clEnqueueMarkerWithWaitList` | **1.2** | ✅ | ✅ | ✅ | 运行时数值级（`examples/07`） |
| SPIR-V + `clCreateProgramWithIL` | 2.1 | ❌ **无 IL** | ✅ SPIR-V_1.2 | ✅ SPIR-V 1.0–1.4 | 离线工具链级 + 运行时数值级 |
| SVM（`clSVMAlloc`） | 2.0 | ❌ 构建即失败 | ✅（需 `-cl-std=CL2.0`） | ✅ | 运行时数值级 |
| `to_global()` 泛型地址 | 2.0 | ⚠️ 能编译 | ✅（需 `-cl-std=CL2.0`） | ✅ | 运行时数值级 |
| `sub_group_broadcast` | 2.1 | ❌ ptxas 报未解析外部函数 | ✅ sg=16（需 `-cl-std=CL2.0`） | ✅ sg=8 | 运行时数值级 |
| 设备端队列 / 动态并行 | 2.0 | ❌ | ❌ | ❌ | **本机无任何设备支持** |
| Pipe 对象 | 2.0 | ❌ | ❌ | ❌ | **本机无任何设备支持** |
| OpenCL C++ 内核语言 | 2.2 | ❌ | ❌ | ❌ | 需 OpenCL C 2.2+，本机无 |

后三行是**诚实边界**：设备端队列、pipe、OpenCL C++ 内核语言在本机没有任何设备支持，因此本教程**不提供**它们的可运行代码，只在 [09-practical-examples.md](./09-practical-examples.md) 里做文字说明。硬写一个跑不了的示例，比不写更糟。

### 1.6.1 `CL_DEVICE_OPENCL_C_VERSION` 既不是默认等级，也不是可靠上限

上面那张表里有三行标着"需 `-cl-std=CL2.0`"，这个细节值得单独说，因为它是本次验证过程中**推翻过的一个结论**。

一开始的实测是这样的：把 `to_global()` 编到 Intel UHD 630 上，得到

```text
error: implicit declaration of function 'to_global' is invalid in OpenCL
```

据此很容易下结论"核显是 OpenCL C 1.2，2.x 的内建函数用不了"。**这个结论是错的。**

但**修正它的理由不是"`CL_DEVICE_OPENCL_C_VERSION` 报的是默认级别"**——这一条在本教程写作过程中也被推翻了，详见 [06 篇 §6.2.2](./06-kernel-programming.md)。那里用"只在宏等于命令行传入的值时才编译通过"的 fixture 扫出了真值：

| 设备 | `CL_DEVICE_OPENCL_C_VERSION` | 不带 `-cl-std` 时的 `__OPENCL_C_VERSION__` |
|---|---|---|
| Intel UHD 630 | OpenCL C 1.2 | **120** |
| Intel i7-9700 CPU | OpenCL C 3.0 | **120** |
| NVIDIA RTX 2060 | OpenCL C 1.2 | **300** |

两点结论：**默认语言等级由厂商决定**（i7 CPU 广告 "OpenCL C 3.0" 却默认按 1.2 编译，RTX 2060 广告 "OpenCL C 1.2" 却默认按 3.0 编译），而 `CL_DEVICE_OPENCL_C_VERSION` 这个字符串**两个方向都不对应**。

回到本节的现象：显式传 `-cl-std=CL2.0` 再编同一份源码——

| 特性 | i7-9700 CPU（C 3.0） | **Intel UHD 630（C 1.2）** | RTX 2060（C 1.2） |
|------|---------------------|---------------------------|-------------------|
| SVM `clSVMAlloc` + 内核写入 | PASS | **PASS** | 未到达（构建即失败） |
| `to_global()` | PASS | **PASS** | 能编译 |
| `sub_group_broadcast` | PASS，sg=8 | **PASS，sg=16** | **FAIL** |

三个特性在两块 Intel 设备上都是**既编译通过、又运行正确**（256/256 个值全对）。设备能做，你得开口要。

RTX 2060 的失败方式还不一样，它是 `ptxas` 阶段的：

```text
ptxas fatal: Unresolved extern function 'get_sub_group_local_id'
```

注意它**接受了** `to_global` 却**拒绝了** `sub_group_broadcast`——因为子组支持是一个**能力**问题，不是版本问题。NVIDIA 的扩展列表里既没有 `cl_khr_subgroups` 也没有 `cl_intel_subgroups`，而两块 Intel 设备都有。**版本字符串预测不了这件事，任何方向的版本字符串都不能。**

运行时该查什么，取决于特性属于哪一类：

| 特性类别 | 该查 | 例子 |
|---|---|---|
| 扩展 | `CL_DEVICE_EXTENSIONS` | `cl_khr_subgroups`、`cl_intel_subgroups` |
| OpenCL C 可选特性（3.0 起） | `CL_DEVICE_OPENCL_C_FEATURES` | `__opencl_c_subgroups`、`__opencl_c_generic_address_space` |
| 语言版本 | `CL_DEVICE_OPENCL_C_ALL_VERSIONS` | 本机两块 GPU 的列表里**没有 2.0** |

OpenCL 3.0 把原来的"OpenCL C 2.0"整体等级拆成了一组**逐项宣称的可选特性**，所以子组这类能力现在正确的门控是 `__opencl_c_subgroups`，而不是扩展名、更不是版本号。三者的实测对比见 [06 篇 §6.2.2](./06-kernel-programming.md)。

这条经验的可迁移部分是：

> 不要因为一次构建失败就断言"这个设备做不到 X"。先确认当时生效的 `-cl-std` 是哪一级。

但它仍然**不可移植**——而且本机测到的偏差是**两个方向都有**的：两块 Intel 设备广告 "OpenCL C 1.2"，开口要 `-cl-std=CL2.0` 就真给；RTX 2060 只宣称 4 项可选特性（不含子组），却把默认等级设成 3.0，于是**接受了一个自己并未宣称支持的特性**。所以本教程的默认策略是：**内核按 OpenCL C 1.2 写**，确实需要 2.x 特性时才显式加 `-cl-std=CL2.0`，运行时判断按上面那张表选对应的查询（可选特性查 `CL_DEVICE_OPENCL_C_FEATURES`，扩展查 `CL_DEVICE_EXTENSIONS`），**永远不要查版本字符串**。`examples/11-ocl3-features/` 就是这么写的，它跑在 i7-9700 CPU 上。

### 1.6.2 四个只在真机上才会露头的坑

上面那次闸门测试还捞出四个纯粹的陷阱，全都是文档里查不到、只有编译过才知道的：

1. **CUDA 的 `cl.h` 里 SVM 映射函数叫 `clEnqueueSVMMap` / `clEnqueueSVMUnmap`**，不是 OpenCL 2.0 规范里的 `clEnqueueMapSVMBuffer` / `clEnqueueUnmapSVMBuffer`。用规范名字会得到 `LNK2019`（无法解析的外部符号），链接 `OpenCL.lib` 失败。
2. **`generic` 是 OpenCL C 的保留字。** 把一个变量命名为 `generic` 会得到 `error: expected identifier or '('`，而这个报错完全没提示你撞了关键字。
3. **`sub_group_broadcast` 在本机编译器上要求两参数形式** `(value, sub_group_local_id)`；单参数形式报 "no matching function"。
4. **广播 0 号通道的值 0 是一个空测试。** 一个什么都不做的广播也能通过它。要验证广播真的生效，必须同时输出每个通道自己的值和广播结果，然后比对——否则这条断言什么也没证明。

第 4 条是本教程对所有示例的统一要求：**断言必须能失败。** 一个不可能失败的检查不是验证，是装饰。`examples/05-reduce-sum/` 和 `examples/06-image-brightness/` 里都专门保留了会算错的用例，并把"算错"本身当成预期输出。

## 1.7 版本选择建议

| 场景 | 建议 | 理由 |
|------|------|------|
| **要最大兼容性** | 内核按 **OpenCL C 1.2** 写 | 本机三台设备全部支持；也是覆盖面最广的基线 |
| **主机 API** | 工程里定义 `CL_TARGET_OPENCL_VERSION=300` | 不等于内核要写 3.0，只是让头文件**暴露**出全部 API；详见 [02 篇 2.6](./02-environment-setup.md) |
| **确实需要 2.x 内核特性** | 显式传 `-cl-std=CL2.0`，并用 `CL_DEVICE_EXTENSIONS` 门控 | 1.6.1 节：默认级别不是上限，但兑现程度由厂商决定 |
| **嵌入式设备** | 查 `CL_PLATFORM_PROFILE` 是否为 `EMBEDDED_PROFILE` | 不存在 "OpenCL ES"；嵌入式 profile 的唯一实质区别是不要求支持图像 |
| **macOS** | 用 Metal | Apple 已弃用 OpenCL，停留在 1.2 |

注意第二行和第一行不矛盾：**主机 API 版本**和**内核语言版本**是两个独立的旋钮。本工程把它们分别设成 300 和 1.2，这是本机唯一能同时用上 `clCreateProgramWithIL`（2.1 API）和保证内核到处能编的组合。

## 1.8 关键名词速查

| 名词 | 含义 |
|------|------|
| Platform | 一个厂商的 OpenCL 实现（本机有 3 个：NVIDIA、Intel 核显、Intel CPU） |
| Device | 平台下的一个计算设备 |
| Context | 管理设备、内存对象、命令队列的容器 |
| Command Queue | 主机向某个设备下发命令的通道；分**顺序**与**乱序**两种 |
| Program | 编译后的内核程序对象，由源码或 IL 构建而来 |
| Kernel | Program 里一个可执行的入口函数 |
| Buffer | 一维的设备内存对象 |
| Image | 带格式与采样器的二维/三维内存对象 |
| Event | 命令的完成标记，用于同步与 profiling |
| Work-item | 执行内核的最小单位，一个线程 |
| Work-group | 一组 work-item，能用 `__local` 内存和 `barrier` 协作 |
| NDRange | 描述 work-item 总数与分组方式的多维索引空间 |
| Subgroup | work-group 内由硬件调度的更小子集，大小由设备决定（本机 iGPU=16，CPU=8） |
| SVM | Shared Virtual Memory，主机与设备共享同一指针 |
| SPIR-V | 可离线编译的内核中间语言，经 `clCreateProgramWithIL` 加载 |
| ICD | Installable Client Driver，`OpenCL.dll` 加载各厂商驱动的机制 |
| `CL_TARGET_OPENCL_VERSION` | **主机侧**宏，决定头文件暴露到哪一版 API |
| `CL_DEVICE_OPENCL_C_VERSION` | **设备侧**查询项，报告内核编译器的默认语言级别 |

---

下一篇：[02-environment-setup.md](./02-environment-setup.md) —— 装运行时、配 Visual Studio 与 CMake、选对 `CL_TARGET_OPENCL_VERSION`，以及怎么用两个探针工具确认这一切真的能用。
