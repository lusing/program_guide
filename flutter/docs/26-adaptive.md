# 26 · Cupertino 与平台自适应

> 对应示例：examples/26_adaptive/

## 26.1 解决什么问题

Material 是 Flutter 的跨平台默认脸，Android 用户零学习成本；但 iOS 用户对自己的原生控件有肌肉记忆——`Cupertino` 组件族是 Flutter 内置的 iOS 风格实现（无插件、不调原生，纯 Dart 画出来的高保真）。本章：怎么判断平台、Cupertino 族怎么用、以及"一套代码两种脸"的自适应组织法。

## 26.2 平台判断：一个入口

```dart
// ═══ 26.2 书 17.1 的判断路径（至今是推荐写法） ═══
final platform = Theme.of(context).platform;   // TargetPlatform.iOS / android / windows …
platform == TargetPlatform.iOS
    ? const CupertinoActivityIndicator()       // iOS 脸
    : const CircularProgressIndicator();       // Material 脸
```

两个入口分清楚：

| 入口 | 来源 | 可被覆写？ | 用途 |
|---|---|---|---|
| `Theme.of(context).platform` | 最近的 ThemeData | **是**——MaterialApp 的 `theme.platform`、外层 Theme 覆写 | **UI 分支**一律用它 |
| `defaultTargetPlatform` | foundation 库，真硬件平台 | 否 | 非 UI 的底层分支（日志、分析） |

为什么 UI 必须用前者：`Theme.of(context).platform` 可被覆写意味着**测试、设计稿评审、`flutter run` 按 `o` 键切换平台**都能影响它——你的自适应代码在这些场景下真实生效。`defaultTargetPlatform` 是硬件事实，测试里改不了。示例的"模拟平台"分段按钮就是改前者——Windows 上也能一键体验 iOS 脸。

### 千万别用 Platform.isIOS

`dart:io` 的 `Platform.isIOS` / `Platform.isAndroid` 在 **Flutter Web 上直接抛异常**（dart:io 在 Web 不存在）。任何 UI 分支用 `Theme.of(context).platform`，Web 安全且可覆写。

## 26.3 Cupertino 族巡礼

```dart
// ═══ 26.3 常用对照：Material ↔ Cupertino ═══
CupertinoButton(child:, onPressed:)                     // FilledButton
CupertinoActivityIndicator(radius: 14)                  // CircularProgressIndicator
CupertinoSwitch(value:, onChanged:)                     // Switch
CupertinoSlider(value:, onChanged:)                     // Slider
CupertinoTextField(placeholder:)                        // TextField
CupertinoListTile(title:, trailing:)                    // ListTile
showCupertinoDialog(context:, builder:)                 // showDialog
CupertinoPageScaffold(navigationBar: CupertinoNavigationBar(middle:))  // Scaffold/AppBar
```

两条纪律：

- **alert 类对话框成对换**——Material 页里弹 `CupertinoAlertDialog` 会按钮风格劈叉，按钮和对话框跟同一张脸（示例的 `adaptiveConfirm` 就是成对封装）。
- **Cupertino 族不读 Material 主题**——`CupertinoButton` 不读 ThemeData 的 colorScheme，颜色自己传（`CupertinoColors.activeBlue`）或上 `CupertinoTheme`。

### .adaptive 构造器：官方帮你分好叉的控件

一部分 Material 控件自带 `.adaptive` 命名构造器——内部自己判断平台，iOS/macOS 用 Cupertino 实现，其他平台用 Material：

```dart
Switch.adaptive(value: v, onChanged: (v) {})        // iOS 上自动是 CupertinoSwitch
Checkbox.adaptive(value: v, onChanged: (v) {})
Slider.adaptive(value: v, onChanged: (v) {})
```

有 `.adaptive` 的控件**优先用它**——比手写三元更短，且官方维护分叉逻辑。没有的（按钮、对话框、导航栏）才走 26.4 的 helper 层。

### CupertinoApp 与 CupertinoTheme

`CupertinoApp` 是 iOS 脸的 `MaterialApp` 对应物：内部用 `CupertinoThemeData`（不是 ThemeData）做系统级主题，配 `CupertinoPageScaffold` + `CupertinoNavigationBar` 组成 iOS 标准页面骨架。**什么时候用**：纯 iOS 应用（不上 Android）。**什么时候不用**：跨平台应用——跨平台应用以 MaterialApp 为根（MaterialApp 内部也能嵌 Cupertino 控件），只有"整页都是 iOS 脸"的子树才考虑局部 CupertinoTheme：

```dart
CupertinoTheme(
  data: const CupertinoThemeData(
    primaryColor: CupertinoColors.systemIndigo,
    brightness: Brightness.light,
  ),
  child: someCupertinoSubtree,
)
```

