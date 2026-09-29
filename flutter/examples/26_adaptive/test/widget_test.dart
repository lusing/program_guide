// 26 · 自适应控件馆：平台覆写后组件族跟随切换（26.2 的测试化用法）。
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_app/main.dart';

void main() {
  testWidgets('默认 Material 脸：android 分支生效', (tester) async {
    await tester.pumpWidget(const AdaptiveGalleryApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(find.byType(CupertinoSwitch), findsNothing);
  });

  testWidgets('切到 iOS：加载条/开关/对话框按钮全换 Cupertino 脸', (tester) async {
    await tester.pumpWidget(const AdaptiveGalleryApp());

    await tester.tap(find.text('iOS'));
    // 两帧：AnimatedTheme 第 2 帧才把 inherited 数据换成新 platform；
    // 且 CupertinoActivityIndicator 无限动画，settle 永不落定——只能有限 pump
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    expect(find.byType(CupertinoSwitch), findsOneWidget);
    expect(find.byType(CupertinoButton), findsWidgets);

    // 弹的是 Cupertino 对话框（不是 Material 的）
    await tester.tap(find.text('确认'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    await tester.tap(find.text('好'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('切到 Windows：回到 Material 脸', (tester) async {
    await tester.pumpWidget(const AdaptiveGalleryApp());

    await tester.tap(find.text('iOS'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Windows'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CupertinoActivityIndicator), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('开关状态互通：Cupertino 开关也能拨', (tester) async {
    await tester.pumpWidget(const AdaptiveGalleryApp());

    await tester.tap(find.text('iOS'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byType(CupertinoSwitch));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('开关（当前 true）'), findsOneWidget);
  });
}
