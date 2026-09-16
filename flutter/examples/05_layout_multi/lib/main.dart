import 'package:flutter/material.dart';

// 05 布局 II：Row/Column、主轴与交叉轴、Expanded/Flexible、Stack
void main() => runApp(const LayoutMultiApp());

class LayoutMultiApp extends StatelessWidget {
  const LayoutMultiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('布局 II：线性与层叠')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            // ═══ 5.1 Row 与主轴排布 ═══
            AxisDemo(),
            SizedBox(height: 12),
            // ═══ 5.2 Expanded 与 Flexible：瓜分剩余空间 ═══
            ExpandDemo(),
            SizedBox(height: 12),
            // ═══ 5.3 Stack 与 Positioned：层叠布局 ═══
            StackDemo(),
          ],
        ),
      ),
    );
  }
}

class AxisDemo extends StatelessWidget {
  const AxisDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ═══ 5.1（续）spaceEvenly：均分空隙；交叉轴默认居中拉伸 ═══
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            Chip(label: Text('左')),
            Chip(label: Text('中')),
            Chip(label: Text('右')),
          ],
        ),
        const SizedBox(height: 4),
        const Text('spaceEvenly 均分空隙；交叉轴方向默认居中'),
      ],
    );
  }
}

class ExpandDemo extends StatelessWidget {
  const ExpandDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: const [
          // ═══ 5.2（续）flex 比例瓜分；Flexible 先按需后让步 ═══
          Expanded(flex: 2, child: ColoredBox(color: Colors.green, child: Center(child: Text('2 份')))),
          Expanded(flex: 1, child: ColoredBox(color: Colors.teal, child: Center(child: Text('1 份')))),
          Flexible(child: ColoredBox(color: Colors.lime, child: Center(child: Text('让')))),
        ],
      ),
    );
  }
}

class StackDemo extends StatelessWidget {
  const StackDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Stack(
        children: const [
          // ═══ 5.3（续）alignment 对齐 + Positioned 精确定位 ═══
          ColoredBox(color: Colors.blueGrey, child: Center(child: Text('底层'))),
          Positioned(right: 8, top: 8, child: Icon(Icons.push_pin)),
        ],
      ),
    );
  }
}
