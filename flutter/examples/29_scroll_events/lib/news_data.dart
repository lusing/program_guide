// ═══ 29.7 频道模型 + 假数据仓库 + Stream 广播总线 ═══
// 书 6.7.6 用的是三方包 event_bus 1.x（EventBus().on<T>().listen）；
// 现代等价物就是 StreamController<T>.broadcast()——零依赖，语义相同：
// 一处 fire，多处 listen，先订阅后发送才收得到（无缓冲）。

import 'dart:async';

import 'package:flutter/foundation.dart';

@immutable
class Channel {
  const Channel(this.id, this.name);
  final String id;
  final String name;

  @override
  bool operator ==(Object other) => other is Channel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

const allChannels = [
  Channel('tech', '科技'),
  Channel('finance', '财经'),
  Channel('sport', '体育'),
  Channel('edu', '教育'),
];

@immutable
class NewsItem {
  const NewsItem({
    required this.channel,
    required this.page,
    required this.index,
    required this.refreshMark,
  });

  final Channel channel;
  final int page;
  final int index;
  /// 每次下拉刷新 +1，让"新数据"在测试里可区分。
  final int refreshMark;

  // 注意 ${refreshMark} 的花括号必须保留："轮"是合法标识符续字符，
  // 写 $refreshMark轮 会整体解析成一个新变量名——lint 对中文边界
  // 报 unnecessary_brace 时先想清楚再删。这里干脆用空格分界。
  String get title =>
      '[${channel.name}] 第 $refreshMark 轮 · P$page-$index 条资讯标题';
}

/// 假仓库：确定性生成，无网络无随机——widget 测试的确定性前提。
class NewsRepository {
  const NewsRepository();

  /// 每页 8 条；第 3 页之后告知"没有更多"。
  static const pageSize = 8;
  static const maxPage = 3;

  Future<List<NewsItem>> firstPage(Channel channel, int refreshMark) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _page(channel, 1, refreshMark);
  }

  Future<List<NewsItem>> loadMore(
      Channel channel, int page, int refreshMark) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _page(channel, page, refreshMark);
  }

  List<NewsItem> _page(Channel channel, int page, int refreshMark) => [
        for (var i = 1; i <= pageSize; i++)
          NewsItem(
              channel: channel, page: page, index: i, refreshMark: refreshMark),
      ];
}

/// ═══ 全局事件总线（书 6.7.6 EventBus 的现代零依赖版）═══
/// Drawer 换频道 → 主页刷新：跨页通信不靠构造函数层层传参。
class ChannelBus {
  ChannelBus._();
  static final ChannelBus instance = ChannelBus._();

  final _controller = StreamController<Channel>.broadcast();

  /// 订阅端：主页 initState 里 listen，dispose 里 cancel。
  Stream<Channel> get stream => _controller.stream;

  /// 发布端：任意角落调用，无需持有主页引用。
  void select(Channel channel) => _controller.add(channel);
}
