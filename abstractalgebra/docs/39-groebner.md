# 39 格罗布纳基

**对应原书 §7.5 格罗布纳基小节（pp. 569-580）。**

---

## 39.1 让余式唯一的好基

第 38 章的病根：除法每次只顾"当前首项能不能被某个 LT(gᵢ) 整除"，
选谁、按什么次序，答案就不同。修复方案一锤定音：

> **定义** {g₁,…,g_m} 是理想 I = (g₁,…,g_m) 的**格罗布纳基**
>（按固定单项式序），若 I 的**首项理想**
> LT(I) = (LT(f) : f ∈ I) 恰由 LT(g₁),…,LT(g_m) 生成：
> (LT(I)) = (LT(g₁),…,LT(g_m))。

等价的操作判据（命题 7.62）：**每个 f ∈ I 的首项都被某个
LT(gᵢ) 整除**。于是除法走到 I 里的任何多项式时首项总能被消掉
——三个直接推论：

> **推论 7.63** f ∈ I ⟺ f mod G = 0（**成员判定完备**）。
> **推论 7.64** 余式与被除式的次序无关（**唯一性**）。

Buchberger 在博士论文中（导师 Grobner）证明了存在性与算法，
原书脚注特意记录了这段师承。

## 39.2 S-多项式与 Buchberger 判据

怎么检查一组基是不是 Grobner 基？唯一可能出问题的场景：两个
生成元的首项"合作"出一个更小的首项——探测它的工具是：

> **定义**（7.6 节）f、g 的 **S-多项式**
> S(f, g) = (L/LT(f))·f − (L/LT(g))·g，L = lcm(LT(f), LT(g))。
> 构造使 S 的首项**互相抵消**，暴露" lcm 处的隐藏首项"。

> **定理 7.67（Buchberger 判据）** {g₁,…,g_m} 是 Grobner 基
> ⟺ 对所有 i < j，S(gᵢ, gⱼ) mod G 的余式为零。

判据是**有限次检查**（C(m,2) 对），于是得到算法：

> **Buchberger 算法** 反复计算各对的 S-余式，非零者补入基，
> 直到全部对余式为零。终止性由理想首项的递增链 + Dickson 引理
>（第 36 章）保证——**这同时也是希尔伯特基定理的构造性证明**。

最小的完整例子（三通道一致）：{x²+1, xy−1} 不是 Grobner 基：
S = y(x²+1) − x(xy−1) = **x+y**，mod 原基余式非零（x、y 都
不再可约）。补入后 {x²+1, xy−1, x+y} 继续检验：S(xy−1, x+y) =
(xy−1) − y(x+y) = −(y²+1) 非零，再补；最终
{x²+1, xy−1, x+y, y²+1 型四元基} 全部 S-余式为零。

## 39.3 三个应用

**理想成员判定**（推论 7.63）：xy²−x ∈ (xy+1, y²−1)？
第 38 章看到直接除法余式 −x−y（假象）；对 Grobner 基除法余式
**0**——真成员。x 的余式非零——非成员。

**理想相等**：I = (x+y, x−y) 与 J = (x, y) 相等（ℚ 上）：
x = ½(x+y) + ½(x−y)、y = ½(x+y) − ½(x−y)——双向成员判定
（各生成元 mod 对方基余式为零）。

**消元与解方程组**：lex 序（x > y）的 Grobner 基对"变元分层"：
{x²+y²−1, x−y} 的基含纯 y 多项式 **2y²−1**（消去 x）——
三角形系统 y = ±1/√2、x = y。"用 lex-Grobner 基解多元方程组"
= 高斯消元的非线性升级版，这是符号计算软件（Mathematica、
Singular、sympy 的 `groebner`）的心脏。

## 39.4 机器验证一：Lean——证书式验证

