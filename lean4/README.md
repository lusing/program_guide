# Lean 4 / Mathlib4 教程示例集

本目录按 `guide` 统一标准整理：教程文档、独立示例源码、统一构建验证脚本。

## 目录结构

```text
lean4/
├── README.md
├── lean4-mathlib4-tutorial.md
├── build.ps1
├── lakefile.lean
├── lean-toolchain
├── Lean4Tutorial.lean
├── Lean4Tutorial/
│   └── Examples/
└── examples/
    ├── 00_verified/
    │   ├── 01_nat_basics.lean
    │   ├── 02_functions.lean
    │   ├── ...
    │   └── 10_mathlib_number_theory.lean
    ├── 01_basics/
    ├── 02_inductive_types/
    ├── 03_pattern_matching/
    ├── 04_typeclasses/
    ├── 05_propositions/
    ├── 06_tactics/
    ├── 07_structures/
    ├── 08_modules_projects/
    ├── 09_mathlib_algebra/
    ├── 10_mathlib_number_theory/
    ├── 11_mathlib_analysis/
    ├── 12_mathlib_topology/
    ├── 13_mathlib_linear_algebra/
    ├── 14_mathlib_combinatorics/
    ├── 15_mathlib_measure_probability/
    └── 16_advanced_tactics/
```

说明：
- `examples/00_verified/` 是当前默认编译验证集合（与 `build.ps1 -All` 对齐）。
- 默认 `-All` 会先校验纯 Lean4 示例；含 Mathlib 的 `09/10` 可用 `-WithMathlib` 显式启用。
- `examples/` 其他编号目录保留为历史扩展素材（可用 `-All -LegacyAll` 全量尝试校验）。
- `Lean4Tutorial/Examples/` 提供与 Lake 模块名一致的镜像结构，便于模块化导入。

## 工具链

- Lean/Lake：`g:\lean\bin\lake.exe`（或已在 PATH 中的 `lake`）
- Toolchain：`leanprover/lean4:v4.33.1`（见 `lean-toolchain`）
- Mathlib4（本地源码）：`G:\github\lang\mathlib4`

## 编译验证

```powershell
cd G:\code\guide\lean4
.\build.ps1 -All
```

包含 Mathlib 示例：

```powershell
.\build.ps1 -All -WithMathlib
```

单文件校验：

```powershell
.\build.ps1 -File 00_verified\09_mathlib_ring.lean
```

清理：

```powershell
.\build.ps1 -Clean
```

历史示例全量校验（可能较慢、并可能因旧 API 失败）：

```powershell
.\build.ps1 -All -LegacyAll
```
