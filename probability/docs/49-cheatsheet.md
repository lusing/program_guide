# 第 49 章 全书速查与定理地图

## 49.1 用法

这是 50 章的口袋版：公式、关系与坑账的总账。

三条检索路径：

1. **按问题找工具**：先查 49.9 的"假设 → 定理 → 结论 → 误用"总表，定位到需要的定理与前提；
2. **按主题取公式**：49.2–49.8 六张分表；
3. **翻车先翻坑账**：49.10 精选全书实测踩过的坑，每条都来自真实批次。

## 49.2 概率基础（第 1–2 篇）

**公理**：非负、可数可加、全集为 1；补律、容斥、Boole 上界与 Bonferroni 下界全部由三公理免费推出。

**条件与更新**：

$$P(A|B)=\frac{P(A\cap B)}{P(B)},\qquad \text{全概率 }P(B)=\textstyle\sum_iP(B|A_i)P(A_i),\qquad \text{Bayes }P(A|B)=\frac{P(B|A)P(A)}{P(B)}.$$

**独立性三重警示**：两两独立 ⇏ 相互独立；零协方差 ⇏ 独立（$Y=X^2$ 四点表）；独立 ⇏ 条件独立（共同原因与对撞）。

**计数**：排列 $n!$ 、组合 $\binom nk$ 、多项式 $\frac{n!}{a_1!\cdots a_k!}$ ；四种抽样（有序/无序 × 有放回/无放回）。恒等式三宝 $\binom nk=\binom n{n-k}$ 、$\sum_k\binom nk=2^n$ 、$k\binom nk=n\binom{n-1}{k-1}$ ；Vandermonde $\binom{m+n}k=\sum_j\binom mj\binom n{k-j}$ 。

## 49.3 分布族总表

| 分布 | pmf/pdf | 均值 | 方差 |
|---|---|---|---|
| Bernoulli(p) | $p^x(1-p)^{1-x}$ | $p$ | $p(1-p)$ |
| Binomial(n,p) | $\binom nkp^kq^{n-k}$ | $np$ | $npq$ |
| Geometric(p) | $pq^{n-1}$ | $1/p$ | $q/p^2$ |
| NegBinomial(r,p) | $\binom{k+r-1}kp^kq^r$ | $rp/q$ | $rp/q^2$ |
| Poisson(λ) | $\lambda^ke^{-\lambda}/k!$ | $\lambda$ | $\lambda$ |
| Uniform(a,b) | $\frac1{b-a}$ | $\frac{a+b}2$ | $\frac{(b-a)^2}{12}$ |
| Exponential(λ) | $\lambda e^{-\lambda x}$ | $1/\lambda$ | $1/\lambda^2$ ） |
| Γ(k, θ) | $x^{k-1}e^{-x/\theta}/(\Gamma(k)\theta^k)$ | $k\theta$ | $k\theta^2$ |
| N(μ, σ²) | $(2\pi\sigma^2)^{-1/2}e^{-(x-\mu)^2/2\sigma^2}$ | $\mu$ | $\sigma^2$ |
| χ²(ν) | $y^{\nu/2-1}e^{-y/2}/(2^{\nu/2}\Gamma(\nu/2))$ | $\nu$ | $2\nu$ |
| Cauchy | $\frac1{\pi(1+x^2)}$ | **不存在** | — |

**族谱**：Bin = n·Bern；Geom→NegBin；Bin $(n,p_n\to\lambda/n)$ →Pois；独立 Poisson 和封闭；Exp=Γ(1)；Γ$(\nu/2,2)=\chi^2(\nu)$ ；$Z^2\sim\chi^2(1)$ ；正态稳定；Cauchy 稳定但无矩。

**矩工具**：$E[aX+b]=a\mu+b$ （无条件）；$E[X+Y]=E[X]+E[Y]$ （**不需要独立**）；积期望与方差可加需要独立；Var $=E[X^2]-\mu^2$ 。

**不等式链**：Markov $P(X\ge a)\le E[X]/a$ ⟹ Chebyshev $P(|X-\mu|\ge k\sigma)\le1/k^2$ ⟹ 弱大数定律；Jensen 固定凹凸方向。

