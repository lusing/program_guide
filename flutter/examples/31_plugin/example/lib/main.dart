import 'package:flutter/material.dart';
import 'package:guide_battery/guide_battery.dart';

/// 插件演示应用：一条方法通道问电量 + 一条事件通道收状态。
///
/// 注意 main() 之外没有任何通道细节——应用只认 GuideBattery 这个
/// API 类。这就是插件和应用侧通道（27 章）的分界线。
void main() {
  runApp(const BatteryApp());
}

class BatteryApp extends StatelessWidget {
  const BatteryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'guide_battery 演示',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const BatteryHomePage(),
    );
  }
}

class BatteryHomePage extends StatefulWidget {
  const BatteryHomePage({super.key});

  @override
  State<BatteryHomePage> createState() => _BatteryHomePageState();
}

class _BatteryHomePageState extends State<BatteryHomePage> {
  final _battery = GuideBattery();

  // late final：Future 存进 State 而不是在 build 里现造（14 章铁律），
  // 这样 FutureBuilder 不会因重建而重新发起调用。
  late final Future<int> _level;

  @override
  void initState() {
    super.initState();
    _level = _battery.batteryLevel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('31 · 插件：guide_battery')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LevelCard(future: _level, onRetry: _reload),
          const SizedBox(height: 12),
          _StatusCard(stream: _battery.onBatteryStatus()),
          const SizedBox(height: 12),
          Text(
            '插一条/拔电源试试：状态变化会在半秒内被原生层推过来（EventChannel）。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _reload() {
    setState(() {
      _level = _battery.batteryLevel();
    });
  }
}

/// 方法通道一问一答：FutureBuilder 三态照常适用。
class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.future, required this.onRetry});

  final Future<int> future;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('电量（MethodChannel）',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FutureBuilder<int>(
              future: future,
              builder: (context, snap) => switch (snap.connectionState) {
                ConnectionState.done when snap.hasError => Row(
                    children: [
                      const Icon(Icons.battery_unknown,
                          color: Colors.red, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('读不到（本机可能没电池）'),
                            TextButton(onPressed: onRetry, child: const Text('重试')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ConnectionState.done => Row(
                    children: [
                      const Icon(Icons.battery_std, size: 40),
                      const SizedBox(width: 12),
                      Text('${snap.data}%',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall!
                              .copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                _ => const CircularProgressIndicator(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 事件通道持续推送：StreamBuilder 每收一个事件就重建。
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.stream});

  final Stream<BatteryStatus> stream;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('充电状态（EventChannel）',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            StreamBuilder<BatteryStatus>(
              stream: stream,
              builder: (context, snap) {
                // 还没来过事件时给个占位（连接中≠错误）
                final status = snap.data;
                final (label, icon, color) = switch (status) {
                  BatteryStatus.full => ('已充满', Icons.battery_full, Colors.green),
                  BatteryStatus.charging =>
                    ('充电中', Icons.battery_charging_full, Colors.teal),
                  BatteryStatus.discharging =>
                    ('使用电池', Icons.battery_alert, Colors.orange),
                  null => ('等待原生推送…', Icons.hourglass_top, Colors.grey),
                };
                return Row(children: [
                  Icon(icon, color: color, size: 40),
                  const SizedBox(width: 12),
                  Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall),
                ]);
              },
            ),
          ],
        ),
      ),
    );
  }
}
