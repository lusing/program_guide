# 18 · 桌面专题：Windows 的一等公民

> 对应示例：examples/18_desktop/

## 18.1 解决什么问题

前面 17 章的组件在手机和桌面上都成立，但桌面用户有一套自己的**肌肉记忆**：顶部菜单栏、可见的滚动条、可选中的文本、键盘直达。本章补齐这些"桌面标配"，并把 Windows 的构建与发布讲清楚。

桌面与移动的差异清单（写桌面应用前过一遍）：

| 维度 | 桌面预期 |
|---|---|
| 窗口 | 用户随便拉伸 → 响应式是刚需（16 章） |
| 指针 | 鼠标：悬停态、右键、滚轮；命中区域可以更紧凑 |
| 键盘 | Tab 焦点流转、快捷键（shortcuts/actions） |
| 文本 | 期望可选中复制 |

## 18.2 MenuBar：顶部菜单栏

```dart
          // ═══ 18.1 MenuBar：桌面级菜单栏（顶部） ═══
          MenuBar(
            children: [
              SubmenuButton(
                menuChildren: [
                  MenuItemButton(
                    onPressed: () => setState(() => _selected = '新建'),
                    child: const Text('新建'),
                  ),
                  MenuItemButton(
                    onPressed: () => setState(() => _selected = '退出'),
                    child: const Text('退出'),
                  ),
                ],
                child: const Text('文件'),
              ),
            ],
          ),
```

Material 3 的桌面菜单三件套：`MenuBar`（栏）→ `SubmenuButton`（"文件"这类可展开项）→ `MenuItemButton`（真命令）。键盘可达（方向键/首字母）免费获得——这是选它而不是自造 Row+PopupMenu 的理由。惯例：菜单触发命令而不是直接干活（命令再走快捷键系统）。

### MenuItemButton 的常用参数

| 参数 | 用途 |
|---|---|
| `onPressed` | 点击回调（null = 禁用态，灰色） |
| `shortcut` | 右侧显示快捷键提示（`const SingleActivator(LogicalKeyboardKey.keyN, control: true)` 显示 "Ctrl+N"）——**只是显示**，真正绑定在 Shortcuts 层做（18.5） |
| `leadingIcon` / `trailingIcon` | 前后图标（新建=文档+，退出=门） |
| `closeOnActivate` | 点击后是否收起菜单（子菜单里选完通常收起） |

菜单项的禁用态直接传 `onPressed: null`——Material 自动灰显，无需手动改颜色。

### PlatformMenuBar：macOS 的原生菜单栏

`MenuBar` 是 Flutter 自绘的菜单栏（Windows/Linux 适用）；macOS 的应用菜单栏在**屏幕顶部**且由系统渲染——`PlatformMenuBar` 走原生通道把菜单交给 macOS：

```dart
PlatformMenuBar(
  menus: [
    PlatformMenu(
      label: 'File',
      menus: [
        PlatformMenuItem(
          label: 'Quit',
          onSelected: () => exit(0),
        ),
      ],
    ),
  ],
  child: MyApp(),
)
```

跨平台应用的标准做法：`PlatformMenuBar` 包外层（macOS 生效），内部 `Scaffold` 里条件渲染 `MenuBar`（Windows/Linux 生效）——`PlatformMenuBar` 在非 macOS 上是透明的（child 直接显示），不会重复出菜单。

## 18.3 SelectionArea 与 Scrollbar：两条桌面铁律

```dart
          Expanded(
            // ═══ 18.3 Scrollbar + 滚轮：桌面用户 expect 可见滚动条 ═══
            child: Scrollbar(
              child: ListView.builder(
                itemCount: 40,
                itemBuilder: (context, i) => ListTile(
                  dense: true,
                  title: Text('条目 $i'),
                ),
              ),
            ),
          ),
          // ═══ 18.2 SelectionArea：让文本可选中复制（桌面标配） ═══
          SelectionArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text('菜单选择：$_selected（这段文字可以选中复制）'),
            ),
          ),
```

- **`SelectionArea`**：包住的区域里 Text 变为可选可复制（默认不可选——第 02 章的坑在这是正解）。整页包或局部包都行——包整页最省事（`MaterialApp` 的 `builder` 里套一层，全局生效）。
- **`Scrollbar`**：桌面滚动区应有可见滚动条；与 ScrollController 联动（16 章 ListView 处传 `controller:` 同款），滚轮支持原生自带。

### Scrollbar 与 ScrollController 的显式联动

示例的 `Scrollbar` 没传 controller——框架自动找 ListView 的 PrimaryScrollController，够用。要编程控制滚动位置（"回顶部"按钮）时显式建 controller 两边挂：

```dart
final _scrollCtrl = ScrollController();

// build:
Scrollbar(
  controller: _scrollCtrl,
  child: ListView.builder(
    controller: _scrollCtrl,   // 两边同一个
    // ...
  ),
)

// 回顶部：
_scrollCtrl.animateTo(0, duration: 300ms, curve: Curves.easeOut);
```

Scrollbar 和 ListView 用**同一个** controller——两个 controller 各管各的，滚动条不跟内容走。

## 18.4 构建与发布

```bash
flutter build windows --debug     # 开发/自测（带热重载符号，体积大）
flutter build windows --release   # 发布（AOT，体积小启动快）
```

