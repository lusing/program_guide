# 12 · 同步：barrier、原子操作、互斥锁

> 对应示例 `examples/12_barrier_atomics/main.c`。参照 HCL 第 5 章（OpenCL 同步：kernel/fence/barrier）、OiA 7.4 节。

## 12.1 同步的层级地图

| 层级 | 原语 | 谁负责 |
|---|---|---|
| work-item 内（内存序） | `mem_fence(CLK_*)` / `read_mem_fence` / `write_mem_fence` | 编译器/缓存屏障 |
| **work-group 内** | `barrier(CLK_LOCAL_MEM_FENCE \| CLK_GLOBAL_MEM_FENCE)` | 全组集合点 |
| 组间/命令间 | 多次内核启动、事件 wait list（13 章）、`clFinish` | 主机/队列 |
| 单变量原子性 | `atomic_add` 等原子函数 | 硬件 |

`barrier` 的两条铁律：

1. **所有** work-item 必须到达同一 barrier（写在一致的分 支结构里）——`if (lid < 16) barrier(...)` 是未定义行为；
2. barrier 前对 local/global 的写入，barrier 后全组可见（按 fence 参数）。

## 12.2 实验：barrier 到底防什么

示例 12A 的两阶段内核——先各写各的 local 槽，再读"组内下一个邻居"：

```c
s[lid] = in[gid];
barrier(CLK_LOCAL_MEM_FENCE);        /* 去掉它就是竞争 */
out[gid] = s[(lid + 1) % lsz];
```

对照组故意去掉 barrier，跑 5 轮统计出错：

```
barrier : rotated-in-group verified
no-barrier: 0/5 runs produced races (illustrative)
```

> ⚠️ 诚实说明：**小网格 + 顺序调度下，去掉 barrier 也常碰巧全对**（本机 5/0 全对）。竞争是概率性 bug——正确性来自规范保证，不来自"跑了几次没炸"。教学上把 deterministic 验证留给 barrier 版本，把"可能对"留给对照组。

## 12.3 原子操作（OpenCL C 1.2 语法）

```c
atomic_add(p, v)        atomic_sub / atomic_xchg
atomic_inc(p) / atomic_dec(p)
atomic_cmpxchg(p, cmp, val)     /* CAS：成功返回旧值（==cmp），失败返回 *p */
atomic_min / atomic_max / atomic_and / or / xor
```

约束：作用于 `volatile __global` 或 `__local` 的 **int/uint**（32 位核心；`cl_khr_int64_base_atomics` 扩展支持 long，本机两家都有；**float 没有原子加**——这是 12.4 互斥锁存在的理由）。C 3.0 引入了 C11 风格的 `atomic_fetch_add_explicit` 家族，旧名仍是 1.2 语法主力。

实测原子计数（4096 个 item 对同一 int `atomic_add`）：

```
atomic_add counter = 4096 (expect 4096) verified
```

`atomic_xchg` 实验（1024 个 item 抢换同一个槽）：旧值里初始哨兵 `-777` 恰好出现一次、终值在合法编号内——交换语义精确成立。

## 12.4 互斥锁：CAS 自旋 + 临界区（OiA 7.4.3）

float 累加没有原子版，经典替代是锁：

```c
__kernel void mutex_sum(__global const float* x, volatile __global float* sum,
                        volatile __global int* lock, const int n) {
    int gid = get_global_id(0);
    if (gid >= n) return;
    int acquired;
    do {
        int expected = 0;
        acquired = atomic_cmpxchg(lock, expected, 1);   /* CAS 抢锁 */
    } while (acquired != 0);
    float s = *sum;          /* 临界区 */
    s = s + x[gid];
    *sum = s;
    atomic_xchg(lock, 0);    /* 放锁 */
}
```

> ⚠️ **本教程实测最重要的并发坑**：`sum`/`lock` **必须声明 `volatile`**。不加 volatile 的版本实测只累加了第一个 wave（恰好 512 项）——编译器/缓存把 `*sum` 的读提升到自旋之前，后续所有"拿到锁"的线程写回的都是过期快照（丢失更新）。结果从 8386560 变成 130816（恰好 = 0+1+…+511）。加了 volatile 后：

```
mutex float sum = 8386560.0 (expect 8386560.0) verified
```

GPU 上锁的通用告诫：自旋锁在占满设备时可能活锁/饿死（没有前向进度保证），生产代码优先用"组内归约 + 原子合并"（18/22 章的姿势），锁只用于低竞争路径。

## 12.5 fence：更细粒度的内存序

```c
mem_fence(CLK_LOCAL_MEM_FENCE);          /* 本 item 此前的读写对后续操作有序 */
read_mem_fence(CLK_IMAGE_MEM_FENCE);     /* 图像读 */
write_mem_fence(CLK_GLOBAL_MEM_FENCE);
```

fence 只约束**单个 work-item 自己**的内存序（不给别的 item 可见性）；跨 item 可见性要 barrier。图像对象有独立的 fence 标志位 `CLK_IMAGE_MEM_FENCE`。

## 12.6 异步拷贝：async_work_group_copy（组级预取）

```c
event_t e = async_work_group_copy(local_ptr, global_ptr, n, 0);
wait_group_events(1, &e);       /* 全组等待拷贝完成（隐式组同步语义） */
```

把 global→local 的搬运交给 DMA 引擎与计算重叠（HCL 第 6 章的内存性能讨论）。教学主线用手写合作搬运（更可解释），需要压榨带宽时再换 async 版。

## 12.7 坑位清单（实测）

1. barrier 在不一致分支里 = UB；
2. **锁保护的共享变量不加 volatile = 丢更新**（12.4 实测案例，教材级坑）；
3. float 原子：没有，别想（C 3.0 扩展 `cl_ext_float_atomics` 才有，27 章查法）；
4. 自旋锁 + 全占满 = 活锁风险；
5. `atomic_cmpxchg` 返回**旧值**判断成败，不是 bool。

> 下一章：[13 事件](13-events.md)——wait list、用户事件、回调与三段流水线。
