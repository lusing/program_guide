# 16 · Stream：异步的数据序列

> 对应示例：examples/16_streams.dart

## 16.1 解决什么问题

第 15 章的 Future 是"**一个**将来才有的值"；但 WebSocket 消息、文件逐行、传感器读数、按钮点击是"**一串**将来才有的值"。Stream 就是异步版的 Iterable——把"将来陆续到达的数据"抽象成可遍历、可变换的序列。

```dart
  // ═══ 16.1 Stream 是"异步的 Iterable"：await for 消费 ═══
  print('--- countDown ---');
  await for (final n in countDown(3)) {
    print('T-$n');
  }
```

消费端与 for-in 完全对称，只多一个 await——每轮循环"等下一个事件"。这是 Stream 的标准吃法。

## 16.2 async* 生成器：像写循环一样生产事件

```dart
// ═══ 16.2 async* 生成器：像写循环一样产出事件 ═══
Stream<int> countDown(int from) async* {
  while (from > 0) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    yield from--; // 产出一个事件，暂停等消费者处理
  }
}
```

生产端用 `async*` 标记 + `yield` 产出：`yield` 把值推给消费者，然后**暂停生成器**，消费者处理完要下一个才继续——生产节奏被消费端反向控制（背压的雏形）。对照记忆：同步侧是 `Iterable + sync* + yield`，异步侧全加 `a` 前缀。

## 16.3 工厂流与组合子

```dart
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
```

常见工厂：`Stream.fromIterable`（同步数据装进流）、`Stream.periodic`（定时tick，配 `take(n)` 防无限）。而且 Stream 与 Iterable 共享一套组合子——`map/where/take/skip` 全有，`toList()` 同样把流"落袋"成 Future<List>。

## 16.4 单订阅 vs 广播：一个流的两种身份

```dart
  // ═══ 16.4 单订阅 vs 广播 ═══
  final broadcast = countDown(2).asBroadcastStream();
  await Future.wait([
    broadcast.forEach((n) => print('观察者A: $n')),
    broadcast.forEach((n) => print('观察者B: $n')),
  ]);
```

| | 单订阅流（默认） | 广播流 |
|---|---|---|
| 监听者数 | **只能 1 个** | 多个 |
| 第二次 listen | 抛 StateError | 各自收到后续事件 |
| 事件缓冲 | 有（listen 前的事件排队） | 无（没人在听就丢） |
| 典型来源 | 文件读取、HTTP 响应体 | WebSocket、UI 事件总线 |

`asBroadcastStream()` 把单订阅流转成广播；也可以直接用 `StreamController.broadcast`（16.5）。选择看语义："这份完整数据给一个人"用单订阅，"这个频道谁订阅谁听"用广播。

## 16.5 StreamController：手动推送事件

```dart
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
```

生成器适合"拉"（消费者要一个我算一个）；controller 是"推"——任意代码路径 `add` 事件。铁律：**用完必须 `close()`**，否则下游 `await for` 永远悬在"等下一个"上（进程不退出、页面不结束）。这也是把事件源（定时器、原生回调）适配成 Stream 的标准胶水。

## 16.6 错误与 done：流的两种"非常规事件"

```dart
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
```

流里传三种东西：数据、**错误**、**done**（结束信号）。错误处理仍复用 try/catch——包住 await for 即可捕获流中错误（流随之终止）；用 listen 的话则对应 `onError`/`onDone` 回调。close() 触发 done；出错也会终止流（没有"跳过错误继续"的默认语义，要重试得在流生产端做）。

## 16.7 Stream vs Future API 对照

| | Future | Stream |
|---|---|---|
| 值的个数 | 1 | 0..n（含错误与 done） |
| 消费 | `await f` | `await for (… in s)` / `s.listen` |
| 收集 | 直接是值 | `s.toList()` → Future<List> |
| 组合 | `Future.wait([...])` | `StreamGroup.merge` 等社区工具 |

## 坑位清单

- **单订阅流二次监听抛 StateError**：文件流、HTTP body 只能读一次；要多次消费转广播或 `toList` 落袋。
- **忘 close controller**：await for 永挂（本教程 build 脚本的运行验证会当场暴露）；广播 controller 同理要 close。
- **广播流不回放**：订阅前已发出的事件拿不到——"先 connect 后 subscribe"要自己缓存。
- **listen 与 await for 别混用同一流**：单订阅流一个监听者，混用直接炸；同一份数据两个消费者请转广播。
