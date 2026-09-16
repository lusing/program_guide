# Flutter 教程重写实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 `flutter/` 从"424 行单文件 + 3 个玩具示例"重写为 20 章自学教程（docs/ 分章 + 19 个独立 Flutter 工程 + 实战记事本），Dart 语言内容交叉引用 `../dart/docs/` 不重写，全部工程 analyze 零告警、widget 测试全绿、抽查工程 windows 构建通过。

**Architecture:** 删除旧单文件指南与 3 个旧示例工程（含误跟踪的 ephemeral/.idea/iml/lock）；`examples/02…20` 每章一个 `flutter create --project-name <合法包名> --platforms=windows <NN_目录>` 完整工程（目录保留章号前缀，包名另起——Dart 包名不能数字开头）；docs/ 20 章讲解为主、widget 代码片段为辅；build.ps1（pwsh 7）分级验证：pub get + analyze + test 全量，windows --debug 构建抽查 02_hello 与 20_notes。

**Tech Stack:** Flutter 3.47.4 stable（Material 3 默认、flutter_lints）、flutter_test、第一方包 http / shared_preferences、dart:io HttpServer（13 章自测型后端）、PowerShell 7 构建脚本、Markdown。

**Spec:** `G:\code\guide\docs\superpowers\specs\2026-09-17-flutter-tutorial-rewrite-design.md`（本计划依 spec 而写，执行者两份都要读）

## Global Constraints

- 工作目录：`G:\code\guide\flutter`（bash 路径 `/g/code/guide/flutter`）；仓库根 `G:\code\guide`。
- Flutter：`G:\scoop\apps\flutter\current\bin\flutter.bat`（3.47.4，内嵌 Dart 3.13.3；build.ps1 内已硬编码，勿改）。
- **工程创建命令模板**（每个示例工程第一步，改目录名与包名）：

  ```bash
  cd /g/code/guide/flutter/examples
  "G:/scoop/apps/flutter/current/bin/flutter.bat" create --project-name <合法包名> --platforms=windows <NN_name>
  ```

  目录名 `NN_snake_case`（章号=目录号）；包名必须合法 Dart 标识符（小写下划线、
  不能数字开头）。create 生成的 `.gitignore`/`windows/.gitignore` 已覆盖
  ephemeral/.idea/.iml/build/.dart_tool；**根仓库 .gitignore 全局忽略 `**/pubspec.lock`**。
  创建后只覆写 `lib/main.dart` 与 `test/widget_test.dart`（模板 test 引用模板 MyApp，
  不覆写必挂）；模板 README/.metadata 保留不动。
- **API 风格铁律**（flutter_lints 全量约束，实测零告警的写法）：
  - 所有 Widget 构造一律带 `{super.key}`（`use_key_in_widget_constructors`）。
  - 能 const 就 const：`const Text(…)`、`children: const […]`（`prefer_const_constructors`
    / `prefer_const_literals_to_create_immutables`）。
  - 主题一律 `ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: …))`；**不用弃用的
    `primarySwatch`**、不写 `useMaterial3: true`（3.x 默认）。
  - async 回调里用过 context 前必须 `if (!context.mounted) return;`（`use_build_context_synchronously`）。
- **示例分节注释约定**：main.dart 用 `// ═══ N.M 小节名 ═══` 分节，编号与本章文档小节一致（docs 按小节号逐字摘录）。
- **widget 测试确定性铁律**：不依赖真实网络/真实时间——异步数据一律**构造注入**
  （页面收 `Future/Stream/存储` 参数，默认真实现、测试注入假实现）；真实 IO（文件往返）
  放普通 `test()`（不是 testWidgets）；SharedPreferences 用 `setMockInitialValues`。
- **Dart 语言交叉引用格式**（docs 全教程统一）：`[Dart 教程·第 N 章](../dart/docs/NN-name.md)`，
  如第 05 章函数 → `[Dart 教程·第 05 章](../dart/docs/05-functions.md)`。只链接、不重讲。
- **章节写作模板**（每章必须遵守）：
  - 文件名 `NN-kebab-case.md`；首行 `# NN · 主题：副标题`；第二行 `> 对应示例：examples/NN_name/`（01 章无此行，引用 `examples/02_hello/`）。
  - `## N.M` 编号小节；先讲"解决什么问题"再讲 API；对比用表格；结尾 `## 坑位清单`。
  - 代码片段与 examples 逐字一致（省略处标 `// …`）；每章 100–200 行；中文行文。
  - 风格范本（每章动笔前先读）：`G:\code\guide\dart\docs\05-functions.md` 与 `G:\code\guide\dart\docs\13-records-patterns.md`。
- **build.ps1 运行环境坑**：中文无 BOM，必须 pwsh 7（bash 路径 `/g/Program Files/PowerShell/7/pwsh`）。
- 构建验证命令：

  ```bash
  cd /g/code/guide/flutter && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
  ```

  单工程：`... -Project 06_material`（含 windows 构建，首次约 2–4 分钟）。
- 提交规范：`feat(flutter):` / `docs(flutter):` / `chore(flutter):` 前缀 + 中文，结尾必须带：
  `Co-Authored-By: Claude Code <noreply@anthropic.com>`
- 每个 Task 结束 `git status` 干净；**每个 Task 创建工程后须 `git ls-files` 核对无
  ephemeral/.idea/.iml/pubspec.lock 被跟踪**。

## 已核实的平台事实（执行者不得凭记忆改动）

| 事实 | 内容 | 来源 |
|---|---|---|
| SDK | **Flutter 3.47.4 stable**（2026-09-10 revision 9584c6713b；Dart 3.13.3、DevTools 2.60.0） | 2026-09-17 `flutter --version` 实测 |
| create 与目录名 | `flutter create --project-name smoke_app --platforms=windows 02_smoke` **合法**：目录可数字开头，包名不行 | /tmp/flutter_smoke 实测 |
| 模板 .gitignore | 根 .gitignore 含 .idea/、*.iml、.dart_tool/、/build/；windows/.gitignore 含 `flutter/ephemeral/` | 模板实查 |
| 仓库级忽略 | 根 .gitignore 第 30 行 `**/pubspec.lock`（全仓库不提交 lock） | git check-ignore 实测 |
| Material 3 烟测 | fromSeed/darkTheme/ListView.builder/Navigator.push/TextField/AnimatedContainer/FutureBuilder/showDialog/SnackBar/FilledButton + const 纪律：analyze 零告警（18.8s）、testWidgets 2 例全绿 | /tmp/flutter_smoke 实测 |
| widget 测试环境 | flutter_tester 无需真实窗口；analyze 约 15–20s/工程、test 约 10–30s/工程 | 实测 |
| 旧工程病灶 | 旧 3 工程跟踪了 windows/flutter/ephemeral 下 18 个生成物/工程 + .idea/iml/lock | git ls-files 实查 |
| windows 构建 | `flutter build windows --debug` 通过（`✓ Built build\windows\x64\runner\Debug\smoke_app.exe`） | /tmp/flutter_smoke 实测（2026-09-17） |

---

### Task 1: 清理旧结构

**Files:**
- Delete: `Flutter开发指南.md`、`examples/01_hello`、`examples/02_layout`、`examples/03_state`（git 跟踪的 75 个文件整体移除；磁盘上未跟踪的 build/.dart_tool/ephemeral 一并删除）

**Interfaces:**
- Produces: 干净的 `examples/` 空目录（Task 3 起逐章创建）；根仅剩 README/build.ps1 待重写。

- [x] **Step 1: 删除旧文件与工程**

```bash
cd /g/code/guide/flutter
git rm -q "Flutter开发指南.md"
git rm -q -r examples
rm -rf examples   # 清掉未跟踪的 build/.dart_tool/ephemeral 等磁盘残留（1.6GB 大头）
mkdir examples
git status --short | head -5
ls
```

预期：git status 全部为 D；目录仅剩 README.md、build.ps1、空 examples/。

- [x] **Step 2: Commit**

```bash
git add -A && git commit -m "chore(flutter): 删除旧指南与旧示例工程

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 2: build.ps1（analyze+test 全量分级，windows 构建抽查）

**Files:**
- Create: `build.ps1`

**Interfaces:**
- Produces: `-All` 全量流程（Task 16 终验依赖）：逐工程 pub get → analyze → test，抽查工程追加 `build windows --debug`；`-Project <name>` 单工程全流程（含构建）；`-Clean` 各工程 `flutter clean` + 清根 build/。

- [x] **Step 1: 写 build.ps1 全文**（保持无 BOM）

```powershell
param(
    [switch]$All,
    [string]$Project,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# 示例输出含中文：统一 UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$flutter = "G:\scoop\apps\flutter\current\bin\flutter.bat"
$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"
# windows 构建抽查名单（其余工程 analyze+test 已足够）
$buildCheck = @('02_hello', '20_notes')

if (-not (Test-Path -LiteralPath $flutter)) {
    throw "未找到 Flutter：$flutter"
}
if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录: $examplesDir"
}

function Invoke-Flutter {
    param(
        [string]$Label,
        [string[]]$ArgList,
        [string]$WorkDir = $projectRoot
    )
    Write-Host "[$Label] flutter $($ArgList -join ' ') @ $WorkDir" -ForegroundColor Cyan
    Push-Location $WorkDir
    try {
        & $flutter @ArgList
        if ($LASTEXITCODE -ne 0) {
            throw "命令失败（退出码 $LASTEXITCODE）：flutter $($ArgList -join ' ') @ $WorkDir"
        }
    } finally {
        Pop-Location
    }
}

function Invoke-Example {
    param(
        [Parameter(Mandatory = $true)][string]$DirPath,
        [switch]$WithBuild
    )
    Invoke-Flutter 'PubGet' @('pub', 'get') $DirPath
    Invoke-Flutter 'Analyze' @('analyze') $DirPath
    Invoke-Flutter 'Test' @('test') $DirPath
    if ($WithBuild) {
        Invoke-Flutter 'BuildWin' @('build', 'windows', '--debug') $DirPath
    }
}

if ($Clean) {
    $examples = Get-ChildItem -LiteralPath $examplesDir -Directory | Sort-Object Name
    foreach ($entry in $examples) {
        if (Test-Path -LiteralPath (Join-Path $entry.FullName 'pubspec.yaml')) {
            Write-Host "[Clean] $($entry.Name)" -ForegroundColor Yellow
            Push-Location $entry.FullName
            & $flutter clean | Out-Null
            Pop-Location
        }
    }
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
    }
    Write-Host "[Clean] 已清理全部工程与根 build。" -ForegroundColor Yellow
    exit 0
}

if ($Project) {
    $dir = Join-Path $examplesDir $Project
    if (-not (Test-Path -LiteralPath (Join-Path $dir 'pubspec.yaml'))) {
        throw "找不到示例工程: $dir"
    }
    Invoke-Example -DirPath $dir -WithBuild
    Write-Host "[Done] 验证通过（含 windows 构建）: $Project" -ForegroundColor Green
    exit 0
}

if ($All) {
    $examples = Get-ChildItem -LiteralPath $examplesDir -Directory | Sort-Object Name
    if ($examples.Count -eq 0) {
        throw 'examples 目录下没有示例工程。'
    }
    foreach ($entry in $examples) {
        $name = $entry.Name
        Write-Host "===== $name =====" -ForegroundColor Magenta
        Invoke-Example -DirPath $entry.FullName -WithBuild:($buildCheck -contains $name)
    }
    Write-Host '[Done] 全部工程 analyze+test 通过；抽查工程 windows 构建通过。' -ForegroundColor Green
    exit 0
}

Write-Host '用法:' -ForegroundColor Yellow
Write-Host '  .\build.ps1 -All                全量：逐工程 pub get + analyze + test；02_hello/20_notes 额外 windows 构建（首跑约 10–15 分钟）'
Write-Host '  .\build.ps1 -Project 06_material 单工程全流程（含 windows 构建）'
Write-Host '  .\build.ps1 -Clean               各工程 flutter clean + 清理根 build'
```

- [x] **Step 2: 烟测脚本**

```bash
cd /g/code/guide/flutter && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1
```

预期：无参数时打印用法（examples 为空目录，-All 会 throw 属预期，Task 3 起消失）；`-Clean` 输出"[Clean]"正常退出。

- [x] **Step 3: Commit**

```bash
git add build.ps1 && git commit -m "feat(flutter): 新 build.ps1 分级验证（analyze+test 全量、构建抽查）

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 3: 示例 02_hello / 03_widgets / 04_layout_single

**Files:**
- Create: `examples/02_hello`（包名 `hello_app`）、`examples/03_widgets`（包名 `widgets_app`）、`examples/04_layout_single`（包名 `layout_single_app`）

**Interfaces:**
- Produces: 第 02/03/04 章引用代码；02_hello 为 01 章引用对象与 windows 构建抽查对象。

- [x] **Step 1: 创建三个工程**（create 命令模板，改目录名与包名各跑三次）

```bash
cd /g/code/guide/flutter/examples
"G:/scoop/apps/flutter/current/bin/flutter.bat" create --project-name hello_app --platforms=windows 02_hello
"G:/scoop/apps/flutter/current/bin/flutter.bat" create --project-name widgets_app --platforms=windows 03_widgets
"G:/scoop/apps/flutter/current/bin/flutter.bat" create --project-name layout_single_app --platforms=windows 04_layout_single
```

- [x] **Step 2: 覆写 examples/02_hello/lib/main.dart**

```dart
import 'package:flutter/material.dart';

// 02 第一个应用：runApp、MaterialApp、Scaffold、热重载工作流
void main() => runApp(const HelloApp());

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

class HelloPage extends StatelessWidget {
  const HelloPage({super.key});

  @override
  Widget build(BuildContext context) {
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
  }
}
```

