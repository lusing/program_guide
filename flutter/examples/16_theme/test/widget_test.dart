import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theme_app/main.dart';

void main() {
  testWidgets('默认浅色，切换到深色', (tester) async {
    await tester.pumpWidget(const ThemeApp());
    expect(find.text('当前：浅色'), findsOneWidget);
    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();
    expect(find.text('当前：深色'), findsOneWidget);
  });

  testWidgets('LayoutBuilder 按宽度换布局', (tester) async {
    await tester.pumpWidget(const ThemeApp());
    await tester.binding.setSurfaceSize(const Size(900, 700));
    await tester.pump();
    expect(find.text('宽屏：双栏'), findsOneWidget);
    await tester.binding.setSurfaceSize(const Size(360, 700));
    await tester.pump();
    expect(find.text('窄屏：单栏'), findsOneWidget);
    await tester.binding.setSurfaceSize(null); // 恢复默认
  });
}
