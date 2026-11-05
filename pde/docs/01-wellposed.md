# 01 分类、适定性与 Hadamard 反例

**对应书第 1 章 §1.3（研究策略）、§1.4（全书概览）、§1.5 习题
（多重指标技术）与贯穿全书的适定性（well-posedness）主题。**

---

## 01.1 适定性：三判据

Hadamard 给出"一个定解问题值得解"的三条标准：

1. **存在性**：解存在；
2. **唯一性**：解至多一个；
3. **连续依赖性**：解连续地依赖于数据（初值、边值、系数、源项）。

三条全真称问题**适定**（well-posed）。适定性不只是哲学：数值方法
（有限差分、有限元）本质上是数据的扰动——若解不连续依赖于数据，
任何算法都不可能收敛。这是数值分析课的 Lax 等价定理背后的事，
也是本书反复出现的暗线。

**正面例子**（本教程后续全部证成定理）：

- 传输方程 Cauchy 问题：解 u(x,t) = g(x − bt) 显式，连续依赖显然
  （02 章）；
- 热方程初边值问题：模式 e^{−k²t} 衰减，压缩半群（07、34 章）；
- 波方程 Cauchy 问题：能量守恒，等距半群（10、36 章）；
- Laplace 方程 Dirichlet 问题：能量估计 + 极值原理（04、05 章）。

**反面例子**是本 章 的两个主角：逆时热方程与 Laplace 方程的
Cauchy 问题。

## 01.2 逆时热方程：模式放大 e^{k²|t|}

热方程 u_t = u_xx 的 Fourier 模式 sin(kx) 以 e^{−k²t} 衰减——
这就是"平滑化"：正向问题是**稳定**的，高频扰动被指数压缩。
Julia 通道 `examples/julia/01_wellposed.jl` 实验一：

```julia
for k in [2, 4, 8]
    amp = exp(-k^2 * 0.5)
    @printf("    k=%d: |data|=1e-3 -> |u(.,0.5)| = %.2e\n", k, 1e-3 * amp)
end
```

实测：k = 2/4/8 的初始扰动 10⁻³ 在 t = 0.5 分别缩到 1.35×10⁻⁴ /
3.35×10⁻⁷ / 1.27×10⁻¹⁷——k = 8 已经低于机器精度。**数据被压缩
的映射自然是连续的**，连续依赖成立。

现在**倒着解**：给 t = T 时刻的观测，问 t = 0 的初始值。同一模式
要放大 e^{+k²T}：

```julia
for k in [10, 20]
    growth = exp(k^2 * 0.1)
    ...
end
@assert exp(20^2*0.1) * 1e-12 > 1e3
```

实测：k = 20、T = 0.1 的放大因子 e^{40} = 2.35×10¹⁷——**双精度
下限量级（10⁻¹²）的数据噪声被放大成 O(10⁵) 的"解"**。放大因子
关于 k 无界，连续依赖彻底失效。这就是照片去模糊、热扩散反问题
不适定的原因；实践里要么加正则化（Tikhonov），要么放弃。

## 01.3 Hadamard 反例：边值趋零而解爆炸

适定性失败的Prototype来自 Hadamard，考虑**Laplace 方程的 Cauchy
问题**（在半平面 y > 0 求调和函数，给定 y = 0 上的 u 与 ∂u/∂y）：

    Δu = 0  于 {y > 0}，u(x,0) = 0，∂_y u(x,0) = sin(nx)/n。

解是 u_n(x,y) = sin(nx)·sinh(ny)/n²。当 n → ∞：

- 边值：u_n(x,0) = 0（sinh 0 = 0），∂_y u_n(x,0) = sin(nx)/n → 0；
  **数据一致地趋于零**；
- 内部：u_n(π/2, 1) = sinh(n)/n² ~ e^n/(2n²) → **∞**。

