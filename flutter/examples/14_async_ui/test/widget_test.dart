import 'package:flutter_test/flutter_test.dart';
import 'package:async_ui_app/main.dart';

void main() {
  testWidgets('三态：未请求 → 成功', (tester) async {
    await tester.pumpWidget(const AsyncUiApp());
    expect(find.text('还没发起请求'), findsOneWidget);
    await tester.tap(find.text('成功'));
    await tester.pumpAndSettle();
    expect(find.text('拿到：成功的数据'), findsOneWidget);
  });

  testWidgets('错误态', (tester) async {
    await tester.pumpWidget(const AsyncUiApp());
    await tester.tap(find.text('失败'));
    await tester.pumpAndSettle();
    expect(find.textContaining('加载失败'), findsOneWidget);
  });

  testWidgets('StreamBuilder 五个 tick 后停在 5/5', (tester) async {
    await tester.pumpWidget(const AsyncUiApp());
    // tick 之间没有帧调度，pumpAndSettle 会提前返回：手动逐个 300ms 推进假时钟
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.text('tick 5/5'), findsOneWidget);
  });
}
