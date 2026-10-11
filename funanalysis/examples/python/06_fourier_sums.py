import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
"""第 06 章 · 圆周 Fourier 变换与直和的数值实验（Conway I.5-6）——scipy 通道。

对应 docs/06-fourier-sums.md。
- 圆周 Fourier 基的正交性（Conway 5.7）；
- Fourier 系数衰减与光滑性（5.6 的现象）；
- Parseval 恒等式（5.10）；
- Gibbs 现象：L² 收敛 ≠ 逐点收敛（5.8-5.11 的边界）。
"""

import numpy as np

print("==== 06 fourier-sums (Python) ====")

n = 1000                       # 圆周采样数
t = np.arange(n) / n           # [0,1) 上的格点，e_n(t) = exp(2πint)

# --- 实验 1：Fourier 基的正交性（Conway 5.7）----------------------------------
# <e_m, e_n> = δ_{mn}（离散正交带因子 n）
m, k = 5, 9
inner_mk = abs(np.sum(np.exp(2j * np.pi * m * t) * np.conj(np.exp(2j * np.pi * k * t))))
inner_mm = abs(np.sum(np.exp(2j * np.pi * m * t) * np.conj(np.exp(2j * np.pi * m * t))))
print(f"<e_{m},e_{k}> = {inner_mk:.2e}（应为 0）  <e_{m},e_{m}> = {inner_mm:.1f}（= n）")
assert inner_mk < 1e-8
assert abs(inner_mm - n) < 1e-8

# --- 实验 2：系数衰减反映光滑性（Conway 5.6 的现象）----------------------------
# 只统计 |频率| > 10 的能量：光滑函数集中在低频，方波按 1/k 缓慢衰减
f_smooth = np.sin(2 * np.pi * t) + 0.5 * np.cos(6 * np.pi * t)
f_rough = np.sign(np.sin(2 * np.pi * t))                     # 方波：跳跃
F_smooth = np.fft.fft(f_smooth) / n
F_rough = np.fft.fft(f_rough) / n
freq_idx = np.fft.fftfreq(n) * n                             # 整数频率
high = np.abs(freq_idx) > 10
tail_s = np.sum(np.abs(F_smooth[high]))
tail_r = np.sum(np.abs(F_rough[high]))
print(f"high-freq (|k|>10) mass: smooth = {tail_s:.2e}  rough = {tail_r:.4f}")
assert tail_s < 1e-10
assert tail_r > 0.1

# --- 实验 3：Parseval 恒等式（Conway 5.10 离散版）-------------------------------
e_time = np.sum(np.abs(f_rough) ** 2) / n
e_freq = np.sum(np.abs(F_rough) ** 2)
print(f"Parseval: time = {e_time:.6f}  freq = {e_freq:.6f}")
assert abs(e_time - e_freq) < 1e-10

# --- 实验 4：Gibbs 现象——L² 收敛但有超调（5.8 的边界）---------------------------
partial = np.zeros(n, dtype=complex)
for kk in range(-5, 6):                                      # 前 11 个频率
    partial += F_rough[kk] * np.exp(2j * np.pi * kk * t)
overshoot = np.max(np.abs(partial.real))                      # 方波幅值 1
print(f"Gibbs overshoot at jump: max = {overshoot.real:.4f}（≈1.18–1.19，含直流偏置）")
assert 1.1 < overshoot.real < 1.25
# L² 收敛照旧
res = np.sqrt(np.sum(np.abs(f_rough - partial) ** 2) / n)
assert res < 0.6

print("==== 06 fourier-sums END ====")
