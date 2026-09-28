# Agda 教程（Agda 2.9.0 / 标准库 3.0）

面向**会编程（任意语言背景）、初学 Agda** 的读者。全书按逻辑分八个部分，
**章号即阅读顺序**：先立「类型即命题、程序即证明、且程序必须终止」这门心智
模型与工具链（第一部分 01–04），再把类型、数据与计算建模讲清楚（第二部分
05–12：宇宙、模式匹配、终止检查、列表、记录与 Σ、Fin、规范化语义、
pattern 同义词），然后进入证明主线（第三部分 13–19：等式、逻辑、归纳、
推理框架、可判定性、Vec，加一节列表等式的成串实战），继而做依赖编程与
代数结构（第四部分 20–24：函数同构与外延、Relation/Algebra 接口、monoid
折叠、类型的代数、intrinsic 与 extrinsic 两种证明风格），第五部分 25–32
讲语言机制与效应（instance 参数、Monad、IO、文本、余归纳、反射、类型层
计算、立方类型论），第六部分 33–35 收三个综合项目（类型良好表达式解释器、
可验证插入排序、SK 组合子规范化器），第七部分 36–42 是标准库手册，
第八部分 43–44 是参考与附录。

教材取材（Maguire《Certainty by Construction》与 Stump《Verified Functional
Programming in Agda》）不单独成篇，已按主题融进上面的顺序：计算模型在 11 章、
pattern 同义词与差分整数在 12 章、列表等式实战在 19 章、monoid 折叠在 22 章、
类型的代数在 23 章、intrinsic/extrinsic 在 24 章、instance 参数在 25 章、
类型层反射在 31 章、组合子操作语义在 35 章。

**章号 = 示例编号**——除 43（坑清单）与 44（装机校验）两章附录外，每章对应
`examples/` 里一个经 Agda 2.9.0 + stdlib 3.0 类型检查验证的完整 .agda 文件。

> 核心理念：**类型即命题，程序即证明，且程序必须终止。**
> Agda 把依赖类型做成了一等公民——编译（类型检查）通过，定理就成立；
> 详见 [01 章](docs/01-intro.md) 与 [43 章](docs/43-pitfalls.md)。

## 目录结构

```text
agda/
├── README.md              本文件
├── build.sh               类型检查 / 编译运行脚本（bash）
├── AgdaTutorial.agda-lib  项目库定义（examples 目录 + 标准库路径）
├── docs/                  44 章教程（01 → 44 顺序阅读，八个部分）
├── examples/              42 个 .agda 示例（章号 = 示例编号）
└── _build/                类型检查产物（已 gitignore）
```

## 章节索引

### 第一部分 · 入门与工具（01–04）

| 章 | 主题 | 示例 |
|---|---|---|
| [01 认识 Agda](docs/01-intro.md) | Agda 是什么、Curry–Howard、与 Coq/Lean/Idris 对比 | `Ex01_intro.agda` |
| [02 工具链与交互方式](docs/02-toolchain.md) | agda 命令行、.agda-lib、Emacs 交互与孔洞 | `Ex02_toolchain.agda` |
| [03 第一个文件](docs/03-basics.md) | 定义、求值、类型标注与第一个证明 | `Ex03_basics.agda` |
| [04 记号与运算符](docs/04-syntax.md) | fixity、syntax 声明、Unicode 与命名 | `Ex04-syntax.agda` |

### 第二部分 · 类型、数据与计算（05–12）