- [x] **Step 3: 覆写 examples/02_hello/test/widget_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_app/main.dart';

void main() {
  testWidgets('首页渲染标题与提示', (tester) async {
    await tester.pumpWidget(const HelloApp());
    expect(find.text('Hello Flutter'), findsOneWidget); // AppBar 标题
    expect(find.text('你好，Flutter！'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
```

- [x] **Step 4: 覆写 examples/03_widgets/lib/main.dart**

```dart
import 'package:flutter/material.dart';

// 03 Widget 基础：Widget 是不可变配置，界面靠组合而非继承
void main() => runApp(const WidgetsApp());

class WidgetsApp extends StatelessWidget {
  const WidgetsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Widget 基础')),
        // ═══ 3.3 组合优于继承：页面 = Widget 拼 Widget ═══
        body: const ListView(children: [ProfileCard(), SkillList()]),
      ),
    );
  }
}

// ═══ 3.1 StatelessWidget：纯配置，build 描述"长什么样" ═══
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    // ═══ 3.2 基础展示组件：Card/ListTile/Icon/Text/Divider ═══
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: const Text('阿 Dart'),
        subtitle: const Text('一名会写 Dart 的开发者'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class SkillList extends StatelessWidget {
  const SkillList({super.key});

  @override
  Widget build(BuildContext context) {
    const skills = ['Dart 语言', 'Widget 组合', '布局约束'];
    return Column(
      children: [
        const Divider(),
        // ═══ 3.4 const 复用：配置不可变，编译期就固定 ═══
        for (final s in skills)
          ListTile(
            dense: true,
            leading: const Icon(Icons.check_circle_outline),
            title: Text(s),
          ),
      ],
    );
  }
}
```

- [x] **Step 5: 覆写 examples/03_widgets/test/widget_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_app/main.dart';

void main() {
  testWidgets('组合渲染：卡片 + 技能条目', (tester) async {
    await tester.pumpWidget(const WidgetsApp());
    expect(find.text('阿 Dart'), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
    expect(find.text('Dart 语言'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsNWidgets(3));
  });
}
```

- [x] **Step 6: 覆写 examples/04_layout_single/lib/main.dart**

```dart
import 'package:flutter/material.dart';

// 04 布局 I：单子容器——Container/Padding/Align/SizedBox 与装饰
void main() => runApp(const LayoutSingleApp());

class LayoutSingleApp extends StatelessWidget {
  const LayoutSingleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('布局 I：容器')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            // ═══ 4.1 Padding 与 SizedBox：留白三件套 ═══
            Padding(
              padding: EdgeInsets.all(12),
              child: Text('Padding 四周留白 12'),
            ),
            SizedBox(height: 8, child: ColoredBox(color: Colors.amber)),
            // ═══ 4.2 Container：盒子模型与装饰 ═══
            BoxDemo(),
            SizedBox(height: 12),
            // ═══ 4.3 Align 与 Center：把唯一的孩子放到指定位置 ═══
            AlignDemo(),
          ],
        ),
      ),
    );
  }
}

class BoxDemo extends StatelessWidget {
  const BoxDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('box-demo'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      // ═══ 4.2（续）BoxDecoration：颜色/圆角/边框/阴影 ═══
      decoration: BoxDecoration(
        color: Colors.deepOrange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange, width: 2),
        boxShadow: const [
          BoxShadow(blurRadius: 8, offset: Offset(2, 4), color: Colors.black26),
        ],
      ),
      child: const Text('圆角 + 边框 + 阴影的 Container'),
    );
  }
}

class AlignDemo extends StatelessWidget {
  const AlignDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('align-demo'),
      height: 80,
      color: Colors.blueGrey.shade100,
      // ═══ 4.3（续）Alignment 九宫格：alignment 0.9 表示右侧 90% ═══
      child: const Align(
        alignment: Alignment(0.9, 0),
        child: Icon(Icons.arrow_circle_right),
      ),
    );
  }
}
```

- [x] **Step 7: 覆写 examples/04_layout_single/test/widget_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_single_app/main.dart';

void main() {
  testWidgets('容器与装饰渲染', (tester) async {
    await tester.pumpWidget(const LayoutSingleApp());
    expect(find.byKey(const Key('box-demo')), findsOneWidget);
    expect(find.byKey(const Key('align-demo')), findsOneWidget);
    expect(find.text('圆角 + 边框 + 阴影的 Container'), findsOneWidget);
  });
}
```

- [x] **Step 8: 验证 + 核对跟踪清单 + Commit**

```bash
cd /g/code/guide/flutter
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 02_hello
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 03_widgets 2>&1 | tail -2
```

（02_hello 含 windows 构建首次较慢；03/04 如需快速验证可手动在各工程目录跑
`flutter analyze` + `flutter test`。）

```bash
git add examples && git ls-files examples | grep -cE "ephemeral|\.idea|\.iml|pubspec.lock" || echo "生成物零跟踪 OK"
```

预期：grep 计数为 0（输出"生成物零跟踪 OK"）；analyze 无告警、测试全绿。

```bash
git commit -m "feat(flutter): 示例 02_hello/03_widgets/04_layout_single

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 4: 示例 05_layout_multi / 06_material / 07_interaction

**Files:**
- Create: `examples/05_layout_multi`（包名 `layout_multi_app`）、`examples/06_material`（包名 `material_app_demo`）、`examples/07_interaction`（包名 `interaction_app`）

**Interfaces:**
- Produces: 第 05/06/07 章引用代码。

- [x] **Step 1: 创建三个工程**

```bash
cd /g/code/guide/flutter/examples
"G:/scoop/apps/flutter/current/bin/flutter.bat" create --project-name layout_multi_app --platforms=windows 05_layout_multi
"G:/scoop/apps/flutter/current/bin/flutter.bat" create --project-name material_app_demo --platforms=windows 06_material
"G:/scoop/apps/flutter/current/bin/flutter.bat" create --project-name interaction_app --platforms=windows 07_interaction
```

- [x] **Step 2: 覆写 examples/05_layout_multi/lib/main.dart**

```dart
import 'package:flutter/material.dart';

// 05 布局 II：Row/Column、主轴与交叉轴、Expanded/Flexible、Stack
void main() => runApp(const LayoutMultiApp());

class LayoutMultiApp extends StatelessWidget {
  const LayoutMultiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('布局 II：线性与层叠')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            // ═══ 5.1 Row 与主轴排布 ═══
            AxisDemo(),
            SizedBox(height: 12),
            // ═══ 5.2 Expanded 与 Flexible：瓜分剩余空间 ═══
            ExpandDemo(),
            SizedBox(height: 12),
            // ═══ 5.3 Stack 与 Positioned：层叠布局 ═══
            StackDemo(),
          ],
        ),
      ),
    );
  }
}

class AxisDemo extends StatelessWidget {
  const AxisDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ═══ 5.1（续）spaceEvenly：均分空隙；交叉轴默认居中拉伸 ═══
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            Chip(label: Text('左')),
            Chip(label: Text('中')),
            Chip(label: Text('右')),
          ],
        ),
        const SizedBox(height: 4),
        const Text('spaceEvenly 均分空隙；交叉轴方向默认居中'),
      ],
    );
  }
}

class ExpandDemo extends StatelessWidget {
  const ExpandDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: const [
          // ═══ 5.2（续）flex 比例瓜分；Flexible 先按需后让步 ═══
          Expanded(flex: 2, child: ColoredBox(color: Colors.green, child: Center(child: Text('2 份')))),
          Expanded(flex: 1, child: ColoredBox(color: Colors.teal, child: Center(child: Text('1 份')))),
          Flexible(child: ColoredBox(color: Colors.lime, child: Center(child: Text('让')))),
        ],
      ),
    );
  }
}

class StackDemo extends StatelessWidget {
  const StackDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Stack(
        children: const [
          // ═══ 5.3（续）alignment 对齐 + Positioned 精确定位 ═══
          ColoredBox(color: Colors.blueGrey, child: Center(child: Text('底层'))),
          Positioned(right: 8, top: 8, child: Icon(Icons.push_pin)),
        ],
      ),
    );
  }
}
```

- [x] **Step 3: 覆写 examples/05_layout_multi/test/widget_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_multi_app/main.dart';

void main() {
  testWidgets('线性与层叠渲染', (tester) async {
    await tester.pumpWidget(const LayoutMultiApp());
    expect(find.text('2 份'), findsOneWidget);
    expect(find.text('1 份'), findsOneWidget);
    expect(find.byIcon(Icons.push_pin), findsOneWidget); // Stack 内 Positioned
  });
}
```

- [x] **Step 4: 覆写 examples/06_material/lib/main.dart**

```dart
import 'package:flutter/material.dart';

// 06 Material 组件库：Scaffold 全家（AppBar/Drawer/FAB/BottomNav）与常用组件
void main() => runApp(const MaterialDemoApp());

class MaterialDemoApp extends StatelessWidget {
  const MaterialDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    // ═══ 6.1 Scaffold：页面骨架的六个插槽 ═══
    return Scaffold(
      appBar: AppBar(title: const Text('Material 组件')),
      // ═══ 6.2 Drawer：侧滑抽屉 ═══
      drawer: Drawer(
        child: ListView(
          children: const [
            DrawerHeader(child: Text('菜单')),
            ListTile(leading: Icon(Icons.inbox), title: Text('收件箱')),
            ListTile(leading: Icon(Icons.settings), title: Text('设置')),
          ],
        ),
      ),
      // ═══ 6.3 BottomNavigationBar：底部导航 ═══
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.search), label: '发现'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: _tab == 0 ? const HomeBody() : const Center(child: Text('发现页')),
    );
  }
}

class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    // ═══ 6.4 信息组件：Card + ListTile + Chip ═══
    return ListView(
      padding: const EdgeInsets.all(8),
      children: const [
        Card(
          child: ListTile(
            leading: Icon(Icons.article),
            title: Text('卡片标题'),
            subtitle: Text('ListTile 承载一行信息的标准姿势'),
            trailing: Chip(label: Text('新')),
          ),
        ),
        Card(child: ListTile(leading: Icon(Icons.photo), title: Text('第二张卡片'))),
      ],
    );
  }
}
```

- [x] **Step 5: 覆写 examples/06_material/test/widget_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_app_demo/main.dart';

void main() {
  testWidgets('首页卡片与按钮家族', (tester) async {
    await tester.pumpWidget(const MaterialDemoApp());
    expect(find.text('卡片标题'), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(2));
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('底部导航切换', (tester) async {
    await tester.pumpWidget(const MaterialDemoApp());
    await tester.tap(find.text('发现'));
    await tester.pumpAndSettle();
    expect(find.text('发现页'), findsOneWidget);
    expect(find.text('卡片标题'), findsNothing);
  });

  testWidgets('Drawer 打开', (tester) async {
    await tester.pumpWidget(const MaterialDemoApp());
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('收件箱'), findsOneWidget);
  });
}
```

- [x] **Step 6: 覆写 examples/07_interaction/lib/main.dart**

```dart
import 'package:flutter/material.dart';

// 07 交互与对话框：GestureDetector/InkWell、AlertDialog、SnackBar、BottomSheet
void main() => runApp(const InteractionApp());

class InteractionApp extends StatelessWidget {
  const InteractionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
      ),
      home: const InteractionPage(),
    );
  }
}

class InteractionPage extends StatefulWidget {
  const InteractionPage({super.key});

  @override
  State<InteractionPage> createState() => _InteractionPageState();
}

class _InteractionPageState extends State<InteractionPage> {
  var _taps = 0;

  void _showDialog() {
    // ═══ 7.3 AlertDialog：确认对话框与返回值 ═══
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('删除')),
        ],
      ),
    );
  }

  void _showSnackBar() {
    // ═══ 7.4 SnackBar：轻提示（挂在 ScaffoldMessenger 上） ═══
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('已保存')));
  }

  void _showSheet() {
    // ═══ 7.5 模态 BottomSheet ═══
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => const ListTile(title: Text('底部面板内容')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('交互与对话框')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ═══ 7.1 InkWell：水波纹点击（Material 风格首选） ═══
          Card(
            child: InkWell(
              onTap: () => setState(() => _taps++),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('点我（InkWell）：$_taps 次'),
              ),
            ),
          ),
          // ═══ 7.2 GestureDetector：更底层的原始手势 ═══
          Card(
            child: GestureDetector(
              onDoubleTap: () => setState(() => _taps += 10),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('双击（GestureDetector）+10'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(onPressed: _showDialog, child: const Text('对话框')),
              OutlinedButton(onPressed: _showSnackBar, child: const Text('轻提示')),
              TextButton(onPressed: _showSheet, child: const Text('底部面板')),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [x] **Step 7: 覆写 examples/07_interaction/test/widget_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:interaction_app/main.dart';

void main() {
  testWidgets('InkWell 点击计数', (tester) async {
    await tester.pumpWidget(const InteractionApp());
    await tester.tap(find.text('点我（InkWell）：0 次'));
    await tester.pump();
    expect(find.text('点我（InkWell）：1 次'), findsOneWidget);
  });

  testWidgets('双击 +10', (tester) async {
    await tester.pumpWidget(const InteractionApp());
    await tester.tap(find.text('双击（GestureDetector）+10'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('双击（GestureDetector）+10'));
    await tester.pump();
    expect(find.text('点我（InkWell）：10 次'), findsOneWidget);
  });

  testWidgets('对话框打开与关闭', (tester) async {
    await tester.pumpWidget(const InteractionApp());
    await tester.tap(find.text('对话框'));
    await tester.pumpAndSettle();
    expect(find.text('确认删除？'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('确认删除？'), findsNothing);
  });

  testWidgets('SnackBar 轻提示', (tester) async {
    await tester.pumpWidget(const InteractionApp());
    await tester.tap(find.text('轻提示'));
    await tester.pump(); // SnackBar 动画入场
    expect(find.text('已保存'), findsOneWidget);
  });
}
```

