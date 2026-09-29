# 23 · 认证与凭据：token 的完整一生

> 对应示例：examples/23_auth/

## 23.1 解决什么问题

真实应用的后端是**无状态 API**：服务器不记 Session，靠 token 识别用户。第 13 章的"自测型后端"模式本章升级成一个**假认证服务器**（本地 HttpServer，带用户表、token 签发与校验），然后沿 token 的一生走完全程：**获取 → 携带 → 持久化 → 自动登录 → 过期 → 登出**。表单侧（确认密码校验、加载态、错误弹窗）与状态侧（认证状态驱动根路由）一并练齐。

| 概念 | 一句话 |
|---|---|
| Session | 服务器记住你（有状态），客户端只存钥匙 |
| token | 服务器发了张实名通行证（无状态），客户端每次出示 |

## 23.2 登录/注册表单：一个页面两种模式

```dart
// ═══ 23.2 AuthMode 枚举切换登录/注册（书 13.2） ═══
enum AuthMode { login, signup }
AuthMode _mode = AuthMode.login;

// 确认密码框：validator 里比对密码框的 controller（书 13.2 的原版手法）
TextFormField(
  controller: _confirmController,
  obscureText: true,
  validator: (value) =>
      _passwordController.text != value ? '两次密码输入不一致' : null,
),
```

要点两个：**枚举驱动 UI 分支**（登录模式不渲染确认框，按钮文案随模式变）；**确认密码的 validator 读另一个框的 controller**——两个 TextField 各持 controller，实时文本随手可得（第 11 章表单的进阶用法）。

## 23.3 认证服务与错误分支

网络细节收进一个 `AuthGateway` 抽象（第 13 章依赖注入的接口版）——页面只认接口，`main()` 传真实现（HTTP），测试传真数据：

```dart
// ═══ 23.3 网关返回统一的结果对象：成功带 user，失败带人话消息 ═══
class AuthResult {
  const AuthResult({required this.ok, required this.message, this.user, this.expiresIn});
  final bool ok;
  final String message;        // '登录成功' / '用户已存在' / '密码不错误'…
  final AuthUser? user;        // ok 时才有
  final int? expiresIn;        // token 有效秒数
}
```

书 13.4 的错误处理纪律：**把服务端的错误码翻译成用户能懂的话，再决定 UI 反应**——`EMAIL_EXISTS → "用户已存在"`（弹对话框）、`EMAIL_NOT_FOUND → "不存在这个用户"`。提交期间用 `isLoading` 换掉按钮（转圈），登录/注册共用一套提交逻辑（书 13.5）。

## 23.4 带 token 访问受保护资源

```dart
// ═══ 23.4 现在这样：Authorization 头；书当年是 ?token=xxx 拼在 URL 上 ═══
final resp = await http.get(
  Uri.parse('$base/profile'),
  headers: {'Authorization': 'Bearer ${user.token}'},
);
```

"当年如此/现在这样"：把 token 拼进 URL 会进服务器日志、浏览器历史、代理缓存——**凭据走头不走 URL** 是今天的铁律。示例的假服务器专门两个都查：无头 401，带合法 Bearer 才发资料。

## 23.5 持久化与自动登录

token 只存内存 = 每次重启都登录一遍（书 13.8 开头的痛点）。第 17 章的 `shared_preferences` 接上：

```dart
// ═══ 23.5 登录成功：token + 用户信息 + 过期时间点，三样一起落盘 ═══
await prefs.setString('token', user.token);
await prefs.setString('userId', user.id);
await prefs.setString('userEmail', user.email);
await prefs.setString('expiryTime', expiryTime.toIso8601String()); // 绝对时间点！

// 启动时 autoLogin()：有 token 且未过期 → 直接恢复会话
final expiry = DateTime.tryParse(prefs.getString('expiryTime') ?? '');
if (token == null || expiry == null || expiry.isBefore(DateTime.now())) {
  await _clearPrefs();   // 过期/残缺：清干净，回登录页
  return;
}
```

注意存的是**绝对时间点**而不是剩余秒数（书 13.11 的关键洞察）：重启后剩余时间要靠 `expiryTime - now` 现算，存相对值一重启就失真。

## 23.6 过期与自动登出

```dart
// ═══ 23.6 Timer 到点自动登出；重挂时用剩余秒数（书 13.11） ═══
void _armTimer(int seconds) {
  _expiryTimer?.cancel();
  _expiryTimer = Timer(Duration(seconds: seconds), logout);
}
// 自动登录路径：_armTimer(expiry.difference(now).inSeconds)
```

登出要做全套：`_expiryTimer?.cancel()` → 清 prefs（`remove` 精准删或 `clear` 全清，书 13.10）→ 置空用户 → 通知。**controller 的 dispose 也必须 cancel**——否则页面关了 Timer 还挂着（widget 测试会直接报 "Timer is still pending" 给你看，第 21 章的坑在这是正解）。

## 23.7 书的 rxdart 时刻：今天不需要了

书 13.12 当年引入 rxdart 的 `PublishSubject` 解决一个时序问题：`autoAuthenticate()` 是异步的，`initState` 发起后根组件可能**先于会话恢复**就 build 了，路由判断用了旧状态。书的解法是发布/订阅事件驱动 `setState`。

今天的答案你已经会了：**ChangeNotifier 本来就是发布订阅**（`notifyListeners` 即事件）。把认证状态放根级 InheritedNotifier，`autoLogin()` 完成后一通知，根路由自然翻页——第 09/22 章的原语直接覆盖 rxdart 在这里的职责。书 13.13 的性能顾虑（包住 MaterialApp 会不会重建太多）也一并消解：重建的是根的 builder，Flutter 的 diff 只提交真正的差异。

## 23.8 凭据安全红线

- **不存明文密码**：书当年把 `password` 塞进 UserModel 常驻内存——反面教材。登录完就忘掉密码，设备上只留 token。
- **token 过期短、可撤销**：`expiresIn` 别设一年；服务端能作废 token 才是安全边界。
- **更高安全需求上 secure storage**：`flutter_secure_storage`（Keychain/Keystore/Windows 凭据库）——非第一方，本教程不引入，知道边界在哪。
- **https**：明文 http 上的 token 等于广播。示例用 loopback 演示，真实接口必须 TLS。
- **token 不进日志、不进异常上报**：打印用户对象前先脱敏。

## 坑位清单

- **await 之后直接用 context**：登录是异步的，弹错误框前 `if (!mounted) return;`（第 07 章纪律的异步版）。
- **存剩余秒数当过期依据**：重启即失真——存绝对时间点，启动时现算差值。
- **登出忘 cancel Timer**：到点对着已注销会话再"登出"一次；widget 测试里是 "Timer is still pending"。
- **把凭据拼进 URL**：日志/历史/缓存全留痕——走 Authorization 头。
- **错误码直接怼给用户**：`EMAIL_EXISTS` 不是给人看的——网关层翻译成人话。
