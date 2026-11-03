# 第 24 章 差分方程与 Markov 链

## 24.1 从递推到随机动力系统

前面各章主要研究一次试验或一维、多维随机向量。本章让随机性随时间展开：

$$
X_0,X_1,X_2,\dots.
$$

这里 $X_n$ 是第 $n$ 时刻的状态。若只观察当前状态，下一时刻的条件分布就已经确定，而与更早历史无关，就称序列具有 Markov 性：

$$
\boxed{
P(X_{n+1}=j\mid X_n=i,X_{n-1}=i_{n-1},\dots,X_0=i_0)
=P(X_{n+1}=j\mid X_n=i).
}
$$

这个等式不是“未来与过去独立”。未来通常与过去相关；它只是说，**在已知当前状态的条件下，更早历史不再提供额外预测信息**。

若右侧还不依赖时间 $n$，称为时间齐次 Markov 链。本章只讨论有限状态、时间齐次链。此时全部转移规律可写成一个矩阵

$$
P=(p_{ij}),\qquad
p_{ij}=P(X_{n+1}=j\mid X_n=i).
$$

矩阵每行非负且和为 1：

$$
p_{ij}\ge0,\qquad \sum_jp_{ij}=1.
$$

这样的矩阵称为行随机矩阵。第 $i$ 行是从状态 $i$ 出发的一步条件分布，而不是第 $i$ 列。

Markov 链与差分方程共享一个核心思想：用有限维状态概括历史。五连正面问题需要知道最近五次结果；把“当前连续正面长度”设为状态后，下一步只需看当前长度，问题就成为 Markov 链。

## 24.2 两状态链：转移、平稳与收敛

考虑两个地区之间的人口比例变化。每一步中：

- 状态 0 有 $1/5$ 的比例转向状态 1；
- 状态 1 有 $3/10$ 的比例转向状态 0。

因此

$$
P=
\begin{pmatrix}
4/5&1/5\\
3/10&7/10
\end{pmatrix}.
$$

若初始分布为行向量 $\mu^{(0)}$，一步后

$$
\mu^{(1)}=\mu^{(0)}P.
$$

分布用行向量左乘，状态值函数则用列向量右乘：

$$
(Pf)(i)=\sum_jp_{ij}f(j)=E[f(X_1)\mid X_0=i].
$$

这两种方向不能混淆。

两步转移由条件概率和全概率公式给出：

$$
P(X_2=j\mid X_0=i)
=\sum_kP(X_1=k\mid X_0=i)P(X_2=j\mid X_1=k)
=\sum_kp_{ik}p_{kj}.
$$

所以两步矩阵就是 $P^2$。Lean 对本例逐元素计算：

```lean
theorem two_step :
    mul2 P2 P2 0 0 = 7/10 ∧ mul2 P2 P2 0 1 = 3/10 ∧
    mul2 P2 P2 1 0 = 9/20 ∧ mul2 P2 P2 1 1 = 11/20 := by
  simp [mul2, P2]
  norm_num
```

## 24.3 Chapman–Kolmogorov 方程

一般地，$n$ 步转移概率为

$$
p_{ij}^{(n)}=P(X_{m+n}=j\mid X_m=i)=(P^n)_{ij}.
$$

把 $m+n$ 步旅程在中间时刻 $m$ 切开，得到

$$
\boxed{
p_{ij}^{(m+n)}=\sum_kp_{ik}^{(m)}p_{kj}^{(n)},
}
$$

即

$$
\boxed{P^{m+n}=P^mP^n.}
$$

这就是 Chapman–Kolmogorov 方程。它来自条件化与矩阵乘法结合律，不依赖平稳性或遍历性。

Prolog 用有理数矩阵乘法直接核对：

```prolog
mpow(P, 3, P3), mpow(P, 4, P4), mpow(P, 7, P7),
mmul(P3, P4, P34), P7 == P34
```

这里 `==` 要求两个有理矩阵的项完全一致，不是近似浮点比较。

Lean 对三状态生灭链检查两种乘法顺序：

