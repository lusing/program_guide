# Flutter 开发指南

面向**会编程、已具备 Dart 基础** 的读者：重点是 Widget 体系、布局、状态管理与桌面交付。主线 Flutter 3.47（Material 3、Windows 桌面验证），章节与示例工程一一对应，每章"读讲解 → `flutter run -d windows` 跑起来 → 改代码看热重载"。Dart 语言请先读 [Dart 教程](../dart/README.md)——本教程只讲框架层。

## 目录结构

```text
flutter/
├── README.md           本文件
├── docs/               20 章教程（01 → 20 顺序阅读）
├── examples/           19 个独立 Flutter 工程（章号 = 目录号）
├── build.ps1           统一构建脚本（须 PowerShell 7 / pwsh 运行）
└── CHEATSheet.md       Widget/命令速查
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 平台全景](docs/01-overview.md) | 三层架构、工具链、与 Dart 教程衔接 | — |
| [02 第一个应用](docs/02-hello.md) | create、runApp、Scaffold、热重载 | `examples/02_hello` |
| [03 Widget 基础](docs/03-widgets.md) | 不可变配置、组合优于继承 | `examples/03_widgets` |
| [04 布局 I](docs/04-layout-single.md) | Container/Padding/Align/装饰 | `examples/04_layout_single` |
| [05 布局 II](docs/05-layout-multi.md) | Row/Column/Expanded/Stack | `examples/05_layout_multi` |
| [06 Material 组件库](docs/06-material.md) | Scaffold 六插槽、按钮家族 | `examples/06_material` |
| [07 交互与对话框](docs/07-interaction.md) | 手势、Dialog/SnackBar/Sheet | `examples/07_interaction` |
| [08 有状态 Widget](docs/08-stateful.md) | setState、生命周期、controller | `examples/08_stateful` |
| [09 状态提升与共享](docs/09-state-sharing.md) | 提升、ChangeNotifier、Inherited | `examples/09_state_sharing` |
| [10 导航与路由](docs/10-navigation.md) | push/pop、传参、命名路由 | `examples/10_navigation` |
| [11 表单](docs/11-forms.md) | Form、validator、焦点链 | `examples/11_forms` |
| [12 列表与滚动](docs/12-lists.md) | ListView.builder、GridView、Sliver | `examples/12_lists` |
| [13 网络与 JSON](docs/13-http-json.md) | http 包、fromJson、依赖注入 | `examples/13_http_json` |
| [14 异步 UI](docs/14-async-ui.md) | FutureBuilder/StreamBuilder 三态 | `examples/14_async_ui` |
| [15 动画](docs/15-animation.md) | 隐式、Hero、AnimationController | `examples/15_animation` |
| [16 主题与响应式](docs/16-theme.md) | fromSeed、深浅切换、LayoutBuilder | `examples/16_theme` |
| [17 数据持久化](docs/17-persist.md) | prefs、文件、测试两层法 | `examples/17_persist` |
| [18 桌面专题](docs/18-desktop.md) | 菜单栏、构建与发布 | `examples/18_desktop` |
| [19 Widget 测试](docs/19-testing.md) | testWidgets、finders、假时钟 | `examples/19_testing` |
| [20 实战：记事本](docs/20-notes.md) | 列表/编辑/持久化/主题/测试 | `examples/20_notes` |

## 构建工具链

- Flutter SDK：`G:\scoop\apps\flutter\current\bin\flutter.bat`（3.47.4，内嵌 Dart 3.13.3）
- 构建脚本须 **pwsh 7** 运行（含中文无 BOM，Windows PowerShell 5.1 会误读）
- Windows 构建需 Visual Studio"使用 C++ 的桌面开发"组件

## 编译验证

```powershell
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                  # 全量：19 工程 pub get + analyze + test；02_hello/20_notes 额外 windows 构建
pwsh -ExecutionPolicy Bypass -File build.ps1 -Project 06_material  # 单工程全流程（含 windows 构建）
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean                # 各工程 flutter clean + 清根 build
```

行为分级：全部工程 analyze 零告警 + widget 测试全绿；02_hello 与 20_notes 通过 `flutter build windows --debug` 实际构建。

单跑某个示例（第 02 章起的标准学法）：

```bash
cd examples/06_material
flutter run -d windows
```
