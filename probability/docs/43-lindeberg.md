# 第 43 章 Lindeberg 条件：中心极限定理的充要边界

## 43.1 为什么同分布的 CLT 不够

第 27 章的中心极限定理回答的是同分布问题：$X_1,X_2,\dots$ 独立同分布、方差有限，则标准化和依分布收敛到 $N(0,1)$ 。但应用中大量场景**天然不同分布**：

- 资产组合里 8 只股票的波动率可以差一个数量级（权重集中度的风险）；
- 保险公司一个月的总理赔来自不同保额层级的保单；
- 高频数据里一天内各时段的波动率有明显的日内模式。

它们的共同形状是：第 $n$ 组观测由 $n$ 个**独立但不必同分布**的变量组成，且没有任何一项"天然主导"。何时这种异质和仍然正态化？本章的答案由一个条件给出——Lindeberg 条件，以及它在"没有单项主导"前提下的充要化（Lindeberg–Feller 定理）。这是从"记住定理"到"能检查定理前提"的一步：条件本身是可计算的，本章四条机器通道全部围绕它的精确账展开。

## 43.2 三角阵列与总方差

固定一个序列 $X_1,X_2,\dots$ （独立，期望 $m_k$ ，方差 $\sigma_k^2$ 有限）。记部分和与总方差：

$$ S_n=\sum_{k=1}^{n}X_k,\qquad c_n^2=\operatorname{var}(S_n)=\sum_{k=1}^{n}\sigma_k^2, $$

标准化的部分和为 $T_n=(S_n-E S_n)/c_n$ 。当 $n$ 变化时，参与求和的变量个数也在变化——把 $(X_k-m_k)/c_n$ （$1\le k\le n$ ）排成一张三角形，第 $n$ 行有 $n$ 个分量，这就是**三角阵列**的视角。第 44 章将把阵列本身允许随 $n$ 变化（$X_{n,k}$ ），本章先处理"每行都是序列前缀"的简单情形，直觉完全一致。

$T_n$ 正态化的物理图像：把总方差 $c_n^2$ 想象成总"话语权"，每个分量持有份额 $\sigma_k^2/c_n^2$ 。CLT 成立与否，取决于这份话语权是否**分散**。

## 43.3 Lindeberg 条件：民主条款

$$ \forall\varepsilon>0:\quad \frac{1}{c_n^2}\sum_{k=1}^{n}\int_{|x-m_k|\ge\varepsilon c_n}(x-m_k)^2\,dF_k(x)\ \longrightarrow\ 0\quad(n\to\infty). $$

这就是胡书式 (5.3.5) 的 **Lindeberg 条件**。读法：对每个阈值 $\varepsilon c_n$ （随 $n$ 增大），把各分量分布中"越过阈值的那部分"的方差加起来、除以总方差——要求它消失。也就是说：**对总波动而言，任何单个分量的大幅跳动都可忽略**。没有谁单独拥有不可忽略的"越线方差"，这就是民主条款。

本章机器件的核心化简：若 $X_k$ 是两点分布 $\pm\sigma_k$ （等概率、零均值），则被积函数恰为 $\sigma_k^2\cdot 1\{\sigma_k^2\ge\varepsilon^2 c_n^2\}$ ——判据两边平方，Lindeberg 商变成纯有理数算术：

$$ L_n(\varepsilon)=\frac{\sum_{k\,:\,\sigma_k^2\ge\varepsilon^2c_n^2}\sigma_k^2}{c_n^2}. $$

这使 Julia/Python/Prolog/Lean 四条通道可以做**精确**账，而不用数值积分。

## 43.4 定理 5.3.1 与证明骨架

**定理（Lindeberg CLT，胡书定理 5.3.1）** 设 $X_1,X_2,\dots$ 独立，方差有限，$c_n^2=\sum_k\operatorname{var}(X_k)$ 。若 Lindeberg 条件 (5.3.5) 成立，则 $T_n=(S_n-E S_n)/c_n$ 依分布收敛到 $Z\sim N(0,1)$ 。

证明用特征函数（第 28 章的工具），骨架分五步，每步都不神秘：

