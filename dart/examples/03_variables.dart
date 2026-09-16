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
  // ignore: unnecessary_type_check
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
