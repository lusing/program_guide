# 01 · Flutter 全景：一套代码，多端一致

## 1.1 Flutter 是什么

Flutter 是 Google 的跨平台 UI 框架：一套 Dart 代码，编译出 Windows/macOS/Linux/iOS/Android/Web 全平台应用。它和"跨平台"前辈们的根本区别在渲染路线——**自带图形引擎自绘界面**：

| 路线 | 代表 | 界面怎么来 | 一致性 |
|---|---|---|---|
| 原生桥接 | React Native、早期 Xamarin | JS/C# 描述 → 映射原生控件 | 跟随各平台，常有不一致 |
| WebView 套壳 | Cordova、Electron（DOM） | 网页装进容器 | 一致但性能受限 |
| **自绘引擎** | **Flutter** | Skia/Impeller 直接画像素 | **像素级一致**，不依赖平台控件 |

自绘的代价是"每个控件都得自己画"，收益是"画出来的就是全部"——按钮、滚动、动画在 Windows 和手机上分毫不差，且没有"桥接层"的性能税。

## 1.2 三层架构：Framework / Engine / Embedder

```text
┌────────────────────────────────────────┐
│ Framework（Dart）                       │  Widget/Material/Cupertino 组件库
│   ← 你写的代码在这层，全部是 Dart        │
├────────────────────────────────────────┤
│ Engine（C++）                           │  Skia/Impeller 渲染、Dart VM、文本排版
├────────────────────────────────────────┤
│ Embedder（各平台宿主）                   │  Windows 的 Win32 窗口、输入事件循环
└────────────────────────────────────────┘
```

对日常开发的含义：**你只写 Dart**；窗口、事件泵、GPU 上下文由 Embedder 打理——这就是为什么同一份 `main.dart` 能跑在桌面和手机上。遇到"平台特有"问题（窗口标题、输入法）才会碰到边界（第 18 章）。

## 1.3 一切皆 Widget：先立好心智模型

Flutter 的世界观只有一条：**界面是 Widget 树，Widget 是不可变配置**。`Text('你好')` 不是"一个文本控件"，而是"一段如何画文本的描述"；数据变了不是改控件，而是**用新配置重新描述**，框架 diff 前后两棵树，只更新差异（第 03 章展开）。

这条规矩解释了后面所有章的写法：为什么改 UI 全靠 `setState`（08 章）、为什么主题切换是换一棵 `ThemeData` 配置（16 章）、为什么动画是"配置值随时间变"（15 章）。

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

本机 SDK：`G:\scoop\apps\flutter\current\bin\flutter.bat`（3.47.4，内嵌 Dart 3.13.3）。

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

## 1.7 本教程的工作流与验证

每章三步：**读讲解 → `cd examples/NN_name && flutter run -d windows` 跑起来 → 改代码看热重载**。批量验证用构建脚本（**须 pwsh 7**，含中文无 BOM）：

```powershell
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                  # 全量：19 工程 pub get + analyze + test；02/20 额外 windows 构建
pwsh -ExecutionPolicy Bypass -File build.ps1 -Project 06_material  # 单工程全流程（含构建）
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean                # 清理全部构建产物
```

## 1.8 20 章路线图

| 阶段 | 章 | 你将获得 |
|---|---|---|
| 入门 | 02 hello · 03 Widget · 04/05 布局 · 06 Material · 07 交互 | 能搭出静态界面并响应点击 |
| 状态与数据 | 08 有状态 · 09 状态共享 · 10 导航 · 11 表单 · 12 列表 | 能写出多页面有数据的应用 |
| 异步与打磨 | 13 网络 · 14 异步 UI · 15 动画 · 16 主题 · 17 持久化 | 应用接近可交付 |
| 交付 | 18 桌面专题 · 19 测试 · 20 实战记事本 | 构建、测试、发布完整闭环 |

## 坑位清单

- **热重载不是万能**：改 `main()` 入口、全局函数、常量值需要热重启（`R`）；改 native 侧（windows/）要完全停掉重跑。
- **flutter clean 慎用**：清空缓存后首次构建回到几分钟；增量构建才是日常（本仓库 build.ps1 特意不做 clean）。
- **生成物别提交**：`build/`、`ephemeral/`、`.idea/`、`*.iml`、`pubspec.lock`——旧工程就是教训。
- **Windows 构建前置**：需要 Visual Studio"使用 C++ 的桌面开发"组件（不是 VS Code）；缺它 `flutter build windows` 直接报错。
