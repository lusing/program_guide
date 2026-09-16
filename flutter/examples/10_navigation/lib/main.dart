import 'package:flutter/material.dart';

// 10 导航与路由：push/pop、传参、返回值、命名路由
void main() => runApp(const NavigationApp());

class NavigationApp extends StatelessWidget {
  const NavigationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
      ),
      // ═══ 10.3 命名路由：字符串寻址，集中登记 ═══
      routes: {
        '/': (context) => const HomePage(),
        '/about': (context) => const AboutPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _result = '（无）';

  // ═══ 10.1 push 一个页面并 await 它的返回值 ═══
  Future<void> _openDetail() async {
    final picked = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const DetailPage(item: 7)),
    );
    if (!mounted) return;
    setState(() => _result = picked ?? '直接返回（无值）');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导航与路由')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('打开详情页（传参 7）'),
            onTap: _openDetail,
          ),
          ListTile(
            title: const Text('关于（命名路由）'),
            // ═══ 10.3（续）pushNamed：按字符串跳转 ═══
            onTap: () => Navigator.pushNamed(context, '/about'),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('详情页返回值：$_result'),
          ),
        ],
      ),
    );
  }
}

// ═══ 10.2 页面参数：构造传参（不可变配置的一部分） ═══
class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.item});

  final int item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('详情 #$item')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('收到参数：$item'),
            const SizedBox(height: 12),
            FilledButton(
              // ═══ 10.1（续）pop 带回返回值 ═══
              onPressed: () => Navigator.pop(context, '选中了 #$item'),
              child: const Text('选定并返回'),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: const Center(child: Text('这是命名路由页面')),
    );
  }
}
