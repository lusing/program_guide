import 'package:flutter/material.dart';

// 08 有状态 Widget：setState、生命周期、TextEditingController
void main() => runApp(const StatefulApp());

class StatefulApp extends StatelessWidget {
  const StatefulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
      ),
      home: const CounterPage(),
    );
  }
}

// ═══ 8.1 StatefulWidget = 配置 + State：状态活在这 ═══
class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _count = 0;
  // ═══ 8.3 TextEditingController：读输入框内容/预填文本 ═══
  final _nameCtrl = TextEditingController();

  // ═══ 8.2 生命周期：initState 做一次性准备 ═══
  @override
  void initState() {
    super.initState();
    _nameCtrl.text = '阿 Dart';
  }

  // ═══ 8.2（续）dispose：离开页面时释放资源 ═══
  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('有状态 Widget')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('count = $_count', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            // ═══ 8.4 setState：告诉框架"状态变了，重新 build" ═══
            FilledButton(
              onPressed: () => setState(() => _count++),
              child: const Text('加一'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '名字'),
            ),
            const SizedBox(height: 8),
            Text('你好，${_nameCtrl.text}'),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => setState(() {}), // 手动触发重建，Text 才会刷新
              child: const Text('刷新问候'),
            ),
          ],
        ),
      ),
    );
  }
}
