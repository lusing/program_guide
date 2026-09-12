# OpenCL Windows 平台开发教程

本教程介绍如何在 Windows 平台下配置和开发 OpenCL 应用程序。

## 目录

1. [OpenCL 简介](#opencl-简介)
   - [OpenCL 历史和版本](#opencl-历史和版本)
2. [环境准备](#环境准备)
3. [安装 OpenCL 运行时](#安装-opencl-运行时)
4. [开发环境配置](#开发环境配置)
5. [第一个 OpenCL 程序](#第一个-opencl-程序)
6. [OpenCL 编程模型](#opencl-编程模型)
7. [OpenCL 核心概念](#opencl-核心概念)
8. [OpenCL 内核编程](#opencl-内核编程)
9. [OpenCL C++ 编程](#opencl-c++-编程)
10. [使用 SPIR-V 中间语言](#使用-spir-v-中间语言)
11. [OpenCL API 详解](#opencl-api-详解)
12. [常见问题](#常见问题)
13. [调试技巧](#调试技巧)
14. [OpenCL 实用示例](#opencl-实用示例)
15. [参考资源](#参考资源)

---

## OpenCL 简介

OpenCL（Open Computing Language）是一个为异构平台（CPU、GPU、DSP 等）编写程序的开源框架。它允许开发者利用设备的并行计算能力来加速计算密集型任务。

### OpenCL 主要特点

- **跨平台**：支持多种设备和操作系统
- **并行计算**：利用 GPU 等设备的大量计算单元
- **C 语言扩展**：使用类似 C 语言的编程语言（Kernel 语言）

---

## OpenCL 历史和版本

### 发展历程

| 时间 | 事件 |
|------|------|
| 2008-12 | OpenCL 1.0 正式发布 |
| 2010-06 | OpenCL 1.1 发布 |
| 2011-11 | OpenCL 1.2 发布 |
| 2013-11 | OpenCL 2.0 发布（重大更新） |
| 2015-11 | OpenCL 2.1 发布（SPIR-V 支持） |
| 2017-05 | OpenCL 2.2 发布 |
| 2020-09 | OpenCL 3.0 发布（向后兼容） |

### 版本特性对比

#### OpenCL 1.0 (2008)
- 初始版本
- 支持 CPU/GPU 并行计算
- 基本内存对象（Buffer、Image）
- 单命令队列

#### OpenCL 1.1 (2010)
- 添加事件回调机制
- 改进的图像对象支持
- 用户事件（User Events）
- 3D 图像支持

#### OpenCL 1.2 (2011)
- **设备分区**：逻辑分割设备
- **子缓冲区**：创建缓冲区的子区域
- **程序构建缓存**：提升编译性能
- **图像对象改进**：1D/2D 图像数组
- **DX9/DX11 互操作**：媒体共享

#### OpenCL 2.0 (2013) - 重大更新
- **共享虚拟内存（SVM）**：主机与设备共享指针
- **设备端队列**：设备可以入队内核
- **动态并行**：内核启动内核
- **C++ 原子操作**：改进的原子操作
- **管道对象**：设备端通信

#### OpenCL 2.1 (2015)
- **SPIR-V 支持**：中间语言
- **任意尺寸工作组**：移除工作组大小限制
- **设备端图像写入**：Image2D/3D 写支持
- **pipe 对象**：管道对象增强
- **OpenCL C 2.1**：更多内建函数

#### OpenCL 2.2 (2017)
- **OpenCL C++ 内核语言**：C++14 子集
- **SPIR-V 1.1/1.2**：更新中间语言
- **atomic_flag 支持**：原子操作
- **FP16 支持**：半精度浮点
- **IL 程序**：中间语言程序

#### OpenCL 3.0 (2020) - 向后兼容
- **统一扩展框架**：所有功能通过扩展提供
- **向后兼容**：无需支持所有 2.x 功能
- **功能子集**：厂商可选择实现特性
- **OpenCL C 3.0**：与 C17 对齐
- **CL interop**：更好的 Vulkan/DirectX 互操作

### OpenCL 版本演进图

```
OpenCL 1.0 (2008)
      |
      v
OpenCL 1.1 (2010)
      |
      v
OpenCL 1.2 (2011)
      |
      v
OpenCL 2.0 (2013) -----> 共享虚拟内存、设备端队列
      |
      v
OpenCL 2.1 (2015) -----> SPIR-V 支持
      |
      v
OpenCL 2.2 (2017) -----> OpenCL C++ 内核语言
      |
      v
OpenCL 3.0 (2020) -----> 模块化设计、向后兼容
```

### 主要厂商支持状态

| 厂商 | OpenCL 版本 | 备注 |
|------|-------------|------|
| Intel | 3.0 | 通过 oneAPI 支持 |
| AMD | 2.0/3.0 | ROCm 平台支持 2.0，部分 GPU 支持 3.0 |
| NVIDIA | 3.0 | 通过 CUDA Driver 支持 |
| Apple | 1.2 | macOS 已弃用 OpenCL，推荐使用 Metal |

### 如何检查 OpenCL 版本

```c
#include <CL/cl.h>
#include <stdio.h>

int main() {
    cl_uint numPlatforms;
    clGetPlatformIDs(0, NULL, &numPlatforms);

    cl_platform_id platform;
    clGetPlatformIDs(1, &platform, NULL);

    char version[256];
    clGetPlatformInfo(platform, CL_PLATFORM_VERSION, sizeof(version), &version, NULL);
    printf("OpenCL Version: %s\n", version);

    return 0;
}
```

### 版本选择建议

| 场景 | 推荐版本 | 理由 |
|------|----------|------|
| 最大兼容性 | OpenCL 1.2 | 支持最广泛的平台 |
| 新项目 | OpenCL 3.0 | 最新特性，向后兼容 |
| 移动嵌入 | OpenCL ES | 嵌入式优化版本 |
| macOS | Metal | Apple 已弃用 OpenCL |

---

## 环境准备

### 系统要求

- Windows 7 或更高版本（Windows 10/11 推荐）
- 支持 OpenCL 的硬件设备：
  - Intel CPU/GPU（集成显卡）
  - AMD CPU/GPU
  - NVIDIA GPU

### 需要安装的组件

| 组件 | 说明 |
|------|------|
| OpenCL 运行时 | 由硬件厂商提供 |
| 开发头文件 | CL/CL.h 等头文件 |
| 开发库 | OpenCL.lib |

---

## 安装 OpenCL 运行时

### Intel 平台

访问 [Intel CSVAD](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-cpu-runtime-for-opencl-applications.html) 下载 Intel CPU Runtime for OpenCL Applications。

或使用 Intel Graphics Driver（包含 OpenCL 支持）：
- 下载 [Intel Graphics Driver](https://www.intel.com/content/www/us/en/download/725582/intel-arc-graphics-windows-dch-drivers.html)

### AMD 平台

AMD CPU 和 GPU 均自带 OpenCL 支持，通过安装 AMD Drivers 即可。

- 下载 [AMD Adrenalin Driver](https://www.amd.com/en/support)

### NVIDIA 平台

NVIDIA GPU 通过 CUDA Driver 提供 OpenCL 支持。

- 下载 [NVIDIA Driver](https://www.nvidia.com/Download/index.aspx)

> **提示**：安装完成后，可以使用 [clinfo](https://github.com/Oblomov/clinfo) 或 [GPU Caps Viewer](https://www.ozone3d.net/gpu_caps_viewer/) 等 OpenCL 检测工具验证安装。

---

## 开发环境配置

### 使用 Visual Studio 配置工程

#### 1. 创建项目

打开 Visual Studio -> 创建新项目 -> C++ 空项目

#### 2. 配置包含目录

打开项目属性（Alt + F7），配置以下路径：

**C/C++ -> 常规 -> 附加包含目录**：
```
C:\Program Files (x86)\Intel\OpenCL SDK\21.12.20446\include
```

或手动下载 OpenCL 头文件：
- [OpenCL-Headers](https://github.com/KhronosGroup/OpenCL-Headers)

#### 3. 配置库目录

**链接器 -> 常规 -> 附加库目录**：
```
C:\Program Files (x86)\Intel\OpenCL SDK\21.12.20446\lib\x64
```

**链接器 -> 输入 -> 附加依赖项**：
```
OpenCL.lib
```

### 环境变量配置（可选）

将 OpenCL DLL 路径添加到系统 PATH：
```
C:\Windows\System32\OpenCL.dll
```

不同厂商的 OpenCL DLL 位置：
- Intel: `C:\Program Files (x86)\Intel\Intel(R) CPU Performance Libraries\`
- AMD: `C:\Windows\System32\`
- NVIDIA: `C:\Windows\System32\`

---

## 第一个 OpenCL 程序

以下是一个完整的示例程序，实现向量加法。

```c
// opencl_helloworld.c
#include <stdio.h>
#include <stdlib.h>
#include <CL/cl.h>

// 辅助函数：打印错误信息
const char* clErrorString(cl_int error) {
    switch (error) {
        case CL_SUCCESS: return "CL_SUCCESS";
        case CL_DEVICE_NOT_FOUND: return "CL_DEVICE_NOT_FOUND";
        case CL_DEVICE_NOT_AVAILABLE: return "CL_DEVICE_NOT_AVAILABLE";
        case CL_COMPILER_NOT_AVAILABLE: return "CL_COMPILER_NOT_AVAILABLE";
        case CL_MEM_OBJECT_ALLOCATION_FAILURE: return "CL_MEM_OBJECT_ALLOCATION_FAILURE";
        case CL_OUT_OF_RESOURCES: return "CL_OUT_OF_RESOURCES";
        case CL_OUT_OF_HOST_MEMORY: return "CL_OUT_OF_HOST_MEMORY";
        case CL_INVALID_PLATFORM: return "CL_INVALID_PLATFORM";
        case CL_INVALID_DEVICE: return "CL_INVALID_DEVICE";
        case CL_INVALID_CONTEXT: return "CL_INVALID_CONTEXT";
        case CL_INVALID_QUEUE_PROPERTIES: return "CL_INVALID_QUEUE_PROPERTIES";
        case CL_INVALID_WORK_GROUP_SIZE: return "CL_INVALID_WORK_GROUP_SIZE";
        default: return "Unknown error";
    }
}

int main() {
    cl_int err;

    // 第一步：获取平台 ID
    cl_uint numPlatforms = 0;
    err = clGetPlatformIDs(0, NULL, &numPlatforms);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to get number of platforms: %s\n", clErrorString(err));
        return -1;
    }

    printf("Found %d platform(s)\n", numPlatforms);

    if (numPlatforms == 0) {
        printf("Error: No OpenCL platforms found\n");
        return -1;
    }

    cl_platform_id* platforms = (cl_platform_id*)malloc(numPlatforms * sizeof(cl_platform_id));
    err = clGetPlatformIDs(numPlatforms, platforms, NULL);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to get platform IDs: %s\n", clErrorString(err));
        free(platforms);
        return -1;
    }

    // 第二步：查找第一个可用的设备
    cl_uint numDevices = 0;
    cl_device_id* devices = NULL;
    cl_platform_id platform = platforms[0];

    // 打印平台信息
    char platformName[256];
    err = clGetPlatformInfo(platform, CL_PLATFORM_NAME, sizeof(platformName), platformName, NULL);
    if (err == CL_SUCCESS) {
        printf("Platform: %s\n", platformName);
    }

    // 获取设备数量
    err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_ALL, 0, NULL, &numDevices);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to get number of devices: %s\n", clErrorString(err));
        free(platforms);
        return -1;
    }

    printf("Found %d device(s)\n", numDevices);

    devices = (cl_device_id*)malloc(numDevices * sizeof(cl_device_id));
    err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_ALL, numDevices, devices, NULL);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to get device IDs: %s\n", clErrorString(err));
        free(platforms);
        free(devices);
        return -1;
    }

    // 打印设备信息
    for (cl_uint i = 0; i < numDevices; i++) {
        char deviceName[256];
        char vendorName[256];
        cl_uint maxComputeUnits;
        cl_ulong globalMemSize;
        cl_ulong localMemSize;

        clGetDeviceInfo(devices[i], CL_DEVICE_NAME, sizeof(deviceName), deviceName, NULL);
        clGetDeviceInfo(devices[i], CL_DEVICE_VENDOR, sizeof(vendorName), vendorName, NULL);
        clGetDeviceInfo(devices[i], CL_DEVICE_MAX_COMPUTE_UNITS, sizeof(maxComputeUnits), &maxComputeUnits, NULL);
        clGetDeviceInfo(devices[i], CL_DEVICE_GLOBAL_MEM_SIZE, sizeof(globalMemSize), &globalMemSize, NULL);
        clGetDeviceInfo(devices[i], CL_DEVICE_LOCAL_MEM_SIZE, sizeof(localMemSize), &localMemSize, NULL);

        printf("\nDevice %d:\n", i + 1);
        printf("  Name: %s\n", deviceName);
        printf("  Vendor: %s\n", vendorName);
        printf("  Max Compute Units: %u\n", maxComputeUnits);
        printf("  Global Memory: %llu MB\n", (unsigned long long)(globalMemSize / (1024 * 1024)));
        printf("  Local Memory: %llu KB\n", (unsigned long long)(localMemSize / 1024));
    }

    // 第三步：创建上下文
    cl_context context = clCreateContext(NULL, numDevices, devices, NULL, NULL, &err);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to create context: %s\n", clErrorString(err));
        free(platforms);
        free(devices);
        return -1;
    }

    // 第四步：创建命令队列
    // 注意：clCreateCommandQueue 在 OpenCL 2.0 中被弃用，但仍可用于向后兼容
    // OpenCL 2.0+ 推荐使用 clCreateCommandQueueWithProperties
    cl_command_queue cmdQueue = clCreateCommandQueue(context, devices[0], 0, &err);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to create command queue: %s\n", clErrorString(err));
        clReleaseContext(context);
        free(platforms);
        free(devices);
        return -1;
    }

    // 第五步：准备内核代码
    const char* kernelSource =
        "__kernel void vector_add(__global const float* a, "
        "__global const float* b, __global float* c) {"
        "    int idx = get_global_id(0);"
        "    c[idx] = a[idx] + b[idx];"
        "}";

    // 第六步：创建程序对象
    cl_program program = clCreateProgramWithSource(context, 1, &kernelSource, NULL, &err);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to create program: %s\n", clErrorString(err));
        clReleaseCommandQueue(cmdQueue);
        clReleaseContext(context);
        free(platforms);
        free(devices);
        return -1;
    }

    // 第七步：编译程序
    err = clBuildProgram(program, numDevices, devices, NULL, NULL, NULL);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to build program: %s\n", clErrorString(err));

        // 打印编译日志
        size_t logSize;
        clGetProgramBuildInfo(program, devices[0], CL_PROGRAM_BUILD_LOG, 0, NULL, &logSize);
        char* log = (char*)malloc(logSize);
        clGetProgramBuildInfo(program, devices[0], CL_PROGRAM_BUILD_LOG, logSize, log, NULL);
        printf("\nBuild Log:\n%s\n", log);
        free(log);

        clReleaseProgram(program);
        clReleaseCommandQueue(cmdQueue);
        clReleaseContext(context);
        free(platforms);
        free(devices);
        return -1;
    }

    // 第八步：创建内核
    cl_kernel kernel = clCreateKernel(program, "vector_add", &err);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to create kernel: %s\n", clErrorString(err));
        clReleaseProgram(program);
        clReleaseCommandQueue(cmdQueue);
        clReleaseContext(context);
        free(platforms);
        free(devices);
        return -1;
    }

    // 第九步：准备数据
    const int dataCount = 10;
    float* hostA = (float*)malloc(dataCount * sizeof(float));
    float* hostB = (float*)malloc(dataCount * sizeof(float));
    float* hostC = (float*)malloc(dataCount * sizeof(float));

    for (int i = 0; i < dataCount; i++) {
        hostA[i] = (float)i;
        hostB[i] = (float)(i * 2);
    }

    // 第十步：创建缓冲区对象
    cl_mem bufferA = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                     dataCount * sizeof(float), hostA, &err);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to create buffer A: %s\n", clErrorString(err));
        clReleaseKernel(kernel);
        clReleaseProgram(program);
        clReleaseCommandQueue(cmdQueue);
        clReleaseContext(context);
        free(platforms);
        free(devices);
        free(hostA);
        free(hostB);
        free(hostC);
        return -1;
    }

    cl_mem bufferB = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                     dataCount * sizeof(float), hostB, &err);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to create buffer B: %s\n", clErrorString(err));
        clReleaseMemObject(bufferA);
        clReleaseKernel(kernel);
        clReleaseProgram(program);
        clReleaseCommandQueue(cmdQueue);
        clReleaseContext(context);
        free(platforms);
        free(devices);
        free(hostA);
        free(hostB);
        free(hostC);
        return -1;
    }

    cl_mem bufferC = clCreateBuffer(context, CL_MEM_WRITE_ONLY, dataCount * sizeof(float), NULL, &err);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to create buffer C: %s\n", clErrorString(err));
        clReleaseMemObject(bufferA);
        clReleaseMemObject(bufferB);
        clReleaseKernel(kernel);
        clReleaseProgram(program);
        clReleaseCommandQueue(cmdQueue);
        clReleaseContext(context);
        free(platforms);
        free(devices);
        free(hostA);
        free(hostB);
        free(hostC);
        return -1;
    }

    // 第十一步：设置内核参数
    err = clSetKernelArg(kernel, 0, sizeof(cl_mem), &bufferA);
    err |= clSetKernelArg(kernel, 1, sizeof(cl_mem), &bufferB);
    err |= clSetKernelArg(kernel, 2, sizeof(cl_mem), &bufferC);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to set kernel arguments: %s\n", clErrorString(err));
        clReleaseMemObject(bufferA);
        clReleaseMemObject(bufferB);
        clReleaseMemObject(bufferC);
        clReleaseKernel(kernel);
        clReleaseProgram(program);
        clReleaseCommandQueue(cmdQueue);
        clReleaseContext(context);
        free(platforms);
        free(devices);
        free(hostA);
        free(hostB);
        free(hostC);
        return -1;
    }

    // 第十二步：执行内核
    size_t globalWorkSize = dataCount;
    err = clEnqueueNDRangeKernel(cmdQueue, kernel, 1, NULL, &globalWorkSize, NULL, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to execute kernel: %s\n", clErrorString(err));
        clReleaseMemObject(bufferA);
        clReleaseMemObject(bufferB);
        clReleaseMemObject(bufferC);
        clReleaseKernel(kernel);
        clReleaseProgram(program);
        clReleaseCommandQueue(cmdQueue);
        clReleaseContext(context);
        free(platforms);
        free(devices);
        free(hostA);
        free(hostB);
        free(hostC);
        return -1;
    }

    // 第十三步：读取结果
    err = clEnqueueReadBuffer(cmdQueue, bufferC, CL_TRUE, 0, dataCount * sizeof(float), hostC, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to read buffer C: %s\n", clErrorString(err));
        clReleaseMemObject(bufferA);
        clReleaseMemObject(bufferB);
        clReleaseMemObject(bufferC);
        clReleaseKernel(kernel);
        clReleaseProgram(program);
        clReleaseCommandQueue(cmdQueue);
        clReleaseContext(context);
        free(platforms);
        free(devices);
        free(hostA);
        free(hostB);
        free(hostC);
        return -1;
    }

    // 第十四步：输出结果
    printf("\nResults:\n");
    printf("A + B = C\n");
    for (int i = 0; i < dataCount; i++) {
        printf("%f + %f = %f\n", hostA[i], hostB[i], hostC[i]);
    }

    // 验证结果
    int success = 1;
    for (int i = 0; i < dataCount; i++) {
        if (hostC[i] != hostA[i] + hostB[i]) {
            success = 0;
            break;
        }
    }

    printf("\n%s\n", success ? "Test PASSED!" : "Test FAILED!");

    // 清理资源
    clReleaseMemObject(bufferA);
    clReleaseMemObject(bufferB);
    clReleaseMemObject(bufferC);
    clReleaseKernel(kernel);
    clReleaseProgram(program);
    clReleaseCommandQueue(cmdQueue);
    clReleaseContext(context);

    free(platforms);
    free(devices);
    free(hostA);
    free(hostB);
    free(hostC);

    return 0;
}
```

### 编译和运行

#### 使用 Visual Studio

1. 将代码保存为 `.c` 或 `.cpp` 文件
2. 确保已配置包含目录和库目录
3. 按 F5 运行

#### 使用命令行（MinGW）

```bash
# 编译（注意路径需要用引号包裹包含空格的路径）
gcc -o opencl_demo.exe opencl_helloworld.c -I"C:\Program Files (x86)\Intel\OpenCL SDK\include" -L"C:\Program Files (x86)\Intel\OpenCL SDK\lib\x64" -lOpenCL

# 运行
./opencl_demo.exe
```

---

## 项目结构示例

```
OpenCLProjects/
├── CMakeLists.txt
├── include/
│   └── CL/
│       ├── cl.h
│       ├── cl_ext.h
│       └── cl_platform.h
├── src/
│   ├── main.c
│   └── utils.c
└── lib/
    └── x64/
        └── OpenCL.lib
```

### CMakeLists.txt 示例

```cmake
cmake_minimum_required(VERSION 3.10)
project(OpenCLDemo)

set(CMAKE_CXX_STANDARD 11)

# 查找 OpenCL
find_package(OpenCL REQUIRED)

# 包含头文件目录
include_directories(${OPENCL_INCLUDE_DIRS})

# 添加可执行文件
add_executable(opencl_demo src/main.c)

# 链接 OpenCL 库
target_link_libraries(opencl_demo ${OPENCL_LIBRARIES})

# 设置库目录（如果需要）
# link_directories("C:/Program Files (x86)/Intel/OpenCL SDK/lib/x64")
```

---

## OpenCL 编程模型

OpenCL 采用**主机-设备**（Host-Device）编程模型：

```
+------------------+      +------------------+
|                  |      |                  |
|   主机 (Host)    |<---->|   设备 (Device)  |
|   (CPU)          |      |   (GPU/FPGA/etc) |
|                  |      |                  |
+------------------+      +------------------+
```

### 编程流程

OpenCL 程序的基本执行流程如下：

1. **发现平台和设备** - 枚举系统中可用的 OpenCL 平台和设备
2. **创建上下文** - 建立主机和设备之间的通信上下文
3. **创建命令队列** - 设置向设备提交命令的队列
4. **准备内核代码** - 编写运行在设备上的内核函数
5. **编译程序** - 将内核代码编译成设备可执行的二进制
6. **创建内核对象** - 从程序中创建可执行的内核
7. **设置内核参数** - 传递数据给内核
8. **执行内核** - 提交内核到命令队列执行
9. **数据传输** - 在主机和设备间传输数据
10. **清理资源** - 释放所有 OpenCL 对象

### 计算单元层次结构

```
Platform (平台)
├── Device 1 (设备1 - CPU/GPU)
│   ├── Compute Unit 1 (计算单元1)
│   │   ├── work-group 0 (工作组0)
│   │   ├── work-group 1 (工作组1)
│   │   └── ...
│   └── Compute Unit 2 (计算单元2)
│       ├── work-group 0 (工作组0)
│       └── ...
└── Device 2 (设备2)
    └── ...
```

- **Platform**：代表一个 OpenCL 框架，通常对应一个厂商的 OpenCL 实现
- **Device**：具体的计算设备，如 GPU、CPU 等
- **Compute Unit**：设备上的计算单元（AMD 称为 CU，NVIDIA 称为 SM）
- **work-group**：工作组，一组可以同步和共享数据的工作项
- **work-item**：工作项，最小的执行单位，对应一个线程

---

## OpenCL 核心概念

### 1. 平台（Platform）

_platform_id_ 表示一个 OpenCL 平台，通常由硬件厂商提供。

```c
// 获取平台数量
cl_uint numPlatforms;
clGetPlatformIDs(0, NULL, &numPlatforms);

// 获取平台 ID
cl_platform_id platform;
clGetPlatformIDs(1, &platform, NULL);

// 查询平台信息
char platformName[256];
clGetPlatformInfo(platform, CL_PLATFORM_NAME, sizeof(platformName), &platformName, NULL);
```

常用平台属性：
- `CL_PLATFORM_NAME` - 平台名称
- `CL_PLATFORM_VENDOR` - 平台厂商
- `CL_PLATFORM_VERSION` - OpenCL 版本
- `CL_PLATFORM_PROFILE` - 配置文件（FULL_PROFILE/EMBEDDED_PROFILE）
- `CL_PLATFORM_EXTENSIONS` - 支持的扩展

### 2. 设备（Device）

_device_id_ 表示具体的计算设备。

```c
// 获取设备数量
cl_uint numDevices;
clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, 0, NULL, &numDevices);

// 获取设备 ID
cl_device_id device;
clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, 1, &device, NULL);

// 查询设备信息
char deviceName[256];
clGetDeviceInfo(device, CL_DEVICE_NAME, sizeof(deviceName), &deviceName, NULL);
```

常用设备类型：
- `CL_DEVICE_TYPE_CPU` - CPU
- `CL_DEVICE_TYPE_GPU` - GPU
- `CL_DEVICE_TYPE_ACCELERATOR` - 加速器
- `CL_DEVICE_TYPE_DEFAULT` - 默认设备
- `CL_DEVICE_TYPE_ALL` - 所有设备

常用设备属性：
- `CL_DEVICE_NAME` - 设备名称
- `CL_DEVICE_VENDOR` - 设备厂商
- `CL_DEVICE_MAX_COMPUTE_UNITS` - 最大计算单元数
- `CL_DEVICE_MAX_WORK_ITEM_DIMENSIONS` - 最大工作项维度
- `CL_DEVICE_MAX_WORK_GROUP_SIZE` - 最大工作组大小
- `CL_DEVICE_GLOBAL_MEM_SIZE` - 全局内存大小
- `CL_DEVICE_LOCAL_MEM_SIZE` - 本地内存大小
- `CL_DEVICE_CONSTANT_BUFFER_SIZE` - 常量缓冲区大小

### 3. 上下文（Context）

_context_ 是设备和主机之间的通信环境。

```c
// 创建上下文
cl_context context = clCreateContext(NULL, numDevices, devices, NULL, NULL, &err);

// 创建带属性的上下文
cl_context_properties props[] = {
    CL_CONTEXT_PLATFORM, (cl_context_properties)platform,
    0
};
cl_context context = clCreateContext(props, numDevices, devices, NULL, NULL, &err);

// 释放上下文
clReleaseContext(context);
```

### 4. 命令队列（Command Queue）

_command_queue_ 用于向设备提交命令。

```c
// 创建命令队列（OpenCL 1.x 和 2.x）
// 注意：此函数在 OpenCL 3.0 中被移除，仅用于向后兼容
cl_command_queue queue = clCreateCommandQueue(context, device, 0, &err);

// 创建命令队列（OpenCL 2.0+ 推荐，OpenCL 3.0 必需）
cl_queue_properties props[] = { CL_QUEUE_PROPERTIES, 0, 0 };
cl_command_queue queue = clCreateCommandQueueWithProperties(context, device, props, &err);

// 释放命令队列
clReleaseCommandQueue(queue);
```

命令队列属性：
- `CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE` - 允许乱序执行
- `CL_QUEUE_PROFILING_ENABLE` - 启用性能分析

> **注意**：在 OpenCL 3.0 中，`clCreateCommandQueue` 已被移除，必须使用 `clCreateCommandQueueWithProperties`。

### 5. 缓冲区对象（Buffer）

_buffer_ 是主机和设备之间共享的内存对象。

```c
// 创建缓冲区
cl_mem buffer = clCreateBuffer(context,
                                CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                size * sizeof(float), hostPtr, &err);

// 创建子缓冲区（用于访问缓冲区的一部分）
cl_buffer_region region = { offset * sizeof(float), count * sizeof(float) };
cl_mem subBuffer = clCreateSubBuffer(buffer, CL_MEM_READ_WRITE,
                                     CL_BUFFER_CREATE_TYPE_REGION, &region, &err);

// 释放缓冲区
clReleaseMemObject(buffer);
```

缓冲区内存标志：
- `CL_MEM_READ_ONLY` - 只读
- `CL_MEM_WRITE_ONLY` - 只写
- `CL_MEM_READ_WRITE` - 读写
- `CL_MEM_COPY_HOST_PTR` - 从主机指针复制初始化
- `CL_MEM_USE_HOST_PTR` - 使用主机指针
- `CL_MEM_ALLOC_HOST_PTR` - 分配主机可访问内存

### 6. 图像对象（Image）

_image_ 是专门用于图像处理的内存对象。

```c
// 创建 2D 图像
cl_image_format format = { CL_RGBA, CL_FLOAT };
cl_image_desc desc = { CL_MEM_OBJECT_IMAGE2D, width, height, 0, 0, 0, 0, 0, 0 };
cl_mem image = clCreateImage(context, CL_MEM_READ_ONLY, &format, &desc, NULL, &err);

// 释放图像
clReleaseMemObject(image);
```

常用图像格式：
- `CL_RGBA`, `CL_ARGB`, `CL_BGRA` 等通道顺序
- `CL_UNORM_INT8`, `CL_UNORM_INT16`, `CL_SIGNED_INT8` 等数据类型

### 7. 事件（Event）

_event_ 用于跟踪命令执行状态和依赖管理。

```c
// 创建事件
cl_event event;
clEnqueueNDRangeKernel(queue, kernel, workDim, NULL, globalWorkSize,
                       localWorkSize, 0, NULL, &event);

// 等待事件完成
clWaitForEvents(1, &event);

// 获取事件信息
cl_ulong startTime, endTime;
clGetEventProfilingInfo(event, CL_PROFILING_COMMAND_START, sizeof(startTime), &startTime, NULL);
clGetEventProfilingInfo(event, CL_PROFILING_COMMAND_END, sizeof(endTime), &endTime, NULL);
double duration = (endTime - startTime) * 1e-9; // 纳秒转秒

// 释放事件
clReleaseEvent(event);
```

---

## OpenCL 内核编程

### 内核语言基础

OpenCL C 是基于 ANSI C 的子集，增加了并行编程特性。

#### 数据类型

| OpenCL C 类型 | 描述 |
|--------------|------|
| `char/uchar` | 8 位有符号/无符号整数 |
| `short/ushort` | 16 位有符号/无符号整数 |
| `int/uint` | 32 位有符号/无符号整数 |
| `long/ulong` | 64 位有符号/无符号整数 |
| `float` | 32 位浮点数 |
| `double` | 64 位浮点数（需扩展支持） |

#### 向量类型

OpenCL 支持向量类型用于 SIMD 操作：

```c
float4 v1 = (float4)(1.0f, 2.0f, 3.0f, 4.0f);
float2 v2 = (float2)(5.0f, 6.0f);

// 向量运算
float4 result = v1 * 2.0f + v2.xyxy;
```

常用向量类型：`char2/char3/char4/char8/char16`，`float2/float4/float8/float16` 等。

### 内建函数

#### 工作项函数

| 函数 | 描述 |
|------|------|
| `get_local_id(dim)` | 获取工作项在工作组中的本地 ID |
| `get_global_id(dim)` | 获取工作项的全局 ID |
| `get_local_size(dim)` | 获取工作组大小 |
| `get_group_id(dim)` | 获取工作组 ID |
| `get_num_groups(dim)` | 获取工作组数量 |
| `get_global_size(dim)` | 获取全局工作大小 |

#### 同步函数

| 函数 | 描述 |
|------|------|
| `barrier(flags)` | 同步工作组内所有工作项 |
| `mem_fence(flags)` | 内存栅栏，确保内存访问顺序 |

### 内存空间

OpenCL 有多种内存空间：

```c
__global      // 全局内存，所有工作项可访问，容量大但延迟高
__local       // 本地内存，工作组内可访问，速度快
__private     // 私有内存，工作项私有
__constant    // 常量内存，只读，对所有工作项可见
```

示例：
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

---

## OpenCL C++ 编程

### OpenCL C++ 扩展概述

OpenCL C++ 提供了比 OpenCL C 更高级的抽象，包括模板、 lambda 表达式和更丰富的数据类型。

### C++ for OpenCL 头文件

```c
#include <CL/opencl.hpp>  // C++ 封装
// 或者
#include <CL/cl2.hpp>     // 旧版 C++ 封装
```

### C++ API 与 C API 对比

#### 对象封装

```cpp
// C 风格
cl_context context = clCreateContext(...);
clEnqueueNDRangeKernel(queue, kernel, ...);
clReleaseContext(context);

// C++ 风格
cl::Context context(...);
queue.enqueueNDRangeKernel(kernel, ...);
// 自动析构释放资源
```

#### 异常处理

```cpp
try {
    cl::Program program(context, kernelSource);
    program.build();
} catch (cl::Error& err) {
    std::cerr << "OpenCL Error: " << err.what() << std::endl;
}
```

---

## OpenCL C++ 详细内容

### 1. 上下文（Context）

```cpp
#include <CL/cl2.hpp>
#include <iostream>
#include <vector>

int main() {
    try {
        // 获取平台
        std::vector<cl::Platform> platforms;
        cl::Platform::get(&platforms);

        if (platforms.empty()) {
            std::cerr << "No OpenCL platforms found!" << std::endl;
            return -1;
        }

        // 选择第一个平台
        cl::Platform platform = platforms[0];
        std::cout << "Platform: " << platform.getInfo<CL_PLATFORM_NAME>() << std::endl;

        // 创建上下文
        std::vector<cl::Device> devices;
        platform.getDevices(CL_DEVICE_TYPE_GPU, &devices);

        cl::Context context(devices);

        // 获取设备信息
        for (const auto& device : devices) {
            std::cout << "Device: " << device.getInfo<CL_DEVICE_NAME>() << std::endl;
            std::cout << "Max Compute Units: "
                      << device.getInfo<CL_DEVICE_MAX_COMPUTE_UNITS>() << std::endl;
        }
    } catch (cl::Error& err) {
        std::cerr << "OpenCL Error: " << err.what() << std::endl;
        return -1;
    }

    return 0;
}
```

### 2. 命令队列（Command Queue）

```cpp
// 创建命令队列
cl::CommandQueue queue(context, device, CL_QUEUE_PROFILING_ENABLE);

// 使用 lambda 的事件回调
cl::Event event;
queue.enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(1024), cl::NullRange,
                           nullptr, &event);

event.setCallback(CL_COMPLETE, [](cl_event, cl_int, void*) {
    std::cout << "Kernel execution completed!" << std::endl;
}, nullptr);
```

### 3. 内存对象（Buffer）

```cpp
// 创建缓冲区
std::vector<float> data(1024);
cl::Buffer buffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                  data.size() * sizeof(float), data.data());

