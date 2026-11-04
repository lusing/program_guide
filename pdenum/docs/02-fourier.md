# 02 Fourier 变换与复矩阵

**对应书第 1 章 §3"Fourier 变换和复数矩阵"（式 (3.1)–(3.10)、
定理 3.1–3.3）。**

---

## 2.1 从 Fourier 级数到 Fourier 积分

第 05 章分析差分格式稳定性时，主角工具是 Fourier 变换。原书第 1 章
专门用一节把它和复矩阵知识备齐，本教程沿用同样的安排。

推导的思路是原书 (3.2)–(3.6) 的形式推导：设 u(x) 在 [−L, L] 上可展
开为 Fourier 级数

    u(x) = a₀/2 + Σₙ [aₙ cos(nπx/L) + bₙ sin(nπx/L)]，

把系数的积分公式代回去，得到系数与函数的双重积分表达；令 L → ∞，
第一项（a₀ 部分）趋于零，和式在极限下变成 [0, ∞) 上的积分，再以
cos θ = (e^{iθ} + e^{−iθ})/2 拆开合并，就得到 **Fourier 积分公式**

    u(x) = (1/π) ∫₀^∞ dμ ∫_{−∞}^{∞} u(ξ) cos(μ(ξ − x)) dξ.

把内层积分的余弦换成指数并整理，得到**变换对**（本教程统一采用
对称约定，与书 (3.7)–(3.8) 相差常数因子的摆放）：

    û(k) = (1/√(2π)) ∫_{−∞}^{∞} u(x) e^{−ikx} dx        （正变换）
    u(x) = (1/√(2π)) ∫_{−∞}^{∞} û(k) e^{+ikx} dk         （逆变换）

常数因子的约定各书不同，但**结构**是不变的：正变换剥掉空间振荡
的信息、逆变换把它装回去。

## 2.2 两条性质：Parseval 与导数法则

**Parseval 关系式**（书 (3.9)）：

    ∫ |u(x)|² dx = ∫ |û(k)|² dk.

意义：Fourier 变换在 L² 范数下**保持度量**（对称约定下是等距）。
这是把"差分格式的解不会能量爆炸"翻译成"每个波数的增长因子有界"
的桥梁——第 05 章稳定性判据的推导正反两次用到 Parseval。

