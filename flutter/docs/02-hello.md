# 02 · 第一个应用：从 create 到热重载

> 对应示例：examples/02_hello/

## 2.1 解决什么问题

任何 Flutter 之旅的第一站都是三个问题：工程从哪来、程序从哪开始、改了代码怎么见效。本章用最小可运行的应用把这条链路打通，并建立"两层外壳"（MaterialApp + Scaffold）的肌肉记忆——之后每个应用都是这个形状。

创建工程：

```bash
cd examples
flutter create --project-name hello_app --platforms=windows 02_hello
```

一个马上会撞上的细节：**目录名可以 `02_hello`（数字开头），包名不行**——Dart 包名必须是合法标识符，所以用 `--project-name hello_app` 分开指定。这也是本教程"章号=目录号"约定的实现方式。

## 2.2 runApp：把 Widget 树挂到屏幕

```dart
// ═══ 2.1 runApp：把 widget 树挂到屏幕 ═══
class HelloApp extends StatelessWidget {
  const HelloApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ═══ 2.2 MaterialApp 与 Scaffold：应用外壳与页面骨架 ═══
    return MaterialApp(
      title: 'Hello Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const HelloPage(),
    );
  }
}
```

`void main() => runApp(const HelloApp())` 是固定开场。`runApp` 做三件事：

1. 确保 `WidgetsFlutterBinding` 已初始化（拉起全部 Binding，见第 01 章）
2. 把传入的 Widget **inflate**（展开成 Element 树）
3. attach 到平台 view——Windows 上就是那个 Win32 窗口

`runApp` 之后框架接管：build → layout → paint 的循环开始运转。注意 HelloApp 的三个习惯：`const` 构造（复用实例）、`super.key`（Widget 身份标识，lint 强制）、`build` 方法（描述长什么样）。

### runApp 只能调一次吗

`runApp` 可以再次调用（比如动态换根 Widget），框架会像 setState 一样 diff 新旧树——但正常应用从不这么干。`main()` 里一次 `runApp` 是标准形状。

### MaterialApp / WidgetsApp / CupertinoApp 三层

| 组件 | 职责 | 什么时候用 |
|---|---|---|
| `WidgetsApp` | 最基础的应用壳：Navigator、Localizations、文字方向 | 不用 Material/Cupertino 主题的自定义框架 |
| `MaterialApp` | WidgetsApp + Material Design 主题 + Scaffold 体系 | **跨平台默认选择**（本教程全程） |
| `CupertinoApp` | WidgetsApp + iOS 风格主题 | 纯 iOS 应用（第 26 章） |

MaterialApp 是**应用级外壳**，管三件事：`title`（任务栏/切换器显示名）、`theme`（全局主题，第 16 章展开；`ColorScheme.fromSeed` 用一颗种子色生成整套色板）、`home`（首页是谁）。完整参数面在第 10 章（路由相关）和第 16 章（主题相关）展开。

## 2.3 Scaffold：页面骨架的插槽

```dart
    // ═══ 2.3 页面骨架：AppBar + body + FAB ═══
    return Scaffold(
      appBar: AppBar(title: const Text('Hello Flutter')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('你好，Flutter！', style: TextStyle(fontSize: 24)),
            SizedBox(height: 8),
            Text('改这行代码，保存后热重载即可见效'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.waving_hand),
      ),
    );
```

Scaffold 把一屏拆成**插槽**：`appBar`（顶栏）、`body`（主内容）、`floatingActionButton`（右下角悬浮按钮）、`drawer`（抽屉）、`bottomNavigationBar`（底部导航，第 06 章逐个讲）。你不需要自己摆位置——塞进对应插槽即可。body 里的 `Center > Column > Text × 2` 是布局组合的第一课，第 04/05 章展开。

顺带三个惯性写法：能 `const` 的地方全部 `const`（编译期固定，跳过无谓重建）；`SizedBox(height: 8)` 是标准间隙；`onPressed: () {}` 空回调表示"可点但没行为"（`null` 才是禁用，第 07 章）。

### 这段代码背后的三棵树

