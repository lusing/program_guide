// 23 · 纯 Dart 层测试：真服务器往返 + 控制器自动登出。
// 本文件不含 testWidgets——一旦同套件出现 WidgetBinding，真实 http 会被改成 400。
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auth_app/auth_server.dart';
import 'package:auth_app/main.dart';

import 'fake_gateway.dart';

void main() {
  group('假认证服务器 + HttpAuthGateway（真实 IO）', () {
    late FakeAuthServer server;
    late HttpAuthGateway gateway;

    setUp(() async {
      server = await FakeAuthServer.start();
      gateway = HttpAuthGateway('${server.base}');
    });

    tearDown(() => server.close());

    test('注册 → 重复注册 → 登录的各分支', () async {
      final signup = await gateway.signup('a@x.com', '123456');
      expect(signup.ok, isTrue);
      expect(signup.user!.token, isNotEmpty);
      expect(signup.expiresIn, 3600);

      expect((await gateway.signup('a@x.com', '123456')).message, '用户已存在');
      expect((await gateway.login('b@x.com', '123456')).message, '不存在这个用户');
      expect((await gateway.login('a@x.com', '000000')).message, '密码不正确');
      expect((await gateway.login('a@x.com', '123456')).ok, isTrue);
    });

    test('受保护资源：Bearer 头校验', () async {
      final signup = await gateway.signup('a@x.com', '123456');
      final token = signup.user!.token;

      expect(await gateway.fetchProfile(token), 'a@x.com');
      expect(await gateway.fetchProfile('wrong-token'), isNull);
    });
  });

  group('AuthController（纯 Dart）', () {
    test('expiresIn=0：Timer 到点自动登出并清 prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = AuthController(FakeAuthGateway(expiresIn: 0), prefs);

      final result = await controller.login('alice@example.com', '123456');
      expect(result.ok, isTrue);
      expect(controller.user, isNotNull);
      expect(prefs.getString('token'), 'tok-alice');

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(controller.user, isNull); // Timer 已触发登出
      expect(prefs.getString('token'), isNull);
      controller.dispose();
    });
  });
}