`CupertinoThemeData` 的关键字段：`primaryColor`（按钮/活动色）、`brightness`、`barBackgroundColor`（导航栏底色）、`scaffoldBackgroundColor`、`textTheme`。它只作用于 Cupertino 族控件——Material 控件在树里照常读 ThemeData，两套主题互不干扰。

## 26.4 自适应的组织法

书 17.1 在每个用点写三元表达式——三五个控件还行，规模一大就散装。收拢成一个 **adaptive helper 层**：

```dart
// ═══ 26.4 把平台分叉收进 helper：调用点只声明"我要一个加载条" ═══
Widget adaptiveSpinner(BuildContext context, {double radius = 12}) =>
    Theme.of(context).platform == TargetPlatform.iOS
        ? CupertinoActivityIndicator(radius: radius)
        : SizedBox(
            width: radius * 2, height: radius * 2,
            child: const CircularProgressIndicator(strokeWidth: 2));

Widget adaptiveSwitch(BuildContext context,
        {required bool value, required ValueChanged<bool> onChanged}) =>
    Theme.of(context).platform == TargetPlatform.iOS
        ? CupertinoSwitch(value: value, onChanged: onChanged)
        : Switch(value: value, onChanged: onChanged);
```

helper 层的收益：**调用点声明意图**（`adaptiveSpinner(context)`），平台分叉只写一次；改脸（比如全公司统一换加载条样式）只动 helper。示例的 `adaptiveConfirm` 更进一步——连"对话框 + 按钮"的组合也成对封装，调用点完全不感知平台。

主题也按平台分（书 17.2 的思路，写法升级——`primaryColor/accentColor` 已废，3.47 用 `colorSchemeSeed`）：

```dart
ThemeData themeFor(TargetPlatform platform) => platform == TargetPlatform.iOS
    ? ThemeData(colorSchemeSeed: CupertinoColors.systemIndigo, brightness: Brightness.dark)
    : ThemeData(colorSchemeSeed: const Color(0xFF00838F));
```

分寸感：**自适应不等于处处二分**——列表、文本、布局这类"中性"控件两边通用；只在**控件脸面**（按钮、开关、对话框、导航栏）分叉。真正的产品级方案看 `flutter_adaptive_scaffold`（生态包）或按平台拆页面级组件，本章的 helper 层够中小应用。

## 26.5 桌面与 Web 的脸

`TargetPlatform` 家族还有 windows/macos/linux——但 Flutter 没有为桌面平台准备专属组件族：桌面应用用 Material 脸是事实标准（第 18 章的桌面专题全部基于 Material）。macOS 想更"苹果"，做法与本章相同——混用 Cupertino 控件、按平台选主题；Web 默认 Material，理由同（无原生控件期待可依附）。

一个实用的细节：桌面窗口的**标题栏样式**（macOS 的 stoplight 按钮位置、Windows 的标题栏颜色）不在 Flutter 的 widget 体系内——由平台插件（window_manager、bitsdojo_window 等生态包）控制，第 18 章有展开。

## 26.6 测试自适应代码

自适应代码的测试要点：**用 Theme 覆写 platform，不依赖真宿主**。

```dart
testWidgets('iOS 脸显示 CupertinoActivityIndicator', (tester) async {
  await tester.pumpWidget(
    Theme(
      data: ThemeData(platform: TargetPlatform.iOS),
      child: const AdaptiveGalleryApp(),
    ),
  );
  expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
});
```

`Theme(data: ThemeData(platform: ...))` 覆写后，`Theme.of(context).platform` 在 widget 树里读到的是覆写值——测试在任何宿主（Windows CI、Linux 容器）都能跑。示例的测试文件就是这套：同一套 widget，覆写 iOS 断言 Cupertino 控件存在，覆写 Android 断言 Material 控件存在。

## 坑位清单

- **判断平台用了 `Platform.isIOS`**：dart:io 的 Platform 在 Web 上直接崩——UI 分支用 `Theme.of(context).platform`。
- **Material 页弹 Cupertino 对话框**：按钮脸和弹窗脸劈叉——成对换。
- **Cupertino 控件吃 Material 主题**：它不读 ThemeData——颜色显式传或上 CupertinoTheme。
- **处处三元表达式**：分叉收进 helper/主题函数，调用点声明意图而不是实现。
- **测试里硬等 iOS 控件**：用 Theme 覆写 `platform:` 再断言（示例的手法），别依赖真宿主。
- **有 .adaptive 还手写三元**：`Switch.adaptive` / `Checkbox.adaptive` / `Slider.adaptive` 官方分叉更可靠——优先用。
- **CupertinoApp 当跨平台根**：CupertinoApp 只服务纯 iOS 应用——跨平台应用以 MaterialApp 为根，Cupertino 控件嵌在内部。
---

上一章：[25 · 性能优化与质量债](25-performance.md) ｜ 下一章：[27 · 平台通道：MethodChannel 直通原生](27-platform-channel.md) ｜ 返回：[README](../README.md)