```lean
theorem ck_assoc : ∀ i j : Fin 3,
    mul3 (mul3 P3 P3) P3 i j = mul3 P3 (mul3 P3 P3) i j := by
  intro i j
  fin_cases i <;> fin_cases j <;> simp [mul3, P3] <;> norm_num
```

对固定矩阵，$P^2P=PP^2$ 当然成立；这个有限验证强调的是 Chapman–Kolmogorov 方程背后的结合律结构。

## 24.4 平稳分布

若概率向量 $\pi$ 满足

$$
\boxed{\pi P=\pi,\qquad \sum_i\pi_i=1,}
$$

则称 $\pi$ 为平稳分布。若 $X_0\sim\pi$，则

$$
X_1\sim\pi P=\pi,
$$

归纳可知每个 $X_n$ 都服从 $\pi$。因此“平稳”首先是**边际分布不随时间改变**。

两状态链

$$
P=\begin{pmatrix}1-a&a\\b&1-b\end{pmatrix}
$$

的平稳方程为

$$
\pi_0(1-a)+\pi_1b=\pi_0,
\qquad \pi_0+\pi_1=1.
$$

第一式化为 $\pi_1a=\pi_0b$，所以

$$
\boxed{
\pi_0=\frac b{a+b},\qquad \pi_1=\frac a{a+b}.
}
$$

本例 $a=1/5,b=3/10$，故

$$
\pi=(3/5,2/5).
$$

Lean 逐项验证：

```lean
theorem two_state_stationary :
    (3/5 : ℚ) * (4/5) + (2/5) * (3/10) = 3/5 ∧
    (3/5 : ℚ) * (1/5) + (2/5) * (7/10) = 2/5 ∧
    (3/5 : ℚ) + 2/5 = 1 := by
  norm_num
```

Prolog 则把一般两状态公式写成可复用谓词：

```prolog
stat2([[_, A], [B, _]], [P0, P1]) :-
    P0 is B/(A+B), P1 is A/(A+B).
```

### 24.4.1 平稳不等于依分布收敛

这两个概念必须分开：

- **平稳分布**：从 $\pi$ 出发，分布保持不变；
- **依分布收敛到 $\pi$**：从给定初始分布出发，$\mu^{(n)}\to\pi$。

周期链可以有平稳分布但不收敛。例如

$$
P=\begin{pmatrix}0&1\\1&0\end{pmatrix}
$$

有平稳分布 $(1/2,1/2)$，但从状态 0 出发，分布永远在

$$
(1,0),\quad(0,1),\quad(1,0),\dots
$$

之间切换。不可约、非周期等条件才用于排除这种振荡。

还存在另一个区别：即使 $X_n$ 的分布收敛到 $\pi$，也不表示随机路径 $X_n(\omega)$ 收敛到某个常数。链仍会在状态之间跳动，收敛的是分布，不是每条路径。

## 24.5 两状态链的闭式与收敛速率

设

$$
p_n=P(X_n=0\mid X_0=0).
$$

对第 $n$ 步状态条件化：

$$
p_{n+1}=p_n(1-a)+(1-p_n)b
=b+(1-a-b)p_n.
$$

令 $\lambda=1-a-b$，平稳点为 $\pi_0=b/(a+b)$。作差得到

$$
p_{n+1}-\pi_0=\lambda(p_n-\pi_0).
$$

因此

$$
\boxed{
p_n=\pi_0+\lambda^n(1-\pi_0)
=\frac b{a+b}+\lambda^n\frac a{a+b}.
}
$$

Lean 对一般有理数 $a,b$ 归纳证明：

```lean
theorem pn_closed (a b : ℚ) (h : a + b ≠ 0) (n : ℕ) :
    pn a b n = b / (a + b) + (1 - a - b) ^ n * (a / (a + b)) := by
  induction n with
  | zero => field_simp; ring
  | succ n ih =>
    simp only [pn, ih]
    field_simp
    ring
```

本例 $\lambda=1/2$，所以从状态 0 出发，

$$
p_n=\frac35+\left(\frac12\right)^n\frac25.
$$

更一般地，令 $\Pi$ 为每一行都等于 $\pi$ 的矩阵，则

