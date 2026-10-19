# 测度论：编程与自动证明教程

以严加安《测度论讲义》（第二版，科学出版社 2004）为纲的自包含中文测度论
教程，辅以袁德美/王学军《测度论基础与高等概率论》下册两章选讲。全部核心
内容在正文中讲清，不需要回看原书；每章开头给"对应严书 §x.y"定位锚。

## 结构

- `docs/00-intro.md … docs/50-cheatsheet.md` —— 教程正文（51 篇，讲解为主，
  每章 ≥200 行；所有要讲的代码都在正文中引用并解释）
- `examples/lean/` —— Lean 4 + mathlib4 主证明通道（单一 lake 工程）
- `examples/isabelle/` —— Isabelle2025-2 HOL-Analysis 二证通道（每章一会话）
- `examples/julia/`、`examples/python/` —— 数值实验通道
- `examples/prolog/` —— 有限模型/离散推理通道（SWI-Prolog；WSL gprolog 抽查）
- `build.ps1` —— 五通道 章×单元 矩阵对账
- `tools/ocr_yan.py` —— 原书扫描件 OCR 流水线（取材骨架用）
- `PLAN.md` —— 逐章通道分配表与批次进度（工作文档）

## 章表（51 篇）

| 批 | 章 | 主题 | 严书 |
|---|---|---|---|
| B0 | 00 | 导言：测度论地图与工具链 | — |
| B1 | 01-06 | 集类/单调类/测度/Carathéodory 扩张/LS 测度/逼近 | §1.1-1.6 |
| B2 | 07-09 | 可测映射/函数单调类/收敛方式 | §2.1-2.3 |
| B3 | 10-16 | 积分/极限定理/符号测度 RN/Lp/L∞对偶 ba/Daniell/Bochner | §3.1-3.7 |
| B4 | 17-22 | 乘积 σ-代数/Fubini/核/无穷乘积/Kolmogorov-Tulcea/投影极限 | §4.1-4.7 |
| B5 | 23-29 | 拓扑预备/Riesz/正则测度/C₀ 对偶/Lusin/乘积拓扑/波兰空间 | §5.1-5.7 |
| B6 | 30-34 | 欧氏收敛/弱收敛 Portmanteau/胎紧 Prohorov/度量化/淡收敛 | §6.1-6.5 |
| B7 | 35-40 | 独立 0-1 律/条件期望/正则条件概率/一致可积/essSup/解析集 | §7.1-7.6 |
| B8 | 41-43 | Doob 不等式/鞅收敛/离散局部鞅 | §8.1-8.3 |
| B9 | 44-47 | Bochner 定理/Minlos-Sazonov/Minlos/Hilbert 上 Gauss 测度 | §9.1-9.4 |
| B10 | 48-49-50 | 特征函数与 CLT/大数定律（袁书选讲）/收官 CHEATSheet | 袁下册 |

## 构建与验证

```powershell
pwsh -NoProfile -Command '& ./build.ps1 -All'        # 全量对账
pwsh -NoProfile -Command '& ./build.ps1 -Chapter 04' # 只验一章
pwsh -NoProfile -Command '& ./build.ps1 -Lang lean'  # 只验一通道
pwsh -NoProfile -Command '& ./build.ps1 -List'       # 列出验证单元
```

通道判定与工具链版本见 `build.ps1` 头注释。Lean 依赖本地钉版 mathlib
（`H:/Lang/lean4/mathlib4-4.33.1`）；Isabelle 经自带 Cygwin bash 调用。

## 纪律

1. 原书为扫描件，OCR 只作取材骨架；数学公式一律按领域知识重建。
2. 无机器基础设施的专题（ba 空间、随机 Daniell 积分、Choquet 容度、
   Minlos 定理、离散局部鞅、淡收敛）按"通道分工"处理：由数值/有限通道
   承载并在正文如实标注，不硬造形式化。
3. 数值实验一律钉随机种子；断言前先心算理论值。
4. 教程正文自包含：只读 docs 即可学会；examples 是可选的验证物。

## 收官对账

终态见 `docs/50-cheatsheet.md`（定理地图 + 两书对照 + 各通道速查 +
实测坑总账）。批次提交历史即进度日志。
