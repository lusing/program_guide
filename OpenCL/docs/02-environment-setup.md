# 2. 环境准备：运行时、SDK、工程配置

OpenCL 在 Windows 上的环境配置比大多数技术都容易出错，原因很简单：**运行你的程序的东西，和编译你的程序的东西，来自两个不同的来源，而且谁也不检查对方。** 编译时你链接的是某个 SDK 里的 `OpenCL.lib`，运行时加载的是各厂商驱动里的 ICD。两者的版本可以差得很远，而链接器不会告诉你。

这一篇把本机真实的环境逐项列出来，讲清楚每一样东西在哪、怎么让构建脚本自己找到它，以及 `CL_TARGET_OPENCL_VERSION` 这个宏为什么必须设成 300。

> **验证方式说明**：本篇的路径、DLL 版本、注册表内容、CMake 输出全部是 2026-09-17 在本机实测的，不是从文档抄的。`CL_TARGET_OPENCL_VERSION=120` 导致编译失败一节附了完整的 cl.exe 输出与退出码，属于**主机编译级**证据；CMake 一节做到了 configure → build → 运行 → 打印 `numPlatforms = 3` 的完整闭环，属于**运行时级**证据。文中所有失效路径（`C:\Program Files (x86)\Intel\OpenCL SDK\21.12.20446\`、`G:\cuda\v13.3\`）已删除。

## 2.1 三样东西，缺一不可

| 组件 | 作用 | 谁提供 | 本机位置 |
|------|------|--------|---------|
| **OpenCL 运行时** | 真正执行你的内核 | 硬件厂商驱动 + Khronos ICD 加载器 | `C:\Windows\System32\OpenCL.dll` + 各厂商 ICD |
| **开发头文件** | `CL/cl.h` 等，声明 API 与常量 | CUDA Toolkit 或 oneAPI | `D:\cuda\13.3\include\CL\` |
| **导入库** | `OpenCL.lib`，链接期解析符号 | 同上 | `D:\cuda\13.3\lib\x64\OpenCL.lib` |

头文件和导入库可以来自**任何** SDK——它们只是声明，不含实现。运行时才是真正干活的那一方，而它由驱动决定。这个分离带来一个很实际的后果：

> 你用 CUDA 13.3 的头文件编译出来的程序，完全可以跑在 Intel 核显上。本教程就是这么做的。

### 2.1.1 ICD：运行时是怎么被找到的

`C:\Windows\System32\OpenCL.dll` 不是任何厂商的实现，它是 **Khronos 的 ICD 加载器**（Installable Client Driver loader）。本机实测：

```text
FileVersion     : 3.0.6.0
CompanyName     : Khronos Group
FileDescription : OpenCL Client DLL
```

你的程序链接 `OpenCL.lib`，运行时加载 `OpenCL.dll`，然后这个加载器去注册表找各厂商的 ICD，把它们提供的平台拼成一个列表交给你。

**注意 `OpenCL.dll` 不需要、也不应该被加进 `PATH`。** 它在 `System32` 里，本来就在搜索路径上。一些资料会把 `C:\Windows\System32\OpenCL.dll` 当成一条 PATH 配置项列出来——那是把"文件在哪"和"要往 PATH 里加什么"混为一谈了。

## 2.2 本机运行时实况：注册表说的和设备列表说的不一致

`HKLM\SOFTWARE\Khronos\OpenCL\Vendors` 里只登记了**一个** ICD：

```text
D:\oneAPI\compiler\2025.3\bin\intelocl64.dll    REG_DWORD    0x0
```

`HKLM\SOFTWARE\WOW6432Node\Khronos\OpenCL\Vendors` 与 `HKCU\SOFTWARE\Khronos\OpenCL\Vendors` 都不存在。但 `clGetPlatformIDs` 返回的是**三个**平台，其中包括 NVIDIA CUDA。NVIDIA 的 ICD 实际躺在驱动仓库里，根本不在 `System32`：

```text
C:\Windows\System32\DriverStore\FileRepository\nvcvi.inf_amd64_c50a3f34a3a4ced8\nvopencl64.dll
C:\Windows\System32\DriverStore\FileRepository\nvcvi.inf_amd64_c50a3f34a3a4ced8\nvopencl32.dll
```

这条观察的可迁移结论是：

> **不要通过读注册表来判断本机有哪些 OpenCL 设备。** 注册表只是 ICD 发现机制的一部分，不是全部。唯一可靠的办法是在运行时调 `clGetPlatformIDs` / `clGetDeviceIDs` 去枚举——这正是 `tools/clinfo-probe/` 存在的原因。

顺带说清一件事：Intel 的**一个** `intelocl64.dll` 同时提供了本机的 Platform 1（核显）和 Platform 2（CPU）。所以"三个平台"不等于"三个 ICD"。

### 2.2.1 各厂商运行时的获取方式

| 厂商 | 运行时来源 |
|------|-----------|
| **Intel** | [Intel CPU Runtime for OpenCL Applications](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-cpu-runtime-for-opencl-applications.html)；核显部分随 [Intel 显卡驱动](https://www.intel.com/content/www/us/en/download-center/home) 一起装，或随 oneAPI |
| **NVIDIA** | 随 [NVIDIA 显卡驱动](https://www.nvidia.com/Download/index.aspx) 一起装（不需要装 CUDA Toolkit 就能跑 OpenCL） |
| **AMD** | 随 [AMD Adrenalin 驱动](https://www.amd.com/en/support) 一起装 |

装完之后不要靠第三方工具去猜，直接跑本仓库的探针：

```powershell
cd tools\clinfo-probe
.\build.ps1
```

它会编译并运行 `clinfo-probe.exe`，打印出 [01 篇 1.5 节](./01-opencl-overview.md#15-本机实测基线)那张表。外部工具（如 [clinfo](https://github.com/Oblomov/clinfo)）当然也能用，但仓库自带探针的好处是：它的输出格式就是本教程引用的格式，读者复现出来的东西和正文逐字对得上。

## 2.3 本机的 SDK 布局

本机装了不止一套 OpenCL SDK，而且它们的目录结构**不一样**。这个差异会让"照着文档配路径"直接失败：

| SDK 根目录 | `include\CL\cl.h` | `include\CL\cl.hpp` | 导入库位置 | 说明 |
|-----------|:---:|:---:|-----------|------|
| `D:\cuda\13.3` | ✅ | ✅ | `lib\x64\OpenCL.lib` | CUDA 13.3.1，**本教程默认使用** |
| `D:\scoop\apps\cuda\current` | ✅ | ✅ | `lib\x64\OpenCL.lib` | 也是 13.3.1，`cl.h` 与上一行 **MD5 相同**；`$env:CUDA_PATH` 指向它 |
| `D:\oneAPI\compiler\latest` | ✅ | ❌ | `lib\OpenCL.lib`（**没有 x64 子目录**） | 提供 `clang.exe` / `llvm-spirv.exe`，SPIR-V 那一章用它 |

三点值得记住：

1. **CUDA 把导入库放在 `lib\x64`，oneAPI 直接放在 `lib`。** 构建脚本必须两个都探。
2. **oneAPI 的 `include\CL\` 里没有 C++ 绑定头文件**，只有 `sycl.hpp`。`cl.hpp` 只存在于 CUDA 那边。这就是 [07 篇](./07-cpp-bindings.md) 和 `examples/08-cpp-bindings/` 必须用 CUDA SDK 编译的原因——不是偏好，是唯一可行。
3. **`<CL/cl2.hpp>` 和 `<CL/opencl.hpp>` 在本机两个 SDK 里都不存在。** 只有 `<CL/cl.hpp>`。07 篇会讲清这三个名字的沿革，以及为什么本教程统一用 `cl.hpp`。

CUDA SDK 的 `include\CL\` 完整内容：

```text
cl.h          cl_d3d10.h      cl_d3d11.h      cl_d3d11_ext.h  cl_d3d10_ext.h
cl.hpp        cl_dx9_media_sharing.h          cl_egl.h        cl_ext.h
cl_gl.h       cl_gl_ext.h     cl_platform.h   cl_version.h    opencl.h
```

### 2.3.1 已删除的失效路径

原始资料里出现过下面这些路径，本机**全部不存在**，已在教程中删除：

```text
C:\Program Files (x86)\Intel\OpenCL SDK\21.12.20446\include      ← 不存在
C:\Program Files (x86)\Intel\OpenCL SDK\21.12.20446\lib\x64      ← 不存在
C:\Program Files (x86)\Intel\Intel(R) CPU Performance Libraries\  ← 不存在
G:\cuda\v13.3\                                                    ← 不存在
```

Intel 早在 oneAPI 之前就停止发布独立的 "OpenCL SDK" 安装包了。教程里写死带版本号的厂商路径，注定会在下一次驱动更新后失效——这也是本仓库改用**自动发现**的原因，见 2.4。

## 2.4 自动发现：`tools/opencl-sdk.ps1`

所有构建脚本（根 `build.ps1`、`build-spirv.ps1`、两个探针的 `build.ps1`）都点源同一个文件，SDK 搜索顺序只写在一处：

```powershell
# Find an OpenCL SDK: a directory holding both include\CL\cl.h and an OpenCL.lib.
function Find-OpenCLSDK {
    $roots = @()
    if ($env:OPENCL_ROOT) { $roots += $env:OPENCL_ROOT }
    $roots += 'D:\cuda\13.3'
    if ($env:CUDA_PATH) { $roots += $env:CUDA_PATH }
    $roots += 'D:\oneAPI\compiler\latest'

    foreach ($root in $roots) {
        if (-not $root -or -not (Test-Path $root)) { continue }
        $include = Join-Path $root 'include'
        if (-not (Test-Path (Join-Path $include 'CL\cl.h'))) { continue }
        foreach ($libRel in @('lib\x64', 'lib')) {
            $lib = Join-Path $root $libRel
            if (Test-Path (Join-Path $lib 'OpenCL.lib')) {
                return [pscustomobject]@{ Root = $root; Include = $include; Lib = $lib }
            }
        }
    }

    $msg = @(
        'No OpenCL SDK found. Probed these roots for include\CL\cl.h + OpenCL.lib:'
        ($roots | ForEach-Object { "  - $_" })
        'Set $env:OPENCL_ROOT to an SDK root, or install the CUDA Toolkit / Intel oneAPI.'
    ) -join "`n"
    throw $msg
}
```

设计上的三个决定：

- **`$env:OPENCL_ROOT` 排第一**，让读者能在不改脚本的情况下覆盖。
- **两种 lib 布局都探**（`lib\x64` 与 `lib`），因为 2.3 节说了 CUDA 和 oneAPI 不一样。
- **找不到就抛异常并列出所有探过的路径**，绝不静默失败。一条"No OpenCL SDK found"配上候选列表，比一个莫名的链接错误有用得多。

MSVC 环境用 vswhere 定位，和 `WinUI3/build.ps1` 找 MSBuild 是同一套写法：

```powershell
function Find-VcVars64 {
    $vswhere = 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe'
    if (Test-Path $vswhere) {
        $installPath = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath 2>$null |
            Select-Object -First 1
        if ($installPath) {
            $candidate = Join-Path $installPath 'VC\Auxiliary\Build\vcvars64.bat'
            if (Test-Path $candidate) { return $candidate }
        }
    }
    throw 'vcvars64.bat not found; install Visual Studio with the "Desktop development with C++" workload.'
}
```

本机实测解析结果：

```text
vcvars64   d:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat
OpenCL SDK D:\cuda\13.3
  include  D:\cuda\13.3\include
  lib      D:\cuda\13.3\lib\x64
