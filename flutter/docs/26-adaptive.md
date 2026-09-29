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

两个入口分清楚：`Theme.of(context).platform` **可被覆盖**（MaterialApp 的 theme.platform 或外层 Theme 覆写）——设计稿评审、测试、`flutter run` 按 `o` 键模拟平台，都走它；`defaultTargetPlatform`（foundation 库）是**真硬件平台**，非 UI 的底层分支用。示例的"模拟平台"分段按钮就是改前者——Windows 上也能一键体验 iOS 脸。

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

两条纪律：**alert 类对话框成对换**——Material 页里弹 `CupertinoAlertDialog` 会按钮风格劈叉，按钮和对话框跟同一张脸；**Cupertino 族不读 Material 主题**——颜色自己传（`CupertinoColors.activeBlue`、`CupertinoTheme`），包 `CupertinoApp` 才有系统级 Cupertino 主题。

## 26.4 自适应的组织法

书 17.1 在每个用点写三元表达式——三五个控件还行，规模一大就散装。收拢成一个 **adaptive helper 层**：

```dart
// ═══ 26.4 把平台分叉收进 helper：调用点只声明"我要一个加载条" ═══
Widget adaptiveSpinner(BuildContext context, {double radius = 12}) =>
    Theme.of(context).platform == TargetPlatform.iOS
        ? CupertinoActivityIndicator(radius: radius)
        : const SizedBox(
            width: radius * 2, height: radius * 2,
            child: CircularProgressIndicator(strokeWidth: 2));

Widget adaptiveSwitch(BuildContext context,
        {required bool value, required ValueChanged<bool> onChanged}) =>
    Theme.of(context).platform == TargetPlatform.iOS
        ? CupertinoSwitch(value: value, onChanged: onChanged)
        : Switch(value: value, onChanged: onChanged);
```

主题也按平台分（书 17.2 的思路，写法升级——`primaryColor/accentColor` 已废，3.47 用 `colorSchemeSeed`）：

```dart
ThemeData themeFor(TargetPlatform platform) => platform == TargetPlatform.iOS
    ? ThemeData(colorSchemeSeed: CupertinoColors.systemIndigo, brightness: Brightness.dark)
    : ThemeData(colorSchemeSeed: const Color(0xFF00838F));
```

分寸感：**自适应不等于处处二分**——列表、文本、布局这类"中性"控件两边通用；只在**控件脸面**（按钮、开关、对话框、导航栏）分叉。真正的产品级方案看 `flutter_adaptive_scaffold`（生态包）或按平台拆页面级组件，本章的 helper 层够中小应用。

## 26.5 桌面与 Web 的脸

`TargetPlatform` 家族还有 windows/macos/linux——但 Flutter 没有为桌面平台准备专属组件族：桌面应用用 Material 脸是事实标准（第 18 章的桌面专题全部基于 Material）。macOS 想更"苹果"，做法与本章相同——混用 Cupertino 控件、按平台选主题；Web 默认 Material，理由同（无原生控件期待可依附）。

## 坑位清单

- **判断平台用了 `Platform.isIOS`**：dart:io 的 Platform 在 Web 上直接崩——UI 分支用 `Theme.of(context).platform`。
- **Material 页弹 Cupertino 对话框**：按钮脸和弹窗脸劈叉——成对换。
- **Cupertino 控件吃 Material 主题**：它不读 ThemeData——颜色显式传或上 CupertinoTheme。
- **处处三元表达式**：分叉收进 helper/主题函数，调用点声明意图而不是实现。
- **测试里硬等 iOS 控件**：用 Theme 覆写 `platform:` 再断言（示例的手法），别依赖真宿主。
