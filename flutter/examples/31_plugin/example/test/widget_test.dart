import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guide_battery_example/main.dart';

/// 应用层测试照样走 mock 通道——插件的使用者不需要真机。
/// （如果连通道都不想 mock，可以直接换 GuideBatteryPlatform.instance，
/// 那是插件作者给联邦结构预留的后门，见 docs/31 的 31.6。）
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('guide_battery');
  const statusChannel = MethodChannel('guide_battery_status');
  final codec = const StandardMethodCodec();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            methodChannel, (call) async => 87);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(statusChannel, (call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(statusChannel, null);
  });

  Future<void> emitStatus(String label) async {
    await TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger.handlePlatformMessage(
      'guide_battery_status',
      codec.encodeSuccessEnvelope(label),
      (_) {},
    );
  }

  testWidgets('方法通道：电量 87 上屏', (tester) async {
    await tester.pumpWidget(const BatteryApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('87%'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('方法通道：无电池时走错误分支并提示', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (call) async {
      throw PlatformException(code: 'UNAVAILABLE', message: '无电池');
    });

    await tester.pumpWidget(const BatteryApp());
    await tester.pumpAndSettle();

    expect(find.text('读不到（本机可能没电池）'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('事件通道：状态推送即时换脸', (tester) async {
    await tester.pumpWidget(const BatteryApp());
    await tester.pumpAndSettle();

    expect(find.text('等待原生推送…'), findsOneWidget);

    await emitStatus('charging');
    await tester.pump();
    expect(find.text('充电中'), findsOneWidget);

    await emitStatus('full');
    await tester.pump();
    expect(find.text('已充满'), findsOneWidget);
  });

  testWidgets('枚举映射：full 与 discharging 都有对应文案', (tester) async {
    await tester.pumpWidget(const BatteryApp());
    await tester.pumpAndSettle();

    await emitStatus('discharging');
    await tester.pump();
    expect(find.text('使用电池'), findsOneWidget);
  });
}
