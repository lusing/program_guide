# Rust 编程指南示例集

本目录按 `guide` 统一结构组织 Rust 教程与可验证示例。

## 目录结构

```text
rust/
├── README.md
├── Rust编程指南.md
├── build.ps1
└── examples/
    ├── 01_hello.rs
    ├── 02_variables_types.rs
    ├── 03_control_flow.rs
    ├── 04_functions.rs
    ├── 05_ownership_borrowing.rs
    ├── 06_structs_impl.rs
    ├── 07_enums_match.rs
    ├── 08_collections.rs
    ├── 09_strings.rs
    ├── 10_error_handling.rs
    ├── 11_generics_traits.rs
    ├── 12_lifetimes.rs
    ├── 13_modules.rs
    ├── 14_iterators.rs
    ├── 15_closures.rs
    ├── 16_concurrency_threads.rs
    ├── 17_channels.rs
    ├── 18_file_io.rs
    ├── 19_tests_style.rs
    └── 20_macro_pattern.rs
```

## 构建工具链

- Rust 安装目录：`G:\scoop\apps\rust\current`
- 编译器：`G:\scoop\apps\rust\current\bin\rustc.exe`

## 编译/验证

```powershell
cd G:\code\guide\rust
.\build.ps1 -All
```

单文件：

```powershell
.\build.ps1 -File 08_collections.rs
```

清理：

```powershell
.\build.ps1 -Clean
```