若该问题适定，数据 → 0 应迫使解 → 0（线性问题的连续依赖即解算
子有界）。矛盾。所以 Laplace Cauchy 问题不适定——尽管它是椭圆方
程（"好"方程），**定解条件的搭配**错了：椭圆方程的正确问题是
Dirichlet 或 Neumann（04 章），不是 Cauchy。

### 机器验证：三通道各证一半

**Lean**（`examples/lean/Evanspde/Ch01Classification.lean`）证
反例的**代数核**——sin x · sinh y 调和：

```lean
theorem harmonic_sin_sinh (x y : ℝ) :
    deriv (fun x => deriv (fun x => sin x * sinh y) x) x
      + deriv (fun y => deriv (fun y => sin x * sinh y) y) y = 0 := by
  rw [pxx_sin_sinh, pyy_sin_sinh]
  ring
```

两个方向定理分别算出 ∂²ₓₓ(sin x·sinh y) = −sin x·sinh y 与
∂²_yy = +sin x·sinh y——`ring` 收尾相消。文件里另有
`harmonic_scaled`：对 sin(nx)·sinh(ny)/n² **直接**证调和（链式
法则 `.comp` + `mul_const` + `field_simp`），即 Hadamard 序列的
每一项都调和——所以反例序列合法，爆炸是"合法解的极限行为"。

**Julia** 实验三数值展示爆炸（n = 1..21 步长 5）：

    n= 1: sup|u_n(.,0)|=0.0e+00  sup|dy u_n(.,0)|=1.00e+00  u_n(pi/2,1)=1.175e+00
    n=16: ...                     sup|dy u_n(.,0)|=6.25e-02  u_n(pi/2,1)=1.736e+04
    n=21: ...                     sup|dy u_n(.,0)|=4.76e-02  u_n(pi/2,1)=1.495e+06

断言两条：内部值**单调**爆炸；n = 21 时超 10⁶ 而边值仍趋零。最
后一条对账渐近律：

```julia
ratio = (sinh(n)/n^2) / (exp(n)/(2*n^2))
@assert abs(ratio - 1) < 1e-15
```

**Python**（`examples/python/01_wellposed.py`）做交叉，而且更狠
一步——**残差=截断预测**的逐位对账。调和函数的数值 Laplacian 不
是零而是截断项：

    Δ_h u = Δu + (h²/12)(∂⁴ₓₓ + ∂⁴_yy)u + O(h⁴) = (h²/6)·n²·|sin(nx)|·sinh(ny)

因为 Δu = 0（Lean 已证），残差应**等于**预测公式：

```python
r = abs(lap5(u, 0.4, 0.3))
pred = (1e-6 / 6) * n**2 * abs(math.sin(n * 0.4)) * math.sinh(n * 0.3)
assert abs(r / pred - 1) < 0.02
```

实测 n = 1/3/7：残差 1.976×10⁻⁸ / 1.435×10⁻⁶ / 1.100×10⁻⁵，
与预测**三位有效数字全同**。这一步是"残差阶数对账"的强化版：
不只对量级，对**数值本身**——数值通道复现了解析截断展开的主项，
Lean 的调和性证明由此获得独立交叉。

> 顺手记一笔：本教程第一个被抓的错就在这组数字里。初版 Python
> 断言用"残差 < 10⁻⁸n²"这类想当然的界，被 n = 1 实测 1.98×10⁻⁸
> 当场打回；改成与截断预测的比值对账后才真正对齐。**阈值必须从
> 推导来，不能从感觉来。**

## 01.4 Prolog：适定性规则库

`examples/prolog/01_wellposed.pl` 把三判据做成规则：

```prolog
wellposed(P) :- exists_ok(P), unique_ok(P), continuous(P).
illposed_reason(backward_heat, 'mode growth exp(k^2 |t|): unbounded').
illposed_reason(laplace_cauchy,  'Hadamard u_n = sin(nx)sinh(ny)/n^2: ...').
```

