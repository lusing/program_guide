import 'package:flutter/material.dart';

// 12 列表与滚动：ListView.builder、分隔线、GridView、Sliver 一瞥
void main() => runApp(const ListsApp());

class ListsApp extends StatelessWidget {
  const ListsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lime),
      ),
      home: const ListsPage(),
    );
  }
}

class ListsPage extends StatelessWidget {
  const ListsPage({super.key});

  // 40 条：足够长，懒构建的差异才看得见（可见区 + 缓存区之外的条目不构建）
  static final _items = List.generate(40, (i) => '条目 ${i + 1}');

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('列表与滚动'),
          bottom: const TabBar(tabs: [Tab(text: '列表'), Tab(text: '网格')]),
        ),
        body: TabBarView(
          children: [
            // ═══ 12.1 ListView.separated：懒构建 + 分隔线 ═══
            ListView.separated(
              itemCount: _items.length,
              itemBuilder: (context, i) => ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(_items[i]),
                trailing: const Icon(Icons.chevron_right),
              ),
              separatorBuilder: (_, _) => const Divider(height: 1),
            ),
            // ═══ 12.2 GridView.count：固定列数网格 ═══
            GridView.count(
              crossAxisCount: 4,
              children: [for (final f in _items) Center(child: Text(f))],
            ),
          ],
        ),
      ),
    );
  }
}
