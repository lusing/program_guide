# 29 · 滚动进阶与页面事件

> 对应示例：examples/29_scroll_events/（频道资讯流：Sliver 家族 / 滚动通知 / 下拉刷新上拉加载 / PopScope 双击退出 / Stream 广播换频道）

## 29.1 解决什么问题

第 12 章的 `ListView`/`GridView` 覆盖了 90% 的列表需求。剩下 10% 长这样：**头部图随滚动折叠、频道条钉在顶上、列表和网格混排在同一滚动里**——这就得把整个页面交给 `CustomScrollView` + Sliver 家族拼装。本章还一并解决三个"页面级"问题：**怎么感知滚到哪了**（回顶按钮/自动加载）、**怎么拦下返回键**（误触保护），以及**跨页面通信不层层传参**（事件广播）。

素材对应书 6.6.5 自定义滚动组件、6.6.6 滚动的控制及实时状态监听、6.7.1 拦截返回键、6.7.5 通知组件、6.7.6 全局事件广播，以及书 13 章实战的频道切换模式。

## 29.2 CustomScrollView 与 Sliver 家族

Sliver = **可滚动区域的一块**（"薄片"）。`ListView` 本质是"一个 SliverList 装在隐形 CustomScrollView 里"的糖。自己拼 Sliver 时，多块内容共享同一个滚动坐标系：

```dart
// ═══ 29.2 ═══
CustomScrollView(
  slivers: [
    SliverAppBar(                        // 折叠头图：expandedHeight 随滚动收缩
      pinned: true,                      // 收到底后钉住变成普通 AppBar
      expandedHeight: 160,
      flexibleSpace: FlexibleSpaceBar(title: Text('科技资讯'), background: ...),
    ),
    const SliverPersistentHeader(...),   // 粘性频道条（见下）
    SliverPadding(
      sliver: SliverGrid(...),           // 频道快速入口
    ),
    const SliverFixedExtentList(...),    // 资讯条目（固定行高）
    const SliverToBoxAdapter(...),       // 尾部"没有更多"
  ],
)
```

- **SliverAppBar**：`pinned`（钉住）与 `floating`（一松手就浮回）二选一；折叠动画是它自带的，不用写。
- **SliverPersistentHeader**：粘性条的唯一正路，但必须给一个 `SliverPersistentHeaderDelegate`：

```dart
// ═══ 29.2 delegate ═══
class _ChannelBarDelegate extends SliverPersistentHeaderDelegate {
  @override double get minExtent => 46;  // 断言要求 minExtent <= maxExtent
  @override double get maxExtent => 46;
  @override bool shouldRebuild(_) => true;
  @override Widget build(ctx, shrinkOffset, overlapsContent) => ...;
}
```

- **SliverList 与 SliverFixedExtentList**：想给固定行高优化时，`SliverList` **没有** `itemExtent` 参数（那是 ListView 的）——固定行高的 Sliver 是另一个类 `SliverFixedExtentList`，行高跳过 layout 测量。
- **懒构建是 Sliver 的核心收益**：`SliverChildBuilderDelegate` 只构建视口内的条目。示例测试里第 1 条在树上、第 8 条不在——这正是第 12 章 ListView.builder 行为在 Sliver 世界的翻版。

## 29.3 ScrollController：精控滚动位置

```dart
// ═══ 29.3 ═══
final _scrollController = ScrollController();
// CustomScrollView(controller: _scrollController, ...)
_scrollController.animateTo(              // 平滑回顶（回顶按钮）
  0,
  duration: const Duration(milliseconds: 400),
  curve: Curves.easeOutCubic,
);
// 跳变用 jumpTo(0)；读位置用 _scrollController.position.pixels
```

`position` 上还有 `maxScrollExtent`（总可滚距离）、`extentAfter`（距底部还有多远）——29.5 的自动加载就靠它。

## 29.4 滚动通知冒泡：NotificationListener

**`Listener` 监听指针、`NotificationListener` 监听滚动**——后者吃的是 widget 树里向上冒泡的 `ScrollNotification`，任何嵌套深度的可滚动子树都能被外层统一接管：

```dart
// ═══ 29.4 ═══
NotificationListener<ScrollNotification>(
  onNotification: (n) {
    if (n is ScrollUpdateNotification) {          // 滚动中：记深度
      setState(() => _scrolledPixels = n.metrics.pixels);
    }
    if (n.metrics.extentAfter < 300 && ...) {     // 快到底：自动加载
      _loadMore();
    }
    return false;                                 // false=继续冒泡，别截断
  },
  child: const CustomScrollView(...),
)
```

常用通知：`ScrollStartNotification` / `ScrollUpdateNotification`（带 `dragDetails`，可区分手指/惯性）/ `OverscrollNotification`（拉过头，`overscroll` 是超出量）/ `ScrollEndNotification`。**通知的 `depth` 表示离接收者隔了几层滚动视图**——RefreshIndicator 只认 `depth == 0`（自己直接包的那个），嵌套列表时想放行内层要把 predicate 配好。

## 29.5 下拉刷新与上拉加载

- **下拉刷新**：`RefreshIndicator(onRefresh: ...)` 包住滚动视图。它认的是 **drag 位移**（默认超过 100 逻辑像素武装），松手才触发 `onRefresh`；`onRefresh` 返回的 Future 完成时 spinner 收场。内容不满一屏也要能拉——physics 给 `AlwaysScrollableScrollPhysics()`：

```dart
// ═══ 29.5a ═══
RefreshIndicator(
  onRefresh: _refresh,
  child: CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),  // 没这条，短列表拉不动
    slivers: [...],
  ),
)
```

