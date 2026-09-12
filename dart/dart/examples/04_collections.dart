// 04 集合：List、Map、Set 与集合操作符
void main() {
  // List
  var scores = [90, 85, 77];
  scores.add(95);
  print('scores: $scores, length=${scores.length}');
  print('first=${scores.first}, last=${scores.last}');
  scores.sort((a, b) => b.compareTo(a));
  print('sorted desc: $scores');

  // 集合操作符：展开、if、for
  var base = [1, 2];
  var flag = true;
  var extended = [...base, if (flag) 3, for (var i = 4; i <= 5; i++) i];
  print('extended: $extended');

  // Map
  var capitals = {
    'China': 'Beijing',
    'Japan': 'Tokyo',
    'France': 'Paris',
  };
  capitals['Germany'] = 'Berlin';
  print('China -> ${capitals['China']}');
  print('containsKey(US) = ${capitals.containsKey('US')}');
  print('putIfAbsent: ${capitals.putIfAbsent('US', () => 'Washington')}');
  capitals.forEach((country, capital) => print('  $country: $capital'));

  // Set：自动去重
  var tags = {'dart', 'flutter', 'dart'};
  print('tags: $tags, size=${tags.length}');

  // 函数式操作：where / map / fold / any / every
  var nums = [1, 2, 3, 4, 5, 6];
  var evens = nums.where((n) => n.isEven).toList();
  var squares = nums.map((n) => n * n).toList();
  var total = nums.fold<int>(0, (acc, n) => acc + n);
  print('evens: $evens');
  print('squares: $squares');
  print('total: $total');
  print('any > 5: ${nums.any((n) => n > 5)}');
  print('every > 0: ${nums.every((n) => n > 0)}');

  // 不可变视图
  var fixed = List.unmodifiable([1, 2, 3]);
  print('unmodifiable: $fixed');
}
