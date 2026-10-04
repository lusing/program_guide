# 3. 第一个 OpenCL 程序：向量加法完整闭环

向量加法是 OpenCL 的 "Hello World"，但它比大多数语言的 Hello World 要长得多——因为在一个能跑起来的 OpenCL 程序里，"算 1024 个加法"这件事只占两行，其余两百多行全都在**搭台**：找设备、建上下文、建队列、编内核、开缓冲、搬数据、下发、等待、搬回、释放。

这一篇把 `examples/02-vector-add/` 逐段讲完。它是本教程后面所有章节的参照物：04 篇讲执行模型时会回到这里的 NDRange，05 篇讲核心对象时会回到这里的每个 `clCreate*`，05 篇 §5.4.5 与 `examples/07-async-events/` 讲顺序与乱序队列时会回到这里"为什么三条命令不需要事件也能有序"。

> **验证方式说明**：本篇的全部代码就是仓库里的 `examples/02-vector-add/main.c`（231 行）与 `examples/02-vector-add/kernels/vector_add.cl`（21 行），逐字引用，没有为了讲解而简化。在 `OpenCL/` 目录执行 `.\build.ps1 -Examples 02-vector-add` 即可从零编译并运行。3.5 节的输出是 Intel UHD Graphics 630 上的真实运行结果，属于**运行时数值级**证据：1024 个元素逐一与 CPU 参考值比对，外加 profiling 时间戳单调性断言。3.6 节列出的十处修正里，`err |=` 与错误码表缺失属于**主机编译级/文档核对**，`global size 向上取整` 属于**运行时数值级**（由 `examples/04-matmul-tiled/` 的实测反证）。

## 3.1 一个能跑的 OpenCL 程序要经过的十步

```text
 1. 找平台、按名字挑设备          clGetPlatformIDs / clGetDeviceIDs
 2. 建上下文                      clCreateContext
 3. 建命令队列（开 profiling）    clCreateCommandQueueWithProperties
 4. 读内核源码 → 建程序 → 编译    clCreateProgramWithSource / clBuildProgram
 5. 从程序里取出内核              clCreateKernel
 6. 分配主机数据                  malloc
 7. 建三个设备缓冲                clCreateBuffer
 8. 下发：写 A、写 B、跑内核、读 C  clEnqueueWriteBuffer / clEnqueueNDRangeKernel / clEnqueueReadBuffer
 9. 等它做完                      clFinish
10. 验证，然后按建立的逆序释放     clRelease*
```

第 4 步和第 8 步是新手最容易卡住的两处，而且**卡住时都不给有用的信息**：第 4 步失败只返回一个 `-11`，真正的编译错误在 `CL_PROGRAM_BUILD_LOG` 里，不主动去取就永远看不到；第 8 步失败只返回一个 `-54`，看不出是工作组太大还是全局尺寸没对齐。本篇 3.3.4 和 3.3.7 分别针对这两点。

## 3.2 内核：`kernels/vector_add.cl`

```c
// The simplest possible kernel: one work-item per element, no interaction between
// work-items, no local memory, no barriers.
//
// Written against OpenCL C 1.2 on purpose. Every device on this machine accepts
// 1.2, so this kernel is the portable baseline; later examples raise the level only
// where a feature genuinely needs it.
//
// Note the address-space qualifier on every pointer argument: __global. A kernel
// pointer with no address space is a compile error, which is exactly what the
// original tutorial's __const float* arguments were.
__kernel void vector_add(__global const float* a,
                         __global const float* b,
                         __global float* c,
                         const int n) {
    int i = get_global_id(0);
    // Bounds check. The host rounds the global size up to a multiple of the local
    // size, which means some work-items land past n and must not write.
    if (i < n) {
        c[i] = a[i] + b[i];
    }
}
```

三个要点：

**`__global` 不能省。** OpenCL C 要求内核的每个指针参数都带地址空间限定符。原始资料的矩阵乘法示例写的是 `__const float*`——`__const` 根本不是 OpenCL C 的关键字，编译器把指针读成"没有地址空间"，于是拒绝：

```text
error: pointer arguments to kernel functions must reside in '__global',
       '__constant' or '__local' address space
```

正确写法是 `__global const float*`：`__global` 是地址空间，`const` 是普通的 C 限定符，两个都要。这个反例被固化成了 `tools/cl-build-probe/fixtures/matmul_bad.cl`，可以随时重跑复现；改正版是 `matmul_good.cl`。详见 [09 篇](./09-practical-examples.md)。

**`const int n` 加上了越界保护。** 原始版本的内核没有 `n` 参数，直接 `c[idx] = a[idx] + b[idx]`。它在原始版本里能跑，只因为原始版本给 `clEnqueueNDRangeKernel` 传了 `local_work_size = NULL`，让驱动自己选分组，于是全局尺寸正好等于 10。

