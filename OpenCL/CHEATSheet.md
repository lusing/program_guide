# OpenCL Windows 速查表（CHEATSheet）

> 配合 [docs/](docs/) 32 章使用；坑位带 ✳ 的都是本仓库实测（NVIDIA CUDA 3.0 / RTX 3060 + Intel OpenCL 3.0 / 12700F，2026-09）。

## 1. 主机端八步骨架

```c
clGetPlatformIDs → clGetDeviceIDs → clCreateContext
→ clCreateCommandQueueWithProperties → clCreateProgramWithSource + clBuildProgram
→ clCreateKernel → clCreateBuffer + clSetKernelArg
→ clEnqueueNDRangeKernel → clEnqueueReadBuffer → (释放：逆序)
```

## 2. 常用 API 微手册

```c
/* 平台/设备 */
clGetPlatformIDs(0, NULL, &n);  clGetPlatformIDs(n, ps, NULL);
clGetDeviceIDs(plat, CL_DEVICE_TYPE_GPU, 1, &dev, NULL);
clGetDeviceInfo(dev, CL_DEVICE_*, size, buf, NULL);      /* 两遍法问字符串 */

/* 对象 */
cl_context   c = clCreateContext(props /*可NULL*/, 1, &dev, NULL, NULL, &err);
cl_command_queue q = clCreateCommandQueueWithProperties(c, dev, qprops, &err);
cl_program   p = clCreateProgramWithSource(c, 1, &src, NULL, &err);
               clBuildProgram(p, 1, &dev, "-cl-fast-relaxed-math", NULL, NULL);
cl_kernel    k = clCreateKernel(p, "name", &err);
cl_mem       b = clCreateBuffer(c, CL_MEM_READ_ONLY|CL_MEM_COPY_HOST_PTR, sz, h, &err);

/* 参数（三类） */
clSetKernelArg(k, 0, sizeof(cl_mem), &b);   /* buffer */
clSetKernelArg(k, 1, sizeof(float), &f);    /* 标量 */
clSetKernelArg(k, 2, bytes, NULL);          /* __local 动态 */

/* 执行（3 维参数：offset / global / local） */
size_t g = N, l = 256;
clEnqueueNDRangeKernel(q, k, 1, NULL, &g, &l, 0, NULL, &event);

/* 数据 */
clEnqueueWriteBuffer/ReadBuffer(q, b, CL_TRUE, off, sz, h, 0, NULL, NULL);
clEnqueueMapBuffer(q, b, CL_TRUE, CL_MAP_WRITE_INVALIDATE_REGION, 0, sz, ...);
clEnqueueUnmapMemObject(q, b, mapped, ...);
clEnqueueCopyBuffer / clEnqueueFillBuffer / clEnqueue{Read,Write}BufferRect;
clEnqueueReadImage/WriteImage(q, img, CL_TRUE, origin3, region3, 0, 0, h, ...);

/* 事件 */
clWaitForEvents(1, &ev);
clEnqueueMarkerWithWaitList(q, 0, NULL, &ev);
clSetEventCallback(ev, CL_COMPLETE, cb, user);
clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_{QUEUED,SUBMIT,START,END}, ...);
/* 队列必须带 CL_QUEUE_PROFILING_ENABLE 创建，否则 -7 */
```

## 3. 内核语言速查

```c
__kernel void k(__global const float* in, __global float* out,
                __constant float4* w, __local float* scratch /*动态*/,
                const int n) {
    int gid = get_global_id(0), lid = get_local_id(0), lsz = get_local_size(0);
    __local float stat[256];                    /* 静态 local */
    float4 v = (float4)(1.f);                   /* 向量+广播 */
    float4 r = v.xyxy * v.wzyx + v.x;           /* swizzle */
    uint4 bits = as_uint4(v);                   /* 位重解释 */
    int4  ci = convert_int4_sat_rte(v);         /* 值转换+饱和+舍入 */
    float t = select(a, b, cond) ...            /* 向量三目（真取 b） */
    float4 sh = shuffle(v, (uint4)(3,2,1,0));   /* 分量重排 */
    barrier(CLK_LOCAL_MEM_FENCE | CLK_GLOBAL_MEM_FENCE);
    atomic_add(p_int, 1);                       /* 只 int/uint（float 无原子加） */
}
```

