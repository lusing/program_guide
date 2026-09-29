import 'package:flutter/material.dart';

/// 我的页：logo 用的是带 2.0x 分辨率变体的 asset（见 pubspec 与 3.6）。
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: scheme.surfaceContainerHighest,
              // 同一张 logo 的两个分辨率变体：1x 64px / 2.0x 128px。
              // 框架按设备像素比自动挑，代码一字不改。
              child: Image.asset('assets/logo/im_logo.png', width: 56),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('我',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          for (final (icon, title) in [
            (Icons.people, '好友动态'),
            (Icons.photo, '相册'),
            (Icons.folder, '文件'),
            (Icons.support_agent, '客服'),
            (Icons.delete_sweep, '清理缓存'),
          ])
            ListTile(
              leading: Icon(icon),
              title: Text(title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title：演示入口')),
              ),
            ),
        ],
      ),
    );
  }
}
