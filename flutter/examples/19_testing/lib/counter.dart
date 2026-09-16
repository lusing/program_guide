/// 19 章 fixture：纯逻辑计数器——单元测试的对象。
class Counter {
  int _value = 0;

  int get value => _value;

  void increment() => _value++;

  /// 减到 0 为止：负数是 bug（第 12 章分界），抛 StateError。
  void decrement() {
    if (_value == 0) {
      throw StateError('计数器已经是 0');
    }
    _value--;
  }

  void reset() => _value = 0;
}
