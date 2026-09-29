// 23 · 认证与凭据：token 的完整一生。
// 对照文档 docs/23-auth.md；假认证服务器在 lib/auth_server.dart。
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_server.dart';

Future<void> main() async {
  final server = await FakeAuthServer.start(); // 自测型后端（第 13 章模式）
  runApp(AuthApp(gateway: HttpAuthGateway('${server.base}')));
}

// ═══ 23.3 网关抽象：页面只认接口，main 传真实现，测试传真数据 ═══

class AuthUser {
  const AuthUser({required this.id, required this.email, required this.token});
  final String id;
  final String email;
  final String token;
}

class AuthResult {
  const AuthResult({
    required this.ok,
    required this.message,
    this.user,
    this.expiresIn,
  });
  final bool ok;
  final String message;
  final AuthUser? user;
  final int? expiresIn;
}

abstract class AuthGateway {
  Future<AuthResult> signup(String email, String password);
  Future<AuthResult> login(String email, String password);
  Future<String?> fetchProfile(String token); // null = 401
}

/// HTTP 真实现：错误码在这层翻译成人话（书 13.4 的纪律）。
class HttpAuthGateway implements AuthGateway {
  HttpAuthGateway(this._base);
  final String _base;

  @override
  Future<AuthResult> signup(String email, String password) =>
      _authenticate('signup', email, password);

  @override
  Future<AuthResult> login(String email, String password) =>
      _authenticate('login', email, password);

