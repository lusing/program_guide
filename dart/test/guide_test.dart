import 'dart:convert';

import 'package:test/test.dart';

// 测试自包含的最小定义（覆盖扩展/密封/mixin 三个章节主题）
extension WordCountX on String {
  int get wordCount => trim().isEmpty ? 0 : trim().split(' ').length;
}

sealed class Op {
  const Op();
}

class AddOp extends Op {
  final int n;
  const AddOp(this.n);
}

class MulOp extends Op {
  final int n;
  const MulOp(this.n);
}

int apply(List<Op> ops, int seed) =>
    ops.fold(seed, (acc, op) => switch (op) {
          AddOp(n: var n) => acc + n,
          MulOp(n: var n) => acc * n,
        });

mixin WhoA {
  String who() => 'A';
}

mixin WhoB {
  String who() => 'B';
}

class Mixed with WhoA, WhoB {}

String? nullString() => null;

String? nonNullString() => 'x';

void main() {
  test('字符串插值与操作', () {
    final name = 'Dart';
    expect('Hello, $name!', 'Hello, Dart!');
    expect('  x '.trim(), 'x');
    expect('a,b'.split(','), ['a', 'b']);
  });

  test('集合操作', () {
    final nums = [5, 2, 9];
    expect(nums.where((n) => n > 3).toList(), [5, 9]);
    expect({...nums, 5}.length, 3);
    expect({'a': 1}['b'], isNull);
    expect([3, 1, 2]..sort(), [1, 2, 3]);
  });

  test('const 字面量规范化', () {
    const a = [1, 2];
    const b = [1, 2];
    expect(identical(a, b), isTrue);
  });

  test('空安全操作符', () {
    final s = nullString(); // 运行时才知道的可空来源
    expect(s?.length, isNull);
    expect(s ?? '默认', '默认');
    final t = nonNullString(); // 类型可空、运行时非空：! 才有意义
    expect(t!.length, 1);
  });

  test('密封类穷尽 switch', () {
    expect(apply([const AddOp(3), const MulOp(4)], 1), 16);
  });

  test('记录结构相等与解构', () {
    expect((x: 1, y: 2) == (x: 1, y: 2), isTrue);
    final (lo, hi) = (3, 7);
    expect(lo + hi, 10);
  });

  test('扩展方法', () {
    expect('a b c'.wordCount, 3);
  });

  test('泛型协变与运行时类型', () {
    final ints = <int>[9];
    // ignore: unnecessary_type_check
    expect(ints is List<num>, isTrue);
    final nums = <num>[1, 2, 3];
    expect(nums.first, 1);
  });

  test('异常', () {
    expect(() => throw ArgumentError('x'), throwsArgumentError);
    expect(() => int.parse('x'), throwsFormatException);
  });

  test('Future 与 Stream', () async {
    final v = await Future<int>.value(7);
    expect(v, 7);
    final collected = await Stream.fromIterable([1, 2, 3]).toList();
    expect(collected, [1, 2, 3]);
  });

  test('JSON 编解码往返', () {
    final encoded = jsonEncode({'k': [1, 2]});
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    expect(decoded['k'], [1, 2]);
  });

  test('mixin 线性化：后者覆盖前者', () {
    expect(Mixed().who(), 'B');
  });
}
