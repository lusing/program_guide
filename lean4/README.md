# Lean 4 / Mathlib4 教程示例集

本目录按 `guide` 统一标准整理：教程文档、独立示例源码、统一构建验证脚本。

## 目录结构

```text
lean4/
├── README.md
├── lean4-mathlib4-tutorial.md     # 教程主文档（20 章 + 附录）
├── build.ps1                      # 构建验证脚本
├── lakefile.lean
├── lean-toolchain                 # leanprover/lean4:v4.34.0
├── Lean4Tutorial.lean             # 库根模块
├── Lean4Tutorial/
│   └── Examples/                  # Lake 模块镜像（与 examples/ 章节文件同步生成）
└── examples/
    ├── 00_verified/               # 独立验证集（快速冒烟）
    ├── 01_basics/basics.lean              # 第 2 章 基础类型与函数
    ├── 02_inductive_types/universes.lean  # 第 3 章 依赖类型与宇宙
    ├── 02_inductive_types/inductive_types.lean  # 第 4 章 归纳类型
    ├── 03_pattern_matching/pattern_matching.lean # 第 5 章 模式匹配与递归
    ├── 04_typeclasses/typeclasses.lean    # 第 6 章 类型类
    ├── 05_propositions/propositions.lean  # 第 7 章 命题与证明
    ├── 06_tactics/tactics.lean            # 第 8 章 战术基础
    ├── 07_structures/structures.lean      # 第 9 章 结构与记录
    ├── 08_modules_projects/modules.lean   # 第 10 章 项目管理与模块系统
    ├── 09_mathlib_algebra/algebra.lean    # 第 12 章 代数结构
    ├── 10_mathlib_number_theory/number_theory.lean # 第 13 章 数论（含 Euclid、√2 案例）
    ├── 11_mathlib_analysis/analysis.lean  # 第 14 章 实分析（含 IVT 案例）
    ├── 12_mathlib_topology/topology.lean  # 第 15 章 拓扑学
    ├── 13_mathlib_linear_algebra/linear_algebra.lean # 第 16 章 线性代数（含 Cayley-Hamilton）
    ├── 14_mathlib_combinatorics/combinatorics.lean   # 第 17 章 组合数学
    ├── 15_mathlib_measure_probability/measure_probability.lean # 第 18 章 测度与概率
    ├── 16_advanced_tactics/advanced_tactics.lean      # 第 19 章 常用高级战术
    └── 17_workflow/workflow.lean          # 第 20 章 定理检索与工作流
```

说明：
- `lean4-mathlib4-tutorial.md` 是主文档；每个章节的代码块与上述章节文件一一对应，全部编译验证通过。
- `build.ps1 -All` 校验 `00_verified` + 教程章节文件的纯 Lean 部分；`-WithMathlib` 追加含 Mathlib 的章节（第 12-20 章对应文件）。
- `Lean4Tutorial/Examples/` 是章节文件的 Lake 模块镜像（模块名见各文件头注释），`lake build` 递归构建全部模块。
- `examples/` 中其他历史文件（basic_types.lean 等旧命名）保留为扩展素材，不在默认验证集内（可用 `-All -LegacyAll` 全量尝试，旧 API 可能失效）。

## 工具链

- Lean/Lake：`g:\lean\bin\lake.exe`（elan shim，或已在 PATH 中的 `lake`）
- Toolchain：`leanprover/lean4:v4.34.0`（见 `lean-toolchain`）
- Mathlib4（本地源码，path 依赖）：`G:\github\lang\mathlib4`（master@2026-09）
- 依赖锁定：`lake-manifest.json` 中 8 个 git 依赖的 rev 与 mathlib4 仓库的锁定一致

## 编译验证

```powershell
cd G:\code\guide\lean4
.\build.ps1 -All                # 00_verified + 章节文件（纯 Lean 部分）
.\build.ps1 -All -WithMathlib   # 含 Mathlib 章节一并校验
lake build                      # 递归构建 Lean4Tutorial 镜像库（全部模块）
```

单文件校验：

```powershell
.\build.ps1 -File 09_mathlib_algebra\algebra.lean
```

清理：

```powershell
.\build.ps1 -Clean
```

历史示例全量扫描（可能较慢、并可能因旧 API 失败）：

```powershell
.\build.ps1 -All -LegacyAll
```

## 升级到 v4.34.0 的注意事项

- mathlib4 于 2026-08 将 `Mathlib.Data.Real.Basic` 等迁移到 `Mathlib.Basic.Real.Basic`（旧模块保留 deprecated 重导出）；2026-09-15 批量删除了 2021~2026-02 的废弃声明（如 `add_left_neg` → `neg_add_cancel`）。
- 大算子绑定符由 `∑ i in s` 改为 `∑ i ∈ s`。
- `simp_arith` 已废弃（改用 `simp +arith` 或 `omega`）；`refine'` 由 `refine` 取代。
- 教程代码已全部按新 API 校准；镜像库通过 `globs := #[.submodules `Lean4Tutorial]` 递归构建。
