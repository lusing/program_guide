// 27 · 平台通道：MethodChannel 查电池（Windows 宿主侧在 windows/runner/flutter_window.cpp）。
// 对照文档 docs/27-platform-channel.md 的 27.2 节。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const BatteryApp());

/// 通道名用域名风格保证全局唯一（书 18.1 的纪律）。
const batteryChannel = MethodChannel('guide.flutter/battery');

/// 三分支齐全：Success / PlatformException / MissingPluginException。
Future<String> fetchBatteryLevel() async {
  try {
    final level = await batteryChannel.invokeMethod<int>('getBatteryLevel');
    if (level == null || level < 0) return '电池状态未知';
    return '电池电量：$level%';
  } on PlatformException catch (e) {
    return '获取失败（${e.code}：${e.message}）';
  } on MissingPluginException {
    return '宿主没有实现这个通道';
  }
}

class BatteryApp extends StatelessWidget {
  const BatteryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '平台通道演示',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF827717)),
      home: const BatteryPage(),
    );
  }
}

class BatteryPage extends StatefulWidget {
  const BatteryPage({super.key});

  @override
  State<BatteryPage> createState() => _BatteryPageState();
}

class _BatteryPageState extends State<BatteryPage> {
  late Future<String> _level;

  @override
  void initState() {
    super.initState();
    _level = fetchBatteryLevel(); // 发一次存字段（第 13 章坑）
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('27 · 平台通道：查电池')),
      body: Center(
        child: FutureBuilder<String>(
          future: _level,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const CircularProgressIndicator();
            }
            final Icon icon;
            if (snapshot.data!.startsWith('电池电量')) {
              icon = const Icon(Icons.battery_std, size: 56);
            } else {
              icon = const Icon(Icons.battery_unknown, size: 56);
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(height: 8),
                Text(snapshot.data!, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  // setState 回调写块体：箭头函数返回 Future 会被 debug 断言拒绝
                  onPressed: () {
                    setState(() {
                      _level = fetchBatteryLevel();
                    });
                  },
                  child: const Text('刷新'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
