# Swift 编程指南示例集

本目录按 `guide` 的统一结构组织 Swift 教程与可编译示例。

## 目录结构

```text
swift/
├── README.md
├── Swift编程指南.md
├── build.ps1
└── examples/
    ├── 01_hello.swift
    ├── 02_types_control.swift
    ├── 03_functions_collections.swift
    ├── 04_struct_enum_protocol.swift
    ├── 05_generics_extensions.swift
    ├── 06_error_handling.swift
    ├── 07_optionals_result.swift
    ├── 08_concurrency_asyncawait.swift
    ├── 09_file_io_json.swift
    └── 10_testing_cli.swift
```

## 构建工具链

- Swift 编译器根目录：`G:\scoop\apps\swift\current`
- 默认使用：`G:\scoop\apps\swift\current\Toolchains\usr\bin\swiftc.exe`

## 编译验证

```powershell
cd G:\code\guide\swift
.\build.ps1 -All
```

单文件编译：

```powershell
.\build.ps1 -File 08_concurrency_asyncawait.swift
```

清理：

```powershell
.\build.ps1 -Clean
```