## 49.4 变换、生成函数与多元

**换元**：$Y=g(X)$ 单调可逆时 $f_Y(y)=f_X(h(y))|h'(y)|$ ；多支反函数逐段求和。

**卷积**：独立和 $f_{X+Y}=f_X*f_Y$ ；grouping 省一半（$(X_1+X_2)+(X_3+X_4)$ ）。

**生成函数三件套**：PGF/MGF/CF 把计数、矩、卷积统一成"系数读取与乘法"；MGF 可能不存在（Cauchy），CF 恒存在且 $\widehat{f*g}=\hat f\hat g$ 。正态 $e^{-t^2/2}$ 、Cauchy $e^{-|t|}$ 。

**多元**：联合→边际→条件三层；$E[Y|X]$ 是 $L^2$ 投影（塔性质、全方差公式）；协方差矩阵半正定；Cauchy–Schwarz $|\rho|\le1$ 。

**多元正态**：线性变换封闭、零协方差⇒独立、条件分布仍正态（Schur 补）；Cholesky 生成采样。

**抽样分布（正态样本）**：Helmert 正交变换给出 $\bar X\perp S^2$ 、$\frac{(n-1)S^2}{\sigma^2}\sim\chi^2(n-1)$ 、$T=\frac{\bar X-\mu}{S/\sqrt n}\sim t(n-1)$ 、$F=\frac{U_1/\nu_1}{U_2/\nu_2}$ （独立卡方之比）。t²=F(1,ν)。

## 49.5 收敛与极限（第 6–7 篇）

**四模式关系**：

$$L^p\Rightarrow a.s.\Rightarrow \xrightarrow{p}\Rightarrow \xrightarrow{d},$$

全部不可逆；反例账：$L^p$ 要求矩（Cauchy 出局）、a.s. 与 p 互不蕴含（滑行示性函数）、依分布最弱（只看分布函数）。

**大数定律**：Khinchin（iid 均值存在）弱律；Kolmogorov 强律；Monte Carlo 误差 $\sigma/\sqrt n$ 。

**中心极限定理**：iid 有限方差，$\frac{\bar X-\mu}{\sigma/\sqrt n}\Rightarrow N(0,1)$ （特征函数证明：标准化吃一阶项、Taylor 二阶、$(1+w/N)^N\to e^w$ ）；格点分布要连续性修正；Berry–Esseen 给有限 n 误差阶 $1/\sqrt n$ 。

