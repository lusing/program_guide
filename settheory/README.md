# 集合论教程（settheory）

以 Thomas Jech《Set Theory》（Academic Press 1978，第一版）为纲的中文
教程：从 ZFC 公理、序数、基数到力迫、大基数与描述集合论，全书 44 节
全覆盖。六通道机器验证：

- **Lean 4 + mathlib4**（主证明：Ordinal / Cardinal / ZFC / Zorn 官方锚点）
- **Isabelle/ZF**（第二证明：Paulson 的 Constructible = Gödel L 独家形式化）
- **Coq 8.20**（三证明：浅嵌入 ZF、公理显式记账、有限力迫 toy）
- **Agda 2.8**（构造性视角：HF 集合论、Gale-Stewart 有限博弈）
- **Julia / Python**（计算：基数算术、Aronszajn 树有限构造、Δ系统）
- **Prolog**（有限模型：HF 集合推理、偏序泛型搜索、博弈求解器）

章节正文在 `docs/`（只读 docs 即可学习，代码全部在正文引用讲解）；
可运行验证物在 `examples/`。

## 验证

```pwsh
pwsh -NoProfile -Command '& ./build.ps1 -All'        # 全量对账
pwsh -NoProfile -Command '& ./build.ps1 -Chapter 02' # 只验一章
pwsh -NoProfile -Command '& ./build.ps1 -List'       # 列出验证单元
```

蓝图见 [PLAN.md](PLAN.md)。
