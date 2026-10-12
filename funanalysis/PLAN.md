# 泛函分析教程 · 总体规划（PLAN）

以 John B. Conway《A Course in Functional Analysis》第二版（GTM 96）为纲的
中文教程，结合机器证明（Lean 4 + mathlib4 主证、Isabelle/HOL 第二证明通道）
与数值/离散计算（Julia、Python/scipy、Prolog）。全书 11 章 + 附录全覆盖，
星号节不砍、降级承载方式。

## 硬性写作纪律

1. **教程而非代码罗列**：所有要讲解的代码必须在 docs 正文中引用并逐段讲解，
   只读 docs 不看 examples 也能学会；每段代码前后必有文字。
2. **自包含提炼原书**：定理给完整证明或完整讲解，不指路"见原书某章"。
   Conway 的编号在文中仅作溯源注记（如 "Conway I.3.4"），不构成阅读依赖。
3. 每章 ≥200 行、文字多于代码。
4. 章末导航采用 Zig 式（与 mathlogic 一致）。

## 通道分工与判定

| 通道 | 工具 | 角色 | 判定 |
|---|---|---|---|
| lean | Lean 4.33.1 (lake) + mathlib4 v4.33.1（H:/Lang/lean4/mathlib4-4.33.1 发布版钉版路径依赖，缓存永不过期） | 主证明通道 | `lake build` 退出码 0、无 error/warning |
| isabelle | Isabelle2025-2（G:\xulun3\isabelle，Cygwin re-exec） | 第二证明通道（对拍 + Isar 叙事） | 每章一会话 `isabelle build`，退出码 0、无 Failed |
| julia | Julia 1.13 | 数值通道一 | run-all 断言全过、标记齐全 |
| python | Python 3.13 + scipy | 数值通道二 | 脚本断言全过 |
| prolog | SWI-Prolog（本机 G:\scoop\apps\swipl）+ WSL gprolog 抽查 | 有限维离散模型 | 退出码 0、END 标记、纯 ASCII 输出 |

mathlib 没有的内容（分布、无界算子 Stone 定理、Fredholm 指标、重数理论等）
不在 Lean 强撑：改走数值/离散通道，并在文中明说"为什么机器还证不了"。

## 取材协议

原书为 421 页扫描版（无文本层）。每章：pdf2image 300 dpi 渲染 → RapidOCR
（onnxruntime + G:\cudnn\9.24 DLL）→ OCR 仅作结构骨架（定理编号/表述/习题
素材/Conway 特有组织），公式由领域知识重建校订——扫描数学 OCR 不可信。

## 章表（48 章 + CHEATSheet；Conway 原书节号溯源）

