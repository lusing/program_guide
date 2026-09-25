# Coq-HoTT 教程（同伦类型论，Rocq 9.2）

面向**会编程（任意语言背景）、初学类型论与 HoTT** 的读者：**从类型论原理讲起**——
命题即类型、证明即程序、依赖类型、恒等类型——然后沿"路径代数 → 等价 →
截断 → 泛等 → 高阶归纳类型 → 范畴与点化"的路线推进，最后以综合实战
**圆上的螺旋覆叠**收束（自己构造覆叠、算单值变换、证明环路非平凡）。

**章号 = 示例编号**——01–24 章每章对应 `examples/` 里一个经 coqc 编译验证的
完整 .v 文件，25 章为坑位总清单（各章合计 **291 条**，跨章通用 30 条集中于此）。

> 核心理念：**类型即空间，项即点，`p : x = y` 即路径。** 恒等类型不再是
> "只有一个元素的类型"——路径可以复合、逆转、甚至本身之间还有路径
> （二维同伦）。泛等公理更进一步：**等价的类型就是相等的类型**，
> 于是"结构沿同构唯一"从口号变成定理。详见
> [01 章](docs/01-type-theory.md) 与 [11 章](docs/11-univalence.md)。

## 目录结构

```text
coq-hott/
├── README.md        本文件
├── run-all.sh       全量验证脚本（bash）
├── build.ps1        全量验证脚本（PowerShell，判定与 shell 版一致）
├── build-hott.sh    构建 HoTT 库本体（绕过官方 Makefile 的 CRLF 问题）
├── docs/            25 章教程（01 → 25 顺序阅读）
├── examples/        24 个 .v 示例（章号 = 示例编号，01–24）
└── build/           验证产物（可删，脚本自动重建）
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 类型论原理](docs/01-type-theory.md) | 命题即类型、证明即程序、依赖类型、类型即空间 | `01_type_theory.v` |
| [02 工具链](docs/02-toolchain.md) | coqc / Rocq 9.2、-noinit、四件套问询命令 | `02_toolchain.v` |
| [03 依赖类型](docs/03-dependent-types.md) | Π 与 Σ、`sig`、`.1` / `.2` | `03_dependent_types.v` |
| [04 恒等类型与路径归纳](docs/04-identity-types.md) | `paths`、`idpath`、J 消去子 | `04_identity_types.v` |
| [05 Transport](docs/05-transport.md) | 沿路径搬运、moveR/moveL 移项术 | `05_transport.v` |
| [06 路径代数](docs/06-path-algebra.md) | 复合、逆转、`concat_*` 家族、二维同伦 | `06_path_algebra.v` |
| [07 等价](docs/07-equivalences.md) | IsEquiv 四份数据、`equiv_adjointify`、复合 | `07_equivalences.v` |
| [08 同伦纤维与可缩性](docs/08-fibers.md) | `hfiber`、`Contr`、"纤维可缩 ⟺ 等价" | `08_fibers.v` |
| [09 截断层级](docs/09-truncation.md) | -2/-1/0、`IsTrunc_internal`、路径的唯一性 | `09_truncation.v` |
| [10 函数外延](docs/10-funext.md) | `ap10`/`apD10`、`path_forall`、Funext 类 | `10_funext.v` |
| [11 泛等公理](docs/11-univalence.md) | `path_universe`、`equiv_path`、宇宙不是集合 | `11_univalence.v` |
| [12 HIT：区间](docs/12-hit-interval.md) | `interval`、用区间造函数外延 | `12_hit_interval.v` |
| [13 圆 S¹ 与编码-解码](docs/13-circle.md) | `Circle`、π₁(S¹)=ℤ、编码-解码法 | `13_circle.v` |
| [14 类型构造器的路径](docs/14-type-formers.md) | 乘积/Σ/和/箭头的路径与等价 | `14_type_formers.v` |
| [15 截断操作](docs/15-truncations.md) | `Tr n A`、`merely`、`hexists`/`hor`、image | `15_truncations.v` |
| [16 集合与商类型](docs/16-sets-quotient.md) | `Quotient`、`qglue`、BoolQuot 实战 | `16_quotient.v` |
| [17 截断映射与嵌入](docs/17-trunc-maps.md) | `IsTruncMap`、嵌入/满射、分解定理 | `17_trunc_maps.v` |
| [18 泛等的应用](docs/18-univalence-apps.md) | 结构沿等价搬运、`univalent_transport` | `18_univalence_apps.v` |
| [19 余极限](docs/19-colimits.md) | `Pushout`、`Coeq`、`Susp`、HIT 通用模板 | `19_colimits.v` |
| [20 范畴论](docs/20-categories.md) | `PreCategory`、离散范畴、`Functor` | `20_categories.v` |
| [21 点化类型](docs/21-pointed.md) | `pType`、`loops`、`(pCircle ->** X) ≃* ΩX` | `21_pointed.v` |
| [22 自然数与整数](docs/22-numbers.md) | `nat`/`Int`、%nat 坑、归纳证明算术 | `22_numbers.v` |
| [23 元理论与证明工程](docs/23-metatheory.md) | 公理追踪、Search 三板斧、scope 排查 | `23_metatheory.v` |
| [24 综合实战：螺旋覆叠](docs/24-capstone.md) | 覆叠构造、单值变换、`loop ≠ 1` | `24_capstone.v` |
| [25 坑位总清单](docs/25-pitfalls.md) | 各章 291 条汇总、跨章通用 30 条、按症状速查 | — |

学习路线：01–04 原理与基础（命题即类型 → 依赖 → 路径）→ 05–08 路径与等价
核心 → 09–11 截断与两条公理 → 12–13 HIT 与圆 → 14–17 类型构造器与映射 →
18–21 高阶结构 → 22–23 集合数学与工程 → 24 综合实战 → 25 坑清单收束
（写代码前先查）。

## 工具链

| 组件 | 路径 / 版本 |
|---|---|
| coqc | `/opt/local/bin/coqc`（Rocq 9.2，MacPorts） |
| HoTT 库 | `/Volumes/mac004/lang/Coq-HoTT`（官方仓库，582 个 .v 全量编译通过） |
| COQLIB | `/opt/local/lib/coq/` |

> 为什么不用官方 Makefile：仓库的 `etc/generate_coqproject.sh` 与
> `Makefile.coq.local` 是 **CRLF 行尾**，bash 5 解析直接报语法错。
> `build-hott.sh` 绕过方案：`coqdep` 生成依赖 + 两行自制 Makefile，
> 582/582 个 .vo 全部编译成功。不改动源码树。

## 验证命令

```bash
cd coq-hott
bash run-all.sh                        # 全量：24 个示例全部验证
bash run-all.sh 03_dependent_types.v   # 单文件验证
pwsh -NoProfile -Command '& ./build.ps1 -All'     # PowerShell 版全量
pwsh -NoProfile -Command '& ./build.ps1 -File 03_dependent_types.v'
```

**编译开关**（缺一不可）：

```text
coqc -q -noinit -indices-matter -R $HOTT/theories HoTT ex_NN_xxx.v
```

- `-noinit`：不加载 Stdlib 的 Prelude（否则 `paths`、`sig`、`=` 记号被标准库抢走）
- `-indices-matter`：归纳类型的索引参与等价判断（HoTT 要求）
- `-R ... HoTT`：把库根映射成 `HoTT` 命名空间
- 示例先复制到 `build/examples/` 加 `ex_` 前缀再编译
  （Coq 模块名不能以数字开头）

**判定标准**（每示例七条）：

1. coqc 退出码 0；
2. stderr 为 0 字节（连 `[notation-overridden]`、`[level-tolerance]` 警告都不许有）；
3. `sec_NN_BEGIN` / `sec_NN_END` 哨兵各恰好出现一次（`Check` 哨兵常量机制）；
4. 区间非空；
5. 区间无控制字符；
6. 同一文件连跑两遍，区间逐字节一致（排除非确定性）；
7. 全量至少验证一个示例（杜绝"通过 0"的假绿）。

## 公理立场

本教程明确区分**零公理核心**与**公理部分**：

| 内容 | 公理 |
|---|---|
| 路径代数、transport、等价论、截断层级、纤维可缩 ⟺ 等价 | 无（`Print Assumptions` 全部 `Closed under the global context`） |
| 函数外延（第 10 章） | `Funext` |
| 泛等（第 11 章起） | `Univalence` |
| π₁(S¹)=ℤ、loop 非平凡、螺旋覆叠 | `Univalence`（经 `path_universe` 进入） |

每个综合结论都配了 `Print Assumptions` 实测（见第 23、24 章）。

## 平台差异说明

- 验证环境：macOS（Darwin 23 x86_64）+ MacPorts 工具链；
- bash 5.3 下 `"$PASS，"` 全角标点会吞进变量名，脚本一律写 `${PASS}`；
- `pwsh -File x.ps1` 在 MacPorts pwsh 7.6.6 下不可用，
  用 `pwsh -NoProfile -Command '& ./x.ps1'`；
- HoTT 库的宇宙多态打印（`@{u u0}`）与 evar 报告（`?A : [ |- Type]`）
  是 Rocq 9.2 的输出形状，旧版 Coq 略有差异；
- 文档引用的所有输出均逐字节抽取自 `build/out/NN.sec1`（第一遍运行产物）。

## 与姊妹教程的关系

- [coq/](../coq/README.md)：同一工具链的"普通 Coq"教程——先学它再学本章，
  路径归纳与 tactic 基础会顺滑得多；
- [agda/](../agda/README.md)、[lean4/](../lean4/README.md)：另一种
  依赖类型论实现，可对照第 01–04 章；
- [isabelle/](../isabelle/README.md)、[hol4/](../hol4/README.md)：
  经典 HOL 一系，与第 01 章"命题即类型"形成两派证明助手对照。
