# Coq-HoTT 教程（同伦类型论，Rocq 9.2）

写给**会编程、但没学过类型论和同伦类型论**的读者。

这本书要让你真正理解一件事：

> **类型是空间，元素是点，`p : x = y` 是一条从 x 到 y 的路径。**

一旦把这句话当真，许多熟悉的东西会换一种样子出现。相等不再是“是或否”，而是可以复合、取逆、还能彼此比较的路径。“两个类型一样”不再是集合论里一句空话，而是可以精确定义、并且由泛等公理与“相等”画上等号的概念。拓扑学里的圆、覆叠空间、基本群，都变成了类型论里可以写下来、可以证明的对象。

每一章先问**为什么需要这个概念**，再用几何和逻辑两套语言把它讲清楚，最后才落到 Coq-HoTT 库里的定义。代码是用来对照直觉的，不是教程的主角。想亲自跑例子时，看文末附录即可。

假定读者见过 `Definition`、`Inductive` 和几条基本 tactic。没有的话，先读姊妹教程 [coq/](../coq/README.md) 的前几章。

## 你将理解什么

读完最短路线之后，你应该能用自己的话回答这些问题：

- 为什么“相等的证明可以不止一个”，而这并不使相等变得不可靠？
- 路径归纳（J 规则）到底允许你对哪些路径说话，为什么环路不能直接归纳？
- 什么叫两个类型“一样”？为什么“有逆函数”还不够？
- 命题、集合、圆，在同一把标尺上差在哪一层？
- 泛等公理在说什么？它为什么让 `Type` 不再是集合，又为什么能证明圆的环路缩不回去？

这些问题的答案构成同伦类型论的主干。其余章节是把主干长成一棵能做数学的树：截断、商、余极限、范畴、点化空间。

## 阅读路线

```text
第一部分  地基         01 类型即空间 → 02 设计选择 → 03 依赖类型
第二部分  路径         04 恒等类型 → 05 Transport → 06 路径代数
第三部分  等价与层级   07 等价 → 08 纤维与可缩 → 09 截断层级
第四部分  两条公理     10 函数外延 → 11 泛等
第五部分  高阶归纳类型 12 区间 → 13 圆与编码-解码
第六部分  类型的结构   14 构造器里的路径 → 15 截断操作 → 16 集合与商 → 17 截断映射
第七部分  高阶结构     18 结构搬运 → 19 余极限 → 20 范畴论 → 21 点化类型
第八部分  落地         22 集合上的数学 → 23 公理意味着什么
终章                  24 螺旋覆叠 → 25 误区总览
```

**最短路线**：01 → 04 → 05 → 07 → 09 → 11 → 13 → 24。

这条线从“相等是路径”走到“用泛等证明圆的环路非平凡”，是 HoTT 的主干。其余章节在你需要时再读：卡住了再回头，比按目录硬读更有效。

## 章节索引

| 章 | 主题 | 要理解的那句话 | 示例 |
|---|---|---|---|
| [01](docs/01-type-theory.md) | 类型即空间 | 命题即类型，证明即程序，类型即空间 | `01_type_theory.v` |
| [02](docs/02-toolchain.md) | 三条设计选择 | 没有 `Prop`、公理是假设、路径优先于算术 | `02_toolchain.v` |
| [03](docs/03-dependent-types.md) | 依赖类型 | Π 是全称，Σ 是带见证的存在 | `03_dependent_types.v` |
| [04](docs/04-identity-types.md) | 恒等类型 | 只有一条规则 J，一切路径性质由它派生 | `04_identity_types.v` |
| [05](docs/05-transport.md) | Transport | 沿路径把纤维里的点平行移动过去 | `05_transport.v` |
| [06](docs/06-path-algebra.md) | 路径代数 | 每个类型是一个 ∞-群胚 | `06_path_algebra.v` |
| [07](docs/07-equivalences.md) | 等价 | “两个类型一样”必须在所有层次对齐 | `07_equivalences.v` |
| [08](docs/08-fibers.md) | 纤维与可缩 | 等价 ⟺ 每个纤维可缩 | `08_fibers.v` |
| [09](docs/09-truncation.md) | 截断层级 | 可缩、命题、集合是同一把尺子上的刻度 | `09_truncation.v` |
| [10](docs/10-funext.md) | 函数外延 | 逐点相等推不出函数相等 | `10_funext.v` |
| [11](docs/11-univalence.md) | 泛等公理 | 等价的类型就是相等的类型 | `11_univalence.v` |
| [12](docs/12-hit-interval.md) | 区间 | HIT 用路径构造子把空间粘出来 | `12_hit_interval.v` |
| [13](docs/13-circle.md) | 圆 | 第一个有非平凡环路的类型；π₁(S¹) = ℤ | `13_circle.v` |
| [14](docs/14-type-formers.md) | 构造器里的路径 | 每种类型里的“相等”都可以拆开看 | `14_type_formers.v` |
| [15](docs/15-truncations.md) | 截断操作 | “存在但不告诉你是谁”是把类型压成命题 | `15_truncations.v` |
| [16](docs/16-sets-quotient.md) | 集合与商 | 商必须截断，否则会留下环路 | `16_quotient.v` |
| [17](docs/17-trunc-maps.md) | 截断映射 | 嵌入不是单射；满射 + 嵌入 = 等价 | `17_trunc_maps.v` |
| [18](docs/18-univalence-apps.md) | 结构搬运 | 同构的东西有相同的性质，在这里是定理 | `18_univalence_apps.v` |
| [19](docs/19-colimits.md) | 余极限 | 所有 HIT 都是“沿指定方式粘合” | `19_colimits.v` |
| [20](docs/20-categories.md) | 范畴论 | 单叶范畴 = 对象的同构即相等 | `20_categories.v` |
| [21](docs/21-pointed.md) | 点化类型 | 基点变成数据，环路空间才有定义 | `21_pointed.v` |
| [22](docs/22-numbers.md) | 自然数与整数 | 集合层面的 HoTT 就是普通数学 | `22_numbers.v` |
| [23](docs/23-metatheory.md) | 公理意味着什么 | 每条定理用了什么，机器可以列出来 | `23_metatheory.v` |
| [24](docs/24-capstone.md) | 螺旋覆叠 | 自己造覆叠，证明 `loop ≠ 1` | `24_capstone.v` |
| [25](docs/25-pitfalls.md) | 误区总览 | 想错了比写错了更危险 | — |

