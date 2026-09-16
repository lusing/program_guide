import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_app_demo/main.dart';

void main() {
  testWidgets('首页卡片与按钮家族', (tester) async {
    await tester.pumpWidget(const MaterialDemoApp());
    expect(find.text('卡片标题'), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(2));
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('底部导航切换', (tester) async {
    await tester.pumpWidget(const MaterialDemoApp());
    await tester.tap(find.text('发现'));
    await tester.pumpAndSettle();
    expect(find.text('发现页'), findsOneWidget);
    expect(find.text('卡片标题'), findsNothing);
  });

  testWidgets('Drawer 打开', (tester) async {
    await tester.pumpWidget(const MaterialDemoApp());
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('收件箱'), findsOneWidget);
  });
}
