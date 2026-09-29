# Flutter 速查表

配合[教程](docs/01-overview.md)使用，条目按章号索引；主线 Flutter 3.47 / Material 3 / Windows 桌面。

## 命令速查

```bash
flutter create --project-name hello_app --platforms=windows 02_hello  # 目录可数字开头，包名不行
flutter run -d windows        # 运行；r=热重载 R=热重启 q=退出
flutter analyze               # 静态检查（本教程标准：零告警）
flutter test [--plain-name "…"]  # widget 测试（不需要真窗口）
flutter build windows --debug|--release   # AOT 构建；产物在 build\windows\x64\runner\
flutter pub get / add <pkg>
flutter clean                 # 慎用：清后首跑变慢
```

## 工程结构

```text
lib/main.dart   入口     test/  widget 测试
pubspec.yaml    依赖+资源（资源必须声明）   windows/  桌面宿主（一般不动）
```

不提交：`build/`、`.dart_tool/`、`windows/flutter/ephemeral/`、`.idea/`、`*.iml`、`pubspec.lock`（仓库全局忽略）。

## Widget 分类（03–06）

```dart
// 展示
Text(s, style: TextStyle(fontSize: 24))   Icon(Icons.add)   CircleAvatar(child:)
Card(child: ListTile(leading:, title:, subtitle:, trailing:))   Divider()

// 单子布局（04）
Padding(padding: EdgeInsets.all(12), child:)     SizedBox(height: 8)
Container(width:, padding:, decoration: BoxDecoration(
  color:, borderRadius: BorderRadius.circular(12),
  border: Border.all(color:, width:), boxShadow: [BoxShadow(blurRadius:, offset:)]))
Align(alignment: Alignment(0.9, 0), child:)   Center(child:)

// 多子布局（05）
Row/Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
           crossAxisAlignment: CrossAxisAlignment.center, children: [])
Expanded(flex: 2, child:)   Flexible(child:)       // 必须 vs 至多
Stack(children: [底层, Positioned(right: 8, top: 8, child:)])

// Scaffold 六插槽（06）
Scaffold(appBar:, body:, floatingActionButton:, drawer:, bottomNavigationBar:)

// 按钮（重要度递减）
FilledButton / FilledButton.tonal / OutlinedButton / TextButton / IconButton(tooltip:) / FloatingActionButton
// onPressed: null=禁用；() {}=可点无动作
```

## 交互（07）

```dart
InkWell(onTap:, onLongPress:, child:)      // Material 水波纹（默认选它）
GestureDetector(onDoubleTap:, onSecondaryTap:, child:)  // 原始手势
showDialog(context:, builder: (ctx) => AlertDialog(title:, actions: [...]))
final ok = await showDialog<bool>(...);    // pop(ctx, true) 带回返回值
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:))
showModalBottomSheet(context:, builder:)
// await 之后用 context 前必查 if (!context.mounted) return;
```

## 状态（08–09）

```dart
class XPage extends StatefulWidget { … createState() => _XPageState(); }
class _XPageState extends State<XPage> {
  final ctrl = TextEditingController();
  initState() { /* 一次性准备 */ }        dispose() { ctrl.dispose(); }
  build(context) { … setState(() => _x++); … }
}
// setState 纪律：回调必须同步；箭头函数别返回 Future

class Cart extends ChangeNotifier {        // 可监听状态
  void add() { count++; notifyListeners(); }
}
class CartScope extends InheritedNotifier<Cart> {   // 沿树广播
  CartScope({super.key, required super.child}) : super(notifier: Cart());
  static Cart of(ctx) => ctx.dependOnInheritedWidgetOfExactType<CartScope>()!.notifier!;
}
// 生态：provider（小）→ Riverpod（编译期安全）→ Bloc（大型）
```

## 导航（10）