clang      D:\oneAPI\compiler\latest\bin\compiler\clang.exe
```

## 2.5 Visual Studio 工程配置

如果要手工配一个 VS 工程（而不是用本仓库的 `build.ps1`），需要三处设置：

**C/C++ → 常规 → 附加包含目录**

```text
D:\cuda\13.3\include
```

**C/C++ → 预处理器 → 预处理器定义**

```text
CL_TARGET_OPENCL_VERSION=300
_CRT_SECURE_NO_WARNINGS
```

**链接器 → 常规 → 附加库目录**

```text
D:\cuda\13.3\lib\x64
```

**链接器 → 输入 → 附加依赖项**

```text
OpenCL.lib
```

就这些。**不需要**配置任何运行时 DLL 路径——`OpenCL.dll` 在 `System32`，Windows 自己会找到它。

## 2.6 `CL_TARGET_OPENCL_VERSION`：为什么必须是 300

这个宏是本教程踩得最实的一个坑，因为它造成的失败**看起来很不像版本问题**。

原始资料把工程钉在 `CL_TARGET_OPENCL_VERSION=120`（意思是"我要兼容到 OpenCL 1.2"），然后在正文里教读者用 `clCreateCommandQueueWithProperties`（2.0 API）和 `clCreateProgramWithIL`（2.1 API）。这两件事互相矛盾。实测把同一段代码分别用 120 和 300 编一遍：

```c
#ifndef CL_TARGET_OPENCL_VERSION
#define CL_TARGET_OPENCL_VERSION 300
#endif
#include <CL/cl.h>

