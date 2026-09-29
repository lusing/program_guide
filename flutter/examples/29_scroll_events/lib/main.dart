// ═══ 29 章主线：频道资讯流 ═══
// CustomScrollView + Sliver 家族（29.2）/ ScrollController 精控（29.3）/
// 滚动通知冒泡（29.4）/ RefreshIndicator + 上拉加载（29.5）/
// PopScope 双击退出（29.6）/ Stream 广播跨页通信（29.7）

import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'channel_drawer.dart';
import 'news_data.dart';

Future<void> main() async {
  runApp(const NewsFeedApp());
}

class NewsFeedApp extends StatelessWidget {
  const NewsFeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '滚动进阶与页面事件',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const NewsFeedPage(),
    );
  }
}

class NewsFeedPage extends StatefulWidget {
  const NewsFeedPage({super.key});

  @override
  State<NewsFeedPage> createState() => _NewsFeedPageState();
}

class _NewsFeedPageState extends State<NewsFeedPage> {
  final _repo = const NewsRepository();
  final _scrollController = ScrollController();

  StreamSubscription<Channel>? _busSub;

  Channel _channel = allChannels.first;
  List<NewsItem> _items = const [];
  int _page = 1;
  int _refreshMark = 0;
  bool _loading = false;
  bool _hasMore = true;

  /// 29.4：滚动感知状态——超过一屏显示"回顶"，粘性头条显示累计像素。
  double _scrolledPixels = 0;
  bool get _showBackToTop => _scrolledPixels > 200;

  @override
  void initState() {
    super.initState();
    _refresh();
    // 29.7：先订阅。Drawer 那头发事件，这里零传参收到新频道。
    _busSub = ChannelBus.instance.stream.listen((channel) {
      setState(() => _channel = channel);
      _refresh();
    });
  }

  @override
  void dispose() {
    _busSub?.cancel(); // 订阅不取消 = 泄漏，setState 会炸在已卸载页面上。
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final mark = _refreshMark + 1;
    final items = await _repo.firstPage(_channel, mark);
    if (!mounted) return;
    setState(() {
      _refreshMark = mark;
      _items = items;
      _page = 1;
      _hasMore = true;
      _loading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    final items = await _repo.loadMore(_channel, _page + 1, _refreshMark);
    if (!mounted) return;
    setState(() {
      _items = [..._items, ...items];
      _page = _page + 1;
      _hasMore = _page < NewsRepository.maxPage;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // ═══ 29.6 PopScope 双击退出 ═══
      // 当年 WillPopScope 的 onWillPop 返回 Future.value(true/false)；
      // 现在 canPop 先表态，onPopInvokedWithResult 收回执。
      canPop: false,
      onPopInvokedWithResult: _onWillPop,
      child: Scaffold(
        drawer: ChannelDrawer(current: _channel),
        body: SafeArea(
            child: NotificationListener<ScrollNotification>(
              // ═══ 29.4 滚动通知冒泡 ═══
              // 不同于 Listener（指针事件），Notification 是 widget 树向上冒泡。
              onNotification: _onScrollNotification,
              child: RefreshIndicator(
                // ═══ 29.5 下拉刷新 ═══
                // 内容不满屏也要能拉：physics 给 AlwaysScrollableScrollPhysics。
                onRefresh: _refresh,
                child: CustomScrollView(
                  // ═══ 29.3 ScrollController ═══
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // ═══ 29.2 Sliver 家族 ═══
                    NewsFeedHeader(channel: _channel),
                    _ChannelBar(
                        channel: _channel, scrolledPixels: _scrolledPixels),
                    SliverPadding(
                      padding: const EdgeInsets.all(12),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 120,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.6,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => ActionChip(
                            label: Text(allChannels[i].name),
                            onPressed: () => ChannelBus.instance
                                .select(allChannels[i]),
                          ),
                          childCount: allChannels.length,
                        ),
                      ),
                    ),
                    // 固定行高：SliverList 没有 itemExtent 参数——
                    // 想让滚动跳过行高测量要用 SliverFixedExtentList。
                    SliverFixedExtentList(
                      itemExtent: 64,
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => ListTile(
                          title: Text(_items[i].title),
                          subtitle: Text('摘要 ${_items[i].index}'),
                        ),
                        childCount: _items.length,
                      ),
                    ),
                    SliverFooter(
                        loading: _loading, hasMore: _hasMore),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: _showBackToTop
              ? FloatingActionButton(
                  onPressed: () => _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                  ),
                  child: const Icon(Icons.arrow_upward),
                )
              : null,
        ),
    );
  }

  /// 29.4：三个通知各有用途——Update 记深度（回顶按钮）、
  /// 深度是 metrics.pixels，与具体列表无关（任何可滚动子树都适用）。
  bool _onScrollNotification(ScrollNotification n) {
    if (n is ScrollUpdateNotification) {
      setState(() => _scrolledPixels = n.metrics.pixels);
    }
    // 29.5：快到底（剩余视口 < 300 逻辑像素）自动加载下一页。
    if (n.metrics.extentAfter < 300 && !_loading && _hasMore && _items.isNotEmpty) {
      _loadMore();
    }
    return false; // 继续冒泡：外层还有别的监听者时不截断。
  }

  /// 29.6：canPop=false 后每次返回意图都到这里。
  void _onWillPop(bool didPop, Object? result) {
    if (didPop) return; // canPop 放行的路径不会进这里，防御而已。
    // clock.now() 而非 DateTime.now()：后者在 widget 测试里是真实墙钟
    // （pump 只推进虚拟帧时钟），时间窗口逻辑会变得不可测。
    final now = clock.now();
    final last = _lastPopAttempt;
    if (last != null && now.difference(last) < const Duration(seconds: 1)) {
      SystemNavigator.pop(); // 二次确认，真正退出。
    } else {
      _lastPopAttempt = now;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('再按一次返回键退出'),
          duration: Duration(seconds: 1),
        ));
    }
  }

  DateTime? _lastPopAttempt;
}

/// 29.2：SliverAppBar——Material 折叠头图（expandedHeight 随滚动收缩）。
class NewsFeedHeader extends StatelessWidget {
  const NewsFeedHeader({super.key, required this.channel});

