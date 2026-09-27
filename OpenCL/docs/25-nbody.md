# 25 · N 体模拟：双缓冲、守恒律验证、每秒 630 亿次交互

> 对应示例 `examples/25_nbody/main.c`。参照 HCL 第 10 章（OpenCL 案例学习 4：混合粒子模拟——CPU/GPU 负载均衡的原始出处）。

## 25.1 N 体：GPU 的本命负载

每步对每对粒子算引力（O(N²)），无分支、算术密集、规则访问——与 GPU 形状完全匹配。教程实现 4096 体 × 20 步 Leapfrog 积分：

```c
__kernel void nbody_step(__global const float4* pos,   /* float4 装_xyz */
                         __global const float4* vel,
                         __global float4* pos_out,
                         __global float4* vel_out,
                         const int nb, const float dt) {
    int i = get_global_id(0);
    if (i >= nb) return;
    float4 pi = pos[i];
    float3 acc = (float3)(0.0f);
    for (int j = 0; j < nb; j++) {
        if (j == i) continue;
        float4 pj = pos[j];
        float3 d = pj.xyz - pi.xyz;
        float dist2 = dot(d, d) + 0.01f;      /* 软化 eps²：近距离不发散 */
        float inv = rsqrt(dist2);
        acc += d * (inv*inv*inv);             /* G·m = 1 */
    }
    float4 v_new = vel[i] + (float4)(acc * dt, 0.0f);
    vel_out[i] = v_new;
    pos_out[i] = pos[i] + v_new * dt;
}
```

三个工程点：

1. **float4 装载**：位置/速度各占一条 128 位载入（`.xyz` 干活、`.w` 空着）；
2. **软化因子**（softening）：`r² + ε²` 防两体近距时力爆炸（数值稳定性必需）；
3. **`rsqrt` 近似 + 两次自乘**：比 `pow(r,-3)` 快得多（11 章精度分级）。

## 25.2 双缓冲：数据不出设备

每步读写同一批数据会竞争——标准解法是**乒乓双缓冲**：

```c
cl_mem bpos[2], bvel[2];
int cur = 0;
for (int s = 0; s < STEPS; s++) {
    /* 读 bpos[cur]/bvel[cur]，写 bpos[1-cur]/bvel[1-cur] */
    clSetKernelArg(k, 0, sizeof(cl_mem), &bpos[cur]);
    ...
    cur = 1 - cur;
}
```

步与步之间**零主机往返**——只在最后读回。队列顺序提供步间全局同步（内核序执行）。

## 25.3 验证：数值对拍 + 守恒律

1. **单步对拍**：重建初值（同随机序列），GPU 跑一步 vs CPU 双重循环（8 个体抽样），实测 `max |dvx| = 4.77e-07`（float 累加序差异量级）；
2. **动量守恒**：引力成对抵消（牛顿第三定律）→ 全程总动量不变。实测：

```
momentum: before (-1.5703, -3.0856, -1.0477), after (-1.5713, -3.0848, -1.0485)
```

20 步后漂移 1e-3 量级（float 误差累积的合理水位）——守恒律是物理模拟最便宜的正确性监控。

## 25.4 实测性能

```
4096 bodies x 20 steps: kernel total 5.29 ms (0.26 ms/step), wall 6.9 ms
interactions/sec ~ 63.42 billion
```

每秒 634 亿对交互（含软化开方）。同一 N² 内核在 CPU（12700F 单线程）上做一步要秒级——N 体是"GPU 为什么存在"的标准答案。

## 25.5 HCL 第 10 章的完整版：混合粒子模拟

书的原版更进一步——**CPU 和 GPU 同时干活**：

- 加速结构（均匀网格/bucket）把 O(N²) 砍到 O(N·邻居)；
- 粒子按 CPU/GPU 各自吞吐动态分区（负载均衡）；
- CPU 端用向量化代码处理自己的份额；
- GPU 计算结果 OpenGL 直出（书里的 8 章视频处理同款互操作）。

教程简化为纯 GPU 版（教学焦点在双缓冲与守恒验证）；多设备分工的完整套路在下一章用更透明的负载实测。

> 下一章：[26 多设备并行](26-multi-device.md)——GPU 与 CPU 同算一份作业。
