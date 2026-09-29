// 24 · 纯 Dart 层：multipart 上传全链路（真实 IO，与 widget 测试分文件）。
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart' show XFile;

import 'package:camera_gallery_app/main.dart';
import 'package:camera_gallery_app/upload_server.dart';

void main() {
  test('multipart 上传 → 拿到 URL → GET 取回内容', () async {
    final server = await UploadServer.start();
    addTearDown(server.close);

    final tempFile = File(
        '${Directory.systemTemp.path}/upload-src-${DateTime.now().microsecondsSinceEpoch}.txt');
    const content = 'HELLO-PNG-BYTES';
    await tempFile.writeAsString(content);
    addTearDown(() => tempFile.delete());

    final url = await uploadImage(server.base, XFile(tempFile.path));
    expect(url, contains('/file/'));
    expect(url, startsWith('${server.base}'));

    final back = await HttpClient().getUrl(Uri.parse(url));
    final resp = await back.close();
    expect(resp.statusCode, 200);
    final body = await resp.transform(const Utf8Decoder(allowMalformed: true)).join();
    expect(body, contains(content)); // 哑服务器存的是整个 multipart 信封
  });
}
