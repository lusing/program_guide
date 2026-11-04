# 抽象代数：编程与自动证明教程

以 Joseph J. Rotman *A First Course in Abstract Algebra*, 3rd ed.
（Prentice Hall；中译本《抽象代数基础教程（原书第3版）》，李样明、冯明军
译，机械工业出版社 2008）为纲的自包含中文教程。目标：**只读 docs 就能
学会**——讲解为主、代码为辅，每一段示例代码都在正文中引用并解释，读者
不必翻看原书；引用原书时使用英文版编号与页码。

## 结构

- `docs/00-41.md` —— 42 章正文（七篇：数论 / 群 I / 交换环 I / 线性代数 / 域 /
  群 II / 交换环 II），每章末有要点回顾与上下章导航。
- `examples/lean/` —— Lean 4 + mathlib（钉版 4.33.1）证明通道，每章一个
  `Abstractalgebra/ChNN*.lean`。
- `examples/isabelle/` —— Isabelle2025-2 选配通道（HOL-Algebra 擅长的章）。
- `examples/julia/` —— Julia 计算通道（`NN_*.jl`）。
- `examples/python/` —— Python + sympy 计算通道（`NN_*.py`）。
- `examples/prolog/` —— SWI-Prolog 逻辑/枚举通道（`NN_*.pl`）。
- `tools/` —— 原书扫描件 OCR 取材流水线（rapidocr）。
- `build.ps1` —— 五通道验证脚本。

## 验证

```powershell
pwsh -NoProfile -Command '& ./build.ps1 -All'        # 全量验证
pwsh -NoProfile -Command '& ./build.ps1 -Chapter 03' # 单章
pwsh -NoProfile -Command '& ./build.ps1 -Lang lean'  # 单通道
pwsh -NoProfile -Command '& ./build.ps1 -List'       # 章×通道矩阵
```

判定标准：lean 整工程 `lake build` 无 error/warning；isabelle 会话构建通过；
julia/python 要求 stdout 含 `==== NN` 与 `END ====` 标记且退出码 0；prolog 要求
`END ====` 且退出码 0。

## 约定

- 数学内容自包含：正文给出完整定义、定理与证明思路，不要求读者回看原书。
- 原书编号以「原书 §x.y / 命题 x.z」形式标注（**英文 3 版**编号与页码），
  便于对照；中译本补录条目明确标注。
- 机器验证的定理，正文注明对应示例文件与定理名。

## 状态（2026-11-04 更新轮收官）

初稿 41 章（B0-B8，以中译本为纲）+ **U 轮英文原版对账扩充**：
42 章（00-41）正文全部完成；五通道验证 **159/159 全绿**（lean 整
工程 + julia 40 + python 40 + prolog 40）。U 轮变更：全书编号/页码
迁移至英文版（U1）；新增第 27 章「行列式」（U2，原 27-40 重编号为
28-41）；第 19 章补欧几里得环/ℤ[i]/费马二平方和（U3）；第 30 章
补韦达三角解、第 31 章补 Epilog 伽罗瓦对应与高斯作图定理（U4）。
章节结构：数论 01-06 · 群 I 07-14 · 交换环 I 15-23 · 线性代数
24-29 · 域 30-31 · 群 II 32-34 · 交换环 II 35-40 · 总结 41。