1. **截断展开**（引理 5.3.1）：对任意实数 $y$ 与 $|z|\le|y|$ ，

$$ e^{iy}=1+iy+\theta\frac{y^2}{2}\ (|\theta|\le1),\qquad e^{iy}=1+iy-\frac{y^2}{2}+\theta'\frac{y^2}{2}\ (|\theta'|\le1), $$

   以及 $\operatorname{Log}(1+z)=z+\theta''\frac{|z|^2}{2}$ 。这是把特征函数在 $1$ 附近展开到二阶、误差可控。

2. **分部**：把 $h_k(u)$ 在 $|x|<\varepsilon c_n$ 与 $|x|\ge\varepsilon c_n$ 两段积分，得到 $h_k(u)=1-\frac{u^2\sigma_k^2}{2c_n^2}+\alpha_{nk}+\beta_{nk}$ ，其中截断段误差 $|\alpha_{nk}|\le\varepsilon^2 u^2\sigma_k^2/c_n^2$ 、越线段误差被 Lindeberg 条件压扁。

3. **乘积取对数**：独立性给 $h_{T_n}(u)=\prod_k h_k(u/c_n)$ ，再对 $\sum_k\operatorname{Log}(1+\eta_{nk})$ 用第三条展开。

4. **极限**：$\max_k|\eta_{nk}|\to0$ 且 $\sum_k(\alpha_{nk}+\beta_{nk})\to0$ ，于是 $\log h_{T_n}(u)\to-u^2/2$ 。

5. **翻译**：Lévy 连续定理（第 28.10 节）把逐点收敛的特征函数翻成依分布收敛。

注意第 2 步里 Lindeberg 条件只压"越线段"——这正是它作为民主条款的角色：大跳动的总贡献必须可忽略，剩下的都是可加的小贡献。

## 43.5 三个好用的充分条件

胡书注 5.3.2–5.3.4 给出三个"检查更容易"的充分条件：

- **有界分量**（注 5.3.2）：$|X_k|\le M$ 且 $c_n\to\infty$ 时 Lindeberg 条件自动成立——阈值 $\varepsilon c_n$ 终将越过 $M$ ，越线方差整体为零。本章机器账给出整数证书：$\sigma_k^2=3$ 的有界族在 $n=4$ 时阈值 $3$ 恰被踩线（商为 $1$ ），$n=5$ 起阈值 $15/4>3$ ，商精确为 $0$ 。
- **同分布**（注 5.3.3）：iid + 有限方差时 Lindeberg 条件成立，定理退化为第 27 章的经典 CLT。
- **Lyapunov 条件**（注 5.3.4）：存在 $\delta>0$ 使 $\sum_k E|X_k|^{2+\delta}=o(c_n^{2+\delta})$ ，则 Lindeberg 条件成立——用更高阶矩一揽子控制越线段。

实务检查顺序建议：先看是否有界或同分布（免费），再算 Lyapunov 比值（只要高阶矩存在），最后才直接算 Lindeberg 商。

## 43.6 例 5.3.1：正态和的"假民主"

Lindeberg 条件是充分的，但**不是必要的**（注 5.3.5）。胡书例 5.3.1 是最干净的反例：

设 $X_1\sim N(0,1)$ ，$X_k\sim N(0,2^{k-2})$ （$k\ge2$ ）独立。则 $c_n^2=2^{n-1}$ （几何级数求和），且 $T_n=\sum_k X_k/c_n$ 是独立正态之和——**精确地**服从 $N(0,1)$ ，对每个 $n$ 都是。CLT 的结论有了，条件却失败：末项方差份额

$$ \frac{2^{n-2}}{2^{n-1}}=\frac12\qquad(\text{对所有 } n\ge2), $$

无论加多少项，最后一项永远握着一半话语权——独裁永不退位。对 $\varepsilon<1/\sqrt2$ ，越线方差中至少含这半壁江山，Lindeberg 商不趋于零。

这个例子分离了两件事：**结论成立**（正态性可以从分量正态性直接继承，与民主无关）与**条件成立**（民主是"任意分量结构下正态极限"的保障）。Lindeberg 条件买的是后者。

