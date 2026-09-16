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
  subtitle = fetchSubtitle(); // 换成"运行时才知道"的来源，下面几个操作符才有悬念
  print('len=${subtitle?.length}'); // null 时短路，整个表达式为 null
  print('len=${subtitle?.length ?? 0}'); // 给空值兜底
  subtitle ??= '默认副标题'; // 为 null 才赋值
  print('subtitle=$subtitle');

  // ═══ 10.3 ! 断言：我知道它不是 null（错了运行时抛错） ═══
  subtitle = fetchLocal(); // 换个来源：类型上仍可空、运行时非空，! 才有意义
  int len = subtitle!.length; // 若这里拿到 null，! 处当场抛错
  print('len=$len');

  // ═══ 10.4（续）局部变量才会被提升 ═══
  String? local = fetchLocal(); // 运行时非空，但类型系统不知道
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

String? fetchSubtitle() => null; // 模拟外部可空来源

String? fetchLocal() => 'abc';

String greet(String? who) => '你好，${who ?? '游客'}';