| 章 | 标题 | 原书 | lean | isa | julia/py | prolog |
|---|---|---|---|---|---|---|
| **第〇篇 导引** |
| 00 | 泛函分析与机器证明：导引 | Preface | ✓ | ✓ | ✓ | ✓ |
| 01 | 预备知识：拓扑、网、Zorn 与 Baire 纲 | A + III.12 前置 | ✓ | ✓ | ✓ | |
| **第一篇 Hilbert 空间** |
| 02 | 内积空间初步 | I.1 | ✓ | ✓ | ✓ | |
| 03 | 正交性与投影定理 | I.2 | ✓ | ✓ | ✓ | ✓ |
| 04 | Riesz 表示定理 | I.3 | ✓ | ✓ | | |
| 05 | 标准正交集与基 | I.4 | ✓ | ✓ | ✓ | |
| 06 | 同构分类、圆周 Fourier 变换与直和 | I.5-6 | ✓ | | ✓ | |
| **第二篇 Hilbert 空间上的算子** |
| 07 | 有界算子与 B(H) | II.1 | ✓ | ✓ | ✓ | |
| 08 | 伴随算子 | II.2 | ✓ | ✓ | ✓ | |
| 09 | 投影、幂等与不变子空间 | II.3 | ✓ | ✓ | | ✓ |
| 10 | 紧算子 | II.4 | ✓ | | ✓ | |
| 11 | 紧自伴算子的对角化 | II.5 | ✓ | | ✓ | |
| 12 | 应用：Sturm-Liouville 系统 | II.6* | | | ✓ | |
| 13 | 紧正规算子：谱定理、泛函演算与单位等价 | II.7-8* | ✓ | | ✓ | |
| **第三篇 Banach 空间** |
| 14 | 赋范空间与 Banach 空间 | III.1-4 | ✓ | ✓ | ✓ | |
| 15 | 线性泛函与 Hahn-Banach 定理 | III.5-6 | ✓ | ✓ | | |
| 16 | 应用三讲：Banach 极限、Runge、序向量空间 | III.7-9* | | | ✓ | ✓ |
| 17 | 对偶理论：商、子空间、自反性与 L^p/C_0 对偶 | III.10-11 + B/C | ✓ | ✓ | | |
| 18 | 开映射、闭图像与补子空间 | III.12-13 | ✓ | ✓ | ✓ | |
| 19 | 一致有界原理 | III.14 | ✓ | ✓ | ✓ | |
| **第四篇 局部凸空间与弱拓扑** |
| 20 | 局部凸空间 | IV.1-2 | ✓ | | ✓ | |
| 21 | 几何 Hahn-Banach：分离定理 | IV.3 | ✓ | | | |
| 22 | 归纳极限与分布 | IV.4-5* | | | ✓ | |
| 23 | 弱拓扑、Alaoglu 与自反性再访 | V.1-5 | ✓ | ✓ | | |
| 24 | Stone-Čech 紧化 | V.6* | | ✓ | | |
| 25 | Krein-Milman 与 Stone-Weierstrass | V.7-8 | ✓ | ✓ | | |
| 26 | 不动点、Haar 测度与弱紧致性 | V.9-13* | | | ✓ | ✓ |
| **第五篇 Banach 空间上的算子** |
| 27 | 算子的伴随与 Banach-Stone 定理 | VI.1-2* | ✓ | | | |
| 28 | 紧算子、不变子空间与弱紧算子 | VI.3-5 | ✓ | | ✓ | |
| **第六篇 Banach 代数与谱理论** |
| 29 | Banach 代数：理想与商 | VII.1-2 | ✓ | | | |
| 30 | 谱与预解式 | VII.3,5,6 | ✓ | | ✓ | |
| 31 | Riesz 泛函演算 | VII.4 | ✓ | | ✓ | |
| 32 | 紧算子的谱理论 | VII.7 | ✓ | | ✓ | |
| 33 | 交换 Banach 代数与 Gelfand 理论 | VII.8-9* | ✓ | | ✓ | |
| **第七篇 C* 代数** |
| 34 | C* 代数与 Gelfand-Naimark 定理 | VIII.1-2 | ✓ | | | |
| 35 | 正元、理想、表示与 GNS 构造 | VIII.3-5* | ✓ | | ✓ | |
| **第八篇 正规算子的谱定理** |
| 36 | 谱测度与交换 C* 代数的表示 | IX.1 | ✓ | | | |
| 37 | 谱定理 | IX.2 | ✓ | | ✓ | |
| 38 | 星循环算子、应用与 B(H) 上的拓扑 | IX.3-6 | ✓ | | ✓ | |
| 39 | von Neumann 代数与泛函演算终章 | IX.7-8 | ✓ | | | |
| 40 | 不变子空间与重数理论 | IX.9-10 | | | ✓ | ✓ |
| **第九篇 无界算子** |
| 41 | 无界算子基础 | X.1 | ✓ | | | |
| 42 | 对称、自伴与 Cayley 变换 | X.2-3 | | | ✓ | |
| 43 | 无界谱定理与 Stone 定理 | X.4-5 | | | ✓ | |
| 44 | Fourier 变换与微分、矩问题 | X.6-7 | | | ✓ | |
| **第十篇 Fredholm 理论** |
| 45 | Fredholm 算子与指标 | XI.1-3 | | | ✓ | ✓ |
| 46 | 本质谱与谱的精细分析 | XI.4-6 | | | ✓ | |
| **收官** |
| 47 | CHEATSheet：全定理地图与通道速查 | — | | | | |

（✓ 为计划覆盖，实施时逐章核库微调；对拍 = Lean 与 Isabelle 证同一定理。）

## 批次计划（批批全绿即提交）

| 批 | 章 | 内容 |
|---|---|---|
| B1 | 00-04 | 导引、预备、内积、正交投影、Riesz |
| B2 | 05-09 | 正交基、Fourier/直和、B(H)、伴随、投影 |
| B3 | 10-13 | 紧算子四连 |
| B4 | 14-16 | Banach 基础、Hahn-Banach、应用三讲 |
| B5 | 17-19 | 对偶、开映射、一致有界 |
| B6 | 20-23 | 局部凸、几何 HB、分布、弱拓扑 |
| B7 | 24-26 | Stone-Čech、Krein-Milman/SW、不动点/Haar |
| B8 | 27-33 | Banach 算子 + Banach 代数 |
| B9 | 34-40 | C* 代数 + 谱定理 |
| B10 | 41-47 | 无界 + Fredholm + CHEATSheet |