$$
\boxed{P^n=\Pi+\lambda^n(I-\Pi).}
$$

Python 对多个 $n$ 用精确分数检查：

```python
Pi = [pi2, pi2]
for n in (1, 2, 5, 10):
    Pn = matpow(P2, n)
    for i in range(2):
        for j in range(2):
            assert Pn[i][j] == Pi[i][j] + lam ** n * (
                F(int(i == j)) - Pi[i][j])
```

当 $|\lambda|<1$ 时，所有初始分布都以几何速度趋近 $\pi$。本例次特征值模为 $1/2$，每步把偏差缩小一半。

## 24.6 可达性、通信类与闭集

若存在 $n\ge0$ 使 $p_{ij}^{(n)}>0$，称从 $i$ 可达 $j$，记作 $i\to j$。若双向可达，称 $i,j$ 互通，记作 $i\leftrightarrow j$。

互通是等价关系，把状态空间划分为通信类。若整个状态空间只有一个通信类，链不可约。

类 $C$ 为闭集，若

$$
i\in C,\quad i\to j\quad\Longrightarrow\quad j\in C.
$$

一旦进入闭类就不能离开。只有一个状态的闭类是吸收态，其转移满足 $p_{ii}=1$。

Python 用布尔传递闭包计算可达关系：

```python
R = [[P[i][j] > 0 or i == j for j in range(n)]
     for i in range(n)]
for k in range(n):
    for i in range(n):
        for j in range(n):
            R[i][j] = R[i][j] or (R[i][k] and R[k][j])
```

示例链的通信类为

$$
\{0\},\qquad\{1,2\},\qquad\{3\},
$$

其中 $\{1,2\}$ 与 $\{3\}$ 是闭类，状态 0 可以离开自己的类。

有限 Markov 链中：

- 有限闭通信类中的状态都是常返态；
- 非闭类中的状态是暂态；
- 暂态状态最终被访问的次数几乎必然有限；
- 常返状态从该类出发会被无穷多次返回。

有限状态链至少有一个闭通信类，因此至少有一个常返状态。不可约有限链的全部状态都常返，并且存在唯一平稳分布。

## 24.7 周期与非周期性

状态 $i$ 的周期定义为所有可能返回时间的最大公约数：

$$
\boxed{
d(i)=\gcd\{n\ge1:p_{ii}^{(n)}>0\}.
}
$$

若 $d(i)=1$，状态非周期。同一通信类中的状态周期相同。

二状态循环 $0\to1\to0$ 的返回时间为 $2,4,6,\dots$，周期为 2。若某状态有自环 $p_{ii}>0$，则返回时间包含 1，故周期必为 1。

有限不可约、非周期链称为遍历链。其基本极限定理为

$$
P^n\longrightarrow\Pi,
$$

其中 $\Pi$ 的每一行都是唯一平稳分布 $\pi$。不可约保证只有一份长期质量分配，非周期性消除确定性循环。

周期链仍可能满足 Cesàro 平均收敛：

$$
\frac1N\sum_{n=0}^{N-1}P^n\to\Pi,
$$

即使 $P^n$ 本身振荡。这也解释了为什么“长期访问比例”与“第 $n$ 时刻分布”不能混为一谈。

## 24.8 细致平衡与可逆性

若概率向量 $\pi$ 满足

$$
\boxed{\pi_ip_{ij}=\pi_jp_{ji}\qquad\text{对所有 }i,j,}
$$

则称链关于 $\pi$ 满足细致平衡。把等式对 $i$ 求和：

$$
\sum_i\pi_ip_{ij}
=\pi_j\sum_ip_{ji}
=\pi_j.
$$

所以细致平衡蕴含 $\pi$ 平稳，但反向不成立。

细致平衡的含义是：平稳运行时，任意有向边 $i\to j$ 的概率流等于反向边 $j\to i$ 的概率流。这比总流入等于总流出更强。

考虑三状态生灭链

$$
P=
\begin{pmatrix}
1/2&1/2&0\\
1/4&1/2&1/4\\
0&1/2&1/2
\end{pmatrix},
\qquad
\pi=(1/4,1/2,1/4).
$$