// 创建子缓冲区（需要使用 buffer_region 结构）
cl_buffer_region region;
region.origin = offset;
region.size = size;
cl_int err;
cl::Buffer subBuffer(buffer.createSubBuffer(CL_MEM_READ_ONLY,
                                            CL_BUFFER_CREATE_TYPE_REGION,
                                            &region, &err));

// 使用 map 函数（RAII）
{
    cl::Buffer deviceBuffer(context, CL_MEM_READ_WRITE, size * sizeof(float));

    // 写入数据
    queue.enqueueWriteBuffer(deviceBuffer, CL_TRUE, 0, size * sizeof(float), hostData);

    // 读取数据
    queue.enqueueReadBuffer(deviceBuffer, CL_TRUE, 0, size * sizeof(float), hostResult);
}

// 使用 map
{
    cl::Buffer buffer(context, CL_MEM_WRITE_ONLY, size * sizeof(float));
    auto mapped_ptr = queue.enqueueMapBuffer(buffer, CL_TRUE, CL_MAP_WRITE, 0, size * sizeof(float));

    // 使用 mapped_ptr
    float* data = static_cast<float*>(mapped_ptr);
    for (size_t i = 0; i < size; i++) {
        data[i] = static_cast<float>(i);
    }

    // 解映射
    queue.enqueueUnmapMemObject(buffer, mapped_ptr);
}
```

### 4. 图像对象（Image）

```cpp
// 创建 2D 图像
cl::Image2D image2D(context, CL_MEM_READ_ONLY,
                    cl::ImageFormat(CL_RGBA, CL_FLOAT),
                    width, height, 0, nullptr);

