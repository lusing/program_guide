# 20 · 实战：CLI 待办管理器

> 对应示例：examples/20_todo/（独立 pub 包）

## 20.1 成品与目标

本章把 19 章的知识拼成一件完整的产品：一个命令行待办管理器。先看它跑起来的样子（`./build.sh --project 20_todo` 或 `build.ps1 -Project 20_todo` 的演示序列实跑输出）：

```text
$ dart run bin/todo.dart -f build/todo-demo.json add 买牛奶
已添加：[ ] #1 买牛奶
$ … add 写周报 … add 修剪草坪
$ … list
[ ] #1 买牛奶
[ ] #2 写周报
[ ] #3 修剪草坪
共 3 条
$ … done 2
已完成 #2
$ … list --all
[ ] #1 买牛奶
[x] #2 写周报
[ ] #3 修剪草坪
共 3 条
$ … remove 3
已删除 #3
```

功能四件套：add / list（默认只看未完成，--all 看全部）/ done / remove，数据落在 JSON 文件（`-f` 指定，默认 `todo.json`）。目标不是功能多，而是**每个设计决策都能在前 19 章找到出处**。

## 20.2 工程结构：入口薄、逻辑进 lib

```text
20_todo/
├── pubspec.yaml          # name: todo_cli
├── bin/todo.dart         # 入口：解析 → 分派 → 退出码（薄）
├── lib/
│   ├── todo.dart         # 公共出口：export 三个 src
│   └── src/
│       ├── task.dart     # 数据模型 + 列表操作
│       ├── parser.dart   # argv → Command（纯函数）
│       └── storage.dart  # JSON ↔ 文件
└── test/todo_test.dart   # 三组测试
```

为什么入口要薄、逻辑进 lib？**bin 里的代码无法被测试导入**（工程入口不可 import），lib 是包的对外接口——第 19 章"逻辑可测"的工程化落法。三个 src 各管一段：模型、解析、存储，互相之间只在入口处汇合。

## 20.3 建模：Task、异常与列表操作

```dart
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
```

fromJson/toJson 是第 18 章的海关模板（`bool? ?? false` 兼容旧数据缺字段）；命名参数 + required 是第 05 章。两个决策值得停一下：

```dart
/// 预期的业务失败（第 12 章：可预期失败用 Exception 而非 Error）。
class TaskNotFound implements Exception {
  final int id;
  TaskNotFound(this.id);

  @override
  String toString() => '找不到 id=$id 的待办';
}
```

"找不到该 id"是**用户输入的正常失败分支**，按第 12 章分界线建为 Exception（带上下文 id、toString 可读）。操作不写成 Task 的方法，而是挂在列表上的扩展（第 14 章）——"对一批待办做的事"归列表，语义更顺：

```dart
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
  // removeById 同构，略
}
```

## 20.4 解析：sealed Command + 错误当值

argv 是 `List<String>`，第一道工序是把它变成**类型安全的数据**——这是第 09/13 章的合体实战：

```dart
sealed class Command {
  const Command();
}

class AddCommand extends Command {
  final String title;
  const AddCommand(this.title);
}
// ListCommand(showAll) / DoneCommand(id) / RemoveCommand(id) 同构，略

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
```

两层 sealed：Command 家族消灭"字符串命令 + 到处 if"的散弹式修改；ParseResult 把"用法错误"建成值而不是异常——第 12 章坑位清单里"可预期分支优先返回值建模"的落实。解析主体 `parse(List<String> args)` 是纯函数（无 IO、同输入同输出），先摘 `-f 文件` 前缀，再按第 04 章的 switch 语句分派子命令（空 case 体直落、共享 case 用堆叠写法 `case 'done': case 'remove':`）。

## 20.5 持久化与入口

storage 就两个函数（第 18 章套路：缺文件=空列表、缩进 2 便于人看、同步 IO 的 CLI 取舍）：

```dart
List<Task> loadTasks(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return [];
  }
  // jsonDecode → List<Task>，略
}

void saveTasks(String path, List<Task> tasks) {
  final json = const JsonEncoder.withIndent('  ')
      .convert(tasks.map((t) => t.toJson()).toList());
  File(path).writeAsStringSync('$json\n');
}
```

入口 bin/todo.dart 是全程序的"汇流处"，通篇是学过的招式：

```dart
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
```

`switch` 解构 ParseResult（第 13 章对象模式 + 解构参数）；业务失败 stderr + exit(1)、用法错误 exit(64)（第 02 章的退出码坑位）；`run` 里再对 Command 做一次 sealed 穷尽 switch 分派——四种命令各一个 case，将来加命令，编译器立刻指出要补的地方。

## 20.6 测试：三组覆盖三条主线

```dart
  group('parser', () {
    test('解析 add（默认数据文件）', () {
      final ok = parse(['add', '买牛奶']) as Ok;
      expect(ok.file, 'todo.json');
      expect((ok.command as AddCommand).title, '买牛奶');
    });
    // -f/done、未知命令、缺 id、--all 共 5 例
```

parser 组测纯函数的正反例；task 操作组测 nextId/toggle 抛 TaskNotFound；storage 组用 `Directory.systemTemp.createTempSync` 做临时夹具，往返读写并清理（第 19 章的夹具纪律）。九个用例，全部毫秒级。

## 20.7 扩展方向

学完本章，这些方向每个都是一次独立的练习：截止日期字段（DateTime 序列化要手转字符串）、`--format json` 输出（复用 toJson）、ANSI 颜色（`\x1b[32m` 转义序列）、HTTP 同步（第 18 章的 HttpServer 做后端）、用 package:args 重写解析（体验"社区包 vs 手写"的边界）。

## 坑位清单

- **argv 不含程序名**：`dart run bin/todo.dart add x` 里 args[0] 是 `add`（第 02 章）；`dart run` 本身的参数与脚本参数要分清。
- **JSON 里没有 DateTime**：jsonEncode 不会自动序列化 DateTime，存储前先 `toIso8601String()`，读取再 parse。
- **exit 立即终止进程**：exit 后 stdout 缓冲可能没刷完，关键输出先 await 完成再 exit。
- **测试用真实临时目录后要清理**：`dir.deleteSync(recursive: true)` 放在用例尾部；泄漏的临时目录会在 CI 磁盘上堆积。