六个典型问题查表：正向热 Dirichlet、Laplace Dirichlet、波
Cauchy、传输 Cauchy 适定；逆热与 Laplace Cauchy 不适定（附失败原
因）。审计断言 `wellposed 4 of 6` 且两个反例确实不在适定集中。

规则库里还有书 **§1.5 习题 2** 的规则版：k 阶偏导数按多重指标计
数，n 维恰有 C(n+k−1, k) 个——"星与隔板"组合。这一条在 Python
通道用 `itertools.combinations_with_replacement` 枚举对账：

```python
for (n, k) in [(2, 3), (3, 2), (3, 4)]:
    enum = len(multiindices(n, k))
    comb = math.comb(n + k - 1, k)
    assert enum == comb
```

n = 2、k = 3 枚举出 4 = C(4,3)：多重指标 (3,0),(2,1),(1,2),(0,3)。

> 又一笔对表账：Prolog 审计里初版把 n = 2、k = 3 的期望值写成
> 10，被规则引擎算出的 4 顶回——而 Python 枚举通道早给出 4。
> **两个通道各算各的，错的那个人无处藏身。** 组合数递推还有个小
> 坑：C(N,k) = C(N,k−1)·(N−k+1)/k 必须从 k = 1 端累积才保证逐步
> 整除，从另一端会踩出非整数中间值。

同一文件里还有习题 4 的计数核：Leibniz 公式 D^α(uv) = Σ_{β≤α}
C(α,β) D^β u D^{α−β} v 中"β ≤ α"的子多重指标恰有 ∏(αᵢ+1) 个
（α = (2,1) 时 6 个，枚举与乘积公式对账）——Leibniz 公式本身在
23 章幂级数方法里正式上场。

## 01.5 研究策略与全书路线

书 §1.3 给出的策略清单，映射到本教程后续章：

| 策略 | 内容 | 章 |
|---|---|---|
| 显式解 | 基本解、Green 函数、d'Alembert | 02–10 |
| 简化 | 降维、对称性、相似解 | 09、18、20 |
| 变量替换 | Cole–Hopf、hodograph | 21 |
| 渐近展开 | 奇异摄动、几何光学、均匀化 | 22 |
| 幂级数 | Cauchy–Kovalevskaya | 23 |
| 能量估计 | 弱解、先验估计 | 05 起全书 |
| 泛函分析 | Lax–Milgram、半群 | 29、38 |
| 变分法 | 直接方法、山路 | 39–42 |
| 不动点 | Banach、Schauder | 43 |
| 结构条件 | 熵、粘性、单调性 | 45–48 |

一句话总览（书 §1.4 的路线）：**第一部分求公式，第二部分用能量
估计与泛函分析造弱解，第三部分对各种非线性各显神通**。

## 01.6 要点回顾

1. 适定 = 存在 + 唯一 + 连续依赖；不适定的定解问题没有可靠的
   （数值或解析）解法。
2. 逆热：模式放大 e^{k²|t|} 关于 k 无界——反问题不适定的原型。
3. Hadamard 反例：调和函数列 sin(nx)sinh(ny)/n² 边值趋零、内部
   爆炸——椭圆方程配 Cauchy 数据就毁掉适定性。
4. 三通道分工样板：Lean 证代数核（调和性），Julia 数值爆炸与渐
   近律，Python 残差=截断预测的逐位对账。
5. 多重指标计数 C(n+k−1,k)（习题 2）与 Leibniz 子指标计数
   ∏(αᵢ+1)（习题 4 核）——后面 Sobolev 空间与 CK 定理的的地砖。

*本章示例：`examples/julia/01_wellposed.jl`、`examples/python/
01_wellposed.py`、`examples/prolog/01_wellposed.pl`、
`examples/lean/Evanspde/Ch01Classification.lean`。*

---

上一章：[00 导言](00-intro.md) · 下一章：[02 传输方程](02-transport.md) · [返回目录](../README.md)
