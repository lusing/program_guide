// 21 · 调试演练场的测试：三类错误的"修好前行为"被锁在这里。
import 'package:debug_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('对照计数器：有 setState 的刷新，忘 setState 的纹丝不动', (tester) async {
    await tester.pumpWidget(const DebugPlaygroundApp());

    await tester.tap(find.text('+1（有 setState）'));
    await tester.pump();
    await tester.tap(find.text('+1（有 setState）'));
    await tester.pump();
    await tester.tap(find.text('+1（有 setState）'));
    await tester.pump();
    expect(find.text('计数：3'), findsOneWidget);

    // ═══ 21.4 逻辑错误的可测特征：点了三次，界面仍是旧值 ═══
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('+1（忘 setState）'));
      await tester.pump();
    }
    expect(find.text('计数：0'), findsOneWidget);
  });

  testWidgets('溢出触发器：渲染错误能被测试捕获并断言', (tester) async {
    await tester.pumpWidget(const DebugPlaygroundApp());

    await tester.tap(find.text('触发溢出'));
    await tester.pump();

    // ═══ 21.3 overflow 是 FlutterError：takeException 拿到它，断言错误文本 ═══
    final exception = tester.takeException();
    expect(exception, isNotNull);
    expect(exception.toString(), contains('overflow'));
  });

  testWidgets('不可变列表：异常文本进错误面板', (tester) async {
    await tester.pumpWidget(const DebugPlaygroundApp());

    await tester.tap(find.text('触发不可变列表'));
    await tester.pump();

    expect(
      find.textContaining('Cannot add to an unmodifiable list'),
      findsOneWidget,
    );
  });

  testWidgets('视觉开关：栅格开关即时生效（重建而非热重启）', (tester) async {
    await tester.pumpWidget(const DebugPlaygroundApp());

    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(4));
    expect(tester.widget<Switch>(switches.last).value, isFalse);

    await tester.tap(find.text('Material 栅格 debugShowMaterialGrid'));
    await tester.pump();

    expect(tester.widget<Switch>(switches.last).value, isTrue);
  });
}
