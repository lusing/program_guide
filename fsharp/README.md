# F# 编程指南示例集

本目录按照 `guide` 统一标准整理为“教程文档 + 独立示例项目 + 构建脚本”的结构，便于在本机 .NET SDK 上实际编译与验证 F# 代码。

## 目录结构

```text
fsharp/
├── README.md
├── F#编程指南.md
├── build.ps1
├── examples/
│   ├── 01_hello_console/
│   │   ├── 01_hello_console.fsproj
│   │   └── Program.fs
│   ├── 02_basic_types/
│   │   ├── 02_basic_types.fsproj
│   │   └── Program.fs
│   ├── 03_functions_and_patterns/
│   │   ├── 03_functions_and_patterns.fsproj
│   │   └── Program.fs
│   ├── 04_records_and_discriminated_unions/
│   │   ├── 04_records_and_discriminated_unions.fsproj
│   │   └── Program.fs
│   ├── 05_collections_and_linq/
│   │   ├── 05_collections_and_linq.fsproj
│   │   └── Program.fs
│   ├── 06_async_and_file_io/
│   │   ├── 06_async_and_file_io.fsproj
│   │   └── Program.fs
│   ├── 07_winforms/
│   │   ├── 07_winforms.fsproj
│   │   └── Program.fs
│   └── 08_wpf/
│       ├── 08_wpf.fsproj
│       └── Program.fs
└── build/
```

## 构建工具链

- .NET SDK：`G:\scoop\apps\dotnet-sdk\current\dotnet.exe`

## 编译与验证

```powershell
cd G:\code\guide\fsharp
.\build.ps1 -All
```

单个示例：

```powershell
.\build.ps1 -Project 03_functions_and_patterns
```

清理：

```powershell
.\build.ps1 -Clean
```

## 说明

- F# 是一门函数式优先的 .NET 语言，适合数据处理、数值计算、脚本、后端服务和 Windows 桌面应用开发。
- 本目录使用 .NET SDK 直接编译 F# Console、WinForms 和 WPF 项目，确保示例在本机环境中真实可编译。
- 例子覆盖了基础语法、函数、模式匹配、记录类型、联合类型、集合、异步 I/O，以及 WinForms / WPF 桌面界面开发的核心模式。
