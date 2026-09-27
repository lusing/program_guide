# 14 · 性能剖析：事件时间戳与带宽测量

> 对应示例 `examples/14_profiling/main.c`。参照 OiA 7.3 节、OPE 第 8 章（Finding the performance of your program）、HCL 第 12 章（基于事件的剖析）。

## 14.1 前提：队列必须开剖析属性

```c
const cl_queue_properties props[] = {
    CL_QUEUE_PROPERTIES, (cl_queue_properties)CL_QUEUE_PROFILING_ENABLE,
    0
};
cl_command_queue q = clCreateCommandQueueWithProperties(ctx, dev, props, &err);
```

事后无法补开。反面实验（示例实测）：普通队列上查事件时间戳 →

```
profiling on plain queue -> CL_PROFILING_INFO_NOT_AVAILABLE (-7)
```

## 14.2 四个时间戳

每条命令（配了事件的话）带四个纳秒时间戳（设备时钟）：

```
QUEUED --(排队等待)--> SUBMIT --(提交等待)--> START --(纯执行)--> END
```

```c
cl_ulong t;
clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_QUEUED,  sizeof(t), &t, NULL);
/* 同族：CL_PROFILING_COMMAND_SUBMIT / START / END */
```

三段差值的含义：

| 区间 | 含义 | 想缩短要动什么 |
|---|---|---|
| SUBMIT−QUEUED | 主机提交前的排队 | 主机代码效率 |
| START−SUBMIT | 设备从收到到开跑 | 队列深度/前序命令 |
| END−START | **纯执行** | 内核本身（优化篇的目标） |

## 14.3 实测：传输 vs 计算的时间线

示例 14 对 32MB 数据的 write→kernel→read 三段剖析（RTX 3060 实测）：

```
stage      queued->submit  submit->start  run(end-start)  total
-------------------------------------------------------------
write             0.102ms         1.113ms         3.080ms      4.3ms
kernel            0.009ms         0.517ms         0.306ms      0.8ms
read              0.009ms         0.806ms         3.594ms      4.4ms
write bandwidth ~ 10.1 GB/s, read ~ 8.7 GB/s (32MB each)
```

一眼可见的结论：**传输比计算贵一个数量级**（3ms vs 0.3ms）。优化优先级永远是：先减传输次数（留在设备上算多步）、再用非阻塞传输重叠、最后才是抠内核。

> 带宽参考：PCIe 4.0 x16 理论 ~32 GB/s，实测 10 GB/s 是小包+同步开销下的正常水位；RTX 3060 显存带宽 ~360 GB/s（30 章实测合并访问 106 GB/s）。

## 14.4 计时纪律（示例的写法）

1. **预热一轮再计时**（首次启动含程序加载/页表建立，31 章实测差异巨大）；
2. 多轮取最优或中位数（单轮会被系统抖动污染）；
3. `CL_TRUE` 读回会隐式同步——计时流水线用事件串联、最后只 join 读事件（13 章）；
4. 时间戳是**设备时钟**的纳秒，与主机时钟无对齐关系——别拿它和 `QueryPerformanceCounter` 相加减。

## 14.5 工具生态

| 工具 | 用途 |
|---|---|
| 事件剖析（本章） | 零依赖、跨厂商的底线手段 |
| [clinfo](https://github.com/Oblomov/clinfo) | 环境全量报告 |
| NVIDIA Nsight Systems | 时间线（内核/拷贝/间距一目了然） |
| AMD Radeon GPU Profiler / uProf | AMD 侧 |
| Intel VTune Profiler | Intel 侧（GPU/CPU 混合） |

HCL 第 12 章演示的 AMD APP Profiler / gDEBugger 已随时代退场，思路（轨迹 + 计数器）被 Nsight/uProf 继承。

> 下一章：[15 图像对象](15-images.md)——格式、采样器与两种插值的实测语义。
