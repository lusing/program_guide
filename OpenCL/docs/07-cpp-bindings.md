# 7. C++ 绑定：`cl.hpp`、三个宏、与 C API 的逐项对照

[06 篇](./06-kernel-programming.md) 讲的是设备侧。这一篇回到主机侧，讲 `cl.hpp`——Khronos 官方的 C++ 绑定。

先说清楚这一篇**不是什么**：它不是"C++ 比 C 好，所以后面都改用 C++"。绑定是纯主机侧的设施，它不改变内核语言、不改变构建选项、不改变任何一个数值结果。`examples/08-cpp-bindings/kernels/vector_add.cl` 与 `examples/02-vector-add/kernels/vector_add.cl` **逐字节相同**（`diff` 可验）。它改变的是两件事：**错误模型**（错误码 → 异常）和**对象生命周期模型**（手动 `clRelease*` → RAII）。这两件事都值得单独测量，因为文档和网上示例对它们的说法有大量互相矛盾的地方。

这一篇有一条贯穿全篇的实测结论，先摆在这里：

> **绑定是一个头文件，没有自己的库。所以关于它的几乎每一个问题都是"主机编译级"问题——`cl.exe` 退出码是 0 还是非 0，报错在哪一行。** 这跟前面几篇不一样：06 篇的证据来自设备侧编译器，05 篇来自运行时查询，而这一篇的证据绝大部分来自**编译一个只包含头文件的翻译单元**。这就是 `tools/cpp-header-probe/` 存在的原因：17 个变体，同一份源文件，只有宏和包含顺序不同，其中 **7 个必须编译失败**。一个对所有配置都报"通过"的探针对这一篇毫无价值。

> **验证方式说明**：本篇的证据通道以**主机编译级**为主，全部来自 `tools/cpp-header-probe/`（17 个变体，`.\build.ps1` 可重跑，末尾 `[RESULT] PASS`）。涉及引用计数、构建选项字符串、数值正确性的部分属于**运行时数值级**，来自 `examples/08-cpp-bindings/`（Intel UHD Graphics 630，`.\build.ps1 -Examples 08-cpp-bindings`）。凡引用 `cl.hpp` 行号处均指本机 `D:\cuda\13.3\include\CL\cl.hpp`（版权头 2008-2023 The Khronos Group Inc.）。7.9 节的 OpenGL 互操作在本机**不可验证**，明确标注为诚实边界。

## 7.1 头文件到底叫什么

原始资料写：

```cpp
#include <CL/opencl.hpp>  // C++ 封装
// 或者
#include <CL/cl2.hpp>     // 旧版 C++ 封装
```

**这两个文件在本机都不存在。** 这不是"某个 SDK 漏装了"，而是命名沿革造成的普遍混乱。

### 7.1.1 本机实测：只有一个存在

`tools/cpp-header-probe` 的变体 5、6 各编译一个只包含其中一个头文件的翻译单元，结果都是 `C1083`（无法打开包括文件）：

| 变体 | 包含 | 结果 |
|---|---|---|
| 5 | `<CL/cl2.hpp>` | **失败**，`C1083` |
| 6 | `<CL/opencl.hpp>` | **失败**，`C1083` |
| 7 | `<CL/cl.hpp>` | 通过，链接 `OpenCL.lib`，枚举出 3 个平台 |

两个 SDK 的实际内容：

| SDK | `include\CL\` 里的 C++ 绑定 |
|---|---|
| `D:\cuda\13.3` | **只有 `cl.hpp`** |
| `D:\oneAPI\compiler\latest` | **一个都没有**（只有 `sycl.hpp`，那是另一套东西） |

所以本教程的 C++ 部分只能用 CUDA SDK 编译——不是偏好，是唯一可行。这一点 [02 篇 §2.3](./02-environment-setup.md) 已经记过。

### 7.1.2 为什么会有三个名字

`cl.hpp` 自己的文档头把这段历史讲清楚了（`cl.hpp:70-73`）：

> There are numerous compatibility, portability and memory management fixes in the new header as well as additional OpenCL 2.0 features. As a result the header is not directly backward compatible and for this reason **we release it as opencl.hpp rather than a new version of cl.hpp**.

翻译成时间线：

```text
cl.hpp      OpenCL 1.x 时代的 C++ 绑定，宏名是 __CL_*
   |
cl2.hpp     OpenCL 2.0 绑定。因为不向后兼容，Khronos 不肯覆盖旧的 cl.hpp，
   |        于是另起一个文件名
   |
opencl.hpp  又改了一次名，宏名统一成 CL_HPP_*
```

**关键在于：本机这个叫 `cl.hpp` 的文件，内容是 `opencl.hpp`。** 证据是它自称 `opencl.hpp`——全文 13 条 `# pragma message` 里有 **12 条**以 `"opencl.hpp: ..."` 开头（例如 `cl.hpp:404`、`447`、`473`），文档头（`cl.hpp:61`）也写着 "The interface is contained with a single C++ header file *opencl.hpp*"。唯一不带这个前缀的是 `cl.hpp:457`，也就是 7.2.1 会引到的那一条。CUDA SDK 只是沿用了旧文件名装新版内容。

更直接的证据：`cl.hpp:225` 那段官方示例代码写的是

```cpp
#define CL_HPP_ENABLE_EXCEPTIONS
#define CL_HPP_TARGET_OPENCL_VERSION 200

#include <CL/opencl.hpp>
```

**头文件的自带示例教你包含一个这个 SDK 没有装的文件名。** 照着抄必然 `C1083`。

### 7.1.3 实操规则

1. **先看你手上装的是哪个名字**，别照抄任何教程（包括这一篇）。`dir "%SDK%\include\CL\*.hpp"` 一眼就知道。
2. 三个名字对应**两套宏名**：`cl.hpp`（1.x 版）用 `__CL_*`，`cl2.hpp` / `opencl.hpp` 用 `CL_HPP_*`。本机这个是新版内容，用 `CL_HPP_*`。
3. 老宏名 `__CL_ENABLE_EXCEPTIONS` **仍然生效**，见 7.2.3。

## 7.2 三个宏

用 `cl.hpp` 需要三个宏，根 `build.ps1` 的实际写法（`$cppExtra`）：

```powershell
$cppExtra = @(
    '/DCL_HPP_ENABLE_EXCEPTIONS',
    '/DCL_HPP_TARGET_OPENCL_VERSION=300',
    '/DCL_HPP_MINIMUM_OPENCL_VERSION=200'
)
```

| 宏 | 本机取值 | 作用 | 填错的后果 |
|---|---|---|---|
| `CL_HPP_TARGET_OPENCL_VERSION` | `300` | 绑定**声明**哪个版本为止的 API | 与 `CL_TARGET_OPENCL_VERSION` 不一致 → 42 个编译错误 |
| `CL_HPP_MINIMUM_OPENCL_VERSION` | `200` | 绑定要**兼容运行**的最低版本；决定运行时探测分支和弃用包装 | 填 `120` → 12 个错误（门控缝隙） |
| `CL_HPP_ENABLE_EXCEPTIONS` | 定义 | 失败时抛 `cl::Error` 而不是返回错误码 | 不定义则 `cl::Error` 这个类根本不存在 |

三个都不是必须显式写的：`CL_HPP_TARGET_OPENCL_VERSION` 缺省是 `300`（`cl.hpp:436-438`），`CL_HPP_MINIMUM_OPENCL_VERSION` 缺省是 `200`（`cl.hpp:463-465`）。显式写出来只是把这个决定留在明面上。

### 7.2.1 `CL_HPP_TARGET_OPENCL_VERSION` 必须与 `CL_TARGET_OPENCL_VERSION` 一致

