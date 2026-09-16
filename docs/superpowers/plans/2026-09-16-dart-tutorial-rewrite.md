# Dart 教程重写实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 `dart/` 从"单文件代码堆砌 + 嵌套工程"重写为 20 章自学教程（docs/ 分章 + 17 个单文件示例 + 2 个嵌套工程 + 实战收尾章），全部示例 `build.ps1 -All` 运行、分析、测试通过。

**Architecture:** 删除旧 `dart/dart/` 嵌套工程与单文件指南，建立扁平根包（pubspec + lints + test）；`examples/02…18` 为仅标准库的单文件示例，`19_testing/`、`20_todo/` 为嵌套 pub 工程；`docs/` 20 章讲解为主、短代码片段为辅（片段从示例逐字摘录）；build.ps1（pwsh 7）分级验证：analyze → 逐个运行 → AOT 编译 02_hello → 嵌套包 test → 20 演示序列 → 根 test。

**Tech Stack:** Dart SDK 3.13（JIT `dart run` / AOT `dart compile exe`）、package:test、package:lints、dart:io / dart:convert / dart:async / dart:isolate、PowerShell 7 构建脚本、Markdown。

**Spec:** `G:\code\guide\docs\superpowers\specs\2026-09-16-dart-tutorial-rewrite-design.md`（本计划依 spec 而写，执行者两份都要读）

## Global Constraints

- 工作目录：`G:\code\guide\dart`（bash 路径 `/g/code/guide/dart`）；仓库根 `G:\code\guide`。
- Dart 可执行文件：`G:\scoop\apps\dart\current\bin\dart.exe`（3.13.4；build.ps1 内已处理回退扫描，勿改）。
- 示例文件命名：`NN_snake_case.dart`（`file_names` lint 强制小写下划线）；文档命名：`NN-kebab-case.md`。
- SDK 约束一律 `^3.13.0`；dev 依赖一律 `lints: ^6.0.0` + `test: ^1.26.0`（已验证可解析）。
- **根包与嵌套包的 analysis_options.yaml 一律为**：

  ```yaml
  include: package:lints/recommended.yaml
  ```

- **示例分节注释约定**：每个示例用 `// ═══ N.M 小节名 ═══` 分节，编号与本章文档小节编号一致（docs 任务按小节号逐字摘录代码）。
- 代码风格：dartfmt 风格（2 空格缩进、单引号优先）；若 `dart analyze` 报出等效风格问题，允许做最小修正，但语义/小节结构不得变。
- **所有示例必须确定退出**：HTTP 示例用随机端口 + 显式 close；Isolate 示例关闭 ReceivePort；Stream 示例显式 close controller——不允许有挂起等待。
- **章节写作模板**（每章必须遵守）：
  - 文件名 `NN-kebab-case.md`；首行标题 `# NN · 主题：副标题`；第二行引用块 `> 对应示例：examples/NN_name.dart`（第 01 章无此行，改引用 `examples/02_hello.dart`；19/20 章引用目录名）。
  - 结构：`## N.M` 起编号小节；**先讲"解决什么问题"再讲语法**；代码段配讲解；对比用表格；结尾 `## 坑位清单`（按命中率排序）。
  - 跨章引用格式：`第 12 章`（不带文件名）。章节内代码片段必须与 `examples/` 实际代码**逐字一致**（省略处标 `// …`）。
  - 每章 100–200 行（重点章可到 220）；中文行文。
  - 风格范本（每章动笔前先读）：`G:\code\guide\fsharp\docs\04-functions.md` 与 `G:\code\guide\fsharp\docs\06-collections.md`。
- **build.ps1 运行环境坑**：脚本含中文且无 BOM，**必须用 pwsh 7 运行**（本机 bash 路径 `/g/Program Files/PowerShell/7/pwsh`）；编辑时保持无 BOM。
- 构建验证命令（所有"验证构建"步骤统一用）：

  ```bash
  cd /g/code/guide/dart && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
  ```

- 单文件示例验证：`... -File 06_collections.dart`；嵌套包验证：`... -Project 20_todo`。
- 提交规范：中文 conventional 风格（`feat(dart):` / `docs(dart):` / `chore(dart):` 前缀），结尾必须带：
  `Co-Authored-By: Claude Code <noreply@anthropic.com>`
- 每个 Task 结束时 `git status` 应干净（本 Task 变更已提交）。

## 已核实的平台事实（执行者不得凭记忆改动）

| 事实 | 内容 | 来源 |
|---|---|---|
| SDK 版本 | **3.13.4 (stable)**（2026-09-15 构建），`G:\scoop\apps\dart\current\bin\dart.exe` | 2026-09-16 `dart --version` 实测 |
| 依赖可解析 | `lints ^6.0.0` → 6.1.0、`test ^1.26.0` → 1.32.0（pub 镜像已缓存） | pub cache 实查 |
| lints 包结构 | `package:lints/recommended.yaml` 存在（core 35 条 + recommended 58 条规则） | lints-6.1.0 实查 |
| Dart 3 特性烟测 | sealed + records + switch 表达式 + 对象模式 + extension type + 中文字符串/注释（UTF-8 无 BOM）：`dart analyze` 零告警、`dart run` 输出正常 | 2026-09-16 /tmp/dart_smoke 实测 |
| AOT 编译 | `dart compile exe` 可用（旧 build.ps1 一直在用） | 仓库现有代码 |
| 嵌套包先例 | fsharp 教程 `examples/20_todo/{src,tests}` 嵌套工程，build.ps1 分级处理 | 仓库现有代码 |

---

### Task 1: 清理旧结构 + 根包骨架

**Files:**
- Delete: `Dart开发指南.md`、`dart/`（旧嵌套工程整体）
- Create: `pubspec.yaml`、`analysis_options.yaml`、`.gitignore`

**Interfaces:**
- Produces: 扁平根包（name: `dart_guide`），Task 2–9 在其上创建 build.ps1 / examples / test；根 `dart pub get` / `dart analyze` / `dart test` 可用（Task 2/15 依赖）。

- [ ] **Step 1: 删除旧文件**

```bash
cd /g/code/guide/dart
git rm "Dart开发指南.md"
git rm -r dart
git status --short | head
```

预期：`Dart开发指南.md` 为 D，`dart/` 下全部文件为 D；目录只剩本次新增骨架文件。

- [ ] **Step 2: 写根包三件套**

`pubspec.yaml`：

```yaml
name: dart_guide
description: Dart 教程示例与测试
version: 1.0.0
environment:
  sdk: ^3.13.0
dev_dependencies:
  lints: ^6.0.0
  test: ^1.26.0
```

`analysis_options.yaml`：

```yaml
include: package:lints/recommended.yaml
```

`.gitignore`：

```text
.dart_tool/
build/
*.exe
```

- [ ] **Step 3: 验证依赖解析**

```bash
cd /g/code/guide/dart && "G:/scoop/apps/dart/current/bin/dart.exe" pub get
```

预期：`Got dependencies!`；生成 `.dart_tool/`（已被忽略）。

- [ ] **Step 4: Commit**

```bash
cd /g/code/guide/dart && git add -A && git commit -m "chore(dart): 删除旧指南与嵌套工程，建立扁平根包骨架

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 2: build.ps1（分级验证：analyze / run / AOT / 嵌套包 test / demo / 根 test）

**Files:**
- Create: `build.ps1`

**Interfaces:**
- Produces: `-All` 全量流程（Task 16 终验依赖）；`-File NN_x.dart` 单示例运行（Task 3–7 依赖）；`-Project 19_testing|20_todo` 嵌套包验证（Task 8–9 依赖）；`-Test` 根包 analyze+test（Task 15 依赖）；`-Clean` 清理。

- [ ] **Step 1: 写 build.ps1 全文**（保持无 BOM）

```powershell
param(
    [switch]$All,
    [switch]$Test,
    [string]$File,
    [string]$Project,
    [switch]$Clean
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# 示例输出含中文：统一 UTF-8，避免默认编码乱码
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Dart 可执行文件：优先 current，回退扫描版本目录
$dartExe = "G:\scoop\apps\dart\current\bin\dart.exe"
if (-not (Test-Path -LiteralPath $dartExe)) {
    $candidates = Get-ChildItem -LiteralPath "G:\scoop\apps\dart" -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        ForEach-Object { Join-Path $_.FullName "bin\dart.exe" } |
        Where-Object { Test-Path -LiteralPath $_ }
    if ($candidates) {
        $dartExe = @($candidates)[0]
    } else {
        throw "未找到 Dart 可执行文件，请检查 G:\scoop\apps\dart 安装。"
    }
}

$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"
$nestedPackages = @('19_testing', '20_todo')

function Invoke-Dart {
    param(
        [string]$Label,
        [string[]]$ArgList,
        [string]$WorkDir = $projectRoot
    )
    Write-Host "[$Label] dart $($ArgList -join ' ')" -ForegroundColor Cyan
    Push-Location $WorkDir
    try {
        & $script:dartExe @ArgList
        if ($LASTEXITCODE -ne 0) {
            throw "命令失败（退出码 $LASTEXITCODE）：dart $($ArgList -join ' ') @ $WorkDir"
        }
    } finally {
        Pop-Location
    }
}

if ($Clean) {
    foreach ($dir in @($projectRoot) + ($nestedPackages | ForEach-Object { Join-Path $examplesDir $_ })) {
        $tool = Join-Path $dir '.dart_tool'
        if (Test-Path -LiteralPath $tool) {
            Remove-Item -LiteralPath $tool -Recurse -Force
        }
    }
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
    }
    Write-Host "[Clean] 已清理 build 与 .dart_tool。" -ForegroundColor Yellow
    exit 0
}

if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录: $examplesDir（Task 3 起创建）"
}

# 根包依赖
Invoke-Dart 'PubGet' @('pub', 'get')

if ($Test -and -not $All -and -not $File -and -not $Project) {
    Invoke-Dart 'Analyze' @('analyze')
    Invoke-Dart 'Test' @('test')
    Write-Host "[Done] 根包 analyze + test 通过。" -ForegroundColor Green
    exit 0
}

if ($File) {
    $source = Join-Path $examplesDir $File
    if (-not (Test-Path -LiteralPath $source)) {
        throw "找不到示例文件: $source"
    }
    Invoke-Dart 'Run' @('run', "examples/$File")
    exit 0
}

function Invoke-Nested {
    param([string]$Name)
    $dir = Join-Path $examplesDir $Name
    Invoke-Dart 'PubGet' @('pub', 'get') $dir
    Invoke-Dart 'Analyze' @('analyze') $dir
    Invoke-Dart 'Test' @('test') $dir
}

function Invoke-TodoDemo {
    New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
    $demo = Join-Path $buildDir 'todo-demo.json'
    if (Test-Path -LiteralPath $demo) {
        Remove-Item -LiteralPath $demo -Force
    }
    $todoDir = Join-Path $examplesDir '20_todo'
    foreach ($line in @(
            @('-f', $demo, 'add', '买牛奶'),
            @('-f', $demo, 'add', '写周报'),
            @('-f', $demo, 'add', '修剪草坪'),
            @('-f', $demo, 'list'),
            @('-f', $demo, 'done', '2'),
            @('-f', $demo, 'list', '--all'),
            @('-f', $demo, 'remove', '3'),
            @('-f', $demo, 'list', '--all')
        )) {
        Invoke-Dart 'TodoDemo' (@('run', 'bin/todo.dart') + $line) $todoDir
    }
}

if ($Project) {
    $dir = Join-Path $examplesDir $Project
    if (-not (Test-Path -LiteralPath $dir)) {
        throw "找不到示例目录: $dir"
    }
    if (Test-Path -LiteralPath (Join-Path $dir 'pubspec.yaml')) {
        Invoke-Nested $Project
        if ($Project -eq '20_todo') {
            Invoke-TodoDemo
        }
    } else {
        # 单文件示例：-Project 06_collections 等价 -File 06_collections.dart
        Invoke-Dart 'Run' @('run', "examples/$Project.dart")
    }
    exit 0
}

if ($All) {
    Invoke-Dart 'Analyze' @('analyze')

    $files = Get-ChildItem -LiteralPath $examplesDir -Filter '*.dart' | Sort-Object Name
    if ($files.Count -eq 0) {
        throw 'examples 目录下没有单文件示例。'
    }
    foreach ($f in $files) {
        Invoke-Dart 'Run' @('run', "examples/$($f.Name)")
    }

    New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
    Invoke-Dart 'AOT' @('compile', 'exe', 'examples/02_hello.dart', '-o', 'build/02_hello.exe')

    foreach ($name in $nestedPackages) {
        Invoke-Nested $name
    }
    Invoke-TodoDemo

    Invoke-Dart 'Test' @('test')
    Write-Host '[Done] 全部示例运行、AOT 编译、嵌套包测试、根测试通过。' -ForegroundColor Green
    exit 0
}

Write-Host '用法:' -ForegroundColor Yellow
Write-Host '  .\build.ps1 -All                       全量验证：analyze + 运行全部示例 + AOT + 嵌套包测试 + 根测试'
Write-Host '  .\build.ps1 -File 06_collections.dart  运行单个示例'
Write-Host '  .\build.ps1 -Project 20_todo           验证嵌套包（19_testing 同理）'
Write-Host '  .\build.ps1 -Project 06_collections    运行单个单文件示例'
Write-Host '  .\build.ps1 -Test                      根包 analyze + test'
Write-Host '  .\build.ps1 -Clean                     清理 build 与 .dart_tool'
```

注意：Task 2 时 `examples/` 还不存在，Step 2 只验证脚本本身可解析与用法输出。

- [ ] **Step 2: 烟测脚本（此时 examples 不存在，走报错/用法路径）**

```bash
cd /g/code/guide/dart && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Clean
```

预期：`[Clean] 已清理…`（build 不存在也正常退出）；再跑无参数版本会因缺 examples 报"找不到 examples 目录"——属预期，Task 3 创建后消失。

- [ ] **Step 3: Commit**

```bash
cd /g/code/guide/dart && git add build.ps1 && git commit -m "feat(dart): 新 build.ps1 分级验证（analyze/run/AOT/嵌套包/根测试）

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 3: 示例 02_hello / 03_variables / 04_control_flow / 05_functions

**Files:**
- Create: `examples/02_hello.dart`、`examples/03_variables.dart`、`examples/04_control_flow.dart`、`examples/05_functions.dart`

