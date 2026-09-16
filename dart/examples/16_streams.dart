// 16 Stream：异步序列、async* 生成器、广播流、StreamController
// 运行：dart run examples/16_streams.dart

import 'dart:async';

// ═══ 16.2 async* 生成器：像写循环一样产出事件 ═══
Stream<int> countDown(int from) async* {
  while (from > 0) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    yield from--; // 产出一个事件，暂停等消费者处理
  }
}

// ═══ 16.5 StreamController：手动推送事件 ═══
Stream<double> sensor() {
  final controller = StreamController<double>();
  final values = [36.5, 36.8, 37.2, 36.9];
  var i = 0;
  Timer.periodic(const Duration(milliseconds: 15), (t) {
    if (i < values.length) {
      controller.add(values[i++]);
    } else {
      controller.close(); // 必须关闭，否则 await for 永远等不到 done
      t.cancel();
    }
  });
  return controller.stream;
}

void main() async {
  // ═══ 16.1 Stream 是"异步的 Iterable"：await for 消费 ═══
  print('--- countDown ---');
  await for (final n in countDown(3)) {
    print('T-$n');
  }

  // ═══ 16.3 工厂流：fromIterable / periodic + take ═══
  print('--- fromIterable ---');
  await for (final w in Stream.fromIterable(['a', 'b'])) {
    print(w);
  }
  final ticks = await Stream<int>.periodic(
    const Duration(milliseconds: 5),
    (i) => i,
  ).take(3).toList(); // take(n) 限定数量，toList 收集
  print('periodic take(3): $ticks');

  // ═══ 16.4 单订阅 vs 广播 ═══
  final broadcast = countDown(2).asBroadcastStream();
  await Future.wait([
    broadcast.forEach((n) => print('观察者A: $n')),
    broadcast.forEach((n) => print('观察者B: $n')),
  ]);

  // ═══ 16.6 错误也是事件：try/catch 包住 await for ═══
  final broken = () async* {
    yield 1;
    throw StateError('流中途出错');
  }();
  try {
    await for (final n in broken) {
      print('broken 收到 $n');
    }
  } catch (e) {
    print('流错误：$e');
  }

  // ═══ 16.5（续）controller ═══
  print('--- sensor ---');
  await for (final t in sensor()) {
    print('体温 $t');
  }
}