`cl.hpp` 用 `CL_HPP_*` 门控自己的声明，`cl.h` 用 `CL_TARGET_OPENCL_VERSION` 门控同一批 token。两者错开时，`cl.hpp` 照常展开 2.x 的声明列表，而 `cl.h` 把那些 token 全藏了。实测（变体 3、4，`CL_TARGET=120` + `CL_HPP_TARGET=300`）：**42 个 `error C` 行，其中 34 个是 `C2065` 未声明的标识符，全部来自 `cl.hpp` 的两行 X-macro 展开（1629 和 1632）**，第一个缺失的是 `CL_DEVICE_QUEUE_ON_HOST_PROPERTIES`：

```text
D:\cuda\13.3\include\CL/cl.hpp(1629): error C2065: “CL_DEVICE_QUEUE_ON_HOST_PROPERTIES”: 未声明的标识符
...
D:\cuda\13.3\include\CL/cl.hpp(1632): fatal error C1003: 错误计数超过 100；正在停止编译
```

完整的错误构成、为什么"34 是下限"、以及 X-macro 一行炸出一批错误的机制，在 [02 篇 §2.6.3](./02-environment-setup.md) 有逐项表格，这里不重复。

值得在这一篇强调的是**`cl.hpp` 不会替你修正这个不一致**。它只打印一句 `#pragma message`（`cl.hpp:452-461`）：

```cpp
#if defined(CL_TARGET_OPENCL_VERSION)
#if CL_TARGET_OPENCL_VERSION < CL_HPP_TARGET_OPENCL_VERSION
# pragma message("CL_TARGET_OPENCL_VERSION is already defined as is lower than CL_HPP_TARGET_OPENCL_VERSION")
#endif
#else
# define CL_TARGET_OPENCL_VERSION CL_HPP_TARGET_OPENCL_VERSION
#endif
```

注意 `#else` 分支：**没定义时它会替你定义成一致的值**。所以最省事的写法不是"把两个宏调成一样"，而是——用 `cl.hpp` 的翻译单元里干脆别定义 `CL_TARGET_OPENCL_VERSION`。

但本教程的 `examples/common/ocl_util.h` 定义了它（`ocl_util.h:23-25`），因为同一份工具头也要服务纯 C 的例子。它带 `#ifndef` 守卫，所以顺序是可控的：`examples/08` 里 `main.cpp` 先 `#define CL_TARGET_OPENCL_VERSION 300`，`ocl_util.h` 的守卫就尊重它，`cl.hpp` 看到的两个值自然一致。**能这么做的前提是那个 `#ifndef`**——[02 篇 §2.6.2](./02-environment-setup.md) 记过一次因为漏掉它而把对照实验整个做废的经历。

### 7.2.2 `CL_HPP_MINIMUM_OPENCL_VERSION` 不能填 120

这是本机这份 `cl.hpp` 上的一处**门控缝隙**，`120` 恰好是唯一编译不过的取值。`detail::getContextPlatformVersion` 定义在 `cl.hpp:2089-2139` 这个块里，门控是 `TARGET >= 120 && MINIMUM < 120`；而它有 8 处调用，分属两组门控：

| 位置 | 门控 | `TARGET=300, MINIMUM=120` |
|---|---|---|
| 定义处 `cl.hpp:2089` | `TARGET >= 120 && MINIMUM < 120` | 假 → 不定义 |
| 2 处 `Image` 构造，门控 `cl.hpp:5003`、5347 | `TARGET >= 120 && MINIMUM < 120` | 假 → 一起消失，无害 |
| 6 处 `CommandQueue` 构造，门控 `cl.hpp:7184`、7250、7315、7382、7433、7484 | `TARGET >= 200 && MINIMUM < 200` | **真 → 要调用** |

`Image` 那两处门控与定义处完全一致，跟着一起被排除。出问题的是 `CommandQueue` 那六处：门控写的是 `< 200` 而不是 `< 120`。`MINIMUM=120` 满足 `< 200`、不满足 `< 120`，正好落在两个条件的差集里——调用六次、定义零次，**12 个错误**（变体 11）：

```text
D:\cuda\13.3\include\CL/cl.hpp(7187): error C2039: “getContextPlatformVersion”: 不是“cl::detail”的成员
D:\cuda\13.3\include\CL/cl.hpp(7187): error C3861: “getContextPlatformVersion”: 找不到标识符
```

对照实验：`MINIMUM=110` 同时满足两个门控，通过（变体 12）；`MINIMUM=200` 两个都不满足，通过（变体 7）；`MINIMUM=300` 也通过（变体 13、15）。**只有 120 落在缝里。**

这个错误特别容易误判成"我代码写错了"或"这个设备不支持"——它报的是官方头文件里的内部符号找不到，跟你的源码一行关系都没有。

> `CL_HPP_MINIMUM_OPENCL_VERSION` 的默认值是 **200**（`cl.hpp:463-465`），所以**不定义它反而是安全的**。显式写 `120` 才是把自己推进缝里。另外 `MINIMUM > TARGET` 是硬 `#error`（`cl.hpp:477-479`，变体 8 实测），这一条至少报错报得很清楚。

> **诚实边界**：`120` 这个缝隙是本机这份 `cl.hpp` 上的实测结果，不是 OpenCL 规范条款。换一份头文件（尤其从 KhronosGroup/opencl-headers 取的新版）可能已修好，也可能仍在。`tools/cpp-header-probe` 存在的意义就是让这条结论可重跑。

### 7.2.3 `__CL_ENABLE_EXCEPTIONS`：老名字仍然生效

网上流传一种说法：用老宏名 `__CL_ENABLE_EXCEPTIONS` 会炸出一堆未定义标识符。**这个归因是错的。** `cl.hpp:403-406` 把它直接映射到新名字，只附一条弃用提示：

```cpp
#if !defined(CL_HPP_ENABLE_EXCEPTIONS) && defined(__CL_ENABLE_EXCEPTIONS)
# pragma message("opencl.hpp: __CL_ENABLE_EXCEPTIONS is deprecated. Define CL_HPP_ENABLE_EXCEPTIONS instead")
# define CL_HPP_ENABLE_EXCEPTIONS
#endif
```

实测三个变体，把宏名和版本宏这两个因素分开：

| 变体 | 异常宏 | `CL_TARGET` | 结果 |
|---|---|---|---|
| 2 | `__CL_ENABLE_EXCEPTIONS`（老名） | 300 | **通过**，只有弃用提示 |
| 3 | `__CL_ENABLE_EXCEPTIONS`（老名） | 120 | 42 个错误 |
| 4 | `CL_HPP_ENABLE_EXCEPTIONS`（新名） | 120 | 42 个错误，**与变体 3 完全相同** |

变体 2 对 3：同一个老宏名，只改 `CL_TARGET_OPENCL_VERSION`，结果翻转。变体 3 对 4：同一个版本组合，只改宏名，错误一模一样。**决定成败的是那对版本宏，不是异常宏的名字。**

仍然建议用新名字（老名字每次编译都打印一条提示），但把它当故障原因会把你引向完全错误的方向——你会去改宏名，改完发现还是炸，然后开始怀疑 SDK 装坏了。

### 7.2.4 关掉异常会失去什么

`CL_HPP_ENABLE_EXCEPTIONS` 不定义时，绑定退化成"返回错误码"风格，而且**`cl::Error` 这个类根本不存在**——它的声明整个在 `cl.hpp:739-785` 的 `#if defined(CL_HPP_ENABLE_EXCEPTIONS)` 块里。

实测这一对变体：

| 变体 | 代码形状 | 结果 |
|---|---|---|
| 9 | 异常关，函数体里写 `catch (const cl::Error& e)` | **失败**，首个错误是 `C2039: “Error”: 不是“cl”的成员`，共 5 个 |
| 10 | 异常关，改成 `cl_int err = cl::Platform::get(&platforms)` | **通过**，链接、运行、枚举出 3 个平台 |

变体 9 特意在 `Forbid` 里排除了 `getContextPlatformVersion`，确保它是**因为 `cl::Error` 不存在而失败**，而不是顺带撞上了 7.2.2 那个缝隙——一个因为错误原因而"通过"的负面用例比没有负面用例更糟。

关掉异常后每个调用都要接返回值：

