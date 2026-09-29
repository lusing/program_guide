import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'guide_battery.dart';
import 'guide_battery_platform_interface.dart';

/// 默认实现：MethodChannel 拿电量 + EventChannel 收状态推送。
///
/// 通道名是 Dart 与原生的"接头暗号"，两边必须一字不差
/// （C++ 侧在 windows/guide_battery_plugin.cpp）。
class MethodChannelGuideBattery extends GuideBatteryPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('guide_battery');

  /// The event channel used to receive status pushes from native.
  @visibleForTesting
  final eventChannel = const EventChannel('guide_battery_status');

  Stream<BatteryStatus>? _onStatus;

  @override
  Future<int> batteryLevel() async {
    // invokeMethod 的泛型参数是"期望的原生返回类型"；
    // 类型对不上会在 await 处炸 TypeError，所以插件侧要自己兜错。
    final level = await methodChannel.invokeMethod<int>('getBatteryLevel');
    return level!;
  }

  @override
  Stream<BatteryStatus> onBatteryStatus() {
    // 缓存广播流：多个订阅者共享同一次原生 onListen，
    // 最后一个退订才触发 onCancel（见 31.4 的生命周期图）。
    return _onStatus ??= eventChannel
        .receiveBroadcastStream()
        .map((dynamic event) => _parseStatus(event as String));
  }
}

/// 原生推来的是字符串标签，映射回强类型枚举。
///
/// 通道只传"朴素值"（数字/字符串/列表/字典——StandardMessageCodec
/// 认识的类型），枚举永远自己映射：两端各自演进也不至于炸。
BatteryStatus _parseStatus(String state) {
  switch (state) {
    case 'full':
      return BatteryStatus.full;
    case 'charging':
      return BatteryStatus.charging;
    case 'discharging':
      return BatteryStatus.discharging;
    default:
      throw ArgumentError('未知电池状态: $state');
  }
}