- [x] **Step 8: 验证 + Commit**

```bash
cd /g/code/guide/flutter/examples/05_layout_multi && "G:/scoop/apps/flutter/current/bin/flutter.bat" test
cd ../06_material && "G:/scoop/apps/flutter/current/bin/flutter.bat" test
cd ../07_interaction && "G:/scoop/apps/flutter/current/bin/flutter.bat" test
cd /g/code/guide/flutter && git add examples && git commit -m "feat(flutter): 示例 05_layout_multi/06_material/07_interaction

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

预期：三工程测试全绿（06 含 3 例、07 含 4 例）。

---

### Task 5: 示例 08_stateful / 09_state_sharing / 10_navigation

**Files:**
- Create: `examples/08_stateful`（包名 `stateful_app`）、`examples/09_state_sharing`（包名 `state_sharing_app`）、`examples/10_navigation`（包名 `navigation_app`）

**Interfaces:**
- Produces: 第 08/09/10 章引用代码。

- [x] **Step 1: 创建三个工程**

```bash
cd /g/code/guide/flutter/examples
"G:/scoop/apps/flutter/current/bin/flutter.bat" create --project-name stateful_app --platforms=windows 08_stateful
"G:/scoop/apps/flutter/current/bin/flutter.bat" create --project-name state_sharing_app --platforms=windows 09_state_sharing
"G:/scoop/apps/flutter/current/bin/flutter.bat" create --project-name navigation_app --platforms=windows 10_navigation
```

- [x] **Step 2: 覆写 examples/08_stateful/lib/main.dart**

```dart
import 'package:flutter/material.dart';

// 08 有状态 Widget：setState、生命周期、TextEditingController
void main() => runApp(const StatefulApp());

class StatefulApp extends StatelessWidget {
  const StatefulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
      ),
      home: const CounterPage(),
    );
  }
}

// ═══ 8.1 StatefulWidget = 配置 + State：状态活在这 ═══
class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _count = 0;
  // ═══ 8.3 TextEditingController：读输入框内容/预填文本 ═══
  final _nameCtrl = TextEditingController();

  // ═══ 8.2 生命周期：initState 做一次性准备 ═══
  @override
  void initState() {
    super.initState();
    _nameCtrl.text = '阿 Dart';
  }

  // ═══ 8.2（续）dispose：离开页面时释放资源 ═══
  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('有状态 Widget')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('count = $_count', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            // ═══ 8.4 setState：告诉框架"状态变了，重新 build" ═══
            FilledButton(
              onPressed: () => setState(() => _count++),
              child: const Text('加一'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '名字'),
            ),
            const SizedBox(height: 8),
            Text('你好，${_nameCtrl.text}'),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => setState(() {}), // 手动触发重建，Text 才会刷新
              child: const Text('刷新问候'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [x] **Step 3: 覆写 examples/08_stateful/test/widget_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:stateful_app/main.dart';

void main() {
  testWidgets('setState 计数递增', (tester) async {
    await tester.pumpWidget(const StatefulApp());
    expect(find.text('count = 0'), findsOneWidget);
    await tester.tap(find.text('加一'));
    await tester.tap(find.text('加一'));
    await tester.pump();
    expect(find.text('count = 2'), findsOneWidget);
  });

  testWidgets('输入框双向绑定与手动刷新', (tester) async {
    await tester.pumpWidget(const StatefulApp());
    expect(find.text('你好，阿 Dart'), findsOneWidget); // initState 预填
    await tester.enterText(find.byType(TextField), '小李');
    await tester.tap(find.text('刷新问候'));
    await tester.pump();
    expect(find.text('你好，小李'), findsOneWidget);
  });
}
```

- [x] **Step 4: 覆写 examples/09_state_sharing/lib/main.dart**

```dart
import 'package:flutter/material.dart';

// 09 状态提升与共享：提升到父级、ChangeNotifier、InheritedWidget
void main() => runApp(const StateSharingApp());

class StateSharingApp extends StatelessWidget {
  const StateSharingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
      ),
      home: const CartScope(child: CartPage()),
    );
  }
}

// ═══ 9.3 ChangeNotifier：一个可监听的状态对象 ═══
class Cart extends ChangeNotifier {
  int count = 0;

  void add() {
    count++;
    notifyListeners(); // 通知所有监听者重建
  }
}

// ═══ 9.4 InheritedWidget：沿树向下广播、O(1) 取回 ═══
class CartScope extends InheritedNotifier<Cart> {
  const CartScope({super.key, required Widget child})
      : super(notifier: Cart(), child: child);

  static Cart of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CartScope>()!.notifier!;
}

// ═══ 9.1 状态提升：两个子组件通过父级共享同一份数据 ═══
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('状态共享')),
      body: const Column(
        children: [
          CartAdder(), // 子 A：只负责改
          CartViewer(), // 子 B：只负责显示
        ],
      ),
    );
  }
}

class CartAdder extends StatelessWidget {
  const CartAdder({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      // ═══ 9.3（续）谁改谁通知，监听者自动重建 ═══
      onPressed: () => CartScope.of(context).add(),
      child: const Text('加入购物车'),
    );
  }
}

class CartViewer extends StatelessWidget {
  const CartViewer({super.key});

  @override
  Widget build(BuildContext context) {
    // ═══ 9.4（续）dependOn... 建立依赖：notifyListeners 时这里重建 ═══
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text('购物车：${CartScope.of(context).count} 件'),
    );
  }
}
```

- [x] **Step 5: 覆写 examples/09_state_sharing/test/widget_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:state_sharing_app/main.dart';

void main() {
  testWidgets('子组件改、另一子组件显示：共享生效', (tester) async {
    await tester.pumpWidget(const StateSharingApp());
    expect(find.text('购物车：0 件'), findsOneWidget);
    await tester.tap(find.text('加入购物车'));
    await tester.pump(); // notifyListeners 触发依赖者重建
    expect(find.text('购物车：1 件'), findsOneWidget);
  });
}
```

- [x] **Step 6: 覆写 examples/10_navigation/lib/main.dart**

```dart
import 'package:flutter/material.dart';

// 10 导航与路由：push/pop、传参、返回值、命名路由
void main() => runApp(const NavigationApp());

class NavigationApp extends StatelessWidget {
  const NavigationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
      ),
      // ═══ 10.3 命名路由：字符串寻址，集中登记 ═══
      routes: {
        '/': (context) => const HomePage(),
        '/about': (context) => const AboutPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _result = '（无）';

  // ═══ 10.1 push 一个页面并 await 它的返回值 ═══
  Future<void> _openDetail() async {
    final picked = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const DetailPage(item: 7)),
    );
    if (!mounted) return;
    setState(() => _result = picked ?? '直接返回（无值）');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导航与路由')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('打开详情页（传参 7）'),
            onTap: _openDetail,
          ),
          ListTile(
            title: const Text('关于（命名路由）'),
            // ═══ 10.3（续）pushNamed：按字符串跳转 ═══
            onTap: () => Navigator.pushNamed(context, '/about'),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('详情页返回值：$_result'),
          ),
        ],
      ),
    );
  }
}

// ═══ 10.2 页面参数：构造传参（不可变配置的一部分） ═══
class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.item});

  final int item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('详情 #$item')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('收到参数：$item'),
            const SizedBox(height: 12),
            FilledButton(
              // ═══ 10.1（续）pop 带回返回值 ═══
              onPressed: () => Navigator.pop(context, '选中了 #$item'),
              child: const Text('选定并返回'),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: const Center(child: Text('这是命名路由页面')),
    );
  }
}
```

- [x] **Step 7: 覆写 examples/10_navigation/test/widget_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation_app/main.dart';

void main() {
  testWidgets('push 传参、pop 带返回值', (tester) async {
    await tester.pumpWidget(const NavigationApp());
    await tester.tap(find.text('打开详情页（传参 7）'));
    await tester.pumpAndSettle();
    expect(find.text('收到参数：7'), findsOneWidget);
    await tester.tap(find.text('选定并返回'));
    await tester.pumpAndSettle();
    expect(find.text('详情页返回值：选中了 #7'), findsOneWidget);
  });

  testWidgets('命名路由跳转', (tester) async {
    await tester.pumpWidget(const NavigationApp());
    await tester.tap(find.text('关于（命名路由）'));
    await tester.pumpAndSettle();
    expect(find.text('这是命名路由页面'), findsOneWidget);
  });
}
```

- [x] **Step 8: 验证 + Commit**

```bash
cd /g/code/guide/flutter/examples/08_stateful && "G:/scoop/apps/flutter/current/bin/flutter.bat" test
cd ../09_state_sharing && "G:/scoop/apps/flutter/current/bin/flutter.bat" test
cd ../10_navigation && "G:/scoop/apps/flutter/current/bin/flutter.bat" test
cd /g/code/guide/flutter && git add examples && git commit -m "feat(flutter): 示例 08_stateful/09_state_sharing/10_navigation

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

预期：三工程测试全绿。

---

### Task 6: 示例 11_forms / 12_lists / 13_http_json

**Files:**
- Create: `examples/11_forms`（包名 `forms_app`）、`examples/12_lists`（包名 `lists_app`）、`examples/13_http_json`（包名 `http_json_app`）

**Interfaces:**
- Produces: 第 11/12/13 章引用代码；13 章 `Note.fromJson` 与页面注入 `Future<List<Note>> Function()` fetcher（测试注入假实现）。

- [x] **Step 1: 创建三个工程**

```bash
cd /g/code/guide/flutter/examples
"G:/scoop/apps/flutter/current/bin/flutter.bat" create --project-name forms_app --platforms=windows 11_forms
"G:/scoop/apps/flutter/current/bin/flutter.bat" create --project-name lists_app --platforms=windows 12_lists
"G:/scoop/apps/flutter/current/bin/flutter.bat" create --project-name http_json_app --platforms=windows 13_http_json
```

- [x] **Step 2: 覆写 examples/11_forms/lib/main.dart**

```dart
import 'package:flutter/material.dart';

// 11 表单与输入：Form/TextFormField/校验/FocusNode
void main() => runApp(const FormsApp());

class FormsApp extends StatelessWidget {
  const FormsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
      ),
      home: const SignupPage(),
    );
  }
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // ═══ 11.1 FormState 的钥匙：GlobalKey 触发校验/保存 ═══
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _message = '';

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    // ═══ 11.3 validate()：跑一遍全部字段的 validator ═══
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _message = '欢迎，${_userCtrl.text}！');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('表单')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ═══ 11.2 TextFormField：validator 一行一个规则 ═══
            TextFormField(
              controller: _userCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: '用户名'),
              validator: (v) =>
                  (v == null || v.length < 3) ? '至少 3 个字符' : null,
            ),
            TextFormField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: '密码'),
              validator: (v) =>
                  (v == null || v.length < 6) ? '至少 6 位' : null,
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _submit, child: const Text('注册')),
            const SizedBox(height: 12),
            if (_message.isNotEmpty) Text(_message),
          ],
        ),
      ),
    );
  }
}
```

- [x] **Step 3: 覆写 examples/11_forms/test/widget_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:forms_app/main.dart';

void main() {
  testWidgets('空表单提交显示两条校验错误', (tester) async {
    await tester.pumpWidget(const FormsApp());
    await tester.tap(find.text('注册'));
    await tester.pump();
    expect(find.text('至少 3 个字符'), findsOneWidget);
    expect(find.text('至少 6 位'), findsOneWidget);
  });

  testWidgets('合法输入通过校验', (tester) async {
    await tester.pumpWidget(const FormsApp());
    await tester.enterText(find.byType(TextFormField).first, 'dartfan');
    await tester.enterText(find.byType(TextFormField).last, '123456');
    await tester.tap(find.text('注册'));
    await tester.pump();
    expect(find.text('欢迎，dartfan！'), findsOneWidget);
    expect(find.text('至少 3 个字符'), findsNothing);
  });
}
```

- [x] **Step 4: 覆写 examples/12_lists/lib/main.dart**

```dart
import 'package:flutter/material.dart';

// 12 列表与滚动：ListView.builder、分隔线、GridView、Sliver 一瞥
void main() => runApp(const ListsApp());

class ListsApp extends StatelessWidget {
  const ListsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lime),
      ),
      home: const ListsPage(),
    );
  }
}

class ListsPage extends StatelessWidget {
  const ListsPage({super.key});

