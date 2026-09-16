import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forms_app/main.dart';

void main() {
  testWidgets('空表单提交显示两条校验错误', (tester) async {
    await tester.pumpWidget(const FormsApp());
    await tester.tap(find.text('注册'));
    await tester.pump();
    expect(find.text('至少 3 个字符'), findsOneWidget);
    expect(find.text('至少 6 位'), findsOneWidget);
  });

  testWidgets('合法输入通过校验', (tester) async {
    await tester.pumpWidget(const FormsApp());
    await tester.enterText(find.byType(TextFormField).first, 'dartfan');
    await tester.enterText(find.byType(TextFormField).last, '123456');
    await tester.tap(find.text('注册'));
    await tester.pump();
    expect(find.text('欢迎，dartfan！'), findsOneWidget);
    expect(find.text('至少 3 个字符'), findsNothing);
  });
}