## 43.7 u.a.n. 与 Feller 条件

要把 Lindeberg 条件补成充要，需要排除"假民主"的结构。称 $(X_k)$ 为 **u.a.n. 序列**（一致渐近可忽略，定义 5.3.1）：

$$ \forall\varepsilon>0:\quad \max_{1\le k\le n}P\!\left(\frac{|X_k-m_k|}{c_n}\ge\varepsilon\right)\ \longrightarrow\ 0. $$

每个分量在标准化尺度下都变成"无穷小"。胡书注 5.3.6 给出它的方差等价刻画（**Feller 条件**）：

$$ (X_k-m_k)/c_n\ \text{u.a.n.}\iff \max_{1\le k\le n}\frac{\sigma_k^2}{c_n^2}\ \longrightarrow\ 0. $$

对两点分布数组，u.a.n. 的判决尤其干净：$P(|X_k|/c_n\ge\varepsilon)$ 非 $0$ 即 $1$ ，于是 u.a.n. $\iff$ 没有越线者 $\iff$ Lindeberg 商为零——Prolog 通道直接把这一等价做成判决。

## 43.8 定理 5.3.2：Lindeberg–Feller 充要定理

**定理（胡书定理 5.3.2）** 设 $X_1,X_2,\dots$ 独立、方差有限。则

$$ \text{Lindeberg 条件}\iff\big(T_n\to Z\ \text{且}\ (X_k-m_k)/c_n\ \text{u.a.n.}\big). $$

语义：**在民主（u.a.n.）前提下，CLT 与 Lindeberg 条件等价**。例 5.3.1 恰好卡在右边的裂缝里——$T_n$ 收敛但没有 u.a.n.（末项份额恒 $1/2$ ），所以它不与条件的失败矛盾。反过来这也说明：如果你的数据生成里有一项"系统性偏大"的波动源，正态近似失效不是数值巧合，而是结构性的。

机器账把两个方向都变成可算的对象：Feller 份额 $\max\sigma_k^2/c_n^2$ （多项式族 $2/(n+1)\to0$ ，几何族恒 $1/2$ ）与 Lindeberg 商（多项式族归零，几何族恒 $3/4$ ）。

## 43.9 机器账 I：三族对照与峰度签名

Julia 与 Python 各自实现同一个商函数（判据两边平方，全程有理）：

```julia
quot(sig2::Vector{Int}, eps::Rational{Int}) =
    let c2 = sum(sig2), thr = eps * eps * c2
        sum(s2 -> s2 >= thr ? s2 : 0, sig2) // c2
    end
```

```python
def quot(sig2, eps):
    c2 = sum(sig2)
    thr = eps * eps * c2
    return F(sum(s for s in sig2 if s >= thr), c2)
```

三族对照（$\varepsilon=1/2$ ，两点分布 $\pm\sigma_k$ ，`examples/julia/43_lindeberg.jl` 与 `examples/python/43_lindeberg.py`）：

| 方差族 | $L_n(1/2)$ 的行为 | 语义 |
|---|---|---|
| 多项式 $\sigma_k^2=k$ | $n=7$ ：$1/4$ ；$n=8$ ：$0$ ，此后恒 $0$ | 民主：阈值 $n(n+1)/8$ 终将越过所有 $k\le n-1$ |
| 几何 $1,1,2,\dots,2^{n-2}$ | 恒 $3/4$ （$n\ge4$ ） | 独裁：越线方差恰为末两项 $2^{n-3}+2^{n-2}$ ，占比纹丝不动 |
| 有界 $\sigma_k^2=3$ | $n=4$ ：$1$ （踩线）；$n\ge5$ ：$0$ | 注 5.3.2 的整数证书版本 |

"多项式族 $n=8$ 商精确归零"是本章第一个整数证书：$c_8^2=36$ ，$\varepsilon^2c_8^2=9>8=\max\sigma_k^2$ ，越线者清空。

第二件机器证据是**峰度签名**。独立两点变量的和 $T_n$ 有精确四阶矩账（奇数阶消失、交叉项 $6\sum_{j<k}\sigma_j^2\sigma_k^2$ ）：