```dart
final back = await Navigator.push<T>(ctx, MaterialPageRoute(builder: (_) => Page(arg: x)));
Navigator.pop(ctx, value);                 // 带返回值
Navigator.pushNamed(ctx, '/about');        // routes: {'/': …, '/about': …}
```

## 表单（11）

```dart
final key = GlobalKey<FormState>();
Form(key: key, child: ListView(children: [
  TextFormField(controller:, decoration: InputDecoration(labelText:),
    validator: (v) => (v == null || v.length < 6) ? '至少 6 位' : null),
]));
if (key.currentState!.validate()) { /* 提交 */ }
```

## 列表与滚动（12）

```dart
ListView.separated(itemCount:, itemBuilder: (c, i) => ListTile(…),
                   separatorBuilder: (_, _) => const Divider())
GridView.count(crossAxisCount: 4, children:)     // childAspectRatio 定形状
final ctrl = ScrollController();                 // animateTo/jumpTo + Scrollbar
// 懒构建：只有可见区+cacheExtent 内的 itemBuilder 被调用
```

## 网络与异步 UI（13–14）

```dart
final resp = await http.get(Uri.parse(url));     // pubspec: http
final items = (jsonDecode(resp.body) as List).map((e) => Item.fromJson(e)).toList();

late final Future<T> _future;                    // 存 State！别在 build 现造
FutureBuilder<T>(future: _future, builder: (c, snap) => switch (snap.connectionState) {
  ConnectionState.none => …, _ => const CircularProgressIndicator(),
  ConnectionState.done when snap.hasError => …, ConnectionState.done => …(snap.data),
});
StreamBuilder<T>(stream:, builder:)              // 同构；data 随事件更新
```

## 动画（15）

```dart
AnimatedContainer(duration:, curve: Curves.easeOutCubic, width: …)  // 改值即动
Hero(tag: 'x', child:)                            // 两页同 tag 飞行
late final ctl = AnimationController(vsync: this, duration:);      // with SingleTicker…
..addListener(() => setState(() {}));             // value: 0..1；dispose 必须
```

## 主题与响应式（16）

```dart
MaterialApp(theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
  darkTheme: …(brightness: Brightness.dark), themeMode: mode)
Theme.of(context).colorScheme.primary / surface / onSurface   // 语义色，不写死
LayoutBuilder(builder: (c, constraints) => constraints.maxWidth > 500 ? 宽 : 窄)
MediaQuery.of(context).size                        // 全局屏幕信息
```

## 持久化（17）

```dart
final prefs = await SharedPreferences.getInstance();
final v = prefs.getInt(k) ?? 0;  await prefs.setInt(k, v + 1);
// 测试：SharedPreferences.setMockInitialValues({...})
await File(p).writeAsString(jsonEncode(v));        // dart:io 文件 + JSON
// 选型：prefs（键值）→ JSON 文件 → sqflite（查询）
```

## 测试（19）

```dart
testWidgets('名', (tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.tap(find.text('加一')); await tester.pump();
  expect(find.text('1'), findsOneWidget);
});
// finders: text / byType / byIcon / byKey / widgetWithText
// pump=一帧；pumpAndSettle=到动画结束（定时器驱动的事件要手动 pump(Duration)）
// 边界注入假实现；真实 IO 放普通 test()
```

## 进阶篇（21–30）