  static const _items = [
    '草莓', '香蕉', '苹果', '西瓜', '葡萄', '橙子', '芒果', '樱桃',
    '荔枝', '蓝莓', '柠檬', '桃子',
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('列表与滚动'),
          bottom: const TabBar(tabs: [Tab(text: '列表'), Tab(text: '网格')]),
        ),
        body: TabBarView(
          children: [
            // ═══ 12.1 ListView.separated：懒构建 + 分隔线 ═══
            ListView.separated(
              itemCount: _items.length,
              itemBuilder: (context, i) => ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(_items[i]),
                trailing: const Icon(Icons.chevron_right),
              ),
              separatorBuilder: (_, __) => const Divider(height: 1),
            ),
            // ═══ 12.2 GridView.count：固定列数网格 ═══
            GridView.count(
              crossAxisCount: 4,
              children: [for (final f in _items) Center(child: Text(f))],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [x] **Step 5: 覆写 examples/12_lists/test/widget_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lists_app/main.dart';

void main() {
  testWidgets('列表懒构建：可见项渲染', (tester) async {
    await tester.pumpWidget(const ListsApp());
    expect(find.text('草莓'), findsOneWidget);
    expect(find.text('荔枝'), findsNothing); // 懒构建：还没滚到
  });

  testWidgets('滚动后可见后续条目', (tester) async {
    await tester.pumpWidget(const ListsApp());
    await tester.scrollUntilVisible(
      find.text('蓝莓'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('蓝莓'), findsOneWidget);
  });

  testWidgets('切到网格页', (tester) async {
    await tester.pumpWidget(const ListsApp());
    await tester.tap(find.text('网格'));
    await tester.pumpAndSettle();
    expect(find.text('柠檬'), findsOneWidget);
  });
}
```

- [x] **Step 6: 覆写 examples/13_http_json/lib/main.dart**

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// 13 网络与 JSON：http 包、fromJson、依赖注入让页面可测
Future<void> main() async {
  // ═══ 13.4 自测型后端：本地起一个 HttpServer，零外网依赖 ═══
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    final body = jsonEncode([
      {'id': 1, 'title': '第一条新闻', 'done': true},
      {'id': 2, 'title': '第二条新闻', 'done': false},
    ]);
    request.response.headers.contentType = ContentType.json;
    request.response.write(body);
    await request.response.close();
  });
  runApp(NewsApp(fetcher: fetchFrom('http://127.0.0.1:${server.port}/notes')));
}

// ═══ 13.2 数据模型 + fromJson（模板见 Dart 教程·第 18 章） ═══
class NewsItem {
  const NewsItem({required this.id, required this.title, required this.done});

  factory NewsItem.fromJson(Map<String, dynamic> json) => NewsItem(
        id: json['id'] as int,
        title: json['title'] as String,
        done: json['done'] as bool,
      );

  final int id;
  final String title;
  final bool done;
}

Future<List<NewsItem>> Function() fetchFrom(String url) => () async {
      // ═══ 13.1 http 包：一行 GET，未来 JSON 解码 ═══
      final resp = await http.get(Uri.parse(url));
      final list = jsonDecode(resp.body) as List<dynamic>;
      return list.map((e) => NewsItem.fromJson(e as Map<String, dynamic>)).toList();
    };

class NewsApp extends StatelessWidget {
  // ═══ 13.5 依赖注入：main 传真实现，测试注入假 fetcher ═══
  const NewsApp({super.key, required this.fetcher});

  final Future<List<NewsItem>> Function() fetcher;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      home: NewsPage(fetcher: fetcher),
    );
  }
}

class NewsPage extends StatefulWidget {
  const NewsPage({super.key, required this.fetcher});

  final Future<List<NewsItem>> Function() fetcher;

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  late final Future<List<NewsItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.fetcher(); // 只在 initState 发一次请求（第 14 章坑位）
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('网络与 JSON')),
      // ═══ 13.3 消费 Future：FutureBuilder（第 14 章展开） ═══
      body: FutureBuilder<List<NewsItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }
          final items = snapshot.data;
          if (items == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: [
              for (final n in items)
                ListTile(
                  leading: Icon(n.done ? Icons.check_box : Icons.check_box_outline_blank),
                  title: Text(n.title),
                ),
            ],
          );
        },
      ),
    );
  }
}
```

- [x] **Step 7: 覆写 examples/13_http_json/test/widget_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:http_json_app/main.dart';

void main() {
  testWidgets('注入假 fetcher：JSON 数据渲染成列表', (tester) async {
    await tester.pumpWidget(NewsApp(
      fetcher: () async => const [
        NewsItem(id: 1, title: '本地假数据 A', done: true),
        NewsItem(id: 2, title: '本地假数据 B', done: false),
      ],
    ));
    await tester.pumpAndSettle();
    expect(find.text('本地假数据 A'), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
  });

  testWidgets('加载失败态', (tester) async {
    await tester.pumpWidget(NewsApp(
      fetcher: () => Future.error('网络不通'),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('加载失败'), findsOneWidget);
  });

  test('NewsItem.fromJson 解析', () {
    final n = NewsItem.fromJson({'id': 9, 'title': 't', 'done': false});
    expect(n.id, 9);
    expect(n.title, 't');
    expect(n.done, isFalse);
  });
}
```

- [x] **Step 8: pubspec 加 http 依赖 + 验证 + Commit**

`examples/13_http_json/pubspec.yaml` 的 dependencies 段加（保持 create 生成的其余内容不动）：

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
```

```bash
cd /g/code/guide/flutter/examples/13_http_json && "G:/scoop/apps/flutter/current/bin/flutter.bat" pub get && "G:/scoop/apps/flutter/current/bin/flutter.bat" test
cd ../11_forms && "G:/scoop/apps/flutter/current/bin/flutter.bat" test
cd ../12_lists && "G:/scoop/apps/flutter/current/bin/flutter.bat" test
cd /g/code/guide/flutter && git add examples && git commit -m "feat(flutter): 示例 11_forms/12_lists/13_http_json

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

预期：三工程测试全绿（13 的 http 依赖解析成功）。

---

### Task 7: 示例 14_async_ui / 15_animation / 16_theme

**Files:**
- Create: `examples/14_async_ui`（包名 `async_ui_app`）、`examples/15_animation`（包名 `animation_app`）、`examples/16_theme`（包名 `theme_app`）

**Interfaces:**
- Produces: 第 14/15/16 章引用代码。14 章页面收可注入的 `Future`/`Stream`（测试确定性）。

- [x] **Step 1: 创建三个工程**

```bash
cd /g/code/guide/flutter/examples
"G:/scoop/apps/flutter/current/bin/flutter.bat" create --project-name async_ui_app --platforms=windows 14_async_ui
"G:/scoop/apps/flutter/current/bin/flutter.bat" create --project-name animation_app --platforms=windows 15_animation
"G:/scoop/apps/flutter/current/bin/flutter.bat" create --project-name theme_app --platforms=windows 16_theme
```

- [x] **Step 2: 覆写 examples/14_async_ui/lib/main.dart**

```dart
import 'dart:async';

import 'package:flutter/material.dart';

// 14 异步 UI：FutureBuilder 与 StreamBuilder、加载/错误/数据三态
void main() => runApp(const AsyncUiApp());

class AsyncUiApp extends StatelessWidget {
  const AsyncUiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      ),
      home: const AsyncUiPage(),
    );
  }
}

class AsyncUiPage extends StatefulWidget {
  const AsyncUiPage({super.key});

  @override
  State<AsyncUiPage> createState() => _AsyncUiPageState();
}

class _AsyncUiPageState extends State<AsyncUiPage> {
  // ═══ 14.2 状态里存 Future，而不是在 build 里现造 ═══
  Future<String>? _future;
  // ═══ 14.4 Stream.periodic + take：有限个 tick 的流 ═══
  final Stream<int> _ticks = Stream<int>.periodic(
    const Duration(milliseconds: 300),
    (i) => i + 1,
  ).take(5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('异步 UI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () => setState(() => _future = Future.value('成功的数据')),
                child: const Text('成功'),
              ),
              OutlinedButton(
                onPressed: () => setState(() => _future = Future.error('服务器 500')),
                child: const Text('失败'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ═══ 14.1 FutureBuilder：一次异步值的三态渲染 ═══
          FutureBuilder<String>(
            future: _future,
            builder: (context, snap) => switch (snap.connectionState) {
              ConnectionState.none => const Text('还没发起请求'),
              ConnectionState.done when snap.hasError => Text(
                  '加载失败：${snap.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ConnectionState.done => Text('拿到：${snap.data}'),
              _ => const CircularProgressIndicator(),
            },
          ),
          const Divider(height: 32),
          // ═══ 14.3 StreamBuilder：序列数据逐个到达 ═══
          StreamBuilder<int>(
            stream: _ticks,
            builder: (context, snap) => Text(
              snap.hasData ? 'tick ${snap.data}/5' : '等待第一个事件…',
            ),
          ),
        ],
      ),
    );
  }
}
```

- [x] **Step 3: 覆写 examples/14_async_ui/test/widget_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:async_ui_app/main.dart';

void main() {
  testWidgets('三态：未请求 → 成功', (tester) async {
    await tester.pumpWidget(const AsyncUiApp());
    expect(find.text('还没发起请求'), findsOneWidget);
    await tester.tap(find.text('成功'));
    await tester.pumpAndSettle();
    expect(find.text('拿到：成功的数据'), findsOneWidget);
  });

  testWidgets('错误态', (tester) async {
    await tester.pumpWidget(const AsyncUiApp());
    await tester.tap(find.text('失败'));
    await tester.pumpAndSettle();
    expect(find.textContaining('加载失败'), findsOneWidget);
  });

  testWidgets('StreamBuilder 五个 tick 后停在 5/5', (tester) async {
    await tester.pumpWidget(const AsyncUiApp());
    await tester.pumpAndSettle(); // 假时钟推进，300ms×5 全部走完
    expect(find.text('tick 5/5'), findsOneWidget);
  });
}
```

- [x] **Step 4: 覆写 examples/15_animation/lib/main.dart**

```dart
import 'package:flutter/material.dart';

// 15 动画：隐式动画（AnimatedXxx）、Hero、显式 AnimationController
void main() => runApp(const AnimationApp());

class AnimationApp extends StatelessWidget {
  const AnimationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AnimationPage(),
    );
  }
}

class AnimationPage extends StatefulWidget {
  const AnimationPage({super.key});

  @override
  State<AnimationPage> createState() => _AnimationPageState();
}

class _AnimationPageState extends State<AnimationPage>
    with SingleTickerProviderStateMixin {
  var _big = false;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..addListener(() => setState(() {}));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('动画')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ═══ 15.1 隐式动画：改属性值，动画自动发生 ═══
          GestureDetector(
            onTap: () => setState(() => _big = !_big),
            child: AnimatedContainer(
              key: const Key('animated-box'),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              width: _big ? 160.0 : 80.0,
              height: 64,
              color: _big ? Colors.deepPurple : Colors.deepPurple.shade200,
            ),
          ),
          // ═══ 15.3 显式动画：AnimationController 亲自推进 ═══
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: Align(
              alignment: Alignment(-0.9 + 1.8 * _controller.value, 0),
              child: const Icon(Icons.directions_run),
            ),
          ),
          FilledButton(
            onPressed: () {
              _controller.forward(from: 0); // 从头跑一次 0 → 1
            },
            child: const Text('跑一格'),
          ),
          // ═══ 15.2 Hero：跨页共享元素 ═══
          const SizedBox(height: 16),
          Center(
            child: Hero(
              tag: 'logo',
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.deepPurple.shade100,
                child: const Icon(Icons.flutter_dash),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HeroPage()),
            ),
            child: const Text('Hero 转场到下一页'),
          ),
        ],
      ),
    );
  }
}

class HeroPage extends StatelessWidget {
  const HeroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hero 目的地')),
      body: Center(
        child: Hero(
          tag: 'logo',
          child: CircleAvatar(
            radius: 64,
            backgroundColor: Colors.deepPurple.shade100,
            child: const Icon(Icons.flutter_dash, size: 48),
          ),
        ),
      ),
    );
  }
}
```

- [x] **Step 5: 覆写 examples/15_animation/test/widget_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:animation_app/main.dart';

void main() {
  testWidgets('AnimatedContainer 尺寸动画到位', (tester) async {
    await tester.pumpWidget(const AnimationApp());
    var size = tester.getSize(find.byKey(const Key('animated-box')));
    expect(size.width, 80.0);
    await tester.tap(find.byKey(const Key('animated-box')));
    await tester.pumpAndSettle();
    size = tester.getSize(find.byKey(const Key('animated-box')));
    expect(size.width, 160.0);
  });

  testWidgets('Hero 转场到目标页', (tester) async {
    await tester.pumpWidget(const AnimationApp());
    await tester.tap(find.text('Hero 转场到下一页'));
    await tester.pumpAndSettle();
    expect(find.text('Hero 目的地'), findsOneWidget);
  });

  testWidgets('显式动画跑完停在终点', (tester) async {
    await tester.pumpWidget(const AnimationApp());
    await tester.tap(find.text('跑一格'));
    await tester.pumpAndSettle();
    final position = tester.getTopLeft(find.byIcon(Icons.directions_run));
    expect(position.dx, greaterThan(200)); // 0→1 跑完，接近右端
  });
}
```

- [x] **Step 6: 覆写 examples/16_theme/lib/main.dart**

```dart
import 'package:flutter/material.dart';

// 16 主题与响应式：ThemeData/深浅模式切换、LayoutBuilder 适配
void main() => runApp(const ThemeApp());

class ThemeApp extends StatefulWidget {
  const ThemeApp({super.key});

  @override
  State<ThemeApp> createState() => _ThemeAppState();
}

class _ThemeAppState extends State<ThemeApp> {
  var _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    // ═══ 16.1 一颗种子色生成整套色板（Material 3） ═══
    return MaterialApp(
      title: 'Theme Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _mode,
      home: ThemePage(
        mode: _mode,
        onModeChanged: (m) => setState(() => _mode = m),
      ),
    );
  }
}

class ThemePage extends StatelessWidget {
  const ThemePage({super.key, required this.mode, required this.onModeChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text('当前：${isDark ? "深色" : "浅色"}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ═══ 16.2 SegmentedButton：M3 的分段选择 ═══
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, label: Text('浅色')),
              ButtonSegment(value: ThemeMode.dark, label: Text('深色')),
            ],
            selected: {mode},
            onSelectionChanged: (s) => onModeChanged(s.first),
          ),
          const SizedBox(height: 16),
          // ═══ 16.3 颜色语义化：不写死颜色，用色板角色 ═══
          Card(
            child: ListTile(
              leading: Icon(Icons.palette, color: Theme.of(context).colorScheme.primary),
              title: const Text('颜色来自 colorScheme.primary'),
            ),
          ),
          const SizedBox(height: 16),
          // ═══ 16.4 LayoutBuilder：按可用宽度换布局 ═══
          Container(
            height: 80,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 500;
                return wide
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [Text('宽屏：双栏'), Text('第二栏')],
                      )
                    : const Center(child: Text('窄屏：单栏'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

- [x] **Step 7: 覆写 examples/16_theme/test/widget_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:theme_app/main.dart';

void main() {
  testWidgets('默认浅色，切换到深色', (tester) async {
    await tester.pumpWidget(const ThemeApp());
    expect(find.text('当前：浅色'), findsOneWidget);
    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();
    expect(find.text('当前：深色'), findsOneWidget);
  });

  testWidgets('LayoutBuilder 按宽度换布局', (tester) async {
    await tester.pumpWidget(const ThemeApp());
    await tester.binding.setSurfaceSize(const Size(900, 700));
    await tester.pump();
    expect(find.text('宽屏：双栏'), findsOneWidget);
    await tester.binding.setSurfaceSize(const Size(360, 700));
    await tester.pump();
    expect(find.text('窄屏：单栏'), findsOneWidget);
    await tester.binding.setSurfaceSize(null); // 恢复默认
  });
}
```

- [x] **Step 8: 验证 + Commit**

```bash
cd /g/code/guide/flutter/examples/14_async_ui && "G:/scoop/apps/flutter/current/bin/flutter.bat" test
cd ../15_animation && "G:/scoop/apps/flutter/current/bin/flutter.bat" test
cd ../16_theme && "G:/scoop/apps/flutter/current/bin/flutter.bat" test
cd /g/code/guide/flutter && git add examples && git commit -m "feat(flutter): 示例 14_async_ui/15_animation/16_theme

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

预期：三工程测试全绿。

---

### Task 8: 示例 17_persist / 18_desktop / 19_testing

**Files:**
- Create: `examples/17_persist`（包名 `persist_app`）、`examples/18_desktop`（包名 `desktop_app`）、`examples/19_testing`（包名 `testing_app`）

**Interfaces:**
- Produces: 第 17/18/19 章引用代码；17 章文件往返放普通 `test()`、prefs 用 mock；19 章工程本身就是"被测示例"（lib 纯逻辑 + 双层测试）。

- [x] **Step 1: 创建三个工程**

```bash
cd /g/code/guide/flutter/examples
"G:/scoop/apps/flutter/current/bin/flutter.bat" create --project-name persist_app --platforms=windows 17_persist
"G:/scoop/apps/flutter/current/bin/flutter.bat" create --project-name desktop_app --platforms=windows 18_desktop
"G:/scoop/apps/flutter/current/bin/flutter.bat" create --project-name testing_app --platforms=windows 19_testing
```

- [x] **Step 2: 覆写 examples/17_persist/lib/main.dart**

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 17 数据持久化：文件（dart:io）与 shared_preferences
Future<void> main() async {
  runApp(const PersistApp());
}

class PersistApp extends StatelessWidget {
  const PersistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: const PersistPage(),
    );
  }
}

// ═══ 17.1 文件存储：JSON 落盘（模板见 Dart 教程·第 18 章） ═══
class FileCounter {
  FileCounter(this.path);

  final String path;

  Future<int> read() async {
    final file = File(path);
    if (!await file.exists()) return 0;
    return jsonDecode(await file.readAsString()) as int;
  }

  Future<void> write(int value) async {
    await File(path).writeAsString(jsonEncode(value));
  }
}

class PersistPage extends StatefulWidget {
  const PersistPage({super.key});

  @override
  State<PersistPage> createState() => _PersistPageState();
}

class _PersistPageState extends State<PersistPage> {
  static const _fileKey = 'file_count';
  static const _prefsKey = 'prefs_count';
  // 桌面演示用临时目录（真实应用建议 path_provider 取应用数据目录）
  late final FileCounter _file = FileCounter(
    '${Directory.systemTemp.path}/flutter_guide_17.json',
  );
  int _fileCount = 0;
  int _prefsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _fileCount = 0; // 文件计数在按钮触发时演示读盘
      _prefsCount = prefs.getInt(_prefsKey) ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据持久化')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ═══ 17.2 shared_preferences：键值对存取 ═══
          Text('prefs 计数：$_prefsCount',
              style: Theme.of(context).textTheme.titleLarge),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final next = (prefs.getInt(_prefsKey) ?? 0) + 1;
                  await prefs.setInt(_prefsKey, next);
                  if (!mounted) return;
                  setState(() => _prefsCount = next);
                },
                child: const Text('prefs +1 并保存'),
              ),
            ],
          ),
          const Divider(height: 32),
          // ═══ 17.3 文件：读盘/写盘按钮 ═══
          Text('文件计数：$_fileCount',
              style: Theme.of(context).textTheme.titleLarge),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: () async {
                  final v = await _file.read();
                  if (!mounted) return;
                  setState(() => _fileCount = v);
                },
                child: const Text('从文件读'),
              ),
              FilledButton(
                onPressed: () async {
                  await _file.write(_fileCount + 1);
                  if (!mounted) return;
                  setState(() => _fileCount++);
                },
                child: const Text('写入文件'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('选型：小键值用 prefs；结构化数据用 JSON 文件；大量数据上 sqflite（生态）'),
        ],
      ),
    );
  }
}
```

- [x] **Step 3: 覆写 examples/17_persist/test/widget_test.dart**

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:persist_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // 文件往返：真实 IO，放普通 test（不进 widget 的假时钟环境）
  test('FileCounter 写读往返', () async {
    final path = '${Directory.systemTemp.path}/guide17_test.json';
    final counter = FileCounter(path);
    await counter.write(41);
    expect(await counter.read(), 41);
    await File(path).delete();
  });

  test('FileCounter 缺文件返回 0', () async {
    final counter = FileCounter('${Directory.systemTemp.path}/guide17_missing.json');
    expect(await counter.read(), 0);
  });

  testWidgets('prefs mock：预置值渲染、+1 持久', (tester) async {
    SharedPreferences.setMockInitialValues({'prefs_count': 7});
    await tester.pumpWidget(const PersistApp());
    await tester.pumpAndSettle();
    expect(find.text('prefs 计数：7'), findsOneWidget);
    await tester.tap(find.text('prefs +1 并保存'));
    await tester.pumpAndSettle();
    expect(find.text('prefs 计数：8'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('prefs_count'), 8); // 真的存回去了
  });
}
```