```cpp
cl_int err = cl::Platform::get(&platforms);
if (err != CL_SUCCESS) { /* ... */ }
```

**这基本抵消了用绑定的主要理由。** 绑定相对 C API 的最大收益就是"不用在每个调用后面跟一个 `if (err != CL_SUCCESS)`"；把异常关掉之后，你写的是同样多的错误检查，只是换了个类型系统。要关就干脆用 C API（前六篇讲的那套），至少错误码的含义是明确的。

> 顺带一个宏细节：`CL_HPP_ERR_STR_(x)` 在异常开启时是 `#x`（`cl.hpp:782`），关闭时是 `nullptr`（`cl.hpp:784`）。所以异常关掉之后连错误字符串都没有了，只有一个裸的 `cl_int`。

## 7.3 那条 `C4996` 是谁的

`examples/08-cpp-bindings` 第一版编译时，除了成功之外还多出一行：

```text
D:\cuda\13.3\include\CL/cl.hpp(6856): warning C4996: 'clSetProgramReleaseCallback': 被声明为已否决
```

这行警告**不在你的代码里**。它指向 `cl.hpp` 内部，报的是一个你从未调用过的函数。第一版的解释是"`CL_HPP_MINIMUM_OPENCL_VERSION=200` 让 `cl.hpp` 编进了 2.2 的弃用包装，包装里调了弃用的 C 函数"——**这个解释是错的**，或者说只对了一半。

### 7.3.1 二乘二实测

变体 7 用的宏组合与上面那句解释完全一致（`MINIMUM=200`、`TARGET=300`、异常开启），却**一个警告都没有**。差别只在包含顺序。于是把两个因素各取两值，凑成四格：

| 变体 | `MINIMUM` | 包含顺序 | `C4996` |
|---|---|---|---|
| 14 | 200 | `<CL/cl.h>` **先**，然后 `<CL/cl.hpp>` | **有** |
| 7 | 200 | 只有 `<CL/cl.hpp>` | 无 |
| 15 | 300 | `<CL/cl.h>` 先，然后 `<CL/cl.hpp>` | 无 |
| 13 | 300 | 只有 `<CL/cl.hpp>` | 无 |

变体 14 的输出与 `examples/08` 第一版**逐字相同**（同一行号 6856、同一个函数名）。四格里只有"两个因素都成立"的那一格报警告，说明**两个原因都是必要的**：

1. **`cl.hpp` 必须编进那个弃用包装。** 这需要两个条件同时成立：外层 `cl.hpp:6839` 要求 `TARGET >= 220`，内层 `cl.hpp:6840` 要求 `CL_USE_DEPRECATED_OPENCL_2_2_APIS` 已被定义，而后者由 `cl.hpp:496-498` 在 `MINIMUM <= 220` 时定义。两者都满足，`cl.hpp:6840-6862` 那个块里的 `setReleaseCallback` 才会被编译，而它内部（`cl.hpp:6856`）调用了 `::clSetProgramReleaseCallback`。本教程的 `TARGET=300` 恒满足外层，所以实际起决定作用的是 `MINIMUM`——`MINIMUM=300` 时整块不编译，变体 13、15 因此安静。
2. **`cl_platform.h` 必须已经把弃用标记冻上。** `cl_platform.h:128` 在**被解析的那一刻**检查 `CL_USE_DEPRECATED_OPENCL_2_2_APIS` 是否已定义，据此决定 `CL_API_PREFIX__VERSION_2_2_DEPRECATED` 带不带 `deprecated`。而 `cl_platform.h` 在 `__CL_PLATFORM_H` 守卫后面（`cl_platform.h:17-18`），**这个决定不会被重访**。

两者一撞就出问题：`<CL/cl.h>` 先被包含 → `cl_platform.h` 此时看不到 `CL_USE_DEPRECATED_OPENCL_2_2_APIS`（`cl.hpp:496` 还没执行到）→ 标记冻成"已弃用"；随后 `cl.hpp` 定义了那个宏、编进包装、包装调用一个已被标记弃用的 C 函数 → `C4996`。

**如果只测了变体 13 就下结论"把 MINIMUM 改成 300 就好了"，包含顺序这个真正的原因就永远不会被发现。** 这是本篇里最值得记住的方法论：一个能通过的变体不能证明你的因果解释，能区分的是一组只在单个因素上不同的变体。

### 7.3.2 修法

`examples/08-cpp-bindings/main.cpp` 的包含顺序因此被改成 `cl.hpp` 在前：

```cpp
// cl.hpp FIRST, then anything that pulls in <CL/cl.h>. Reversing these two lines
// costs one warning that is not your code's fault:
//
//   cl.hpp(6856): warning C4996: 'clSetProgramReleaseCallback'
//
#include <CL/cl.hpp>

#include "ocl_util.h"   // verdict contract, ocl_report_device, ocl_round_up
```

第一版是 `ocl_util.h` 在前——它内部第 27 行 `#include <CL/cl.h>`，正好触发上面那条链路。改完之后 `.\build.ps1 -Examples 08-cpp-bindings -Rebuild` **零警告**。

两条修法，本教程选第一条：

| 修法 | 代价 |
|---|---|
| **`cl.hpp` 放在任何会拉进 `cl.h` 的头之前** | 只是包含顺序的纪律；`MINIMUM` 仍可保持 200，兼容 2.x 设备 |
| `CL_HPP_MINIMUM_OPENCL_VERSION=300` | 顺序无关，但 `cl.hpp` 不再编进 2.2 之前的弃用包装，等于把教程限定在 3.0 设备上 |

根 `build.ps1` 的注释里记了这个取舍。`cl.hpp` 自己的建议其实也是第一条（`cl.hpp:61-64`）："There is no additional requirement to include *cl.h* ... it is enough to simply include *opencl.hpp*"——**只包含 `cl.hpp` 就够了，不需要再包含 `cl.h`**。混合包含才是问题的来源。

> 这不是"警告而已，忽略就好"。`C4996` 指向的行号在官方头文件里、函数名你从没写过，任何人第一次看到都会先怀疑自己的构建配置。花时间把它归因清楚，比 `/wd4996` 屏蔽掉值钱。

## 7.4 与 C API 的逐项对照

`examples/02-vector-add/main.c`（231 行 C）与 `examples/08-cpp-bindings/main.cpp`（355 行 C++）做的是同一件事，跑在同一个设备上，得到同一组数值。行数变多不是因为 C++ 啰嗦，而是因为 08 多做了三组测量（构建选项、引用计数、profiling）。

### 7.4.1 对照表

| 步骤 | C API（[03 篇](./03-first-program.md)） | `cl.hpp` |
|---|---|---|
| 枚举平台 | `clGetPlatformIDs` 两次调用（先取数量再取列表） | `cl::Platform::get(&platforms)` 一次 |
| 枚举设备 | `clGetDeviceIDs` 两次调用 | `platform.getDevices(type, &devices)` 一次 |
| 查设备信息 | `clGetDeviceInfo(dev, PARAM, size, &val, &ret)` | `device.getInfo<PARAM>()` |
| 建上下文 | `clCreateContext` + 手动 `clReleaseContext` | `cl::Context context(device);` 析构自动释放 |
| 建队列 | `clCreateCommandQueueWithProperties` + 手动释放 | `cl::CommandQueue queue(context, device, props);` |
| 建缓冲 | `clCreateBuffer` + 手动 `clReleaseMemObject` | `cl::Buffer buf(context, flags, size, ptr);` |
| 建程序 | `clCreateProgramWithSource` | `cl::Program program(context, sources);` |
| 编译 | `clBuildProgram` + 手动查日志 | `program.build(options)`，失败抛 `cl::BuildError` 自带日志 |
| 查构建信息 | `clGetProgramBuildInfo` 两次调用 | `program.getBuildInfo<PARAM>(device)` |
| 建内核 | `clCreateKernel` | `cl::Kernel kernel(program, "name");` |
| 设参数 | `clSetKernelArg(k, i, sizeof(cl_mem), &buf)` | `kernel.setArg(i, buf)` |
| 下发 | `clEnqueueNDRangeKernel(queue, k, dim, off, gws, lws, n, waits, &ev)` | `queue.enqueueNDRangeKernel(k, off, gws, lws, waits, &ev)` |
| 读回 | `clEnqueueReadBuffer` | `queue.enqueueReadBuffer` |
| 查 profiling | `clGetEventProfilingInfo` | `ev.getProfilingInfo<PARAM>()` |
| 错误处理 | 每次调用后 `if (err != CL_SUCCESS)` | `try` / `catch (const cl::Error&)` |
| 释放 | 21 处 `clRelease*`，正常路径 10 处 + 五条错误路径 11 处 | **0 处** |

