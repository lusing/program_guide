// 06 空安全：可空类型、?.、??、!、late、类型提升
void main() {
  // 默认不可空；加 ? 表示可空
  String? nickname;
  print('nickname = $nickname'); // null
  nickname = 'Ace';
  print('nickname = $nickname');

  // ?. 安全调用：左侧为 null 时整体为 null
  String? city;
  print('city length = ${city?.length}'); // null
  city = 'Shanghai';
  print('city length = ${city?.length}'); // 8

  // ?? 空值合并
  var displayName = nickname ?? 'Anonymous';
  print('displayName = $displayName');

  // ??= 仅在为 null 时赋值
  int? retryCount;
  retryCount ??= 3;
  print('retryCount = $retryCount');

  // 可空集合的级联与链式调用
  var parts = '2026-09-02'.split('-');
  var year = int.tryParse(parts[0]);
  print('year = $year');

  // late：延迟初始化，使用前必须赋值
  late String config;
  config = loadConfig();
  print('config = $config');

  // 类型提升：is 判断后可直接当作非空/子类型使用
  Object data = 'hello null safety';
  if (data is String) {
    print('length = ${data.length}');
  }

  // 空安全下的集合
  List<int?> sparse = [1, null, 3];
  var nonNull = sparse.whereType<int>().toList();
  print('nonNull = $nonNull');
}

String loadConfig() => 'mode=production';
