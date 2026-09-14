# Flutter 开发指南

## 1. 什么是 Flutter

Flutter 是 Google 推出的跨平台 UI 框架，用于创建高性能、可定制、跨平台的桌面和移动应用。它基于 Dart 语言，主要特点包括：

- 跨平台：一套代码可同时服务于移动端、桌面端和 Web
- 高性能：直接使用 Skia 图形引擎渲染
- 组件化：从基础控件到复杂布局均由 Widget 组装而成
- 热重载：适合快速迭代和 UI 调试

本教程的重点是：

- Flutter 工程结构
- Widget 和布局
- StatefulWidget 管理状态
- 事件和交互
- 桌面端编译验证

---

## 2. 本地工具链

本机安装路径：

- Flutter：`G:\scoop\apps\flutter\current\bin\flutter.bat`
- Dart：`G:\scoop\apps\flutter\current\bin\dart.bat`

环境验证命令：

```powershell
& 'G:\scoop\apps\flutter\current\bin\flutter.bat' --version
```

桌面端编译示例：

```powershell
cd G:\code\guide\flutter\examples\01_hello
& 'G:\scoop\apps\flutter\current\bin\flutter.bat' build windows --debug
```

---

## 3. 一个最小 Flutter 应用

一个最小 Flutter 应用通常由以下几部分组成：

```text
my_app/
├── lib/
│   └── main.dart
├── pubspec.yaml
├── analysis_options.yaml
└── test/
```

最简的 `main.dart`：

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Hello Flutter')),
        body: const Center(child: Text('Hello, Flutter!')),
      ),
    );
  }
}
```

这表明 Flutter 的核心思路：

- `runApp()` 启动应用
- `MaterialApp` 提供 Material 设计环境
- `Scaffold` 组织页面骨架
- `Widget` 负责 UI 结构与样式

---

## 4. 示例一：Hello Flutter

第一个示例展示最基础的 Flutter 页面：

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const HelloFlutterApp());
}

class HelloFlutterApp extends StatelessWidget {
  const HelloFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hello Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HelloPage(),
    );
  }
}

class HelloPage extends StatelessWidget {
  const HelloPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('01_hello')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flutter_dash, size: 72, color: Colors.blue),
            SizedBox(height: 16),
            Text('Hello, Flutter!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('这是第一个 Flutter 示例。'),
          ],
        ),
      ),
    );
  }
}
```

这个例子强调：

- Flutter 页面由组件树构成
- `StatelessWidget` 适合纯展示界面
- `Scaffold` 是最常用的页面容器

---

## 5. 布局系统：Row / Column / Stack

Flutter 很擅长布局。常见布局元素包括：

- `Row`：横向排列
- `Column`：纵向排列
- `Stack`：层叠布局
- `Expanded`：在可用空间中扩展
- `Padding`：内边距
- `SizedBox`：固定尺寸

简单的纵向布局：

```dart
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: const [
    Text('标题'),
    SizedBox(height: 12),
    Text('副标题'),
    ElevatedButton(onPressed: null, child: Text('按钮')),
  ],
)
```

像网页和桌面应用一样，Flutter 通过树状布局系统组合每一层组件。

---

## 6. 示例二：布局示例

第二个示例展示基础布局与卡片式 UI：

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const LayoutDemoApp());
}

class LayoutDemoApp extends StatelessWidget {
  const LayoutDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Layout Demo',
      theme: ThemeData(useMaterial3: true),
      home: const LayoutPage(),
    );
  }
}

class LayoutPage extends StatelessWidget {
  const LayoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('02_layout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Card(
              child: ListTile(
                leading: Icon(Icons.info),
                title: Text('布局示例'),
                subtitle: Text('使用 Row、Column 和 Card 组织内容'),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                Chip(label: Text('A')),
                Chip(label: Text('B')),
                Chip(label: Text('C')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

学习重点：

- `Card` 用于展示一组信息
- `ListTile` 常用于列表项
- `Row` 和 `Column` 让内容按需排列
- `Padding` 和 `SizedBox` 给布局留白

---

## 7. 状态管理：StatefulWidget

当界面必须在用户交互后更新时，需要使用 `StatefulWidget`。例如：

```dart
class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int count = 0;

  void increment() {
    setState(() {
      count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('点击次数：$count'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

核心点：

- `StatefulWidget` 保存可变状态
- `setState()` 通知 Flutter 重新构建界面
- 交互事件和 UI 更新紧密结合

---

## 8. 示例三：状态示例

第三个示例演示一个最简单的计数器：

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const CounterApp());
}

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'State Demo',
      theme: ThemeData(useMaterial3: true),
      home: const CounterPage(),
    );
  }
}

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int count = 0;

  void increment() {
    setState(() {
      count += 1;
    });
  }

  void decrement() {
    setState(() {
      count -= 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('03_state')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('当前计数：', style: TextStyle(fontSize: 24)),
            Text('$count', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: decrement,
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  onPressed: increment,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

这说明了最基础的 UI 交互模型：

- 用户点击事件
- 事件触发状态修改
- `setState()` 重新渲染界面

---

## 9. 实战建议

如果你想继续学习 Flutter，建议按以下顺序：

1. 先做 `01_hello`，理解 `MaterialApp` 与 `Scaffold`
2. 再看 `02_layout`，感受 `Column` / `Row` / `Card`
3. 再做 `03_state`，理解 `StatefulWidget`
4. 接着学习表单、导航、列表、异步与 API 请求
5. 最后进入桌面端/移动端的真实应用开发

---

## 10. 结论

Flutter 的学习难点不在语法，而在“把 UI 组件构造成一棵树”。一旦掌握了：

- Widget
- Layout
- State
- Event
- Build

你就已经具备了构建现代应用界面的基础能力。

为了保证本仓库的统一标准，每个示例都以独立项目目录形式保留，且通过真实的 Flutter 桌面编译命令验证。你可以继续扩展组件、导航、表单和状态管理章节。 

---

## 11. 本仓库中可用的命令

```powershell
cd G:\code\guide\flutter
.\build.ps1 -All
```

单个示例：

```powershell
.\build.ps1 -Project 02_layout
```

清理输出：

```powershell
.\build.ps1 -Clean
```

这样既满足本仓库的统一标准，也能确保每个 Flutter 示例都经过真实编译验证。