**文件：`examples/lean/Abstractalgebra/Ch39Groebner.lean`**。
Grobner 基的算法性内容由计算通道承担，Lean 验证每一步的**恒等式
证书**（全部一行 `ring`）：S-多项式的消首
`y(x²+1) − x(xy−1) = x+y`；补基步 `S(xy−1, x+y) = −(y²+1)`；
成员证书 `xy²−x = x(y²−1)`（换序除法余式 0 的组合路径）；
理想相等 `x = ½(x+y)+½(x−y) ∧ y = ½(x+y)−½(x−y)`；
消元核心步 `2y²−1 = (x²+y²−1) − (x+y)(x−y)`。

## 39.5 机器验证二：Julia——Buchberger 全实现

**文件：`examples/julia/39_groebner.jl`**。S-多项式与判据：

```julia
function spoly(f, g, ord)
    lf, lg = leading_term(f, ord), leading_term(g, ord)
    L = [max(lf[2][i], lg[2][i]) for i in eachindex(lf[2])]
    padd(monom_mul(1 // lf[1], L .- lf[2], f),
         monom_mul(-(1 // lg[1]), L .- lg[2], g))
end
```

断言组：(1) S(x²+1, xy−1) = x+y、余式非零 ⟹ 非基；
(2) `buchberger` 补至四元基、`is_groebner` 判据复核全过；
(3) 成员判定 xy²−x ∈（余式 0）与 x ∉；(4) 理想相等双向；
(5) 消元：基含 2y²−1。开发实录：S-多项式的符号先算错
（y(x²+1) − x(xy−1) 误写 y−x），机器残差当场抓出；理想相等的
第一版例子 (x+1,y+1) 与 (x²−1, …) 其实**不相等**（零点集不同），
成员判定的失败暴露后换成正确的 (x+y, x−y) = (x, y)。

## 39.6 机器验证三：Python 与 Prolog

**文件：`examples/python/39_groebner.py`**。与 Julia 同构的
自实现 `spoly`/`buchberger`，然后与 **sympy.groebner 全面对拍**：
四组理想，断言 sympy 的（既约）基首项集合 ⊆ 自算基首项集合
（同一首项理想的两组基），且每个 sympy 生成元 mod 自算基余式为
零——两条独立实现互相锁死。三个应用与 Julia 同值。

**文件：`examples/prolog/39_groebner.pl`**。整数系数版（例题
首项皆首一；S-多项式用**交叉乘** lc(g)·f − lc(f)·g 保持整性，
与标准定义差一个单位倍，余式归零性等价）；`normalize_sign` 把
补入的余式按首项符号归一（交叉乘带出的负号会污染基的形态）；
`buch_loop` 补基到判据全过，三个应用（成员 −xy²−x ✓/x ✗、
消元 2y²−1）与 Julia/Python 三通道同值。

## 39.7 要点回顾

1. Grobner 基 = 首项理想由基首项生成的基（命题 7.62 的操作形：
   每个 f ∈ I 的首项被某 LT(gᵢ) 整除）。
2. S-多项式探测"合作隐藏首项"；Buchberger 判据（定理 7.67）
   把无穷检查缩成 C(m,2) 对；算法终止性 = Dickson/希尔伯特基
   的构造性证明。
3. 推论 7.63/7.64：余式唯一、成员判定完备——第 38 章的病全愈。
4. lex-Grobner 基给出消元三角形：解方程组 = 高斯消元的非线性
   推广；理想相等 = 双向成员判定。
5. 全书于此收束：群（作用与对称）→ 环（理想与商）→ 域（扩张
   与不可解性）→ 计算代数（序、除法、基）——抽象结构与算法
   在 Grobner 基处会师。

*对应示例：`examples/lean/Abstractalgebra/Ch39Groebner.lean`、
`examples/julia/39_groebner.jl`、`examples/python/39_groebner.py`、
`examples/prolog/39_groebner.pl`。*

---

上一章：[38 广义的除法算式](38-division.md) · 下一章：[40 总结：定理地图](40-finale.md)
