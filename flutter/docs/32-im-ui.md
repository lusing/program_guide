# 32 · IM 聊天界面实战：拼一个完整应用

> 对应示例：examples/32_im/（聊天室：加载页 / 底部三 Tab / 会话列表 / 消息气泡聊天页 / A–Z 索引条通讯录 / 焦点搜索页 / 我的页）

## 32.1 解决什么问题

前面的章节都在练"单块肌肉"，本章把它们组装成一套完整应用——即时通信 App 的界面（书的综合案例，16 章整章的体量）。IM 界面是绝佳的毕业设计：**多页面路由、列表、气泡布局、手势、焦点管理、资产打包**全用上，而且每块都不难，难的是拼装时的条理。

书的做法值得偷师：**动笔前先拆布局**——把页面画成草图，拆成"导航栏 / 内容区 / 输入区"，每块想好用什么组件（Row/Column/ListView/Stack），再动手。本章每个页面都按这个流程走。

> **当年如此 → 现在这样**：书里的 flutter_im 用了两个三方包——`flutter_webview_plugin`（"好友动态"页内嵌网页）与 `date_format`（时间格式化）。本教程第一方铁律下：动态页直接裁掉（三 Tab 变消息/通讯录/我的），时间显示用 `time` 字段的字符串种子数据带过。主题也从 `ThemeData(primaryColor: Colors.green)`（M2 写法）换成 `ColorScheme.fromSeed`。

## 32.2 骨架：加载页与底部三 Tab

应用第一帧不一定是主界面。加载页（splash）亮 LOGO、干初始化活，到点整体替换：

```dart
// ═══ 32.2 ═══
class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) {                     // 2 秒里页面可能已被销毁
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AppShell()));
      }
    });
  }
```

`pushReplacement` 而不是 `push`：加载页不该留在返回栈里（按返回键回到加载页就死循环了）。`if (mounted)` 是异步回调碰 context 的护栏（07 章纪律）。

主骨架三 Tab 用 `NavigationBar`（M3 版 BottomNavigationBar）+ **`IndexedStack`**——切 Tab 时各页状态不丢（聊天草稿、滚动位置都在）：

```dart
// ═══ 32.2 ═══
IndexedStack(
  index: _tab,
  children: [ConversationsPage(), ContactsPage(...), ProfilePage()],
)
```

## 32.3 会话列表

标准的 `ListView.builder` + `ListTile` 拼装：`CircleAvatar`（首字 + 名字哈希色）当头像、`subtitle` 放摘要、`trailing` 是"时间 + 未读徽标"的纵排。徽标用 M3 的 `Badge.count`——十年前要自己拼红点 Container：

```dart
// ═══ 32.3 ═══
trailing: Column(
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    Text(conv.time, style: Theme.of(context).textTheme.bodySmall),
    if (conv.unread > 0) Badge.count(count: conv.unread),
  ],
),
```

点进聊天页走 `MaterialPageRoute` 直接传 `Contact` 对象（命名路由版在 main.dart 里用 `ModalRoute.of(context)!.settings.arguments` 取参——书 16.1.3 路由表的做法，两种都留了样例）。

## 32.4 聊天页：气泡、输入栏与回声机器人

布局拆分：`Column` 上段 `Expanded(ListView)` 管消息流，下段输入栏贴底（`SafeArea(top: false)` 防手机下巴）。

**气泡**是 Row 的对齐游戏：自己 `MainAxisAlignment.end` + 绿底白字，对方 `.start` + 灰底；头像永远贴气泡开口一侧（自己的气泡右下开口，对方的左下——`borderRadius` 的"零角"朝头像）：

```dart
// ═══ 32.4 ═══
borderRadius: BorderRadius.only(
  topLeft: const Radius.circular(12),
  topRight: const Radius.circular(12),
  bottomLeft: message.fromMe ? const Radius.circular(12) : Radius.zero,
  bottomRight: message.fromMe ? Radius.zero : const Radius.circular(12),
),
```

**输入栏**：`TextField` + `IconButton.filled`。发送键的解禁状态交给 `ValueListenableBuilder<TextEditingValue>` 监听控制器——输入为空时 `onPressed: null`（按钮灰掉），不用自己 setState 跟踪每次击键。

**回声机器人**（书里没有的灵魂补丁）：真实 IM 要接 socket，教学版用确定性 `EchoBot`——回复只取决于输入与轮次（`'收到「$text」（第 $n 轮）'`），测试能精确断言。发消息后 `addPostFrameCallback` 里 `animateTo(maxScrollExtent)`：**新气泡此刻还没布局完，等下一帧再滚才滚得到底**。

## 32.5 通讯录：字母分组与 A–Z 索引条

联系人按首字母分组（真实应用由拼音库算 `letter`，教学数据手工给）。列表项 = "组头（首个该字母联系人处画）+ 行"：

```dart
// ═══ 32.5 ═══
final isFirstOfGroup = i == 0 || contacts[i - 1].letter != c.letter;
Column(children: [
  if (isFirstOfGroup) SizedBox(height: _sectionHeight, child: 组头),
  SizedBox(height: _tileHeight, child: ListTile(...)),
])
```

**A–Z 索引条**是 IM 的招牌交互，书 16.8 只做到字母分组——拖拽跳组是本教程补的实现。三步：

