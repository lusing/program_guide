// 24 · 界面层 widget 测试：picker/uploader 全注入（24.7）。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:camera_gallery_app/main.dart';

void main() {
  testWidgets('底部弹层：图库与拍照两个入口', (tester) async {
    await tester.pumpWidget(MediaPickerApp(
      picker: (_) async => null,
      uploader: (_) async => 'http://server/file/a.jpg',
    ));

    await tester.tap(find.text('选择图片'));
    await tester.pumpAndSettle();

    expect(find.text('从图库选择'), findsOneWidget);
    expect(find.text('拍照'), findsOneWidget);
  });

  testWidgets('图库选择：本地预览 → 上传完成切网络回显', (tester) async {
    final uploaded = Completer<String>(); // 钉住上传：先看乐观预览，再放行
    await tester.pumpWidget(MediaPickerApp(
      picker: (source) async =>
          source == ImageSource.gallery ? XFile('C:\\fake\\photo.jpg') : null,
      uploader: (_) => uploaded.future,
    ));

    await tester.tap(find.text('选择图片'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('从图库选择'));
    await tester.pump(const Duration(milliseconds: 50));

    // 中间态用确定性断言：占位消失（_picked 已生效）+ 上传进度条在跑。
    // Image.file 的真实文件 IO 在 FakeAsync 里不推进（第 17 章坑），不断言 errorBuilder 文本。
    expect(find.text('请选择图片'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    uploaded.complete('http://server/file/photo.jpg');
    await tester.pumpAndSettle();
    // didUpdateWidget 清掉本地新选，networkUrl 接管回显（Image.network 在测试里走 errorBuilder）
    expect(find.text('已上传：http://server/file/photo.jpg'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('用户取消：picker 返回 null，预览保持占位', (tester) async {
    await tester.pumpWidget(MediaPickerApp(
      picker: (_) async => null,
      uploader: (_) async => throw StateError('不应被调用'),
    ));

    await tester.tap(find.text('选择图片'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('从图库选择'));
    await tester.pumpAndSettle();

    expect(find.text('请选择图片'), findsOneWidget);
  });

  testWidgets('Windows 拍照：StateError 被接住，给人话提示', (tester) async {
    await tester.pumpWidget(MediaPickerApp(
      picker: (source) async {
        if (source == ImageSource.camera) {
          throw StateError('camera is not supported on this platform');
        }
        return null;
      },
      uploader: (_) async => 'http://server/file/a.jpg',
    ));

    await tester.tap(find.text('选择图片'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('拍照'));
    await tester.pumpAndSettle();

    expect(find.textContaining('不支持拍照'), findsOneWidget);
  });

  testWidgets('编辑模式：初始 networkUrl 直接回显（书 14.7）', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ImageInput(
          picker: _neverPick,
          onPicked: _ignore,
          networkUrl: 'http://server/old-avatar.jpg',
        ),
      ),
    ));
    await tester.pumpAndSettle(); // Image.network 加载失败异步进 errorBuilder

    expect(find.text('已上传：http://server/old-avatar.jpg'), findsOneWidget);
  });
}

Future<XFile?> _neverPick(ImageSource source) async => null;
void _ignore(XFile file) {}