int main(void) {
    cl_context ctx = NULL;
    cl_device_id dev = NULL;
    cl_int err = CL_SUCCESS;
    cl_queue_properties props[] = {
        CL_QUEUE_PROPERTIES,
        (cl_queue_properties)(CL_QUEUE_PROFILING_ENABLE),
        0
    };
    cl_command_queue q = clCreateCommandQueueWithProperties(ctx, dev, props, &err);
    printf("%p %d\n", (void*)q, err);
    return 0;
}
```

**`/DCL_TARGET_OPENCL_VERSION=120` —— cl.exe 退出码 2：**

```text
h1_queueprops_target120.c
.\h1_queueprops_target120.c(22): error C2065: “cl_queue_properties”: 未声明的标识符
.\h1_queueprops_target120.c(22): error C2146: 语法错误: 缺少“;”(在标识符“props”的前面)
.\h1_queueprops_target120.c(22): error C2065: “props”: 未声明的标识符
.\h1_queueprops_target120.c(22): error C2059: 语法错误:“]”
.\h1_queueprops_target120.c(27): warning C4013: “clCreateCommandQueueWithProperties”未定义；假设外部返回 int
.\h1_queueprops_target120.c(27): error C2065: “props”: 未声明的标识符
.\h1_queueprops_target120.c(27): warning C4047: “初始化”:“cl_command_queue”与“int”的间接级别不同
cl.exe exit code = 2
```

**`/DCL_TARGET_OPENCL_VERSION=300` —— cl.exe 退出码 0，零警告。**

### 2.6.1 真正危险的不是那几个 error，是那条 warning

注意 `C4013`：

```text
warning C4013: “clCreateCommandQueueWithProperties”未定义；假设外部返回 int
```

MSVC 对**未声明的函数**只给警告，然后假设它返回 `int`。真正让编译失败（C2065）的是缺失的**类型** `cl_queue_properties`。也就是说：

> 如果你的代码里没有用到 2.0 才引入的类型，只调了 2.0 才引入的**函数**，那么在 `CL_TARGET_OPENCL_VERSION=120` 下它**能编译通过**，然后在 64 位上把一个指针截断成 int 返回，运行时炸在一个和版本毫无关系的地方。

`C4047` 那条警告（"间接级别不同"）就是截断正在发生的信号。看到 `C4013` + `C4047` 这个组合，先查 `CL_TARGET_OPENCL_VERSION`。

### 2.6.2 300 不等于"我要写 3.0 的内核"

这一点和 [01 篇 1.4 节](./01-opencl-overview.md#14-三个版本字符串问的根本不是同一件事)呼应：`CL_TARGET_OPENCL_VERSION` 是**主机侧**的宏，控制头文件暴露哪些 API 声明。它和**内核**能写什么毫无关系——后者由设备的 `CL_DEVICE_OPENCL_C_VERSION` 和运行时编译器的 `-cl-std` 决定。

本教程的组合是：

| 旋钮 | 取值 | 含义 |
|------|------|------|
| `CL_TARGET_OPENCL_VERSION` | **300** | 主机代码可以调用全部 API，包括 2.1 的 `clCreateProgramWithIL` |
| 内核语言目标 | **OpenCL C 1.2** | 三台设备都能编，可移植性最好 |
| `-cl-std=CL2.0` | 仅在确实需要 2.x 特性时显式传 | 见 [01 篇 1.6.1](./01-opencl-overview.md#161-cl_device_opencl_c_version-是默认值不是天花板) |

`examples/common/ocl_util.h` 里用了 `#ifndef` 守卫，这样构建脚本的 `/D` 能覆盖它，而单独编译时又有合理默认值：

