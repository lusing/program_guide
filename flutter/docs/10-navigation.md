# 10 · 导航与路由：页面的栈

> 对应示例：examples/10_navigation/

## 10.1 解决什么问题

应用总要多页面。Flutter 的 Navigator 是一个**栈**——push 进新页、pop 弹回旧页，没有"全局页面注册中心"这种东西。这个模型简单到一句话，但有两个必须养成的配套习惯：**页面间传数据走构造参数、页面回传走 pop 的返回值**。

```dart
  // ═══ 10.1 push 一个页面并 await 它的返回值 ═══
  Future<void> _openDetail() async {
    final picked = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const DetailPage(item: 7)),
    );
    if (!mounted) return;
    setState(() => _result = picked ?? '直接返回（无值）');
  }
```

三个要点一次看清：`MaterialPageRoute` 的 builder **惰性**建页——push 的那一刻才调用 builder，不是先建好等着；**push 返回 Future**——await 它拿到新页 pop 回来的值；await 之后用 context/state 前的 `if (!mounted) return` 是纪律（用户可能已经离开这页）。

### Navigator.push 的泛型：类型安全的返回值

注意 `Navigator.push<String>` 的 `<String>`——它声明"这个页面 pop 时会还给你一个 String"。泛型参数顺着 Future 传回来：`push<String>` 的返回类型就是 `Future<String?>`。如果你写 `Navigator.push(context, ...)` 不指定泛型，返回值就是 `Future<dynamic>`——失去类型检查，pop 时传错类型编译器不拦。养成习惯：**push 永远带泛型**，与 pop 的返回值类型对应。

## 10.2 pop 带回返回值；参数走构造

```dart
            FilledButton(
              // ═══ 10.1（续）pop 带回返回值 ═══
              onPressed: () => Navigator.pop(context, '选中了 #$item'),
              child: const Text('选定并返回'),
            ),
```

```dart
// ═══ 10.2 页面参数：构造传参（不可变配置的一部分） ═══
class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.item});

  final int item;
```

数据进页面 = **构造参数**（Widget 本来就是不可变配置，参数即数据，第 03 章哲学的应用）；数据出页面 = **pop 的第二个参数**。用户点标题栏返回/ESC 时 pop 没带值，Future 得到 null——所以 `picked ?? '直接返回'` 兜底。复杂对象（整条 Note）同样直接传引用，第 20 章实战就传 Note。

### pop 的返回值类型必须与 push 的泛型匹配

`Navigator.pop<String>(context, '选中了 #$item')` 里的 `<String>` 可以省略（编译器从上下文推断），但**传入的值的类型**必须与 `push<T>` 的 `T` 一致或为其子类型。运行时类型不匹配不会崩溃（pop 的 result 是 `Object?`），但 await 出来做强转时会抛 `TypeError`——这是"类型安全只到编译期"的一个缺口，靠团队约定堵上：push 时声明泛型，pop 时传对应类型。

## 10.3 MaterialPageRoute：不只是 builder

`MaterialPageRoute` 的完整构造参数（api.flutter.dev 3.47）：

```dart
MaterialPageRoute<T>(
  required WidgetBuilder builder,       // 惰性建页函数
  RouteSettings? settings,              // 路由元数据（名称 + 参数）
  bool maintainState = true,            // 下层路由是否保留在内存
  bool fullscreenDialog = false,        // 是否以"模态对话框"样式进入
  bool allowSnapshotting = true,        // 是否允许路由快照（性能优化）
  bool barrierDismissible = false,      // 点外部是否可关闭（fullscreenDialog 时有效）
)
```

四个值得知道的参数：

- **`settings`**：给路由挂元数据。即使不用命名路由，也可以 `MaterialPageRoute(builder: ..., settings: RouteSettings(name: '/detail', arguments: 7))`——名字进路由表，方便 analytics 和调试。
- **`maintainState: false`**：下层页面不再保留在内存。适用于"全屏详情看完即弃"的场景——下层列表释放掉，省内存。代价是返回时下层要重新 build。
- **`fullscreenDialog: true`**：新页从底部滑入且右上角自动带关闭按钮（iOS 风格），语义是"这是一个任务模态，不是导航层级"。
- **`barrierDismissible`**：配合 fullscreenDialog，点页面外部是否关闭。

### RouteSettings：名字与参数

```dart
const RouteSettings({String? name, Object? arguments})
```

`name` 是路由的字符串标识（进 `route.settings.name`，NavigatorObserver 和 analytics 插件读它）；`arguments` 是挂在路由上的任意对象——**命名路由传参的官方通道**（见 10.5）。

## 10.4 导航模式三剑客：replace / removeUntil / popUntil

