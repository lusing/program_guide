# 15 · Future 与 async/await：单线程异步

> 对应示例：examples/15_async.dart

## 15.1 解决什么问题

一个线程怎么"同时"等网络、读文件、跑定时器？答案是**事件循环 + 非阻塞 Future**：等待时不占线程，好了再回调。Dart 的整个异步大厦——包括 Flutter 的每一帧——建立在这套模型上。本章第一课先纠正一个最大误解：**await 不是开线程**，它只是"登记个回调然后让出执行权"。并发计算是第 17 章 Isolate 的事。

```dart
  // ═══ 15.1 Future：一个"将来才有"的值 ═══
  final pending = Future<int>.value(42);
  print('pending 已创建（回调还没执行）');
  final v = await pending;
  print('await 拿到 $v');
```

Future 是"将来才有的值"的占位符：创建即进入调度，但回调要等当前同步代码跑完才执行——输出顺序（先打印"已创建"再拿到 42）就是证据。

## 15.2 async/await：读起来同步，跑起来异步

```dart
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
```

规则三条：`async` 标记的函数**自动把返回值包进 Future**（写 `String` 返回类型不行，必须是 `Future<String>`）；`await` 只能在 async 函数里用（main 也可以是 async 的）；await 右边接 Future，左边拿到解包后的值。多个 await 顺序执行——这就是"看起来同步"的异步。

## 15.3 错误处理：try/catch 原样可用

```dart
  // ═══ 15.3 await 的错误处理就是 try/catch ═══
  try {
    await fetchUserName(-1);
  } on StateError catch (e) {
    print('捕获：$e');
  }
```

await 的最大红利：异步错误**与同步异常共用同一套语法**——try/on/catch/finally（第 12 章）原封不动搬过来用。被 await 的 Future 抛出的异常，会在 await 处像本地异常一样被 catch。

## 15.4 并行：Future.wait

```dart
// ═══ 15.4 Future.wait：并行等待多个 Future ═══
Future<List<int>> loadAll() async {
  return await Future.wait([
    Future<int>.delayed(const Duration(milliseconds: 30), () => 1),
    Future<int>.delayed(const Duration(milliseconds: 20), () => 2),
    Future<int>.delayed(const Duration(milliseconds: 10), () => 3),
  ]);
}
```

```dart
  final sw = Stopwatch()..start();
  final all = await loadAll();
  print('并行结果 $all，耗时 ${sw.elapsedMilliseconds}ms（串行则约 60ms）');
```

逐个 await 是**串行**（30+20+10=60ms）；`Future.wait([...])` 同时启动、一起等，耗时≈最长者（约 30ms）。凡是"互相独立的 IO"——批量请求、并行读文件——都该 wait。注意 wait 的策略是"**一个失败即抛**"；要全部跑完再汇总错误，用 `Future.wait(…, eagerError: false)` 配合各 Future 自身的 catchError，或上第 19 章的测试验证边界。

## 15.5 then 链：await 之前的世界

```dart
  // ═══ 15.5 then 链：await 之前的写法（读懂旧代码用） ═══
  Future.value(3).then((n) => n * 2).then((n) => print('then 链结果：$n'));
```

await 语法（ES2017 时代引入 Dart）之前，异步全靠 `then/catchError/whenComplete` 组合子。新代码一律 async/await，但读老库、看 Flutter 框架源码还会遇到——看懂即可：`.then(f)` 就是"完成后把值喂给 f"，链式传递。

## 15.6 事件循环：两队列模型

最后把底层模型讲透——Dart 每个 isolate 有一条执行流 + **两个队列**：

```dart
  // ═══ 15.6 事件循环：microtask 与 event 的顺序 ═══
  print('--- 事件循环演示 ---');
  scheduleMicrotask(() => print('microtask 1（先执行：插队队列）'));
  Future<void>(() => print('event 1（后执行：新事件排到队尾）'));
  await Future<void>.delayed(Duration.zero); // 让队列跑完
  print('--- 演示结束 ---');
```

规则两条：

1. **microtask 队列优先**：当前同步代码跑完后，先把 microtask 清空才碰 event 队列——它是"插队通道"（await 已完成 Future 的续体就走这里，所以 then 链结果先于 microtask 1 出现：它更早入队）。
2. **每个 event 之间清一次 microtask**：IO 完成、定时器到期都是 event，处理完一个 event 就回头清 microtask。

为什么单线程不卡 UI？因为所有等待都不占线程——线程只跑"事件处理"这种微片段。反过来说，**任何一段长同步计算都会冻结整个循环**（UI 掉帧、网络超时），这正是第 17 章 Isolate 存在的理由。

## 坑位清单

- **循环里 await 是串行**：`for (final u in users) { await fetch(u); }` 一个接一个；要并行先 `users.map(fetch).toList()` 再 `Future.wait`。
- **忘 await 的 Future 静默吞错**：`fetch(); // 没接住` 异常无人认领；确定不关心也要 `unawaited(fetch())` 把意图写明。
- **async 函数的 return 类型**：写 `String` 会是编译错（async 必须 Future/Stream/void），初学常在重构时忘改。
- **`Future.value(x)` 不是"立即执行"**：它创建即完成，但回调仍要走一轮 microtask——输出顺序相关的测试别想当然。