另有 [CHEATSheet.md](CHEATSheet.md)：读完之后用来查记号和引理，不是入门读物。

## 公理立场

本教程始终区分**零公理核心**与**公理部分**，并在正文里标明每个结论信了什么：

| 内容 | 需要的公理 |
|---|---|
| 路径代数、transport、等价论、截断层级、纤维可缩 ⟺ 等价 | 无 |
| 函数外延（第 10 章起） | `Funext` |
| 泛等（第 11 章起）、结构搬运、π₁(S¹) = ℤ、`loop ≠ 1` | `Univalence` |

这个区分本身就是要理解的内容：HoTT 的大部分几何，并不依赖那两条著名公理。公理只在两处进场——比较两个函数，以及把等价提升为类型之间的路径。第 23 章专门讲这件事。

## 与姊妹教程的关系

- [coq/](../coq/README.md)：普通 Coq。本教程假定读者至少见过它的前几章。
- [typetheory/](../typetheory/README.md)：类型论通论。第 19–23 章用自包含的 mini-HoTT 走了同一条主干；本教程改用官方库，走得更远。
- [agda/](../agda/README.md)、[lean4/](../lean4/README.md)：另外两种依赖类型论，可与第 01–04 章对照。
- [isabelle/](../isabelle/README.md)、[hol4/](../hol4/README.md)：经典高阶逻辑一系，与“命题即类型”形成对照。

## 延伸阅读

- *Homotopy Type Theory: Univalent Foundations of Mathematics*（HoTT Book）。本教程的章节顺序大体对应其第 1–4、6–8 章。
- Egbert Rijke, *Introduction to Homotopy Type Theory*。
- 读完本教程后，值得从 `theories/Basics/Overture.v` 开始翻 Coq-HoTT 库源码：那是同一套观念的工程形态。

---

## 附录：目录与运行示例

先读正文。下面这些只在你想编译例子、或想对照库里的定义时才需要。

```text
coq-hott/
├── README.md        本文件
├── CHEATSheet.md    一页速查
├── docs/            25 章正文
├── examples/        24 个 .v 示例（章号 = 示例编号）
├── run-all.sh       验证脚本（bash）
├── build.ps1        验证脚本（PowerShell）
└── build-hott.sh    构建 HoTT 库本体
```

每章正文里的代码片段取自对应示例。示例是给机器核对的，不是给读者当主教材的。

编译一个示例需要 Rocq 9.2 与 Coq-HoTT 库：

```bash
coqc -q -noinit -indices-matter -R $HOTT/theories HoTT ex_NN_xxx.v
```

三个开关各有语义上的理由（详见第 02 章）：`-noinit` 挡住标准库的 Prelude，因为基础类型同名不同义；`-indices-matter` 让归纳类型的索引参与宇宙计算，否则恒等类型会落错宇宙；`-R ... HoTT` 把库根映射成 `HoTT` 命名空间。示例文件名以数字开头，而 Coq 模块名不能以数字开头，所以脚本会先复制成 `ex_NN_xxx.v` 再编译。

批量验证：

```bash
bash run-all.sh                        # 全部示例
bash run-all.sh 13                     # 只跑第 13 章
pwsh -NoProfile -Command '& ./build.ps1 -All'
```

库本体用 `build-hott.sh` 构建。环境变量 `HOTT_SRC`、`COQBIN` 可指定库根与 `coqc` 所在目录。