栈式导航不止 push/pop。三个高频模式：

### pushReplacement：换顶不换栈

```dart
// 登录成功 → 主页替换登录页（按返回不再见到登录页）
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => const HomePage()),
);
```

`pushReplacement` 把栈顶的旧路由**替换**为新路由：旧页面被销毁（走 dispose），新页面占据栈顶。典型场景：**登录页 → 主页**、**启动页 → 首页**——用户按返回键不应该回到登录页/启动页。

### pushAndRemoveUntil：清栈到某处

```dart
// 退出登录 → 回登录页，把中间所有页面清掉
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (_) => const LoginPage()),
  (route) => false,  // 对所有已有路由返回 false = 全部移除
);
```

`pushAndRemoveUntil` 的第二个参数是一个谓词 `(Route<dynamic>) -> bool`：对每个栈中已有路由问"保留吗"，返回 false 就移除。`(route) => false` 是"全清"——新页面成为栈底唯一路由。想保留栈底首页、清掉中间详情页：`(route) => route.isFirst`。

### popUntil：一路弹回

```dart
Navigator.popUntil(context, (route) => route.isFirst);
```

`popUntil` 连续 pop 直到谓词为 true。`route.isFirst` 是"栈底路由"（通常就是首页）。与 `pushAndRemoveUntil` 的区别：popUntil 不引入新页面，只是把中间的都弹掉。

三个模式一张表：

| 模式 | 效果 | 典型场景 |
|---|---|---|
| `push` | 栈顶加一页 | 打开详情 |
| `pushReplacement` | 栈顶换一页 | 登录 → 主页 |
| `pushAndRemoveUntil` | 加一页 + 清掉若干旧页 | 退出登录、支付完成回首页 |
| `popUntil` | 弹掉若干页 | 取消深层流程回首页 |

## 10.5 命名路由：字符串寻址

```dart
      // ═══ 10.3 命名路由：字符串寻址，集中登记 ═══
      routes: {
        '/': (context) => const HomePage(),
        '/about': (context) => const AboutPage(),
      },
```

```dart
            onTap: () => Navigator.pushNamed(context, '/about'),
```

把页面登记到 MaterialApp 的 `routes` 表，跳转用 `pushNamed(context, '/about')`。优点：路径集中管理、页面代码不互相 import；缺点：**传参要另走** `settings: RouteSettings(arguments: ...)` 或 `onGenerateRoute` 按名分发。

### 命名路由传参：arguments

```dart
// 发送端：arguments 挂任意对象
Navigator.pushNamed(
  context,
  '/detail',
  arguments: 7,
);

// 接收端：从 ModalRoute.of(context)!.settings.arguments 取
class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final item = ModalRoute.of(context)!.settings.arguments as int;
    return Scaffold(
      appBar: AppBar(title: Text('详情 #$item')),
      // ...
    );
  }
}
```

`arguments` 的类型是 `Object?`，取回来要 cast——**没有编译期类型安全**。这是命名路由最大的代价：传参爽了，类型检查没了。经验法则：

- **参数是简单值、路由多、不需要深链**：命名路由 + arguments 够用
- **参数是复杂对象、想要类型安全**：直接 `MaterialPageRoute(builder: (_) => DetailPage(note: note))`——构造传参永远类型安全
- **要深链 / URL 同步 / 浏览器后退按钮**：上 Router（Navigator 2.0，见 10.9）

### onGenerateRoute：动态路由

`routes` 表是静态的——所有路由在编译期就登记完。要按名字动态建路由（比如 `/user/:id` 这种带参数的路径），用 `onGenerateRoute`：

```dart
MaterialApp(
  onGenerateRoute: (settings) {
    if (settings.name == '/user') {
      final id = settings.arguments as int;
      return MaterialPageRoute(
        builder: (_) => UserPage(id: id),
        settings: settings,
      );
    }
    return null;  // 返回 null 交给 onUnknownRoute 处理
  },
)
```

`onGenerateRoute` 收到 `RouteSettings`（含 name 和 arguments），返回一个 Route 或 null。返回 null 时 MaterialApp 走 `onUnknownRoute`（默认是一个红屏错误页，可以换成友好的 404 页）。

## 10.6 maybePop / canPop：有条件的返回

`Navigator.pop(context)` 是无条件的——栈里有东西就弹。两个"先问再弹"的 API：

```dart
// canPop：查询当前能否 pop（栈里是否有可弹的路由）
final canGoBack = Navigator.canPop(context);

// maybePop：能弹才弹，返回 Future<bool> 告知是否真的弹了
final didPop = await Navigator.maybePop(context);
```