```c
// 300, not 120: at 120 the headers hide every 2.x entry point, so
// clCreateCommandQueueWithProperties and clCreateProgramWithIL do not even
// compile. See docs/02-environment-setup.md.
#ifndef CL_TARGET_OPENCL_VERSION
#define CL_TARGET_OPENCL_VERSION 300
#endif
```

**这个 `#ifndef` 不是可有可无的。** 本节上面那次实测的第一版 fixture 就漏了它——文件里无条件 `#define CL_TARGET_OPENCL_VERSION 120`，于是 `/D300` 被文件内的定义覆盖（MSVC 报 `C4005` 宏重定义），两次编译**都**失败了，看起来像"300 也没用"。纯粹是 fixture 的 bug。写这类对照实验时，先确认你以为在改的那个旋钮真的被改到了。

### 2.6.3 C++ 侧必须同步：`CL_HPP_TARGET_OPENCL_VERSION`

用 `cl.hpp`（见 [07 篇](./07-cpp-bindings.md)）时，还有第二个宏，而且**两者的值必须一致**。根 `build.ps1` 里的实际写法：

```powershell
# C++ examples use the Khronos bindings header. CL_HPP_TARGET_OPENCL_VERSION MUST
# match CL_TARGET_OPENCL_VERSION: cl.hpp gates its declarations on the former, so
# a mismatch leaves CL_DEVICE_QUEUE_ON_HOST_PROPERTIES, CL_DEVICE_SVM_CAPABILITIES
# and 40 other identifiers undefined and the compile explodes.
#
# CL_HPP_MINIMUM_OPENCL_VERSION must be 200 here, NOT 120. cl.hpp defines
# detail::getContextPlatformVersion under "TARGET >= 120 && MINIMUM < 120" but calls
# it from six sites under "TARGET >= 200 && MINIMUM < 200", so 120 is the single
# value where the calls survive and the definition does not: 12 errors, C2039 and
# C3861 per call site. Measured by tools/cpp-header-probe variants 11 and 12.
#
# 300 would also compile, and would additionally drop cl.hpp's deprecated 2.2
# wrappers - but it would restrict this tutorial to 3.0-only devices, so 200 stays.
# The C4996 those wrappers provoke is avoided by include order instead: cl.hpp must
# be included before anything that pulls in <CL/cl.h>. Variants 7 and 14.
$cppExtra = @(
    '/DCL_HPP_ENABLE_EXCEPTIONS',
    '/DCL_HPP_TARGET_OPENCL_VERSION=300',
    '/DCL_HPP_MINIMUM_OPENCL_VERSION=200'
)
```