// 创建 3D 图像
cl::Image3D image3D(context, CL_MEM_READ_WRITE,
                    cl::ImageFormat(CL_RGBA, CL_UNORM_INT8),
                    width, height, depth, 0, 0, nullptr);

// 使用图像读写
queue.enqueueWriteImage(image2D, CL_TRUE, origin, region,
                        row_pitch, slice_pitch, hostData);
```

### 5. 程序和内核（Program & Kernel）

```cpp
// 从源码创建程序
std::string kernelSource = R"(
    __kernel void vector_add(__global const float* a,
                             __global const float* b,
                             __global float* c) {
        int idx = get_global_id(0);
        c[idx] = a[idx] + b[idx];
    }
)";
cl::Program::Sources sources;
sources.push_back({kernelSource.c_str(), kernelSource.length()});
cl::Program program(context, sources);

// 编译程序
program.build();

// 创建内核
cl::Kernel kernel(program, "vector_add");

// 设置内核参数
kernel.setArg(0, bufferA);
kernel.setArg(1, bufferB);
kernel.setArg(2, bufferC);

// 使用模板设置参数
cl::Kernel vectorAdd(program, "vector_add");
vectorAdd.setArg<cl::Buffer>(0, bufferA);
vectorAdd.setArg<cl::Buffer>(1, bufferB);
vectorAdd.setArg<cl::Buffer>(2, bufferC);
```

### 6. 内核执行

```cpp
// NDRange 执行
cl::NDRange globalSize(1024);
cl::NDRange localSize(256);