  final Channel channel;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 160,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('${channel.name}资讯'),
        background: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.indigo.shade300, Colors.indigo.shade700],
            ),
          ),
        ),
      ),
    );
  }
}

/// 29.2：SliverPersistentHeader——钉在视口顶部的粘性条。
/// 必须实现 SliverPersistentHeaderDelegate，且 minExtent <= maxExtent
/// （违反直接断言崩溃）。
class _ChannelBar extends StatelessWidget {
  const _ChannelBar({required this.channel, required this.scrolledPixels});

  final Channel channel;
  final double scrolledPixels;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _ChannelBarDelegate(
        builder: (context, shrinkOffset, overlapsContent) => Container(
          // 实测坑：内容自然高度若小于 delegate 声明的 extent，
          // paintExtent < layoutExtent 直接断言崩溃——显式给足高度。
          height: _ChannelBarDelegate._height,
          color: Theme.of(context).colorScheme.secondaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Icon(Icons.rss_feed,
                size: 18,
                color: Theme.of(context).colorScheme.onSecondaryContainer),
            const SizedBox(width: 8),
            Text('当前频道：${channel.name}'),
            const Spacer(),
            Text('已滚动 ${scrolledPixels.round()}px',
                style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      ),
    );
  }
}

class _ChannelBarDelegate extends SliverPersistentHeaderDelegate {
  _ChannelBarDelegate({required this.builder});

  final Widget Function(BuildContext, double, bool) builder;

  static const _height = 46.0;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      builder(context, shrinkOffset, overlapsContent);

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  bool shouldRebuild(_ChannelBarDelegate oldDelegate) => true;
}

/// 29.2：列表尾部状态（加载中/没有更多）也是 Sliver。
class SliverFooter extends StatelessWidget {
  const SliverFooter({super.key, required this.loading, required this.hasMore});

  final bool loading;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(hasMore ? '上拉加载更多' : '— 没有更多了 —'),
        ),
      ),
    );
  }
}
