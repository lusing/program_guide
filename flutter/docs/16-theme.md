# 16 · 主题与响应式：一处定义，处处生效

> 对应示例：examples/16_theme/

## 16.1 解决什么问题

二十个页面写二十遍颜色，改版时改二十处——主题把"视觉决策"从页面里抽出来集中管理。桌面应用还有第二个刚需：**窗口宽度用户随便拖**，从 360 到 4K 都要看得过去——响应式布局是桌面的一等公民，不是手机附赠品。

```dart
    // ═══ 16.1 一颗种子色生成整套色板（Material 3） ═══
    return MaterialApp(
      title: 'Theme Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _mode,
      home: ThemePage(
        mode: _mode,
        onModeChanged: (m) => setState(() => _mode = m),
      ),
    );
```

MaterialApp 的三件套：`theme`（浅色）、`darkTheme`（深色）、`themeMode`（当前用哪套——light/dark/system）。`ColorScheme.fromSeed` 是 M3 的核心手法：**一颗种子色生成整套协调色板**（primary/secondary/surface/onXxx 全有了），不用手工配 17 个颜色。深浅模式 = 同一颗种子的两种 brightness。

### ColorScheme 的角色体系

M3 的 ColorScheme 按"角色"组织颜色，每个角色有"底色 + 前景色"成对出现：

| 角色 | 用途 | 前景色 |
|---|---|---|
| `primary` | 主操作、强调 | `onPrimary` |
| `secondary` | 次强调（Chip、Filter） | `onSecondary` |
| `tertiary` | 第三强调（平衡主色） | `onTertiary` |
| `surface` | 卡片/面板底 | `onSurface` |
| `error` | 错误态 | `onError` |
| `surfaceContainerHighest` | 分层底（凹槽区、对话框底） | — |

写颜色时的思考顺序：**"这个元素是什么角色" → 取对应色**——按钮用 primary、正文用 onSurface、错误用 error。写死 `Colors.blue` 的每一处都是深色模式的潜在炸弹。

## 16.2 切换主题：根 State 管模式

```dart
          // ═══ 16.2 SegmentedButton：M3 的分段选择 ═══
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, label: Text('浅色')),
              ButtonSegment(value: ThemeMode.dark, label: Text('深色')),
            ],
            selected: {mode},
            onSelectionChanged: (s) => onModeChanged(s.first),
          ),
```

themeMode 是状态，放**根 State**（MaterialApp 的父级），通过回调下发（第 09 章的提升模式）——换 mode 即换整棵树的 ThemeData，所有页面同步变色。顺带认识 `SegmentedButton<T>`（M3 分段选择器）：`segments` 选项 + `selected` 是**Set**（注意花括号）+ onSelectionChanged 取 first。

### ThemeMode.system 与持久化

`ThemeMode.system` 跟随操作系统的深浅设置——桌面用户期望的默认行为。把用户选择存到 shared_preferences（第 17 章），启动时读回：

```dart
// main 里
final prefs = await SharedPreferences.getInstance();
final modeIndex = prefs.getInt('theme_mode') ?? 0;  // 0=light 1=dark 2=system
runApp(ThemeApp(initialMode: ThemeMode.values[modeIndex]));
```

切换时同步写 prefs——下次启动就是上次的选择。

## 16.3 语义色：不写死颜色

```dart
          Card(
            child: ListTile(
              leading: Icon(Icons.palette,
                  color: Theme.of(context).colorScheme.primary),
              title: const Text('颜色来自 colorScheme.primary'),
            ),
          ),
```

`Theme.of(context)`（第 09 章点破过：InheritedWidget）取当前主题，用**角色**而不是具体值：

| 角色 | 用途 |
|---|---|
| `primary` / `onPrimary` | 主色 / 主色上的前景 |
| `surface` / `onSurface` | 面板底 / 面板上的前景 |
| `error` | 错误 |
| `surfaceContainerHighest` | 分层底色（卡片上的凹槽区） |

写 `Colors.black` 的地方换成 `onSurface`、写 `Colors.blue` 的换成 `primary`——深色模式自动正确。字体与组件风格同理：`Theme.of(context).textTheme.titleLarge`；要全局改某组件默认样式用 ThemeData 里的组件主题（`appBarTheme:`、`listTileTheme:` 一句话：进阶再学）。

### textTheme 的层级

M3 的 textTheme 按信息层级组织：

