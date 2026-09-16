import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stateful_app/main.dart';

void main() {
  testWidgets('setState 计数递增', (tester) async {
    await tester.pumpWidget(const StatefulApp());
    expect(find.text('count = 0'), findsOneWidget);
    await tester.tap(find.text('加一'));
    await tester.tap(find.text('加一'));
    await tester.pump();
    expect(find.text('count = 2'), findsOneWidget);
  });

  testWidgets('输入框双向绑定与手动刷新', (tester) async {
    await tester.pumpWidget(const StatefulApp());
    expect(find.text('你好，阿 Dart'), findsOneWidget); // initState 预填
    await tester.enterText(find.byType(TextField), '小李');
    await tester.tap(find.text('刷新问候'));
    await tester.pump();
    expect(find.text('你好，小李'), findsOneWidget);
  });
}
