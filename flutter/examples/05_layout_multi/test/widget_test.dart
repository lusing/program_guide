import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_multi_app/main.dart';

void main() {
  testWidgets('线性与层叠渲染', (tester) async {
    await tester.pumpWidget(const LayoutMultiApp());
    expect(find.text('2 份'), findsOneWidget);
    expect(find.text('1 份'), findsOneWidget);
    expect(find.byIcon(Icons.push_pin), findsOneWidget); // Stack 内 Positioned
  });
}