`maybePop` 的用途：**系统返回手势/按钮的统一处理**。Android 的返回键、iOS 的侧滑返回、桌面的 Alt+Left，最终都汇聚到 `maybePop`。如果你要拦截返回（比如表单未保存时确认），不拦 `maybePop` 本身，而是用 `PopScope`（下一节）。

## 10.7 PopScope：拦截返回

3.47 的推荐写法（`onPopInvoked` 已 deprecated，用 `onPopInvokedWithResult`）：

```dart
PopScope(
  canPop: false,  // 硬拦截：不弹
  onPopInvokedWithResult: (didPop, result) {
    if (!didPop) {
      // canPop 为 false 时 didPop 恒为 false——这里弹确认框
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('放弃编辑？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),  // 关对话框
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);   // 关对话框
                Navigator.pop(context);   // 关页面
              },
              child: const Text('放弃'),
            ),
          ],
        ),
      );
    }
  },
  child: Scaffold(/* ... */),
)
```

两个回调参数的分工：

- **`canPop: bool`**：同步硬开关。false = 路由完全不弹（系统返回键、AppBar 返回按钮、pop 调用全部被拦）。
- **`onPopInvokedWithResult: (bool didPop, T? result)`**：每次"有 pop 意图"时调用。`didPop` 告诉你这次意图是否真的弹了——canPop 为 true 时 didPop 为 true（已经弹了，你只能做清理）；canPop 为 false 时 didPop 为 false（被拦下了，你可以弹确认框）。

常见模式：**`canPop: false` + `onPopInvokedWithResult` 里弹确认**——用户点返回时不立刻走，而是问"确定放弃吗？"。确认后手动 `Navigator.pop` 两次（关对话框 + 关页面）。

注意 PopScope 是**声明式**的：`canPop` 的值应该随状态变。比如"表单有未保存修改时才拦"：

```dart
PopScope(
  canPop: !_isDirty,  // 干净时直接放行，脏时拦截
  onPopInvokedWithResult: (didPop, _) {
    if (!didPop) _showDiscardDialog();
  },
  child: /* ... */,
)
```

## 10.8 对话框也是路由

`showDialog`、`showModalBottomSheet`、`showDatePicker` 的底层都是 `Navigator.push`——对话框是**半透明路由**压在栈顶。这个认知解释了两个现象：

1. **对话框的 pop 与页面的 pop 是同一个栈**——在对话框里 `Navigator.pop(context)` 弹的是对话框，不是页面（对话框离栈顶更近）。但如果对话框已经关了再 pop，弹的就是页面——"连点两次确认"的 bug 就是这么来的（坑位清单里有）。
2. **`Navigator.pop(context, value)` 可以从对话框返回值**——`showDialog<T>` 同样返回 `Future<T?>`：

```dart
final confirmed = await showDialog<bool>(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text('删除这条记录？'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('删除'),
      ),
    ],
  ),
);
if (confirmed == true) _delete();
```

`showDialog<bool>` 的泛型、pop 的 bool 值、await 出来的 `confirmed`——整条链类型安全。`showDialog` 的 `barrierDismissible` 默认 true（点外部关闭），此时 Future 得到 null——所以判断用 `confirmed == true` 而不是 `confirmed!`。

## 10.9 Navigator 2.0 / Router：什么时候上

Navigator 1.0（本章讲的 push/pop 系列）是**命令式**导航：代码说"去那页"，框架就去。简单直接，但有两个结构性短板：

- **状态与 URL 不同步**：浏览器地址栏不反映当前页面（Flutter Web 上按浏览器后退按钮行为不对）
- **深层链接要手写**：从通知点开 `/orders/42/detail` 要在启动代码里手动 push 三层

Navigator 2.0 的 `Router` 是**声明式**导航：你维护一个"当前路由状态"对象（比如 `AppState.currentPage`），`RouterDelegate` 把它翻译成 Navigator 的页面列表；反过来 Navigator 的变化也回流到状态。URL、浏览器历史、深层链接由 `RouteInformationParser` 和 `BackButtonDispatcher` 自动同步。

```dart
MaterialApp.router(
  routerDelegate: myRouterDelegate,        // 状态 → 页面列表
  routeInformationParser: myRouteParser,   // URL 字符串 → 状态
  backButtonDispatcher: myBackDispatcher,  // 系统返回键 → 状态回退
)
```

**什么时候用 Router**：Flutter Web 应用（URL 同步是刚需）、需要深层链接的移动端、企业级应用的路由状态机。**什么时候不用**：纯桌面/移动应用、页面层级简单（栈式导航够用）——Router 的复杂度成本（多写两个 delegate 类）在简单场景不划算。本教程的示例工程（记事本、IM）都属于后者，所以全程 Navigator 1.0。

