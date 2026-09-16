// 15 Future 与 async/await：事件循环、错误处理、并行
// 运行：dart run examples/15_async.dart

import 'dart:async';

// ═══ 15.2 async 函数：返回 Future，内部用 await ═══
Future<String> fetchUserName(int id) async {
  await Future<void>.delayed(const Duration(milliseconds: 50)); // 模拟网络
  if (id <= 0) {
    throw StateError('无效用户 id: $id');
  }
  return '用户$id';
}

Future<String> greet(int id) async {
  final name = await fetchUserName(id);
  return '你好，$name';
}

// ═══ 15.4 Future.wait：并行等待多个 Future ═══
Future<List<int>> loadAll() async {
  return await Future.wait([
    Future<int>.delayed(const Duration(milliseconds: 30), () => 1),
    Future<int>.delayed(const Duration(milliseconds: 20), () => 2),
    Future<int>.delayed(const Duration(milliseconds: 10), () => 3),
  ]);
}

void main() async {
  // ═══ 15.1 Future：一个"将来才有"的值 ═══
  final pending = Future<int>.value(42);
  print('pending 已创建（回调还没执行）');
  final v = await pending;
  print('await 拿到 $v');

  // ═══ 15.2（续） ═══
  print(await greet(7));

  // ═══ 15.3 await 的错误处理就是 try/catch ═══
  try {
    await fetchUserName(-1);
  } on StateError catch (e) {
    print('捕获：$e');
  }

  // ═══ 15.4（续）并行：总耗时取最长者而非求和 ═══
  final sw = Stopwatch()..start();
  final all = await loadAll();
  print('并行结果 $all，耗时 ${sw.elapsedMilliseconds}ms（串行则约 60ms）');

  // ═══ 15.5 then 链：await 之前的写法（读懂旧代码用） ═══
  Future.value(3).then((n) => n * 2).then((n) => print('then 链结果：$n'));

  // ═══ 15.6 事件循环：microtask 与 event 的顺序 ═══
  print('--- 事件循环演示 ---');
  scheduleMicrotask(() => print('microtask 1（先执行：插队队列）'));
  Future<void>(() => print('event 1（后执行：新事件排到队尾）'));
  await Future<void>.delayed(Duration.zero); // 让队列跑完
  print('--- 演示结束 ---');
}
