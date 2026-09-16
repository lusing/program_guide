# dart 教程重写设计（2026-09-16）

## 1. 背景与问题

`dart/` 目录现状：单文件 `Dart开发指南.md`（1249 行，15 节）+ 嵌套 `dart/dart/`
pub 工程（13 个示例文件、build.ps1、两个浅测试）。每节结构是"2–3 句导语 + 整文件
代码贴放（50–80 行）+ 完整输出堆砌 + 3–4 条 bullet"，讲解密度远低于今天完成的
dotnet/fsharp 教程标准（概念小节 + 短代码片段 + 设计动机讲解 + 坑位清单）。

教学缺口：构造函数家族、implicit interface、mixin、类修饰符（sealed/base/final/
interface）、Stream、Isolate、测试、实战项目全部缺失或只有只言片语；现有嵌套
`dart/dart/` 布局也与 fsharp 等教程的扁平结构不一致。

## 2. 目标与非目标

**目标**：重写为 20 章独立文档（每章 100–200 行）、章号 = 示例号；讲解为主、代码
片段为辅；全部示例 `dart run` 实跑、`dart analyze` 零告警、`dart test` 通过；
第 20 章为实战收尾项目（CLI 待办管理器）。

**非目标**：
- 不做 Flutter/UI 内容（`flutter/` 目录已有专门教程）
- 主线零社区依赖：02–18 章仅标准库；19/20 章只用 `test`/`lints` 官方包
- 不面向零基础读者（起点是"会编程，初学 Dart"，与其他教程一致）

## 3. 已确认决策

| 决策点 | 结论 |
|---|---|
| 章节规模 | 扩充到 20 章，对齐 fsharp/dotnet 教程 |
| 实战项目 | 要：第 20 章 CLI 待办管理器（建模 + JSON 持久化 + 测试） |
| HTTP 内容 | 不开独立章，作为第 18 章 `dart:io` 一节（自测型示例，起服务→自请求→退出） |
| 目录布局 | 扁平化：`dart/{docs,examples,test}`，删除嵌套 `dart/dart/` |
| 读者定位 | 会编程、初学 Dart |
| 主线 SDK | Dart 3.13（实测 3.13.4，`G:\scoop\apps\dart\current\bin\dart.exe`） |
| 旧文件 | 删除 `Dart开发指南.md` 与整个 `dart/dart/` 嵌套工程；重写 README、build.ps1；新增 CHEATSheet |

## 4. 章节结构（docs/，20 章）

学习曲线：入门 → 语言核心 → 类型系统 → 异步/并发 → 生态实战。

| # | 文件 | 主题 | 示例 | 来源 |
|---|---|---|---|---|
| 01 | `01-overview.md` | 平台全景：Dart 定位与 Flutter 关系、JIT/AOT/dart2js 编译模型、SDK 与 pub 工具链 | —（引用 02_hello） | 新写（吸收旧指南 §1） |
| 02 | `02-hello.md` | 第一个程序：main、print、dart run/compile exe、analyze/format、单文件快速迭代工作流 | `02_hello.dart` | ←00_hello 扩充 |
| 03 | `03-values.md` | 变量与内置类型：var/final/const 三分、num/int/double、String 与插值、类型推断 | `03_variables.dart` | ←01_basics 扩充 |
| 04 | `04-control-flow.md` | 控制流：if/for/while、break/continue、**switch 语句 → switch 表达式（Dart 3）** | `04_control_flow.dart` | ←02_control_flow 扩充 |
| 05 | `05-functions.md` | 函数：命名参数/可选位置参数/required、箭头、闭包、函数类型与一等公民 | `05_functions.dart` | ←03_functions 扩充 |
| 06 | `06-collections.md` | 集合：List/Set/Map、字面量 + 集合 if/for、展开操作符、常用操作对比 | `06_collections.dart` | ←04_collections 扩充 |
| 07 | `07-classes.md` | 类与对象：构造函数家族（命名/重定向/工厂/初始化列表）、getter/setter、运算符重载、== 与 hashCode | `07_classes.dart` | ←05_oop 拆分扩充 |
| 08 | `08-inheritance.md` | 继承、抽象与接口：extends、abstract、**implicit interface（每个类都是接口）**、@override | `08_inheritance.dart` | ←05_oop 拆分 |
| 09 | `09-mixins-modifiers.md` **新增** | Mixin 与类修饰符：mixin/on、线性组合 vs 多继承、**sealed/base/final/interface（Dart 3）** | `09_mixins_modifiers.dart` | 新建 |
| 10 | `10-null-safety.md` | 空安全：可空类型、?./??/!、late、类型提升规则与失效场景 | `10_null_safety.dart` | ←06_null_safety 扩充 |
| 11 | `11-generics.md` | 泛型：泛型类/方法、bounds、集合协变边界、reified 类型 | `11_generics.dart` | ←07_generics 扩充 |
| 12 | `12-exceptions.md` | 异常：Error vs Exception、try/on/catch/finally、rethrow、自定义异常 | `12_exceptions.dart` | ←09_exceptions 扩充 |
| 13 | `13-records-patterns.md` | 记录与模式匹配：records、解构、switch 全模式族谱（对象/关系/逻辑/列表）、sealed 穷尽匹配 | `13_records_patterns.dart` | ←10_records_patterns 深化 |
| 14 | `14-extensions.md` | 扩展与 typedef：extension、泛型扩展、冲突解析、**extension type（Dart 3.3）** | `14_extensions.dart` | ←11_extensions 扩充 |
| 15 | `15-async.md` | Future 与 async/await：事件循环、Future API、错误处理、Future.wait | `15_async.dart` | ←08_async 拆分 |
| 16 | `16-streams.md` **新增** | Stream：单订阅 vs 广播、async*/yield、await for、StreamController、错误流 | `16_streams.dart` | 新建 |
| 17 | `17-isolates.md` **新增** | Isolate 并发：消息传递模型、Isolate.spawn、SendPort/ReceivePort、Isolate.run、何时需要 isolate | `17_isolates.dart` | 新建 |
| 18 | `18-files-json-http.md` | 文件、JSON 与 HTTP：File/Directory、dart:convert JSON 编解码、HttpServer 自测型示例 | `18_files_json_http.dart` | ←12_json_file_io 扩充 |
| 19 | `19-testing.md` **新增** | 测试：package:test、group/test/expect、常见匹配器、纯函数可测性、覆盖率 | `19_testing/`（嵌套 pub 包） | 新建 |
| 20 | `20-todo.md` | **实战**：CLI 待办管理器——sealed 命令建模、参数解析、JSON 持久化、package:test 测试 | `20_todo/`（嵌套 pub 包） | 新建 |

