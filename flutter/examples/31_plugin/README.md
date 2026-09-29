# guide_battery

31 章示例插件：`MethodChannel` 问电量 + `EventChannel` 推充电状态。

## 结构

- `lib/guide_battery.dart` — 应用层 API（`GuideBattery` 类，唯一公面孔）
- `lib/guide_battery_platform_interface.dart` — 平台契约（联邦三层的中层）
- `lib/guide_battery_method_channel.dart` — 默认通道实现（两条通道 + 枚举映射）
- `windows/` — C++ 原生实现（`GetSystemPowerStatus` + 轮询线程推状态）
- `example/` — 演示应用（独立工程，`path: ../` 依赖本插件）

## 验证

```bash
flutter test                 # 插件两层测试（接口替身 + 通道 mock）
cd example && flutter test   # 演示应用测试（UI 三态 + 事件换脸）
cd example && flutter run -d windows   # 真机演示（插拔电源看状态推送）
```

教程见 [docs/31-plugin-dev.md](../../docs/31-plugin-dev.md)。
