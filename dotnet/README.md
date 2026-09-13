# .NET 编程指南示例集

本目录已按 `guide` 统一标准整理为“教程文档 + 独立示例工程 + 构建脚本”结构。

## 目录结构

```text
dotnet/
├── README.md
├── DOTNET编程指南.md
├── SAMPLES_MIGRATION_MAP.md
├── build.ps1
├── examples/
│   ├── 01_hello_console/
│   ├── 02_types_control/
│   ├── 03_linq_basics/
│   ├── 04_records_pattern/
│   ├── 05_generics_extensions/
│   ├── 06_error_handling/
│   ├── 07_file_json/
│   ├── 08_async_await/
│   ├── 09_parallel_tasks/
│   ├── 10_span_memory/
│   ├── 11_collections_mapped/
│   ├── 12_minimal_api_mapped/
│   ├── 13_efcore_mapped/
│   ├── 14_testing_mapped/
│   └── 15_new_features_mapped/
├── advanced/
├── samples/
└── CHEATSheet.md
```

说明：
- `examples/` 是可直接编译验证的标准示例工程目录。
- `SAMPLES_MIGRATION_MAP.md` 记录 `samples/` 到 `examples/` 的映射关系。
- `advanced/`、`samples/`、`CHEATSheet.md` 保留为扩展阅读资料。

## 构建工具链

- .NET SDK：`G:\scoop\apps\dotnet-sdk\current\dotnet.exe`

## 编译验证

```powershell
cd G:\code\guide\dotnet
.\build.ps1 -All
```

单工程编译：

```powershell
.\build.ps1 -Project 08_async_await
```

清理：

```powershell
.\build.ps1 -Clean
```
