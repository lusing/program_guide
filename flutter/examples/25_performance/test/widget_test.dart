// 25 · 重建计数实验室：const 与非常量在父级 setState 下的分岔被锁死。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:performance_app/main.dart';

void main() {
  testWidgets('父级重建：const 卡纹丝不动，非常量卡逐次 +1', (tester) async {
    await tester.pumpWidget(const PerformanceLabApp());

    // 初始：两卡各构建 1 次，父级 1 次
    expect(find.widgetWithText(Card, '已构建 1 次'), findsNWidgets(2));
    expect(find.text('父级已构建 1 次'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('重建父级（setState）'));
      await tester.pump();
    }

    // const 卡被 identical 短路：计数仍是 1；非常量卡 1+3=4
    expect(find.descendant(
      of: find.ancestor(of: find.text('const 构造'), matching: find.byType(Card)),
      matching: find.text('已构建 1 次'),
    ), findsOneWidget);
    expect(find.descendant(
      of: find.ancestor(of: find.text('每次新建'), matching: find.byType(Card)),
      matching: find.text('已构建 4 次'),
    ), findsOneWidget);
    expect(find.text('父级已构建 4 次'), findsOneWidget);
  });

  testWidgets('开关 debugPrintRebuildDirtyWidgets 可切换', (tester) async {
    await tester.pumpWidget(const PerformanceLabApp());

    final sw = find.byType(SwitchListTile);
    expect(tester.widget<SwitchListTile>(sw).value, isFalse);
    await tester.tap(sw);
    await tester.pump();
    expect(tester.widget<SwitchListTile>(sw).value, isTrue);

    // 测试结束前必须拨回：binding 会校验 widget debug 变量保持复位
    await tester.tap(sw);
    await tester.pump();
    expect(tester.widget<SwitchListTile>(sw).value, isFalse);
  });
}
