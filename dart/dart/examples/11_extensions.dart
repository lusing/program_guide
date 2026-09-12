// 11 扩展（Extensions）：为已有类型添加方法与静态成员
extension StringX on String {
  bool get isBlank => trim().isEmpty;

  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  String repeatWithSeparator(String separator, int times) {
    return List.filled(times, this).join(separator);
  }
}

extension ListX<T> on List<T> {
  T? get firstOrZero => isEmpty ? null : first;

  List<T> takeFirst(int count) => sublist(0, count.clamp(0, length));
}

extension IntX on int {
  bool get isPrime {
    if (this < 2) return false;
    for (var i = 2; i * i <= this; i++) {
      if (this % i == 0) return false;
    }
    return true;
  }
}

void main() {
  print('"  ".isBlank = ${'  '.isBlank}');
  print('"dart".capitalize() = ${'dart'.capitalize()}');
  print('"ab".repeat = ${'ab'.repeatWithSeparator('-', 3)}');

  var nums = [10, 20, 30];
  print('firstOrZero = ${nums.firstOrZero}');
  print('empty firstOrZero = ${<int>[].firstOrZero}');
  print('takeFirst(2) = ${nums.takeFirst(2)}');

  var primes = <int>[];
  for (var i = 2; i <= 30; i++) {
    if (i.isPrime) primes.add(i);
  }
  print('primes <= 30: $primes');
}
