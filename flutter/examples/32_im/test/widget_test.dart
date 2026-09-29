import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_app/chat_page.dart';
import 'package:im_app/contacts_page.dart';
import 'package:im_app/data.dart';
import 'package:im_app/main.dart';

void main() {
  testWidgets('加载页：2 秒后整体替换为主骨架（返回栈不残留）', (tester) async {
    await tester.pumpWidget(const ImApp());

    expect(find.text('聊天室'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle(); // 过场动画走完
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(SplashPage), findsNothing);
  });

  testWidgets('会话列表：未读徽标与摘要都在，点击进聊天页', (tester) async {
    await tester.pumpWidget(const ImApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('明天见？'), findsOneWidget);
    expect(find.text('2'), findsWidgets); // 张三 2 条未读
    expect(find.text('5'), findsWidgets); // 李白 5 条未读

    await tester.tap(find.text('张三'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatPage), findsOneWidget);
    expect(find.text('你好，我是张三'), findsOneWidget); // 种子消息
  });

  testWidgets('聊天页：气泡左右分家，发送后收到确定性回声', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green)),
      home: ChatPage(peer: kContacts.first), // 阿伟
    ));

    // 种子消息：自己的在右、对方的在左
    final youRow = tester.widget<Row>(find.ancestor(
        of: find.text('你好，我是阿伟'), matching: find.byType(Row)));
    expect(youRow.mainAxisAlignment, MainAxisAlignment.start);
    final meRow = tester.widget<Row>(find.ancestor(
        of: find.text('你好！'), matching: find.byType(Row)));
    expect(meRow.mainAxisAlignment, MainAxisAlignment.end);

    // 发送
    await tester.enterText(find.byType(TextField), '在忙吗');
    await tester.pump(); // 控制器变值 → 发送钮解禁，要过一帧才生效
    await tester.tap(find.byTooltip('发送'));
    await tester.pump(); // 自己的消息上屏
    expect(find.text('在忙吗'), findsOneWidget);

    // 回声机器人 300ms 后回复
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('收到「在忙吗」（第 1 轮）'), findsOneWidget);
  });

  testWidgets('空输入发送钮禁用；连发两轮计数递增', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green)),
      home: ChatPage(peer: kContacts.first),
    ));

    // byTooltip 命中的是 IconButton 内部的 Tooltip，取按钮本体要往上找一层
    final send = find.byTooltip('发送');
    expect(
        tester
            .widget<IconButton>(
                find.ancestor(of: send, matching: find.byType(IconButton)))
            .onPressed,
        isNull);

    await tester.enterText(find.byType(TextField), '一');
    await tester.pump();
    await tester.tap(send);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '二');
    await tester.pump();
    await tester.tap(send);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('收到「一」（第 1 轮）'), findsOneWidget);
    expect(find.text('收到「二」（第 2 轮）'), findsOneWidget);
  });

  testWidgets('通讯录：字母组头就位，索引条拖到 Z 跳到最后一位', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green)),
      home: ContactsPage(contacts: kContacts),
    ));

    // A 组组头可见；Z 组的"张三"在视口外（懒构建）
    expect(find.text('A'), findsWidgets);
    expect(find.text('张三'), findsNothing);

    // 拖索引条：从中部一路拖到底（Z）。
    // 用 Key 定位——find.byType(GestureDetector).last 抓到的是 AppBar 搜索钮！
    final bar = find.byKey(const ValueKey('index_bar'));
    await tester.drag(bar, const Offset(0, 300), touchSlopY: 0);
    await tester.pumpAndSettle();

    expect(find.text('张三'), findsOneWidget); // Z 组进视口
    expect(find.text('周伯通'), findsOneWidget);
  });

  testWidgets('索引条：拖动时中央字母气泡出现，松手消失', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green)),
      home: ContactsPage(contacts: kContacts),
    ));

    final barCenter = tester.getCenter(find.byKey(const ValueKey('index_bar')));
    final gesture = await tester.startGesture(barCenter);
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    // 中央 feedback 气泡：全树唯一的 32 号大字（组头/索引条都是小字，同名也不怕）
    expect(_bubbleFinder, findsOneWidget);

    await gesture.up();
    await tester.pump();
    expect(_bubbleFinder, findsNothing); // 松手收气泡
  });

  testWidgets('搜索页：一进来就有焦点，输入即过滤', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green)),
      home: ContactsPage(contacts: kContacts),
    ));

    await tester.tap(find.byTooltip('搜索'));
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);

    await tester.enterText(field, '李白');
    await tester.pump();
    // 输入框里的"李白"和结果行的"李白"同名——断言收窄到 ListTile
    expect(
        find.descendant(of: find.byType(ListTile), matching: find.text('李白')),
        findsOneWidget);
    expect(
        find.descendant(of: find.byType(ListTile), matching: find.text('张三')),
        findsNothing);

    await tester.enterText(field, '不存在的人');
    await tester.pump();
    expect(find.text('没有匹配的联系人'), findsOneWidget);
  });

  testWidgets('我的页：logo asset（含 2.0x 变体声明）可渲染', (tester) async {
    await tester.pumpWidget(const ImApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('清理缓存'), findsOneWidget);
  });
}

/// 中央 feedback 气泡的定位器：字号 32 的大字母。
final _bubbleFinder = find.byWidgetPredicate(
    (w) => w is Text && w.style?.fontSize == 32);
