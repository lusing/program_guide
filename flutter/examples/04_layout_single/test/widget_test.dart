import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_single_app/main.dart';

void main() {
  testWidgets('容器与装饰渲染', (tester) async {
    await tester.pumpWidget(const LayoutSingleApp());
    expect(find.byKey(const Key('box-demo')), findsOneWidget);
    expect(find.byKey(const Key('align-demo')), findsOneWidget);
    expect(find.text('圆角 + 边框 + 阴影的 Container'), findsOneWidget);
  });
}
