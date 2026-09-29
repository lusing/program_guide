// ═══ 29 章 widget 层：懒构建 / 上拉加载 / 下拉刷新 / 频道广播 / PopScope ═══
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_events/main.dart';
import 'package:scroll_events/news_data.dart';

void main() {
  setUp(() {
    // 每个测试都从"科技"频道第一页起步，互不串台。
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const NewsFeedApp());
    // 首屏数据 300ms 延迟 → FakeAsync 推进后出现。
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('首屏：懒构建只画视口内的条目（Sliver 的核心收益）', (tester) async {
    await pumpApp(tester);
    // 第一页 8 条，首屏只够画前几条：第 1 条在、第 8 条还没构建。
    expect(find.textContaining('P1-1 '), findsOneWidget);
    expect(find.textContaining('P1-8 '), findsNothing);
  });

  testWidgets('上拉加载：快到底部自动拉下一页，直到没有更多', (tester) async {
    await pumpApp(tester);
    await tester.fling(
        find.byType(CustomScrollView), const Offset(0, -2000), 2000);
    await tester.pump(); // ballistic 启动
    await tester.pump(const Duration(milliseconds: 200)); // 惯性滚动到位
    await tester.pump(const Duration(milliseconds: 400)); // 300ms 网络延迟
    await tester.pump(); // 重建帧
    // 视口停在底部，懒构建只画尾部条目——断言最后一条而非第一条。
    expect(find.textContaining('P2-8 '), findsOneWidget);

    // 第二波：到第三页后 hasMore=false。
    await tester.fling(
        find.byType(CustomScrollView), const Offset(0, -3000), 2000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.textContaining('P3-8 '), findsOneWidget);
    expect(find.text('— 没有更多了 —'), findsOneWidget);
  });

  testWidgets('下拉刷新：refreshMark 递增出"新数据"', (tester) async {
    await pumpApp(tester);
    expect(find.textContaining('第 1 轮'), findsWidgets);
    // 慢拖 300px 无速度：RefreshIndicator 认 drag 位移（阈值 100px）。
    await tester.drag(
        find.byType(CustomScrollView), const Offset(0, 300));
    await tester.pump(); // 触发 onRefresh，spinner 起帧
    // spinner 起场 + 300ms 数据延迟 + dismiss 动画是串联的，
    // 实测要两段充裕的推进才轮到新数据上屏。
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('第 2 轮'), findsWidgets);
  });

  testWidgets('频道广播：Drawer 选择 → 主页零传参换频道', (tester) async {
    await pumpApp(tester);
    expect(find.text('当前频道：科技'), findsOneWidget);
    expect(find.textContaining('[财经]'), findsNothing);

    // 打开抽屉（左边缘右滑）选"财经"——注意与主页频道 Chip 撞名，
    // 要限定在 Drawer 里找。
    await tester.dragFrom(
        tester.getTopLeft(find.byType(Scaffold)), const Offset(300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byType(Drawer),
        matching: find.text('财经'),
      ));
    await tester.pump(); // 事件广播
    // drawer 关闭动画 + 300ms 数据延迟串联，两段推进才稳。
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('当前频道：财经'), findsOneWidget);
    // 换频道走的是 _refresh：refreshMark 已从 1 递增到 2。
    expect(find.textContaining('[财经] 第 2 轮 · P1-1'), findsOneWidget);
  });

  testWidgets('滚动感知：粘性头条记录累计像素，回顶按钮按需出现', (tester) async {
    await pumpApp(tester);
    expect(find.textContaining('已滚动 0px'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    // 慢拖不产生动量，位置可控；首屏 maxScrollExtent 有限会被 clamp。
    await tester.drag(
        find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.textContaining('已滚动 0px'), findsNothing);

    // 实测坑：拖到底会顺手触发一次上拉加载（300ms Timer 挂着）——
    // 不先把它 pump 完，紧接着的 animateTo 会被 pending timer 饿死。
    await tester.pump(const Duration(milliseconds: 500));

    // 回顶按钮：animateTo 回 0（有限 pump 推进完动画）。
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('已滚动 0px'), findsOneWidget);
  });

  testWidgets('PopScope：首次返回弹提示，一秒内二次才退出', (tester) async {
    final platformMessages = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformMessages.add(call);
      return null;
    });

    // DateTime.now() 在测试里是真实墙钟——用 withClock 注入可控时钟，
    // 手动"拨表"模拟两次按键的间隔（这正是应用侧改用 clock.now() 的原因）。
    var fakeNow = DateTime(2026, 1, 1, 12);
    await withClock(Clock(() => fakeNow), () async {
      await pumpApp(tester);
      bool popSent() =>
          platformMessages.any((c) => c.method == 'SystemNavigator.pop');

      // 第一次返回：SnackBar 提示，不退出。
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('再按一次返回键退出'), findsOneWidget);
      expect(popSent(), isFalse);

      // 间隔超过 1 秒的第二次：重新计时，仍不退出。
      fakeNow = fakeNow.add(const Duration(milliseconds: 1200));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(popSent(), isFalse);

      // 紧跟着的第三次（间隔远小于 1 秒）：SystemNavigator.pop 出货。
      fakeNow = fakeNow.add(const Duration(milliseconds: 100));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(popSent(), isTrue);
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('ChannelBus：广播无缓冲，先发后订阅收不到', () async {
    var received = 0;
    // 先发：此刻无人订阅。
    ChannelBus.instance.select(const Channel('tech', '科技'));
    final sub = ChannelBus.instance.stream.listen((_) => received++);
    expect(received, 0); // 错过就是错过——broadcast 流不回放历史。

    ChannelBus.instance.select(const Channel('sport', '体育'));
    await pumpEventQueue();
    expect(received, 1);
    await sub.cancel();
  });
}
