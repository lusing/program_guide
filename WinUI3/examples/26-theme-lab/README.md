# 26-theme-lab（主题实验室）

控件篇第四功能工程（进阶篇）：预设换肤真生效、自定义控件仪表盘、ColorPicker 实时改全局 accent、VSM 自适应、换肤过渡动画、Shape 迷你柱状图。

## 承载章节

| 章 | 机制 | 在本工程的真实职责 |
|---|---|---|
| 26 | Style/资源系统 | 预设换肤（Application.Resources 覆盖 accent 键） |
| 27 | 自定义控件 | LabeledValueControl（UserControl + 两个依赖属性）×4 仪表盘 |
| 28 | VSM | AdaptiveTrigger 宽窄两态 |
| 29 | 动画 | 换肤 Storyboard 过渡（代码建，全限定命名空间） |
| 30 | Shape/ColorPicker | 七柱周访问图（随 accent 重刷）+ 取色器 |

## 架构

```text
MainWindow
├── PresetList(ListBox)   四预设（色板+名），SelectionChanged → ApplyAccent+主题+动画
├── Dashboard             Tiles(2x2 自定义控件) + Chart(7×Rectangle)
│   └── VSM               AdaptiveTrigger MinWindowWidth=1200 宽窄切换
├── AccentPicker(ColorPicker)  ColorChanged → ApplyAccent（实时）
└── PlaySkinTransition()  Storyboard：Opacity 0.2→1 + TranslateY 18→0（450ms）
Preset/PresetInfo         结构体（逻辑）+ runtimeclass（绑定）
```

## 关键实现位

- **运行时改 accent 的正路**：`Application::Current().Resources().Insert(L"AccentFillColorDefaultBrush", brush)`——全树 ThemeResource 引用即时跟随
- **代码造的元素跟 accent**：柱子登记进 `m_bars`、ApplyAccent 全量重刷（TryLookup 拿不到 XamlControlsResources 内层键，实测）
- **DP 三连坑**（LabeledValueControl 实录）：PropertyMetadata 默认值必给、getter/setter 先经惰性注册、崩溃用 UnhandledException 落盘定位——27 章整节
- **IDL 三坑**：注释必须 ASCII、runtimeclass 不收静态成员、构造函数带参要 factory_implementation

## 冒烟

```powershell
pwsh tools\ui-smoke\smoke-themelab.ps1
```

两流程：preset（Sunset：选中高亮 + 暗壳 + 七柱变红）/ picker（accent=#107,10,10 实时）。证据在 `.smoke/26-theme-lab/<流程>/`。
