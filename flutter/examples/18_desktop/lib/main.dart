import 'package:flutter/material.dart';

// 18 桌面专题：菜单栏、SelectionArea、Scrollbar 与桌面习惯
void main() => runApp(const DesktopApp());

class DesktopApp extends StatelessWidget {
  const DesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      ),
      home: const DesktopPage(),
    );
  }
}

class DesktopPage extends StatefulWidget {
  const DesktopPage({super.key});

  @override
  State<DesktopPage> createState() => _DesktopPageState();
}

class _DesktopPageState extends State<DesktopPage> {
  var _selected = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('桌面专题')),
      body: Column(
        children: [
          // ═══ 18.1 MenuBar：桌面级菜单栏（顶部） ═══
          MenuBar(
            children: [
              SubmenuButton(
                menuChildren: [
                  MenuItemButton(
                    onPressed: () => setState(() => _selected = '新建'),
                    child: const Text('新建'),
                  ),
                  MenuItemButton(
                    onPressed: () => setState(() => _selected = '退出'),
                    child: const Text('退出'),
                  ),
                ],
                child: const Text('文件'),
              ),
            ],
          ),
          Expanded(
            // ═══ 18.3 Scrollbar + 滚轮：桌面用户 expect 可见滚动条 ═══
            child: Scrollbar(
              child: ListView.builder(
                itemCount: 40,
                itemBuilder: (context, i) => ListTile(
                  dense: true,
                  title: Text('条目 $i'),
                ),
              ),
            ),
          ),
          // ═══ 18.2 SelectionArea：让文本可选中复制（桌面标配） ═══
          SelectionArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text('菜单选择：$_selected（这段文字可以选中复制）'),
            ),
          ),
        ],
      ),
    );
  }
}