**Interfaces:**
- Produces: 第 02–05 章引用代码；`// ═══ N.M` 小节号即文档小节号（Task 10 按号逐字摘录）。

- [ ] **Step 1: 写 examples/02_hello.dart**

```dart
// 02 第一个程序：main 入口、print 输出、字符串插值、命令行参数
//
// 开发运行：dart run examples/02_hello.dart [任意参数]
// AOT 发布：dart compile exe examples/02_hello.dart -o build/02_hello.exe

// ═══ 2.1 main：唯一入口 ═══
// 参数列表可省略；需要命令行参数时声明为 List<String>（args 不含程序名）
void main(List<String> args) {
  // ═══ 2.2 print 与字符串插值 ═══
  var name = 'Dart';
  var version = 3.13;
  print('Hello, $name!'); // $变量
  print('version = ${version.toStringAsFixed(2)}'); // ${表达式}

  // ═══ 2.3 命令行参数 ═══
  print('收到 ${args.length} 个参数：$args');
  if (args.isNotEmpty) {
    print('第一个参数：${args.first}');
  }
}
```

- [ ] **Step 2: 写 examples/03_variables.dart**

```dart
// 03 变量与内置类型：var 与类型推断、内置类型、字符串、const/final、dynamic
// 运行：dart run examples/03_variables.dart

// ═══ 3.5 const 与 final：两种"不可变" ═══
const double pi = 3.14159; // 编译期常量：值必须在编译时确定
final DateTime bootTime = DateTime.now(); // 运行期一次性赋值

// ═══ 3.6 dynamic：静态检查的逃生舱（尽量别用） ═══
dynamic anything = 42;

void main() {
  // ═══ 3.1 var 与类型推断 ═══
  var city = 'Beijing'; // 推断为 String
  // city = 42; // 编译错误：推断后类型固定，不能改放 int
  String explicit = '显式标注也可以';
  print('$city / $explicit');

  // ═══ 3.2 内置类型 ═══
  int count = 42;
  double ratio = 0.75;
  num anyNumber = count; // num 是 int/double 的共同父类
  anyNumber = ratio; // num 变量既能装 int 也能装 double
  bool ok = true;
  print('int=$count double=$ratio num=$anyNumber bool=$ok');
  print('int 是 num 的子类：${count is num}');

  // ═══ 3.3 字符串 ═══
  var adjacent = '相邻''字面量''自动拼接';
  var multi = '''三引号
可以换行''';
  var raw = r'$name 不插值（raw 字符串）';
  var text = '  Dart Guide  ';
  print('${text.trim()} / ${text.toUpperCase()}');
  print('split: ${'a,b,c'.split(',')}');
  print("padLeft: ${'7'.padLeft(3, '0')}");
  print('$adjacent / ${multi.length} 字 / $raw');

  // ═══ 3.4 数字解析与转换 ═══
  var parsed = int.parse('42'); // 失败抛 FormatException
  var safe = int.tryParse('4x'); // 失败返回 null（配合 ?? 给默认值）
  print('parsed=$parsed safe=${safe ?? -1}');
  print('3.7 round=${3.7.round()} truncate=${3.7.truncate()}');

  // ═══ 3.5（续）const 的"深度不可变" ═══
  const rates = [0.1, 0.2]; // const 列表：整个字面量编译期固化，元素也不可变
  final list = [1, 2]; // final 只锁"引用"，列表本身仍可 add
  list.add(3);
  print('rates=$rates list=$list');
  print('pi=$pi bootTime=$bootTime');

  // ═══ 3.6（续）dynamic 的代价 ═══
  anything = '现在装字符串';
  print('anything.length = ${anything.length}'); // 静态检查完全放行
}
```

- [ ] **Step 3: 写 examples/04_control_flow.dart**

```dart
// 04 控制流：if/for/while、break/continue、switch 语句与 Dart 3 switch 表达式
// 运行：dart run examples/04_control_flow.dart

// ═══ 4.5 switch 表达式：Dart 3 的核心新语法 ═══
// 支持模式组合（||）、关系模式与 => 返回值，可直接参与赋值
String dayType(String weekday) => switch (weekday) {
      'Sat' || 'Sun' => '周末',
      'Mon' || 'Tue' || 'Wed' || 'Thu' || 'Fri' => '工作日',
      _ => '未知',
    };

// ═══ 4.4 switch 语句：case 体非空必须以 break/return/throw 结束（Dart 3） ═══
String grade(int score) {
  switch (score) {
    case >= 90:
      return 'A';
    case >= 80:
      return 'B';
    case >= 60:
      return 'C';
    default:
      return '不及格';
  }
}

void main() {
  // ═══ 4.1 if：条件必须是 bool，没有 truthy ═══
  int score = 88;
  if (score >= 90) {
    print('A');
  } else if (score >= 80) {
    print('B');
  } else {
    print('C');
  }
  var list = [1, 2, 3];
  if (list.isNotEmpty) {
    print('list 非空，长度 ${list.length}');
  }

  // ═══ 4.2 for / for-in / while / do-while ═══
  var sum = 0;
  for (var i = 1; i <= 10; i++) {
    sum += i;
  }
  print('sum(1..10) = $sum');

  for (final fruit in ['apple', 'banana', 'cherry']) {
    print('fruit: $fruit');
  }

  var n = 5;
  var factorial = 1;
  while (n > 1) {
    factorial *= n;
    n--;
  }
  print('5! = $factorial');

  var count = 0;
  do {
    count++;
  } while (count < 3);
  print('do-while count = $count');

  // ═══ 4.3 break 与 continue ═══
  for (var i = 0; i < 10; i++) {
    if (i.isOdd) continue;
    if (i > 6) break;
    print('even i = $i');
  }

  // ═══ 4.4（续） ═══
  print('grade(88) = ${grade(88)}');

  // ═══ 4.5（续） ═══
  print('Sat -> ${dayType('Sat')}');
  print('Mon -> ${dayType('Mon')}');

  // ═══ 4.6 条件表达式：?: 是表达式，if 不是 ═══
  var parity = sum.isEven ? '偶' : '奇';
  print('55 是${parity}数');
}
```

- [ ] **Step 4: 写 examples/05_functions.dart**

```dart
// 05 函数：参数三形态、箭头语法、函数类型、闭包、一等公民
// 运行：dart run examples/05_functions.dart

// ═══ 5.2 命名参数：{} 包裹，required 必填，其余可给默认值 ═══
String formatUser({required String name, int age = 0, String role = 'guest'}) {
  return '$name（age=$age, role=$role）';
}

// ═══ 5.3 可选位置参数：[] 包裹，按位置省略 ═══
int sumRange(int start, [int end = 10, int step = 1]) {
  var total = 0;
  for (var i = start; i <= end; i += step) {
    total += i;
  }
  return total;
}

// ═══ 5.1 箭头语法 =>：单表达式函数的简写 ═══
int square(int x) => x * x;

// ═══ 5.4 函数类型：一等公民的类型写法 ═══
int Function(int) makeAdder(int base) {
  // ═══ 5.6 闭包：返回的函数捕获了 base ═══
  return (int x) => base + x;
}

void applyTwice(int value, void Function(int) callback) {
  callback(value);
  callback(value * 2);
}

(int, int) minMax(List<int> items) {
  // ═══ 5.7 返回多个值：用记录（第 13 章详解） ═══
  var min = items.reduce((a, b) => a < b ? a : b);
  var max = items.reduce((a, b) => a > b ? a : b);
  return (min, max);
}

void main() {
  // ═══ 5.2（续）命名参数调用：与顺序无关 ═══
  print(formatUser(name: 'Alice', age: 30, role: 'admin'));
  print(formatUser(name: 'Bob')); // age/role 用默认值

  // ═══ 5.3（续） ═══
  print('sumRange(1) = ${sumRange(1)}');
  print('sumRange(1, 5, 2) = ${sumRange(1, 5, 2)}');
  print('square(7) = ${square(7)}');

  // ═══ 5.5 函数是值：匿名函数传给高阶方法 ═══
  var numbers = [1, 2, 3, 4, 5];
  var doubled = numbers.map((n) => n * 2).toList();
  var evens = numbers.where((n) => n.isEven).toList();
  print('doubled: $doubled');
  print('evens: $evens');

  // ═══ 5.4/5.6（续） ═══
  int Function(int) add10 = makeAdder(10);
  print('add10(5) = ${add10(5)}');

  applyTwice(3, (v) => print('callback got: $v'));

  // ═══ 5.7（续）解构接收 ═══
  var (min, max) = minMax([4, 1, 7, 3]);
  print('min=$min, max=$max');
}
```

- [ ] **Step 5: 验证四个示例**

```bash
cd /g/code/guide/dart
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 02_hello.dart
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 03_variables.dart
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 04_control_flow.dart
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 05_functions.dart
```

预期：四个示例 `[Run]` 通过。02 输出 `Hello, Dart!`；05 输出 `min=1, max=7`。（build.ps1 只跑 `dart run`，不跑 analyze；告警在 Task 16 终验的 `-All` 统一暴露，也可随时手动 `dart analyze` 提前检查。）

- [ ] **Step 6: Commit**

```bash
cd /g/code/guide/dart && git add examples && git commit -m "feat(dart): 示例 02–05 hello/变量/控制流/函数

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 4: 示例 06_collections / 07_classes / 08_inheritance

**Files:**
- Create: `examples/06_collections.dart`、`examples/07_classes.dart`、`examples/08_inheritance.dart`

**Interfaces:**
- Produces: 第 06–08 章引用代码；`Point`（构造函数家族/运算符重载/==）与 `Temperature`（factory 缓存）为第 07 章核心案例；`StorableRect`（super 参数 + 多接口）为第 08 章案例。

- [ ] **Step 1: 写 examples/06_collections.dart**

```dart
// 06 集合：List/Set/Map、字面量构建（spread/集合 if/for）、Iterable 操作
// 运行：dart run examples/06_collections.dart

void main() {
  // ═══ 6.1 List ═══
  var langs = ['Dart', 'Go', 'Rust'];
  langs.add('Kotlin'); // 末尾追加
  langs.insert(0, 'C'); // 指定位置插入
  langs.remove('Go');
  print('langs: $langs');
  print('first=${langs.first} last=${langs.last} length=${langs.length}');
  print('切片 [1..3): ${langs.sublist(1, 3)}');

  // ═══ 6.2 字面量构建：spread 与集合 if/for（Dart 特色） ═══
  var base = [1, 2, 3];
  var withZero = [0, ...base]; // ... 展开
  var compact = [
    ...base,
    if (base.length > 2) 99, // 条件成立才收入
    for (final x in base) x * 10, // 逐个变换收入
  ];
  print('withZero: $withZero');
  print('compact: $compact');

  // ═══ 6.3 Set ═══
  var tags = <String>{'dart', 'flutter'};
  tags.add('dart'); // 重复元素被忽略
  var seen = <String>{};
  for (final w in 'to be or not to be'.split(' ')) {
    seen.add(w);
  }
  print('tags: $tags（长度 ${tags.length}）');
  print('去重后: $seen');
  print('并集: ${{1, 2}.union({2, 3})} 交集: ${{1, 2}.intersection({2, 3})}');

  // ═══ 6.4 Map ═══
  var scores = {'Alice': 90, 'Bob': 82};
  scores['Carol'] = 95; // 新增/覆盖
  scores.putIfAbsent('Bob', () => 0); // 已存在则不动
  print('scores: $scores');
  print("Bob=${scores['Bob']} Dave=${scores['Dave'] ?? '无'}");
  for (final entry in scores.entries) {
    print('${entry.key}: ${entry.value}');
  }

  // ═══ 6.5 Iterable 操作：where/map/any/every/fold ═══
  var nums = [5, 2, 9, 1, 7];
  print('sorted: ${[...nums]..sort()}'); // 拷贝后排序，不动原列表
  print('where>4: ${nums.where((n) => n > 4).toList()}');
  print('map×2: ${nums.map((n) => n * 2).toList()}');
  print('any>8: ${nums.any((n) => n > 8)} / every>0: ${nums.every((n) => n > 0)}');
  print('fold 求和: ${nums.fold(0, (acc, n) => acc + n)}');
  print('reduce: ${nums.reduce((a, b) => a + b)}');

  // ═══ 6.6 Iterable 是惰性的：toList() 才落袋 ═══
  var lazy = nums.where((n) => n > 2).map((n) => n * 10); // 还没执行
  print('lazy 运行时类型: ${lazy.runtimeType}');
  print('toList 后: ${lazy.toList()}');

  // ═══ 6.7 不可变列表 ═══
  var frozen = List.unmodifiable([1, 2, 3]);
  // frozen.add(4); // 运行时抛 UnsupportedError
  print('frozen: $frozen');
}
```

- [ ] **Step 2: 写 examples/07_classes.dart**

```dart
// 07 类与对象：构造函数家族、getter/setter、运算符重载、== 与 hashCode
// 运行：dart run examples/07_classes.dart

import 'dart:math' as math;

// ═══ 7.1–7.4 构造函数家族 ═══
class Point {
  final double x;
  final double y;

  Point(this.x, this.y); // 主构造：参数直赋字段

  Point.origin()
      : x = 0,
        y = 0; // 命名构造 + 初始化列表

  Point.checked(double x, double y)
      : assert(x >= 0 && y >= 0, '坐标不能为负'),
        x = x,
        y = y; // 初始化列表：构造体之前执行，可做断言

  Point.alongX(double x) : this(x, 0); // 重定向构造：转发到主构造

  // ═══ 7.6 getter：像字段一样访问的计算属性 ═══
  double get distanceFromOrigin => math.sqrt(x * x + y * y);

  // ═══ 7.7 运算符重载与 == ═══
  Point operator +(Point other) => Point(x + other.x, y + other.y);
  Point operator *(double k) => Point(x * k, y * k);

  @override
  bool operator ==(Object other) =>
      other is Point && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Point($x, $y)';
}

// ═══ 7.5 工厂构造 factory：自己决定返回哪个实例 ═══
class Temperature {
  final double celsius;
  static final Map<double, Temperature> _cache = {};

  Temperature._(this.celsius); // 私有构造：外界只能走 factory

  factory Temperature(double celsius) {
    return _cache.putIfAbsent(celsius, () => Temperature._(celsius));
  }

  double get fahrenheit => celsius * 9 / 5 + 32;

  @override
  String toString() => '$celsius°C';
}

// ═══ 7.6（续）setter：拦截写入 ═══
class Account {
  double _balance = 0; // 下划线开头：库内私有

