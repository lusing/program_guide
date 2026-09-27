# 28 · 调试与错误处理：注入实验、内核 printf、坑位总表

> 对应示例 `examples/28_debug/main.c`。参照 HCL 第 12 章（调试 OpenCL 应用：AMD printf 扩展等——printf 现已是核心）、OPE 第 8 章的工具介绍。

## 28.1 错误注入：把错误码背下来

调试的底气来自"见到码就知道哪里错"。示例 28 故意犯 7 类错（实测 NVIDIA 驱动）：

```
error injection suite:
  clCreateKernel(bad name)           -> CL_INVALID_KERNEL_NAME       (as expected)
  clSetKernelArg(index 7 of 1)       -> CL_INVALID_ARG_INDEX         (as expected)
  clEnqueueNDRangeKernel(dim=4)      -> CL_INVALID_WORK_DIMENSION    (as expected)
  clGetDeviceIDs(type=0xDEAD)        -> CL_SUCCESS                   (driver is lenient)
  clSetKernelArg(size=0)             -> CL_INVALID_ARG_SIZE          (as expected)
  clCreateBuffer(size=0)             -> CL_INVALID_BUFFER_SIZE       (as expected)
  clEnqueueMapBuffer(flags=0)        -> CL_SUCCESS                   (driver is lenient)
```

> ⚠️ 两处"宽容驱动"实测：NVIDIA 对未知 device type 位、map flags=0 **不报规范要求的错误，照样成功**。教训：别把"没报错"当"参数合法"；也别在测试里假定错误码必然出现（示例因此把这两项写成 informational）。

错误码速查（高频 Top 15）：

| 码 | 名字 | 常见原因 |
|---|---|---|
| 0 | SUCCESS | — |
| -1 | DEVICE_NOT_FOUND | 类型不匹配/未装驱动 |
| -3 | COMPILER_NOT_AVAILABLE | 嵌入式无编译器 |
| -5 | OUT_OF_HOST_MEMORY | 主机内存不足/泄漏 |
| -11 | BUILD_PROGRAM_FAILURE | **内核编译错（看 build log！）** |
| -30 | INVALID_VALUE | 参数值/大小非法（最杂） |
| -33 | INVALID_DEVICE | 设备不在上下文/能力不符 |
| -34 | INVALID_CONTEXT | 上下文已释放/跨上下文混用 |
| -36 | INVALID_COMMAND_QUEUE | 队列已释放 |
| -38 | INVALID_MEM_OBJECT | buffer 已释放/类型不符 |
| -44 | INVALID_KERNEL_NAME | 名字拼错 |
| -45 | INVALID_KERNEL_DEFINITION | 签名不合法 |
| -46 | INVALID_KERNEL | kernel 已释放 |
| -48 | INVALID_ARG_INDEX/−49 VALUE/−51 SIZE | 参数三兄弟（索引/值/大小） |
| -52/53 | INVALID_KERNEL_ARGS / WORK_DIMENSION | setArg 没设全 / dims∉[1,3] |

（完整表见 `common/cl_utils.h` 的 `clu_err_str` 与规范。）

## 28.2 编译错误的正确姿势

`clBuildProgram` 失败 → **必拿 build log**（`clGetProgramBuildInfo` 的 `CL_PROGRAM_BUILD_LOG`，06 章）。NVIDIA 的日志带 clang 式行列定位（`<kernel>:2:27: error: ...`），一般直接指认病灶。`clu_build_program` 已内置"失败即打印完整日志"。

## 28.3 内核 printf：设备端的 Console.WriteLine

OpenCL C 1.2 起 printf 是核心功能（HCL 第 12 章时代的 `cl_amd_printf` 已入土）：

```c
__kernel void probe(__global const float* x) {
    int i = get_global_id(0);
    if (i < 3)
        printf("[kernel] i=%d x=%.2f group=%d local=%d\n",
               i, x[i], (int)get_group_id(0), (int)get_local_id(0));
}
```

实测输出（注意顺序：设备输出在命令完成后 flush）：

```
[kernel] i=0 x=0.00 group=0 local=0
[kernel] i=1 x=1.50 group=0 local=1
[kernel] i=2 x=3.00 group=0 local=2
kernel printf output shown above (needs clFinish)
```

三条纪律：

1. **`clFinish`（或读回等同步）后输出才可见**——输出缓冲在命令完成时上抛；
2. **格式子集**：`%d %f %s %x` 等基本都有，**`%zu` 不支持**（实测原样打印字面量）——size_t 转成 `(int)` 再 `%d`；
3. 打印量大有性能与缓冲上限（默认 ~1MB，`CL_PRINTF_CALLBACK/CL_PRINTF_BUFFERSIZE` 可调），**只在前几个 item 打**（`if (i < 3)`）。

## 28.4 调查清单（按症状）

| 症状 | 先查 |
|---|---|
| 编不过 | build log（06 章）；`-cl-std` 与内核语法匹配 |
| 运行结果全 0 / 不变 | setArg 是否全部设置；global size 是否 > 0；guard 条件写反 |
| 结果随机错 | 竞争：barrier 缺失 / 锁没 volatile（12 章）/ 输出与输入同 buffer |
| 崩溃（访问违例） | 主机读回长度溢出（07 章翻车实录）/ buffer 已释放 / 越界写 global |
| 卡死不返回 | SPIR-V 的 size_t 索引坑（16 章）/ 自旋锁活锁 / 等 Never 完成的用户事件 |
| 首帧极慢 | 程序加载+编译一次性别忘了预热（31 章实测差异） |
| 拿不到平台 | 驱动未装 / 进程位数（x64）/ 远程会话 |

## 28.5 工具

| 工具 | 定位 |
|---|---|
| `CL_CHECK` + `clu_err_str`（本教程） | 第一道防线 |
| 内核 printf | 设备端变量值 |
| Nsight Systems / Compute | NVIDIA 时间线与源代码级调试（断点看内核变量） |
| printf 对照法 | 同一数据 CPU 参考对拍（所有算法章的验证套路） |

> 下一章：[29 图形互操作](29-d3d-interop.md)——D3D11 路线与一次教科书级的"扩展存在但用不了"实测。
