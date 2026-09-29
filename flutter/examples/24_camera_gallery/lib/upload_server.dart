// ═══ 24.5 假上传服务器：接收 multipart 上传，落盘后发回可访问 URL ═══
// 教学用哑设计：不解析 multipart 信封，原样存整个请求体（客户端编码正确性由测试验证）。
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class UploadServer {
  UploadServer._(this._server, this._dir);

  final HttpServer _server;
  final Directory _dir;

  static Future<UploadServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final dir = await Directory.systemTemp.createTemp('upload_server');
    final instance = UploadServer._(server, dir);
    server.listen(instance._handle);
    return instance;
  }

  Uri get base => Uri.parse('http://127.0.0.1:${_server.port}');

  Future<void> close() async {
    await _server.close();
    if (await _dir.exists()) {
      await _dir.delete(recursive: true);
    }
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    try {
      if (request.uri.path == '/upload' && request.method == 'POST') {
        final builder = BytesBuilder(copy: false);
        await for (final chunk in request) {
          builder.add(chunk);
        }
        final body = builder.takeBytes();
        final name = 'img-${DateTime.now().microsecondsSinceEpoch}.jpg';
        await File('${_dir.path}/$name').writeAsBytes(body);
        // 响应形状仿书 14.8：url + name + size
        final payload = jsonEncode({
          'url': '${base.toString()}/file/$name',
          'name': name,
          'size': body.length,
        });
        response.headers.contentType = ContentType.json;
        response.write(payload);
        await response.close();
        return;
      }
      if (request.uri.path.startsWith('/file/')) {
        final name = request.uri.path.substring('/file/'.length);
        final file = File('${_dir.path}/$name');
        if (!await file.exists()) {
          response.statusCode = 404;
          await response.close();
          return;
        }
        response.headers.contentType = ContentType.parse('image/jpeg');
        await response.addStream(file.openRead());
        await response.close();
        return;
      }
      response.statusCode = 404;
      await response.close();
    } catch (_) {
      response.statusCode = 500;
      await response.close();
    }
  }
}
