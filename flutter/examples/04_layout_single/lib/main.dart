import 'package:flutter/material.dart';

// 04 布局 I：单子容器——Container/Padding/Align/SizedBox 与装饰
void main() => runApp(const LayoutSingleApp());

class LayoutSingleApp extends StatelessWidget {
  const LayoutSingleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('布局 I：容器')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            // ═══ 4.1 Padding 与 SizedBox：留白三件套 ═══
            Padding(
              padding: EdgeInsets.all(12),
              child: Text('Padding 四周留白 12'),
            ),
            SizedBox(height: 8, child: ColoredBox(color: Colors.amber)),
            // ═══ 4.2 Container：盒子模型与装饰 ═══
            BoxDemo(),
            SizedBox(height: 12),
            // ═══ 4.3 Align 与 Center：把唯一的孩子放到指定位置 ═══
            AlignDemo(),
          ],
        ),
      ),
    );
  }
}

class BoxDemo extends StatelessWidget {
  const BoxDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('box-demo'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      // ═══ 4.2（续）BoxDecoration：颜色/圆角/边框/阴影 ═══
      decoration: BoxDecoration(
        color: Colors.deepOrange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange, width: 2),
        boxShadow: const [
          BoxShadow(blurRadius: 8, offset: Offset(2, 4), color: Colors.black26),
        ],
      ),
      child: const Text('圆角 + 边框 + 阴影的 Container'),
    );
  }
}

class AlignDemo extends StatelessWidget {
  const AlignDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('align-demo'),
      height: 80,
      color: Colors.blueGrey.shade100,
      // ═══ 4.3（续）Alignment 九宫格：alignment 0.9 表示右侧 90% ═══
      child: const Align(
        alignment: Alignment(0.9, 0),
        child: Icon(Icons.arrow_circle_right),
      ),
    );
  }
}
