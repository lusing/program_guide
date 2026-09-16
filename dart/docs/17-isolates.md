# 17 · Isolate：没有共享内存的并发

> 对应示例：examples/17_isolates.dart

## 17.1 解决什么问题

第 15 章说过：事件循环单线程，任何长同步计算都会冻结一切（UI 掉帧、请求超时）。传统解法是多线程——然后锁、竞态、死锁接踵而至。Dart 的答案激进得多：**Isolate，互相不共享内存的轻量执行单元**。没有共享，就没有数据竞争，锁从根上消失。

| | 线程（Java/C++） | Isolate |
|---|---|---|
| 内存 | 共享堆 | **各自独立** |
| 通信 | 共享变量 + 锁 | **消息传递**（值拷贝） |
| 数据竞争 | 常客 | 不可能 |
| 典型开销 | MB 级栈 + 切换 | 轻量，但消息要拷贝 |

## 17.2 Isolate.run：一行搬计算

现代 API 首选，覆盖 90% 场景：

```dart
  // ═══ 17.2 Isolate.run：一行把任务丢到别的 isolate ═══
  final fib = await Isolate.run(() => fibSlow(30));
  print('fib(30) = $fib（在 worker 里算，没卡主 isolate）');
```

把"纯计算"闭包整个丢进新 isolate，跑完把返回值送回来——主 isolate 的 await 期间照常处理事件，界面不卡。命名由来即本质：**一个隔离的执行域**。什么时候需要它？**CPU 密集**（解析大 JSON、图像处理、加密压缩）；IO 密集（网络、文件）用 Future 就够——第 15 章的等待不占线程，开 isolate 无收益。

## 17.3 手工协议：spawn + SendPort/ReceivePort

需要流式交互（worker 多次回报）时，落到底层 API——这是一套**握手协议**：

```dart
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
```

三个角色：主 isolate 开 `ReceivePort` 收信；spawn 启动 worker，把 **`sendPort`（回信地址）** 当消息带过去；worker 算完向回信地址 `send` 结果。这里用 record `(data, sendPort)` 一条消息带两样东西，worker 侧一行解构——第 13 章知识的实战亮相。两条纪律：**mainPort.close()**（不关，进程挂着不退出）；worker 端口用完也应关闭或让 isolate 自然结束。

## 17.4 数据是拷贝，不是共享

```dart
// ═══ 17.4 数据是拷贝而非共享：worker 里排序不影响主 isolate ═══
Future<List<int>> heavySort(List<int> data) async {
  return await Isolate.run(() => [...data]..sort()); // 闭包带着数据过去，跑完带回来
}
```

```dart
  final data = [5, 3, 9, 1, 7];
  print('heavySort = ${await heavySort(data)}，原列表未被改动 $data');
```

输出里"原列表未被改动"就是证据：跨 isolate 传递的数据被**拷贝**（可发送类型：基本值、不可变结构、record、普通集合；Random 这类带内部状态的对象不行）。worker 改的是自己的副本——所谓"通信靠传值"，这也是无锁安全的代价与保证。

## 17.5 何时用哪个：一张决策表

| 场景 | 工具 |
|---|---|
| 等 IO（网络/文件/定时器） | Future + await（第 15 章），**不要** isolate |
| 一段 CPU 密集计算要结果 | `Isolate.run(闭包)` |
| 与 worker 多轮交互 | spawn + SendPort（17.3） |
| Flutter 里偷懒版 | `compute(函数, 参数)`——Isolate.run 的前身封装 |

经验法则：**先把 await 写对，性能实测卡了再上 isolate**。并发不是免费的：消息拷贝与 isolate 创建都有成本，数据来回传得越多，收益越薄。

## 坑位清单

- **忘关 ReceivePort 进程不退出**：示例特意注释了那行——现象是程序"跑完了但不停"，Ctrl+C 才能结束。
- **worker 异常会传回**：Isolate.run 里抛的异常在 await 处正常抛出（好事）；spawn 手工协议里 worker 崩了只体现为"再无消息"，需要自己加错误端口处理。
- **改 worker 数据不影响主 isolate**：想让结果生效，必须把新值**传回来**并赋值，而不是指望"共享"。
- **IO 密集硬上 isolate**：白付拷贝成本零收益——异步 IO 本来就不占线程。
