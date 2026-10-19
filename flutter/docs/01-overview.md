# 01 · Flutter 全景：一套代码，多端一致

## 1.1 Flutter 是什么

Flutter 是 Google 的跨平台 UI 框架：一套 Dart 代码，编译出 Windows/macOS/Linux/iOS/Android/Web 全平台应用。它和"跨平台"前辈们的根本区别在渲染路线——**自带图形引擎自绘界面**：

| 路线 | 代表 | 界面怎么来 | 一致性 |
|---|---|---|---|
| 原生桥接 | React Native、早期 Xamarin | JS/C# 描述 → 映射原生控件 | 跟随各平台，常有不一致 |
| WebView 套壳 | Cordova、Electron（DOM） | 网页装进容器 | 一致但性能受限 |
| **自绘引擎** | **Flutter** | Skia/Impeller 直接画像素 | **像素级一致**，不依赖平台控件 |

自绘的代价是"每个控件都得自己画"，收益是"画出来的就是全部"——按钮、滚动、动画在 Windows 和手机上分毫不差，且没有"桥接层"的性能税。

### Impeller：3.47 的默认渲染器

Flutter 的图形引擎经历两代：Skia（通用 2D 库）和 **Impeller**（Flutter 团队自研，3.10 起在 iOS 默认，3.27 起全平台默认）。Impeller 的关键改进：**在编译期把着色器（shader）准备好**——Skia 时代的"首帧卡顿/着色器编译抖动"（runtime shader compilation jank）在 Impeller 下基本消失。对开发者的意义：不用管渲染后端，`flutter run` 出来的就是 Impeller 渲染的结果；性能调优时知道瓶颈在"Widget 重建"还是"raster 线程"即可（第 25 章）。

## 1.2 三层架构：Framework / Engine / Embedder

```text
┌────────────────────────────────────────┐
│ Framework（Dart）                       │  Widget/Material/Cupertino 组件库
│   ← 你写的代码在这层，全部是 Dart        │
├────────────────────────────────────────┤
│ Engine（C++）                           │  Impeller 渲染、Dart VM、文本排版
├────────────────────────────────────────┤
│ Embedder（各平台宿主）                   │  Windows 的 Win32 窗口、输入事件循环
└────────────────────────────────────────┘
```

对日常开发的含义：**你只写 Dart**；窗口、事件泵、GPU 上下文由 Embedder 打理——这就是为什么同一份 `main.dart` 能跑在桌面和手机上。遇到"平台特有"问题（窗口标题、输入法）才会碰到边界（第 18 章）。

### Binding 体系：框架的"总电源"

Flutter 框架不是单一对象，而是一组 **Binding**（胶水层）的协作——每个 Binding 负责一个底层领域：

| Binding | 职责 |
|---|---|
| `GestureBinding` | 手势识别（指针事件 → 手势） |
| `SchedulerBinding` | 帧调度（vsync、定时任务） |
| `PaintingBinding` | 图片缓存、着色器预热 |
| `ServicesBinding` | 平台消息通道（MethodChannel 的底层） |
| `WidgetsBinding` | Widget 树、焦点、生命周期通知 |
| `RenderingBinding` | RenderObject 树的绘制调度 |

