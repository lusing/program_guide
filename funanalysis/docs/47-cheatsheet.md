# 47 · CHEATSheet：全定理地图与通道速查

> 一页看懂全书骨架：十篇主线、定理谱系、五通道分工。

## 47.1 全书结构地图（Conway 对应）

| 篇 | 章 | 主线 | Conway |
|---|---|---|---|
| 一 预备 | 00-01 | 集论/拓扑/线性基础 | 预备章 |
| 二 Hilbert 空间 | 02-09 | 内积→正交→Riesz→基→B(H)→伴随→投影 | I |
| 三 算子谱论初阶 | 10-13 | 紧算子四连（对角化/S-L/紧正规） | II |
| 四 Banach 空间 | 14-19 | 完备性→HB→对偶→开映射→一致有界 | III |
| 五 局部凸与弱拓扑 | 20-26 | 局部凸→分离→分布→弱拓扑→Stone-Čech→KM/SW→不动点 | IV-V |
| 六 Banach 算子 | 27-28 | 伴随/Banach-Stone→紧算子/Lomonosov | VI |
| 七 Banach 代数 | 29-33 | 代数→谱→泛函演算→紧谱→Gelfand | VII |
| 八 C* 代数 | 34-35 | C* 公理→GN→正元→GNS | VIII |
| 九 谱定理 | 36-40 | PVM→谱定理→拓扑→vN 代数→重数 | IX |
| 十 无界与 Fredholm | 41-46 | 无界→对称/自伴→Stone→Fourier→指标→本质谱 | X-XI |

## 47.2 定理谱系速查

**支柱定理**（全书反复使用的承重墙）：
- Hahn-Banach（15）：延拓/分离/达范——一切对偶论证之源
- 开映射/闭图像（18）：满射开、图像闭 ⟹ 有界
- 一致有界（19）：逐点有界 ⟹ 一致有界
- Alaoglu（23）：对偶球弱*紧——弱拓扑存在的理由
- 谱定理（37/43）：正规/自伴 = 乘法算子

** Hilbert 空间链**：Riesz（04）→ 正交分解（03）→
Bessel/Parseval（05）→ 投影定理（09）→ 紧正规对角化（13）。

**Banach 代数链**：Neumann 级数（29）→ 谱非空紧（30）→
Gelfand 公式（30）→ Riesz 演算（31）→ 谱几何化（33）→
C* 恒等式（34）→ GNS（35）→ PVM（36）→ 谱定理（37）→
双交换子（39）→ 重数分类（40）。

**无界链**：闭图像（41）→ 亏指数（42）→ Cayley（42）→
Stone（43）→ Fourier=酉（44）→ 不确定性（44）。

**指标链**：Fredholm 二择一（32/45）→ Atkinson（45）→
指标同伦不变（45）→ Weyl 定理（46）→ 本质谱（46）。

**大定理一览**：
| 定理 | 内容 | 章 |
|---|---|---|
| Banach-Stone | C(K) 等距 ⟺ 空间同胚 | 27 |
| Gelfand-Naimark | 交换 C* ≅ C(Δ)；一般 C* ⊆ B(H) | 34/35 |
| Krein-Milman | 紧凸集 = 极点闭包 | 25 |
| Stone-Weierstrass | 自伴分离点子代数稠密 | 25 |
| Stone 定理 | 酉群 ⟺ 自伴生成元 | 43 |
| Atiyah-Singer（入口） | 指标 = 拓扑不变量 | 45 |
| Heisenberg | σx·σξ ≥ 1/2 | 44 |
| Lomonosov | 交换紧算子 ⟹ 不变子空间 | 28 |

## 47.3 五通道分工总表

| 通道 | 强项 | 本书承担 | 代表锚点 |
|---|---|---|---|
| **Lean 4 + mathlib** | 定理的完全形式化 | 34/47 章锚点（谱/伴随/紧算子/C* 恒等式/三大原理/PVM 构件/无界伴随） | `banach_steinhaus` `isOpenMap` `IsCompactOperator` `norm_adjoint_comp_self` `LinearPMap.adjoint` |
| **Isabelle/HOL** | 分析证明的交互检查 | 00-09 会话（FA00-FA09） | onorm/内积/投影 |
| **Julia** | 数值实验主通道 | 44 个实验：谱/逼近/群/指标全谱系 | opnorm/eigen/svd/FFTW |
| **Python/scipy** | 数值交叉验证 | 与 Julia 逐章对拍 | null_space/expm/eigh |
| **Prolog** | 离散模型 | 00/03/09（正交/投影的有限格点模型） | swipl + gprolog 双引擎 |