  double get balance => _balance;

  set balance(double value) {
    if (value < 0) {
      throw ArgumentError('余额不能为负');
    }
    _balance = value;
  }
}

void main() {
  var p = Point(3, 4);
  print('p=$p 距原点=${p.distanceFromOrigin}');
  print('origin=${Point.origin()} alongX=${Point.alongX(5)}');
  print('p + p * 2 = ${p + p * 2}'); // 运算符重载参与表达式
  print('==(3,4): ${Point(3, 4) == p}（重写后按值比较）');
  print('checked: ${Point.checked(1, 1)}');

  var t1 = Temperature(25);
  var t2 = Temperature(25);
  print('factory 复用实例：${identical(t1, t2)}，25°C = ${t1.fahrenheit}°F');

  var acc = Account();
  acc.balance = 100;
  print('balance=${acc.balance}');
  try {
    acc.balance = -1;
  } on ArgumentError catch (e) {
    print('setter 拦截：$e');
  }
}
```

- [ ] **Step 3: 写 examples/08_inheritance.dart**

```dart
// 08 继承、抽象与接口：extends、abstract、implicit interface
// 运行：dart run examples/08_inheritance.dart

// ═══ 8.3 抽象类：约定子类必须实现的行为 ═══
abstract class Shape {
  String get name; // 抽象 getter：无实现

  double area(); // 抽象方法

  // 抽象类可以有具体方法（供 extends 的子类复用）
  void describe() => print('$name 的面积是 ${area().toStringAsFixed(2)}');
}

// ═══ 8.1 extends：继承实现 ═══
class Circle extends Shape {
  final double r;
  Circle(this.r);

  @override
  String get name => '圆';

  @override
  double area() => 3.14159 * r * r;
}

class Rect extends Shape {
  final double w;
  final double h;
  Rect(this.w, this.h);

  @override
  String get name => '矩形';

  @override
  double area() => w * h;
}

// ═══ 8.4 implicit interface：每个类同时隐式定义一个接口 ═══
// implements 只拿"契约"（所有成员签名），不带任何实现
class Square implements Shape {
  final double side;
  Square(this.side);

  @override
  String get name => '正方形';

  @override
  double area() => side * side;

  @override
  void describe() => print('[$name] area=${area().toStringAsFixed(1)}（自己实现）');
}

// ═══ 8.5 一个类可以同时实现多个契约 ═══
abstract class Storable {
  Map<String, dynamic> toJson();
}

class StorableRect extends Rect implements Storable {
  StorableRect(super.w, super.h); // super 参数：直接转发给父类构造

  @override
  Map<String, dynamic> toJson() => {'w': w, 'h': h};
}

void main() {
  // ═══ 8.1/8.2 继承复用与多态 ═══
  Shape c = Circle(2);
  c.describe(); // describe 来自抽象类，area 来自 Circle——模板方法模式

  for (final s in [Circle(1), Rect(3, 4), Square(5)]) {
    s.describe(); // 同一调用，不同实现
  }

  // ═══ 8.4（续）implements vs extends 的本质区别 ═══
  Square(2).describe(); // implements 拿不到 describe 的实现，必须自己写

  // ═══ 8.5（续）多接口 ═══
  print(StorableRect(3, 4).toJson());

  // ═══ 8.6 组合方式选型 ═══
  // extends：想要实现复用（单继承）
  // implements：只要契约、全部自己写（可多个）
  // with：混入横向能力（第 09 章）
}
```

- [ ] **Step 4: 验证三个示例**

```bash
cd /g/code/guide/dart
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 06_collections.dart
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 07_classes.dart
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 08_inheritance.dart
```

预期：全部 `[Run]` 通过；07 输出 `p + p * 2 = Point(9, 12)` 与 `factory 复用实例：true`；08 输出 `{w: 3.0, h: 4.0}`。

- [ ] **Step 5: Commit**

```bash
cd /g/code/guide/dart && git add examples && git commit -m "feat(dart): 示例 06–08 集合/类/继承接口

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 5: 示例 09_mixins_modifiers / 10_null_safety / 11_generics

**Files:**
- Create: `examples/09_mixins_modifiers.dart`、`examples/10_null_safety.dart`、`examples/11_generics.dart`

**Interfaces:**
- Produces: 第 09–11 章引用代码；`Result`/`Ok`/`Err` sealed 家族（09）与协变运行时检查（11）为讲解核心。

- [ ] **Step 1: 写 examples/09_mixins_modifiers.dart**

```dart
// 09 Mixin 与类修饰符：with、mixin/on、线性化、sealed/base/final/interface
// 运行：dart run examples/09_mixins_modifiers.dart

// ═══ 9.1 mixin：可组合的行为片段 ═══
mixin Logger {
  void log(String msg) => print('[log] $msg');
}

abstract class Animal {
  String get name;
  void breathe() => print('$name 呼吸');
}

// ═══ 9.2 mixin on：限定只能混入某个类之上，从而安全使用其成员 ═══
mixin Pet on Animal {
  void greet() => print('$name 摇尾巴（作为宠物打招呼）');
}

// ═══ 9.3 线性化：右边的 mixin 覆盖左边的同名方法 ═══
mixin A {
  String who() => 'A';
}

mixin B {
  String who() => 'B';
}

class Dog extends Animal with Pet, Logger {
  @override
  String get name => '阿黄';
}

class Confused with A, B {}

// ═══ 9.4 sealed：封闭继承树，换来穷尽检查（配合第 13 章 switch） ═══
sealed class Result<T> {
  const Result();
}

class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

class Err<T> extends Result<T> {
  final String message;
  const Err(this.message);
}

String describeResult(Result<int> r) => switch (r) {
      Ok(value: var v) => '成功：$v',
      Err(message: var m) => '失败：$m',
      // 不需要 _ 兜底：sealed 保证子类全部在本文件内，编译器能数得清
    };

// ═══ 9.5 base/final/interface 修饰符（Dart 3） ═══
base class BaseModel {
  void id() => print('base：允许被 extends/with，禁止被 implements');
}

final class FinalModel {
  void id() => print('final：禁止 extends 与 implements，只能直接用');
}

interface class InterfaceModel {
  void id() => print('interface：允许 implements，禁止 extends');
}

void main() {
  var dog = Dog();
  dog.breathe(); // 来自 Animal
  dog.greet(); // 来自 Pet（on Animal 才能用）
  dog.log('你好'); // 来自 Logger

  // ═══ 9.3（续） ═══
  print('with A, B 的 who() = ${Confused().who()}'); // B 胜出：从左到右叠加，后者覆盖

  // ═══ 9.4（续） ═══
  print(describeResult(const Ok(42)));
  print(describeResult(const Err('网络超时')));

  // ═══ 9.5（续） ═══
  // class MyModel implements BaseModel {} // 编译错误：base 类禁止被 implements
  BaseModel().id();
  FinalModel().id();
  InterfaceModel().id();
}
```

- [ ] **Step 2: 写 examples/10_null_safety.dart**

```dart
// 10 空安全：可空类型、?./??/!、类型提升、late
// 运行：dart run examples/10_null_safety.dart

// ═══ 10.4 字段不参与类型提升（关键坑） ═══
class Profile {
  String? nickname; // 可空字段

  String display() {
    // if (nickname != null) { return nickname.toUpperCase(); } // 编译错误：
    // 提升只对局部变量生效，字段可能被其他代码改回 null
    return nickname?.toUpperCase() ?? '（匿名）';
  }
}

void main() {
  // ═══ 10.1 默认不可空 ═══
  String title = 'Dart';
  // title = null; // 编译错误：String 不能装 null
  String? subtitle; // 加 ? 才可空，默认值就是 null
  print('title=$title subtitle=$subtitle');

  // ═══ 10.2 ?. 与 ?? ═══
  print('len=${subtitle?.length}'); // null 时短路，整个表达式为 null
  print('len=${subtitle?.length ?? 0}'); // 给空值兜底
  subtitle ??= '默认副标题'; // 为 null 才赋值
  print('subtitle=$subtitle');

  // ═══ 10.3 ! 断言：我知道它不是 null（错了运行时抛错） ═══
  int len = subtitle!.length;
  print('len=$len');

  // ═══ 10.4（续）局部变量才会被提升 ═══
  String? local = 'abc';
  if (local != null) {
    print('local 提升：${local.toUpperCase()}'); // 局部变量判空后自动窄化
  }

  // ═══ 10.5 late：先声明后初始化，首次访问才求值 ═══
  late final String config = loadConfig();
  print('访问 config 之前不会触发 loadConfig');
  print('config=$config');

  // ═══ 10.6 可空参数与默认值 ═══
  print(greet(null));
  print(greet('小李'));

  var p = Profile()..nickname = '大熊';
  print(p.display());
}

String loadConfig() {
  print('>> loadConfig 执行（惰性求值的证据）');
  return 'dev';
}

String greet(String? who) => '你好，${who ?? '游客'}';
```

- [ ] **Step 3: 写 examples/11_generics.dart**

```dart
// 11 泛型：泛型类/方法、约束、协变边界、reified 类型
// 运行：dart run examples/11_generics.dart

// ═══ 11.1 泛型类 ═══
class Box<T> {
  final T content;
  Box(this.content);

  T open() => content;
}

class Pair<K, V> {
  final K first;
  final V second;
  const Pair(this.first, this.second);

  @override
  String toString() => '($first, $second)';
}

// ═══ 11.2/11.3 泛型方法与约束：T extends num 才能用 > ═══
T maxOf<T extends num>(T a, T b) => a > b ? a : b;

List<T> sortedCopy<T extends Comparable<T>>(List<T> list) => [...list]..sort();

// ═══ 11.4 泛型 + 空安全：返回 T? 表达"可能没有" ═══
T? firstOrNull<T>(List<T> list, bool Function(T) test) {
  for (final item in list) {
    if (test(item)) {
      return item;
    }
  }
  return null;
}

void main() {
  var box = Box('字符串也可以'); // T 推断为 String
  print('box=${box.open()}（${box.content.runtimeType}）');
  print(Pair(1, '一')); // K=int, V=String

  // ═══ 11.2（续） ═══
  print('maxOf(3, 7) = ${maxOf(3, 7)}');
  print('maxOf(2.5, 2.1) = ${maxOf(2.5, 2.1)}');
  print('sortedCopy: ${sortedCopy([3, 1, 2])}');
  print('firstOrNull: ${firstOrNull([5, 8, 11], (n) => n > 10)}');

  // ═══ 11.5 协变：List<int> 可以当 List<num> 用（有代价） ═══
  List<int> ints = [1, 2, 3];
  List<num> nums = ints; // 合法：Dart 泛型协变
  // nums.add(1.5); // 编译通过、运行时抛 TypeError！ints 实际只能装 int
  print('nums=$nums runtimeType=${nums.runtimeType}');

  // ═══ 11.6 reified：类型参数运行时仍在（对比 Java 擦除） ═══
  print('is List<int>: ${ints is List<int>}');
  print('is List<String>: ${ints is List<String>}');
}
```

- [ ] **Step 4: 验证三个示例**

```bash
cd /g/code/guide/dart
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 09_mixins_modifiers.dart
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 10_null_safety.dart
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 11_generics.dart
```

预期：全部 `[Run]` 通过；09 输出 `with A, B 的 who() = B`；10 输出 `>> loadConfig 执行` 出现在 `config=dev` 之前；11 输出 `is List<String>: false`。

- [ ] **Step 5: Commit**

```bash
cd /g/code/guide/dart && git add examples && git commit -m "feat(dart): 示例 09–11 mixin修饰符/空安全/泛型

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 6: 示例 12_exceptions / 13_records_patterns / 14_extensions

**Files:**
- Create: `examples/12_exceptions.dart`、`examples/13_records_patterns.dart`、`examples/14_extensions.dart`

**Interfaces:**
- Produces: 第 12–14 章引用代码；`InsufficientBalance` 自定义异常（12）、sealed `Shape` + 模式族谱 `classify`（13）、`Meters`/`Seconds` extension type（14）为核心案例。

- [ ] **Step 1: 写 examples/12_exceptions.dart**

```dart
// 12 异常：throw、try/on/catch、finally、Error vs Exception、自定义
// 运行：dart run examples/12_exceptions.dart

// ═══ 12.6 自定义异常：实现 Exception 接口 ═══
class InsufficientBalance implements Exception {
  final double need;
  final double have;
  InsufficientBalance(this.need, this.have);

  @override
  String toString() => '余额不足：需要 $need，只有 $have';
}

class BankAccount {
  double balance = 100;

  void withdraw(double amount) {
    if (amount > balance) {
      throw InsufficientBalance(amount, balance); // 业务失败
    }
    if (amount < 0) {
      throw ArgumentError('取款金额不能为负'); // 调用方 bug
    }
    balance -= amount;
  }
}

void main() {
  var account = BankAccount();

  // ═══ 12.2 try/on/catch：on 按类型过滤 ═══
  try {
    account.withdraw(500);
  } on InsufficientBalance catch (e) {
    print('业务异常：$e');
  }

  try {
    account.withdraw(-1);
  } on ArgumentError catch (e) {
    print('参数错误：${e.message}');
  }

  // ═══ 12.3 捕获调用栈 + rethrow 交还上层 ═══
  try {
    risky();
  } catch (e, stack) {
    print('捕获：$e');
    print('栈顶：${stack.toString().split('\n').first}');
    // rethrow; // 需要上层继续处理时原样抛出（保留原始栈）
  }

  // ═══ 12.4 finally：无论如何都执行 ═══
  try {
    account.withdraw(30);
    print('取款成功，余额 ${account.balance}');
  } finally {
    print('finally：释放资源放这里');
  }

  // ═══ 12.5 Error vs Exception ═══
  // Error（RangeError/TypeError...）：程序 bug，不该捕获，修代码
  // Exception（自定义业务异常）：可预期失败，选择合适的层捕获处理
  var list = [1];
  try {
    list[5];
  } on RangeError {
    print('RangeError 是 Error：这是 bug，不该靠 try 掩盖');
  }
}

// ═══ 12.1 throw 与 Never ═══
Never risky() {
  throw StateError('状态不对'); // 永不返回的函数标 Never
}
```

- [ ] **Step 2: 写 examples/13_records_patterns.dart**

```dart
// 13 记录与模式匹配：record、解构、switch 全模式、sealed 穷尽
// 运行：dart run examples/13_records_patterns.dart

