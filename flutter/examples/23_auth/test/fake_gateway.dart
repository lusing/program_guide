// 假网关：widget 测试与控制器纯 Dart 测试共用，数据写死零网络。
import 'package:auth_app/main.dart';

class FakeAuthGateway implements AuthGateway {
  const FakeAuthGateway({this.expiresIn = 3600});

  final int expiresIn;

  @override
  Future<AuthResult> login(String email, String password) async {
    if (password != '123456') {
      return const AuthResult(ok: false, message: '密码不正确');
    }
    return AuthResult(
      ok: true,
      message: '登录成功',
      user: AuthUser(id: '1', email: email, token: 'tok-alice'),
      expiresIn: expiresIn,
    );
  }

  @override
  Future<AuthResult> signup(String email, String password) async =>
      const AuthResult(ok: false, message: '用户已存在');

  @override
  Future<String?> fetchProfile(String token) async =>
      token == 'tok-alice' ? 'alice@example.com' : null;
}
