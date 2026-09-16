# flutter 教程重写设计（2026-09-17）

## 1. 背景与问题

`flutter/` 目录现状：单文件 `Flutter开发指南.md`（424 行，代码堆砌浅讲）+ 3 个玩具示例工程
（01_hello/02_layout/03_state，每个只有 lib/main.dart 一个源文件）。与今天完成的
fsharp/dotnet/dart 教程标准（docs/ 分章 + 章号=示例 + 概念小节讲解 + 坑位清单）差距大。
另有工程卫生问题：旧工程把 `windows/flutter/ephemeral/`、`.idea/`、`*.iml`、`pubspec.lock`
等生成物/IDE 文件跟踪进了 git（18 个/工程），磁盘 build 产物合计 1.6GB。

## 2. 目标与非目标

**目标**：重写为 20 章独立文档（每章 100–200 行）、章号 = 示例工程号（02–20 共 19 个
flutter create 工程）；Dart 语言内容一律交叉引用刚完成的 Dart 教程（`../dart/docs/`），
不重写；全部工程 `flutter analyze` 零告警、`flutter test` 全绿；02_hello 与 20_notes
通过 `flutter build windows --debug` 实际构建；第 20 章为实战记事本应用。

**非目标**：
- 不重写 Dart 语言知识（命名参数、Future、JSON 解析等链接 Dart 教程对应章）
- 不面向零基础读者（起点是"会编程 + 已读 Dart 教程或等价"）
- 不做 iOS/Android/Web 端专题（主线 Windows 桌面，多平台一句话带过）
- 不引社区状态管理包（provider/Riverpod/BLoC 只在第 09 章尾做选型纵览）
- 第三方包仅限第一方：`http`、`shared_preferences`（flutter.dev 维护）

## 3. 已确认决策

| 决策点 | 结论 |
|---|---|
| 章节规模 | 20 章 + 实战记事本 |
| Dart 内容 | 交叉引用 `../dart/docs/NN-*.md`，零重写 |
| 示例形态 | 每章独立完整工程（`flutter create --platforms=windows`），生成物全不跟踪 |
| 验证策略 | analyze + test 全量；windows --debug 构建抽查（02_hello、20_notes）；去 flutter clean 用增量 |
| 主线版本 | Flutter 3.47.4 stable（Dart 3.13.3、Material 3 默认、flutter_lints） |
| 旧文件 | 删 `Flutter开发指南.md` 与旧 3 个示例工程；重写 README、build.ps1；新增 CHEATSheet |

## 4. 章节结构（docs/，20 章）

| # | 文件 | 主题 | 示例工程 | Dart 教程引用 |
|---|---|---|---|---|
| 01 | `01-overview.md` | 平台全景：Flutter 三层架构、widget 树心智模型、工具链（run/build/analyze/test）、与 Dart 教程衔接 | —（引用 02_hello） | 01 |
| 02 | `02-hello.md` | 第一个应用：flutter create、runApp/MaterialApp/Scaffold、热重载工作流、pubspec | `02_hello` | 02 |
| 03 | `03-widgets.md` | Widget 基础：Widget=不可变配置、build(BuildContext)、组合优于继承、Text/Icon/Image | `03_widgets` | 03/07 |
| 04 | `04-layout-single.md` | 布局 I：Container/Padding/Center/Align/SizedBox、BoxDecoration 装饰 | `04_layout_single` | 03 |
| 05 | `05-layout-multi.md` | 布局 II：Row/Column、主轴/交叉轴、Expanded/Flexible、Stack/Positioned | `05_layout_multi` | — |
| 06 | `06-material.md` | Material 组件库：Scaffold（AppBar/Drawer/FAB/BottomNav）、Card/ListTile/Chip、按钮家族 | `06_material` | 08 |
| 07 | `07-interaction.md` | 交互与对话框：GestureDetector/InkWell、AlertDialog/SnackBar/BottomSheet | `07_interaction` | 05 |
| 08 | `08-stateful.md` | 有状态 Widget：setState、initState/dispose、TextEditingController、为何 build 频繁调用 | `08_stateful` | 10 |
| 09 | `09-state-sharing.md` | 状态提升与共享：提升模式、ChangeNotifier/ValueNotifier、InheritedWidget 原理、生态选型一段 | `09_state_sharing` | 14 |
| 10 | `10-navigation.md` | 导航与路由：Navigator.push/pop、MaterialPageRoute、命名路由、传参与返回值 | `10_navigation` | — |
| 11 | `11-forms.md` | 表单与输入：Form/TextFormField/校验、FocusNode、输入类型 | `11_forms` | 12 |
| 12 | `12-lists.md` | 列表与滚动：ListView（builder/分隔线）、GridView、CustomScrollView 与 Sliver 一瞥、刷新 | `12_lists` | 06 |
| 13 | `13-http-json.md` | 网络与 JSON：http 包、Future 链、fromJson 复用；示例内置本地 HttpServer 自测（零外网依赖） | `13_http_json` | 15/18 |
| 14 | `14-async-ui.md` | 异步 UI：FutureBuilder/StreamBuilder、加载/错误/空三态、避免在 build 里发请求 | `14_async_ui` | 15/16 |
| 15 | `15-animation.md` | 动画：隐式动画（AnimatedContainer 等）、Hero、显式 AnimationController 一节 | `15_animation` | — |
| 16 | `16-theme.md` | 主题与响应式：ThemeData/ColorScheme.fromSeed、深色模式、MediaQuery/LayoutBuilder/窗口适配 | `16_theme` | — |
| 17 | `17-persist.md` | 数据持久化：dart:io 文件读写、shared_preferences、路径与迁移注意 | `17_persist` | 18 |
| 18 | `18-desktop.md` | 桌面专题：Windows --debug/--release 构建、产物结构、发布打包、桌面特有交互（滚轮/菜单/窗口） | `18_desktop` | 01 |
| 19 | `19-testing.md` | Widget 测试：testWidgets、pumpWidget/pump、finders、matcher、与单元测试分层 | `19_testing` | 19 |
| 20 | `20-notes.md` | **实战**：记事本——笔记列表 + 编辑页、JSON 文件持久化、深浅主题切换、删除确认、widget 测试 | `20_notes` | 20 |