import 'dart:math' as math;

// ═══ 13.6 sealed 层级 + 穷尽 switch：模式匹配的最佳搭档 ═══
sealed class Shape {
  const Shape();
}

class Circle extends Shape {
  final double r;
  const Circle(this.r);
}

class Rect extends Shape {
  final double w, h;
  const Rect(this.w, this.h);
}

class Triangle extends Shape {
  final double a, b, c;
  const Triangle(this.a, this.b, this.c);
}

double area(Shape s) => switch (s) {
      Circle(r: var r) => 3.14159 * r * r, // 对象模式：按字段名解构
      Rect(w: var w, h: var h) => w * h,
      Triangle(a: var a, b: var b, c: var c) => heron(a, b, c),
    };

double heron(double a, double b, double c) {
  final s = (a + b + c) / 2;
  return math.sqrt((s - a) * (s - b) * (s - c) * s);
}

// ═══ 13.5 模式族谱：一张 switch 认识全部模式 ═══
String classify(Object obj) => switch (obj) {
      int n when n > 0 => '正整数 $n', // 类型 + when 卫兵
      int() => '非正整数', // 空参类型模式
      String s => '字符串"$s"（长度 ${s.length}）',
      [int first, ...] => '以 $first 开头的列表', // 列表模式
      {'name': String name} => '含 name=$name 的映射', // 映射模式
      _ => '其他',
    };

(int, int) bounds(List<int> list) {
  // ═══ 13.3 函数返回多值 ═══
  var min = list.first;
  var max = list.first;
  for (final n in list) {
    if (n < min) {
      min = n;
    }
    if (n > max) {
      max = n;
    }
  }
  return (min, max);
}

void main() {
  // ═══ 13.1 record：轻量结构化值，== 按结构比较 ═══
  var point = (x: 3, y: 4); // 命名字段 record
  var other = (x: 3, y: 4);
  print('point == other: ${point == other}（结构相等，无需重写 ==）');
  print('字段访问：x=${point.x}');
  var rgb = (255, 128, 0); // 位置字段 record
  print('位置字段：第一个=${rgb.$1}');

  // ═══ 13.2 解构：一次声明多个变量 ═══
  var (x, y) = point;
  final (r, g, b) = rgb;
  print('解构：x=$x y=$y r=$r g=$g b=$b');

  // ═══ 13.3（续） ═══
  var (lo, hi) = bounds([4, 1, 7, 3]);
  print('bounds: lo=$lo hi=$hi');

  // ═══ 13.4/13.5（续） ═══
  for (final v in [7, -2, 'Dart', [10, 20], {'name': 'Bob'}, 3.14]) {
    print('${v.runtimeType}: ${classify(v)}');
  }

  // ═══ 13.6（续）穷尽 switch：新增子类时编译器强制补分支 ═══
  for (final s in [const Circle(1), const Rect(3, 4), const Triangle(3, 4, 5)]) {
    print('${s.runtimeType} 面积 = ${area(s).toStringAsFixed(2)}');
  }
}
```

- [ ] **Step 3: 写 examples/14_extensions.dart**

```dart
// 14 扩展与 typedef：extension、可空/泛型扩展、冲突解析、extension type
// 运行：dart run examples/14_extensions.dart

// ═══ 14.1 扩展既有类型 ═══
extension StringX on String {
  int get wordCount => trim().isEmpty ? 0 : trim().split(RegExp(r'\s+')).length;

  String get reversed => String.fromCharCodes(codeUnits.reversed);
}

// ═══ 14.2 泛型扩展 ═══
extension ListX<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;

  String joinWithComma() => map((e) => '$e').join('、');
}

// ═══ 14.3 扩展可空类型：内部 this 可为 null ═══
extension NullableStringX on String? {
  String orDash() => this ?? '-';
}

// ═══ 14.4 冲突时必须显式调用 ═══
extension ShoutX on String {
  String shout() => toUpperCase();
}

extension WhisperX on String {
  String shout() => '$this...'; // 与 ShoutX 同名同签名：冲突
}

// ═══ 14.5 extension type：零开销"新类型"（Dart 3.3+） ═══
extension type Meters(double value) {
  double get inFeet => value * 3.28084;

  Meters operator +(Meters other) => Meters(value + other.value);
}

extension type Seconds(int value) {
  String get human {
    final m = value ~/ 60;
    final s = value % 60;
    return m > 0 ? '$m 分 $s 秒' : '$s 秒';
  }
}

// ═══ 14.6 typedef：类型别名 ═══
typedef IntList = List<int>;
typedef Mapper<S, T> = T Function(S);

void main() {
  // ═══ 14.1（续） ═══
  print('wordCount=${'dart is nice'.wordCount}');
  print('reversed=${'abcdef'.reversed}');

  // ═══ 14.2（续） ═══
  print('firstOrNull=${[9, 1].firstOrNull} / ${<int>[].firstOrNull}');
  print('joinWithComma=${[1, 2, 3].joinWithComma()}');

  // ═══ 14.3（续） ═══
  String? maybe = null;
  print('orDash=${maybe.orDash()}');

  // ═══ 14.4（续）两个扩展有同名方法时，隐式调用直接编译报错 ═══
  print(ShoutX('hi').shout());
  print(WhisperX('hi').shout());

  // ═══ 14.5（续） ═══
  var len = Meters(5);
  print('5 米 = ${len.inFeet.toStringAsFixed(2)} 英尺；相加 = ${(len + Meters(1)).value} 米');
  print('95 秒 = ${Seconds(95).human}');
  // Meters(5) + 3 是编译错误：新类型不与底层 double 自动互通（这正是意义）

  // ═══ 14.6（续） ═══
  IntList scores = [90, 85];
  Mapper<String, int> lengthOf = (s) => s.length;
  print('scores 长度 ${scores.length}，lengthOf("Dart") = ${lengthOf('Dart')}');
}
```

- [ ] **Step 4: 验证三个示例**

```bash
cd /g/code/guide/dart
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 12_exceptions.dart
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 13_records_patterns.dart
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 14_extensions.dart
```

预期：全部 `[Run]` 通过；13 输出 `point == other: true`、`Triangle 面积 = 6.00`；14 输出 `95 秒 = 1 分 35 秒`。

- [ ] **Step 5: Commit**

```bash
cd /g/code/guide/dart && git add examples && git commit -m "feat(dart): 示例 12–14 异常/记录模式/扩展

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 7: 示例 15_async / 16_streams / 17_isolates

**Files:**
- Create: `examples/15_async.dart`、`examples/16_streams.dart`、`examples/17_isolates.dart`

**Interfaces:**
- Produces: 第 15–17 章引用代码；三个示例全部确定性退出（无挂起）。

- [ ] **Step 1: 写 examples/15_async.dart**

```dart
// 15 Future 与 async/await：事件循环、错误处理、并行
// 运行：dart run examples/15_async.dart

import 'dart:async';

// ═══ 15.2 async 函数：返回 Future，内部用 await ═══
Future<String> fetchUserName(int id) async {
  await Future<void>.delayed(const Duration(milliseconds: 50)); // 模拟网络
  if (id <= 0) {
    throw StateError('无效用户 id: $id');
  }
  return '用户$id';
}

Future<String> greet(int id) async {
  final name = await fetchUserName(id);
  return '你好，$name';
}

// ═══ 15.4 Future.wait：并行等待多个 Future ═══
Future<List<int>> loadAll() async {
  return await Future.wait([
    Future<int>.delayed(const Duration(milliseconds: 30), () => 1),
    Future<int>.delayed(const Duration(milliseconds: 20), () => 2),
    Future<int>.delayed(const Duration(milliseconds: 10), () => 3),
  ]);
}

void main() async {
  // ═══ 15.1 Future：一个"将来才有"的值 ═══
  final pending = Future<int>.value(42);
  print('pending 已创建（回调还没执行）');
  final v = await pending;
  print('await 拿到 $v');

  // ═══ 15.2（续） ═══
  print(await greet(7));

  // ═══ 15.3 await 的错误处理就是 try/catch ═══
  try {
    await fetchUserName(-1);
  } on StateError catch (e) {
    print('捕获：$e');
  }

  // ═══ 15.4（续）并行：总耗时取最长者而非求和 ═══
  final sw = Stopwatch()..start();
  final all = await loadAll();
  print('并行结果 $all，耗时 ${sw.elapsedMilliseconds}ms（串行则约 60ms）');

  // ═══ 15.5 then 链：await 之前的写法（读懂旧代码用） ═══
  Future.value(3).then((n) => n * 2).then((n) => print('then 链结果：$n'));

  // ═══ 15.6 事件循环：microtask 与 event 的顺序 ═══
  print('--- 事件循环演示 ---');
  scheduleMicrotask(() => print('microtask 1（先执行：插队队列）'));
  Future<void>(() => print('event 1（后执行：新事件排到队尾）'));
  await Future<void>.delayed(Duration.zero); // 让队列跑完
  print('--- 演示结束 ---');
}
```

- [ ] **Step 2: 写 examples/16_streams.dart**

```dart
// 16 Stream：异步序列、async* 生成器、广播流、StreamController
// 运行：dart run examples/16_streams.dart

import 'dart:async';

// ═══ 16.2 async* 生成器：像写循环一样产出事件 ═══
Stream<int> countDown(int from) async* {
  while (from > 0) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    yield from--; // 产出一个事件，暂停等消费者处理
  }
}

// ═══ 16.5 StreamController：手动推送事件 ═══
Stream<double> sensor() {
  final controller = StreamController<double>();
  final values = [36.5, 36.8, 37.2, 36.9];
  var i = 0;
  Timer.periodic(const Duration(milliseconds: 15), (t) {
    if (i < values.length) {
      controller.add(values[i++]);
    } else {
      controller.close(); // 必须关闭，否则 await for 永远等不到 done
      t.cancel();
    }
  });
  return controller.stream;
}

void main() async {
  // ═══ 16.1 Stream 是"异步的 Iterable"：await for 消费 ═══
  print('--- countDown ---');
  await for (final n in countDown(3)) {
    print('T-$n');
  }

  // ═══ 16.3 工厂流：fromIterable / periodic + take ═══
  print('--- fromIterable ---');
  await for (final w in Stream.fromIterable(['a', 'b'])) {
    print(w);
  }
  final ticks = await Stream<int>.periodic(
    const Duration(milliseconds: 5),
    (i) => i,
  ).take(3).toList(); // take(n) 限定数量，toList 收集
  print('periodic take(3): $ticks');

  // ═══ 16.4 单订阅 vs 广播 ═══
  final broadcast = countDown(2).asBroadcastStream();
  await Future.wait([
    broadcast.forEach((n) => print('观察者A: $n')),
    broadcast.forEach((n) => print('观察者B: $n')),
  ]);

  // ═══ 16.6 错误也是事件：try/catch 包住 await for ═══
  final broken = () async* {
    yield 1;
    throw StateError('流中途出错');
  }();
  try {
    await for (final n in broken) {
      print('broken 收到 $n');
    }
  } catch (e) {
    print('流错误：$e');
  }

  // ═══ 16.5（续）controller ═══
  print('--- sensor ---');
  await for (final t in sensor()) {
    print('体温 $t');
  }
}
```

- [ ] **Step 3: 写 examples/17_isolates.dart**

```dart
// 17 Isolate 并发：消息传递、Isolate.run、spawn、数据拷贝
// 运行：dart run examples/17_isolates.dart

import 'dart:async';
import 'dart:isolate';

// ═══ 17.4 数据是拷贝而非共享：worker 里排序不影响主 isolate ═══
Future<List<int>> heavySort(List<int> data) async {
  return await Isolate.run(() => [...data]..sort()); // 闭包带着数据过去，跑完带回来
}

// ═══ 17.3 手工协议：spawn + SendPort/ReceivePort ═══
Future<int> sumInWorker(List<int> data) async {
  final result = Completer<int>();
  final mainPort = ReceivePort();
  await Isolate.spawn(_workerEntry, (data, mainPort.sendPort));
  mainPort.listen((message) {
    result.complete(message as int);
    mainPort.close(); // 不关掉端口，进程不会退出
  });
  return result.future;
}

void _workerEntry((List<int>, SendPort) args) {
  final (data, replyTo) = args; // record 解构参数（第 13 章）
  final total = data.fold(0, (a, b) => a + b);
  replyTo.send(total);
}

void main() async {
  print('主 isolate 开始');

  // ═══ 17.2 Isolate.run：一行把任务丢到别的 isolate ═══
  final fib = await Isolate.run(() => fibSlow(30));
  print('fib(30) = $fib（在 worker 里算，没卡主 isolate）');

  // ═══ 17.4（续） ═══
  final data = [5, 3, 9, 1, 7];
  print('heavySort = ${await heavySort(data)}，原列表未被改动 $data');

  // ═══ 17.3（续） ═══
  print('sumInWorker = ${await sumInWorker([1, 2, 3, 4])}');

  print('主 isolate 结束');
}

int fibSlow(int n) => n < 2 ? n : fibSlow(n - 1) + fibSlow(n - 2);
```

- [ ] **Step 4: 验证三个示例（重点看是否正常退出）**

```bash
cd /g/code/guide/dart
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 15_async.dart
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 16_streams.dart
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 17_isolates.dart
```

预期：全部 `[Run]` 通过且**正常退出**（无挂起）；15 输出 `microtask 1` 在 `event 1` 之前；16 输出 `观察者A: 2`/`观察者B: 2` 交错后正常结束；17 输出 `fib(30) = 832040` 与 `主 isolate 结束`。

- [ ] **Step 5: Commit**

```bash
cd /g/code/guide/dart && git add examples && git commit -m "feat(dart): 示例 15–17 异步/流/Isolate

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 8: 示例 18_files_json_http + 19_testing 嵌套包

**Files:**
- Create: `examples/18_files_json_http.dart`
- Create: `examples/19_testing/pubspec.yaml`、`examples/19_testing/analysis_options.yaml`、`examples/19_testing/.gitignore`、`examples/19_testing/lib/cart.dart`、`examples/19_testing/test/cart_test.dart`

**Interfaces:**
- Produces: 第 18/19 章引用代码；`Book.fromJson/toJson`（18）、`Cart`/`CartItem`（19）。19_testing 为独立 pub 包 `name: cart_demo`（Task 2 的 `-Project 19_testing` 依赖 `pubspec.yaml` 位于该目录）。

- [ ] **Step 1: 写 examples/18_files_json_http.dart**

```dart
// 18 文件、JSON 与 HTTP：dart:io 文件、dart:convert 编解码、HttpServer 自测
// 运行：dart run examples/18_files_json_http.dart

