// 23 · 界面层 widget 测试：假网关注入 + prefs mock。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auth_app/main.dart';

import 'fake_gateway.dart';

void main() {
  testWidgets('注册模式：两次密码不一致被 validator 拦下', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AuthApp(gateway: FakeAuthGateway()));
    await tester.pump();

    await tester.tap(find.text('切换到 注册'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(0), 'alice@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.enterText(find.byType(TextFormField).at(2), '654321');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('两次密码输入不一致'), findsOneWidget);
  });

  testWidgets('登录成功：翻页进主页，profile 带 Bearer 拉到，token 落盘', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AuthApp(gateway: FakeAuthGateway()));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'alice@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('欢迎回来'), findsOneWidget);
    expect(find.textContaining('alice@example.com'), findsWidgets);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('token'), 'tok-alice'); // 23.5：token 已落盘
  });

  testWidgets('密码错误：弹窗显示人话消息', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AuthApp(gateway: FakeAuthGateway()));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'alice@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), '000000');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('密码不正确'), findsOneWidget);
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();
  });

  testWidgets('登出：回登录页且 token 清除', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AuthApp(gateway: FakeAuthGateway()));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'alice@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('退出登录'));
    await tester.pumpAndSettle();

    expect(find.text('登录'), findsWidgets); // 回到登录页的按钮/标题
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('token'), isNull);
  });

  testWidgets('自动登录：prefs 里有未过期 token，直接进主页', (tester) async {
    SharedPreferences.setMockInitialValues({
      'token': 'tok-alice',
      'userId': '1',
      'userEmail': 'alice@example.com',
      'expiryTime':
          DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
    });
    await tester.pumpWidget(const AuthApp(gateway: FakeAuthGateway()));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.textContaining('欢迎回来'), findsOneWidget);
    expect(find.textContaining('切换到'), findsNothing); // 没经过登录页
  });

  testWidgets('token 已过期：自动登录失败，留在登录页', (tester) async {
    SharedPreferences.setMockInitialValues({
      'token': 'tok-alice',
      'userId': '1',
      'userEmail': 'alice@example.com',
      'expiryTime':
          DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
    });
    await tester.pumpWidget(const AuthApp(gateway: FakeAuthGateway()));
    await tester.pumpAndSettle();

    expect(find.textContaining('切换到'), findsOneWidget); // 登录页特征
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('token'), isNull); // 过期即清（23.5）
  });
}