**通道分工原则**：某通道遇到系统性障碍（如 mathlib 无
vN 代数基础设施、Isabelle simp 闭包困难）时，内容由
其余通道承载，文档如实标注——不硬凑。

## 47.4 数值实验清单（按主题）

- **范数与对偶**：对偶范数 sup（17）、Hölder（17）、
  伴随保范 ‖A‖₁=‖Aᵀ‖∞（27）
- **谱论**：谱半径 vs 范数（30）、Gelfand 收敛表（29）、
  预解式爆破（29）、三法 exp(A)（31）、Riesz 投影（31）
- **紧性**：奇异值衰减 + Eckart-Young（28）、
  Volterra 拟幂零（32）、三角谱不变性（32）
- **C* 与谱定理**：C* 恒等式（34）、正元平方根（35）、
  PVM 五公理 + 谱积分（36）、谱分解重构（37）
- **拓扑与代数**：WOT≠SOT（38）、交换子=双交换子（39）、
  不变旗/约化/Jordan 重数（40）
- **无界**：Cayley 酉性 + 三扩张谱（42）、Stone 群律（43）、
  谱方法求导 + Heisenberg 饱和 + Hankel（44）
- **指标**：行列式引理 + 指标 0 vs 移位 -1（45）、
  Weyl 列 + 谱坍缩（46）

## 47.5 实测坑总账（跨批次精华）

**Julia**：
- 顶层 `for` 内对已声明全局再赋值（`+=`/`&=`）按局部处理，
  造成假绿或 UndefVarError——用 `let` 块或推导式收集
- `$var` 插值后紧跟全角标点（`，`）被并入标识符——
  一律写 `$(var)`
- `norm(A, 2)` 是 Frobenius——算子范数必须 `opnorm`
- `factorial(::Float64)` 不存在；Int 版 21 起溢出——
  级数用增量 `term = term * A / k`
- `fftfreq(n, d)` 的 d 是**采样率**（与 NumPy 的间距相反）
- `λ ∈ f` 对函数按集合处理报 iterate——直接调用 `f(λ)`
- `eigvals` 升序返回：与降序参考对位须 `reverse`

**Python**：
- `np.exp` 逐元素；矩阵指数必须 `scipy.linalg.expm`
- `**` 右结合：`w ** (-1.5) ** 2` = `w ** 2.25`——括号纪律
- 控制台 GBK：io.TextIOWrapper 包裹 + PYTHONIOENCODING

**数学建模**：
- 满秩矩阵 null_space 返回空数组——断言空转；
  零化子实验必须造亏秩矩阵
- 左移 vs 右移：几何向量是左移的特征向量（点谱=开圆盘），
  Weyl 列演示必须用右移（等距）
- 有限维指标恒 0（rank-nullity）：移位的 -1 是纯无穷维现象，
  数值只能证"截断保持 0"+ 解析对照
- 严格不等号断言在理论等值点（如 1/√m 恰减半）会翻车——
  用 0.75 倍余量

**Lean/mathlib v4.33**：
- 模块搬家：`NormedSpace/Banach`→`Normed/Module/…`、
  `NormedAlgebra/Spectrum`→`Complex/Spectrum`
- `conj` 对 ℝ/ℂ 失效 → `starRingEnd ℂ`
- `onorm_le` 前提序变化 → 用 `onorm_bound` 命题形式

**Isabelle 2025-2**：type 2 坐标 {1,2}、also/finally 链的
simp 自消失败、SQLite 会话库损坏处理（详见记忆文件）。

## 47.6 构建与验证协议

```powershell
pwsh -NoProfile -Command '& ./build.ps1 -All'        # 全量
pwsh -NoProfile -Command '& ./build.ps1 -Chapter 37' # 单章
pwsh -NoProfile -Command '& ./build.ps1 -Lang lean'  # 单通道
pwsh -NoProfile -Command '& ./build.ps1 -List'       # 章×通道矩阵
```

判定：退出码 0 + 输出标记（`==== NN` / `END ====`）+
Lean 无 error:/warning:。每批次结束跑受影响章的对账，
收官跑 -All 全量。

## 47.7 延伸阅读路线

- **深化 C*/vN**：Takesaki《Theory of Operator Algebras》
- **指标理论**：Atiyah 的 Edinburgh 讲义；
  Hörmander 的椭圆算子分析
- **谱定理的几何**：von Neumann 的连续几何；
  Connes 非交换几何
- **形式化前沿**：mathlib 的 `Analysis.Fourier.*` 与
  无界算子建设线（`LinearPMap` 系列）

---

上一章：[46 本质谱](docs/46-essential-spectrum.md) · [返回目录](../README.md)
