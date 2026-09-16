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
