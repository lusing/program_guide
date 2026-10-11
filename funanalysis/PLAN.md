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
