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

builder 拿到 `snapshot`（`AsyncSnapshot<T>`），两条轴判完就是完整的三态：`connectionState`（none/waiting/done）+ done 之后再分 `hasError`/`data`。示例用 Dart 3 的 switch 表达式 + when 卫兵写（[Dart 教程·第 13 章](../dart/docs/13-records-patterns.md)），传统 if/else 同样可以。

### AsyncSnapshot 全字段

`AsyncSnapshot<T>` 是 builder 的唯一输入，字段一览：

| 字段 | 类型 | 语义 |
|---|---|---|
| `connectionState` | `ConnectionState` | 异步任务的连接状态（见下表） |
| `data` | `T?` | 最近一个数据值（等待期为 null） |
| `error` | `Object?` | 错误对象（无错为 null） |
| `stackTrace` | `StackTrace?` | 错误的堆栈（调试用） |
| `hasData` | `bool` | data 非 null |
| `hasError` | `bool` | error 非 null |
| `requireData` | `T` | 直接取 data，无数据时**抛 StateError** |

`ConnectionState` 四值：

| 值 | 语义 | FutureBuilder 何时出现 |
|---|---|---|
| `none` | 未连接 | `future: null` |
| `waiting` | 等待中 | future 非 null 且未完成 |
| `active` | 活跃中 | 仅 StreamBuilder：流已发数据但未关 |
| `done` | 完成 | future 完成（无论成功失败） |

注意 **done ≠ 成功**：done 只表示"异步操作结束了"，成功失败都走 done——所以示例里先判 `done when snap.hasError` 再判 `done`。`requireData` 适合"前面已判 hasData，后面不想再判一次"的链式写法：`snap.hasData ? Text('${snap.requireData}') : 占位`。

三态设计表：

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

### initialData：等待期也有数据

`FutureBuilder` 的第三个参数 `initialData` 在等待期就放进 snapshot.data：

```dart
FutureBuilder<String>(
  future: _future,
  initialData: '（上次缓存的值）',  // waiting 期 snap.data 就是它
  builder: /* ... */,
)
```

用途：**缓存展示**——上次加载的数据先顶着，新数据到了再替换，避免"加载中 → 闪空 → 有数据"的两段闪烁。配合 14.5 的缓存策略。

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

### StreamBuilder 与 ConnectionState.active

Stream 比 Future 多一个 `active` 状态：流已经开始吐数据但还没关闭。示例的 `Stream.periodic` 第一个事件到达前是 waiting，之后到 take(5) 完成前是 active，关闭后是 done。FutureBuilder 永远不会出现 active（Future 只有"未完成 → 完成"两态）。

### 广播流与 StreamBuilder

StreamBuilder 订阅流用的是 `listen`——对单订阅流（默认），**一个流只能被一个 StreamBuilder 订阅**。两个 StreamBuilder 共享同一个单订阅流，第二个 builder 永远收不到事件（流已被第一个 listen 占住）。需要多处监听时用**广播流**：

```dart
final _ticks = Stream<int>.periodic(
  const Duration(milliseconds: 300),
  (i) => i + 1,
).take(5).asBroadcastStream();  // 多处 StreamBuilder 共享
```

广播流的代价：事件**不等人**——没有监听者时事件直接丢弃。`Stream.periodic` 这类定时流无所谓（下一个 tick 马上来）；`StreamController` 的广播流要留意"页面还没 build 完，前几个事件已丢"。

## 14.4 手写 vs Builder：什么时候不用它

FutureBuilder 适合"一次性展示"。要**重试、缓存、并发合并、把数据再交给别的逻辑**时，State 字段 + 自己 await 管理生命周期往往更直白（错误存字段、loading 存字段）——Builder 是模板不是教条。第 20 章实战用"注入选据 + State 管理"的组合，就是这个判断。

### 手写状态机的标准形状

```dart
sealed class AsyncData<T> {}
class Loading<T> extends AsyncData<T> {}
class Error<T> extends AsyncData<T> { Error(this.message); final String message; }
class Ok<T> extends AsyncData<T> { Ok(this.data); final T data; }

// State 里：
AsyncData<List<Note>> _notes = Loading();

Future<void> _load() async {
  setState(() => _notes = Loading());
  try {
    final list = await _api.fetchNotes();
    if (!mounted) return;
    setState(() => _notes = Ok(list));
  } catch (e) {
    if (!mounted) return;
    setState(() => _notes = Error('$e'));
  }
}
```

