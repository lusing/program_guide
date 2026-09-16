// 17 Isolate 并发：消息传递、Isolate.run、spawn、数据拷贝
// 运行：dart run examples/17_isolates.dart

import 'dart:async';
import 'dart:isolate';

// ═══ 17.4 数据是拷贝而非共享：worker 里排序不影响主 isolate ═══
Future<List<int>> heavySort(List<int> data) async {
  return await Isolate.run(() => [...data]..sort()); // 闭包带着数据过去，跑完带回来
}

// ═══ 17.3 手工协议：spawn + SendPort/ReceivePort ═══
Future<int> sumInWorker(List<int> data) async {
  final result = Completer<int>();
  final mainPort = ReceivePort();
  await Isolate.spawn(_workerEntry, (data, mainPort.sendPort));
  mainPort.listen((message) {
    result.complete(message as int);
    mainPort.close(); // 不关掉端口，进程不会退出
  });
  return result.future;
}

void _workerEntry((List<int>, SendPort) args) {
  final (data, replyTo) = args; // record 解构参数（第 13 章）
  final total = data.fold(0, (a, b) => a + b);
  replyTo.send(total);
}

void main() async {
  print('主 isolate 开始');

  // ═══ 17.2 Isolate.run：一行把任务丢到别的 isolate ═══
  final fib = await Isolate.run(() => fibSlow(30));
  print('fib(30) = $fib（在 worker 里算，没卡主 isolate）');

  // ═══ 17.4（续） ═══
  final data = [5, 3, 9, 1, 7];
  print('heavySort = ${await heavySort(data)}，原列表未被改动 $data');

  // ═══ 17.3（续） ═══
  print('sumInWorker = ${await sumInWorker([1, 2, 3, 4])}');

  print('主 isolate 结束');
}

int fibSlow(int n) => n < 2 ? n : fibSlow(n - 1) + fibSlow(n - 2);