`WidgetsFlutterBinding.ensureInitialized()` 在 `runApp` 前把所有 Binding 拉起来——自定义 `main()`（比如插件要在 runApp 前初始化）时这行不能少：

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // 拉起全部 Binding
  await SomePlugin.init();                     // 现在可以调平台通道了
  runApp(const MyApp());
}
```

## 1.3 一切皆 Widget：先立好心智模型

Flutter 的世界观只有一条：**界面是 Widget 树，Widget 是不可变配置**。`Text('你好')` 不是"一个文本控件"，而是"一段如何画文本的描述"；数据变了不是改控件，而是**用新配置重新描述**，框架 diff 前后两棵树，只更新差异（第 03 章展开）。

这条规矩解释了后面所有章的写法：为什么改 UI 全靠 `setState`（08 章）、为什么主题切换是换一棵 `ThemeData` 配置（16 章）、为什么动画是"配置值随时间变"（15 章）。

### 三棵树的对应关系

| 层 | 对象 | 生命周期 | 职责 |
|---|---|---|---|
| Widget | `Text`/`Container`/... | 临时（每帧可重建） | 配置描述（"要什么"） |
| Element | `StatefulElement`/`StatelessElement` | 长期（随树结构） | 实例化对应物（"谁在哪"） |
| RenderObject | `RenderParagraph`/`RenderBox`... | 长期 | 布局与绘制（"实际怎么画"） |

Widget 的 `createElement()` 建 Element；Element 的 `mount()` 建 RenderObject（需要绘制的 Widget 才有）。日常开发 95% 的时间只碰 Widget 层——Element/RenderObject 是框架实现细节，但理解它们解释了"为什么重建 Widget 很便宜"（只换配置，Element/RenderObject 复用）和"为什么 State 能存活"（State 挂在 Element 上，不随 Widget 重建）。

## 1.4 与 Dart 教程的衔接

本教程**不重讲 Dart 语言**——需要时链接过去：

| 本教程用到 | 在哪章 |
|---|---|
| 命名参数 `{required this.x}`（Flutter API 的主流形态） | [Dart 教程·第 05 章](../dart/docs/05-functions.md) |
| `Future`/`async`/`await`（一切 IO） | [Dart 教程·第 15 章](../dart/docs/15-async.md) |
| `fromJson/toJson` 模板（网络与持久化） | [Dart 教程·第 18 章](../dart/docs/18-files-json-http.md) |
| sealed 类、模式匹配（状态建模） | [Dart 教程·第 13 章](../dart/docs/13-records-patterns.md) |
| 空安全操作符（到处都是 `?`） | [Dart 教程·第 10 章](../dart/docs/10-null-safety.md) |

## 1.5 工具链速查

| 命令 | 用途 |
|---|---|
| `flutter create --platforms=windows <名>` | 新建工程（只生成 Windows 平台目录） |
| `flutter run -d windows` | 运行（热重载：改完保存即生效，`r` 重载 / `R` 热重启） |
| `flutter analyze` | 静态检查（flutter_lints，IDE 同款） |
| `flutter test` | 跑 widget 测试（秒级，不需要真窗口） |
| `flutter build windows --debug/--release` | 构建 Windows 可执行文件 |
| `flutter pub get / add <包>` | 依赖管理 |
| `flutter clean` | 清理构建产物（首跑变慢，慎用） |
| `flutter doctor` | 环境体检（SDK/IDE/设备连接） |
| `flutter devices` | 列出可用设备（Windows/macOS/Chrome/手机） |
| `flutter logs` | 查看设备日志 |

本机 SDK：`G:\scoop\apps\flutter\current\bin\flutter.bat`（3.47.4，内嵌 Dart 3.13.3）。

### 版本管理：Flutter 的发布节奏

Flutter 采用**季度稳定版**节奏：每年 2/5/8/11 月各一个大版本（如 3.44/3.47/3.50），大版本间有补丁版（3.47.1/3.47.2...）。版本号语义：`3.47.4` = 大版本.小版本.补丁。升级：

```bash
flutter upgrade          # 升 stable 最新
flutter channel stable   # 确认在 stable 渠道（beta/master 不推荐生产）
```

`pubspec.yaml` 的 `environment.sdk` 约束 Dart 版本——Flutter 升级会带 Dart 一起升，不需要单独管 Dart SDK。

## 1.6 工程解剖：flutter create 产物

```text
my_app/
├── lib/main.dart        ← 你的全部世界（入口）
├── test/                ← widget 测试
├── pubspec.yaml         ← 依赖与资源声明
├── analysis_options.yaml← lint 配置（flutter_lints）
└── windows/             ← 桌面宿主工程（CMake/runner，一般不动）
```

与纯 Dart 工程的两点差异：依赖多了 `flutter: sdk: flutter`（SDK 内依赖的写法）；资源（图片/字体）必须**在 pubspec 里声明**才会打进产物。生成物纪律：`build/`、`.dart_tool/`、`windows/flutter/ephemeral/` 一律不提交（create 自带的 .gitignore 已覆盖，本仓库还全局忽略 `pubspec.lock`）。

### pubspec.yaml 关键字段

```yaml
name: my_app
description: 应用描述
publish_to: 'none'          # 应用工程不发布；插件包才填 pub.dev
version: 1.0.0+1            # 版本+构建号（Android 的 versionCode 用 + 后数字）

