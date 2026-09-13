# Coq 教程示例集

本目录按 `guide` 统一结构组织 Coq 教程与可验证示例。

## 目录结构

```text
coq/
├── README.md
├── COQ编程指南.md
├── build.ps1
└── examples/
    ├── 01_basics.v
    ├── 02_induction.v
    ├── 03_lists.v
    ├── 04_bool_nat.v
    ├── 05_records.v
    ├── 06_option.v
    ├── 07_higher_order.v
    ├── 08_logic.v
    └── 09_modules.v
```

## 工具链

- Coq: `G:\scoop\apps\coq\current`
- 编译器: `G:\scoop\apps\coq\current\bin\coqc.exe`

## 编译验证

```powershell
cd G:\code\guide\coq
.\build.ps1 -All
```

单文件：

```powershell
.\build.ps1 -File 03_lists.v
```

清理：

```powershell
.\build.ps1 -Clean
```

