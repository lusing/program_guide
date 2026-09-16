import 'package:flutter_test/flutter_test.dart';
import 'package:testing_app/counter.dart';

void main() {
  group('Counter 纯逻辑', () {
    test('递增与复位', () {
      final c = Counter();
      c.increment();
      c.increment();
      expect(c.value, 2);
      c.reset();
      expect(c.value, 0);
    });

    test('0 再减抛 StateError（负例）', () {
      expect(() => Counter().decrement(), throwsStateError);
    });
  });
}