## 工程布局

```
funanalysis/
  PLAN.md          本文件（章表×通道矩阵驱动 build.ps1 对账）
  README.md        入口
  build.ps1        全通道对账（-All/-Chapter NN/-Lang lean/-List/-Clean）
  docs/NN-slug.md  章正文（Zig 式导航）
  examples/
    lean/          单 lake 工程（lakefile + lean-toolchain + Funanalysis.lean 根）
    isabelle/      ROOT：每章一会话 FANN（父会话 HOL-Analysis 或 HOL）
    julia/         NN_xxx.jl + run-all.jl
    python/        NN_xxx.py
    prolog/        NN_xxx.pl（swipl 主 + gprolog 抽查）
  tools/           OCR 流水线等
  build/           产物（不入库）
```

## 里程碑记录

- 2026-10-11 立项：设计经用户确认（通道组合/全书覆盖/目录名）。
- 2026-10-11 B1（00-04 章）完成：docs×5、Isabelle 5/5、Julia 4/4、
  Python 4/4、Prolog 2/2（swipl）+gprolog 双文件抽查；mathlib 走本地
  克隆 + `lake exe cache get`（克隆被 pull 后缓存须重拉）；
  build.ps1 章表对账协议落地。
- 2026-10-11 B2（05-09 章）完成：docs×5、Lean 5/5（Ch05-09）、
  Isabelle FA05/07/08/09（09 的 ran=ker 与 obl 反例因 v4.33 numeral-type
  组件求值与 E x - E x = 0 simp 闭包障碍按通道分工原则裁撤，仅保留
  I-E 幂等；07 的 onorm 等号版同理裁撤，仅保留 ≤ 界与 bounded_linear）、
  Julia 9/9 全绿（FFTW 新依赖）、Python 9/9 全绿、Prolog 3/3。
- 2026-10-11 B3（10-13 章）完成：紧算子四连。docs×4、Lean 4/4
  （Ch10-13，IsCompactOperator/eq_zero_of_forall_hasEigenvalue_eq_zero/
  conj_eigenvalue_eq_self/orthogonalFamily_eigenspaces）、Julia/Python
  各4文件全绿（截断SVD误差=σ_{k+1}/Volterra 2π/Green函数/
  特征值1/(n²π²)/正规性/泛函演算/sqrtm/酉等别）。
- 2026-10-11 B4（14-16 章）完成：Banach 空间三连。docs×3、
  Lean 3/3（Ch14-16）、Julia/Python 各3文件全绿
  （Taylor收敛/商范数/Riesz高维/Banach极限Cesàro/Runge逼近1/z）。
- 2026-10-11 B5（17-19 章）完成：对偶+三大原理收官。docs×3、
  Lean 3/3（Ch17-19）、Julia/Python 各3文件全绿
  （对偶范数sup/Hölder/svd满射/min σ/逐点vs一致有界）。
  mathlib 核心API：banach_steinhaus + isOpenMap。
- 2026-10-11 B6（20-23 章）完成：局部凸+弱拓扑。docs×4、
  Lean 4/4（Ch20-23）、Julia/Python 各4文件全绿
  （半范数族分离/超平面分离/δ高斯逼近/弱收敛eₙ→0）。
- 2026-10-11 B7（24-26 章）完成：V.6-V.13 收官。docs×3、
  Lean 3/3（Ch24-26：StoneCech/KreinMilman/SW/extremePoints）、
  Julia/Python 各3文件全绿（极点凸组合/Brouwer迭代/Haar均匀）。
  同时修复 B3 遗留：Ch11 conj 改 starRingEnd、Ch12/13 重写简化。
  Isabelle 通道 v4.33 三大新坑入记忆：①type 2 坐标系是 {1,2} 而非
  {0,1}（axis_def 展开后 if-condition 求值需要 axis_def 而非 axis_nth
  单独使用）；②E x - E x = 0 在 also/finally 链中 simp 不闭（哪怕
  diff_self/right_minus_eq 显式添加）——线性函数差的自消需要
  函数级等式而非向量级；③onorm_le 前提序在 v4.33 变化，
  rule 直接用会报 refine 错，需用 onorm_bound 命题形式。
- 2026-10-11 B8（27-33 章）完成：Banach 算子 + Banach 代数。
  docs×7、Lean 7/7、Julia/Python 各7文件、Isabelle FA07-09。
- 2026-10-11 B9（34-40 章）完成：C* 代数 + 谱定理。
  docs×7、Lean 7/7、Julia/Python 各7文件。
