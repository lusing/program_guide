import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_app/main.dart';

void main() {
  testWidgets('菜单打开并选择', (tester) async {
    await tester.pumpWidget(const DesktopApp());
    await tester.tap(find.text('文件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新建').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('菜单选择：新建'), findsOneWidget);
  });

  testWidgets('列表渲染与 SelectionArea', (tester) async {
    await tester.pumpWidget(const DesktopApp());
    expect(find.text('条目 0'), findsOneWidget);
    expect(find.byType(SelectionArea), findsOneWidget);
  });
}
