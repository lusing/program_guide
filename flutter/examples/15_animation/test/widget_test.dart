import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:animation_app/main.dart';

void main() {
  testWidgets('AnimatedContainer 尺寸动画到位', (tester) async {
    await tester.pumpWidget(const AnimationApp());
    var size = tester.getSize(find.byKey(const Key('animated-box')));
    expect(size.width, 80.0);
    await tester.tap(find.byKey(const Key('animated-box')));
    await tester.pumpAndSettle();
    size = tester.getSize(find.byKey(const Key('animated-box')));
    expect(size.width, 160.0);
  });

  testWidgets('Hero 转场到目标页', (tester) async {
    await tester.pumpWidget(const AnimationApp());
    await tester.tap(find.text('Hero 转场到下一页'));
    await tester.pumpAndSettle();
    expect(find.text('Hero 目的地'), findsOneWidget);
  });

  testWidgets('显式动画跑完停在终点', (tester) async {
    await tester.pumpWidget(const AnimationApp());
    await tester.tap(find.text('跑一格'));
    await tester.pumpAndSettle();
    final position = tester.getTopLeft(find.byIcon(Icons.directions_run));
    expect(position.dx, greaterThan(200)); // 0→1 跑完，接近右端
  });
}