三个宏，两条规则，都是**主机编译级**实测出来的（`tools/cpp-header-probe`，变体 3、4、11、12）。

#### 规则一：`CL_TARGET_OPENCL_VERSION` 与 `CL_HPP_TARGET_OPENCL_VERSION` 不一致就会炸，而且报错不提版本

`cl.hpp` 用自己的 `CL_HPP_*` 宏门控声明，而 C 头文件用 `CL_TARGET_OPENCL_VERSION` 门控同一批 token。C++ 侧要 3.0、C 侧只给 1.2 时，`cl.hpp` 照常展开 2.x 的声明列表，`cl.h` 却把那些 token 全藏了起来。实测（变体 3、4，`CL_TARGET=120` + `CL_HPP_TARGET=300`）：

```text
D:\cuda\13.3\include\CL/cl.hpp(1629): error C2065: “CL_DEVICE_QUEUE_ON_HOST_PROPERTIES”: 未声明的标识符
D:\cuda\13.3\include\CL/cl.hpp(1629): error C2065: “CL_DEVICE_QUEUE_ON_DEVICE_PROPERTIES”: 未声明的标识符
...
D:\cuda\13.3\include\CL/cl.hpp(1632): fatal error C1003: 错误计数超过 100；正在停止编译
```

| 实测项 | 数值 |
|---|---|
| `error C` 行总数 | **42** |
| 其中 `C2065`（未声明的标识符） | **34** |
| 第一个缺失的标识符 | `CL_DEVICE_QUEUE_ON_HOST_PROPERTIES`（不是 `CL_DEVICE_SVM_CAPABILITIES`，后者也在 34 个里） |
| 34 个错误来自几行 `cl.hpp` | **2 行**：1629 和 1632 |

**34 是下限，不是全量。** `C1003` 说明 MSVC 在错误计数超过 100 时主动停止编译——它停在 1632 行，也就是 `cl.hpp:1634` 的 2.2 列表和后面的 3.0 列表**都还没展开**。真实缺失数量比 34 多，但无法在本机测出，因为编译器不肯继续。

为什么两行能炸出 34 个错误：`cl.hpp:1622-1633` 是 X-macro 展开，每行把一个版本的全部 `param_traits` 特化一次性铺开。

```cpp
#if CL_HPP_TARGET_OPENCL_VERSION >= 200
CL_HPP_PARAM_NAME_INFO_2_0_(CL_HPP_DECLARE_PARAM_TRAITS_)   // <- 1629，一行 = 一批标识符
#endif
```

门控条件是 `CL_HPP_TARGET_OPENCL_VERSION`，展开出来的 token 却由 `CL_TARGET_OPENCL_VERSION` 决定是否存在。两个宏一错开，一行就是一批错误。

**`cl.hpp` 不会替你修正这个不一致**，只会打印一句 `#pragma message`（`cl.hpp:452-461`）：

```cpp
#if defined(CL_TARGET_OPENCL_VERSION)
#if CL_TARGET_OPENCL_VERSION < CL_HPP_TARGET_OPENCL_VERSION
# pragma message("CL_TARGET_OPENCL_VERSION is already defined as is lower than CL_HPP_TARGET_OPENCL_VERSION")
#endif
#else
# define CL_TARGET_OPENCL_VERSION CL_HPP_TARGET_OPENCL_VERSION
#endif
```

注意 `#else` 分支：**没定义时它会替你定义成一致的值**。所以最省事的写法不是"把两个宏调成一样"，而是——用 `cl.hpp` 的翻译单元里干脆别定义 `CL_TARGET_OPENCL_VERSION`。`examples/common/ocl_util.h` 那个 `#ifndef` 之所以重要，也正是因为它让"先包含 `cl.hpp`"这条路走得通。

顺便澄清一个流传很广的误判：炸出这一堆错误的**不是**老式宏名 `__CL_ENABLE_EXCEPTIONS`。`cl.hpp:403-405` 把它映射到 `CL_HPP_ENABLE_EXCEPTIONS` 并附一条弃用 `#pragma message`，功能是**照旧生效**的。实测（变体 2 对 3，同一个老宏名，只改 `CL_TARGET_OPENCL_VERSION`）：