`examples/08` 全文没有任何一处 `clRelease*` **调用**（`grep` 到的两处都在注释里），也没有任何一个 `cl_int` 被检查。这是绑定最主要的收益，而且它是**可数的**：`examples/02-vector-add/main.c` 里有 **21 处 `clRelease*` 调用**，分布在 15 行上——

| 位置 | 调用数 | 作用 |
|---|---|---|
| `main.c:215-224` | 10 | 正常路径末尾的清理，顺序不能错 |
| `main.c:66`、`72`、`78`、`100`、`108` | 11 | **五条提前返回的错误路径，每条都要把已建好的对象重抄一遍** |

后面那 11 处才是重点。C 版本里每加一个提前返回，就得把"此刻已经建好的对象"按逆序再释放一遍；漏一个就是泄漏，多一个就是双重释放。`examples/08` 里这类代码是 **0 行**——不是因为它写得更巧妙，而是因为作用域结束自动就做了。

### 7.4.2 `getInfo<T>()`：真正消掉的一类错误

`getInfo<T>()` 不只是"少写一个 size 参数"。它的返回类型来自一张以参数常量为键的 traits 表，所以**类型不可能写错**：

```cpp
std::string name = device.getInfo<CL_DEVICE_NAME>();          // 返回 std::string
size_t maxwg  = device.getInfo<CL_DEVICE_MAX_WORK_GROUP_SIZE>(); // 返回 size_t
```

对照 [05 篇 §5.3.1](./05-core-concepts.md) 记过的那个坑：C API 下用 `cl_uint` 去接 `CL_DEVICE_MAX_WORK_GROUP_SIZE`，驱动因为 size 不匹配**拒答并把输出缓冲留成 0**，程序照常运行，然后你拿着 `max_work_group_size = 0` 去算 local size。那个错误在 `getInfo<T>()` 下**写不出来**——没有 size 参数可以传错。

这是绑定最实在的一处改进，比"少打几行字"重要得多。

### 7.4.3 `setArg`：消掉 `sizeof(cl_mem)`

```cpp
kernel.setArg(0, bufA);      // 直接传包装对象
kernel.setArg(3, (int)N);    // 标量也直接传
```

C 版对应的是 `clSetKernelArg(kernel, 0, sizeof(cl_mem), &bufA)`。[03 篇 §3.3.7](./03-first-program.md) 记过：第二个参数是"**参数值**的字节数"，不是"数据的字节数"；写成 `sizeof(float*)` 在 64 位上碰巧等于 `sizeof(cl_mem)`，所以这个错误能潜伏很久。`setArg` 用重载决定大小，这一整类错误消失了。

### 7.4.4 绑定让某些错误**更容易**犯

必须说清楚反面。原始资料的 C++ 示例这样选设备：

```cpp
cl::Platform platform = platforms[0];
platform.getDevices(CL_DEVICE_TYPE_GPU, &devices);
cl::Device device = devices[0];
```

**在本机这选中的是 NVIDIA RTX 2060，不是本教程要讲的 Intel UHD 630**——`platforms[0]` 是 "NVIDIA CUDA"（`examples/01-device-query` 的输出可查）。

C 版本犯同样的错时，至少 `clGetPlatformIDs` 会给你一个 `cl_int` 让你有机会注意到出了什么事。C++ 版本**没有错误可检查**：`platforms[0]` 就是能编译、能运行、能出正确数值，只不过那些数值属于另一块 GPU。

> **绑定把这类错误变得更容易写、更难发现。** 它消掉的是"忘记检查返回值"和"忘记释放"这两类**机械性**错误；它消不掉"你选错了设备""你算错了尺寸"这类**语义**错误，反而因为没有错误码可看，让后者更安静。`examples/08` 因此仍然按名字匹配设备（`pickDeviceByName`，遍历所有平台），跟其余十个例子一致。

## 7.5 错误模型

### 7.5.1 `cl::Error::what()` 是 C 入口点的名字，不是句子

原始资料写：

```cpp
} catch (cl::Error& err) {
    std::cerr << "OpenCL Error: " << err.what() << std::endl;
}
```

看起来会打印一句描述。**实际打印的是失败的那个 C 函数的名字**，比如：

```text
OpenCL Error: clBuildProgram
```

因为 `what()` 返回的是 `CL_HPP_ERR_STR_(x)`，而这个宏就是 `#x`（`cl.hpp:782`）——字符串化的入口点名。它不含错误码、不含原因、不含参数信息。

要用对，得把三样东西一起打出来：

```cpp
} catch (const cl::Error& e) {
    printf("[FAIL] cl::Error %d %s (thrown by %s)\n",
           e.err(), ocl_err_name(e.err()), e.what());
}
```

`e.err()` 是 `cl_int`，`ocl_err_name` 把它翻成 `CL_INVALID_WORK_GROUP_SIZE` 这样的常量名（`examples/common/ocl_util.h`），`e.what()` 告诉你是哪一次调用出的事。三个合起来才等于 C 版本里"错误码 + 出错行"的信息量。

**`what()` 报的是入口点名，这一点其实很有用**——它精确地告诉你是 `clBuildProgram` 还是 `clEnqueueNDRangeKernel` 失败了，而 C 版本里你得靠 `err |=` 的累积顺序去猜。只是别指望它是一句人话。

### 7.5.2 `cl::BuildError` 把构建日志装在异常里

`cl::BuildError` 是 `cl::Error` 的子类（`cl.hpp:2595-2608`），额外带一份**逐设备的构建日志**：

```cpp
class BuildError : public Error
{
private:
    BuildLogType buildLogs;
public:
    BuildError(cl_int err, const char * errStr, const BuildLogType &vec) : Error(err, errStr), buildLogs(vec) { }
    BuildLogType getBuildLog() const { return buildLogs; }
};
```

`BuildLogType` 是 `vector<pair<cl::Device, string>>`（`cl.hpp:2590`）。`Program::build()` 与那几个会自动构建的构造函数通过 `detail::buildErrHandler`（`cl.hpp:2610-2619`）抛它。

这直接替掉了 `examples/02-vector-add/main.c` 里那段约 15 行的手动 `clGetProgramBuildInfo` 两次调用（先查长度、再分配、再查内容）。`examples/08` 的对应代码：

```cpp
} catch (const cl::BuildError& e) {
    printf("[FAIL] cl::BuildError %d (%s)\n", e.err(), e.what());
    std::vector<std::pair<cl::Device, std::string>> logs = e.getBuildLog();
    for (size_t i = 0; i < logs.size(); i++) {
        printf("---- build log: %s ----\n%s\n",
               logs[i].first.getInfo<CL_DEVICE_NAME>().c_str(),
               logs[i].second.c_str());
    }
    return ocl_report(0);
}
```

**这是绑定最值的一处改进**，比 RAII 更值。内核编译错误是 OpenCL 开发里最高频的失败，而 C API 下"编译失败"和"取到日志"是两个独立步骤，忘了第二步就只剩一个 `-11 CL_BUILD_PROGRAM_FAILURE`，什么也看不出来。绑定把日志塞进异常本身，忘不掉。

### 7.5.3 `catch` 的顺序

`cl::BuildError` 派生自 `cl::Error`，所以**必须先接 `BuildError`**：