import 'dart:convert';
import 'dart:io';

// ═══ 18.4 类型安全的 JSON：手写 fromJson/toJson ═══
class Book {
  final String title;
  final int year;
  const Book(this.title, this.year);

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        json['title'] as String,
        json['year'] as int,
      );

  Map<String, dynamic> toJson() => {'title': title, 'year': year};

  @override
  String toString() => '《$title》($year)';
}

Future<void> main() async {
  // ═══ 18.1 File：读写文本与追加 ═══
  final dir = await Directory.systemTemp.createTemp('dart_guide_');
  final file = File('${dir.path}/note.txt');
  await file.writeAsString('第一行\n', mode: FileMode.write);
  await file.writeAsString('第二行\n', mode: FileMode.append);
  final text = await file.readAsString();
  print('文件内容：${text.trim().split('\n')}');
  print('存在=${await file.exists()} 大小=${await file.length()} 字节');

  // ═══ 18.2 Directory：创建与列出 ═══
  await File('${dir.path}/extra.txt').writeAsString('x');
  final entries = await dir.list().toList();
  print('临时目录有 ${entries.length} 个条目');
  await dir.delete(recursive: true); // 清理临时目录

  // ═══ 18.3 JSON：编码/解码 ═══
  final jsonText = jsonEncode({'name': 'Dart', 'scores': [90, 85]});
  print('编码：$jsonText');
  final decoded = jsonDecode(jsonText); // 静态类型是"动态的" Map/List
  print('解码：${decoded['name']} / ${decoded['scores'][1]}');
  print('解码类型：${decoded.runtimeType}');

  // ═══ 18.4（续）对象 <-> JSON ═══
  final books = [const Book('Dart 实战', 2026), const Book('深入浅出', 2025)];
  final bookJson = jsonEncode(books.map((b) => b.toJson()).toList());
  print('books JSON：$bookJson');
  final restored = (jsonDecode(bookJson) as List)
      .map((e) => Book.fromJson(e as Map<String, dynamic>))
      .toList();
  print('还原：$restored');

  // ═══ 18.5 HttpServer：随机端口起服务，自请求一次后关闭 ═══
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final url = 'http://127.0.0.1:${server.port}';
  server.listen((request) async {
    final response = request.response;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode({'ok': true, 'path': request.uri.path}));
    await response.close();
  });

  final client = HttpClient();
  final req = await client.getUrl(Uri.parse('$url/hello'));
  final res = await req.close();
  final body = await utf8.decodeStream(res);
  print('HTTP ${res.statusCode} 响应：$body');

  await server.close(force: true);
  client.close();
  print('HTTP 演示结束（服务已关闭，进程正常退出）');
}
```

- [ ] **Step 2: 创建 19_testing 包骨架**

`examples/19_testing/pubspec.yaml`：

```yaml
name: cart_demo
description: 19 章测试示例：购物车计价
version: 1.0.0
environment:
  sdk: ^3.13.0
dev_dependencies:
  lints: ^6.0.0
  test: ^1.26.0
```

`examples/19_testing/analysis_options.yaml`：

```yaml
include: package:lints/recommended.yaml
```

`examples/19_testing/.gitignore`：

```text
.dart_tool/
```

- [ ] **Step 3: 写 examples/19_testing/lib/cart.dart**

```dart
/// 19 章 fixture：一个纯逻辑购物车，演示"可测试的代码"长什么样。
class CartItem {
  final String name;
  final double unitPrice;
  final int quantity;

  const CartItem(this.name, this.unitPrice, this.quantity);

  double get subtotal => unitPrice * quantity;
}

class Cart {
  final List<CartItem> items = [];

  void add(CartItem item) {
    items.add(item);
  }

  double get total => items.fold(0, (sum, i) => sum + i.subtotal);

  /// 满 [threshold] 元打 [rate] 折（0.9 = 九折）；空车或未达标不打折。
  double payable({double threshold = 100, double rate = 0.9}) {
    if (items.isEmpty || total < threshold) {
      return total;
    }
    return total * rate;
  }

  /// 数量必须为正整数，否则抛 ArgumentError——负例测试的目标。
  static CartItem parse(String name, double price, int qty) {
    if (qty <= 0) {
      throw ArgumentError('数量必须是正数：$qty');
    }
    return CartItem(name, price, qty);
  }
}
```

- [ ] **Step 4: 写 examples/19_testing/test/cart_test.dart**

```dart
import 'package:cart_demo/cart.dart';
import 'package:test/test.dart';

void main() {
  // group：把同一主题的用例聚在一起，共享 setUp 里的夹具
  group('Cart 合计', () {
    late Cart cart;

    setUp(() {
      cart = Cart();
      cart.add(const CartItem('书', 45.0, 2));
      cart.add(const CartItem('笔', 5.0, 3));
    });

    test('单价×数量后求和', () {
      expect(cart.total, closeTo(105.0, 0.001));
    });

    test('满 100 打九折', () {
      expect(cart.payable(), closeTo(94.5, 0.001));
    });

    test('空车不打折', () {
      expect(Cart().payable(), 0);
    });
  });

  group('CartItem.parse 校验', () {
    test('负数量抛 ArgumentError', () {
      expect(() => CartItem.parse('书', 45.0, -1), throwsA(isA<ArgumentError>()));
    });

    test('正常输入', () {
      final item = CartItem.parse('书', 45.0, 1);
      expect(item.name, '书');
      expect(item.subtotal, 45.0);
    });
  });

  test('集合匹配器', () {
    final cart = Cart()..add(const CartItem('书', 45.0, 1));
    expect(cart.items.map((i) => i.name), contains('书'));
    expect(cart.items, hasLength(1));
  });
}
```

- [ ] **Step 5: 验证**

```bash
cd /g/code/guide/dart
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -File 18_files_json_http.dart
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 19_testing
```

预期：18 `[Run]` 通过且正常退出（输出 `HTTP 200 响应：{ok: true, path: /hello}`）；19_testing 输出 `[PubGet]`、`[Analyze]`、`[Test]`，6 个测试全绿（`+6`）。

- [ ] **Step 6: Commit**

```bash
cd /g/code/guide/dart && git add examples && git commit -m "feat(dart): 示例 18 文件JSONHTTP 与 19_testing 测试包

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 9: 示例 20_todo 嵌套包（实战工程）

**Files:**
- Create: `examples/20_todo/pubspec.yaml`、`analysis_options.yaml`、`.gitignore`、`lib/todo.dart`、`lib/src/task.dart`、`lib/src/parser.dart`、`lib/src/storage.dart`、`bin/todo.dart`、`test/todo_test.dart`

**Interfaces:**
- Produces: 独立 pub 包 `name: todo_cli`（第 20 章引用）；对外出口 `Task`/`TaskListX`/`TaskNotFound`/`Command` 家族/`ParseResult`/`parse`/`loadTasks`/`saveTasks`/`usageText`。Task 2 的 `-Project 20_todo` 演示序列依赖命令形态：`[-f 文件] add <标题>|list [--all]|done <id>|remove <id>`。

- [ ] **Step 1: 创建包骨架**

`examples/20_todo/pubspec.yaml`：

```yaml
name: todo_cli
description: 20 章实战：命令行待办管理器
version: 1.0.0
environment:
  sdk: ^3.13.0
dev_dependencies:
  lints: ^6.0.0
  test: ^1.26.0
```

`examples/20_todo/analysis_options.yaml`：

```yaml
include: package:lints/recommended.yaml
```

`examples/20_todo/.gitignore`：

```text
.dart_tool/
todo.json
```

- [ ] **Step 2: 写 lib/src/task.dart**

```dart
/// 一条待办。
class Task {
  final int id;
  String title;
  bool done;

  Task({required this.id, required this.title, this.done = false});

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as int,
        title: json['title'] as String,
        done: json['done'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};

  @override
  String toString() => '${done ? "[x]" : "[ ]"} #$id $title';
}

/// 预期的业务失败（第 12 章：可预期失败用 Exception 而非 Error）。
class TaskNotFound implements Exception {
  final int id;
  TaskNotFound(this.id);

  @override
  String toString() => '找不到 id=$id 的待办';
}

/// 列表上的操作：命令处理的核心逻辑（纯内存，好测试）。
extension TaskListX on List<Task> {
  int nextId() => fold(0, (max, t) => t.id > max ? t.id : max) + 1;

  void toggle(int id) {
    for (final t in this) {
      if (t.id == id) {
        t.done = !t.done;
        return;
      }
    }
    throw TaskNotFound(id);
  }

  void removeById(int id) {
    final before = length;
    removeWhere((t) => t.id == id);
    if (length == before) {
      throw TaskNotFound(id);
    }
  }
}
```

- [ ] **Step 3: 写 lib/src/parser.dart**

```dart
/// 命令解析：把 argv 变成类型安全的 Command（sealed + 模式匹配实战）。
sealed class Command {
  const Command();
}

class AddCommand extends Command {
  final String title;
  const AddCommand(this.title);
}

class ListCommand extends Command {
  final bool showAll;
  const ListCommand(this.showAll);
}

class DoneCommand extends Command {
  final int id;
  const DoneCommand(this.id);
}

class RemoveCommand extends Command {
  final int id;
  const RemoveCommand(this.id);
}

/// 解析结果：Ok(命令, 数据文件) 或 ParseErr(提示)——把错误当值传。
sealed class ParseResult {
  const ParseResult();
}

class Ok extends ParseResult {
  final Command command;
  final String file;
  const Ok(this.command, this.file);
}

class ParseErr extends ParseResult {
  final String message;
  const ParseErr(this.message);
}

const usageText = '''
用法：dart run bin/todo.dart [-f 数据文件] <命令>

命令：
  add <标题>        新增待办
  list [--all]      列出待办（默认只看未完成）
  done <id>         完成指定待办
  remove <id>       删除指定待办''';

/// 解析 [-f file] 前缀 + 子命令。
ParseResult parse(List<String> args) {
  var file = 'todo.json';
  var rest = args;
  if (rest.isNotEmpty && rest.first == '-f') {
    if (rest.length < 3) {
      return const ParseErr(usageText); // -f 之后必须有文件和命令
    }
    file = rest[1];
    rest = rest.sublist(2);
  }
  if (rest.isEmpty) {
    return const ParseErr(usageText);
  }
  final Command command;
  switch (rest[0]) {
    case 'add':
      if (rest.length < 2 || rest[1].isEmpty) {
        return const ParseErr('add 需要标题，例如：add 买牛奶');
      }
      command = AddCommand(rest[1]);
    case 'list':
      command = ListCommand(rest.contains('--all'));
    case 'done':
    case 'remove':
      final id = rest.length > 1 ? int.tryParse(rest[1]) : null;
      if (id == null) {
        return ParseErr('${rest[0]} 需要数字 id，例如：${rest[0]} 1');
      }
      command = rest[0] == 'done' ? DoneCommand(id) : RemoveCommand(id);
    default:
      return ParseErr('未知命令：${rest[0]}\n$usageText');
  }
  return Ok(command, file);
}
```

- [ ] **Step 4: 写 lib/src/storage.dart**

```dart
import 'dart:convert';
import 'dart:io';

import 'task.dart';

/// 从 JSON 文件读取待办；文件不存在视为空列表（首次使用）。
List<Task> loadTasks(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return [];
  }
  final decoded = jsonDecode(file.readAsStringSync());
  return (decoded as List)
      .map((e) => Task.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// 把待办写回 JSON 文件（缩进 2，方便人看）。
void saveTasks(String path, List<Task> tasks) {
  final json = const JsonEncoder.withIndent('  ')
      .convert(tasks.map((t) => t.toJson()).toList());
  File(path).writeAsStringSync('$json\n');
}
```

- [ ] **Step 5: 写 lib/todo.dart 与 bin/todo.dart**

`lib/todo.dart`：

```dart
/// 实战待办管理器的公共出口。
export 'src/parser.dart';
export 'src/storage.dart';
export 'src/task.dart';
```

`bin/todo.dart`：

```dart
import 'dart:io';

import 'package:todo_cli/todo.dart';

Future<void> main(List<String> args) async {
  switch (parse(args)) {
    case Ok(:final command, :final file):
      try {
        await run(command, file);
      } on TaskNotFound catch (e) {
        stderr.writeln(e);
        exit(1);
      }
    case ParseErr(:final message):
      stderr.writeln(message);
      exit(64); // 约定俗成的 usage 错误退出码
  }
}

Future<void> run(Command command, String file) async {
  final tasks = loadTasks(file);
  switch (command) {
    case AddCommand(:final title):
      final task = Task(id: tasks.nextId(), title: title);
      tasks.add(task);
      saveTasks(file, tasks);
      print('已添加：$task');
    case ListCommand(:final showAll):
      final shown = showAll ? tasks : tasks.where((t) => !t.done).toList();
      if (shown.isEmpty) {
        print('（没有待办）');
        return;
      }
      for (final t in shown) {
        print(t);
      }
      print('共 ${shown.length} 条');
    case DoneCommand(:final id):
      tasks.toggle(id);
      saveTasks(file, tasks);
      print('已完成 #$id');
    case RemoveCommand(:final id):
      tasks.removeById(id);
      saveTasks(file, tasks);
      print('已删除 #$id');
  }
}
```

- [ ] **Step 6: 写 test/todo_test.dart**