坐标恒等式：`gid = offset + group_id * local_size + local_id`；`gsize = num_groups * local_size`。

## 4. 环境与工具链

| 项 | 值/做法 |
|---|---|
| 运行时 | 显卡驱动自带（ICD 架构：OpenCL.dll 查注册表 Khronos\OpenCL\Vendors） |
| 头/库 | CUDA Toolkit 的 `include/CL` + `lib/x64/OpenCL.lib`（或 Khronos OpenCL-SDK） |
| C++ 绑定 | `CL/opencl.hpp`（本仓库 vendor 在 examples/common/CL/） |
| 编译 | `cl /utf-8 /DCL_TARGET_OPENCL_VERSION=300 /W3 x.c /I<inc> /link /LIBPATH:<lib> OpenCL.lib` |
| 枚举验证 | `pwsh build.ps1 -Chapter 02`（迷你 clinfo）或装 clinfo |
| SPIR-V 编译 | MSYS2 clang：`clang -cl-std=CL1.2 -target spirv64 -c k.cl -o k.spv`（scoop llvm 无 SPIRV 后端 ✳） |

## 5. 坑位总索引（全部实测）

| # | 坑 | 章 |
|---|---|---|
| 1 | ✳ `CL_DEVICE_OPENCL_C_FEATURES` 返回 cl_name_version **数组**不是字符串（%s 打印为空） | 04 |
| 2 | ✳ NVIDIA `CL_PROGRAM_BINARY_TYPE` 必须走 `clGetProgramBuildInfo`（GetProgramInfo 报 -30）；EXECUTABLE=4（枚举跳过 3） | 06 |
| 3 | ✳ `cl_buffer_region.origin` 单位是字节；`CL_DEVICE_MEM_BASE_ADDR_ALIGN` 单位是**位**（NVIDIA 4096bit=512B） | 07 |
| 4 | ✳ **BufferRect 的 origin[1]/[2] 单位是行/片（乘 pitch），不是字节**——写 36 想表达字节实际读 36 行外，静默越界还返回 SUCCESS | 07 |
| 5 | ✳ 读回长度超主机数组 = 栈破坏，症状离现场很远 | 07 |
| 6 | ✳ NVIDIA 第三维 work-item 上限 64（1024×1024×**64**） | 04/08 |
| 7 | ✳ `upsample` 是位拼接：short+ushort→uint 占满 32 位；想要字节拼用 char+uchar | 11 |
| 8 | ✳ 线性采样 texel 中心在 i+0.5：`i0=floor(u-0.5), a=frac(u-0.5)`；最近邻是**截断** `(int)u` 不是四舍五入 | 15 |
| 9 | ✳ 采样格式组合先 `clGetSupportedImageFormats` 问上下文（设备级无"格式数"查询） | 15 |
| 10 | ✳ NVIDIA 无 SPIR-V（IL_VERSION 空）；Intel CPU 有（1.0–1.4） | 16 |
| 11 | ✳ clang 产 SPIR-V 内核索引用 `size_t` → Intel `clBuildProgram` **无限卡死**；用 int | 16 |
| 12 | ✳ 锁保护的共享变量不加 `volatile` → 读被提升到锁外，丢更新（实测只累加第一个 wave） | 12 |
| 13 | ✳ float 没有原子加；锁或整数定点 | 12 |
| 14 | ✳ barrier 在不一致分支 = UB；小网格无 barrier 也常"碰巧对"——别用跑几次验证竞争 | 12 |
| 15 | ✳ 剖析必须建队列时开 `CL_QUEUE_PROFILING_ENABLE`（否则 -7，事后补不开） | 14 |
| 16 | ✳ 事件状态枚举非负：QUEUED=3/SUBMITTED=2/RUNNING=1/COMPLETE=0；被闸命令报 3 | 13 |
| 17 | ✳ 回调在驱动线程跑；内核 printf 需 clFinish 后可见、**不支持 %zu**、只在前几个 item 打 | 28 |
| 18 | ✳ NVIDIA 宽容驱动：未知 device type 位 / map flags=0 不报错照样成功——别把"没报错"当"参数合法" | 28 |
| 19 | ✳ NVIDIA 通告 cl_khr_d3d11_sharing / gl_sharing 但 `clGetDeviceIDsFromD3D11KHR` 返回 -59——互操作幽灵通告，必须能力探测 + staging 桥接兜底 | 29 |
| 20 | ✳ D3D11 互操作扩展函数必须 `clGetExtensionFunctionAddressForPlatform` 动态拿 | 29 |
| 21 | ✳ subgroup 支持别查扩展名（Intel 字符串里就没有）——查 `CL_DEVICE_MAX_NUM_SUB_GROUPS > 0` | 27 |
| 22 | ✳ 内核的 max work-group（如 256）可小于设备上限（1024）——查 `CL_KERNEL_WORK_GROUP_SIZE` | 04/31 |
| 23 | ✳ C 运行时 `fopen` 不吃 UTF-8 中文路径——示例一律相对路径 + ASCII | 16 |
| 24 | ✳ PowerShell 调 clang 的 `-cl-std=CL1.2` 要加引号（否则拆成 `CL1` 和 `.2`） | 16 |
| 25 | ✳ 首轮内核含加载开销慢数倍——基准必须预热 | 31 |
| 26 | ✳ 传输比计算贵一个量级（32MB：3ms vs 0.3ms）——先减传输再抠内核 | 14 |