| 变体 | 异常宏 | `CL_TARGET` | 结果 |
|---|---|---|---|
| 2 | `__CL_ENABLE_EXCEPTIONS`（老名） | 300 | 编译通过，只有弃用提示 |
| 3 | `__CL_ENABLE_EXCEPTIONS`（老名） | 120 | 42 个错误 |
| 4 | `CL_HPP_ENABLE_EXCEPTIONS`（新名） | 120 | 42 个错误，与变体 3 完全相同 |

变体 3 和 4 的唯一差别是宏名，错误一模一样。**决定成败的是那对版本宏，不是异常宏的名字。** 建议仍然用新名字（老名字会打印弃用提示），但把它当成故障原因会把你引向完全错误的方向。

#### 规则二：`CL_HPP_MINIMUM_OPENCL_VERSION` 不能填 120

这是 `cl.hpp` 自身的一处**门控缝隙**，本机版本上 `120` 恰好是唯一编译不过的取值。`detail::getContextPlatformVersion` 定义在 `cl.hpp:2089-2139` 这个块里（函数本体 2127 行），一共有 **8 处调用**，分属两组门控：

| 位置 | 门控条件 | `TARGET=300, MINIMUM=120` |
|---|---|---|
| 定义处 `cl.hpp:2089` | `TARGET >= 120 && MINIMUM < 120` | **假** → 不定义 |
| 2 处 `Image` 构造，门控在 `cl.hpp:5003`、5347 | `TARGET >= 120 && MINIMUM < 120` | **假** → 一起消失，无害 |
| 6 处 `CommandQueue` 构造，门控在 `cl.hpp:7184`、7250、7315、7382、7433、7484 | `TARGET >= 200 && MINIMUM < 200` | **真** → 要调用 |

`Image` 那两处的门控与定义处**完全一致**，所以它们跟着一起被排除，不出问题。出问题的是 `CommandQueue` 那六处：门控写的是 `< 200` 而不是 `< 120`。`MINIMUM=120` 满足 `< 200`，不满足 `< 120`——正好落进两个条件的差集里。

于是 `getContextPlatformVersion` 被调用六次、定义零次，得到 **12** 个错误（每个调用点 `C2039` + `C3861`，调用行在 7187、7253、7318、7385、7436、7487）：

```text
D:\cuda\13.3\include\CL/cl.hpp(7187): error C2039: “getContextPlatformVersion”: 不是“cl::detail”的成员
D:\cuda\13.3\include\CL/cl.hpp(7187): error C3861: “getContextPlatformVersion”: 找不到标识符
```

对照实验（变体 11、12）：`MINIMUM=110` 同时满足两个门控（`< 120` 且 `< 200`），编译通过；`MINIMUM=200` 两个门控都不满足，也编译通过。**只有 120 落在缝里。**

这个错误特别容易误判成"我的代码写错了"或"这个设备不支持"——它报的是 `cl.hpp` 内部符号找不到，而 `cl.hpp` 是官方头文件。

> `CL_HPP_MINIMUM_OPENCL_VERSION` 的默认值是 **200**（`cl.hpp:463-465`）。也就是说**不定义它**反而是安全的；显式写 `120` 才是把自己推进缝里。根 `build.ps1` 显式写 `200`，与默认值一致，只是为了把这个决定留在明面上。

> **诚实边界**：`120` 这个缝隙是本机 `D:\cuda\13.3\include\CL\cl.hpp` 上的实测结果，不是 OpenCL 规范的条款。换一份 `cl.hpp`（尤其是从 KhronosGroup/opencl-headers 取的新版）可能已经修好，也可能仍在。`tools/cpp-header-probe` 存在的意义就是让这条结论可重跑：换头文件之后跑一遍，17 个变体里哪个翻车一目了然。

### 2.6.4 本机 `cl.hpp` 的另一个坑：`generic` 是保留字

顺带记一条属于**内核编译级**的陷阱，因为它和"环境"一样属于"你查不到、只能撞上"的类别：

`generic` 是 OpenCL C 的保留关键字。把一个变量命名为 `generic` 会得到

```text
error: expected identifier or '('
```

这个报错完全不提关键字冲突，看起来像语法写错了。`tools/cl-build-probe/fixtures/generic_addr.cl` 保留了这个用例。

## 2.7 CMake 配置

`find_package(OpenCL)` 在本机可用，而且**已经跑通到运行**。原始资料给的 `CMakeLists.txt` 有两处要改：`link_directories` 那行注释掉的失效路径要删，以及必须补上 `CL_TARGET_OPENCL_VERSION`——`find_package(OpenCL)` 不会替你定义它。

本机实测可用的版本：

