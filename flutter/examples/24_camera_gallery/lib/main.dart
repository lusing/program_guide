// 24 · 相机与图库：媒体选取（image_picker + multipart 上传）。
// 对照文档 docs/24-camera-gallery.md；假上传服务器在 lib/upload_server.dart。
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'upload_server.dart';

/// 选取动作与上传动作都做成类型别名：main 传真实现，测试传假（24.7 注入）。
typedef ImagePickerFn = Future<XFile?> Function(ImageSource source);
typedef UploaderFn = Future<String> Function(XFile file);

Future<void> main() async {
  final server = await UploadServer.start();
  runApp(MediaPickerApp(
    // ═══ 24.2 三板斧：maxWidth + imageQuality 双限，别直传原图 ═══
    picker: (source) => ImagePicker()
        .pickImage(source: source, maxWidth: 800, imageQuality: 70),
    uploader: (x) => uploadImage(server.base, x),
  ));
}

/// ═══ 24.5 第一方 http 的 multipart 上传：不必为表单引入 dio ═══
Future<String> uploadImage(Uri base, XFile file) async {
  final request = http.MultipartRequest('POST', base.replace(path: '/upload'))
    ..files.add(await http.MultipartFile.fromPath('files', file.path));
  final streamed = await request.send();
  final body =
      jsonDecode(await streamed.stream.bytesToString()) as Map<String, dynamic>;
  return body['url'] as String;
}

class MediaPickerApp extends StatelessWidget {
  const MediaPickerApp({super.key, required this.picker, required this.uploader});

  final ImagePickerFn picker;
  final UploaderFn uploader;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '媒体选取演示',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF6A1B9A)),
      home: AvatarPage(picker: picker, uploader: uploader),
    );
  }
}

class AvatarPage extends StatefulWidget {
  const AvatarPage({super.key, required this.picker, required this.uploader});

  final ImagePickerFn picker;
  final UploaderFn uploader;

  @override
  State<AvatarPage> createState() => _AvatarPageState();
}

class _AvatarPageState extends State<AvatarPage> {
  String? _remoteUrl;
  bool _uploading = false;

  Future<void> _onPicked(XFile xfile) async {
    setState(() => _uploading = true); // 乐观 UI：先本地预览，上传完切网络图
    try {
      final url = await widget.uploader(xfile);
      if (!mounted) return;
      setState(() => _remoteUrl = url);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('上传失败')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('换个头像')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ImageInput(
            picker: widget.picker,
            onPicked: _onPicked,
            networkUrl: _remoteUrl,
          ),
          const SizedBox(height: 12),
          if (_uploading) const LinearProgressIndicator(),
          if (!_uploading)
            const ListTile(
              leading: Icon(Icons.cloud_done),
              title: Text('选取后自动上传'),
              subtitle: Text('本地预览是乐观 UI；上传完成切换到服务器 URL 回显'),
            ),
        ],
      ),
    );
  }
}

class ImageInput extends StatefulWidget {
  const ImageInput({
    super.key,
    required this.picker,
    required this.onPicked,
    this.networkUrl,
  });

  final ImagePickerFn picker;
  final ValueChanged<XFile> onPicked;
  final String? networkUrl; // 编辑模式：已有网络图（书 14.7）

  @override
  State<ImageInput> createState() => _ImageInputState();
}

class _ImageInputState extends State<ImageInput> {
  XFile? _picked;

  @override
  void didUpdateWidget(ImageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ═══ 上传完成（networkUrl 更新）：本地新选让位给服务器回显 ═══
    if (widget.networkUrl != null && widget.networkUrl != oldWidget.networkUrl) {
      _picked = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => _openSourceSheet(context),
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('选择图片'),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(height: 240, width: double.infinity, child: _preview()),
        ),
      ],
    );
  }

  // ═══ 24.4 三态预览：本地新选 > 网络旧图 > 占位 ═══
  Widget _preview() {
    final picked = _picked;
    if (picked != null) {
      return Image.file(
        File(picked.path),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Center(child: Text('已选择：${picked.name}')),
      );
    }
    final url = widget.networkUrl;
    if (url != null) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Center(child: Text('已上传：$url')),
      );
    }
    return const Center(child: Text('请选择图片'));
  }

  // ═══ 24.3 底部弹层：相机/图库二选一（书 14.2） ═══
  void _openSourceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('从图库选择'),
            onTap: () => _pick(sheetContext, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('拍照'),
            onTap: () => _pick(sheetContext, ImageSource.camera),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext sheetContext, ImageSource source) async {
    Navigator.of(sheetContext).pop(); // 先关弹层再等选取（书 14.3 的顺序）
    try {
      final xfile = await widget.picker(source);
      if (xfile == null) return; // 用户取消：不是错误
      setState(() => _picked = xfile);
      widget.onPicked(xfile);
    } on StateError {
      // 实测：Windows 上 camera 无实现，抛 StateError（image_picker_windows 源码注释）
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前平台不支持拍照（Windows 只有图库）')),
      );
    }
  }
}