| 章 | 主题 | 示例 |
|---|---|---|
| [05 类型系统与宇宙](docs/05-universes.md) | Set / Setω、Level 多态、Π 与依赖函数 | `Ex05_universes.agda` |
| [06 数据类型与模式匹配](docs/06-patterns.md) | data、通配符、荒谬模式、点模式 | `Ex06_patterns.agda` |
| [07 递归与终止检查](docs/07-recursion.md) | 结构递归、递归论据、终止性实测边界 | `Ex07_recursion.agda` |
| [08 列表专题](docs/08-lists.md) | List 操作、隐式参数、append 家族 | `Ex08_lists.agda` |
| [09 记录与 Σ 类型](docs/09-records.md) | record、eta、依赖对、函数即记录 | `Ex09_records.agda` |
| [10 依赖类型入门：Fin](docs/10-dependent.md) | 索引类型、依赖消除、荒谬模式实战 | `Ex10_dependent.agda` |
| [11 Agda 的计算模型](docs/11-computation-model.md) | 规范化、卡住项（stuck）、分支因子、copattern 与 η | `Ex11_computation-model.agda` |
| [12 pattern 同义词与差分整数](docs/12-pattern-synonyms.md) | monus、差分整数记录与标签法、规范形做类型、`pattern` 声明、`Data.Integer` | `Ex12-patsyn.agda` |

### 第三部分 · 证明主线（13–19）

| 章 | 主题 | 示例 |
|---|---|---|
| [13 命题等式](docs/13-equality.md) | ≡ 的构造、subst / transport、Leibniz 等式 | `Ex13_equality.agda` |
| [14 逻辑连接词](docs/14-logic.md) | ⊤ ⊥ ¬ × ⊎ ⇔ 与 Curry–Howard 实战 | `Ex14_logic.agda` |
| [15 归纳证明](docs/15-induction.md) | 归纳剧本、依赖消除版归纳、generalize | `Ex15_induction.agda` |
| [16 推理框架](docs/16-reasoning.md) | ≡-Reasoning、≤ 推理、calc 风格 | `Ex16_reasoning.agda` |
| [17 可判定性质](docs/17-decidable.md) | Dec、`_≡?_`、布林判定与命题证明的分野 | `Ex17_decidable.agda` |
| [18 Vec：长度索引的列表](docs/18-vectors.md) | 依赖编程招牌：向量与越界不可表达 | `Ex18_vectors.agda` |
| [19 Braun 树与列表运算推理](docs/19-braun-lists.md) | `length`/`reverse`/`filter` 等式串、keep/inspect idiom、形状焊进类型 | `Ex19_braun_lists.agda` |

### 第四部分 · 依赖编程、代数与证明风格（20–24）

| 章 | 主题 | 示例 |
|---|---|---|
| [20 函数世界：同构与外延](docs/20-functions.md) | `_↔_`、Function.Related、外延公理 | `Ex20_functions.agda` |
| [21 关系代数与抽象代数](docs/21-algebra.md) | Relation.Binary、Semigroup/Monoid 接口 | `Ex21_algebra.agda` |
| [22 monoid 与折叠：单子折纸](docs/22-monoid-origami.md) | `IsMonoid`/`Monoid`、`foldList`、`fold-++`、融合与同态搬运 | `Ex22_monoids.agda` |
| [23 类型的代数](docs/23-type-algebra.md) | `≅`、`Bool ≅ Fin 2`、`Vec ≅ Fin →`、半环定律与 ADT 多项式 | `Ex23_type_algebra.agda` |
| [24 intrinsic 与 extrinsic 证明](docs/24-intrinsic-extrinsic.md) | 三种「判断」、`Dec`/`Tri`、BST 插入查找两版与 ±∞ 收口 | `Ex24_intrinsic_extrinsic.agda` |

### 第五部分 · 机制、效应与反射（25–32）

| 章 | 主题 | 示例 |
|---|---|---|
| [25 instance 参数与模算术](docs/25-instance-modular.md) | `⦃ ⦄` 实例搜索算法、手写 typeclass、多实例冲突、`ℕ/nℕ` 商模型 | `Ex25_modular.agda` |
| [26 Functor/Applicative/Monad](docs/26-monads.md) | Effect 模块族与 do 记号 | `Ex26_monads.agda` |
| [27 IO 与真实程序](docs/27-io.md) | IO 单子、`--compile` 编译流水线 | `Ex27_io.agda` |
| [28 文本处理](docs/28-strings.md) | String / Char / Nat 互转与解析 | `Ex28_strings.agda` |
| [29 余归纳与无限流](docs/29-codata.md) | guardedness、Musical.Stream | `Ex29-codata.agda` |
| [30 反射与元编程](docs/30-reflection.md) | TCDecls、quote goal、宏基础 | `Ex30_reflection.agda` |
| [31 类型层计算与证明反射](docs/31-typelevel-reflection.md) | 类型层整数与 `≤Z`、`Setω`、格式化打印、`quoteTerm`/`showTerm` 反射 | `Ex31_typelevel_reflection.agda` |
| [32 立方类型论初步](docs/32-cubical.md) | `--cubical`、Path、Univalence 体验 | `Ex32_cubical.agda` |

