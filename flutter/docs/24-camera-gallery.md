# 24 · 相机与图库：媒体选取

> 对应示例：examples/24_camera_gallery/

## 24.1 解决什么问题

资讯要配图、头像要上传——移动应用的两大媒体入口：**拍照**与**选图**。Flutter 第一方包 `image_picker`（flutter/packages 出品）把两个入口统一成一个 API，桌面端（Windows/macOS/Linux）用文件对话框实现"图库"。先立平台矩阵（读源码实测，不是背文档）：

| 能力 | Android | iOS | Windows 桌面 |
|---|---|---|---|
| 图库选择 | ✅（新版系统免权限照片选择器） | ✅ | ✅ 文件对话框 |
| 拍照 | ✅ | ✅ | ❌ 抛 `StateError`（无相机实现） |
| 权限配置 | 免（包内声明齐全） | Info.plist 两个 key | 无权限概念 |

## 24.2 选取 API：XFile 时代

```dart
// ═══ 24.2 现在：实例方法 + XFile?（null = 用户取消） ═══
final picker = ImagePicker();
final xfile = await picker.pickImage(
  source: ImageSource.gallery,   // 或 .camera
  maxWidth: 800,                 // 三板斧一：限宽
  imageQuality: 70,              // 三板斧二：JPEG 质量 0-100
);
if (xfile == null) return;       // 用户取消了——不是错误
// xfile.path / xfile.name / await xfile.readAsBytes()
```

"当年如此/现在这样"：书 2020 年写的是 `ImagePicker.pickImage(...)`（静态方法）返回 `Future<File>`——现在是**实例方法**，返回 `XFile?`。`XFile` 是跨平台文件抽象（Web 上根本没有磁盘路径，`File` 撑不住）。可空性本身就是语义：**取消不再抛异常，返回 null**。三板斧（`maxWidth`/`maxHeight`/`imageQuality`）在书年代只有 `maxWidth`——后两个是后来补的压缩武器：原图 4000px 直传既卡界面又费流量。

## 24.3 选择器 UI：底部弹层

```dart
// ═══ 24.3 书 14.2：相机/图库二选一的底部弹层 ═══
void _openSourceSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => Column(mainAxisSize: MainAxisSize.min, children: [
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
    ]),
  );
}

Future<void> _pick(BuildContext context, ImageSource source) async {
  Navigator.of(context).pop();               // 先关弹层再等选取（书 14.3 的顺序）
  try {
    final xfile = await widget.picker(source);
    if (xfile != null) widget.onPicked(xfile);
  } on StateError {
    // ═══ 实测：Windows 上 camera 无实现，抛 StateError ═══
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前平台不支持拍照（Windows 只有图库）')),
      );
    }
  }
}
```

平台差异的教训：**能力矩阵进 UI 层**——要么隐藏"拍照"项（按 `Platform.isWindows` 判断），要么像示例这样接住错误给一句人话提示。直接崩给用户看是下策。

## 24.4 预览三态

```dart
// ═══ 24.4 书 14.7 的三态预览：新选的本地图 / 已上传的网络图 / 占位 ═══
Widget _preview() {
  if (_picked != null) {
    return Image.file(File(_picked!.path),
        fit: BoxFit.cover, height: 240,
        errorBuilder: (_, __) => Text('已选择：${_picked!.name}'));
  }
  if (widget.networkUrl != null) {
    return Image.network(widget.networkUrl!,
        fit: BoxFit.cover, height: 240,
        errorBuilder: (_, __) => Text('已上传：${widget.networkUrl}'));
  }
  return const SizedBox(
      height: 240, child: Center(child: Text('请选择图片')));
}
```

`XFile` 喂 `Image.file` 要过一道 `File(x.path)`（平台实现里 XFile 包着真文件）；`errorBuilder` 让坏图不白屏——测试环境里假路径也能给出可断言的文本（第 23 章同款手法）。

## 24.5 上传：multipart 表单

书 14.6 当年为此引入了 `dio`（第三方 HTTP 库）。**第一方 `http` 包同样能发 multipart**，不必为此加依赖：

```dart
// ═══ 24.5 http 包的 MultipartRequest：字段名 files 与服务端约定对齐 ═══
Future<String> uploadImage(Uri base, XFile file) async {
  final request = http.MultipartRequest('POST', base.replace(path: '/upload'))
    ..files.add(await http.MultipartFile.fromPath('files', file.path));
  final streamed = await request.send();
  final body = jsonDecode(await streamed.stream.bytesToString())
      as Map<String, dynamic>;
  return body['url'] as String;       // 服务端返回可访问的 URL
}
```

选完图到拿到 URL 是异步链路：`onPicked` 回调里先显示本地预览（乐观 UI），上传完成再切网络图——示例的假上传服务器（本地 HttpServer，把文件落临时目录再发回 URL）跑通了全链路。

## 24.6 权限与平台配置

- **iOS**：`ios/Runner/Info.plist` 加两个描述 key（书 14.3 原样有效）——`NSPhotoLibraryUsageDescription`、`NSCameraUsageDescription`，值是弹给用户看的一句话。漏配直接崩。
- **Android**：现代版走系统照片选择器（PHOTOPICKER），免存储权限；老设备回落到 READ_MEDIA_IMAGES，包内清单已声明。
- **Windows**：文件对话框，无权限弹窗；`ImageSource.camera` 抛 `StateError`（源码注释明说：除非你注入 cameraDelegate）。

## 24.7 可测性：picker 注入

`ImagePicker()` 一调就拉起真机文件框——widget 测试没法点它。解法是第 13 章的依赖注入：**把"选图动作"抽象成函数参数**：

```dart
class ImageInput extends StatefulWidget {
  const ImageInput({
    super.key,
    required this.picker,      // Future<XFile?> Function(ImageSource)
    required this.onPicked,    // ValueChanged<XFile?>
    this.networkUrl,
  });
```

`main()` 传真实现（`ImagePicker().pickImage`），测试传假函数（返回写死的 `XFile` 或 null 模拟取消）。上传同理注入 `Future<String> Function(XFile)`——23 章的教训在这里升级成习惯：**平台通道背后的能力，一概注入化**（下一章的 MethodChannel 更是如此）。

## 坑位清单

- **拿旧 API 抄书**：`ImagePicker.pickImage` 静态版已死——实例方法 + `XFile?`，取消返回 null 不抛错。
- **不限尺寸直传原图**：4000px 照片进 ListView 就掉帧——`maxWidth` + `imageQuality` 双限。
- **Windows 上点拍照**：`StateError` 直崩——按平台隐藏入口，或 catch 后给人话提示。
- **弹层没关就去等选取**：先 `pop` 弹层再 `await`，顺序反了上下文先失效（书 14.3 的顺序）。
- **iOS 忘配 Info.plist**：一调相机/图库就崩，控制台给的原因在真机日志里——两个 UsageDescription key 先写上。
- **widget 测试里调真 picker**：测试环境没有文件框——picker/upload 全注入。