```cpp
try {
    /* ... */
} catch (const cl::BuildError& e) {   // 先接派生类
    /* 有构建日志 */
} catch (const cl::Error& e) {        // 再接基类
    /* 只有错误码和入口点名 */
}
```

写反了不会编译错误，只是构建日志永远取不到——`catch (const cl::Error&)` 会先把 `BuildError` 接走。这是那种"静默地丢掉最有用的信息"的缺陷。

## 7.6 对象生命周期：`retainObject` 是"再加一个引用"

每个包装类的构造函数都有一个从裸句柄构造的重载，第二个参数是 `bool retainObject`。原始资料在 OpenGL 互操作那节写：

```cpp
// 包装为 C++ 对象（注意：需要手动管理 cl_mem 的生命周期）
cl::Image2D glImage(clImage, true);  // true 表示接管所有权
```

**这条注释是反的，而且反得很危险。**

`cl.hpp:2724` 的文档原文：

> `\param retainObject` will cause the constructor to **retain** its cl object. Defaults to false to maintain compatibility with earlier versions.

`retain` 在 OpenCL 里是一个有精确定义的动词：`clRetainMemObject` 把引用计数**加一**。所以：

| `retainObject` | 语义 | 引用计数变化 | 谁负责释放 |
|---|---|---|---|
| `true` | 包装**另取一个**引用 | **+1** | 调用方仍持有自己那一个，**仍须自己 `clRelease*`** |
| `false`（默认） | 包装**接管**调用方现有的那一个引用 | 不变 | 包装析构时释放；调用方**不能再释放** |

"接管所有权"是 `false` 的语义，不是 `true` 的。按原始资料那行写，`glImage` 析构时释放一个引用，而 `clImage` 那个引用**没人释放**——一个稳定的泄漏；反过来，如果你"补上"一次 `clReleaseMemObject(clImage)` 又以为 `true` 已经接管了，逻辑就绕成了双重释放的候选。

### 7.6.1 实测：`CL_MEM_REFERENCE_COUNT`

引用计数是**可观测的**，所以这一条不必靠读文档定论。`examples/08` 第 11 节直接把它读出来（**运行时数值级**，Intel UHD 630）：

```cpp
cl_uint rc0 = bufC.getInfo<CL_MEM_REFERENCE_COUNT>();
{
    cl::Buffer shared(bufC(), true);        // retain
    cl_uint rc1 = shared.getInfo<CL_MEM_REFERENCE_COUNT>();
    printf("[refcount] original=%u, after cl::Buffer(handle, true)=%u\n", rc0, rc1);
}
cl_uint rc2 = bufC.getInfo<CL_MEM_REFERENCE_COUNT>();
printf("[refcount] after the wrapper went out of scope=%u\n", rc2);
```

真实输出：

```text
[refcount] original=1, after cl::Buffer(handle, true)=2
[refcount] after the wrapper went out of scope=1
```

`1 → 2 → 1`。`true` 确实**加了一个**引用，包装析构时把它还回去，原来那个包装的引用毫发无损。如果 `true` 真是"接管所有权"，第二个数就该还是 1，而 `rc2` 会是 0 或者一个已失效的句柄。

`false` 那半段更能说明问题：

```cpp
cl_mem rawMem = clCreateBuffer(context(), CL_MEM_READ_WRITE, 16 * sizeof(float), nullptr, &cerr);
cl_uint before = rawRefCount(rawMem);
{
    cl::Buffer adopted(rawMem, false);      // adopt
    cl_uint inside = adopted.getInfo<CL_MEM_REFERENCE_COUNT>();
    printf("[refcount] raw cl_mem=%u, after cl::Buffer(handle, false)=%u\n", before, inside);
}
// adopted 的析构释放了唯一的引用，rawMem 已经死了
cl_uint dead = 0;
cl_int q = clGetMemObjectInfo(rawMem, CL_MEM_REFERENCE_COUNT, sizeof(dead), &dead, nullptr);
printf("[refcount] querying the raw handle afterwards -> %d %s\n", q, ocl_err_name(q));
```

真实输出：

```text
[refcount] raw cl_mem=1, after cl::Buffer(handle, false)=1
[refcount] querying the raw handle afterwards -> -38 CL_INVALID_MEM_OBJECT
```

`1 → 1`：接管**不新建**引用。作用域结束后**查询失败**，返回 `-38 CL_INVALID_MEM_OBJECT`——句柄已经无效，因为包装把唯一的引用释放掉了。**这个失败就是证据**：如果只是"包了一层"，句柄还会正常应答。

代码里那句注释也就此有了着落——`false` 之后**故意不再调 `clReleaseMemObject(rawMem)`**，因为包装已经释放过了，再释放一次就是双重释放。

### 7.6.2 这条规则适用于所有包装类

`retainObject` 不是 `cl::Buffer` 独有的，`cl::Image2D`、`cl::Program`、`cl::Kernel`、`cl::Event`、`cl::CommandQueue`、`cl::Context` 全都有同形状的重载，文档措辞一致（`cl.hpp:2724` 那段是 `cl::Platform` 的，其余各处照抄）。所以 OpenGL 互操作那段正确的写法是：

```cpp
cl_mem clImage = clCreateFromGLTexture(context.get(), CL_MEM_READ_WRITE,
                                       GL_TEXTURE_2D, 0, texture, &err);
// false：包装接管这个引用，析构时释放它，外面不要再 clReleaseMemObject
cl::Image2D glImage(clImage, false);
```

（顺带修掉原始资料的另一处：`clCreateFromGLTexture2D` 自 OpenCL 1.2 起已弃用，应使用 `clCreateFromGLTexture`。）

> **诚实边界**：`false` 那半段的引用计数序列是**运行时数值级**实测（本机 Intel UHD 630，普通 `clCreateBuffer` 句柄）。7.6.2 那段 GL 代码本身**没有在本机跑过**——见 7.9。这里只主张"`retainObject` 的语义对 `cl::Image2D` 与对 `cl::Buffer` 相同"，依据是 `cl.hpp` 里各包装类的构造重载形状一致，属于**主机编译级 + 文档核对**。

## 7.7 `cl::Program` 什么时候构建、用什么语言等级构建

这一节是 `examples/08` 第 5 节整节存在的原因。**同一份内核源码，用三种方式构造，得到三个不同的 `-cl-std`，而三者跑出来的数值完全一样**——所以除非你把构建选项读回来，否则看不出差别。

### 7.7.1 三个构造，三个 `-cl-std`

```cpp
// (A) 单字符串便捷构造 + build=true
cl::Program pA(context, source, /*build=*/true);
optsAuto = pA.getBuildInfo<CL_PROGRAM_BUILD_OPTIONS>(device);

// (B) Sources 构造，然后不带参数 build()
cl::Program::Sources sources;
sources.push_back(source);
cl::Program program(context, sources);
program.build();
optsPlain = program.getBuildInfo<CL_PROGRAM_BUILD_OPTIONS>(device);

// (C) 显式指定
cl::Program program12(context, sources);
program12.build("-cl-std=CL1.2");
opts12 = program12.getBuildInfo<CL_PROGRAM_BUILD_OPTIONS>(device);
```

Intel UHD Graphics 630 上的真实输出（**运行时数值级**）：

```text
[build options] ctor(string, build=true) : '-cl-std=CL2.0'
[build options] Sources ctor + build()   : ''
[build options] build("-cl-std=CL1.2")    : '-cl-std=CL1.2'
```

**(A) 那个 `-cl-std=CL2.0` 是 `cl.hpp` 硬编码的，没有人要求过它。** 四个带 `bool build = false` 参数的 `Program` 构造函数（`cl.hpp:6254`、6294、6407、6463）内部都写着同一段：

```cpp
error = ::clBuildProgram(
    object_,
    0,
    nullptr,
#if !defined(CL_HPP_CL_1_2_DEFAULT_BUILD)
    "-cl-std=CL2.0",
#else
    "",
#endif
    nullptr,
    nullptr);
```