| 层级 | 用途 |
|---|---|
| `displayLarge/Medium/Small` | 超大展示数字、空态插画标题 |
| `headlineLarge/Medium/Small` | 页面大标题 |
| `titleLarge/Medium/Small` | 卡片标题、列表项标题、对话框标题 |
| `bodyLarge/Medium/Small` | 正文（bodyMedium 是默认正文） |
| `labelLarge/Medium/Small` | 按钮文字、标签、小字 |

优先用层级而不是手写 `TextStyle(fontSize: 24)`——全应用 typography 一致，改主题一处生效。

### 组件主题：全局改某组件的默认样式

```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
  appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
  cardTheme: CardTheme(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
  inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  listTileTheme: const ListTileThemeData(dense: true),
)
```

每个组件的"默认外观"都可以在 ThemeData 里全局定制——不用在每个使用点重复传参。

## 16.4 响应式：LayoutBuilder 与 MediaQuery

```dart
          // ═══ 16.4 LayoutBuilder：按可用宽度换布局 ═══
          Container(
            height: 80,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 500;
                return wide
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [Text('宽屏：双栏'), Text('第二栏')],
                      )
                    : const Center(child: Text('窄屏：单栏'));
              },
            ),
          ),
```

两个工具，用途不同：

| | LayoutBuilder | MediaQuery |
|---|---|---|
| 拿到什么 | **自己**的约束（父级给的） | **屏幕**的全局信息（尺寸/安全区/缩放） |
| 适用 | 局部自适应（这个格子宽了换布局） | 全局适配（断点、平板判定） |
| 响应 | 窗口拖动时实时 rebuild | 同样实时 |

经验：**布局决策优先用 LayoutBuilder**（嵌套场景里"自己的宽度"才作数，屏幕宽不等于你的宽）；MediaQuery 处理键盘弹出避让、安全区这类全局关切。

### MediaQuery 的常用查询

```dart
// 屏幕尺寸（推荐用 xxxOf 系列——只在该字段变化时重建）
final size = MediaQuery.sizeOf(context);
final padding = MediaQuery.paddingOf(context);       // 安全区（刘海/状态栏）
final viewInsets = MediaQuery.viewInsetsOf(context);  // 键盘占用
final platformBrightness = MediaQuery.platformBrightnessOf(context);

// 旧写法（不推荐）：
// final size = MediaQuery.of(context).size;  // MediaQueryData 任何字段变都重建
```

`MediaQuery.of(context)` 返回整个 `MediaQueryData`——**任何**字段变化（包括键盘弹出）都触发重建。`sizeOf`/`paddingOf` 等细粒度方法只监听特定字段——键盘弹出时 `sizeOf` 不重建（屏幕尺寸没变），性能更好。lint（use_media_query_xxx_of）会推荐细粒度版本。

### 断点常量

Material 3 的响应式断点：

| 断点 | 宽度 | 典型布局 |
|---|---|---|
| compact | < 600 | 手机/窄窗：单栏 |
| medium | 600–840 | 平板/半屏：列表+详情 |
| expanded | > 840 | 桌面/宽屏：多栏 |

```dart
String breakpoint(double width) =>
    width < 600 ? 'compact' : width < 840 ? 'medium' : 'expanded';
```

桌面应用的主从布局（master-detail）按断点切换：compact 全屏详情、medium 列表 300 + 详情剩余、expanded 列表 360 + 详情剩余。

## 坑位清单

- **写死颜色**：`Colors.white` 背景在深色模式刺眼——语义色是默认选项，例外要注释原因。
- **Theme.of 结果缓存到字段**：主题切换后字段还是旧值——在 build 里取（或用依赖 InheritedWidget 的机制自动重建）。
- **断点用屏幕宽而非约束宽**：侧栏展开时内容区变窄，按屏幕宽判"宽屏"就错了——LayoutBuilder 拿局部约束。
- **SegmentedButton 的 selected 是 Set**：`selected: {mode}` 不是 `mode`。
- **MediaQuery.of 引起过度重建**：键盘弹出整页重建——用 `MediaQuery.sizeOf` 等细粒度方法，只监听需要的字段。
- **深色模式只改 colorScheme**：文字颜色/图标颜色写死 `Colors.black` 在深色下看不见——全部走 onSurface/onPrimary 等前景角色。
---

上一章：[15 · 动画：隐式、Hero 与显式](15-animation.md) ｜ 下一章：[17 · 数据持久化：记住用户的世界](17-persist.md) ｜ 返回：[README](../README.md)
