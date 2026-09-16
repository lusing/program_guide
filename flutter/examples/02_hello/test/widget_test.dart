import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_app/main.dart';

void main() {
  testWidgets('首页渲染标题与提示', (tester) async {
    await tester.pumpWidget(const HelloApp());
    expect(find.text('Hello Flutter'), findsOneWidget); // AppBar 标题
    expect(find.text('你好，Flutter！'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