queue.enqueueNDRangeKernel(kernel, cl::NullRange, globalSize, localSize);

// 带事件的执行
cl::Event event;
queue.enqueueNDRangeKernel(kernel, cl::NullRange, globalSize, localSize,
                           nullptr, &event);
event.wait();

// 使用 lambda 的事件回调
event.setCallback(CL_COMPLETE, [](cl_event, cl_int status, void* data) {
    if (status == CL_SUCCESS) {
        std::cout << "Kernel completed successfully!" << std::endl;
    }
}, nullptr);
```

### 7. 事件和 Profiling

```cpp
// 性能分析
cl::Event kernelEvent;
queue.enqueueNDRangeKernel(kernel, cl::NullRange, globalSize, localSize,
                           nullptr, &kernelEvent);
kernelEvent.wait();

// 获取事件时间
cl_ulong start = kernelEvent.getProfilingInfo<CL_PROFILING_COMMAND_START>();
cl_ulong end = kernelEvent.getProfilingInfo<CL_PROFILING_COMMAND_END>();
double duration_ns = end - start;
double duration_ms = duration_ns * 1e-6;

std::cout << "Kernel execution time: " << duration_ms << " ms" << std::endl;
```

### 8. 互操作性（OpenGL）

```cpp
#include <GL/gl.h>
#include <CL/cl_gl.h>

