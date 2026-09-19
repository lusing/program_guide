# 02 · 第一个程序：main、print 与两种运行方式

> 对应示例：examples/02_hello.dart

## 2.1 解决什么问题

任何语言的第一个问题都是"程序从哪开始"。Dart 的答案简单到一句话：**`main` 是唯一入口**，没有第二种写法（对比 C++ 可以指定入口函数、Python 按文件顺序执行）。

```dart
// 参数列表可省略；需要命令行参数时声明为 List<String>（args 不含程序名）
void main(List<String> args) {
```

两个细节值得注意：`main` 的参数列表**可以整个省略**（不关心命令行参数时），以及 `args` **不含程序名**——`dart run todo.dart add 买牛奶` 里 `args` 是 `['add', '买牛奶']`，而 C 语言的 `argv[0]` 是程序名。第 20 章的实战工程就靠这个差异解析命令。

## 2.2 print 与字符串插值

输出用 `print`，字符串里嵌值用**插值**——这是 Dart 字符串的核心机制，也是你以后写得最多的语法之一：

```dart
  // ═══ 2.2 print 与字符串插值 ═══
  var name = 'Dart';
  var version = 3.13;
  print('Hello, $name!'); // $变量
  print('version = ${version.toStringAsFixed(2)}'); // ${表达式}
```

两种写法的分工：

| 写法 | 何时用 | 例子 |
|---|---|---|
| `$变量` | 单个标识符，后面紧跟的字符不属于标识符 | `$name` |
| `${表达式}` | 访问成员、调用方法、任意表达式 | `${pi.toStringAsFixed(2)}` |

经验法则：**能 `$` 就 `$`，一访问成员就 `${}`**。第 03 章会展开字符串的全部细节。

## 2.3 命令行参数

`args` 是 `List<String>`，天然的集合操作都可用（第 06 章）：

```dart
  // ═══ 2.3 命令行参数 ═══
  print('收到 ${args.length} 个参数：$args');
  if (args.isNotEmpty) {
    print('第一个参数：${args.first}');
  }
```

`isNotEmpty` 而不是 `length > 0`——这是 Dart 社区的既定惯用法，lint 工具也会这么建议。

## 2.4 两种运行方式：JIT 与 AOT

同一个文件，两种跑法，对应第 01 章的编译模型表：

```bash
# 开发：JIT，改完即跑，无需构建步骤
dart run examples/02_hello.dart

# 发布：AOT，编译成单文件原生可执行文件
dart compile exe examples/02_hello.dart -o build/02_hello          # macOS/Linux
dart compile exe examples/02_hello.dart -o build/02_hello.exe      # Windows
```

| | `dart run` | `dart compile exe` |
|---|---|---|
| 启动 | 略慢（JIT 预热） | 毫秒级 |
| 产物 | 无 | 单文件原生可执行文件（macOS: Mach-O / Linux: ELF / Windows: .exe），可拷给没装 Dart 的同平台机器 |
| 迭代 | 秒级 | 每次改动都要重新编译 |

开发期全用前者；本教程的构建脚本（`build.sh` / `build.ps1`）在验证时额外把本示例 AOT 编译一次，证明发布链路可用。

## 2.5 工具三件套

写完第一个程序，把日常工具带上：

```bash
dart analyze     # 静态检查：错误、警告、风格建议（IDE 底层就是它）
dart format .    # 按官方风格格式化整个目录
dart create -t console my_tool   # 脚手架：新建一个 console 工程
```

`analyze` 与 `format` 的关系是"检查"与"修理"：前者告诉你哪里不对，后者直接改。团队协作时先 `format` 再 `analyze`，剩下的就是真正的逻辑问题。

## 2.6 单文件 vs pub 工程

什么时候一个 `.dart` 文件就够，什么时候要 `dart create`？

- **单文件**：只用标准库（`dart:io`、`dart:convert`……）的脚本与学习示例——本教程 02–18 章全部如此，`dart run` 即跑。
- **pub 工程**：需要第三方包（`package:test`、`package:http`……）或要拆分 lib/bin/test 目录——本教程 19/20 章的两个完整工程是范例。

判断标准就一条：**要不要 import `package:` 开头的依赖**。要，就是工程；不要，单文件最轻。

## 坑位清单

- **`print` 走 stdout**：错误信息应该用 `stderr.writeln`（第 20 章实战会用到），两者在管道重定向时是分开的流。
- **插值花括号忘了写**：`'$user.name'` 解析成 `$user` + 文本 `.name`，要 `'${user.name}'`；凡是取成员/调用方法，一律 `${}`。
- **退出码不是 `return` 出来的**：`main` 返回 `void`；要设置进程退出码用 `exit(64)`（dart:io），第 20 章 有完整示范。
- **Windows 控制台中文乱码（仅 Windows）**：那是终端编码问题（`chcp 65001` 可解），不是 Dart 把字打错了。macOS/Linux 终端默认 UTF-8，无此问题。