**(B) 那个空字符串是因为 `Sources` 构造函数根本没有 `build` 参数。** `cl.hpp:6363-6370` 的注释写得很直白：

```cpp
/**
 * Create a program from a vector of source strings and a provided context.
 * Does not compile or link the program.
 */
Program(
    const Context& context,
    const Sources& sources,
    cl_int* err = nullptr)
```

所以 (B) 走的是"不带参数 `build()`"→ 传 `NULL` 给 `clBuildProgram` → **由驱动决定默认等级**。按 [06 篇 §6.2.2](./06-kernel-programming.md) 的实测，本机两个 Intel 设备的 `__OPENCL_C_VERSION__` 默认是 `120`，于是 (B) 实际按 OpenCL C 1.2 编译。

### 7.7.2 这是文档写明的行为，不是 bug

`cl.hpp:122-131` 自己解释了为什么：

> In OpenCL 2.0 OpenCL C is not entirely backward compatibility with earlier versions. As a result a flag must be passed to the OpenCL C compiled to request OpenCL 2.0 compilation of kernels with 1.2 as the default in the absence of the flag. In some cases the C++ bindings automatically compile code for ease. **For those cases the compilation defaults to OpenCL C 2.0.** If this is not wanted, the `CL_HPP_CL_1_2_DEFAULT_BUILD` macro may be specified to assume 1.2 compilation. If more fine-grained decisions on a per-kernel bases are required then explicit build operations that take the flag should be used.

三条出路，按可控性排序：

| 做法 | 效果 |
|---|---|
| **显式 `build("-cl-std=CL1.2")`** | 最清楚。等级写在代码里，读代码就知道 |
| 定义 `CL_HPP_CL_1_2_DEFAULT_BUILD` | 全局把四个自动构建路径的硬编码换成 `""`，交回驱动默认 |
| 用 `Sources` 构造 + 不带参数 `build()` | 也是交回驱动默认，但这是"碰巧"，不是设计意图 |

### 7.7.3 为什么这一条在本机会咬人

[06 篇](./06-kernel-programming.md) 整篇的核心结论是：**`CL_DEVICE_OPENCL_C_VERSION` 不能预测一个内建函数能不能编译**，本机 Intel iGPU 广告 "OpenCL 3.0" 却只给 OpenCL C 1.2。

在这个背景下，(A) 那个自动的 `-cl-std=CL2.0` 是一枚定时炸弹：它让内核**按 2.0 编译**，于是 `to_global`、`work_group_barrier` 这些 1.2 下不存在的内建函数在 iGPU 上**编译通过**了。你因此以为"这台设备支持 OpenCL C 2.0"，把代码写下去——直到某天换了一个不自动加这个选项的构建路径（比如 (B)，或者 `clBuildProgram` 直接调），同样的源码突然编译失败。

`examples/08` 因此把三个选项字符串**读回来并断言**：

```cpp
int optsOk =
    (optsAuto.find("-cl-std=CL2.0") != std::string::npos) &&
    (optsPlain.find_first_not_of(" \t\r\n") == std::string::npos) &&
    (opts12.find("-cl-std=CL1.2") != std::string::npos);
```

三个条件任一变化，例子就 `[RESULT] FAIL`。这条断言的作用是**在头文件行为改变时立刻发现**，而不是等某个内核在另一台机器上编译失败。

实际下发内核用的是 (C) 那个 `program12`——**教程的其余部分一律显式指定 `-cl-std`**。

### 7.7.4 `build()` 与 `build(device)`

原始资料写 `program.build(device)`，`examples/08` 写 `program.build()`。区别：

- `build()` → 传给 `clBuildProgram` 的设备数是 0、设备列表是 `nullptr`，即**为程序关联的所有设备构建**。
- `build(device)` → 只为那一个设备构建。

单设备上下文下两者等价。多设备上下文下（[09 篇](./09-practical-examples.md) 会讲到 `examples/10-multi-device`）用 `build(device)` 会让**其余设备上的内核处于未构建状态**，之后在那台设备上 `clCreateKernel` 会失败。这个失败离原因很远，很难查。

## 7.8 绑定不改变设备侧

值得单独强调，因为"C++ 绑定"这个名字容易让人以为内核也能写 C++。

```text
$ diff examples/02-vector-add/kernels/vector_add.cl \
       examples/08-cpp-bindings/kernels/vector_add.cl
$
```

**无输出——两个文件逐字节相同。** 同一份 OpenCL C 1.2 源码，同一个设备，同一组数值（1024/1024 元素正确）。

内核语言是另一回事："C++ for OpenCL"（基于 C++14 的内核语言）需要 OpenCL C 2.2 以上，**本机没有任何设备能在运行时编译它**——两块 GPU 都是 OpenCL C 1.2，Intel CPU 设备是 3.0 但不含 C++ for OpenCL。这一条在 [01 篇 §1.6](./01-opencl-overview.md) 的能力矩阵里已经标为不可用。

**但"编不了"和"跑不了"是两件事**，[08 篇 §8.8.5](./08-spirv.md) 用同一个文件把两者并排测了出来：把一份真含模板的 OpenCL C++ 源码交给核显自己的前端，得到 `-11` 与 `error: unknown type name 'template'`；而离线 clang 用 `-cl-std=CLC++` 编出的模块，**在同一块核显上跑通 1024/1024**。原因是 `clCreateProgramWithIL` 之后驱动只做后端代码生成，没有前端可言。绑定侧的对应写法（`cl::Program` 的 IL 构造函数、以及它那个在失败路径上从不被写的 `cl_int* err` 出参）见 [08 篇 §8.9](./08-spirv.md)，可运行版本是 `examples/08-cpp-bindings` 的第 12 节。

**所以：走本篇这条路（主机把源码交给 `clBuildProgram`，由设备编译）时，主机侧用 C++ 绑定、设备侧仍然是 OpenCL C，这两件事完全独立。** 唯一的例外是离线 IL 路线，它把编译搬到程序运行之前，于是设备侧能写什么由离线工具链决定——那是 [08 篇](./08-spirv.md) 的主题。

## 7.9 OpenGL 互操作

原始资料有一整节 C++ 的 GL 互操作。本节**不重写它**，只列修正点，因为：

> **诚实边界**：本机没有可用的 OpenGL 上下文与 OpenCL-GL 共享环境，`examples/` 里也**没有**对应的可运行工程。以下每条都是**文档核对**级，不是实测。`tools/cpp-header-probe` 的 17 个变体没有一个涉及 `cl_gl.h`。

| 原始资料 | 修正 | 依据 |
|---|---|---|
| `clCreateFromGLTexture2D` | 改 `clCreateFromGLTexture` | 前者自 OpenCL 1.2 起弃用（文档核对） |
| `cl::Image2D glImage(clImage, true); // true 表示接管所有权` | 改 `false`，注释也反了 | 7.6.1 的**运行时数值级**实测（语义本身已实测，GL 代码路径未实测） |
| 缺 `cl_khr_gl_sharing` 扩展检查 | 建上下文前必须查 `CL_DEVICE_EXTENSIONS` | 没有该扩展时 `clCreateFromGLTexture` 返回 `CL_INVALID_GL_SHAREGROUP_REFERENCE_KHR`（文档核对） |
| 缺"同一上下文的所有设备都必须支持共享"的说明 | 建共享上下文时要用 `cl_context_properties` 指定 GL 上下文句柄 | 文档核对 |
| `enqueueAcquireGLObjects` / `enqueueReleaseGLObjects` 之间没有同步说明 | acquire 之前必须确保 GL 侧渲染已完成（`glFinish` 或 fence），release 之后才能再动纹理 | 文档核对 |

**最后一条是最容易出错的**，而且出错方式是间歇性的画面撕裂或过期数据，不是崩溃。GL 与 CL 是两个独立的命令流，`enqueueAcquireGLObjects` 只转移对象所有权，**不做跨 API 同步**。

## 7.10 原教程 C++ 部分的逐条修正

