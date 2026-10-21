# 集合论：对无穷概念的探索 —— 教程（郝兆宽·杨跃 底本）

以郝兆宽、杨跃《集合论：对无穷概念的探索》（复旦大学出版社 2014）
为底本的中文自包含教程：从罗素悖论与 ZFC 公理出发，经关系、函数、
实数构造、序数、基数、选择公理、滤与无界闭集、层垒谱系，直到
可构成集 L 与力迫法。每个概念都配机器侧的"影子"——Lean（mathlib）
主证、Isabelle/ZF 第二通道（ZF 公理系统的一等公民）、Coq 浅嵌入、
Julia/Python 计算、Prolog 有限穷举。

**阅读方式**：只读 docs/ 即可学会，examples/ 是每章代码的存档与验证
对象（`pwsh -NoProfile -Command '& ./build.ps1 -All'` 全量对账）。

## 目录

- [00 导引：欢迎来到康托乐园](docs/00-intro.md)
- [01 罗素悖论与一点数理逻辑](docs/01-russell-logic.md)
- [02 ZFC 公理](docs/02-axioms.md)
- [03 关系与函数](docs/03-relations-functions.md)
- [04 等价、划分与序](docs/04-equivalence-order.md)
- [05 自然数与递归定理](docs/05-naturals-recursion.md)
- [06 等势与可数](docs/06-equipollence.md)
- [07 整数、有理数、实数](docs/07-reals.md)
- [08 不可数集合](docs/08-uncountable.md)
- [09 良序集](docs/09-wellorders.md)
- [10 序数与超穷归纳](docs/10-ordinals.md)
- [11 超穷递归与序数算术](docs/11-ordinal-arith.md)
- [12 古德斯坦定理](docs/12-goodstein.md)
- [13 选择公理](docs/13-choice.md)
- [14 基数](docs/14-cardinals.md)
- [15 基数算术](docs/15-cardinal-arith.md)
- [16 共尾与无穷和积](docs/16-cofinality.md)
- [17 基数幂与连续统](docs/17-cardinal-power.md)
- [18 滤、理想与无界闭集](docs/18-filters-club.md)
- [19 层垒谱系与绝对性](docs/19-cumulative-hierarchy.md)
- [20 基础公理与良基归纳](docs/20-foundation-wellfounded.md)
- [21 不可达基数与反映定理](docs/21-inaccessible-reflection.md)
- [22 可构成集 L](docs/22-constructible.md)
- [23 力迫与 CH 独立性](docs/23-forcing.md)
- [24 收官速查表](docs/24-cheatsheet.md)

## 姊妹教程

- [settheory](../settheory/README.md)：Jech+Viale+Makinson 三底本研究生向 69 章；
  本教程是其入门坡道，独立可读。
