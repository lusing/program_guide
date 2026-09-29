import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'guide_battery.dart';
import 'guide_battery_method_channel.dart';

/// 平台接口：插件 API 的抽象契约。
///
/// 联邦插件的三层分工（详见 docs/31 的 31.2）：
/// 应用层只 import [GuideBattery]；本文件定义"必须实现什么"；
/// method_channel 实现文件回答"默认怎么做"——别的平台实现
/// （比如测试替身、一个假电池）只要 extends 本类并替换 instance 即可。
abstract class GuideBatteryPlatform extends PlatformInterface {
  /// Constructs a GuideBatteryPlatform.
  GuideBatteryPlatform() : super(token: _token);

  static final Object _token = Object();

  static GuideBatteryPlatform _instance = MethodChannelGuideBattery();

  /// The default instance of [GuideBatteryPlatform] to use.
  ///
  /// Defaults to [MethodChannelGuideBattery].
  static GuideBatteryPlatform get instance => _instance;

  /// 平台实现注册自己的入口（测试替身也走这里）。
  static set instance(GuideBatteryPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// 电量百分比；不可得时抛 PlatformException。
  Future<int> batteryLevel() {
    throw UnimplementedError('batteryLevel() has not been implemented.');
  }

  /// 状态流；平台实现负责把通道事件映射回 [BatteryStatus]。
  Stream<BatteryStatus> onBatteryStatus() {
    throw UnimplementedError('onBatteryStatus() has not been implemented.');
  }
}
