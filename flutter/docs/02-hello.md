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

`void main() => runApp(const HelloApp())` 是固定开场：`runApp` 接住一个 Widget，把它挂成界面树的根。注意 HelloApp 的三个习惯：`const` 构造（复用实例）、`super.key`（Widget 身份标识，lint 强制）、`build` 方法（描述长什么样）。

MaterialApp 是**应用级外壳**，管三件事：`title`（任务栏/切换器显示名）、`theme`（全局主题，第 16 章展开；`ColorScheme.fromSeed` 用一颗种子色生成整套色板）、`home`（首页是谁）。

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

## 2.4 热重载工作流：本教程的节奏

跑起来（`flutter run -d windows`，或 IDE 的运行按钮），然后**改 `Text` 里的字，Ctrl+S**——界面瞬间更新，这就是热重载（hot reload，终端里 `r`）。它的边界要心里有数：

| 改动 | 热重载 | 热重启（`R`） | 停掉重跑 |
|---|---|---|---|
| build 里的 UI/样式 | ✅ | ✅ | ✅ |
| State 字段增删、方法签名 | ❌ | ✅ | ✅ |
| main()、全局变量初值、const 值 | ❌ | ✅ | ✅ |
| pubspec 依赖、windows/ 原生代码 | ❌ | ❌ | ✅ |

日常就是"改完保存看效果"，卡住了按 `R`。这个迭代节奏是 Flutter 开发体验的核心——本教程每章都靠它。

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

## 坑位清单

- **`const` 漏写的连锁反应**：`children: [Text('a')]` 不报错但每次重建都新建实例；lint（prefer_const）会提醒——本教程标准是 analyze 零告警。
- **桌面文本默认不可选**：桌面用户习惯选中复制，`Text` 默认不行——第 18 章 SelectionArea 解决。
- **设备列表**：`flutter devices` 看可运行目标；`-d windows` 明确指定桌面，避免开成浏览器。
- **中文乱码**：Windows 老终端（PowerShell 5.1）按 ANSI 读无 BOM 文件会把中文源码读烂——一律 pwsh 7（仓库全局约定）。
