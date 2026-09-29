import 'package:flutter_test/flutter_test.dart';
import 'package:guide_battery/guide_battery.dart';
import 'package:guide_battery/guide_battery_method_channel.dart';
import 'package:guide_battery/guide_battery_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// 平台接口层的替身：不碰通道，直接发固定值。
/// 这就是联邦结构的好处——接口层测试不需要任何 mock 通道。
class MockGuideBatteryPlatform
    with MockPlatformInterfaceMixin
    implements GuideBatteryPlatform {
  MockGuideBatteryPlatform(this.level, this.statuses);

  final int level;
  final List<BatteryStatus> statuses;

  @override
  Future<int> batteryLevel() => Future.value(level);

  @override
  Stream<BatteryStatus> onBatteryStatus() => Stream.fromIterable(statuses);
}

void main() {
  final GuideBatteryPlatform initialPlatform = GuideBatteryPlatform.instance;

  test('$MethodChannelGuideBattery is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelGuideBattery>());
  });

  test('换掉 instance 后，应用 API 立刻走替身', () async {
    final original = GuideBatteryPlatform.instance;
    addTearDown(() => GuideBatteryPlatform.instance = original);

    GuideBatteryPlatform.instance =
        MockGuideBatteryPlatform(87, [BatteryStatus.charging]);

    final plugin = GuideBattery();
    expect(await plugin.batteryLevel(), 87);
    expect(await plugin.onBatteryStatus().first, BatteryStatus.charging);
  });

  test('instance 换成裸类（不带 token）会被 PlatformInterface 拦下', () {
    expect(
      () => GuideBatteryPlatform.instance = _FakePlatform(),
      throwsA(isA<AssertionError>()),
    );
  });
}

/// 故意不用 MockPlatformInterfaceMixin——没有 token 直通证。
class _FakePlatform implements GuideBatteryPlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