// 从 OpenGL 纹理创建 OpenCL 图像
GLuint texture;
glGenTextures(1, &texture);
// ... OpenGL 纹理创建代码 ...

cl_int err;
cl_mem clImage = clCreateFromGLTexture2D(context.get(), CL_MEM_READ_WRITE,
                                         GL_TEXTURE_2D, 0, texture, &err);
if (err != CL_SUCCESS) {
    std::cerr << "Failed to create OpenCL image from GL texture" << std::endl;
    return -1;
}

// 包装为 C++ 对象（注意：需要手动管理 cl_mem 的生命周期）
cl::Image2D glImage(clImage, true);  // true 表示接管所有权

// 在 OpenCL 和 OpenGL 之间共享数据
std::vector<cl::Memory> glObjects;
glObjects.push_back(glImage);
queue.enqueueAcquireGLObjects(&glObjects);
queue.enqueueNDRangeKernel(kernel, cl::NullRange, globalSize, localSize);
queue.enqueueReleaseGLObjects(&glObjects);
queue.finish();
```

### 9. 自定义异常处理

```cpp
class OpenCLError : public std::runtime_error {
public:
    OpenCLError(cl_int error, const std::string& msg)
        : std::runtime_error(msg + " (Error code: " + std::to_string(error) + ")"),
          errorCode(error) {}