## 10.10 嵌套 Navigator：多标签各自成栈

`Navigator` 本身就是一个 Widget——可以在页面里再嵌一个 Navigator，让某个子树有独立的导航栈。典型场景：**底部 Tab 各自维护浏览历史**（微信：通讯录 → 联系人详情，按返回回通讯录，不影响"我"标签）。

```dart
// 每个 Tab 一个嵌套 Navigator，key 用来从外部调它的静态方法
final _tabANavigatorKey = GlobalKey<NavigatorState>();

Scaffold(
  body: IndexedStack(
    index: _currentTab,
    children: [
      Navigator(
        key: _tabANavigatorKey,
        onGenerateRoute: (_) => MaterialPageRoute(
          builder: (_) => const TabAHomePage(),
        ),
      ),
      const TabBPage(),
    ],
  ),
  bottomNavigationBar: /* ... */,
)
```

嵌套 Navigator 的关键心智模型：**`Navigator.of(context)` 找的是最近的 Navigator**——内层页面里的 push/pop 都作用于内层栈；要从内层页面跳外层（比如 Tab 内详情跳全局设置页），用 `Navigator.of(context, rootNavigator: true)`。

## 10.11 NavigatorObserver：路由的"行车记录仪"

`NavigatorObserver` 是一组路由生命周期回调（`didPush`、`didPop`、`didReplace`、`didRemove`），挂在 MaterialApp 上：

```dart
MaterialApp(
  navigatorObservers: [MyAnalyticsObserver()],
  // ...
)

class MyAnalyticsObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name ?? route.runtimeType.toString();
    Analytics.track('page_view', {'page': name});
  }
}
```

每次 push/pop 都经过 observer——页面埋点、路由日志、权限检查都挂这里。Firebase Analytics 的 `FirebaseAnalyticsObserver` 就是现成的实现。

## 10.12 restorablePush：进程被杀后的路由恢复

Android/iOS 会在内存紧张时杀后台应用，用户切回来期望"还在原来那页"。`restorablePush` 系列（`restorablePush`、`restorablePushNamed`、`restorablePushReplacement` 等）让路由状态参与系统状态保存/恢复：

```dart
Navigator.restorablePush(
  context,
  (context, arguments) => MaterialPageRoute(
    builder: (_) => DetailPage(item: arguments as int),
  ),
  arguments: 7,
);
```

与 `push` 的区别：builder 变成**带 arguments 的函数**（因为恢复时要凭 arguments 重建路由），路由的 arguments 会被序列化保存。桌面（Windows/macOS/Linux）没有"系统杀进程"的概念，这个 API 主要是移动端的事——知道它存在即可。

## 10.13 桌面小注

路由的 Material 转场动画在桌面同样生效（桌面口味上你以后可能想换更克制的 FadeUpwards）；Windows 上 Alt+Left 能触发 pop（返回栈），写桌面应用时留意"用户可能用键盘导航回去"。`PopScope` 在桌面同样拦截 Alt+Left 和窗口关闭（macOS 的红点）——表单页别忘加。

## 坑位清单

- **await 后忘 mounted 检查**：lint（use_build_context_synchronously）会拦——本教程所有示例都带 `if (!mounted) return;` 模板。
- **pop 两次**：一次关对话框一次关页面——连点确认按钮时容易叠（对话框的 pop 与页面 pop 是同一个栈，见 10.8）。
- **routes 表必须有 '/'**：没有首页直接红屏。
- **命名路由 arguments 忘记 cast**：`settings.arguments` 是 `Object?`，取回必须 `as T`——cast 前判空，否则类型错误直接抛。
- **PopScope 的 canPop 写成常量 true**：那样 onPopInvokedWithResult 里 didPop 恒为 true，拦截逻辑永远不会跑——canPop 要随状态变（`_isDirty` 那种）。
- **嵌套 Navigator 里找错栈**：内层页面的 `Navigator.of(context)` 是内层栈——要跳外层用 `rootNavigator: true`。
- **pushAndRemoveUntil 的谓词写反**：`(route) => false` 是全清，`route.isFirst` 是保留栈底——写反要么清不掉、要么把新页面也清了（谓词只作用于**已有**路由，不影响新推入的）。
- **restorablePush 的 builder 闭包捕获外部状态**：恢复时 builder 会被重新调用，闭包里捕获的 State 可能已失效——一切需要的数据走 arguments，别走闭包捕获。
---

上一章：[09 · 状态提升与共享：数据放哪](09-state-sharing.md) ｜ 下一章：[11 · 表单：校验与提交](11-forms.md) ｜ 返回：[README](../README.md)
