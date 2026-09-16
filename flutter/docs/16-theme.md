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

| | LayoutBuilder | MediaQuery.of(context) |
|---|---|---|
| 拿到什么 | **自己**的约束（父级给的） | **屏幕**的全局信息（尺寸/安全区/缩放） |
| 适用 | 局部自适应（这个格子宽了换布局） | 全局适配（断点、平板判定） |
| 响应 | 窗口拖动时实时 rebuild | 同样实时 |

经验：**布局决策优先用 LayoutBuilder**（嵌套场景里"自己的宽度"才作数，屏幕宽不等于你的宽）；MediaQuery 处理键盘弹出避让、安全区这类全局关切。

## 坑位清单

- **写死颜色**：`Colors.white` 背景在深色模式刺眼——语义色是默认选项，例外要注释原因。
- **Theme.of 结果缓存到字段**：主题切换后字段还是旧值——在 build 里取（或用依赖 InheritedWidget 的机制自动重建）。
- **断点用屏幕宽而非约束宽**：侧栏展开时内容区变窄，按屏幕宽判"宽屏"就错了——LayoutBuilder 拿局部约束。
- **SegmentedButton 的 selected 是 Set**：`selected: {mode}` 不是 `mode`。
