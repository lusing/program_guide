import 'package:flutter_test/flutter_test.dart';
import 'package:interaction_app/main.dart';

void main() {
  testWidgets('InkWell 点击计数', (tester) async {
    await tester.pumpWidget(const InteractionApp());
    await tester.tap(find.text('点我（InkWell）：0 次'));
    await tester.pump();
    expect(find.text('点我（InkWell）：1 次'), findsOneWidget);
  });

  testWidgets('双击 +10', (tester) async {
    await tester.pumpWidget(const InteractionApp());
    await tester.tap(find.text('双击（GestureDetector）+10'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('双击（GestureDetector）+10'));
    await tester.pump();
    expect(find.text('点我（InkWell）：10 次'), findsOneWidget);
    // 双击识别器有 40ms 收尾定时器：推进假时钟把它冲掉，否则"Timer is still pending"
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('对话框打开与关闭', (tester) async {
    await tester.pumpWidget(const InteractionApp());
    await tester.tap(find.text('对话框'));
    await tester.pumpAndSettle();
    expect(find.text('确认删除？'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('确认删除？'), findsNothing);
  });

  testWidgets('SnackBar 轻提示', (tester) async {
    await tester.pumpWidget(const InteractionApp());
    await tester.tap(find.text('轻提示'));
    await tester.pump(); // SnackBar 动画入场
    expect(find.text('已保存'), findsOneWidget);
  });
}