## 5. 示例规划

- `examples/02_hello.dart` … `examples/18_files_json_http.dart`：单文件（80–200 行），
  仅标准库，从上到下按章内小节顺序组织，输出与文档展示一致；根包 `dart run` 运行。
- `examples/19_testing/`：嵌套 pub 包（pubspec + lib + test），`dart test` 验证。
- `examples/20_todo/`：嵌套 pub 包（pubspec + bin/todo.dart + lib/ + test/），
  `dart test` + 以演示参数序列运行（add/list/done/remove，数据文件指向 build/ 下）。
- 根 `test/`：按章主题的行为验证测试（自包含，不 import 示例文件）。
- 每章文档头部标注"对应示例"，文档代码片段从示例摘录。

## 6. build.ps1 重写设计

对齐 fsharp/dotnet 分级验证模式：

1. **pwsh 7 运行**（中文无 BOM，与仓库其他教程一致）。
2. Dart 发现：优先 `G:\scoop\apps\dart\current\bin\dart.exe`，回退扫描版本目录。
3. 脚本内设 `[Console]::OutputEncoding = UTF8`（示例输出中文）。
4. `-All` 分级：根 `dart pub get` + `dart analyze` → 逐个 `dart run` 单文件示例
   （校验退出码）→ AOT 编译 02_hello 验证 `dart compile exe` 可用 → 19/20 嵌套包
   各自 `dart pub get` + `dart analyze` + `dart test` → 20 以演示序列运行 → 根
   `dart test`。
5. 参数 `-All` / `-File <name>` / `-Project <dir>`（嵌套目录）/ `-Test` / `-Clean`
   （清理 build/ 与 .dart_tool），行为与 fsharp 脚本一致。

## 7. 文件操作清单

| 操作 | 文件 |
|---|---|
| 删除 | `Dart开发指南.md` |
| 删除 | `dart/dart/` 整个嵌套工程（含 testdart.iml、lib/dart.dart、旧 examples） |
| 新增 | 根 `pubspec.yaml`（dev_deps: lints, test）+ `analysis_options.yaml` |
| 新增 | `docs/01-overview.md` … `docs/20-todo.md` 共 20 章 |
| 新增 | `examples/02…18` 单文件 + `19_testing/`、`20_todo/` 嵌套包 + 根 `test/` |
| 重写 | `README.md`（目录结构 + 20 章索引表 + 验证说明，对齐 fsharp README） |
| 重写 | `build.ps1`（见 §6） |
| 新增 | `CHEATSheet.md`（Dart 语法速查） |

## 8. 验证方案

1. `pwsh -ExecutionPolicy Bypass -File build.ps1 -All`：analyze 零告警、17 个单文件
   示例运行成功、02_hello AOT 编译成功、19/20 测试全绿、根 test 全绿。
2. 每章文档代码片段与 `examples/` 实际内容一致（写作时从示例摘录）。
3. README 章节索引表与 docs/ 实际文件一一对应。
4. 涉及版本声明的表述以 3.13.4 实测为准。

## 9. 风险与对策

| 风险 | 对策 |
|---|---|
| HttpServer/Isolate 示例挂起不退出 | 18 章绑定 `localhost` 随机端口、请求后 shutdown；17 章显式 close ReceivePort / 用 `Isolate.run`，构建脚本加超时 |
| 中文输出在 PowerShell 乱码 | build.ps1 设 UTF-8 编码；文档运行输出块仅作展示 |
| 嵌套 pub 包依赖未拉取 | 脚本对 19/20 目录先 `dart pub get` |
| `dart analyze` 对嵌套包文件误报/漏检 | 根与嵌套包分别执行 analyze |
| 类修饰符/extension type 等新特性表述过新 | 全部以 3.13.4 实测编译通过为准，版本敏感处标注"需 Dart 3.x" |
| 20_todo 演示运行污染数据文件 | 支持 `-f` 指定数据文件，脚本演示用 `build/` 下临时文件 |