```dart
import 'dart:io';

import 'package:test/test.dart';
import 'package:todo_cli/todo.dart';

void main() {
  group('parser', () {
    test('解析 add（默认数据文件）', () {
      final ok = parse(['add', '买牛奶']) as Ok;
      expect(ok.file, 'todo.json');
      expect((ok.command as AddCommand).title, '买牛奶');
    });

    test('-f 指定数据文件 + done 命令', () {
      final ok = parse(['-f', 'a.json', 'done', '3']) as Ok;
      expect(ok.file, 'a.json');
      expect((ok.command as DoneCommand).id, 3);
    });

    test('未知命令给错误提示', () {
      final err = parse(['fly']);
      expect(err, isA<ParseErr>());
    });

    test('done 缺 id 报错', () {
      expect(parse(['done']), isA<ParseErr>());
    });

    test('list --all 生效', () {
      final ok = parse(['list', '--all']) as Ok;
      expect((ok.command as ListCommand).showAll, isTrue);
    });
  });

  group('task 操作', () {
    test('nextId 从最大 id+1', () {
      final tasks = [Task(id: 2, title: 'a'), Task(id: 5, title: 'b')];
      expect(tasks.nextId(), 6);
    });

    test('toggle 找不到抛 TaskNotFound', () {
      final tasks = [Task(id: 1, title: 'a')];
      expect(() => tasks.toggle(9), throwsA(isA<TaskNotFound>()));
    });

    test('removeById 删除后长度变化', () {
      final tasks = [Task(id: 1, title: 'a'), Task(id: 2, title: 'b')];
      tasks.removeById(1);
      expect(tasks, hasLength(1));
      expect(tasks.single.id, 2);
    });
  });

  group('storage 往返', () {
    test('保存后能原样读回；缺文件视为空', () {
      final dir = Directory.systemTemp.createTempSync('todo_test_');
      final path = '${dir.path}/t.json';
      saveTasks(path, [
        Task(id: 1, title: '买牛奶'),
        Task(id: 2, title: '写周报', done: true),
      ]);
      final restored = loadTasks(path);
      expect(restored.length, 2);
      expect(restored[1].title, '写周报');
      expect(restored[1].done, isTrue);
      expect(loadTasks('${dir.path}/missing.json'), isEmpty);
      dir.deleteSync(recursive: true);
    });
  });
}
```

- [ ] **Step 7: 验证（含演示序列）**

```bash
cd /g/code/guide/dart
"/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Project 20_todo
```

预期：`[PubGet]`、`[Analyze]`、`[Test]` 9 个测试全绿，随后 `[TodoDemo]` 八条命令依次运行：3 条 `已添加`、`list` 3 条、`已完成 #2`、`list --all` 3 条（#2 为 `[x]`）、`已删除 #3`、最终 `list --all` 2 条。

- [ ] **Step 8: Commit**

```bash
cd /g/code/guide/dart && git add examples && git commit -m "feat(dart): 示例 20_todo 实战待办管理器

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 10: docs/01-overview.md + docs/02-hello.md + docs/03-values.md + docs/05-functions.md

**Files:**
- Create: `docs/01-overview.md`（无示例，引用 `examples/02_hello.dart`）
- Create: `docs/02-hello.md`（示例 `examples/02_hello.dart`）
- Create: `docs/03-values.md`（示例 `examples/03_variables.dart`）
- Create: `docs/05-functions.md`（示例 `examples/05_functions.dart`；第 04 章控制流归 Task 11 批次）

**Interfaces:**
- Consumes: Task 3 的示例 02_hello/03_variables/05_functions（片段按 `// ═══ N.M` 小节号逐字摘录）。
- Produces: `docs/` 目录与 01/02/03/05 四章；后续章节沿用其行文结构。

注意：本批实际章节为 01/02/03 与 **05**（函数）——控制流（04）放 Task 11 与集合/类一起写，保持每批 4 章的工作量均衡。

- [ ] **Step 1: 写 01-overview.md**（约 150 行）：
  1. `# 01 · Dart 全景：为 UI 而生、为全平台而长`
  2. Dart 是什么：Google 2011 发布、Dart 3 语言大版本；定位"客户端优先"的语言——为 Flutter 而进化，但纯 Dart 控制台/服务端同样一等公民；引用 02_hello 2.1 段（5 行）作"第一印象"
  3. 编译模型表：JIT（`dart run`，开发热载快）/ AOT（`dart compile exe`，发布启动快）/ dart2js+Wasm（Web）；"一套语言、多个后端"与"JIT/AOT 行为一致"的意义
  4. Dart 与 Flutter 的关系：Flutter 是框架、Dart 是语言；本教程纯 Dart 打底（UI 见 flutter 教程一句话引导）
  5. 工具链速查表：run/analyze/format/compile/pub get/test/create/doc（每行一句话）
  6. pub 生态：pubspec.yaml 结构（name/environment/dependencies/dev_dependencies）、`^` 语义、`.dart_tool/` 与 lock 文件
  7. 本教程工作流：读章节 → `dart run examples/NN.dart` → 改代码再跑；build.ps1 用法（-All/-File/-Project/-Test/-Clean；pwsh 7 要求）
  8. 20 章学习路线图（按阶段分组：入门 02–06 / 类型系统 07–14 / 异步并发 15–17 / 生态实战 18–20）
  9. `## 坑位清单`：Windows PowerShell 5.1 读无 BOM 中文会乱码（用 pwsh 7）、`dart run` 首次会先解析依赖、别用 `dart` 命令直接跑带 package 的文件（要 `dart run`）

- [ ] **Step 2: 写 02-hello.md**（约 110 行）：
  1. `# 02 · 第一个程序：main、print 与两种运行方式`
  2. 问题先行：Dart 程序的最小形状为什么是 `void main()`；入口唯一、可带 `List<String> args`（引用 2.1 段）；args 不含程序名（对比 C 的 argv[0]）
  3. print 与字符串插值（引用 2.2 段）：`$var` 与 `${expr}` 两种形式、何时必须用花括号
  4. 两种运行方式对比表：`dart run`（JIT，改完即跑）vs `dart compile exe`（AOT，单文件发布、启动毫秒级）；各自适用场景
  5. 命令行参数（引用 2.3 段）：`args.length/first/isNotEmpty`
  6. 工具三件套：`dart analyze`（静态检查，IDE 同款引擎）、`dart format .`（官方格式化）、`dart create -t console`（脚手架）
  7. 单文件 vs pub 包：什么时候一个 .dart 就够（本教程 02–18 章），什么时候要 `dart create`（19/20 章）
  8. `## 坑位清单`：`print` 输出到 stdout、`stderr.writeln` 才是错误流；插值里复杂表达式忘加 `{}`；`main` 不能有返回值语义依赖（`exit()` 才设进程退出码）；Windows 控制台中文乱码是编码问题不是 Dart 问题

- [ ] **Step 3: 写 03-values.md**（约 170 行）：
  1. `# 03 · 变量与内置类型：一切皆对象`
  2. 问题先行：Dart 没有原始类型——int/double/bool/String 全是对象（`42.isEven` 就是证据）；这与 Java/C# 的装箱差异
  3. var 与类型推断（引用 3.1 段）：推断后类型固定；何时显式标注（公共 API、歧义处）
  4. 内置类型表（引用 3.2 段）：int（64 位）/double/String/bool/num；`num` 变量混合装 int 与 double 的场景；`is` 判型
  5. String 深入（引用 3.3 段）：插值、相邻字面量拼接、三引号多行、raw 字符串 `r''`；常用方法表（trim/split/padLeft/toUpperCase/replaceAll）；不可变性（"修改"都返回新串）
  6. 解析与转换（引用 3.4 段）：parse vs tryParse 的取舍（连第 12 章异常）；round/truncate/toInt/toDouble
  7. const vs final（引用 3.5 段）：编译期 vs 运行期；const 的深度不可变（const 列表元素也冻结）；final 只锁引用；两者都能做顶层声明
  8. dynamic（引用 3.6 段）：静态检查逃生舱；代价是错误推迟到运行时；何时合理（解析 JSON 中间态也尽量避免，第 18 章教类型安全做法）
  9. `## 坑位清单`：`var x;` 推断成 dynamic 而非报错、const 对象内不能装运行期值、`==` 对 String 比内容（引用相等仅 identical）、double 无隐式转 int（要显式）

- [ ] **Step 4: 写 05-functions.md**（约 160 行）：
  1. `# 05 · 函数：参数三形态与一等公民`
  2. 问题先行：Flutter API 为什么全是 `width: 120` 风格——答案在命名参数；函数是 Dart 里最常用的"值"
  3. 参数三形态表（引用 5.2/5.3 段）：必填位置 / 命名 `{}`（required、默认值、调用无关顺序）/ 可选位置 `[]`；设计建议：公共 API 用命名参数
  4. 箭头语法（引用 5.1 段）：`=>` 只能单表达式；与 `{ return ...; }` 完全等价
  5. 函数类型（引用 5.4 段）：`int Function(int)` 写法拆解；作为参数类型（`applyTwice`）；typedef 预告（第 14 章）
  6. 一等公民（引用 5.5 段）：匿名函数 `(n) => n * 2`；map/where 高阶用法（深入在第 06 章）
  7. 闭包（引用 5.6 段）：`makeAdder` 捕获 base；"函数 + 它看到的環境"
  8. 返回多值（引用 5.7 段）：record 返回 + `var (a, b) =` 解构；预告第 13 章
  9. `## 坑位清单`：命名参数忘写 `required` 变成"可省略必填"、`[]` 与 `{}` 不能同用一个参数列表、闭包捕获可变变量的坑、`=>` 后跟语句块是编译错

- [ ] **Step 5: 验证 + Commit**

```bash
cd /g/code/guide/dart && wc -l docs/*.md
```

预期：4 个文件各 100–200 行；抽查 2.1/3.5/5.6 三段与 examples 逐字一致。

```bash
cd /g/code/guide/dart && git add docs && git commit -m "docs(dart): 第 01/02/03/05 章 全景、hello、变量、函数

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 11: docs/04-control-flow.md + docs/06-collections.md + docs/07-classes.md + docs/08-inheritance.md

**Files:**
- Create: `docs/04-control-flow.md`（示例 `examples/04_control_flow.dart`）
- Create: `docs/06-collections.md`（示例 `examples/06_collections.dart`）
- Create: `docs/07-classes.md`（示例 `examples/07_classes.dart`）
- Create: `docs/08-inheritance.md`（示例 `examples/08_inheritance.dart`）

**Interfaces:**
- Consumes: Task 3/4 的示例。
- Produces: 04/06/07/08 章。

- [ ] **Step 1: 写 04-control-flow.md**（约 150 行）：
  1. `# 04 · 控制流：从语句到表达式`
  2. 问题先行：传统 switch 的三个毛病（fall-through、不是表达式、忘了 default）；Dart 3 用 switch 表达式一并解决
  3. if 与"没有 truthy"（引用 4.1 段）：条件必须是 bool——JS 迁移者最容易踩；`isNotEmpty` 惯用法
  4. 循环四件套（引用 4.2 段）：for/for-in/while/do-while；for-in 是集合遍历首选
  5. break/continue（引用 4.3 段）
  6. switch 语句的 Dart 3 形态（引用 4.4 段）：case 可用关系模式 `>= 90`；非空 case 体必须以 break/return/throw 收尾（历史 fall-through 已废除）
  7. switch 表达式（引用 4.5 段）：`=>` 分支、`||` 逻辑模式、`_` 兜底；直接参与赋值/返回；穷尽性检查的意义（编译器替你数分支）
  8. 三元 `?:`（引用 4.6 段）：Dart 里 if 不是表达式，要"表达式级"分支用 `?:` 或 switch 表达式
  9. `## 坑位清单`：switch 表达式忘 `_` 且未穷尽=编译错、`case 1 || 2` 合法但 `case n > 1` 要写 `case > 1` 或 when、循环变量闭包捕获（var vs final）、continue 只跳本轮

- [ ] **Step 2: 写 06-collections.md**（约 190 行）：
  1. `# 06 · 集合：List、Set、Map 与 Iterable`
  2. 三种集合定位表：List（有序可重复）/Set（唯一）/Map（键值）——何时选谁
  3. List（引用 6.1 段）：增删插查、first/last/sublist；`[...x..sort()]` 拷贝惯用法
  4. **字面量构建**（引用 6.2 段）：spread `...`、集合 if、集合 for——Dart 特色（Flutter 构建列表的基石）；对照"传统写法"表格
  5. Set（引用 6.3 段）：去重惯用法、union/intersection/difference
  6. Map（引用 6.4 段）：`[]` 读（缺键给 null）、`??` 兜底、putIfAbsent、entries 遍历
  7. Iterable 操作（引用 6.5 段）：where/map/any/every/fold/reduce/sort 对比表（各自返回什么、空集合谁抛错）；fold vs reduce
  8. 惰性（引用 6.6 段）：where/map 返回 Iterable 还没执行；toList/toSet 落袋；多次遍历的重复计算坑
  9. 不可变（引用 6.7 段）：List.unmodifiable、const 列表；与 final 的差别（连第 03 章）
  10. `## 坑位清单`：`map(...)` 忘 toList 就 print 出的是 Iterable、reduce 空集合抛错（fold 有初值不抛）、sort 是原地排序（要保留原序先拷贝）、Map 遍历时删元素要用 removeWhere

- [ ] **Step 3: 写 07-classes.md**（约 200 行）：
  1. `# 07 · 类与对象：构造函数的六种形态`
  2. 问题先行：Java/C# 的构造函数重载在 Dart 被禁——命名构造与初始化列表补位；理解"this.x 参数直赋"是读 Flutter 源码的第一关
  3. 最简类与主构造（引用 7.1 段）：`Point(this.x, this.y)` 语法糖拆解
  4. 构造函数六形态表 + 逐个讲解：主构造 / 命名构造（7.2）/ 初始化列表（7.3：构造体前执行、final 字段的赋值时机、assert）/ 重定向（7.4）/ 工厂 factory（7.5：缓存复用、单例写法）/ 常量构造 const（预告：record 与 const 的配合在 13 章）
  5. getter/setter（引用 7.6 段）：计算属性像字段；setter 拦截校验；下划线私有是"库级"而非"类级"（与 Java/C# 的关键差别）
  6. 运算符重载与 ==（引用 7.7 段）：== 重写模板（is 判型 + 字段比较）+ hashCode 成对重写（Object.hash）；不重写 == 时按引用比较
  7. static 成员与类常量：static final 缓存的用法（Temperature._cache 即例）
  8. `## 坑位清单`：重写 == 不重 hashCode（HashMap 行为诡异）、初始化列表里不能用 this、factory 不能访问实例成员、默认 == 是引用相等、私有是库级（跨文件 import 同库不隔）

