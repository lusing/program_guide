import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guide_battery/guide_battery.dart';
import 'package:guide_battery/guide_battery_method_channel.dart';

/// EventChannel 测试的关键认知：它底层就是一条 MethodChannel，
/// 用 'listen' / 'cancel' 两个方法名管理生命周期；事件本体则是
/// 平台方向发来的"成功信封"（StandardMethodCodec 编码）。
/// 所以 mock 掉 listen/cancel、再往通道里塞信封，流就活了。
class _StatusChannelHarness {
  final messenger = TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger;
  final codec = const StandardMethodCodec();
  final List<String> listenLog = [];

  Future<void> setUp() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('guide_battery_status'),
            (call) async {
      if (call.method == 'listen') {
        listenLog.add('listen');
      }
      if (call.method == 'cancel') {
        listenLog.add('cancel');
      }
      return null; // EventChannel 协议：listen 的回复体不携带事件
    });
  }

  /// 模拟原生侧 sink.Event(...)：成功信封直接投给 Dart。
  Future<void> emit(String label) async {
    await messenger.handlePlatformMessage(
      'guide_battery_status',
      codec.encodeSuccessEnvelope(label),
      (_) {},
    );
  }

  Future<void> tearDown() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('guide_battery_status'), null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelGuideBattery platform = MethodChannelGuideBattery();
  const MethodChannel channel = MethodChannel('guide_battery');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return 42;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('batteryLevel：方法通道取回原生整数', () async {
    expect(await platform.batteryLevel(), 42);
  });

  test('batteryLevel：原生报错映射为 PlatformException', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      throw PlatformException(code: 'UNAVAILABLE', message: '无电池');
    });
    await expectLater(
      platform.batteryLevel(),
      throwsA(isA<PlatformException>().having(
          (e) => e.code, 'code', 'UNAVAILABLE')),
    );
  });

  test('onBatteryStatus：订阅触发 listen、事件按序到达、退订触发 cancel',
      () async {
    final harness = _StatusChannelHarness();
    await harness.setUp();
    addTearDown(harness.tearDown);

    final events = <BatteryStatus>[];
    final done = Completer<void>();
    final sub = platform.onBatteryStatus().listen((s) {
      events.add(s);
      if (events.length == 2) done.complete();
    });
    await pumpEventQueue();
    expect(harness.listenLog, ['listen']);

    await harness.emit('charging');
    await harness.emit('full');
    await done.future;
    expect(events, [BatteryStatus.charging, BatteryStatus.full]);

    await sub.cancel();
    await pumpEventQueue();
    expect(harness.listenLog, ['listen', 'cancel']);
  });

  test('广播语义：两个订阅者共享一次 listen', () async {
    final harness = _StatusChannelHarness();
    await harness.setUp();
    addTearDown(harness.tearDown);

    final a = <String>[];
    final b = <String>[];
    final gotBoth = Completer<void>();
    final subs = [
      platform.onBatteryStatus().listen((s) => a.add(s.name)),
      platform.onBatteryStatus().listen((s) {
        b.add(s.name);
        if (a.length == 1 && b.length == 1) gotBoth.complete();
      }),
    ];
    await pumpEventQueue();
    expect(harness.listenLog, ['listen']); // 只有一次

    await harness.emit('discharging');
    await gotBoth.future;
    expect(a, ['discharging']);
    expect(b, ['discharging']);

    await subs[0].cancel();
    await pumpEventQueue();
    expect(harness.listenLog, ['listen']); // 还有订阅者：不 cancel

    await subs[1].cancel();
    await pumpEventQueue();
    expect(harness.listenLog, ['listen', 'cancel']); // 最后一个走时才 cancel
  });

  test('未知状态标签在 map 阶段炸 ArgumentError（值域由插件收口）', () async {
    final harness = _StatusChannelHarness();
    await harness.setUp();
    addTearDown(harness.tearDown);

    final errors = <Object>[];
    final done = Completer<void>();
    final sub = platform.onBatteryStatus().listen(
      (_) {},
      onError: (Object e) {
        errors.add(e);
        if (!done.isCompleted) done.complete();
      },
    );
    await pumpEventQueue();

    await harness.emit('mystery');
    await done.future;
    expect(errors.single, isArgumentError);

    await sub.cancel();
  });
}