### 第六部分 · 综合实战（33–35）

| 章 | 主题 | 示例 |
|---|---|---|
| [33 实战：类型良好表达式解释器](docs/33-typedast.md) | 依赖 AST：良 scoped + 良 typed 构造即正确 | `Ex33_typedast.agda` |
| [34 实战：可验证插入排序](docs/34-sorting.md) | sorted 谓词 + 重排证明的插入排序 | `Ex34_sorting.agda` |
| [35 SK 组合子：操作语义与终止性](docs/35-combinators.md) | 规则即构造子、`Sfree` 谓词、`Acc` 良基递归与规范化器 | `Ex35_combinators.agda` |

### 第七部分 · 标准库手册（36–42）

| 章 | 主题 | 示例 |
|---|---|---|
| [36 标准库阅读指南](docs/36-stdlib-guide.md) | 模块组织、Base/API 约定、命名地图 | `Ex36_stdlib.agda` |
| [37 stdlib 代数结构](docs/37-stdlib-algebra.md) | Algebra 三层（Definitions/Structures/Bundles）+ Solver 家族 | `Ex37_stdlib-algebra.agda` |
| [38 stdlib 判定性体系](docs/38-stdlib-decidable.md) | Dec 内部构造、Recomputable、判定式组合子、`_≟_`→`_≡?_` | `Ex38_stdlib-decidable.agda` |
| [39 stdlib 关系产业](docs/39-stdlib-relations.md) | 关系三层 + Construct 变形、Reasoning 挂接 | `Ex39_stdlib-relations.agda` |
| [40 stdlib 函数论与类型运算](docs/40-stdlib-functions.md) | Function.Base/Bundles/Related、外延公理位置 | `Ex40_stdlib-functions.agda` |
| [41 stdlib 数据结构系统](docs/41-stdlib-data.md) | List 关系树、Fin 构造、`Data.AVL`→`Data.Tree.AVL` | `Ex41_stdlib-data.agda` |
| [42 stdlib 自动证明](docs/42-stdlib-automation.md) | Reasoning 基础设施 + Tactic 求解器（Cong/Monoid/Ring） | `Ex42_stdlib-automation.agda` |

### 第八部分 · 参考与附录（43–44）

| 章 | 主题 | 示例 |
|---|---|---|
| [43 坑清单与最佳实践](docs/43-pitfalls.md) | 106 条实测坑位总清单 + 各章坑位索引 + 最佳实践十条 | — |
| [44 macOS 校验与 2.3→3.0 迁移](docs/44-macos-checklist.md) | macOS 源码编译装机 + 2.3→3.0 导入迁移清单 | — |

八个部分本身就是一条依赖链：每章标题下标注所属部分，进一章前先确认它的
前置章已在射程内。几条常见支线：

- 只想写程序、暂不碰证明：01–12 → 25–28 → 36。
- 目标是读懂并证明定理：01–19 全读，再按兴趣挑 20–24、32。
- 做依赖编程 / DSL：10 → 18 → 19 → 23 → 24 → 33。
- 动手写之前先扫 [43 章](docs/43-pitfalls.md) 的目录，遇到报错按标签回查它。

## 工具链