- [ ] **Step 4: 写 08-inheritance.md**（约 160 行）：
  1. `# 08 · 继承、抽象与隐式接口`
  2. 问题先行：Dart 没有 `interface` 关键字——因为**每个类都隐式是一个接口**；这是从 JVM 语言里最反直觉的一条
  3. extends 与 super（引用 8.1 段）：继承实现；`super.w` 参数转发（StorableRect 例）
  4. 抽象类（引用 8.3 段）：抽象方法 + 具体方法共存；模板方法模式（describe 复用、area 多态）
  5. **implicit interface**（引用 8.4 段）：`implements Shape` 意味着"重新实现所有成员"（包括 Shape 里的具体方法）；与 extends 的对照表
  6. 多接口（引用 8.5 段）：implements A, B；与单继承的分工
  7. 三种组合方式选型表（引用 8.6 段）：extends（实现复用，单）/ implements（契约，多）/ with（横切能力，第 09 章）
  8. `## 坑位清单`：implements 后忘实现具体方法=编译错、`@override` 可省但不该省（拼写错误直接暴露）、抽象类不能实例化但可以有工厂构造与静态成员、多态调用看运行时类型

- [ ] **Step 5: 验证 + Commit**

```bash
cd /g/code/guide/dart && wc -l docs/04*.md docs/06*.md docs/07*.md docs/08*.md
```

预期：各 100–200 行（07 可到 220）；抽查 4.5/6.2/7.5/8.4 四段与 examples 逐字一致。

```bash
cd /g/code/guide/dart && git add docs && git commit -m "docs(dart): 第 04/06/07/08 章 控制流、集合、类、继承接口

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 12: docs/09-mixins-modifiers.md + docs/10-null-safety.md + docs/11-generics.md + docs/12-exceptions.md

**Files:**
- Create: `docs/09-mixins-modifiers.md`（示例 `examples/09_mixins_modifiers.dart`）
- Create: `docs/10-null-safety.md`（示例 `examples/10_null_safety.dart`）
- Create: `docs/11-generics.md`（示例 `examples/11_generics.dart`）
- Create: `docs/12-exceptions.md`（示例 `examples/12_exceptions.dart`）

**Interfaces:**
- Consumes: Task 5/6 的示例。
- Produces: 09–12 章。

- [ ] **Step 1: 写 09-mixins-modifiers.md**（约 180 行）：
  1. `# 09 · Mixin 与类修饰符：组合优于继承的 Dart 答案`
  2. 问题先行：单继承装不下"会飞 + 会游 + 会叫"这类横切能力；多继承又有菱形问题——mixin 线性化是 Dart 的解法
  3. mixin 与 with（引用 9.1 段）：行为片段；Dog 同时获得 Animal 继承 + Pet/Logger 混入
  4. `mixin on`（引用 9.2 段）：限定基类才能安全调用其成员（Pet 用 name）
  5. **线性化**（引用 9.3 段）：`with A, B` 从左到右叠加、后者覆盖；画一条线性链文字图；对比 C++/Python MRO 一句话
  6. **sealed**（引用 9.4 段）：封闭在同一库内的继承树；换来的穷尽检查（describeResult 不需要 `_`）；与第 13 章 switch 的配合预告
  7. base/final/interface 修饰符表（引用 9.5 段）：每个修饰符"允许/禁止什么"（extends/with/implements 三列）；适用场景（库作者控制扩展面）
  8. `## 坑位清单`：mixin 不能有构造参数、同名方法冲突时"静默后者胜"（要留意线性化顺序）、sealed 子类必须同库、base 类跨库 implements 是编译错

- [ ] **Step 2: 写 10-null-safety.md**（约 170 行）：
  1. `# 10 · 空安全：把 null 关进类型系统`
  2. 问题先行："十亿美元错误"；Dart 2.12 sound null safety——类型系统保证"不可空就是不会有 null"
  3. 默认非空（引用 10.1 段）：`String` 装不下 null；`String?` 是另一个类型（联合类型视角）
  4. 操作符四件套表（引用 10.2/10.3 段）：`?.`（null 短路）/`??`（兜底）/`??=`（空才赋）/`!`（断言非空，运行时背锅）
  5. **类型提升**（引用 10.4 段）：局部变量判空后自动窄化；**字段不提升**（Profile.display 的编译错误注释行）——为什么（并发/别名风险）；字段的两条出路：local 拷贝或 `?.`/`??`
  6. late（引用 10.5 段）：惰性求值（loadConfig 证据输出）；late final；"忘了初始化就访问"的运行时错误
  7. 可空参数设计（引用 10.6 段）：`String?` + `??` 默认值；与 required 命名参数的组合
  8. `## 坑位清单`：滥用 `!`（每写一次问一次凭什么）、字段判空后仍报错（提升不覆盖字段）、`late` 循环初始化崩溃、`??` 与 `||` 混淆（bool? 场景）

- [ ] **Step 3: 写 11-generics.md**（约 150 行）：
  1. `# 11 · 泛型：参数化类型与协变边界`
  2. 问题先行：没有泛型的集合只能 List<dynamic>——丢类型检查；泛型把"集合装什么"写进类型
  3. 泛型类（引用 11.1 段）：Box/Pair；构造处类型推断
  4. 泛型方法与约束（引用 11.2/11.3 段）：`T extends num` 才有 `>`；`Comparable<T>` 约束的 sortedCopy
  5. 泛型 + 空安全（引用 11.4 段）：返回 `T?` 表达"可能没有"
  6. **协变**（引用 11.5 段）：`List<int>` 赋给 `List<num>` 合法；代价是运行时检查（nums.add(1.5) 抛 TypeError）；对比 Java 数组协变/泛型不变——Dart 选择了"方便 + 运行时兜底"
  7. **reified**（引用 11.6 段）：`is List<int>` 运行时可知（Java 擦除做不到）；`runtimeType` 的用途与滥用
  8. `## 坑位清单`：`List<dynamic>` 不是万能袋（读出要 cast）、协变写入的运行时 TypeError、泛型参数无约束时只能当 Object 用、`is` 判可空类型（`x is int?`）的语义

- [ ] **Step 4: 写 12-exceptions.md**（约 160 行）：
  1. `# 12 · 异常：Error 与 Exception 的分界线`
  2. 问题先行：捕获异常太方便，以至于把 bug 也 try 掉——Dart 用 Error/Exception 两族划清"修代码"与"处理失败"
  3. throw 与 Never（引用 12.1 段）：任意对象可抛但请只用异常；`Never` 返回类型标记"不会正常返回"
  4. try/on/catch（引用 12.2 段）：on 按类型过滤、catch 拿对象；`on X catch (e)` 组合
  5. 栈与 rethrow（引用 12.3 段）：`catch (e, stack)`；rethrow 保留原栈（区别于 throw e）
  6. finally（引用 12.4 段）：执行时机与资源释放
  7. **Error vs Exception 表**（引用 12.5 段）：Error=程序 bug（RangeError/TypeError/CastError）不该捕获；Exception=可预期失败该在合适层处理；`ArgumentError` 归 Error 族（调用方 bug）
  8. 自定义异常（引用 12.6 段）：`implements Exception` + toString；带上下文字段（need/have）
  9. `## 坑位清单`：裸 `catch (e)` 吞 Error（连断言都吞）、finally 里 return/throw 覆盖原异常、`throw e` 丢栈（要 rethrow）、异常当流程控制可读性差（可预期失败优先返回值，第 20 章 ParseErr 即例）

- [ ] **Step 5: 验证 + Commit**

```bash
cd /g/code/guide/dart && wc -l docs/09*.md docs/10*.md docs/11*.md docs/12*.md
```

预期：各 100–200 行；抽查 9.4/10.4/11.5/12.5 四段与 examples 逐字一致。

```bash
cd /g/code/guide/dart && git add docs && git commit -m "docs(dart): 第 09–12 章 mixin修饰符、空安全、泛型、异常

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 13: docs/13-records-patterns.md + docs/14-extensions.md + docs/15-async.md + docs/16-streams.md

**Files:**
- Create: `docs/13-records-patterns.md`（示例 `examples/13_records_patterns.dart`）
- Create: `docs/14-extensions.md`（示例 `examples/14_extensions.dart`）
- Create: `docs/15-async.md`（示例 `examples/15_async.dart`）
- Create: `docs/16-streams.md`（示例 `examples/16_streams.dart`）

**Interfaces:**
- Consumes: Task 6/7 的示例。
- Produces: 13–16 章。

- [ ] **Step 1: 写 13-records-patterns.md**（约 220 行，本教程重点章）：
  1. `# 13 · 记录与模式匹配：Dart 3 的表达力跃迁`
  2. 问题先行：返回两个值要建类？switch 只能配常量？一堆 is+as+判空的样板？——records + patterns 一次解决
  3. record（引用 13.1 段）：位置/命名字段；`$1` 访问；**结构相等**（== 自动按字段）；不可变；vs class 选型表（临时聚合用 record、有身份/行为用 class）
  4. 解构（引用 13.2 段）：`var (x, y) = point`；final 同样可解构；交换两值的惯用法
  5. 返回多值（引用 13.3 段）：`(int, int) bounds` + 解构接收——替代建 Pair 类
  6. **模式族谱表**（引用 13.4/13.5 段）：常量/变量/或 `||`/关系/when 卫兵/列表 `[a, ...]`/映射 `{'k': v}`/对象 `Circle(r: var r)`/类型判别；classify 的六个分支逐个讲
  7. **sealed + 穷尽 switch**（引用 13.6 段）：area 对三种 Shape 无 `_` 兜底；新增 Triangle 子类时编译器强制补分支（重构安全网）；连第 09 章
  8. 模式还能用在哪：switch 语句、if-case、for-in 模式（各一行示例）
  9. `## 坑位清单`：record 字段类型不同则 == 为 false（(1,'a') vs (1,'b')）、解构变量数必须匹配、switch 表达式穷尽性对非 sealed 需 `_`、`_` 通配丢弃值别用于命名字段

- [ ] **Step 2: 写 14-extensions.md**（约 160 行）：
  1. `# 14 · 扩展：不改源码地"加方法"`
  2. 问题先行：给 String 加个 wordCount，Java 只能写工具类 StringUtil；Dart 扩展让调用读起来像成员方法
  3. extension 基础（引用 14.1 段）：on String；静态解析（不是注入成员，编译期换算成静态调用）——所以效率无损失
  4. 泛型扩展（引用 14.2 段）：`extension ListX<T> on List<T>`
  5. 可空扩展（引用 14.3 段）：`on String?` 内部 this 可为 null——`?? '-'` 处理
  6. **冲突解析**（引用 14.4 段）：两个同名扩展方法=隐式调用编译错；显式 `ShoutX('hi').shout()`；导入冲突与 hide/show
  7. **extension type**（引用 14.5 段，Dart 3.3+）：零开销新类型；`Meters` 不与 double 互通（编译错即价值：单位错误提前暴露）；vs 普通包装类（无分配开销）；限制（无接口实现身份、不能扩展已有类型）
  8. typedef（引用 14.6 段）：类型别名（IntList）；函数类型别名（Mapper）——复杂函数签名的降噪
  9. `## 坑位清单`：扩展在 null 上不安全（`null.foo()` 静态通过？——on String? 才收 null）、扩展方法不能被子类覆写（静态分发）、扩展成员不能存状态（无字段）、extension type 会被 is 检查拆穿

- [ ] **Step 3: 写 15-async.md**（约 180 行）：
  1. `# 15 · Future 与 async/await：单线程异步`
  2. 问题先行：一个线程怎么同时等网络、文件、定时器——事件循环 + 非阻塞 Future；"await 不是开线程"是本章第一课
  3. Future 概念（引用 15.1 段）："将来才有的值"占位；创建即调度、await 才取
  4. async/await（引用 15.2 段）：async 函数体自动包装 Future；await 只能在 async 内；串行 await 的时序
  5. 错误处理（引用 15.3 段）：try/catch/finally 与同步完全一致——这是 await 的最大红利
  6. **并行**（引用 15.4 段）：`Future.wait` 对比逐个 await；耗时演示读数；`Future.wait` 一个失败即抛（错误策略一段带过）
  7. then 链（引用 15.5 段）：历史写法；catchError/whenComplete；何时还会见到（无 async 上下文）
  8. **事件循环**（引用 15.6 段）：两队列模型图（microtask 优先插队、event 排队）；演示输出顺序逐行解释；为什么 UI 不卡=单线程不阻塞
  9. `## 坑位清单`：循环里 await 是串行（要并行用 Future.wait）、忘 await 的 Future 静默吞错、async 函数里 return 值被包 Future、`Future.value` 立即值也要等 microtask

- [ ] **Step 4: 写 16-streams.md**（约 180 行）：
  1. `# 16 · Stream：异步的数据序列`
  2. 问题先行：Future 是"一个将来值"，WebSocket/文件逐行/传感器是"一串将来值"——Stream 是异步 Iterable
  3. 消费（引用 16.1 段）：await for；与 for-in 对称性
  4. **async* 生成器**（引用 16.2 段）：yield 产出、暂停、消费者驱动节奏；同步对应 sync*/Iterable
  5. 工厂（引用 16.3 段）：fromIterable/periodic/take/toList——流也有一套组合子（map/where 同 Iterable）
  6. **单订阅 vs 广播**（引用 16.4 段）：默认流只能听一次；asBroadcastStream 多听众；对比表（缓冲、重放、适用）
  7. StreamController（引用 16.5 段）：手动 add/close；必须 close 否则 await for 永挂
  8. 错误与 done（引用 16.6 段）：错误是流内事件；await for + try/catch；流正常结束事件 done
  9. Stream vs Future API 对照小表（一个值 vs 序列）
  10. `## 坑位清单`：单订阅流二次监听抛 StateError、忘 close 导致挂起（build 全量验证会抓）、广播流早到的听众错过已发事件、listen 与 await for 别混用同一流

- [ ] **Step 5: 验证 + Commit**

```bash
cd /g/code/guide/dart && wc -l docs/13*.md docs/14*.md docs/15*.md docs/16*.md
```

预期：13 章 180–220 行，其余 100–200；抽查 13.5/14.5/15.6/16.4 四段与 examples 逐字一致。

