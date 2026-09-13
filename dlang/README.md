# D 语言编程指南示例集

本目录按 `guide` 的统一结构组织 D 语言教程与可编译示例。

## 目录结构

```text
dlang/
├── README.md
├── D语言编程指南.md
├── build.ps1
└── examples/
    ├── 01_hello.d
    ├── 02_types_control.d
    ├── 03_functions_slices.d
    ├── 04_structs_ufcs.d
    ├── 05_templates_generics.d
    ├── 06_ranges_algorithms.d
    ├── 07_error_handling_scope.d
    ├── 08_concurrency.d
    └── 09_unittest.d
```

## 构建工具链

- DMD: `G:\scoop\apps\dmd\current\windows\bin64\dmd.exe`

## 编译验证

```powershell
cd G:\code\guide\dlang
.\build.ps1 -All
```

单文件编译：

```powershell
.\build.ps1 -File 06_ranges_algorithms.d
```

清理：

```powershell
.\build.ps1 -Clean
```