**导数法则**（书 (3.10)，分部积分立得）：

    F[u'] = ik · û(k)，F[u^{(m)}] = (ik)^m · û(k).

意义：求导在变换侧是乘 ik——微分方程变成每个波数 k 上的**代数**
方程。整个"von Neumann 分析"就是把这句话用在差分方程上：把网格
函数按波型 e^{ijθ} 展开，差分算子对每个波型的作用退化为乘一个数
（增长因子）。

## 2.3 复矩阵三定理

书 §3.2 列出三条后面要用的复矩阵结论。设 A ∈ ℂ^{n×n}，Aᴴ 为共轭
转置：

- **酉矩阵** U：UᴴU = I（保范数的可逆阵）；
- **Hermite 矩阵** A：Aᴴ = A（实对称是其特例），特征值全实；
- **正规矩阵** A：AAᴴ = AᴴA（对角阵、Hermite 阵、酉阵都是）。

**定理 3.1**：对任意 A，‖A‖₂ ≥ ρ(A)（谱范数不小于谱半径；对正规
矩阵取等，因为 ‖A‖₂ = ‖AᴴA‖₂^{1/2} 的特征值恰是 |λᵢ|²）。

**定理 3.2**：Hermite 矩阵可酉对角化 UᴴAU = diag(λ₁,…,λₙ)，U 的
第 i 列是对应 λᵢ 的特征向量，且特征向量两两正交。

**定理 3.3**：A 是正规矩阵 ⟺ 存在酉矩阵 U 使 UᴴAU 为对角阵。即
"可酉对角化"正是正规性。

为什么这些矩阵事实属于 PDE 数值解的预备知识？两个直接去处：

1. **矩阵法稳定性分析**（第 06 章）：差分格式在有限区间初边值问题
   下是一个矩阵迭代 uⁿ⁺¹ = Guⁿ，稳定性 ⟺ G 的幂一致有界。若 G
   正规，‖Gⁿ‖ = ρ(G)ⁿ——谱半径直接决定一切（定理 3.1 的等号情形）。
2. **非正规的危险**：若 G 不正规，ρ(G) < 1 也可能‖Gⁿ‖先增后降
   （瞬态增长）。更极端地，Richardson 格式（第 15 章）的增长矩阵
   G = [[−8rs, 1],[1, 0]]（r 为网格比，s = sin²(θ/2)）特征值
   μ = −4rs ± √(16r²s² + 1)，其中一支的模**恒大于 1**——对任何
   r > 0 都不稳定。这是二阶精度却"无实用价值"的经典案例，第 05
   章例 3.4 用 Fourier 方法正式判它死刑。

## 2.4 机器验证

### Julia/Python：变换对、导数法则与 Parseval

数值上"对表" Fourier 变换用最著名的变换对——高斯函数是自身的
变换（宽度参数对偶）：

    u(x) = e^{−x²}  ⟷  û(k) = e^{−k²/4} / √2     （对称约定下）。

核对方式是把正变换的积分直接算出来（偶函数只剩余弦部分）：

```julia
L, n = 8.0, 4000
u(x) = exp(-x^2)
uhat(k) = exp(-k^2 / 4) / sqrt(2.0)   # 闭式：(1/√2π)·√π e^{-k²/4}
for k in (0.0, 0.5, 1.0, 2.0)
    re = simpson(x -> u(x) * cos(k * x), -L, L, n) / sqrt(2π)
    @assert abs(re - uhat(k)) < 1.0e-8
    im_ = simpson(x -> -u(x) * sin(k * x), -L, L, n) / sqrt(2π)
    @assert abs(im_) < 1.0e-12
end
```

k = 0, 0.5, 1, 2 四个波数上，数值变换与闭式相差 1e−8 以内（截断
在 ±8：e^{−64} ≈ 1e−28，无截断问题）；虚部在对称区间上积奇函数，
机器上恒为零。逆变换在 x₀ = 0.7 处还原 u(x₀)，同样到 1e−8——
注意被积函数 e^{−k²/4} 衰减**慢一倍**，截断必须放宽到 ±10 才达
到同一精度（这一处容差正是"容差写依据"纪律的小案例）。

导数法则 F[u′] = ik û(k) 的数值核对拆成实虚部两对积分：u′ =
−2x e^{−x²} 是奇函数，其变换纯虚：

```julia
for k in (0.3, 1.0, 2.5)
    lhs_re = simpson(x -> dup(x) * cos(k * x), -L, L, n) / sqrt(2π)   # 奇函数积分为 0
    lhs_im = simpson(x -> -dup(x) * sin(k * x), -L, L, n) / sqrt(2π)
    rhs_re = -k * (simpson(x -> -u(x) * sin(k * x), -L, L, n) / sqrt(2π))  # ik·(a+ib) = -kb + ika
    rhs_im = k * (simpson(x -> u(x) * cos(k * x), -L, L, n) / sqrt(2π))
    @assert abs(lhs_re) < 1.0e-12
    @assert abs(lhs_re - rhs_re) < 1.0e-8
    @assert abs(lhs_im - rhs_im) < 1.0e-8
end
```

Parseval 数值版：∫|u|² 与 ∫|û|² 都等于 √(π/2)（闭式 ∫e^{−2x²}dx
= √(π/2)；这里第一次手算时容易误写 √π/2——本教程作者就被机器断言
当场纠正，左右两侧数值相等但与错误闭式差 0.37，一眼识破）。

### Julia/Python：正规/非正规矩阵的分野

定理 3.1 的等号与严格不等号各给一个实例：

```julia
for (name, M) in (("rotation(unitary)", R_rot), ("symmetric(hermite)", S_sym))
    nrm = opnorm(M, 2)
    rho = maximum(abs, eigvals(M))
    @assert abs(nrm - rho) < 1.0e-12 "正规矩阵应满足 ‖A‖=ρ(A)（$name）"
end
nj = opnorm(A_jordan, 2)
rhoj = maximum(abs, eigvals(A_jordan))
@assert nj > rhoj + 0.5 "Jordan 块应严格 ‖A‖>ρ(A)"
```

旋转矩阵（酉）与实对称阵（Hermite）都精确满足 ‖A‖₂ = ρ(A)；而
Jordan 块 [[1,1],[0,1]] 非正规，‖A‖₂ = 1.6180…（恰是黄金比 φ）
而 ρ(A) = 1——**特征值全在单位圆内，谱范数却大于 1.5**。若把
迭代矩阵的非正规性当不存在，稳定判断就会翻车；Richardson 格式
的增长矩阵正是这一类。

最后是 Richardson 增长矩阵的"死刑宣判"扫描：

```julia
for r in (0.2, 0.5, 0.49), s in (0.1, 0.5, 1.0)
    G = [-8r * s 1.0; 1.0 0.0]
    mu = eigvals(G)
    @assert maximum(abs, mu) > 1.0 + 1.0e-12 "Richardson 增长矩阵恒有一支特征值超界"
end
println("Richardson growth matrix: max|eig| > 1 for every r,s (always unstable)")
```

对 r ∈ {0.2, 0.5, 0.49} × s ∈ {0.1, 0.5, 1} 的所有组合，特征值
−4rs ± √(16r²s²+1) 中取减号的一支模恒超过 1（例如 r = 0.5, s = 1
时两根为 0.236 与 −4.236）。"无条件不稳定"四个字从此有了可复算
的数值证据；第 05 章会给出 Fourier 方法的正式推导。

Hermite 矩阵的酉对角化（定理 3.2）用最经典的例子落实：S =
[[2,1],[1,2]] 取 Hadamard 阵 U = ½[[1,1],[1,−1]]，数值验证
UᴴSU = diag(3,1) 且 UᴴU = I，到 1e−14。

### Prolog：变换表与复矩阵分类引擎

Prolog 通道（`examples/prolog/02_fourier.pl`）把知识整理成规则。
变换对存为事实，数值核对用表达式树上的 Simpson 积分器：

```prolog
% u = exp(-x^2)  ⟺  uhat = exp(-k^2/4)/sqrt(2)
u_gauss(exp(neg(pow(x, 2)))).
uhat_gauss(mul(exp(neg(div(pow(k, 2), n(4)))), n(InvSqrt2))) :- InvSqrt2 is 1 / sqrt(2).

check_gauss_pair(K, Err) :-
    u_gauss(U),
    subst_k(mul(U, cos(mul(k, x))), K, Integrand),
    simpson_expr(Integrand, -8.0, 8.0, 2000, Integral),
    Factor is 1 / sqrt(2 * pi),
    uhat_gauss(Hat),
    subst_k(Hat, K, HatE), ev_at(HatE, _, HatV),
    Err is abs(Integral * Factor - HatV).
```

`subst_k` 把符号 k 换成具体数值后，被积函数成为单变量表达式树，
Simpson 积分器逐点求值（`ev_at`）。三个波数上的核对误差全部在
1e−15 量级——与 Julia 的闭式对账一致。

复矩阵分类引擎用 c(实部, 虚部) 表示复数，实现共轭转置与三个判定：

```prolog
% 共轭转置 A^H = (conj A)^T
ct([[c(Ar,Ai),c(Br,Bi)],[c(Cr,Ci),c(Dr,Di)]],
   [[c(Ar,NAi),c(Cr,NCi)],[c(Br,NBi),c(Dr,NDi)]]) :-
    NAi is -Ai, NBi is -Bi, NCi is -Ci, NDi is -Di.

hermite(M) :- ct(M, T), meq(M, T).
normal(M) :- ct(M, T), mm(M, T, P1), mm(T, M, P2), meq(P1, P2).
```

三个测试矩阵的判定结果与定理完全一致：实对称阵 hermite + normal；
旋转阵非 hermite 但 normal（酉阵都正规——定理 3.3 的正向实例）；
Jordan 块两者皆非。

Richardson 特征值存成闭式规则：

```prolog
richardson_mu(R, S, Mu1, Mu2) :-
    Disc is sqrt(16 * R * R * S * S + 1),
    Mu1 is -4 * R * S + Disc,
    Mu2 is -4 * R * S - Disc.
richardson_unstable(R, S) :-
    richardson_mu(R, S, M1, M2),
    ( abs(M1) > 1.0000001 ; abs(M2) > 1.0000001 ).
```

`forall/2` 扫过 r ∈ {0.1,…,0.6} 与 s ∈ {0.1,…,0.9} 的全部组合，
每组合都 `richardson_unstable`——Prolog 通道也画出了"无条件不稳
定"的完整句号。

## 2.5 要点回顾

1. Fourier 积分公式是级数在 L → ∞ 的极限；对称约定下正逆变换
   共享 1/√(2π) 因子。
2. 两条性质支撑第 05 章：Parseval（L² 等距）把稳定性翻译成增长
   因子有界；导数法则 F[u′] = ikû 把微分算子代数化。
3. 复矩阵三定理：‖A‖₂ ≥ ρ(A) 恒立，正规取等；Hermite 阵酉对角化
   且特征值全实；正规 ⟺ 可酉对角化。
4. 非正规矩阵可以有 ρ < 1 而 ‖·‖ > 1 的瞬态增长；Richardson 格式
   更极端——特征值一支恒出单位圆，二阶精度也无济于事。
5. 高斯变换对 e^{−x²} ⟷ e^{−k²/4}/√2 是全书数值 Fourier 的对表
   基准；Parseval 对高斯的右端是 √(π/2)（不是 √π/2）。

*本章示例：`examples/julia/02_fourier.jl`、`examples/python/
02_fourier.py`、`examples/prolog/02_fourier.pl`。*

---

上一章：[01 预备：典型方程、定解问题与适定性](01-prelim.md) · 下一章：[03 差分格式的构造](03-scheme-construction.md)