| # | 原始资料 | 问题 | 修正 | 通道 |
|---|---|---|---|---|
| 1 | `#include <CL/opencl.hpp>` / `<CL/cl2.hpp>` | 本机两个 SDK 都没有这两个文件 | 统一 `<CL/cl.hpp>`，讲清命名沿革（7.1） | 主机编译级（变体 5、6） |
| 2 | 只用 `__CL_ENABLE_EXCEPTIONS` 会炸 100+ 未定义标识符 | **归因错误**。老宏名照旧生效；炸的原因是两个版本宏不一致。数量也不是 100+，是 42 个 `error C` 行 / 34 个 `C2065`，且 34 是下限 | 7.2.1、7.2.3；[02 篇 §2.6.3](./02-environment-setup.md) | 主机编译级（变体 2、3、4） |
| 3 | 未提 `CL_HPP_MINIMUM_OPENCL_VERSION` | 填 120 会撞上 `cl.hpp` 的门控缝隙，12 个错误 | 7.2.2；默认值 200，别显式写 120 | 主机编译级（变体 11、12） |
| 4 | `platforms[0]` / `devices[0]` | 本机 `platforms[0]` 是 NVIDIA CUDA，整个教程会跑在 RTX 2060 上；C++ 版**没有错误码可检查**，更安静 | 按名字匹配，遍历所有平台（7.4.4） | 设备元数据级 |
| 5 | `err.what()` 当作错误描述打印 | 它返回的是 C 入口点名字，如 `clBuildProgram` | `e.err()` + 错误码名 + `e.what()` 三样一起打（7.5.1） | 主机编译级（`cl.hpp:782`） |
| 6 | `catch (cl::Error&)` 处理构建失败 | 丢掉 `cl::BuildError` 携带的逐设备构建日志 | 先 `catch (const cl::BuildError&)`（7.5.2、7.5.3） | 主机编译级 |
| 7 | `cl::Image2D glImage(clImage, true); // true 表示接管所有权` | **语义反了**，`true` 是再加一个引用 | 改 `false`；用 `CL_MEM_REFERENCE_COUNT` 实测（7.6） | 运行时数值级 |
| 8 | `clCreateFromGLTexture2D` | 自 1.2 起弃用 | `clCreateFromGLTexture` | 文档核对 |
| 9 | `cl::Program program(context, sources); program.build(device);` | 多设备上下文下其余设备未构建 | 单设备用 `build()`；多设备显式列出（7.7.4） | 文档核对 |
| 10 | 未提自动构建路径硬编码 `-cl-std=CL2.0` | 在本机（设备只给 OpenCL C 1.2）会让人误判设备能力 | 一律显式 `build("-cl-std=CL1.2")`（7.7） | 运行时数值级 |
| 11 | 内核 `c[idx] = a[idx] + b[idx];` 无越界保护 | `N` 不是 local size 整数倍时越界写 | 内核加 `if (idx < n)`，主机 `ocl_round_up`（见 [03 篇 §3.3.7](./03-first-program.md)） | 运行时数值级 |
| 12 | `cl::NDRange(256)` 写死 local size | 本机 iGPU 上限恰好是 256，纯属侥幸；RTX 2060 上设备上限 1024 而**内核**上限 256 | `min(device max_wg, kernel wg size)`（[06 篇 §6.7.3](./06-kernel-programming.md)） | 运行时数值级 |
| 13 | `setCallback` 在 3.0 已弃用 | **这条不成立**。`clSetEventCallback` 在 `cl.h:1479-1485` 带的是 `CL_API_SUFFIX__VERSION_1_1`，**没有** `_DEPRECATED`；`cl.hpp` 的 `setCallback` 由 `cl.hpp:3721` 的 `#if CL_HPP_TARGET_OPENCL_VERSION >= 110` 门控（声明在 3726），没有任何弃用标记。**并且真的编译过**：变体 16 用原文那个 lambda 形状调它，x64 与 x86 都是零警告 | 撤回弃用说法。事件回调真正的缺陷是**线程安全**（见下） | 主机编译级（变体 16、17） |

第 13 条值得单独说，因为它是一个**被撤回的修正**。原始资料的事件回调写法确实有问题，但问题不是弃用。它给的两段是这样的（原文第 1073 行）：

```cpp
cl::Event event;
queue.enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(1024), cl::NullRange,
                           nullptr, &event);

event.setCallback(CL_COMPLETE, [](cl_event, cl_int, void*) {
    std::cout << "Kernel execution completed!" << std::endl;
}, nullptr);
```

`setCallback` 是 `cl::Event` 的成员，签名是 `(cl_int type, pfn_notify, void* user_data)`（`cl.hpp:3726-3729`）。三条真实缺陷：

1. **回调在驱动拥有的线程上执行。** 在那里写 `std::cout`（或与主线程共享任何状态）是数据竞争。回调里应当只做"设置一个标志 / 释放一个信号量"这类最小动作。
2. **主线程从不等待回调。** 原始资料那节结束就 `return 0` 了，进程可能在回调触发前退出，于是 "Kernel execution completed!" 有时打印有时不打印。必须 `queue.finish()` 或 `event.wait()`，且**等待之后仍不保证回调已经跑完**——`clSetEventCallback` 只保证回调会被排入执行，需要额外同步（条件变量之类）。
3. **原文第二段（第 1190 行）先 `event.wait()`、再 `setCallback`**，等于给一个已经完成的事件挂回调。规范上它仍应触发（状态已满足），但这个顺序说明作者把回调当成了"等待的替代品"，而它不是——它是通知机制。

`clSetEventCallback` 本身没被弃用，可以放心用。

**这一条是"被撤回的修正"，所以它拿到的证据比它替换掉的那个说法更强。** 光读 `cl.h:1479-1485` 只能证明"声明上没有弃用标记"，证明不了"你的调用不会触发警告"。所以 `tools/cpp-header-probe` 的变体 16、17 真的把原文那个调用编译了一遍——一字不改的 lambda 形状，只改包含顺序：

| 变体 | 包含顺序 | 结果 |
|---|---|---|
| 16 | `<CL/cl.hpp>` 先 | 编译通过，**零警告** |
| 17 | `<CL/cl.h>` 先 | 编译通过，只有一条 `cl.hpp(6856): warning C4996: 'clSetProgramReleaseCallback'` |

变体 17 的断言里除了 `Require = @('C4996', 'clSetProgramReleaseCallback')`，还有一条 `Forbid = @('clSetEventCallback')`。**这条 Forbid 才是重点**：它把"警告不是你的回调引起的"从一句辩解变成一个会失败的检查。两个变体里用户代码逐字节相同，警告却只在其中一个出现——差异只能来自包含顺序，而包含顺序不参与那次调用。

> 顺带记一个**被实测否掉的推测**，因为它看起来很可信。`cl.hpp:561-563` 把 `CL_CALLBACK` 定义为空，而 `cl_platform.h:33-35` 在 Windows 上把它定义成 `__stdcall`，于是很自然会推断：包含顺序决定 `setCallback` 形参的调用约定，而 cdecl 的 lambda 在 x86 上转换不过去。**两半都是错的。** 实测（x86 与 x64 各跑一遍）`CL_CALLBACK` 在**两种顺序下都展开成 `__stdcall`**，因为 `cl.hpp:525` 自己就 `#include <CL/opencl.h>`，位置在 561 那个兜底之前——只要 C 头文件找得到（永远找得到），兜底就不会生效。另外 x86 的 MSVC 本来就接受"无捕获 lambda → `__stdcall` 函数指针"这个转换（两行的独立测试，退出码 0、无警告）。**包含顺序改变的是那条 `C4996`，仅此而已。**

## 7.11 什么时候用绑定，什么时候别用

**用**：

- 主机侧代码量大、对象多、错误路径多。RAII 消掉的是**机械性**错误（漏释放、释放顺序错），这类错误在长代码里必然出现。
- 需要频繁查设备/程序/内核信息。`getInfo<T>()` 让"size 参数传错"这一整类错误写不出来（7.4.2）。
- 内核编译是主要调试对象。`cl::BuildError` 自带日志（7.5.2）比 C 版那 15 行查询实在得多。