sealed 类 + 模式匹配（[Dart 教程·第 13 章](../dart/docs/13-records-patterns.md)）让三态在编译期穷尽——比 `bool _loading + String? _error + List? _data` 三个可空字段的组合更安全（三个字段的组合有 2×2×2=8 种状态，其中 7 种是非法的）。FutureBuilder 内部就是这套状态机，只是帮你写好了。

## 14.5 RefreshIndicator：下拉刷新

移动端列表的标配交互——`RefreshIndicator` 包住一个可滚动 Widget，下拉时触发 `onRefresh`：

```dart
RefreshIndicator(
  onRefresh: _load,  // 返回 Future<void>，转圈到 Future 完成
  child: ListView(
    children: /* ... */,
  ),
)
```

`onRefresh` 的类型是 `RefreshCallback = Future<void> Function()`——把 `_load` 的返回类型改成 `Future<void>` 直接传。转圈的时长 = Future 的时长：Future 太快转圈一闪而过（体验上"没刷到"），太慢用户等得烦——常见做法是人为保证最短转 400ms：`Future.wait([_load(), Future.delayed(400ms)])`。

桌面端没有"下拉刷新"的手势文化——Windows/macOS 应用更常见的是工具栏上的刷新按钮（第 18 章）。`RefreshIndicator` 在桌面也能用（鼠标拖滚动条到顶继续拖），但别指望用户发现。

## 14.6 缓存与竞态：两个进阶坑

### 缓存：内存 + 持久化两层

FutureBuilder 本身不缓存——`future` 换成新实例就重新等。要"回到这页不重新加载"，把数据存到 State 外面：

```dart
// 内存缓存：全局单例（第 09 章 ChangeNotifier 的轻量变体）
class NoteCache {
  static List<Note>? _cache;
  static Future<List<Note>> get(Future<List<Note>> Function() fetch) async =>
      _cache ??= await fetch();
}
```

注意缓存的**失效策略**：什么时候重新拉？常见触发点——下拉刷新（RefreshIndicator）、返回页面时（`RouteObserver`）、数据变更后（写入操作成功后清缓存）。没有失效策略的缓存 = 数据越旧越离谱。

### 竞态：慢请求覆盖快请求

两个请求几乎同时发出，**后发的先回来、先发的后回来**——UI 最终显示的是旧数据。FutureBuilder 不解决这个问题（它只认"当前 future"），手写状态机要自己做：

```dart
Future<void> _load() async {
  final request = ++_requestId;  // 每次请求一个序号
  setState(() => _loading = true);
  try {
    final data = await _api.fetch();
    if (!mounted || request != _requestId) return;  // 过期响应丢弃
    setState(() { _data = data; _loading = false; });
  } catch (_) {
    if (!mounted || request != _requestId) return;
    setState(() => _loading = false);
  }
}
```

"最新请求号"模式：每次发起请求时递增计数器，回调里比对"我是否还是最新"——不是就丢弃。搜索框联想（输入一个字发一个请求）必须做这个，否则联想结果乱跳。

## 坑位清单

- **future/stream 每次 build 换新实例**：反复重连/重发（14.2 的坑，命中率第一）。
- **waiting 期取 data**：`snapshot.data!` 在等待期是 null 直接崩——先判 connectionState/hasData，或用 `requireData`（它帮你抛语义正确的错）。
- **失败无重试入口**：error 态放个按钮重新 setState 换新 future——只显示"加载失败"不给重试按钮的页面是死路。
- **测试里的 pumpAndSettle 提前返回**：定时器驱动的流（periodic）在 tick 之间没有帧调度，pumpAndSettle 立即结束——手动 `pump(Duration)` 逐格推进（示例测试即如此）。
- **单订阅流被两个 StreamBuilder 共享**：第二个永远没数据——改广播流（`asBroadcastStream`）或各建各的流。
- **竞态不防**：搜索联想、连续翻页必踩——"最新请求号"模式是标准答案（14.6）。
- **RefreshIndicator 的 onRefresh 太快返回**：转圈一闪而过用户感知不到"刷新了"——人为保证最短时长（`Future.wait` 并一个 delay）。
- **把 FutureBuilder 当缓存层**：它不缓存——缓存是数据层的事（ChangeNotifier/单例），FutureBuilder 只负责"把异步值翻译成 UI"。
---

上一章：[13 · 网络与 JSON：数据从远方来](13-http-json.md) ｜ 下一章：[15 · 动画：隐式、Hero 与显式](15-animation.md) ｜ 返回：[README](../README.md)