**渐近工具**：$O_p/o_p$ 、连续映射、Slutsky（加减乘除拼接）、Delta 方法 $g(\hat\theta)\approx N(g(\theta),g'^2V/n)$ 。

**Stirling**：$n!\approx n^ne^{-n}\sqrt{2\pi n}$ （误差 $1+O(1/n)$ ）；$\binom{2n}n/4^n\approx(\pi n)^{-1/2}$ 。

**Markov 链**：转移矩阵、Chapman–Kolmogorov、平稳分布、细致平衡；收敛依赖不可约与非周期。

## 49.6 估计（第 8 篇）

| 对象 | 公式/结论 | 前提 |
|---|---|---|
| 风险 | $R(\theta,\hat\theta)=E[(\hat\theta-\theta)^2]$ =偏差²+方差 | 可积 |
| MLE | $\hat\theta=\arg\max\ell$ ；得分 $\bar s_n(\hat\theta)=0$ | 正则内点 |
| Fisher 信息 | $I(\theta)=E[s^2]=-E[\ell'']$ ；$I_n=nI$ | 可换序 |
| 矩/GMM | $\hat\theta_W=\arg\min\bar m'W\bar m$ ；线性闭式 $(G'WG)^{-1}G'W\bar a$ | 识别秩 |
| 最优权重 | $W=S^{-1}$ ，$\Omega_*=(G'S^{-1}G)^{-1}$ | $S$ 正定 |
| J 统计量 | $J=n\bar m'\widehat S^{-1}\bar m\to\chi^2_{q-p}$ | 过度识别 |
| Rao–Blackwell | 条件期望降方差保均值 | 充分统计量 |
| Lehmann–Scheffé | 完备充分 ⇒ UMVU 唯一 | 完备性 |
| Cramér–Rao | $\operatorname{Var}(T)\ge\psi'(\theta)^2/I_n$ ；等号⟺误差∝得分 | 正则+积分换序 |
| 渐近展开 | $\sqrt n(\hat\theta-\theta_*)\to N(0,A^{-1}JA^{-1})$ | 一致性+余项控制 |
| 正确模型化简 | $A=-I,J=I\Rightarrow V=I^{-1}$ | 信息等式 |
| 稳健推断 | sandwich 方差修不确定度，不修结构参数 | 误设仍一致于伪真值 |

**警示**：CR 不可达 ≠ 非 UMVU（正态 $S^2$ ）；MLE 边界/多峰破坏展开；GMM 弱识别时 $G'WG$ 病态。

## 49.7 检验（第 9 篇）

**Neyman–Pearson**：简单对简单，似然比检验最大功效；逐点不等式 $(\phi-\psi)(f_1-kf_0)\ge0$ 积分即证。单侧正态检验对全部右侧备择 UMP；双侧无 UMP（对称/无偏类内取 $|Z|>z_{\alpha/2}$ ）。

**三大渐近检验**（$H_0:g(\theta)=0$ ，$q$ 个约束）：

| 检验 | 统计量 | 用到的拟合 |
|---|---|---|
| Wald | $W=g(\hat\theta)'[\widehat G\widehat V\widehat G']^{-1}g(\hat\theta)$ | 仅无约束 |
| LM/score | $LM=n\bar s'(\tilde\theta)\widehat I^{-1}\bar s(\tilde\theta)$ | 仅受约束 |
| LR | $2n[\bar\ell(\hat\theta)-\bar\ell(\tilde\theta)]$ | 两者 |

原假设下均 $\to\chi^2_q$ ；有限样本数值不同（Bernoulli 例 5/6、4/5、0.805）；误设时朴素 LR 失校准。

**正态回归精确推断**：$T_j\sim t(n-k)$ ；$F=\frac{(R\hat\beta-r)'[R(X'X)^{-1}R']^{-1}(R\hat\beta-r)/q}{s^2}\sim F(q,n-k)$ ；$q=1$ 时 F=t²。

**对偶**：$\theta_0\in C_{1-\alpha}\iff$ 水平 $\alpha$ 不拒绝——同一个不等式两种读法。

**多重比较**：$m$ 次独立 5% 检验族错误率 $1-0.95^m$ （20 次达 0.6415）；Bonferroni $\alpha/m$ 由 Boole 不等式保证，无需独立。

**p 值纪律**：p = P(数据|H₀) 不是 P(H₀|数据)；不拒绝 ≠ 接受；统计显著 ≠ 实际显著。

## 49.8 回归（第 10 篇）

