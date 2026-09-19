# Coq 教程示例集

本目录按 `guide` 统一结构组织 Coq 教程与可验证示例。教程正文见
[COQ编程指南.md](./COQ编程指南.md)（25 章；扩充中，当前完成第 1–10 章）。

## 目录结构

```text
coq/
├── README.md
├── COQ编程指南.md
├── build.ps1
└── examples/
    ├── 01_intro.v
    ├── 02_toolchain.v
    ├── 03_first_proof.v
    ├── 04_types.v
    ├── 05_expressions.v
    ├── 06_tuples_records.v
    ├── 07_patterns.v
    ├── 08_lists.v
    ├── 09_inductive.v
    └── 10_fixpoint.v
```

## 工具链

- Coq: `G:\scoop\apps\coq\current`（8.20.1）
- 编译器: `G:\scoop\apps\coq\current\bin\coqc.exe`

## 编译验证

```powershell
cd G:\code\guide\coq
.\build.ps1 -All
```

单文件：

```powershell
.\build.ps1 -File 03_first_proof.v
```

清理：

```powershell
.\build.ps1 -Clean
```
