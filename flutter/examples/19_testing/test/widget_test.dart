import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testing_app/main.dart';

void main() {
  testWidgets('点击 FAB 界面计数递增', (tester) async {
    await tester.pumpWidget(const TestingApp());
    expect(find.text('value = 0'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('value = 1'), findsOneWidget);
  });
}
