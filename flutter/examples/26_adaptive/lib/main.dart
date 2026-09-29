// 26 · Cupertino 与平台自适应：一套代码两种脸。
// 对照文档 docs/26-adaptive.md 的 26.2 / 26.4 节。
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() => runApp(const AdaptiveGalleryApp());

class AdaptiveGalleryApp extends StatefulWidget {
  const AdaptiveGalleryApp({super.key});

  @override
  State<AdaptiveGalleryApp> createState() => _AdaptiveGalleryAppState();
}

class _AdaptiveGalleryAppState extends State<AdaptiveGalleryApp> {
  TargetPlatform _platform = TargetPlatform.android; // 模拟平台（o 键的手动版）

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '自适应控件馆',
      // ═══ 26.4 主题按平台分：写法升级为 colorSchemeSeed（书的 primaryColor 已废） ═══
      theme: themeFor(_platform),
      home: GalleryPage(
        platform: _platform,
        onPlatform: (p) => setState(() => _platform = p),
      ),
    );
  }
}

ThemeData themeFor(TargetPlatform platform) => platform == TargetPlatform.iOS
    ? ThemeData(
        colorSchemeSeed: CupertinoColors.systemIndigo,
        brightness: Brightness.dark,
        platform: platform,
      )
    : ThemeData(
        colorSchemeSeed: const Color(0xFF00838F),
        platform: platform,
      );

// ═══ 26.4 adaptive helper 层：调用点只声明意图，平台分叉收在这里 ═══

Widget adaptiveSpinner(BuildContext context, {double radius = 12}) =>
    Theme.of(context).platform == TargetPlatform.iOS
        ? CupertinoActivityIndicator(radius: radius)
        : SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: const CircularProgressIndicator(strokeWidth: 2),
          );

Widget adaptiveSwitch(BuildContext context,
        {required bool value, required ValueChanged<bool> onChanged}) =>
    Theme.of(context).platform == TargetPlatform.iOS
        ? CupertinoSwitch(value: value, onChanged: onChanged)
        : Switch(value: value, onChanged: onChanged);

Future<void> adaptiveConfirm(BuildContext context, String title) {
  // ═══ 26.3 对话框与按钮成对换脸：避免一页两副面孔 ═══
  final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
  return isIOS
      ? showCupertinoDialog<void>(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: Text(title),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('好'),
              ),
            ],
          ),
        )
      : showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('好'),
              ),
            ],
          ),
        );
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({
    super.key,
    required this.platform,
    required this.onPlatform,
  });

  final TargetPlatform platform;
  final ValueChanged<TargetPlatform> onPlatform;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  bool _switchValue = false;

  @override
  Widget build(BuildContext context) {
    final isIOS = widget.platform == TargetPlatform.iOS;
    return Scaffold(
      appBar: AppBar(title: Text('26 · 自适应控件馆（${isIOS ? 'iOS 脸' : 'Material 脸'}）')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ═══ 26.2 模拟平台：Theme.platform 可被覆写，Windows 上也能体验 iOS 脸 ═══
          SegmentedButton<TargetPlatform>(
            segments: const [
              ButtonSegment(value: TargetPlatform.android, label: Text('Android')),
              ButtonSegment(value: TargetPlatform.iOS, label: Text('iOS')),
              ButtonSegment(value: TargetPlatform.windows, label: Text('Windows')),
            ],
            selected: {widget.platform},
            onSelectionChanged: (s) => widget.onPlatform(s.first),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Text('加载条'),
                  const SizedBox(height: 8),
                  adaptiveSpinner(context, radius: 16),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(child: Text('开关（当前 $_switchValue）')),
                  adaptiveSwitch(
                    context,
                    value: _switchValue,
                    onChanged: (v) => setState(() => _switchValue = v),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('确认对话框'),
              subtitle: const Text('按钮与弹窗跟同一张脸'),
              trailing: isIOS
                  ? CupertinoButton(
                      onPressed: () => adaptiveConfirm(context, '已保存'),
                      child: const Text('确认'),
                    )
                  : FilledButton(
                      onPressed: () => adaptiveConfirm(context, '已保存'),
                      child: const Text('确认'),
                    ),
              // ═══ 26.3 CupertinoListTile：iOS 风格列表行（中性内容两边通用） ═══
            ),
          ),
          CupertinoListTile(
            title: Text(isIOS ? 'CupertinoListTile（iOS 风）' : 'CupertinoListTile（桌面也可用）'),
            trailing: const CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: null,
              child: Text('详情'),
            ),
          ),
        ],
      ),
    );
  }
}