- 2026-10-11 B9.5 质量债清偿（27-40 章）：B7 起遗留的
  14 章 24 行占位文档全部重写为 95-121 行正式教程；
  Julia/Python 各 10 个空壳实验全部充实为真实验
  （伴随保范/零化子/Banach-Stone 分类、Eckart-Young、Neumann
  级数、Gelfand 公式 k=200、预解式爆破、三法合一 exp(A)、
  Riesz 投影、三角谱不变性、Volterra 拟幂零、正元平方根、
  PVM 五公理、移位 WOT≠SOT、交换子核 = 双交换子、
  不变旗/约化/Jordan 重数）；Lean Ch35/36/38/39/40 空 Shell
  补 mathlib 锚点（IsPositive/orthogonalProjectionOnto/
  le_opNorm/comp_assoc/Submodule.map+eigenspace）。
  实测新坑：Julia 顶层 for 内对已声明全局的再赋值（含 &= / +=）
  一律按局部处理致假绿/报错，须 let 块或推导式收集；
  λ ∈ f 对函数 f 不合法（in 当集合处理），须直接调用 f(x)；
  eigvals 升序 vs 1./n 降序的对位比较要 reverse 参考向量；
  级数累加漏 k=0 项时误差恰为 √n（Frobenius 范数的指纹）；
  numpy np.exp 是逐元素、矩阵指数必须 scipy.linalg.expm；
  满秩矩阵的 null_space 为空数组，断言空转——需造亏秩矩阵
  才是真检验。
- 2026-10-11 B10（41-47 章）完成：全书收官。docs×7
  （41-46 教程 + 47 CHEATSheet 全定理地图/通道速查/坑总账）、
  Lean 1/1（Ch41：LinearPMap.adjoint + IsSymmetric）、
  Julia/Python 各5文件全绿（Cayley 酉性 + -d²/dx² 三自伴扩张
  三套谱、Stone 群律/酉性/强连续生成元界、无界对角算子域内
  域外判别 + √N 演算、Parseval/谱方法求导/Heisenberg Gaussian
  饱和 0.5/双峰 4.0/Hamburger 正反例、行列式引理/奇异秩一
  ker=coker=1/截断移位 vs 无穷维指标 -1/I+tK 谱锁 1、
  Weyl 列 1/√m vs 圆盘内 0.866 下界/谱坍缩 ≥20/30）。
  实测新坑：Julia $var 后紧跟全角标点被并入标识符（须 $(var)）；
  Julia fftfreq 第二参数是采样率而非间距（与 NumPy 相反），
  且网格须排除右端点否则误差 ~1/n；左移的点谱是开圆盘
  （几何向量为真特征向量），Weyl 列演示必须用右移（等距，
  ‖(S-λ)x‖ ≥ (1-|λ|)‖x‖）；Weyl 误差必须用相对误差
  （绝对残差对任何 λ 都 ~1/√m）；Python ** 右结合
  （w**(-1.5)**2 = w**2.25）；理论等值点上的严格不等号
  断言须留余量（0.75 倍）。
- 2026-10-12 L 轮（Lax 增补篇 48-63 章启动）：以 Peter D. Lax
  《Functional Analysis》(Wiley 2002, 598 页扫描版) 为第二底本，
  对现有 Conway 48 章做增补而非重写。差距分析结论：Lax 独有而
  Conway 不覆盖的标志性内容共 16 章新篇——
  L1（48-51）：Lax-Milgram+变分法/Dirichlet、Banach 极限+有限可加
  不变测度、Müntz/Runge 对偶逼近、弱收敛应用（Toeplitz 求和法/
  Fourier 发散/Galerkin/Herglotz-Riesz）；
  L2（52-56）：Riesz-Thorin 插值+Hilbert 变换+Hausdorff-Young、
  Wiener Tauberian、Fredholm 行列式+迹公式、Toeplitz/Hankel 算子
  绕数指标、迹类 Weyl/Lidskii/Mercer；
  L3（57-58）：Herglotz 表示/Cauchy 变换谱路线（深化 42 章）、
  Friedrichs 扩张+Rellich 扰动；
  L4（59-62）：Hille-Yosida 半群+Lax 等价定理+Trotter、von Neumann
  平均遍历+Koopman、Weyl 交换关系+一维散射、Beurling 定理+Hardy
  空间内外因子分解；
  L5（63）：Lax 篇 CHEATSheet + 两书路线总对照。
  取材：rapidocr（cudnn G:/cudnn/9.24/bin/12.9/x64 须入 PATH）
  OCR 扫描页，书页 N ↔ PDF 页 N+18。文档纪律同 Conway 篇：
  ≥200 行、文字多于代码、定理自包含。