Python 检查所有状态对：

```python
assert all(pi3[i] * P3[i][j] == pi3[j] * P3[j][i]
           for i in range(3) for j in range(3))
```

Lean 对九个状态对逐一展开并化简：

```lean
theorem birth_death_detailed_balance :
    ∀ i j : Fin 3,
      ![(1/4 : ℚ), 1/2, 1/4] i * P3 i j =
      ![(1/4 : ℚ), 1/2, 1/4] j * P3 j i := by
  intro i j
  fin_cases i <;> fin_cases j <;> norm_num [P3]
```

再看定向三圈链

$$
C=
\begin{pmatrix}
0&3/4&1/4\\
1/4&0&3/4\\
3/4&1/4&0
\end{pmatrix}.
$$

它双随机，所以均匀分布 $(1/3,1/3,1/3)$ 平稳；但顺时针和逆时针流量不同，故不满足细致平衡。平稳分布只要求净流量平衡，并不要求每条边双向流量相等。

## 24.9 首达问题：用一步方程代替无限路径求和

设 $A$ 为目标状态集合，首达时间为

$$
T_A=\inf\{n\ge0:X_n\in A\}.
$$

定义

$$
h_i=P_i(T_A<\infty),
\qquad
t_i=E_i[T_A].
$$

对暂态状态做一步分解，通常得到

$$
h_i=\sum_jp_{ij}h_j,
$$

目标态边界 $h_i=1$，永远到不了目标的吸收边界 $h_i=0$。

若首达时间有限且期望有限，则

$$
t_i=1+\sum_jp_{ij}t_j,
$$

目标态边界 $t_i=0$。这里的 1 是已经消耗的一步。

首达方法的关键不是枚举无限多条路径，而是把无限未来折叠为“一步之后仍处于同一个问题”。

## 24.10 赌徒破产

赌徒初始资本为 $i$，每局以概率 $p$ 增加 1，以概率 $q=1-p$ 减少 1；资本到 0 或 $N$ 时停止。令

$$
h_i=P_i(\text{先到 }N).
$$

边界为 $h_0=0,h_N=1$，内部满足

$$
h_i=ph_{i+1}+qh_{i-1}.
$$

公平情形 $p=q=1/2$ 时，二阶差分为零，故 $h_i$ 是直线，边界条件给出

$$
\boxed{h_i=\frac iN.}
$$

不公平且 $p\ne q$ 时，令 $\rho=q/p$，解为

$$
\boxed{
h_i=\frac{1-\rho^i}{1-\rho^N}.
}
$$

期望停止时间 $t_i=E_i[T]$ 满足

$$
t_i=1+pt_{i+1}+qt_{i-1},
\qquad t_0=t_N=0.
$$

公平情形的解为

$$
\boxed{t_i=i(N-i).}
$$

Python 用 SymPy 精确求解线性方程，而非模拟大量赌局：

```python
eh = [h[0], h[N] - 1] + [
    h[i] - P * h[i + 1] - Q * h[i - 1]
    for i in range(1, N)]
et = [t[0], t[N]] + [
    t[i] - 1 - P * t[i + 1] - Q * t[i - 1]
    for i in range(1, N)]
```

对 $N=5$，程序同时验证公平与 $p=2/3$ 两种闭式。精确线性方程把吸收概率和平均时长分开，避免用同一个模拟回答两个不同问题。

## 24.11 五连正面：状态扩张与两种递推对账

问：公平硬币至少需要抛多少次，才期望出现连续 5 次正面？

把当前连续正面长度记为 $s\in\{0,1,2,3,4\}$，并设吸收态 5。对 $s<5$：

- 下一次正面，进入 $s+1$；
- 下一次反面，回到 0。

令 $E_s$ 为从状态 $s$ 到首次吸收还需的期望次数，则

$$
E_s=1+\frac12E_{s+1}+\frac12E_0,
\qquad E_5=0.
$$

猜想并验证

$$
\boxed{E_s=2^6-2^{s+1}.}
$$

特别地，

$$
\boxed{E_0=64-2=62.}
$$

Prolog 对所有暂态状态检查一步方程：