1. **偏移表**：遍历数据，每组字母记下"组头到列表顶部的像素偏移"（组头 32 + 行 56 累加）。偏移表与布局常量是**合约**——改一处必须两处同步；
2. **手势换算**：`GestureDetector.onVerticalDragStart/Update` 拿到**本地坐标**，除以索引条高度、乘字母数、clamp 收口 → 字母下标。条的高度用条自己的 `LayoutBuilder` 现场取（别拿外层容器的约束凑合——顶部留白会让换算整体偏移）；
3. **跳转与反馈**：`jumpTo`（拖拽要"teleport"，animateTo 的滑动反而碍事）+ offset 对 `maxScrollExtent` clamp（列表不满一屏时偏移会越界）；当前字母在屏幕中央放大显示（72px 圆泡），松手 `onVerticalDragEnd` 收掉。

```dart
// ═══ 32.5 ═══
void _onIndexPan(Offset localPosition, BoxConstraints barBox) {
  final dy = localPosition.dy.clamp(0.0, barBox.maxHeight);
  final idx = (dy / barBox.maxHeight * _letters.length)
      .clamp(0, _letters.length - 1).toInt();
  final letter = _letters[idx];
  if (letter != _activeLetter) {
    setState(() => _activeLetter = letter);
    _scroll.jumpTo(_offsets[idx]
        .clamp(0.0, _scroll.position.maxScrollExtent));
  }
}
```

`HitTestBehavior.opaque` 让索引条的空隙也响应手指（好按）。索引条盖在列表右侧（`Stack` + `Positioned`），不与列表抢手势——命中测试从顶层开始，条命中后列表根本收不到该指针。

## 32.6 搜索页：一进来就待命

书 16.6 的招牌细节：搜索页打开的瞬间**键盘就该弹出来**。做法是 `FocusNode` + 首帧后 `requestFocus()`：

```dart
// ═══ 32.6 ═══
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) _focus.requestFocus();   // 焦点请求要等第一帧布局完成
  });
}
```

为什么不在 `TextField(autofocus: true)` 里做？也能——但显式 `FocusNode` 是可教可控的路径：焦点可以被抢走、可以被 `dispose`，测试里 `focusNode.hasFocus` 可以直接断言。过滤逻辑就是 `where((c) => c.name.contains(q))`，空结果显示"没有匹配的联系人"。

## 32.7 我的页与资产实战

我的页是 `ListView` + `ListTile` 的清单页。它的教学任务是**资产打包实战**（3.6 的落地）：logo 是带分辨率变体的 asset——`assets/logo/im_logo.png`（1x，64px）+ `assets/logo/2.0x/im_logo.png`（2x，128px）。pubspec 里声明**目录**（`- assets/logo/`）会连变体目录一起收。代码始终写 `Image.asset('assets/logo/im_logo.png')`，框架按设备像素比自动挑变体——高 DPI 屏不糊，低 DPI 设备不多掏内存。

## 32.8 示例工程的结构

```text
examples/32_im/
├── assets/logo/im_logo.png + 2.0x/     分辨率变体资产（pubspec 声明目录）
├── lib/
│   ├── main.dart        入口：路由表、加载页、AppShell 三 Tab、会话列表
│   ├── data.dart        Contact/Message/Conversation 模型 + 种子数据 + EchoBot
│   ├── chat_page.dart   气泡列表 + 输入栏 + 滚底
│   ├── contacts_page.dart  字母分组 + A–Z 索引条 + 搜索页（同文件小页）
│   └── profile_page.dart   我的页（asset logo）
└── test/widget_test.dart  8 条：跳转/徽标/气泡方向/回声/索引条/焦点/asset
```

确定性设计贯穿始终：种子数据全 const、EchoBot 按轮次回复、头像颜色名字哈希——全部可精确断言。

## 坑位清单

- **`find.byType(GestureDetector).last` 抓错人**：以为索引条是树里最后一个 GestureDetector，实际 AppBar 的搜索按钮（内部也有 GD）排得更靠后——**手势目标挂 Key**（`find.byKey(ValueKey('index_bar'))`）才是可维护写法。
- **索引条换算要用条自己的约束**：拿外层 `LayoutBuilder` 的约束算比例，顶部 8px 留白 + AppBar 会让映射整体偏移——条内再套一层 `LayoutBuilder` 现场取。
- **气泡字母断言撞名**：中央反馈泡、组头、索引条三处都是 'L'——`find.text('L')` 找到仨。用字号谓词（`byWidgetPredicate((w) => w is Text && w.style?.fontSize == 32)`）锁定大字泡。
- **`byTooltip` 命中的是 Tooltip 不是按钮**：`IconButton` 内部包着 `Tooltip`，取按钮本体要 `find.ancestor(of: byTooltip(...), matching: byType(IconButton))` 再 cast。
- **`enterText` 后不 pump 就 tap 发送**：控制器变值要过一帧，按钮才从禁用变可点——tap 落在旧帧的 `onPressed: null` 上，`_send` 根本没进。
- **回声没等到就断言**：`pumpAndSettle` 只在有排帧时推进，机器人 300ms 的 Timer 没到点就返回了——先显式 `pump(Duration(milliseconds: 300))` 拨到点，再 settle。
- **滚底要等下一帧**：`setState` 加完消息立刻 `animateTo(maxScrollExtent)` 拿到的是旧布局的 max——`addPostFrameCallback` 里滚。
- **`jumpTo` 的偏移会越界**：列表不满一屏时组偏移超过 `maxScrollExtent`，clamp 收口防断言。
- **书的三方包裁剪**：`flutter_webview_plugin`/`date_format` 都有更现代的第一方替代路径（裁掉页面 / 字符串种子数据），照书抄会引入废弃依赖。

---

上一章：[31 · Flutter 插件开发](31-plugin-dev.md) ｜ 返回：[README](../README.md)