    cl_int getErrorCode() const { return errorCode; }

private:
    cl_int errorCode;
};

// 使用宏简化错误处理
#define CL_CHECK(err) \
    do { \
        cl_int err_code = (err); \
        if (err_code != CL_SUCCESS) { \
            throw OpenCLError(err_code, "OpenCL error at " + std::string(__FILE__) + ":" + std::to_string(__LINE__)); \
        } \
    } while(0)
```

---

## OpenCL C++ 完整示例

```cpp
#include <CL/cl2.hpp>
#include <iostream>
#include <vector>
#include <exception>

int main() {
    try {
        // 1. 获取平台和设备
        std::vector<cl::Platform> platforms;
        cl::Platform::get(&platforms);

        if (platforms.empty()) {
            std::cerr << "No OpenCL platforms found!" << std::endl;
            return -1;
        }

        cl::Platform platform = platforms[0];
        std::cout << "Using Platform: " << platform.getInfo<CL_PLATFORM_NAME>() << std::endl;

        std::vector<cl::Device> devices;
        platform.getDevices(CL_DEVICE_TYPE_GPU, &devices);

        if (devices.empty()) {
            // 回退到 CPU
            platform.getDevices(CL_DEVICE_TYPE_CPU, &devices);
        }

        cl::Device device = devices[0];
        std::cout << "Using Device: " << device.getInfo<CL_DEVICE_NAME>() << std::endl;

        // 2. 创建上下文和命令队列
        cl::Context context(device);
        cl::CommandQueue queue(context, device, CL_QUEUE_PROFILING_ENABLE);

        // 3. 准备数据
        const size_t N = 1024;
        std::vector<float> hostA(N), hostB(N), hostC(N);

        for (size_t i = 0; i < N; i++) {
            hostA[i] = static_cast<float>(i);
            hostB[i] = static_cast<float>(i * 2.0f);
        }

        // 4. 创建缓冲区
        cl::Buffer bufferA(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                           N * sizeof(float), hostA.data());
        cl::Buffer bufferB(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                           N * sizeof(float), hostB.data());
        cl::Buffer bufferC(context, CL_MEM_WRITE_ONLY, N * sizeof(float));

        // 5. 创建程序和内核
        std::string kernelSource = R"(
            __kernel void vector_add(__global const float* a,
                                     __global const float* b,
                                     __global float* c) {
                int idx = get_global_id(0);
                c[idx] = a[idx] + b[idx];
            }
        )";

        cl::Program::Sources sources;
        sources.push_back({kernelSource.c_str(), kernelSource.length()});
        cl::Program program(context, sources);

        program.build(device);

        cl::Kernel kernel(program, "vector_add");

        // 6. 设置内核参数
        kernel.setArg(0, bufferA);
        kernel.setArg(1, bufferB);
        kernel.setArg(2, bufferC);

        // 7. 执行内核
        cl::Event event;
        queue.enqueueNDRangeKernel(kernel, cl::NullRange,
                                   cl::NDRange(N), cl::NDRange(256),
                                   nullptr, &event);

        event.wait();

        // 8. 获取结果
        queue.enqueueReadBuffer(bufferC, CL_TRUE, 0, N * sizeof(float), hostC.data());

        // 9. 验证结果
        int success = 1;
        for (size_t i = 0; i < N; i++) {
            if (hostC[i] != hostA[i] + hostB[i]) {
                success = 0;
                std::cerr << "Mismatch at index " << i << ": "
                          << hostA[i] << " + " << hostB[i]
                          << " != " << hostC[i] << std::endl;
                break;
            }
        }

        if (success) {
            std::cout << "Test PASSED!" << std::endl;
        }

        // 10. 性能分析
        cl_ulong start = event.getProfilingInfo<CL_PROFILING_COMMAND_START>();
        cl_ulong end = event.getProfilingInfo<CL_PROFILING_COMMAND_END>();
        double duration_ms = (end - start) * 1e-6;

        std::cout << "Execution time: " << duration_ms << " ms" << std::endl;

    } catch (cl::Error& err) {
        std::cerr << "OpenCL Error: " << err.what()
                  << " (Code: " << err.err() << ")" << std::endl;
        return -1;
    } catch (std::exception& err) {
        std::cerr << "Exception: " << err.what() << std::endl;
        return -1;
    }

    return 0;
}
```

---

## OpenCL C++ 编译示例

### Visual Studio

1. 添加头文件目录：`C:\Program Files (x86)\Intel\OpenCL SDK\include`
2. 添加库目录：`C:\Program Files (x86)\Intel\OpenCL SDK\lib\x64`
3. 附加依赖项：`OpenCL.lib`

### 命令行

```bash
g++ -o opencl_cpp_demo opencl_cpp_demo.cpp \
    -I"C:\Program Files (x86)\Intel\OpenCL SDK\include" \
    -L"C:\Program Files (x86)\Intel\OpenCL SDK\lib\x64" \
    -lOpenCL
```

---

## 使用 SPIR-V 中间语言

### SPIR-V 简介

SPIR-V（Standard Portable Intermediate Representation）是 Khronos 定义的中间语言，用于在 OpenCL、Vulkan 等框架中表示着色器和内核程序。

**SPIR-V 的优势**：
- **跨平台**：一次编译，多处运行
- **保护知识产权**：二进制格式，难以逆向工程
- **编译优化**：前端编译器可进行深度优化
- **语言无关**：支持 OpenCL C、OpenCL C++、GLSL、HLSL 等多种源语言

### SPIR-V 版本要求

| OpenCL 版本 | SPIR-V 支持 | 说明 |
|-------------|-------------|------|
| OpenCL 2.1+ | 原生支持 | `clCreateProgramWithIL()` |
| OpenCL 1.2 | 扩展支持 | `cl_khr_il_program` 扩展 |
| OpenCL 3.0 | 原生支持 | 完整 SPIR-V 1.5 支持 |

### 检查 SPIR-V 支持

```c
cl_bool supportsIL;
clGetDeviceInfo(device, CL_DEVICE_IL_VERSION, sizeof(supportsIL), &supportsIL, NULL);

if (supportsIL) {
    printf("Device supports IL programs (SPIR-V)\n");
}

// 获取支持的 IL 版本
char ilVersion[256];
clGetDeviceInfo(device, CL_DEVICE_IL_VERSION, sizeof(ilVersion), ilVersion, NULL);
printf("IL Version: %s\n", ilVersion);
```

### 编译 OpenCL C 到 SPIR-V

#### 方法 1：使用 clang 编译器

```bash
# 安装 LLVM/Clang（需要支持 OpenCL 的版本）
# 编译 OpenCL C 源码到 SPIR-V

clang -cl-std=CL2.0 -target spirv64 -c kernel.cl -o kernel.spv

# 或者使用 OpenCL 离线编译器
opencl-c-compiler -cl-std=CL2.0 -o kernel.spv kernel.cl
```

#### 方法 2：使用 spirv-dis 和 spirv-as

```bash
# 从 SPIR-V 反汇编
spirv-dis kernel.spv -o kernel.asm

# 从汇编生成 SPIR-V
spirv-as kernel.asm -o kernel.spv
```

#### 方法 3：使用 Khronos SPIR-V Tools

```bash
# 优化 SPIR-V
spirv-opt -O kernel.spv -o kernel_optimized.spv

# 验证 SPIR-V
spirv-val kernel.spv

# 生成 SPIR-V 信息
spirv-cfg kernel.spv -o cfg.dot
```

### 从 SPIR-V 创建 OpenCL 程序

#### C API 示例

```c
#include <CL/cl.h>
#include <stdio.h>
#include <stdlib.h>

