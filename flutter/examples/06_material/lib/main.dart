import 'package:flutter/material.dart';

// 06 Material 组件库：Scaffold 全家（AppBar/Drawer/FAB/BottomNav）与常用组件
void main() => runApp(const MaterialDemoApp());

class MaterialDemoApp extends StatelessWidget {
  const MaterialDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    // ═══ 6.1 Scaffold：页面骨架的六个插槽 ═══
    return Scaffold(
      appBar: AppBar(title: const Text('Material 组件')),
      // ═══ 6.2 Drawer：侧滑抽屉 ═══
      drawer: Drawer(
        child: ListView(
          children: const [
            DrawerHeader(child: Text('菜单')),
            ListTile(leading: Icon(Icons.inbox), title: Text('收件箱')),
            ListTile(leading: Icon(Icons.settings), title: Text('设置')),
          ],
        ),
      ),
      // ═══ 6.3 NavigationBar：M3 底部导航 ═══
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.search), label: '发现'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: _tab == 0 ? const HomeBody() : const Center(child: Text('发现页')),
    );
  }
}

class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    // ═══ 6.4 信息组件：Card + ListTile + Chip ═══
    return ListView(
      padding: const EdgeInsets.all(8),
      children: const [
        Card(
          child: ListTile(
            leading: Icon(Icons.article),
            title: Text('卡片标题'),
            subtitle: Text('ListTile 承载一行信息的标准姿势'),
            trailing: Chip(label: Text('新')),
          ),
        ),
        Card(child: ListTile(leading: Icon(Icons.photo), title: Text('第二张卡片'))),
      ],
    );
  }
}
