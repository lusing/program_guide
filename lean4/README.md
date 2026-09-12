# Lean 4 & Mathlib4 完整教程示例代码

版本: **Lean 4.33.1 / Mathlib4 4.33.1**

## 项目结构

```
lean4/
├── lean-toolchain                     # 指定工具链版本
├── lakefile.lean                      # Lake 项目配置
├── README.md                          # 本文件
├── build.ps1                          # 构建脚本
├── lean4-mathlib4-tutorial.md         # 完整教程文档
├── Lean4Tutorial.lean                 # 根模块
├── Lean4Tutorial/
│   └── Examples/                      # 所有示例代码
│       ├── Basics/                    # 基础类型与函数
│       ├── InductiveTypes/            # 归纳类型
│       ├── PatternMatching/           # 模式匹配与递归
│       ├── Typeclasses/               # 类型类
│       ├── Propositions/              # 命题与证明
│       ├── Tactics/                   # 战术基础
│       ├── Structures/                # 结构与记录
│       ├── ModulesProjects/           # 模块与项目管理
│       ├── MathlibAlgebra/            # 代数结构
│       ├── MathlibNumberTheory/       # 数论
│       ├── MathlibAnalysis/           # 实分析
│       ├── MathlibTopology/           # 拓扑学
│       ├── MathlibLinearAlgebra/      # 线性代数
│       ├── MathlibCombinatorics/      # 组合数学
│       ├── MathlibMeasureProbability/ # 测度论与概率论
│       └── AdvancedTactics/           # 高级战术
├── examples/                          # 源码示例（数字编号分类，便于阅读）
│   ├── 01_basics/
│   ├── 02_inductive_types/
│   ├── ...
│   └── 16_advanced_tactics/
└── scripts/
    ├── build_all.ps1                  # 构建所有示例
    └── clean.ps1                      # 清理构建产物
```

## 环境要求

- **elan**（Lean 版本管理器）
- **Lean 4.33.1**（通过 elan 安装）
- **Mathlib4 4.33.1**

## 快速开始

### 1. 安装工具链

```bash
# 安装指定版本
elan install leanprover/lean4:v4.33.1
```

### 2. 获取 Mathlib 缓存（可选但推荐）

```bash
lake exe cache get
```

### 3. 构建

```powershell
# 构建全部示例
.\build.ps1

# 或使用 lake 命令
lake build
```

### 4. 运行单个示例

```bash
# 检查类型
lake env lean Lean4Tutorial/Examples/Basics/BasicTypes.lean

# 构建指定模块
lake build Lean4Tutorial.Examples.Basics.BasicTypes
```

## 示例文件清单

### 第一部分：Lean 4 基础（29 个文件）

| 目录 | 文件 | 描述 |
|------|------|------|
| 01_basics | basic_types.lean | 基本类型：Nat, Int, Bool, String, Char, Float |
| | functions.lean | 函数定义、匿名函数、高阶函数 |
| | polymorphism.lean | 多态函数、类型推断、元组 |
| | strings.lean | 字符串操作 |
| 02_inductive_types | enums.lean | 枚举类型 |
| | option_type.lean | Option 类型 |
| | recursive_types.lean | 递归归纳类型 |
| | dependent_types.lean | 依赖归纳类型（Vector） |
| 03_pattern_matching | match_basics.lean | match 表达式 |
| | equation_compiler.lean | 等式定义（阶乘、斐波那契） |
| | list_recursion.lean | 列表上的递归 |
| | well_founded.lean | 有根递归（阿克曼函数） |
| | tree_recursion.lean | 二叉树结构递归 |
| 04_typeclasses | typeclass_basics.lean | 类型类定义与实例 |
| | operator_overloading.lean | 操作符重载 |
| | typeclass_inheritance.lean | 类型类继承 |
| 05_propositions | logic_connectives.lean | 逻辑连接词 |
| | quantifiers.lean | 全称与存在量词 |
| | equality.lean | 等式推理 |
| | calc_proofs.lean | calc 计算证明 |
| 06_tactics | basic_tactics.lean | intro, exact, apply, have, rw |
| | induction.lean | 归纳证明 |
| | cases.lean | cases 分情况 |
| | simp_norm_num.lean | simp 和 norm_num 战术 |
| 07_structures | basic_structures.lean | 结构基础 |
| | structure_update.lean | 结构更新与继承 |
| | pattern_matching_struct.lean | 结构模式匹配 |
| 08_modules_projects | namespaces.lean | 命名空间 |
| | sections_variables.lean | section 与 variable |

### 第二部分：Mathlib4（32 个文件）

| 目录 | 文件 | 描述 |
|------|------|------|
| 09_mathlib_algebra | semigroups.lean | 半群 |
| | monoids.lean | 幺半群 |
| | groups.lean | 群，abel 战术 |
| | rings.lean | 环，ring 战术 |
| | fields.lean | 域，field_simp 战术 |
| 10_mathlib_number_theory | divisibility.lean | 整除关系 |
| | gcd.lean | 最大公约数 |
| | primes.lean | 素数 |
| | modeq.lean | 同余与模运算 |
| | fermat_little.lean | 费马小定理 |
| 11_mathlib_analysis | real_numbers.lean | 实数 |
| | absolute_value.lean | 绝对值 |
| | limits.lean | 数列与函数极限 |
| | continuity.lean | 连续函数 |
| | derivatives.lean | 导数 |
| 12_mathlib_topology | topological_spaces.lean | 拓扑空间 |
| | metric_spaces.lean | 度量空间 |
| | compactness.lean | 紧性 |
| 13_mathlib_linear_algebra | modules.lean | 模与向量空间 |
| | linear_maps.lean | 线性映射 |
| | matrices.lean | 矩阵 |
| | determinant.lean | 行列式 |
| 14_mathlib_combinatorics | finsets.lean | 有限集合 |
| | big_operators.lean | 求和与求积 |
| | binomial.lean | 二项式系数 |
| | pigeonhole.lean | 鸽巢原理 |
| 15_mathlib_measure_probability | measurable_spaces.lean | 可测空间 |
| | measures.lean | 测度 |
| | probability.lean | 概率测度 |
| 16_advanced_tactics | ring_tactic.lean | ring 战术 |
| | linarith_tactic.lean | linarith 战术 |
| | norm_num_tactic.lean | norm_num 战术 |
| | aesop_tactic.lean | aesop 战术 |
| | omega_tactic.lean | omega 战术 |
| | positivity_tactic.lean | positivity 战术 |
| | nlinarith_tactic.lean | nlinarith 战术 |

## 常用命令

```bash
# 查看 Lean 版本
lean --version

# 查看 elan 已安装版本
elan show

# 初始化新项目
lake init my_project

# 构建项目
lake build

# 清理构建
lake clean

# 获取 mathlib 缓存
lake exe cache get

# 运行单个文件
lake env lean path/to/file.lean
```

## 学习资源

- **Lean 4 手册**: https://leanprover.github.io/lean4/doc/
- **Mathlib4 文档**: https://leanprover-community.github.io/mathlib4_docs/
- **Theorem Proving in Lean 4**: https://leanprover.github.io/theorem_proving_in_lean4/
- **Mathematics in Lean**: https://leanprover-community.github.io/mathematics_in_lean/
- **Lean Zulip**: https://leanprover.zulipchat.com/