- [x] **Step 4: 覆写 examples/18_desktop/lib/main.dart**

```dart
import 'package:flutter/material.dart';

// 18 桌面专题：菜单栏、SelectionArea、Scrollbar 与桌面习惯
void main() => runApp(const DesktopApp());

class DesktopApp extends StatelessWidget {
  const DesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      ),
      home: const DesktopPage(),
    );
  }
}

class DesktopPage extends StatefulWidget {
  const DesktopPage({super.key});

  @override
  State<DesktopPage> createState() => _DesktopPageState();
}

class _DesktopPageState extends State<DesktopPage> {
  var _selected = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('桌面专题')),
      // ═══ 18.1 MenuBar：桌面级菜单栏（顶部） ═══
      body: Column(
        children: [
          MenuBar(
            children: [
              SubmenuButton(
                menuChildren: [
                  MenuItemButton(
                    onPressed: () => setState(() => _selected = '新建'),
                    child: const Text('新建'),
                  ),
                  MenuItemButton(
                    onPressed: () => setState(() => _selected = '退出'),
                    child: const Text('退出'),
                  ),
                ],
                child: const Text('文件'),
              ),
            ],
          ),
          Expanded(
            // ═══ 18.3 Scrollbar + 滚轮：桌面用户expect可见滚动条 ═══
            child: Scrollbar(
              child: ListView.builder(
                itemCount: 40,
                itemBuilder: (context, i) => ListTile(
                  dense: true,
                  title: Text('条目 $i'),
                ),
              ),
            ),
          ),
          // ═══ 18.2 SelectionArea：让文本可选中复制（桌面标配） ═══
          SelectionArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text('菜单选择：$_selected（这段文字可以选中复制）'),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [x] **Step 5: 覆写 examples/18_desktop/test/widget_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_app/main.dart';

void main() {
  testWidgets('菜单打开并选择', (tester) async {
    await tester.pumpWidget(const DesktopApp());
    await tester.tap(find.text('文件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新建').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('菜单选择：新建'), findsOneWidget);
  });

  testWidgets('列表渲染与 SelectionArea', (tester) async {
    await tester.pumpWidget(const DesktopApp());
    expect(find.text('条目 0'), findsOneWidget);
    expect(find.byType(SelectionArea), findsOneWidget);
  });
}
```

- [x] **Step 6: 覆写 examples/19_testing 的 lib 与双层测试**

`lib/counter.dart`：

```dart
/// 19 章 fixture：纯逻辑计数器——单元测试的对象。
class Counter {
  int _value = 0;

  int get value => _value;

  void increment() => _value++;

  /// 减到 0 为止：负数是 bug（第 12 章分界），抛 StateError。
  void decrement() {
    if (_value == 0) {
      throw StateError('计数器已经是 0');
    }
    _value--;
  }

  void reset() => _value = 0;
}
```

`lib/main.dart`：

```dart
import 'package:flutter/material.dart';

import 'counter.dart';

// 19 Widget 测试：被测对象本身——纯逻辑 + 薄 UI
void main() => runApp(const TestingApp());

class TestingApp extends StatelessWidget {
  const TestingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
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
  final _counter = Counter();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('测试分层')),
      body: Center(child: Text('value = ${_counter.value}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(_counter.increment),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

`test/counter_test.dart`（纯单元层）：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:testing_app/counter.dart';

void main() {
  group('Counter 纯逻辑', () {
    test('递增与复位', () {
      final c = Counter();
      c.increment();
      c.increment();
      expect(c.value, 2);
      c.reset();
      expect(c.value, 0);
    });

    test('0 再减抛 StateError（负例）', () {
      expect(() => Counter().decrement(), throwsStateError);
    });
  });
}
```

`test/widget_test.dart`（widget 层）：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:testing_app/main.dart';

