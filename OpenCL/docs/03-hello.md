# 03 · 第一个程序：向量加法全流程

> 对应示例 `examples/03_hello/main.c`。参照 OiA 第 1–2 章的"卡片游戏"比喻与 HCL 第 2 章的向量相加实例。

## 3.1 全景：主机端八件事

一个最小的 OpenCL 计算流程，主机端只做八件事（示例按此编号）：

```
① 选平台与设备        clGetPlatformIDs / clGetDeviceIDs
② 创建上下文          clCreateContext
③ 创建命令队列        clCreateCommandQueueWithProperties
④ 创建并编译程序      clCreateProgramWithSource + clBuildProgram
⑤ 提取内核            clCreateKernel
⑥ 分配设备内存并传参  clCreateBuffer + clSetKernelArg
⑦ 执行               clEnqueueNDRangeKernel
⑧ 读回结果            clEnqueueReadBuffer
```

设备端只有一件事：`__kernel` 函数按全局编号各算一份。

## 3.2 逐步讲解（示例 03 的骨架）

### ① 平台与设备：优先 GPU，找不到就退回

```c
cl_platform_id platform;
cl_device_id device;
clu_pick_device(&platform, &device, NULL);   /* common/cl_utils.h 提供 */
clu_print_device_brief(device);
```

`clu_pick_device` 的逻辑：枚举平台 → 每个平台先要 `CL_DEVICE_TYPE_GPU` → 都没有就退回 `CL_DEVICE_TYPE_DEFAULT`。本机第一平台就是 NVIDIA GPU。

### ② 上下文：内存对象与队列的作用域

```c
cl_context ctx = clCreateContext(NULL, 1, &device, NULL, NULL, &err);
CL_CHECK(err);
```

第一个参数是属性数组（5 章用它挂 OpenGL/D3D 共享），`NULL` 即默认。上下文是**引用计数对象**——创建即 1，`clRetainContext`/`clReleaseContext` 增减，到 0 销毁。

### ③ 命令队列：2.0 起的唯一正规姿势

```c
cl_command_queue q = clCreateCommandQueueWithProperties(ctx, device, NULL, &err);
```

`NULL` 属性 = **顺序队列**（命令按提交序执行）。老教程里的 `clCreateCommandQueue` 从 2.0 起弃用，3.0 头文件里默认不声明（要 `CL_USE_DEPRECATED_OPENCL_1_2_APIS` 才能见到）——新代码一律写 WithProperties。

### ④ 程序：源码进来，编译成设备可执行

```c
cl_program prog = clu_build_program(ctx, device, K_SRC, NULL);
```

`clu_build_program` = `clCreateProgramWithSource` + `clBuildProgram`，失败时把 **build log 完整打印**再退出——这是内核排错的第一手段（6 章专讲选项与日志）。内核源码是字符串：

```c
"__kernel void vec_add(__global const float* a,   \n"
"                      __global const float* b,   \n"
"                      __global float* c,         \n"
"                      const unsigned int n)      \n"
"{                                                  \n"
"    unsigned int i = get_global_id(0);            \n"
"    if (i < n) c[i] = a[i] + b[i];                \n"
"}                                                  \n"
```

要点：

- `__kernel`：标记这是设备端入口；`__global`：指针指向设备全局内存。
- `get_global_id(0)`：本工作项在一维索引空间中的编号——**并行思维的核心**：不写 for 循环，写"编号为 i 的那份怎么算"。
- `if (i < n)`：守卫（8 章展开）。启动的 work-item 数量常大于逻辑数据量，多出来的必须闭嘴。

### ⑤ 内核：从程序里取一个函数

```c
cl_kernel k = clCreateKernel(prog, "vec_add", &err);
```

名字取错返回 `CL_INVALID_KERNEL_NAME`（28 章的注入实验清单里有它）。

### ⑥ 缓冲区与参数

```c
cl_mem ba = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                           N * sizeof(float), ha, &err);
...
clSetKernelArg(k, 0, sizeof(cl_mem), &ba);   /* 注意传的是 cl_mem 变量的地址 */
clSetKernelArg(k, 3, sizeof(cl_uint), &un);  /* 标量直接传值地址 */
```

`CL_MEM_COPY_HOST_PTR`：创建时把主机数据拷进去（此后主机怎么改都不影响设备）。参数绑定的规则：**指针参数传 `cl_mem`，标量参数传值的地址、长度必须与内核签名一致**——7 章展开所有标志与坑。

### ⑦ 执行：NDRange

```c
size_t global = N;
clEnqueueNDRangeKernel(q, k, 1, NULL, &global, NULL, 0, NULL, NULL);
```

一维、N 个 work-item、local size 交给运行时选择（8 章讲什么时候必须自己指定）。

### ⑧ 读回

```c
clEnqueueReadBuffer(q, bc, CL_TRUE, 0, N * sizeof(float), hc, 0, NULL, NULL);
```

`CL_TRUE` = 阻塞直到数据到手。最后主机侧逐元素对拍：

```
device : NVIDIA GeForce RTX 3060 (OpenCL 3.0 CUDA)
c[0]=0.00 c[1]=-6.50 c[1023]=15.50
03 hello PASS
```

## 3.3 错误处理纪律

每个返回 `cl_int` 的调用都可能失败。本教程所有示例统一用 `CL_CHECK`（`common/cl_utils.h`）：

```c
#define CL_CHECK(expr)                                      \
    do {                                                    \
        cl_int _e = (expr);                                 \
        if (_e != CL_SUCCESS) {                             \
            fprintf(stderr, "OpenCL error %d (%s) at %s:%d in %s\n", \
                    (int)_e, clu_err_str(_e), __FILE__, __LINE__, #expr); \
            exit(1);                                        \
        }                                                   \
    } while (0)
```

不检查返回值的 OpenCL 程序 = 用 `NULL` 队列/内核继续跑，崩在离事故现场很远的地方。错误码速查表在 [28 调试](28-debugging.md)。

## 3.4 资源释放

OpenCL 对象全是引用计数，顺序**逆序**释放即可：

```c
clReleaseMemObject / clReleaseKernel / clReleaseProgram
clReleaseCommandQueue / clReleaseContext
```

忘记释放 = 显存/句柄泄漏，进程退出由 OS 兜底（教学程序无所谓，服务端程序不行）。C++ 绑定（17 章）把这些全部 RAII 化。

## 3.5 编译与运行

```powershell
pwsh build.ps1 -Chapter 03
```

`build.ps1` 的验证标准：退出码 0 且输出含 `PASS`。

> 下一章：[04 平台与设备](04-devices.md)——`clGetDeviceInfo` 的四类查询形态与 `cl_name_version` 数组。