一旦你想控制工作组大小（性能调优时你一定会想），在 OpenCL 1.2 设备上就必须把全局尺寸**向上取整**到本地尺寸的整数倍——多出来的工作项就会越过 `n`，写到缓冲区外面。主机取整 + 内核保护是**同一个修正的两半，缺一个都不行**。3.3.7 节讲主机那一半，`examples/04-matmul-tiled/` 用实测把两半都演示一遍。

**按 OpenCL C 1.2 写。** 本机三台设备全部接受 1.2，所以 1.2 是可移植基线。[01 篇 1.6.1](./01-opencl-overview.md#161-cl_device_opencl_c_version-是默认值不是天花板) 讲过，1.2 是**默认**级别不是天花板，需要 2.x 特性时显式传 `-cl-std=CL2.0` 就能用；但那是"确实需要时"才做的事，第一个程序不需要。

## 3.3 主机程序：`main.c` 逐段

### 3.3.1 选设备：按名字匹配，跨全部平台

```c
int main(void) {
    const char* deviceHint = OCL_DEFAULT_DEVICE;

    // ---- 1. device -------------------------------------------------------
    // Selected by NAME across every platform. platforms[0] on this machine is
    // NVIDIA, so the naive choice would quietly benchmark the wrong GPU.
    cl_device_id device = NULL;
    char deviceName[256] = {0};
    if (ocl_pick_device(deviceHint, CL_DEVICE_TYPE_ALL, &device, deviceName, sizeof(deviceName)) != 0) {
        printf("[FAIL] no device matching \"%s\"\n", deviceHint);
        printf("       Run examples/01-device-query to see what this machine actually has.\n");
        return ocl_report(0);
    }
    ocl_report_device(device);
```

`OCL_DEFAULT_DEVICE` 是 `examples/common/ocl_util.h` 里的 `#define`，值为 `"UHD"`。`ocl_pick_device` 的完整实现见 [01 篇 1.4.1](./01-opencl-overview.md#141-正确的版本探测写法)。

两件事值得强调：

- **找不到目标设备时直接失败退出，绝不退回"随便挑一个"。** 一个跑在错设备上的示例什么也证明不了，而且它的输出看起来完全正常——这才是最糟的地方。
- **`ocl_report_device` 会把实际选中的设备打出来。** 每个示例都调它，所以日志本身就说明了"这些数字是哪台设备给的"。

输出：

```text
[device] Intel(R) UHD Graphics 630
[device] OpenCL 3.0 NEO  | OpenCL C 1.2  | max_work_group_size=256 | local_mem=65536 B
```

第二行就是 [01 篇 1.4 节](./01-opencl-overview.md#14-三个版本字符串问的根本不是同一件事)那个区分的现场版：设备版本 3.0，内核语言 1.2，工作组上限 **256**。

### 3.3.2 上下文

```c
    // ---- 2. context ------------------------------------------------------
    cl_int err = CL_SUCCESS;
    cl_context context = clCreateContext(NULL, 1, &device, NULL, NULL, &err);
    if (!context || err != CL_SUCCESS) {
        printf("[FAIL] clCreateContext -> %d %s\n", err, ocl_err_name(err));
        return ocl_report(0);
    }
```

`clCreateContext` 的六个参数里，本教程永远只用得上第一、二、三、六个：

| 参数 | 本例取值 | 说明 |
|------|---------|------|
| `properties` | `NULL` | 平台已经在设备里隐含了；只有做 GL/D3D 互操作时才需要显式给 `CL_CONTEXT_PLATFORM` |
| `num_devices` | `1` | **一个设备一个 context**。原始资料在这里传了 `numDevices`（该平台的全部设备），然后队列却只建在 `devices[0]` 上——能跑，但白建了一堆用不上的东西 |
| `devices` | `&device` | |
| `pfn_notify` / `user_data` | `NULL` / `NULL` | 错误回调。它在**另一个线程**里被调用，写日志要小心线程安全 |
| `errcode_ret` | `&err` | |

注意 `if (!context || err != CL_SUCCESS)` 这个双重判断。只判 `err` 不够：某些实现在失败时也会返回一个非空句柄；只判句柄也不够：`errcode_ret` 是唯一能告诉你**为什么**失败的渠道。两个都判。

### 3.3.3 命令队列：顺手把 profiling 打开

```c
    // ---- 3. command queue, with profiling enabled ------------------------
    // CL_QUEUE_PROFILING_ENABLE is what makes clGetEventProfilingInfo return
    // real timestamps instead of CL_PROFILING_INFO_NOT_AVAILABLE.
    cl_queue_properties props[] = { CL_QUEUE_PROPERTIES, CL_QUEUE_PROFILING_ENABLE, 0 };
    cl_command_queue queue = clCreateCommandQueueWithProperties(context, device, props, &err);
    if (!queue || err != CL_SUCCESS) {
        printf("[FAIL] clCreateCommandQueueWithProperties -> %d %s\n", err, ocl_err_name(err));
        clReleaseContext(context);
        return ocl_report(0);
    }
```

`clCreateCommandQueueWithProperties` 是 OpenCL **2.0** 的 API（不是 2.2，也不是 3.0）。它取代了 1.0 的 `clCreateCommandQueue`——后者在 3.0 里是**弃用而非移除**，本机的 `cl.h` 两个都有，所以两个都能编。本教程统一用新的那个。

用它就要求 `CL_TARGET_OPENCL_VERSION >= 200`。工程里设的是 300，原因见 [02 篇 2.6](./02-environment-setup.md#26-cl_target_opencl_version为什么必须是-300)——那里附了实测的 cl.exe 退出码 2 与完整错误输出。

`props` 是一个"键-值-键-值…-0"的属性列表。这里只有一个属性：

```c
cl_queue_properties props[] = { CL_QUEUE_PROPERTIES, CL_QUEUE_PROFILING_ENABLE, 0 };
```

**这个标志决定了 3.3.9 节能不能拿到时间戳。** 不加它，`clGetEventProfilingInfo` 会返回 `CL_PROFILING_INFO_NOT_AVAILABLE`，而程序其余部分照常工作——你会得到一堆 0，然后以为设备很慢。原始资料传的是 `0`（无属性），所以它根本没法做 profiling。

想要乱序执行，就把标志换成 `CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE | CL_QUEUE_PROFILING_ENABLE`——但**先得查设备支不支持**，见 [05 篇 §5.4.4](./05-core-concepts.md)。

### 3.3.4 程序：从文件读源码，并且**无论成败都取构建日志**

```c
    // ---- 4. program, built from a .cl file -------------------------------
    char* source = ocl_read_file("kernels/vector_add.cl");
    if (!source) { clReleaseCommandQueue(queue); clReleaseContext(context); return ocl_report(0); }

    cl_program program = clCreateProgramWithSource(context, 1, (const char**)&source, NULL, &err);
    free(source);
    if (!program || err != CL_SUCCESS) {
        printf("[FAIL] clCreateProgramWithSource -> %d %s\n", err, ocl_err_name(err));
        clReleaseCommandQueue(queue); clReleaseContext(context);
        return ocl_report(0);
    }

    err = clBuildProgram(program, 1, &device, NULL, NULL, NULL);
    // Fetch the log whether the build succeeded or not: Intel's driver emits
    // useful warnings even for kernels that compile.
    {
        size_t logSz = 0;
        clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, 0, NULL, &logSz);
        if (logSz > 1) {
            char* log = (char*)malloc(logSz + 1);
            if (log) {
                clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, logSz, log, NULL);
                log[logSz] = '\0';
                printf("[build log]\n%s\n", log);
                free(log);
            }
        }
    }
    if (err != CL_SUCCESS) {
        printf("[FAIL] clBuildProgram -> %d %s\n", err, ocl_err_name(err));
        clReleaseProgram(program); clReleaseCommandQueue(queue); clReleaseContext(context);
        return ocl_report(0);
    }
    printf("[build] program compiled for %s\n", deviceName);
```

四个细节，每个都对应一个真实踩过的坑：

**内核放在单独的 `.cl` 文件里，不塞进 C 字符串。** 原始资料把内核写成一行拼接的字符串字面量。那样写有三个坏处：编辑器不给内核做语法高亮、`tools/cl-build-probe` 没法单独拿它去编、行号信息全丢（构建日志里的 `<kernel>:3:12` 变得毫无意义）。

**`free(source)` 紧跟在 `clCreateProgramWithSource` 之后。** 这个调用会**复制**源码，返回后原缓冲区就没用了。很多人以为要一直留着，于是要么泄漏要么在别处误释放。

**取日志的两次调用是"先问长度、再取内容"的标准两段式**，`logSz > 1` 而不是 `logSz > 0`：驱动返回的长度**包含结尾的 NUL**，所以只有 `> 1` 才说明真有内容。

**日志在编译成功时也取。** 原始资料只在失败分支里取，于是编译成功但带警告的情况完全看不见。Intel 的驱动对能编过的内核也经常给有用提示。而且它 `malloc(logSize)` 没加 1、也没写 `log[logSize] = '\0'`——`logSize` 为 0 时 `malloc(0)` 是实现定义行为，接着用 `%s` 打印它就是未定义行为。

### 3.3.5 取出内核

```c
    cl_kernel kernel = clCreateKernel(program, "vector_add", &err);
    if (!kernel || err != CL_SUCCESS) {
        printf("[FAIL] clCreateKernel -> %d %s\n", err, ocl_err_name(err));
        clReleaseProgram(program); clReleaseCommandQueue(queue); clReleaseContext(context);
        return ocl_report(0);
    }
```

`"vector_add"` 必须和 `.cl` 里的 `__kernel void vector_add(...)` **逐字符相同**，包括大小写。写错会得到 `-46 CL_INVALID_KERNEL_NAME`，这个错误码还算直白。

一个 `cl_program` 可以含多个内核，`examples/07-async-events/` 就是从同一个 program 里取了三个（`scale_kernel`、`offset_kernel`、`add_kernel`）。

### 3.3.6 主机数据与设备缓冲

```c
    // ---- 5. host data ----------------------------------------------------
    float* a = (float*)malloc(N * sizeof(float));
    float* b = (float*)malloc(N * sizeof(float));
    float* c = (float*)malloc(N * sizeof(float));
    if (!a || !b || !c) { printf("[FAIL] host allocation\n"); return ocl_report(0); }
    for (int i = 0; i < N; i++) {
        a[i] = (float)i;
        b[i] = (float)(i * 2);
        c[i] = -1.0f;                       // sentinel, so an unwritten element is obvious
    }

    // ---- 6. device buffers ----------------------------------------------
    cl_mem bufA = clCreateBuffer(context, CL_MEM_READ_ONLY,  N * sizeof(float), NULL, &err);
    cl_mem bufB = clCreateBuffer(context, CL_MEM_READ_ONLY,  N * sizeof(float), NULL, &err);
    cl_mem bufC = clCreateBuffer(context, CL_MEM_WRITE_ONLY, N * sizeof(float), NULL, &err);
    if (!bufA || !bufB || !bufC) {
        printf("[FAIL] clCreateBuffer -> %d %s\n", err, ocl_err_name(err));
        return ocl_report(0);
    }
```

**`c[i] = -1.0f` 这个哨兵值不是装饰。** 如果内核因为越界保护跳过了某些元素、或者读回操作没做完，`c` 里就会留下 `-1.0`，一眼能看出来。让输出缓冲区保持未初始化（`malloc` 出来的脏内存）是最常见的坏习惯：脏内存偶尔正好等于正确答案，于是你的验证通过了，而程序其实是坏的。

**`CL_MEM_READ_ONLY` / `CL_MEM_WRITE_ONLY` 是从内核视角说的**，不是从主机视角。`bufA` 标 `READ_ONLY` 意思是"内核只读它"，主机当然还是要往里写。这个方向性搞反是初学者的高频错误。

原始资料在这里用了 `CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR`，创建时就把数据拷进去。那是合法的、而且少一次 enqueue，但本教程**故意不用**：把 `clEnqueueWriteBuffer` 显式写出来，才能在 `examples/07-async-events/` 与 [05 篇 §5.7](./05-core-concepts.md) 里讨论"写、算、读三者的依赖关系"。`CL_MEM_COPY_HOST_PTR` 的拷贝时机是由驱动决定的，你想给它排依赖也排不了。

这两个标志只是**性能提示**，不是访问控制。标了 `READ_ONLY` 的缓冲区被内核写入，多数实现不会报错。别把它当断言用。

### 3.3.7 下发：写、算、读，以及全局尺寸向上取整

```c
    // ---- 7. enqueue: write, compute, read --------------------------------
    // All three go onto ONE in-order queue, so they execute in submission order
    // without needing explicit event dependencies. examples/07-async-events shows
    // what changes when you want them to overlap instead.
    cl_event evWrite = NULL, evKernel = NULL, evRead = NULL;

    err = clEnqueueWriteBuffer(queue, bufA, CL_FALSE, 0, N * sizeof(float), a, 0, NULL, &evWrite);
    if (err != CL_SUCCESS) printf("[FAIL] write A -> %d %s\n", err, ocl_err_name(err));
    err = clEnqueueWriteBuffer(queue, bufB, CL_FALSE, 0, N * sizeof(float), b, 0, NULL, NULL);
    if (err != CL_SUCCESS) printf("[FAIL] write B -> %d %s\n", err, ocl_err_name(err));

    int n = N;
    clSetKernelArg(kernel, 0, sizeof(cl_mem), &bufA);
    clSetKernelArg(kernel, 1, sizeof(cl_mem), &bufB);
    clSetKernelArg(kernel, 2, sizeof(cl_mem), &bufC);
    clSetKernelArg(kernel, 3, sizeof(int), &n);

    // Global size rounded UP to a multiple of the local size. On an OpenCL 1.2
    // device an unrounded global size is rejected with -54
    // CL_INVALID_WORK_GROUP_SIZE even though the kernel guards its own accesses -
    // so 1024 with local 64 is fine, but 1000 with local 64 would not be.
    size_t localSize = 64;
    size_t globalSize = ocl_round_up((size_t)N, localSize);
    printf("[launch] global=%zu local=%zu (n=%d, rounded up=%s)\n",
           globalSize, localSize, N, globalSize == (size_t)N ? "no change" : "yes");

    err = clEnqueueNDRangeKernel(queue, kernel, 1, NULL, &globalSize, &localSize, 0, NULL, &evKernel);
    if (err != CL_SUCCESS) {
        printf("[FAIL] clEnqueueNDRangeKernel -> %d %s\n", err, ocl_err_name(err));
        printf("       Check global%%local==0 and local<=CL_DEVICE_MAX_WORK_GROUP_SIZE.\n");
        return ocl_report(0);
    }

    err = clEnqueueReadBuffer(queue, bufC, CL_FALSE, 0, N * sizeof(float), c, 0, NULL, &evRead);
    if (err != CL_SUCCESS) printf("[FAIL] read C -> %d %s\n", err, ocl_err_name(err));

    // Blocking read was CL_FALSE, so nothing is guaranteed until we wait.
    clFinish(queue);
```

**顺序队列 = 不需要事件就能有序。** 三条命令进的是同一个 in-order queue，所以设备侧保证按提交顺序执行。`evWrite` / `evKernel` / `evRead` 在这里**不是用来排序的**，只是用来做 3.3.9 节的 profiling。这一点在 [05 篇 §5.4.5](./05-core-concepts.md) 与 `examples/07-async-events/` 会被彻底展开：换成乱序队列后，没有等待列表就会出现真实的竞争。

**`clSetKernelArg` 的第二个参数是"参数值的字节数"，不是"数据的字节数"。** 传缓冲区时是 `sizeof(cl_mem)`——一个句柄的大小；传标量时是 `sizeof(int)`。写成 `sizeof(float*)` 在 64 位上碰巧和 `sizeof(cl_mem)` 一样，所以这个错误常常潜伏很久。

**`ocl_round_up` 是本机 OpenCL 1.2 设备的硬性要求。** 这一条是本次验证中查出来、原文完全没提的坑：

> 在 OpenCL 1.2 设备上，`clEnqueueNDRangeKernel` 要求 `global_work_size` 是 `local_work_size` 的**整数倍**（逐维），否则返回 `-54 CL_INVALID_WORK_GROUP_SIZE`——**即使内核已经对每一次访存做了越界保护**。

`examples/04-matmul-tiled/` 用一个 100×100 的矩阵配 16×16 的本地尺寸实测了这个失败：内核的保护写得好好的，照样 `-54`。`examples/06-image-brightness/` 的 case E/F 也复现了一次（100×37 不取整 → `-54`；取整到 112×48 → 3700/3700 全对）。

`-54` 这个错误码起得很有误导性：它听起来像资源不够，实际上是参数不合法。所以本例在失败时直接打印两条检查项：

```text
       Check global%local==0 and local<=CL_DEVICE_MAX_WORK_GROUP_SIZE.
```

本例里 `N = 1024`、`localSize = 64`，1024 本来就是 64 的整数倍，所以取整是空操作——日志里明确写出了 `rounded up=no change`，不让读者以为这里发生了什么。

**`clEnqueueWriteBuffer` 的第三个参数是"阻塞与否"，这是主机侧的性质。** 本例传 `CL_FALSE`（非阻塞），意思是"这个调用立刻返回，拷贝在后台排队"。它**不影响设备侧的执行顺序**——在顺序队列里，非阻塞的写仍然会先于后面的内核完成。所以末尾必须 `clFinish(queue)`：非阻塞读回来的数据在 `clFinish` 之前什么都不是。

原始资料在 `clEnqueueReadBuffer` 传的是 `CL_TRUE`（阻塞），那样就不需要 `clFinish`。两种都对，但本教程选非阻塞 + 显式 `clFinish`，因为这正是 `examples/07-async-events/` 要讨论的形状，而且它让 case B 能演示"偷看未完成的缓冲区会看到什么"。

### 3.3.8 验证：和 CPU 参考值逐元素比对

```c
    // ---- 8. verify against a CPU reference -------------------------------
    int bad = 0;
    for (int i = 0; i < N; i++) {
        float ref = (float)i + (float)(i * 2);
        if (c[i] != ref) {
            if (bad < 5) printf("  mismatch i=%d got %f want %f\n", i, c[i], ref);
            bad++;
        }
    }
    printf("[verify] %d/%d elements correct\n", N - bad, N);
```

三点：

- **不 `break`。** 原始资料在第一个不匹配处就 `break`，于是你永远只知道"错了"，不知道"错了几个、错在哪"。"1024 个里错了 3 个"和"1024 个全错"指向完全不同的 bug。
- **最多打印前 5 条明细**，避免刷屏，但计数是全量的。
- **这里用 `!=` 精确比较是合理的**，因为 `i + 2*i` 对 `i < 1024` 都是小整数，float 精确可表示。换成含除法或累加的计算就必须用 epsilon——`examples/03-matmul-naive/` 和 `examples/05-reduce-sum/` 就是这么做的。

### 3.3.9 Profiling：命令到底什么时候跑的

```c
    // ---- 9. profiling: when did each stage actually run? -----------------
    // Timestamps are nanoseconds since an unspecified epoch, so only DIFFERENCES
    // and ORDERING are meaningful.
    int profOk = 1;
    if (evKernel) {
        cl_ulong queued  = profTime(evKernel, CL_PROFILING_COMMAND_QUEUED);
        cl_ulong submit  = profTime(evKernel, CL_PROFILING_COMMAND_SUBMIT);
        cl_ulong start   = profTime(evKernel, CL_PROFILING_COMMAND_START);
        cl_ulong end     = profTime(evKernel, CL_PROFILING_COMMAND_END);
        if (!queued || !submit || !start || !end) {
            printf("[profiling] timestamps unavailable\n");
            profOk = 0;
        } else {
            printf("[profiling] kernel queued->submit %llu ns, submit->start %llu ns, execute %llu ns\n",
                   (unsigned long long)(submit - queued),
                   (unsigned long long)(start - submit),
                   (unsigned long long)(end - start));
            // The four stamps must be non-decreasing. A driver that reports them out
            // of order would make every bandwidth number derived from them fiction.
            if (!(queued <= submit && submit <= start && start <= end)) {
                printf("[profiling] timestamps NOT monotonic: %llu %llu %llu %llu\n", ...);
                profOk = 0;
            } else {
                printf("[profiling] timestamps monotonic: OK\n");
            }
        }
    } else {
        profOk = 0;
    }
```

四个时间戳把一条命令的一生分成四段：

```text
QUEUED ──► SUBMIT ──► START ──► END
  │           │          │        │
  │           │          │        └─ 内核在设备上跑完
  │           │          └────────── 内核开始在设备上跑
  │           └───────────────────── 命令交给设备驱动
  └───────────────────────────────── 命令进队列（clEnqueue* 返回前后）
```

时间戳是**纳秒，从一个未指明的纪元开始**。所以只有**差值**和**先后关系**有意义，绝对值没有意义，更不能拿去和主机侧的 `clock()` 比。

本例断言的是 `queued <= submit <= start <= end`。这是一条**能失败**的断言——如果驱动报出乱序的时间戳，那么由它算出来的任何带宽数字都是虚构的，必须当场暴露。

### 3.3.10 释放：按建立的逆序

```c
    // ---- 10. release, newest first ---------------------------------------
    if (evWrite)  clReleaseEvent(evWrite);
    if (evKernel) clReleaseEvent(evKernel);
    if (evRead)   clReleaseEvent(evRead);
    clReleaseMemObject(bufA);
    clReleaseMemObject(bufB);
    clReleaseMemObject(bufC);
    clReleaseKernel(kernel);
    clReleaseProgram(program);
    clReleaseCommandQueue(queue);
    clReleaseContext(context);
    free(a); free(b); free(c);

    int pass = (bad == 0) && profOk;
    printf("\nassert all %d elements match CPU reference : %s\n", N, bad == 0 ? "OK" : "FAILED");
    printf("assert profiling timestamps monotonic      : %s\n", profOk ? "OK" : "FAILED");
    return ocl_report(pass);
}
```

OpenCL 的对象都是引用计数的，`clRelease*` 只是减一。但**逆序释放**仍然是对的写法：`kernel` 引用 `program`，`program` 和 `queue` 和 `buf*` 都引用 `context`。正序释放在多数实现上也不会崩，但一旦出问题，排查成本远高于按逆序写。

最后 `return ocl_report(pass)` 打出 `[RESULT] PASS` 并返回 0——这是 `build.ps1` 判定所有示例的统一契约，见 [02 篇 2.8](./02-environment-setup.md#28-项目结构)。

## 3.4 编译与运行

**用仓库脚本（推荐）：**

```powershell
cd OpenCL
.\build.ps1 -Examples 02-vector-add
```

脚本会自动发现 vcvars64 和 OpenCL SDK（见 [02 篇 2.4](./02-environment-setup.md#24-自动发现toolsopencl-sdkps1)），编译到 `build\02-vector-add.exe`，然后**在该示例自己的目录下运行它**——这样 `ocl_read_file("kernels/vector_add.cl")` 的相对路径才成立。

**手工用 MSVC：**

```bat
call "d:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
cd examples\02-vector-add
cl /nologo /utf-8 /W3 /EHsc /D_CRT_SECURE_NO_WARNINGS /DCL_TARGET_OPENCL_VERSION=300 /TC ^
   /I"D:\cuda\13.3\include" /I"..\common" main.c /Fe:..\..\build\02-vector-add.exe ^
   /link /LIBPATH:"D:\cuda\13.3\lib\x64" OpenCL.lib
..\..\build\02-vector-add.exe
```

**用 CMake** 见 [02 篇 2.7](./02-environment-setup.md#27-cmake-配置)。

原始资料给的 MinGW 命令行用的是 `C:\Program Files (x86)\Intel\OpenCL SDK\` 这个本机不存在的路径，已删除。MinGW 本身可以编 OpenCL 程序（只要指向任一 SDK 的头和库），但本教程不做它的验证，因为 `build.ps1` 走的是 MSVC。

## 3.5 实测输出

Intel UHD Graphics 630 上的真实运行结果：

```text
[device] Intel(R) UHD Graphics 630
[device] OpenCL 3.0 NEO  | OpenCL C 1.2  | max_work_group_size=256 | local_mem=65536 B
[build] program compiled for Intel(R) UHD Graphics 630
[launch] global=1024 local=64 (n=1024, rounded up=no change)
[verify] 1024/1024 elements correct
[profiling] kernel queued->submit 10900 ns, submit->start 1766593 ns, execute 4499 ns
[profiling] timestamps monotonic: OK

assert all 1024 elements match CPU reference : OK
assert profiling timestamps monotonic      : OK
[RESULT] PASS
```

那行 profiling 值得停下来看：

```text
queued->submit    10900 ns   =  0.011 ms
submit->start   1766593 ns   =  1.77  ms   ◄── 比执行时间长 393 倍
execute            4499 ns   =  0.0045 ms
```

**内核真正执行只花了 4.5 微秒，而从提交到开始执行等了 1.77 毫秒。** 连跑三次，`execute` 稳定在 4166–4499 ns，`submit->start` 在 1.21–2.14 ms 之间波动：

| 运行 | queued→submit | submit→start | execute |
|------|--------------|-------------|---------|
| 1 | 10900 ns | 1766593 ns | 4499 ns |
| 2 | 573300 ns | 2140606 ns | 4166 ns |
| 3 | 12700 ns | 1210045 ns | 4166 ns |

这条数据说明两件对性能工作至关重要的事：

1. **小数据量的 OpenCL 程序，开销几乎全在启动，不在计算。** 1024 个 float 的加法对 GPU 来说是零头；1.77 ms 是驱动首次下发内核时的初始化。如果你的问题规模只有几千个元素，用 OpenCL 一定比 CPU 慢——这不是 bug，是常数项。
2. **profiling 时间戳有噪声，单次测量不能用来下结论。** `submit->start` 波动了 1.7 倍。要测性能，得跑多次取统计量，而不是相信一次读数。

也正因为如此，本例的断言是**单调性**而不是**任何具体的时长阈值**。一个断言"内核必须在 1 ms 内跑完"的检查会随机失败，而它失败时你什么也学不到。

## 3.6 原始版本被推翻的十处写法

原始资料的向量加法程序能跑，但它在十个地方会误导读者。每一条都改进了正文，并列在这里，因为**知道哪里容易错比看到正确答案更有用**：

| # | 原始写法 | 问题 | 改成 | 通道 |
|---|---------|------|------|------|
| 1 | `platforms[0]` | 本机 `platforms[0]` 是 **NVIDIA**，不是 Intel。整篇教程会跑在错误的设备上 | `ocl_pick_device("UHD", ...)`，跨全部平台按名字匹配 | 设备元数据级 |
| 2 | `err \|= clSetKernelArg(...)` | **按位或错误码是错的**。`-30 \| -46` 的结果不对应任何已知错误，后面 `clErrorString(err)` 打出来的是虚构的名字 | `keepFirst(acc, e)`，保留第一个真实错误（见 `examples/07-async-events/main.c`） | 文档核对 |
| 3 | `clErrorString` 的 switch | **漏掉了 `CL_BUILD_PROGRAM_FAILURE`（-11）**——内核编译失败时最可能遇到的那个错误码，会被打成 "Unknown error"。同样漏了 `CL_INVALID_VALUE`(-30)、`CL_INVALID_KERNEL_NAME`(-46)、`CL_INVALID_WORK_GROUP_SIZE` 之外的十几个 | `ocl_err_name()`，覆盖 37 个错误码 | 文档核对 |
| 4 | `clCreateCommandQueue(ctx, dev, 0, &err)` | 属性传 `0`，profiling 关着；而且这个 API 在 3.0 里已弃用 | `clCreateCommandQueueWithProperties` + `CL_QUEUE_PROFILING_ENABLE` | 主机编译级 + 运行时 |
| 5 | 内核无 `n` 参数、无越界保护 | 一旦主机把全局尺寸向上取整（1.2 设备上指定本地尺寸时**必须**这么做），多出的工作项就会写穿缓冲区 | 加 `const int n` + `if (i < n)` | 运行时数值级 |
| 6 | `local_work_size = NULL` | 让驱动自己选分组，所以从来没撞上 `-54`。这也意味着你无法控制占用率 | 显式给 `localSize`，主机侧 `ocl_round_up` | 运行时数值级 |
| 7 | 构建日志只在失败分支取 | 编译成功但有警告时完全看不见；而且 `malloc(logSize)` 没 +1、没写 NUL 终止符，`logSize == 0` 时用 `%s` 打印是 UB | 成败都取，`logSz > 1` 才分配，`malloc(logSz + 1)` 并显式写 `log[logSz] = '\0'` | 主机编译级 |
| 8 | 内核源码塞进 C 字符串字面量 | 没有语法高亮、没法单独用 `cl-build-probe` 编、构建日志里的行号失去意义 | 独立 `kernels/*.cl`，用 `ocl_read_file` 读 | — |
| 9 | `clCreateContext(NULL, numDevices, devices, ...)` 但队列只建在 `devices[0]` | 给整个平台的所有设备建了 context，`clBuildProgram` 也为全部设备编译了一遍，然后只用其中一个 | context、queue、build 全部针对**一个**设备 | — |
| 10 | 验证循环里 `break` | 只知道"错了"，不知道错了几个、错在哪。"1024 里错 3 个"和"全错"是完全不同的 bug | 全量计数，只截断打印明细 | — |

第 2 条和第 3 条组合起来尤其致命：错误码被按位或成一个无意义的数，再交给一个漏了最常见错误码的翻译函数。等于是**两层都在撒谎**，而你看到的输出还是一句自信的英文。

## 3.7 本篇涉及的错误码

| 码 | 名字 | 在这个程序里通常意味着 |
|----|------|---------------------|
| 0 | `CL_SUCCESS` | — |
| -1 | `CL_DEVICE_NOT_FOUND` | `clGetDeviceIDs` 的 `type` 过滤掉了所有设备 |
| -5 | `CL_OUT_OF_RESOURCES` | 设备资源耗尽。注意它**不是** `CL_INVALID_VALUE` |
| -7 | `CL_PROFILING_INFO_NOT_AVAILABLE` | `clGetEventProfilingInfo` 拿不到时间戳——**队列创建时没开 `CL_QUEUE_PROFILING_ENABLE`**，见 3.3.3 |
| -11 | `CL_BUILD_PROGRAM_FAILURE` | 内核编译失败。**去看 `CL_PROGRAM_BUILD_LOG`，别猜** |
| -30 | `CL_INVALID_VALUE` | 参数不合法。`clSetKernelArg` 的 `sizeof` 传错、`clGetDeviceInfo` 的缓冲区大小写错（见 [01 篇 1.4.2](./01-opencl-overview.md#142-一个查询类型的坑size_t-不是-cl_uint)）都是它 |
| -46 | `CL_INVALID_KERNEL_NAME` | 名字和 `.cl` 里的不一致（含大小写） |
| -47 | `CL_INVALID_KERNEL_DEFINITION` | 内核签名和参数个数不匹配 |
| -48 | `CL_INVALID_KERNEL` | `cl_kernel` 句柄本身无效 |
| -54 | `CL_INVALID_WORK_GROUP_SIZE` | 本地尺寸超过 `CL_DEVICE_MAX_WORK_GROUP_SIZE`，**或全局尺寸不是本地尺寸的整数倍** |

完整列表与调试流程见 [10 篇](./10-debugging-faq.md)。表里的数值全部对照 `D:\cuda\13.3\include\CL\cl.h` 第 197–255 行核过——`CL_INVALID_VALUE` 是 -30 而不是 -5，`CL_INVALID_KERNEL_DEFINITION` 是 -47 而不是 -48，这两处正是本表初稿写错、被核对纠正的地方。

---

上一篇：[02-environment-setup.md](./02-environment-setup.md) ｜ 下一篇：[04-programming-model.md](./04-programming-model.md) —— 主机-设备模型、NDRange 与计算单元层次，把 3.3.7 那个 `global=1024 local=64` 讲透。