```cmake
cmake_minimum_required(VERSION 3.10)
project(OpenCLDemo C)

find_package(OpenCL REQUIRED)

add_executable(opencl_demo main.c)

# find_package(OpenCL) locates the SDK but does NOT define this macro for you.
# Without it the headers pick their own default and every 2.x entry point stays
# hidden - see docs/02-environment-setup.md section 2.6.
target_compile_definitions(opencl_demo PRIVATE CL_TARGET_OPENCL_VERSION=300)

# Prefer the imported target over ${OPENCL_LIBRARIES}: it carries the include
# directory with it, so no separate include_directories() call is needed.
target_link_libraries(opencl_demo PRIVATE OpenCL::OpenCL)
```

CMake 4.4.3 的 configure 输出（节选）：

```text
-- Looking for include file OpenCL/cl.h
-- Looking for include file OpenCL/cl.h - not found
-- Looking for CL_VERSION_3_0
-- Looking for CL_VERSION_3_0 - found
-- Found OpenCL: D:/scoop/apps/cuda/current/lib/x64/OpenCL.lib (found version "3.0")
-- Configuring done (12.8s)
-- Generating done (0.2s)
```

编译并运行：

```text
main.c
opencl_demo.vcxproj -> ...\build\Release\opencl_demo.exe

clGetPlatformIDs -> 0, numPlatforms = 3
exit=0
```

注意 CMake 找到的是 `D:/scoop/apps/cuda/current`（即 `$env:CUDA_PATH`），而 `build.ps1` 找到的是 `D:\cuda\13.3`。**两者是同一个 CUDA 13.3.1，`cl.h` 的 MD5 完全相同**，所以结果一致。`Looking for include file OpenCL/cl.h - not found` 那行也不是错误——CMake 先试大写 `OpenCL/` 目录名（Linux 惯例），失败后改用 Windows 的 `CL/`，然后在 `CL_VERSION_3_0` 这个符号上确认成功。

## 2.8 项目结构

本仓库的实际布局：

```text
OpenCL/
├── README.md              教程入口、验证状态表、诚实边界
├── build.ps1              编译并运行全部 examples，PASS/FAIL 汇总
├── build-spirv.ps1        离线编译 .cl → .spv（调 oneAPI clang）
├── .gitignore             build/ 等生成物
├── docs/                  十章中文正文
├── examples/
│   ├── common/
│   │   └── ocl_util.h     设备选择、错误码翻译、结果判定的共享头
│   ├── 01-device-query/
│   ├── 02-vector-add/
│   ├── ...                每个目录一个 main.c + 需要时的 kernels/*.cl
│   └── 11-ocl3-features/
└── tools/
    ├── opencl-sdk.ps1     SDK / vcvars / clang 自动发现，被所有脚本点源
    ├── clinfo-probe/      设备元数据级探针
    └── cl-build-probe/    内核编译级探针
```

`build/` 目录是生成物，不入库。每个 example 的内核放在自己的 `kernels/*.cl` 里，由主机程序用相对路径读进来——`build.ps1` 运行示例前会 `Push-Location` 到示例目录，所以相对路径和文档里写的一致。

## 2.9 两个探针工具

本教程的所有能力声明都由这两个工具之一产出。它们对应两条不同的验证通道：

| 工具 | 通道 | 证明什么 | 不证明什么 |
|------|------|---------|-----------|
| `tools/clinfo-probe/` | **设备元数据级** | 平台/设备真实存在；版本、profile、IL 字符串、SVM 位、工作组上限、本地内存类型、扩展列表 | 任何代码能不能编译，任何数值对不对 |
| `tools/cl-build-probe/` | **内核编译级** | 某个 `.cl` 在某台设备上能否**真的编译通过**；驱动的真实构建日志；每个内核的 `CL_KERNEL_WORK_GROUP_SIZE` / `CL_KERNEL_LOCAL_MEM_SIZE` / `CL_KERNEL_PRIVATE_MEM_SIZE` | 内核跑起来数值对不对——那是 `examples/` 的事 |

### 2.9.1 `clinfo-probe`

```powershell
cd tools\clinfo-probe
.\build.ps1              # 编译并运行
.\build.ps1 -SkipRun     # 只编译
```

输出末尾是自带的断言汇总，退出码 0 表示断言全过：

```text
=== summary ===
    platforms                          3
    devices                            3
    devices_with_opencl_c_3_0          1
    gpus_with_il_support               1
    gpus_without_il_support            1
[RESULT] PASS
```

### 2.9.2 `cl-build-probe`

```text
cl-build-probe.exe <kernel.cl> [kernelName] [deviceHint] [buildOptions]
```

`deviceHint` 默认 `UHD`（本机 Intel 核显），传 `NVIDIA`、`i7` 或 `CPU` 可以换目标。设备**按名字匹配、跨全部平台**查找，绝不取 `platforms[0]`。

退出码是有含义的，写断言时要按它来判断：

