# Coq 教程（Coq 8.20 / Rocq）

面向**会编程（任意语言背景）、初学 Coq** 的读者：从证明助手的心智模型讲到
类型系统、归纳类型、tactic 证明技法，再到 AST 求值器、插入排序正确性、
列表定律等证明实战，最后以综合项目**表达式解释器与优化器**收束。
**章号 = 示例编号**——01–24 章每章对应 `examples/` 里一个经 coqc 8.20.1
编译验证的完整 .v 文件，25 章为 60+ 条实测坑位总清单。

> 核心理念：**类型即命题，程序即证明。** Coq 把"写代码"和"证定理"变成
> 同一种语言里的同一件事——编译通过就是定理成立；详见
> [01 章](docs/01-intro.md) 与 [25 章](docs/25-pitfalls.md)。

## 目录结构

```text
coq/
├── README.md        本文件
├── build.ps1        编译验证脚本（PowerShell）
├── docs/            25 章教程（01 → 25 顺序阅读）
├── examples/        24 个 .v 示例（章号 = 示例编号，01–24）
└── build/           编译输出（已 gitignore）
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 认识 Coq](docs/01-intro.md) | Coq 是什么、Check / Compute 与第一个证明 | `01_intro.v` |
| [02 工具链与运行方式](docs/02-toolchain.md) | coqc / coqtop / CoqIDE、问询四件套 | `02_toolchain.v` |
| [03 第一个证明](docs/03-first-proof.md) | Proof-Qed 解剖、Fail、Abort | `03_first_proof.v` |
| [04 类型系统](docs/04-types.md) | nat 真身、sorts、多态与隐式参数 | `04_types.v` |
| [05 表达式与运算符](docs/05-expressions.md) | 记号、nat 算术坑、if 真身、%Z | `05_expressions.v` |
| [06 元组与记录](docs/06-tuples-records.md) | 积类型、Record、字段名坑 | `06_tuples_records.v` |
| [07 模式匹配](docs/07-patterns.md) | match 词汇表、穷尽 / 冗余分支 | `07_patterns.v` |
| [08 列表](docs/08-lists.md) | list 操作、fold 方向与参数序坑 | `08_lists.v` |
| [09 归纳类型：自定义数据](docs/09-inductive.md) | 枚举、自造 bool/nat、二叉树 | `09_inductive.v` |
| [10 递归函数：Fixpoint 与终止性](docs/10-fixpoint.md) | 结构递归、守卫检查实测边界 | `10_fixpoint.v` |
| [11 证明状态与 tactic 机理](docs/11-proof-state.md) | 证明状态演变、apply / exact | `11_proof_state.v` |
| [12 归纳证明](docs/12-induction.md) | 归纳剧本四例（nat / list） | `12_induction.v` |
| [13 重写、化简与分情况讨论](docs/13-rewrite.md) | rewrite 方向学、destruct、discriminate | `13_rewrite.v` |
| [14 命题逻辑](docs/14-logic.md) | /\ \/ -> ~ iff 与子弹层级 | `14_logic.v` |
| [15 谓词逻辑与 reflect](docs/15-predicates.md) | 归纳谓词、exists、强化、reflect | `15_predicates.v` |
| [16 高阶函数及其证明](docs/16-higher-order.md) | map 定律、filter 幂等 | `16_higher_order.v` |
| [17 Option：安全建模](docs/17-option.md) | option 建模、bind 链、定律 | `17_option.v` |
| [18 策略武器库与模块](docs/18-tactics-modules.md) | auto / assert、模块签名封装 | `18_tactics_modules.v` |
| [19 表达式求值器：AST 入门](docs/19-ast.md) | aexp 求值器 + 优化器正确性 | `19_ast.v` |
| [20 列表定律证明实战](docs/20-list-laws.md) | 六条列表定律 + rev_acc 强化 | `20_list_laws.v` |
| [21 插入排序与正确性证明](docs/21-sorting.md) | 插入排序 + 有序 / 重排双正确性 | `21_sorting.v` |
| [22 数值专题：nat、N 与 Z](docs/22-numbers.md) | nat/N/Z、lia、作用域坑 | `22_numbers.v` |
| [23 测试与断言风格](docs/23-testing.md) | Example 即测试、Print Assumptions | `23_testing.v` |
| [24 综合实战：表达式解释器与优化器](docs/24-project.md) | 解释器 + 双 pass 流水线 + Extraction | `24_project.v` |
| [25 坑清单与最佳实践](docs/25-pitfalls.md) | 60+ 条实测坑位与最佳实践总清单 | — |

学习路线：01–05 语言与基本证明 → 06–10 数据建模（元组/匹配/列表/归纳/
递归）→ 11–15 证明技法主线（归纳/重写/逻辑）→ 16–18 高阶与工程化 →
19–24 实战递进（AST → 列表定律 → 排序 → 数值 → 测试 → 解释器）→
25 坑清单收束（写代码前先查）。

## 工具链

| 组件 | 路径 / 版本 |
|---|---|
| Coq | `G:\scoop\apps\coq\current`（8.20.1，scoop 安装） |
| 编译器 | `G:\scoop\apps\coq\current\bin\coqc.exe` |

## 验证命令

```powershell
cd coq
.\build.ps1 -All                        # 复制到 build/ 加 ex_ 前缀逐个 coqc 编译
.\build.ps1 -File 03_first_proof.v      # 单文件编译验证
.\build.ps1 -Clean                      # 清理 build/
```

**判定标准**：全部 24 个示例 coqc 编译退出码 0。`24_project.v` 的
`Recursive Extraction` 会向输出打印抽取的 OCaml 代码，全量编译耗时略长
（2–4 分钟）属正常。

## 平台差异说明

- .v 文件为 UTF-8 **无 BOM**，中文注释可直接编译。
- 2024 年 Coq 更名 **Rocq**，9.0 起库命名空间 `Coq.*` → `Stdlib.*`；
  本教程钉在 8.20.1（旧命名空间），新版本 Rocq 下部分 `From Coq Require`
  需改为 `From Stdlib Require`。

## 示例怎么读

- **章号 = 示例编号**：`docs/05-expressions.md` ↔ `examples/05_expressions.v`，
  每章开头一行"对应示例"标注。
- 25 章无示例，是全教程坑位的汇总清单——写代码前先查它。
- 改示例后重跑对应文件：`.\build.ps1 -File NN_xxx.v`。

## 相关教程

同为证明助手的 [lean4](../lean4/README.md)（数学定理主线）；ML 系函数式
对照 [sml](../sml/README.md) / [ocaml](../ocaml/README.md)；惰性函数式与
类型类 [haskell](../haskell/README.md)。