```prolog
forall(between(0, 4, S),
       (e5(S, ES), e5(0, E00),
        (S < 4 -> S1 is S+1, e5(S1, ES1) ; ES1 = 0),
        ES =:= 1 + (ES1 + E00)/2))
```

还可计算 100 次内已经出现五连正面的概率。令 $b_n$ 为前 $n$ 次没有五连正面的概率，按开头第一段连续正面长度分类：

$$
b_n=\sum_{k=1}^5\frac{b_{n-k}}{2^k},
\qquad b_0=\cdots=b_4=1.
$$

另一方面，状态扩张后的吸收概率为 $(P^{100})_{0,5}$。Python 对账：

```python
M = matpow(P5, 100)
assert M[0][5] == 1 - b[100]
assert float(M[0][5]) > 0.81 and float(M[0][5]) < 0.82
```

两个算法使用同一 Markov 结构的不同表达：补事件递推记录“尚未出现”，吸收矩阵记录“已经出现”。二者相等是有意义的独立实现核对。

## 24.12 差分方程与矩阵幂

一般深度 $k$ 的线性递推

$$
a_{n+1}=c_1a_n+\cdots+c_ka_{n-k+1}
$$

可以写成状态向量递推。以 Fibonacci 为例，

$$
F_{n+1}=F_n+F_{n-1}
$$

等价于

$$
\begin{pmatrix}F_{n+1}\\F_n\end{pmatrix}
=
\begin{pmatrix}1&1\\1&0\end{pmatrix}
\begin{pmatrix}F_n\\F_{n-1}\end{pmatrix}.
$$

因此

$$
\begin{pmatrix}1&1\\1&0\end{pmatrix}^n
=
\begin{pmatrix}
F_{n+1}&F_n\\
F_n&F_{n-1}
\end{pmatrix}.
$$

矩阵特征方程为

$$
r^2-r-1=0,
$$

根为黄金比例

$$
\varphi=\frac{1+\sqrt5}{2}
$$

和 $-1/\varphi$。主特征值模决定长期增长率。

Python 用整数矩阵幂验证 Fibonacci 恒等式：

```python
Fm = sp.Matrix([[1, 1], [1, 0]])
assert all((Fm ** n)[0, 1] == fibs[n]
           for n in (5, 10, 30))
```

这种“低阶递推高维化、高维递推矩阵化”的技巧，也是 Markov 链状态扩张的确定性前身。

## 24.13 Leslie 矩阵：人口递推不是概率转移

五个年龄组的 Leslie 矩阵为

$$
A=
\begin{pmatrix}
0&2&1&0&0\\
1&0&0&0&0\\
0&1&0&0&0\\
0&0&1&0&0\\
0&0&0&1&0
\end{pmatrix},
\qquad v_{n+1}=Av_n.
$$

第一行是各年龄组的繁殖贡献，次对角线是存活到下一龄组。这里 $A$ **不是行随机矩阵**：元素表示期望繁殖数和存活数，行和不必为 1，向量分量是人口数而非概率。

Python 计算特征多项式：

```python
cp = sp.factor(A.charpoly(lam_s).as_expr())
assert sp.expand(cp - lam_s ** 2 * (lam_s + 1) *
               (lam_s ** 2 - lam_s - 1)) == 0
```

即

$$
\det(\lambda I-A)
=\lambda^2(\lambda+1)(\lambda^2-\lambda-1).
$$

模最大的特征值是 $\varphi>1$，长期人口按约 $\varphi$ 的倍率增长；若主特征值模小于 1，则相应方向长期衰减。不能把 $\varphi>1$ 误写成“灭绝条件”。

Julia 独立检查：

```julia
@assert maximum(abs.(eigvals(A))) ≈ φ
```

Leslie 矩阵与 Markov 矩阵都用矩阵幂研究长期行为，但一个追踪数量，一个追踪概率；解释矩阵元素前必须先看其归一化结构。

## 24.14 遍历均值：长期平均不等于 iid 平均

对有限不可约非周期链，不仅分布收敛，还有遍历定理：若 $E_\pi|f(X)|<\infty$，则

