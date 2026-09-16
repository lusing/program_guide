import 'package:flutter/material.dart';

// 15 动画：隐式动画（AnimatedXxx）、Hero、显式 AnimationController
void main() => runApp(const AnimationApp());

class AnimationApp extends StatelessWidget {
  const AnimationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AnimationPage(),
    );
  }
}

class AnimationPage extends StatefulWidget {
  const AnimationPage({super.key});

  @override
  State<AnimationPage> createState() => _AnimationPageState();
}

class _AnimationPageState extends State<AnimationPage>
    with SingleTickerProviderStateMixin {
  var _big = false;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..addListener(() => setState(() {}));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('动画')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ═══ 15.1 隐式动画：改属性值，动画自动发生 ═══
          // ListView 给子项的宽度约束是"紧"的，先 Center 放松，width 才生效
          GestureDetector(
            onTap: () => setState(() => _big = !_big),
            child: Center(
              child: AnimatedContainer(
                key: const Key('animated-box'),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                width: _big ? 160.0 : 80.0,
                height: 64,
                color: _big ? Colors.deepPurple : Colors.deepPurple.shade200,
              ),
            ),
          ),
          // ═══ 15.3 显式动画：AnimationController 亲自推进 ═══
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: Align(
              alignment: Alignment(-0.9 + 1.8 * _controller.value, 0),
              child: const Icon(Icons.directions_run),
            ),
          ),
          FilledButton(
            onPressed: () {
              _controller.forward(from: 0); // 从头跑一次 0 → 1
            },
            child: const Text('跑一格'),
          ),
          // ═══ 15.2 Hero：跨页共享元素 ═══
          const SizedBox(height: 16),
          Center(
            child: Hero(
              tag: 'logo',
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.deepPurple.shade100,
                child: const Icon(Icons.flutter_dash),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HeroPage()),
            ),
            child: const Text('Hero 转场到下一页'),
          ),
        ],
      ),
    );
  }
}

class HeroPage extends StatelessWidget {
  const HeroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hero 目的地')),
      body: Center(
        child: Hero(
          tag: 'logo',
          child: CircleAvatar(
            radius: 64,
            backgroundColor: Colors.deepPurple.shade100,
            child: const Icon(Icons.flutter_dash, size: 48),
          ),
        ),
      ),
    );
  }
}
