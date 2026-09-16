import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_app/main.dart';

void main() {
  testWidgets('组合渲染：卡片 + 技能条目', (tester) async {
    await tester.pumpWidget(const WidgetsDemoApp());
    expect(find.text('阿 Dart'), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
    expect(find.text('Dart 语言'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsNWidgets(3));
  });
}
