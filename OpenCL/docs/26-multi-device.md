# 26 · 多设备并行：GPU + CPU 分块同算

> 对应示例 `examples/26_multidevice/main.c`。参照 HCL 第 10 章（负载均衡）、OiA 附录与 OPE 第 2 章（Application scaling）。

## 26.1 两种多设备组织

| 方案 | 结构 | 优缺点 |
|---|---|---|
| **多上下文**（本章） | 每设备独立 context/queue/buffer，主机调度数据分片 | 任何设备组合都能用（含跨厂商：本机 NVIDIA GPU + Intel CPU）；数据经主机或显式拷贝互通 |
| 单上下文多队列 | 一个 context 挂多设备，buffer 全局可见 | 设备间互访仍要拷贝命令；跨厂商同 context 基本不可行 |

多上下文是最通用的教学样板：**"同一内核、各自上下文、主机切数据、事件各自 join"**。

## 26.2 结构体化的设备槽位

```c
typedef struct {
    cl_platform_id plat;  cl_device_id dev;
    cl_context ctx;       cl_command_queue q;
    cl_program prog;      cl_kernel kern;
    cl_mem bx, by;        char name[128];
} devslot_t;
```

每槽位独立走一遍 03 章的八步（各自 build——**程序对象不跨上下文**）。选设备：每平台先 GPU 后 CPU，最多两台。

## 26.3 调度：切块、下发、join、合并

```c
int chunk = N / nslots;
for (int s = 0; s < nslots; s++) {
    int off = s * chunk, cnt = ...;
    /* 各槽位自己的 buffer（主机分片 COPY_HOST_PTR）+ 入队，事件存 evs[s] */
    clEnqueueNDRangeKernel(slots[s].q, slots[s].kern, ..., &evs[s]);
}
for (int s = 0; s < nslots; s++)          /* 主机 join 两台 */
    clWaitForEvents(1, &evs[s]);
for (int s = 0; s < nslots; s++)          /* 各自读回自己的分片 */
    clEnqueueReadBuffer(slots[s].q, slots[s].by, CL_TRUE, ...);
```

关键：**两台下发之间主机零阻塞**（非阻塞下发 + 事件数组最后 join），两台设备真正并行。

## 26.4 实测（8M 元素 saxpy：y = 3x + y）

```
slot 0: NVIDIA GeForce RTX 3060
slot 1: 12th Gen Intel(R) Core(TM) i7-12700F
slot 0 (NVIDIA GeForce RTX 3060): kernel 2.16 ms for 4194304 elements
slot 1 (12th Gen Intel(R) Core(TM) i7-12700F): kernel 6.36 ms for 4194304 elements
wall clock (dispatch..merge): 74.2 ms
merged result: verified across all chunks
26 multidevice PASS
```

- GPU 2.16ms vs CPU 6.36ms（Intel CPU 运行时 20 核全开也就慢 GPU 3 倍——CPU 平台并不弱）；
- wall 74ms 里大头是**两次 32MB 的主机→设备 COPY 与读回**（14 章的传输瓶颈再现）——多设备收益在小数据/多轮计算的场景才明显；
- 静态均分不是最优：按 2.16:6.36 的吞吐比切 3:1 才能两边同时收工（HCL 第 10 章"负载均衡"的核心；31 章 autotune 思想平移过来）。

## 26.5 深水区（文档路线）

- **SVM**（OpenCL 2.0，本机 NVIDIA 不支持）：共享虚拟内存让多设备免显式拷贝；
- **跨上下文事件**：不同 context 的命令不能直接进彼此的 wait list——用用户事件手工桥（主机等 A 完成再 setStatus B 的依赖事件）；
- **子缓冲区分片**：单上下文多设备用 `clCreateSubBuffer` 给每台一段（7 章），省掉主机中转；
- **cl_device_partition**（fission 后继）：把一台 CPU 切成几台设备（4 章查询）。

> 下一章：[27 扩展机制](27-extensions.md)——查询、启用与 subgroup 的正确查法。
