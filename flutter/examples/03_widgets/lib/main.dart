import 'package:flutter/material.dart';

// 03 Widget 基础：Widget 是不可变配置，界面靠组合而非继承
void main() => runApp(const WidgetsDemoApp());

class WidgetsDemoApp extends StatelessWidget {
  const WidgetsDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Widget 基础')),
        // ═══ 3.3 组合优于继承：页面 = Widget 拼 Widget ═══
        body: ListView(children: const [ProfileCard(), SkillList()]),
      ),
    );
  }
}

// ═══ 3.1 StatelessWidget：纯配置，build 描述"长什么样" ═══
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    // ═══ 3.2 基础展示组件：Card/ListTile/Icon/Text/Divider ═══
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: const Text('阿 Dart'),
        subtitle: const Text('一名会写 Dart 的开发者'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class SkillList extends StatelessWidget {
  const SkillList({super.key});

  @override
  Widget build(BuildContext context) {
    const skills = ['Dart 语言', 'Widget 组合', '布局约束'];
    return Column(
      children: [
        const Divider(),
        // ═══ 3.4 const 复用：配置不可变，编译期就固定 ═══
        for (final s in skills)
          ListTile(
            dense: true,
            leading: const Icon(Icons.check_circle_outline),
            title: Text(s),
          ),
      ],
    );
  }
}
