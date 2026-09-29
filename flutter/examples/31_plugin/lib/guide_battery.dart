import 'guide_battery_platform_interface.dart';

/// 电池状态。
enum BatteryStatus { full, charging, discharging }

/// guide_battery 插件对应用暴露的 API。
///
/// 只有这一个类是"公面孔"：调用方永远不直接碰通道，
/// 也不关心底下是 Windows 还是 Android——这正是插件的意义
/// （联邦结构见 31.2 与 docs/31）。
class GuideBattery {
  /// 当前电量百分比（0–100）。
  ///
  /// 拿不到（台式机无电池、系统拒绝报告）时抛 [PlatformException]。
  Future<int> batteryLevel() {
    return GuideBatteryPlatform.instance.batteryLevel();
  }

  /// 电池状态流：原生层在状态变化时推送，无需轮询。
  ///
  /// 底层是 [EventChannel]：第一次订阅时才 onListen，
  /// 最后一个订阅取消时 onCancel——流的生命周期交给框架管。
  Stream<BatteryStatus> onBatteryStatus() {
    return GuideBatteryPlatform.instance.onBatteryStatus();
  }
}
