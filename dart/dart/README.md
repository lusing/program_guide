# Dart 开发指南示例工程

该目录用于存放 `Dart开发指南.md` 中的可运行源码，并提供统一编译验证入口。

## 目录结构

- `examples/`：从指南中提取的 Dart 示例源码（`00_hello.dart` ~ `12_json_file_io.dart`）
- `test/guide_examples_test.dart`：指南中的测试示例
- `build.ps1`：编译与测试脚本
- `build/`：编译产物输出目录（`.exe`）

## 编译与验证

```powershell
# 编译全部示例
.\build.ps1 -All

# 编译单个示例
.\build.ps1 -File 03_functions.dart

# 运行测试
.\build.ps1 -Test
```
