# 偏微分方程数值解法教程 · 构建计划

以 **陆金甫、关治《偏微分方程数值解法》第 3 版**（清华大学出版社，
2016，ISBN 978-7-302-45472-4，293 页 PDF，纯扫描零文字层）为纲的
中文教程。全书自包含：只读 docs 即可学习；每章开头给"对应书 §x.y"
定位锚（书页 = PDF 页 − 15），但不依赖原书。

## 五通道分工

- **Lean 4 + mathlib 4.33.1**（主证明）：增长因子恒等式（|G|≤1 ⟺ 稳定
  条件的代数内核）、三对角特征向量 Dv=λv、离散极值原理归纳证明、
  FEM 局部刚度矩阵有理数精确装配、截断误差对多项式的差商恒等式
- **Julia / Python(scipy)**（数值）：全部差分格式的实现与收敛阶测量、
  谱半径/特征值、FEM 装配、多重网格、边界元——双实现交叉验证
- **Prolog (SWI)**（符号规则引擎）：Taylor 截断误差主项引擎（复用 ode
  的微分内核）、von Neumann 增长因子求解器、CFL/格式知识库、FEM
  装配索引映射、方法选择树
- **Fortran (flang)**（经典数值内核）：Lax-Wendroff、波动方程、
  Crank-Nicolson、Saul'ev、ADI、五点 SOR、一维 FEM、多重网格

## 书 → 教程章映射（35 章）

| 教程章 | 标题 | 对应书 | 通道 |
|---|---|---|---|
| 00 | 导言：PDE 数值解全景 | 前言+1章§1 | jl py |
| 01 | 预备：典型方程、定解问题与适定性 | 1章§2 | jl py lean |
| 02 | Fourier 变换与复矩阵 | 1章§3 | jl py pl |
| 03 | 差分格式的构造 | 2章§1 | jl py pl lean |
| 04 | 相容性、收敛性、稳定性与 Lax 等价定理 | 2章§2 | jl py pl |
| 05 | von Neumann 稳定性分析 | 2章§3 | jl py pl lean |
| 06 | 其他稳定性方法：Hirt、矩阵法、能量不等式 | 2章§4 | jl py lean |
| 07 | 一阶常系数双曲：迎风、L-F、L-W | 3章§1.1–1.3 | jl py pl lean ft |
| 08 | CFL 条件、特征线与蛙跳 | 3章§1.4–1.7 | jl py pl lean |
| 09 | 一阶方程组与变系数双曲 | 3章§2–§3 | jl py |
| 10 | 二阶双曲：波动方程差分格式 | 3章§4 | jl py lean ft |
| 11 | 初边值问题与数值边界处理 | 3章§5 | jl py pl |
| 12 | 二维双曲与 ADI | 3章§6 | jl py |
| 13 | 守恒律与守恒型差分格式 | 3章§7 | jl py pl |
| 14 | 常系数扩散方程：显式、隐式与加权隐式 | 4章§1.1–1.2 | jl py pl lean ft |
| 15 | 三层格式与跳点格式 | 4章§1.3–1.5 | jl py lean |
| 16 | 初边值问题：边界处理、Saul'ev 与分组显式 | 4章§2 | jl py ft |
| 17 | 对流扩散方程的差分格式 | 4章§3 | jl py pl lean |
| 18 | 变系数方程：Keller 盒式与有限体积法 | 4章§4 | jl py |
| 19 | 多维抛物：ADI、LOD 与预测-校正 | 4章§5 | jl py ft |
| 20 | 非线性抛物方程 | 4章§6 | jl py |
| 21 | 椭圆方程：五点、九点差分与极坐标 | 5章§1 | jl py pl lean ft |
| 22 | 极值原理：存在唯一性与收敛性 | 5章§2 | jl py pl lean |
| 23 | 边界处理、变系数、双调和与特征值 | 5章§3–§6 | jl py |
| 24 | 变分问题：从古典变分到必要条件 | 6章§1 | jl py lean |
| 25 | 两点边值问题的变分形式 | 6章§2 | jl py |
| 26 | 高维变分问题 | 6章§3 | jl py |
| 27 | Ritz、Galerkin 与权余量方法 | 6章§4–§5 | jl py pl lean |
| 28 | 一维有限元：线性元 | 7章§1 | jl py pl lean ft |
| 29 | 二维三角形线性元 | 7章§2 | jl py lean |
| 30 | 高次插值与等参元 | 7章§3 | jl py pl |
| 31 | 基于变分原理的差分格式与抛物有限元 | 8章§1–§2 | jl py |
| 32 | 特征值问题、变分不等方程 | 8章§3–§4 | jl py pl lean |
| 33 | 边界元与多重网格 | 8章§5–§6 | jl py ft |
| 34 | 总结：方法选择地图 | 全书 | jl py pl |

目标 ~112 单元（jl 35 / py 35 / pl 17 / lean 17 / ft 8）。

## 批次计划

- **B0** 基建 + 导论篇（00–02）：build.ps1、lean 工程、OCR 流水线
- **B1** 差分基础篇（03–06）
- **B2** 双曲篇（07–13）
- **B3** 抛物篇（14–20）
- **B4** 椭圆篇（21–23）
- **B5** 变分篇（24–27）
- **B6** 有限元篇（28–30）
- **B7** 收官篇（31–34）+ 全书总账

每批协议：写 docs → 写 examples → `pwsh ./build.ps1 -All` 全绿 →
git commit（提交信息带坑账）→ 更新 README 计数。

## 取材协议

- 书为纯扫描件：rapidocr（onnxruntime）流水线见 `tools/ocr_li.py`；
  **坑：本机 onnxruntime(CPU) 与 onnxruntime-gpu 双装冲突——GPU EP 报
  bad allocation、CPU EP 报找不到 cudnn DLL。解法：cudnn 路径
  （G:\cudnn\9.24\bin\12.9\x64）加进 PATH 让 DLL 能加载，同时构造
  RapidOCR 时传 det/cls/rec_use_cuda=False 强制走 CPU provider；且
  updater 有 KeyError 坑，须显式传 det_model_path=None 等。**
- OCR 产出仅作取材骨架（结构/编号/表格）；数学公式一律按领域知识
  重建，不抄 OCR（扫描数学 OCR 不可信纪律）。
- 页偏移：书页 = PDF 页 − 15。书页锚：ch1 p1 / ch2 p13 / ch3 p45 /
  ch4 p89 / ch5 p138 / ch6 p155 / ch7 p185 / ch8 p230 / 索引 p275。

## 坑账（滚动记录）

- mathlib 4.33.1（同 ode 前科）：HasDerivAt 点记号全部失效，须写全名
  `HasDerivAt.div_const` 等；Calculus 在 `Mathlib.Analysis.Calculus.*`。
- SWI-Prolog：首行 `:- encoding(utf8).` + 运行期输出纯 ASCII；整数/
  浮点不统一；递归谓词参数先 is 再递归；循环累积累积漏乘步长 H 两次前科。
- Python：-I 模式下 PYTHONIOENCODING 不生效 → 文件输出纯 ASCII。
- flang 链接须补 clang_rt.builtins-x86_64.lib（build.ps1 已处理）。
- Julia：SpecialFunctions 装不上（IntelOpenMP_jll 前科）→ 需要特殊
  函数时自实现级数。