## 5. 示例工程规划

- 全部示例用 `flutter create --project-name <合法包名> --platforms=windows <NN_name>`
  生成：**目录名保留章号前缀**（`02_hello/`，章号=目录号惯例），**包名另起合法标识符**
  （`hello_app` 等——Dart 包名不能以数字开头，create 会拒绝；旧工程正是这么做的）。
  删除模板自带 test 后重写为本章测试；lib/main.dart 按章节重写（重章可拆多文件：
  lib/models.dart 等）。
- 每个工程自带 `.gitignore`（create 生成，已含 build/、.dart_tool/、ephemeral/）；
  执行时核实 ephemeral 与 .idea 均不在跟踪清单。
- 每个工程 `test/widget_test.dart` 覆盖本章核心行为（pumpWidget + finder 断言；
  交互章含 tap 后状态断言）。
- 13_http_json 示例内置 `dart:io` HttpServer（随机端口、请求后关闭，复用 Dart 教程
  18 章的自测型模式），http 包请求 localhost——不依赖外网。
- 20_notes 实战：多文件工程（lib/main.dart + notes.dart + storage.dart + theme.dart），
  功能 = 笔记列表（ListView）/新建编辑（导航）/自动保存（JSON 文件）/主题切换/删除确认，
  测试覆盖导航与持久化往返。

## 6. build.ps1 重写设计

1. **pwsh 7 运行**（中文无 BOM，与其他教程一致）。
2. flutter.bat = `G:\scoop\apps\flutter\current\bin\flutter.bat`。
3. 脚本内设 `[Console]::OutputEncoding = UTF8`。
4. `-All` 分级：逐工程 `flutter pub get` → `flutter analyze` → `flutter test`；
   抽查 `flutter build windows --debug`（02_hello、20_notes）。**不做 flutter clean**
   （增量编译，首次慢后续快）。
5. `-Project <name>`：单工程全流程（pub get + analyze + test + windows 构建）。
6. `-Clean`：清理各工程 build/、.dart_tool/ 与根 build/。
7. 预估耗时：-All 全量 10–15 分钟（首次构建 20_notes windows 部分最慢）。

## 7. 文件操作清单

| 操作 | 文件 |
|---|---|
| 删除 | `Flutter开发指南.md` |
| 删除 | `examples/01_hello`、`examples/02_layout`、`examples/03_state`（含误跟踪的 ephemeral/.idea/iml/lock） |
| 新增 | `docs/01-overview.md` … `docs/20-notes.md` 共 20 章 |
| 新增 | `examples/02_hello` … `examples/20_notes` 共 19 个工程 |
| 重写 | `README.md`（目录结构 + 20 章索引表 + 验证说明） |
| 重写 | `build.ps1`（见 §6） |
| 新增 | `CHEATSheet.md`（常用 Widget/布局心智/命令速查） |

## 8. 验证方案

1. `pwsh -ExecutionPolicy Bypass -File build.ps1 -All`：19 个工程 analyze 零告警、
   flutter test 全绿；02_hello 与 20_notes windows --debug 构建成功。
2. 每章文档代码片段与 `examples/` 工程实际内容逐字一致（按小节注释号核对）。
3. README 章节索引表与 docs/ 实际文件一一对应；抽查对 `../dart/docs/` 的交叉引用链接可达。
4. Flutter 3.47.4 实测编译通过为准；版本敏感处标注"需 Flutter 3.x"。

## 9. 风险与对策

| 风险 | 对策 |
|---|---|
| Material 3 API 变动（primarySwatch 等弃用） | 以 `flutter analyze` 零告警为准；统一 `ColorScheme.fromSeed` 风格 |
| flutter test 在无显示环境挂起 | widget 测试跑在 flutter_tester 虚拟环境，无需真实窗口；构建抽查才需要桌面（本机满足） |
| http 示例误连外网 | 内置 localhost HttpServer 自测型模式；无网络也能通过 |
| 工程生成物再次入库 | create 自带 .gitignore + 提交前 `git ls-files` 核对无 ephemeral/.idea/lock |
| -All 耗时长 | 分级验证 + 不 clean + 增量；文档标注耗时预期；-Project 单工程快速迭代 |
| shared_preferences 在 Windows 的存储位置变化 | 第 17 章以"概念 + 简单用例"为准，不承诺具体注册表路径 |
