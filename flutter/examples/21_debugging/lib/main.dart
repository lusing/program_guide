// 21 · 调试演练场：三类错误各有触发按钮，行为被 widget 测试锁住。
// 对照文档 docs/21-debugging.md 的 21.3 / 21.4 / 21.7 节。
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show debugPaintBaselinesEnabled, debugPaintPointersEnabled, debugPaintSizeEnabled;

void main() => runApp(const DebugPlaygroundApp());

/// MaterialApp 自身持状态：debugShowMaterialGrid 是构造参数，重建即生效。
class DebugPlaygroundApp extends StatefulWidget {
  const DebugPlaygroundApp({super.key});

  @override
  State<DebugPlaygroundApp> createState() => _DebugPlaygroundAppState();
}

class _DebugPlaygroundAppState extends State<DebugPlaygroundApp> {
  bool _materialGrid = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '调试演练场',
      debugShowMaterialGrid: _materialGrid,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF3F51B5)),
      home: PlaygroundPage(
        materialGrid: _materialGrid,
        onMaterialGrid: _setMaterialGrid,
      ),
    );
  }

  void _setMaterialGrid(bool value) => setState(() => _materialGrid = value);
}

class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({super.key, required this.materialGrid, required this.onMaterialGrid});

  final bool materialGrid;
  final ValueChanged<bool> onMaterialGrid;

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  bool _showOverflow = false;
  String? _runtimeError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('21 · 调试演练场')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _sectionTitle('① 逻辑错误：忘 setState'),
          const Row(
            children: [
              Expanded(child: FixedCounter()),
              SizedBox(width: 12),
              Expanded(child: BrokenCounter()),
            ],
          ),
          _sectionTitle('② 运行时错误触发器'),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () => setState(() => _showOverflow = true),
                child: const Text('触发溢出'),
              ),
              OutlinedButton(
                onPressed: _triggerUnmodifiable,
                child: const Text('触发不可变列表'),
              ),
            ],
          ),
          if (_showOverflow)
            const SizedBox(
              height: 32,
              // ═══ 21.3 三个文本塞进 32px：RenderFlex overflowed by ... pixels ═══
              child: Column(
                children: [
                  Text('第一行长文本被硬塞进三十二像素高的盒子里'),
                  Text('第二行长文本继续挤进来把溢出量堆大'),
                  Text('第三行长文本确保溢出肉眼可见且报错可复现'),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: SelectableText(
                _runtimeError ?? '（错误面板：触发后，异常文本显示在这里——先读它，再改代码）',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: _runtimeError == null
                      ? Theme.of(context).hintColor
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ),
          _sectionTitle('③ 视觉调试开关（三个全局量须热重启 R；栅格即时）'),
          SwitchListTile(
            dense: true,
            title: const Text('构造线 debugPaintSizeEnabled'),
            value: debugPaintSizeEnabled,
            onChanged: (v) => setState(() => debugPaintSizeEnabled = v),
          ),
          SwitchListTile(
            dense: true,
            title: const Text('文字基线 debugPaintBaselinesEnabled'),
            value: debugPaintBaselinesEnabled,
            onChanged: (v) => setState(() => debugPaintBaselinesEnabled = v),
          ),
          SwitchListTile(
            dense: true,
            title: const Text('点按命中 debugPaintPointersEnabled'),
            value: debugPaintPointersEnabled,
            onChanged: (v) => setState(() => debugPaintPointersEnabled = v),
          ),
          SwitchListTile(
            dense: true,
            title: const Text('Material 栅格 debugShowMaterialGrid'),
            // 真值在 _DebugPlaygroundAppState：构造参数走重建，即时生效（对照上面三个全局量）
            value: widget.materialGrid,
            onChanged: widget.onMaterialGrid,
          ),
          _sectionTitle('④ 日志（print 不上屏，去控制台看——这正是它的用途）'),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.tonal(
                // ignore: avoid_print -- 本章教学点就是 print；生产代码才该被 lint 拦
                onPressed: () => print('print：短日志一行'),
                child: const Text('print 短日志'),
              ),
              OutlinedButton(
                onPressed: () => debugPrint('debugPrint：' * 40),
                child: const Text('debugPrint 长日志（节流分片）'),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _triggerUnmodifiable() {
    try {
      // ═══ 21.3 const 列表 add：编译期无感，运行时立刻炸 ═══
      const unmodifiable = <int>[1, 2];
      unmodifiable.add(3);
    } catch (e) {
      setState(() => _runtimeError = e.toString());
    }
  }

  static Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
}

/// ═══ 21.4 正解：改动包进 setState，界面立刻刷新 ═══
class FixedCounter extends StatefulWidget {
  const FixedCounter({super.key});

  @override
  State<FixedCounter> createState() => _FixedCounterState();
}

class _FixedCounterState extends State<FixedCounter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('计数：$_count'),
            FilledButton(
              onPressed: () => setState(() => _count++),
              child: const Text('+1（有 setState）'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ═══ 21.4 逻辑错误：改了数据没通知，界面纹丝不动、零报错 ═══
/// 注意"幽灵"特征：任何导致本组件 rebuild 的操作（父级 setState、热重载）
/// 都会让积压的值突然冒出来——排查时这正是"忘 setState"的签名。
class BrokenCounter extends StatefulWidget {
  const BrokenCounter({super.key});

  @override
  State<BrokenCounter> createState() => _BrokenCounterState();
}

class _BrokenCounterState extends State<BrokenCounter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('计数：$_count'),
            OutlinedButton(
              // 坏示范：漏掉 setState —— 页面上看着"按钮没反应"
              onPressed: () => _count++,
              child: const Text('+1（忘 setState）'),
            ),
          ],
        ),
      ),
    );
  }
}