  Future<AuthResult> _authenticate(String path, String email, String password) async {
    final resp = await http.post(
      Uri.parse('$_base/$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(resp.body) as Map<String, dynamic>? ?? {};
    switch (data['message']) {
      case 'EMAIL_EXISTS':
        return const AuthResult(ok: false, message: '用户已存在');
      case 'EMAIL_NOT_FOUND':
        return const AuthResult(ok: false, message: '不存在这个用户');
      case 'INVALID_PASSWORD':
        return const AuthResult(ok: false, message: '密码不正确');
    }
    final localId = data['localId'];
    if (localId == null) {
      return const AuthResult(ok: false, message: '服务器响应异常');
    }
    return AuthResult(
      ok: true,
      message: path == 'login' ? '登录成功' : '注册成功',
      user: AuthUser(
        id: '$localId',
        email: email,
        token: data['idToken'] as String,
      ),
      expiresIn: int.parse(data['expiresIn'] as String),
    );
  }

  @override
  Future<String?> fetchProfile(String token) async {
    // ═══ 23.4 凭据走头不走 URL：Authorization: Bearer ═══
    final resp = await http.get(
      Uri.parse('$_base/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode != 200) return null;
    return (jsonDecode(resp.body) as Map<String, dynamic>)['email'] as String?;
  }
}

// ═══ 23.5/23.6 认证控制器：token 一生的大管家 ═══

class AuthController extends ChangeNotifier {
  AuthController(this._gateway, this._prefs);

  final AuthGateway _gateway;
  final SharedPreferences _prefs;

  AuthUser? _user;
  DateTime? _expiryTime;
  bool _loading = false;
  Timer? _expiryTimer;

  AuthUser? get user => _user;
  bool get isLoading => _loading;
  DateTime? get expiryTime => _expiryTime;

  Future<AuthResult> login(String email, String password) =>
      _authenticate(true, email, password);

  Future<AuthResult> signup(String email, String password) =>
      _authenticate(false, email, password);

  Future<AuthResult> _authenticate(bool isLogin, String email, String password) async {
    _setLoading(true);
    try {
      final result = isLogin
          ? await _gateway.login(email, password)
          : await _gateway.signup(email, password);
      if (result.ok && result.user != null && result.expiresIn != null) {
        _user = result.user;
        // 存绝对时间点：重启后剩余时间要现算（书 13.11 的关键洞察）
        _expiryTime = DateTime.now().add(Duration(seconds: result.expiresIn!));
        await _persist();
        _armTimer(result.expiresIn!);
        notifyListeners();
      }
      return result;
    } finally {
      _setLoading(false);
    }
  }

  /// 启动时恢复会话：有 token 且未过期 → 直接进主页（书 13.9）。
  Future<void> autoLogin() async {
    final token = _prefs.getString('token');
    final expiry = DateTime.tryParse(_prefs.getString('expiryTime') ?? '');
    if (token == null || expiry == null || expiry.isBefore(DateTime.now())) {
      await _clearPrefs(); // 过期/残缺：清干净，回登录页
      return;
    }
    _user = AuthUser(
      id: _prefs.getString('userId') ?? '',
      email: _prefs.getString('userEmail') ?? '',
      token: token,
    );
    _expiryTime = expiry;
    _armTimer(expiry.difference(DateTime.now()).inSeconds); // 用剩余秒数重挂
    notifyListeners();
  }

  Future<void> logout() async {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _user = null;
    _expiryTime = null;
    await _clearPrefs();
    notifyListeners();
  }

  Future<String?> fetchProfile() => _gateway.fetchProfile(_user!.token);

  void _armTimer(int seconds) {
    _expiryTimer?.cancel();
    _expiryTimer = Timer(Duration(seconds: seconds), _onExpired);
  }

  Future<void> _onExpired() async {
    if (_user == null) return;
    await logout(); // 到点自动登出（书 13.11）
  }

  Future<void> _persist() async {
    await _prefs.setString('token', _user!.token);
    await _prefs.setString('userId', _user!.id);
    await _prefs.setString('userEmail', _user!.email);
    await _prefs.setString('expiryTime', _expiryTime!.toIso8601String());
  }

  Future<void> _clearPrefs() async {
    await _prefs.remove('token');
    await _prefs.remove('userId');
    await _prefs.remove('userEmail');
    await _prefs.remove('expiryTime');
  }

  void _setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel(); // 不 cancel：widget 测试报 Timer is still pending
    super.dispose();
  }
}

// ═══ 23.7 根级认证状态：ChangeNotifier 本来就是发布订阅，rxdart 不需要了 ═══

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({super.key, required AuthController super.notifier, required super.child});

  static AuthController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()!.notifier!;
}

class AuthApp extends StatefulWidget {
  const AuthApp({super.key, required this.gateway});

  final AuthGateway gateway;

  @override
  State<AuthApp> createState() => _AuthAppState();
}

class _AuthAppState extends State<AuthApp> {
  AuthController? _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final controller = AuthController(widget.gateway, prefs);
    await controller.autoLogin(); // 异步恢复会话，完成后一通知，根路由自然翻页
    if (!mounted) {
      controller.dispose();
      return;
    }
    setState(() => _controller = controller);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }
    return AuthScope(
      notifier: _controller!,
      child: MaterialApp(
        title: '认证演示',
        theme: ThemeData(colorSchemeSeed: const Color(0xFF455A64)),
        home: const RootGate(),
      ),
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AuthScope.of(context);
    return controller.user == null ? const AuthPage() : HomePage(controller: controller);
  }
}

// ═══ 23.2 登录/注册表单：枚举切换模式 + 确认密码 validator ═══

enum AuthMode { login, signup }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  AuthMode _mode = AuthMode.login;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AuthScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_mode == AuthMode.login ? '登录' : '注册')),
      body: Center(
        child: SizedBox(
          width: 380,
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: '邮箱'),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? '邮箱格式不对' : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '密码'),
                  validator: (v) =>
                      (v == null || v.length < 6) ? '密码至少 6 位' : null,
                ),
                if (_mode == AuthMode.signup)
                  TextFormField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: '确认密码'),
                    // 确认框的 validator 读密码框的 controller（书 13.2 原版手法）
                    validator: (v) => _passwordController.text != v
                        ? '两次密码输入不一致'
                        : null,
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: controller.isLoading ? null : _submit,
                  child: controller.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_mode == AuthMode.login ? '登录' : '注册'),
                ),
                TextButton(
                  onPressed: () => setState(() => _mode =
                      _mode == AuthMode.login ? AuthMode.signup : AuthMode.login),
                  child: Text(_mode == AuthMode.login ? '切换到 注册' : '切换到 登录'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final controller = AuthScope.of(context); // await 前先取好引用
    final result = _mode == AuthMode.login
        ? await controller.login(_emailController.text, _passwordController.text)
        : await controller.signup(_emailController.text, _passwordController.text);
    if (!mounted) return; // await 之后用 context 前必查（第 07 章纪律的异步版）
    if (result.ok) return; // 根路由由认证状态驱动，自动翻页
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提示'),
        content: Text(result.message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('知道了')),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.controller});

  final AuthController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<String?> _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.controller.fetchProfile(); // 发一次存字段（第 13 章坑）
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.controller.user!;
    final expiry = widget.controller.expiryTime;
    return Scaffold(
      appBar: AppBar(title: const Text('受保护的主页')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.badge),
              title: Text('欢迎回来，${user.email}'),
              subtitle: Text('用户 id：${user.id}'),
            ),
          ),
          FutureBuilder<String?>(
            future: _profile,
            builder: (context, snapshot) {
              // GET /profile 自动带上 Bearer 头（23.4）：三态渲染（第 14 章）
              if (snapshot.connectionState != ConnectionState.done) {
                return const ListTile(title: Text('正在拉取服务器资料…'));
              }
              final email = snapshot.data;
              return ListTile(
                leading: Icon(email == null ? Icons.gpp_bad : Icons.verified_user),
                title: Text(email == null ? 'token 已失效（401）' : '服务器资料：$email'),
                subtitle: const Text('GET /profile · Authorization: Bearer'),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.key),
            title: Text('token：${_masked(user.token)}'),
            subtitle: Text('有效期至 ${expiry.toString()}'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => widget.controller.logout(),
            child: const Text('退出登录'),
          ),
        ],
      ),
    );
  }

  static String _masked(String token) =>
      token.length <= 12 ? token : '${token.substring(0, 12)}…';
}