| 退出码 | 含义 |
|--------|------|
| 0 | 编译通过，内核对象创建成功 |
| 1 | 编译失败，或内核创建失败 |
| 2 | 用法错误 / 文件读不到 / 没有匹配的设备 |

**要证明某个内核会失败**（比如 `__const` 那个反例），就断言退出码是 **1** 并且日志里含预期文本——不要断言退出码 0。`tools/cl-build-probe/fixtures/` 里放了四个固定用例：`matmul_bad.cl`（`__const`，预期失败）、`matmul_good.cl`（`__global const`，预期成功）、`generic_addr.cl`、`subgroup_bcast.cl`。

## 2.10 Windows 命令行陷阱

这一节的每一条都在本次改造中实际撞到过，全都和 OpenCL 无关，但每一条都能让你以为问题出在 OpenCL 上。

### 2.10.1 `.ps1` 必须纯 ASCII

Windows PowerShell 5.1 把**无 BOM** 的 `.ps1` 按 OEM 代码页（本机 cp936）解码。文件里只要有一个中文字符串字面量，就会报：

```text
字符串缺少终止符
```

而且报错位置指向一个和中文毫无关系的行。本仓库的 `build.ps1` 和 `tools/opencl-sdk.ps1` 因此**全部纯 ASCII**，注释也是英文。这不是风格偏好，是 5.1 的解码行为决定的。（用 `pwsh` / PowerShell 7 没这个问题，但脚本要在 5.1 上也能跑。）

### 2.10.2 PowerShell 5.1 会在 `=` 处重新切分参数

把 `-cl-std=CL1.2` 直接交给原生命令时，5.1 会把它拆成 `-cl-std=CL1` 加上一个多余的 `.2` 文件参数。SPIR-V 那条命令因此必须整体交给 `cmd.exe` 执行单个字符串，见 `tools/opencl-sdk.ps1` 里的说明。

### 2.10.3 PowerShell 函数的返回值包含它输出的一切

```powershell
$output = & cmd.exe /c $line 2>&1
$code = $LASTEXITCODE
foreach ($l in $output) { Write-Host $l }
return $code
```

必须**先捕获、再读退出码、最后回显**。如果让 cmd 的 stdout 直接流出去，PowerShell 会把它当成函数返回值的一部分，调用方拿到的 `$code` 就成了 `@(<cl 的输出...>, 0)` 这样一个数组，`"$code -ne 0"` 于是变成字符串比较，判断彻底失效。

### 2.10.4 `.cmd` 辅助脚本必须是 CRLF

LF 结尾的 `.cmd` 会让 cmd.exe 把长命令行切碎，报出类似

```text
'oft' 不是内部或外部命令
```

这种完全看不出原因的话。

### 2.10.5 不要三层嵌套传编译器参数

`bash → powershell → cmd` 三层引号传递没有一次成功过。本仓库统一用 `powershell → cmd` 两层，且调用方传**不加引号**的开关（`"/I$($sdk.Include)"` 这种由 PowerShell 插值出来的除外），由 `Invoke-ClCompile` 统一决定哪里需要引号。在调用点预先加引号会在最终字符串里留下字面反斜杠，cl.exe 会解析错。

### 2.10.6 MSVC 的诊断信息是 cp936

`/utf-8` 只影响**源文件**编码，不影响编译器自己输出的消息语言。本机 MSVC 是中文版，诊断按 cp936 输出。在 Git Bash 里管道给 `iconv -f cp936 -t utf-8` 才能读。2.6 节那段错误输出就是这么解出来的。

## 2.11 上手检查清单

按顺序做完这五步，环境就是好的：

1. `cd tools\clinfo-probe; .\build.ps1` —— 应打印三个平台并以 `[RESULT] PASS` 结束。
2. 对照 [01 篇 1.5 节](./01-opencl-overview.md#15-本机实测基线) 确认你的 `Intel(R) UHD Graphics 630` 那一列：`max_work_group_size = 256`、`local_mem_size = 65536`、`il_version = SPIR-V_1.2`。
3. `cd ..\..; .\build.ps1` —— 编译并运行全部 examples，末尾汇总表应无 FAIL。
4. 只想编不想跑：`.\build.ps1 -SkipRun`。只想跑一个：`.\build.ps1 -Examples 02-vector-add`。
5. 改了代码想强制重编：`.\build.ps1 -Rebuild`。

如果你的机器上设备名不是 `UHD`，改 `examples/common/ocl_util.h` 里的 `OCL_DEFAULT_DEVICE`，或者给 `cl-build-probe` 传 `deviceHint` 参数。**不要**改成取 `platforms[0]`。

---

上一篇：[01-opencl-overview.md](./01-opencl-overview.md) ｜ 下一篇：[03-first-program.md](./03-first-program.md) —— 从零写完第一个向量加法程序，逐行讲清楚每个 API 调用。
