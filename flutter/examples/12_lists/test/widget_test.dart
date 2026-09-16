import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lists_app/main.dart';

void main() {
  testWidgets('列表懒构建：可见项渲染，远处条目未构建', (tester) async {
    await tester.pumpWidget(const ListsApp());
    expect(find.text('条目 1'), findsOneWidget);
    expect(find.text('条目 30'), findsNothing); // 可见区+缓存区之外：还没建
  });

  testWidgets('滚动后可见后续条目', (tester) async {
    await tester.pumpWidget(const ListsApp());
    await tester.dragUntilVisible(
      find.text('条目 30'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('条目 30'), findsOneWidget);
  });

  testWidgets('切到网格页', (tester) async {
    await tester.pumpWidget(const ListsApp());
    await tester.tap(find.text('网格'));
    await tester.pumpAndSettle();
    expect(find.text('条目 5'), findsOneWidget);
  });
}
