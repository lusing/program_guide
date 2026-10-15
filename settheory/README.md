# 集合论教程（settheory）

以 Thomas Jech《Set Theory》（Academic Press 1978，第一版）为纲、
Matteo Viale《The Forcing Method in Set Theory》（Springer UNITEXT 168，
2024）为力迫篇第二底本、David Makinson《Sets, Logic and Maths for
Computing》（Springer UTiCS，第三版 2020）为计算视角篇第三底本的
中文教程：从 ZFC 公理、序数、基数到力迫、大基数与描述集合论，
Jech 全书 44 节 + Viale 7 章附录 + Makinson 11 章全覆盖。

七通道机器验证：

- **Lean 4 + mathlib4**（主证明：Ordinal / Cardinal / ZFC / Zorn 官方锚点）
- **Isabelle/ZF**（第二证明：Paulson 的 Constructible = Gödel L 独家形式化）
- **Coq 8.20**（三证明：浅嵌入 ZF、公理显式记账、有限力迫 toy）
- **Agda 2.8**（构造性视角：HF 集合论、Gale-Stewart 有限博弈）
- **Julia / Python**（计算：基数算术、Aronszajn 树有限构造、Δ系统）
- **Prolog**（有限模型：HF 集合推理、偏序泛型搜索、博弈求解器）

## 全书结构（68 章）

| 篇 | 章 | 底本 | 主题 |
|---|---|---|---|
| 导引 | 00 | — | 机器证明的七通道立场 |
| 一 公理集合论 | 01-09 | Jech §1-9 | ZFC、序数、基数、实数、AC、基数算术、滤子、奇异、正则 |
| 二 传递模型 | 10-15 | Jech §10-15 | 绝对性、坍缩、L、AC+GCH 在 L、Σₙ、OD |
| 三 力迫 | 16-22 | Jech §16-21 | 泛型扩张、cBa、V^B、CH/AC 独立、积、对称 |
| 四 力迫应用 | 23-28 | Jech §22-26 | Suslin、MA、迭代、组合、cBa 对应、Kurepa |
| 五 可测基数 | 29-34 | Jech §27-32 | 测度、超幂、分划、0#、L[U]、弱紧 |
| 六 大基数 | 35-40 | Jech §33-38 | 紧、实值可测、饱和、GCH、力迫应用、超滤 |
| 七 DST | 41-46 | Jech §39-44 | Borel、投影、L 投影、Solovay、AD、DST 力迫 |
| 八 Viale 路线 | 46-55 | Viale 全书 | 布尔值逻辑重建力迫 |
| 九 Makinson 路线 | 56-66 | Makinson 全书 | 计算者的离散数学与逻辑工具箱 |
| 收官 | 67 | — | 三书 CHEATSheet |

章节正文在 `docs/`（只读 docs 即可学习，代码全部在正文引用讲解）；
可运行验证物在 `examples/`（68 章 × 7 通道 = 476 单元）。

## 验证

```pwsh
pwsh -NoProfile -Command '& ./build.ps1 -All'        # 全量对账（476 单元）
pwsh -NoProfile -Command '& ./build.ps1 -Chapter 02' # 只验一章
pwsh -NoProfile -Command '& ./build.ps1 -List'       # 列出全部验证单元
```
