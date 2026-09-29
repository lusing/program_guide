// 27 · 平台通道的测试：mock 挂在 messenger 上，三分支各锁一条。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:platform_channel_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void mock(Future<Object?>? Function(MethodCall call)? handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(batteryChannel, handler);
  }

  tearDown(() => mock(null)); // 摘掉 mock，别污染别的测试

  testWidgets('Success 分支：宿主返回 87', (tester) async {
    mock((call) async =>
        call.method == 'getBatteryLevel' ? 87 : null);
    await tester.pumpWidget(const BatteryApp());
    await tester.pumpAndSettle();

    expect(find.text('电池电量：87%'), findsOneWidget);
    expect(find.byIcon(Icons.battery_std), findsOneWidget);
  });

  testWidgets('Error 分支：PlatformException 显示人话', (tester) async {
    mock((call) async => throw PlatformException(
        code: 'UNAVAILABLE', message: '获取不到电池状态'));
    await tester.pumpWidget(const BatteryApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('获取失败（UNAVAILABLE'), findsOneWidget);
    expect(find.byIcon(Icons.battery_unknown), findsOneWidget);
  });

  testWidgets('未知方法：宿主 NotImplemented → null 返回走未知分支', (tester) async {
    mock((call) async => null); // 模拟 result.NotImplemented() 的可空回话
    await tester.pumpWidget(const BatteryApp());
    await tester.pumpAndSettle();

    expect(find.text('电池状态未知'), findsOneWidget);
  });

  testWidgets('刷新按钮重新过桥', (tester) async {
    var n = 42;
    mock((call) async => n++);
    await tester.pumpWidget(const BatteryApp());
    await tester.pumpAndSettle();
    expect(find.text('电池电量：42%'), findsOneWidget);

    await tester.tap(find.text('刷新'));
    await tester.pumpAndSettle();
    expect(find.text('电池电量：43%'), findsOneWidget);
  });
}