```bash
cd /g/code/guide/dart && git add docs && git commit -m "docs(dart): 第 13–16 章 记录模式、扩展、异步、流

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 14: docs/17-isolates.md + docs/18-files-json-http.md + docs/19-testing.md + docs/20-todo.md

**Files:**
- Create: `docs/17-isolates.md`（示例 `examples/17_isolates.dart`）
- Create: `docs/18-files-json-http.md`（示例 `examples/18_files_json_http.dart`）
- Create: `docs/19-testing.md`（示例 `examples/19_testing/`）
- Create: `docs/20-todo.md`（示例 `examples/20_todo/`）

**Interfaces:**
- Consumes: Task 7/8/9 的示例。
- Produces: 17–20 章，docs/ 共 20 章齐。

- [ ] **Step 1: 写 17-isolates.md**（约 170 行）：
  1. `# 17 · Isolate：没有共享内存的并发`
  2. 问题先行：CPU 密集任务在主 isolate 跑会卡事件循环（UI 掉帧）；传统方案是多线程+锁——Dart 的答案是不共享
  3. 模型（引用 17.1 段思路）：每 isolate 独立堆 + 消息传递；没有数据竞争（不需要锁）；与线程/进程对比表
  4. **Isolate.run**（引用 17.2 段）：一行搬计算（fibSlow 30 不卡）；现代首选 API
  5. 手工协议（引用 17.3 段）：spawn + SendPort/ReceivePort + 握手；record 传 (data, sendPort)；Completer 桥接 Future
  6. 拷贝语义（引用 17.4 段）：heavySort 原 list 不变；可发送对象边界一段（基本类型/集合/record 可，含闭包引用；Random 不可——一句带过）
  7. 何时用：CPU 密集→isolate；IO 密集→纯 Future 就够（事件循环天然并发）；Flutter 的 compute 即封装
  8. `## 坑位清单`：忘关 ReceivePort 进程不退出（17 示例特设注释）、worker 抛异常如何传回（Isolate.run 会转发）、跨 isolate 改数据不会反映（拷贝）、把 IO 密集硬塞 isolate 无收益

- [ ] **Step 2: 写 18-files-json-http.md**（约 180 行）：
  1. `# 18 · 文件、JSON 与 HTTP：dart:io 三件套`
  2. 问题先行：配置/缓存/接口——落地三件事；dart:io + dart:convert 全标准库
  3. File（引用 18.1 段）：async API（writeAsString/readAsString/exists/length）；mode write/append；同步版 API 存在但 CLI 之外的场景应 async
  4. Directory（引用 18.2 段）：systemTemp.createTemp；list/delete(recursive)
  5. JSON 基础（引用 18.3 段）：jsonEncode/jsonDecode；解码产物是 Map<String,dynamic>/List（动态）——runtimeType 证据
  6. **类型安全 JSON**（引用 18.4 段）：fromJson 工厂 + toJson + as 强转；`as` 失败抛 TypeError（连第 11/12 章）；为什么不用代码生成（教学手动写，生态里 json_serializable 一句话）
  7. **HttpServer**（引用 18.5 段）：bind 随机端口（0）；listen 处理请求；HttpClient 自请求；close(force) 收尾——"自测型示例"模式（不挂起）
  8. `## 坑位清单`：jsonDecode 后忘 as 直接用下标（dynamic 静默通过、运行时炸）、相对路径依赖 cwd（用绝对路径或传参）、HttpServer 不 close 进程挂着、Windows 路径分隔符（用 Platform.pathSeparator 或 URI）

- [ ] **Step 3: 写 19-testing.md**（约 170 行）：
  1. `# 19 · 测试：package:test 与可测试的代码`
  2. 问题先行：为什么 20 章实战敢重构——因为有测试兜底；测试是教程 20 章知识的应用题
  3. 工程（引用 19_testing 包结构）：dev_dependencies + test/ 目录约定；`dart test` 跑全部、`--plain-name` 跑单个
  4. 骨架（引用 cart_test.dart）：test/group/expect 三原语；setUp/tearDown 夹具；AAA 结构（准备-执行-断言）
  5. 匹配器表：equals/closeTo（浮点必用）/throwsA(isA<T>())/contains/hasLength/isTrue/isNull/predicate——各一行适用
  6. **好测试的形状**（引用 Cart 设计）：纯逻辑（无 IO）易测；依赖注入（threshold/rate 参数化）；负例（parse 抛 ArgumentError）与正例成对；边界（空车）
  7. 测试驱动小流程：先写失败测试→最小实现→重构（红绿重构一段）；`dart test --reporter expanded` 看明细
  8. 覆盖率一句话：`dart test --coverage`；mock 何时需要（边界 IO，mocktail 一句话预告生态）
  9. `## 坑位清单`：浮点用 equals 会抖（closeTo）、测试之间共享可变全局状态、依赖执行顺序的测试、抛错断言写了却先抛在准备阶段

- [ ] **Step 4: 写 20-todo.md**（约 200 行，实战章）：
  1. `# 20 · 实战：CLI 待办管理器`
  2. 成品演示：演示命令序列 + 输出（build.ps1 TodoDemo 的八条命令实跑输出）
  3. 工程结构讲解：bin（入口）/lib/src（分层）+ 出口文件；pubspec；为什么入口薄、逻辑进 lib（可测试）
  4. **建模**（task.dart）：Task 类（fromJson/toJson/copyWith）；TaskNotFound（第 12 章选型：Exception 非 Error）；TaskListX 扩展（第 14 章）承载操作
  5. **解析**（parser.dart）：sealed Command 家族 + ParseResult（Ok/ParseErr）——错误当值（呼应第 12 章坑位）；switch 语句处理子命令；usageText 常量
  6. **持久化**（storage.dart）：jsonEncode withIndent；文件缺失=空列表；同步 IO 的取舍（CLI 简单性）与 async 化思路
  7. **入口**（bin/todo.dart）：switch 解构 ParseResult（第 13 章模式落地：`Ok(:final command, :final file)`）；exit 码约定（64 usage/1 业务失败）；Command 分派四 case
  8. **测试**（todo_test.dart）：parser/task 操作/存储往返三组；临时目录夹具
  9. 扩展方向清单（每条一两句）：截止日期字段、`--format json` 输出、颜色输出（ANSI 转义）、HTTP 同步、用 args 包重写解析
  10. `## 坑位清单`：argv 与 `dart run bin/todo.dart` 的参数边界、JSON 里 DateTime 要手动序列化、exitCode 与 return 的区别、测试里用真实临时目录后要清理

- [ ] **Step 5: 验证 + Commit**

```bash
cd /g/code/guide/dart && wc -l docs/17*.md docs/18*.md docs/19*.md docs/20*.md && ls docs | wc -l
```

预期：各 100–200 行（20 章可到 220）；docs/ 共 20 个文件；抽查 17.2/18.4/19.4/20.5 与 examples 逐字一致。

```bash
cd /g/code/guide/dart && git add docs && git commit -m "docs(dart): 第 17–20 章 Isolate、文件JSONHTTP、测试、实战待办

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 15: 根 test/guide_test.dart + README.md 重写 + CHEATSheet.md 新增

**Files:**
- Create: `test/guide_test.dart`
- Create: `README.md`（重写，先删旧内容）
- Create: `CHEATSheet.md`

**Interfaces:**
- Consumes: 根包 pubspec（Task 1）；`build.ps1 -Test` 入口（Task 2）。
- Produces: 根测试全绿；README 章节索引表与 docs/ 一一对应（Task 16 校验依赖）。

- [ ] **Step 1: 写 test/guide_test.dart**（自包含，不 import 示例文件）

```dart
import 'dart:convert';

import 'package:test/test.dart';

// 测试自包含的最小定义（覆盖扩展/密封/mixin 三个章节主题）
extension WordCountX on String {
  int get wordCount => trim().isEmpty ? 0 : trim().split(' ').length;
}

sealed class Op {
  const Op();
}

class AddOp extends Op {
  final int n;
  const AddOp(this.n);
}

class MulOp extends Op {
  final int n;
  const MulOp(this.n);
}

int apply(List<Op> ops, int seed) =>
    ops.fold(seed, (acc, op) => switch (op) {
          AddOp(n: var n) => acc + n,
          MulOp(n: var n) => acc * n,
        });

mixin WhoA {
  String who() => 'A';
}

mixin WhoB {
  String who() => 'B';
}

class Mixed with WhoA, WhoB {}

void main() {
  test('字符串插值与操作', () {
    final name = 'Dart';
    expect('Hello, $name!', 'Hello, Dart!');
    expect('  x '.trim(), 'x');
    expect('a,b'.split(','), ['a', 'b']);
  });

  test('集合操作', () {
    final nums = [5, 2, 9];
    expect(nums.where((n) => n > 3).toList(), [5, 9]);
    expect({...nums, 5}.length, 3);
    expect({'a': 1}['b'], isNull);
    expect([3, 1, 2]..sort(), [1, 2, 3]);
  });

  test('const 字面量规范化', () {
    const a = [1, 2];
    const b = [1, 2];
    expect(identical(a, b), isTrue);
  });

  test('空安全操作符', () {
    String? s;
    expect(s?.length, isNull);
    expect(s ?? '默认', '默认');
    s = 'x';
    expect(s!.length, 1);
  });

  test('密封类穷尽 switch', () {
    expect(apply([const AddOp(3), const MulOp(4)], 1), 16);
  });

  test('记录结构相等与解构', () {
    expect((x: 1, y: 2) == (x: 1, y: 2), isTrue);
    final (lo, hi) = (3, 7);
    expect(lo + hi, 10);
  });

  test('扩展方法', () {
    expect('a b c'.wordCount, 3);
  });

  test('泛型协变与运行时类型', () {
    final ints = <int>[9];
    expect(ints is List<num>, isTrue);
    final nums = <num>[1, 2, 3];
    expect(nums.first, 1);
  });

  test('异常', () {
    expect(() => throw ArgumentError('x'), throwsArgumentError);
    try {
      int.parse('x');
      fail('应当抛 FormatException');
    } on FormatException {
      // 预期路径
    }
  });

  test('Future 与 Stream', () async {
    final v = await Future<int>.value(7);
    expect(v, 7);
    final collected = await Stream.fromIterable([1, 2, 3]).toList();
    expect(collected, [1, 2, 3]);
  });

  test('JSON 编解码往返', () {
    final encoded = jsonEncode({'k': [1, 2]});
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    expect(decoded['k'], [1, 2]);
  });

  test('mixin 线性化：后者覆盖前者', () {
    expect(Mixed().who(), 'B');
  });
}
```

- [ ] **Step 2: 跑根测试**

```bash
cd /g/code/guide/dart && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Test
```

预期：`[Analyze]` 无告警、`[Test]` 12 个用例全绿。

- [ ] **Step 3: 重写 README.md**（对齐 fsharp README 格式，约 70 行）：

  1. 标题 `# Dart 语言开发指南`；定位段：面向**会编程、初学 Dart** 的读者；主线 Dart SDK 3.13；每章"读讲解 → 跑示例 → 改代码再跑"；UI 开发见 flutter 教程一句话
  2. 目录结构代码块（README.md / docs / examples / test / build.ps1 / pubspec.yaml / CHEATSheet.md，各一行注释）
  3. **章节索引表**（20 行三列表：章主题链接 | 主题 | 示例；01 行示例列写 `—`，19/20 行写目录名）
  4. 构建工具链：SDK 路径 `G:\scoop\apps\dart\current\bin\dart.exe`（3.13.4）；pwsh 7 要求
  5. 编译验证命令块（-All/-File/-Project/-Test/-Clean 五行 + 行为分级一句话）
  6. 单跑某个示例：`dart run examples/06_collections.dart`（第 02 章起的标准学法）

- [ ] **Step 4: 写 CHEATSheet.md**（约 180 行，速查非教程）：
  1. `# Dart 速查表`（开头注明：配教程使用，按章号引用）
  2. 变量与常量：var/final/const/dynamic/late 一表
  3. 内置类型与转换：num 家族、parse/tryParse、round/truncate
  4. 字符串：插值、三引号、raw、常用方法
  5. 函数：三种参数形态速记、=>、函数类型写法
  6. 集合：字面量三种、spread/集合 if/for、Iterable 组合子表、Set/Map API
  7. 类：构造六形态一行一个、getter/setter、==/hashCode 模板、运算符重载语法
  8. 继承与 mixin：extends/implements/with 选型一行表；sealed/base/final/interface 四行表
  9. 空安全：?/?./??/??=/!/late 五行表 + 类型提升注意
  10. 泛型：约束语法、协变提醒
  11. 异常：try/on/catch/rethrow/finally 骨架、Error vs Exception 分界
  12. 记录与模式：record 字面量、解构、模式族谱一行表、sealed 穷尽骨架
  13. 扩展：extension 声明骨架、冲突显式调用、extension type、typedef
  14. 异步：async/await 骨架、Future.wait、then 链；Stream：async*/yield/await for/broadcast 骨架；Isolate.run 一行
  15. 文件/JSON/HTTP：File 读写三行、jsonEncode/Decode、HttpServer 骨架
  16. 测试：expect 常用匹配器表
  17. 命令速查：run/analyze/format/compile/pub/test/create

- [ ] **Step 5: Commit**

```bash
cd /g/code/guide/dart && git add test README.md CHEATSheet.md && git commit -m "docs(dart): 根测试 12 例、重写 README、新增 CHEATSheet

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 16: 终验（全量 -All + 一致性检查）

**Files:**
- 无新文件（只验证；发现问题回修对应文件后重跑）

**Interfaces:**
- Consumes: 全部前置任务。
- Produces: 终验通过的教程成品。

- [ ] **Step 1: 全量验证**

```bash
cd /g/code/guide/dart && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -All
```

预期（逐项核对）：`[Analyze]` No issues；17 个 `[Run]`（02–18）全部成功且正常退出；`[AOT]` 生成 build/02_hello.exe；19_testing `[Test]` +6；20_todo `[Test]` +9；`[TodoDemo]` 八条命令成功；根 `[Test]` +12；末行 `[Done]`。

- [ ] **Step 2: 一致性检查**

```bash
cd /g/code/guide/dart && ls docs | wc -l && ls examples/*.dart | wc -l && wc -l docs/*.md | tail -1 && grep -c "docs/" README.md
```

预期：docs 20 个文件；examples 单文件 17 个；docs 总行数 2800–4000；README 含 20 个 docs/ 链接。抽查三个章节的代码片段与 examples 对应小节逐字一致（用 grep 抽 2.1、10.4、20.5）。

- [ ] **Step 3: 清理与收尾**

```bash
cd /g/code/guide/dart && "/g/Program Files/PowerShell/7/pwsh" -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Clean && git status --short
```

预期：`git status` 干净（build/ 与 .dart_tool/ 被忽略，不入库）。若有未提交变更，补提交。

- [ ] **Step 4: Commit（如有收尾变更）**

```bash
cd /g/code/guide/dart && git add -A && git commit -m "chore(dart): 教程终验收尾

Co-Authored-By: Claude Code <noreply@anthropic.com>" || echo "无收尾变更，跳过"
```