- **上拉加载**：没有官方组件，惯例是 29.4 的通知里看 `extentAfter`（剩余 < 300px 触发）+ 防重入标志位 + 尾部 SliverFooter 显示状态（加载中 spinner / "没有更多了"）。示例工程 `main.dart` 的 `_loadMore` 是完整实现。

## 29.6 PopScope：拦截返回键

误触保护的标准款是"再按一次退出"。**当年如此**：书 6.7.1 用 `WillPopScope`，`onWillPop` 回调返回 `Future.value(false)`（留下）或 `true`（放行）。**现在这样**：`WillPopScope` 已废弃，`PopScope` 把语义拆成两半——`canPop` 先静态表态，`onPopInvokedWithResult` 收异步回执：

```dart
// ═══ 29.6 ═══
PopScope(
  canPop: false,                        // 拦下所有返回意图
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;                 // didPop=true：已放行，无需处理
    final now = clock.now();            // 见下方坑位：为什么不是 DateTime.now()
    if (_lastPopAttempt != null &&
        now.difference(_lastPopAttempt!) < const Duration(seconds: 1)) {
      SystemNavigator.pop();            // 一秒内第二次：真退出
    } else {
      _lastPopAttempt = now;
      // 弹 SnackBar："再按一次返回键退出"
    }
  },
  child: ...,
)
```

API 沿革一句话记牢：`WillPopScope(onWillPop:)` → 3.16 `PopScope(onPopInvoked:)` → 3.22 起 `onPopInvokedWithResult`（多带一个 result 参数，老名已废弃）。

## 29.7 全局事件广播：从 EventBus 到 Stream.broadcast

**当年如此**：书 6.7.6 引三方包 `event_bus`，`EventBus().on<T>().listen(...)` 换全局主题色。**现在这样**：`StreamController<T>.broadcast()` 语义完全相同，还省一个依赖：

```dart
// ═══ 29.7 news_data.dart ═══
class ChannelBus {
  static final ChannelBus instance = ChannelBus._();
  final _controller = StreamController<Channel>.broadcast();
  Stream<Channel> get stream => _controller.stream;   // 订阅端
  void select(Channel channel) => _controller.add(channel); // 发布端
}

// 订阅端（主页 initState）——dispose 必须 cancel，否则泄漏
_busSub = ChannelBus.instance.stream.listen((channel) {
  setState(() => _channel = channel);
  _refresh();
});
```

示例工程用它打通"Drawer 换频道 → 主页零传参刷新"（书 13 章的 ChannelList 频道映射 + 抽屉选择模式）：Drawer 只管 `select(channel)` 然后关抽屉，主页在订阅里自己换数据。与第 22 章的 scoped_model 是两种工具：**状态快照适合"共享的数据"，事件流适合"发生的事"**——频道切换是后者（过去的就让它过去）。

## 29.8 示例工程的结构

```text
29_scroll_events/
├── lib/news_data.dart        # Channel/NewsItem 模型 · 确定性假数据仓库 · ChannelBus
├── lib/channel_drawer.dart   # 频道抽屉（发布事件后 pop）
└── lib/main.dart             # 主页：Sliver 拼装 + 通知监听 + PopScope
```

测试七件套：懒构建只画视口内条目（断言 P1-1 在、P1-8 不在）、上拉两页到"没有更多"、下拉刷新 refreshMark 递增、Drawer 广播换频道、滚动感知（回顶按钮出现/归零）、PopScope 三段时序（首次提示 → 超时重置 → 一秒内退出）、broadcast 无缓冲语义。

## 坑位清单

- **SliverList 没有 itemExtent**：固定行高要换 `SliverFixedExtentList`（写错直接 undefined_named_parameter）。
- **SliverPersistentHeader 的内容比声明的 extent 矮**：断言崩 `layoutExtent (46) exceeds paintExtent (44)`——delegate 的 child 要显式给足高度（`Container(height: 46)`），别指望 padding 自然撑。
- **`DateTime.now()` 在 widget 测试里是真实墙钟**：`pump(1200ms)` 只推进虚拟帧时钟，"一秒内双击退出"这类真实时间窗口在测试里全乱套——应用代码改用 `package:clock` 的 `clock.now()`（dart.dev 第一方），测试里 `withClock(Clock(() => fakeNow), ...)` 手动拨表。
- **animateTo 被 pending timer 饿死**：拖到底自动触发的加载 Timer 还挂着时点回顶按钮，animateTo 推不动——测试里先把 pending 异步 pump 完再触发动画。
- **RefreshIndicator 的测试要喂足帧**：spinner 起场 + onRefresh 延迟 + dismiss 动画是**串联**的，一段大 pump 不够，实测要两段充裕推进（600ms × 2）新数据才上屏。
- **懒构建断言别找视口外条目**：滚到底后新页的"第一条"在视口上方未构建——断言尾部条目（P2-8）而非头部（P2-1）。
- **short content 拉不动 RefreshIndicator**：physics 必须 `AlwaysScrollableScrollPhysics`。
- **`SystemChannels.platform` 上不止 pop**：SystemChrome 样式消息随时插队——mock 断言只盯 `SystemNavigator.pop` 方法名，别断言消息列表为空。
- **Drawer 与页面内组件撞名**：主页频道 Chip 和 Drawer 里的频道同名时，`find.text('财经')` 歧义——用 `find.descendant(of: find.byType(Drawer), matching: ...)` 限定。
- **broadcast 流无缓冲**：先发后订阅收不到（测试单测锁死这条语义）；订阅端 `dispose` 里必须 `cancel`。
---

上一章：[28 · 移动端构建与发布：以 Android 为例](28-android-release.md) ｜ 下一章：[30 · 国际化：一套代码，多副面孔](30-i18n.md) ｜ 返回：[README](../README.md)
