import 'package:flutter/material.dart';

// 16 主题与响应式：ThemeData/深浅模式切换、LayoutBuilder 适配
void main() => runApp(const ThemeApp());

class ThemeApp extends StatefulWidget {
  const ThemeApp({super.key});

  @override
  State<ThemeApp> createState() => _ThemeAppState();
}

class _ThemeAppState extends State<ThemeApp> {
  var _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    // ═══ 16.1 一颗种子色生成整套色板（Material 3） ═══
    return MaterialApp(
      title: 'Theme Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _mode,
      home: ThemePage(
        mode: _mode,
        onModeChanged: (m) => setState(() => _mode = m),
      ),
    );
  }
}

class ThemePage extends StatelessWidget {
  const ThemePage({super.key, required this.mode, required this.onModeChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text('当前：${isDark ? "深色" : "浅色"}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ═══ 16.2 SegmentedButton：M3 的分段选择 ═══
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, label: Text('浅色')),
              ButtonSegment(value: ThemeMode.dark, label: Text('深色')),
            ],
            selected: {mode},
            onSelectionChanged: (s) => onModeChanged(s.first),
          ),
          const SizedBox(height: 16),
          // ═══ 16.3 颜色语义化：不写死颜色，用色板角色 ═══
          Card(
            child: ListTile(
              leading: Icon(Icons.palette,
                  color: Theme.of(context).colorScheme.primary),
              title: const Text('颜色来自 colorScheme.primary'),
            ),
          ),
          const SizedBox(height: 16),
          // ═══ 16.4 LayoutBuilder：按可用宽度换布局 ═══
          Container(
            height: 80,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 500;
                return wide
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [Text('宽屏：双栏'), Text('第二栏')],
                      )
                    : const Center(child: Text('窄屏：单栏'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
