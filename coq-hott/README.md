# Coq-HoTT 教程（同伦类型论，Rocq 9.2）

写给**会编程、但没学过类型论和同伦类型论**的读者。全书围绕一个念头展开：

> **类型是空间，元素是点，`p : x = y` 是一条从 x 到 y 的路径。**

一旦接受这个念头，很多熟悉的东西会换一种样子出现：相等不再是"是或否"，
而是可以复合、取逆、还能彼此比较的路径；"两个类型一样"不再是集合论里的
一句空话，而是可以精确定义、并且由泛等公理与"相等"画上等号的概念；
拓扑学里的圆、覆叠空间、基本群，都变成了可以在证明助手里一行行写出来的对象。

每一章先讲**为什么需要这个概念、它的直觉是什么**，再用 Coq-HoTT 库里的
代码把直觉落实成定义和证明，最后用一节"常见误区"指出初学者最容易想歪的地方。
代码是用来照亮概念的，不是反过来。

## 阅读路线

```text
第一部分  地基         01 类型论原理 → 02 读懂这个库 → 03 依赖类型
第二部分  路径         04 恒等类型 → 05 Transport → 06 路径代数
第三部分  等价与层级   07 等价 → 08 纤维与可缩性 → 09 截断层级
第四部分  两条公理     10 函数外延 → 11 泛等
第五部分  高阶归纳类型 12 区间 → 13 圆与编码-解码
第六部分  类型的结构   14 类型构造器的路径 → 15 截断操作 → 16 集合与商 → 17 截断映射
第七部分  高阶结构     18 泛等的应用 → 19 余极限 → 20 范畴论 → 21 点化类型
第八部分  落地         22 自然数与整数 → 23 公理纪律与证明工程
终章                  24 综合实战：圆上的螺旋覆叠 → 25 误区总览
```

只想抓住核心的读者，可以走最短路线：01 → 04 → 05 → 07 → 09 → 11 → 13 → 24。
这条线从"相等是路径"一直走到"用泛等证明圆的环路非平凡"，是 HoTT 的主干。

## 章节索引

| 章 | 主题 | 一句话 | 示例 |
|---|---|---|---|
| [01](docs/01-type-theory.md) | 类型论原理 | 命题即类型、证明即程序、类型即空间 | `01_type_theory.v` |
| [02](docs/02-toolchain.md) | 读懂这个库 | HoTT 库与标准 Coq 的三点不同，如何查东西，公理纪律 | `02_toolchain.v` |
| [03](docs/03-dependent-types.md) | 依赖类型 | Π 与 Σ：全称与存在的类型论形态 | `03_dependent_types.v` |
| [04](docs/04-identity-types.md) | 恒等类型与路径归纳 | 只有一条规则 J，一切路径性质由它派生 | `04_identity_types.v` |
| [05](docs/05-transport.md) | Transport | 沿路径搬运纤维；证明不等的标准方法 | `05_transport.v` |
| [06](docs/06-path-algebra.md) | 路径代数 | 路径构成群胚，二维路径与 Eckmann–Hilton | `06_path_algebra.v` |
| [07](docs/07-equivalences.md) | 等价 | 什么叫"两个类型一样"：伴随等价 | `07_equivalences.v` |
| [08](docs/08-fibers.md) | 同伦纤维与可缩性 | 等价 ⟺ 每个纤维可缩 | `08_fibers.v` |
| [09](docs/09-truncation.md) | 截断层级 | 可缩、命题、集合……类型的复杂度标尺 | `09_truncation.v` |
| [10](docs/10-funext.md) | 函数外延 | 逐点相等为何推不出相等，以及公理如何被管理 | `10_funext.v` |
| [11](docs/11-univalence.md) | 泛等公理 | 等价就是相等；`Type` 不是集合 | `11_univalence.v` |
| [12](docs/12-hit-interval.md) | HIT 入门：区间 | 带路径构造子的类型；区间推出函数外延 | `12_hit_interval.v` |
| [13](docs/13-circle.md) | 圆与编码-解码 | 第一个有非平凡环路的类型；π₁(S¹) = ℤ | `13_circle.v` |
| [14](docs/14-type-formers.md) | 类型构造器的路径 | 乘积、Σ、和、函数里的"相等"各是什么 | `14_type_formers.v` |
| [15](docs/15-truncations.md) | 截断操作 | 把类型压成命题：`merely` 与构造性的"存在" | `15_truncations.v` |
| [16](docs/16-sets-quotient.md) | 集合与商类型 | 在 0-型里做普通数学；商为什么是集合 | `16_quotient.v` |
| [17](docs/17-trunc-maps.md) | 截断映射与嵌入 | 等价、嵌入、满射：一条标尺上的三个刻度 | `17_trunc_maps.v` |
| [18](docs/18-univalence-apps.md) | 泛等的应用 | 结构沿等价自动搬运 | `18_univalence_apps.v` |
| [19](docs/19-colimits.md) | 余极限 | Pushout、Coeq、Susp：所有 HIT 的共同模板 | `19_colimits.v` |
| [20](docs/20-categories.md) | 范畴论 | 为什么要"预范畴"，范畴公理为何是数据 | `20_categories.v` |
| [21](docs/21-pointed.md) | 点化类型 | 基点、环路空间、保点映射 | `21_pointed.v` |
| [22](docs/22-numbers.md) | 自然数与整数 | 集合层面的 HoTT 就是普通数学 | `22_numbers.v` |
| [23](docs/23-metatheory.md) | 公理纪律与证明工程 | `Print Assumptions`、找引理、排查类型类 | `23_metatheory.v` |
| [24](docs/24-capstone.md) | 综合实战：螺旋覆叠 | 自己造覆叠、算单值变换、证明 `loop ≠ 1` | `24_capstone.v` |
| [25](docs/25-pitfalls.md) | 误区总览 | 概念误区与工程陷阱的跨章汇总 | — |

