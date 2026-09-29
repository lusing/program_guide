// 25 · 重建计数实验室：把"重建开销"变成肉眼可见、测试可断言的数字。
// 对照文档 docs/25-performance.md 的 25.3 / 25.5 节。
import 'package:flutter/material.dart';

void main() => runApp(const PerformanceLabApp());

class PerformanceLabApp extends StatefulWidget {
  const PerformanceLabApp({super.key});

  @override
  State<PerformanceLabApp> createState() => _PerformanceLabAppState();
}

class _PerformanceLabAppState extends State<PerformanceLabApp> {
  bool _printRebuilds = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '性能实验室',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2E7D32)),
      home: RebuildLabPage(
        printRebuilds: _printRebuilds,
        onPrintRebuilds: (v) => setState(() => _printRebuilds = v),
      ),
    );
  }
}

class RebuildLabPage extends StatefulWidget {
  const RebuildLabPage({
    super.key,
    required this.printRebuilds,
    required this.onPrintRebuilds,
  });

  final bool printRebuilds;
  final ValueChanged<bool> onPrintRebuilds;

  @override
  State<RebuildLabPage> createState() => _RebuildLabPageState();
}

class _RebuildLabPageState extends State<RebuildLabPage> {
  int _parentBuilds = 0;

  @override
  Widget build(BuildContext context) {
    _parentBuilds++;
    if (widget.printRebuilds) {
      debugPrintRebuildDirtyWidgets = true; // 25.5：每帧打印被重建的 widget 名单
    } else {
      debugPrintRebuildDirtyWidgets = false;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('25 · 重建计数实验室')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          FilledButton(
            // ═══ 25.3 重建父级：两张卡的命运立刻分岔 ═══
            onPressed: () => setState(() {}),
            child: const Text('重建父级（setState）'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('父级已构建 $_parentBuilds 次'),
          ),
          // ═══ 25.3 const 卡：编译期规范化，父级重建时 identical → 直接跳过 ═══
          const BuildCounterCard(key: ValueKey('const'), label: 'const 构造'),
          // 非常量卡：每次父级 build 都拿到新实例 → 必然重跑 build
          BuildCounterCard(key: const ValueKey('var'), label: '每次新建'),
          SwitchListTile(
            dense: true,
            title: const Text('debugPrintRebuildDirtyWidgets（看控制台名单）'),
            value: widget.printRebuilds,
            onChanged: widget.onPrintRebuilds,
          ),
          // ═══ 25.2 书 16.2 质量债：长标题软换行 + Flexible 限宽 ═══
          const Card(
            child: ListTile(
              title: Text('质量债示例：长标题'),
              subtitle: Text(
                '关于诺贝尔奖，你知道多少？百年来，围绕提名与获奖，都有哪些不为人知的故事？'
                '新一批"人生赢家"又会是谁呢？',
                softWrap: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 计数自己的 build 被调用几次：const 与否决定它会不会被父级重建波及。
class BuildCounterCard extends StatefulWidget {
  const BuildCounterCard({super.key, required this.label});

  final String label;

  @override
  State<BuildCounterCard> createState() => _BuildCounterCardState();
}

class _BuildCounterCardState extends State<BuildCounterCard> {
  int _builds = 0;

  @override
  Widget build(BuildContext context) {
    _builds++;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.speed),
        title: Text(widget.label),
        subtitle: Text('已构建 $_builds 次'),
      ),
    );
  }
}