$$
\boxed{
\frac1n\sum_{k=0}^{n-1}f(X_k)
\longrightarrow E_\pi[f(X)]
\quad\text{几乎必然}.
}
$$

这看起来像大数定律，但 $f(X_k)$ 通常不独立。因此误差方差不能只算 $\operatorname{Var}_\pi(f)/n$，还必须加协方差项：

$$
\operatorname{Var}\left(\sum_{k=0}^{n-1}f(X_k)\right)
=
\sum_{i,j}\operatorname{Cov}(f(X_i),f(X_j)).
$$

对两状态平稳链，取 $f(x)=\mathbf1\{x=0\}$。其平稳方差为

$$
\gamma_0=\pi_0\pi_1=\frac6{25}.
$$

指数记忆给出

$$
\operatorname{Cov}(f(X_0),f(X_k))=\gamma_0\lambda^{|k|},
$$

所以

$$
\lim_{n\to\infty}n\operatorname{Var}(\bar f_n)
=\gamma_0\left(1+2\sum_{k=1}^\infty\lambda^k\right)
=\gamma_0\frac{1+\lambda}{1-\lambda}.
$$

本例 $\lambda=1/2$，故

$$
\boxed{
\sigma_{\mathrm{MC}}^2=\frac{18}{25}
=3\cdot\frac6{25}.
}
$$

正相关使渐近方差是 iid 情形的三倍。Python 对有限 $n=400$ 的双重协方差和做精确计算：

```python
var_sn = sum(g0 * lam ** abs(i - j)
             for i in range(n) for j in range(n))
assert abs(var_sn / n - sig2) < F(1, 100)
```

Julia 另外用种子 2411 模拟 2000 条长度 2000 的路径，检查

$$
n\operatorname{Var}(\bar f_n)\approx0.72,
$$

而不是 iid 的 0.24。模拟用于审计公式，不用于证明遍历定理。

## 24.15 与后续极限定理的边界

Markov 链的长期问题至少有三层：

1. **分布层**：$\mu^{(n)}=\mu^{(0)}P^n$ 是否收敛到 $\pi$；
2. **路径层**：时间平均 $n^{-1}\sum f(X_k)$ 是否几乎必然收敛；
3. **波动层**：中心化并缩放后的误差是否有非退化极限及其渐近方差。

第 25、26 章主要讨论随机变量序列的收敛模式和 iid 大数定律；不能把这些定理未经修改地套到 Markov 链上。遍历链有自身的大数定律，且相关性会改变方差。中心极限型的 Markov 链结论也需要额外条件，不在本章冒充已证。

## 24.16 本章要点

1. Markov 性表示已知当前状态后，更早历史不改变下一步条件分布。
2. 行随机矩阵的第 $i$ 行是从状态 $i$ 出发的一步分布；分布左乘 $P$，值函数右乘 $P$。
3. $n$ 步转移是 $P^n$，Chapman–Kolmogorov 方程是矩阵乘法与条件化的结合。
4. 平稳分布满足 $\pi P=\pi$；存在平稳分布不蕴含从任意初态依分布收敛。
5. 两状态链的次特征值 $\lambda=1-a-b$ 决定几何收敛速率。
6. 闭通信类、常返性、周期和非周期性分别控制能否离开、是否返回和是否振荡。
7. 细致平衡比平稳更强；定向三圈链给出平稳而不可逆的反例。
8. 首达概率和期望首达时间通过一步线性方程求解。
9. 五连正面经状态扩张成为吸收 Markov 链，期望首达时间为 62。
10. Leslie 矩阵描述人口数量而非概率；主特征值模决定长期增长尺度。
11. 遍历均值考虑所有时间协方差，不能直接照搬 iid 方差公式。

*对应示例：`examples/lean/Probability/Ch24MarkovChains.lean`、`examples/julia/24_markov_chains.jl`、`examples/python/24_markov_chains.py`、`examples/prolog/24_markov_chains.pl`。*

---

上一章：[23 充分统计量与数据简化](23-sufficiency.md) · 下一章：[25 随机变量序列的收敛](25-convergence.md)