另有 [CHEATSheet.md](CHEATSheet.md)：记号、核心引理与证明套路的一页速查。

## 公理立场

本教程始终区分**零公理核心**与**公理部分**，并在正文里标明每个结论用到了什么：

| 内容 | 需要的公理 |
|---|---|
| 路径代数、transport、等价论、截断层级、"纤维可缩 ⟺ 等价" | 无 |
| 函数外延（第 10 章起） | `Funext` |
| 泛等（第 11 章起）、结构搬运、π₁(S¹) = ℤ、`loop ≠ 1` | `Univalence` |

HoTT 库把两条公理做成类型类，`Print Assumptions` 能列出任何定理的公理依赖。
第 23 章专门讲这件事。

## 目录结构

```text
coq-hott/
├── README.md        本文件
├── CHEATSheet.md    一页速查
├── docs/            25 章正文
├── examples/        24 个 .v 示例（章号 = 示例编号，经 coqc 编译验证）
├── run-all.sh       验证脚本（bash）
├── build.ps1        验证脚本（PowerShell）
└── build-hott.sh    构建 HoTT 库本体
```

每章正文里的代码片段都取自对应的示例文件；读者可以边读边在示例文件里
把 `Check`、`Print`、`Compute` 的结果看个究竟。

## 运行示例（附录）

示例需要 Rocq 9.2 与 Coq-HoTT 库。编译一个示例的命令是：

```bash
coqc -q -noinit -indices-matter -R $HOTT/theories HoTT ex_NN_xxx.v
```

- `-noinit`：不加载标准库的 Prelude。HoTT 库自带一套 prelude，重新定义了
  `paths`、`nat`、`sig` 等基础类型，与标准库同名不同义，所以必须把标准库挡在外面。
- `-indices-matter`：让归纳类型的索引参与宇宙层级判断，这是 HoTT 对一致性的要求。
- `-R ... HoTT`：把库根映射成 `HoTT` 命名空间。
- 示例文件名以数字开头，而 Coq 模块名不能以数字开头，所以脚本会先复制成 `ex_NN_xxx.v` 再编译。

批量验证：

```bash
bash run-all.sh                        # 全部示例
bash run-all.sh 13                     # 只跑第 13 章
pwsh -NoProfile -Command '& ./build.ps1 -All'
```

脚本会检查每个示例编译通过、stderr 为空、输出稳定。
HoTT 库本体用 `build-hott.sh` 构建（它绕过官方 Makefile 的 CRLF 行尾问题，
用 `coqdep` 生成依赖后直接编译，不改动源码树）。验证环境为 macOS + MacPorts，
`HOTT_SRC` 与 `COQBIN` 两个环境变量可指定库根与 coqc 所在目录。

## 与姊妹教程的关系

- [coq/](../coq/README.md)：普通 Coq 教程。本教程假定读者至少见过 `Definition`、
  `Inductive`、`Proof ... Qed` 和几条基本 tactic；没有的话先读它的前几章。
- [agda/](../agda/README.md)、[lean4/](../lean4/README.md)：另外两种依赖类型论实现，
  可与第 01–04 章对照。
- [isabelle/](../isabelle/README.md)、[hol4/](../hol4/README.md)：经典高阶逻辑一系，
  与"命题即类型"形成对照。

## 延伸阅读

- *Homotopy Type Theory: Univalent Foundations of Mathematics*（HoTT Book），
  本教程的章节顺序大体对应其第 1–4、6–8 章。
- Egbert Rijke, *Introduction to Homotopy Type Theory*。
- Coq-HoTT 库源码：`theories/Basics/Overture.v` 是一切的起点，读完本教程后值得通读。