**别用**（或至少想清楚）：

- 你在写一个要被 C 项目调用的库。绑定是 C++ 头文件，会把 C++ 运行时和异常语义带进 ABI。
- 你需要精确控制每一次 `clRetain*` / `clRelease*`（例如与别的框架共享句柄）。包装的自动释放在这类场景里是障碍，`retainObject` 的两个取值都必须搞清楚（7.6）。
- 你打算关掉异常。那基本抵消了用绑定的理由（7.2.4），不如直接用 C API。
- 你的构建里 `cl.hpp` 与 `cl.h` 会被混着包含，而你没法控制顺序。会撞上 7.3 那条警告。

**本教程的选择**：01–07 与 09–11 用 C API，08 用绑定。理由是其余十个例子要把每一个 `clCreate*` / `clRelease*` / 错误码都摆在明面上讲清楚——绑定会把它们藏起来，而**藏起来正是它的优点，也正好是教学时的缺点**。真实项目里我建议用绑定。

## 7.12 小结

1. **本机只有 `<CL/cl.hpp>`**，`cl2.hpp` 与 `opencl.hpp` 都不存在（变体 5、6 实测 `C1083`）。但它的**内容是 `opencl.hpp`**——13 条 `# pragma message` 里 12 条自称 `opencl.hpp`，连它自带的示例代码都教你包含一个本机没有的文件名。
2. **`CL_HPP_TARGET_OPENCL_VERSION` 必须与 `CL_TARGET_OPENCL_VERSION` 一致**，不一致是 42 个编译错误、34 个未声明标识符，全部来自 `cl.hpp` 的两行 X-macro。最省事的写法是干脆别定义 `CL_TARGET_OPENCL_VERSION`——`cl.hpp:460` 会替你定义成一致的值。
3. **`CL_HPP_MINIMUM_OPENCL_VERSION` 填 120 会撞上门控缝隙**，12 个错误，报的是官方头文件里的内部符号。默认值 200 是安全的，别显式改成 120。
4. **老宏名 `__CL_ENABLE_EXCEPTIONS` 仍然生效**，把它当故障原因是错误归因（变体 2/3/4 的三方对照）。
5. **那条 `C4996` 需要两个原因同时成立**：`MINIMUM <= 220` 让 `cl.hpp` 编进弃用包装，`cl.h` 先被包含让 `cl_platform.h` 把弃用标记冻上。四格实测（变体 7、13、14、15）里只有一格报警告。修法是**把 `cl.hpp` 放在最前面**。
6. **`cl::Error::what()` 返回 C 入口点名字**，不是句子。要打 `e.err()` + 错误码名 + `e.what()` 三样。
7. **`cl::BuildError` 携带逐设备构建日志**，这是绑定最值的一处改进，`catch` 时必须排在 `cl::Error` 前面。
8. **`retainObject = true` 是"再加一个引用"，不是"接管所有权"**——原始资料的注释正好反了。引用计数实测 `1 → 2 → 1`（`true`）与 `1 → 1 → CL_INVALID_MEM_OBJECT`（`false`）。
9. **自动构建路径硬编码 `-cl-std=CL2.0`**（`cl.hpp:122-131` 有文档说明，不是 bug）。在本机这个"设备只给 OpenCL C 1.2"的环境里，它会让人误判设备能力。一律显式 `build("-cl-std=CL1.2")`。
10. **`cl::Program(context, sources)` 从不自动构建**——那个重载连 `build` 参数都没有（`cl.hpp:6365` 的注释：*Does not compile or link the program.*）。
11. **绑定不改变设备侧。** `examples/08` 与 `examples/02` 的内核文件逐字节相同。
12. **绑定让语义错误更安静。** 它消掉的是漏释放、漏检查这类机械错误；`platforms[0]` 选错设备这种事，C++ 版连一个 `cl_int` 都不给你。
13. **`clSetEventCallback` 没有弃用**——这条修正被撤回了，而且是**编译过**才撤回的：变体 16、17 用原文那个 lambda 形状真调了一次，x64 与 x86 都零警告；变体 17 还断言那条 `C4996` **不得**提到 `clSetEventCallback`，这就把"警告不是你的回调引起的"变成了会失败的检查。事件回调真正的问题是线程安全和从不等待。
14. **`cl::Program` 的 IL 构造函数里，`cl_int* err` 出参在失败路径上从不被写**——`detail::errHandler` 在 `*err = error` **之前**就把异常抛出去了。实测把 `err` 预置成哨兵值 `12345`，捕获到 `cl::Error -42 CL_INVALID_BINARY (clCreateProgramWithIL)` 之后哨兵**原封不动**。所以原始资料那个 `if (err != CL_SUCCESS) throw` 是死代码：走到那一行时要么没出错，要么已经不在你的栈上了。同一个构造函数在 `build=true` 时还硬编码 `-cl-std=CL2.0` 并向 `clBuildProgram` 传**零个设备**（`cl.hpp:6492`）。完整拆解见 [08 篇 §8.9](./08-spirv.md)，可运行版本是 `examples/08-cpp-bindings` 第 12 节。

### 本机验证状态

| 结论 | 通道 | 复现方式 |
|---|---|---|
| `cl2.hpp` / `opencl.hpp` 不存在，只有 `cl.hpp` | 主机编译级 | `tools/cpp-header-probe\build.ps1`，变体 5、6、7 |
| 版本宏不一致 → 42 错 / 34 个未声明标识符 | 主机编译级 | 变体 3、4（`-DumpVariant 3` 看完整输出） |
| `MINIMUM=120` → 12 个 `getContextPlatformVersion` 错误 | 主机编译级 | 变体 11、12 |
| 老宏名仍然生效 | 主机编译级 | 变体 2、3、4 |
| 关异常后 `cl::Error` 不存在 | 主机编译级 | 变体 9、10 |
| `C4996` 需要"MINIMUM ≤ 220"与"cl.h 先包含"同时成立 | 主机编译级 | 变体 7、13、14、15 |
| 三个构建选项字符串 `-cl-std=CL2.0` / `''` / `-cl-std=CL1.2` | 运行时数值级 | `build.ps1 -Examples 08-cpp-bindings` |
| `retainObject` 的引用计数序列 | 运行时数值级 | 同上，第 11 节 |
| 1024/1024 元素正确、profiling 时间戳单调 | 运行时数值级 | 同上 |
| IL 构造函数：`errHandler` 先抛，`*err` 出参从不被写（哨兵 `12345` 原封不动） | 主机编译级 + 运行时数值级 | `build.ps1 -Examples 08-cpp-bindings`，第 12 节；完整拆解见 [08 篇 §8.9](./08-spirv.md) |
| `clSetEventCallback` 未弃用，且 `C4996` 与用户回调无关 | 主机编译级 | 变体 16、17（17 的 `Forbid` 里排除了 `clSetEventCallback`）；另见 `cl.h:1479-1485` 的 `CL_API_SUFFIX__VERSION_1_1` |
| lambda 回调在 x86 上同样编译通过；`CL_CALLBACK` 两种包含顺序下都是 `__stdcall` | 主机编译级（x86 + x64 各一遍） | `vcvars32` 下重编变体 16、17；`CL_CALLBACK` 展开值用 `#pragma message` + 字符串化直接打印 |
| OpenGL 互操作的全部结论 | **文档核对，本机不可验证** | 见 7.9 诚实边界 |

---

上一篇：[06-kernel-programming.md](./06-kernel-programming.md) ｜ 下一篇：[08-spirv.md](./08-spirv.md) —— SPIR-V 离线编译链路：`clang -target spirv64-unknown-unknown`、`clCreateProgramWithIL`、本机三设备的 IL 支持实测，以及为什么 clang 产出的 SPIR-V 1.4 能被只广告 1.2 的 UHD 630 接受。
