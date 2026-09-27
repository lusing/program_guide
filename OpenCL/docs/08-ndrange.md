# 08 · 执行模型：NDRange、work-item、work-group、全局偏移

> 对应示例 `examples/08_ndrange/main.c`。参照 HCL 第 5 章（执行域与同步）、OiA 3.6 节（Data partitioning）。

## 8.1 三层执行结构

```
NDRange（整个索引空间，global size 决定）
 ├─ work-group 0（local size 个 work-item，一起调度到同一计算单元）
 │    ├─ work-item 0..L-1
 ├─ work-group 1
 └─ ...
```

坐标恒等式（示例 08 内核把四组量全部写回，主机逐项验证）：

```
get_global_id(d)  = get_global_offset(d) + get_group_id(d) * get_local_size(d) + get_local_id(d)
get_global_size(d) = get_num_groups(d) * get_local_size(d)
```

实测输出（4×4 网格、2×2 工作组）：

```
coords  : gid/lid/group/num_groups consistent
```

内核端的六件套（维度参数 0/1/2）：

| 函数 | 返回 |
|---|---|
| `get_global_id(d)` / `get_global_size(d)` | 全局编号 / 全局大小 |
| `get_local_id(d)` / `get_local_size(d)` | 组内编号 / 组大小（= local size） |
| `get_group_id(d)` / `get_num_groups(d)` | 组编号 / 组数 |
| `get_global_offset(d)` | 全局偏移（默认 0） |
| `get_work_dim()` | 维度数 |

## 8.2 启动参数

```c
size_t global[2] = {4, 4}, local[2] = {2, 2}, offset[2] = {1, 2};
clEnqueueNDRangeKernel(q, k, 2 /*dims*/, offset, global, local, 0, NULL, NULL);
```

| 参数 | 规则 | 违规后果（实测） |
|---|---|---|
| dims | 1–3 | `CL_INVALID_WORK_DIMENSION` |
| global | 每维 > 0；**各维必须能被 local 整除**（除非设备支持不规则分组） | `CL_INVALID_GLOBAL_WORK_SIZE` / `CL_INVALID_WORK_GROUP_SIZE` |
| local | 每维 ≤ `CL_KERNEL_WORK_GROUP_SIZE` 且 ≤ `MAX_WORK_ITEM_SIZES[d]` | `CL_INVALID_WORK_GROUP_SIZE` |
| offset | 通常 0；非 0 时 `get_global_id` 从 offset 起 | 逻辑编号要自己减 offset |

**local size = NULL** 让运行时自选——对"每元素独立"的内核最省心；但注意此时 global 仍需能被运行时选出的组合整除（示例实测：global=16 可行，global=10 之类奇数大小要靠 guard 或 padded buffer）。

## 8.3 全局偏移：跳进数据的中间

示例 08B：`offset = {1, 2}`、grid 3×2，内核把 `get_global_offset` 和真实 gid 写回：

```
offset : get_global_offset=(1,2), gid starts at (1,2) verified
```

用途：数据在缓冲区中间某处开始时免去 `gid + base` 的手动加法。**索引回"无偏移坐标系"要减 offset**（示例内核 `i = (gy - oy) * w + (gx - ox)`）。

## 8.4 边界守卫：N 不是 local 倍数时的标准姿势

逻辑数据 10 个、local 4 → global 只能取 12（≥10 且被 4 整除），多出的 2 个 item 必须守卫：

```c
__kernel void guarded(__global int* out, const int n) {
    int i = get_global_id(0);
    if (i < n)              /* 守卫：多派的工作项立刻返回 */
        out[i] = i * i;
}
```

示例用哨兵值验证：`[0..9]=i*i, [10..11] untouched verified`——越界 item 一字未写。

三种"凑整"策略对比：

| 策略 | 写法 | 适用 |
|---|---|---|
| guard（教程默认） | `if (i < n)` | 通用，简单 |
| padded buffer | 分配 ceil(N/L)*L，结果只读前 N | 内存不敏感时 |
| 尾块单独处理 | 主机把尾巴切出来 | 追求极致时 |

## 8.5 work-group 怎么选大小

- `CL_KERNEL_WORK_GROUP_SIZE`：这个内核的上限（≤ 设备上限）；
- `CL_KERNEL_PREFERRED_WORK_GROUP_SIZE_MULTIPLE`：波次倍数（NVIDIA 32、Intel CPU 常 128/256）；
- 组内可 `barrier` 同步、共享 `__local` 内存（9/12 章）——**组间没有 OpenCL C 级同步**，只有多次内核启动或主机参与（18 章归约因此分两级）；
- 组太小组太少 → 占不满设备；组太大 → 寄存器/local 不够启动失败或降速。31 章直接自动扫描。

> ⚠️ NVIDIA 第三维上限 64（本机 `MAX_WORK_ITEM_SIZES = 1024×1024×64`）：3D 问题把高维放 [0]/[1]。

> 下一章：[09 内存模型](09-memory-model.md)——四级地址空间与一致性。