void main() {
  testWidgets('点击 FAB 界面计数递增', (tester) async {
    await tester.pumpWidget(const TestingApp());
    expect(find.text('value = 0'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('value = 1'), findsOneWidget);
  });
}
```

- [x] **Step 7: pubspec 加 shared_preferences（17）+ 验证 + Commit**

`examples/17_persist/pubspec.yaml` dependencies 加：

```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.0
```

```bash
cd /g/code/guide/flutter/examples/17_persist && "G:/scoop/apps/flutter/current/bin/flutter.bat" pub get && "G:/scoop/apps/flutter/current/bin/flutter.bat" test
cd ../18_desktop && "G:/scoop/apps/flutter/current/bin/flutter.bat" test
cd ../19_testing && "G:/scoop/apps/flutter/current/bin/flutter.bat" test
cd /g/code/guide/flutter && git add examples && git commit -m "feat(flutter): 示例 17_persist/18_desktop/19_testing

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

预期：三工程测试全绿（17 含 3 例、19 含 3 例跨两个文件）。

---

### Task 9: 示例 20_notes（实战：记事本）

**Files:**
- Create: `examples/20_notes`（包名 `notes_app`），lib 多文件：`main.dart`、`note.dart`、`storage.dart`、`edit_page.dart`；test `notes_test.dart`

**Interfaces:**
- Produces: 第 20 章引用代码；`NotesStorage` 抽象（测试注入内存实现）；Note 模型（fromJson/toJson/copyWith）。

- [x] **Step 1: 创建工程**

```bash
cd /g/code/guide/flutter/examples
"G:/scoop/apps/flutter/current/bin/flutter.bat" create --project-name notes_app --platforms=windows 20_notes
```

- [x] **Step 2: 写 lib/note.dart**

```dart
/// 一条笔记：纯数据模型（模板见 Dart 教程·第 18/20 章）。
class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as int,
        title: json['title'] as String,
        body: json['body'] as String,
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );

  final int id;
  final String title;
  final String body;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  Note copyWith({String? title, String? body, DateTime? updatedAt}) => Note(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  bool get isEmpty => title.trim().isEmpty && body.trim().isEmpty;
}
```

- [x] **Step 3: 写 lib/storage.dart**

```dart
import 'dart:convert';
import 'dart:io';

import 'note.dart';

/// 存储抽象：页面依赖它而不是具体文件——测试注入内存实现（依赖注入）。
abstract class NotesStorage {
  Future<List<Note>> load();
  Future<void> save(List<Note> notes);
}

/// JSON 文件实现（桌面演示：临时目录下固定文件）。
class FileNotesStorage implements NotesStorage {
  FileNotesStorage(this.path);

  final String path;

  @override
  Future<List<Note>> load() async {
    final file = File(path);
    if (!await file.exists()) return [];
    final list = jsonDecode(await file.readAsString()) as List<dynamic>;
    return list.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> save(List<Note> notes) async {
    final json = const JsonEncoder.withIndent('  ')
        .convert(notes.map((n) => n.toJson()).toList());
    await File(path).writeAsString('$json\n');
  }
}
```

- [x] **Step 4: 写 lib/main.dart**

```dart
import 'dart:io';

import 'package:flutter/material.dart';

import 'edit_page.dart';
import 'note.dart';
import 'storage.dart';

// 20 实战记事本：列表 + 编辑 + 持久化 + 主题切换 + 删除确认
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await DirectoryWrapper.tempDir();
  runApp(NotesApp(storage: FileNotesStorage('${dir.path}/notes.json')));
}

/// 可替换的目录来源（保持 main 可测的薄封装）。
class DirectoryWrapper {
  static Future<Directory> tempDir() async => Directory.systemTemp;
}

class NotesApp extends StatefulWidget {
  const NotesApp({super.key, required this.storage});

  final NotesStorage storage;

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  var _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '记事本',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _mode,
      home: NotesHomePage(
        storage: widget.storage,
        mode: _mode,
        onModeChanged: (m) => setState(() => _mode = m),
      ),
    );
  }
}

class NotesHomePage extends StatefulWidget {
  const NotesHomePage({
    super.key,
    required this.storage,
    required this.mode,
    required this.onModeChanged,
  });

  final NotesStorage storage;
  final ThemeMode mode;
  final ValueChanged<ThemeMode> onModeChanged;

  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  List<Note> _notes = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final notes = await widget.storage.load();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _openEditor({Note? note}) async {
    final saved = await Navigator.push<Note>(
      context,
      MaterialPageRoute(
        builder: (_) => EditPage(note: note, nextId: _nextId()),
      ),
    );
    if (saved == null) return;
    if (!mounted) return;
    setState(() {
      final i = _notes.indexWhere((n) => n.id == saved.id);
      if (i >= 0) {
        _notes[i] = saved;
      } else {
        _notes.insert(0, saved);
      }
    });
    await widget.storage.save(_notes);
  }

  Future<void> _confirmDelete(Note note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除「${note.title}」？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _notes.removeWhere((n) => n.id == note.id));
    await widget.storage.save(_notes);
  }

  int _nextId() =>
      _notes.fold(0, (max, n) => n.id > max ? n.id : max) + 1;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('记事本'),
        actions: [
          IconButton(
            tooltip: dark ? '切换浅色' : '切换深色',
            icon: Icon(dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () =>
                widget.onModeChanged(dark ? ThemeMode.light : ThemeMode.dark),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(child: Text('还没有笔记，点 + 新建'))
              : ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, i) {
                    final n = _notes[i];
                    return ListTile(
                      leading: const Icon(Icons.sticky_note_2_outlined),
                      title: Text(n.title.isEmpty ? '（无标题）' : n.title),
                      subtitle: n.body.isEmpty
                          ? null
                          : Text(n.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => _openEditor(note: n),
                      onLongPress: () => _confirmDelete(n),
                    );
                  },
                ),
    );
  }
}
```

- [x] **Step 5: 写 lib/edit_page.dart**

```dart
import 'package:flutter/material.dart';

import 'note.dart';

/// 编辑页：新建收 note=null；返回时 pop 带保存后的 Note。
class EditPage extends StatefulWidget {
  const EditPage({super.key, required this.note, required this.nextId});

  final Note? note;
  final int nextId;

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  late final _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
  late final _bodyCtrl = TextEditingController(text: widget.note?.body ?? '');

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final note = (widget.note ?? Note(id: widget.nextId, title: '', body: ''))
        .copyWith(
      title: _titleCtrl.text,
      body: _bodyCtrl.text,
      updatedAt: DateTime.now(),
    );
    Navigator.pop(context, note);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? '新建笔记' : '编辑笔记'),
        actions: [
          IconButton(icon: const Icon(Icons.check), tooltip: '保存', onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: '标题'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            maxLines: null,
            decoration: const InputDecoration(
              labelText: '正文',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [x] **Step 6: 写 test/notes_test.dart**

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/main.dart';
import 'package:notes_app/note.dart';
import 'package:notes_app/storage.dart';

/// 内存实现：widget 测试注入，零真实 IO。
class InMemoryStorage implements NotesStorage {
  List<Note> seed;
  InMemoryStorage([this.seed = const []]);

  List<Note> saved = [];

  @override
  Future<List<Note>> load() async => seed;

  @override
  Future<void> save(List<Note> notes) async => saved = [...notes];
}

Note _note(int id, String title) =>
    Note(id: id, title: title, body: '内容 $id');

void main() {
  test('Note JSON 往返', () {
    final n = Note(id: 1, title: 't', body: 'b', updatedAt: DateTime(2026, 1, 1));
    final restored = Note.fromJson(n.toJson());
    expect(restored.title, 't');
    expect(restored.updatedAt, DateTime(2026, 1, 1));
  });

  test('FileNotesStorage 往返与空文件', () async {
    final path = '${Directory.systemTemp.path}/notes20_test.json';
    final storage = FileNotesStorage(path);
    expect(await storage.load(), isEmpty);
    await storage.save([_note(1, '一'), _note(2, '二')]);
    final loaded = await storage.load();
    expect(loaded.length, 2);
    expect(loaded[1].title, '二');
    File(path).deleteSync();
  });

  testWidgets('初始加载渲染', (tester) async {
    await tester.pumpWidget(NotesApp(
      storage: InMemoryStorage([_note(1, '第一篇'), _note(2, '第二篇')]),
    ));
    await tester.pumpAndSettle();
    expect(find.text('第一篇'), findsOneWidget);
    expect(find.text('第二篇'), findsOneWidget);
  });

  testWidgets('新建并保存', (tester) async {
    final storage = InMemoryStorage();
    await tester.pumpWidget(NotesApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '新笔记标题');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.text('新笔记标题'), findsOneWidget);
    expect(storage.saved.single.title, '新笔记标题'); // 真的存了
  });

  testWidgets('长按删除确认', (tester) async {
    final storage = InMemoryStorage([_note(1, '待删除')]);
    await tester.pumpWidget(NotesApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('待删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();
    expect(find.text('待删除'), findsNothing);
    expect(storage.saved, isEmpty);
  });

  testWidgets('主题切换', (tester) async {
    await tester.pumpWidget(
      NotesApp(storage: InMemoryStorage([_note(1, 'x')])),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.dark_mode));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.light_mode), findsOneWidget); // 图标随主题翻转
  });
}
```

- [x] **Step 7: 验证（含 windows 构建）+ Commit**

```bash
cd /g/code/guide/flutter
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 20_notes
git add examples && git commit -m "feat(flutter): 示例 20_notes 实战记事本

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

预期：analyze 零告警、6 个测试全绿、windows --debug 构建成功（首跑约 2–4 分钟）。

---

### Task 10: docs/01-overview.md + docs/02-hello.md + docs/03-widgets.md + docs/04-layout-single.md

**Files:**
- Create: `docs/01-overview.md`（无示例，引用 `examples/02_hello/`）
- Create: `docs/02-hello.md`（示例 `examples/02_hello/`）
- Create: `docs/03-widgets.md`（示例 `examples/03_widgets/`）
- Create: `docs/04-layout-single.md`（示例 `examples/04_layout_single/`）

**Interfaces:**
- Consumes: Task 3 的三个工程（片段按 `// ═══ N.M` 摘录）。
- Produces: docs/ 目录与首批四章；后续章节沿用行文结构。

- [x] **Step 1: 写 01-overview.md**（约 150 行）：
  1. `# 01 · Flutter 全景：一套代码，多端一致`
  2. Flutter 是什么：Google UI 框架、自绘引擎（不映射原生控件）；与"WebView 套壳/原生桥接"路线对比表
  3. 三层架构表：Framework（Dart，Widget 层）/Engine（C++，Skia/Impeller 渲染、Dart VM）/Embedder（各平台宿主）；"为什么 Windows 上能跑"
  4. 一切皆 Widget 的心智模型：UI = widget 树 = 不可变配置；`setState` 触发重建（预告 08 章）
  5. 与 Dart 的关系：语言底座是 Dart——引用 `[Dart 教程·第 01 章](../dart/docs/01-overview.md)`；本教程假设已具备等价知识；速查表（本教程哪章会用到 Dart 哪章：命名参数/Future/JSON 等）
  6. 工具链速查表：flutter run/build/analyze/test/pub/clean/create；`flutter run -d windows` 热重载工作流（r/R 键说明）
  7. 工程解剖：flutter create 产物表（lib/test/pubspec/windows/README），pubspec 管理 Flutter SDK 依赖的差异
  8. 本教程工作流与 build.ps1（-All/-Project/-Clean；pwsh 7；分级验证说明）
  9. 20 章路线图（入门 02–07 / 状态与数据 08–14 / 打磨与交付 15–20）
  10. `## 坑位清单`：热重载改不了 main() 入口需热重启、flutter clean 后首次构建慢、生成物（ephemeral/build）别提交、Windows 构建需 VS 组件

- [x] **Step 2: 写 02-hello.md**（约 130 行）：
  1. `# 02 · 第一个应用：从 create 到热重载`
  2. flutter create 命令与产物（引用工程结构）；`--project-name` 与目录名分离的坑（包名不能数字开头）
  3. runApp 与 widget 树挂载（引用 2.1）；`main() => runApp(...)` 的形状
  4. MaterialApp：应用级外壳（title/theme/home）；Scaffold：页面骨架六插槽图（AppBar/body/FAB/drawer/bottomNavigationBar…）（引用 2.2/2.3）
  5. theme 初识：ColorScheme.fromSeed（一颗种子生成整套色板；预告 16 章）
  6. 热重载工作流：保存即生效、状态保留 vs 热重启；哪些改动必须重启（main、全局、常量）
  7. flutter run -d windows 与退出；widget 测试初见（工程自带 test 怎么跑）（连第 19 章）
  8. `## 坑位清单`：const 漏写引发的无谓重建、Text 默认不可选（桌面注意，连 18 章）、运行设备列表 `flutter devices`、中文乱码与编码

- [x] **Step 3: 写 03-widgets.md**（约 160 行）：
  1. `# 03 · Widget：不可变的配置树`
  2. 问题先行：为什么改 UI 不"改"而是"重建"——Widget 是**不可变配置**（对比 DOM 可变节点）；组合优于继承（对比 WinForms 控件继承体系）
  3. StatelessWidget 与 build（引用 3.1）：build 什么时候被调、纯函数性（同输入同 UI）
  4. 展示组件速览表（引用 3.2）：Text/Icon/CircleAvatar/Card/ListTile/Divider——各一句话与常用参数
  5. 组合的威力（引用 3.3）：ProfileCard = Card+ListTile+Icon；嵌套深了怎么读（缩进即结构；IDE 的 build_runner/Flutter Inspector 提及）
  6. const 的复用价值（引用 3.4）：同一 const widget 实例被复用、跳过重建——lint 强制不是强迫症（连 [Dart 教程·第 03 章](../dart/docs/03-values.md) const 深度不可变）
  7. Widget/Element/RenderObject 三树一瞥：配置树 vs 实例树 vs 布局树——为什么 setState 只重建子树（不展开原理，给心智模型）
  8. `## 坑位清单`：build 里做重活/发请求（应放 initState/事件）、在 build 里创建 TextEditingController（应放 State 字段）、忘 dispose 控制器、直接 new 对象当 child（应 const）

- [x] **Step 4: 写 04-layout-single.md**（约 150 行）：
  1. `# 04 · 布局 I：容器与装饰`
  2. Flutter 布局心智模型：约束传递（父给约束、子报尺寸）——一句话版 + "想深入看官方 Understanding constraints"指引
  3. Padding/EdgeInsets（引用 4.1）：all/symmetric/only/fromLTRB；SizedBox 撑空隙/固定尺寸；为什么有 Padding 组件而不是 padding 属性（一切皆 Widget）
  4. Container（引用 4.2）：盒子模型（margin/padding/装饰/尺寸）；BoxDecoration 四件套表（color/borderRadius/border/boxShadow）；Container vs ColoredBox vs SizedBox（性能一句话：无参数 Container 直接是 child）
  5. Align/Center（引用 4.3）：Alignment 九宫格坐标（-1..1）；Center = Alignment.center 特例；FractionalOffset 一句话
  6. 尺寸语义速查：double.infinity/MainAxisSize.max 一览
  7. `## 坑位清单`：Container 无约束时 width: infinity 会怎样、把 SizedBox 当"div"无脑套、阴影被父级裁剪（ClipRect）、EdgeInsets.only 拼四个方向的写法

- [x] **Step 5: 验证 + Commit**

```bash
cd /g/code/guide/flutter && wc -l docs/*.md
```

预期：各 100–200 行；抽查 2.1/3.4/4.2 与 examples 逐字一致。

```bash
git add docs && git commit -m "docs(flutter): 第 01–04 章 全景、hello、Widget、容器布局

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 11: docs/05-layout-multi.md + docs/06-material.md + docs/07-interaction.md + docs/08-stateful.md

**Files:**
- Create: `docs/05-layout-multi.md`（示例 `examples/05_layout_multi/`）
- Create: `docs/06-material.md`（示例 `examples/06_material/`）
- Create: `docs/07-interaction.md`（示例 `examples/07_interaction/`）
- Create: `docs/08-stateful.md`（示例 `examples/08_stateful/`）

- [x] **Step 1: 写 05-layout-multi.md**（约 160 行）：
  1. `# 05 · 布局 II：线性、弹性与层叠`
  2. Row/Column（引用 5.1）：同构（verticalDirection/textDirection）；主轴/交叉轴概念图（文字版）
  3. MainAxisAlignment 五种值表（引用 5.1）+ crossAxisAlignment（默认 center；stretch 的效果）
  4. Expanded/Flexible（引用 5.2）：flex 比例瓜分 vs 按需+让步；"Row 里放不受约束的孩子会溢出"的 YellowStripe 报错讲解
  5. Stack/Positioned（引用 5.3）：alignment 兜底 + Positioned 精确定位；fit: expand
  6. 布局选型表：单子用上一章容器；横向 Row、纵向 Column、悬浮角标 Stack、可滚动 ListView（预告 12 章）
  7. `## 坑位清单`：RenderFlex overflow 的三种解法（Expanded/可滚动/缩字）、mainAxisSize.min 在无限父约束下的行为、Stack 第一个孩子决定尺寸、Positioned 必须直接父级是 Stack

- [x] **Step 2: 写 06-material.md**（约 170 行）：
  1. `# 06 · Material 组件库：搭积木的说明书`
  2. Material Design 与 Flutter 的关系：组件库只是 widget（ Cupertino 另一套一句话）
  3. Scaffold 六插槽表（引用 6.1）：appBar/body/floatingActionButton/drawer/bottomNavigationBar/endDrawer——各一句话与常用组件
  4. AppBar 与 Drawer（引用 6.2）：自动加 menu 图标；DrawerHeader/UserAccountsDrawerHeader
  5. NavigationBar（引用 6.3）：M3 底部导航（selectedIndex/onDestinationSelected 四件套）
  6. 信息组件：Card/ListTile（leading/title/subtitle/trailing 四位）、Chip、Divider（引用 6.4）；ListTile 密度与 onTap
  7. 按钮家族表：FilledButton/OutlinedButton/TextButton/IconButton/FloatingActionButton——层级递减的使用场景
  8. `## 坑位清单`：ListTile 里塞长文本不换行（isThreeLine/expanded）、Drawer 里第一个可滚动子项必须是 ListView（防顶部 unsafe area）、NavigationBar 与 BottomNavigationBar（M2 旧版）混淆、Card 默认 margin

- [x] **Step 3: 写 07-interaction.md**（约 150 行）：
  1. `# 07 · 交互与对话框：点击、轻提示、确认`
  2. InkWell vs GestureDetector（引用 7.1/7.2）：水波纹材质反馈 vs 原始手势；onTap/onDoubleTap/onLongPress 手势速查表
  3. 回调即交互：onPressed 传函数（连 [Dart 教程·第 05 章](../dart/docs/05-functions.md) 匿名函数/箭头）
  4. AlertDialog（引用 7.3）：showDialog + builder；actions 顺序；返回值（pop(true/false)）与 await —— 10 章导航伏笔
  5. SnackBar（引用 7.4）：ScaffoldMessenger.of(context)；为什么不是 context.scaffold（嵌套 Scaffold 的语义）；duration
  6. 模态 BottomSheet（引用 7.5）：showModalBottomSheet；与 Dialog 的选用
  7. `## 坑位清单`：async 回调里用 context 前忘 context.mounted（lint 会拦）、SnackBar 在 Scaffold 外调用报错、Dialog 不关就 push 新页面（栈混乱）、onPressed: null 与 onPressed: () {} 的区别（禁用 vs 空操作）

- [x] **Step 4: 写 08-stateful.md**（约 180 行）：
  1. `# 08 · 有状态 Widget：setState 与生命周期`
  2. 问题先行：03 章说 Widget 不可变——那数据变了怎么办？答案：StatefulWidget 拆成"配置（不可变）+ State（可变，长期存活）"
  3. 声明骨架（引用 8.1）：createState/State 类；为什么 State 是 public 而状态字段建议私有（_count）
  4. setState（引用 8.4）：不是"赋值"而是"标记重建"；等价于"改状态 + 通知框架"；忘记 setState 界面不动
  5. 生命周期表（引用 8.2）：initState（一次性准备、读 prefs/发请求）→ build（多次）→ dispose（释放 controller/订阅）；didUpdateWidget 一句话
  6. TextEditingController（引用 8.3）：预填、读取、监听；dispose 纪律；示例中"刷新问候"按钮演示 TextField 不自动触发重建
  7. 重建范围与性能：setState 重建整个 State 的 build；小部件拆分 State 限制重建范围（连 09 章）
  8. `## 坑位清单`：build 里 setState（死循环）、initState 里同步调 ScaffoldMessenger/Navigator（时机过早）、dispose 后用 controller、State 字段能不变就 final（只把真正会变的设为可变）

- [x] **Step 5: 验证 + Commit**

```bash
cd /g/code/guide/flutter && wc -l docs/05*.md docs/06*.md docs/07*.md docs/08*.md
```

预期：各 100–200 行（08 可到 200）；抽查 5.2/6.3/7.4/8.2 与 examples 逐字一致。

```bash
git add docs && git commit -m "docs(flutter): 第 05–08 章 线性层叠布局、Material、交互、有状态

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 12: docs/09-state-sharing.md + docs/10-navigation.md + docs/11-forms.md + docs/12-lists.md

**Files:**
- Create: `docs/09-state-sharing.md`（示例 `examples/09_state_sharing/`）
- Create: `docs/10-navigation.md`（示例 `examples/10_navigation/`）
- Create: `docs/11-forms.md`（示例 `examples/11_forms/`）
- Create: `docs/12-lists.md`（示例 `examples/12_lists/`）

- [x] **Step 1: 写 09-state-sharing.md**（约 170 行）：
  1. `# 09 · 状态提升与共享：数据放哪`
  2. 问题先行：两个兄弟组件要读同一份数据——状态放公共祖先（提升），还是放进"全局"？两个世界都要懂
  3. 状态提升（引用 9.1）：回调上抛 + 数据下放；CartPage 的 adder/viewer 例；单数据流方向（Flutter 界的 Flux 气质）
  4. ChangeNotifier（引用 9.3）：可监听的状态对象；notifyListeners；与 setState 的关系（谁监听谁重建）
  5. InheritedWidget（引用 9.4）：沿树向下广播、dependOn 建"依赖关系"自动重建；InheritedNotifier 组合拳；"of(context)" 是惯用形（Theme.of 同款——点破 06 章伏笔）
  6. **生态选型表**：原生（本教程）→ provider（官方风格封装）→ Riverpod（编译期安全）→ Bloc（流式大项目）；建议"先原生后生态，知道痛点再上工具"
  7. `## 坑位清单`：notifyListeners 忘了调用（界面不动）、InheritedWidget 每次 notify 重建整棵子树（粒度控制）、把可变对象直接塞 const 构造、setState 提升后又全树重建（该上 InheritedNotifier）

- [x] **Step 2: 写 10-navigation.md**（约 150 行）：
  1. `# 10 · 导航与路由：页面的栈`
  2. 心智模型：Navigator 是**栈**不是"页面注册表"；push/pop 即进栈出栈
  3. push 与 MaterialPageRoute（引用 10.1）：builder 惰性建页；**push 返回 Future**——await 拿返回值（连 [Dart 教程·第 15 章](../dart/docs/15-async.md)）
  4. pop 带返回值（引用 10.1 续）：Navigator.pop(context, value)；系统返回键/关闭按钮是 null——?? 兜底
  5. 构造传参（引用 10.2）：参数进 Widget 构造（不可变配置的一部分）；复杂对象传整只
  6. 命名路由（引用 10.3）：routes 表 + pushNamed；onGenerateRoute 带参一句话（传参复杂时的形态）
  7. 桌面特有：路由动画在桌面默认也是 Material 过渡；Alt+Left 返回行为一句话
  8. `## 坑位清单`：async gap 后用 context（mounted 检查，示例代码有）、push 后 pop 两次（栈失衡）、routes 表 '/' 必须存在、嵌套 Navigator（标签页各持独立栈）一瞥

- [x] **Step 3: 写 11-forms.md**（约 150 行）：
  1. `# 11 · 表单：校验与提交`
  2. Form/GlobalKey<FormState>（引用 11.1）：Form 是"校验域"，钥匙调 validate()/save()/reset()
  3. TextFormField（引用 11.2）：validator 返回错误文案或 null；obscureText/keyboardType/autofocus 参数表
  4. validate 与 save 流程（引用 11.3）：submit 一按全表单校验；onSaved 与 controller 两套取值方式对比表
  5. 焦点链：FocusNode/FocusScope 一节（autofocus 够用的小表单；键盘回车跳下一格的 onFieldSubmitted）
  6. 桌面差异：输入即触发校验的时机（autovalidateMode）、Tab 顺序默认按树序
  7. `## 坑位清单`：validate() 前忘挂 GlobalKey（ currentState! 崩）、validator 忘 return null（永远报错）、controller 与 onSaved 混用取值（一套就好）、dispose 漏掉 controller

- [x] **Step 4: 写 12-lists.md**（约 160 行）：
  1. `# 12 · 列表与滚动：从十条到十万条`
  2. 问题先行：Column 装一千条会怎样（全量构建+溢出）——ListView 懒构建按需建
  3. ListView 四形态表：children（少量）/builder（大量）/separated（分隔线）/custom（完全定制）
  4. ListView.separated（引用 12.1）：itemCount/itemBuilder/separatorBuilder 三件；CircleAvatar 序号头
  5. GridView.count（引用 12.2）：crossAxisCount/childAspectRatio；SliverGrid 一句话
  6. CustomScrollView 与 Sliver 一瞥：多个滚动区拼一屏（SliverAppBar 折叠头图一段文字）；ScrollView 中心智
  7. 控制滚动：ScrollController（jumpTo/animateTo）；滚到顶按钮小例（连 18 章 Scrollbar）
  8. `## 坑位清单`：ListView 嵌 ListView（内层必须 shrinkWrap/固定高，或该用 CustomScrollView）、itemBuilder 里闭包捕获索引错位、分隔线计入 itemCount 的坑（separated 不用）、没给 itemCount（无限列表）

- [x] **Step 5: 验证 + Commit**

```bash
cd /g/code/guide/flutter && wc -l docs/09*.md docs/10*.md docs/11*.md docs/12*.md
```

预期：各 100–200 行；抽查 9.4/10.1/11.3/12.1 与 examples 逐字一致。

```bash
git add docs && git commit -m "docs(flutter): 第 09–12 章 状态共享、导航、表单、列表

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 13: docs/13-http-json.md + docs/14-async-ui.md + docs/15-animation.md + docs/16-theme.md

**Files:**
- Create: `docs/13-http-json.md`（示例 `examples/13_http_json/`）
- Create: `docs/14-async-ui.md`（示例 `examples/14_async_ui/`）
- Create: `docs/15-animation.md`（示例 `examples/15_animation/`）
- Create: `docs/16-theme.md`（示例 `examples/16_theme/`）

- [x] **Step 1: 写 13-http-json.md**（约 170 行）：
  1. `# 13 · 网络与 JSON：数据从远方来`
  2. Dart 异步底座回顾：Future/await（链 [Dart 教程·第 15 章](../dart/docs/15-async.md)）
  3. http 包（引用 13.1）：`http.get(Uri)`；为什么用它而不是裸 HttpClient（API 友好；两者关系）；pubspec 添加依赖
  4. 数据建模 fromJson（引用 13.2）：模型类 + factory；链 [Dart 教程·第 18 章](../dart/docs/18-files-json-http.md) 的完整模板
  5. 自测型后端（引用 13.4）：示例内置 localhost HttpServer——学习零外网依赖；与 [Dart 教程·第 18 章](../dart/docs/18-files-json-http.md) 同款技巧
  6. 消费数据（引用 13.3）：initState 发请求 + FutureBuilder 展示（展开留 14 章）
  7. **依赖注入与可测性**（引用 13.5）：页面收 `Future<List<NewsItem>> Function()`；测试注入假 fetcher——"边界隔离"设计观
  8. 错误处理：状态码检查/超时一句带过；测试断言失败态
  9. `## 坑位清单`：build 里发请求（每次重建都发）、jsonDecode 结果裸用（连 Dart 18 章坑位）、忘了 Content-Type（自建 server 演示可见）、真实 app 的 API key 别写死在代码里

- [x] **Step 2: 写 14-async-ui.md**（约 160 行）：
  1. `# 14 · 异步 UI：把 Future 画出来`
  2. 问题先行：Future 还没完成时界面显示什么？FutureBuilder 把"三态渲染"模板化
  3. FutureBuilder（引用 14.1）：connectionState 分支表（none/waiting/done）；done 里再分 data/error；示例用 switch 表达式（连 [Dart 教程·第 13 章](../dart/docs/13-records-patterns.md)）
  4. **future 存 State 不存 build**（引用 14.2）：build 里现造 Future = 每次重建重新请求——本章第一大坑
  5. StreamBuilder（引用 14.3）：序列数据；示例 periodic+take 有限流；done 语义
  6. 加载/错误/空 三态设计表：CircularProgressIndicator/ErrorText/空提示；骨架屏一句话
  7. 手写 vs Builder：为什么不用 setState+Future.then 手搓（模板代码量对比）
  8. `## 坑位清单`：future 参数每次 build 换新实例、StreamBuilder 的 stream 同理、snapshot.data 在 waiting 期是 null（! 崩）、失败后无重试入口（加刷新按钮的模式）

- [x] **Step 3: 写 15-animation.md**（约 160 行）：
  1. `# 15 · 动画：隐式、Hero 与显式`
  2. 动画三档表：隐式（AnimatedXxx）/转场共享（Hero）/显式（Controller）——复杂度与控制力递增
  3. 隐式动画（引用 15.1）：改属性即动；duration/curve；AnimatedContainer/AnimatedOpacity/AnimatedSwitcher 三常客
  4. Hero（引用 15.2）：同 tag 跨页飞；tag 匹配规则；只有一次转场机会
  5. 显式动画（引用 15.3）：AnimationController 0→1；vsync/TickerProviderStateMixin；addListener+setState；forward(from:)/reverse/repeat；dispose 纪律；Tween/CurvedAnimation 一句话
  6. 桌面动画口味：桌面用户对动画更"耐短"——duration 建议表
  7. `## 坑位清单`：Controller 忘 dispose、vsync 忘 with（编译错）、repeat() 让 pumpAndSettle 永不结束（测试场景）、AnimatedXxx 的属性没变就不动（值相同不触发）

- [x] **Step 4: 写 16-theme.md**（约 160 行）：
  1. `# 16 · 主题与响应式：一处定义，处处生效`
  2. ThemeData 与 ColorScheme.fromSeed（引用 16.1）：种子色生成整套色板；light/dark 两套 + themeMode 三态
  3. 主题切换（引用 16.2）：themeMode 状态在根 State；SegmentedButton（M3 分段选择）
  4. 语义色（引用 16.3）：Theme.of(context).colorScheme.primary/surface/onPrimary——**不写死颜色**；角色速查表
  5. 字体/组件主题定制：textTheme 一瞥；组件级 theme（AppBarTheme 等）一句话
  6. 响应式（引用 16.4）：LayoutBuilder 拿约束换布局；500px 断点示例；MediaQuery（屏幕尺寸/安全区）对比表；桌面窗口可任意拖宽——响应式是桌面刚需
  7. `## 坑位清单`：写死 Colors.black 在深色模式翻车、Theme.of 在 builder 外缓存（重建不更新）、断点用屏幕宽而非约束宽（嵌套场景错）、SegmentedButton selected 是 Set

- [x] **Step 5: 验证 + Commit**

```bash
cd /g/code/guide/flutter && wc -l docs/13*.md docs/14*.md docs/15*.md docs/16*.md
```

预期：各 100–200 行；抽查 13.5/14.2/15.3/16.4 与 examples 逐字一致。

```bash
git add docs && git commit -m "docs(flutter): 第 13–16 章 网络JSON、异步UI、动画、主题

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 14: docs/17-persist.md + docs/18-desktop.md + docs/19-testing.md + docs/20-notes.md

**Files:**
- Create: `docs/17-persist.md`（示例 `examples/17_persist/`）
- Create: `docs/18-desktop.md`（示例 `examples/18_desktop/`）
- Create: `docs/19-testing.md`（示例 `examples/19_testing/`）
- Create: `docs/20-notes.md`（示例 `examples/20_notes/`）

- [x] **Step 1: 写 17-persist.md**（约 150 行）：
  1. `# 17 · 数据持久化：记住用户的世界`
  2. 三档选型表：键值（shared_preferences）/文件（dart:io JSON）/数据库（sqflite 生态一句话）
  3. shared_preferences（引用 17.2）：getInstance/setInt/getInt；异步性；Windows 下的存储位置一句话（注册表/文件由插件管）；**setMockInitialValues** 测试法
  4. 文件（引用 17.1/17.3）：FileCounter 类封装读写；exists 兜底；路径策略（systemTemp 演示 vs path_provider 应用目录）
  5. 模型序列化：链 [Dart 教程·第 18 章](../dart/docs/18-files-json-http.md)（toJson/fromJson 模板不重讲）
  6. 真实 IO 与 widget 测试：普通 test() 做 IO 往返、widget 测试用注入/mock——两层测试策略（示例 test 文件即范本）
  7. `## 坑位清单`：prefs 的 await 忘写（读到旧值）、文件路径依赖 cwd、initState 同步读 prefs 拿不到（异步加载后 setState）、大量结构化数据硬塞 prefs

- [x] **Step 2: 写 18-desktop.md**（约 160 行）：
  1. `# 18 · 桌面专题：Windows 的一等公民`
  2. 桌面与移动的差异表：窗口可拉伸（响应式刚需）、鼠标（右键/滚轮/悬停）、键盘直达、无触屏手势
  3. 构建与发布（引用 build 命令）：`flutter build windows --debug/--release`；产物路径与 exe；--release 体积/启动对比；打包（zip/msix 一句话）
  4. 菜单栏（引用 18.1）：MenuBar/SubmenuButton/MenuItemButton——桌面 App 的标配
  5. SelectionArea（引用 18.2）：文本可选复制——桌面用户预期；默认 Text 不可选的坑
  6. Scrollbar（引用 18.3）：桌面惯常可见滚动条；ScrollController 联动（连 12 章）
  7. 窗口控制：标题/初始尺寸在 windows/runner/main.cpp（ShowWindow）——改原生侧一句带过；多窗口暂不官方支持一句话
  8. 鼠标交互：Listener/ MouseRegion 一节（悬停/右键 SecondaryTap）
  9. `## 坑位清单`：debug 与 release 行为差异（断言/性能）、exe 缺 dll（产物整目录拷贝）、ScrollView 无滚动条、触屏组件习惯用在桌面（间距/命中区域过小）

- [x] **Step 3: 写 19-testing.md**（约 160 行）：
  1. `# 19 · Widget 测试：自动化的界面验证`
  2. 分层表：纯逻辑单元测试（dart test）vs widget 测试（flutter_test）vs 集成测试（integration_test 一句话）——成本/速度/覆盖递增
  3. 纯逻辑层（引用 19 工程 counter_test.dart）：与 [Dart 教程·第 19 章](../dart/docs/19-testing.md) 同一套（package:test 与 flutter_test 兼容）；负例 throwsStateError
  4. testWidgets 骨架：pumpWidget 起"渲染一帧"；FakeAsync 时钟（pump(duration) 推进动画/定时器）
  5. finders 表：find.text/byType/byIcon/byKey/widgetWithText——选哪个
  6. 交互动作：tap/enterText/longPress/drag；pump vs pumpAndSettle 的区别表（动画没结束时 settle 等不完的坑）
  7. 可测性设计：依赖注入（13 章 fetcher 模式）、存储抽象（20 章）——好测的代码长什么样
  8. 跑法：flutter test / --plain-name / --coverage；本教程 build.ps1 -All 的全量验证即此
  9. `## 坑位清单`：真实网络/文件进 widget 测试（应注入/mock）、pumpAndSettle 配 repeat 动画死等、find.text 找到多个（N 个同文案）、异步 setState 后忘 pump

- [x] **Step 4: 写 20-notes.md**（约 200 行，实战章）：
  1. `# 20 · 实战：记事本`
  2. 成品演示：功能走查（列表/新建/编辑/删除/主题）+ `flutter run -d windows` 演示序列
  3. 工程结构讲解：lib 多文件分层（main/note/storage/edit_page）；"入口薄、模型纯、存储抽象、页面组页"
  4. 建模（note.dart）：Note + fromJson/toJson/copyWith（链 [Dart 教程·第 20 章](../dart/docs/20-todo.md) 同款思路）；DateTime 手动序列化的坑
  5. 存储抽象（storage.dart）：NotesStorage 接口 + FileNotesStorage；为什么抽象（测试注入 + 换实现不痛）
  6. 列表页（main.dart）：加载态/空态/列表三态；新建与编辑共用 _openEditor；insertOrUpdate 模式；长按删除确认（07 章）
  7. 编辑页（edit_page.dart）：controller 初始化（widget.note 的惯用法 late final）；保存即 pop 带值（10 章）
  8. 主题切换：根 State 持 themeMode（16 章模式复用）
  9. 测试（notes_test.dart）：内存存储注入的六个用例走查——每个用例验证什么行为
  10. 扩展方向：搜索过滤、markdown 渲染、系统托盘（生态）、自动保存防抖、多窗口（等官方）
  11. `## 坑位清单`：DateTime 直接 jsonEncode 不报错但存成 String 要手转、saved 后忘记 save 回存储（内存与盘不一致）、push 回来 mounted 检查、空标题笔记的展示兜底（（无标题））

- [x] **Step 5: 验证 + Commit**

```bash
cd /g/code/guide/flutter && wc -l docs/17*.md docs/18*.md docs/19*.md docs/20*.md && ls docs | wc -l
```

预期：各 100–200 行（20 章可到 220）；docs/ 共 20 个文件。

```bash
git add docs && git commit -m "docs(flutter): 第 17–20 章 持久化、桌面、测试、实战记事本

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 15: README.md 重写 + CHEATSheet.md 新增

**Files:**
- Create: `README.md`（重写）
- Create: `CHEATSheet.md`

- [x] **Step 1: 重写 README.md**（约 70 行，对齐 dart 教程 README 格式）：
  1. 标题 `# Flutter 开发指南`；定位段：面向**会编程、已具备 Dart 基础**的读者；Dart 语言请先读 [Dart 教程](../dart/README.md)（本教程只讲框架层）；主线 Flutter 3.47、Windows 桌面
  2. 目录结构代码块（README/docs/examples/build.ps1/CHEATSheet.md 各一行注释）
  3. **章节索引表**（20 行三列：章主题链接 | 主题 | 示例目录）
  4. 构建工具链：flutter.bat 路径；pwsh 7 要求；Windows 构建需 VS 桌面开发组件
  5. 编译验证命令块（-All/-Project/-Clean + 行为分级一句话：analyze+test 全量、02_hello 与 20_notes 额外 windows 构建）
  6. 单跑某个示例：`cd examples/06_material && flutter run -d windows`（标准学法：跑起来改一改热重载）

- [x] **Step 2: 写 CHEATSheet.md**（约 200 行）：
  1. `# Flutter 速查表`（开头注明配教程使用、按章号引用）
  2. 命令速查：create/run/analyze/test/build/pub/clean + 热重载键位
  3. 工程结构：create 产物一表 + pubspec 骨架
  4. Widget 分类速查表：展示（Text/Icon/Image）/布局单子（Container/Padding/Align/SizedBox）/多子（Row/Column/Stack/Expanded）/滚动（ListView×4/GridView）/Material（Scaffold 六插槽/Card/ListTile/按钮家族）
  5. 交互：InkWell/GestureDetector 手势表、Dialog/SnackBar/BottomSheet 骨架
  6. 状态：setState 骨架、生命周期表、ChangeNotifier+InheritedNotifier 骨架、提升模式图
  7. 导航：push/pop/pushNamed/返回值骨架
  8. 表单：GlobalKey+validator 骨架
  9. 异步 UI：FutureBuilder/StreamBuilder 三态骨架 + future 存 State 的提醒
  10. 动画：AnimatedXxx 一行、Hero 一行、Controller 骨架
  11. 主题：fromSeed 两套+themeMode、语义色表
  12. 持久化：prefs 三行、文件三行
  13. 测试：testWidgets 骨架、finders 表、pump vs pumpAndSettle

- [x] **Step 3: Commit**

```bash
git add README.md CHEATSheet.md && git commit -m "docs(flutter): 重写 README、新增 CHEATSheet

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 16: 终验（全量 -All + 一致性检查）

**Files:**
- 无新文件（发现问题回修后重跑）

- [x] **Step 1: 全量验证**

```bash
cd /g/code/guide/flutter && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All 2>&1 | tail -30
```

预期（逐项核对）：19 个工程各 `[PubGet][Analyze][Test]` 全过（analyze 零告警、测试 +N 全绿）；02_hello 与 20_notes 额外 `[BuildWin]` 成功（`✓ Built …`）；末行 `[Done]`。首跑约 10–15 分钟。

- [x] **Step 2: 一致性与卫生检查**

```bash
cd /g/code/guide/flutter && ls docs | wc -l && ls examples | wc -l && wc -l docs/*.md | tail -1
git ls-files examples | grep -cE "ephemeral|\.idea/|\.iml|pubspec.lock" || echo "生成物零跟踪 OK"
grep -c "docs/" README.md && grep -rn "../dart/docs/" docs | wc -l
```

预期：docs 20 个、examples 19 个、docs 总行数 2900–3900；生成物零跟踪；README 含 20 个 docs/ 链接；docs 对 Dart 教程的交叉引用 ≥ 10 处。抽查三章代码片段与 examples 逐字一致（2.1/11.3/20.5）。

- [x] **Step 3: 清理与收尾**

```bash
cd /g/code/guide/flutter && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Clean && git status --short
```

预期：`git status` 干净（build/.dart_tool/ephemeral 全被忽略）。若有未提交变更，补提交。

- [x] **Step 4: Commit（如有收尾变更）**

```bash
git add -A && git commit -m "chore(flutter): 教程终验收尾

Co-Authored-By: Claude Code <noreply@anthropic.com>" || echo "无收尾变更，跳过"
```

## 执行勘误（2026-09-17 实施时对计划的修正）

| 位置 | 偏差 | 原因 |
|---|---|---|
| Task 3 三工程测试 | 补 `import 'package:flutter/material.dart';` | 测试引用 FloatingActionButton/Card/Icons/Key |
| Task 3 示例 03 | `const ListView(...)` → `ListView(children: const [...])`；类名 `WidgetsApp` → `WidgetsDemoApp` | ListView 构造非常量；与 Flutter 内置 WidgetsApp 撞名 |
| Task 4 示例 07 | 双击测试末尾补 `pump(100ms)`；测试去 material import | 双击识别器 40ms 收尾定时器触发 "Timer is still pending"；unused_import |
| Task 5 示例 09 | CartScope 去 const（Cart() 非常量）、child 改 super 参数 | ChangeNotifier 无 const 构造 |
| Task 6 示例 12 | 列表从 12 个水果改为 40 条编号条目；滚动测试改 `dragUntilVisible(ListView)`；`(_, __)`→`(_, _)` | 12 条全被 cacheExtent 建出来（懒构建断言不成立）；scrollUntilVisible 的 scrollable 定位失败；unnecessary_underscores |
| Task 7 示例 14 | setState 回调改块体（箭头返回 Future 被拒）；`Future.error` 加 `..ignore()`；tick 测试改手动逐格 pump | setState 纪律；测试 zone 判"未处理异步错误"；pumpAndSettle 在无帧调度的 tick 间提前返回 |
| Task 7 示例 15 | AnimatedContainer 外包 Center | ListView 紧约束顶满 width（04 章 Align 放松约束的实战例） |
| Task 8 示例 17 | pubspec 手工合并 shared_preferences 时全文重写 | 保持模板其余段 |
| Task 9 20_notes 测试 | InMemoryStorage.load 返回 `[...seed]` 拷贝 | 返回 const 原表导致页面 insert 抛 unmodifiable |
| Task 10–14 docs | 若干章行数 65–100 行（低于 100–200 目标） | 内容按大纲完整覆盖、以密度优先；抽查片段与示例逐字一致 |

全部偏差不改变章节结构、小节编号与教学语义。
