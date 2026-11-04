# 常微分方程教程 · 构建计划

底本：Henner, Nepomnyashchy, Belozerova, Khenner,
*Ordinary Differential Equations: Analytical Methods and Applications*,
Springer 2023（609 页 PDF，原生文本层，免 OCR）。

## 目标

- 中文教程 `ode/docs/00-32` 共 33 章，全书核心自包含：只读 docs 即可学会，
  每章开头给"对应书 §x.y"定位锚，但不依赖原书。
- 五通道机器验证：
  - **lean**：单 lake 工程（mathlib 4.33.1 钉版 H:/Lang/lean4/mathlib4-4.33.1，
    toolchain v4.33.1），`Ode/ChNN*.lean` 逐章，`lake build` 无 error/warning。
  - **julia**：`examples/julia/NN_*.jl`，`julia --startup-file=no`，
    stdout 含 `==== NN` 与 `END ====` 标记。
  - **python**：`examples/python/NN_*.py`，python313（scoop current 3.15 的
    numpy 坏——沿用 measuretheory 前科），`python -I`，utf-8。
  - **prolog**：`examples/prolog/NN_*.pl`，SWI `swipl -q -f 文件 -g main -t halt`。
  - **fortran**：`examples/fortran/NN_*.f90`，LLVM flang + compiler-rt builtins
    链接补丁（沿用 fortran/ 教程前科），运行产物判标记。
- 每章 docs ≥ 200 行、文字多于代码；正文引用全部代码并讲解。

## 章节地图（书 § → 教程章）

| 书 | 教程 | 主题 |
|---|---|---|
| ch1 | 00 | 导言：ODE 基本概念、解、IVP、建模实例 |
| 2.1 | 01 | 存在唯一性：Picard–Lindelöf、Picard 迭代、√\|y\| 反例 |
| 2.2 | 02 | 方向场、积分曲线、等斜线；Euler 方法 |
| 2.3 | 03 | 可分离方程、正交轨线 |
| 2.4 | 04 | 一阶线性：参数变易、积分因子、Bernoulli |
| 2.5 | 05 | 恰当方程、积分因子寻找 |
| 2.6 | 06 | 未解出导数：正则/奇解、Lagrange、Clairaut |
| 2.7 | 07 | 自治方程相线、平衡点稳定性 |
| 2.8 | 08 | 一阶模型：冷却/衰变/人口/混合/电路 |
| 3.1–3.3 | 09 | 一般理论与降阶法 |
| 3.4 | 10 | 线性二阶理论：Wronskian、Abel、参数变易 |
| 3.5 | 11 | 常系数二阶：特征方程、待定系数、共振 |
| 3.6 | 12 | 周期系数：Hill、Mathieu、Floquet |
| 3.7–3.9 | 13 | 高阶线性、Euler 方程 |
| 3.10 | 14 | 振动：机械/RLC/浮体 |
| 4.1–4.3 | 15 | 方程组一般理论 |
| 4.4–4.5 | 16 | 常系数方程组：特征值法 |
| 4.6 | 17 | 矩阵指数 e^{At}、非齐次 |
| 4.7 | 18 | 方程组应用：带电粒子/磁矩/互感 |
| 5.1–5.2 | 19 | 相平面、奇点分类、迹–行列式图 |
| 5.3 | 20 | Lyapunov 稳定性、线性化、Lyapunov 函数 |
| 5.4.1–3 | 21 | 分岔：鞍结/跨临界/叉式/Hopf |
| 5.4.4 | 22 | 非线性振动：极限环、van der Pol |
| ch6 | 23 | 幂级数解法、Frobenius |
| ch7 | 24 | Laplace 变换 |
| ch8 | 25 | Fourier 级数、Gibbs、Parseval |
| ch9 | 26 | Sturm–Liouville、Green 函数 |
| 10.1–10.2 | 27 | Γ 函数、Bessel、Airy |
| 10.3–10.5 | 28 | Legendre、Hermite、椭圆积分 |
| ch11 | 29 | 积分方程：Fredholm/Volterra |
| ch12 | 30 | 变分法：Euler 方程、brachistochrone、Ritz |
| ch13 | 31 | 分离变量：热/波/Laplace 方程 |
| — | 32 | 总结：方法地图 |

## 批次

- B0：基建（build.ps1/lean 工程/README）+ 00–08（一阶方程篇）
- B1：09–14（二阶与高阶篇）
- B2：15–18（方程组篇）
- B3：19–22（定性理论篇）
- B4：23–25（级数与变换篇）
- B5：26–28（边值与特殊函数篇）
- B6：29–32（积分方程/变分/PDE/总结）

## 实测坑账（滚动记录）

1. GitHub 直连拉 lean 依赖被 reset（Connection was reset）——从
   measuretheory/.lake/packages robocopy 本地种子（370 MB，40 秒）。
2. mathlib 4.33.1 是模块系统重构版：Calculus 全家搬进 Analysis——
   导入是 `Mathlib.Analysis.Calculus.Deriv.Basic` 而非旧的
   `Mathlib.Analysis.Deriv.Basic`（ODE 三件套路径未变）。
3. HasDerivAt 在 4.33 被结构性还原为 HasFDerivAtFilter——**点记号
   全部失效**（`(h).pow`/`h.div_const` 会静默变成字段应用或垃圾），
   必须写全名 `HasDerivAt.div_const`。ContDiff 未还原，点记号可用。
4. 改名账：`abs_add`→`abs_add_le`；`contDiff_pow` 没了→
   `(contDiff_id.pow 2).of_le le_top`；`lipschitzOnWith_iff`→
   `lipschitzOnWith_iff_dist_le_mul`；`hasDerivAt_pow n x` 可用；
   ODE 存在性入口 `ContDiffAt.exists_forall_mem_closedBall_exists_
   eq_forall_mem_Ioo_hasDerivAt₀`、唯一性 `ODE_solution_unique_of_
   mem_Icc_right`（根命名空间）。
5. API 查询套路：写 probe.lean（带 import + exact?）跑
   `lake env lean probe.lean`，比 grep 源码快得多；用完即删。
6. SWI-Prolog 铁律：首行 `:- encoding(utf8).` + 输出纯 ASCII，
   否则 multibyte 报错连锁炸解析。
