# 01 · Dart 全景：为 UI 而生、为全平台而长

## 1.1 Dart 是什么

Dart 是 Google 在 2011 年发布的语言，如今由 Google 与社区共同维护。它的定位一句话就能说清：**客户端优先（client-optimised）的语言**——为构建界面而进化，但纯 Dart 的命令行工具、脚本和服务端程序同样是一等公民。Flutter 框架用它写 iOS/Android/桌面/Web 的界面，本教程只用纯 Dart 打底：语言机制学会了，Flutter 只是"再学一个库"。

一个最小的 Dart 程序长这样（引用 `examples/02_hello.dart` 的 2.1 段）：

```dart
// ═══ 2.1 main：唯一入口 ═══
// 参数列表可省略；需要命令行参数时声明为 List<String>（args 不含程序名）
void main(List<String> args) {
  // …
}
```

如果你会 Java/C#/JavaScript/Python 中的任何一门，这个形状都不陌生——Dart 刻意做了"多数程序员一看就懂"的语法表层，而把心思花在你看不见的地方：类型系统、编译管线和异步模型。

## 1.2 编译模型：一套语言，多个后端

Dart 代码不绑定单一运行方式，这是它最独特的工程决策：

| 模型 | 命令 | 特点 | 适用 |
|---|---|---|---|
| JIT（即时编译） | `dart run` | 启动快、支持热重载、运行时略慢 | 开发调试 |
| AOT（提前编译） | `dart compile exe` | 生成单文件原生可执行文件，启动毫秒级 | 发布交付 |
| Web | `dart compile js` / Wasm | 编译为 JavaScript / WebAssembly | 浏览器 |

关键承诺是**两套编译器语义一致**：开发时 JIT 跑对的程序，AOT 发布后行为不变。这不是所有动态语言都能做到的——Dart 从类型系统层面为这个承诺买了保险。

## 1.3 Dart 与 Flutter 的关系

一句话分层：**Flutter 是框架，Dart 是语言**。Flutter 的界面树、状态管理都是 Dart 代码，所以 Dart 的语言特性经常是"为 Flutter 量身定做"的：

- 命名参数让 Flutter API 天然自文档（第 05 章）；
- 集合字面量的 if/for 让界面构建像写声明（第 06 章）；
- `extends Widget` + mixin 组合出组件体系（第 08/09 章）；
- async/await 支撑一切 IO 与动画（第 15/16 章）。

本教程止步于纯 Dart；UI 开发见仓库的 flutter 教程，那里的每一章都建立在本教程之上。

## 1.4 工具链速查

| 命令 | 用途 |
|---|---|
| `dart run <file>` | 直接运行脚本（JIT） |
| `dart analyze` | 静态分析，检查错误与代码风格（IDE 同款引擎） |
| `dart format .` | 按官方风格格式化代码 |
| `dart compile exe <file>` | 编译为原生可执行文件（AOT） |
| `dart pub get` / `add` | 拉取 / 添加 `pubspec.yaml` 声明的依赖 |
| `dart test` | 运行单元测试 |
| `dart create -t console <名字>` | 脚手架新建工程 |
| `dart doc` | 生成 API 文档 |

## 1.5 pub 生态：pubspec.yaml 是包的身份

Dart 的包仓库是 [pub.dev](https://pub.dev)，包身份由 `pubspec.yaml` 描述：

```yaml
name: dart_guide      # 包名（snake_case）
environment:
  sdk: ^3.13.0        # SDK 版本约束，^ 表示 >=3.13.0 <4.0.0
dependencies:         # 运行时依赖
dev_dependencies:     # 只在开发/测试期需要的依赖（如 test、lints）
```

`dart pub get` 解析依赖后生成 `.dart_tool/`（已忽略，不入库）。两个经验：**版本约束用 `^`**（允许补丁与小版本升级）；**测试、lint 类工具进 dev_dependencies**（发布时不算依赖）。

## 1.6 本教程的工作流

每章的学法固定三步：**读讲解 → 跑示例 → 改代码再跑**。

```bash
cd /path/to/dart          # 进入本教程根目录（Windows: cd G:\code\guide\dart）
dart run examples/03_variables.dart    # 单跑某个示例
```

全量验证用构建脚本（macOS/Linux 用 `build.sh`，Windows 用 `build.ps1`，后者须 pwsh 7——脚本含中文无 BOM，Windows PowerShell 5.1 会误读）：

```bash
./build.sh --all                             # 全量：analyze + 运行 + AOT + 测试
./build.sh --file 06_collections.dart        # 单示例
./build.sh --project 20_todo                 # 嵌套工程（含测试）
./build.sh --test                            # 根包 analyze + test
```

Windows 等效命令：

```powershell
pwsh -ExecutionPolicy Bypass -File build.ps1 -All
pwsh -ExecutionPolicy Bypass -File build.ps1 -File 06_collections.dart
pwsh -ExecutionPolicy Bypass -File build.ps1 -Project 20_todo
pwsh -ExecutionPolicy Bypass -File build.ps1 -Test
```

行为分级：02–18 章的单文件示例实际运行；02_hello 额外 AOT 编译验证；19/20 章的完整工程跑 `dart test`，20 章再以演示序列运行。

## 1.7 20 章学习路线图

| 阶段 | 章 | 你将获得 |
|---|---|---|
| 入门 | 02 hello · 03 变量 · 04 控制流 · 05 函数 · 06 集合 | 能读写日常 Dart 代码 |
| 类型系统 | 07 类 · 08 继承接口 · 09 mixin 修饰符 · 10 空安全 · 11 泛型 · 12 异常 · 13 记录模式 · 14 扩展 | 理解 Dart 类型设计的原因 |
| 异步与并发 | 15 Future · 16 Stream · 17 Isolate | 掌握 Dart 的并发模型 |
| 生态实战 | 18 文件 JSON HTTP · 19 测试 · 20 实战待办 | 能交付完整命令行工具 |

## 坑位清单

- **PowerShell 5.1 乱码（仅 Windows）**：本仓库脚本与示例输出都含中文，Windows 上一律用 pwsh 7；旧版 PowerShell 按 ANSI 读无 BOM 文件会把中文读烂。macOS/Linux 终端默认 UTF-8，无此问题。
- **`dart run` 首次较慢**：会先做依赖解析与 JIT 预热，不是卡死；AOT 后的程序没有这个延迟。
- **别用 `dart file.dart` 直接跑带 package 依赖的文件**：依赖解析需要 `dart run` 的工程上下文（本教程 02–18 章示例零依赖，两种方式等价，但习惯统一用 `dart run`）。
- **`dart analyze` 比 IDE 更严**：本教程标准是零告警，命令行以它为准。
