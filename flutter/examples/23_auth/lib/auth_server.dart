// ═══ 23.1 自测型假认证服务器：本地 HttpServer，零外网依赖 ═══
// 用户表 + token 签发/校验 + Bearer 鉴权的受保护资源。main() 与纯 Dart 测试共用。
import 'dart:convert';
import 'dart:io';

class FakeAuthServer {
  FakeAuthServer._(this._server);

  final HttpServer _server;
  final Map<String, String> _users = {};      // email -> password
  final Map<String, String> _tokens = {};     // token -> email
  int _nextId = 1;

  /// 随机端口启动，避免测试间打架。
  static Future<FakeAuthServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final instance = FakeAuthServer._(server);
    server.listen(instance._handle);
    return instance;
  }

  Uri get base => Uri.parse('http://127.0.0.1:${_server.port}');
  Future<void> close() => _server.close();

  void _handle(HttpRequest request) async {
    final path = request.uri.path;
    final response = request.response;
    try {
      if (path == '/signup' && request.method == 'POST') {
        // ═══ 书 13.3：注册接口。重复注册返回 EMAIL_EXISTS（沿用书的形状） ═══
        final body = await _readJson(request);
        final email = body['email'] as String? ?? '';
        final password = body['password'] as String? ?? '';
        if (_users.containsKey(email)) {
          await _json(response, {'message': 'EMAIL_EXISTS'});
          return;
        }
        _users[email] = password;
        await _json(response, {
          'localId': '${_nextId++}',
          'idToken': _newToken(email),
          'expiresIn': '3600',
        });
        return;
      }
      if (path == '/login' && request.method == 'POST') {
        // ═══ 书 13.6：登录接口的三分支 ═══
        final body = await _readJson(request);
        final email = body['email'] as String? ?? '';
        final password = body['password'] as String? ?? '';
        if (!_users.containsKey(email)) {
          await _json(response, {'message': 'EMAIL_NOT_FOUND'});
          return;
        }
        if (_users[email] != password) {
          await _json(response, {'message': 'INVALID_PASSWORD'});
          return;
        }
        await _json(response, {
          'localId': '${_nextId++}',
          'idToken': _newToken(email),
          'expiresIn': '3600',
        });
        return;
      }
      if (path == '/profile' && request.method == 'GET') {
        // ═══ 23.4 受保护资源：Authorization: Bearer <token>，无头/坏 token 一律 401 ═══
        final header = request.headers.value('Authorization');
        final email = header != null && header.startsWith('Bearer ')
            ? _tokens[header.substring(7)]
            : null;
        if (email == null) {
          response.statusCode = 401;
          await _json(response, {'message': 'UNAUTHORIZED'});
          return;
        }
        await _json(response, {'email': email});
        return;
      }
      response.statusCode = 404;
      await _json(response, {'message': 'NOT_FOUND'});
    } catch (_) {
      response.statusCode = 500;
      await response.close();
    }
  }

  String _newToken(String email) {
    final token = 'tok-${DateTime.now().microsecondsSinceEpoch}-$email';
    _tokens[token] = email;
    return token;
  }

  static Future<Map<String, dynamic>> _readJson(HttpRequest request) async {
    final text = await utf8.decoder.bind(request).join();
    return jsonDecode(text) as Map<String, dynamic>;
  }

  static Future<void> _json(HttpResponse response, Map<String, dynamic> body) async {
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
    await response.close();
  }
}