cl_program createProgramFromSPIRV(cl_context context, cl_device_id device,
                                   const char* spvFile) {
    FILE* fp = fopen(spvFile, "rb");
    if (!fp) {
        printf("Failed to open SPIR-V file: %s\n", spvFile);
        return NULL;
    }

    // 获取文件大小
    fseek(fp, 0, SEEK_END);
    size_t size = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    // 读取 SPIR-V 二进制
    unsigned char* spvBinary = (unsigned char*)malloc(size);
    fread(spvBinary, 1, size, fp);
    fclose(fp);

    // 检查 IL 支持
    size_t ilVersionSize;
    clGetDeviceInfo(device, CL_DEVICE_IL_VERSION, 0, NULL, &ilVersionSize);
    if (ilVersionSize == 0) {
        printf("Device does not support IL programs\n");
        free(spvBinary);
        return NULL;
    }

    // 创建程序
    cl_int err;
    size_t lengths[1] = { size };
    cl_program program = clCreateProgramWithIL(context, spvBinary, size, &err);

    free(spvBinary);

    if (err != CL_SUCCESS) {
        printf("Failed to create program from IL: %d\n", err);
        return NULL;
    }

    // 构建程序
    err = clBuildProgram(program, 1, &device, NULL, NULL, NULL);
    if (err != CL_SUCCESS) {
        size_t logSize;
        clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, 0, NULL, &logSize);
        char* log = (char*)malloc(logSize);
        clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, logSize, log, NULL);
        printf("Build error: %s\n", log);
        free(log);
        clReleaseProgram(program);
        return NULL;
    }

    return program;
}
```

#### C++ API 示例

```cpp
#include <CL/cl2.hpp>
#include <fstream>
#include <vector>
#include <iostream>

cl::Program createProgramFromSPIRV(const cl::Context& context,
                                    const cl::Device& device,
                                    const std::string& spvFile) {
    // 读取 SPIR-V 文件
    std::ifstream file(spvFile, std::ios::binary | std::ios::ate);
    if (!file.is_open()) {
        throw std::runtime_error("Failed to open SPIR-V file: " + spvFile);
    }

    size_t size = file.tellg();
    file.seekg(0, std::ios::beg);

    std::vector<char> spvBinary(size);
    file.read(spvBinary.data(), size);
    file.close();

    // 检查设备是否支持 IL
    std::string ilVersion;
    device.getInfo(CL_DEVICE_IL_VERSION, &ilVersion);
    if (ilVersion.empty()) {
        throw std::runtime_error("Device does not support IL programs");
    }

    std::cout << "Device IL Version: " << ilVersion << std::endl;

    // 从 IL 创建程序
    cl_int err;
    cl::Program program = cl::Program(context, spvBinary, true, &err);

    if (err != CL_SUCCESS) {
        throw cl::Error(err, "Failed to create program from IL");
    }

    // 构建程序
    program.build(device);

    return program;
}

// 完整使用示例
int main() {
    try {
        // 获取平台和设备
        std::vector<cl::Platform> platforms;
        cl::Platform::get(&platforms);
        cl::Platform platform = platforms[0];

        std::vector<cl::Device> devices;
        platform.getDevices(CL_DEVICE_TYPE_GPU, &devices);
        cl::Device device = devices[0];

        cl::Context context(device);

        // 从 SPIR-V 加载程序
        cl::Program program = createProgramFromSPIRV(context, device, "kernel.spv");

        // 创建内核
        cl::Kernel kernel(program, "my_kernel");

        std::cout << "SPIR-V program loaded successfully!" << std::endl;

    } catch (cl::Error& err) {
        std::cerr << "OpenCL Error: " << err.what() << " (" << err.err() << ")" << std::endl;
        return -1;
    }

    return 0;
}
```

### OpenCL C++ 内核到 SPIR-V

OpenCL C++ 内核语言（基于 C++14）可以直接编译为 SPIR-V：

```cpp
// kernel.clcpp - OpenCL C++ 内核
kernel void vector_add(global const float* a,
                       global const float* b,
                       global float* c,
                       const int n) {
    int idx = get_global_id(0);
    if (idx < n) {
        c[idx] = a[idx] + b[idx];
    }
}
```

编译命令：
```bash
# 使用 clang 编译 OpenCL C++ 到 SPIR-V
clang++ -cl-std=c++ -target spirv64 -c kernel.clcpp -o kernel.spv
```

### SPIR-V 内核示例

#### 原始 OpenCL C 代码

```c
// original_kernel.cl
__kernel void matrix_multiply(__global const float* A,
                              __global const float* B,
                              __global float* C,
                              const int M, const int N, const int K) {
    int row = get_global_id(0);
    int col = get_global_id(1);

    if (row < M && col < N) {
        float sum = 0.0f;
        for (int k = 0; k < K; k++) {
            sum += A[row * K + k] * B[k * N + col];
        }
        C[row * N + col] = sum;
    }
}
```

#### 编译为 SPIR-V

```bash
# 编译到 SPIR-V（64 位）
clang -cl-std=CL2.0 -target spirv64 -c original_kernel.cl -o matrix_multiply.spv

# 查看生成的 SPIR-V 信息
spirv-dis matrix_multiply.spv
```

### SPIR-V 扩展支持

检查设备支持的 SPIR-V 扩展：

```c
// 检查 SPIR-V 扩展
char extensions[4096];
clGetDeviceInfo(device, CL_DEVICE_EXTENSIONS, sizeof(extensions), extensions, NULL);

// 常见 SPIR-V 扩展
if (strstr(extensions, "cl_khr_il_program")) {
    printf("Supports cl_khr_il_program (OpenCL 1.2 SPIR-V)\n");
}
if (strstr(extensions, "cl_khr_spirv_no_integer_wrap_decoration")) {
    printf("Supports SPIR-V no integer wrap decoration\n");
}
```

### SPIR-V 与源码编译对比

| 特性 | 源码编译 | SPIR-V 编译 |
|------|----------|-------------|
| 编译时间 | 运行时编译 | 预编译，加载快 |
| 代码保护 | 源码可见 | 二进制格式 |
| 跨设备 | 需要重新编译 | 可跨设备使用 |
| 调试 | 较容易 | 需要特殊工具 |
| 文件大小 | 较小 | 较大 |

### 在线编译 vs 离线编译

```c
// 在线编译（运行时）
cl_program program = clCreateProgramWithSource(context, 1, &source, NULL, &err);
clBuildProgram(program, 1, &device, "-cl-std=CL2.0", NULL, NULL);

// 离线编译（SPIR-V）
cl_program program = clCreateProgramWithIL(context, spirvBinary, spirvSize, &err);
clBuildProgram(program, 1, &device, NULL, NULL, NULL);
```

### 使用 SPIR-V 的最佳实践

1. **版本兼容性**：确保目标设备支持相应的 SPIR-V 版本
2. **优化选项**：使用 `spirv-opt` 优化 SPIR-V 二进制
3. **错误处理**：始终检查 `clCreateProgramWithIL` 的返回值
4. **缓存策略**：缓存编译后的 SPIR-V 以减少加载时间
5. **验证工具**：使用 `spirv-val` 验证 SPIR-V 文件的正确性

### 获取程序 IL

```c
// 从已编译的程序获取 SPIR-V
size_t ilSize;
clGetProgramInfo(program, CL_PROGRAM_IL, 0, NULL, &ilSize);

unsigned char* ilBinary = (unsigned char*)malloc(ilSize);
clGetProgramInfo(program, CL_PROGRAM_IL, ilSize, ilBinary, NULL);

// 保存到文件
FILE* fp = fopen("output.spv", "wb");
fwrite(ilBinary, 1, ilSize, fp);
fclose(fp);
free(ilBinary);
```

---

## OpenCL API 详解

#### clGetPlatformIDs

```c
cl_int clGetPlatformIDs(cl_uint num_entries,
                        cl_platform_id* platforms,
                        cl_uint* num_platforms);
