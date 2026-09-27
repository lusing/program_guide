# 30 · 设备架构与性能模型：SIMT、合并访问、带宽实测

> 对应示例 `examples/30_coalescing/main.c`。参照 HCL 第 3 章（设备架构：超标量/VLIW/SIMD/多线程/多核）与第 6 章（OpenCL 在 CPU/GPU 平台上的实现、内存性能）。

## 30.1 GPU 执行模型：SIMT

HCL 第 3 章的架构谱系（超标量 → VLIW → SIMD → 硬件多线程 → 多核）在当代 GPU 汇成 **SIMT**（单指令多线程）：

- work-group 被切成 **sub-group / warp**（NVIDIA 32 线程）调度；
- 同一 warp 的线程**锁步**执行同一条指令——遇到 `if/else` 分岔就两边都跑（休眠一半），**分支发散按最坏路径计时**；
- warp 调度器在内存等待时切换到别的 warp 隐藏延迟——所以"占用率"（在飞 warp 数 / 上限）是吞吐的粗代理。

推论：`select` 代替分支（11 章）、warps 内索引连续（下节）、组大小取 32 的倍数（31 章）都不是玄学，全是 SIMT 的直接后果。

## 30.2 内存层次与"合并访问"

```
寄存器（每线程私有）
  ↑  ~1 cycle
Shared memory / local（每 SM 48KB，NVIDIA）← __local
  ↑  ~30 cycles
L2（几 MB，全设备共享）
  ↑  ~200 cycles
GDDR6 显存（360 GB/s @ RTX 3060）
```

全局内存按 **32B/128B 事务**取数。**合并访问（coalescing）**= 一个 warp 的 32 次访问落在尽量少的事务里（理想：连续 128B 一发）。

示例 30 的三组对照（实测，RTX 3060）：

```
coalesced 1D :  106.7 GB/s (64 MB read)
strided x32  :  0.054 ms for 2MB effective (64.0 MB touched) -- lines evicted and re-fetched
sum_rows     :   86.3 GB/s (2D traversal)
sum_cols     :   77.6 GB/s (2D traversal)
```

- **coalesced**：相邻 work-item 读相邻地址 → 106.7 GB/s（约显存理论带宽的 30%，读+归约的合理水位）；
- **strided ×32**：同样只"读 2MB 有效数据"，但相邻 item 隔 128B——每个 128B 事务只用到 4B，且 L2 缓存行在 64MB 里反复进出，耗时反而接近全量扫描；
- **rows vs cols**：行主序按行走（相邻）86 GB/s；按列走（每步跨一行）77 GB/s——L2 兜住了部分伤害，但没有 local 转置缓存时列遍历永远亏。

> 经验法则：**如果 work-item 的索引由 `get_global_id` 直接或近似线性映射，访问天然合并；出现 `* big_stride`、转置下标、指针追逐，就要警惕**。

## 30.3 local 内存 = 手动一级缓存

19/21/22 章的"搬进 local 再算"本质：用编程纪律把**反复访问的全局数据**锁进 SM 私有高速存储。判断什么时候值得：`每字节数据的重复使用次数 > (全局延迟 / local 延迟)`——矩阵乘法每元素用 2N 次赚麻了；流式单遍扫描就别折腾。

## 30.4 CPU 设备的另一张牌

HCL 第 6 章对 CPU 实现的分析：Intel CPU 运行时把 work-item 映射到线程池、向量化成 SIMD（native width 8，4 章实测）、local 内存只是 DRAM 里的软件 cache。CPU 的强项是大缓存 + 乱序 + 分支预测——**分支多、工作集小的内核 CPU 反而快**（26 章实测 CPU 仅慢 GPU 3 倍）。跨设备调优别只盯 GPU。

## 30.5 占用率与资源公式（NVIDIA 视角）

```
在飞 warps = min(寄存器限制, shared内存限制, 线程槽限制)
占用率     = 在飞 warps / 每 SM 上限（RTX 3060: 48 warps）
```

示例 06 实测内核 `tint` 的 `CL_KERNEL_WORK_GROUP_SIZE = 256`（寄存器压力把它从设备上限 1024 压下来）——内核资源决定组上限，**这比设备参数更接近真相**。占用率不是越高越好（cache 抖动），但低于 25% 通常说明资源安排有问题。

## 30.6 性能直觉清单（背下来）

1. 先减数据传输（14 章实测传输贵计算一个量级）；
2. 访存合并 > 一切内核微优化（106 vs 个位数 GB/s 的差距）；
3. 分支用 select 重写（warp 锁步代价）；
4. local 只对复用数据有价值；
5. 组大小 = preferred multiple 的倍数起步，再 autotune（31 章）；
6. 占用率看 `CL_KERNEL_WORK_GROUP_SIZE` 而非设备上限；
7. 小数据/多分支负载先试试 CPU 设备再下结论。

> 下一章：[31 优化方法论](31-optimization.md)——autotune 实验台与优化循环。
