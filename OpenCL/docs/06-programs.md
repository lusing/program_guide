# 06 · 程序与内核：build 选项、编译日志、多段源码

> 对应示例 `examples/06_build_options/main.c`。参照 OiA 2.5/2.6、OPE 第 5 章（Creating program objects / OpenCL program building options）。

## 6.1 三条创建程序的路线

| 入口 | 输入 | 适用 |
|---|---|---|
| `clCreateProgramWithSource` | 内核源码字符串数组 | 教学/应用主流（运行时在线编译） |
| `clCreateProgramWithBinary` | 设备相关二进制 | 离线缓存、缩短启动（16 章） |
| `clCreateProgramWithIL` | SPIR-V 字节码 | 语言无关中间层（16 章，NVIDIA 不支持） |

本机 NVIDIA 对源码程序的 `CL_PROGRAM_BINARIES` 实测只有约 1KB（PTX/微码句柄式的轻量产物），Intel CPU 平台的二进制则大得多——**二进制与设备绑定，别跨设备加载**。

## 6.2 多段源码：一个程序，几段字符串

```c
const char* sources[2] = { SRC_DECL, SRC_BODY };   /* 先声明后定义，拼接语义 */
cl_program prog = clCreateProgramWithSource(ctx, 2, sources, NULL, &err);
clBuildProgram(prog, 1, &dev, options, NULL, NULL);
```

两段字符串按顺序拼接成一个翻译单元。`CL_PROGRAM_SOURCE` 查询会把拼接结果原样还给你（示例验证了这一点）——多文件工程可以自己在主机端做 include 展开，或用 1.2 的 `clCompileProgram`+`clLinkProgram` 做真正的分离编译（教学少用）。

## 6.3 build 选项速查

第三参数传给 `clBuildProgram` 的字符串，空格分隔：

| 选项 | 作用 | 教学态度 |
|---|---|---|
| `-cl-std=CL1.2` / `CL3.0` | 语言版本 | 显式声明最稳；3.0 特性宏（`__opencl_c_*`）只在 CL3.0 下可用 |
| `-cl-fast-relaxed-math` | 放宽浮点（等价 `-cl-finite-math-only -cl-unsafe-math-optimizations` + fast 函数） | 数值敏感时禁用 |
| `-cl-mad-enable` | 允许乘加合并为 mad | 同上 |
| `-cl-denorms-are-zero` | 非规格数冲零 | 音频/DSP 注意 |
| `-Werror`、`-g`、`-O...`（NVIDIA 支持 `-cl-nv-*` 系） | 诊断/调试/厂商私有 | 按需 |

示例 06 实测驱动会回显选项（`CL_PROGRAM_BUILD_OPTIONS` 查询）：

```
build options echoed: -cl-fast-relaxed-math -cl-mad-enable -cl-std=CL1.2
```

## 6.4 编译日志：排错第一现场

```c
err = clBuildProgram(prog, 1, &dev, NULL, NULL, NULL);
if (err != CL_SUCCESS) {
    size_t lsz = 0;
    clGetProgramBuildInfo(prog, dev, CL_PROGRAM_BUILD_LOG, 0, NULL, &lsz);
    char* log = malloc(lsz + 1);
    clGetProgramBuildInfo(prog, dev, CL_PROGRAM_BUILD_LOG, lsz, log, NULL);
    /* 打印 log —— 永远别忽略它 */
}
```

示例 06 故意放一个语法错误，实测 NVIDIA 的日志带 clang 风格的行列定位：

```
broken kernel -> CL_BUILD_PROGRAM_FAILURE; log (118 bytes) first line: <kernel>:2:27: error: expected expression
```

**注意 build log 永远值得打**（即使成功也常有性能提示），`clu_build_program` 已内置失败即打。

## 6.5 程序/内核信息查询

```c
clGetProgramInfo(prog, CL_PROGRAM_REFERENCE_COUNT / CL_PROGRAM_SOURCE / ...);
clGetProgramBuildInfo(prog, dev, CL_PROGRAM_BINARY_TYPE / CL_PROGRAM_BUILD_LOG / ...);
```

> ⚠️ 实测坑：`CL_PROGRAM_BINARY_TYPE` 是**按设备**的构建信息，必须走 `clGetProgramBuildInfo`；用 `clGetProgramInfo` 查它返回 `CL_INVALID_VALUE`。实测值 `4 = CL_PROGRAM_BINARY_TYPE_EXECUTABLE`（注意枚举跳过 3）。

内核级：

```c
clGetKernelInfo(k, CL_KERNEL_NUM_ARGS / CL_KERNEL_FUNCTION_NAME / ...);
clGetKernelWorkGroupInfo(k, dev, CL_KERNEL_WORK_GROUP_SIZE / ...);
```

示例实测（NVIDIA，内核 `tint`）：

```
kernel 'tint': num_args=3 max_wg=256 preferred_multiple=32 local_mem=1
```

三个数都有戏：max_wg=256 **小于**设备上限 1024（寄存器压力）；preferred_multiple=32 是 warp 宽度（31 章 autotune 的锚点）；local_mem=1 说明编译器为内核静态分配了 local。

## 6.6 内核对象与参数

```c
cl_kernel k = clCreateKernel(prog, "tint", &err);        /* 名字错 -> CL_INVALID_KERNEL_NAME */
cl_kernel* all = ...; clCreateKernelsInProgram(prog, n, all, &out_n);  /* 全量枚举 */
```

`clSetKernelArg` 的三类典型用法（后续章节全覆盖）：

```c
clSetKernelArg(k, 0, sizeof(cl_mem), &buf);    /* buffer/image */
clSetKernelArg(k, 1, sizeof(float), &fval);    /* 标量按值 */
clSetKernelArg(k, 2, 1024, NULL);              /* __local 动态数组：size=字节数，ptr=NULL */
```

一个 `cl_program` 可造多个 `cl_kernel`；`cl_kernel` 可重复 setArg 后多次入队。SVM 指针与 sampler 参数（15 章）另有专门形态。

## 6.7 生命周期

```
source/binary/IL --clCreateProgramWith*--> program --clBuildProgram--> (executable)
program --clCreateKernel--> kernel --clSetKernelArg--> 可入队
用完：clReleaseKernel -> clReleaseProgram
```

> 下一章：[07 缓冲区](07-buffers.md)——创建标志全家桶、映射、子缓冲区与矩形读写的"行单位"大坑。
