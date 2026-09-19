# Dart 语言开发指南

面向**会编程、初学 Dart** 的读者：重点是 Dart 3 的语言机制、类型系统与异步/并发模型。主线 Dart SDK 3.13，章节与示例一一对应，每章"读讲解 → 跑示例 → 改代码再跑"。（UI 开发见仓库的 [flutter](../flutter) 教程。）

## 目录结构

```text
dart/
├── README.md               本文件
├── docs/                   20 章教程（01 → 20 顺序阅读）
├── examples/               17 个单文件示例 + 19_testing/、20_todo/ 两个完整工程
├── test/                   根包行为验证测试（12 例）
├── build.sh                统一构建脚本（macOS / Linux）
├── build.ps1               统一构建脚本（Windows，须 pwsh 7）
├── pubspec.yaml            根包（dev: lints, test）
└── CHEATSheet.md           语法速查
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 平台全景](docs/01-overview.md) | JIT/AOT 编译模型、工具链、pub | — |
| [02 第一个程序](docs/02-hello.md) | main、print、插值、两种运行方式 | `examples/02_hello.dart` |
| [03 变量与内置类型](docs/03-values.md) | 一切皆对象、const/final、dynamic | `examples/03_variables.dart` |
| [04 控制流](docs/04-control-flow.md) | switch 语句 → switch 表达式 | `examples/04_control_flow.dart` |
| [05 函数](docs/05-functions.md) | 参数三形态、闭包、一等公民 | `examples/05_functions.dart` |
| [06 集合](docs/06-collections.md) | List/Set/Map、集合 if/for、Iterable | `examples/06_collections.dart` |
| [07 类与对象](docs/07-classes.md) | 构造函数六形态、==、运算符重载 | `examples/07_classes.dart` |
| [08 继承与接口](docs/08-inheritance.md) | extends、abstract、implicit interface | `examples/08_inheritance.dart` |
| [09 Mixin 与类修饰符](docs/09-mixins-modifiers.md) | 线性化、sealed/base/final/interface | `examples/09_mixins_modifiers.dart` |
| [10 空安全](docs/10-null-safety.md) | ?./??/!、类型提升、late | `examples/10_null_safety.dart` |
| [11 泛型](docs/11-generics.md) | 约束、协变边界、reified | `examples/11_generics.dart` |
| [12 异常](docs/12-exceptions.md) | Error vs Exception 分界 | `examples/12_exceptions.dart` |
| [13 记录与模式匹配](docs/13-records-patterns.md) | record、解构、模式族谱、穷尽 | `examples/13_records_patterns.dart` |
| [14 扩展](docs/14-extensions.md) | extension、extension type、typedef | `examples/14_extensions.dart` |
| [15 Future](docs/15-async.md) | async/await、并行、事件循环 | `examples/15_async.dart` |
| [16 Stream](docs/16-streams.md) | async*、广播流、StreamController | `examples/16_streams.dart` |
| [17 Isolate](docs/17-isolates.md) | 消息传递、Isolate.run、spawn | `examples/17_isolates.dart` |
| [18 文件 JSON HTTP](docs/18-files-json-http.md) | dart:io 三件套、自测型 HttpServer | `examples/18_files_json_http.dart` |
| [19 测试](docs/19-testing.md) | package:test、可测试的设计 | `examples/19_testing/` |
| [20 实战：待办管理器](docs/20-todo.md) | 建模、解析、持久化、测试 | `examples/20_todo/` |

## 构建工具链

- Dart SDK：运行 `which dart`（macOS/Linux）或 `where dart`（Windows）确认路径（需 3.13+，详见[第 01 章](docs/01-overview.md)）
- macOS / Linux 用 `./build.sh`；Windows 用 `pwsh build.ps1`（须 pwsh 7，脚本含中文无 BOM，Windows PowerShell 5.1 会误读）

## 编译验证

macOS / Linux：

```bash
./build.sh --all                             # 全量：analyze + 运行全部示例 + AOT + 测试
./build.sh --file 06_collections.dart        # 运行单个示例
./build.sh --project 20_todo                 # 验证嵌套工程（含测试与演示序列）
./build.sh --test                            # 根包 analyze + test
./build.sh --clean                           # 清理 build 与 .dart_tool
```

Windows（须 pwsh 7）：

```powershell
pwsh -ExecutionPolicy Bypass -File build.ps1 -All
pwsh -ExecutionPolicy Bypass -File build.ps1 -File 06_collections.dart
pwsh -ExecutionPolicy Bypass -File build.ps1 -Project 20_todo
pwsh -ExecutionPolicy Bypass -File build.ps1 -Test
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean
```

行为分级：02–18 章单文件示例实际运行；02_hello 额外 AOT 编译验证；19/20 章完整工程跑 `dart test`，20 章再以演示序列运行（add/list/done/remove）。

单跑某个示例（第 02 章起的标准学法）：

```bash
dart run examples/06_collections.dart
```