$$ \operatorname{kurt}(T_n)=3-2\,\frac{\sum_k\sigma_k^4}{c_n^4}. $$

- 多项式族：$\sum\sigma_k^4/c_n^4\sim\frac{4}{3n}\to0$ ，峰度 $\to3$ （正态化）；
- 几何族：$\sum\sigma_k^4/c_n^4\to\frac13$ ，峰度恒趋 $7/3$ ——**差 $2/3$ 的缺口永不愈合**，非正态性写在四阶矩里。

Julia 在固定种子（`MersenneTwister(4301)`）下 $10^5$ 次模拟：几何族经验峰度 $2.333$ （对账 $7/3$ ），多项式族 $n=32$ 时 $2.93$ 。特征函数一侧同向：正态几何族的 $|\varphi_{T_n}(u)|=\exp(-u^2/2)$ 精确成立（例 5.3.1 的 CLT），而两点几何族 $|\varphi|=\prod_k\cos(u\sigma_k/c_n)<\exp(-u^2/2)$ ——cos 每步都比 Gaussian 半步衰减更狠。

组合体检（④ 段）：8 个方差全 $1$ 的资产，商 $0$ 、最大份额 $1/8$ ；换成 $[1,\dots,1,16]$ （一只独大），商 $16/23\approx0.70$ 、最大份额同——**正态近似何时可用是一个可以逐项检查的工程问题**。

## 43.10 机器账 II：Lean 的两条一般 $n$ 定理

Lean 件（`examples/lean/Probability/Ch43Lindeberg.lean`）分三层。

**锚点层**：mathlib 没有 Lindeberg 定理，但 iid 情形就是现成的 CLT：

```lean
#check @ProbabilityTheory.tendstoInDistribution_inv_sqrt_mul_sum
-- iid、零均值、单位方差的标准化和依分布收敛到 N(0,1)
```

其完整签名要求 `iIndepFun`（独立函数列）与 `IdentDistrib`（同分布），恰是注 5.3.3 的机器化。

**定义层**：把两点数组的 Lindeberg 商做成一等公民：

```lean
def twoPointLindebergQuot (sig2 : List ℚ) (eps : ℚ) : ℚ :=
  let c2 := sig2.sum
  (sig2.map fun s => if s ≥ eps * eps * c2 then s else 0).sum / c2
```

四个 concrete 例（$1/4$ 、$0$ 、$1$ 、$0$ ）由 `norm_num` 直接判——包括"踩线"与"归零"的边界。

**定理层**：两条一般 $n$ 的完全证明。民主归零：

```lean
theorem polyQuot_zero (n : ℕ) (hn : 6 ≤ n) :
    ∑ k ∈ Finset.range n, polyTerm n k = 0
```

关键代数是 $n(n+1)-8(n-1)=(n-1)(n-6)+2>0$ （对 $n\ge6$ ），把"阈值越过所有项"化成一次 `linarith`。独裁不退位：

```lean
theorem geoQuot_const (m : ℕ) (hm : 1 ≤ m) :
    (∑ k ∈ Finset.range (m + 3), geoTerm m k) / (2 : ℚ) ^ (m + 2) = 3 / 4
```

证明按三步拆尾 $\sum_{k<m+3}=\sum_{k<m}+f(m)+f(m+1)+f(m+2)$ ：前段逐项为零（$k=0$ 时 $1<2^m$ ；$1\le k<m$ 时 $2^{k-1}<2^m$ ，由自证的 2 的幂单调引理 `two_pow_lt` 给出），末三项依次为 $0,2^m,2^{m+1}$ ，合计 $(2^m+2^{m+1})/2^{m+2}=3/4$ 。例 5.3.1 的几何方差账也单独成例：$\sum_{k<n}2^k=2^n-1$ （`geom_sum_eq`）与末项份额恒 $1/2$ 。

## 43.11 机器账 III：Prolog 的商与 u.a.n. 判决

Prolog 件（`examples/prolog/43_lindeberg.pl`）把 43.7 节的等价做成判决器。商用 `rdiv` 精确计算：