**矩阵恒等式**（$P=X(X'X)^{-1}X'$ 、$M=I-P$ ）：

$$\hat\beta=(X'X)^{-1}X'y,\quad \hat y=Py,\ e=My,\quad P+M=I,\ PM=0,\ P^2=P,$$

$$X'e=0,\quad \operatorname{tr}P=k,\ \operatorname{tr}M=n-k,\quad \|y\|^2=\|\hat y\|^2+\|e\|^2.$$

（全部纯代数，与随机假设无关。）

**统计性质分层**：

| 结论 | 需要假设 |
|---|---|
| 解唯一 | 线性 + 满秩 |
| $E(\hat\beta\mid X)=\beta$ | + 外生性 $E(\varepsilon\mid X)=0$ |
| $\operatorname{Var}(\hat\beta\mid X)=\sigma^2(X'X)^{-1}$ | + 球形扰动 |
| Gauss–Markov（BLUE） | 外生 + 球形 |
| 精确 t/F | + 正态 |

**拟合与选择**：TSS=ESS+RSS（含常数列）；$R^2=1-\mathrm{RSS}/\mathrm{TSS}$ ；嵌套加变量 $R^2$ 必不降；调整 $R^2$ 升 ⟺ $|t|>1$ ；AIC $=n\log(\mathrm{RSS}/n)+2k$ 、BIC $+k\log n$ 。

**$s^2$ 迹账**：$E(\varepsilon'M\varepsilon)=\sigma^2\operatorname{tr}(M)=\sigma^2(n-k)$ 。

**受约束**：$\tilde\beta=\hat\beta-(X'X)^{-1}R'[R(X'X)^{-1}R']^{-1}(R\hat\beta-r)$ ；$\mathrm{RSS}_R=\mathrm{RSS}_U+$ 约束离距二次型。

**误设**：遗漏偏误 $(X_1'X_1)^{-1}X_1'X_2\beta_2$ （方向=相关性×β₂ 符号）；无关相关变量方差膨胀（VIF $=1/(1-R_j^2)$ ）；正交变量两个方向都免费。

**GLS/Aitken**：$\hat\beta_{GLS}=(X'\Omega^{-1}X)^{-1}X'\Omega^{-1}y$ 、方差 $\sigma^2(X'\Omega^{-1}X)^{-1}$ 、变换后套 Gauss–Markov；WLS 是对角特例（**常数列也除以** $\sqrt{w_t}$ ）；Ω 未知走 FGLS 或稳健标准误。

## 49.9 假设 → 定理 → 结论 → 误用总表

| 模型/假设 | 关键定理 | 可用结论 | 常见误用 |
|---|---|---|---|
| iid + 均值存在 | Khinchin WLLN | $\bar X\to^p\mu$ | Cauchy 上用（无均值） |
| iid + 有限方差 | CLT | 标准化和 →正态 | 忽略格点/偏度残差 |
| 正则参数模型 | MLE 渐近正态 | $\sqrt n(\hat\theta-\theta)\to N(0,I^{-1})$ | 边界/多峰仍套用 |
| 矩条件识别 | GMM 一致+渐近正态 | 最优权重 $S^{-1}$ 、J 检验 | 弱识别当强识别用 |
| 完备充分统计量 | Lehmann–Scheffé | UMVU | 忽略完备性直接宣称唯一 |
| 简单假设对 | Neyman–Pearson | 似然比最大功效 | 复合备择宣称 UMP |
| 正则 + 约束 | Wald/LM/LR → χ²_q | 三大渐近检验 | 误设下沿用朴素 LR |
| 线性 + 外生 | OLS 无偏 | $E(\hat\beta\mid X)=\beta$ | 用 $X'e=0$ 当外生证据 |
| + 球形 | Gauss–Markov | BLUE、$\sigma^2(X'X)^{-1}$ | 异方差下方差公式照抄 |
| + 正态 | t/F 精确分布 | 有限样本推断 | 大样本才有近似当精确用 |
| Cov=σ²Ω 已知 | Aitken | GLS BLUE | Ω 估错仍称有效 |

## 49.10 坑账精选（全书实测）

**数学与统计**：

1. Bernoulli 尾概率要乘组合数与失败概率（$P(K{=}4)\ne\binom55$ ）；
2. F(1,ν) 临界值 = 双侧 t 分位平方（非单侧）；
3. GLS 加权和逐项手算两次滑数（$S_{wx},S_{wxy}$ ）被精确断言当场抓出；
4. MSE 必须围绕真值，`.var()` 悄悄扣掉偏差；
5. 期望线性性的等式在单样本里带 $\bar\varepsilon$ 噪声，容差按 $\sigma/\sqrt n$ ；
6. 均值可不存在（Cauchy、$E[1/X]$ ）——绝对可积是闸门；
7. 零协方差 ⇏ 独立（$Y=X^2$ ）；成对独立 ⇏ 相互独立；
8. 无常数项回归的 $R^2$ 可能出 $[0,1]$ ；
9. Poisson 伪似然方差是 $\operatorname{Var}(X)$ ，不再除以 $\lambda^2$ ；
10. 模拟 ≠ 证明：覆盖率表格只审计指定设计。

**机器与实现**：

11. 裸数字分式默认 ℕ，`(1/3)=0` 假绿——分数断言显式 `(x:ℚ)`；
12. Lean kernel `decide` 对 Rat 链式求和停滞——矩阵断言走 `native_decide`；
13. `*ᵥ` 结合力高于 `*`，正规方程必须写 `(Xᵀ*X)*ᵥβ̂`；
14. mathlib 4.33 `dotProduct` 移出 `Matrix` 命名空间、`Matrix.dotProduct_self_nonneg` 不存在；
15. Julia 顶层 for 循环赋值软作用域——循环封装为函数；
16. `MersenneTwister` 与 numpy 种子不同源，对账对象是理论值不是逐位一致；
17. numpy 按行求和广播要 `keepdims=True`；批量回归用行约定 $y'X(X'X)^{-1}$ ；
18. E2/E3 度量对照要偏斜残差（对称数据两度量重合）；
19. 联合显著/单个不显著演示用固定数据集（随机种子会翻车）；
20. 数值积分端点奇异（$y^{-1/2}$ ）须代换吸收或闭式配平。

## 49.11 五通道分工与验证状态

| 通道 | 角色 | 招牌件 |
|---|---|---|
| Lean 4.33 + mathlib4（钉版 `H:/Lang/lean4/mathlib4-4.33.1`） | 定理判决与代数锚 | `norm_num` 分数账、`native_decide` 矩阵断言、NP/CR/GM/对偶的形式化 |
| Isabelle2025-2 | 测度侧二证 | HOL-Probability 的 PMF 族、条件概率、FTC 机器件（MT02/03/09/12/27） |
| Julia | 频率与模拟 | 有理数矩阵、固定种子 MC、t 密度闭式积分 |
| Python（3.13，`-I`） | 精确计算 | `Fraction` 全程精确、SciPy 分布、向量化 MC |
| Prolog | 小宇宙穷举 | 有限样本空间全枚举终审 |

**收官验证状态**（2026-11-06 HU 轮后）：`build.ps1 -All` 全量 **169 单元 PASS、FAIL 0**
（Lean 45 / Julia 47 / Python 49 / Prolog 23 / Isabelle 5；新增 43–48 六章 × 四通道，
原 42 章通道分布 Lean 39 模块、Julia 41、Python 43、Prolog 17）；`check_docs.py --final`
0 errors；50 章文档全部 ≥200 行；HU 轮顺手清掉了上次重排漏网的 5 个孤儿文档。
迁移映射清理，无 `.migrating` 与旧 Isabelle 会话残留。工具链版本：
Lean 4.33.1（mathlib4 钉版 `H:/Lang/lean4/mathlib4-4.33.1`）、
Isabelle2025-2、Julia 1.13、Python 3.13（`-I`）、SWI-Prolog。

复现命令：

```powershell
pwsh -NoProfile -Command '& ./build.ps1 -All'
pwsh -NoProfile -Command '& ./build.ps1 -List'
G:\scoop\apps\python313\current\python.exe -I probability/tools/check_docs.py --root probability --final
```

## 49.12 全书结构地图

| 篇 | 章 | 主题 |
|---|---|---|
| 导言 | 00 | 经济随机系统与统计推断 |
| 一 | 01–07 | 概率模型与有限计数 |
| 二 | 08–11 | 一元随机变量与界限 |
| 三 | 12–16 | 分布族与独立和工具 |
| 四 | 17–21 | 多元随机变量与信息更新 |
| 五 | 22–23 | 抽样分布与统计信息 |
| 六 | 24–26 | 随机序列与大数定律 |
| 七 | 27–30 | 渐近定理与拼接工具 |
| 八 | 31–35 | 统计模型与估计 |
| 九 | 36–37 | 假设检验与置信推断 |
| 十 | 38–41 | 线性回归模型 |
| 十一 | 42 | 收官综合：合成案例与证明方法 |
| 十二 | 43–48 | 高等概率论专题（胡晓予）：Lindeberg、无穷可分、三级数、重对数律、离散鞅两讲 |
| 尾 | 49 | 全书速查 |

**方法论总纲**（全教程一以贯之）：精确公式 + 机器对拍 + 反例审计三方互审——标记 ≠ 算对，跑过 ≠ 理解；渐近结论带余项账，模拟结论带种子与容差，形式化锚定代数与逻辑内核。

---

上一章：[48 离散鞅 II：一致可积、停时与选样](48-martingale-convergence.md) · 全书完
