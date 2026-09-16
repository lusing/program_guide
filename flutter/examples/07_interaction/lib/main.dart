import 'package:flutter/material.dart';

// 07 交互与对话框：GestureDetector/InkWell、AlertDialog、SnackBar、BottomSheet
void main() => runApp(const InteractionApp());

class InteractionApp extends StatelessWidget {
  const InteractionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
      ),
      home: const InteractionPage(),
    );
  }
}

class InteractionPage extends StatefulWidget {
  const InteractionPage({super.key});

  @override
  State<InteractionPage> createState() => _InteractionPageState();
}

class _InteractionPageState extends State<InteractionPage> {
  var _taps = 0;

  void _showDialog() {
    // ═══ 7.3 AlertDialog：确认对话框与返回值 ═══
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('删除')),
        ],
      ),
    );
  }

  void _showSnackBar() {
    // ═══ 7.4 SnackBar：轻提示（挂在 ScaffoldMessenger 上） ═══
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('已保存')));
  }

  void _showSheet() {
    // ═══ 7.5 模态 BottomSheet ═══
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => const ListTile(title: Text('底部面板内容')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('交互与对话框')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ═══ 7.1 InkWell：水波纹点击（Material 风格首选） ═══
          Card(
            child: InkWell(
              onTap: () => setState(() => _taps++),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('点我（InkWell）：$_taps 次'),
              ),
            ),
          ),
          // ═══ 7.2 GestureDetector：更底层的原始手势 ═══
          Card(
            child: GestureDetector(
              onDoubleTap: () => setState(() => _taps += 10),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('双击（GestureDetector）+10'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(onPressed: _showDialog, child: const Text('对话框')),
              OutlinedButton(onPressed: _showSnackBar, child: const Text('轻提示')),
              TextButton(onPressed: _showSheet, child: const Text('底部面板')),
            ],
          ),
        ],
      ),
    );
  }
}
