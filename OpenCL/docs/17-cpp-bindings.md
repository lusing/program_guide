# 17 · C++ 绑定：opencl.hpp 的 RAII、异常与惯用法

> 对应示例 `examples/17_cpp_vecadd/main.cpp`。参照 OiA 第 8 章（Development with C++）。头文件 vendor 在 `examples/common/CL/opencl.hpp`（Khronos OpenCL-CLHPP main 分支）。

## 17.1 三代头文件别拿错

| 头文件 | 年代 | 说明 |
|---|---|---|
| `CL/cl.hpp` | 1.1/1.2 | 元老，CUDA 还附带（目标 2.0 的旧版） |
| `CL/cl2.hpp` | 2.x | 曾用名，已改 |
| **`CL/opencl.hpp`** | 现在 | 唯一推荐；单头、header-only、需要 C++11+ |

开启姿势（示例 17 的四行宏）：

```cpp
#define CL_HPP_TARGET_OPENCL_VERSION 300      // 目标 API 版本（≤ 头文件的 cl.h）
#define CL_HPP_MINIMUM_OPENCL_VERSION 120     // 最低兼容（允许暴露的最老 API）
#define CL_HPP_ENABLE_EXCEPTIONS              // cl::Error 异常体系
#include <CL/opencl.hpp>
```

> 版本组合错了会得到宏告警或编译错误。`CL_HPP_ENABLE_EXCEPTIONS` 不开的话错误走返回码（更啰嗦）。

## 17.2 C API → C++ 的机械对应

| C | C++ |
|---|---|
| `cl_context` + `clCreateContext` + `clReleaseContext` | `cl::Context`（构造即建，析构即放） |
| `cl_command_queue` | `cl::CommandQueue` |
| `cl_mem`（buffer） | `cl::Buffer` |
| `cl_program` / `cl_kernel` | `cl::Program` / `cl::Kernel` |
| `cl_event` | `cl::Event` |
| `cl_sampler` | `cl::Sampler` |
| `clGetDeviceInfo(dev, CL_DEVICE_NAME, ...)` | `dev.getInfo<CL_DEVICE_NAME>()`（直接返回 `std::string` 等） |

类型只是 C 句柄的强类型包装（`cl::Buffer` 可隐式转回 `cl_mem`），**零抽象税**。

## 17.3 惯用法速览（示例 17 全部出现）

```cpp
std::vector<cl::Platform> platforms;
cl::Platform::get(&platforms);                       // 平台枚举

cl::Context context(device);                         // 单设备上下文
cl::CommandQueue queue(context, device, CL_QUEUE_PROFILING_ENABLE);

std::vector<std::string> src{ K_SRC };
cl::Program program(context, src);                   // 源码构造
program.build(device);                               // 失败抛异常前可拿 build log：
// program.getBuildInfo<CL_PROGRAM_BUILD_LOG>(device)

cl::Buffer bx(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
              N * sizeof(float), hx.data());
kernel.setArg(0, bx);                                // 注意：传对象，不是 &bx
kernel.setArg(2, 3.0f);                              // 标量直接给值

queue.enqueueNDRangeKernel(kernel, cl::NullRange,
                           cl::NDRange(N), cl::NullRange, nullptr, &ev);
queue.enqueueReadBuffer(by, CL_TRUE, 0, bytes, hout.data());

cl_ulong t0 = ev.getProfilingInfo<CL_PROFILING_COMMAND_START>();   // 模板化剖析
```

`cl::NullRange`（偏移）/`cl::NDRange(N)`（全局）/`cl::NullRange`（local）对应 `clEnqueueNDRangeKernel` 的三个尺寸参数。

子缓冲区与映射：

```cpp
cl::Buffer bsub = by.createSubBuffer(CL_MEM_READ_WRITE,
                                     CL_BUFFER_CREATE_TYPE_REGION, &region);
float* mapped = (float*)queue.enqueueMapBuffer(bsub, CL_TRUE, CL_MAP_READ, 0, bytes);
queue.enqueueUnmapMemObject(bsub, mapped);
```

## 17.4 错误处理：cl::Error

```cpp
try {
    ...
} catch (const cl::Error& e) {
    fprintf(stderr, "cl::Error %s (%d)\n", e.what(), e.err());   // what=调用点字符串，err=错误码
}
```

`e.what()` 是出错的表达式/函数名，`e.err()` 是 `cl_int`——比 C 的 `CL_CHECK` 宏省掉一整层样板。混合代码里 `CL_CHECK`（17 章之前的示例）与异常体系可以共存。

## 17.5 什么时候值得用 C++ 绑定

| 场景 | 建议 |
|---|---|
| 主机端工程代码 | **用**——RAII 把 20 行清理代码变 0 行，泄漏面直接消失 |
| 学 OpenCL 概念 | 先过一遍 C API（03–16 章），知道包装层下面是什么 |
| 老引擎/纯 C 工程 | C API + `CL_CHECK` |
| C++ 但想要更高层 | 直接上 SYCL（32 章） |

实测示例输出（C++ 版 saxpy + 剖析 + 子缓冲区 map）：

```
device : NVIDIA GeForce RTX 3060 (OpenCL 3.0 CUDA)
kernel : 0.007 ms (profiling)
saxpy  : verified (spot y[7]=8.75 expect 8.75)
map    : first 32768 values match (0.00)
17 cpp_vecadd PASS
```

> 下一章：[18 归约](18-reduction.md)——两阶段树形归约与向量化实测。
