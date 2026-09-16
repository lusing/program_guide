# 14 · 异步 UI：把 Future 画出来

> 对应示例：examples/14_async_ui/

## 14.1 解决什么问题

`await` 拿到数据之后呢？**等待的那几百毫秒界面显示什么？失败了呢？**手写这套（状态机 + if/else 渲染）每个页面都要一遍——FutureBuilder/StreamBuilder 把"异步数据的 UI 模板"组件化。底座是 [Dart 教程·第 15 章](../dart/docs/15-async.md)（Future/Stream）与第 16 章（流的消费）。

```dart
          // ═══ 14.1 FutureBuilder：一次异步值的三态渲染 ═══
          FutureBuilder<String>(
            future: _future,
            builder: (context, snap) => switch (snap.connectionState) {
                  ConnectionState.none => const Text('还没发起请求'),
                  ConnectionState.done when snap.hasError => Text(
                      '加载失败：${snap.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ConnectionState.done => Text('拿到：${snap.data}'),
                  _ => const CircularProgressIndicator(),
                },
          ),
```

builder 拿到 `snapshot`，两条轴判完就是完整的三态：`connectionState`（none/waiting/done）+ done 之后再分 `hasError`/`data`。示例用 Dart 3 的 switch 表达式 + when 卫兵写（[Dart 教程·第 13 章](../dart/docs/13-records-patterns.md)），传统 if/else 同样可以。三态设计表：

| 状态 | 常用呈现 |
|---|---|
| 等待 | CircularProgressIndicator / 骨架屏 |
| 失败 | 错误文案 + **重试按钮** |
| 空/成功 | 空态提示 / 数据 |

## 14.2 第一大坑：future 存 State，别在 build 里现造

```dart
  // ═══ 14.2 状态里存 Future，而不是在 build 里现造 ═══
  Future<String>? _future;
  // …
  FilledButton(
    onPressed: () => setState(() {
      _future = Future.value('成功的数据');
    }),
    child: const Text('成功'),
  ),
```

`FutureBuilder(future: fetch())` 写在 build 里 = **每次重建都新建 Future** = 请求重发、加载态闪烁——FutureBuilder 见到"新的 future 实例"会立即回到 waiting。正确姿势：future 是 State 字段，只在需要时（initState/按钮回调）换新。同理 StreamBuilder 的 stream。

顺带一个 Dart 细节（示例里踩过）：`setState(() => _future = Future.error(...))` 的箭头函数**返回了赋的值**（一个 Future）——setState 拒绝返回 Future 的回调，要写块体 `{ _future = ...; }`。而 `Future.error` 若在 FutureBuilder 订阅前就完成，还会被判"未处理异步错误"——`..ignore()` 压掉（错误本身照样由 builder 呈现）。

## 14.3 StreamBuilder：画一条数据流

```dart
          // ═══ 14.3 StreamBuilder：序列数据逐个到达 ═══
          StreamBuilder<int>(
            stream: _ticks,
            builder: (context, snap) => Text(
              snap.hasData ? 'tick ${snap.data}/5' : '等待第一个事件…',
            ),
          ),
```

接口同构：future 换 stream，snapshot 换成"最近一个事件"（data 会随流更新）。示例用 `Stream.periodic + take(5)` 做有限 tick 流（[Dart 教程·第 16 章](../dart/docs/16-streams.md) 的生成器）——进度、心跳、WebSocket 消息都是这个形状。

## 14.4 手写 vs Builder：什么时候不用它

FutureBuilder 适合"一次性展示"。要**重试、缓存、并发合并、把数据再交给别的逻辑**时，State 字段 + 自己 await 管理生命周期往往更直白（错误存字段、loading 存字段）——Builder 是模板不是教条。第 20 章实战用"注入选据 + State 管理"的组合，就是这个判断。

## 坑位清单

- **future/stream 每次 build 换新实例**：反复重连/重发（14.2 的坑，命中率第一）。
- **waiting 期取 data**：`snapshot.data!` 在等待期是 null 直接崩——先判 connectionState/hasData。
- **失败无重试入口**：error 态放个按钮重新 setState 换新 future。
- **测试里的 pumpAndSettle 提前返回**：定时器驱动的流（periodic）在 tick 之间没有帧调度，pumpAndSettle 立即结束——手动 `pump(Duration)` 逐格推进（示例测试即如此）。
