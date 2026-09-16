import 'package:flutter/material.dart';

// 02 第一个应用：runApp、MaterialApp、Scaffold、热重载工作流
void main() => runApp(const HelloApp());

// ═══ 2.1 runApp：把 widget 树挂到屏幕 ═══
class HelloApp extends StatelessWidget {
  const HelloApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ═══ 2.2 MaterialApp 与 Scaffold：应用外壳与页面骨架 ═══
    return MaterialApp(
      title: 'Hello Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const HelloPage(),
    );
  }
}

class HelloPage extends StatelessWidget {
  const HelloPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ═══ 2.3 页面骨架：AppBar + body + FAB ═══
    return Scaffold(
      appBar: AppBar(title: const Text('Hello Flutter')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('你好，Flutter！', style: TextStyle(fontSize: 24)),
            SizedBox(height: 8),
            Text('改这行代码，保存后热重载即可见效'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.waving_hand),
      ),
    );
  }
}
