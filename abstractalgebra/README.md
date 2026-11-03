# 抽象代数：编程与自动证明教程

以 Joseph J. Rotman《抽象代数基础教程（原书第3版）》（A First Course in
Abstract Algebra with Applications, 3rd ed.，李样明、冯明军译，机械工业出版社
2008）为纲的自包含中文教程。目标：**只读 docs 就能学会**——讲解为主、代码为辅，
每一段示例代码都在正文中引用并解释，读者不必翻看原书。

## 结构

- `docs/00-40.md` —— 41 章正文（七篇：数论 / 群 I / 交换环 I / 线性代数 / 域 /
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
- 原书编号以「原书 §x.y / 命题 x.z」形式标注，便于对照。
- 机器验证的定理，正文注明对应示例文件与定理名。