```prolog
quot(Sig2, Eps, Q) :-
    sum_list(Sig2, C2),
    T is Eps * Eps * C2,
    over_sum(Sig2, T, S),
    Q is S rdiv C2.

uan(Sig2, Eps) :- quot(Sig2, Eps, 0).   % 两点分布：无越线者 ⟺ u.a.n.
```

三段输出：① 三族商（`1r4`/`0`/`3r4`——SWI 打印有理数用 `r` 代替分数线）；② u.a.n. 判决——多项式 $n=8$ 通过（每项越线概率为 $0$ ）、几何 $n=6$ 失败（末项越线概率为 $1$ ）；③ Feller 份额（$2/9$ 对 $1/2$ ）与峰度亏损（$171/256$ 对 $17/54$ ，全部精确分数）。

## 43.12 经济与统计落地

- **组合风险管理**：等权分散的组合，总损失的正态近似有 Lindeberg 背书；集中度高的组合（一只资产握半数方差）尾部由那只资产决定，用正态分布算 VaR 会系统性低估尾部。43.9 节的"体检器"三行代码即可搬进风险报表。
- **保险聚合**：保单层级的保额分布右偏且不同质；总理赔 CLT 成立的前提是"没有单张巨型保单主导总理赔方差"——再保险的存在正是人为恢复民主条款。
- **回归推断**：第 38–41 章的 OLS 渐近理论底层同样是异质和的 CLT（误差项不同分布时）；Lindeberg 条件就是"异方差下 t 检验仍渐近有效"的数学前提之一。

## 43.13 常见误区

1. **"大样本自动正态"**——不对。样本量救不了结构：几何方差族的峰度缺口 $2/3$ 与 $n$ 无关。
2. **"Lindeberg 是 CLT 的必要条件"**——只在 u.a.n. 前提下（定理 5.3.2）。例 5.3.1 有精确正态极限却违背条件。
3. **"阈值检验会漏掉踩线项"**——判据 $|x|\ge\varepsilon c_n$ 是闭的：有界族 $n=4$ 时阈值 $3$ 恰被 $\sigma^2=3$ 踩线，商为 $1$ 而非 $0$ ；机器账保留了这个边界。
4. **"峰度接近 3 就完事"**——峰度只是一个四阶矩签名；它在这里恰好把两类族分开，是因为两点分布族的非正态性完全集中在四阶矩上。一般分布需要看整套条件。

## 43.14 本章要点

1. Lindeberg 条件 = 越线方差占比消失 = 没有单个分量能主导总波动的"大跳动"；对两点分布可两边平方变成纯有理算术。
2. 定理 5.3.1：条件 ⟹ 异质和正态化；证明五步 = 展开、分部、取对数、极限、Lévy 翻译。
3. 三个充分条件：有界 + $c_n\to\infty$ ；iid；Lyapunov（$2+\delta$ 矩）。
4. 例 5.3.1：正态分量给精确正态极限但条件失败（末项份额恒 $1/2$ ）——结论与条件是两回事。
5. 定理 5.3.2：民主（u.a.n./Feller）前提下 CLT $\iff$ Lindeberg；Feller 条件 $\max\sigma_k^2/c_n^2\to0$ 是可计算的份额检查。
6. 机器证据链：整数证书（$n=8$ 归零、$n=5$ 归零）→ 峰度签名（$7/3$ 对 $3$ ）→ Lean 一般 $n$ 定理（$(n-1)(n-6)+2$ 与三步拆尾）→ Prolog 判决（商与 u.a.n. 合一）。

---

*对应示例：`examples/lean/Probability/Ch43Lindeberg.lean`（CLT 锚点 + 两点商 + 两条一般 $n$ 定理）、`examples/julia/43_lindeberg.jl`（三族商 + 峰度签名 + 特征函数账 + 组合体检）、`examples/python/43_lindeberg.py`（精确分数商 + Feller 份额 + MC 峰度）、`examples/prolog/43_lindeberg.pl`（rdiv 商 + u.a.n. 判决 + 峰度亏损）。*

---

上一章：[42 综合案例与概率证明方法](42-synthesis.md) · 下一章：[44 无穷可分分布：任意切分的分布族](44-infinitely-divisible.md)
