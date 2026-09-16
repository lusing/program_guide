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
