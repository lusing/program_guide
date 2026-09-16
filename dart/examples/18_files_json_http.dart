// 18 文件、JSON 与 HTTP：dart:io 文件、dart:convert 编解码、HttpServer 自测
// 运行：dart run examples/18_files_json_http.dart

import 'dart:convert';
import 'dart:io';

// ═══ 18.4 类型安全的 JSON：手写 fromJson/toJson ═══
class Book {
  final String title;
  final int year;
  const Book(this.title, this.year);

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        json['title'] as String,
        json['year'] as int,
      );

  Map<String, dynamic> toJson() => {'title': title, 'year': year};

  @override
  String toString() => '《$title》($year)';
}

Future<void> main() async {
  // ═══ 18.1 File：读写文本与追加 ═══
  final dir = await Directory.systemTemp.createTemp('dart_guide_');
  final file = File('${dir.path}/note.txt');
  await file.writeAsString('第一行\n', mode: FileMode.write);
  await file.writeAsString('第二行\n', mode: FileMode.append);
  final text = await file.readAsString();
  print('文件内容：${text.trim().split('\n')}');
  print('存在=${await file.exists()} 大小=${await file.length()} 字节');

  // ═══ 18.2 Directory：创建与列出 ═══
  await File('${dir.path}/extra.txt').writeAsString('x');
  final entries = await dir.list().toList();
  print('临时目录有 ${entries.length} 个条目');
  await dir.delete(recursive: true); // 清理临时目录

  // ═══ 18.3 JSON：编码/解码 ═══
  final jsonText = jsonEncode({'name': 'Dart', 'scores': [90, 85]});
  print('编码：$jsonText');
  final decoded = jsonDecode(jsonText); // 静态类型是"动态的" Map/List
  print('解码：${decoded['name']} / ${decoded['scores'][1]}');
  print('解码类型：${decoded.runtimeType}');

  // ═══ 18.4（续）对象 <-> JSON ═══
  final books = [const Book('Dart 实战', 2026), const Book('深入浅出', 2025)];
  final bookJson = jsonEncode(books.map((b) => b.toJson()).toList());
  print('books JSON：$bookJson');
  final restored = (jsonDecode(bookJson) as List)
      .map((e) => Book.fromJson(e as Map<String, dynamic>))
      .toList();
  print('还原：$restored');

  // ═══ 18.5 HttpServer：随机端口起服务，自请求一次后关闭 ═══
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final url = 'http://127.0.0.1:${server.port}';
  server.listen((request) async {
    final response = request.response;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode({'ok': true, 'path': request.uri.path}));
    await response.close();
  });

  final client = HttpClient();
  final req = await client.getUrl(Uri.parse('$url/hello'));
  final res = await req.close();
  final body = await utf8.decodeStream(res);
  print('HTTP ${res.statusCode} 响应：$body');

  await server.close(force: true);
  client.close();
  print('HTTP 演示结束（服务已关闭，进程正常退出）');
}