environment:
  sdk: ^3.13.3              # Dart SDK 约束

dependencies:
  flutter:
    sdk: flutter            # Flutter SDK 内依赖
  http: ^1.2.0              # 生态包（caret 约束：兼容 1.x 最新）

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0     # lint 规则集

flutter:
  uses-material-design: true
  assets:                   # 资源声明（不声明打不进包）
    - images/
    - fonts/MyFont.ttf
```

`^1.2.0` 的 caret 约束 = "兼容 1.2.0 的最高 1.x"——`pub get` 解析到 1.x 最新。要锁死版本去掉 caret 写死 `1.2.0`。

## 1.7 本教程的工作流与验证

每章三步：**读讲解 → `cd examples/NN_name && flutter run -d windows` 跑起来 → 改代码看热重载**。批量验证用构建脚本（**须 pwsh 7**，含中文无 BOM）：

```powershell
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                  # 全量：31 工程 pub get + analyze + test；02/20/27/31_plugin 额外 windows 构建
pwsh -ExecutionPolicy Bypass -File build.ps1 -Project 06_material  # 单工程全流程（含构建）
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean                # 清理全部构建产物
```

## 1.8 32 章路线图

| 阶段 | 章 | 你将获得 |
|---|---|---|
| 入门 | 02 hello · 03 Widget · 04/05 布局 · 06 Material · 07 交互 | 能搭出静态界面并响应点击 |
| 状态与数据 | 08 有状态 · 09 状态共享 · 10 导航 · 11 表单 · 12 列表 | 能写出多页面有数据的应用 |
| 异步与打磨 | 13 网络 · 14 异步 UI · 15 动画 · 16 主题 · 17 持久化 | 应用接近可交付 |
| 毕业实战 | 18 桌面专题 · 19 测试 · 20 实战记事本 | 桌面交付 + 测试 + 完整小应用 |
| 进阶篇（21+） | 21 调试 · 22 集中状态 · 23 认证 · 24 媒体选取 | 工程硬功夫：让代码可维护、可发布 |
| 进阶篇（25+） | 25 性能 · 26 Cupertino 自适应 · 27 平台通道 · 28 移动发布 | 优化、跨脸、直通原生、上架闭环 |
| 进阶篇（29+） | 29 滚动进阶与页面事件 · 30 国际化 | Sliver 拼装、返回拦截、事件广播、多语言 |
| 进阶篇（31+） | 31 插件开发 · 32 IM 界面实战 | 可复用通道包、完整应用拼装毕业 |

## 坑位清单

- **热重载不是万能**：改 `main()` 入口、全局函数、常量值需要热重启（`R`）；改 native 侧（windows/）要完全停掉重跑。
- **flutter clean 是核选项**：清完全部工程要重新 `pub get` + 全量构建——只在依赖解析错乱/磁盘空间告急时用。
- **create 工程名含大写/连字符**：Flutter 包名规范是小写+下划线——`flutter create my_app` 对，`flutter create My-App` 会警告并自动规范化。
- **pubspec.lock 提交与否**：应用工程提交（锁版本可复现）；库/插件包不提交（让使用者解析）——本仓库全局忽略是历史决定，应用工程建议提交。
- **Windows 构建前置**：需要 Visual Studio"使用 C++ 的桌面开发"组件（不是 VS Code）；缺它 `flutter build windows` 直接报错。
---

下一章：[02 · 第一个应用：从 create 到热重载](02-hello.md) ｜ 返回：[README](../README.md)
