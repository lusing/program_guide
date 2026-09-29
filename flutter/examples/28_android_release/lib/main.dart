// 28 · 移动端构建与发布：发布身份演示页。
// 版本号与 pubspec.yaml 的 version: 保持同步（真实值运行时可由生态包 package_info 读取）。
import 'package:flutter/material.dart';

const appVersion = '1.2.0+7'; // pubspec: version: 1.2.0+7

void main() => runApp(const ReleaseChecklistApp());

class ReleaseChecklistApp extends StatelessWidget {
  const ReleaseChecklistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '发布演示',
      theme: ThemeData(colorSchemeSeed: const Color(0xFFBF360C)),
      home: const ChecklistPage(),
    );
  }
}

class ChecklistPage extends StatelessWidget {
  const ChecklistPage({super.key});

  static const checklist = [
    ('身份', 'label / applicationId / versionCode 三处各就各位'),
    ('脸面', 'flutter_launcher_icons 生成全密度图标；闪屏 launch_background.xml'),
    ('签名', 'keytool 生成 jks + key.properties（不进 git）+ signingConfigs.release'),
    ('构建', 'flutter build apk --release / appbundle'),
    ('上架', 'versionCode 递增；AAB 走 Google Play，APK 直发'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('28 · 发布清单')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified),
              title: const Text('发布演示（com.guide.release_demo）'),
              subtitle: const Text('version: $appVersion'),
            ),
          ),
          const SizedBox(height: 8),
          for (final (stage, detail) in checklist)
            ListTile(
              dense: true,
              leading: const Icon(Icons.check_circle_outline),
              title: Text(stage),
              subtitle: Text(detail),
            ),
        ],
      ),
    );
  }
}