## 6. 性能速查（本机实测参考值）

| 场景 | 数值 |
|---|---|
| PCIe 传输（32MB 块） | 写 ~10 GB/s、读 ~9 GB/s |
| 显存合并访问（64M float 求和） | ~107 GB/s |
| strided ×32 | 同量数据慢一个量级（缓存行反复丢弃） |
| 矩阵乘 512³ naive/tiled | 755 / 971 GFLOP/s |
| 归约 float4 向量化 | 2.3x |
| 直方图本地攒桶 | 7.15x |
| N 体 4096 | 63.4 G 交互/s |
| 最优 local（fma 内核） | 128（preferred multiple 32 的倍数；32 最差、64–256 平台） |
| CPU vs GPU（8M saxpy） | 6.36 vs 2.16 ms（Intel CPU 不弱） |

## 7. 三本书 → 章节映射

| 书 | 教程对应章 |
|---|---|
| HCL 第 1–2 章（并行思维/向量加法） | 01/03/08 |
| HCL 第 3/6 章（设备架构/平台实现） | 30 |
| HCL 第 5 章（并发与执行/同步/内存模型/事件） | 08/09/12/13 |
| HCL 第 7–10 章（卷积/视频/直方图/粒子案例） | 21/29/22/25 |
| HCL 第 11–12 章（扩展/剖析调试） | 27/14/28 |
| OiA 第 2–8 章（主机端/内核语言/图像/事件/C++） | 03–17 |
| OiA 第 10–14 章（优化/排序/矩阵/稀疏/FFT） | 18–24/31 |
| OiA 第 15–16 章与附录 B（OpenGL 互操作） | 29（Windows 用 D3D11 路线） |
| OPE 第 2–7 章（架构/buffer/image/program/events/OpenCL C） | 04–16 |
| OPE 第 8–9 章（优化案例/图像处理+JPEG） | 19/22/23 |
| OPE 第 10/11 章（GL 互操作/回归·排序·KNN） | 29/20 |
