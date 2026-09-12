import 'package:test/test.dart';

void main() {
  test('字符串拼接', () {
    expect('Hello, ' + 'Dart', equals('Hello, Dart'));
  });

  group('数学运算', () {
    test('加法', () => expect(1 + 1, equals(2)));
    test('除法', () => expect(10 / 4, equals(2.5)));
  });
}