第 01 章的三棵树模型在这 20 行代码里全部出现：`HelloApp`/`HelloPage`（Widget，配置）→ 框架为它们建 `StatelessElement`（Element，实例）→ `Text`/`Center`/`Column` 对应的 `RenderParagraph`/`RenderPositionedBox`/`RenderFlex`（RenderObject，实际布局绘制）。你写的是 Widget 配置，框架在背后维护 Element 和 RenderObject——改 Widget 重建时，Element/RenderObject 尽量复用，只更新差异。

## 2.4 热重载工作流：本教程的节奏

跑起来（`flutter run -d windows`，或 IDE 的运行按钮），然后**改 `Text` 里的字，Ctrl+S**——界面瞬间更新，这就是热重载（hot reload，终端里 `r`）。它的边界要心里有数：

| 改动 | 热重载 | 热重启（`R`） | 停掉重跑 |
|---|---|---|---|
| build 里的 UI/样式 | ✅ | ✅ | ✅ |
| State 字段增删、方法签名 | ❌ | ✅ | ✅ |
| main()、全局变量初值、const 值 | ❌ | ✅ | ✅ |
| pubspec 依赖、windows/ 原生代码 | ❌ | ❌ | ✅ |

热重载的原理：Dart VM 用新代码替换旧代码的函数体，**State 对象原样保留**（第 08 章详解）——所以计数器/输入框的值在热重载后不丢。热重启（`R`）重建 Widget 树，State 重置。日常就是"改完保存看效果"，卡住了按 `R`。这个迭代节奏是 Flutter 开发体验的核心——本教程每章都靠它。

## 2.5 工程自带的测试怎么跑

create 出的工程自带 `test/widget_test.dart`（我们每章都重写成覆盖本章行为的测试）。跑法：

```bash
cd examples/02_hello
flutter test                       # 全部
flutter test --plain-name "首页渲染"  # 单个
```

widget 测试跑在 flutter_tester 虚拟环境里——**不需要真窗口、秒级完成**，这就是本教程 build.ps1 敢对 19 个工程全量跑测试的原因（第 19 章专门讲怎么写）。02 章的测试长这样：

```dart
  testWidgets('首页渲染标题与提示', (tester) async {
    await tester.pumpWidget(const HelloApp());
    expect(find.text('Hello Flutter'), findsOneWidget); // AppBar 标题
    expect(find.text('你好，Flutter！'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
```

读法：pumpWidget 渲染一帧 → find 找 Widget → expect 断言。先会读，第 19 章教写。

## 2.6 第一个应用的常见微调

### 改窗口标题和大小（Windows）

窗口标题默认取 `MaterialApp.title`，但 Windows 的窗口标题在原生侧 `windows/runner/main.cpp` 里：

```cpp
// windows/runner/main.cpp
Win32Window window;
window.Create(L"hello_app", origin, size);  // 第一个参数是窗口标题
```

初始窗口大小在同文件的 `size` 变量（`const SIZE size{1280, 720}`）。改完要**完全停掉重跑**（原生侧不走热重载）。

### 改应用图标

Windows 图标在 `windows/runner/resources/app_icon.ico`——替换这个文件重新构建即可。多分辨率图标（16/32/48/256）用一个 ico 文件打包。

### debug 横幅

`MaterialApp` 右上角黄色的 "DEBUG" 横幅在 release 模式自动消失；开发期想关掉传 `debugShowCheckedModeBanner: false`。

## 坑位清单

- **`const` 漏写的连锁反应**：`children: [Text('a')]` 不报错但每次重建都新建实例；lint（prefer_const）会提醒——本教程标准是 analyze 零告警。
- **桌面文本默认不可选**：桌面用户习惯选中复制，`Text` 默认不行——第 18 章 SelectionArea 解决。
- **设备列表**：`flutter devices` 看可运行目标；`-d windows` 明确指定桌面，避免开成浏览器。
- **中文乱码**：Windows 老终端（PowerShell 5.1）按 ANSI 读无 BOM 文件会把中文源码读烂——一律 pwsh 7（仓库全局约定）。
- **改了 main.cpp 热重载无效**：原生侧改动必须停掉重跑——`r`/`R` 都只覆盖 Dart 侧。
---

上一章：[01 · Flutter 全景：一套代码，多端一致](01-overview.md) ｜ 下一章：[03 · Widget：不可变的配置树](03-widgets.md) ｜ 返回：[README](../README.md)
