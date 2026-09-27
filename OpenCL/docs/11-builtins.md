# 11 · 运算符与内建函数：数学、整数、shuffle/select、几何

> 对应示例 `examples/11_builtin_funcs/main.c`。参照 OiA 第 5 章（最系统的函数表）、OPE 第 7 章。

## 11.1 总览：六族函数

| 族 | 代表函数 | 备注 |
|---|---|---|
| 浮点算术 | `fabs fma mad exp log sqrt rsqrt` | `fma` 单次舍入；`native_*`/`fast_*` 是硬件近似 |
| 取值/比较 | `fmin fmax clamp step smoothstep mix sign isnan isinf` | `mix(a,b,t)=a+(b-a)t` |
| 整数 | `abs clz mad_sat upsample rotate popcount` | 饱和版防溢出 |
| shuffle/select | `shuffle select shuffle2 bitselect` | SIMD 精髓 |
| 几何 | `dot cross normalize fast_length distance` | 3D 图形/物理 |
| 工作项 | `get_global_id` 等（8 章）+ `barrier`（12 章） | — |

示例 11 用三个内核把六族全部与 CPU（CRT）对拍，容差比较（近似函数给 2e-3 相对容差，精确函数 0~1e-5）。

## 11.2 精度分级：精确 / fast_ / native_

- **精确函数**（`exp log sin sqrt` 等核心）：规范规定 ulp 误差上界（如 `sin` ≤ 2 ulp…按函数各不相同）；
- **`fast_*`**（`fast_length fast_distance`…）：更快更糙；
- **`native_*`**（`native_exp native_divide`…）：直接映射硬件指令，精度实现自定。

教学默认用精确版；`-cl-fast-relaxed-math` 编译选项把前者整体换成后者的语义（6 章）。实测对照：示例中 `native_exp` 给了 2e-3 容差仍然全过——量级正确、尾数不可依赖。

`sqrt` 注意：核心 `sqrt` 满足正确舍入要求（实测与 CPU `sqrtf` 差异 < 1e-6 相对），而 `rsqrt` 是近似（1/x 量级对）。

## 11.3 整数族实测注记

```
int1   : 0 mismatches (abs/clz/mad_sat/upsample/rotate)
```

- `clz(x)`：前导零计数；负数按无符号位型算（MSB=1 → 0）；
- `mad_sat(a,b,c)`：无限精度算 a*b+c 后饱和到 int 范围；
- `rotate(v, n)`：按无符号位型循环左移；
- **`upsample` 是位拼接不是数值运算**（本教程实测翻车点）：`upsample(short hi, ushort lo)` 返回 **uint**，hi 占高 16 位、lo 占低 16 位。想要"高字节+低字节拼 16 位"要用 `upsample((char)h, (uchar)l)`（得 ushort）。开发时把 short 版当字节拼用，负数结果全错——肉眼可见的 `0xFF80xxxx` 模式就是它。

## 11.4 shuffle 与 select：向量的分支重排

```c
uint4 mask = (uint4)(3, 2, 1, 0);
float4 rev = shuffle(va, mask);                 /* 按索引表取分量拼新向量 */

float4 picked = select(va, vb, isgreater(vb, va));  /* 逐分量三目：条件真取 b */
```

- `shuffle` 的掩码每分量低 2·n 位是索引（float4 用低 2 位；可跨两个源用 `shuffle2`）；
- `select(a, b, cond)`：**条件为真取第二个操作数 b**（和 C 的 `?:` 一致，但别和 GLSL mix 弄混）；标量条件会被广播；
- `bitselect(a, b, m)`：按位版 `m?b:a`。

示例对拍：`vec_ops: 0 mismatches (shuffle/select/dot/fast_length/distance)`。

这是 GPU 上代替"分支"的主力：**用 select 重写 `if`，把 32 个通道的分支合成无分支代码**（30 章性能篇回来看为什么值钱）。

## 11.5 几何族

```c
float3 p, q;
float d = dot(p, q);
float3 c = cross(p, q);              /* 仅 3/4 分量向量 */
float  n = length(p);                /* sqrt(dot(p,p))
float  dist = distance(p, q);        /* length(p-q) */
```

`fast_length/fast_distance` 用 `rsqrt` 近似（示例给 2e-3 容差实测通过）。`normalize` 返回单位向量。

## 11.6 常用对照表（速查）

| 想做的事 | 内核写法 |
|---|---|
| 绝对值 | `fabs(x)`（浮点）/ `abs(x)`（整数） |
| 三目但向量化 | `select(a, b, cond)` |
| 饱和转 int | `convert_int_sat_rte(x)` |
| 位重解释 | `as_uint(x)` |
| 分量重排 | `shuffle(v, (uint4)(...))` |
| 限幅 | `clamp(x, lo, hi)` |
| 线性插值 | `mix(a, b, t)` |
| 快速 exp | `native_exp(x)`（精度自担） |

> 下一章：[12 同步](12-synchronization.md)——barrier 的必要性与原子操作。