| 组件 | 路径 / 版本 |
|---|---|
| Agda（Debian/WSL） | `/usr/bin/agda`（2.8.0，apt 安装） |
| Agda（macOS） | 源码编译：`/Volumes/mac004/lang/agda`（master，Agda 2.9.0）经 stack + GHC 9.14.1 构建，详见 [44 章](docs/44-macos-checklist.md) |
| 标准库 | Debian：`/usr/share/agda-stdlib`（2.3）；macOS：git 源 `/Volumes/mac004/lang/agda-stdlib/src`（3.0），经 `AgdaTutorial.agda-lib` 引入 |
| Emacs 交互 | Debian：`elpa-agda2-mode`（C-u C-x ` 跳孔洞，C-c C-l 加载） |

## 验证命令

```bash
cd agda
./build.sh                # 全部示例类型检查
./build.sh Ex15_induction # 单文件检查
./build.sh run Ex27_io    # 编译为可执行文件并运行
./build.sh clean          # 清理 _build/
```

**判定标准**：全部示例 `agda` 类型检查退出码 0；`Ex27_io` 额外
`--compile` 后运行输出 `hello agda 42`。

## 平台差异说明

- .agda 文件为 UTF-8 无 BOM；中文注释直接可用（Agda 的 Unicode 标识符
  与中文注释天然共存）。
- `AgdaTutorial.agda-lib` 的 `include` 写死标准库源码路径（当前为 macOS
  git 源 `/Volumes/mac004/lang/agda-stdlib/src`，stdlib 3.0）；换机器改
  这一行即可。
- 本教程以 Agda 2.9.0 + stdlib 3.0 为基线（macOS 源码编译装机与全量校验
  结果见 44 章）。stdlib 各版本间模块路径有挪动（如 `Data.AVL` →
  `Data.Tree.AVL`、顶层没有 `Data.Tree` 这个模块而树族住在
  `Data/Tree/{Rose,Binary,AVL}`、单子群顶层名 `+-isMonoid` →
  `+-0-isMonoid`），2.3→3.0 的实测迁移清单见
  [44 章](docs/44-macos-checklist.md)，另见 24 章 24.10 与 19 章 19.14
  的实名普查。
- `build.sh` 自动定位 agda：先探 `PATH`，再逐个试常见安装位（stack/
  cabal/ghcup/Homebrew），找不到才报错——非交互 shell 里 PATH 缺
  `/opt/local/bin` 也能跑；darwin 下脚本会 `export LC_ALL=en_US.UTF-8`，
  保证 `≟`/`ℕ`/`≤` 等 Unicode 正常输出。

## 示例怎么读

- **章号 = 示例编号**：`docs/15-induction.md` ↔ `examples/Ex15_induction.agda`，
  每章开头一行"对应示例"标注。
- 示例文件名带 `Ex` 前缀：Agda 模块名不能以数字开头，
  `module 15_induction` 直接是语法错误——这个坑 01 章就会撞上。
  04/12/29 三章用**连字符**（`Ex04-syntax`、`Ex12-patsyn`、`Ex29-codata`）：
  `syntax`/`pattern`/`codata` 是关键字，被下划线分隔成独立词法片段后
  连 parse 都过不去。
- 每章正文开头一行「**实测口径**」交代这一章的代码与报错原文跑在哪台机器上
  （两台机器的对照表见 [02 章](docs/02-toolchain.md)，升级差异见
  [44 章](docs/44-macos-checklist.md)）——引用任何一条报错前先认这行。
- 每章末尾各带一份「实测坑位清单」（编号见各章最后一节），报错文本全部
  来自当时删除的临时探针文件；43 章把全部坑位去重归类成总清单。
- 报错原文里的探针文件名（`TmpProbeNN*`、`TmpNNx`）带的是**当初写那一章时
  的章号**，统稿重编号后可能与现在的章号对不上——它们是引文，文件早已删除，
  原样保留比"顺手改齐"更诚实。
- 43 章无示例，是全教程坑位的汇总清单——写代码前先查它。

## 相关教程

同为证明助手的 [coq](../coq/README.md)（tactic 证明主线）与
[lean4](../lean4/README.md)（数学定理主线）；三者共享 Curry–Howard 心智
模型，Agda 的特殊处是**项构造为主 + 终止性检查**；函数式对照
[haskell](../haskell/README.md)（Agda 语法与模块系统与其同源）。