```dart
// 调试（21）：flutter run 键位 r/R/q/d · p 构造线 · P 性能 overlay · i Inspector · v DevTools
debugPrint('长日志')                          // print 会截断；溢出错误从底部往上读
debugPaintSizeEnabled = true;                 // 视觉开关（改完须热重启 R）
tester.takeException()                        // 测试断言渲染错误（如 overflow）

// 集中状态（22）：手写 scoped_model 三零件
class M extends ChangeNotifier {}             // Model
ScopedModel<T>(model: T(), child: ...)        // 挂树（InheritedNotifier 封装）
ScopedModelDescendant<T>(builder: (c, w, m) => ...)  // 订阅；notifyListeners 重跑 builder
// 军规：私有状态 / getter 出口 List.of 拷贝 / 按实体不按索引 / 改完必通知
// mixin 合并：class Main extends Model with NewsPart, UserPart {}

// 认证（23）：token 一生
http.post(url, headers: {'Authorization': 'Bearer $token'})   // 凭据走头不走 URL
prefs.setString('expiryTime', t.toIso8601String())            // 存绝对时间点
Timer(Duration(seconds: left), logout)                        // 剩余秒数重挂；dispose 必 cancel

// 媒体（24）
final x = await ImagePicker().pickImage(      // 实例方法；null=用户取消
    source: ImageSource.gallery, maxWidth: 800, imageQuality: 70);
Image.file(File(x.path), errorBuilder: (_, _, _) => ...)      // XFile 三态预览
..files.add(await MultipartFile.fromPath('files', x.path))    // 第一方 http multipart

// 性能（25）
const MyCard()                                // identical 短路：父重建不波及
debugPrintRebuildDirtyWidgets = true;         // 找过度重建（测试结束前必须复位）
Image.network(u, cacheWidth: 200)             // 小框大图必限解码

// 自适应（26）
Theme.of(context).platform == TargetPlatform.iOS   // 可覆写，测试友好（勿用 dart:io Platform）
? const CupertinoActivityIndicator() : const CircularProgressIndicator()
// helper 层收拢分叉；对话框与按钮成对换脸；Cupertino 不读 ThemeData

// 平台通道（27）
const ch = MethodChannel('guide.flutter/battery');
try { await ch.invokeMethod<int>('getBatteryLevel'); }
  on PlatformException {} on MissingPluginException {}        // 三分支 try 必写
// Windows 宿主：flutter_window.cpp OnCreate 里 SetMethodCallHandler
// 测试：TestDefaultBinaryMessengerBinding...setMockMethodCallHandler(ch, handler)

// 发布（28）
keytool -genkeypair -keystore android/app/x.jks -alias x -validity 10000 ...
flutter build apk --release / appbundle        // versionCode 每次发版必递增
flutter build apk --release --obfuscate --split-debug-info=build/symbols
flutter symbolize -d build/symbols/... < stack.txt   // 崩溃栈还原，symbols 按版本归档
// key.properties + *.jks 绝不进 git；AAB 只进 Google Play

// 滚动进阶（29）
CustomScrollView(slivers: [SliverAppBar(pinned: true, ...),
  SliverPersistentHeader(delegate: ...),       // minExtent<=maxExtent；内容高给足
  SliverFixedExtentList(itemExtent: 64, ...),  // SliverList 没有 itemExtent！
])
NotificationListener<ScrollNotification>(onNotification: (n) {
  n.metrics.extentAfter < 300 && loadMore();   // 快到底自动翻页
  return false;                                // 继续冒泡
}, child: ...)
PopScope(canPop: false, onPopInvokedWithResult: (didPop, _) { ... })  // WillPopScope 已废
StreamController<T>.broadcast()                // 书的 event_bus 现代零依赖版；无缓冲
clock.now()                                    // 时间窗口逻辑可测（DateTime.now 是真实墙钟）
_scrollController.animateTo(0, duration: ..., curve: ...)   // 精控回顶

// 国际化（30）
localizationsDelegates: [AppL10n.delegate,
  GlobalMaterialLocalizations.delegate,        // 需 import flutter_localizations
  GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
supportedLocales: [Locale('zh'), Locale('en')], locale: _override,
class AppL10n { static of(ctx) => Localizations.of<AppL10n>(ctx, AppL10n)!; }
class D extends LocalizationsDelegate<AppL10n> {  // isSupported / load / shouldReload
  load(loc) => SynchronousFuture(AppL10n(loc)); }
Intl.plural(n, locale: loc.toString(), other: ..., one: ...)  // 不传 locale 按英文分叉
await initializeDateFormatting('zh', null)     // DateFormat 非默认 locale 必先初始化
```