- 产物在 `build\windows\x64\runner\Release\`，exe + dll 整目录拷走才能跑（缺 dll 是经典翻车）。
- 版本号在 pubspec 的 `version:`；图标与窗口标题在 `windows/runner/`（main.cpp 的 `ShowWindow` 控制初始尺寸，Runner.rc 控图标）——动 C++ 侧后要完全重跑。
- 正式分发可打 msix（`msix` 生态包）或做安装器；小工具直接 zip 整目录也常见。
- debug 与 release **行为有差**：断言只在 debug 生效、性能差距明显——验收以 release 为准（与 [Dart 教程·第 01 章](../dart/docs/01-overview.md) 的 JIT/AOT 对应）。

### 窗口控制：生态包的领地

Flutter 核心没有"改窗口标题/尺寸/位置"的 API——窗口由平台宿主（windows/runner 的 Win32 代码）管理。运行期控制窗口（最大化、最小化到托盘、自定义标题栏）用生态包：

| 包 | 用途 |
|---|---|
| `window_manager` | 跨平台窗口控制（尺寸/位置/最大化/最小化/标题） |
| `bitsdojo_window` | 自定义标题栏（无边框窗口 + 自绘最小化/最大化/关闭按钮） |
| `tray_manager` | 系统托盘图标 |

pubspec 里加依赖、main() 里初始化即可——机制是平台通道（第 27 章），这些包把通道封装好了。

## 18.5 鼠标与键盘进阶

### MouseRegion：悬停态

`MouseRegion` 跟踪鼠标进出与移动：

```dart
MouseRegion(
  onEnter: (_) => setState(() => _hovered = true),
  onExit: (_) => setState(() => _hovered = false),
  cursor: SystemMouseCursors.click,  // 悬停变手型
  child: Container(
    color: _hovered ? Colors.blue.shade50 : Colors.transparent,
    child: /* ... */,
  ),
)
```

`cursor` 参数控制鼠标图标（`SystemMouseCursors.click/pointer/text/forbidden` 等）——可点击的元素悬停应变手型，桌面用户的预期。许多 Material 控件（Button、InkWell）自带 cursor 切换，自绘的可点击区域要手动加。

### 右键：onSecondaryTap

`GestureDetector` 的 `onSecondaryTap`（鼠标右键）和 `onTertiaryTap`（中键）：

```dart
GestureDetector(
  onSecondaryTapUp: (details) => _showContextMenu(details.globalPosition),
  child: /* ... */,
)
```

桌面应用的右键菜单是标配——文件列表、消息气泡都该有。`onSecondaryTapUp` 的 `details.globalPosition` 是鼠标位置，菜单从这里弹出。

### Shortcuts + Actions + Intent：快捷键体系

三件套的分工：

- **`ShortcutActivator`**：定义按键组合（`SingleActivator(LogicalKeyboardKey.keyN, control: true)` = Ctrl+N；`CharacterActivator('?')` = 按 ? 键）
- **`Intent`**：按键要触发的"意图"（一个标记类）
- **`Actions`**：把 Intent 映射到具体回调

```dart
// 1. 定义 Intent（空类，只是标记）
class NewDocumentIntent extends Intent {
  const NewDocumentIntent();
}

// 2. Shortcuts 绑定按键 → Intent
Shortcuts(
  shortcuts: const {
    SingleActivator(LogicalKeyboardKey.keyN, control: true): NewDocumentIntent(),
  },
  child: Actions(
    actions: {
      NewDocumentIntent: CallbackAction<NewDocumentIntent>(
        onInvoke: (intent) {
          _createDocument();
          return null;
        },
      ),
    },
    child: Focus(autofocus: true, child: MyAppBody()),  // 焦点在树里快捷键才生效
  ),
)
```

为什么要三层而不是"按键直接调函数"：**Intent 是抽象层**——菜单点击（`MenuItemButton.onPressed`）和快捷键（`Shortcuts`）触发同一个 Intent，业务回调只写一次。加新快捷键 = 加一个 SingleActivator 映射，业务代码不动。`Focus(autofocus: true)` 不可少——Shortcuts 只在焦点子树内监听按键。

## 18.6 桌面应用的响应式义务

窗口可拉伸 = 布局必须在任意宽度下成立。三个工具：

- **`LayoutBuilder`**（16 章）：按可用宽度分布局（宽 → 左右分栏；窄 → 上下堆叠）
- **`MediaQuery.sizeOf(context)`**：整窗尺寸——对话框宽度按窗口比例设（`width: screenWidth * 0.6`）
- **断点常量**：Material 3 的 `Breakpoints`（`MediaQuery` 扩展）或自己定义（`isWide = width > 900`）

桌面应用最常见的布局是"主从结构"（左列表右详情）——窗口窄时详情全屏覆盖、宽时并排。`flutter_adaptive_scaffold`（生态包）封装了这个模式，手写用 `LayoutBuilder` + 条件渲染也够。

## 坑位清单

- **exe 单文件拷走跑不起来**：Flutter Windows 产物是目录（exe+dll+data）——整目录打包。
- **改了 windows/runner 没生效**：原生侧改动不走热重载/热重启，完全停掉重跑。
- **滚动区没滚动条**：桌面观感差评——Scrollbar 包上。
- **触屏习惯带上桌面**：间距/字体/命中区域过小——桌面 `dense:` 列表、紧凑模式按需开。
- **Shortcuts 不触发**：焦点不在 Shortcuts 子树里——包 `Focus(autofocus: true)`。
- **菜单快捷键提示只是装饰**：`MenuItemButton.shortcut` 只显示文字——真正绑定在 Shortcuts 层，两处都要写。
- **PlatformMenuBar 在 Windows 上没反应**：它只服务 macOS——Windows/Linux 用 MenuBar，条件渲染。
- **窗口拉伸布局崩了**：没做响应式——LayoutBuilder 按宽度分支（18.6）。
---

上一章：[17 · 数据持久化：记住用户的世界](17-persist.md) ｜ 下一章：[19 · Widget 测试：自动化的界面验证](19-testing.md) ｜ 返回：[README](../README.md)
