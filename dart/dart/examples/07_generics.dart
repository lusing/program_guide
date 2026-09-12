// 07 泛型：泛型类、泛型方法、类型约束
class Stack<T> {
  final List<T> _items = [];

  void push(T item) => _items.add(item);

  T pop() {
    if (_items.isEmpty) {
      throw StateError('Stack is empty');
    }
    return _items.removeLast();
  }

  T? get peek => _items.isEmpty ? null : _items.last;
  int get length => _items.length;
  bool get isEmpty => _items.isEmpty;
}

// 泛型方法
T firstOrDefault<T>(List<T> items, T fallback) {
  return items.isEmpty ? fallback : items.first;
}

// 类型约束：T 必须实现 Comparable
T maxOf<T extends Comparable<T>>(List<T> items) {
  if (items.isEmpty) {
    throw ArgumentError('items must not be empty');
  }
  var result = items.first;
  for (var item in items.skip(1)) {
    if (item.compareTo(result) > 0) {
      result = item;
    }
  }
  return result;
}

// 泛型接口与实现
abstract class Repository<T> {
  void save(T entity);
  List<T> findAll();
}

class InMemoryUserRepo implements Repository<String> {
  final List<String> _users = [];

  @override
  void save(String entity) => _users.add(entity);

  @override
  List<String> findAll() => List.unmodifiable(_users);
}

void main() {
  var stack = Stack<int>();
  stack.push(1);
  stack.push(2);
  stack.push(3);
  print('peek = ${stack.peek}');
  print('pop = ${stack.pop()}');
  print('length = ${stack.length}');

  print('firstOrDefault(empty) = ${firstOrDefault(<int>[], -1)}');
  print('firstOrDefault(nums) = ${firstOrDefault([7, 8], -1)}');

  print('maxOf ints = ${maxOf([3, 9, 2])}');
  print('maxOf strings = ${maxOf(['apple', 'zebra', 'mango'])}');

  var repo = InMemoryUserRepo();
  repo.save('alice');
  repo.save('bob');
  print('users = ${repo.findAll()}');

  // 泛型类型信息在运行时可用
  print('stack is Stack<int>: ${stack is Stack<int>}');
}