```

---

## 常见问题

### 1. 找不到 OpenCL.lib

**问题**：链接错误 `LNK2019: 无法解析的外部符号 _clGetPlatformIDs`

**解决方案**：
- 确保已安装 Intel/AMD/NVIDIA 的 OpenCL 运行时
- 在项目属性中添加 OpenCL.lib 的路径
- 确认平台位数匹配（x64/x86）

### 2. 找不到 CL/cl.h

**问题**：编译错误 `fatal error C1083: 无法打开包括文件: "CL/cl.h"`

**解决方案**：
- 下载 [OpenCL-Headers](https://github.com/KhronosGroup/OpenCL-Headers)
- 或安装 Intel/AMD/NVIDIA OpenCL SDK
- 在项目属性中添加头文件路径

### 3. 没有找到 OpenCL 平台

**问题**：`clGetPlatformIDs` 返回 0 个平台

**解决方案**：
- 更新显卡驱动
- 重新安装 OpenCL 运行时
- 检查系统环境变量

### 4. 编译内核失败

**问题**：`clBuildProgram` 返回错误

**解决方案**：
- 查看编译日志：
```c
size_t logSize;
clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, 0, NULL, &logSize);
char* log = (char*)malloc(logSize);
clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, logSize, log, NULL);
printf("%s\n", log);
```

### 5. 内存不足

**问题**：`CL_MEM_OBJECT_ALLOCATION_FAILURE`

**解决方案**：
- 减少分配的缓冲区大小
- 检查设备的全局内存限制
- 使用分块处理大数据

---

## 调试技巧

### 使用 clEnqueueMarkerWithWaitList 和 clFinish

```c
// 在关键操作后添加同步点（OpenCL 2.0+）
cl_event marker;
clEnqueueMarkerWithWaitList(cmdQueue, 0, NULL, &marker);
clWaitForEvents(1, &marker);
clReleaseEvent(marker);

// 或者使用 OpenCL 1.2 的 clEnqueueMarker（已弃用）
// clEnqueueMarker(cmdQueue, &marker);

// 强制执行所有排队的操作
clFinish(cmdQueue);
```

### 检查返回值

所有 OpenCL API 都返回 `cl_int` 错误码，务必检查：

```c
cl_int err = clSomeFunction(params);
if (err != CL_SUCCESS) {
    printf("Error %d at %s:%d\n", err, __FILE__, __LINE__);
    return -1;
}
```

---

## OpenCL 实用示例

### 示例 1：矩阵乘法

```c
__kernel void matrix_mul(__const float* A,
                         __const float* B,
                         __global float* C,
                         const int width) {
    int row = get_global_id(1);
    int col = get_global_id(0);

    if (row < width && col < width) {
        float sum = 0.0f;
        for (int i = 0; i < width; i++) {
            sum += A[row * width + i] * B[i * width + col];
        }
        C[row * width + col] = sum;
    }
}
```

### 示例 2：使用本地内存优化的矩阵乘法

```c
__kernel void matrix_mul_optimized(__const float* A,
                                   __const float* B,
                                   __global float* C,
                                   const int width) {
    // 本地内存用于缓存
    __local float tileA[32][32];
    __local float tileB[32][32];

    int row = get_global_id(1);
    int col = get_global_id(0);
    int localRow = get_local_id(1);
    int localCol = get_local_id(0);

    float sum = 0.0f;

    // 分块处理
    int numTiles = (width + 31) / 32;

    for (int t = 0; t < numTiles; t++) {
        // 加载 tile 到本地内存
        tileA[localRow][localCol] = A[row * width + t * 32 + localCol];
        tileB[localRow][localCol] = B[(t * 32 + localRow) * width + col];

        barrier(CLK_LOCAL_MEM_FENCE);

        // 计算部分乘积
        for (int i = 0; i < 32; i++) {
            sum += tileA[localRow][i] * tileB[i][localCol];
        }

        barrier(CLK_LOCAL_MEM_FENCE);
    }

    if (row < width && col < width) {
        C[row * width + col] = sum;
    }
}
```

### 示例 3：归约操作（求和）

```c
__kernel void reduce(__global const float* input,
                     __global float* output,
                     __local float* temp,
                     const int n) {
    int localId = get_local_id(0);
    int globalId = get_global_id(0);
    int groupSize = get_local_size(0);

    // 加载数据到本地内存
    temp[localId] = (globalId < n) ? input[globalId] : 0.0f;
    barrier(CLK_LOCAL_MEM_FENCE);

    // 树形归约
    for (int stride = groupSize / 2; stride > 0; stride >>= 1) {
        if (localId < stride) {
            temp[localId] += temp[localId + stride];
        }
        barrier(CLK_LOCAL_MEM_FENCE);
    }

    // 写入结果
    if (localId == 0) {
        output[get_group_id(0)] = temp[0];
    }
}
```

### 示例 4：图像处理（亮度调整）

```c
// 定义采样器（通常在内核外部或作为常量定义）
const sampler_t smpSampler = CLK_NORMALIZED_COORDS_FALSE |
                             CLK_ADDRESS_CLAMP_TO_EDGE |
                             CLK_FILTER_NEAREST;

__kernel void adjust_brightness(__read_only image2d_t input,
                                __write_only image2d_t output,
                                const float brightness) {
    int x = get_global_id(0);
    int y = get_global_id(1);

    // 获取图像尺寸
    int width = get_image_width(input);
    int height = get_image_height(input);

    if (x < width && y < height) {
        // 读取像素
        float4 color = read_imagef(input, smpSampler, (int2)(x, y));

        // 调整亮度
        color.xyz += brightness;

        // 写回
        write_imagef(output, (int2)(x, y), color);
    }
}
```

### 示例 5：异步数据传输

```c
// 使用事件管理异步操作
cl_event writeEvent, kernelEvent, readEvent;

// 异步写入数据
clEnqueueWriteBuffer(queue, buffer, CL_FALSE, 0, size, hostData,
                     0, NULL, &writeEvent);

// 依赖写入完成的内核执行
clEnqueueNDRangeKernel(queue, kernel, 1, NULL, &globalSize,
                       &localSize, 1, &writeEvent, &kernelEvent);

// 依赖内核完成的读取
clEnqueueReadBuffer(queue, buffer, CL_FALSE, 0, size, hostResult,
                    1, &kernelEvent, &readEvent);

// 等待所有操作完成
clWaitForEvents(1, &readEvent);

// 清理
clReleaseEvent(writeEvent);
clReleaseEvent(kernelEvent);
clReleaseEvent(readEvent);
```

### 示例 6：多设备并行

```c
// 在多个设备上并行处理
cl_uint numDevices;
clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, 0, NULL, &numDevices);
cl_device_id* devices = (cl_device_id*)malloc(numDevices * sizeof(cl_device_id));
clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, numDevices, devices, NULL);

// 为每个设备创建上下文和队列
cl_context* contexts = (cl_context*)malloc(numDevices * sizeof(cl_context));
cl_command_queue* queues = (cl_command_queue*)malloc(numDevices * sizeof(cl_command_queue));

for (cl_uint i = 0; i < numDevices; i++) {
    contexts[i] = clCreateContext(NULL, 1, &devices[i], NULL, NULL, NULL);
    cl_queue_properties props[] = { 0 };  // 属性数组必须以 0 结尾
    queues[i] = clCreateCommandQueueWithProperties(contexts[i], devices[i], props, NULL);
}

// 分割数据并分配给不同设备
int itemsPerDevice = totalCount / numDevices;
for (cl_uint i = 0; i < numDevices; i++) {
    int offset = i * itemsPerDevice;
    int count = (i == numDevices - 1) ? totalCount - offset : itemsPerDevice;

    // 为每个设备创建独立的内核并执行
    cl_mem buffer = clCreateBuffer(contexts[i], CL_MEM_READ_WRITE,
                                   count * sizeof(float), NULL, NULL);
    clSetKernelArg(kernel, 0, sizeof(cl_mem), &buffer);
    // ...
}
```

---

## 参考资源

- [Khronos OpenCL 官方网站](https://www.khronos.org/opencl/)
- [OpenCL 规范文档](https://www.khronos.org/registry/OpenCL/)
- [OpenCL GitHub 仓库](https://github.com/KhronosGroup/OpenCL-SDK)
- [Intel OpenCL 文档](https://www.intel.com/content/www/us/en/developer/tools/oneapi/opencl.html)
- [AMD OpenCL 文档](https://rocm.docs.amd.com/en/latest/)

---

## 版本信息

- 文档版本：1.0
- 最后更新：2026-03-07
- 支持的 OpenCL 版本：1.2, 2.0, 2.1, 2.2, 3.0
