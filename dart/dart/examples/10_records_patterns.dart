// 10 Dart 3 新特性：记录（Records）与模式匹配（Patterns）
enum HttpStatus { ok, created, notFound, serverError }

// 记录作为轻量返回值
(double, double) divideWithRemainder(int a, int b) {
  return (a / b, (a % b).toDouble());
}

// 带字段名的记录
({String name, int age}) makeUser() => (name: 'Dave', age: 35);

void main() {
  // 记录基础
  var point = (3, 4);
  print('point = $point, x=${point.$1}, y=${point.$2}');

  var (quotient, remainder) = divideWithRemainder(17, 5);
  print('17 / 5 = $quotient 余 $remainder');

  var user = makeUser();
  print('user: ${user.name}, ${user.age}');

  // 记录交换变量
  var left = 1;
  var right = 2;
  (left, right) = (right, left);
  print('swapped: left=$left, right=$right');

  // if-case 模式匹配
  Object data = [1, 'two', 3.0];
  if (data case [int a, String s, double d]) {
    print('matched list: a=$a, s=$s, d=$d');
  }

  // switch 表达式 + 对象模式
  var status = HttpStatus.notFound;
  var message = switch (status) {
    HttpStatus.ok => '成功',
    HttpStatus.created => '已创建',
    HttpStatus.notFound => '未找到',
    HttpStatus.serverError => '服务器错误',
  };
  print('status message: $message');

  // 逻辑或模式与守卫
  int code = 404;
  var category = switch (code) {
    >= 200 && < 300 => '成功',
    404 || 410 => '资源缺失',
    >= 500 => '服务端错误',
    _ => '其他',
  };
  print('code $code -> $category');

  // null 检查模式
  String? maybe = 'value';
  if (maybe case String value?) {
    print('non-null string: $value');
  }
}
